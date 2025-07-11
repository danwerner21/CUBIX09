;	PAGE
;	SBTTL "--- Z-STRING HANDLERS ---"

; -----------------
; POINT TO Z-STRING
; -----------------

SETSTR:
        CLRA
        ASL     TEMP+1
        ROL     TEMP
        ROLA
        STA     MPCH
        LDD     TEMP
        STD     MPCM
        CLR     MPCFLG
ZSTEX:
        RTS

; --------------
; PRINT Z-STRING
; --------------

PZSTR:
        CLR     CSPERM                            ; PERMANENT CHARSET
        CLR     STBYTF                            ; RESET STRING BYTE FLAG
        LDA     #$FF
        STA     CSTEMP                            ; NO TEMP CHARSET ACTIVE

PZSTRL:
        JSR     GETZCH                            ; GET A Z-CHARACTER
        BCS     ZSTEX                             ; END OF STRING IF CARRY SET
        STA     MASK                              ; SAVE CHAR HERE
        BEQ     PZSTRS                            ; O = SPACE CHAR
        CMPA    #4                                ; IS THIS AN F-WORD?
        BLO     PZSTRF                            ; APPARENTLY SO
        CMPA    #6                                ; SHIFT CHAR?
        BLO     PZSTRT                            ; YES, CHANGE CHARSET

        JSR     GETMOD
        TSTA                                      ; IS THIS CHARSET 0?
        BNE     PZSTR1                            ; NOPE

; PRINT LOWER-CASE CHAR (CHARSET 0)

        LDA     #$61-6                            ; ASCII "a" MINUS Z-OFFSET
PZSTP0:
        ADDA    MASK                              ; ADD CHARACTER
PZSTP1:
        JSR     COUT                              ; PRINT RESULT
        BRA     PZSTRL                            ; AND FETCH ANOTHER Z-CHAR

; CHARSET 1 OR 2?

PZSTR1:
        CMPA    #1                                ; SET 1?
        BNE     PZSTR2                            ; NOPE, IT'S SET 2

; PRINT UPPER-CASE CHAR (CHARSET 1)

        LDA     #$41-6                            ; ASCII "A" MINUS Z-OFFSET
        BRA     PZSTP0                            ; AND SO ON ...

; DECODE/PRINT CHARSET 2

PZSTR2:
        LDB     MASK                              ; RETRIEVE Z-CHAR
        SUBB    #6                                ; CONVERT TO ZERO-ALIGNED INDEX
        BEQ     PZSTRA                            ; IF ZERO, IT'S "DIRECT" ASCII
        LDX     #CHRTBL                           ; ELSE GET BASE OF DECODE TABLE
        LDA     B,X                               ; GET CHAR FROM TABLE
        BRA     PZSTP1                            ; AND PRINT IT!

; DECODE/PRINT A "DIRECT" ASCII CHAR

PZSTRA:
        JSR     GETZCH                            ; GET NEXT Z-BYTE
        ASLA                                      ; SHIFT INTO POSITION
        ASLA
        ASLA
        ASLA
        ASLA
        STA     MASK                              ; SAVE MSB
        JSR     GETZCH                            ; FETCH LSB
        STA     MASK+1                            ; SAVE THAT, TOO
        LDA     MASK                              ; GET MSB
        ORA     MASK+1                            ; SUPERIMPOSE LSB
        BRA     PZSTP1                            ; AND PRINT RESULT

; PRINT A SPACE

PZSTRS:
        LDA     #$20
        BRA     PZSTP1

; CHANGE CHARACTER SETS

PZSTRT:
        SUBA    #3                                ; CONVERT TO 1 OR 2
        TFR     A,B
        BSR     GETMOD
        BNE     PZSTRP                            ; NO, DO PERMANENT SHIFT
        STB     CSTEMP                            ; JUST A TEMP-SHIFT
        BRA     PZSTRL

PZSTRP:
        STB     CSPERM                            ; PERMANENT SHIFT
        CMPA    CSPERM                            ; NEW SET SAME AS OLD?
        BEQ     PZSTRL                            ; YES, EXIT
        CLR     CSPERM                            ; ELSE BACK TO SET 0
        BRA     PZSTRL                            ; BEFORE FINISHING

; HANDLE AN F-WORD

