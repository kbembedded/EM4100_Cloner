;The MIT License (MIT)
;
;Copyright (c) 2014 KBEmbedded
;
;This project is based on the OPEN RFID tag with resources pulled from t4f.org
;and kukata86.com.
;
;Permission is hereby granted, free of charge, to any person obtaining a copy of
;this software and associated documentation files (the "Software"), to deal in
;the Software without restriction, including without limitation the rights to
;use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of
;the Software, and to permit persons to whom the Software is furnished to do so,
;subject to the following conditions:
;
;The above copyright notice and this permission notice shall be included in all
;copies or substantial portions of the Software.
;
;THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
;IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS
;FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR
;COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER
;IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN
;CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.

    #INCLUDE "p16f684.inc"
	#INCLUDE "EM4100_Cloner_rf.inc"


	GLOBAL	_initRF, _initRF_common
	GLOBAL  _txManchester1, _txManchester0, _txBiphase1, _txBiphase0

    EXTERN  LATA, LATC



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



	UDATA

TMP_CLOCKS_PER_BIT	RES 1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _initRF                                                        ;
;    Desc.:     Initialize the RF                                              ;
;    Params.:   W -> CARRIER CLOCKS PER BIT                                    ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;    Notes:     The TMR1 interruption is activated.                            ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_initRF_common

    BANKSEL TRISA               ; Bank 1

    BSF     DEMODULATOR_TRIS    ; Set Demodulator back as an input

    MOVLW   b'00000010'         ; RA1 as analog input. Rest as digital
    MOVWF   ANSEL

    ; XXX: Check this value
    MOVLW   b'10101010'         ; Voltage Regulator ON; Low range; XXX Vdd
    MOVWF   VRCON

    BANKSEL CMCON0
    MOVLW   b'00000010'         ; Comparator Output NOT Inverted. CIN- == GP1 ; CIN+ == CVref
    MOVWF   CMCON0

    RETURN

_initRF
    BCF     STATUS, C
    MOVWF	TMP_CLOCKS_PER_BIT	; Backup of the CLOCK_PER_BIT value stored in W
    RRF     TMP_CLOCKS_PER_BIT, F
    ; We only need to care about clocks per bit / 2

    BCF     COIL1				; COIL1 connected to GND (if COIL1_TRIS = 0)
    MOVF    LATA, W             ; COIL1 is on PORTA, write shadow reg
    MOVWF   PORTA

	MOVLW	0xFF				; Write the Timer1 upper byte
	MOVWF	TMR1H

    CLRF    TMR1L
    MOVF    TMP_CLOCKS_PER_BIT, W
    SUBWF   TMR1L, F            ; 0x00 - (CLOCKS_PER_BIT / 2)
    INCF    TMR1L, F            ; Tune

    MOVLW	b'00000111'         ; Timer1: external clock source, synchronous, no prescaler.
    ;MOVLW   b'00110001'         ; Timer1: internal clock, 1:8 prescaler, for debugging
	MOVWF	T1CON               ; Timer1 config

	BCF     PIR1, TMR1IF        ; Clear the TMR1IF flag

	RETURN



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txManchester1                                                 ;
;    Desc.:     Transmit a Manchester encoded 1 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txManchester1
    MOVF    TMP_CLOCKS_PER_BIT, W   ; Load W with needed clocks per bit / 2
    ; At this point, we're ready to just reload the timer

    RF_0
    RF_1
    BSF     STATUS, C

	RETURN




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txManchester0                                                 ;
;    Desc.:     Transmit a Manchester encoded 0 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txManchester0
    MOVF    TMP_CLOCKS_PER_BIT, W   ; Load W with needed clocks per bit / 2
    ; At this point, we're ready to just reload the timer

    RF_1
    RF_0
    BCF     STATUS, C

    RETURN



; XXX: Biphase is not yet supported!

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txBiphase1                                                    ;
;    Desc.:     Transmit a Manchester encoded 1 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txBiphase1

	;WAIT_RF_IS_READY
	RF_TOGGLE

	;WAIT_RF_IS_READY

	return




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _txBiphase0                                                    ;
;    Desc.:     Transmit a Manchester encoded 0 bit                            ;
;    Vars:                                                                     ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_txBiphase0

	;WAIT_RF_IS_READY
	RF_TOGGLE

	;WAIT_RF_IS_READY
	RF_TOGGLE

	return

END