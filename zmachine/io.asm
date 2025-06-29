;	PAGE
;	SBTTL "--- OS EQUATES ---"

EOL             EQU $0D                           ; END-OF-LINE CHARACTER
BS              EQU $08                           ; BACKSPACE CHARACTER
SPACE           EQU $20                           ; SPACE CHARACTER

;        PAGE
;        SBTTL   "I/O PRIMITIVES"



; --------------------
; ACCESS OS CHAR-PRINT
; --------------------


OUTCHR:
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC
        RTS

; -----------------
; READ A SINGLE KEY
; -----------------

; EXIT: KEYCODE IN [A]

BADKEY:
        JSR     BOOP                              ; RAZZ
        BRA     GK                                ; AND TRY AGAIN

GETKEY:
        PSHS    U,X,Y,B,CC                        ; SAVE THESE


GK:
        SWI
        FCB     35
        BEQ     KTEST                             ; got a key
        INC     RAND1                             ; GENERATE RANDOMNESS
        BNE     >
        INC     RAND2
!
        BRA     GK
KTEST:
        SWI
        FCB     34
        STA     IOCHAR                            ; STORE THE KEYPRESS


; KEYCODE IN [A]

QKEY:
        CMPA    #EOL                              ; "ENTER" IS FINE
        BEQ     CLICK
        CMPA    #BS                               ; SO IS "LEFT ARROW"
        BEQ     CLICK

        CMPA    #$61                              ; LOWER-CASE ALPHA?
        BLO     PKICK                             ; NO, CHECK FOR OTHERS
        CMPA    #$7B                              ; NOTHING ABOVE "z" IS LEGAL
        BHS     BADKEY
        SUBA    #$20                              ; CONVERT TO UPPER-CASE ALPHA
        BRA     CLICK

PKICK:
        CMPA    #$5B                              ; NOTHING BETWEEN "Z" AND "a"
        BHS     BADKEY                            ; IS LEGAL
        CMPA    #$20                              ; NOTHING BELOW "SPACE"
        BLO     BADKEY                            ; IS LEGAL EITHER

; "CLICK" SOUND FOR KEYS

CLICK:
        PULS    U,X,Y,B,CC                        ; RESTORE THINGS
        LDA     IOCHAR                            ; RETRIEVE THE KEYPRESS
        RTS


; DELAY FOR KEYCLICK

CDELAY:
        LDX     #CFREQ
CDEL:
        LEAX    -1,X
        BNE     CDEL
        RTS

; -------------------
; READ A LINE OF TEXT
; -------------------

; ENTRY: [ARG1] HAS ADDRESS OF CHAR BUFFER
;        LENGTH OF BUFFER IN 1ST BYTE
; EXIT:	# CHARS READ IN [A]

INPUT:
        CLR     LINCNT                            ; RESET LINE COUNTER
        LDX     ARG1                              ; GET ADDRESS OF INPUT BUFFER
        LDB     ,X+                               ; GET MAX # CHARS
        SUBB    #2                                ; LEAVE A MARGIN FOR ERROR
        STB     BINDEX                            ; SAVE MAX # CHARS

        CLRB                                      ; RESET	INDEX
INLOOP:
        JSR     GETKEY                            ; KEY IN [A] AND [IOCHAR]
        CMPA    #EOL                              ; IF EOL,
        BEQ     ENDLIN                            ; LINE IS DONE
        CMPA    #BS                               ; IF BACKSPACE,
        BEQ     GOBACK                            ; TAKE CARE OF IT

        CMPA    #$41                              ; IF LOWER THAN ASCII "A,"
        BLO     SENDCH                            ; SEND THE CHARACTER
        ADDA    #$20                              ; ELSE CONVERT TO LOWER-CASE

SENDCH:
        STA     B,X                               ; SEND CHAR TO BUFFER
        INCB                                      ; UPDATE INDEX
TOSCR:
        LDA     IOCHAR                            ; RETRIEVE KEY CHAR
        BSR     CHAR                              ; ECHO CHAR TO SCREEN
        CMPB    BINDEX                            ; BUFFER FILLED?
        BHS     NOMORE                            ; YES -- INSIST ON BS OR EOL
        CMPB    #61                               ; 2 SCREEN LINES FILLED?
        BLO     INLOOP                            ; NO, KEEP GOING

