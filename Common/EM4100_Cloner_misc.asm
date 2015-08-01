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


	#include "EM4100_Cloner_misc.inc"


	GLOBAL	_writeEEPROM, _readEEPROM , _pauseWx10us, _pauseWx1ms
	GLOBAL	_nibbleHex2ASCII, _ASCII2nibbleHex, _ASCII2byteHex
	GLOBAL	PARAM1



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                VARIABLES                                   ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	UDATA

TMP		RES 1
TMP2	RES 1

	UDATA_SHR

PARAM1	RES	1
	
	

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                  CODE                                      ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	CODE






;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _nibbleHex2ASCII                                              ;
;    Desc.:     Transform an hex digit (4 bits) to an ASCII char               ;
;    Params.:   W -> hex digit                                                 ;
;    Returns:   W -> ASCII char                                                ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



_nibbleHex2ASCII
	

	ANDLW	0x0F							; Take the low nibble

	ADDLW	'0'
	MOVWF	TMP
	
	SUBLW	'9'
	BTFSC	STATUS, C
	GOTO	_nibbleHex2ASCII_exit

	MOVLW	'A'-'9'-.1
	ADDWF	TMP, F

_nibbleHex2ASCII_exit

	MOVFW	TMP
	RETURN



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _ASCII2byteHex                                                 ;
;    Desc.:     Transform two hex digit represented in ASCII to byte           ;
;    Params.:   W -> low nibble hex digit in ASCII                             ;
;               PARAM1 -> high nibble                                          ;
;    Returns:   W ->                                                           ;
;    Vars:      TMP2                                                            ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



_ASCII2byteHex
	
	
	CALL	_ASCII2nibbleHex
	MOVWF	TMP2
	
	MOVFW	PARAM1
	CALL	_ASCII2nibbleHex
	
	SWAPF	TMP2, F
	IORWF	TMP2, F
	SWAPF	TMP2, W

	RETURN	


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _ASCII2nibbleHex                                               ;
;    Desc.:     Transform an hex digit represented in ASCII to a nibble        ;
;    Params.:   W -> hex digit in ASCII                                        ;
;    Returns:   W ->                                                           ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;



_ASCII2nibbleHex
	
	

	MOVWF	TMP								; Backup

	MOVLW	'0' 
	SUBWF	TMP, F
	MOVFW	TMP							
	
	SUBLW	.9								; Check if W<=9
	BTFSS	STATUS, C
	GOTO	$+3

	; W<9
	MOVFW	TMP
	RETURN
	
	MOVLW	'A'-'0'
	SUBWF	TMP, F
	MOVFW	TMP

	SUBLW	.5								; Check if W<=5 (0x0A to 0x0F)
	BTFSS	STATUS, C
	RETLW	0

	MOVFW	TMP
	ADDLW	.10
	RETURN
	



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _pauseWx10us                                                    ;
;    Desc.:     Wait W*10uS + 5 uS                                             ;
;    Params.:   W -> delay in 10uS                                             ;
;    Vars:      TMP                                                            ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_pauseWx10us

	MOVWF TMP
	
	GOTO	$+1
	GOTO	$+1
	GOTO	$+1	
	NOP
	DECFSZ	TMP, F
	GOTO	$-5	

	RETURN



;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _pauseWx1ms                                                     ;
;    Desc.:     Wait W*10uS + 5 uS                                             ;
;    Params.:   W -> delay in 10uS                                             ;
;    Vars:      TMP, TMP2                                                      ;
;                                                                              ;
;    Notes:                                                                    ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_pauseWx1ms


	MOVWF	TMP2

	MOVLW 	.100
	MOVWF	TMP
	
	GOTO	$+1
	GOTO	$+1
	GOTO	$+1	
	NOP
	DECFSZ	TMP, F
	GOTO	$-5

	DECFSZ	TMP2, F
	GOTO	$-9

	RETURN




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _readEEPROM                                                    ;
;    Desc.:     Read the EEPROM                                               ;
;    Params.:   W -> EEPROM address to read                                    ;
;    Return:    W -> readed value                                              ;
;    Vars:      TMP, TMP2                                                      ;
;                                                                              ;
;    Notes: This function doesn't affect the STATUS register                   ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_readEEPROM 

	; Store de W register (EEPROM Address) into TMP
	MOVWF	TMP

	; Store the STATUS register into TMP2
	MOVFW	STATUS	
	MOVWF	TMP2

	; Select the EEPROM ADDRESS
	MOVFW	TMP
	BANKSEL	EEADR
	MOVWF	EEADR

	; Reading...
	BSF		EECON1, RD
	
	; Store the readed data in TMP
	MOVF	EEDAT, W
	BANKSEL	TMP
	MOVWF	TMP

	; Restore the STATUS register 
	MOVF	TMP2, W
	MOVWF	STATUS

	; Store the readed value into W
	MOVF	TMP, W

	RETURN




;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;                                                                            ;;
;    Function:  _writeEEPROM                                                   ;
;    Desc.:     Write the EEPROM                                              ;
;    Params.:   W -> Data to write                                             ;
;               PARAM1 -> EEPROM address to write                              ;
;    Vars:      TMP, TMP2                                                      ;
;                                                                              ;
;    Notes: This function doesn't affect the STATUS register                   ; 
;;                                                                            ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

_writeEEPROM

	; Store the W register (DATA) into TMP 
	MOVWF	TMP

	; Store the STATUS register into TMP2
	MOVF 	STATUS, W
	MOVWF	TMP2

	; Recover the data and load it into the EEDATA register
	MOVF	TMP, W
	BANKSEL	EEDATA
	MOVWF	EEDATA

	; Recover the EEPROM Address and load it into EEADR
	BANKSEL	PARAM1
	MOVFW	PARAM1
	BANKSEL EEADR
	MOVWF	EEADR


	; Start the write
	BSF		EECON1,WREN 
	MOVLW	0x55 
	MOVWF	EECON2 
	MOVLW	0xAA 
	MOVWF	EECON2 
	BSF		EECON1,WR 

	; Wait until the data is written
	BTFSC	EECON1, WR
	GOTO	$-1

	
	BANKSEL	TMP2

	; Recover the STATUS register
	MOVFW	TMP2
	MOVWF	STATUS


	RETURN

	
	END



