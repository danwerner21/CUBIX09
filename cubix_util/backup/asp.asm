;        TITLE   ASSEMBLY SOURCE PREPROCESSOR
;*
;* ASP: Assembly Source Preprocessor
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ; START OF OS OPERATING AREA
OSEND           = $DBFF
STACK           = OSEND                           ;SYSTEM STACK SPACE
USP             = STACK-512                       ;USER STACK SPACE
CTSP            = USP-512                         ;CONTROL STACK SPACE
;*
        ORG     OSRAM                             ;PROGRAM EXECUTION SPACE
;* PROGRAM ENTRY
ASP
        CMPA    #'?'                              ;QUERY OPERAND?
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIER
        SWI
        FCB     25
        FCN     'Use: ASP[/COMMENT/SOURCE/QUIET] <ASP source file>'
        SWI
        FCB     0
;*
;* PARSE	FOR QUALIFIERS
;*
QUAL
        LDA     ,Y                                ;GET CHAR FROM COMMAND LINE
        CMPA    #'/'                              ;IS IT A QUALIFIER?
        BNE     MAIN                              ;NO, GET PARAMETERS
        LEAX    QTABLE,PCR	POINT TO QUALIFIER TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;IS IT IN RANGE
        BHS     QERR                              ;IF SO, IT'S INVALID
        LEAX    QFLAGS,PCR	POINT TO QUALIFIER FLAGS
        CLR     B,X                               ;SET THE FLAG
        BRA     QUAL                              ;LOOK FOR ANOTHER QUALIFIER
QERR
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Invalid qualifier: '
        LDA     ,Y+                               ;GET CHARACTER
DSQU1
        SWI
        FCB     33                                ;DISPLAY
        LDA     ,Y+                               ;GET NEXT CHAR
        BEQ     GOABO                             ;NULL IS DELIMITER
        CMPA    #'/'                              ;START OF ANOTHER QUALIFIER?
        BEQ     GOABO                             ;IF SO, QUIT
        CMPA    #' '                              ;SPACE?
        BEQ     GOABO                             ;IF SO, QUIT
        CMPA    #$0D                              ;END OF LINE?
        BNE     DSQU1                             ;NO, KEEP DUMPING
GOABO
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCB     $27,0                             ;CHARACTERS TO DISPLAY
        LDA     #1                                ;INVALID OPERAND RETURN CODE
ABORT
        SWI
        FCB     0                                 ;RETURN TO OS
;*
;* OPEN INPUT FILE
;*
MAIN
        LDS     #STACK
        SWI
        FCB     11                                ;GET NAME
        LBNE    ABORT                             ;ERROR
        LDD     #$4153                            ;'AS'
        STD     ,X                                ;SAVE
        LDA     #'P'                              ;'P', CR
        STA     2,X                               ;SAVE
        LDU     #INPFIL                           ;PT TO INPUT
        SWI
        FCB     55                                ;OPEN FOR READ
        BNE     ABORT                             ;BAD, GIVE UP
        LDA     #'M'                              ;'ASM'
        STA     2,X                               ;SET LAST CHAR
        LDU     #OUTFIL                           ;PT TO OUTPUT
        SWI
        FCB     56                                ;OPEN FOR WRITE
        LBNE    ABORT                             ;INVALID
        LDU     #USP                              ;POINT TO USER STACK SPACE
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
        CLR     ,X                                ;START OFF WITH NO SYMBOLS
        STX     SYMEND                            ;SAVE POINTER
        TST     QUIET                             ;ARE WE BEING QUIET?
        BEQ     RDINP                             ;IF SO, DON'T MAKE ANY NOISE
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCC     'ASP version 1.0'
        FCB     $0A,$0D
        FCN     'Processing source file...'
;*
;* READ LINE OF INPUT
;*
RDINP
        LDD     LINE                              ;GET CURRENT LINE NUMBER
        ADDD    #1                                ;INCREMENT
        STD     LINE                              ;RESAVE
        LDX     #INPLIN                           ;POINT TO INPUT LINE
        TFR     X,Y                               ;COPY TO Y FOR LATER
RDIN1
        LBSR    RDINPF                            ;READ A CHAR
        BNE     CRVARS                            ;END OF FILE
        STA     ,X+                               ;SAVE IT
        CMPA    #$0D                              ;END OF LINE?
        BNE     RDIN1                             ;NO, KEEP READING
        SWI
        FCB     4                                 ;LOOK FOR INPUT
        BEQ     RDINP                             ;NULL LINE, IGNORE
        CMPA    #'*'                              ;COMMANT?
        BEQ     PROCOM                            ;IF SO, SKIP IT
;* WE HAVE INPUT LINE
        PSHS    Y                                 ;SAVE IT
        LDA     SOURCE                            ;IS SOURCE COPY ENABLED?
        BNE     NOSORC                            ;NO, SKIP IT
        LBSR    STROUT                            ;WRITE STRING
        FCN     '*>> '                            ;MESSAGE
WRSRLI
        LDA     ,Y+                               ;GET CHAR
        LBSR    WROUT                             ;OUTPUT
        CMPA    #$0D                              ;END OF LINE?
        BNE     WRSRLI                            ;CONTINUE
;* TEST FOR LABLE ON LINE
NOSORC
        LDY     ,S                                ;GET POINTER BACK
        LDA     ,Y                                ;GET CHAR
        CMPA    #'A'                              ;<'A'
        BLO     NOSR1                             ;NO LABLE
        CMPA    #'Z'                              ;>'Z'?
        BHI     NOSR1                             ;NO LABLE
SRCLAB
        LDA     ,Y+                               ;GET CHAR
        LBSR    VALSYM                            ;IS THIS IT?
        BEQ     SRCLAB                            ;KEEP GOING
        CMPA    #':'                              ;LABLE?
        BNE     NOSR1                             ;NOT A LABLE
        PULS    Y                                 ;RESTORE Y
        LBSR    CPVAR
        LBSR    STROUT
        FCB     $09
        FCC     'EQU'
        FCB     $09,'*',$0D,0
        LEAY    1,Y                               ;ADVANCE
        PSHS    Y                                 ;RESAVE
NOSR1
        PULS    Y                                 ;RESTORE Y
        STS     SAVS                              ;SAVE SP
        STU     SAVU                              ;SAVE U
        LDX     #RESWRD
        SWI
        FCB     18                                ;LOOK UP WORD
        LDX     #HNDLRS                           ;POINTS TO HANDLERS
        ASLB                                      ;	SHIFT FOR DOUBLE BYTE WORDS
        JSR     [B,X]                             ;EXECUTE PROGRAM CODE
        BRA     RDINP                             ;READ NEXT LINE
;* PROCESS COMMENT LINE
PROCOM
        TST     COMNT                             ;INCLUDE IN OUTPUT?
        BNE     RDINP                             ;NO, SKIP IT
WRCOMN
        LDA     ,Y+                               ;GET CHAR
        LBSR    WROUT                             ;WRITE IT
        CMPA    #$0D                              ;END OF LINE?
        BNE     WRCOMN                            ;NO, CONTINUE
        LBRA    RDINP                             ;NEXT LINE
;*
;* END OF COMPILE, CREATE VARIABLE STATEMENTS
;*
CRVARS
        LDD     DATADR                            ;GET DATA ADDRESS
        BEQ     NODORG                            ;DON'T ORG DATA
        LBSR    STROUT                            ;WRITE STRING
        FCB     9                                 ;TAB
        FCC     'ORG'
        FCB     9                                 ;TAB,CR
        FCN     '$'
        LDD     DATADR                            ;GET DATA ADDRESS
        LBSR    WRHEXW                            ;OUTPUT HEX WORD
        LBSR    ENDCR                             ;WRITE A NEW LINE CHARACTER
