;*        TITLE   RESIDENT 6809 ASSEMBLER
;*
;* ASM: A resident 6809 assembler
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ; START OF OS OPERATING AREA
RAM             = OSRAM+8192                      ; FREE RAM AREA
RAMHB           = (OSRAM+8192)/256                ; FREE RAM AREA
;* STORAGE
        ORG     RAM                               ;RESERVED AREA FOR ASSEMBLER
FILPTR
        RMB     2                                 ;POINTER TO SAVED FILENAME
ERRORS
        RMB     2                                 ;COUNT OF ASSEMBLY ERRORS
VAL1
        RMB     2                                 ;TEMPORARY REGISTER FOR EVAL
TEMP
        RMB     2                                 ;TEMPORARY REGISTER FOR MEMOP
CURPC
        RMB     2                                 ;CURRENT PROGRAM COUNTER
CURDP
        RMB     2                                 ;CURRENT DIRECT PAGE VALUE
SYMLOC
        RMB     2                                 ;CURRENT LOCATION IN SYMBOL TABLE
LINUM
        RMB     2                                 ;CURRENT LISTING LINE NUMBER
PAGE
        RMB     2                                 ;CURRENT PAGE NUMBER
PAGLIN
        RMB     1                                 ;CURRENT LINE ON PAGE
VALUE
        RMB     2                                 ;VALUE PRODUCED AS AN OPERAND
EMSG
        RMB     1                                 ;ERROR MESSAGE FLAGE VARIABLE
POST
        RMB     1                                 ;POSTBYTE PRODUCED
INDFLG
        RMB     1                                 ;INDIRECT FLAG
ITYPE
        RMB     1                                 ;SAVED INSTRUCTION TYPE
TITLE
        RMB     60                                ;TITLE SPACE
CODE
        RMB     80                                ;SPACE FOR CODE GENERATION
LINE
        RMB     80                                ;INPUT LINE
        RMB     100                               ;STACK SPACE
STACK           EQU *                             ;PLACE STACK HERE
INFIL
        RMB     522                               ;INPUT FILE BUFFER
LSTFIL
        RMB     522                               ;LIST FILE BUFFER
OBJFIL
        RMB     522                               ;OBJECT FILE BUFFER
SYMTAB          EQU *                             ;SYMBOL TABLE STARTS HERE
;*
        ORG     OSRAM                             ;START IT HERE
;* PROGRAM ENTRY
ASM
        CMPA    #'?'                              ;HELP REQUEST?
        BNE     GOASM                             ;NO
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCC     'Use: ASM[/ERROR/FAST/SYMBOL/TERM/QUIET] <filename>'
        FCB     00
        SWI
        FCB     0
GOASM
        LDA     #RAMHB                            ;POINT TO HIGH BYTE OF DATA AREA
        TFR     A,DP                              ;SET UP DIRECT PAGE
        SETDP   RAMHB                             ;LET ASSEMBLER IN ON IT
        LDS     #STACK                            ;SET UP STACK
        CLRA                                      ;START WITH ORIGIN OF ZERO
        CLRB                                      ;SO WE CAN START THERE
        STD     CURPC                             ;SAVE IT
        STD     ERRORS                            ;CLEAR ERROR FLAG
        STD     LINUM                             ;SET UP FOR FIRST PASS
        CLR     INDFLG                            ;INSURE WE ARE OK
;*
;* TEST FOR QULAIFIER
;*
QUAL
        LDA     ,Y                                ;GET CHARACTER FROM INPUT LINE
        CMPA    #'/'                              ;QUALIFIER?
        BNE     MAIN                              ;NO, QUIT
        LDX     #QTABLE                           ;POINT TO QUALIFIER TABLE
        SWI
        FCB     18                                ;IS THIS IT?
        CMPB    #QMAX                             ;ARE WE OVER LIMIT?
        BHS     QERR                              ;IF SO, INDICATE SO
        LDX     #TERM                             ;POINT TO QUALIFIER TABLE
        CLR     B,X                               ;SET QUALIFIER
        BRA     QUAL                              ;KEEP LOOKING FOR QUALIFIERS
QERR
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCC     'Invalid qualifier: '
        FCB     00
        LDA     ,Y+                               ;GET CHARACTER
DSQU1
        SWI
        FCB     33                                ;DISPLAY
        LDA     ,Y+                               ;GET NEXT CHARACTER
        CMPA    #'/'                              ;ANOTHER QUALIFIER?
        BEQ     GOABO                             ;GO ABORT
        CMPA    #' '                              ;SPACE
        BEQ     GOABO                             ;IF SO, EXIT AS WELL
        CMPA    #$0D                              ;LAST TERMINATOR
        BNE     DSQU1                             ;IF NOT, KEEP DISPLAYING
GOABO
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCB     $27,0                             ;QUOTE
        LDA     #1                                ;INDICATE INVALID OPERATOR
        LBRA    ABORT                             ;AND EXIT
;*
;* INITIALIZATIONS
;*
;* GET FILENAME & SETUP TITLE
;*
MAIN
        PSHS    Y                                 ;SAVE FILENAME POINTER
        SWI
        FCB     11                                ;GET FILENAME
        LBNE    ABORT                             ;INVALID, REPORT ERROR
        STX     FILPTR                            ;SAVE FILENAME
        LDD     #$4153                            ;'AS' GET FIRST PORTION
        STD     ,X                                ;SAVE IT
        LDA     #'M'                              ;LAST CHAR
        STA     2,X                               ;WRITE IT
;* SET UP DEFAULT TITLE
        LDY     #TITLE                            ;POINT TO TITLE
        LEAX    -8,X                              ;BACKUP TO DIRECTORY
        LDB     #8                                ;COPY UP TO 8 CHARS
CPYNAM
        LDA     ,X+                               ;GET CHAR FROM DIR
        BEQ     CPYN1                             ;NO MORE, QUIT
        STA     ,Y+                               ;SAVE IN TITLE
        DECB    REDUCE COUNT
        BNE     CPYNAM                            ;CONTINUE
CPYN1
        LDA     #$0D                              ;GET CR
        STA     ,Y                                ;TERMINATE TITLE
;* OPEN INPUT FILE
        LDU     #INFIL                            ;POINT TO INPUT FCB
        SWI
        FCB     55                                ;OPEN FILE FOR READ
        LBNE    ABORT                             ;ABORT OPERATION
;* OPEN LISTING FILE FOR WRITE
        TST     TERM                              ;TEST FOR LISTING FILE
        BEQ     INITS                             ;IF SO, DONT OPEN LISTING
        LDX     FILPTR                            ;RESTORE FILE POINTER
        LDD     #$4c53                            ;'LS' GET 'LS'
        STD     ,X                                ;SAVE IT
        LDA     #'T'                              ;GET 'T'
        STA     2,X                               ;SAVE IN NAME
        LDU     #LSTFIL                           ;POINT TO LIST FCB
        SWI
        FCB     56                                ;OPEN FILE FOR WRITE
        LBNE    ABORT                             ;ABORT OPERATION
;* INITIALIZE SYMBOL TABLE
INITS
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
        STX     SYMLOC                            ;POINT TO SYMBOL TABLE LOCATION
        CLR     ,X                                ;INDICATE NO SYMBOLS
        TST     QUIET                             ;ARE WE BEING QUIET?
        BEQ     PASS1                             ;DONT SAY A WORD
        SWI
        FCB     24                                ;DISPLAY PASS1 MESSAGE
        FCC     'First pass... '
        FCB     00
;*
;* PASS ONE, RESOLVE SYMBOLS
;*
PASS1
        LDA     #$FF                              ;INSURE HIGH BYTE IS NOT ZERO
        STA     CURDP                             ;SET DIRECT PAGE ADDRESING OFF
PLINE
        LDY     #LINE                             ;POINT TO LINE BUFFER
L1
        LBSR    RDINP                             ;READ A CHARACTER FROM THE FILE
        LBNE    OPTMIZ                            ;WE HAVE HIT THE END, PERFORM OPT. PASSES
        CMPA    #9                                ;IS IT TAB?
        BNE     SAVCHR                            ;NO, SAVE IT
        LDA     #' '                              ;CONVERT TO BLANK
SAVCHR
        STA     ,Y+                               ;SAVE CHARACTER FOR LATER REFERENCE
        CMPA    #$0D                              ;END OF LINE?
        BNE     L1                                ;KEEP LOOKING
        LDY     #LINE                             ;POINT TO START OF LINE
        CLR     EMSG                              ;INSURE NO ERROR MESSAGE
;* TEST FOR COMMENT LINE
        LDA     ,Y                                ;GET FIREST CHARACTER FROM LINE
        CMPA    #'*'                              ;COMMENT?
        BEQ     PLINE                             ;SKIP TO END OF LINE
;* TEST FOR LABLE
        CMPA    #' '                              ;NO LABLE?
        BEQ     SKPLAB                            ;IF SO, IGNORE
        CMPA    #$0D                              ;NULL LINE?
        BEQ     SKPLAB                            ;IF SO, IGNORE
        LBSR    LOCSYM                            ;FIND THE SYMBOL
        LDA     LINUM+1                           ;IS THIS AN OPTOMIZATION PASS?
        BEQ     INSYM                             ;NO, PERFORM FIRST PASS INITIALIZATION
        CMPX    CURPC                             ;IS THIS WHERE WE ARE
        BEQ     SKPLAB                            ;DONT UPDATE
        LBSR    LOCINS                            ;LOOK UP INSTRUCTION
        CMPB    #11                               ;IS IT 'EQU'?
        BEQ     SKPL1                             ;IF SO, DONT FLAG
        PSHS    B                                 ;SAVE INSTRUCTION TYPE
        LDD     CURPC                             ;GET CURRENT PROGRAM COUNTER
        LDX     TEMP                              ;GET ADDRESS OF SYMBOL TABLE ENTRY
        STD     ,X                                ;UPDATE SYMBOL TABLE
        LDA     #$FF                              ;GET SET FLAG
        STA     LINUM                             ;INDICATE WE MADE CHANGES
        PULS    B                                 ;RESTORE INSTRUCTION TYPE
        BRA     SKPL1                             ;CONTINUE
INSYM
        TST     EMSG                              ;DID WE FIND IT?
        BNE     SYMOK                             ;NOT FOUND, ITS OK
;* SYMBOL ALREADY EXISTS, INDICATE SO
        DEC     EMSG                              ;INSURE WE DISPLAY IN ERROR
        LDX     #EMSG1                            ;POINT TO MESSAGE
        LBSR    WRIMSG                            ;DISPLAY
        LBSR    WRIMSG                            ;DISPLAY DUPLICATE SYMBOL MESSAGE,
        LDY     #LINE                             ;POINT TO LINE
OUTSYS
        LBSR    TSTERM                            ;LOOK FOR TERMINATOR
        BEQ     SYMCR                             ;IF SO, QUIT
        LBSR    WRICHR                            ;OUTPUT CHARACTER
        BRA     OUTSYS                            ;KEEP DISPLAYING
SYMCR
        LDA     #$0D                              ;NEW LINE CHARACTER
        LBSR    WRICHR                            ;OUTPUT
        LDD     ERRORS                            ;GET ERROR FLAG
        ADDD    #1                                ;INCREMENT
        STD     ERRORS                            ;RESAVE
        BRA     SKPLAB                            ;DONT INSERT SECOND ONE
;* INSERT SYMBOL INTO SYMBOL TABLE
SYMOK
        LDX     SYMLOC                            ;GET SYMBOL TABLE POSITION
        LDY     #LINE                             ;POINT TO START OF SYMBOL
SYMM
        LBSR    TSTERM                            ;GET CHARACTER
        BEQ     FIXSYM                            ;IF END, STOP
        STA     ,X+                               ;SAVE IN SYMBOL TABLE
        BRA     SYMM                              ;KEEP GOING
FIXSYM
        LDA     -1,X                              ;GET OLD VALUE FROM SYMBOL
        ORA     #$80                              ;SET HIGH BIT
        STA     -1,X                              ;RESAVE
        STX     TEMP                              ;POINT TO VALUE FOR EQUATE
        LDD     CURPC                             ;GET CURRENT PROGRAM COUNTER
        STD     ,X++                              ;SAVE IN SYMBOL TABLE
        CLR     ,X                                ;INDICATE NEW END
        STX     SYMLOC                            ;SAVE NEW SYMBOL TABLE LOCATION
        LDA     #$FF                              ;GET POSITIVE FLAG
        STA     LINUM                             ;INDICATE WE CHANGED
