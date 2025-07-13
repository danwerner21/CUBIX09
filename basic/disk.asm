;* SAVE
SAVE
        BEQ     SAVERR                            ; BRANCH IF NO ARGUMENT
        LDX     CURLIN                            ; GET CURRENT LINE NUMBER
        CMPX    #$FFFF                            ; ERROR IF NOT DIRECT MODE
        BNE     NONDIRECTSAVE

        JSR     LB156                             ; EVALUATE EXPRESSION
        JSR     LB654                             ; GET THE STRING ARGUMENT (B=LEN, X=ADDRESS)
                                                  ; TURN THE STRING INTO A CUBIX FILENAME (LESS THE EXTENSION)
        CLRA
        STX     TEMPTR
        ADDD    TEMPTR
        TFR     D,Y
        LDA     #$0D
        STA     ,Y
        TFR     X,Y
;
        SWI                                       ; AND OPEN THE FILE FOR WRITE/CREATE
        FCB     11                                ; ERROR OUT IF THE FILENAME IS NOT VALID
        BNE     DSKABORT
        LDD     #$4241                            ;'BA' GET FIRST PORTION
        STD     ,X                                ;SAVE IT
        LDA     #'S'                              ;LAST CHAR
        STA     2,X                               ;WRITE IT

;
        LDX     #PROGST                           ; BEGINNING OF BASIC PROGRAM
        LDD     VARTAB
        SUBD    #PROGST                           ; D CONTAINS LENGTH OF BASIC PROGRAM

        CLC
        RORA
        TFR     A,B
        CLRA
        INCB                                      ; D NOW CONTAINS NUMBER OF BLOCKS OF BASIC PROGRAM

        SWI                                       ; SAVE THAT SUCKER
        FCB     54
        BNE     DSKABORT

        JMP     CLEAR                             ; CLEAR ALL VARIABLES

SAVERR:
        JMP     LB277                             ; 'SYNTAX ERROR' IF NOT A TEXT STRING ARGUMENT
DSKABORT:
        LDB     #2*20                             ; 'IO' ERROR
        JMP     LAC46
NONDIRECTSAVE:
        LDB     #2*24                             ; 'DM' ERROR
        JMP     LAC46


;* LOAD
LOAD
        BEQ     SAVERR                            ; BRANCH IF NO ARGUMENT

        JSR     LB156                             ; EVALUATE EXPRESSION
        JSR     LB654                             ; GET THE STRING ARGUMENT (B=LEN, X=ADDRESS)
                                                  ; TURN THE STRING INTO A CUBIX FILENAME (LESS THE EXTENSION)
        CLRA
        STX     TEMPTR
        ADDD    TEMPTR
        TFR     D,Y
        LDA     #$0D
        STA     ,Y
        TFR     X,Y
;
        SWI                                       ; AND OPEN THE FILE
        FCB     11                                ; ERROR OUT IF THE FILENAME IS NOT VALID
        BNE     DSKABORT
        LDD     #$4241                            ;'BA' GET FIRST PORTION
        STD     ,X                                ;SAVE IT
        LDA     #'S'                              ;LAST CHAR
        STA     2,X                               ;WRITE IT

;
        LDX     #PROGST                           ; BEGINNING OF BASIC PROGRAM
        SWI                                       ; LOAD THAT SUCKER
        FCB     53
        BNE     DSKABORT

        LDX     #PROGST                           ; BEGINNING OF BASIC PROGRAM
        INX
        STX     TXTTAB                            ; SET START OF BASIC

!
        CPX     #END_OF_USER_RAM
        BHS     LOADMEMERR
        LDA     ,X+
        CMPA    #$00
        BNE     <
        LDA     ,X+
        CMPA    #$00
        BNE     <

        STX     VARTAB
        JSR     LAD21
        JSR     CLEAR                             ; CLEAR ALL VARIABLES TO RESET MESS MADE BY FCB
        JMP     LAC73                             ; GOTO INPUT LOOP

LOADMEMERR:
        LDB     #2*6                              ; 'OM' ERROR
        JMP     LAC46                             ; JUMP TO ERROR HANDLER
