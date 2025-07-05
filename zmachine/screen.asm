;	PAGE
;	SBTTL "--- SCREEN & PRINTER I/O ---"

; ------------
; RESTART GAME
; ------------

ZSTART:
        JSR     ZCRLF                             ; FLUSH OUTPUT BUFFER
        CLR     SCRIPT                            ; DISABLE SCRIPTING [ASK 5/28/85]
        LDA     ZCODE+ZSCRIP+1
        STA     SFLAG
; FALL THROUGH TO ...

; ---------
; COLDSTART
; ---------

COLD:
        CLR     SCRIPT                            ; DISABLE SCRIPTING
        JSR     CLS                               ; A CLEAN SLATE
        JSR     BOLD
        LDX     #LOADM                            ;
        LDB     #LOADML
        JSR     DLINE                             ; "LOADING GAME ..."
        JSR     UNBOLD
        JMP     START                             ; AND DO A WARMSTART

LOADM:
        FCB     27
        FCC     "[10;10H "
        FCC     "THE STORY IS LOADING ..."
        FCB     13,13,13,13
loadlen:
LOADML          EQU loadlen-LOADM

; -----
; ERROR
; -----

; ENTRY: ERROR CODE # IN [A]

INTERR:
        FCB     EOL
        FCC     "INTERNAL ERROR #"
interrlen:
IERRL           EQU interrlen-INTERR

ZERROR:
        PSHS    A                                 ; SAVE CODE #
        JSR     ZCRLF                             ; FLUSH BUFFER
        LDX     #INTERR
        LDB     #IERRL
        JSR     LINE                              ; "INTERNAL ERROR #"
        PULS    A                                 ; RETRIEVE CODE #
        STA     TEMP+1
        CLR     TEMP
        JSR     NUMBER                            ; CONVERT ERROR CODE #
        JSR     CR1                               ; AND SHOW IT

; FALL THROUGH TO ...

; ----
; QUIT
; ----

ZQUIT:
        LDX     #ENDSES
        LDB     #ENDSL
        JSR     LINE                              ; "END OF SESSION"

        SWI
        FCB     00


FREEZE:
        BRA     FREEZE                            ; STOP DEAD

ENDSES:
        FCC     "END OF SESSION"
VCODE:
        FCB     EOL                               ; SHARED EOL CHAR
endseslen:
ENDSL           EQU endseslen-ENDSES

; --------------------------
; DISPLAY ZIP VERSION NUMBER
; --------------------------

        FCC     "6809 CUBIX VERSION"
        FCB     EOL
vcodelen:
VCODEL          EQU vcodelen-VCODE

VERNUM:
        LDX     #VCODE
        LDB     #VCODEL
        JMP     LINE

; -----------------
; PRINT A CHARACTER
; -----------------
COUT:
        LDX     #BUFFER                           ; POINT TO I/O BUFFER
        LDB     CHRPNT                            ; GET LINE INDEX
        CMPA    #EOL                              ; IF THIS IS A CR,
        BEQ     ZCRLF                             ; HANDLE AS SUCH
        CMPA    #SPACE                            ; IGNORE OTHER CONTROLS
        BLO     COUT1

        STA     B,X                               ; SEND CHAR TO BUFFER
        CMPB    #79                               ; END OF SCREEN LINE?
        BHS     FLUSH                             ; YES, SO FLUSH CURRENT BUFFER
        INC     CHRPNT                            ; ELSE UPDATE INDEX
COUT1:
        RTS                                       ; AND LEAVE

; FLUSH CONTENTS OF [BUFFER]

FLUSH:
        LDA     #SPACE
FLUSH1:
        CMPA    B,X                               ; FIND LAST SPACE CHAR
        BEQ     FLUSH2                            ; IN CURRENT LINE
        DECB
        BNE     FLUSH1                            ; KEEP SCANNING
        LDB     #79                               ; SEND ENTIRE LINE IF NONE FOUND

