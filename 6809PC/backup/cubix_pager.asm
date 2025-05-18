;__pager_________________________________________________________________________________________________________________________
;
; 	Duodyne Memory page management code
;
;	Entry points:
;		PAGER_INIT          - called during OS init
;________________________________________________________________________________________________________________________________
;
;  The 6809PC has a flexible hardware MMU. There are 64 programmable task contexts, each with 16 4K banks ($BXXX).
;  The MMU has several Registers.
;     $xFE0- Write only-Task Register, Sets which context is active, when the mmu is enabled (0-63)
;     $xFE1- Write only-Setup Register, Sets which context is being setup (exposed in the edit window) (0-63)
;     $xFE2- Write only-Enable Register 0=MMU Disabled, 1=MMU Enabled
;     $xFE4- Read Only- Active Task Register (only lower 6 bits)
;     $xFE6- Read Only- hit ISA TC Bit
;     $xFE7- Read Only- Current IO Page (only lower 4 bits)
;
;     $xfDx- read or write task edit window
;
;________________________________________________________________________________________________________________________________
;
; MMU
;
; SETUP:
; 	TASK 0, NORMAL OPERATION
;               0: 00 RAM page 00XXX
;               1: 0E IO SHADOW (RAM PAGE 0EXXXX)
;               2: 02 RAM page 02XXX
;               3: 03 RAM page 03XXX
;               4: 04 RAM page 04XXX
;               5: 05 RAM page 05XXX
;               6: 06 RAM page 06XXX
;               7: 07 RAM page 07XXX
;               8: 08 RAM page 08XXX
;               9: 09 RAM page 09XXX
;               A: 0A RAM page 0AXXX
;               B: 0B RAM page 0BXXX
;               C: 0C RAM page 0CXXX
;               D: 0D RAM page 0DXXX
;               E: 10 RAM page 10XXX
;               F: 11 RAM page 11XXX
;
;       TASK 1, ADDITIONAL DRIVERS PAGED INTO C000-D000
;               0: 00 RAM page 00XXX
;               1: 0E IO SHADOW (RAM PAGE 0EXXXX)
;               2: 02 RAM page 02XXX
;               3: 03 RAM page 03XXX
;               4: 04 RAM page 04XXX
;               5: 05 RAM page 05XXX
;               6: 06 RAM page 06XXX
;               7: 07 RAM page 07XXX
;               8: 08 RAM page 08XXX
;               9: 09 RAM page 09XXX
;               A: 0A RAM page 0AXXX
;               B: 0B RAM page 0BXXX
;               C: 12 RAM page 12XXX
;               D: 13 RAM page 13XXX
;               E: 10 RAM page 10XXX
;               F: 11 RAM page 11XXX
;
;	TASKS 2-63 -- OPEN FOR OS/USER USE
;_______________________________________________________________


MMU_ACT_TASK    = $FE0+CUBIX_IO_BASE
MMU_MAP_SETUP   = $FE1+CUBIX_IO_BASE
MMU_ENABLE      = $FE2+CUBIX_IO_BASE
MMU_TASK_EDIT   = $FE2+CUBIX_IO_BASE


; CODE FOR PAGER OPERATIONS
MD_PAGERA:
; CODE TO CALL A "FAR FUNCTION"
; THIS CHANGES PAGES AND THEN CALLS THE DISPATCHER
        STD     >PAGER_D                          ; SAVE 'D'
        STX     >PAGER_X                          ; SAVE 'X'
        STY     >PAGER_Y                          ; SAVE 'Y'
        STU     >PAGER_U                          ; SAVE 'U'
        STS     >PAGER_S                          ; SAVE STACK
        LDS     #PAGER_STACK                      ; SET TEMP STACK

        LDA     #$01
        STA     MMU_ACT_TASK                      ; SET ACTIVE TASK TO 01

        JSR     BANKED_DRIVER_DISPATCHER

        LDA     #$00
        STA     MMU_ACT_TASK                      ; SET ACTIVE TASK TO 00

        LDS     >PAGER_S                          ; RESTORE STACK
        LDX     >PAGER_X                          ; RESTORE 'X'
        LDY     >PAGER_Y                          ; RESTORE 'Y'
        LDU     >PAGER_U                          ; RESTORE 'U'
        LDD     >PAGER_D                          ; RESTORE 'D'
        RTS