PZSTRF:
        DECA                                      ; CONVERT TO 0-2
        LDB     #64                               ; TIMES 64
        MUL
        STB     PZSTFO                            ; SAVE FOR LATER
        JSR     GETZCH                            ; GET F-WORD INDEX
        TFR     A,B                               ; MOVE IT
        ASLB                                      ; FORM WORD-ALIGNED INDEX
        ADDB    PZSTFO                            ; ADD OFFSET
        LDX     FWORDS                            ; GET BASE ADDR OF FWORDS TABLE
        ABX                                       ; ADD THE OFFSET
        LDD     ,X                                ; GET THE FWORD POINTER
        STD     TEMP                              ; AND SAVE IT

; SAVE THE STATE OF CURRENT Z-PRINT

        LDA     MPCH
        PSHS    A
        LDA     CSPERM
        LDB     STBYTF
        LDX     MPCM
        LDY     ZSTWRD
        PSHS    Y,X,B,A

        JSR     SETSTR                            ; PRINT THE F-WORD
        JSR     PZSTR                             ; POINTED TO BY [TEMP]

; RESTORE THE OLD Z-STRING

        PULS    Y,X,B,A
        STY     ZSTWRD
        STX     MPCM
        STB     STBYTF
        STA     CSPERM
        PULS    A
        STA     MPCH

        LDA     #$FF
        STA     CSTEMP                            ; DISABLE TEMP CHARSET
        CLR     MPCFLG                            ; MPC HAS CHANGED!
        JMP     PZSTRL                            ; CONTINUE INNOCENTLY

; ----------------------
; RETURN CURRENT CHARSET
; ----------------------

GETMOD:
        LDA     CSTEMP
        BPL     GM
        LDA     CSPERM
        RTS

GM:
        LDB     #$FF
        STB     CSTEMP
        RTS

; ---------------
; GET NEXT Z-CHAR
; ---------------

GETZCH:
        LDA     STBYTF                            ; WHICH BYTE?
        BPL     GTZ0
        COMB                                      ; SET CARRY
        RTS                                       ; TO INDICATE "NO MORE CHARS"

GTZ0:
        BNE     GETZH1                            ; NOT FIRST CHAR
        INC     STBYTF
        JSR     GETWRD
        LDD     TEMP
        STD     ZSTWRD
        LSRA
        LSRA
GTEXIT:
        ANDA    #%00011111
        CLRB                                      ; CLEAR CARRY
        RTS

GETZH1:
        DECA
        BNE     GETZH2                            ; MUST BE LAST CHAR
        LDA     #2
        STA     STBYTF
        LDD     ZSTWRD
        LSRA
        RORB
        LDA     ZSTWRD
        LSRA
        LSRA
        RORB
        LSRB
        LSRB
        LSRB
GETZH3:
        TFR     B,A                               ; EXPECTED HERE
        BRA     GTEXIT

GETZH2:
        CLR     STBYTF
        LDD     ZSTWRD
        BPL     GETZH3
        COM     STBYTF                            ; INDICATE END OF STRING
        BRA     GETZH3

; -------------------
; CONVERT TO Z-STRING
; -------------------

CONZST:
        LDD     #$0505                            ; FILL OUTPUT BUFFER
        STD     ZSTBUO                            ; WITH PAD CHARS
        STD     ZSTBUO+2
        STD     ZSTBUO+4

        INCA                                      ; = 6
        STA     MASK                              ; INIT CHAR COUNT

        CLR     VAL                               ; RESET OUTPUT AND
        CLR     TEMP                              ; INPUT INDEXES

CNZSL1:
        LDB     TEMP
        INC     TEMP
        LDX     #ZSTBUI                           ; POINT TO INPUT BUFFER
        LDA     B,X                               ; GRAB NEXT CHAR
        STA     MASK+1                            ; SAVE IT HERE
        BNE     CNZSL2                            ; IF CHAR WAS ZERO,
        LDA     #5                                ; USE A Z-PAD
        BRA     CNZSLO

CNZSL2:
        LDA     MASK+1
        JSR     ZCHRCS                            ; WHICH CHARSET TO USE?
        TSTA
        BEQ     CNZSLC                            ; IF CHARSET 0, USE LOWER CASE
        ADDA    #3
        LDB     VAL                               ; OUTPUT A TEMP SHIFT
        LDX     #ZSTBUO
        STA     B,X
        INC     VAL
        DEC     MASK
        LBEQ    CNZSLE