FLUSH2:
        STB     CPSAV                             ; SAVE
        STB     CHRPNT                            ; # CHARS IN LINE
        JSR     ZCRLF                             ; OUTPUT 1ST PART OF LINE

; START NEW LINE WITH REMAINDER OF OLD

FLUSH3:
        INC     CPSAV                             ; GET 1ST CHAR
        LDB     CPSAV                             ; OF REMAINDER
        CMPB    #79                               ; END OF LINE YET?
        BLS     FLUSH4                            ; NO, MOVE IT FORWARD
        RTS                                       ; ELSE WE'RE DONE HERE

FLUSH4:
        LDX     #BUFFER                           ; POINT TO BUFFER
        LDA     B,X                               ; GET OLD CHAR
        LDB     CHRPNT                            ; THIS WAS RESET BY CRLF
        STA     B,X                               ; MOVE TO START OF BUFFER
        INC     CHRPNT                            ; NEXT POSITION
        BRA     FLUSH3                            ; KEEP MOVING

MORES:
        FCC     "[more]"
morlen:
MOREL           EQU morlen-MORES
MCLR:
        FCB     08,08,08,08,08,08
        FCC     "      "
        FCB     08,08,08,08,08,08
mclrlen:
MCLRL           EQU mclrlen-MCLR


; ---------------
; CARRIAGE RETURN
; ---------------
ZCRLF:
        INC     LINCNT                            ; NEW LINE GOING OUT
        LDA     LINCNT
        CMPA    #13                               ; 13 LINES SENT YET?
        BLO     CR1                               ; NO, KEEP GOING

        JSR     ZUSL                              ; UPDATE STATUS LINE

        JSR     BOLD
        LDX     #MORES                            ; "[MORE]"
        LDB     #MOREL
        JSR     DLINE
        JSR     UNBOLD

        JSR     GETKEY                            ; GET A KEYPRESS

        LDX     #MCLR                             ; CLEAR LINE
        LDB     #MCLRL
        JSR     DLINE

        CLR     LINCNT                            ; RESET LINE COUNTER

CR1:
        LDB     CHRPNT
        LDX     #BUFFER
        LDA     #EOL                              ; INSTALL AN EOL
        STA     B,X                               ; AT END OF CURRENT LINE
        INC     CHRPNT                            ; ADD IT TO CHAR COUNT

LINOUT:
        TST     CHRPNT                            ; IF NO CHARS IN BUFFER
        BEQ     SCDONE                            ; DON'T PRINT ANYTHING
OUTPUT:
        JSR     BUFOUT                            ; ELSE DISPLAY BUFFER
        CLR     CHRPNT                            ; RESET CHAR INDEX
SCDONE:
        RTS                                       ; AND RETURN

; ------------------
; UPDATE STATUS LINE
; ------------------

ZUSL:
        LDA     CHRPNT                            ; SAVE ALL Z-STRING VARS
        LDB     STBYTF
        LDY     ZSTWRD
        PSHS    X,Y,D
        LDA     MPCH                              ; HIGH BIT OF MPC
        LDB     BINDEX
        LDX     MPCM                              ; LOW BYTES OF MPC
        LDY     CSTEMP                            ; TEMP & PERM TOGETHER!
        PSHS    X,Y,D

        LDY     #OBUFSAV                          ; MOVE OUTPUT BUFFER
        LDX     #BUFFER                           ; TO TEMPORARY STORAGE
        LDB     #SPACE                            ; CLEAR [BUFFER] WITH SPACES
ZUSL1:
        LDA     ,X
        STB     ,X+
        STA     ,Y+
        CMPX    #BUFFER+80
        BLO     ZUSL1

