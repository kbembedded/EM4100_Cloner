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



	#IFNDEF	MULTIMAP_INC
	
	#DEFINE MULTIMAP_INC

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;                                                                          ;;;
;;								   DEFINITIONS                                ;;
;;;                                                                          ;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

	
	#DEFINE MAX_MEMORY_SIZE	.16		; Maximal memory size of the RFID tag
	#DEFINE NUM_TAGS .12			; Number of RFID tags


	; TAG modulation modes
	#DEFINE TAG_MODE_CODING_BIT .0
	#DEFINE TAG_MODE_CODING_MANCHESTER b'00000000'
	#DEFINE TAG_MODE_CODING_BIPHASE	b'00000001'
	

	;#DEFINE CAPTURE_MODE_BIT	.7




	#ENDIF