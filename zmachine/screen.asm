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
	LDX     #LOADM                            ;
        LDB     #LOADML
        JSR     DLINE                             ; "LOADING GAME ..."
        JMP     START                             ; AND DO A WARMSTART

LOADM:
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
	FCB 	00


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

        FCC     "COCO 2 VERSION C"
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

; ---------------
; CARRIAGE RETURN
; ---------------

ZCRLF:
        INC     LINCNT                            ; NEW LINE GOING OUT
        LDA     LINCNT
        CMPA    #20                               ; 13 LINES SENT YET? (CHANGED TO 20)
        BLO     CR1                               ; NO, KEEP GOING

        BSR     ZUSL                              ; UPDATE STATUS LINE

        LDX     #MORES                            ; "[MORE]"
        LDB     #MOREL
        JSR     DLINE

        CLR     CFLAG                             ; NO CURSOR!
        JSR     GETKEY                            ; GET A KEYPRESS


        LDA     #SPACE                            ; ERASE "MORE" MESSAGE
        LDB     #MOREL                            ; WITH SPACES
SPCS:
        JSR     OUTCHR
        DECB
        BNE     SPCS

        CLR     LINCNT                            ; RESET LINE COUNTER

CR1:
        LDA     #$0D
        JSR     CHAR
        RTS                                       ; AND RETURN

; ------------------
; UPDATE STATUS LINE
; ------------------

ZUSL:
        RTS ;;;;;;;;;;;;;;;;;;;;;;;;;;;;;ADDED DDW
;       LDA     CHRPNT                            ; SAVE ALL Z-STRING VARS
;       LDB     STBYTF
;       LDY     ZSTWRD
;       PSHS    X,Y,D
;       LDA     MPCH                              ; HIGH BIT OF MPC
;       LDB     BINDEX
;       LDX     MPCM                              ; LOW BYTES OF MPC
;       LDY     CSTEMP                            ; TEMP & PERM TOGETHER!
;       PSHS    X,Y,D

;       LDY     #BUFSAV                           ; MOVE OUTPUT BUFFER
;       LDX     #BUFFER                           ; TO TEMPORARY STORAGE
;       LDB     #SPACE                            ; CLEAR [BUFFER] WITH SPACES
;USL1:
;       LDA     ,X
;       STB     ,X+
;       STA     ,Y+
;       CMPX    #BUFFER+32
;       BLO     ZUSL1


; DISPLAY ROOM NAME

;       CLR     CHRPNT                            ; RESET CHAR INDEX
;       CLR     SCRIPT                            ; DISABLE SCRIPTING

;       LDA     #$10                              ; GLOBAL VAR #0 (ROOM #)
 ;      JSR     VARGET
 ;      LDA     TEMP+1
 ;      JSR     PRNTDC                            ; GET SHORT DESC INTO [BUFFER]

 ;      LDA     #22                               ; ADVANCE BUFFER INDEX
 ;      STA     CHRPNT                            ; INTO SCORING POSITION
 ;      LDA     #SPACE                            ; PRINT A SPACE
 ;      JSR     COUT                              ; TO SEPARATE THINGS (BM 12/6/84)

  ;     LDA     #$11                              ; FETCH GLOBAL VARIABLE
  ;     JSR     VARGET                            ; #1 (SCORE/HOURS)
  ;     TST     TIMEFL                            ; TIME MODE?
  ;     BNE     PTIME                             ; YES IF NZ

; PRINT SCORE

   ;    JSR     NUMBER                            ; PRINT THE VALUE
   ;    LDA     #$2F                              ; ASCII SLASH
   ;    BRA     MOVEP

; PRINT TIME (HOURS)

;PTIME:
;       LDA     TEMP+1
;       BNE     PTIME1                            ; 00 IS REALLY 24
;       LDA     #24
;PTIME1:
;       CMPA    #12
;       BLE     PTIME2                            ; IF HOURS IS GREATER THAN 12,
;       SUBA    #12                               ; CONVERT TO 12-HOUR TIME
;       STA     TEMP+1
;PTIME2:
;        JSR     NUMBER                            ; SHOW HOURS VALUE
;        LDA     #$3A                              ; ASCII COLON
;
;MOVEP:
;        JSR     COUT                              ; SEND COLON (OR SLASH)
;        LDA     #$12                              ; GLOBAL VAR #2 (MOVES/MINUTES)
;        JSR     VARGET
;        TST     TIMEFL                            ; TIME MODE?
;        BEQ     PNUM                              ; NO, DO MOVES

; PRINT MINUTES

;        LDA     TEMP+1
;        CMPA    #10                               ; IF LESS THAN 10 MINUTES,
;        BHS     MOVEP1
;        LDA     #$30                              ; ADD ASCII ZERO FOR PADDING
;        JSR     COUT

;MOVEP1:
;        JSR     NUMBER                            ; SHOW MINUTES

; PRINT "AM/PM"

;        LDA     #SPACE                            ; SEPARATE TIMING
;        JSR     COUT                              ; FROM "AM/PM"
;        LDA     #$11                              ; GLOBAL #1 AGAIN
;        JSR     VARGET
;        LDA     TEMP+1
;        CMPA    #12                               ; PAST NOON?
;        BHS     USEPM                             ; YES, IT'S PM
;        LDA     #$41                              ; "A"
;        BRA     DOM
;USEPM:
;        LDA     #$50                              ; "P"
;DOM:
;        JSR     COUT
;        LDA     #$4D                              ; "M"
;        JSR     COUT
;        BRA     AHEAD                             ; DONE!

; PRINT # MOVES

;PNUM:
;        JSR     NUMBER                            ; SIMPLE, EH?
;
;AHEAD:
;        JSR     CR1                               ; DUMP BUFFER
;        BSR     INVERT                            ; INVERT STATUS LINE

;        LDY     #BUFSAV                           ; POINT TO "SAVE" BUFFER
;        LDX     #BUFFER                           ; POINT TO OUTPUT BUFFER
;USLEND:
;        LDA     ,Y+
;        STA     ,X+                               ; RESTORE PREVIOUS CONTENTS
;        CMPX    #BUFFER+32
;        BLO     USLEND

;        PULS    X,Y,D                             ; RESTORE EVERYTHING
;        STY     CSTEMP
;        STX     MPCM
;        STB     BINDEX
;        STA     MPCH
;        PULS    X,Y,D
;        STY     ZSTWRD
;        STB     STBYTF
;        STA     CHRPNT
;        COM     SCRIPT                            ; RE-ENABLE SCRIPTING
;        CLR     MPCFLG                            ; MPC NO LONGER VALID
;        RTS

; ------------------
; INVERT STATUS LINE
; ------------------

;INVERT:
;        RTS
