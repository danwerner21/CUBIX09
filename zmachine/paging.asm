;	PAGE
;	SBTTL	"--- TIMESTAMP PAGING ROUTINES (BM 11/24/84) ---"

; --------------------
; FETCH A VIRTUAL WORD
; --------------------

GETWRD:
        BSR     GETBYT
        STA     TEMP
        BSR     GETBYT
        STA     TEMP+1
        RTS

; -----------------
; FETCH NEXT Z-BYTE
; -----------------

NEXTPC:
        TST     ZPCFLG                            ; IS [ZPCPNT] VALID?
        BNE     NPC2                              ; YES, GET THE BYTE

; Z-PAGE HAS CHANGED!

        LDD     ZPCH                              ; GET TOP 9 BITS OF [ZPC]
        TSTA                                      ; IS TOP BIT CLEAR?
        BNE     NPC0                              ; NO, PAGE MUST BE SWAPPED

        CMPB    ZPURE                             ; IS THIS PAGE PRELOADED?
        BHS     NPC0                              ; NO, SWAP IT IN

        ADDB    #ZCODEHIGH                        ; ELSE MAKE IT ABSOLUTE
        BRA     NPC1                              ; AND CONTINUE

NPC0:
        CLR     MPCFLG                            ; INVALIDATE [MPC] FOR SAFETY
        BSR     PAGE                              ; RETURN BUFFER IN [B]

NPC1:
        STB     ZPCPNT                            ; SET MSB OF BUFFER ADDRESS
        CLR     ZPCPNT+1                          ; CLEAR LSB
        LDA     #TRUE
        STA     ZPCFLG                            ; VALIDATE [ZPC]

NPC2:
        LDB     ZPCL                              ; GET BYTE INDEX
        LDX     ZPCPNT                            ; AND PAGE ADDRESS
        ABX                                       ; USE [ZPCL] AS OFFSET
        LDA     ,X                                ; AND FETCH THE BYTE

        INC     ZPCL                              ; POINT TO NEXT BYTE
        BNE     NPC3                              ; CONTINUE IF NO OVERFLOW

        CLR     ZPCFLG                            ; ELSE INVALIDATE [ZPC]
        INC     ZPCM                              ; AND POINT
        BNE     NPC3                              ; TO THE
        INC     ZPCH                              ; NEXT Z-PAGE

NPC3:
        RTS                                       ; RETURN BYTE IN [A]

; ---------------------
; GET NEXT VIRTUAL BYTE
; ---------------------

GETBYT:
        TST     MPCFLG                            ; IS [MPCPNT] VALID?
        BNE     GTBT2                             ; YES, GET THE BYTE

; Z-PAGE HAS CHANGED!

        LDD     MPCH                              ; GET TOP 9 BITS OF [MPC]
        TSTA                                      ; IS TOP BIT CLEAR?
        BNE     GTBT0                             ; NO, PAGE MUST BE SWAPPED

PATCH           EQU pth+1                         ; PATCH POINT FOR "VERIFY"
pth:
        CMPB    ZPURE                             ; IS THIS PAGE PRELOADED?
        BHS     GTBT0                             ; NO, SWAP IT IN

        ADDB    #ZCODEHIGH                        ; ELSE MAKE IT ABSOLUTE
        BRA     GTBT1                             ; AND CONTINUE

GTBT0:
        CLR     ZPCFLG                            ; INVALIDATE [ZPC] FOR SAFETY
        BSR     PAGE                              ; RETURN BUFFER PAGE IN [B]

GTBT1:
        STB     MPCPNT                            ; SET MSB OF BUFFER ADDRESS
        CLR     MPCPNT+1                          ; CLEAR LSB
        LDA     #TRUE
        STA     MPCFLG                            ; VALIDATE [MPC]

GTBT2:
        LDB     MPCL                              ; GET BYTE INDEX
        LDX     MPCPNT                            ; AND PAGE ADDRESS
        ABX                                       ; USE [MPCL] AS OFFSET
        LDA     ,X                                ; AND FETCH THE BYTE

        INC     MPCL                              ; POINT TO NEXT BYTE
        BNE     GTBT3                             ; CONTINUE IF NO OVERFLOW

        CLR     MPCFLG                            ; ELSE INVALIDATE [MPC]
        INC     MPCM                              ; AND POINT
        BNE     GTBT3                             ; TO THE
        INC     MPCH                              ; NEXT Z-PAGE

GTBT3:
        RTS                                       ; RETURN BYTE IN [A]

; -------------------------
; LOCATE A SWAPPABLE Z-PAGE
; -------------------------

; ENTRY: TARGET PAGE IN [D] (TOP 9 BITS)
; EXIT: ABSOLUTE BUFFER PAGE IN [B]

PAGE:
        STD     DBLOCK                            ; SAVE TARGET PAGE HERE
        CLR     ZPAGE                             ; CLEAR INDEX
        LDX     #PTABLE                           ; START AT BOTOM OF TABLE
