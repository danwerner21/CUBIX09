;	PAGE
;	SBTTL "--- 0-OPS ---"

; -----
; RTRUE
; -----

; Simulate a RETURN 1

ZRTRUE:
        LDB     #1

ZRT:
        CLRA
        STD     ARG1                              ; SAVE VALUE HERE
        JMP     ZRET

; ------
; RFALSE
; ------

; Simulate a RETURN 0

ZRFALS:
        CLRB
        BRA     ZRT

; ------
; PRINTI
; ------

; Print the Z-string immediately following the opcode

ZPRI:
        LDA     ZPCH                              ; MOVE ZPC INTO MPC
        STA     MPCH
        LDD     ZPCM
        STD     MPCM
        CLR     MPCFLG                            ; ZERO MPC FLAG

        JSR     PZSTR                             ; PRINT THE STRING AT [MPC]

        LDA     MPCH                              ; UPDATE ZPC FROM MPC
        STA     ZPCH
        LDD     MPCM
        STD     ZPCM
        LDA     MPCFLG                            ; ALSO UPDATE FLAG
        STA     ZPCFLG
        LDD     MPCPNT                            ; AND PAGE POINTER
        STD     ZPCPNT

; FALL THROUGH TO ...

; ----
; NOOP
; ----

ZNOOP:
        RTS

; ------
; PRINTR
; ------

; Execute a PRINTI, followed by CRLF and RTRUE

ZPRR:
        BSR     ZPRI
        JSR     ZCRLF
        BRA     ZRTRUE

; ------
; RSTACK
; ------

; Execute a RETURN, with CALL value on top of the stack

ZRSTAK:
        JSR     POPSTK
        STD     ARG1                              ; TOS WAS LEFT IN [D]
        JMP     ZRET

; ------
; VERIFY
; ------

; Verify the game code

ZVER:
        JSR     VERNUM                            ; DISPLAY ZIP VERSION CODE
        LDD     ZCODE+ZLENTH                      ; GET LENGTH OF Z-CODE
        STD     ARG2                              ; IN WORDS

; CLEAR VARIABLES

        CLRA
        CLRB
        STD     ARG1
        STD     ARG3                              ; BIT 17 OF Z-CODE LENGTH
        STD     TEMP                              ; BYTE COUNT

; CONVERT Z-CODE LENGTH TO BYTES

        ASL     ARG2+1                            ; BOTTOM 8 BITS
        ROL     ARG2                              ; MIDDLE 8 BITS
        ROL     ARG3+1                            ; 17TH BIT OF LENGTH

        LDA     #$40                              ; 1ST 64 BYTES
        STA     TEMP+1                            ; ARE NOT CHECKED
        JSR     SETWRD                            ; [TEMP] POINTS TO FIRST BYTE

        LDA     #ARG3                             ; PATCH [GETBYT] ROUTINE
        STA     PATCH                             ; SO PRELOAD WILL BE READ FROM DISK

VSUM:
        JSR     GETBYT                            ; GET A BYTE
        CLRB                                      ; CLEAR CARRY
        ADCA    ARG1+1                            ; ADD TO SUM
        STA     ARG1+1
        BCC     VSUM0
        INC     ARG1

VSUM0:
        LDD     MPCM                              ; END OF GAME YET?
        CMPD    ARG2
        BNE     VSUM

        LDA     MPCH                              ; ALSO CHECK TOP BIT
        CMPA    ARG3+1
        BNE     VSUM

        LDA     #ZPURE
        STA     PATCH                             ; UNPATCH [GETBYT]

        LDD     ZCODE+ZCHKSM                      ; GET CHECKSUM
        CMPD    ARG1                              ; SAME AS CALCULATED?
        LBEQ    PREDS                             ; YES, PREDICATE SUCCEEDS
        JMP     PREDF                             ; ELSE FAILURE ...
