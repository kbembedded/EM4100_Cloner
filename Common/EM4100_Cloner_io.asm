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


	#include "EM4100_Cloner_io.inc"
    #include "EM4100_Cloner_rf.inc"

    GLOBAL	_initIO, _read_DIP, _manual_input
    EXTERN  LATA, LATC, DIP_NIBBLE, RFID_MEMORY, PARITY, COLUMN_PARITY, NIBBLE_CNT
    EXTERN  _WDT_reset, _pauseWx10us, _pauseWx1ms, write_RFID




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
    UDATA
TMP     RES .1
DIP_TMP RES .1
ADDRESS RES .1
	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _initIO                                                        ;
;    Desc.:     Initialize the Input/Output devices (LEDS & BUTTONS)          ;
;    Params.:   NONE                                                           ;
;                                                                              ;
;    Notes:     Returns in Bank 0                                              ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_initIO
    ; XXX: Can the LED enable code be cleaned up at all?
    BANKSEL TRISA

    CLRF    ANSEL 					; GPIO as digital IOs

    BCF     OPTION_REG, NOT_RAPU	; PULL-UPs activated on GPIO
    
    BSF     IOCA, IOC5              ; Enable interrupt on change for coil
    BSF     IOCA, IOC2

    ; Manual conflicts itself with PORTx value on WDT reset, lets just be safe
    BANKSEL PORTA
    CLRF    PORTA                   ; Init PORT to known values
    CLRF    PORTC
    CLRF    LATA
    CLRF    LATC
    LED1_OFF
    LED2_OFF

    BANKSEL TRISA
    BCF     LED1_TRIS				; LEDs as output
    BCF     LED2_TRIS
    BCF     TRISC, RC5              ; Set PWM as low output, prevent floppy FETs
    BCF     DEMODULATOR_TRIS        ; Set Demodulator as low output

    BANKSEL PORTA
    MOVLW    07h 					; Disable the analog comparators
    MOVWF    CMCON0

    MOVLW   .50                     ; Wait for debouncing
    CALL    _pauseWx10us

    BSF     INTCON, RAIE            ; Enable interrupt for RA
	
    RETURN

_read_DIP
    MOVF    PORTC, W
    MOVWF   DIP_TMP
    COMF    DIP_TMP, F

    ; Roll bit positions due to layout from 0123 to 3210
    RRF     DIP_TMP, F
    RLF     DIP_NIBBLE, F
    RRF     DIP_TMP, F
    RLF     DIP_NIBBLE, F
    RRF     DIP_TMP, F
    RLF     DIP_NIBBLE, F
    RRF     DIP_TMP, F
    RLF     DIP_NIBBLE, F

    MOVLW   b'00001111'
    ANDWF   DIP_NIBBLE, F
    RETURN

_manual_input
    MOVF    DIP_NIBBLE, W
    MOVWF   ADDRESS
    ; XXX: This is pretty ugly and thrown together for functionality ASAP
    ;        Will have to clean this up later
    BCF     INTCON, GIE
    ; From this point, we're not using an interrupt

    MOVLW   .40
    MOVWF   TMP

_manual_enter
    ; Make sure the button is held for 4 seconds
    MOVLW   .100
    CALL    _pauseWx1ms

    BTFSC   BTN
    GOTO    _WDT_reset

    DECFSZ  TMP
    GOTO    _manual_enter

    LED1_ON
    LED2_ON

    BTFSS   BTN
    GOTO    $-1

    LED2_OFF

    MOVLW   RFID_MEMORY             ; Load INDF with start of RFID_MEMORY
    MOVWF   FSR

    CLRF    COLUMN_PARITY
    MOVLW   .10
    MOVWF   NIBBLE_CNT              ; TODO: Pull this from EEPROM?

_manual_timer
    MOVLW   .200
    MOVWF   TMP
_manual_loop

    MOVLW   .100
    CALL    _pauseWx1ms

    BTFSC   BTN
    GOTO    _end_manual_loop

    CALL    _read_DIP
    CLRF    PARITY

    LED2_ON
    LED1_OFF

    BTFSS   BTN                     ; Wait for button to be released
    GOTO    $-1

    LED2_OFF
    LED1_ON

    MOVF    DIP_NIBBLE, W
    MOVWF   DIP_TMP

    RRF     DIP_TMP, F
    BTFSC   STATUS, C
    INCF    PARITY, F

    RRF     DIP_TMP, F
    BTFSC   STATUS, C
    INCF    PARITY, F

    RRF     DIP_TMP, F
    BTFSC   STATUS, C
    INCF    PARITY, F

    RRF     DIP_TMP, F
    BTFSC   STATUS, C
    INCF    PARITY, F

    BCF     STATUS, C
    RLF     DIP_NIBBLE, F

    ; DIP_NIBBLE is still in W
    XORWF   COLUMN_PARITY, F

    BTFSC   PARITY, 0
    INCF    DIP_NIBBLE, F                   ; Add one to parity if needed

    MOVF    DIP_NIBBLE, W
    MOVWF   INDF                            ; Copy the full nibble to RAM
    INCF    FSR, F

    DECFSZ  NIBBLE_CNT
    GOTO    _manual_timer

    BCF     STATUS, C
    RLF     COLUMN_PARITY, W
    MOVWF   INDF                            ; Save column parity

    MOVF    ADDRESS, W
    MOVWF   DIP_NIBBLE                      ; Restore the address we're saving to

    CALL    write_RFID
    ; We should never end up back here

    GOTO    _WDT_reset

_end_manual_loop
    DECFSZ  TMP
    GOTO    _manual_loop

    GOTO    _WDT_reset



    END
