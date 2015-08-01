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

#include "EM4100_Cloner.inc"
#include "../Common/EM4100_Cloner_io.inc"
#include "../Common/EM4100_Cloner_misc.inc"
#include "../Common/EM4100_Cloner_rf.inc"

__CONFIG _CPD_OFF & _WDT_OFF & _BOD_OFF & _PWRTE_ON & _INTRC_OSC_NOCLKOUT & _MCLRE_ON & _IESO_OFF & _FCMEN_OFF

EXTERN  _initIO
EXTERN  _pauseWx10us, _pauseWx1ms
EXTERN  _initRF_common
EXTERN  _writeEEPROM, PARAM1
EXTERN  _start_PLAY
EXTERN  _read_DIP
EXTERN  _manual_input

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                GLOBALS                                     ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

GLOBAL  EE_MEMORY_SIZE, EE_CLOCKS_PER_BIT, EE_TAG_MODE, EE_RFID_MEMORY
GLOBAL  FLAGS, PARITY, COLUMN_PARITY, NIBBLE_CNT
GLOBAL  LATA, LATC, DIP_NIBBLE, _WDT_reset, RFID_MEMORY, write_RFID

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                LITERALS                                    ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

#DEFINE RECORD             0 ; Flag: Are we writing to RFID Memory?
#DEFINE ERR                1 ; Flag: Error with manchester decoding
#DEFINE NUM_BIT_MANCHESTER 2 ; Flag: Which manchester bit are we on?
#DEFINE MANUAL             3 ; Flag: Manual input mode
#DEFINE BIT                5 ; Flag: Does this bit need to be demodulated?
#DEFINE WAS_T              6 ; Flag: Last bit was T and next bit needs to be checked
#DEFINE CAPTURE            7 ; Flag: If set, we are CAPTURING a tag

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

    UDATA
RFID_MEMORY             RES .11

    UDATA_SHR
LATA                    RES .1  ; Shadow registers for PORTs
LATC                    RES .1
FLAGS                   RES .1  ; Flags defined above.

TMP                     RES .1
W_TEMP                  RES .1
STATUS_TEMP             RES .1

EEPROM_ADDRESS          RES .1

MANCHESTER_BIT_IDX      RES .1  ; Manchester bit index
PACKET                  RES .1

NIBBLE_CNT              RES .1  ; Number of Nibbles remaining to receive
DIP_NIBBLE              RES .1
PARITY                  RES .1
COLUMN_PARITY           RES .1
CONFIG_CLOCKS_PER_BIT   RES .1

TRASH   UDATA   0xA0

TRASH                   RES .32 ; WARNING! We reserve all the GPRs in the BANK1
                                ; to avoid the linker using them.
                                ; This way, we force the linker to alloc all
                                ; the vars in the BANK0.
                                ;
                                ; The "good" way to do this is doing a linker
                                ; script.

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


RST_VECTOR      CODE    0x0000

    GOTO      _start


INT_VECTOR      CODE    0x0004

    ; XXX: See note about PCLATH on pg 109 of datasheet with interrupts on gotos
    ; Save the actual context
    MOVWF   W_TEMP
    SWAPF   STATUS,W
    BCF     STATUS,RP0
    MOVWF   STATUS_TEMP

    BTFSC   INTCON, RAIF
    CALL    _ISR_gpio

    BTFSC   INTCON, T0IF
    CALL    _ISR_timer

_ISR_exit
    ; Restore the context
    SWAPF   STATUS_TEMP,W
    MOVWF   STATUS
    SWAPF   W_TEMP,F
    SWAPF   W_TEMP,W

    RETFIE

_ISR_gpio
    ; If we end up here, we have a GPIO interrupt
    ; If button is released, and we're not in capture mode, the interrupt was from the coil
    ; If button is pressed, and we're not in capture mode, test coil for connection, enter capture mode
    ; If button is released, and we're in capture mode, reset
    ; If button is pressed, and we're in capture mode, reset

    BTFSC   FLAGS, CAPTURE
    GOTO    _WDT_reset

    MOVLW   .20
    CALL    _pauseWx1ms             ; Debounce

    BTFSC   BTN
    GOTO    _ISR_gpio_exit

    ; At this point, test for connection across coil
    BANKSEL TRISC
    BCF     COIL1_TRIS
    BANKSEL PORTA

    BCF     COIL1
    MOVF    LATA, W
    MOVWF   PORTA
    MOVLW   .1
    CALL    _pauseWx1ms

    BTFSS   PORTA, RA5                   ; Coil conn. means tag switch pos.
    BSF     FLAGS, MANUAL

    BSF     FLAGS, CAPTURE
    
    BANKSEL TRISC
    BSF     COIL1_TRIS
    BANKSEL PORTA

    

