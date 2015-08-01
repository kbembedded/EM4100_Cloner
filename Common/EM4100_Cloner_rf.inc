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


	#include "p16f684.inc"

	#IFNDEF	RF_INC
	
	#DEFINE RF_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	;#DEFINE DEBUG 1				; Debugging flag

    ; XXX: Rename COIL1 to COIL2 and vice versa
	; Coil IO
	#DEFINE COIL1               LATA, RA4
	#DEFINE COIL1_TRIS          TRISA, RA4
	#DEFINE COIL1_MASK_TRISIO   b'00010000'
	#DEFINE COIL2               LATA, RA5
	#DEFINE COIL2_TRIS          TRISA, RA5
	#DEFINE DEMODULATOR         LATA, RA1
	#DEFINE DEMODULATOR_TRIS    TRISA, RA1


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								    MACROS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


RF_0 MACRO
    ; Start timing critical section
    BTFSS   PIR1, TMR1IF
    GOTO    $-1
    SUBWF   TMR1L, F            ; TMR1L is 0x0
    INCF    TMR1L, F            ; Tune
    BANKSEL TRISA
    BCF     COIL1_TRIS			; Coil to GND
    ; End critical section
    BANKSEL PORTA
    BCF     PIR1, TMR1IF
    COMF    TMR1H, F            ; TMR1H is 0x0, set to 0xFF
	
	ENDM


RF_1 MACRO
    ; Start timing critical section
    BTFSS   PIR1, TMR1IF
    GOTO    $-1
    SUBWF   TMR1L, F            ; TMR1L is 0x0
    INCF    TMR1L, F            ; Tune
    BANKSEL TRISA
    BSF     COIL1_TRIS			; Coil tristate
    ; End critical section
    BANKSEL PORTA
    BCF     PIR1, TMR1IF
    COMF    TMR1H, F            ; TMR1H is 0x0, set to 0xFF
	
	ENDM


; XXX: This is not valid any longer
RF_TOGGLE MACRO

	BANKSEL TRISA
	MOVLW	COIL1_MASK_TRISIO
	XORWF	TRISA, F
	BANKSEL	PORTA

	ENDM


	#ENDIF