SKPLAB
        LBSR    LOCINS                            ;LOOK UP INSTRUCTION
SKPL1
        DECB    CONVERT TO TYPE 0 ON
        ASLB    TIMES 2 FOR TWO BYTE ENTRIES
        LDU     #P1TAB                            ;POINT TO TABLE
        LDD     B,U                               ;GET ADDRESS
        PSHS    A,B                               ;SAVE ON STACK
        LDU     CURPC                             ;GET CURRENT PROGRAM COUNTER
        RTS     EXECUTE CODE
;* TABLE OF INSTRUCTION HANDLERS FOR PASS 1
P1TAB
        FDB     P1T1
        FDB     P1T2
        FDB     P1T3
        FDB     TYP4
        FDB     TYP4
        FDB     TWOBYT
        FDB     P1T7
        FDB     P1T8
        FDB     TWOBYT
        FDB     TWOBYT
        FDB     P1T11
        FDB     P1T12
        FDB     P1T13
        FDB     P1T14
        FDB     P1T15
        FDB     P1T16
        FDB     P1T17
        FDB     TWOBYT
        FDB     P1T19
        FDB     PLINE
        FDB     PLINE
;* TYPE 1, INHERENT ADDRESSING
P1T1
        TST     1,X                               ;IS IT A TWO BYTE OPCODE?
        BEQ     ONEBYT                            ;ONLY ONE BYTE
TWOBYT
        LEAU    1,U                               ;ADVANCE PC ONE BYTE
ONEBYT
        LEAU    1,U                               ;ADVANCE CURRENT PROGRAM COUNTER
SAVPC
        STU     CURPC                             ;SAVE CURRENT PROGRAM COUNTER
        LBRA    PLINE                             ;PROCESS NEXT LINE
;* TYPE2, MEMORY REFERENCE, EIGHT BIT
P1T2
        LBSR    MEMOP                             ;EVALUATE MEMORY OPERAND
        TSTA    IS IT IMMEDIATE
        BNE     NPIMM                             ;NO, DONT ADJUST
        DECB    USE ONLY EIGHT BIT VALUE
NPIMM
        LEAU    B,U                               ;ADVANCE PROGRAM COUNTER
        BRA     ONEBYT                            ;INLUDE OPCODE AND UPDATE PROGRAM COUNTER
;* TYPE3, SAME AS TYPE 2, BUT 16BIT IMMEDIATE DATA
P1T3
        LBSR    MEMOP                             ;CALCULATE LENGTH
        BRA     NPIMM                             ;CONTINUE
TYP4
        LBSR    MEMOP                             ;GET MEMORY OPERANDS
        INCB    ADVANCE OPERAND COUNT
        BRA     NPIMM                             ;GENERATE OPCODE
;* TYPE	7, LONG BRANCHES
P1T7
        LEAU    3,U                               ;SKIP FOR FOUR BYTES
        BRA     ONEBYT                            ;AND CALCULATE
;* LBRA AND LBSR
P1T8
        LEAU    2,U                               ;THREE BYTE INSTRUCTION
        BRA     ONEBYT                            ;CONTINUE
;* TYPE 11, EQUATE STATEMENT
P1T11
        LDU     TEMP                              ;GET POINTER TO VALUE
        LBSR    EVAL                              ;GET VALUE
        TST     LINUM+1                           ;IS THIS AN OPTOMIZE?
        BEQ     SETSYM                            ;NO, SET SYMBOL VALUE
        CMPD    ,U                                ;IS IT THE SAME?
        BEQ     SETSYM                            ;IF SO, ITS OK
S1
        DEC     LINUM                             ;INSURE FLAG IS SET
        BEQ     S1                                ;SPECIAL CASE
SETSYM
        STD     ,U                                ;CHANGE VALUE OF LAST SYMBOL
        BRA     PLI1                              ;PROCESS NEXT LINE
;* TYPE 12, ORG STATEMENT
P1T12
        LBSR    EVAL                              ;EVALUATE NEW LOCATION
        STD     CURPC                             ;SAVE NEW PC
PLI1
        LBRA    PLINE                             ;START FROM HERE
;* 'RMB' INSTRUCTION
P1T13
        LBSR    EVAL                              ;EVALUATE OPERAND
        LEAU    D,U                               ;ADVANCE THAT MANY BYTES
SAVP1
        BRA     SAVPC                             ;CONTINUE
;* 'FCB' DIRECTIVE
P1T14
        BSR     FCBLEN                            ;CALCULATE LENGTH
        LEAU    D,U                               ;ADD TO CODE LENGTH
        BRA     SAVPC                             ;PROCESS
;*
;* CALCULATES LENGTH ON A 'FCB' TYPE OPERAND
;*
FCBLEN
        LDX     #0                                ;START OUT WITH ZERO
ADDFCB
        LEAX    1,X                               ;ADVANCE COUNTER
        LBSR    EVAL                              ;EVALUATE ON OPERAND
        LDA     -1,Y                              ;GET TERMINATING CHAR
        CMPA    #','                              ;IS THERE MORE?
        BEQ     ADDFCB                            ;CONTINUE
        TFR     X,D                               ;COPY FOR LATER
        RTS
;* 'FDB' DIRECTIVE
P1T15
        BSR     FCBLEN                            ;LOOK UPLENGTH
        LEAU    D,U                               ;ADD IN FOR ONE BYTE
        LEAU    D,U                               ;ADD IN FOR TWO BYTES
        BRA     SAVP1                             ;PROCESS
;* 'FCC' DIRECTIVE
P1T16
        BSR     FCCLEN                            ;FIND OUT ITS LENGTH
        LEAU    D,U                               ;ADVANCE
        BRA     SAVP1                             ;SAVE NEW ADDRESS
;*
;* CALCULATES THE LENGTH OF A STRING
;*
FCCLEN
        LDX     #$FFFF                            ;START WITH -1 LENGTH
        LBSR    TSTERM                            ;GET TERMINATOR
        CMPA    #$0D                              ;TEST FOR NULL LINE
        BEQ     STRERR                            ;ITS INVALID
        STA     TEMP                              ;SAVE FOR LATER
FCC1
        LEAX    1,X                               ;ADVANCE
        LBSR    TSTERM                            ;CONTINUE
        CMPA    #$0D                              ;END OF LINE
        BEQ     STRERR                            ;IF SO, ITS TERRIBLE
        CMPA    TEMP                              ;IS IT THE SAME?
        BNE     FCC1                              ;NO, ITS NOT
STRERR
        TFR     X,D                               ;COPY TO ACCUMULATOR
        RTS
;* 'FCCZ' DIRECTIVE
P1T17
        BSR     FCCLEN                            ;GET LENGTH
        ADDD    #1                                ;OFFSET ONE FOR ZERO BYTE
        LEAU    D,U                               ;ADD TO ADDRESS
        BRA     SAVP1                             ;SAVE NEW PROGRAM COUNTER
;* 'SETDP' DIRECTIVE
P1T19
        LBSR    EVAL                              ;GET OPERAND VALUE
        STD     CURDP                             ;SET CURRENT DIRECT PAGE VALUE
        BRA     PLI1
;*
;* OPTIMIZATION PASSES, RERUN FIRST PASS UNTIL ALL FORWARD REFERENCES
;* ARE RESOLVED
;*
OPTMIZ
        CLRA    GET ORIGIN ADDRESS
        CLRB    OF ZERO
        STD     CURPC                             ;SET PROGRAM COUNTER BACK
        LDU     #INFIL
        SWI
        FCB     62                                ;REWIND INPUT FILE
        LDD     ERRORS                            ;ANY DUPLICATE SYMBOLS?
        BNE     PASS2                             ;IF SO, DONT TRY TO OPTOMIZE
        LDA     DEBUG                             ;ARE WE DEBUGGING?
        BEQ     PASS2                             ;IF SO, DONT PERFORM OPTOMIZE
        LDA     LINUM                             ;CHANGE ANYTHING?
        BEQ     PASS2                             ;NO, AOK
        TST     QUIET                             ;ARE WE BEING QUIET?
        BEQ     OPTA                              ;IF SO, KEEP MUM
        SWI
        FCB     24
        FCC     'Opt... '
        FCB     00
OPTA
        LDA     #$FF                              ;GET FLAG
        STA     LINUM+1                           ;INDICATE OPTIMIZE
        CLR     LINUM                             ;RESET CHANGE FLAG
        LBRA    PASS1                             ;IF NOT, WE ARE OK
;*
;* PASS TWO, GENERATE CODE
;*
PASS2
        TST     QUIET                             ;ARE WE BEING QUIET?
        BEQ     NOM1                              ;IF SO, SHUT UP
        SWI
        FCB     24
        FCC     'Second pass... '
        FCB     00
NOM1
        CLRA    GET HIGH ZERO
        CLRB    GET LOW ZERO
        STD     LINUM                             ;SET UP LINE NUMBER
        STD     PAGE                              ;SET CURRENT PAGE NUMBER
        CLR     PAGLIN                            ;INSURE WE WILL GENERATE TITLE
        CLR     EMSG                              ;INDICATE NO ERROR
        COMA    GET $FF
        STA     CURDP                             ;INSURE NO DIRECT PAGE ADDRESSING
;* OPEN OBJECT FILE FOR WRITE
        LDX     FILPTR                            ;GET FILENAME POINTER BACK
        LDD     #$4F42                            ;'OB' GET 'OB'
        STD     ,X                                ;SAVE IT
        LDA     #'J'                              ;GET 'J'
        STA     2,X                               ;SAVE IN NAME
        LDU     #OBJFIL                           ;POINT TO OBJECT FCB
        SWI
        FCB     56                                ;OPEN FILE FOR WRITE
        LBNE    ABORT                             ;ABORT OPERATION
;* PROCESS FOR EACH LINE
P2LIN
        LDY     #LINE                             ;POINT TO LINE BUFFER
        CLRB    START ON LOCATION ZERO
P21
        LBSR    RDINP                             ;GET A CHARACTER
        LBNE    QUIT                              ;GIVE UP ON ERROR
        CMPA    #9                                ;CHECK FOR TAB
        BNE     NOTTAB                            ;NO, SAVE NORMAL CHARACTER
        LDA     #' '                              ;GET SPACE
STAB1
        STA     ,Y+                               ;SAVE IN LINE
        INCB    ADVANCE SAVED CHARACTER
        BITB    #7                                ;ARE AT A TABSTOP
        BNE     STAB1                             ;NO, SKIP IT
        BRA     P21                               ;GET NEXT CHARACTER
NOTTAB
        STA     ,Y+                               ;SAVE IN BUFFER
        INCB    ADVANCE TO NEXT
        CMPA    #$0D                              ;IS IT END OF LINE?
        BNE     P21                               ;IF NOT, KEEP GOING
        LDY     #LINE                             ;RESTORE POSITION IN LINE
        LDA     ,Y                                ;GET CHARACTER FROM START OF LINE
        CMPA    #'*'                              ;IS IT A COMMENT
        BNE     FNDSPC                            ;NO, KEEP PROCESSING
        LBSR    DSPTTL                            ;DISPLAY TITLE IF NESSARY
        LDX     CURPC                             ;SET CURRENT PROGRAM COUNTER ADDRESS
        BRA     GENLI1                            ;GENERATE BLANK LINE IN LISTING
FNDSPC
        LDA     ,Y+                               ;EXAMINE CHARACTER FROM LINE
        CMPA    #$0D                              ;END OF LINE (NO INST)?
        BEQ     GOINS                             ;IF SO, EXIT LOOP
        CMPA    #' '                              ;IS IT A SPACE (PAST LABEL)?
        BNE     FNDSPC                            ;IF NOT, LOOK FOR ONE
