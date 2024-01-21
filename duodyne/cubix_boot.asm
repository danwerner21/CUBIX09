;________________________________________________________________________________________________________________________________
;
;	Duodyne CUBIX Boot loader
;
; DWERNER 01/20/2024 	Initial
;________________________________________________________________________________________________________________________________
BANK00          EQU $DF50
BANK40          EQU $DF51
BANK80          EQU $DF52
BANKC0          EQU $DF53
;
PAGEUART4       EQU $DF5C                         ; INT and Bank CONTROL

        ORG     $1000
;* Setup Memory Banks  (page out ROM)
        LDA     #$81
        STA     BANK40
        LDA     #$82
        STA     BANK80
        LDA     #$83
        STA     BANKC0

; copy Cubix to proper bank
        LDX     #$1200
        LDY     #$E000
LOOP:
        LDA     ,X+                               ;MOVE IT
        STA     ,Y+                               ;MOVE IT
        CMPY    #$0000                            ;AT END?
        BNE     LOOP                              ;CONTINUE

; copy Drivers to proper bank
        LDA     #$85
        STA     BANK80
        LDX     #$3300
        LDY     #$8800
LOOP1:
        LDA     ,X+                               ;MOVE IT
        STA     ,Y+                               ;MOVE IT
        CMPY    #$BF00                            ;AT END?
        BNE     LOOP1                             ;CONTINUE

;* Setup Memory Banks  (page out ROM)
        LDA     #$81
        STA     BANK40
        LDA     #$82
        STA     BANK80
        LDA     #$83
        STA     BANKC0

; Boot
        JMP     $E108


.END