; LINE FULL; INSIST ON EOL OR BACKSPACE

NOMORE:
        JSR     GETKEY                            ; GET NEXT KEY
        CMPA    #EOL                              ; IF EOL,
        BEQ     ENDLIN                            ; WE'RE FINE
        CMPA    #BS                               ; BACKSPACE
        BEQ     GOBACK                            ; IS OKAY TOO
        JSR     BOOP
        BRA     NOMORE                            ; ELSE PERSIST

; HANDLE BACKSPACE

GOBACK:
        DECB                                      ; BACK UP CHAR COUNT
        BPL     TOSCR                             ; SEND TO SCREEN IF NO UNDERFLOW
        CLRB                                      ; ELSE RESET COUNT
        JSR     BOOP                              ; RAZZ
        BRA     INLOOP                            ; AND TRY AGAIN

; HANDLE EOL

ENDLIN:
        STA     B,X                               ; PUT EOL IN BUFFER
        BSR     CHAR                              ; AND ON SCREEN
        INCB                                      ; UPDATE CHAR COUNT
        STB     BINDEX                            ; SAVE IT HERE

; FALL THROUGH TO ...

; ---------------------
; SCRIPT A LINE OF TEXT
; ---------------------

; ENTRY: ADDRESS OF TEXT IN [X]
;        LENGTH OF LINE IN [BINDEX]

TOPRIN:
        TST     SCRIPT                            ; SCRIPTING ENABLED?
        BEQ     INPEX                             ; NO, EXIT IMMEDIATELY
        LDA     ZCODE+ZSCRIP+1                    ; GET FLAGS BYTE
        ANDA    #1                                ; BIT 0 SET?
        BEQ     INPEX                             ; NO, IGNORE THE FOLLOWING
;        LDA     #$FE                              ; ELSE
;        STA     DEVNUM                            ; POINT TO PRINTER
        LDB     BINDEX                            ; START AT 1ST BUFFER CHAR


SCROUT:
        LDA     ,X+                               ; GRAB A CHAR FROM BUFFER
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC
        DECB
        BNE     SCROUT
INPEX:
;        CLR     DEVNUM                            ; POINT BACK TO SCREEN
        LDA     BINDEX                            ; RETRIEVE # CHARS IN LINE
        RTS

SFLAG
        FCB     0                                 ; FLAG TO SAVE SCRIPT STATE


; -------------------
; PRINT A SINGLE CHAR
; -------------------

; ENTRY: ASCII CODE IN [A]

CHAR:
        STA     IOCHAR                            ; SAVE CHAR HERE
        CMPA    #$0D
        BEQ     >
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33
        PULS    A,B,X,Y,U,CC
        RTS
!
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33
        LDA     #$0A
        SWI
        FCB     33
        PULS    A,B,X,Y,U,CC
        RTS



; FALL THROUGH TO ...

; -------------
; PRINT MESSAGE
; -------------

; ENTRY: ADDRESS OF ASCII MESSAGE IN [X]
;        LENGTH OF MESSAGE IN [B]

LINE:
        STB     BINDEX                            ; SAVE LENGTH
        CLRB                                      ; INIT INDEX

LN:
        LDA     B,X                               ; GET A CHAR
        JSR     CHAR
        INCB
        CMPB    BINDEX
        BLO     LN
        JMP     TOPRIN                            ; HANDLE SCRIPTING

; ----------------
; CLEAR THE SCREEN
; ----------------

CLS:
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     24                                ;String to OS
        FCB     27
        FCN     '[2J'
        PULS    A,B,X,Y,U,CC
        RTS

; --------------
; SOUND HANDLERS
; --------------

AINIT:
        RTS

; DO THE RAZZ
BOOP:

; put sound boop here

        RTS

; TIME DELAY

DELAY:
        LDX     #BFREQ                            ; INIT FREQUENCY
DELOOP:
        LEAX    -1,X
        BNE     DELOOP
        RTS

;-----------------------------------------------------------------------------
