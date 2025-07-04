;	PAGE
;	SBTTL "--- MAIN LOOP SUPPORT ---"

; -----------------------
; FETCH A SHORT IMMEDIATE
; -----------------------

GETSHT:
        JSR     NEXTPC                            ; NEXT Z-BYTE IS
        STA     TEMP+1                            ; THE LSB OF ARGUMENT
        CLR     TEMP                              ; MSB IS ZERO
        RTS

; ----------------------
; FETCH A LONG IMMEDIATE
; ----------------------

GETLNG:
        JSR     NEXTPC                            ; NEXT Z-BYTE IS MSB
        PSHS    A                                 ; SAVE ON STACK
        JSR     NEXTPC                            ; NOW GRAB LSB
        STA     TEMP+1                            ; STORE IT
        PULS    A                                 ; RETRIEVE MSB
        STA     TEMP                              ; AND STORE IT
        RTS

; ----------------
; FETCH A VARIABLE
; ----------------

; GET WITHIN AN OPCODE

VARGET:
        TSTA                                      ; IF NON-ZERO,
        BNE     GETVR1                            ; ACCESS A VARIABLE
        JSR     POPSTK                            ; ELSE TAKE VAR OFF STACK
        BRA     PSHSTK                            ; WITHOUT ALTERING STACK

GETVAR:
        JSR     NEXTPC                            ; GRAB VAR-TYPE BYTE
        TSTA                                      ; IF ZERO,
        BEQ     POPSTK                            ; VALUE IS ON STACK

; IS VARIABLE LOCAL OR GLOBAL?

GETVR1:
        CMPA    #16
        BHS     GETVRG                            ; IT'S GLOBAL

; HANDLE A LOCAL VARIABLE

GETVRL:
        DECA                                      ; FORM A ZERO-ALIGNED INDEX
        ASLA                                      ; WORD INDEX
        LDX     #LOCALS                           ; INTO LOCAL VAR TABLE
        TFR     A,B                               ; MOVE AND
GTVX:
        ABX                                       ; ADD INDEXING OFFSET
        LDD     ,X                                ; FETCH VALUE
        STD     TEMP                              ; AND RETURN IT
        RTS

; HANDLE A GLOBAL VARIABLE

GETVRG:
        SUBA    #16                               ; ZERO-ALIGN
        LDX     GLOBAL                            ; BASE OF GLOBAL VAR TABLE
        TFR     A,B                               ; CONVERT TO WORD-ALIGNED INDEX
        ABX                                       ; BY ADDING OFFSET TWICE (CLEVER, EH?)
        BRA     GTVX                              ; 2ND ADD ABOVE

; --------------
; RETURN A VALUE
; --------------

; RETURN FROM WITHIN OPCODE

VARPUT:
        TSTA                                      ; IF NON-ZERO
        BNE     PUTVR1                            ; ACCESS A VARIABLE
        PULU    D                                 ; ELSE FLUSH TOP ITEM OFF STACK
        CMPU    #TOPSTA
        BHI     UNDER                             ; WATCH FOR UNDERFLOW!
        BRA     PSHSTK                            ; AND PUSH [TEMP] ONTO STACK

; RETURN A ZERO

RET0:
        CLRA                                      ; CLEAR MSB

; RETURN BYTE IN [A]

PUTBYT:
        STA     TEMP+1                            ; USE [A] AS LSB
        CLR     TEMP                              ; ZERO MSB

; RETURN VALUE IN [TEMP]

PUTVAL:
        LDX     TEMP                              ; GET VALUE IN [TEMP]
        PSHS    X                                 ; AND HOLD ON TO IT
        JSR     NEXTPC                            ; GET VAR-TYPE BYTE
        PULS    X                                 ; RETRIEVE VALUE
        STX     TEMP                              ; PUT IT BACK IN [TEMP]
        TSTA                                      ; IF TYPE-BYTE IS ZERO,
        BEQ     PSHSTK                            ; VALUE GOES TO THE STACK

; LOCAL OR GLOBAL?

PUTVR1:
        CMPA    #16
        BHS     PUTVLG                            ; IT'S GLOBAL

; HANDLE A LOCAL VARIABLE

PUTVLL:
        DECA
        ASLA
        TFR     A,B
        LDX     #LOCALS                           ; INTO LOCAL VARIABLE TABLE
PTVX:
        ABX
        LDD     TEMP
        STD     ,X
        RTS

; HANDLE A GLOBAL VARIABLE

PUTVLG:
        SUBA    #16                               ; ZERO-ALIGN
        LDX     GLOBAL                            ; BASE OF GLOBAL VAR TABLE
        TFR     A,B                               ; FORM WORD-ALIGNED INDEX
        ABX                                       ; BY ADDING OFFSET TO BASE
        BRA     PTVX                              ; TWICE

; --------------------
; PUSH [TEMP] TO STACK
; --------------------

