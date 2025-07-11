;	PAGE
;	SBTTL "--- MAIN LOOP ---"

MLOOP:
        DEC     RAND2                             ; RANDOMNESS
        DEC     RAND2

        CLR     ARGCNT                            ; RESET # ARGUMENTS
        JSR     NEXTPC                            ; GET NEXT Z-BYTE
        STA     OPCODE                            ; SAVE OPCODE

        IF      DEBUG = 1
            LDB     #'0'
            JSR     DOBUG
            LDA     OPCODE
        ENDIF

        LBPL    OP2                               ; 2-OP IF POSITIVE
        CMPA    #176
        BLO     OP1                               ; IT'S A 1-OP
        CMPA    #192
        BLO     OP0                               ; IF NOT A 0-OP ...

; HANDLE AN X-OP

OPEXT:
        JSR     NEXTPC                            ; GET ARGUMENT BYTE
        STA     TEMP2                             ; HOLD IT HERE
        CLR     TEMP2+1                           ; INIT LOOP INDEX
        BRA     OPX1

OPX0:
        LDA     TEMP2                             ; GRAB ARG BYTE
        ASLA                                      ; SHIFT TO BITS 7 & 6
        ASLA
        STA     TEMP2                             ; SAVE RESULT

OPX1:
        ANDA    #%11000000                        ; MASK OUT GARBAGE
        BNE     OPX2
        JSR     GETLNG                            ; 00 = LONG IMMEDIATE
        BRA     OPXNXT

OPX2:
        CMPA    #%01000000
        BNE     OPX3
        JSR     GETSHT                            ; 01 = SHORT IMMEDIATE
        BRA     OPXNXT

OPX3:
        CMPA    #%10000000
        BNE     OPX4                              ; 11 = NO MORE VARIABLES
        JSR     GETVAR                            ; 10 = VARIABLE

OPXNXT:
        LDB     TEMP2+1                           ; GET INDEX
        LDX     #ARG1                             ; BASE ADDR OF ARGS
        ABX                                       ; ADD OFFSET IN B
        LDD     TEMP                              ; GRAB THE ARGUMENT'S VALUE
        STD     ,X                                ; AND SAVE IT
        INC     ARGCNT                            ; KEEP TRACK
        INC     TEMP2+1                           ; UPDATE
        INC     TEMP2+1                           ; ARGUMENT INDEX
        LDA     TEMP2+1                           ; DONE 4 ARGS YET?
        CMPA    #8
        BLO     OPX0                              ; NO, KEEP GRABBING

; DISPATCH THE X-OP

OPX4:
        LDB     OPCODE                            ; RETRIEVE THE OPCODE
        CMPB    #224                              ; IS IT AN EXTENDED 2-OP?
        LBLO    OP2EX                             ; YES, HANDLE LIKE A 2-OP
        ANDB    #%00011111                        ; ELSE ISOLATE OP BITS
        CMPB    #NOPSX                            ; COMPARE TO LEGAL # OF X-OPS
        BLO     DISPX                             ; CONTINUE IF OKAY

; *** ERROR #1 -- ILLEGAL X-OP ***

        LDA     #1
        JSR     ZERROR

DISPX:
        LDX     #OPTX                             ; X-OP DISPATCH TABLE
DODIS:
        ASLB                                      ; FORM A WORD-OFFSET INTO IT
        ABX                                       ; ADD THE OFFSET

        IF      DEBUG
            PSHS    X
            LDB     #'1'
            JSR     DOBUG
            PULS    X
        ENDIF

        JSR     [,X]                              ; HANDLE THE OPCODE
        JMP     MLOOP                             ; AND GO BACK FOR ANOTHER

; HANDLE A 0-OP

OP0:
        LDX     #OPT0                             ; 0-OP DISPATCH TABLE
        LDB     OPCODE                            ; FETCH OPCODE
        ANDB    #%00001111                        ; ISOLATE OP BITS
        CMPB    #NOPS0                            ; OPCODE OUT OF RANGE?
        BLO     DODIS                             ; NO, GO DISPATCH IT

; *** ERROR #2 -- ILLEGAL 0-OP ***

        LDA     #2
        JSR     ZERROR

; HANDLE A 1-OP

OP1:
        ANDA    #%00110000                        ; ISOLATE ARG BITS
        BNE     OP1A
        JSR     GETLNG                            ; 00 = LONG IMMEDIATE
        BRA     OP1EX

OP1A:
        CMPA    #%00010000
        BNE     OP1B
        JSR     GETSHT                            ; 01 = SHORT IMMEDIATE
        BRA     OP1EX

OP1B:
        CMPA    #%00100000
        BEQ     OP1C

; *** ERROR #3 -- ILLEGAL 1-OP ***

BADOP1:
        LDA     #3
        JSR     ZERROR

OP1C:
        JSR     GETVAR                            ; 10 = VARIABLE

OP1EX:
        LDD     TEMP
        STD     ARG1                              ; GRAB THE ARGUMENT
        INC     ARGCNT                            ; ONE ARGUMENT
        LDX     #OPT1                             ; ADDR OF 1-OP DISPATCH TABLE
        LDB     OPCODE                            ; RESTORE OPCODE
        ANDB    #%00001111                        ; ISOLATE OP BITS
        CMPB    #NOPS1                            ; IF OPCODE OUT OF RANGE,
        BHS     BADOP1                            ; REPORT IT
        BRA     DODIS                             ; ELSE DISPATCH THE 1-OP

; HANDLE A 2-OP

OP2:
        ANDA    #%01000000                        ; ISOLATE 1ST ARG BIT
        BNE     OP2A
        JSR     GETSHT                            ; 0 = SHORT IMMEDIATE
        BRA     OP2B

OP2A:
        JSR     GETVAR                            ; 1 = VARIABLE

OP2B:
        LDD     TEMP                              ; GRAB VALUE
        STD     ARG1                              ; SAVE IN ARG1
        INC     ARGCNT

        LDA     OPCODE                            ; RESTORE OPCODE
        ANDA    #%00100000                        ; ISOLATE 2ND ARG BIT
        BNE     OP2C
        JSR     GETSHT                            ; 0 = SHORT IMMEDIATE
        BRA     OP2D

OP2C:
        JSR     GETVAR                            ; 1 = VARIABLE

OP2D:
        LDD     TEMP                              ; GRAB 2ND VALUE
        STD     ARG2                              ; STORE AS ARG2
        INC     ARGCNT

OP2EX:
        LDX     #OPT2                             ; ADDR OF 2-OP DISPATCH TABLE
        LDB     OPCODE                            ; RESTORE YET AGAIN
        ANDB    #%00011111                        ; ISOLATE OP BITS
        CMPB    #NOPS2                            ; OPCODE IN RANGE?
        LBLO    DODIS                             ; YES, GO DISPATCH IT

; *** ERROR #4 -- ILLEGAL 2-OP ***

BADOP2:
        LDA     #4
        JSR     ZERROR