GOINS
        LEAY    -1,Y                              ;BACKUP TO TERMINATOR
        LBSR    LOCINS                            ;LOOK UP INSTRUCTION
        LDU     #P2TAB                            ;POINT TO TABLE
        DECB    CONVERT TO ZERO OFFSET
        ASLB    TWO BYTES/ENTRY
        LDD     B,U                               ;GET ADDRESS
        PSHS    A,B                               ;SAVE ON STACK
        LDU     #CODE                             ;PLACE TO PUT THE CODE
        RTS     EXECUTE CODE
;* TABLE OF INSTRUCTION HANDLERS FOR PASS 2
P2TAB
        FDB     P2T1
        FDB     P2T2
        FDB     P2T3
        FDB     P2T4
        FDB     P2T5
        FDB     P2T6
        FDB     P2T7
        FDB     P2T8
        FDB     P2T9
        FDB     P2T10
        FDB     P2T11
        FDB     P2T12
        FDB     P2T13
        FDB     P2T14
        FDB     P2T15
        FDB     P2T16
        FDB     P2T17
        FDB     P2T18
        FDB     P2T19
        FDB     P2T20                             ;PAGE DIRECTIVE
        FDB     P2T21                             ;TITLE DIRECTIVE
;* TYPE1, INHERENT ADDRESSING
P2T1
        LDA     ,X+                               ;GET OPCODE FROM TABLE
        BEQ     GENLIS                            ;IF END, THEN GENERATE LISTING
        STA     ,U+                               ;SAVE IN MEMORY
        BRA     P2T1                              ;TEST FOR ANOTHER OPCODE BYTE
;*
;* GENERATE LISTING
;*
GENLIS
        LBSR    DSPTTL                            ;DISPLAY TITLE IF NESSARY
        LDX     CURPC                             ;GET OUR ADDRESS
        TFR     U,D                               ;COPY TO D REGISTER
        SUBD    #CODE                             ;CONVERT TO BINARY OFFSET
        LEAU    D,X                               ;GET NEW ADDRESS
        STU     CURPC                             ;SAVE IN MEMORY
        LDU     #CODE                             ;POINT TO CODE SPACE
        LDA     ,U                                ;GET OPCODE
        CMPA    #$CF                              ;CHECK FOR INVALID ADDRESSING MODE
        BNE     GENLI1                            ;ADDRESSING IS OK
        LDA     ITYPE                             ;GET INSTRUCTION TYPE BACK
        CMPA    #$B                               ;IS IT A DIRECTIVE
        BHI     GENLI1                            ;DONT GENERATE ERROR FOR DIRECTIVES
        LDA     #3                                ;'INVALID ADDRESSING MODE'
        LBSR    SETERR                            ;SET ERROR MESSAGE
GENLI1
        TFR     X,D                               ;COPY TO D REGISTER
        LBSR    WRIBYT                            ;OUTPUT BYTE IN HEX
        TFR     B,A                               ;GET LOW BYTE
        LBSR    WRIBYT                            ;OUTPUT
LISOUT
        LBSR    SPACE                             ;DISPLAY A SPACE
        LBSR    SPACE                             ;AND ANOTHER
        LDB     #5                                ;# LISTING BYTES TO ALLOW
LISO1
        CMPX    CURPC                             ;ARE WE AT LIMIT?
        BEQ     LISO2                             ;IF SO, DONT DISPLAY MORE CODE
        LEAX    1,X                               ;ADVANCE TO NEXT
        LDA     ,U+                               ;GET BYTE OF CODE
        LBSR    WRIOBB                            ;WRITE OUTPUT BYTE
        DECB    BACKUP COUNT
        BMI     LISO1                             ;DONT OUTPUT
        LBSR    WRIBYT                            ;OUTPUT IN HEX
        LBSR    SPACE                             ;PRINT A SPACE
        BRA     LISO1                             ;AND CONTINUE
;* IF NON-DISPLAYED CODE IS PRESENT, OUTPUT INDICATOR
LISO2
        LDA     #'+'                              ;OVERFLOW INDICATOR
        TSTB    DID WE OVERFLOW?
        BMI     LISO5                             ;YES, OUTPUT INDICATOR
;* FILL LISTING WITH SPACES
LISO3
        DECB    REDUCE COUNT
        BMI     LISO4                             ;NO MORE SPACE
        LBSR    SPACE                             ;PRINT A SPACE
        LBSR    SPACE                             ;PRINT A SPACE
        LBSR    SPACE                             ;PRINT A SPACE
        BRA     LISO3                             ;BACKUP
LISO4
        LDA     #' '                              ;GET SPACE
LISO5
        LBSR    WRICHR                            ;OUTPUT CHARACTER
;* OUTPUT LINE NUMBER
        LDD     LINUM                             ;GET LINE NUMBER
        ADDD    #1                                ;INCREMENT
        STD     LINUM                             ;REPLACE
        CMPD    #10000                            ;ARE WE < 10000
        BHS     NS1                               ;NO, WE ARE OK
        LBSR    SPACE                             ;PAD WITH SPACE
NS1
        CMPD    #1000                             ;< 1000
        BHS     NS2                               ;NO, WE ARE OK
        LBSR    SPACE                             ;PAD WITH SPACE
NS2
        CMPD    #100                              ;< 100?
        BHS     NS3                               ;NO, WE ARE OK
        LBSR    SPACE                             ;PAD WITH SPACE
NS3
        CMPD    #10                               ;< 10
        BHS     NS4                               ;NO, WE ARE OK
        LBSR    SPACE                             ;PAD WITH SPACE
NS4
        LBSR    WRIDEC                            ;OUTPUT DECIMAL NUMBER
        LBSR    SPACE                             ;DISPLAY A SPACE
        LBSR    SPACE                             ;AND ANOTHER
;* OUTPUT ASSEMBLY SOURCE LINE
        LDY     #LINE                             ;POINT TO LINE
DSPLIN
        LDA     ,Y+                               ;GET CHARACTER FROM LINE
        LBSR    WRICHR                            ;DISPLAY
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BNE     DSPLIN                            ;KEEP DISPLAYING
        LBSR    DSPERR                            ;DISPLAY ANY ERROR MESSAGE
        LBRA    P2LIN                             ;PAGE EJECT IF NESSARY
;* TYPE2, MEMORY REFERENCE, EIGHT BIT
P2T2
        LBSR    MEMOP                             ;EVALUATE MEMORY OPERAND
        TSTA    IS IT IMMEDIATE
        BNE     PNIMM                             ;NO, DONT ADJUST
        DECB    USE ONLY EIGHT BIT VALUE
PNIMM
        PSHS    A                                 ;SAVE INSTRUCTON TYPE
        LDA     A,X                               ;GET OPCODE
        STA     ,U+                               ;SAVE OPCODE
        PULS    A                                 ;GET TYPE BACK
        CMPA    #2                                ;IS IT MEMORY REFERENCE?
        BNE     NOPOST                            ;NO POSTBYTE
        LDA     POST                              ;GET POSTBYTE
        STA     ,U+                               ;SAVE POSTBYTE
        DECB    REDUCE LENGTH BY ONE FOR POSTBYTE
NOPOST
        DECB    TEST FOR ZERO OPERANDS
        BMI     T2E                               ;IF NONE, STOP
        LDA     VALUE+1                           ;GET LOWER BYTE OF VALUE
        STA     ,U+                               ;SAVE EIGHT BIT OPERAND VALUE
        DECB    TEST FOR ONE OPERAND BYTE
        BMI     T2E                               ;IF SO, QUIT
        LDD     VALUE                             ;GET ENTIRE 16 BIT VALUE
        STD     -1,U                              ;SAVE IN CODE AREA
        LEAU    1,U                               ;SKIP LAST BYTE
T2E
        LBRA    GENLIS                            ;PRODUCE LISTING
;* TYPE 3, 16 BIT DATA
P2T3
        LBSR    MEMOP                             ;EVALUATE OPERANDS
        BRA     PNIMM                             ;CACULATE AND PRODUCE CODE
;* TYPE4, SAME AS TYPE 3 BUT HAS $10 PREFIX
P2T4
        LDA     #$10                              ;GET PREFIX
        STA     ,U+                               ;SAVE IN MEMORY
        BRA     P2T3                              ;CONTINUE
;* TYPE5, SAME AS TYPE 3 BUT HAS $11 PREFIX
P2T5
        LDA     #$11                              ;GET PREFIX
        STA     ,U+                               ;SAVE IN MEMORY
        BRA     P2T3                              ;CONTINUE
;* TYPE6, SHORT BRANCHES
P2T6
        LDA     ,X                                ;GET OPCODE
        STA     ,U+                               ;SAVE IN MEMORY
        LBSR    EVAL                              ;GET OPERAND VALUE
        SUBD    CURPC                             ;CONVERT TO PC RELATIVE OFFSET
        SUBD    #2                                ;ADJUST FOR OFFSET OF CURRENT INSTRUCT
        CMPD    #128                              ;POSITIVE RANGE
        BLO     RANOK                             ;ITS OK
        CMPD    #-128                             ;NEGATIVE RANGE
        BHS     RANOK                             ;ALSO IS WITHIN RANGE
        LDA     #2                                ;'ADDRESS OUT OF RANGE'
        LBSR    SETERR                            ;INDICATE ERROR
RANOK
        STB     ,U+                               ;SAVE LOWER EIGHT BITS
        BRA     T2E                               ;GENERATE LISTING
;* LONG CONDITIONAL BRANCHES
P2T7
        LDD     ,X                                ;GET PREFIX AND OPCODE
        STD     ,U++                              ;SAVE IN CODE
        LBSR    EVAL                              ;EVALUATE OPERANDS
        SUBD    CURPC                             ;CONVERT TO OFFSET
        SUBD    #4                                ;CONVERT TO NORMAL
        STD     ,U++                              ;SAVE IN CODE
        BRA     T2E                               ;GENERATE LISTING
;* LONE BRANCH AND LBSR
P2T8
        LDA     ,X                                ;GET OPCODE
        STA     ,U+                               ;SAVE IN MEMORY
        LBSR    EVAL                              ;EVALUATE OPERANDS
        SUBD    CURPC                             ;CALCULATE OFFSET
        SUBD    #3                                ;CONVERT TO NORMAL
        STD     ,U++                              ;SAVE IN CODE
        BRA     T2E                               ;GENERATE LISTING
;* TYPE 9, PSH AND PUL
P2T9
        LDA     ,X                                ;GET OPCODE
        STA     ,U+                               ;SAVE IN CODE
        CLR     ,U+                               ;CLEAR POSTBYTE
FNDREG
        LDX     #POTAB                            ;POINT TO TABLE
        CLRB    START WITH NO BITS
        LDA     ,Y+                               ;GET CHARACTER FROM OPERAND
        CMPA    #'S'                              ;IS IT S?
        BNE     NOTS                              ;NO, ITS OK
        LDA     #'U'                              ;CHANGE TO U
NOTS
        ORCC    #1                                ;SET CARRY
F1
        ROLB    SHIFT IN BIT
        BCS     POPERR                            ;ERROR CONDITION
        CMPA    ,X+                               ;IS THIS IT
        ANDCC   #$FE                              ;INSURE CARRY CLEAR
        BNE     F1                                ;ITS BAD
        CMPA    #'D'                              ;WAS THIS 'DP'?
        BNE     NOADJ                             ;NO, DONT ADJUST
        LDA     ,Y                                ;GET OPERAND BYTE
        CMPA    #'P'                              ;IS IT 'DP'
        BEQ     NOADJ                             ;DONT ADJUST
        LDB     #6                                ;CONVERT TO A+B
NOADJ
        ORB     -1,U                              ;INCLUDE OLD VALUE
        STB     -1,U                              ;REPLACE
FNCOM
        LBSR    TSTERM                            ;LOOK FOR TERMINATOR
        BNE     FNCOM                             ;TILL WE FIND
        CMPA    #','                              ;IS IT A COMMA
        BEQ     FNDREG                            ;IF SO, ITS OK
T3E
        LBRA    GENLIS                            ;CONTINUE
TFRERR
        LDA     #7                                ;'INVALID ARGUMENT FORMAT'
TFRE1
        LBSR    SETERR                            ;SAVE IT
        BRA     T3E                               ;AND GO GOME
POTAB
        FCC     'CABDXYUP'	PUSH OPERAND TABLE
