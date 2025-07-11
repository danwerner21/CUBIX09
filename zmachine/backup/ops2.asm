;	PAGE
;	SBTTL "--- 2-OPS ---"

; -----
; LESS?
; -----

; Is arg1 less than arg2? [PRED]

ZLESS:
        LDD     ARG1
        STD     TEMP
        LDD     ARG2
        STD     VAL
        BRA     CEXIT

; -----
; GRTR?
; -----

; Is arg1 greater than arg2? [PRED]

ZGRTR:
        LDD     ARG1
        STD     VAL
        LDD     ARG2
        STD     TEMP
        BRA     CEXIT

; ------
; DLESS?
; ------

; Decrement variable "arg1"; succeed if new value
; is less than arg2 [PRED]

ZDLESS:
        JSR     ZDEC                              ; DECREMENT THE VARIABLE
        LDD     ARG2
        STD     VAL
        BRA     CEXIT                             ; AND COMPARE

; ------
; IGRTR?
; ------

; Increment variable "arg1"; succeed if new value is
; greater than arg2 [PRED]

ZIGRTR:
        JSR     ZINC                              ; INCREMENT THE VARIABLE
        LDD     TEMP
        STD     VAL
        LDD     ARG2
        STD     TEMP

CEXIT:
        BSR     SCOMP
        BLO     POK
PBAD:
        JMP     PREDF

; -----------------
; SIGNED COMPARISON
; -----------------

SCOMP:
        LDA     VAL                               ; ARE ARGUMENTS
        EORA    TEMP                              ; SIGNED THE SAME?
        BPL     SCMP                              ; YES, DO ORDINARY COMPARE
        LDA     VAL                               ; ELSE COMPARE
        CMPA    TEMP                              ; ONLY THE HIGH BYTES
        RTS

SCMP:
        LDD     TEMP
        CMPD    VAL
        RTS

; ---
; IN?
; ---

; Is object "arg1" contained in object "arg2?" [PRED]

ZIN:
        LDA     ARG1+1
        JSR     OBJLOC
        LDX     TEMP
        LDA     ARG2+1
        CMPA    4,X
        BNE     PBAD
POK:
        JMP     PREDS

; ----
; BTST
; ----

; Is every "on" bit in arg1 also "on" in arg2? [PRED]

ZBTST:
        LDD     ARG2
        ANDA    ARG1
        ANDB    ARG1+1
        CMPD    ARG2
        BEQ     POK
        BRA     PBAD

; ---
; BOR
; ---

; Return bitwise OR of arg1 and arg2 [VALUE]

ZBOR:
        LDD     ARG1
        ORA     ARG2
        ORB     ARG2+1
ZB0:
        STD     TEMP
        JMP     PUTVAL

; ----
; BAND
; ----

; Return bitwise AND of arg1 and arg2 [VALUE]

ZBAND:
        LDD     ARG1
        ANDA    ARG2
        ANDB    ARG2+1
        BRA     ZB0

; -----
; FSET?
; -----

; Is flag "arg2" set in object "arg1?" [PRED]

ZFSETP:
        JSR     FLAGSU                            ; GET BIT
        LDD     VAL
        ANDA    MASK
        STA     VAL
        ANDB    MASK+1
        ORB     VAL
        BNE     POK                               ; BIT IS ON
        BRA     PBAD

; ----
; FSET
; ----

; Set flag "arg2" in object "arg1"

ZFSET:
        JSR     FLAGSU
        LDX     TEMP                              ; ADDRESS OF FLAGS
        LDD     VAL                               ; GRAB FLAGS
        ORA     MASK                              ; SUPERIMPOSE THE
        ORB     MASK+1                            ; MASKING PATTERN
        STD     ,X                                ; AND REPLACE FLAG
        RTS

; ------
; FCLEAR
; ------

; Clear flag "arg2" in object "arg1"

ZFCLR:
        JSR     FLAGSU
        LDX     TEMP                              ; ADDRESS OF OBJECT
        LDD     MASK                              ; GRAB THE MASK
        COMA                                      ; COMPLEMENT IT
        COMB
        ANDA    VAL                               ; SUPERIMPOSE FLAGS
        ANDB    VAL+1                             ; TO MASK OUT TARGET
        STD     ,X                                ; REPLACE THE FLAGS
        RTS

; ---
; SET
; ---

; Set variable "arg1" equal to value "arg2"

ZSET:
        LDD     ARG2
        STD     TEMP
        LDA     ARG1+1
        JMP     VARPUT

; ----
; MOVE
; ----

; Put object "arg1" into object "arg2"

