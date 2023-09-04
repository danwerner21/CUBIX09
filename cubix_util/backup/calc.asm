;*
;* CALC: Simple Programmers Desk Calculator
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE
        ORG     OSUTIL
CALC
        STS     SAVSTK                            ;SAVE STACK POINTER
        SWI
        FCB     4                                 ;TEST FOR OPERAND
        BNE     OPSUP                             ;OPERAND WAS SUPPLIED
        DEC     FLAG                              ;SET INTERACTIVE FLAG
CALC1
        SWI
        FCB     24                                ;OUTPUT PROMPT
        FCN     'Calc>'                           ;STRING TO OUTPUT
        SWI
        FCB     3                                 ;GET LINE OF INPUT
        SWI
        FCB     4                                 ;TEST FOR OPERAND SUPPLIED
        BEQ     CLEND                             ;IF NOT, QUIT
        BSR     OPSUP1                            ;CALCULATE AND DISPLAY
        BRA     CALC1                             ;BACK FOR MORE
;* AN OPERAND WAS SUPPLIED
OPSUP
        CMPA    #'?'                              ;HELP WANTED?
        BEQ     HELP                              ;IF SO, GIVE IT TO HIM
;* EVALUATE EXPRESSIONS, AND DISPLAY RESULTS
OPSUP1
        LBSR    EVAL                              ;EVALUATE OPERANDS
        PSHS    A,B                               ;SAVE RESULT
        SWI
        FCB     26                                ;OUTPUT RESULT IN DCIMAL
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     ' $'                              ;MESSAGE TO OUTPUT
        PULS    A,B                               ;RESTORE VALUE
        SWI
        FCB     27                                ;OUTPUT IN HEX
        SWI
        FCB     22                                ;NEW LINE
        SWI
        FCB     4                                 ;TEST MORE
        BNE     OPSUP1                            ;AND CONTINUE
CLEND
        CLRA
        RTS
;* DISPLAY HELP MESSAGE
HELP
        SWI
        FCB     25                                ; DISPLAY MESSAGE
        FCN     'Use: CALC [expression ...]'
        CLRA
        RTS
;*
;* GET A VALUE FROM THE COMMAND LINE, RETURN IN 'D'
;*
GETVAL
        LDA     ,Y+                               ;GET PRECEDING SYMBOL?
;* TEST FOR '=' SWAP HIGH AND LOW BYTES
        CMPA    #'='                              ;IS IT A REVERSE CHARACTER?
        BNE     GETV1                             ;IF NO, NOTHING SPECIAL TO DO
        BSR     GETVAL                            ;EVALUATE NEXT VALUE ELEMENT
        EXG     A,B                               ;SWAP HIGH AND LOW
        BRA     GETEN1                            ;AND EXIT
;* TEST FOR '-' NEGATE VALUE
GETV1
        CMPA    #'-'                              ;IS IT NEGATE?
        BNE     GETV2                             ;NO, ITS OK
        BSR     GETVAL                            ;EVALUATE NEXT
        CLRA
        CLRB
        SUBD    VAL1                              ;CALCULATE NEGATE
        BRA     GETEN1                            ;AND EXIT
;* TEST FOR '~' ONE'S COMPLEMENT
GETV2
        CMPA    #'~'                              ;COMPLEMENT?
        BNE     GETHEX                            ;NO, ITS OK
        BSR     GETVAL                            ;EVALUATE NEXT
        COMA                                      ;	COMPLEMENT HIGH
        COMB                                      ;	COMPLEMENT LOW
GETEN1
        STD     VAL1                              ;SAVE RESULT
        RTS
;* TEST FOR HEXIDECIMAL NUMBER
GETHEX
        PSHS    X                                 ;SAVE 'X'
        LDX     #0                                ;START WITH ZERO
        CMPA    #'$'                              ;IS IT A HEX NUMBER?
        BNE     GETBIN                            ;NOT A HEX NUMBER, TRY BINARY
GETH1
        LBSR    TSTEXP                            ;TEST FOR TERMINATOR
        BEQ     GETEND                            ;IF SO, LAST CHARACTER
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #10                               ;0-9?
        BLO     GETH2                             ;IF SO, IT'S OK
        CMPA    #$11                              ;< 'A'?
        BLT     SYNERR                            ;IF SO, IT'S BAD
        SUBA    #7                                ;CONVERT TO HEX
        CMPA    #$10                              ;IS IT 0-F?
        BHS     SYNERR                            ;IF SO, IT'S BAD
GETH2
        STA     TEMP                              ;SAVE FOR TEMPORARY VALUE
        LDD     #16                               ;MULTIPLY BY 16 (SHIFT FOUR BITS)
        SWI
        FCB     107                               ;D=D;*X
        ORB     TEMP                              ;INCLUDE EXTRA DIGIT
        TFR     D,X                               ;REPLACE IN 'X'
        BRA     GETH1                             ;DO NEXT
