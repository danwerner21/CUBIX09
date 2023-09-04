;	title	MICRO FORTH 1.0
;*
;* MICRO FORTH 1.0
;*
;*    This is a small fast implementation of a forth language for
;* the Motorola 6809 microprocessor. It is unique in that there is
;* no interpreter, all words are directly executable.
;*
;* Copyright 1984-2005 Dave Dunfield
;* All rights reserved.
;*
;* SYSTEM equATES
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
WIDTH           = 65                              ;TERMINAL SCREEN WIDTH MARGIN
LSTLOK          = OSRAM                           ;POINTER TO LAST WORD PROCESSED FROM INPUT BUFFER
TEMP            = LSTLOK+2                        ;TEMPORARY STORAGE
INPBUF          = TEMP+2                          ;INPUT BUFFER
RSTACK          = LSTLOK+256                      ;RETURN STACK
DSTACK          = RSTACK+256                      ;DATA STACK
;*
        ORG     DSTACK                            ;BEGINNING OF FORTH CODE
;* INITIALIZATIONS, START UP FORTH
        LDS     #RSTACK                           ;SET UP RETURN STACK
        LDU     #DSTACK                           ;SET UP DATA STACK
;* IF DESIRED, YOU CAN IMPLEMENT A STARTUP MESSAAGE HERE
;* INSERT THE MESSAGE AT THE VERY END OF THIS FILE.
;*	LDX	#USRSPC  ;POINT TO STARTUP MESSAGE
;*	LBSR	PMSG1  ;DISPLAY IT
        JSR     [BOOT+3]                          ;EXECUTE PRESET ROUTINE (USUALLY 'QUIT')
        LBRA    BYE                               ;EXIT FORTH
;* SUBROUTINE TO OBTAIN VARIABLES ADDRESS ON STACK.
;* USED BY 'VARIABLE' TYPE WORDS
VARIAB
        LDX     ,S++                              ;GET FOLLOWING ADDRESS
        PSHU    X                                 ;SAVE
        RTS                                       ;	RETURN TO CALLER
;* MESSAGES
PROMPT
        FCB     $0A,$0D                           ;NEW LINE
        FCN     'Ok>'                             ;PROMPT
ERMSG1
        FCN     'Error: '                         ;ERROR PREFIX
ERMSG2
        FCB     $27,$20,$00                       ;ERROR SUFFIX
REDMSG
        FCN     'Redef: '                         ;RE-DEFINITION INDICATOR
DELMSG
        FCB     8,' ',8,0                         ;MESSAGE FOR CHARACTER DELETE
;*
;* START	OF USER	DICTIONARY
;* DICTIONARY FORMAT:
;*   1)	- WORD DESCRIPTOR BYTE, FORMAT:
;*	BIT 7	    - ALWAYS SET, INDICATES THIS IS DESCRIPTOR BYTE
;*	BITS 7-3    - CURRENTLY NOT USED
;*	BIT 2	    - NO-COMPILE BIT, WORD CANNOT BE USED IN COMPILES
;*	BIT 1	    - NO-INTERACTIVE BIT, WORD CANNOT BE USED INTERACTIVELY
;*	BIT 0	    - EXECUTE ON COMPILE BIT, COMPILER EXECUTES WORD IMMEDIATLY
;*  ;      INSTEAD OF COMPILING INTO DEFINITION
;*   2)	- WORD NAME, VARIABLE LENGTH, STORED BACKWARDS
;*   3)	- ADDRESS OF PREVIOUS WORD IN DICTIONARY, ADDRESS MUST POINT TO FIRST
;*	  BYTE OF CODE WHICH IMMEDIATLY FOLLOWS THIS FIELD IN THE WORD
;*
;*
;* 'DROPN' - DROPS A NUMBER OF WORDS FROM THE STACK
        FCB     $80
        FCC     'NPORD'
        FDB     0                                 ;** END OF DICTIONARY **
DROPN
        LDD     ,U++                              ;GET OPERAND
        ASLB                                      ;	MULTIPLY BY
        ROLA                                      ;	TWO FOR WORD STACK ENTRIES
        LEAU    D,U                               ;MOVE USER STACK
        RTS
;* 'DROP' - DROP ONE WORD FROM THE STACK
        FCB     $80
        FCC     'PORD'
        FDB     DROPN
DROP
        LEAU    2,U                               ;MOVE STACK POINTER
        RTS
;* 'DUP' - DUPLICATE TOP OF STACK
        FCB     $80
        FCC     'PUD'
        FDB     DROP
DUP
        LDD     ,U                                ;GET TOP OF USER STACK
        STD     ,--U                              ;DUPLICATE
        RTS
;* 'OVER' DUPLICATE ONE DOWN FROM TOP OF STACK
        FCB     $80
        FCC     'REVO'
        FDB     DUP
OVER
        LDD     2,U                               ;GET ELEMENT
        STD     ,--U                              ;DUPLICATE
        RTS
;* 'ROT' - ROTATE TOP THREE ELEMENTS ON STACK
        FCB     $80
        FCC     'TOR'
        FDB     OVER
ROT
        LDD     4,U                               ;GET BOTTOM
        LDX     2,U                               ;GET MIDDLE
        STX     4,U                               ;PUT ON BOTTOM
        BRA     SWAP1                             ;DO REST
;* 'SWAP' - SWAP TOP TWO ELEMENTS ON STACK
        FCB     $80
        FCC     'PAWS'
        FDB     ROT
SWAP
        LDD     2,U                               ;GET LOWER ONE
SWAP1
        LDX     ,U                                ;GET TOP
        STX     2,U                               ;PLACE TOP AT LOWER
        STD     ,U                                ;PLACE LOWER AT TOP
        RTS
;* '0=' - TEST FOR TOS EQUAL TO ZERO
        FCB     $80
        FCC     '=0'
        FDB     SWAP
ZEQU
        LDD     ,U                                ;GET TOP OF STACK
        BEQ     RET1                              ;=AL TO ZERO?
        BRA     RET0                              ;NO, RETURN ONE
;* '=' - TEST FOR EQUALITY
        FCB     $80
        FCC     '='
        FDB     ZEQU
EQUALS
        LDD     ,U++                              ;GET TOP OF STACK
        CMPD    ,U                                ;COMPARE WITH NEXT
        BEQ     RET1                              ;SAME, RETURN 1
        BRA     RET0                              ;NO, RETURN ZERO
;* '<>' - TEST FOR NOT EQUAL
        FCB     $80
        FCC     '><'
        FDB     EQUALS
NOTEQU
        LDD     ,U++                              ;GET TOS
        CMPD    ,U                                ;COMPARE WITH NEXT
        BEQ     RET0                              ;NOT SAME, RETURN 1
        BRA     RET1                              ;NO, RETURN 0
;* '>' - TEST FOR GREATER
        FCB     $80
        FCC     '>'
        FDB     NOTEQU
GRTR
        LDD     2,U                               ;GET LOWER ELEMENT
        CMPD    ,U++                              ;COMPARE WITH TOS
        BGT     RET1                              ;GREATER, RETURN 1
        BRA     RET0                              ;NO, RETURN FALSE
;* '<' - TEST FOR LESS
        FCB     $80
        FCC     '<'
        FDB     GRTR
LESS
        LDD     2,U                               ;GET LOWER ELEMENT
        CMPD    ,U++                              ;COMPARE WITH TOS
        BLT     RET1                              ;LOWER, RETURN 1
        BRA     RET0                              ;NO, RETURN FALSE
;* '>=' - TEST FOR GREATER OR EQUAL TO
        FCB     $80
        FCC     '=>'
        FDB     LESS
GREQU
        LDD     2,U                               ;GET LOWER
        CMPD    ,U++                              ;COMPARE WITH TOS
        BLT     RET0                              ;LESS, RETURN FALSE
RET1
        LDB     #1                                ;GET ONE
        BRA     RETS                              ;RETURN IT
;* '<=' - TEST FOR LESS OR EQUAL TO
        FCB     $80
        FCC     '=<'
        FDB     GREQU
LESEQU
        LDD     2,U                               ;GET LOWER
        CMPD    ,U++                              ;COMPARE WITH TOS
        BLE     RET1                              ;LOWER OR EQUAL, RETURN ONE
RET0
        CLRB                                      ;	GET ZERO RESULT
RETS
        CLRA                                      ;	ZERO HIGH BYTE
        STD     ,U                                ;SAVE ON STACK
        RTS