NODORG
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
NODOR1
        TST     ,X                                ;AT END?
        BEQ     ENDVAR                            ;IF SO, WE ARE AT THE END
        TFR     X,Y                               ;SAVE IT
IDENTI
        LDA     ,Y+                               ;GET CHAR
        BPL     IDENTI                            ;LOOK FOR NEXT
        LDB     ,Y                                ;GET TYPE
        BMI     VARNXT                            ;CONSTANT, SKIP IT
WRNAM
        LDA     ,X                                ;GET VAR
        ANDA    #$7F                              ;CONVERT TO NORM
        LBSR    WROUT                             ;OUTPUT IT
        LDA     ,X+                               ;GET NEXT
        BPL     WRNAM                             ;OUTPUT
        LBSR    STROUT                            ;WRITE STRING
        FCB     9                                 ;TAB
        FCC     'RMB'
        FCB     9
        FCN     '$'
        BITB    #2                                ;TEST FOR WORD
        PSHS    CC                                ;SAVE FLAGS
        LDD     1,X                               ;GET LENGTH
        BNE     DEFA                              ;DEFAULT TO ONE
        INCB                                      ;	CONVERT TO ONE
DEFA
        PULS    CC                                ;RESTORE FLAGS
        BEQ     WRLEN                             ;OK
        LSLB                                      ;	SHIFT B
        ROLA                                      ;	TIMES TWO
WRLEN
        LBSR    WRHEXW                            ;WRITE IT
        LBSR    ENDCR                             ;NEW LINE
VARNXT
        LEAX    3,Y                               ;POINT TO NEXT
        BRA     NODOR1
;* VARIALES ARE CREATED
ENDVAR
        LDU     #OUTFIL                           ;PT TO OUTPUT
        SWI
        FCB     57                                ;CLOSE OUTPUT FILE
        LDD     ERRCNT                            ;ANY ERRORS?
        BEQ     ENDOK                             ;END WAS OK
        SWI
        FCB     26                                ;DISPLAY NUMBER
        SWI
        FCB     25
        FCN     ' errors reported.'
        LDA     #100
ENDOK
        LBRA    ABORT
;*
;* STATEMENT HANDLERS
;*
;* SET CODE ADDRESS
CODE
        LBSR    STROUT                            ;SET STRING TO OUTPUT FILE
        FCB     $09                               ;TAB
        FCC     'ORG'                             ;ORIGIN
        FCB     $09,0                             ;TAB, END
        LBSR    CPELEM                            ;COPY NEXT ELEMENT
;* END LINE WITH	CARRIAGE RETURN
ENDCR
        LDA     #$0D                              ;GET CARRIAGE RETURN
        LBRA    WROUT                             ;END LINE
;* SET DATA ADDRESS
DATA
        LBSR    GETNUM                            ;GET DATA VALUE
        STA     DATADR                            ;SAVE DATA ADDRESS
        RTS
;* VARIABLE DECLARATION
VARIAB
        LSRB                                      ;	CONVERT BACK TO NORMAL VALUE
        STB     TEMP                              ;SAVE TYPE
        LDX     #DTAB                             ;POINT TO DATA TABLE
        SWI
        FCB     18                                ;LOOK FOR IT
        TSTB                                      ;	IS IT CONSTANT?
        BNE     NORVAR                            ;NO, NORMAL VARIABLE
;* SET A	CONSTANT VALUE
CONSTA
        SWI
        FCB     4                                 ;SKIP TO NEXT
        PSHS    Y                                 ;SAVE IT
        LBSR    CRSYM                             ;CREATE SYMBOL
        LDA     TEMP                              ;GET DATA TYPE
        ORA     #$80                              ;SET CONSTANT BIT
        STA     ,X                                ;SET SYMBOL TYPE
        PULS    Y                                 ;RESTORE Y
        LBSR    CPVAR                             ;COPY VARIABLE NAME
        LBSR    SKIP                              ;GET NEXT
        CMPA    #'='                              ;EQUALS?
        BNE     SYNTAX                            ;INVALID CONSTANT
        LBSR    STROUT                            ;WRITE A STRING
        FCB     $09                               ;TAB
        FCC     'EQU'
        FCB     $09,0
        LBSR    CPELEM                            ;SAVE IT
        BSR     ENDCR                             ;WRITE CARRIAGE RETURN
        LBSR    SKIP                              ;GET NEXT
        CMPA    #','                              ;MORE DATA?
        BEQ     CONSTA                            ;IF SO, GO FOR MORE
        CMPA    #$0D                              ;END OF LINE?
        BNE     SYNTAX                            ;INVALID
        RTS
;*
;* SYNTAX ERROR
;*
SYNTAX
        LBSR    ERROR                             ;DISPLAY ERROR MESSAGE
        FCN     'Incorrect Syntax'
        RTS
;* NORMAL VARIABLE DECLARATION
NORVAR
        SWI
        FCB     4                                 ;POINT TO VARIABLE
        LBSR    CRSYM                             ;CREATE SYMBOL
        LDA     TEMP                              ;GET DATA TYPE
        STA     ,X+                               ;SAVE IT
        LBSR    SKIP                              ;GET NEXT
        CMPA    #'('                              ;ARRAY?
        BNE     NOALL                             ;DON'T ALLOCATE SPACE
        LBSR    GETNUM                            ;GET INPUT NUMBER
        STD     ,X                                ;SET ARRAYYSIZE
        LBSR    SKIP                              ;GET NEXT
        CMPA    #')'                              ;CLOSING VALUE?
        BNE     SYNTAX                            ;NO, ERROR
        LBSR    SKIP                              ;GET NEXT
NOALL
        CMPA    #','                              ;DO ANOTHER?
        BEQ     NORVAR                            ;IF SO, GO IT AGAIN
        CMPA    #$0D                              ;END OF LINE?
        BNE     SYNTAX                            ;NO, INVALIE
WRSRTS
        RTS
;*
;* 'ASM' COMMAND
;*
ASM
        LDX     #INPLIN                           ;GET INPUT LINE
        TFR     X,Y                               ;COPY
ASM1
        LBSR    RDINPF                            ;GET DATA
        BNE     WRSRTS                            ;END
        STA     ,X+                               ;SAVE IT
        CMPA    #$0D                              ;END OF LINE
        BNE     ASM1                              ;CONTINUE
        LDX     #ENDWRD                           ;POINT TO 'END'
        SWI
        FCB     18                                ;IS THIS IT
        TSTB                                      ;	FOUND IT
        BEQ     WRSRTS                            ;IF SO, EXIT
        LDX     #INPLIN                           ;POINT TO INPUT LINE
ASM2
        LDA     ,X+                               ;GET IT
        LBSR    WROUT                             ;OUTPUT
        CMPA    #$0D                              ;END OF LINE?
        BNE     ASM2                              ;NO, WAIT
        BRA     ASM                               ;GET NEXT
;* 'SUBROUTINE' STATEMENT
SUBR
        LDA     #$82                              ;INDICATE SUBROUTINE
        LBRA    PUSHS                             ;SAVE IT
;* DO CONDITIONALS
DOCOND
        LDA     #$FF
        STA     BYTE
        LBSR    EXPR                              ;CALCULATE EXPRESION
        LDA     BYTE                              ;GET VALUE
        PSHS    A                                 ;SAVE IT
        LBSR    STROUT
        FCB     $09
        FCC     'PSHS'
        FCB     $09,0
        TST     ,S                                ;WAS IT BYTE
        BEQ     PSYBY                             ;PUSH BYTE
        LBSR    STROUT
        FCN     'A,'                              ;ADD A
