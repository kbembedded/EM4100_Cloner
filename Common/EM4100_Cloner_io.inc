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

	#IFNDEF	IO_INC
	
	#DEFINE IO_INC


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


	#DEFINE LED2		LATA, RA0
	#DEFINE LED2_TRIS	TRISA, RA0
	#DEFINE LED2_MASK	b'00000001'
	#DEFINE LED1		LATC, RC4
	#DEFINE LED1_TRIS	TRISC, RC4
	#DEFINE LED1_MASK 	b'00010000'

    #DEFINE BTN         PORTA, RA2
    #DEFINE BTN_TRIS    TRISA, RA2
    #DEFINE BTN_MASK    b'00000100'

	;#DEFINE COUTPIN         GPIO,   GP2
	;#DEFINE COUTPIN_TRIS    TRISIO,GP2
	;#DEFINE COUTPIN_MASK    b'00000100'
	;#DEFINE BUTTON2		GPIO,   GP3
	;#DEFINE BUTTON2_TRIS TRISIO,GP3
	;#DEFINE BUTTON2_MASK b'00001000'




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								    MACROS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

LED1_ON MACRO
    BCF     LED1
    MOVF    LATC, W
    MOVWF   PORTC
    ENDM

LED1_OFF MACRO
    BSF     LED1
    MOVF    LATC, W
    MOVWF   PORTC
    ENDM

LED2_ON MACRO
    BCF     LED2
    MOVF    LATA, W
    MOVWF   PORTA
    ENDM

LED2_OFF MACRO
    BSF     LED2
    MOVF    LATA, W
    MOVWF   PORTA
    ENDM

;LED1_TOGGLE MACRO
;	MOVLW	LED1_MASK
;	XORWF	PORTC, F
;	ENDM

;LED2_TOGGLE MACRO
;	MOVLW	LED2_MASK
;	XORWF	PORTA, F
;	ENDM


;BUTTON1_WAIT_UNTIL_PRESSED	MACRO
;	BTFSC	BUTTON1
;	GOTO	$-1
;	ENDM

;BUTTON1_WAIT_UNTIL_NOT_PRESSED	MACRO
;	BTFSS	BUTTON1
;	GOTO	$-1
;	ENDM


;BUTTON2_WAIT_UNTIL_PRESSED	MACRO
;	BTFSC	BUTTON2
;	GOTO	$-1
;	ENDM

;BUTTON2_WAIT_UNTIL_NOT_PRESSED	MACRO
;	BTFSS	BUTTON2
;	GOTO	$-1
;	ENDM


;BUTTON1_CALL_IF_PRESSED MACRO ADDRESS
;	BTFSS	BUTTON1
;	CALL	ADDRESS
;	ENDM

;BUTTON1_CALL_IF_NOT_PRESSED MACRO ADDRESS
;	BTFSC	BUTTON1
;	CALL	ADDRESS
;	ENDM

;BUTTON1_GOTO_IF_PRESSED MACRO ADDRESS
;	BTFSS	BUTTON1
;	GOTO	ADDRESS
;	ENDM

;BUTTON1_GOTO_IF_NOT_PRESSED MACRO ADDRESS
;	BTFSC	BUTTON1
;	GOTO	ADDRESS
;	ENDM


;BUTTON2_CALL_IF_PRESSED MACRO ADDRESS
;	BTFSS	BUTTON2
;	CALL	ADDRESS
;	ENDM

BUTTON2_CALL_IF_NOT_PRESSED MACRO ADDRESS
	BTFSC	BUTTON2
	CALL	ADDRESS
	ENDM

BUTTON2_GOTO_IF_PRESSED MACRO ADDRESS
	BTFSS	BUTTON2
	GOTO	ADDRESS
	ENDM

BUTTON2_GOTO_IF_NOT_PRESSED MACRO ADDRESS
	BTFSC	BUTTON2
	GOTO	ADDRESS
	ENDM


	#ENDIF