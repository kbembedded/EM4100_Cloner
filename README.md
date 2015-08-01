EM4100 Cloner
=================

This RFID project is the second iteration of the RFID board for DEF CON's DarkNet game.  This project is based on the OPEN RFID tag with resources pulled from t4f.org and kukata86.com.  Envelope detector credit to multiple people listed here: http://playground.arduino.cc/Main/DIYRFIDReader

This project is to create a battery powered RFID cloner that is compatible with LF 125kHz RFID tags, a.k.a. EM4100.  There are 16 slots each able to store a 5 ID.  This device does not clone a tag and reprogram another, it is able to read and clone a tag and then turn around to emulate it to a proper transponder.  There is also a mechanism to manually program an ID to the device via the button and DIP switch.  Any of the 16 slots can have a cloned ID saved, a manually input ID saved, and an ID replayed from.