;* TYPE 10, TRANSFER AND EXCHANGE
P2T10
        LDA     ,X                                ;GET OPCODE
        STA     ,U++                              ;SAVE IN OUTPUT
        BSR     FNTREG                            ;GET REGSITER
        ASLB    ROTATE
        ASLB    ROTATE
        ASLB    ROTATE
        ASLB    ROTATE
        STB     -1,U                              ;SAVEPOSTBYTE
        LBSR    TSTERM                            ;GET TERMINATOR
        CMPA    #','                              ;COMMA?
        BNE     TFRERR                            ;IF NOT, ITS INVALID
        BSR     FNTREG                            ;GET NEXT REGISTER
        ORB     -1,U                              ;ADD IN OLD VALUE
        STB     -1,U                              ;RESAVE
        BRA     T3E                               ;GENERATE LISTING
;* CALCULATE TRANSFER & EXCHANGE REGISTER
FNTREG
        LDA     ,Y+                               ;GET REGISTER NAME
        LDX     #TFRTAB                           ;POINT TO TABLE
        LDB     #$FF                              ;START WITH MINUS ONE
F2
        INCB    ADVANCE TO NEXT
        CMPB    #12                               ;ARE WO OVER?
        BHS     TOPERR                            ;INDICATE INVALID
        CMPA    ,X+                               ;IS THIS IT?
        BNE     F2                                ;NO, TRY AGAIN
        CMPA    #'D'                              ;IS IT A+B?
        BNE     NOATJ                             ;DONT ADJUST
        LDA     ,Y                                ;LOOK FOR NEXT CHARACTER
        CMPA    #'P'                              ;IS IT 'DP'
        BNE     NOATJ                             ;DONT ADJUST
        LEAY    1,Y                               ;ADVANCE POINTER
        LDB     #$B                               ;CONVERT TO DPR SPEC
NOATJ
        RTS
TOPERR
        LEAS    2,S                               ;SKIP CRAP
POPERR
        LDA     #4                                ;'INVALID REGISTER'
        BRA     TFRE1                             ;GENERATE ERROR MESSAGE
TFRTAB
        FCC     'DXYUSP..ABCD'
;* EQUATE, EVALUATE OPERANDS FOR ERROR MESSAGES
P2T11
        LBSR    EVAL                              ;EVALUATE OPERANDS FOR FUN
WRAD1
        PSHS    A,B                               ;SAVE REGISTERS
        LBSR    DSPTTL                            ;DISPLAY TITLE IF NESSARY
        PULS    A,B                               ;RESTRE REGISTERS
        LBSR    WRIBYT                            ;DISPLAY HIGH BYTE
        TFR     B,A                               ;COPY LOWER BYTE
        LBSR    WRIBYT                            ;DISPLAY LOW BYTE
        LDX     CURPC                             ;INSURE WE HAVE VALID ADDRESS
        LBRA    LISOUT                            ;GENERATE LISTING
;* ORG STATEMENT
P2T12
        LBSR    EVAL                              ;EVLAUATE OPERANDS
        STD     CURPC                             ;SET CURRENT PROGRAM COUNTER
        BSR     WRCADR                            ;INDICATE WE CHANGED ADDRESS
        LDD     CURPC                             ;GET ADDRESS BACK
        BRA     WRAD1                             ;GO BACK
;* WRITE AN ADDRESS CHANGE RECORD
WRCADR
        PSHS    A,B                               ;SAVE HIGH BYTE
        LDA     #$CF                              ;GET FLAG BYTE
        LBSR    WRIOBJ                            ;OUTPUT TO OBJECT FILE
        LDA     #$01                              ;ADDRESS CHANGE
        LBSR    WRIOBJ                            ;OUTPUT
        PULS    A                                 ;GET HIGH BYTE BACK
        LBSR    WRIOBJ                            ;OUTPUT TO FILE
        PULS    A                                 ;GET LOW ADDRESS
        LBRA    WRIOBJ                            ;OUTPUT
;* 'RMB' DIRECTIVE
P2T13
        LBSR    EVAL                              ;GET OFFSET TO ADD
        ADDD    CURPC                             ;CALCULATE NEW PC
        LDX     CURPC                             ;GET OLD PC VALUE
        STD     CURPC                             ;SET UP NEW VALUE
        BSR     WRCADR                            ;INDICATE WE CHANGED ADDRESS
        TFR     X,D                               ;COPY OLD VALUE OVER
        BRA     WRAD1                             ;OUTPUT ADDRESS
;* 'FCB' DIRECTIVE
P2T14
        LBSR    EVAL                              ;EVALUATE OPERAND
        STB     ,U+                               ;SAVE DATA IN CODE
        LDA     -1,Y                              ;GET TERMINATING CHARACTER
        CMPA    #','                              ;IS IT A COMMA
        BEQ     P2T14                             ;IF SO, GENERATE MORE
T4E
        LBRA    GENLIS
;* 'FDB' DIRECTIVE
P2T15
        LBSR    EVAL                              ;EVALUATE OPERAND
        STD     ,U++                              ;SAVE CODE
        LDA     -1,Y                              ;GET TERMINATING CHARACTER
        CMPA    #','                              ;WAS THERE MORE
        BEQ     P2T15                             ;IF SO, GIVE IT TO HIM
        BRA     T4E
;* 'FCC' DIRECTIVE
P2T16
        BSR     FCCCHR                            ;PUT IN STRING
        BRA     T4E                               ;AND PRODUCE LISTING
;* GENERATES FCC STRING
FCCCHR
        LBSR    TSTERM                            ;GET TERMINATOR
        CMPA    #$0D                              ;CHECK FOR END OF LINE
        BEQ     INVSTR                            ;STRING IS INVALID
        STA     TEMP                              ;SAVE FOR LATER REFERENCE
FCCM
        LBSR    TSTERM                            ;GET A CHARACTER
        CMPA    #$0D                              ;END OF LINE
        BEQ     INVSTR                            ;STRING IS INVALID
        CMPA    TEMP                              ;IS THIS IT?
        BEQ     FCCEND                            ;IF SO, WE ARE DONE
        STA     ,U+                               ;SAVE IN MEMORY
        BRA     FCCM                              ;KEEP MOVING THE STRING
INVSTR
        LDA     #8                                ;'STRING NOT PROPERLY DELIMITED'
        LBRA    SETERR                            ;SET UP ERROR MESAGE
FCCEND
        RTS     GO BACK
;* 'FCCZ' DIRECTIVE
P2T17
        BSR     FCCCHR                            ;CALCULATE STRING
        CLR     ,U+                               ;AND APPEND A ZERO
        BRA     T4E                               ;AND GENERATE LISTING
;* SSR DIRECTIVE
P2T18
        LDA     ,X                                ;GET OPCODE
        STA     ,U+                               ;SAVE IN CODE SPACE
        LBSR    EVAL                              ;GET OPERAND
        STB     ,U+                               ;SAVE IN OUTPUT CODE
        BRA     T4E                               ;PRODUCE LISTING
;* 'SETDP' DIRECTIVE
P2T19
        LBSR    EVAL                              ;GET OPERAND VALUE
        STD     CURDP                             ;SAVE CURRENT DIRECT PAGE
        BRA     T4E
;* 'PAGE' DIRECTIVE
P2T20
        CLR     PAGLIN                            ;FORCE PAGE EJECT
        LBRA    P2LIN                             ;AND RETURN FOR NEXT LINE
;* 'TITLE' DIRECTIVE
P2T21
        LDX     #TITLE                            ;POINT TO TITLE SPACE
TITL1
        LDA     ,Y+                               ;GET CHARACTER FROM SOURCE
        STA     ,X+                               ;SAVE IN MEMORY
        CMPA    #$0D                              ;END OF LINE?
        BNE     TITL1                             ;NO, KEEP GOING
        LBRA    P2LIN                             ;PROCESS NEXT LINE
;*
;* TERMINATION OF ASSEMBLER
;*
QUIT
        TST     QUIET
        BEQ     NOM2                              ;DONT SAY A WORD
        LDD     ERRORS
        SWI
        FCB     26                                ;OUTPUT NUMBER
        SWI
        FCB     25
        FCC     ' error(s)'
        FCB     00
NOM2
        LDA     #$0D                              ;NEW LINE
        LBSR    WRICHR                            ;OUTPUT
        TST     TERM                              ;TERMINAL OUTPUT?
        BEQ     NOSUM                             ;IF SO, DONT GENERATE SUMMARY
        LDX     #ERRSUM                           ;POINT TO MESSAGE
        LBSR    WRIMSG                            ;OUTPUT
        LDD     ERRORS                            ;GET ERROR COUNT
        LBSR    WRIDEC                            ;OUTPUT
        LDA     #$0D                              ;CARRIAGE RETURN
        LBSR    WRICHR                            ;OUTPUT
        LBSR    WRICHR                            ;OUTPUT
;* DISPLAY SYMBOL TABLE
NOSUM
        TST     SYM                               ;DO WE DISPLAY SYMBOL TABLE?
        BNE     CLLST                             ;NO, DONT BOTHER
        CLR     PAGLIN                            ;INSURE WE GET NEW PAGE
        LBSR    DSPTTL                            ;DISPLAY PAGE HEADER
        DEC     EMSG                              ;INSURE WE OUTPUT
        LDX     #SYMMSG                           ;POINT TO MESSAGE
        LBSR    WRIMSG                            ;OUTPUT
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
NEWL
        LDA     #$0D                              ;GET CARRIAGE RETURN
        LBSR    WRICHR                            ;OUTPUT
        LDA     #8                                ;DISPLAY 6/LINE
        TST     TERM                              ;IS THIS TO TERMINAL?
        BNE     DSPX1                             ;NO, ITS OK
        LDA     #5                                ;CHANGE TO 5/LINE
DSPX1
        STA     TEMP                              ;SAVE COUNTER
DSPSY
        TST     ,X                                ;END OF TABLE?
        BEQ     ENDSY                             ;IF SO, QUIT NOW
        LDB     #8                                ;MAX OF 8 CHARS
OSYM
        LDA     ,X                                ;GET CHARACTER
        ANDA    #$7F                              ;REMOVE EXTRA BIT
        LBSR    WRICHR                            ;OUTPUT
        DECB    REDUCE COUNT
        BEQ     SKRST                             ;IF END, SKIP THE REST
        LDA     ,X+                               ;GET NEXT CHARACTER
        BPL     OSYM                              ;KEEP GOING
FILSP
        LBSR    SPACE                             ;DISPLAY A SPACE
        DECB    REDUCE COUNT
        BPL     FILSP                             ;CONTINUE
        BRA     OADR                              ;OUTPUT ADDRESS
SKRST
        TST     ,X+                               ;SKIP REMAINING CHARACTERS
        BPL     SKRST                             ;TILL WE HIT END
        LDA     #'+'                              ;INDICATE THERE IS MORE
        LBSR    WRICHR                            ;OUTPUT
OADR
        LDA     ,X+                               ;GET FIRST BYTE
        LBSR    WRIBYT                            ;OUTPUT
        LDA     ,X+                               ;GET NEXT BYTE
        LBSR    WRIBYT                            ;OUTPUT
        LBSR    SPACE                             ;DISPLAY SPACE
        LBSR    SPACE                             ;AND ANOTHER
        DEC     TEMP                              ;REDUCE COUNT
        BNE     DSPSY                             ;GET NEXT
        BRA     NEWL                              ;TRY A NEW LINE
ENDSY
        LDA     #$0D                              ;GET CARRIAGE RETURN
        LBSR    WRICHR                            ;OUTPUT
;* CLOSE LISTING FILE
CLLST
        TST     TERM                              ;ARE WE LISTING?
        BEQ     CLOBJ                             ;NO NEED TO CLOSE
        LDU     #LSTFIL
        SWI
        FCB     57
;* CLOSE OBJECT FILE
CLOBJ
        LDA     #$CF                              ;GET FLAG CHARACTER
        LBSR    WRIOBJ                            ;OUTPUT
        CLRA    GET EOF MARKER
        LBSR    WRIOBJ                            ;OUTPUT TO FILE
        LDU     #OBJFIL
        SWI
        FCB     57                                ;CLOSE IT
        LDD     ERRORS                            ;WERE THERE ANY ERRORS?
        BEQ     ABORT                             ;NO, WE WERE OK
        LDA     #100                              ;SET RETURN CODE