CNZSLC:
        LDA     MASK+1
        JSR     ZCHRCS
        DECA
        BPL     CNZSC1                            ; NOT CHARSET 0!
        LDA     MASK+1
        SUBA    #$61-6                            ; ASCII "a" MINUS 6

CNZSLO:
        LDB     VAL
        LDX     #ZSTBUO
        STA     B,X
        INC     VAL
        DEC     MASK
        BEQ     CNZSLE                            ; ALL FINISHED
        BRA     CNZSL1                            ; ELSE LOOP BACK FOR MORE

CNZSC1:
        BNE     CNZSC3                            ; MUST BE CHARSET 3
        LDA     MASK+1
        SUBA    #$41-6                            ; ASCII "A" MINUS 6
        BRA     CNZSLO

CNZSC3:
        LDA     MASK+1
        JSR     CNZS2M                            ; IS IT IN TABLE?
        BNE     CNZSLO                            ; YES, OUTPUT THE CHAR
        LDA     #6                                ; ELSE IT'S A "DIRECT" ASCII CHAR
        LDB     VAL
        LDX     #ZSTBUO
        STA     B,X                               ; SEND "DIRECT" TO OUTPUT
        INC     VAL
        DEC     MASK
        BEQ     CNZSLE                            ; NO MORE ROOM!

; CONVERT CHAR TO 2-BYTE DIRECT ASCII

        LDA     MASK+1
        LSRA
        LSRA
        LSRA
        LSRA
        LSRA
        ANDA    #%00000011
        LDB     VAL
        LDX     #ZSTBUO
        STA     B,X
        INC     VAL
        DEC     MASK
        BEQ     CNZSLE                            ; NO MORE ROOM!
        LDA     MASK+1
        ANDA    #%00011111                        ; FORM 2ND Z-BYTE
        BRA     CNZSLO                            ; AND OUTPUT IT

; ----------------------
; SEARCH CHARSET 3 TABLE
; ----------------------

CNZS2M:
        LDX     #CHRTBL
        LDB     #25
CNLOOP:
        CMPA    B,X
        BEQ     CNOK
        DECB
        BNE     CNLOOP
        RTS                                       ; RETURN ZERO IN B IF NO MATCH

CNOK:
        TFR     B,A                               ; EXPECTED IN [A]
        ADDA    #6                                ; CONVERT TO Z-CHAR
        RTS

; -------------------------
; DETERMINE CHARSET OF CHAR
; -------------------------

ZCHRCS:
        CMPA    #$61                              ; ASCII "a"
        BLO     ZCHR1
        CMPA    #$7B                              ; ASCII "z"+1
        BHS     ZCHR1
        CLRA                                      ; IT'S CHARSET 0
        RTS

ZCHR1:
        CMPA    #$41                              ; ASCII "A"
        BLO     ZCHR2
        CMPA    #$5B                              ; ASCII "Z"+1
        BHS     ZCHR2
        LDA     #1                                ; IT'S CHARSET 1
        RTS

ZCHR2:
        TSTA
        BEQ     ZCHRX                             ; EXIT IF ZERO
        BMI     ZCHRX                             ; OR NEGATIVE
        LDA     #2                                ; ELSE IT'S CHARSET 2
ZCHRX:
        RTS

; ---------------
; CRUSH 6 Z-CHARS
; ---------------

CNZSLE:
        LDD     ZSTBUO                            ; HANDLE 1ST TRIPLET
        ASLB
        ASLB
        ASLB
        ASLB
        ROLA
        ASLB
        ROLA
        ORB     ZSTBUO+2
        STD     ZSTBUO

        LDD     ZSTBUO+3                          ; HANDLE 2ND TRIPLET
        ASLB
        ASLB
        ASLB
        ASLB
        ROLA
        ASLB
        ROLA
        ORB     ZSTBUO+5
        ORA     #%10000000                        ; SET SIGN BIT OF LAST Z-BYTE
        STD     ZSTBUO+2
        RTS

; ----------------------
; CHARSET 2 DECODE TABLE
; ----------------------

CHRTBL:
        FCB     0                                 ; DUMMY BYTE
        FCB     $0D                               ; CARRIAGE RETURN
        FCC     "0123456789.,!?_#"
        FCB     $27                               ; SINGLE QUOTE
        FCB     $22                               ; DOUBLE QUOTE
        FCC     "/\-:()"
