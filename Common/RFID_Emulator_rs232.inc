  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
 ;;                                                                          ;;
;;                                                                            ;;
;                   RFID Emulator - RS232 LIBRARY                              ;
;;                                                                            ;;
 ;;                                                                          ;;
  ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	#include "p12f683.inc"

	#IFNDEF	RS232_INC
	
	#DEFINE RS232_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	;RS232 CONFIGURATION
	#DEFINE DATA_BITS	8
	#DEFINE BAUDS .1200

	; Timer calcs.
	#DEFINE	CLOCK_FREQ .4000000 / (.4*.4)		; 4x prescaler
	#DEFINE BIT_PERIOD CLOCK_FREQ/BAUDS
	#DEFINE HALF_BIT_PERIOD CLOCK_FREQ/(BAUDS*2)


	; RS232 IO
	#DEFINE SERIAL_TX	GPIO, 0
	#DEFINE SERIAL_RX 	GPIO, 1
	#DEFINE SERIAL_TX_TRIS TRISIO, 0
	#DEFINE SERIAL_RX_TRIS TRISIO, 1

	#DEFINE SERIAL_RX_IOC	IOC, 1
	

	; Flags bits
	#DEFINE FLAGS_WAITING_BAUD 0
	#DEFINE FLAGS_RECEIVING_DATA 1
	#DEFINE FLAGS_TRANSMITING_DATA 2
	#DEFINE FLAGS_DATA_RX 3
	#DEFINE FLAGS_DATA_TX 4
	#DEFINE FLAGS_WAITING_TX_STOP_BIT 5


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								    MACROS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

RS232_TX_AND_WAIT	MACRO

	BCF		RS232_FLAGS, FLAGS_DATA_TX	
	CALL 	_txRS232
	BTFSS	RS232_FLAGS, FLAGS_DATA_TX
	GOTO	$-1

	ENDM


STRING	MACRO VALUE
	da		0x0782					; Assambled word for "ADDWF PCL, F"
	dt VALUE, 0

	ENDM


; TODO: This macro could be coded as a function. 
RS232_PRINT_STR	MACRO	STRING

	CLRF	TMP

	MOVLW	HIGH STRING
	MOVWF	PCLATH

;_RS232printf_loop
	MOVFW	TMP

	CALL	STRING

	ANDLW	0xFF					; Check if the returned value is zero
	BTFSC	STATUS, Z	
	;GOTO	_RS232printf_exit
	GOTO	$+.7

	RS232_TX_AND_WAIT

	INCF	TMP, F

	;GOTO	_RS232printf_loop
	GOTO	$-.10

;_RS232printf_exit

	;RETURN

	ENDM
	
#ENDIF