PSYBY
        LBSR    STROUT
        FCB     'B',$0D,0
;* LOOK UP CONDITIONAL
        LBSR    SKIP                              ;ADVANCE
        CMPA    #','
        BNE     DOCSYN                            ;BAD
        LBSR    SKIP
        LDB     ,Y+                               ;GET SECOND PART
        LDX     #CONTAB-2   POINT TO TABLE
DOCON1
        LEAX    2,X                               ;ADVANCE
        TST     ,X                                ;END?
        BEQ     DOCSYN                            ;BAD SYNTAX
        CMPD    ,X++                              ;SAME?
        BNE     DOCON1                            ;NO, KEEP LOOKING
        LBSR    SKIP                              ;ADVANCE
        CMPA    #','                              ;IS IT COMMA?
        BNE     DOCSYN                            ;SYNTAX
        PSHS    X                                 ;SAVE
        LBSR    EXPR                              ;EVALUATE NEXT EXPRESSION
        TST     BYTE                              ;IS IT BYTE
        BNE     CWRDOK                            ;WORD IS OK
        TST     2,S                               ;WAS LAST BYTE
        BEQ     CWRDOK                            ;NO PROB
        LBSR    STROUT                            ;OUTPUT
        FCB     $09
        FCC     'CLRA'
        FCB     $0D,0                             ;CLEAR ACCA
CWRDOK
        LDA     2,S
        STA     BYTE                              ;SAVE BYTE INDICATOR
        LBSR    WRINS
        FCN     'CMP'
        LBSR    STROUT
        FCB     $09
        FCN     ',S+'
        LDA     2,S                               ;GET BYTE INDICATOR
        BEQ     CBYTOK                            ;BYTE IS OK
        LDA     #'+'
        LBSR    WROUT                             ;OUTPUT
CBYTOK
        LDA     #$0D
        LBSR    WROUT
        LBSR    STROUT
        FCB     $9,'L','B',0
        PULS    X
        LDA     ,X+
        LBSR    WROUT
        LDA     ,X
        LBSR    WROUT
        PULS    A                                 ;RESTORE STACK
        LDA     #9
        LBRA    WROUT                             ;OUTPUT
DOCSYN
        PULS    A
        LBSR    ERROR
        FCN     'Incorrect Syntax.'
        RTS
;* WHILE STATEMENT
WHILE
        LBSR    GETLAB                            ;GET A LABLE
        LBSR    PUSHD                             ;SAVE ON STACK
        PSHS    A,B                               ;SAVE IT
        LBSR    GETLAB                            ;GET LABLE
        LBSR    PUSHD                             ;SAVE IT
        LBSR    WRLAB                             ;OUTPUT LABLE
        LDA     #$81                              ;INDICATE WHILE
        LBSR    PUSHS                             ;SAVE IT
        LBSR    DOCOND                            ;EVALUATE CONDITIONALS
        PULS    A,B                               ;RESTORE LABLE
        LBRA    WRLCR                             ;OUTPUT
;* IF STATEMENT
CIF
        LBSR    GETLAB                            ;GET NEXT LABLE
        LBSR    PUSHD                             ;SAVE
        PSHS    A,B                               ;SAVE
        LDA     #$80                              ;INDICATE 'IF'
        LBSR    PUSHS                             ;SAVE
        LBSR    DOCOND                            ;DO CONDITIONALS
        PULS    A,B                               ;RESTORE
        LBRA    WRLCR                             ;OUTPUT
;* END STATEMENT
CEND
        LBSR    POPS                              ;GET DATA
        SUBA    #$80                              ;IS IT 'IF'?
        BEQ     WREQP                             ;NO
;* END CORRESPONDS TO A 'WHILE' OR 'UNTIL' STATEMENT
CEND1
        DECA                                      ;	IS IT WHILE/UNTIL ?
        BNE     CEND2                             ;NO, TRY NEXT
        LBSR    STROUT                            ;OUTPUT
        FCB     $09
        FCC     'LBRA'
        FCB     $09,0
        LBSR    POPD                              ;GET LABLE
        LBSR    WRLCR                             ;OUTPUT
;* END CORRESPONDS TO AN 'IF' STATEMENT
WREQP
        LBSR    POPD                              ;GET LABLE
WREQU
        LBSR    WRLAB                             ;OUTPUT
        LBSR    STROUT
        FCB     $09
        FCC     'EQU'
        FCB     $09,'*',$0D,0
        RTS
;* END CORRESPONDS TO A 'SUBROUTINE' STATEMENT
CEND2
        DECA                                      ;	IS THIS IT?
        BNE     CENDB                             ;NO
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     9
        FCC     'RTS'
        FCB     $0D,0                             ;END
        RTS
CENDB
        LBSR    ERROR
        FCN     'Improper nesting.'
        RTS
;* ELSE STATEMENT
ELSE
        LDX     CTLSTK
        LDA     ,X
        CMPA    #$80
        BNE     CENDB
        LBSR    STROUT
        FCB     $9
        FCC     'LBRA'
        FCB     $9,0
        LDD     1,X
        PSHS    A,B
        LBSR    GETLAB                            ;GET A NEW LABLE
        STD     1,X
        LBSR    WRLCR                             ;OUTPUT EQUATE INSTRUCTION
        PULS    A,B
        BRA     WREQU                             ;GENERATE EQUATE
;* GOTO STATEMENT
GOTO
        LBSR    STROUT
        FCB     9
        FCC     'LBRA'
        FCB     9,0
GOTO1
        LBSR    CPVAR
        LBRA    ENDCR                             ;OUTPUT
;* CALL COMMAND
CALL
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     9
        FCC     'LBSR'
        FCB     9,0
        BRA     GOTO1
;* EXIT COMMAND
EXIT
        CLR     BYTE                              ;INDICATE BYTE OPERATIONS
        LBSR    EXPR                              ;GET RETURN CODE
        LBSR    STROUT                            ;OUTPUT
        FCB     $09
        FCC     'TFR'
        FCB     $09
        FCC     'B,A'
        FCB     $0D,9
        FCC     'SSR'
        FCB     9,'0',$0D,0
        RTS
;* SUBROUTINES
;*
;* GET LABLE VALUE
GETLAB
        LDD     NXTLAB
        ADDD    #1
        STD     NXTLAB
        RTS
;* PUSH A DOUBLE BYTE ON CTRL STACK
PUSHD
        PSHS    X
        LDX     CTLSTK
        STD     ,--X
        BRA     SAVUSP
PUSHS
        PSHS    X
        LDX     CTLSTK
        STA     ,-X
        BRA     SAVUSP
POPS
        PSHS    X
        LDX     CTLSTK
        LDA     ,X+
        BRA     SAVUSP
POPD
        PSHS    X
        LDX     CTLSTK
        LDD     ,X++
SAVUSP
        STX     CTLSTK
        PULS    X,PC
;*
;* WRITE OPERAND TO INSTRUCTION
WROPR
        LBSR    WRTAB                             ;OUTPUT TAB
WRONT
        LDA     ,U+                               ;GET OPERAND TYPE
        CMPA    #1                                ;CONSTANT?
        BNE     NCNST                             ;NOT A CONSTANT
        LDA     #'#'                              ;INDICATE IMMEDIATE MODE
        LBSR    WROUT                             ;OUTPUT
        LDY     ,U++                              ;GET POINTER BACK
        LDA     ,Y                                ;GET FIRST CHAR
        CMPA    #'#'                              ;ONE OF THESE?
        BNE     NCNT1
        LEAY    1,Y
