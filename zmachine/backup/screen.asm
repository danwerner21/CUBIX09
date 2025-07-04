;	PAGE
;	SBTTL "--- SCREEN & PRINTER I/O ---"

; ------------
; RESTART GAME
; ------------

ZSTART:
        JSR     ZCRLF                             ; FLUSH OUTPUT BUFFER
        CLR     SCRIPT                            ; DISABLE SCRIPTING [ASK 5/28/85]
; 	JSR	ENTER		; "PRESS ANY KEY TO CONTINUE"[ASK 5/28/85]
        LDA     ZCODE+ZSCRIP+1
        STA     SFLAG
        JMP     LUKE                              ; SKIP SCRIPT DISABLE
; FALL THROUGH TO ...

; ---------
; COLDSTART
; ---------

COLD:
        CLR     SCRIPT                            ; DISABLE SCRIPTING
LUKE:
        JSR     CLS                               ; A CLEAN SLATE
        JSR     BOLD
        LDX     #LOADM                            ;
        LDB     #LOADML
        JSR     DLINE                             ; "LOADING GAME ..."
        JSR     UNBOLD
        JSR     MOVECURSOR
        JMP     START                             ; AND DO A WARMSTART

LOADM:
        FCB     27
        FCC     "[10;10H "
        FCC     "THE STORY IS LOADING ..."
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
        CMPA    #EOL                              ; IF THIS IS A CR,
        BEQ     ZCRLF                             ; HANDLE AS SUCH
        JMP     OUTCHR

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


        LDA     #$0D
        JSR     CHAR

        JSR     BOLD
        LDX     #MORES                            ; "[MORE]"
        LDB     #MOREL
        JSR     DLINE
        JSR     UNBOLD

        BSR     ZUSL                              ; UPDATE STATUS LINE
        JSR     GETKEY                            ; GET A KEYPRESS

        LDX     #MCLR                             ; CLEAR LINE
        LDB     #MCLRL
        JSR     DLINE

        CLR     LINCNT                            ; RESET LINE COUNTER

CR1:
        LDA     #$0D
        JSR     CHAR
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

; DISPLAY ROOM NAME

        CLR     CHRPNT                            ; RESET CHAR INDEX
        CLR     SCRIPT                            ; DISABLE SCRIPTING
        JSR     HOME
        JSR     REVERSE

        LDX     #79                               ;
!
        LDA     #SPACE                            ; PRINT A REVERSED LINE
        JSR     COUT                              ; TO SEPARATE THINGS (BM 12/6/84)
        DEX
        BNE     <
        JSR     HOME

        LDA     #$10                              ; GLOBAL VAR #0 (ROOM #)
        JSR     VARGET
        LDA     TEMP+1
        JSR     PRNTDC                            ; GET SHORT DESC INTO [BUFFER]

        LDA     #SPACE                            ; PRINT A SPACE
        JSR     COUT                              ; TO SEPARATE THINGS (BM 12/6/84)
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
        JSR     CR1                               ; DUMP BUFFER


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