;* TEST FOR BINARY NUMBER
GETBIN
        CMPA    #'%'                              ;IS IT BINARY?
        BNE     GETOCT                            ;NO, TRY OCTAL
GETB1
        LBSR    TSTEXP                            ;TEST FOR A TERMINATOR
        BEQ     GETEND                            ;IF END, CONTINUE WITH EXPRESSION
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #1                                ;TEST FOR IN RANGE
        BHI     SYNERR                            ;IF INVALID, SAY SO
        PSHS    A                                 ;SAVE THIS VALUE
        TFR     X,D                               ;COPY TO ACCUMULATOR
        LEAX    D,X                               ;SHIFT BY ONE BIT
        PULS    B                                 ;RESTORE VALUE
        ABX                                       ;	INSERT THIS BIT
        BRA     GETB1                             ;CONTINUE LOOKING
;* END OF EXPRESSION, EXIT
GETEND
        TFR     X,D                               ;D = VALUE
        STD     VAL1                              ;SET VALUE
        PULS    X,PC                              ;RESTORE & RETURN
;* TEST FOR OCTAL NUMBER
GETOCT
        CMPA    #'@'                              ;IS IT OCTAL?
        BNE     GETCHR                            ;NO, TRY CHARACTER
GETO1
        LBSR    TSTEXP                            ;TEST FOR TERMINATOR
        BEQ     GETEND                            ;IF END, CONTINUE
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #7                                ;IN RANGE?
        BHI     SYNERR                            ;INVALID
        STA     TEMP                              ;SAVE TEMP
        LDD     #8                                ;MUL BY 8
        SWI
        FCB     107                               ;DO MULTIPLY
        ORB     TEMP                              ;INCLUDE
        TFR     D,X                               ;COPY BACK
        BRA     GETO1                             ;CONTINUE
;* INVALID HEX DIGIT
SYNERR
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     'Syntax Error.'
EVARET
        LDS     SAVSTK                            ;GET STACK VALUE
        LDA     FLAG                              ;GET INTERACTIVE FLAG
        LBNE    CALC1                             ;AND CONTINUE
        LDA     #1                                ;INDICATE INVALID OPERAND
        RTS
;* TEST FOR QUOTED STRING
GETCHR
        CMPA    #$27                              ;IS IT A QUOTE?
        BNE     GETDEC                            ;NO, TRY DECIMAL NUMBER
GETC1
        LDA     ,Y+                               ;GET CHAR
        BEQ     SYNERR                            ;END OF LINE
        CMPA    #$0D                              ;END OF LINE MEANS SCREWUP
        BEQ     SYNERR                            ;INVALID STRING
        CMPA    #$27                              ;CLOSING QUOTE
        BEQ     GETEND                            ;OF SO, THATS IT
        STA     TEMP                              ;SAVE CHAR
        TFR     X,D                               ;COPY TO ACCUMULATOR
        TFR     B,A                               ;SHIFT UP
        LDB     TEMP                              ;INCLUDE LOWER CHAR
        TFR     D,X                               ;REPLACE OLD VALUE
        BRA     GETC1                             ;GET NEXT CHARACTER
;* TEST FOR DECIMAL NUMBER
GETDEC
        CMPA    #'0'                              ;IS IT < '0'?
        BLO     SYNERR                            ;NO, IT'S NOT DECIMAL
        CMPA    #'9'                              ;IS IT > '9'
        BHI     SYNERR                            ;NO, NOT DECIMAL
        LEAY    -1,Y                              ;BACKUP TO START OF LINE
GETD1
        LBSR    TSTEXP                            ;TEST FOR END OF DIGIT STRING
        BEQ     GETEND                            ;IF SO, QUIT
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #9                                ;ARE WE DECIMAL?
        BHI     SYNERR                            ;IF NOT, GET UPSET
        STA     TEMP                              ;SAVE DIGIT
        LDD     #10                               ;MULTIPLY BY 10
        SWI
        FCB     107                               ;D=D;*X
        ADDB    TEMP                              ;ADD IN DIGIT
        ADCA    #0                                ;INSURE HIGH INCS
        TFR     D,X                               ;SAVE IN X FOR NEXT ITERATION
        BRA     GETD1                             ;KEEP GOING
;*
;* EVALUATE ANY OPERANDS
;*
EVAL
        PSHS    X                                 ;SAVE 'X'
        LBSR    GETVAL                            ;GET VALUE
EVAL1
        TFR     D,X                               ;SAVE OLD VALUE
EVAL2
        SWI
        FCB     5                                 ;GET NEXT CHAR
        BNE     TRYADD                            ;TRY ADD
        TFR     X,D                               ;GET VALUE
EVEXIT
        STD     VAL1                              ;SET VALUE
        PULS    X,PC                              ;RESTORE & RETURN