_ISR_gpio_exit
    BANKSEL IOCA
    BCF     IOCA, IOC5              ; We don't want to get another IRQ from GP5
    BANKSEL PORTA
    MOVF    PORTA, W                ; Read PORTA to clear interrupt condition
    BCF     INTCON, RAIF
    RETURN

_ISR_timer
    BTFSS   INTCON, T0IE            ; Verify the interrupt is actually enabled.
    RETURN

    GOTO    _WDT_reset
    RETURN

_WDT_reset
    CLRF    WDTCON
    BSF     WDTCON, SWDTEN
    GOTO    $




_start
    CLRF    T1CON                   ; This reg doesnt reset on WDT reset

    CLRF    FLAGS
    CALL    _initIO                 ; Init IO

    MOVF    PORTA, W
    BCF     INTCON, RAIF
    BSF     INTCON, GIE             ; Set up for interrupt from coil/button

    SLEEP                           ; Sit here until we do something
    NOP

    CALL    _read_DIP

    BTFSC   FLAGS, MANUAL
    GOTO    _manual_input

    CALL    _initRF_common

    BTFSC   FLAGS, CAPTURE
    GOTO    _start_clone

    ; Set up TMR0 to timeout tag mode and reset us
    CLRWDT
    BANKSEL OPTION_REG
    MOVLW   0xC0                    ; Mask TMR0 select and prescaler bits
    ANDWF   OPTION_REG,W
    IORLW   0x07                    ; Set prescale to 1:256
    MOVWF   OPTION_REG
    BCF     STATUS, C
    BANKSEL PORTA
    CLRF    TMR0
    BSF     INTCON, T0IE

    GOTO _start_PLAY


_start_clone

    LED1_ON

    ; XXX: Need a way to pull this out of EE where it is normally stored
    MOVLW   .64
    MOVWF   CONFIG_CLOCKS_PER_BIT

    ; XXX: From _initRF_RX
    ; XXX: COIL1 is currently an input?
    ;BANKSEL PORTA                ; Bank 0
    ;BCF     COIL1               ; COIL1 connected to GND (if COIL1_TRIS = 0)

    ; Enable PWM for driving the coil
    ;BANKSEL TRISA
    ;BSF     TRISC, RC5
    ;BCF     COIL1_TRIS
    ;BANKSEL PORTA

    BANKSEL PR2
    MOVLW   0x7
    MOVWF   PR2
    MOVLW   0x3c
    BANKSEL CCP1CON
    MOVWF   CCP1CON
    MOVLW   0x3
    MOVWF   CCPR1L
    BCF     PIR1, TMR2IF
    CLRF    T2CON ;Should not be needed
    BSF     T2CON, TMR2ON
    BANKSEL TRISA
    BCF     TRISC, RC5
    MOVLW   .50
    CALL    _pauseWx1ms
    BANKSEL PORTC

    CLRF    PARAM1
_main
    CLRF    TMP                 ; Clear variables
    CLRF    FLAGS
    BSF     FLAGS, CAPTURE

_clksync_start
    MOVLW   b'00000011'                 ; Timer1: external clock source, asynchronous, no prescaler.
    MOVWF   T1CON                       ; Timer1 config

    MOVF    CMCON0, F
    CLRF    PIR1
    CLRF    TMR1H
    CLRF    TMR1L

    BTFSS   PIR1, C1IF
    GOTO    $-1

    CLRF    TMR1L
    MOVF    CMCON0, F
    BCF     PIR1, C1IF

_clksync_loop

    BTFSS   PIR1, C1IF
    GOTO    $-1

    ;check value of TMR1L against 64
    MOVF    TMR1L, W
    CLRF    TMR1L
    MOVF    CMCON0, F                   ; Needed to clear mismatch condition
    BCF     PIR1, C1IF
    ;XXX: Currently hardcoded for 2T (64 clocks per bit)
    ; Hi = 80
    ; Lo = 48
    ; Min and max safe range with this manchester algorithm
    ; addlw (255 - hi)
    ; addlw (hi - lo) + 1
    ; C will be set in status if W was in range
    ADDLW   .175
    ADDLW   .33

    BTFSS   STATUS, C
    GOTO    _clksync_loop

    ; At this point, we're synced to the clock

    BTFSS   CMCON0, C1OUT
    GOTO    _bit0

    BSF     FLAGS, BIT
    GOTO    _bit_set

_bit0
    BCF     FLAGS, BIT

_bit_set
    MOVLW   .9                  ; Prepare to receive header (9 bits)
    MOVWF   NIBBLE_CNT

