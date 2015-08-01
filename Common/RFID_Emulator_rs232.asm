  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                 RFID Emulator - RS232 LIBRARY                                ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;






	#INCLUDE "p12f683.inc"
	#INCLUDE "rs232.inc"


	GLOBAL	_initRS232, _ISRTimer2RS232, _txRS232, _ISRGPIORS232, _rs232PrintHexChar
	GLOBAL	RS232_FLAGS, RX_BYTE

	EXTERN	_nibbleHex2ASCII



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	UDATA

RS232_FLAGS	RES 1
TX_BYTE		RES 1
TX_COUNTER	RES 1
RX_BYTE		RES 1
RX_COUNTER	RES 1

TMP			RES	1
TMP2		RES 1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _initRS232                                                     ;
;    Desc.:     Initialize the RS232                                           ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_initRS232

	BANKSEL	PIE1
	BSF		PIE1, TMR2IE			; Enable the TMR2 interruptions

	; Configure the IO pins
	BSF		SERIAL_RX_TRIS
	BCF		SERIAL_TX_TRIS

	BSF		SERIAL_RX_IOC

	CLRF	ANSEL 					; GPIO as digital IOs
	
	BANKSEL	T2CON					; TMR2 => Prescaler x4.No postscaler.STOPPED
	MOVLW	b'00000001'
	MOVWF	T2CON

	BSF		INTCON, GIE				; Enabling global, peripheral and GPIO interrupts 
	BSF		INTCON, PEIE
	BSF		INTCON, GPIE

	MOVLW	07h 					; Disable the analog comparators
	MOVWF	CMCON0

	BSF		SERIAL_TX				; TX ~ HIGH 

	CLRF	RS232_FLAGS

	RETURN





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _ISRTimer2RS232                                                ;
;    Desc.:     Timer2 Interruption Service Routine                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:     WARNING! It can return with the bank 1 selected                ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ISRTimer2RS232

	BCF		PIR1, TMR2IF			; Clear the TMR2IF flag

	BANKSEL PIE1					; Bank 1

	BTFSS	PIE1, TMR2IE			; Check for ghost interrupts
	RETURN							; WARNING! Return with the Bank 1 selected

	BANKSEL GPIO					; Bank 0
	;BCF		RS232_FLAGS, FLAGS_WAITING_BAUD	; Clear the flags

	BTFSS	RS232_FLAGS, FLAGS_RECEIVING_DATA	; Receiving data?
	GOTO	_ISRTimer2RS232_TX_DATA	; TX DATA

	; Receiving data!	

	MOVFW	RX_COUNTER				; Check if all the data bits have been received
	BTFSC	STATUS, Z
	GOTO	_ISRTimer2RS232_RX_STOP_BIT

	BCF		STATUS, C				; Push the received bit to RX_BYTE
	BTFSC	SERIAL_RX	
	BSF		STATUS, C
	RRF		RX_BYTE, F

	DECF	RX_COUNTER, F			

	RETURN


_ISRTimer2RS232_RX_STOP_BIT

	; Checking the STOP bit

	BTFSS	SERIAL_RX				; STOP bit == 1?
	RETURN							; ERROR!

	; Byte received correctly

	BSF		RS232_FLAGS, FLAGS_DATA_RX	
	BCF		RS232_FLAGS, FLAGS_RECEIVING_DATA

	BCF		T2CON, TMR2ON			; Stop the TMR2
	BSF		INTCON, GPIE			; Enable the GPIE interruptions	
	BANKSEL	IOC
	BSF		SERIAL_RX_IOC			; 
	BANKSEL GPIO
	

	RETURN


_ISRTimer2RS232_TX_DATA


	; Check if the transmission has ended
	BTFSC	RS232_FLAGS, FLAGS_WAITING_TX_STOP_BIT
	GOTO	_ISRTimer2RS232_TX_END
	

	MOVFW	TX_COUNTER				; Check if all the data bits have been received
	BTFSC	STATUS, Z
	GOTO	_ISRTimer2RS232_TX_STOP_BIT

	RRF		TX_BYTE, F
	BTFSC	STATUS,C
	GOTO	_txRS232_HIGH

	BCF		SERIAL_TX
	GOTO	_txRS232_WAIT

