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


	#include "EM4100_Cloner_multimap.inc"
	#include "../Common/EM4100_Cloner_io.inc"
	#include "../Common/EM4100_Cloner_misc.inc"
	#include "../Common/EM4100_Cloner_rf.inc"



	EXTERN EE_MEMORY_SIZE, EE_CLOCKS_PER_BIT, EE_TAG_MODE, EE_RFID_MEMORY


	EXTERN	_initIO
	EXTERN	_writeEEPROM, _readEEPROM , _pauseWx10us, _pauseWx1ms
	EXTERN  _initRF, _txManchester1, _txManchester0, _txBiphase1, _txBiphase0
	EXTERN	PARAM1

	EXTERN 	FLAGS, DIP_NIBBLE, RFID_MEMORY

	GLOBAL	_start_PLAY

    #DEFINE CAPTURE            7 ; Flag: If set, we are not using clone function


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	UDATA

		
;RFID_MEMORY		RES 	.16 	; Memory map

									; TAG configuration
CONFIG_TAG_MODE RES 	1			; Tag mode
CONFIG_MEMORY_SIZE RES 	1			; Memory size
CONFIG_CLOCKS_PER_BIT RES 1			; Clocks per bit

TMP_COUNTER		RES 	1			; Tmp counters
BYTE_COUNTER	RES 	1
BIT_COUNTER		RES 	1
	
									; Context vars.
W_TEMP			RES 	1
STATUS_TEMP		RES 	1

TX_BYTE			RES 	1			; Byte transmited


TMP				RES		1



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE


_start_PLAY

    CALL	_loadConfig             ; Load TAG config
    MOVFW   CONFIG_CLOCKS_PER_BIT
    CALL    _initRF                 ; Init RF

_main

    CLRF    TMR0
    CALL    _play_em4100
    GOTO    _main

_play_em4100

	MOVLW	RFID_MEMORY				; INDF points to the beginning of the RFID memory
	MOVWF	FSR

    ; XXX: This can be removed
	;MOVFW	CONFIG_MEMORY_SIZE		; Load the number of bytes to transmit
	MOVLW	.11		; Load the number of bytes to transmit
	MOVWF	BYTE_COUNTER

	;Cabecera
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1
	CALL	_tx1



_byteloop
	
	MOVF    INDF, W					; Get the first byte to transmit
	MOVWF	TX_BYTE

	RLF		TX_BYTE, F				; Rotate left thrice-wise
	RLF		TX_BYTE, F
	RLF		TX_BYTE, F

	MOVLW	.5						
	MOVWF	BIT_COUNTER

_bitloop

	RLF		TX_BYTE,F				; Shift next bit to transmit in to C

	BTFSC	STATUS, C				; Check if the bit is 1 or 0
	CALL	_tx1
	BTFSS	STATUS, C
	CALL	_tx0

	DECFSZ	BIT_COUNTER, F			; Check if more bits are waiting to be transmited
	GOTO	_bitloop

	INCF	FSR, F					; Next byte
	
	DECFSZ	BYTE_COUNTER, F			; Are there more bytes?
	GOTO	_byteloop



	RETURN


_tx1

	; Check the modulation
	;BTFSC	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	;CALL	_txBiphase1

	;BTFSS	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	CALL	_txManchester1

	RETURN



_tx0

	; Check the modulation
	;BTFSC	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	;GOTO	_txBiphase0
	
	;BTFSS	CONFIG_TAG_MODE, TAG_MODE_CODING_BIT
	GOTO	_txManchester0

	RETURN






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _loadConfig                                                    ;
;    Desc.:     Load the tag configuration                                     ;
;    Vars:      CONFIG_TAG_MODE, CONFIG_TAG_REPETITION, CONFIG_MEMORY_SIZE,    ;
;               CONFIG_S_COUNTER                                               ;
;                                                                              ;
;    Notes:                                                                    ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_loadConfig

	

	MOVLW	EE_TAG_MODE			; Read the tag mode
	CALL	_readEEPROM
	MOVWF	CONFIG_TAG_MODE

	MOVLW	EE_MEMORY_SIZE		; Read the memory size
	CALL	_readEEPROM
	MOVWF	CONFIG_MEMORY_SIZE

	MOVLW	EE_CLOCKS_PER_BIT	; Read the clocks per bit
	CALL	_readEEPROM
	MOVWF	CONFIG_CLOCKS_PER_BIT


    INCF    DIP_NIBBLE
    MOVLW   EE_RFID_MEMORY
_adr_loop
    DECF    DIP_NIBBLE, F
    BTFSC   STATUS, Z
    GOTO    _adr_set
    ADDLW   .11
    GOTO    _adr_loop

_adr_set
	CALL	_loadMemoryMap

	RETURN





;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _loadMemoryMap                                                 ;
;    Desc.:     Load the Memory Map from the EEPROM to the RAM                 ;
;    Params.:   W -> EEPROM ADDRESS                                            ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_loadMemoryMap


	MOVWF	BYTE_COUNTER			; Save the EEPROM ADDRESS (W)

	ADDWF	CONFIG_MEMORY_SIZE, W	; Save in TMP the end of the memory map
	MOVWF	TMP					

	MOVLW	RFID_MEMORY				; INDF points at the beginning of the memory map
	MOVWF	FSR

	

_loadMemoryMap_loop

	MOVFW	BYTE_COUNTER			; Read the EEPROM byte
	CALL	_readEEPROM
	MOVWF	INDF					; Store it in the RAM

	INCF	FSR, F					; Point to the next memory map byte 


	INCF	BYTE_COUNTER, F			; Check if we have copied all the bytes
	MOVFW	TMP
	SUBWF	BYTE_COUNTER, W
	BTFSS	STATUS, Z
	GOTO	_loadMemoryMap_loop

	return



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	END