NCNT1
        LBSR    CPALL                             ;COPY INTO OUTPUT SOURCE
WROK
        LBRA    ENDCR                             ;WRITE IT OUT
NCNST
        LDY     ,U++                              ;GET POINTER
        LBSR    CPALL                             ;COPY IT ALL
        TST     BYTE                              ;BYTE OPERATION?
        BNE     WROK                              ;NO, IT'S OK
        LDY     -2,U                              ;GET POINTER BACK
        LBSR    LOOKUP                            ;LOOK FOR IT
        BITA    #2                                ;WORD?
        BEQ     WROK                              ;IT'S A BYTE VARIABLE
        LBSR    STROUT                            ;OUTPUT
        FCN     '+1'                              ;OK
        BRA     WROK                              ;CONTINUE
;* WRITE OUT INSTRUCTION
WRINS
        PSHS    A,CC,X                            ;SAVE REGS
        BSR     WRTAB                             ;WRITE TAB
        LDX     4,S                               ;GET PC
        BSR     WRSTX                             ;WRITE STRING(X)
        STX     4,S                               ;RESAVE PC
        LDA     #'B'                              ;GET LOW BYTE
        TST     BYTE                              ;IS IT A BYTE OPERATION
        BEQ     WRLST                             ;NO, GO FOR IT
        LDA     #'D'                              ;CHANGE TO D
WRLST
        BSR     WROUT                             ;OUTPUT
        PULS    A,CC,X,PC
;* WRITE STRING(X). TO OUTPUT FILE
WRSTX
        LDA     ,X+                               ;GET CHAR
        LBEQ    WRSRTS                            ;DONE
        BSR     WROUT                             ;OUTPUT
        BRA     WRSTX                             ;CONTINUE
;* WRITE	STRING TO OUTPUT FILE
STROUT
        PSHS    A,X                               ;SAVE X
        LDX     3,S                               ;GET PC
        BSR     WRSTX                             ;OUTPUT STRING(X)
STR2
        STX     3,S                               ;RESAVE
        PULS    A,X,PC                            ;GO HOME
;* WRITE	A HEX WORD
WRHEXW
        TSTA                                      ;	ZERO HIGH BYTE?
        BEQ     WRHEXZ                            ;NO LEADING ZERO
        BSR     WRHEXB                            ;WRITE A BYTE
WRHEXZ
        TFR     B,A                               ;COPY
;* WRITE	A HEX BYTE
WRHEXB
        PSHS    A                                 ;SAVE IT
        LSRA                                      ;	SHIFT
        LSRA                                      ;	HIGH
        LSRA                                      ;	NIBBLE
        LSRA                                      ;	INTO LOW
        BSR     WRNIB                             ;OUTPUT NIBBLE
        PULS    A                                 ;RESTORE A
WRNIB
        ANDA    #$0F                              ;GET RID OF HIGH CRAP
        ADDA    #$30                              ;CONVERT TO ASCII
        CMPA    #$39                              ;< '30-39
        BLS     WROUT
        ADDA    #$07                              ;CONVERT TO 'A'-'F'
;* WRITE	CHARACTER TO OUTPUT FILE
WROUT
        PSHS    U                                 ;SAVE
        LDU     #OUTFIL                           ;SET UP PTR
        SWI
        FCB     61                                ;SEND TO OUTPUT FILE
        PULS    U,PC
WRTAB
        LDA     #9
        BRA     WROUT                             ;OUTPUT TAB
WRLCR
        BSR     WRLAB                             ;OUTPUT LABLE
        LDA     #$0D
        BRA     WROUT                             ;OUTPUT
;* WRITE LABLE VALUE
WRLAB
        PSHS    A,B
        LDA     #'_'                              ;LEAD IN
        BSR     WROUT                             ;OUTPUT
        LDA     ,S
        BSR     WRHEXW                            ;LABLE VALUE
        PULS    A,B,PC
;*
;* COPY THIS ELEMENT TO SOURCE
;*
CPELEM
        SWI
        FCB     4                                 ;SKIP
CPEL1
        LDA     ,Y+                               ;GET CHAR FROM SOURCE
        CMPA    #$0D                              ;CR?
        BEQ     CPE1                              ;IF SO, QUIT
        CMPA    #','                              ;COMMA?
        BEQ     CPE1                              ;IF SO, QUIT
        BSR     WROUT                             ;OUTPUT TO TO OUTPUT FILE
        CMPA    #$27                              ;QUOTE?
        BNE     CPEL1                             ;NO, CONTINUE
CPE2
        LDA     ,Y+                               ;GET NEXT
        CMPA    #$0D                              ;CR?
        BEQ     CPE3                              ;INVALID STRING
        BSR     WROUT                             ;WRITE IT
        CMPA    #$27                              ;CLOSING QUOTE?
        BNE     CPE2                              ;NO, KEEP COPYING
        BRA     CPEL1                             ;CONTINUE,
CPE3
        BSR     BADSTR                            ;WRITE BAD STRING MESSAGE
CPE1
        LEAY    -1,Y                              ;BACKUP TO DELIMITER
        RTS
;*
;* STRING ON THIS LINE IS INVALID
;*
BADSTR
        BSR     ERROR                             ;WRITE  ERROR MESSAGE
        FCN     'Improper string'
        RTS
;*
;* WRITE	ERROR MESSAGE
;*
ERROR
        LDD     ERRCNT
        ADDD    #1
        STD     ERRCNT
        SWI
        FCB     24                                ;WRITE PRE MESSAGE
        FCN     'Line: '
        LDD     LINE
        SWI
        FCB     26                                ;DISPLAY LINE NUMBER
        SWI
        FCB     24
        FCN     ' : '                             ;WRITE POST MESSAGE
        LDX     #INPLIN                           ;POINT TO TEXT
ERR3
        LDA     ,X+                               ;GET CHAR
        CMPA    #$0D                              ;END OF LINE?
        BEQ     ERR4                              ;IF SO, QUIT/
        SWI
        FCB     33                                ;DISPLAY
        BRA     ERR3                              ;CONTINUE
ERR4
        SWI
        FCB     24
        FCN     ' : '
        PSHS    X                                 ;SAVE X
        LDX     2,S                               ;GET OLD PC
        SWI
        FCB     23                                ;DISPLAY
        STX     2,S                               ;RESAVE
        SWI
        FCB     22                                ;NEW LINE
        LDS     SAVS
        LDU     SAVU
        LBRA    RDINP
;*
;* GET A	NUMBER FROM THE	INPUT STREAM
;*
GETNUM
        PSHS    X                                 ;SAVE X
        SWI
        FCB     8                                 ;GET NUMBER
        BEQ     NUMOK                             ;NO BAD RETURN CODE
        BSR     ERROR                             ;DISPLAY MESSAGE,
        FCN     'Invalid numeric value'
NUMOK
        TFR     X,D                               ;COPY IT OVER
        PULS    X,PC
;*
;* COPY VARIABLE/CONSTANT
;*
CPALL
        LBSR    SKIP                              ;LOOK FOR DATA
        CMPA    #'$'                              ;OK?
        BEQ     CPV1                              ;IF SO, OK
        BSR     VALSYM                            ;VALID
        BEQ     CPV1                              ;OK TO COPY
        LBRA    SYNTAX                            ;INVALID
