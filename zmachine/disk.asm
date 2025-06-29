;	PAGE
;	SBTTL "--- DISK I/O ---"


; ------------------------
; READ A Z-BLOCK FROM DISK
; ------------------------

; ENTRY: DRIVE # (0 OR 1) IN [DRIVE]
;        BLOCK # IN [DBLOCK]
;        BUFFER ADDRESS IN [DBUFF]
INFILE:
        FCC     "A:[ZIP]ZIPTEST.Z3"               ; FSDIR(8)   DIRECTORY PREFIX
        FCB     00                                ; FSDRIVE(1) Drive Index (0-3)


OPENGAMEDSK:
        LDY     #INFILE                           ; SET FILE NAME
        SWI
        FCB     10
        LBNE    DERR2                             ; FILE ERROR
        LDU     #INFCB                            ; OPEN FILE
        SWI
        FCB     55
        RTS

GETDSK:
        PSHS    X,Y,U,D                           ; SAVE VARIABLES
        LDU     #INFCB                            ; REWIND FILE
        SWI
        FCB     62
        LDD     DBLOCK                            ; GO TO DBLOCK POSITION
        STA     DTEMP
!
        CMPA    #$00                              ; HOW MANY BLOCKS OF $10000 DO WE NEED TO GET
        BEQ     GETDSK1                           ; NONE, SKIP
        LDD     #$FFFF
        LDU     #INFCB                            ;
        SWI
        FCB     63
        LDD     #1
        LDU     #INFCB                            ;
        SWI
        FCB     63
        DEC     DTEMP
        LDA     DTEMP
        BRA     <
GETDSK1:
        LDD     DBLOCK                            ; HOW MANY BLOCKS OF <$10000 DO WE NEED TO GET
        TFR     B,A
        LDB     #$00
        LDU     #INFCB                            ;
        SWI
        FCB     63
; READ 256 BYTES
	LDB     #$00
	STB 	DTEMP
!
        SWI
        FCB     59
	LDX 	DBUFF
        STA     ,X
	INC 	DBUFF+1
	BNE 	BUFINC
	INC 	DBUFF
BUFINC:
        DEC	DTEMP
	LDB 	DTEMP
        CMPB    #$00
        BNE     <
        INC     DBLOCK+1                          ; POINT TO NEXT Z-BLOCK
        BNE     REND
        INC     DBLOCK
REND:
        PULS    X,Y,U,D                           ; RESTORE VARIABLES
;        STX     VAL
;        STD     TEMP
        RTS

DTEMP 	FCB 	00


; -----------------
; SAVE/RESTORE INIT
; -----------------

SAVRES:
        JSR     ZCRLF                             ; FLUSH OUTPUT BUFFER
        JSR     CLS
        CLR     SCRIPT                            ; DISABLE SCRIPTING
        RTS

; ---------
; SAVE GAME
; ---------

ZSAVE:
        BSR     SAVRES                            ; INIT THINGS
        LDX     #SAV
        LDB     #SAVL
        JSR     DLINE                             ; "SAVE POSITION"

        JSR     PARAMS                            ; GET POSITION AND DRIVE

        LDX     #SING
        LDB     #SINGL
        JSR     DLINE                             ; "SAVING"
        JSR     TIONP                             ; "POSITION X ..."

        LDX     #BUFSAV                           ; POINT TO AUX BUFFER
        LDD     ZCODE+ZID                         ; GET GAME ID CODE
        STD     ,X++                              ; SAVE IN BUFFER
        LDD     OZSTAK                            ; OLD STACK POINTER
        STD     ,X++
        STU     ,X++                              ; AND CURRENT STACK POINTER
        LDA     ZPCH                              ; HI BYTE OF ZPC
        STA     ,X+
        LDD     ZPCM                              ; LOW ZPC BYTES
        STD     ,X

        LDD     #LOCALS
        STD     DBUFF
;        BSR     DWRITE                            ; WRITE LOCAL/BUFFER PAGE

        LDD     #ZSTACK                           ; SAVE CONTENTS
        STD     DBUFF                             ; OF Z-STACK (2 PAGES)
;        BSR     DWRITE                            ; FIRST HALF
 ;       BSR     DWRITE                            ; 2ND HALF

