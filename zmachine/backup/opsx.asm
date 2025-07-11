;	PAGE
;	SBTTL "--- X-OPS ---"

; ------
; EQUAL?
; ------

ZEQUAL:
        DEC     ARGCNT
        BNE     DOEQ

; *** ERROR #9: NOT ENOUGH "EQUAL?" ARGS ***

        LDA     #9
        JSR     ZERROR

DOEQ:
        LDD     ARG1
        CMPD    ARG2
        BEQ     EQOK
        DEC     ARGCNT
        BEQ     EQBAD

        CMPD    ARG3
        BEQ     EQOK
        DEC     ARGCNT
        BEQ     EQBAD

        CMPD    ARG4
        BEQ     EQOK
EQBAD:
        JMP     PREDF

EQOK:
        JMP     PREDS

; ----
; CALL
; ----

; Branch to function pointed to by [arg1 * 2], passing
; the optional parameters "arg2" thru "arg4" [VALUE]

ZCALL:
        LDD     ARG1                              ; DID FUNCTION = 0?
        BNE     DOCALL                            ; NO, CONTINUE
        JMP     MATH                              ; ELSE RETURN A ZERO

DOCALL:
        LDD     OZSTAK                            ; ZSP FROM PREVIOUS ZCALL
        JSR     PSHDZ
        LDB     ZPCL                              ; LOW 8 BITS OF ZPC
        JSR     PSHDZ                             ; SAVE TO Z-STACK
        LDD     ZPCH                              ; PUSH H & M PC
        JSR     PSHDZ

; MULTIPLY ARG1 BY 2; FORM 17-BIT ADDR

        CLRA
        ASL     ARG1+1                            ; BOTTOM 8 BITS
        ROL     ARG1                              ; MIDDLE 8
        ROLA                                      ; TOP BIT
        STA     ZPCH
        LDD     ARG1
        STD     ZPCM
        CLR     ZPCFLG                            ; [ZPC] HAS CHANGED ...

        JSR     NEXTPC                            ; FETCH # NEW LOCALS
        STA     TEMP2                             ; SAVE IT HERE FOR INDEXING
        STA     TEMP2+1                           ; AND HERE FOR REFERENCE
        BEQ     ZCALL2                            ; NO LOCALS IN THIS FUNCTION

; SAVE OLD LOCALS, REPLACE WITH NEW

        LDX     #LOCALS                           ; INIT POINTER
ZCALL1:
        LDD     ,X                                ; GRAB AN OLD LOCAL
        PSHS    X                                 ; SAVE THE POINTER
        JSR     PSHDZ                             ; PUSH OLD LOCAL TO Z-STACK
        JSR     NEXTPC                            ; GET MSB OF NEW LOCAL
        PSHS    A                                 ; SAVE HERE
        JSR     NEXTPC                            ; NOW GET LSB
        TFR     A,B                               ; POSITION IT PROPERLY
        PULS    A                                 ; RETRIEVE MSB
        PULS    X                                 ; THIS IS WHERE IT GOES
        STD     ,X++                              ; STORE NEW LOCAL, UPDATE POINTER
        DEC     TEMP2                             ; ANY MORE OLD LOCALS?
        BNE     ZCALL1                            ; KEEP LOOPING TILL DONE

ZCALL2:
        DEC     ARGCNT                            ; EXTRA ARGUMENTS IN THIS CALL?
        BEQ     ZCALL4                            ; NO ARGS TO PASS

; MOVE UP TO 3 ARGS TO LOCAL STORAGE

ZCALL3:
        LDD     ARG2
        STD     LOCALS
        DEC     ARGCNT
        BEQ     ZCALL4
        LDD     ARG3
        STD     LOCALS+2
        DEC     ARGCNT
        BEQ     ZCALL4
        LDD     ARG4
        STD     LOCALS+4

ZCALL4:
        LDB     TEMP2+1                           ; REMEMBER # LOCALS SAVED
        TFR     B,A                               ; COPY INTO [A]
        COMA                                      ; COMPLEMENT FOR ERROR CHECK (BM 11/24/84)
        JSR     PSHDZ                             ; AND RETURN
        STU     OZSTAK                            ; "THE WAY WE WERE ..."
        RTS

; ---
; PUT
; ---

; Set item "arg2" in WORD-table "arg1" equal to "arg3"

ZPUT:
        ASL     ARG2+1                            ; WORD-ALIGN
        ROL     ARG2                              ; ARG2
        LDD     ARG2
        ADDD    ARG1                              ; ADD Z-ADDR OF TABLE
        ADDD    #ZCODE                            ; FORM ABSOLUTE ADDRESS
        TFR     D,X                               ; FOR USE AS AN INDEX
        LDD     ARG3
        STD     ,X
        RTS