; DISPLAY ROOM NAME

        CLR     CHRPNT                            ; RESET CHAR INDEX
        CLR     SCRIPT                            ; DISABLE SCRIPTING

        LDA     #$10                              ; GLOBAL VAR #0 (ROOM #)
        JSR     VARGET
        LDA     TEMP+1
        JSR     PRNTDC                            ; GET SHORT DESC INTO [BUFFER]

        LDA     #40                               ; ADVANCE BUFFER INDEX
        STA     CHRPNT                            ; INTO SCORING POSITION
        LDA     #SPACE                            ; PRINT A SPACE
        JSR     COUT                              ; TO SEPARATE THINGS (BM 12/6/84)

        LDA     #$11                              ; FETCH GLOBAL VARIABLE
        JSR     VARGET                            ; #1 (SCORE/HOURS)
        TST     TIMEFL                            ; TIME MODE?
        BNE     PTIME                             ; YES IF NZ

; PRINT SCORE

        JSR     NUMBER                            ; PRINT THE VALUE
        LDA     #$2F                              ; ASCII SLASH
        BRA     MOVEP

; PRINT TIME (HOURS)

PTIME:
        LDA     TEMP+1
        BNE     PTIME1                            ; 00 IS REALLY 24
        LDA     #24
PTIME1:
        CMPA    #12
        BLE     PTIME2                            ; IF HOURS IS GREATER THAN 12,
        SUBA    #12                               ; CONVERT TO 12-HOUR TIME
        STA     TEMP+1
PTIME2:
        JSR     NUMBER                            ; SHOW HOURS VALUE
        LDA     #$3A                              ; ASCII COLON

MOVEP:
        JSR     COUT                              ; SEND COLON (OR SLASH)
        LDA     #$12                              ; GLOBAL VAR #2 (MOVES/MINUTES)
        JSR     VARGET
        TST     TIMEFL                            ; TIME MODE?
        BEQ     PNUM                              ; NO, DO MOVES

; PRINT MINUTES

        LDA     TEMP+1
        CMPA    #10                               ; IF LESS THAN 10 MINUTES,
        BHS     MOVEP1
        LDA     #$30                              ; ADD ASCII ZERO FOR PADDING
        JSR     COUT

MOVEP1:
        JSR     NUMBER                            ; SHOW MINUTES

; PRINT "AM/PM"

        LDA     #SPACE                            ; SEPARATE TIMING
        JSR     COUT                              ; FROM "AM/PM"
        LDA     #$11                              ; GLOBAL #1 AGAIN
        JSR     VARGET
        LDA     TEMP+1
        CMPA    #12                               ; PAST NOON?
        BHS     USEPM                             ; YES, IT'S PM
        LDA     #$41                              ; "A"
        BRA     DOM
USEPM:
        LDA     #$50                              ; "P"
DOM:
        JSR     COUT
        LDA     #$4D                              ; "M"
        JSR     COUT
        BRA     AHEAD                             ; DONE!

; PRINT # MOVES

PNUM:
        JSR     NUMBER                            ; SIMPLE, EH?

AHEAD:
        JSR     HOME
        JSR     REVERSE
        JSR     CR1                               ; DUMP BUFFER
        JSR     UNBOLD

        LDY     #OBUFSAV                          ; POINT TO "SAVE" BUFFER
        LDX     #BUFFER                           ; POINT TO OUTPUT BUFFER
USLEND:
        LDA     ,Y+
        STA     ,X+                               ; RESTORE PREVIOUS CONTENTS
        CMPX    #BUFFER+79
        BLO     USLEND


        PULS    X,Y,D                             ; RESTORE EVERYTHING
        STY     CSTEMP
        STX     MPCM
        STB     BINDEX
        STA     MPCH
        PULS    X,Y,D
        STY     ZSTWRD
        STB     STBYTF
        STA     CHRPNT
        COM     SCRIPT                            ; RE-ENABLE SCRIPTING
        CLR     MPCFLG                            ; MPC NO LONGER VALID
        JSR     UNBOLD
        JSR     MOVECURSOR
        RTS
