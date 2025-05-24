;________________________________________________________________________________________________________________________________
;
;	6809PC CUBIX Boot loader
;
; DWERNER 05/17/2025 	Initial
;________________________________________________________________________________________________________________________________

DEFAULT_IO_BASE = $E000                           ; BIOS DEFAULT IO LOCATION
MMU_ACT_TASK    = $FE0+DEFAULT_IO_BASE
MMU_MAP_SETUP   = $FE1+DEFAULT_IO_BASE
MMU_ENABLE      = $FE2+DEFAULT_IO_BASE
MMU_TASK_EDIT   = $FD0+DEFAULT_IO_BASE

IO_BASE         = $1000                           ; NEW IO LOCATION
LMMU_ACT_TASK   = $FE0+IO_BASE
LMMU_MAP_SETUP  = $FE1+IO_BASE
LMMU_ENABLE     = $FE2+IO_BASE
LMMU_TASK_EDIT  = $FD0+IO_BASE


        ORG     $2000

;__CUBIX BOOT________________________________________________________________________________________
; PAGER_INIT
        LDA     #$00                              ; ENSURE MMU IS DISABLED (SHOULD BE ALREADY, BUT . . . )
        STA     MMU_ENABLE
        LDA     #$01
        STA     MMU_MAP_SETUP                     ; Fill TASK 1
        BSR     INITPAGE                          ; FILL TASK 1 WITH DEFAULT MAP
        LDA     #$12                              ; 0C: 12 RAM page 12XXX
        STA     MMU_TASK_EDIT+$0C
        LDA     #$13                              ; 0D: 13 RAM page 13XXX
        STA     MMU_TASK_EDIT+$0D

        LDA     #$00
        STA     MMU_MAP_SETUP                     ; Then do task 0
        BSR     INITPAGE                          ; FILL TASK 0 WITH DEFAULT MAP
        LDA     #$00
        STA     MMU_ACT_TASK                      ; SET ACTIVE TASK TO 00
        LDA     #$01
        STA     MMU_ENABLE                        ; ENABLE MMU --- FEEEEEL THE POOOOWERRRR
        BRA     COPYOS
INITPAGE:
        LDX     #MMU_TASK_EDIT
        LDA     #00
!
        STA     ,X+                               ; CREATE A 1:1 MAP OF BANK
        INCA
        CMPA    #$10
        BNE     <
        LDA     #$0E                              ; BUT, 01 is IO SHADOW
        STA     MMU_TASK_EDIT+$01
        LDA     #$10                              ; 0E: 10 RAM page 10XXX
        STA     MMU_TASK_EDIT+$0E
        LDA     #$11                              ;  0F: 11 RAM page 11XXX
        STA     MMU_TASK_EDIT+$0F
        RTS

COPYOS:

; copy Cubix to proper bank
        LDX     #$2200
        LDY     #$E000
LOOP:
        LDA     ,X+                               ;MOVE IT
        STA     ,Y+                               ;MOVE IT
        CMPY    #$0000                            ;AT END?
        BNE     LOOP                              ;CONTINUE

; copy Drivers to proper bank

        LDA     #$01
        STA     LMMU_ACT_TASK                     ; SET ACTIVE TASK TO 01
        LDX     #$4200
        LDY     #$C100

LOOP1:
        LDA     ,X+                               ;MOVE IT
        STA     ,Y+                               ;MOVE IT
        CMPY    #$DFFF                            ;AT END?
        BNE     LOOP1                             ;CONTINUE

;* Setup Memory Banks  (page out ROM)

        LDA     #$00
        STA     LMMU_ACT_TASK                     ; SET ACTIVE TASK TO 00

; Boot
        JMP     $E108
