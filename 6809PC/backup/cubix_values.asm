;________________________________________________________________________________________________________________________________
;
;	6809PC Cubix System storage locations
;
;  DWERNER 5/17/2025 	Initial
;________________________________________________________________________________________________________________________________
; $0000-$00FF DRIVER/PAGER STACK
; $0100-$01FF OS Driver Storage
farpointer      = $0101
DISKERROR       = $0103
CURRENTDEVICE   = $0104
CURRENTSLICE    = $0105
CURRENTCYL      = $0106
CURRENTSEC      = $0107
CURRENTHEAD     = $0108
PAGER_D         = $0109
PAGER_X         = $010B
PAGER_Y         = $010D
PAGER_S         = $010F
PAGER_U         = $0111


; $200-$3FF Host Buffer Driver Storage
HSTBUF          = $0200
; $400-$7FF OS LOCAL STORAGE
; $1000-$1FFF Hardware Access Window
CUBIX_IO_BASE   = $1000                           ; BIOS DEFAULT IO LOCATION
; $2000-$DFFF User RAM
; $E000-$FFFF CUBIX

BANKED_DRIVER_DISPATCHER = $C100