; ----
; PUTB
; ----

; Set item "arg2" in BYTE-table "arg1" equal to "arg3"

ZPUTB:
        LDD     ARG2
        ADDD    ARG1
        ADDD    #ZCODE
        TFR     D,X
        LDA     ARG3+1
        STA     ,X
        RTS

; ----
; PUTP
; ----

; Set property "arg2" in object "arg1" equal to "arg3"

ZPUTP:
        JSR     PROPB
PUTP1:
        JSR     PROPN
        CMPA    ARG2+1
        BEQ     PUTP2
        BHS     PTP

; *** ERROR #10: BAD PROPERTY NUMBER ***

        LDA     #10
        JSR     ZERROR                            ; ERROR #7 (BAD PROPERTY #)

PTP:
        JSR     PROPNX                            ; NEXT ITEM
        BRA     PUTP1

PUTP2:
        JSR     PROPL
        INCB
        TSTA
        BEQ     PUTP2A
        CMPA    #1
        BEQ     PTP1

; *** ERROR #11: PROPERTY LENGTH ***

        LDA     #11
        JSR     ZERROR                            ; ERROR #8 (PROP TOO LONG)

PTP1:
        LDX     TEMP
        ABX
        LDD     ARG3
        STD     ,X
        RTS

PUTP2A:
        LDA     ARG3+1
        LDX     TEMP
        ABX
        STA     ,X
        RTS

; ------
; PRINTC
; ------

; Print the character with ASCII value "arg1"

ZPRC:
        LDA     ARG1+1
        JMP     COUT

; ------
; PRINTN
; ------

; Print "arg1" as a signed integer

ZPRN:
        LDD     ARG1
        STD     TEMP

; PRINT THE SIGNED VALUE IN [TEMP]

NUMBER:
        LDD     TEMP
        BPL     DIGCNT                            ; IF NUMBER IS NEGATIVE,
        LDA     #$2D                              ; START WITH A MINUS SIGN
        JSR     COUT
        JSR     ABTEMP                            ; GET ABS(TEMP)

; COUNT # OF DECIMAL DIGITS

DIGCNT:
        CLR     MASK                              ; RESET INDEX
DGC:
        LDD     TEMP                              ; CHECK QUOTIENT
        BEQ     PRNTN3                            ; SKIP IF ZERO
        LDD     #10
        STD     VAL                               ; ELSE DIVIDE BY 10
        JSR     UDIV                              ; UNSIGNED DIVIDE
        LDA     VAL+1                             ; GET LSB OF REMAINDER
        PSHS    A                                 ; SAVE ON STACK
        INC     MASK                              ; INCREMENT CHAR COUNT
        BRA     DGC                               ; LOOP TILL ARG1=0

PRNTN3:
        LDA     MASK
        BEQ     PZERO                             ; PRINT AT LEAST A "0"
PRNTN4:
        PULS    A                                 ; GET A CHAR
        ADDA    #$30                              ; CONVERT TO ASCII NUMBER
        JSR     COUT
        DEC     MASK                              ; OUT OF CHARS?
        BNE     PRNTN4                            ; KEEP PRINTING TILL
        RTS                                       ; DONE

; PRINT A ZERO

PZERO:
        LDA     #$30                              ; ASCII "0"
        JMP     COUT

; ------
; RANDOM
; ------

; Return a random value between zero and "arg1" [VALUE]

ZRAND:
        LDD     ARG1                              ; USE [ARG1]
        STD     VAL                               ; AS THE DIVISOR

        LDD     RAND1                             ; GET A RANDOM #
        ADDD    #$AA55                            ; DO WEIRD THINGS
        STA     RAND2                             ; SAVE AS
        STB     RAND1                             ; NEW SEED
        ANDA    #%01111111                        ; MAKE POSITIVE
        STD     TEMP                              ; MAKE IT THE DIVIDEND

        JSR     DIVIDE                            ; UNSIGNED DIVIDE!
        LDD     VAL                               ; GET REMAINDER
        ADDD    #1                                ; AT LEAST 1
        JMP     MATH

; ----
; PUSH
; ----

; Push "arg1" onto the Z-stack

ZPUSH:
        LDD     ARG1
        JMP     PSHDZ

; ---
; POP
; ---

; Pop a word off Z-stack and store in variable "arg1"

ZPOP:
        JSR     POPSTK
        LDA     ARG1+1                            ; GET VARIABLE ID
        JMP     VARPUT

; -----
; SPLIT
; -----

ZSPLIT          EQU ZNOOP

; ------
; SCREEN
; ------

ZSCRN           EQU ZNOOP