;*
;* COPY A VARIABLE NAME TO THE OUTPUT FILE
;*
CPVAR
        LBSR    SKIP                              ;GET NEXT
        CMPA    #'A'                              ;VALID VARIABLE?
        LBLO    SYNTAX                            ;NO, IT'S BAD
        CMPA    #'Z'                              ;VALID?
        LBHI    SYNTAX                            ;NO, IT'S BAD
CPV1
        LBSR    WROUT                             ;WRITE IT
        LDA     ,Y+                               ;GET NEXT
        BSR     VALSYM                            ;VALID SYMBOL?
        BEQ     CPV1                              ;YES, CONTINUE
CPV2
        LEAY    -1,Y                              ;BACKUP
        RTS
;*
;* DETERMINE IF CHAR IN A IS A VALID SYMBOL CHARACTER. (0-9, A-Z)
;*
VALSYM
        CMPA    #'0'                              ;< '0'?
        BLO     BADS                              ;IF SO, IT'S BAD
        CMPA    #'Z'                              ;> 'Z'?
        BHI     BADS                              ;IF SO, IT'S BAD
        CMPA    #'A'                              ;> 'A'?
        BHS     SYMOK                             ;IT'S OK
        CMPA    #'9'                              ;> '9'
        BHI     BADS                              ;IT'S BAD
SYMOK
        ORCC    #$04                              ;SET Z
        RTS
BADS
        ANDCC   #$FB                              ;CLEAR Z
        RTS
;*
;* CREATE A SYMBOL
;*
CRSYM
        LDX     SYMEND                            ;POINT TO END OF SYMBOL TABLE
        LBSR    SKIP                              ;GET NEXT
        CMPA    #'A'                              ;<'A'
        LBLO    SYNTAX                            ;IT'S INVALID
        CMPA    #'Z'                              ;>'Z'
        LBHI    SYNTAX                            ;INVALID
CRS1
        STA     ,X+                               ;SAVE IN RAM
        LDA     ,Y+                               ;GET NEXT CHAR
        BSR     VALSYM                            ;VALID?
        BEQ     CRS1                              ;IT'S OK
        LDA     -1,X                              ;GET LAST CHAR
        ORA     #$80                              ;SET HIGH BIT
        STA     -1,X                              ;RESAVE
        LEAY    -1,Y                              ;BACKUP TO THIS CHAR
        CLR     ,X+                               ;INDICATE NO BITS SET
        CLR     ,X+                               ;INDICATE NO BITS SET
        CLR     ,X+                               ;INDICATE NO BITS SET
        STX     SYMEND                            ;RESAVE
        CLR     ,X                                ;INDICATE END OF TABLE
        LEAX    -3,X                              ;BACKUP
        RTS
;*
;* LOOKUP SYMBOL	POINTED	TO BY Y
;*
LOOKUP
        SWI
        FCB     4                                 ;ADVANCE TO SYMBOL
        LDX     #SYMTAB                           ;LOOK AT SYMBOL TABLE
LOK1
        LDA     ,X                                ;GET CHAR FROM TABLE
        BEQ     NOTFND                            ;SYMBOL WAS NOT FOUND
        PSHS    Y                                 ;SAVE IT
LOK2
        LDA     ,Y+                               ;GET CHAR FROM Y
        BSR     VALSYM                            ;IS IT VALID?
        BNE     LOK3                              ;END OF SYMBOL, DID NOT FIND
        CMPA    ,X+                               ;DOES IT MATCH TABLE ENTRY?
        BEQ     LOK2                              ;YES, WE HAVE IT
        ORA     #$80                              ;SET HIGH BIT
        CMPA    ,-X                               ;IS THIS IT?
        BEQ     LOK4                              ;THIS MIGHT BE IT
;* SYMBOL IN TABLE DID NOT MATCH
LOK3
        LDA     ,X+                               ;GET CHAR FROM TABLE
        BPL     LOK3                              ;FIND DELIMITER
        LEAX    3,X                               ;SKIP TO NEXT
        PULS    Y                                 ;RESTORE Y POINTER
        BRA     LOK1                              ;AND KEEP LOOKING
NOTFND
        ANDCC   #$FB                              ;CLEAR ZERO
        RTS
;* THIS MIGHT BE	IT
LOK4
        LDA     ,Y                                ;GET CHAR FROM SYMBOL
        BSR     VALSYM                            ;IS IT A VALID SYMBOL?
        BEQ     LOK3                              ;WASN'T IT, TRY AGAIN
        LEAX    1,X                               ;ADVANCE TO TABLE ENTRY
        LEAS    2,S                               ;RESTORE STACK
        LDA     ,X                                ;GET TYPE
        ORCC    #$04                              ;SET Z FLAG
        RTS
;*
;* LOOK FOR SYMBOL, AND DISPLAY MESSAGE IF NOT FOUND
;*
LOOKNF
        BSR     LOOKUP                            ;LOOK FOR IT
        BEQ     SYMF                              ;IF WAS FOUND
        LBSR    ERROR                             ;DISPLAY ERROR
        FCN     'Unknown symbol'
SYMF
        RTS
;*
;* SKIP TO NEXT NON BLANK
;*
SKIP
        LDA     ,Y+                               ;GET CHAR
        CMPA    #' '                              ;BLANK?
        BEQ     SKIP                              ;CONTINUE
        CMPA    #$0D                              ;CR?
        RTS
;*
;* DETERMINE TYPE OF TOKEN POINTED TO BY	Y
;*
TOKEN
        LDA     ,Y                                ;GET CHAR
        CMPA    #'$'                              ;NUMBER?
        BEQ     TCON                              ;IF SO, IT'S A CONSTANT
        CMPA    #'#'                              ;ADDRESS?
        BEQ     TCON                              ;IF SO, IT'S ALSO A CONSTANT
        CMPA    #'0'                              ;> 0?
        BLO     TADDR                             ;NOT A CONSTANT
        CMPA    #'9'                              ;< '9'?
        BHI     TADDR                             ;TRY ADDRESS
;* TEST FOR CONSTANT VALUE
TCON
        LEAY    1,Y                               ;ADVANCE
TCON1
        LDA     #$01                              ;CONSTANT VALUE
TNXT
        PSHS    A                                 ;SAVE VALUE
TNXT1
        LDA     ,Y+                               ;GET CHAR
        LBSR    VALSYM                            ;VALID SYMBOL?
        BEQ     TNXT1                             ;CONTINUE
        LEAY    -1,Y                              ;BACKUP TO IT
        PULS    A,PC                              ;GO HOME
;* TEST FOR VARIABLE VALUE
TADDR
        LBSR    VALSYM                            ;VALID SYMBOL 'A-Z'?
        BNE     TOPR                              ;NO, IT'S AN OPERATOR
        LBSR    LOOKNF                            ;WHAT IS IT'S VALUE
        PSHS    CC                                ;IT'S A CONSTANT
        BITA    #2                                ;IS IT A WORD?
        BNE     TOKVAR                            ;IT'S A BYTE VARIABLE
        CLR     BYTE                              ;INDICATE WORD
TOKVAR
        LDA     #2                                ;INDICATE VARIABLE
        PULS    CC                                ;RESTORE COND CODES
        BMI     TCON1                             ;CONSTANT
        BRA     TNXT                              ;GO AGAIN
;* IT'S AN OPERATOR VALUE
TOPR
        LDX     #OPRTAB                           ;POINT TO OPERATOR TABLE
TOP1
        LDA     ,X                                ;GET BYTE FROM TABLE
        BEQ     NTOP                              ;NOT AN OPERATOR
        PSHS    Y                                 ;SAVE Y