;* '$OUT' - OUTPUT CHARACTER TO TERMINAL
        FCB     $80
        FCC     'TUO$'
        FDB     LESEQU
DOLOUT
        LDD     ,U++                              ;GET CHAR FROM STACK
        TFR     B,A                               ;PUT IN RIGHT REGISTER
        SWI
        FCB     33                                ;GET CHAR FROM SYSTEM
        RTS
;* ' $IN' - INPUT CHARACTER FROM TERMINAL
        FCB     $80
        FCC     'NI$'
        FDB     DOLOUT
DOLIN
        SWI
        FCB     34                                ;GET CHAR FROM SYSTEM
        TFR     A,B                               ;GET IN RIGHT REGISTER
        CLRA                                      ;	ZERO HIGH BYTE
        STD     ,--U                              ;SAVE ON STACK
        RTS
;* 'EMIT' - OUTPUT CHARACTER TO GENERAL OUTPUT
        FCB     $80
        FCC     'TIME'
        FDB     DOLIN
EMIT
        JMP     [DISP+3]                          ;EXECUTE OUTPUT ROUTINE IN '(OUT)' VARIABLE
;* 'KEY' - GET CHARACTER FROM GENERAL INPUT
        FCB     $80
        FCC     'YEK'
        FDB     EMIT
KEY
        JMP     [INPT+3]                          ;EXECUTE INPUT ROUTINE IN '(IN)' VARIABLE
;* 'U.' - OUTPUT UNSIGNED NUMBER IN CURRENT BASE
        FCB     $80
        FCC     '.U'
        FDB     KEY
UDOT
        BRA     DOT01                             ;EXECUTE NUMBER OUTPUT ROUTINE
;* '.' - OUTPUT SIGNED NUMBER IN CURRENT BASE
        FCB     $80
        FCC     '.'
        FDB     UDOT
DOT
        LDD     ,U                                ;GET NUMBER FROM STACK
        BPL     DOT01                             ;IS POSITIVE, ITS OK
        LDB     #'-'                              ;GET MINUS SIGN
        PSHU    A,B                               ;SAVE ON STACK
        JSR     EMIT                              ;OUTPUT MINUS SIGN
        JSR     NEG                               ;NEGATE NUMBER
DOT01
        LDA     #$FF                              ;END IF STREAM INDICATOR
        PSHS    A                                 ;SAVE MARKER ON RETURN STACK
DOT1
        LDD     BASE+3                            ;GET NUMBER BASE FROM 'BASE' VARIABLE
        PSHU    A,B                               ;SAVE BASE
        JSR     USMOD                             ;PERFORM DIVISION
        PULU    A,B                               ;GET REMAINDER
        PSHS    B                                 ;SAVE FOR LATER
        LDD     ,U                                ;GET RESULT
        BNE     DOT1                              ;IF MORE, KEEP GOING
        LEAU    2,U                               ;SKIP LAST RESULT ON STACK
DOT2
        LDB     ,S+                               ;GET CHARACTER FROM STACK
        LBMI    SPACE                             ;END OF DIGITS, OUTPUT SPACE AND EXIT
        ADDB    #$30                              ;CONVERT TO DECIMAL NUMBER
        CMPB    #$39                              ;IN RANGE?
        BLS     DOT3                              ;YES, ITS OK
        ADDB    #7                                ;CONVERT TO ALPHA
DOT3
        PSHU    A,B                               ;SAVE ON STACK
        BSR     EMIT                              ;OUTPUT CHARACTER
        BRA     DOT2                              ;KEEP OUTPUTING
;* '-!' - SUBTRACT FROM SELF AND REASSIGN
        FCB     $80
        FCC     '!-'
        FDB     DOT
MSTOR
        LDX     ,U++                              ;GET ADDRESS
        LDD     ,X                                ;GET CONTENTS
        SUBD    ,U++                              ;SUBTRACT TOS
        STD     ,X                                ;RESAVE CONTENTS
        RTS
;* '+!' - ADD TO SELF AND REASSIGN
        FCB     $80
        FCC     '!+'
        FDB     MSTOR
PSTOR
        LDX     ,U++                              ;GET ADDRESS
        LDD     ,X                                ;GET CONTENTS
        ADDD    ,U++                              ;ADD IS TOS
        STD     ,X                                ;RESAVE CONTENTS
        RTS
;* 'C!' - CHARACTER (BYTE) STORE OPERATION
        FCB     $80
        FCC     '!C'
        FDB     PSTOR
VSTORC
        LDX     ,U++                              ;GET ADDRESS
        LDD     ,U++                              ;GET DATA FROM STACK
        STB     ,X                                ;SAVE IN VARIABLE
        RTS
;* '!' - WORD STORE OPERATION
        FCB     $80
        FCC     '!'
        FDB     VSTORC
VSTOR
        LDX     ,U++                              ;GET ADDRESS
        LDD     ,U++                              ;GET DATA
        STD     ,X                                ;PERFORM STORE
        RTS
;* 'C@' - CHARACTER READ OPERATION
        FCB     $80
        FCC     '@C'
        FDB     VSTOR
VREADC
        LDB     [,U]                              ;GET CHARACTER FROM ADDRESS
        CLRA                                      ;	ZERO HIGH BYTE
        BRA     SAVSD                             ;MOVE TO STACK
;* '@' - WORD READ OPERATION
        FCB     $80
        FCC     '@'
        FDB     VREADC
VREAD
        LDD     [,U]                              ;GET WORD FROM ADDRESS
        BRA     SAVSD                             ;PLACE ON STACK
;* '2/' - DIVIDE BY TWO
        FCB     $80
        FCC     '/2'
        FDB     VREAD
SHR
        LSR     ,U                                ;SHIFT HIGH
        ROR     1,U                               ;SHIFT LOW
        RTS
;* '2;*' - MULTIPLY BY TWO
        FCB     $80
        FCC     '*2'
        FDB     SHR
SHL
        LSL     1,U                               ;SHIFT LOW
        ROL     ,U                                ;SHIFT HIGH
        RTS
;* '+' - ADD OPERATOR
        FCB     $80
        FCC     '+'
        FDB     SHL
ADD
        LDD     ,U++                              ;GET TOS
        ADDD    ,U                                ;ADD IN NEXT
        BRA     SAVSD                             ;PLACE RESULT ON STACK
;* '-' - SUBTRACT OPERATOR
        FCB     $80
        FCC     '-'
        FDB     ADD
SUB
        LDD     2,U                               ;GET LOWER OPERAND
        SUBD    ,U++                              ;SUBTRACT TOS
SAVSD
        STD     ,U                                ;PLACE RESULT ON STACK
        RTS
;* 'D-' DOUBLE PRECISION SUBTRACTION
        FCB     $80
        FCC     '-D'
        FDB     SUB
DMINUS
        LDD     6,U                               ;GET LOW WORD OF LOWER OPERAND
        SUBD    2,U                               ;SUBTRACT LOW WORD OFF HIGHER OPERAND
        STD     6,U                               ;RESAVE LOWER WORD OF OPERAND
        LDD     4,U                               ;GET HIGH WORD OF LOWER OPERAND
        SBCB    1,U                               ;SUBTRACT TOP OF STACK
        SBCB    ,U                                ;WITH BORROW FROM PREVIOUS
        LEAU    4,U                               ;FIX UP STACK
        STD     ,U                                ;PLACE HIGH WORD OF RESULT ON STACK
        RTS
;* 'D+' - DOUBLE PRECISION ADDITION
        FCB     $80
        FCC     '+D'
        FDB     DMINUS
DPLUS
        LDD     2,U                               ;GET LOW WORD OF FIRST OPERAND
        ADDD    6,U                               ;ADD LOW WORD OF SECOND OPERAND
        STD     6,U                               ;RESAVE
        LDD     ,U                                ;GET HIGH WORD OF FIRST
        ADCB    5,U                               ;ADD IN HIGH WORD OF
        ADCA    4,U                               ;SECOND WITH CARRY
        LEAU    4,U                               ;FIX UP STACK
        STD     ,U                                ;RESAVE
        RTS
;* 'U;*' - UNSIGNED MULTIPLY
        FCB     $80
        FCC     '*U'
        FDB     DPLUS
UMULT
        LDA     1,U
        LDB     3,U
        MUL
        PSHS    A,B
        LDA     ,U
        LDB     2,U
        MUL
        PSHS    A,B
        LDA     1,U
        LDB     2,U
        MUL
        ADDD    1,S
        BCC     UMUL1
        INC     ,S
