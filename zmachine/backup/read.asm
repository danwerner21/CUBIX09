;	PAGE
;	SBTTL "--- READ HANDLER ---"

ZREAD:
        JSR     ZUSL                              ; UPDATE STATUS LINE FIRST

        LDD     ARG1                              ; CALC ABSOLUTE ADDRESS
        ADDD    #ZCODE                            ; OF READ BUFFERS
        STD     ARG1
        LDD     ARG2
        ADDD    #ZCODE
        STD     ARG2

        JSR     INPUT                             ; READ LINE; RETURN LENGTH IN A
        STA     MASK                              ; # CHARS IN LINE
        CLR     MASK+1                            ; # CHARS IN CURRENT WORD

        LDX     ARG2                              ; SET # OF WORDS READ
        CLR     1,X                               ; TO ZERO

        LDA     #1                                ; = 1
        STA     STABP                             ; INIT SOURCE TABLE POINTER
        INCA                                      ; = 2
        STA     RTABP                             ; AND RESULT TABLE POINTER

READL:
        LDX     ARG2
        LDA     ,X+                               ; FETCH MAXIMUM # OF WORDS
        CMPA    ,X                                ; COMPARE TO # WORDS READ
        BHS     RL1                               ; STILL ROOM

; *** ERROR #13 -- PARSER OVERFLOW ***

        LDA     #13
        JSR     ZERROR

RL1:
        LDD     MASK                              ; OUT OF CHARS & WORDS?
        BNE     RL2                               ; NOT YET
RDEX:
        RTS                                       ; ELSE SCRAM

RL2:
        LDA     MASK+1                            ; GET CHAR COUNT
        CMPA    #6                                ; 6 CHARS DONE?
        BLO     RL3                               ; NOT YET
        JSR     FLUSHW                            ; ELSE FLUSH WORD

RL3:
        LDA     MASK+1                            ; FIRST CHAR IN WORD?
        BNE     READL2                            ; NOPE

; CLEAR OUT WORD BUFFER [ZSTBUI]

        CLRB                                      ; [A] IS ALREADY ZERO
        STD     ZSTBUI
        STD     ZSTBUI+2
        STD     ZSTBUI+4

        LDB     RTABP
        LDX     ARG2
        ABX
        LDB     STABP
        STB     3,X                               ; STORE POSITION

        LDX     ARG1
        LDA     B,X                               ; GRAB A CHAR FROM SOURCE BUFFER
        JSR     SIBRKP                            ; IS IT A SIB?
        BCS     RSIBRK                            ; YES IF CARRY IS SET
        JSR     NBRKP                             ; IS IT A "NORMAL" BREAK CHAR?
        BCC     READL2                            ; NO, KEEP SCANNING
        INC     STABP                             ; ELSE FLUSH STRANDED BREAK
        DEC     MASK                              ; UPDATE # OF CHARS IN LINE
        BRA     READL                             ; AND LOOP BACK

READL2:
        LDA     MASK                              ; OUT OF CHARS?
        BEQ     READL3                            ; SURE ENOUGH
        LDB     STABP
        LDX     ARG1
        LDA     B,X                               ; ELSE GRAB NEXT CHAR
        JSR     RBRKP                             ; IS IT A BREAK?
        BCS     READL3                            ; YES IF CARRY SET
        LDB     MASK+1                            ; ELSE POINT TO
        LDX     #ZSTBUI                           ; WORD BUFFER
        STA     B,X                               ; STORE CHAR IN BUFFER
        DEC     MASK                              ; ONE LESS CHAR IN LINE
        INC     MASK+1                            ; ONE MORE IN RESULT
        INC     STABP                             ; POINT TO NEXT CHAR
        BRA     READL                             ; AND LOOP BACK

RSIBRK:
        STA     ZSTBUI                            ; STORE THE SIB
        DEC     MASK                              ; UPDATE LINE-CHAR COUNT
        INC     MASK+1                            ; WORD-CHAR COUNT
        INC     STABP                             ; AND # CHARS IN WORD

