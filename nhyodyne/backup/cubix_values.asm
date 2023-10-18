;________________________________________________________________________________________________________________________________
;
;	Nhyodyne Cubix System storage locations
;
;  DWERNER 10/15/2023 	Initial
;________________________________________________________________________________________________________________________________

MD_PAGERA       = $0200                           ; PAGE DRIVER ADDRESS
PAGER_STACK     = $02F5
PAGER_U         = $02F6
PAGER_D         = $02F8
PAGER_X         = $02FA
PAGER_Y         = $02FC
PAGER_S         = $02FE
CONSOLEDEVICE   = $0100                           ; (BYTE)
DSKY_BUF        = $01EA                           ; (8 BYTES)
DSKY_HEXBUF     = $01F3                           ; (4 BYTES)
DISKERROR       = $01F7                           ; (BYTE)
CURRENTHEAD     = $01F8                           ; (BYTE)
CURRENTCYL      = $01F9                           ; (BYTE)
CURRENTSEC      = $01FA                           ; (BYTE)
CURRENTDEVICE   = $01FB                           ; (BYTE)
CURRENTSLICE    = $01FC                           ; (WORD)
farpointer      = $01FE                           ; (WORD)                      ;
HSTBUF          = $0300

BANKED_DRIVER_DISPATCHER = $8800
