;	PAGE
;	SBTTL "--- 1-OPS ---"

; -----
; ZERO?
; -----

; Is arg1 equal to zero? [PRED]

ZZERO:
        LDD     ARG1
        LBEQ    PREDS
        JMP     PREDF

; -----
; NEXT?
; -----

; Return the NEXT pointer in object "arg1"; fail if
; none left, and return zero [VALUE][PRED]

ZNEXT:
        LDA     ARG1+1
        JSR     OBJLOC
        LDB     #5                                ; SAME AS FIRST?
        BRA     FIRST1

; ------
; FIRST?
; ------

; Return the FIRST pointer in object "arg1"; fail if
; none, and return zero [VALUE][PRED]

ZFIRST:
        LDA     ARG1+1
        JSR     OBJLOC
        LDB     #6

FIRST1:
        LDX     TEMP
        LDA     B,X                               ; FETCH SLOT
        STA     TEMP+1                            ; SAVE HERE
        PSHS    A                                 ; AND ON STACK
        CLR     TEMP                              ; ZERO MSB
        JSR     PUTVAL
        PULS    A
        TSTA
        LBEQ    PREDF                             ; FAILURE
        JMP     PREDS                             ; OR SUCCESS

; ---
; LOC
; ---

; Return the object containing object "arg1"; zero if none [VALUE]

ZLOC:
        LDA     ARG1+1
        JSR     OBJLOC
        LDX     TEMP
        LDA     4,X
        STA     TEMP+1
        CLR     TEMP
        JMP     PUTVAL

; ------
; PTSIZE
; ------

; Return length of prop table "arg1" in bytes [VALUE]

ZPTSIZ:
        LDD     ARG1
        ADDD    #ZCODE
        SUBD    #1
        STD     TEMP
        CLRB
        JSR     PROPL
        INCA
        JMP     PUTBYT

; ---
; INC
; ---

; Increment arg1 [VALUE]

ZINC:
        LDA     ARG1+1
        JSR     VARGET
        LDD     TEMP
        ADDD    #1
ZINC1:
        STD     TEMP
        PSHS    D
        LDA     ARG1+1
        JSR     VARPUT
        PULS    D
        STD     TEMP
        RTS

; ---
; DEC
; ---

; Decrement arg1 [VALUE]

ZDEC:
        LDA     ARG1+1
        JSR     VARGET
        LDD     TEMP
        SUBD    #1
        BRA     ZINC1

; ------
; PRINTB
; ------

; PRINT the string pointed to by BYTE-pointer "arg1"

ZPRB:
        LDD     ARG1
        STD     TEMP
        JSR     SETWRD
        JMP     PZSTR

; ------
; REMOVE
; ------

; Move object "arg1" to pseudo-object #0

ZREMOV:
        LDA     ARG1+1
        JSR     OBJLOC
        LDX     TEMP
        LDA     4,X
        BEQ     REMVEX                            ; NO OBJECT

        PSHS    X                                 ; SAVE [TEMP]

        JSR     OBJLOC
        LDX     TEMP
        LDA     6,X
        CMPA    ARG1+1
        BNE     REMVC1

        PULS    X                                 ; RETRIEVE FORMER [TEMP]
        PSHS    X                                 ; SAVE COPY ON STACK

        LDA     5,X                               ; OLD [TEMP] IS IN [X]
        LDX     TEMP
        STA     6,X

        BRA     REMVC2

REMVC1:
        JSR     OBJLOC
        LDX     TEMP
        LDA     5,X
        CMPA    ARG1+1
        BNE     REMVC1

        PULS    X
        PSHS    X

        LDA     5,X
        LDX     TEMP
        STA     5,X

REMVC2:
        PULS    X
        CLR     4,X
        CLR     5,X

REMVEX:
        RTS

; ------
; PRINTD
; ------

; Print short description of object "arg1"

ZPRD:
        LDA     ARG1+1

PRNTDC:
        JSR     OBJLOC
        LDX     TEMP
        LDD     7,X
        ADDD    #1                                ; INCREMENT
        STD     TEMP                              ; AND SAVE
        JSR     SETWRD
        JMP     PZSTR

; ------
; RETURN
; ------

; Return from a CALL with value "arg1"

ZRET:
        LDU     OZSTAK                            ; STAY IN SYNC!
        JSR     POPSTK                            ; POP # LOCALS
        STB     VAL                               ; SAVE COUNT HERE

        COMA                                      ; COMPLEMENT [A]
        CMPA    VAL                               ; SHOULD BE OPPOSITE OF [B]
        BNE     RETERR                            ; IF NOT, STACK IS BAD (BM 11/24/84)

        TSTB                                      ; CHECK # LOCALS
        BEQ     RET2                              ; SKIP IF NO LOCALS

; RESTORE LOCAL VARIABLES

        LDX     #LOCALS                           ; SET UP A POINTER
        ASLB                                      ; WORD-ALIGN THE INDEX
        ABX                                       ; [X] POINTS TO LAST LOCAL VAR

RET1:
        JSR     POPSTK                            ; POP A VALUE ([X] UNAFFECTED)
        STD     ,--X                              ; SAVE IN [LOCALS], UPDATE INDEX
        DEC     VAL
        BNE     RET1                              ; LOOP TILL ALL LOCALS POPPED

; RESTORE OTHER VARIABLES

RET2:
        JSR     POPSTK
        STD     ZPCH                              ; RESTORE TOP 9 BITS OF ZPC
        JSR     POPSTK
        STB     ZPCL                              ; RESTORE LOWER 8 BITS OF ZPC
        JSR     POPSTK
        STD     OZSTAK                            ; AND OLD ZSP
        CLR     ZPCFLG                            ; PC NO LONGER VALID

        LDD     ARG1
        STD     TEMP                              ; PASS THE RETURN VALUE
        JMP     PUTVAL                            ; TO PUTVAL

; *** ERROR #15: Z-STACK DESTROYED ***

RETERR:
        LDA     #15
        JMP     ZERROR

; ----
; JUMP
; ----

; Branch to location pointed to by 16-bit 2's-comp "arg1"

ZJUMP:
        LDD     ARG1                              ; TREAT LIKE A BRANCH
        SUBD    #1                                ; THAT ALWAYS SUCCEEDS
        STD     TEMP
        JMP     PREDB3

; -----
; PRINT
; -----

; Print the z-string pointed to by WORD-pointer "arg1"

ZPRINT:
        LDD     ARG1
        STD     TEMP                              ; TELL SETSTR
        JSR     SETSTR                            ; WHERE THE STRING RESIDES
        JMP     PZSTR                             ; AND PRINT IT

; -----
; VALUE
; -----

; Return value of arg1 [VALUE]

ZVALUE:
        LDA     ARG1+1                            ; GRAB VARIABLE ID
        JSR     VARGET                            ; FETCH ITS VALUE
        JMP     PUTVAL                            ; AND RETURN IT

; ----
; BCOM
; ----

; Complement arg1 [VALUE]

ZBCOM:
        LDD     ARG1                              ; GRAB ARGUMENT
        COMA                                      ; COMPLEMENT MSB
        COMB                                      ; AND LSB
        STD     TEMP                              ; AND PASS TO PUTVAL
        JMP     PUTVAL