_txRS232_HIGH

	BSF		SERIAL_TX
	NOP

_txRS232_WAIT

	DECF	TX_COUNTER, F			

	RETURN

_ISRTimer2RS232_TX_STOP_BIT

	BSF		SERIAL_TX					; Transmit zero bit => TX ~ LOW
	BSF		RS232_FLAGS, FLAGS_WAITING_TX_STOP_BIT

	RETURN

_ISRTimer2RS232_TX_END

	BCF		RS232_FLAGS, FLAGS_WAITING_TX_STOP_BIT
	BSF		RS232_FLAGS, FLAGS_DATA_TX
	BCF		RS232_FLAGS, FLAGS_TRANSMITING_DATA
	
	BCF		T2CON, TMR2ON				; Stop the TMR2

	RETURN




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _ISRGPIORS232                                                  ;
;    Desc.:     GPIO Interruption Service Routine                              ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_ISRGPIORS232

	MOVFW	GPIO					; Read the GPIO. GPIF can't be cleared until GPIO is readed
	BCF		INTCON, GPIF			; Clear the GPIF flag

	BTFSS	INTCON, GPIE			; Check for ghost interrupts
	RETURN							

	BTFSC	SERIAL_RX				; Check if we received the start bit (RX == LOW)
	RETURN							; ERROR!  

	BTFSC	RS232_FLAGS, FLAGS_TRANSMITING_DATA	; Check if the RS232 resources (TMR2)
	RETURN							; are busy

	; Start Bit received and RS232 not transmitting
	
	BSF		RS232_FLAGS, FLAGS_RECEIVING_DATA ; Reserve the RS232 resources (TMR2)

	BCF		INTCON, GPIE			; Stop the GPIE interruptions
	

	MOVLW	DATA_BITS				; Load the number of data bits
	MOVWF	RX_COUNTER
	CLRF	RX_BYTE					; Clearing the received data byte


	; Waiting one bit period

	MOVLW	BIT_PERIOD	;- .8		; Loading the half bit period
	BANKSEL	PR2						; The "-8" is to compensate the interruption delay
	MOVWF	PR2

	BCF		SERIAL_RX_IOC			; If not cleared, the GPIF will toggle on

	BANKSEL	TMR2					; Bank 0

	CLRF	TMR2					; Clearing the TMR2 and switching it on 
	BSF		T2CON, TMR2ON
	
	RETURN;



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txRS232                                                       ;
;    Desc.:     Transmit a byte trough the serial port                         ;
;    Vars:		W => Byte to transmit                                          ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txRS232

	MOVWF	TX_BYTE					; Save the TX byte 

	BTFSC	RS232_FLAGS, FLAGS_RECEIVING_DATA ;Wait until data is received
	GOTO	$-1

	BSF		RS232_FLAGS, FLAGS_TRANSMITING_DATA

	MOVLW	DATA_BITS				; Load the number of data bits
	MOVWF	TX_COUNTER


	; Waiting half bit

	MOVLW	BIT_PERIOD				; Loading the bit period
	BANKSEL	PR2						
	MOVWF	PR2

	BANKSEL	TMR2					; Bank 0

	MOVLW	BIT_PERIOD - HALF_BIT_PERIOD - .8	; The "-8" is to compensate the interruption delay
	MOVWF	TMR2					; Clearing the TMR2 and switching it on 
	BSF		T2CON, TMR2ON

	BCF		SERIAL_TX						; Start bit -> TX ~ LOW

	RETURN


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _rs232PrintHexChar                                             ;
;    Desc.:     Transmit a byte in hex format trough the serial port           ;
;    Vars:		W => Byte to transmit                                          ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_rs232PrintHexChar

	MOVWF	TMP								; Make a backup 
	SWAPF	TMP, W	

	CALL	_nibbleHex2ASCII
	RS232_TX_AND_WAIT

	MOVFW	TMP
	CALL	_nibbleHex2ASCII
	RS232_TX_AND_WAIT

	RETURN
	

	END