;*
;* ABORT ASSEMBLER, RETURN TO OS
;*
ABORT
        SWI
        FCB     0                                 ;BACK TO OS
;*
;* LOOK UP INSTRUCTIONS POINTED TO BY THE Y REGISTER IN THE INSTRUCTION TABLE
;* ON EXIT, ACCA CONTAINS TYPE OF INSTRUCTION, AND X POINTS TO FOUR BYTE OPCODE
;* TABLE IN RAM
;*
LOCINS
        LDX     #INSTAB                           ;POINT TO INSTRUCTON TABLE
        LBSR    SKIP                              ;SKIP TO INSTRUCTION
LOC1
        PSHS    Y                                 ;SAVE POINTER TO INSTRUCTION
LOC2
        LBSR    TSTERM                            ;GET CHARACTER FROM LINE
        BEQ     IMATCH                            ;WE MAY HAVE FOUND IT
        CMPA    ,X+                               ;IS THIS IT?
        BEQ     LOC2                              ;LOOKS LIKE IT
LOC4
        LEAX    -1,X                              ;BACKUP INCASE WE ARE AT END
LOC3
        LDA     ,X+                               ;GET VALUE
        BPL     LOC3                              ;SKIP TO NEXT
        LEAX    4,X                               ;SKIP TO NEXT INSTRUNCTION
        PULS    Y                                 ;RESTORE REGISTER POINTER
        TST     ,X                                ;ARE WE AT END OF TABLE?
        BNE     LOC1                              ;TRY THIS ENTRY
        LDA     #1                                ;'UNKNOWN OPCODE'
        LBSR    SETERR                            ;INDICATE WE HAVE AN ERROR
        LDB     #1                                ;INDICATE TYPE ONE
        RTS
IMATCH
        LDB     ,X+                               ;IS THIS IT
        BPL     LOC4                              ;NO, KEEP GOING
        LEAS    2,S                               ;REMOVE Y REGISTER FROM STACK
        ANDB    #$7F                              ;REMOVE HIGH BIT FLAG
        STB     ITYPE                             ;SAVE INSTRUCTION TYPE
;*
;* SKIPS TO NEXT OPERAND
;*
SKIP
        LDA     ,Y+                               ;GET CHARACTER FROM LINE
        CMPA    #' '                              ;SPACE?
        BEQ     SKIP                              ;IF SO, KEEP GOING
        LEAY    -1,Y                              ;BACKUP TO OPERAND
        RTS
;*
;* LOOK UP SYMBOL VALUE
;*
LOCSYM
        LDX     #SYMTAB                           ;POINT TO INSTRUCTON TABLE
LOCSY1
        PSHS    Y                                 ;SAVE POINTER TO INSTRUCTION
SYM2
        LBSR    TSTEXP                            ;GET CHARACTER FROM LINE
        CMPA    ,X+                               ;IS THIS IT?
        BEQ     SYM2                              ;LOOKS LIKE IT
        ORA     #$80                              ;SET HIGH BIT
        CMPA    -1,X                              ;IS THIS IT?
        BEQ     SMATCH                            ;SKIP TO END
        LEAX    -1,X                              ;BACKUP TO START
        TST     ,X                                ;ARE WE AT END?
        BEQ     NOSY1                             ;IF SO, WE DIDNT FIND IT
SYM3
        LDA     ,X+                               ;GET VALUE
        BPL     SYM3                              ;SKIP TO NEXT
SYOFF
        LEAX    2,X                               ;SKIP TO NEXT LABLE
        LDY     ,S                                ;RESTORE REGISTER POINTER
        TST     ,X                                ;ARE WE AT END OF TABLE?
        BNE     SYM2                              ;TRY THIS ENTRY
NS
        LBSR    TSTEXP                            ;FIND TERMINATOR
        BNE     NS                                ;KEEP LOOKING
NOSY1
        LDA     #5                                ;'UNDEFINED SYMBOL'
        LBSR    SETERR                            ;INDICATE ERROR MESSAGE
        LDX     #$7FFF                            ;INSURE MAX. OFFSET
        LEAS    2,S                               ;CLEANUP SYACK
        RTS
SMATCH
        LBSR    TSTEXP                            ;GET TERMINATION CHARACTER
        BNE     SYOFF                             ;INDICATE SYMBOL NOT FOUND
        STX     TEMP                              ;SAVE SO WE CAN UPDATE
        LDX     ,X                                ;GET SYMBOL VALUE
        LEAS    2,S                               ;REMOVE Y REGISTER VALUE FROM STACK
        RTS     KEEP GOING
;*
;* PROCESS MEMORY OPERANDS AND DETERMINE REQUIRED POSTBYTE, OPERAND BYTES,
;* AND LENGTH OF OPERAND
;*
;* ON EXIT, ACC A = THE TYPE OF OPERAND: 0= IMMEDIATE VALUE
;*                                       1= DIRECT PAGE ADDRESSING
;*                                       2= POSTBYTE MEMORY REFERENCE
;*                                       3= EXTENDED ADDRESSING
;*
;* ACC B CONTAINS THE LENGTH (NUMBER OF BYTES) OF ALL OPERAND BYTES TO
;* THE INSTRUCTION
;*
;* THE SIXTEEN BIT MEMORY LOCATION 'VALUE' CONTAINS THE OFFSET OR ADDRESS
;* VALUE TO BE USED FOR INSTRUCTIONS REQUIRING DATA BYTES. FOR INSTRUCTIONS
;* REQUIRING ONLY AN EIGHT BIT OFFSET OR DATA BYTE, USE THE LOWER EIGHT BITS
;*
;* THE EIGHT BIT MEMORY LOCATION 'POST' CONTAINS THE POSTBYTE TO BE USED
;* FOR INSTRUCTIONS REQUIRING IT
;*
MEMOP
        LDA     ,Y+                               ;GET OPERAND TYPE
;* IMMEDIATE ADDRESSING
        CMPA    #'#'                              ;TEST FOR IMMEDIATE
        BNE     NOIMM                             ;NOT IMMEDIATE
        LBSR    EVAL                              ;EVALUATE OPERAND
        STD     VALUE                             ;SAVE FOR LATER
        LDD     #$0002                            ;LENGTH OF POSTBYTE
        RTS
;* EXTENDED ADDRESSING
NOIMM
        CMPA    #'>'                              ;EXTENDED ADDRESSING?
        BNE     NOEXT                             ;NOT EXTENDED
        LBSR    EVAL                              ;EVALUATE OPERAND
        STD     VALUE                             ;SAVE IT
        LDD     #$0302                            ;INDICATE THREE BYTE OPERAND, + TYPE 1
        RTS
;* DIRECT PAGE ADDRESSING
NOEXT
        CMPA    #'<'                              ;DIRECT PAGE ADDRESSING?
        BNE     NODIR                             ;NOT DIRECT PAGE ADDRESSING
        LBSR    EVAL                              ;EVALUATE OPERAND
        STD     VALUE                             ;SAVE VALUE
        LDD     #$0101                            ;INDICATE DIRECT PAGE LENGTH AND TYPE
        RTS
;* INDIRECT ADDRESSING
NODIR
        CMPA    #'['                              ;INDIRECT?
        BNE     NOTIND                            ;NOT INDIRECT
        DEC     INDFLG                            ;INDICATE WE ARE ON SECOND ITERATION
        BSR     EVLIND                            ;EVALUATE INDEXED OPERANDS
        CLR     INDFLG                            ;RESET FLAG
        PSHS    A                                 ;SAVE TYPE
        LDA     POST                              ;GET POSTBYTE
        ORA     #$10                              ;SET INDIRECT BIT
        STA     POST                              ;RESAVE POSTBYTE
        PULS    A,PC                              ;RESTORE TYPE AND RETURN
;* ACCUMULATOR OFFSET FROM REGISTER
NOTIND
        LEAY    -1,Y                              ;BACKUP TO OPERAND
EVLIND
        LDD     ,Y                                ;GET FIRST TWO CHARACTERS?
        CMPD    #$412C                            ;'A,' A ACCUMULATOR OFFSET?
        BEQ     ACCAOF                            ;YES?
        CMPD    #$422C                            ;'B,' B ACCUMULATOR OFFSET?
        BEQ     ACCBOF                            ;YES
        CMPD    #$442C                            ;'D,' D ACCUMULATOR OFFSET?
        LBNE    NOACC                             ;NOT AN ACCUMULATOR OFFSET
        LDA     #$8B                              ;POSTBYTE
        BRA     PRCACC                            ;PROCESS
ACCAOF
        LDA     #$86                              ;POSTBYTE OPERAND
        BRA     PRCACC                            ;PROCESS FOR ACCUMULATOR OFFSET
ACCBOF
        LDA     #$85                              ;POSTBYTE CODE
PRCACC
        STA     POST                              ;SAVE POSTBYTE
        LEAY    2,Y                               ;SKIP ACC AND COMMA
INSREG
        BSR     ADDREG                            ;ADD IN REGISTER BITS
        LDD     #$0201                            ;INDICATE TYPE AND LENGTH
        RTS
ADDREG
        LBSR    TSTERM                            ;GET CHARACTER FROM SOURCE
        CMPA    #'-'                              ;NOT AUTO DECREMENT
        BNE     NOAUT                             ;NO AUTO INC/DEC
        LDB     #$82                              ;AUTO DEC POSTBYTE
        LBSR    TSTERM                            ;TRY AGAIN
        CMPA    #'-'                              ;IS IT AUTO DEC?
        BNE     SETRGB                            ;NO, WE ARE OK
        LDB     #$83                              ;CHANGE OPCODE
        LBSR    TSTERM                            ;GET REGISTER BYTE
SETRGB
        STB     POST                              ;SET NEW POSTBYTE
NOAUT
        CLRB    INDICATE X REGISTER
        CMPA    #'X'                              ;IS IT X?
        BEQ     ADDOUT                            ;IF SO, WE ARE THERE
        INCB    INDICATE Y REGISTER
        CMPA    #'Y'                              ;ARE WE THERE?
        BEQ     ADDOUT                            ;IF SO, SKIP IT
        INCB    ADVANCE
        CMPA    #'U'                              ;USER STACK?
        BEQ     ADDOUT                            ;INDICATE WE ARE THERE
        INCB    ADVANCE
        CMPA    #'S'                              ;SYSTEM STACK POINTER?
        BNE     PCREL                             ;COULD BE PC RELATIVE
ADDOUT
        LDA     #32                               ;OFFSET FIVE BITS
        MUL     MOVE IT OVER
        ORB     POST                              ;ADD IN POSTBYTE BITS
        STB     POST                              ;RESAVE
        LBSR    TSTERM                            ;GET FOLLOWING CHARACTER
        CMPA    #'+'                              ;AUTOINC?
        BNE     NOAINC                            ;NO, TRY AUTODEC
        LDA     POST                              ;GET POST BYTE BACK
        ANDA    #$60                              ;REMOVE BITS WE JUST SET
        PSHS    A                                 ;SAVE BITS
        LDB     #$80                              ;INC BY ONE
        LBSR    TSTERM                            ;GET NEXT CHARACTER
        CMPA    #'+'                              ;TRY FOR AUTO TWICE
        BNE     SAVPOS                            ;SET BITS
        LDB     #$81                              ;NEW POSTBYTE
SAVPOS
        ORB     ,S+                               ;SET REGISTER BITS
        STB     POST                              ;SAVE NEW POSTBYTE
NOAINC
        RTS
;* TEST FOR PC RELATIVE OFFSETS
PCREL
        CMPA    #'P'                              ;TEST FOR 'PCR'
        BNE     REGERR                            ;NO, INDICATE ERROR
        LDD     VALUE                             ;GET VALUE
        SUBD    CURPC                             ;SUBTRACT CURRENT PROGRAM COUNTER
        SUBD    #3                                ;CONVERT TO OFFSET FOR EIGHT BIT
        PSHS    A                                 ;SAVE VALUE
        LDA     ITYPE                             ;GET INSTRUCTION TYPE
        CMPA    #4                                ;IS IT SPECIAL CASE
        BLO     CALOFF                            ;NO, ITS OK
        CMPA    #5                                ;HOW ABOUT OTHER SPECIAL CASE
        BHI     CALOFF                            ;NO, ITS ALSO OK
        LDA     ,S                                ;GET VALUE BACK
        SUBD    #1                                ;CONVERT TO EXTRA BYTE OF OFFSET
        STA     ,S                                ;RESAVE