UMUL1
        STD     1,S
        LDA     ,U
        LDB     3,U
        MUL
        ADDD    1,S
        BCC     UMUL2
        INC     ,S
UMUL2
        STD     1,S
        PULS    D,X
        STD     ,U
        STX     2,U
        RTS
;* ';*' - SIGNED MULTIPLY
        FCB     $80
        FCC     '*'
        FDB     UMULT
MULT
        LDA     1,U
        LDB     3,U
        MUL
        PSHS    A,B
        LDA     ,U
        LDB     3,U
        MUL
        ADDB    ,S
        STB     ,S
        LDA     1,U
        LDB     2,U
        MUL
        ADDB    ,S
        STB     ,S
        PULS    D
        LEAU    2,U
        STD     ,U
        RTS
;* 'M/MOD' - DIVISION WITH REMAINDER
        FCB     $80
        FCC     'DOM/M'
        FDB     MULT
MSMOD
        CLRA
        CLRB
        LDX     #33
MSMODL
        ANDCC   #$FE
MSMODM
        ROL     5,U
        ROL     4,U
        ROL     3,U
        ROL     2,U
        LEAX    -1,X
        BEQ     MSMODD
        ROLB
        ROLA
        CMPD    ,U
        BLO     MSMODL
        SUBD    ,U
        ORCC    #1
        BRA     MSMODM
MSMODD
        STD     ,U
        RTS
;* 'U/MOD' - UNSIGNED DIVISION WITH REMAINDER
        FCB     $80
        FCC     'DOM/U'
        FDB     MSMOD
USMOD
        LDD     ,U++
        CLR     ,-U
        CLR     ,-U
        STD     ,--U
        JSR     MSMOD
        LDD     ,U++
        STD     ,U
        RTS
;* '/MOD' - DIVISION GIVING REMAINDER
        FCB     $80
        FCC     'DOM/'
        FDB     USMOD
SLMOD
        LDA     2,U
        PSHS    A
        BPL     SLMOD2
        CLRA
        CLRB
        SUBD    2,U
        STD     2,U
        LDA     ,S
SLMOD2
        EORA    ,U
        PSHS    A
        LDD     ,U
        BEQ     SLMODR
        BPL     SLMOD1
        COMA
        COMB
        ADDD    #1
        STD     ,U
SLMOD1
        CLRA
        CLRB
        LDX     #17
SLMODL
        ANDCC   #$FE
SLMODM
        ROL     3,U
        ROL     2,U
        LEAX    -1,X
        BEQ     SLMODD
        ROLB
        ROLA
        CMPD    ,U
        BLO     SLMODL
        SUBD    ,U
        ORCC    #1
        BRA     SLMODM
SLMODD
        TST     1,S
        BPL     SLMOD3
        COMA
        COMB
        ADDD    #1
SLMOD3
        STD     ,U
        TST     ,S++
        BPL     SLMODR
        CLRA
        CLRB
        SUBD    2,U
        STD     2,U
SLMODR
        RTS
;* '/' - DIVISION
        FCB     $80
        FCC     '/'
        FDB     SLMOD
SLASH
        BSR     SLMOD
        LEAU    2,U
        RTS
;* 'AND' - LOGICAL AND
        FCB     $80
        FCC     'DNA'
        FDB     SLASH
AND
        LDD     ,U++                              ;GET TOP OF STACK
        ANDA    ,U                                ;AND HIGH BYTE
        ANDB    1,U                               ;AND LOW BYTE
        BRA     SAVDS                             ;SAVE RESULT AND EXIT
;* 'OR' - LOGICAL OR
        FCB     $80
        FCC     'RO'
        FDB     AND
OR
        LDD     ,U++                              ;GET TOP OF STACK
        ORA     ,U                                ;OR HIGH BYTE
        ORB     1,U                               ;OR LOW BYTE
        BRA     SAVDS                             ;SAVE RESULT AND EXIT
;* 'XOR' - LOGCAL EXCLUSIVE OR
        FCB     $80
        FCC     'ROX'
        FDB     OR
XOR
        LDD     ,U++                              ;GET TOP OF STACK
        EORA    ,U                                ;XOR HIGH BYTE
        EORB    1,U                               ;XOR LOW BYTE
        BRA     SAVDS                             ;SAVE RESULT AND EXIT
;* 'COM' - COMPLEMENT OPERAND
        FCB     $80
        FCC     'MOC'
        FDB     XOR
COM
        COM     ,U                                ;COMPLEMENT HIGH BYTE
        COM     1,U                               ;COMPLEMENT LOW BYTE
        RTS
;* 'NEG' - NEGATE OPERAND
        FCB     $80
        FCC     'GEN'
        FDB     COM