ZMOVE:
        JSR     ZREMOV                            ; REMOVE OBJECT FIRST
        LDA     ARG1+1
        JSR     OBJLOC                            ; GET ADDRESS OF OBJECT
        LDX     TEMP                              ; PUT ADDRESS IN X
        PSHS    X                                 ; SAVE IT HERE TOO
        LDA     ARG2+1
        STA     4,X

        JSR     OBJLOC
        LDX     TEMP
        LDA     6,X
        STA     VAL                               ; HOLD HERE FOR A MOMENT
        LDA     ARG1+1
        STA     6,X
        PULS    X                                 ; RESTORE OLD [TEMP]
        LDA     VAL
        BEQ     ZMVEX
        STA     5,X
ZMVEX:
        RTS

; ---
; GET
; ---

; Return value of item "arg2" in WORD-table at "arg1" [VALUE]

ZGET:
        ASL     ARG2+1
        ROL     ARG2                              ; WORD-ALIGN ARG2
        LDD     ARG2
        ADDD    ARG1                              ; ADD OFFSET TO TABLE ADDRESS
        STD     TEMP
        JSR     SETWRD
        JSR     GETWRD
        JMP     PUTVAL

; ----
; GETB
; ----

; Return value of item "arg2" in BYTE-table at "arg1" [VALUE]

ZGETB:
        LDD     ARG1
        ADDD    ARG2
        STD     TEMP
        JSR     SETWRD
        JSR     GETBYT
        STA     TEMP+1
        CLR     TEMP
        JMP     PUTVAL

; ----
; GETP
; ----

; Return prop "arg2" of object "arg1"; if specified prop
; doesn't exist, return prop'th element of default object [VALUE]

ZGETP:
        JSR     PROPB                             ; GET POINTER TO PROPS
GETP1:
        JSR     PROPN
        CMPA    ARG2+1
        BEQ     GETP2
        BLO     GETP3

        JSR     PROPNX
        BRA     GETP1                             ; TRY AGAIN WITH NEXT PROP

GETP3:
        LDD     ZCODE+ZOBJEC                      ; Z-ADDR OF OBJECT TABLE
        ADDD    #ZCODE                            ; FORM THE ABSOLUTE ADDRESS
        TFR     D,X                               ; USE AS AN INDEX
        LDB     ARG2+1                            ; GET PROPERTY #
        DECB
        ASLB
        ABX                                       ; ADD TO TABLE ADDRESS
        LDD     ,X                                ; FETCH THE PROPERTY
        BRA     ETPEX                             ; AND PASS IT ON

GETP2:
        JSR     PROPL
        INCB                                      ; SOMETHING SHOULD BE IN B!
        TSTA                                      ; AND IN A!
        BEQ     GETP2A
        CMPA    #1
        BEQ     GETP2B

; *** ERROR #7: PROPERTY LENGTH ***

        LDA     #7
        JSR     ZERROR

GETP2B:
        LDX     TEMP
        ABX
        LDD     ,X
        BRA     ETPEX

GETP2A:
        LDX     TEMP
        ABX
        LDB     ,X
        CLRA
ETPEX:
        STD     TEMP
        JMP     PUTVAL

; -----
; GETPT
; -----

; Return a POINTER to prop table "arg2" in object "arg1" [VALUE]

ZGETPT:
        JSR     PROPB
GETPT1:
        JSR     PROPN
        CMPA    ARG2+1
        BEQ     GETPT2
        LBLO    RET0
        JSR     PROPNX                            ; TRY NEXT ENTRY
        BRA     GETPT1

GETPT2:
        INC     TEMP+1
        BNE     GPT
        INC     TEMP
GPT:
        CLRA                                      ; ADD OFFSET IN [B]
        ADDD    TEMP
        SUBD    #ZCODE                            ; CHANGE TO RELATIVE POINTER
        STD     TEMP
        JMP     PUTVAL

; -----
; NEXTP
; -----

; Return prop index number of the prop following prop "arg2"
; in object "arg1"; return zero if last property; return
; 1st prop # if arg2=0; error if no prop "arg2" in "arg1" [VALUE]

ZNEXTP:
        JSR     PROPB
        LDA     ARG2+1
        BEQ     NXTP2

NXTP1:
        JSR     PROPN
        CMPA    ARG2+1
        BEQ     NXTP3
        LBCS    RET0
        JSR     PROPNX                            ; TRY NEXT ENTRY
        BRA     NXTP1

NXTP3:
        JSR     PROPNX

NXTP2:
        JSR     PROPN
        JMP     PUTBYT

; ---
; ADD
; ---

; Return (arg1+arg2) [VALUE]

ZADD:
        LDD     ARG1
        ADDD    ARG2
MATH:
        STD     TEMP
        JMP     PUTVAL

; ---
; SUB
; ---

; Return (arg1-arg2) [VALUE]

ZSUB:
        LDD     ARG1
        SUBD    ARG2
        BRA     MATH

; ---
; MUL
; ---