TOP2
        LDA     ,Y+                               ;GET CHAR FROM TABLE
        CMPA    ,X+                               ;DOES IT MATCH?
        BEQ     TOP2                              ;CONTINUE
        ORA     #$80                              ;SET HIGH BIT
        CMPA    ,-X                               ;MATCH?
        BEQ     TOP3                              ;WE FOUND IT
TOP4
        LDA     ,X+                               ;GET VAL
        BPL     TOP4                              ;CONTINUE
        LEAX    1,X                               ;ADVANCE TO NEXT
        PULS    Y                                 ;RESTORE
        BRA     TOP1                              ;CONTINUE
TOP3
        LEAS    2,S                               ;SKIP SAVED Y
        LDA     1,X                               ;GET TOKEN VALUE
        RTS
NTOP
        LBSR    SYNTAX                            ;INDICATE ERROR
        LEAS    2,S
        CLRA
        RTS
;*
;* READ CHARACTER FROM INPUT FILE
;*
RDINPF
        PSHS    U                                 ;SAVE REGS
        LDU     #INPFIL                           ;PT TO INPUT FILE
        SWI
        FCB     59                                ;READ CHAR
        PULS    U,PC
;*
;* ASSIGNMENT STATEMENT
;*
ASSIGN
        PSHS    Y                                 ;SAVE IT
        LDA     #$FF
        STA     BYTE                              ;SET WORD FLAG
        LBSR    LOOKUP                            ;DOES IT EXIST?
        BNE     ASI1                              ;NO, GO IT THE HARD WAY
        BITA    #2                                ;IS IT A BYTE?
        BNE     ASI2                              ;NO, IT'S A WORD
        CLR     BYTE                              ;INDICATE BYTE OPERATION
        BRA     ASI2
ASI1
        LDA     ,Y+                               ;GET CHAR
        LBSR    VALSYM                            ;VALID AS A SYMBOL?
        BEQ     ASI1                              ;CONTINUE
        LEAY    -1,Y                              ;BACKUP TO IT
ASI2
        LBSR    SKIP                              ;ADVANCE PAST ANY BLANKS
        CMPA    #'='                              ;DOES IT MATCH?
        LBNE    SYNTAX                            ;NO, IT'S A SYNTAX ERROR
        LBSR    EXPR                              ;GENERATE CODE
        LDY     ,S                                ;POINT AT LABLE
        LBSR    LOOKUP                            ;DOES IT EXIST?
        BEQ     SYEXI                             ;SYMBOL EXISTS
        LBSR    CRSYM                             ;CREATE IT
        LDA     #1                                ;SET TYPE TO BYTE
        TST     BYTE                              ;BYTE OPERATION?
        BEQ     TYOK                              ;TYPE IS OK
        LDA     #2                                ;CHANGE TO VARIABLE
TYOK
        STA     ,X                                ;SET TYPE
SAVSYM
        LBSR    WRINS                             ;OUTPUT INSTRUCTION
        FCN     'ST'                              ;OUTPUT
        LDA     #9                                ;GET TAB
        LBSR    WROUT                             ;OUTPUT
        PULS    Y                                 ;RESTORE VARIABLE POINTER
        LBSR    CPVAR                             ;COPY IN VARIABLE NAME
        LBRA    ENDCR                             ;END
SYEXI
        LDA     ,X                                ;GET TYPE
        BITA    #2                                ;WORD?
        BEQ     ASSBYT                            ;IT'S A BYTE
        TST     BYTE                              ;BYTE RESULT?
        BNE     SAVSYM                            ;TYPE IS OK
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     9
        FCC     'CLRA'
        FCB     $0D,0
        DEC     BYTE                              ;CONVERT TO WORD STORE
        BRA     SAVSYM                            ;OUTPUT
ASSBYT
        CLR     BYTE                              ;INSURE BYTE STORE
        BRA     SAVSYM                            ;GO FOR IT
;*
;* PARSE	INFIX OPERANDS INTO REVERSE RPN	STACK
;*
NEST
        LEAY    1,Y                               ;SKIP
DOPARS
        LBSR    SKIP                              ;ADVANCE TO NEXT TOKEN
        BEQ     TOK                               ;END OF LINE, QUIT
        CMPA    #')'                              ;END OF SECTION?
        BEQ     TOK                               ;IF SO, QUIT
        CMPA    #','                              ;CLOSING COMMA?
        BEQ     TOK                               ;IF SO, QUIT
        LEAY    -1,Y                              ;BACKUP TO IT
        BSR     GETOK                             ;EVALUATE THIS TOKEN
        BRA     DOPARS                            ;DO IT AGAIN FOR NEXT
;* GET NEXT TOKEN SET
GETOK
        SWI
        FCB     4                                 ;SKIP TO NEXT TOKEN
        BEQ     TOK                               ;END OF LINE, QUIT
        CMPA    #'('                              ;STARTING BRACE?
        BEQ     NEST                              ;IF SO, NEST IT
        STY     TEMP                              ;SAVE POINTER TO TOKEN
        LBSR    TOKEN                             ;DETERMINE IT'S CLASS
        CMPA    #2                                ;IS IT A CONSTANT OR VARIABLE?
        BLS     TOK1                              ;IF SO, IT'S OK
        PSHS    A                                 ;SAVE CLASS
        LBSR    GETOK                             ;GET NEXT TOKEN
TOK2
        PULS    A                                 ;RESTORE CLASS
        PSHU    A                                 ;SAVE ON RPN STACK
TOK
        RTS
;* VARIABLE OR CONSTANT
TOK1
        PSHS    A                                 ;SAVE CLASS
        LDD     TEMP                              ;GET POINTER TO TOKEN
        PSHU    A,B                               ;SAVE
        BRA     TOK2                              ;SAVE CLASS
;*
;* PARSE	LINE, AND GENERATE CODE FOR AN EXPRESSION
;*
EXPR
        STU     SAVUS                             ;SAVE USP FOR DETERMINATION OF TOP
        BSR     DOPARS                            ;PARSE LINE INTO RPN STACK
;* GENERATE CODE	FROM REVERSE RPN STACK
        TFR     U,X                               ;POINT TO STACK SPACE
        STX     USRSTK                            ;POINT TO IT
        BSR     GENCOD                            ;PERFORM CODE GENERATION
        LDU     SAVUS                             ;RESTORE U
        RTS
;* GENERATE CODE	FOR EXPRESSION
GENCOD
        PSHS    A,B,X                             ;SAVE REGISTERS
        CMPU    SAVUS                             ;ARE WE AT END?
        BHS     PAR4                              ;IF SO, QUIT
        LDA     ,U+                               ;GET OPERATOR
        TFR     A,B                               ;COPY TO B
        CMPA    #SNGL                             ;SINGLE OPERATOR?
        BHI     DUBOP                             ;IF SO, WE HAVE IT
        CMPA    #2                                ;IS IT A CONSTANT OF VARIABLE?
        BHI     SNGOP                             ;SINGLE OPERATOR
        STA     ,-U                               ;RESTACK
        LBSR    WRINS                             ;WRITE INSTRUCTION
        FCN     'LD'
        LBSR    WROPR                             ;OUTPUT OPERAND
        PULS    A,B,X,PC
;* SINGLE OPERAND INSTRUCTION
SNGOP
        LDA     ,U                                ;GET OPERAND
        CMPA    #2                                ;CONSTANT?
        BLS     SNG2                              ;IF SO, IT'S OK
        LBSR    GENCOD                            ;GENERATE CODE FOR IT
        BRA     SNG1                              ;AND FINISH
