;__pager_________________________________________________________________________________________________________________________
;
; 	Nhyodyne Memory page management code
;
;	Entry points:
;		PAGER_INIT          - called during OS init
;________________________________________________________________________________________________________________________________
;
; RAM BANK $0C is RAM area for Drivers
; RAM BANK $0E is operating bank for CUBIX $8000-$FFFF
; RAM BANK $0F is fixed bank $0000-$7FFF
;
; ROM BANKS $00 and $0C-$0F are reserved for ROMWBW code
;
MPCL_ROM        = $057C                           ; ROM MAPPER
MPCL_RAM        = $0578                           ; RAM MAPPER
MD_PAGERA       = $0200                           ; PAGE DRIVER ADDRESS
BANKED_DRIVER_DISPATCHER = $8800
PAGER_STACK     = $02F5
PAGER_U         = $02F6
PAGER_D         = $02F8
PAGER_X         = $02FA
PAGER_Y         = $02FC
PAGER_S         = $02FE
;
;
; ROM MEMORY PAGE CONFIGURATION LATCH CONTROL PORT
;       A15 IS INVERTED FOR THE NYHODYNE 6809 CPU . . .
;	7 6 5 4  3 2 1 0      APPLICABLE TO THE UPPER MEMORY PAGE $8000-$FFFF
;	^ ^ ^ ^  ^ ^ ^ ^
;	: : : :  : : : :--0 = A15 ROM ONLY ADDRESS LINE DEFAULT IS 0 x
;	: : : :  : : :----0 = A16 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : :------0 = A17 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  :--------0 = A18 ROM ONLY ADDRESS LINE DEFAULT IS 0 X
;	: : : :-----------0 = A19 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: : :-------------0 = A20 ROM ONLY ADDRESS LINE DEFAULT IS 0
;	: :---------------0 = ROM BOOT OVERRIDE DEFAULT IS 0
;	:-----------------0 = LOWER PAGE ROM SELECT (0=ROM, 1=NOTHING) DEFAULT IS 0
;
; RAM PAGE CONFIGURATION LATCH CONTROL PORT
;
;	7 6 5 4  3 2 1 0      APPLICABLE TO THE UPPER MEMORY PAGE $8000-$FFFF
;	^ ^ ^ ^  ^ ^ ^ ^
;	: : : :  : : : :--0 = A15 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : : :----0 = A16 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  : :------0 = A17 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :  :--------0 = A18 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : : :-----------0 = A19 RAM ONLY ADDRESS LINE DEFAULT IS 0
;	: : :-------------0 = UNDEFINED DEFAULT IS 0
;	: :---------------0 = RAM BOOT OVERRIDE DEFAULT IS 0
;	:-----------------0 = LOWER PAGE RAM SELECT (0=NOTHING, 1=RAM) DEFAULT IS 0;


;__PAGER_INIT___________________________________________________________________________________________
;
;  INIT -- Copy code into $0200-$02FF for controling banking
;____________________________________________________________________________________________________
PAGER_INIT:
        LDX     #$0000
!
        LDA     md_pagecode,X
        STA     MD_PAGERA,X
        INX
        CMPX    #$0100
        BNE     <
        RTS

; CODE FOR PAGER OPERATIONS
md_pagecode:
; CODE TO CALL A "FAR FUNCTION"
; THIS CHANGES PAGES AND THEN CALLS THE DISPATCHER
        STD     >PAGER_D                          ; SAVE 'D'
        STX     >PAGER_X                          ; SAVE 'X'
        STY     >PAGER_Y                          ; SAVE 'Y'
        STU     >PAGER_U                          ; SAVE 'U'
        STS     >PAGER_S                          ; SAVE STACK
        LDS     #PAGER_STACK                      ; SET TEMP STACK
        LDA     #$8C
        STA     MPCL_RAM
        NOP
        NOP
        JSR     BANKED_DRIVER_DISPATCHER
        LDA     #$8E
        STA     MPCL_RAM
        LDS     >PAGER_S                          ; RESTORE STACK
        LDX     >PAGER_X                          ; RESTORE 'X'
        LDY     >PAGER_Y                          ; RESTORE 'Y'
        LDU     >PAGER_U                          ; RESTORE 'U'
        LDD     >PAGER_D                          ; RESTORE 'D'
        RTS