; Return (arg1*arg2) [VALUE]

ZMUL:
        LDX     #17                               ; INIT LOOP INDEX
        CLRA                                      ; CLEAR THE
        CLRB                                      ; CARRY
        STD     MTEMP                             ; AND TEMP REGISTER

ZMLOOP:
        ROR     MTEMP
        ROR     MTEMP+1
        ROR     ARG2                              ; SHIFT A BIT
        ROR     ARG2+1                            ; INTO POSITION
        BCC     ZMNEXT                            ; NO ADDITION IF BIT CLEAR

        LDD     ARG1
        ADDD    MTEMP
        STD     MTEMP

ZMNEXT:
        LEAX    -1,X                              ; ALL BITS EXAMINED?
        BNE     ZMLOOP                            ; NO, KEEP SHIFTING

        LDD     ARG2                              ; ELSE GRAB PRODUCT
        BRA     MATH                              ; AND RETURN

; ---------
; DIV & MOD
; ---------

; DIV: Return quotient of int(arg1/arg2) [VALUE]
; MOD: Return remainder of int(arg1/arg2) [VALUE]

ZDIV:
        BSR     DVINIT
        JMP     PUTVAL                            ; AND SHIP OUT [TEMP]

ZMOD:
        BSR     DVINIT
        LDD     VAL                               ; RETURN THE
        BRA     MATH                              ; REMAINDER IN [VAL]

; -----------
; DIVIDE INIT
; -----------

DVINIT:
        LDD     ARG1
        STD     TEMP
        LDD     ARG2
        STD     VAL

; FALL THROUGH ...

; ---------------
; SIGNED DIVISION
; ---------------

; ENTRY: DIVIDEND IN [TEMP], DIVISOR IN [VAL]
; EXIT: QUOTIENT IN [TEMP], REMAINDER IN [VAL]

DIVIDE:
        LDA     TEMP                              ; SIGN OF REMAINDER
        STA     SREM                              ; IS ALWAYS SIGN OF DIVIDEND
        EORA    VAL                               ; SIGN OF QUOTIENT IS POSITIVE
        STA     SQUOT                             ; IF SIGNS OF TERMS ARE THE SAME

        TST     TEMP                              ; IF DIVIDEND IS NEGATIVE,
        BPL     TABS                              ; CALC ABSOLUTE VALUE
        BSR     ABTEMP

TABS:
        TST     VAL                               ; IF DIVISOR IS NEGATIVE,
        BPL     DOUDIV                            ; DO THE SAME
        BSR     ABSVAL

DOUDIV:
        BSR     UDIV                              ; UNSIGNED DIVIDE

        TST     SQUOT
        BPL     RFLIP
        BSR     ABTEMP

RFLIP:
        TST     SREM
        BPL     DIVEX

; FALL THROUGH ...

; -------------
; CALC ABS(VAL)
; -------------

ABSVAL:
        CLRA
        CLRB
        SUBD    VAL
        STD     VAL

DIVEX:
        RTS

; --------------
; CALC ABS(TEMP)
; --------------

ABTEMP:
        CLRA
        CLRB
        SUBD    TEMP
        STD     TEMP
        RTS

; -----------------
; UNSIGNED DIVISION
; -----------------

; ENTRY: DIVIDEND IN [TEMP], DIVISOR IN [VAL]
; EXIT: QUOTIENT IN [TEMP], REMAINDER IN [VAL]

UDIV:
        LDD     VAL
        BEQ     DIVERR                            ; CAN'T DIVIDE BY ZERO!

        LDX     #16                               ; INIT LOOP INDEX
        CLRA                                      ; CLEAR THE
        CLRB                                      ; CARRY
        STD     MTEMP                             ; AND HI-DIVIDEND REGISTER

UDLOOP:
        ROL     TEMP+1
        ROL     TEMP
        ROL     MTEMP+1
        ROL     MTEMP

        LDD     MTEMP                             ; IS DIVIDEND < DIVISOR?
        SUBD    VAL
        BCS     UDNEXT                            ; YES, CLEAR THE CARRY AND LOOP
        STD     MTEMP                             ; ELSE UPDATE DIVIDEND
        COMA                                      ; SET THE CARRY
        BRA     DECX                              ; AND LOOP

UDNEXT:
        CLRA                                      ; CLEAR CARRY

DECX:
        LEAX    -1,X
        BNE     UDLOOP

        ROL     TEMP+1                            ; SHIFT LAST CARRY INTO PLACE
        ROL     TEMP
        LDD     MTEMP                             ; MOVE REMAINDER INTO
        STD     VAL                               ; ITS RIGHTFUL PLACE
        RTS

; *** ERROR #8: DIVISION ***

DIVERR:
        LDA     #8
        JSR     ZERROR