NEG
        BSR     COM                               ;COMPLEMENT OPERAND
        BRA     ONEP                              ;INCREMENT (TWO'S COMPLEMENT)
;* 'ABS' - GIVE ABSOLUTE VALUE OF OPERAND
        FCB     $80
        FCC     'SBA'
        FDB     NEG
ABS
        LDD     ,U                                ;GET VALUE FROM STACK
        BMI     NEG                               ;NEGATIVE, CONVERT
        RTS
;* '2-' - DECREMENT BY TWO
        FCB     $80
        FCC     '-2'
        FDB     ABS
TWOM
        LDD     ,U                                ;GET TOP OF STACK
        SUBD    #2                                ;DECREMENT BY TWO
SAVDS
        STD     ,U                                ;RESAVE TOP OF STACK
        RTS
;* '2+' - INCREMENT BY TWO
        FCB     $80
        FCC     '+2'
        FDB     TWOM
TWOP
        LDD     ,U                                ;GET TOP OF STACK
        ADDD    #2                                ;INCREMENT BY TWO
        BRA     SAVDS                             ;RESAVE TOP OF STACK
;* '1-' - DECREMENT BY ONE
        FCB     $80
        FCC     '-1'
        FDB     TWOP
ONEM
        LDD     ,U                                ;GET TOP OF STACK
        SUBD    #1                                ;DECREMENT BY ONE
        BRA     SAVDS                             ;RESAVE TOP OF STACK
;* '1+' - INCREMENT BY ONE
        FCB     $80
        FCC     '+1'
        FDB     ONEM
ONEP
        LDD     ,U                                ;GET TOP OF STACK
        ADDD    #1                                ;INCREMENT BY ONE
        BRA     SAVDS                             ;RESAVE TOP OF STACK
;* 'SKIP' - ADVANCE INPUT POINTER TO NON-BLANK
        FCB     $80
        FCC     'PIKS'
        FDB     ONEP
QSKIP
        LDY     INPTR+3                           ;GET CURRENT POSITION IN INPUT BUFFER
QSKI1
        LDA     ,Y+                               ;GET CHARACTER FROM INPUT BUFFER
        CMPA    #' '                              ;IS IT A SPACE
        BEQ     QSKI1                             ;YES, KEEP GOING
        LEAY    -1,Y                              ;BACKUP TO IT
        STY     INPTR+3                           ;RESAVE INPUT POINTER
        TSTA                                      ;	TEST FOR END OF LINE
        RTS
;*
;* SUBROUTINE TO LOOKUP WORDS IN DICTIONARY FROM INPUT LINE
;* ON EXIT: 'Z' IS SET IF WORD NOT FOUND
;*	IF WORD IS FOUND ('Z'=0), ITS ADDRESS IS STACKED ON THE
;*	DATA STACK, AND THE WORD DESCRIPTOR BYTE IS RETURNED IN
;*	THE 'A' ACCUMULATOR
;*
LOOKUP
        PSHS    X,Y                               ;SAVE REGISTERS
        BSR     QSKIP                             ;ADVANCE TO WORD
        STY     LSTLOK                            ;SAVE INCASE ERROR
        LDX     HERE+3                            ;GET START OF DICTIONARY
;* SCAN DICTIONARY, LOOKING FOR WORD
LOK1
        PSHS    X                                 ;SAVE CURRENT ADDRESS
        LEAX    -2,X                              ;BACKUP PAST PRECEDING ADDRESS
LOK2
        LDA     ,-X                               ;GET CHARACTER FROM NAME
        BMI     LOK3                              ;DECREIPTOR BYTE, START OF WORD
        CMPA    ,Y+                               ;DOES IT MATCH INPUT BUFFER?
        BEQ     LOK2                              ;YES, KEEP MATCHING TILL END OF WORD
LOK5
        PULS    X                                 ;RESTORE POINTER
        LDX     ,--X                              ;GET ADDRESS OF PREVIOUS WORD
        BEQ     LOK4                              ;END OF DICTIONARY, QUIT
        LDY     INPTR+3                           ;RESTORE INPUT POINTER
        BRA     LOK1                              ;TRY FOR THIS WORD
LOK3
        LDB     ,Y                                ;GET NET CHAR FROM INPUT STREAM
        BSR     TSTERM                            ;IS IT A TERMINATOR?
        BNE     LOK5                              ;NO, WORD DOES NOT MATCH
        PULS    A,B                               ;RESTORE ADDRESS OF WORD
        STD     ,--U                              ;SAVE ON STACK
        BSR     QSKI1                             ;SKIP TO NEXT NON-BLANK
        LDA     ,X                                ;GET DESCRIPTOR BYTE
        ANDCC   #$FB                              ;CLEAR 'Z' FLAG
LOK4
        PULS    X,Y,PC
;* ROUTINE TO TEST FOR TERMINATOR CHARACTER
TSTERM
        CMPB    #' '                              ;IS IT A SPACE?
        BEQ     TSTER1                            ;YES, ITS OK
        TSTB                                      ;	IS IT NULL (END OF LINE)?
TSTER1
        RTS
;* ''' - TICK: RETURN ADDRESS OF A WORD
        FCB     $81,$27
        FDB     QSKIP
TICK
        BSR     LOOKUP                            ;LOOK UP WORD
        BNE     TSTER1                            ;FOUND, RETURN
        LBRA    LOKERR                            ;WORD NOT FOUND, CAUSE ERROR
;* 'EXEC' - EXECUTE AT ADDRESS
        FCB     $80
        FCC     'CEXE'
        FDB     TICK
EXEC
        JMP     [,U++]                            ;EXECUTE AT ADDRESS ON [TOS]
;* 'NUMBER' - GET NUMBER FROM INPUT STREAM IN CURRENT BASE
        FDB     $80
        FCC     'REBMUN'
        FDB     EXEC
NUMBER
        PSHS    X,Y                               ;SAVE REGS
        LBSR    QSKIP                             ;ADVANCE TO NEXT WORD IN INPUT STREAM
        CMPA    #'-'                              ;IS IT A NEGATIVE NUMBER?
        PSHS    CC                                ;SAVE FLAGS FO LATER TEST
        BNE     NUM4                              ;NO, NOT NEGATIVE
        LEAY    1,Y                               ;SKIP '-' SIGN
NUM4
        CLRA                                      ;	START OFF
        CLRB                                      ;	WITH A ZERO RESULT
        PSHU    A,B                               ;SAVE ON STACK
NUM2
        LDB     ,Y+                               ;GET CHAR FROM SOUCE
        SUBB    #'0'                              ;CONVERT TO BINARY
        CMPB    #9                                ;IS IT NUMERIC DIGIT?
        BLS     NUM1                              ;YES, ITS OK
        SUBB    #7                                ;CONVERT FROM ALPHA
        CMPB    #$0A                              ;IS IT A VALID NUMBER?
        BLO     NUM3                              ;NO, CAUSE ERROR
NUM1
        CLRA                                      ;	ZERO HIGH BYTE
        CMPD    BASE+3                            ;ARE WE WITHIN RANGE OF CURRENT BASE
        BHS     NUM3                              ;NO, CAUSE ERROR
        PSHS    A,B                               ;SAVE NUMBER
        LDD     BASE+3                            ;GET BASE
        PSHU    A,B                               ;STACK
        JSR     MULT                              ;PERFORM MULTIPLY (OLD VALUE ALREADY ON DATA STACK)
        PULS    A,B                               ;GET NEW DIGIT BACK
        ADDD    ,U                                ;ADD TO OLD VALUE
        STD     ,U                                ;RESAVE OLD VALUE
        LDB     ,Y                                ;GET NEXT CHARACTER FROM NUMBER
        LBSR    TSTERM                            ;IS IT A TERMINATOR
        BNE     NUM2                              ;NO, KEEP EVALUATING NUMBER
        STY     INPTR+3                           ;RESAVE INPUT POINTER
        PULS    CC,X,Y                            ;RESTORE REGISTERS
        BNE     NUM5                              ;NO NEGATIVE, DON'T NEGATE
        JSR     NEG                               ;NEGATE VALUE
NUM5
        LBRA    ONE                               ;RETURN TRUE (SUCCESS)
NUM3
        PULS    CC,X,Y                            ;CLEAN UP STACK
        LBRA    ZERO                              ;RETURN FALSE (FAILURE)
;* 'SPACE' - DISPLAY A SPACE ON GENERAL OUTPUT
        FCB     $80
        FCC     'ECAPS'
        FDB     NUMBER
SPACE
        LDB     #' '                              ;GET A SPACE
        PSHU    A,B                               ;PLACEON DATA STACK
        JMP     EMIT                              ;OUTPUT
;* 'CR' - DISPLAY CARRIAGE-RETURN, LINE-FEED ON GENERAL OUTPUT
        FCB     $80
        FCC     'RC'
        FDB     SPACE
CR
        LDD     #$0D                              ;GET CARRIAGE RETURN
        PSHU    A,B                               ;PLACE ON STACK
        JSR     EMIT                              ;OUTPUT TO GENERAL OUTPUT
        LDB     #$0A                              ;GET LINE-FEED
        PSHU    A,B                               ;PLACE ON STACK
        JMP     EMIT                              ;OUTPUT TO GENERAL OUTPUT
;* 'READ' - READ A LINE FROM INPUT DEVICE
        FCB     $80
        FCC     'DAER'
        FDB     CR
READ
        BSR     CR                                ;NEW LINE
READNC
        LDY     #INPBUF                           ;POINT TO INPUT BUFFER
READ1
        JSR     KEY                               ;GET A KEY
        CMPB    #$0D                              ;IS IT CARRIAGE RETURN
        BEQ     READ2                             ;YES, EXIT
        CMPB    #$7F                              ;IS IT DELETE?
        BNE     READ3                             ;NO, NORMAL CHARACTER
;* DELETE KEY, DELETE PREVIOUS CHARACTER
        LEAU    2,U                               ;REMOVE KEYCODE FROM STACK
        LEAY    -1,Y                              ;BACKUP UP INPUT BUFFER POINTER
        CMPY    #INPBUF                           ;PAST BEGINNING?
        BLO     READ                              ;IF SO, RE-INITIATE READ
        LDX     #DELMSG                           ;POINT TO DELETE MESSAGE
        BSR     PMSG1                             ;DISPLAY
        BRA     READ1                             ;GO BACK FOR NEXT KEY
;* NORMAL KEY
READ3
        STB     ,Y+                               ;SAVE KEY IN BUFFER
        JSR     EMIT                              ;ECHO KEY
        BRA     READ1                             ;GO BACK FOR ANOTHER
;* CARRIAGE RETURN, TERMINATE INPUT
READ2
        LEAU    2,U                               ;REMOVE KEYCODE FROM STACK
        CLR     ,Y                                ;INDICATE END OF INPUT LINE
        LDY     #INPBUF                           ;POINT TO INPUT BUFFER
        STY     INPTR+3                           ;SET UP INPUT BUFFER POINTER
PMSG2
        RTS
;* '.MSG' - DISPLAY MESSAGE, ADDRESS ON STACK
        FCB     $80
        FCC     'GSM.'
        FDB     READ
PMSG
        LDX     ,U++                              ;GET ADDRESS
PMSG1
        LDB     ,X+                               ;GET CHARACTER FROM MESSAGE
        BEQ     PMSG2                             ;END OF MESSAGE, EXIT
        PSHU    A,B                               ;SAVE ON STACK
        JSR     EMIT                              ;OUTPUT TO GENERAL OUTPUT
        BRA     PMSG1                             ;GET NEXT CHARACTER
;* '.WRD' - DISPLAY A WORD ON GENERAL OUTPUT (STRING)
        FCB     $80
        FCC     'DRW.'
        FDB     PMSG
PWRD
        LDX     ,U++                              ;GET ADDRESS OF WORD
PWRD1
        LDB     ,X+                               ;GET CHARACTER FROM WORD
        LBSR    TSTERM                            ;IS IT A TERMINATOR?
        BEQ     PMSG2                             ;YES, QUIT
        PSHU    A,B                               ;SAVE DATA ON STACK
        JSR     EMIT                              ;OUTPUT TO GENERAL OUTPUT
        BRA     PWRD1                             ;GET NEXT WORD
;* 'QUIT - GENERAL COMMAND INTERPRETER, USED TO TERMINATE WORDS
        FCB     $80
        FCC     'TIUQ'
        FDB     PWRD
QUIT
        JSR     RPFIX                             ;RESET RETURN STACK
        LDX     #PROMPT                           ;POINT TO PROMPT
        BSR     PMSG1                             ;DISPLAY PROMPT
        LBSR    READNC                            ;READ A LINE OF INPUT
        JSR     SPACE                             ;SEPERATE BY A SPACE
QUI1
        JSR     QSKIP                             ;ADANCE TO NON-BLANK
        BEQ     QUIT                              ;NULL LINE, DO NOTHING
        JSR     LOOKUP                            ;LOOK UP WORD
        BEQ     QUI2                              ;NOT FOUND, TRY NUMBER
        BITA    #$02                              ;OK TO EXECUTE INTERACTIVLY?
        BNE     CONERR                            ;NO, FORCE ERROR
        JSR     [,U++]                            ;EXECUTE WORD
        CMPU    #DSTACK                           ;DID STACK UNDERFLOW?
        BLS     QUI1                              ;NO, KEEP INTERPRETING
        BSR     ERROR                             ;GENERATE ERROR MESSAGE
        FCN     'Stack empty'
;* NOT A WORD, TRY FOR NUMBER
QUI2
        JSR     NUMBER                            ;TRY FOR NUMBER
        LDD     ,U++                              ;GET FLAG BYTE
        BEQ     LOKERR                            ;NOT A NUMBER. INDICATE NOT FOUND
        BRA     QUI1                              ;KEEP INTERPRETING
;* SUBROUTINE TO GENERATE ERROR MESSAGE, FIRST DISPLAYS 'ERROR:' MESSAGE,
;* THEN NAME OF LAST WORD PROCESSED, THEN ERROR MESSAGE TEXT
ERROR
        LDX     #ERMSG1                           ;GET POINTER TO ERROR MESSAGE PREFIX
        BSR     PMSG1                             ;DISPLAY PREFIX
        LDX     LSTLOK                            ;GET ADDRESS OF LAST WORD FROM INPUT BUFFER
        BSR     PWRD1                             ;DISPLAY WORD
        LDX     #ERMSG2                           ;POINT TO ERROR MESSAGE SUFFIX
        BSR     PMSG1                             ;DISPLAY SUFFIX
        LDX     ,S++                              ;GET ADDRESS OF ERROR MESSAGE
        BSR     PMSG1                             ;DISPLAY MESSAGE
        JSR     SPFIX                             ;RESET DATA STACK
        BRA     QUIT                              ;AND ENTER COMMAND INTREPRETER
;* WORD WAS NOT FOUND IN THE DICTIONARY
LOKERR
        BSR     ERROR                             ;GENERATE ERROR MESSAGE
        FCN     'Not found'
;* WORD CAN NOT BE EXECUTED INTERACTIVELY
CONERR
        BSR     ERROR                             ;GENERATE ERROR MESSAGE
        FCN     'Cannot execute'
;* '>R' - MOVE WORD FROM DATA TO RETURN STACK
        FCB     $80
        FCC     'R>'
        FDB     QUIT
TOR
        LDX     ,S                                ;GET RETURN ADDRESS
        LDD     ,U++                              ;GET DATA FROM DATA STACK
        STD     ,S                                ;PLACE ON RETURN STACK
        TFR     X,PC                              ;RETURN TO CALLER
;* '<R' - MOVE WORD FROM RETURN STACK TO DATA STACK
        FCB     $80
        FCC     'R<'
        FDB     TOR
FROMR
        LDX     ,S++                              ;GET RETURN ADDRESS
        LDD     ,S++                              ;GET DATA FROM RETURN STACK
        STD     ,--U                              ;PLACE ON DATA STACK
        TFR     X,PC                              ;RETURN TO CALLER
;* 'RP!' - RESET RETURN STACK
        FCB     $80
        FCC     '!PR'
        FDB     FROMR
RPFIX
        PULS    A,B                               ;GET RETURN ADDRESS
        LDS     #RSTACK                           ;RESET RETURN STACK
        TFR     D,PC                              ;RETURN TO CALLER
;* 'SP!' - RESET DATA STACK
        FCB     $80
        FCC     '!PS'
        FDB     RPFIX
SPFIX
        LDU     #DSTACK                           ;RESET DATA STACK
VOC9
        RTS
;* ''S' - OBTAIN STACK ADDRESS
        FCB     $80
        FCC     'S'
        FDB     $27,SPFIX
TICS
        STU     ,--U                              ;SAVE DATA STACK POINTER
        RTS
;* 'VLIST' - DISPLAY WORDS IN DICTIONARY
        FCB     $80
        FCC     'TSILV'
        FDB     TICS
VOC
        LDX     HERE+3                            ;GET ADDRESS OF START OF DICTIONARY
VOC1
        JSR     CR                                ;NEW LINE
        CLRA                                      ;	ZERO CHARACTER COUNT
VOC2
        PSHS    A,X                               ;SAVE COUNT, CURRENT POSITION
        LEAX    -2,X                              ;BACKUP TO WORD NAME
VOC3
        LDB     ,-X                               ;GET CHARACTER FROM WORD NAME
        BMI     VOC4                              ;DESCRIPTOR BYTE, END OF NAME
        PSHU    A,B                               ;SAVE ON DATA STACK
        JSR     EMIT                              ;OUTPUT TO GENERAL OUTPUT
        INC     ,S                                ;INCREMENT CHARACTER COUNT
        BRA     VOC3                              ;KEEP OUTPUTING
VOC4
        JSR     SPACE                             ;SEPERATE WITH A SPACE
        PULS    A,X                               ;RESTORE CHARACTER COUNT, POSITION IN DICTIONARY
        INCA                                      ;	ADVANCE CHARACTER COUNT FOR SPACE
        LDX     ,--X                              ;GET ADDRESS OF NEXT WORD
        BEQ     VOC9                              ;END OF DICTIONARY, EXIT
        CMPA    #WIDTH                            ;ARE WE BEYOND TERMINAL WIDTH?
        BLO     VOC2                              ;NO, ITS OK
        BRA     VOC1                              ;CONTINUE ON NEW LINE
;* 'BYE' - EXIT FORTH
        FCB     $80
        FCC     'EYB'
        FDB     VOC
BYE
        SWI
        FCB     22                                ;NEW LINE
        SWI
        FCB     0                                 ;EXIT TO SYSTEM
;* 'FORGET' - REMOVE ONE OR MORE WORDS FROM DICTIONARY
        FCB     $80
        FCC     'TEGROF'
        FDB     BYE
FORGET
        JSR     TICK                              ;LOCATE WORDS ADDRESS
        PULU    X                                 ;GET ADDRESS
        CMPX    #USRSPC                           ;IS IT IN KERNAL DICTIONARY?
        BLO     PROERR                            ;IF SO, CAN'T BE FORGOTTON
        LDD     ,--X                              ;GET ADDRESS OF PREVIOUS WORD
        STD     HERE+3                            ;NEW DICTIONARY START
FORG1
        LDA     ,-X                               ;GET CHARACTER FROM NAME
        BPL     FORG1                             ;KEEP GOING TILL WE FIND DESCRIPTOR BYTE
        STX     FREE+3                            ;NEW FREE SPACE FOR DICTIONARY
        RTS
;* WORD IS PROTECTED, CAN'T 'FORGET' IT
PROERR
        LBSR    ERROR                             ;GENERATE ERROR MESSAGE
        FCN     'Protected'
;* 'CREATE' - CREATE NEW WORD IN DICTIONARY
        FDB     $80
        FCC     'ETAERC'
        FDB     FORGET
CREATE
        LDY     INPTR+3                           ;GET INPUT BUFFER POSITION
        LBSR    LOOKUP                            ;SEE IF IT ALREADY EXISTS
        BEQ     CRE1                              ;NO, ITS OK
        LEAU    2,U                               ;REMOVE ADDRESS OF EXISTING WORD
        LDX     #REDMSG                           ;POINT TO REDEFINITION MESSAGE
        LBSR    PMSG1                             ;OUTPUT MESSAGE
        TFR     Y,X                               ;POINT TO WORD WE ARE RE-DEFINING
        LBSR    PWRD1                             ;OUTPUT WORD TO GENERAL OUTPUT
CRE1
        LBSR    QSKI1                             ;ADVANCE TO NEXT NON-BLANK, SAVE POINTER
        LDA     #$FF                              ;START WITH COUNT OF -1
CRE3
        LDB     ,Y+                               ;GET CHARACTER FROM WORD
        INCA                                      ;	ADVANCE WORD SIZE COUNT
        LBSR    TSTERM                            ;TERMINATOR CHARACTER
        BNE     CRE3                              ;LOOK TILL WE FIND END
        LEAY    -1,Y                              ;BACKUP TO LAST CHAR
        STY     INPTR+3                           ;SAVE NEW BUFFER POSITION
        LDX     FREE+3                            ;GET ADDRESS OF FREE DICTIONARY SPACE
        LDB     #$80                              ;GET DEFAULT DESCRIPTOR BYTE
        STB     ,X+                               ;SAVE IN DICTIONARY
CRE2
        LDB     ,-Y                               ;GET CHARACTER FROM NAME
        STB     ,X+                               ;SAVE IN DICTIONARY
        DECA                                      ;	REDUCE COUNT OF NAME LENGTH
        BNE     CRE2                              ;MOVE ALL OF NAME INTO DICTIONARY
        LDD     HERE+3                            ;GET ADDRESS OF PREVIOUS ENTRY
        STD     ,X++                              ;SAVE IN DICTIONARY
        STX     HERE+3                            ;SAVE NEW STARTING ADDRESS
        STX     FREE+3                            ;SAVE NEW FREE SPACE ADDRESS
        RTS
;* 'ALLOT' - ALLOCATE SOME SPACE IN THE DICTIONARY
        FCB     $80
        FCC     'TOLLA'
        FDB     CREATE
ALLOT
        LDD     FREE+3                            ;GET ADDRESS OF FREE DICTIOANRY SPACE
        ADDD    ,U++                              ;OFFSET BY NUMBER OF BYTES R=ESTED
        STD     FREE+3                            ;RESAVE NEW FREE POINTER
        RTS
;* 'VARIABLE' - CREATE A VARIABLE
        FCB     $80
        FCC     'ELBAIRAV'
        FDB     ALLOT
VAR
        BSR     CREATE                            ;CREATE THE VARIABLE NAME
        LDA     #$BD                              ;GET A 'JSR' EXTENDED INSTRUCTION
        STA     ,X+                               ;INSERT INTO DICTIONARY
        LDD     #VARIAB                           ;GET ADDRESS OF VARIABLE SUBROUTINE
        STD     ,X++                              ;INSERT INTO DICTIONARY
        LDD     ,U++                              ;GET DEFAULT VARIABLE VALUE
        STD     ,X++                              ;SAVE INTO DICTIONARY
        STX     FREE+3                            ;SET NEW FREE POINTER
        RTS
;* ';' - END A COLON DEFINITION, TERMINATE COMPILING
        FCB     $83
        FCC     ';'
        FDB     VAR
SEMI
        LDD     -2,X                              ;GET LAST INSTRUCTION COMPLIED
        CMPD    #$3606                            ;IS IT 'PSHU A,B'?
        BEQ     SEMI1                             ;IF SO, ITS OK
        LDA     -3,X                              ;GET INSTRUCTION FROM DICTIONARY
        CMPA    #$BD                              ;IS IT 'JSR >'?
        BNE     SEMI1                             ;NO, ITS OK
;* CONVERT 'JSR' FOLLOWED BY 'RTS' TO SIMPLE 'JMP'
        LDA     #$7E                              ;GET 'JMP >' INSTRUCTION
        STA     -3,X                              ;SAVE IN DICTIONARY
        BRA     SEMI2                             ;TERMINATE COMPILING
SEMI1
        LDA     #$39                              ;GET 'RTS' INSTRUCTION
        STA     ,X+                               ;SAVE IN DICTIONARY
SEMI2
        STX     FREE+3                            ;RESAVE FREE POINTER
        JMP     QUIT                              ;RE-ENTER COMMAND INTERPRETER
;* ':' - COLON DEFINITION, BEGIN COMPLIING
        FCB     $84
        FCC     ':'
        FDB     SEMI
COLON
        JSR     CREATE                            ;CREATE NEW WORD
COL1
        JSR     QSKIP                             ;ADVANCE TO NON-BLANK
        BNE     COL11                             ;NOT END OF LINE, ITS OK
        JSR     READ                              ;READ ANOTHER LINE (NO SEMICOLON YET)
        BRA     COL1                              ;AND CONTINUE SCANNING
;*WE HAVE A WORD, COMPILE INTO PRESENT DEFINITION
COL11
        LBSR    LOOKUP                            ;LOOKUP WORD
        BNE     COL2                              ;FOUND, WE HAVE IT
        JSR     NUMBER                            ;TRY IT AS A NUMBER
        LDD     ,U++                              ;GET FLAG
        LBEQ    LOKERR                            ;NUMBER FAILED, ITS AN ERROR
;* NUMBER TO BE COMPILED INTO DICTIONARY
COL12
        BSR     BRCL                              ;COMPILE LITERAL VALUE
        BRA     COL1                              ;AND KEEP SCANNING
;* WORD TO BE COMPILED INTO DICTIONARY
COL2
        BITA    #$04                              ;IS IT OK TO COMPILE?
        BNE     INTERR                            ;NO, FORCE ERROR
        BITA    #1                                ;DOES IT EXECUTE ON COMPILATION?
        BEQ     COL3                              ;NO, NORMAL WORD
        STU     TEMP                              ;SAVE STACK POINTER
        LDX     FREE+3                            ;GET FREE ADRESS FOR EC FUNCTIONS
        JSR     [,U++]                            ;EXECUTE WORD
        CMPU    TEMP                              ;DID IT LEAVE EXACTLY ONE WORD ON THE STACK?
        BNE     COL1                              ;NO, CONTINUE SCANNING
        BRA     COL12                             ;SPECIAL CASE, COMPILE WORD AS LITERAL
;* NORMAL WORD, COMPILE AS WORD CALL
COL3
        BSR     COMP1                             ;COMPILE CALL TO WORD
        BRA     COL1                              ;AND KEEP SCANNING
;* NON-COMPILE WORD ENCOUNTERED
INTERR
        LBSR    ERROR                             ;GENERATE ERROR MESAGE
        FCN     'Cannot Compile'
;* '[CR]' - COMPILE A RETURN INSTRUCTION
        FCB     $82
        FCC     ']RC['
        FDB     COLON
BRCR
        LDX     FREE+3                            ;GET FREE ADDRESS
        LDB     #$39                              ;GET 'RTS' INSTRUCTION
        BRA     BRC11                             ;PLACE INTO DICTIONATY
;* '[CL]' - COMPILE A LITERAL VALUE
        FCB     $82
        FCC     ']LC['
        FDB     BRCR
BRCL
        LDX     FREE+3                            ;GET FREE ADDRES
        LDA     #$CC                              ;GET 'LDD #' INSTRUCTION
        STA     ,X+                               ;PLACE IN DICTIONARY
        LDD     ,U++                              ;GET DATA VALUE
        STD     ,X++                              ;PLACE IN DICTIONAT
        LDD     #$3606                            ;GET 'PSHU A,B' INSTRUCTION
        BRA     COMP3                             ;PLACE IN DICTIONARY
;* '[CW]' - COMPILE CALL TO A WORD INTO THE DICTIONARY
        FCB     $82
        FCC     ']WC['
        FDB     BRCL
BRCW
        LDX     FREE+3                            ;GET FREE ADDRESS
        BRA     COMP1                             ;COMPILE INTO DICTIONRY
;* '[C2]' - COMPILE A TWO BYTE (WORD) VALUE INTO THE DICTIONARY
        FCB     $82
        FCC     ']2C['
        FDB     BRCW
BRC2
        LDX     FREE+3                            ;GET FREE ADDRESS
        BRA     COMP3                             ;COMPILE TWO BYTE VALUE
;* '[C1]' - COMPILE A SINGLE BYTE VALUE INTO THE DICTIONARY
        FCB     $82
        FCC     ']1C['
        FDB     BRC2
BRC1
        LDX     FREE+3                            ;GET FREE ADDRESS
        LDD     ,U++                              ;GET VALUE TO COMPILE
BRC11
        STB     ,X+                               ;PLACE IN DICTIONARY
        BRA     COMP4                             ;RESAVE FREE POINTER
;* '[FC]' - FORCE COMPILATION OF NEXT WORD, EVEN IF NORMALY AUTO-EXEC
        FCB     $83
        FCC     ']CF['
        FDB     BRC1
BRCF
        JSR     TICK                              ;LOOKUP WORD ADDRESS
        BITA    #$04                              ;CAN IT BE COMPILED?
        BNE     INTERR                            ;NO, GET UPSET
;* COMPILE CALL TO A WORD INTO DICTIONARY
COMP1
        LDA     #$BD                              ;GET 'JSR >' INSTRUCTION
        STA     ,X+                               ;WRITE TO DICTIONARY
COMP2
        LDD     ,U++                              ;GET VALUE FROM DATE STACK
COMP3
        STD     ,X++                              ;WRITE TO DICTIONARY
COMP4
        STX     FREE+3                            ;RESAVE FREE POINTER
        RTS
;* '[NI]' - CAUSE LAST (OR CURRENTLY) COMPILED WORD TO BE NON-INTERACTIVE
        FCB     $81
        FCC     ']IN['
        FDB     BRCF
BRNI
        LDB     #2                                ;GET [NI] BIT
        BRA     SETBIT                            ;SET BIT IN DESCRIPTOR BYTE
;* '[NC]' - CAUSE LAST (OR CURRENTLY) COMPILED WORD TO BE NON-COMPILING
        FCB     $81
        FCC     ']CN['
        FDB     BRNI
BRNC
        LDB     #4                                ;GET [NC] BIT
        BRA     SETBIT                            ;SET BIT IN DESCRIPTOR BYTE
;* '[EC]' - CAUSE LAST (OR CURRENTLY) COMPILED WORD TO EXECUTE WHEN COMPILED
        FCB     $81
        FCC     ']CE['
        FDB     BRNC
BREC
        LDB     #1                                ;GET [EC] BIT
;* SET A BIT IN THE DESCRIPTOR BYTE FOR LAST WORD IN DICTIONARY
SETBIT
        LDY     HERE+3                            ;GET ADDRESS OF LAST WORD IN DICTIONARY
        LEAY    -2,Y                              ;BACKUP TO NAME
SETB1
        LDA     ,-Y                               ;GET CHAR FROM NAME
        BPL     SETB1                             ;KEEP READING TILL WE GET DESCRIPTOR BYTE
        PSHS    B                                 ;SAVE BIT TO ADD
        ORA     ,S+                               ;INCLUDE BIT IN DESCRIPTOR BYTE
        STA     ,Y                                ;RESAVE NEW DESCRIPTOR
        RTS
;* 'EXEC>' - COMPILE JUMP TO REMAINDER OF THIS WORD INTO NEW WORD
        FCB     $82
        FCC     '>CEXE'
        FDB     BREC
DOES
        LDX     FREE+3                            ;GET ADDRESS OF FREE DICTIONARY
        LDA     #$7E                              ;GET 'JMP >' INSTRUCTION
        STA     ,X+                               ;SAVE IN DICTIONARY
        PULS    A,B                               ;GET ADDRESS OF REMAINDER OF THIS WORD
        BRA     COMP3                             ;COMPILE INTO DICTIONARY
;* '(' - BRACE, START OF COMMENT
        FCB     $81
        FCC     '('
        FDB     DOES
BRACE
        LDY     INPTR+3                           ;GET INPUT POINTER
BRAC1
        LDA     ,Y+                               ;GET DATA FROM BUFFER
        BEQ     BRAC3                             ;END OF LINE
        CMPA    #')'                              ;IS IT CLOSING BRACE?
        BEQ     BRAC2                             ;YES, EXIT
        CMPA    #'('                              ;IS IT NESTED OPENING BRACE?
        BNE     BRAC1                             ;NO, ITS OK
        BSR     BRAC1                             ;RECURSE
        BRA     BRAC1                             ;AND KEEP LOOKING
;* END OF LINE, WITH NO CLOSING COMMENT
BRAC3
        JSR     READ                              ;READ ANOTHER LINE
        BRA     BRACE                             ;AND KEEP LOOKING
BRAC2
        STY     INPTR+3                           ;RESAVE INPUT POINTER
        RTS
;* 'LEAVE' - EXIT INNERMOST DO LOOP
        FCB     $82
        FCC     'EVAEL'
        FDB     BRACE
LEAVE
        LDD     4,S                               ;GET LOOP LIMIT
        STD     2,S                               ;SET INDEX TO SAME VALUE
        RTS
;* '+LOOP' - LOOP WITH VALUE TO ADD
        FCB     $83
        FCC     'POOL+'
        FDB     LEAVE
PLOOP
        PULU    A                                 ;GET STRUCTURE TYPE
        CMPA    #$81                              ;IS IT DO LOOP?
        BNE     NSTERR                            ;NO, NESTING ERROR
        LDD     #$EC62                            ;'LDD 2,S'
        STD     ,X++                              ;COMPILE INTO DICTIONARY
        LDD     #$E3C1                            ;'ADDD ,U++'
        STD     ,X++                              ;COMPILE
        LDA     #$ED                              ;'STD 2,S'
        STA     ,X+                               ;COMPILE
        BRA     LOOP1                             ;END TERMINATE NORMALLY
;* 'LOOP' - NORMAL DO LOOP
        FCB     $83
        FCC     'POOL'
        FDB     PLOOP
LOOP
        PULU    A                                 ;GET STRUCTURE TYPE
        CMPA    #$81                              ;IS IT DO LOOP?
        BNE     NSTERR                            ;NO, NESTING ERROR
        LDD     #$EC62                            ;'LDD 2,S'
        STD     ,X++                              ;PLACE IN DICTIONARY
        LDD     #$C300                            ;'ADDD #1'
        STD     ,X++                              ;PLACE IN DICTIONARY
        LDD     #$01ED                            ;'STD 2,S'
        STD     ,X++                              ;PLACE IN DICTIONARY
LOOP1
        LDD     #$6210                            ;< CATCHUP > (POSTBYTE FOR STD, PREFIX FOR CMPD)
        STD     ,X++                              ;SAVE IN DICTIONARY
        LDD     #$A3E4                            ;'CMPD ,S'
        STD     ,X++                              ;COMPILE
        LDD     #$1025                            ;'LBLO'
        LBSR    UNT1                              ;CALCULATE OFFSET VALUE AND COMPILE
        LDD     #$3264                            ;'LEAS 4,S'
        STD     ,X++                              ;COMPILE
COMRET
        STX     FREE+3                            ;SAVE NEW FREE POINTER
        RTS
;* 'K' - THIRD INDEX VALUE FOR DO LOOP
        FCB     $80
        FCC     'K'
        FDB     LOOP
K
        LDD     12,S                              ;GET INDEX VALUE
        BRA     IJK                               ;SAVE IT
;* 'J' - SECOND INDEV VALUE FOR DO LOOP
        FCB     $80
        FCC     'J'
        FDB     K
J
        LDD     8,S                               ;GET INDEX VALUE
        BRA     IJK                               ;SAVE IT
;* 'I' FIRST INDEX VALUE FOR DO LOOP
        FCB     $80
        FCC     'I'
        FDB     J
I
        LDD     4,S                               ;GET INDEX VALUE
IJK
        STD     ,--U                              ;SAVE ON STACK
        RTS
;* STRUCTURE IS NESTED IMPROPERLY
NSTERR
        LBSR    ERROR                             ;GENERATE ERROR MESSAGE
        FCN     'Improper nesting'
;* 'DO' - START OF DO LOOP CONSTRUCT
        FCB     $83
        FCC     'OD'
        FDB     I
DO
        LDA     #$BD                              ;GET 'JSR >' INSTRUCTION
        STA     ,X+                               ;COMPILE INTO DICTIONARY
        LDY     #TOR                              ;ADDRESS OF '>R' WORD
        STY     ,X++                              ;COMPILE INTO DICT
        STA     ,X+                               ;AND ANOTHER 'JSR >'
        STY     ,X++                              ;FOR ANOTHER '>R'
        LDA     #$81                              ;INDICATE DO LOOP
        PSHU    A,X                               ;SAVE PGM COUNTER ETC
        BRA     COMRET                            ;RESAVE FREE POINTER
;* 'FOREVER' - BEGIN LOOP FOREVER
        FCB     $83
        FCC     'REVEROF'
        FDB     DO
FOREVE
        PULU    A,Y                               ;GET LOOP CONSTRUCT IDENTIFIER
        CMPA    #$80                              ;WAS IT A BEGIN LOOP?
        BNE     NSTERR                            ;NO, IMPROPER NESTING
        LDA     #$7E                              ;'JMP >' INSTRUCTION
        STA     ,X+                               ;PLACE IN DICTIONARY
        STY     ,X++                              ;INCLUDE ADDRESS TO LOOP TO
        BRA     COMRET                            ;RESAVE FREE POINTER
;* 'UNTIL' - CONDITIONAL BEGIN LOOP
        FCB     $83
        FCC     'LITNU'
        FDB     FOREVE
UNTIL
        PULU    A                                 ;GET STRUCTURE IDENTIFIER
        CMPA    #$80                              ;IS IT A BEGIN LOOP?
        BNE     NSTERR                            ;NO, BAD NESTING
        LDD     #$ECC1                            ;'LDD ,U++'
        STD     ,X++                              ;SAVE IN DICTIONARY
        LDD     #$1027                            ;'LBEQ'
;* COMPILE LONG BRANCH, AND CALCULATE OFFSET FROM ADDRESS ON STACK
UNT1
        STD     ,X++                              ;SAVE IN DICTIONARY
        LEAX    2,X                               ;GET CURRENT ADDRESS
        PSHS    X                                 ;SAVE ON STACK
        PULU    A,B                               ;GET ADDRESS TO JUMP TO
        SUBD    ,S++                              ;CALCULATE OFFSET
        STD     -2,X                              ;COMPILE INTO DICTIONARY
COMR1
        LBRA    COMRET                            ;RESAVE FREE POINTER
;* 'WHILE' - CONDITIONAL BEGIN LOOP
        FCB     $83
        FCC     'ELIHW'
        FDB     UNTIL
WHILE
        PULU    A                                 ;GET STRUCTURE IDENTIFIER
        CMPA    #$80                              ;IS IT A BEGIN LOOP?
        BNE     NSTERR                            ;NO, IMPROPER NESTING
        LDD     #$ECC1                            ;'LDD ,U++'
        STD     ,X++                              ;COMPILE INTO DICTIONARY
        LDD     #$1026                            ;'LBNE'
        BRA     UNT1                              ;COMPILE INTO DICT WITH OFFSET
;* 'BEGIN' - START A BEGIN LOOP
        FCB     $83
        FCC     'NIGEB'
        FDB     WHILE
BEGIN
        LDA     #$80                              ;BEGIN LOOP IDENTIFIER
        PSHU    A,X                               ;SAVE IT AND CURRENT POSITION
        RTS
;* 'ENDIF' - END AN IF STATEMENT
        FCB     $83
        FCC     'FIDNE'
        FDB     BEGIN
ENDIF
        PULU    A                                 ;GET STRUCTURE IDENTIFIER
        CMPA    #$82                              ;IS IT 'IF'?
        LBNE    NSTERR                            ;NO, BAD NESTING
        LDY     ,U                                ;GET ADDRESS
        TFR     X,D                               ;GET CURRENT FREE ADDRESS
        SUBD    ,U++                              ;CALCULATE OFFSET
        STD     -2,Y                              ;SAVE IN BRANCH OPERAND
        RTS
;* 'ELSE' - ELSE CLAUSE TO AN IF STATEMENT
        FCB     $83
        FCC     'ESLE'
        FDB     ENDIF
ELSE
        LDA     #$16                              ;'LBRA'
        STA     ,X+                               ;COMPILE INTO DICTIONARY
        LEAX    2,X                               ;SKIP TO NEXT FREE
        PSHS    X                                 ;SAVE ADDRESS
        BSR     ENDIF                             ;COMPILE IN BRANCH
        PULS    X                                 ;RESTORE ADDRESS
        BRA     IF1                               ;SET UP NEW IF JUMPS
;* 'IF' - IF CONDITION
        FCB     $83
        FCC     'FI'
        FDB     ELSE
IF
        LDD     #$ECC1                            ;'LDD ,U++'
        STD     ,X++                              ;COMPILE
        LDD     #$1027                            ;'LBEQ'
        STD     ,X++                              ;COMPILE
        LEAX    2,X                               ;ADVANCE TO FREE
IF1
        LDA     #$82                              ;INDICATE IF STRUCTURE
        PSHU    A,X                               ;SAVE WITH ADDRESS ON STACK
COMR2
        LBRA    COMRET                            ;RESAVE FREE POINTER
;* '.' DISPLAY MESSAGE ON TERMINAL
        FCB     $83,$22
        FCC     '.'
        FDB     IF
DOTQ
        BSR     QUOTE                             ;COMPILE STRING
        LDA     #$BD                              ;'JSR >'
        STA     ,X+                               ;COMPILE INTO DICT
        LDD     #PMSG                             ;DISPLAY MESSAGE
        STD     ,X++                              ;COMPILE INTO DICT
        BRA     COMR2                             ;RESAVE FREE POINTER
;* '"' - COMPILE STRING INTO DICTIONARY
        FCB     $83,$22,DOTQ
QUOTE
        LDA     #$8D                              ;'BSR' INSTRUCTION
        STA     ,X++                              ;COMPILE INTO DICT
        JSR     QSKIP                             ;ADVANCE TO NON-BLANK
        PSHS    X                                 ;SAVE POINTER
QUO1
        LDA     ,Y+                               ;GET DATA FROM INPUT BUFFER
        BEQ     UNTERR                            ;END OF LINE, ERROR
        CMPA    #$22                              ;IS IT CLOSING QUOTE?
        BEQ     QUO2                              ;YES, EXIT
        STA     ,X+                               ;SAVE IN STRING
        BRA     QUO1                              ;AND KEEP PROCESSING
QUO2
        STY     INPTR+3                           ;SAVE NEW INPUT BUFFER POINTER
        CLR     ,X+                               ;INDICATE END OF STRING
        LDY     ,S                                ;GET ADDRESS OF BSR OPERAND
        TFR     X,D                               ;GET CURRENT ADDRESS
        SUBD    ,S++                              ;CALCULATE OFFSET FOR BSR
        STB     -1,Y                              ;SAVE IN OPERAND
        LDA     #$BD                              ;'JSR >'
        STA     ,X+                               ;COMPILE INTO DICT
        LDD     #FROMR                            ;GET '>R' ADDRESS
        STD     ,X++                              ;COMPILE
        BRA     COMR2                             ;RESAVE FREE POINTER
;* UNTERMINATED STRING
UNTERR
        LBSR    ERROR                             ;GENERATE ERROR MESSAGE
        FCN     'Unterminated'
;* '0' - QUICKER ZERO
        FCB     $80
        FCC     '0'
        FDB     QUOTE
ZERO
        CLRA                                      ;	ZERO HIGH BYTE
        CLRB                                      ;	ZERO LOW BYTE
        STD     ,--U                              ;SAVE ON DATA STACK
        RTS
;* '1' - QUICKER ONE
        FCB     $80
        FCC     '1'
        FDB     ZERO
ONE
        LDD     #1                                ;GET A VALUE OF ONE
        STD     ,--U                              ;SAVE ON STACK
        RTS
;*
;* VARIABLES
;*
;* '(OUT)' - ADDRESS OF GENERAL OUTPUT DRIVER
        FCB     $80
        FCC     ')TUO('
        FDB     ONE
DISP
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     DOLOUT                            ;DEFAULT IS '$OUT'
;* '(IN)' - ADDRESS OF GENERAL INPUT DRIVER
        FCB     $80
        FCC     ')NI('
        FDB     DISP
INPT
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     DOLIN                             ;DEFAULT IS '$IN'
;* '(GO)' - ADDRESS OF WORD TO EXECUTE AT STARTUP
        FCB     $80
        FCC     ')OG('
        FDB     INPT
BOOT
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     QUIT                              ;DEFUALT IS 'QUIT'
;* '>IN' - POINTER TO POSITION IN INPUT BUFFER
        FCB     $80
        FCC     'NI>'
        FDB     BOOT
INPTR
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     INPBUF                            ;DEFAULT IS START OF BUFFER
;* 'BASE' - CURRENT NUMBER CONVERSION BASE
        FCB     $80
        FCC     'ESAB'
        FDB     INPTR
BASE
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     10                                ;DEFAULT IS BASE 10
;* 'FREE' - ADDRESS OF FREE MEMORY FOLLOWING DICTIONARY
        FCB     $80
        FCC     'EERF'
        FDB     BASE
FREE
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     USRSPC                            ;DEFAULT IS END OF DICTIONARY
;* 'HERE' - ADDRESS OF LAST WORD IN DICTIONARY
        FCB     $80
        FCC     'EREH'
        FDB     FREE
HERE
        JSR     VARIAB                            ;VARIABLE SUBROUTINE
        FDB     HERE                              ;DEFUALT IS ITSELF
;* DICTIONARY GROWS FROM HERE
USRSPC          = *