PG0:
        CMPD    ,X++                              ; FOUND IT?
        BEQ     PG1                               ; YES!
        INC     ZPAGE                             ; ELSE COUNT NEXT PAGE
        CMPX    TABTOP                            ; ANY BUFFERS LEFT?
        BLO     PG0                               ; NO, KEEP SEARCHING

; SWAP IN THE TARGET PAGE

        BSR     EARLY                             ; FIND THE EARLIEST PAGE
        LDB     SWAP                              ; MOVE ITS INDEX
        STB     ZPAGE                             ; INTO [ZPAGE]

        ADDB    PAGE0                             ; CALC ABSOLUTE PAGE OF BUFFER
        STB     DBUFF                             ; TELL DISK WHERE TO PUT DATA
        CLR     DBUFF+1                           ; CLEAR LSB

        LDX     #PTABLE                           ; GET THE PAGING TABLE ADDRESS
        LDB     ZPAGE                             ; AND THE BUFFER OFFSET
        ABX                                       ; ADD THE OFFSET
        ABX                                       ; TWICE FOR WORD ALIGNMENT
        LDD     DBLOCK                            ; RETRIEVE PAGE ID
        STD     ,X                                ; SPLICE IT INTO THE TABLE

        JSR     GETDSK                            ; MOVE BLOCK [DBLOCK] TO [DBUFF]

; UPDATE THE TIMESTAMP

PG1:
        LDB     ZPAGE                             ; GET BUFFER INDEX
        LDX     #LRUMAP                           ; CALC ADDRESS OF ENTRY
        ABX                                       ; IN TIMESTAMP MAP
        LDA     ,X                                ; GET BUFFER'S LAST STAMP
        CMPA    STAMP                             ; SAME AS CURRENT STAMP?
        BEQ     PG5                               ; EXIT IF SO

        INC     STAMP                             ; UPDATE [STAMP]
        BNE     PG4                               ; IF STAMP OVERFLOWS ...

; HANDLE STAMP OVERFLOW

        BSR     EARLY                             ; GET EARLIEST STAMP INTO [LRU]

        LDX     #LRUMAP                           ; GET BASE ADDRESS OF STAMPS
        CLRB                                      ; INIT STAMP COUNTER
PG2:
        LDA     ,X                                ; GET A STAMP
        BEQ     PG3                               ; SKIP IF ALREADY ZERO
        SUBA    LRU                               ; ELSE SUBTRACT OFF EARLIEST STAMP
        STA     ,X                                ; AND REPLACE IT
PG3:
        LEAX    +1,X                              ; INCREMENT BASE ADDRESS
        INCB                                      ; AND COUNTER
        CMPB    PMAX                              ; OUT OF PAGES YET?
        BLO     PG2                               ; LOOP TILL DONE

        LDA     #0                                ; TURN BACK THE CLOCK
        SUBA    LRU                               ; ON [STAMP]
        STA     STAMP                             ; TO REFLECT TABLE FUDGING

; STAMP THE PAGE WITH CURRENT TIME

PG4:
        LDX     #LRUMAP
        LDB     ZPAGE
        ABX
        LDA     STAMP
        STA     ,X

PG5:
        LDB     ZPAGE                             ; GET PAGE OFFSET
        ADDB    PAGE0                             ; MAKE IT ABSOLUTE
        RTS                                       ; AND RETURN IT IN [B]

; -------------------------
; LOCATE EARLIEST TIMESTAMP
; -------------------------

; EXIT: [LRU] = EARLIEST STAMP READING
;       [SWAP] = INDEX TO EARLIEST BUFFER

EARLY:
        CLR     SWAP                              ; RESET [SWAP]
        LDA     LRUMAP                            ; FETCH 1ST READING FOR COMPARISONS
        LDX     #LRUMAP+1                         ; POINT TO 2ND READING
        LDB     #1                                ; INIT BUFFER INDEX
EAR0:
        CMPA    ,X                                ; IS THIS STAMP EARLIER THAN [A]?
        BLO     EAR1                              ; NO, TRY NEXT
        LDA     ,X                                ; ELSE MAKE THIS READING THE "NEW" LOWEST
        STB     SWAP                              ; AND REMEMBER WHERE WE FOUND IT
EAR1:
        LEAX    +1,X                              ; UPDATE POINTER
        INCB                                      ; AND BUFFER INDEX
        CMPB    PMAX                              ; OUT OF BUFFERS YET?
        BLO     EAR0                              ; LOOP TILL DONE

        STA     LRU                               ; SAVE EARLIEST STAMP FOUND
        RTS                                       ; AND RETURN

; ---------------------
; POINT [MPC] TO [TEMP]
; ---------------------

SETWRD:
        LDD     TEMP
        STD     MPCM
        CLR     MPCH
        CLR     MPCFLG
        RTS