CALOFF
        PULS    A                                 ;RESTORE VALUE
        TST     DEBUG                             ;IS THIS DEBUG MODE?
        BEQ     OFF16                             ;IF SO, USE 16 BIT OFFSET
        CMPD    #128                              ;TEST FOR 8 BIT OFFSET
        BLO     OFF8                              ;YES, USE EIGHT BIT OFFSET
        CMPD    #-128                             ;TEST FOR UNDER 8 BIT OFFSET
        BHS     OFF8                              ;YES, USE EIGHT BIT
OFF16
        SUBD    #1                                ;CONVERT FOR 16 BIT OFFSET
        STD     VALUE                             ;SET OFFSET VALUE
        LDA     #$8D                              ;POSTBYTE
        STA     POST                              ;SAVE POSTBYTE
        LEAS    2,S                               ;SKIP SAVE PROGRAM COUNTER
        LDD     #$0203                            ;THREE BYTES OF OPERAND
        RTS
OFF8
        STD     VALUE                             ;SET OFFSET VALUE
        LDA     #$8C                              ;POSTBYTE
        STA     POST                              ;SAVE POSTBYTE VALUE
        LEAS    2,S                               ;SKIP SAVED PROGRAM COUNTER
        LDD     #$0202                            ;TWO BYTES OF OPERANDS
        RTS
REGERR
        LDA     #4                                ;'INVALID REGISTER SPECIFICATION'
        LBRA    SETERR                            ;INDICATE AN ERROR
;* CONSTANT OFFSET FROM REGISTER
NOACC
        CMPA    #','                              ;NO OFFSET?
        BNE     OFFVAL                            ;NO, THERE IS AN OFFSET
        LDA     #$84                              ;POSTBYTE FOR NO OFFSET
        STA     POST                              ;SAVE
        LEAY    1,Y                               ;GET REGISTER VALUE
        LBRA    INSREG                            ;INSERT REGISTER VALUE
OFFVAL
        LBSR    EVAL                              ;EVALUATE OPERAND VALUE
        STD     VALUE                             ;SAVE VALUE FOR LATER
        LDA     -1,Y                              ;GET TERMINATING CHARACTER
        CMPA    #','                              ;ARE WE OFF REGISTER?
        BEQ     BIT5                              ;YES, USE REGISTER DISPLACEMENT
        LDA     #$8F                              ;GENERATE EXTENDED INDIRECT POSTBYTE
        STA     POST                              ;SET POSTBYTE
        TST     INDFLG                            ;ARE WE INDIRECT?
        BNE     BITEXT                            ;YES, SAVE EXTENDED POSTBYTE
;* NO REGISTER, AND NO INDIRECT... USE EXTENDED OR DP
        TST     DEBUG                             ;ARE WE IN DEBUG MODE?
        BEQ     USEXT                             ;IF SO, USE EXTENDED
        TST     CURDP                             ;IS DIRECT PAGE SET?
        BNE     USEXT                             ;NO, USE EXTENDED
        LDA     VALUE                             ;GET HIGH BYTE
        CMPA    CURDP+1                           ;IS ADDRESS IN DP SEGMENT?
        BNE     USEXT                             ;NO, USE EXTENDED
        LDD     #$0101                            ;INDICATE DIRECT PAGE ADDRESSING
        RTS
USEXT
        LDD     #$0302                            ;INDICATE EXTENDED ADDRESSING
        RTS
BIT5
        LDD     VALUE                             ;RESTORE VALUE
        TST     DEBUG                             ;ARE WE DEBUGGING?
        BEQ     BIT16                             ;IF SO, USE 16 BIT OFFSET
        TST     INDFLG                            ;ARE WE INDIRECT?
        BNE     BIT8                              ;IF SO, DONT USE 5 BIT INDEX
        CMPD    #16                               ;ARE WE OVER FIVE BITS
        BGE     BIT8                              ;YES, TRY EIGHTBIT
        CMPD    #-16                              ;ARE WE UNDER FIVE BITS?
        BLT     BIT8                              ;IF SO, TRY FOR EIGHT BIT OFFSET
        ANDB    #$1F                              ;GET FIVE BIT VALUE FOR POSTBYTE
        STB     POST                              ;SET UP POSTBYTE
        LBRA    INSREG
BIT8
        CMPD    #128                              ;ARE WE OVER 8 BITS?
        BGE     BIT16                             ;IF SO, GO WITH 16 BITS
        CMPD    #-128                             ;ARE WE UNDER 8 BITS
        BLT     BIT16                             ;IF SO, GO WITH 16 BITS
        LDA     #$88                              ;GET POSTBYTE FOR EIGHT BITS
        STA     POST                              ;SAVE IN MEMORY
        LBSR    ADDREG                            ;INSERT REGISTER VALUE
        LDD     #$0202                            ;INDICATE MEMORY REFERENCE
        RTS
BIT16
        LDA     #$89                              ;POSTBYTE FOR 16 BIT OFFSET
        STA     POST                              ;SAVE FOR LATER
        LBSR    ADDREG                            ;INSERT REGISTER BITS
BITEXT
        LDD     #$0203                            ;INDICATE TYPE AND LENGTH
        RTS     SAVE FOR LATER
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
        BRA     GETEN1                            ;AND CONTINUE
;* TEST FOR '-' NEGATE VALUE
GETV1
        CMPA    #'-'                              ;IS IT NEGATE?
        BNE     GETV2                             ;NO, ITS OK
        BSR     GETVAL                            ;EVALUATE NEXT
        CLRA
        CLRB
        SUBD    VAL1                              ;CALCULATE NEGATE
        BRA     GETEN1                            ;AND CONTINUE
;* TEST FOR '~' ONE'S COMPLEMENT
GETV2
        CMPA    #'~'                              ;COMPLEMENT?
        BNE     GETHEX                            ;NO, ITS OK
        BSR     GETVAL                            ;EVALUATE NEXT
        COMA    COMPLEMENT HIGH
        COMB    COMPLEMENT LOW
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
        BLO     GETH2                             ;IF SO, ITS OK
        CMPA    #$11                              ;< 'A'?
        BLT     BADHEX                            ;IF SO, ITS BAD
        SUBA    #7                                ;CONVERT TO HEX
        CMPA    #$10                              ;IS IT 0-F?
        BHS     BADHEX                            ;IF SO, ITS BAD
GETH2
        STA     TEMP                              ;SAVE FOR TEMPORARY VALUE
        LDD     #16                               ;MULTIPLY BY 16 (SHIFT FOUR BITS)
        SWI
        FCB     107                               ;D=D                          ;*X
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
        BHI     BADHEX                            ;IF INVALID, SAY SO
        PSHS    A                                 ;SAVE THIS VALUE
        TFR     X,D                               ;COPY TO ACCUMULATOR
        LEAX    D,X                               ;SHIFT BY ONE BIT
        PULS    B                                 ;RESTORE VALUE
        ABX     INSERT THIS BIT
        BRA     GETB1                             ;CONTINUE LOOKING
;* TEST FOR OCTAL NUMBER
GETOCT
        CMPA    #'@'                              ;IS IT OCTAL?
        BNE     GETCHR                            ;NO, TRY CHARACTER
GETO1
        LBSR    TSTEXP                            ;TEST FOR TERMINATOR
        LBEQ    GETEND                            ;IF END, CONTINUE
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #7                                ;IN RANGE?
        BHI     BADHEX                            ;INVALID
        STA     TEMP                              ;SAVE TEMP
        LDD     #8                                ;MUL BY 8
        SWI
        FCB     107                               ;DO MULTIPLY
        ORB     TEMP                              ;INCLUDE
        TFR     D,X                               ;COPY BACK
        BRA     GETO1                             ;CONTINUE
;* INVALID HEX DIGIT
BADHEX
        LDA     #6                                ;'INVALID OPERATOR IN EXPRESSION'
        LBSR    SETERR                            ;DISPLAY
;* END OF GETVAL, EXIT
GETEND
        TFR     X,D                               ;D = VALUE
        STD     VAL1                              ;SET VALUE
        PULS    X,PC                              ;RESTORE & RETURN
;* TEST FOR QUOTED STRING
GETCHR
        CMPA    #$27                              ;IS IT A QUOTE?
        BNE     GETDEC                            ;NO, TRY DECIMAL NUMBER
GETC1
        LDA     ,Y+                               ;GET CHAR
        CMPA    #$0D                              ;END OF LINE MEANS SCREWUP
        BEQ     BADSTR                            ;INVALID STRING
        CMPA    #$27                              ;CLOSING QUOTE
        BEQ     GETEND                            ;OF SO, THATS IT
        STA     TEMP                              ;SAVE CHAR
        TFR     X,D                               ;COPY TO ACCUMULATOR
        TFR     B,A                               ;SHIFT UP
        LDB     TEMP                              ;INCLUDE LOWER CHAR
        TFR     D,X                               ;REPLACE OLD VALUE
        BRA     GETC1                             ;GET NEXT CHARACTER
;* STRING OPERAND WAS INVALID
BADSTR
        LEAY    -1,Y                              ;BACKUP
        LDA     #8                                ;'IMPROPERLY DELIMITED STRING'
        LBSR    SETERR                            ;SET ERROR MESSAGE
        BRA     GETEND                            ;CONTINUE
;* TEST FOR DECIMAL NUMBER
GETDEC
        CMPA    #'0'                              ;IS IT < '0'?
        BLO     GETPC                             ;NO, ITS NOT DECIMAL
        CMPA    #'9'                              ;IS IT > '9'
        BHI     GETPC                             ;NO, NOT DECIMAL
        LEAY    -1,Y                              ;BACKUP TO START OF LINE
GETD1
        LBSR    TSTEXP                            ;TEST FOR END OF DIGIT STRING
        BEQ     GETEND                            ;IF SO, QUIT
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #9                                ;ARE WE DECIMAL?
        BHI     BADHEX                            ;IF NOT, GET UPSET
        STA     TEMP                              ;SAVE DIGIT
        LDD     #10                               ;MULTIPLY BY 10
        SWI
        FCB     107                               ;D=D                          ;*X
        ADDB    TEMP                              ;ADD IN DIGIT
        ADCA    #0                                ;INSURE HIGH INCS
        TFR     D,X                               ;SAVE IN X FOR NEXT ITERATION
        BRA     GETD1                             ;KEEP GOING
;* TEST FOR CURRENT PROGRAM COUNTER
GETPC
        CMPA    #'*'                              ;CURRENT PROGRAM COUNTER?
        BNE     GETSYM                            ;NOT THE CURRENT PROGRAM COUNTER
        LDX     CURPC                             ;GET CURRENT PROGRAM COUNTER
        BRA     GETEND                            ;CONTINUE
;* LOOK UP SYMBOL IN SYMBOL TABLE
GETSYM
        LEAY    -1,Y                              ;BACKUP TO SYMBOL
        LBSR    LOCSYM                            ;LOOK UP SYMBOL VALUE
        BRA     GETEND
;*
;* EVALUATE ANY OPERANDS
;*
EVAL
        PSHS    X                                 ;SAVE 'X'
        LBSR    GETVAL                            ;GET VALUE
EVAL1
        TFR     D,X                               ;SAVE OLD VALUE
EVAL2
        LBSR    TSTERM                            ;GET TERMINATOR
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
        BNE     EVAERR                            ;NO, ERROR
        LBSR    GETVAL                            ;EVALUATE OPERANDS
        TFR     X,D                               ;GET OLD VALUE
        EORA    VAL1                              ;XOR WITH OLD
        EORB    VAL1+1                            ;XOR SECOND BYTE
        BRA     EVAL1                             ;CONTINUE
EVAERR
        LDA     #6                                ;'INVALID OPERATOR IN EXPRESSION'
        LBSR    SETERR                            ;SET ERROR FLAG
        LDD     #0                                ;ZERO VALUE
        BRA     EVEXIT                            ;END EXIT