PSHSTK:
        LDD     TEMP

; PUSH [D] TO STACK

PSHDZ:
        PSHU    D
        CMPU    #ZSTACK
        BLO     OVER
        RTS

; -------------------------
; POP STACK, SAVE IN [TEMP]
; -------------------------

POPSTK:
        PULU    D                                 ; PULL A WORD
        STD     TEMP                              ; SAVE IT IN [TEMP]
        CMPU    #TOPSTA
        BHI     UNDER
        RTS

; *** ERROR #5 -- Z-STACK UNDERFLOW ***

UNDER:
        LDA     #5
        JMP     ZERROR

; *** ERROR #6 -- Z-STACK OVERFLOW ***

OVER:
        LDA     #6
        JMP     ZERROR

; ---------------
; PREDICATE FAILS
; ---------------

PREDF:
        JSR     NEXTPC                            ; GET 1ST BRANCH BYTE
        TSTA                                      ; IF BIT 7 ISN'T SET,
        BPL     PREDB                             ; DO THE BRANCH

PREDNB:
        ANDA    #%01000000                        ; ELSE TEST BIT 6
        BNE     PNBX                              ; ALL DONE IF SET
        JSR     NEXTPC                            ; ELSE SKIP OVER 2ND BRANCH BYTE
PNBX:
        RTS                                       ; BEFORE LEAVING

; ------------------
; PREDICATE SUCCEEDS
; ------------------

PREDS:
        JSR     NEXTPC
        TSTA                                      ; IF BIT 7 IS SET,
        BPL     PREDNB                            ; BRANCH ON PREDICATE FAILURE

; ----------------
; PERFORM A BRANCH
; ----------------

PREDB:
        BITA    #%01000000                        ; LONG OR SHORT BRANCH?
        BEQ     PREDLB                            ; LONG IF BIT 6 IS OFF
        ANDA    #%00111111                        ; ELSE FORM SHORT OFFSET
        STA     TEMP+1                            ; USE AS LSB OF BRANCH OFFSET
        CLR     TEMP                              ; ZERO MSB OF OFFSET
        BRA     PREDB1                            ; AND DO THE BRANCH

; HANDLE A LONG BRANCH

PREDLB:
        ANDA    #%00111111                        ; FORM MSB OF OFFSET
        BITA    #%00100000                        ; CHECK SIGN OF 14-BIT VALUE
        BEQ     DOB2                              ; IT'S POSITIVE
        ORA     #%11100000                        ; ELSE EXTEND SIGN BITS
DOB2:
        PSHS    A                                 ; SAVE MSB OF BRANCH
        JSR     NEXTPC                            ; GRAB NEXT Z-BYTE
        STA     TEMP+1                            ; USE AS LSB OF BRANCH
        PULS    A
        STA     TEMP                              ; RETRIEVE MSB

; BRANCH TO Z-ADDRESS IN [TEMP]

PREDB1:
        LDD     TEMP                              ; IF OFFSET IS ZERO,
        LBEQ    ZRFALS                            ; DO AN "RFALSE"
        SUBD    #1                                ; IF OFFSET IS ONE,
        LBEQ    ZRTRUE                            ; DO AN "RTRUE"

PREDB3:
        SUBD    #1                                ; D = OFFSET-2
        STD     TEMP                              ; SAVE NEW OFFSET

; USE [VAL] TO HOLD TOP 9 BITS OF OFFSET

        STA     VAL+1
        CLRB
        ASLA                                      ; EXTEND THE SIGN BIT
        ROLB                                      ; SHIFT CARRY TO BIT 0 OF [B]
        STB     VAL                               ; SAVE AS UPPER BYTE OF OFFSET

        LDA     TEMP+1                            ; GET LOW BYTE OF OFFSET
        ANDCC   #%11111110                        ; CLEAR CARRY
        ADCA    ZPCL                              ; ADD LOW BYTE OF CURRENT ZPC
        BCC     PDB0                              ; IF OVERFLOWED,

        INC     VAL+1                             ; UPDATE
        BNE     PDB0                              ; UPPER
        INC     VAL                               ; 9 BITS

PDB0:
        STA     ZPCL                              ; LOW-BYTES CALCED

        LDD     VAL                               ; IF 9 UPPER BITS ARE ZERO,
        BEQ     PDB1                              ; NO NEED TO CHANGE PAGES

        LDA     VAL+1                             ; ELSE ADD MIDDLE BYTES
        ANDCC   #%11111110                        ; CLEAR CARRY
        ADCA    ZPCM
        STA     ZPCM
        LDA     VAL                               ; NOW ADD THE TOP BITS
        ADCA    ZPCH                              ; USING PREVIOUS CARRY
        ANDA    #%00000001                        ; ISOLATE BIT 0
        STA     ZPCH
        CLR     ZPCFLG                            ; CHANGED PAGES
PDB1:
        RTS