SNG2
        LBSR    WRINS                             ;OUTPUT STRING
        FCN     'LD'                              ;OUTPUT A LOAD INSTRUCTION
        LBSR    WROPR                             ;AND INCLUDE OPERAND
SNG1
        LDX     #GENTAB                           ;POINT TO TABLE
        ASLB                                      ;	SHIFT IT
        JSR     [B,X]                             ;PERFORM IT
;* TERMINATE
PAR4
        PULS    A,B,X,PC	RESTORE REGISTERS
;* STACKS ENTIRE OPERAND STRING ON VIRTUAL (X) STACK
STKOP
        LDA     ,U+                               ;GET OPERAND FROM USER STACK
        STA     ,-X                               ;SAVE ON X STACK
        CMPA    #2                                ;CONSTANT OR VARIABLE?
        BLS     STKO1                             ;IF SO, IT'T OK
        CMPA    #SNGL                             ;IS IT A SINGLE OPERTOR?
        BLS     STKO2                             ;YES, ONLY ONE OPERATOR TO STAC
        BSR     STKOP                             ;STACK ANOTHER OPERATOR
STKO2
        BRA     STKOP                             ;STACK ANOTHER
STKO1
        LDA     ,U+                               ;GET ADDRESS
        STA     ,-X                               ;STACK
        LDA     ,U+                               ;GET LOW ADDRESS
        STA     ,-X                               ;STACK
        RTS
;* DOUBLE OPERATOR INSTRUCTIONS
DUBOP
        LDX     USRSTK                            ;POINT TO VIRTUAL STACK
        PSHS    X                                 ;SAVE IT
        BSR     STKOP                             ;STACK OPERAND
        STX     USRSTK                            ;SAVE IT
        LDA     ,U                                ;GET OPERAND
        CMPA    #2                                ;CONSTANT OF VARIABLE?
        BLS     DUB1                              ;YES, IT'S OK
        LBSR    GENCOD                            ;GENERATE CODE
        BRA     DUB2                              ;AND CONTINUE
DUB1
        LBSR    WRINS                             ;OUTPUT INSTRUCTION
        FCN     'LD'                              ;DO AN 'LD' INSTRUCTION
        LBSR    WROPR                             ;OUTPUT OPERAND
DUB2
        LDX     USRSTK                            ;POINT TO FAKE STACK
DUB3
        CMPX    ,S                                ;ARE WE IN RANGE?
        BHS     DUB4                              ;OK
        LDA     ,X+                               ;GET BYTE FROM FAKE STACK
        STA     ,-U                               ;SAVE ON USER STACK
        BRA     DUB3                              ;CONTINUE
DUB4
        PULS    X                                 ;SAVE IT
        STX     USRSTK                            ;RESAVE
;* LOOK FOR SIMPLE SECOND OPERATOR
        LDA     ,U                                ;GET BYTE FROM OPERAND
        CMPA    #2                                ;SIMPLE CONSTANT OF VARIABLE?
        BLS     DUB5                              ;YES, IT'S QUITE SIMPLE
        LBSR    WRINS                             ;OUTPUT INSTRUCTION
        FCC     'PSHS'                            ;PUSH INST
        FCB     9,0                               ;TAB AND END
        LBSR    ENDCR                             ;CLOSE IT
        LBSR    GENCOD                            ;GENERATE CODE FOR SECOND ARG
        LDX     #GENTAB                           ;POINT TO TABLE
        ASLB                                      ;	SHIFT
        ORCC    #$01                              ;SET CARRY, INDICATE STACK OPERATION
        JSR     [B,X]                             ;DO IT
        PULS    A,B,X,PC	GO HOME
DUB5
        LDX     #GENTAB                           ;POINT TO IT
        ASLB                                      ;	TIMES TWO
        JSR     [B,X]                             ;DO IT
        PULS    A,B,X,PC	GO HOME
;* SHIFT RIGHT
CSHR
        TST     BYTE
        BEQ     BSHR
        LBSR    STROUT
        FCB     9
        FCC     'LSRA'
        FCB     $0D,9
        FCC     'RORB'
        FCB     $0D,0
        BRA     ESHR
BSHR
        LBSR    STROUT
        FCB     9
        FCC     'LSRB'
        FCB     $0D,0
ESHR
        RTS
;* SHIFT LEFT
CSHL
        TST     BYTE
        BEQ     BSHL
        LBSR    STROUT
        FCB     $09
        FCC     'LSLB'
        FCB     $0D,$09
        FCC     'ROLA'
        FCB     $0D,0
        BRA     ESHL
BSHL
        LBSR    STROUT
        FCB     $09
        FCC     'LSLB'
        FCB     $0D,0
ESHL
        RTS
;* COMPLEMENT
CCOM
        TST     BYTE
        BEQ     BCOM
        LBSR    STROUT
        FCB     $09
        FCC     'COMA'
        FCB     $0D,$09
        FCC     'COMB'
        FCB     $0D,0
        BRA     ECOM
BCOM
        LBSR    STROUT
        FCB     $09
        FCC     'COMB'
        FCB     $0D,0
ECOM
        RTS
;* INCREMENT
CINC
        TST     BYTE
        BEQ     BINC
        LBSR    STROUT
        FCB     $09
        FCC     'ADDD'
        FCB     $09
        FCC     '#1'
        FCB     $0D,0
        BRA     EINC
BINC
        LBSR    STROUT
        FCB     $09
        FCC     'INCB'
        FCB     $0D,0
EINC
        RTS
;* DECREMENT
CDEC
        TST     BYTE
        BEQ     BDEC
        LBSR    STROUT
        FCB     $09
        FCC     'SUBD'
        FCB     $09
        FCC     '#1'
        FCB     $0D,0
        BRA     EDEC
BDEC
        LBSR    STROUT
        FCB     $09
        FCC     'DECB'
        FCB     $0D,0
EDEC
        RTS
;*
;* DOUBLE OPERAND INSTRUCTIONS
;*
;* SUBTRACTION
CSUB
        LBSR    WRINS                             ;OUTPUT INST
        FCN     'SUB'                             ;SUBTRACT
        LBCC    WROPR                             ;IF NOTHING, IT'S OK
        BSR     DSSTK1                            ;PERFORM SUBTRACTION
        LBSR    CCOM                              ;COMPLEMENT IT
        LBRA    CINC                              ;INCREMENT IT
;* ADDITION
CADD
        LBSR    WRINS                             ;OUTPUT INSTRUCTION
        FCN     'ADD'                             ;ADD
DCIF1
        LBCC    WROPR                             ;IF NO STACK, DO IT RIGHT
DSSTK1
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     $09                               ;TAB
        FCN     ',S+'                             ;ONE OPERATION
        TST     BYTE                              ;BYTE OPERATIONS
        BEQ     ENDX                              ;OK
        LDA     #'+'                              ;EXTRA PLUS
        LBSR    WROUT                             ;OUTPUT
ENDX
        LBRA    ENDCR
;* LOGICAL OR
COR
        BSR     WRACO                             ;WRITE ACCUMULATOR OPERATION
        FCN     'OR'                              ;DO AN OR
        RTS
;* LOGICAL AND
CAND
        BSR     WRACO
        FCN     'AND'
        RTS
;* EXCLUSIVE OR
CXOR
        BSR     WRACO
        FCN     'EOR'
        RTS