;*
;* TEST FOR VALID EXPRESSION ELEMENT TERMINATOR
;*
TSTEXP
        LDA     ,Y                                ;GET CHARACTER
        CMPA    #'+'                              ;PLUS SIGN
        BEQ     TSTEND                            ;OK
        CMPA    #'-'                              ;MINUS SIGN
        BEQ     TSTEND                            ;IS ALSO OK
        CMPA    #'&'                              ;LOCAIAL AND?
        BEQ     TSTEND                            ;IF SO, ITS OK
        CMPA    #'|'                              ;LOGICAL OR?
        BEQ     TSTEND                            ;IF SO, ITS OK
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
        CMPA    #','                              ;SO IS COMMA
        BEQ     TSTEND                            ;INDICATE SO
        CMPA    #']'                              ;AND CLOSING BRACE
        BEQ     TSTEND                            ;INDICATE SO
        CMPA    #$0D                              ;CARRIAGE RETURN IS LAST
        BEQ     TSTEND                            ;IF NOT, SAY SO
        LEAY    1,Y                               ;DONT SKIP END OF LINE
TSTEND
        RTS
;* GET CHARACTER (Y) AND ADVANCE Y IF NOT A CR, SET 'Z' IF TERMINATOR
TSTERM
        LDA     ,Y+                               ;GET CHARACTER
        CMPA    #' '                              ;SPACE?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #','                              ;COMMA?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #']'                              ;CLOSEING BRACE?
        BEQ     TSTEND                            ;YES, ITS OK
        CMPA    #$0D                              ;CARRIAGE RETURN
        BNE     TSTEND                            ;NO, ITS OK
        LEAY    -1,Y                              ;BACKUP
        ORCC    #%00000100	SET 'Z' FLAG
        RTS
;* INDICATE AN ERROR HAS OCCURED
SETERR
        TST     EMSG                              ;ALREADY OCCURED?
        BNE     NOSET                             ;DONT SET IF ALREADY IN
        STA     EMSG                              ;SET ERROR FLAG
NOSET
        RTS
;*
;* DISPLAY ERROR MESSAGE
;*
DSPERR
        PSHS    A,B,X                             ;SAVE X REGISTER
        LDA     EMSG                              ;GETERROR MESSAGE
        BEQ     NOERR                             ;NOT AN ERROR
        DEC     PAGLIN                            ;REDUCE LINES/PAGE
        LDX     #EMSG1                            ;POINT TO FIRST MESSAGE
        BSR     WRIMSG                            ;OUTPUT MESSAGE
        LDB     EMSG                              ;GET ERROR NUMBER BACK
        CLRA    ZERO HIGH BYTE
        LBSR    WRIDEC                            ;OUTPUT NUMBER IN DECIMAL
        LDD     ERRORS                            ;GET TOTAL ERRORS
        ADDD    #1                                ;ADVANCE TO NEXT
        STD     ERRORS                            ;SAVE BACK
        LDX     #EMSG2                            ;SECOND PART
        BSR     WRIMSG                            ;OUTPUT MESSAGE
        LDB     EMSG                              ;GET MESSAGE NUMBER BACK
        LDX     #ERRMSG                           ;POINT TO ERROR MESSAGE TABLE
LKMSG
        LDA     ,X+                               ;GET CHARACTER FROM MESSAGE
        BNE     LKMSG                             ;KEEP GOING TILL WE FIND END OF MESSAGE
        DECB    REDUCE COUNT
        BNE     LKMSG                             ;OUTPUT
        BSR     WRIMSG                            ;OUTPUT
        LDA     #$0D                              ;GET CARRIAGE RETURN
        BSR     WRICHR                            ;OUTPUT
        CLR     EMSG                              ;CLEAR ERROR MESSAGE FLAG
NOERR
        PULS    A,B,X,PC	RESTORE REGISTERS
;*
;* DISPLAY A SPACE ON OUTPUT FILE
;*
SPACE
        PSHS    A                                 ;SAVE ACCUMULTOR
        LDA     #' '                              ;GET SPACE
        BSR     WRICHR                            ;OUTPUT
        PULS    A,PC                              ;RESTORE AND RETURN
;*
;* DISPLAY MESSAGE UP TO A ZERO
;*
WRIMSG
        LDA     ,X+                               ;GET CHARACTER FROM MESSAGE
        BEQ     ENDMSG                            ;IF SO, QUIT
        BSR     WRICHR                            ;OUTPUT
        BRA     WRIMSG                            ;KEEP GOING
ENDMSG
        RTS
;*
;* DISPLAY NUMBER IN ACCA IN HEX
;*
WRIBYT
        PSHS    A                                 ;SAVE CURRENT VALUE
        LSRA    NIBBLE INTO LOW
        LSRA    SO WE
        LSRA    CAN CONVERT TO
        LSRA    ASCII HEX
        BSR     OUTASC                            ;OUTPUT
        PULS    A                                 ;RESTORE A VALUE
OUTASC
        ANDA    #$0F                              ;REMOVE ANY GARBAGE
        ADDA    #$30                              ;CONVERT TO ASCII
        CMPA    #$39                              ;IS IT MORE?
        BLS     WRICHR                            ;IF NOT, WRITE OUT CHARACTER
        ADDA    #$7                               ;CONVERT TO ASCII
;*
;* WRITE A CHARACTER TO THE OUTPUT FILE
;*
WRICHR
        PSHS    A,U                               ;SAVE REGISTERS
        TST     ERR                               ;ARE WE OUTPUTING ERROR MSGS ONLY?
        BNE     NOROUT                            ;NORMAL OUTPUT
        TST     EMSG                              ;HAS THERE BEEN AN ERROR?
        BEQ     STLST                             ;IF NOT, QUIT
NOROUT
        TST     TERM                              ;IS IT TERMINAL OUTPUT
        BNE     LSTOUT                            ;NO, OUTPUT TO LISTING
        SWI
        FCB     33                                ;OUTPUT TO TERMINAL
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BNE     STLST                             ;OUTPUT
        LDA     #$0A                              ;GET LINE FEED
        SWI
        FCB     33                                ;OUTPUT
STLST
        PULS    A,U,PC                            ;RESTORE REGISTERS
LSTOUT
        LDU     #LSTFIL
        SWI
        FCB     61                                ;WRITE CHAR
        LBNE    ABORT                             ;ERROR
        PULS    A,U,PC                            ;RESTORE X AND PC
;*
;* WRITE DECIMAL VALUE OF D TO OUTPUT FILE
;*
WRIDEC
        PSHS    A,B,X,Y                           ;SAVE X-Y REGISTERS
        LDY     #0                                ;START WITH ZERO CHARACTERS
        TFR     D,X                               ;SET UP STARTING VALUE
WRDE1
        LDD     #10                               ;DIVIDE BY 10
        SWI
        FCB     108                               ;X=X/D, D=REMAINDER
        PSHS    B                                 ;SAVE REMAINDER
        LEAY    1,Y                               ;INDICATE ANOTHER ON STACK
        CMPX    #0                                ;ANY MORE?
        BNE     WRDE1                             ;NO, CONTINUE
WRDE2
        PULS    A                                 ;GET DIGIT BACK
        ADDA    #'0'                              ;CONVERT TO PRINTABLE FORM
        LBSR    WRICHR                            ;DISPLAY DECIMAL DIGIT
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     WRDE2                             ;IF NOT END, CONTINUE DISPLAYING
        PULS    A,B,X,Y,PC	RESTORE INDEX REGS
;*
;* READS A CHARACTER FROM THE INPUT FILE
;*
RDINP
        PSHS    U                                 ;SAVE REGISTERS
        LDU     #INFIL
        SWI
        FCB     59                                ;READ CHAR
        PULS    U,PC                              ;GO HOME
;*
;* WRITES A BYTE TO THE OBJECT FILE
;*
WRIOBB
        CMPA    #$CF                              ;SPECIAL CASE?
        BNE     WRIOBJ                            ;NO, OUTPUT IT
        BSR     WRIOBJ                            ;IF SPECIAL CASE, WRITE IT TWICE
;*
;* WRITE A CHARACTER TO THE OBJECT FILE
;*
WRIOBJ
        PSHS    A,U                               ;SAVE REGISTERS
        LDU     #OBJFIL
        SWI
        FCB     61                                ;WRITE CHAR
        LBNE    ABORT                             ;ERROR
        PULS    A,U,PC                            ;RESTORE X AND PC
;*
;* DISPLAY TITLE IF NESSARY
;*
DSPTTL
        DEC     PAGLIN                            ;ARE WE BELOW?
        BPL     NTTL                              ;DONT DISPLAY TITLE
        LDA     #55                               ;LINES/PAGE
        STA     PAGLIN                            ;SO WE WONT FORGET
        LDX     #PAGM1                            ;POINT TO FIRST MESSAGE
        LBSR    WRIMSG                            ;OUTPUT TO FILE
        LDX     #TITLE                            ;POINT TO TITLE SPACE
        LDB     #60                               ;NUMBER OF SPACES REMAINING
WRTTL
        LDA     ,X+                               ;GET CHARACTER FROM LINE
        CMPA    #$0D                              ;END OF TITLE?
        BEQ     ENTTL                             ;IF SO, QUIT
        LBSR    WRICHR                            ;OUTPUT
        DECB    REDUCE COUNT
        BNE     WRTTL                             ;KEEP DISPLAYING
ENTTL
        LBSR    SPACE                             ;DISPLAY A SPACE
        DECB    REDUCE COUNT
        BPL     ENTTL                             ;AND KEEP DISPLAYING
        LDX     #PAGM2                            ;NEXT MESSAGE
        LBSR    WRIMSG                            ;OUTPUT
        LDD     PAGE                              ;GET CURRENT PAGE NUMBER
        ADDD    #1                                ;ADD ONE
        STD     PAGE                              ;RESAVE
        LBSR    WRIDEC                            ;OUTPUT
        LDA     #$0D                              ;NEW LINE
        LBSR    WRICHR                            ;OUTPUT
        LBSR    WRICHR                            ;AND A BLANK LINE
NTTL
        RTS
;* INFORMATIONAL MESSAGES
EMSG1
        FCC     ' *ERROR* #'
        FCB     00
DUPSYM
        FCC     '0 - DUPLICATE SYMBOL: '
        FCB     00
EMSG2
        FCC     ' - '
        FCB     00
ERRSUM
        FCC     'TOTAL ERRORS: '
        FCB     00
SYMMSG
        FCC     'SYMBOL TABLE:'
        FCB     $0D,0
PAGM1
        FCB     $0C                               ;FORM FEED CHARACTER
        FCC     '6809 ASSEMBLER : '
        FCB     00
PAGM2
        FCC     'PAGE: '
        FCB     00
;* ERROR MESSAGES
ERRMSG
        FCB     0                                 ;DUMMY BYTE TO START OFF SEARCH
        FCC     'Unknown opcode or directive'
        FCB     00
        FCC     'Address out of range'
        FCB     00
        FCC     'Invalid addressing mode'
        FCB     00
        FCC     'Invalid register specification'
        FCB     00
        FCC     'Undefined symbol'
        FCB     00
        FCC     'Invalid expression syntax'
        FCB     00
        FCC     'Invalid argument format'
        FCB     00
        FCC     'Improperly delimited string'
        FCB     00