;* TEST FOR ADDITION
TRYADD
        CMPA    #'+'                              ;IS THIS ADDITION?
        BNE     TRYSUB                            ;NO, TRY SUBTRACTION
        LBSR    GETVAL                            ;GET NEW OPERAND VALUE
        TFR     X,D                               ;COPY TO ACCUMULATOR
        ADDD    VAL1                              ;ADD TO OLD VALUE
        BRA     EVAL1                             ;BACK TO CALLER
;* TRY SUBTRACTION
TRYSUB
        CMPA    #'-'                              ;SUBTRACT?
        BNE     TRYMUL                            ;NO, TRY MULTIPLICATION
        LBSR    GETVAL                            ;EVALUATE NEXT EXPRESSION
        TFR     X,D                               ;COPY TO ACCUMULATOR FOR ARITHMITIC
        SUBD    VAL1                              ;SUBTRACT NEW VALUE
        BRA     EVAL1                             ;ALL DONE
;* MULTIPLY OPERANDS
TRYMUL
        CMPA    #'*'                              ;IS IT A MULTIPLY?
        BNE     TRYDIV                            ;NO, TRY LOGICAL OR
        LBSR    GETVAL                            ;EVALUATE SECOND OPERAND
        SWI
        FCB     107                               ;DO MULTIPLY
        BRA     EVAL1                             ;ALL DONE
;* DIVIDE OPERATION
TRYDIV
        CMPA    #'/'                              ;DIVISION?
        BNE     TRYMOD                            ;NO, TRY MODULUS
        LBSR    GETVAL                            ;GET OPERAND
        SWI
        FCB     108                               ;X=X/D
        BRA     EVAL2                             ;AND KEEP RESULT
;* MODULUS OPERATION
TRYMOD
        CMPA    #'\'                              ;MODULUS?
        BNE     TRYOR                             ;NO, TRY OR
        LBSR    GETVAL                            ;GET OPERAND
        SWI
        FCB     108                               ;X=X/D
        BRA     EVAL1                             ;RETURN REMAINDER
;* LOGICAL OR OF OPERANDS
TRYOR
        CMPA    #'|'                              ;IS IT OR?
        BNE     TRYAND                            ;NO, TRY LOGICAL AND
        LBSR    GETVAL                            ;CALCULATE OPERAND VALUE
        TFR     X,D                               ;GET OLD VALUE
        ORA     VAL1                              ;PERFORM OR
        ORB     VAL1+1                            ;ON BOTH BYTES
        BRA     EVAL1                             ;CONTINUE
;* LOGICAL AND OF OPERANDS
TRYAND
        CMPA    #'&'                              ;IS IT AND?
        BNE     TRYXOR                            ;NO, TRY XOR
        LBSR    GETVAL                            ;EVALUATE OPERANDS
        TFR     X,D                               ;GET OLD VALUE
        ANDA    VAL1                              ;AND WITH OLD
        ANDB    VAL1+1                            ;AND SECOND BYTE
        BRA     EVAL1                             ;CONTINUE
;* EXCLUSIVE OR OPERATION
TRYXOR
        CMPA    #'^'                              ;IS IT XOR?
        LBNE    SYNERR                            ;NO, ERROR
        LBSR    GETVAL                            ;EVALUATE OPERANDS
        TFR     X,D                               ;GET OLD VALUE
        EORA    VAL1                              ;XOR WITH OLD
        EORB    VAL1+1                            ;XOR SECOND BYTE
        BRA     EVAL1                             ;CONTINUE
;*
;* TEST FOR VALID EXPRESSION ELEMENT TERMINATOR
;*
TSTEXP
        LDA     ,Y                                ;GET CHARACTER
        BEQ     TSTEND                            ;TERMINATOR
        CMPA    #'+'                              ;PLUS SIGN
        BEQ     TSTEND                            ;OK
        CMPA    #'-'                              ;MINUS SIGN
        BEQ     TSTEND                            ;IS ALSO OK
        CMPA    #'&'                              ;LOCAIAL AND?
        BEQ     TSTEND                            ;IF SO, IT'S OK
        CMPA    #'|'                              ;LOGICAL OR?
        BEQ     TSTEND                            ;IF SO, IT'S OK
        CMPA    #'^'                              ;EXCLUSIVE OR?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #'*'                              ;MULTIPLY?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #'/'                              ;DIVIDE?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #'\'                              ;MODULUS?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #' '                              ;SPACE IS VALID
        BEQ     TSTEND                            ;IF SO, QUIT
        CMPA    #$0D                              ;CARRIAGE RETURN IS LAST
        BEQ     TSTEND                            ;IF NOT, SAY SO
        LEAY    1,Y                               ;DON'T SKIP END OF LINE
TSTEND
        RTS
;* TEMPORARY STORAGE
TEMP
        FDB     0                                 ;TEMP STORAGE
VAL1
        FDB     0                                 ;TEMP STORAGE
FLAG
        FCB     0                                 ;INTERACTIVE FLAG
SAVSTK
        RMB     2                                 ;SAVED STACK POINTER