_check_header

    CALL    _Decode_bit
    BTFSC   FLAGS, ERR                  ; Restart if error
    GOTO    _main

    BTFSS   FLAGS, BIT                  ; 1 expected
    GOTO    _bit_set                    ; If not, error, start over.

    DECFSZ  NIBBLE_CNT, F
    GOTO    _check_header

    ; Point FSR to where we store RFID memory.
    MOVLW   RFID_MEMORY
    MOVWF   FSR

    ; We receive 10 data packets and 1 parity packet
    MOVLW   .11
    MOVWF   NIBBLE_CNT

    ; Each packet has 4 data bits and one parity bit.
    MOVLW   .5
    MOVWF   MANCHESTER_BIT_IDX   ; Reset index for next packet (5 bits)

    CLRF    PACKET               ; Clear all variables
    CLRF    PARITY
    CLRF    COLUMN_PARITY


; Wait for next bit, then process it
_wait_for_base_bit
    CALL    _Decode_bit
    ; Once we have the bit, we go ahead and process it

    BTFSC   FLAGS, ERR                  ; Restart if error
    GOTO    _main


_process_packet

    ; Set status flag to received bit.
    BCF     STATUS, C
    BTFSC   FLAGS, BIT
    BSF     STATUS, C

    ; Add bit to processed packet.
    RLF     PACKET, F       ; Rotate packet left to make room.
    BTFSC   FLAGS, BIT      ; If bit is 1...
    INCF    PARITY, F       ; We increment the parity bit.

    DECFSZ  MANCHESTER_BIT_IDX, F   ; If we still have more bits,
    GOTO    _wait_for_base_bit      ; wait for the next one.

    ; The packet is complete.

    ; XOR the packet with the column parity.
    ;     Vamos xoreando los paquetes para comprobar la paridad de columnas
    ;     "So what does -eando mean? we're doing it?"
    MOVFW   PACKET
    XORWF   COLUMN_PARITY, F

    ; If this is the last packet, we don't need to save it.
    DECF    NIBBLE_CNT, W
    BTFSC   STATUS, Z
    GOTO    _save_packet

    ; Check the parity.
    BTFSC   PARITY, 0
    GOTO    _main                   ; Parity is not even! Error!
    NOP


_save_packet

    ; Save packet, discard parity bit.
    BANKISEL RFID_MEMORY            ; Indirect access to bank 0
    MOVFW   PACKET
    MOVWF   INDF                    ;<- Do not lose carry bit
    ;BCF        STATUS, C               ; Clear the carry to rotate the register
    ;RRF        INDF, F                 ; Lose the parity bit
    INCF    FSR,F

    ; Reset the variables for the next packet.
    MOVLW   .5
    MOVWF   MANCHESTER_BIT_IDX
    CLRF    PACKET
    CLRF    PARITY

    ; Check if we have more packets.
    DECFSZ  NIBBLE_CNT, F       ; If we have more nibs, wait for them.
    GOTO    _wait_for_base_bit

    ; Otherwise, we have received all the packets.

    ; Stop interruptions.
    ; CALL    _stopRX
    ; XXX: Make sure timers are shut off, we NEED GIE for gpio
    ;BCF     INTCON,GIE ;Disable INTs

    ; Check the parity for our received data.
    MOVFW   COLUMN_PARITY
    ANDLW   b'11111110'
    BTFSS   STATUS, Z               ;
    GOTO    _main                   ; Error! We do not have parity!

    CALL    write_RFID

    ; We shouldn't get here, but leave this for completeness
    GOTO    _main


write_RFID

    MOVLW   RFID_MEMORY
    MOVWF   FSR

    INCF    DIP_NIBBLE
    MOVLW   EE_RFID_MEMORY
_adr_loop
    DECF    DIP_NIBBLE, F
    BTFSC   STATUS, Z
    GOTO    _adr_set
    ADDLW   .11
    GOTO    _adr_loop

_adr_set
    MOVWF   EEPROM_ADDRESS

    ; XXX: BANKISEL not necessary here?
    BANKISEL    RFID_MEMORY

_write_RFID_BUCLE

    MOVF    EEPROM_ADDRESS, W
    MOVWF   PARAM1

    MOVF    INDF, W

    CALL    _writeEEPROM

    INCF    EEPROM_ADDRESS, F
    INCF    FSR,F


    MOVLW   RFID_MEMORY+.11
    SUBWF   FSR, W
    BTFSS   STATUS, Z
    GOTO    _write_RFID_BUCLE

    BTFSC   FLAGS, MANUAL
    GOTO    _WDT_reset

    LED2_ON                 ; Stop execution and turn on LED.
    LED1_OFF
    BANKSEL TRISC
    BSF     TRISC, RC5
    GOTO    $

    RETURN

