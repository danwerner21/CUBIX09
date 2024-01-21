;__pager_________________________________________________________________________________________________________________________
;
; 	Duodyne Memory page management code
;
;	Entry points:
;		PAGER_INIT          - called during OS init
;________________________________________________________________________________________________________________________________
;
;  The Duodyne system has a straight-forward memory banking scheme.
;  There are four 16K areas $0000-$3FFF, $4000-$7FFF, $8000-$BFFF and $C000-$FFFF.
;  Each 16K area can be assigned to any 16K block in the system from $00:0000 to $3F:0000 in physical ram space
;  Block $00 is $00:0000-$00:3FFF, 01 is $00:4000-$00:7FFF  . . .
;  Block $10 is $04:0000-$04:3FFF, 11 is $04:4000-$04:7FFF  . . .
;     and so on . . . .
;  Block $FF is $3F:C000-$3F:FFFF
;
;  Blocks $00-$7F are ROM (see ROMRAM card for design)
;  Blocks $80-$FF are RAM (see ROMRAM card for design)
;
;  Block $03 is the on-board ROM and the IO Space
;  ROM is $00:E000-$FFFF
;  IO is  $00:DF00-$00:DFFF
;
;  Typically Cubix Lives in RAM BANKS 0=$80,1=$81,2=$82,3=$83
;  Cubix Drivers live in 0=$80,1=$84,2=$85,3=$03
;  Bank 0 ($80 - $20:0000-$20:3FFF) is shared between Drivers and OS
;
;
; Banking is enabled by /OUT1 on the UART
;
;
;
BANK00          EQU $DF50
BANK40          EQU $DF51
BANK80          EQU $DF52
BANKC0          EQU $DF53
;
PAGEUART4       EQU $DF5C                         ; INT and Bank CONTROL
;*

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

        LDA     #$84
        STA     BANK40
        LDA     #$85
        STA     BANK80

        JSR     BANKED_DRIVER_DISPATCHER

        LDA     #$81
        STA     BANK40
        LDA     #$82
        STA     BANK80

        LDS     >PAGER_S                          ; RESTORE STACK
        LDX     >PAGER_X                          ; RESTORE 'X'
        LDY     >PAGER_Y                          ; RESTORE 'Y'
        LDU     >PAGER_U                          ; RESTORE 'U'
        LDD     >PAGER_D                          ; RESTORE 'D'
        RTS
