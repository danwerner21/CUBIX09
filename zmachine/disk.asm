;	PAGE
;	SBTTL "--- DISK I/O ---"


; ------------------------
; READ A Z-BLOCK FROM DISK
; ------------------------

; ENTRY: DRIVE # (0 OR 1) IN [DRIVE]
;        BLOCK # IN [DBLOCK]
;        BUFFER ADDRESS IN [DBUFF]
OPENGAMEDSK:
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
        SWI
        FCB     59
; READ 256 BYTES
        LDD     DBLOCK
        ANDB    #01
        TFR     B,A
        LDB     #$00
        STB     DTEMP
        ADDD    #INFCB+10
        TFR     D,Y                               ; D SHOULD CONTAIN START ADDRESS IN BUFFER
!
        TFR     Y,X
        LDA     ,X+                               ; GET BYTE
        TFR     X,Y
        LDX     DBUFF
        STA     ,X
        INC     DBUFF+1
        BNE     BUFINC
        INC     DBUFF
BUFINC:
        DEC     DTEMP
        LDB     DTEMP
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

DTEMP
        FCB     00


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

        FCB     24                                ;String to OS
        FCB     13
        FCN     'ENTER FILENAME:'
        SWI
        FCB     3                                 ; GET FILENAME
        SWI
        FCB     9
        LDA     'S'
        STA     ,X+
        LDA     'A'
        STA     ,X+
        LDA     'V'
        STA     ,X+
        LDU     #SAVFCB                           ; OPEN FILE FOR WRITE/CREATE
        SWI
        FCB     71

        LDX     #SING
        LDB     #SINGL
        JSR     DLINE                             ; "SAVING"

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

        LDX     #LOCALS                           ; (SAVE 512 BYTES -- MORE THAN NEEDED, BUT  . . .)
        LDU     #SAVFCB
        SWI
        FCB     60

        LDX     #ZSTACK                           ; SAVE CONTENTS OF STACK (512 BYTES)
        LDU     #SAVFCB
        SWI
        FCB     60

; SAVE GAME PRELOAD

        LDX     #ZCODE                            ; START OF PRELOAD
        LDA     ZCODE+ZPURBT                      ; SIZE OF PRELOAD (MSB, # PAGES)
        CLC                                       ; DIVIDE BY 2
        RORA                                      ;
        INCA                                      ; ROUND UP
        STA     TEMP                              ; USE [TEMP] AS INDEX

LSAVE:
        PSHS    X
        LDU     #SAVFCB
        SWI
        FCB     60
        PULS    X
        TFR     X,D
        ADDD    #$200
        TFR     D,X
        DEC     TEMP                              ; SAVED ENTIRE PRELOAD YET?
        BNE     LSAVE                             ; NO, KEEP SAVING
        LDU     #SAVFCB
        SWI
        FCB     57                                ; CLOSE FILE
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

        FCB     24                                ;String to OS
        FCB     13
        FCN     'ENTER FILENAME:'
        SWI
        FCB     3                                 ; GET FILENAME
        SWI
        FCB     9
        LDA     'S'
        STA     ,X+
        LDA     'A'
        STA     ,X+
        LDA     'V'
        STA     ,X+
        BEQ     >                                 ; NO FILE ERROR
        FCB     24                                ;String to OS
        FCB     13
        FCN     'UNABLE TO RESTORE.'
        JMP     DSKERR
!
        LDU     #SAVFCB                           ; OPEN FILE
        SWI
        FCB     55
        SWI
        FCB     59
        LDX     #RING
        LDB     #RINGL
        JSR     DLINE                             ; "RESTORING"

; SAVE LOCALS ON MACHINE STACK
; IN CASE OF ERROR

        LDX     #LOCALS                           ; POINT TO LOCALS STORAGE
        STX     DBUFF                             ; POINT TO 1ST PAGE TO RESTORE
LOCLP:
        LDD     ,X++                              ; GRAB A LOCAL
        PSHS    D                                 ; AND PUSH IT
        CMPX    #LOCALS+30                        ; SAVED 15 LOCALS YET?
        BLO     LOCLP                             ; NO, KEEP PUSHING

        LDX     #SAVFCB+10                        ; RETRIEVE LOCALS/BUFFER PAGE
        LDY     #LOCALS
        LDB     #00
!
        LDA     ,X+
        STA     ,Y+
        INCB
        BNE     <

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
        LDD     #$200                             ; begin game load
        LDU     #SAVFCB
        SWI
        FCB     64

        LEAS    +30,S                             ; POP OLD LOCALS OFF STACK
        LDD     ZCODE+ZSCRIP
        STD     VAL                               ; SAVE FLAGS

        LDX     #ZSTACK                           ; RETRIEVE
        STD     DBUFF                             ; CONTENTS OF Z-STACK (512 bytes)
        LDU     #SAVFCB
        SWI
        FCB     58

DOREST:
        LDX     #ZCODE                            ; NOW RETRIEVE
        STD     DBUFF                             ; 1ST TWO PAGES OF PRELOAD
        LDU     #SAVFCB
        SWI
        FCB     58

        LDA     ZCODE+ZPURBT                      ; DETERMINE # PAGES
        CLC
        RORA
        INCA
        STA     TEMP                              ; TO RETRIEVE

LREST:
        PSHS    X
        LDU     #SAVFCB
        SWI
        FCB     58
        PULS    X
        TFR     X,D
        ADDD    #$200
        TFR     D,X
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


PRESS:
        FCC     "PRESS <ENTER> TO CONTINUE."
        FCB     EOL
        FCC     ">"
presslen:
PRESSL          EQU presslen-PRESS


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

ENDTST:
        FCC     "END"