READL3:
        LDA     MASK+1                            ; ANY CHARS IN WORD?
        BEQ     READL                             ; APPARENTLY NOT

        LDB     RTABP                             ; POINT TO
        LDX     ARG2                              ; IN THIS ENTRY
        ABX
        LDA     MASK+1                            ; FETCH ACTUAL WORD LENGTH
        STA     2,X                               ; AND STORE IN 3RD BYTE

        LDA     MASK
        PSHS    A                                 ; SAVE THIS
        JSR     CONZST                            ; CONVERT TO Z-STRING
        JSR     FINDW                             ; LOOK UP IN VOCABULARY
        PULS    A
        STA     MASK                              ; RESTORE

        LDX     ARG2
        INC     1,X                               ; UPDATE # WORDS READ
        LDB     RTABP                             ; POINT [X] TO 1ST BYTE
        ABX                                       ; IN CURRENT ENTRY
        ADDB    #4
        STB     RTABP                             ; POINT TO NEXT ENTRY
        LDD     VAL                               ; STORE [VAL] IN ENTRY
        STD     ,X
        CLR     MASK+1                            ; RESET WORD-CHAR COUNT
        JMP     READL                             ; AND CONTINUE

; ----------
; FLUSH WORD
; ----------

FLUSHW:
        LDA     MASK
        BEQ     FLEX
        LDB     STABP
        LDX     ARG1
        LDA     B,X
        BSR     RBRKP                             ; WORD BREAK?
        BCS     FLEX                              ; EXIT IF SO
        DEC     MASK
        INC     MASK+1
        INC     STABP
        BRA     FLUSHW                            ; KEEP LOOPING
FLEX:
        RTS

; ---------------
; BREAK CHAR SCAN
; ---------------

RBRKP:
        BSR     SIBRKP                            ; FIRST CHECK FOR SIBS
        BCS     FBRK                              ; EXIT IF MATCHED

; FALL THROUGH TO ...

; ----------------------
; NORMAL BREAK CHAR SCAN
; ----------------------

NBRKP:
        LDX     #BRKTBL                           ; BASE OF BREAK CHAR TABLE
        LDB     #NBRKS-1                          ; NUMBER OF NORMAL BREAK CHARS
        BRA     NBR1

; ------------------------------
; SELF-INSERTING BREAK CHAR SCAN
; ------------------------------

SIBRKP:
        LDX     VOCAB                             ; BASE ADDRESS OF VOCAB TABLE
        LDB     ,X+                               ; GET # SIB CHARS
        DECB                                      ; ZERO-ALIGN COUNT

NBR1:
        CMPA    B,X
        BEQ     FBRK                              ; MATCHED!
        DECB
        BPL     NBR1                              ; KEEP LOOPING
        CLRB                                      ; NO MATCH, CLEAR CARRY
        RTS
FBRK:
        COMB                                      ; SET CARRY TO FLAG MATCH
        RTS

; -----------------
; VOCABULARY SEARCH
; -----------------

FINDW:
        LDX     VOCAB                             ; BASE ADDR OF VOCAB TABLE
        LDB     ,X+                               ; GET # SIB BYTES
        ABX                                       ; AND SKIP OVER THEM

        LDA     ,X+                               ; # BYTES PER TABLE ENTRY
        STA     MASK+1                            ; SAVE IT HERE

        LDD     ,X++                              ; # OF ENTRIES IN TABLE
        STD     VAL                               ; SAVE THAT TOO

FWL1:
        LDD     ,X                                ; CHECK FIRST Z-WORD
        CMPD    ZSTBUO
        BNE     WNEXT                             ; NO GOOD
        LDD     2,X                               ; ELSE CHECK 2ND HALF
        CMPD    ZSTBUO+2
        BEQ     FWSUCC                            ; MATCHED!

WNEXT:
        LDB     MASK+1                            ; MOVE [X] UP TO
        ABX                                       ; NEXT TABLE ENTRY
        LDD     VAL
        SUBD    #1
        STD     VAL                               ; OUT OF ENTRIES YET?
        BNE     FWL1                              ; NO, KEEP LOOKING
        RTS                                       ; ELSE RETURN WITH [VAL]=0

FWSUCC:
        LEAX    -ZCODE,X                          ; CONVERT TO Z-ADDRESS
        STX     VAL                               ; LEAVE RESULT IN [VAL]
        RTS

; ------------------
; NORMAL BREAK CHARS
; ------------------

BRKTBL:
        FCC     "!?,."
        FCB     EOL
        FCB     SPACE

NBRKS           EQU 6                             ; # NORMAL BREAK CHARS