;*
;* 6809 INSTRUCTIONS
;*
INSTAB
        FCC     'LBSR'
        FCB     $88,$17,$CF,$CF,$CF
        FCC     'LDA'
        FCB     $82,$86,$96,$A6,$B6
        FCC     'CMPA'
        FCB     $82,$81,$91,$A1,$B1
        FCC     'BNE'
        FCB     $86,$26,$CF,$CF,$CF
        FCC     'BEQ'
        FCB     $86,$27,$CF,$CF,$CF
        FCC     'BRA'
        FCB     $86,$20,$CF,$CF,$CF
        FCC     'LDX'
        FCB     $83,$8E,$9E,$AE,$BE
        FCC     'LDB'
        FCB     $82,$C6,$D6,$E6,$F6
        FCC     'LDD'
        FCB     $83,$CC,$DC,$EC,$FC
        FCC     'STA'
        FCB     $82,$CF,$97,$A7,$B7
        FCC     'STB'
        FCB     $82,$CF,$D7,$E7,$F7
        FCC     'STD'
        FCB     $83,$CF,$DD,$ED,$FD
        FCC     'STX'
        FCB     $83,$CF,$9F,$AF,$BF
        FCC     'DECA'
        FCB     $81,$4A,0,0,0
        FCC     'DECB'
        FCB     $81,$5A,0,0,0
        FCC     'INCA'
        FCB     $81,$4C,0,0,0
        FCC     'INCB'
        FCB     $81,$5C,0,0,0
        FCC     'LDY'
        FCB     $84,$8E,$9E,$AE,$BE
        FCC     'LBRA'
        FCB     $88,$16,$CF,$CF,$CF
        FCC     'PULS'
        FCB     $89,$35,$CF,$CF,$CF
        FCC     'PULU'
        FCB     $89,$37,$CF,$CF,$CF
        FCC     'PSHS'
        FCB     $89,$34,$CF,$CF,$CF
        FCC     'PSHU'
        FCB     $89,$36,$CF,$CF,$CF
        FCC     'RTS'
        FCB     $81,$39,0,0,0
        FCC     'TFR'
        FCB     $8A,$1F,$CF,$CF,$CF
        FCC     'SSR'
        FCB     $92,$3F,0,0,0
        FCC     'FCB'
        FCB     $8E,0,0,0,0
        FCC     'FDB'
        FCB     $8F,0,0,0,0
        FCC     'FCC'
        FCB     $90,0,0,0,0
        FCC     'FCCZ'
        FCB     $91,0,0,0,0
        FCC     'ASLA'
        FCB     $81,$48,0,0,0
        FCC     'ASLB'
        FCB     $81,$58,0,0,0
        FCC     'ASRA'
        FCB     $81,$47,0,0,0
        FCC     'ASRB'
        FCB     $81,$57,0,0,0
        FCC     'CLRA'
        FCB     $81,$4F,0,0,0
        FCC     'CLRB'
        FCB     $81,$5F,0,0,0
        FCC     'COMA'
        FCB     $81,$43,0,0,0
        FCC     'COMB'
        FCB     $81,$53,0,0,0
        FCC     'DAA'
        FCB     $81,$19,0,0,0
        FCC     'LSLA'
        FCB     $81,$48,0,0,0
        FCC     'LSLB'
        FCB     $81,$58,0,0,0
        FCC     'LSRA'
        FCB     $81,$44,0,0,0
        FCC     'LSRB'
        FCB     $81,$54,0,0,0
        FCC     'MUL'
        FCB     $81,$3D,0,0,0
        FCC     'NEGA'
        FCB     $81,$40,0,0,0
        FCC     'NEGB'
        FCB     $81,$50,0,0,0
        FCC     'ROLA'
        FCB     $81,$49,0,0,0
        FCC     'ROLB'
        FCB     $81,$59,0,0,0
        FCC     'RORA'
        FCB     $81,$46,0,0,0
        FCC     'RORB'
        FCB     $81,$56,0,0,0
        FCC     'RTI'
        FCB     $81,$3B,0,0,0
        FCC     'SEX'
        FCB     $81,$1D,0,0,0
        FCC     'SWI'
        FCB     $81,$3F,0,0,0
        FCC     'SWI2'
        FCB     $81,$10,$3F,0,0
        FCC     'SWI3'
        FCB     $81,$11,$3F,0,0
        FCC     'SYNC'
        FCB     $81,$13,0,0,0
        FCC     'TSTA'
        FCB     $81,$4D,0,0,0
        FCC     'TSTB'
        FCB     $81,$5D,0,0,0
        FCC     'ADCA'
        FCB     $82,$89,$99,$A9,$B9
        FCC     'ADCB'
        FCB     $82,$C9,$D9,$E9,$F9
        FCC     'ADDA'
        FCB     $82,$8B,$9B,$AB,$BB
        FCC     'ADDB'
        FCB     $82,$CB,$DB,$EB,$FB
        FCC     'ADDD'
        FCB     $83,$C3,$D3,$E3,$F3
        FCC     'ANDA'
        FCB     $82,$84,$94,$A4,$B4
        FCC     'ANDB'
        FCB     $82,$C4,$D4,$E4,$F4
        FCC     'ANDCC'
        FCB     $82,$1C,$CF,$CF,$CF
        FCC     'ASL'
        FCB     $82,$CF,$08,$68,$78
        FCC     'ASR'
        FCB     $82,$CF,$07,$67,$77
        FCC     'BITA'
        FCB     $82,$85,$95,$A5,$B5
        FCC     'BITB'
        FCB     $82,$C5,$D5,$E5,$F5
        FCC     'CLR'
        FCB     $82,$CF,$0F,$6F,$7F
        FCC     'CMPB'
        FCB     $82,$C1,$D1,$E1,$F1
        FCC     'CMPX'
        FCB     $83,$8C,$9C,$AC,$BC
        FCC     'COM'
        FCB     $82,$CF,$03,$63,$73
        FCC     'CWAI'
        FCB     $82,$3C,$CF,$CF,$CF
        FCC     'DEC'
        FCB     $82,$CF,$0A,$6A,$7A
        FCC     'EORA'
        FCB     $82,$88,$98,$A8,$B8
        FCC     'EORB'
        FCB     $82,$C8,$D8,$E8,$F8
        FCC     'INC'
        FCB     $82,$CF,$0C,$6C,$7C
        FCC     'JMP'
        FCB     $83,$CF,$0E,$6E,$7E
        FCC     'JSR'
        FCB     $83,$CF,$9D,$AD,$BD
        FCC     'LDU'
        FCB     $83,$CE,$DE,$EE,$FE
        FCC     'LEAS'
        FCB     $82,$CF,$CF,$32,$CF
        FCC     'LEAU'
        FCB     $82,$CF,$CF,$33,$CF
        FCC     'LEAX'
        FCB     $82,$CF,$CF,$30,$CF
        FCC     'LEAY'
        FCB     $82,$CF,$CF,$31,$CF
        FCC     'LSL'
        FCB     $82,$CF,$08,$68,$78
        FCC     'LSR'
        FCB     $82,$CF,$04,$64,$74
        FCC     'NEG'
        FCB     $82,$CF,$00,$60,$70
        FCC     'ORA'
        FCB     $82,$8A,$9A,$AA,$BA
        FCC     'ORB'
        FCB     $82,$CA,$DA,$EA,$FA
        FCC     'ORCC'
        FCB     $82,$1A,$CF,$CF,$CF
        FCC     'ROL'
        FCB     $82,$CF,$09,$69,$79
        FCC     'ROR'
        FCB     $82,$CF,$06,$66,$76
        FCC     'SBCA'
        FCB     $82,$82,$92,$A2,$B2
        FCC     'SBCB'
        FCB     $82,$C2,$D2,$E2,$F2
        FCC     'STU'
        FCB     $83,$CF,$DF,$EF,$FF
        FCC     'SUBA'
        FCB     $82,$80,$90,$A0,$B0
        FCC     'SUBB'
        FCB     $82,$C0,$D0,$E0,$F0
        FCC     'SUBD'
        FCB     $83,$83,$93,$A3,$B3
        FCC     'TST'
        FCB     $82,$CF,$0D,$6D,$7D
        FCC     'CMPD'
        FCB     $84,$83,$93,$A3,$B3
        FCC     'CMPY'
        FCB     $84,$8C,$9C,$AC,$BC
        FCC     'CMPS'
        FCB     $85,$8C,$9C,$AC,$BC
        FCC     'CMPU'
        FCB     $85,$83,$93,$A3,$B3
        FCC     'LDS'
        FCB     $84,$CE,$DE,$EE,$FE
        FCC     'STS'
        FCB     $84,$CF,$DF,$EF,$FF
        FCC     'STY'
        FCB     $84,$CF,$9F,$AF,$BF
        FCC     'BRN'
        FCB     $86,$21,$CF,$CF,$CF
        FCC     'BHI'
        FCB     $86,$22,$CF,$CF,$CF
        FCC     'BLS'
        FCB     $86,$23,$CF,$CF,$CF
        FCC     'BHS'
        FCB     $86,$24,$CF,$CF,$CF
        FCC     'BCC'
        FCB     $86,$24,$CF,$CF,$CF
        FCC     'BLO'
        FCB     $86,$25,$CF,$CF,$CF
        FCC     'BCS'
        FCB     $86,$25,$CF,$CF,$CF
        FCC     'BVC'
        FCB     $86,$28,$CF,$CF,$CF
        FCC     'BVS'
        FCB     $86,$29,$CF,$CF,$CF
        FCC     'BPL'
        FCB     $86,$2A,$CF,$CF,$CF
        FCC     'BMI'
        FCB     $86,$2B,$CF,$CF,$CF
        FCC     'BGE'
        FCB     $86,$2C,$CF,$CF,$CF
        FCC     'BLT'
        FCB     $86,$2D,$CF,$CF,$CF
        FCC     'BGT'
        FCB     $86,$2E,$CF,$CF,$CF
        FCC     'BLE'
        FCB     $86,$2F,$CF,$CF,$CF
        FCC     'BSR'
        FCB     $86,$8D,$CF,$CF,$CF
        FCC     'LBRN'
        FCB     $87,$10,$21,$CF,$CF
        FCC     'LBHI'
        FCB     $87,$10,$22,$CF,$CF
        FCC     'LBLS'
        FCB     $87,$10,$23,$CF,$CF
        FCC     'LBHS'
        FCB     $87,$10,$24,$CF,$CF
        FCC     'LBCC'
        FCB     $87,$10,$24,$CF,$CF
        FCC     'LBLO'
        FCB     $87,$10,$25,$CF,$CF
        FCC     'LBCS'
        FCB     $87,$10,$25,$CF,$CF
        FCC     'LBNE'
        FCB     $87,$10,$26,$CF,$CF
        FCC     'LBEQ'
        FCB     $87,$10,$27,$CF,$CF
        FCC     'LBVC'
        FCB     $87,$10,$28,$CF,$CF
        FCC     'LBVS'
        FCB     $87,$10,$29,$CF,$CF
        FCC     'LBPL'
        FCB     $87,$10,$2A,$CF,$CF
        FCC     'LBMI'
        FCB     $87,$10,$2B,$CF,$CF
        FCC     'LBGE'
        FCB     $87,$10,$2C,$CF,$CF
        FCC     'LBLT'
        FCB     $87,$10,$2D,$CF,$CF
        FCC     'LBGT'
        FCB     $87,$10,$2E,$CF,$CF
        FCC     'LBLE'
        FCB     $87,$10,$2F,$CF,$CF
        FCC     'EXG'
        FCB     $8A,$1E,$CF,$CF,$CF
        FCC     'EQU'
        FCB     $8B,0,0,0,0
        FCC     'ORG'
        FCB     $8C,0,0,0,0
        FCC     'RMB'
        FCB     $8D,0,0,0,0
        FCC     'SETDP'
        FCB     $93,0,0,0,0
        FCC     'ABX'
        FCB     $81,$3A,0,0,0
        FCC     'NOP'
        FCB     $81,$12,0,0,0
        FCC     'PAGE'
        FCB     $94,0,0,0,0
        FCC     'TITLE'
        FCB     $95,0,0,0,0
        FCB     0                                 ;END OF TABLE
;*
;* QUALIFIER TABLE
;*
QTABLE
        FCB     $82
        FCC     '/TERM'
        FCB     $82
        FCC     '/FAST'
        FCB     $82
        FCC     '/ERROR'
        FCB     $82
        FCC     '/SYMBOL'
        FCB     $82
        FCC     '/QUIET'
        FCB     $80
QMAX            EQU 5                             ;NUMBER OF QUALIFIERS
;* QUALIFIER FLAG TABLE
TERM
        FCB     $FF                               ;FLAG FOR NO LISTING
DEBUG
        FCB     $FF                               ;DEBUGGING FLAG
ERR
        FCB     $FF                               ;ERROR ONLY OUTPUT FLAG
SYM
        FCB     $FF                               ;SYMBOL TABLE OUTPUT
QUIET
        FCB     $FF