;*
;* WRITE AN ACCUMUALTOR OPERATION
;*
WRACO
        BCS     WRASTK                            ;ON STACK
        TST     BYTE                              ;BYTE OPERATION?
        BEQ     WRABYT                            ;YES
        LBSR    WRTAB                             ;OUTPUT TAB
        LDX     ,S                                ;GET PC
        LBSR    WRSTX                             ;OUTPUT INSTRUCTION
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     'A',9,0                           ;OUTPUT STRING
        PSHS    U                                 ;SAVE U
        LDA     ,U+                               ;GET OPERAND TYPE
        CMPA    #1                                ;CONSTANT?
        BNE     WRANV                             ;NOT A CONSTANT
        LBSR    STROUT
        FCB     '#','=',0
WRANV
        LBSR    NCNST                             ;TOP BYTE IS OK
        PULS    U                                 ;RESTORE
WRABYT
        LBSR    WRTAB                             ;OUTPUT TAB
        LDX     ,S                                ;GET POINTER
        LBSR    WRSTX                             ;CONTINUE
        STX     ,S                                ;RESAVE
        LBSR    STROUT                            ;OUTPUT
        FCB     'B',9,0                           ;CONTINUE
        TST     BYTE                              ;BYTE OPERATION?
        BEQ     WRANV1                            ;IF SO, NO SPECIAL CRAP
        LDA     ,U                                ;GET TYPE
        CMPA    #2                                ;VARIABLE?
        BNE     WRANV1                            ;NO, SKIP IT
        LDY     1,U                               ;GET ADDRESS
        LBSR    LOOKUP                            ;LOOK FOR IT
        BITA    #2                                ;WORD?
        BEQ     WRANV1                            ;NO
        LBSR    STROUT
        FCN     '1+'
WRANV1
        LBRA    WRONT                             ;OUTPUT OPERAND
;* OPERAND IS ON STACK
WRASTK
        TST     BYTE                              ;OK?
        BEQ     WRASTB                            ;BYTE OPERATION
        LBSR    WRTAB                             ;OUTPUT
        LDX     ,S                                ;GET POINTER
        LBSR    WRSTX                             ;OUTPUT
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     'A',9                             ;OUTPUT STRING
        FCC     ',S+'
        FCB     $0D,0                             ;END OF LINE
WRASTB
        LBSR    WRTAB                             ;OUTPUT TAB
        LDX     ,S                                ;GET POINTER TO INST
        LBSR    WRSTX                             ;OUTPUT
        STX     ,S                                ;SAVE
        LBSR    STROUT                            ;OUTPUT STRING
        FCB     'B',9                             ;OUTPUT STRING
        FCC     ',S+'
        FCB     $0D,0                             ;END OF LINE
        RTS
;*
;* OPERATOR TABLE
;*
OPRTAB
        FCB     '+','+'+$80,5
        FCB     '-','-'+$80,6
        FCB     '-',':'+$80,7
        FCB     '!','!'+$80,12
        FCB     '<'+$80,3
        FCB     '>'+$80,4
        FCB     '+'+$80,8
        FCB     '-'+$80,9
        FCB     '&'+$80,10
        FCB     '!'+$80,11
        FCB     0
SNGL            = 7                               ;HIGEST SINGLE OPERAND OPERATOR
;* TABLE OF GENERATION CODE
GENTAB
        FDB     SYNTAX                            ;0
        FDB     SYNTAX                            ;1
        FDB     SYNTAX                            ;2
        FDB     CSHL                              ;3
        FDB     CSHR                              ;4
        FDB     CINC                              ;5
        FDB     CDEC                              ;6
        FDB     CCOM                              ;7
        FDB     CADD                              ;8
        FDB     CSUB                              ;9
        FDB     CAND                              ;10
        FDB     COR                               ;11
        FDB     CXOR                              ;12
;* RESERVED WORD	TABLE
RESWRD
        FCB     $84
        FCC     'CHAR'
        FCB     $84
        FCC     'BYTE'
        FCB     $87
        FCC     'INTEGER'
        FCB     $84
        FCC     'CODE'
        FCB     $84
        FCC     'DATA'
        FCB     $83
        FCC     'ASM'
ENDWRD
        FCB     $83
        FCC     'END'
        FCB     $82
        FCC     'IF'
        FCB     $84
        FCC     'ELSE'
        FCB     $85
        FCC     'WHILE'
        FCB     $84
        FCC     'GOTO'
        FCB     $84
        FCC     'CALL'
        FCB     $84
        FCC     'EXIT'
        FCB     $84
        FCC     'SUBROUTINE'
        FCB     $80
;*
;* HANDLER DATA TABLE
;*
HNDLRS
        FDB     VARIAB                            ;'CHAR'
        FDB     VARIAB                            ;'BYTE'
        FDB     VARIAB                            ;'INTEGER'
        FDB     CODE                              ;'CODE'
        FDB     DATA                              ;'DATA'
        FDB     ASM                               ;'ASM' COMMAND
        FDB     CEND                              ;'END' STATEMENT
        FDB     CIF                               ;'IF' STATEMENT
        FDB     ELSE                              ;'ELSE' STATEMENT
        FDB     WHILE                             ;'WHILE' STATEMENT
        FDB     GOTO                              ;'GOTO' STATEMENT
        FDB     CALL                              ;'CALL' STATEMENT
        FDB     EXIT                              ;'EXIT' STATEMENT
        FDB     SUBR                              ;'SUBROUTINE' STATEMENT
        FDB     ASSIGN                            ;DEFAULT / UNRECOGNIZED
;*
;* DATA TYPE TABLE
;*
DTAB
        FCB     $88
        FCC     'CONSTANT'
        FCB     $80
;*
;* CONDITIONAL DATA TABLE
;*
CONTAB
        FCC     'EQNE'
        FCC     'NEEQ'
        FCC     'LTLE'
        FCC     'GTGE'
        FCC     'LELT'
        FCC     'GEGT'
        FCC     'LSLO'
        FCC     'LOLS'
        FCC     'HIHS'
        FCC     'HSHI'
        FCB     0,0
;*
;* QUALIFIER TABLE
;*
QTABLE
        FCB     $82
        FCC     '/QUIET'
        FCB     $82
        FCC     '/COMMENT'
        FCB     $82
        FCC     '/SOURCE'
        FCB     $80
QMAX            = 3
;*
QFLAGS          = *
QUIET
        FCB     $FF
COMNT
        FCB     $FF
SOURCE
        FCB     $FF
;*
;* LOCAL	VARIABLE DATA SPACE
;*
LINE
        FDB     0                                 ;CURRENT LINE NUMBER
DATADR
        FDB     0                                 ;DEFAULT DATA ADDRESS
NXTLAB
        FDB     0                                 ;LABLE VALUES
ERRCNT
        FDB     0                                 ;ERROR COUNTER
CTLSTK
        FDB     CTSP                              ;CONTROL STACK POINTER
;*
;* RESERVED MEMORY
;*
BYTE
        RMB     1                                 ;INDICATES BYTE/WORD OPERATIONS
SAVS
        RMB     2                                 ;SAVED SP
SAVU
        RMB     2                                 ;SAVED UP
SAVUS
        RMB     2                                 ;SAVED U STACK POINTER
USRSTK
        RMB     2                                 ;SAVED X STACK POINTER
TEMP
        RMB     2                                 ;TEMPORARY STORAGE
SYMEND
        RMB     2                                 ;SYMBOL TABLE ENDING ADDRESS
INPLIN
        RMB     128                               ;INPUT LINE BUFFER
INPFIL
        RMB     522                               ;INPUT FILE BUFFER
OUTFIL
        RMB     522                               ;OUTPUT FILE BUFFER
SYMTAB          = *                               ;SYMBOL TABLE