; SAVE GAME PRELOAD

        LDD     #ZCODE                            ; START OF PRELOAD
        STD     DBUFF
        LDA     ZCODE+ZPURBT                      ; SIZE OF PRELOAD (MSB, # PAGES)
        INCA                                      ; ROUND UP
        STA     TEMP                              ; USE [TEMP] AS INDEX

LSAVE:
;        BSR     DWRITE                            ; SAVE A PAGE
        DEC     TEMP                              ; SAVED ENTIRE PRELOAD YET?
        BNE     LSAVE                             ; NO, KEEP SAVING
        JMP     RESUME

; *** ERROR #12: DISK ADDRESS RANGE ***

DSKERR:
        LDA     #12
        BRA     DSKEX

; *** ERROR #14: DISK ACCESS ***

DERR2:
        LDA     #14
DSKEX:
        JSR     ZERROR

; ------------
; RESTORE GAME
; ------------

ZREST:
        JSR     SAVRES

        LDX     #RES
        LDB     #RESL
        JSR     DLINE                             ; "RESTORE POSITION"

        JSR     PARAMS

        LDX     #RING
        LDB     #RINGL
        JSR     DLINE                             ; "RESTORING"
        JSR     TIONP                             ; "POSITION X ..."

; SAVE LOCALS ON MACHINE STACK
; IN CASE OF ERROR

        LDX     #LOCALS                           ; POINT TO LOCALS STORAGE
        STX     DBUFF                             ; POINT TO 1ST PAGE TO RESTORE
LOCLP:
        LDD     ,X++                              ; GRAB A LOCAL
        PSHS    D                                 ; AND PUSH IT
        CMPX    #LOCALS+30                        ; SAVED 15 LOCALS YET?
        BLO     LOCLP                             ; NO, KEEP PUSHING

       ; JSR     DREAD                             ; RETRIEVE LOCALS/BUFFER PAGE

        LDD     BUFSAV                            ; READ SAVED GAME ID
        CMPD    ZCODE+ZID                         ; IF IT MATCHES CURRENT GAME ID,
        BEQ     VERSOK                            ; PROCEED WITH THE RESTORE

; WRONG SAVE DISK, ABORT RESTORE

        LDX     #LOCALS+30                        ; RESTORE PUSHED LOCALS
RESLP:
        PULS    D
        STD     ,--X
        CMPX    #LOCALS
        BHI     RESLP
ERRWP:
        BSR     TOBOOT                            ; PROMPT FOR GAME DISK
        JMP     PREDF                             ; PREDICATE FAILS

VERSOK:
        LEAS    +30,S                             ; POP OLD LOCALS OFF STACK
        LDD     ZCODE+ZSCRIP
        STD     VAL                               ; SAVE FLAGS

        LDD     #ZSTACK                           ; RETRIEVE
        STD     DBUFF                             ; CONTENTS OF Z-STACK
      ;  JSR     DREAD
      ;  JSR     DREAD

DOREST:
        LDD     #ZCODE                            ; NOW RETRIEVE
        STD     DBUFF                             ; 1ST PAGE OF PRELOAD
     ;   JSR     DREAD

        LDA     ZCODE+ZPURBT                      ; DETERMINE # PAGES
        STA     TEMP                              ; TO RETRIEVE

LREST:
    ;    JSR     DREAD                             ; FETCH REMAINDER OF PRELOAD
        DEC     TEMP
        BNE     LREST

; RESTORE STATE OF SAVED GAME

        LDX     #BUFSAV+2                         ; POINT TO SAVED VARIABLES
        LDD     ,X++
        STD     OZSTAK                            ; RESTORE OLD STACK POINTERS
        LDU     ,X++
        LDA     ,X+
        STA     ZPCH                              ; HIGH BYTE OF ZPC
        LDD     ,X                                ; LOW BYTES OF ZPC
        STD     ZPCM
        CLR     ZPCFLG                            ; PC HAS CHANGED!

        LDD     VAL                               ; RESTORE FLAGS
        STD     ZCODE+ZSCRIP

; RESUME GAME AFTER SAVE OR RESTORE

RESUME:
        BSR     TOBOOT                            ; PROMPT FOR GAME DISK
        JMP     PREDS                             ; PREDICATE SUCCEEDS

TOBOOT:
        CLR     DRIVE                             ; BACK TO BOOT DRIVE
        LDX     #GAME
        LDB     #GAMEL
        JSR     DLINE                             ; "INSERT STORY DISK IN DRIVE 0,"
        JSR     ENTER                             ; "PRESS <ENTER> TO CONTINUE"
        COM     SCRIPT                            ; RE-ENABLE SCRIPTING
        JMP     CLS                               ; CLEAR SCREEN AND RETURN

; ---------------------------
; "PRESS <ENTER> TO CONTINUE"
; ---------------------------

ENTER:
        LDX     #PRESS
        LDB     #PRESSL
        STB     CFLAG                             ; ENABLE CURSOR
        JSR     LINE                              ; "PRESS <ENTER> TO CONTINUE"
        JSR     GETKEY                            ; GET A KEY
        CLR     CFLAG                             ; DISABLE CURSOR
        LDA     #EOL
        JMP     COUT                              ; DO EOL AND RETURN

; --------------------------------
; PROMPT SEQUENCE FOR SAVE/RESTORE
; --------------------------------

PARAMS:
        LDX     #POSIT
        LDB     #POSITL
        JSR     DLINE                             ; "GAME ... POSITION 1-7 "

        LDA     #TRUE
        STA     CFLAG                             ; ENABLE CURSOR

; GET POSITION

        LDA     GPOSIT                            ; GET DEFAULT POSITION
        INCA                                      ; 1-ALIGN IT
        JSR     DODEF

GETPOS:
        JSR     GETKEY
        CMPA    #EOL
        BEQ     SETPOS
        SUBA    #$31                              ; CONVERT "1-7" TO 0-6
        CMPA    #7                                ; IF LOWER THAN "7"
        BLO     POSSET                            ; SET NEW POSITION
        JSR     BOOP                              ; ELSE RAZZ
        BRA     GETPOS                            ; AND TRY AGAIN

SETPOS:
        LDA     GPOSIT                            ; USE DEFAULT
POSSET:
        STA     GPOSIT                            ; TEMP DEFAULT
        ADDA    #$31                              ; CONVERT TO ASCII
        STA     PDO                               ; HERE TOO
        JSR     OUTCHR                            ; AND SHOW CHOICE

; GET DRIVE #

        LDX     #WDRIV
        LDB     #WDRIVL
        JSR     DLINE                             ; "DRIVE 0 OR 1 "

        LDA     GDRIVE
        BSR     DODEF                             ; SHOW DEFAULT

GETDRV:
        JSR     GETKEY
        CMPA    #EOL
        BEQ     DRVSET
        SUBA    #$30                              ; CONVERT TO ASCII
        CMPA    #2
        BLO     SETDRV
        JSR     BOOP
        BRA     GETDRV                            ; DRIVE # NO GOOD

DRVSET:
        LDA     GDRIVE
SETDRV:
        STA     DRIVE                             ; NEW DEFAULT
        ADDA    #$30                              ; CONVERT TO ASCII
        STA     GAMDRI                            ; FOR PROMPT
        JSR     OUTCHR                            ; SHOW CHOICE

        LDA     GPOSIT                            ; MAKE IT THE NEW DEFAULT
        LDB     #5                                ; CALC BLOCK OFFSET (5 TRACKS/GAME)
        MUL
        STB     TRACK                             ; TRACK ADDRESS
        LDB     #1                                ; START ON SECTOR 1
        STB     TRACK+1                           ; SECTOR ADDRESS

        LDX     #INSERM
        LDB     #INSERML
        JSR     DLINE                             ; "INSERT SAVE DISK IN DRIVE X,"
        JMP     ENTER                             ; ETC.

; ------------
; SHOW DEFAULT
; ------------

DODEF:
        ADDA    #$30                              ; CONVERT # TO ASCII
        STA     DEFNUM                            ; INSERT IN STRING
        LDX     #DEFALT
        LDB     #DEFALL
        STB     CFLAG                             ; ENABLE CURSOR

; FALL THROUGH TO ...

; --------------------
; DIRECT SCREEN OUTPUT
; --------------------

; ENTRY: SAME AS "LINE" ROUTINE

DLINE:
        LDA     ,X+
        JSR     OUTCHR
        DECB
        BNE     DLINE
        RTS

; ----------------------
; PRINT "POSITION X ..."
; ----------------------

TIONP:
        LDX     #PTION
        LDB     #PTIONL
        BRA     DLINE

; ---------------------
; TEXT FOR SAVE/RESTORE
; ---------------------

RES:
        FCC     "RESTORE"
reslen:
RESL            EQU reslen-RES

SAV:
        FCC     "SAVE"
savlen:
SAVL            EQU savlen-SAV

INSERM:
        FCB     EOL
        FCB     EOL
        FCC     "INSERT SAVE DISK IN DRIVE "
GAMDRI:
        FCC     "0."
        FCB     EOL
insermlen:
INSERML         EQU insermlen-INSERM

GAME:
        FCB     EOL
        FCC     "INSERT STORY DISK IN DRIVE 0."
        FCB     EOL
gamelen:
GAMEL           EQU gamelen-GAME

PRESS:
        FCC     "PRESS <ENTER> TO CONTINUE."
        FCB     EOL
        FCC     ">"
presslen:
PRESSL          EQU presslen-PRESS

POSIT:
        FCC     " POSITION"
        FCB     EOL
        FCB     EOL
        FCC     "POSITION 1-7 "
positlen:
POSITL          EQU positlen-POSIT

WDRIV:
        FCB     EOL
        FCC     "DRIVE 0 OR 1 "
wdrivlen:
WDRIVL          EQU wdrivlen-WDRIV

DEFALT:
        FCC     "(DEFAULT IS "
DEFNUM:
        FCC     "0) >"
defalullen:
DEFALL          EQU defalullen-DEFALT

SING:
        FCB     EOL
        FCC     "SAVING"
sinlen:
SINGL           EQU sinlen-SING

RING:
        FCB     EOL
        FCC     "RESTORING"
ringlen:
RINGL           EQU ringlen-RING

PTION:
        FCC     " POSITION "
PDO:
        FCC     "1 ..."
        FCB     EOL
ptionlen:
PTIONL          EQU ptionlen-PTION

ENDTST:
        FCC     "END"
