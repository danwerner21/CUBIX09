;	PAGE
;	SBTTL "--- OBJECT & PROPERTY HANDLERS ---"

PROPB:
        LDA     ARG1+1
        JSR     OBJLOC
        LDX     TEMP
        LDD     7,X
        ADDD    #ZCODE
        STD     TEMP                              ; EXPECTED HERE
        TFR     D,X
        LDB     ,X                                ; GET FIRST BYTE (LENGTH OF DESC)
        ASLB                                      ; WORD-ALIGN IT
        INCB                                      ; AND POINT JUST PAST IT
        RTS

PROPN:
        LDX     TEMP
        ABX
        LDA     ,X
        ANDA    #%00011111
        RTS

PROPL:
        LDX     TEMP
        ABX
        LDA     ,X
        RORA
        RORA
        RORA
        RORA
        RORA
        ANDA    #%00000111
        RTS

PROPNX:
        BSR     PROPL
        STA     VAL
PPX:
        INCB
        DEC     VAL
        BPL     PPX
        INCB
        RTS

FLAGSU:
        LDA     ARG1+1
        JSR     OBJLOC
        LDA     ARG2+1
        CMPA    #16
        BLO     FLGSU1
        SUBA    #16
        LDX     TEMP
        LEAX    2,X
        STX     TEMP

FLGSU1:
        STA     VAL+1
        LDD     #1
        STD     MASK
        LDB     #15
        SUBB    VAL+1

FLGSU2:
        BEQ     FLGSU3
        ASL     MASK+1
        ROL     MASK
        DECB
        BRA     FLGSU2

FLGSU3:
        LDX     TEMP
        LDD     ,X
        STD     VAL
        RTS

OBJLOC:
        LDB     #9                                ; NUMBER IN [A] TIMES 9
        MUL
        ADDD    #53                               ; PLUS 53
        ADDD    ZCODE+ZOBJEC                      ; Z-ADDRESS OF OBJECT TABLE
        ADDD    #ZCODE                            ; FORM ABSOLUTE ADDRESS
        STD     TEMP
        RTS