_Decode_bit
    BTFSS   PIR1, C1IF
    GOTO    $-1
    ;XXX: I could probably clean this up a little
    MOVF    TMR1L, W
    CLRF    TMR1L
    MOVWF   TMP

    MOVF    CMCON0, F                   ; Needed to clear mismatch condition
    BCF     PIR1, C1IF
    ;XXX: Currently hardcoded for T (32 clocks per bit)
    ; Hi = 48
    ; Lo = 16
    ; Min and max safe range with this manchester algorithm
    ; addlw (255 - hi)
    ; addlw (hi - lo) + 1
    ; C will be set in status if W was in range
    ADDLW   .207
    ADDLW   .33

    BTFSS   FLAGS, WAS_T
    GOTO    _keep_going

    BTFSS   STATUS, C
    BSF     FLAGS, ERR

_keep_going
    BTFSS   STATUS, C
    GOTO    _test_2T
    ; Now test for 2T (64)

    BTFSC   FLAGS, WAS_T
    GOTO    _donetimer

    BSF     FLAGS, WAS_T
    BTFSS   PIR1, C1IF
    GOTO    $-1

    GOTO    _Decode_bit

_donetimer
    BCF     FLAGS, WAS_T
    ;XXX: We could have an error here if next edge != T
    ; Next bit == current bit, lets just return
    RETURN

_test_2T
    MOVF    TMP, W
    ;XXX: Currently hardcoded for 2T (64 clocks per bit)
    ; Hi = 80
    ; Lo = 48
    ; Min and max safe range with this manchester algorithm
    ; addlw (255 - hi)
    ; addlw (hi - lo) + 1
    ; C will be set in status if W was in range
    ADDLW   .175
    ADDLW   .33

    BTFSS   STATUS, C
    BSF     FLAGS, ERR

_no_error
    ; Next bit == opposite bit
    MOVLW   b'00100000'           ;BIT
    XORWF   FLAGS, F

    RETURN





ORG 0x2100

; This is where the data is stored.
; We have memory size of 11 bytes, the tag mode (Manchester or BiPhase),
; and the 11 byte data in EE_RFID_MEMORY.
; We use 11 bytes, left 0 padded, one for each 5bits that would be transmitted
; on a single row.  This is more human readable than putting all of the bits
; together and ending up with a string of nonsense.
EE_MEMORY_SIZE      DE .11
EE_CLOCKS_PER_BIT   DE .64
EE_TAG_MODE         DE TAG_MODE_CODING_MANCHESTER
EE_RFID_MEMORY      DE  0x0a, 0x09, 0x0c, 0x0a, 0x0c, 0x18, 0x0c, 0x18, 0x05, 0x00, 0x00
                    DE  0x0f, 0x09, 0x0c, 0x11, 0x0c, 0x0a, 0x05, 0x00, 0x0c, 0x09, 0x1c
                    DE  0x0c, 0x03, 0x0c, 0x0a, 0x0c, 0x1b, 0x0c, 0x1e, 0x0c, 0x1d, 0x1c
                    DE  0x05, 0x18, 0x05, 0x00, 0x05, 0x05, 0x0c, 0x05, 0x0f, 0x0a, 0x14
                    DE  0x0c, 0x1d, 0x0c, 0x1d, 0x0c, 0x12, 0x05, 0x00, 0x0f, 0x0f, 0x1a
                    DE  0x0f, 0x0a, 0x0f, 0x14, 0x05, 0x00, 0x0c, 0x11, 0x0c, 0x0a, 0x00
                    DE  0x0f, 0x05, 0x0c, 0x0a, 0x05, 0x05, 0x05, 0x00, 0x0c, 0x03, 0x06
                    DE  0x0c, 0x1d, 0x0c, 0x09, 0x05, 0x00, 0x0f, 0x05, 0x0c, 0x0a, 0x1c
                    DE  0x0c, 0x06, 0x0c, 0x0a, 0x0c, 0x12, 0x0f, 0x0c, 0x0c, 0x0a, 0x16
                    DE  0x05, 0x00, 0x0f, 0x09, 0x0c, 0x11, 0x0c, 0x0a, 0x05, 0x00, 0x1c
                    DE  0x0f, 0x05, 0x0c, 0x0a, 0x0f, 0x0f, 0x0c, 0x03, 0x0f, 0x05, 0x08
                    DE  0x0c, 0x09, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x04
                    DE  0x0c, 0x05, 0x0f, 0x0a, 0x0c, 0x1d, 0x0c, 0x1d, 0x0c, 0x12, 0x12
                    DE  0x0c, 0x05, 0x0f, 0x0a, 0x0c, 0x1d, 0x0c, 0x1d, 0x0c, 0x12, 0x12
                    DE  0x0c, 0x05, 0x0f, 0x0a, 0x0c, 0x1d, 0x0c, 0x1d, 0x0c, 0x12, 0x12
                    DE  0x0c, 0x05, 0x0f, 0x0a, 0x0c, 0x1d, 0x0c, 0x1d, 0x0c, 0x12, 0x12

END

