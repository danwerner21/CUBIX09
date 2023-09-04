;        TITLE   MICRO APL 1.0
;*
;* MICRO-APL 1.0
;*
;* Simple APL SUBSET for the 6809, using the standard ASCII
;* character set. Lower case characters are used instead of
;* special APL characters to represent some of the primitive
;* functions. The function of the "SHIFT" key is reversed to
;* allow easier operation (SHIFT = special functions)
;*
;* SYSTEM COMMANDS:
;*
;*  )OFF, )LIB, )SI, )REL, )RESET, )LOAD, )SAVE, )WSID, )DROP,
;*  )CLEAR, )SYS, )VARS, )FNS, )LBLS, )STAT
;*
;* MONADIC (SINGLE OPERAND) OPERATORS:
;*
;*  i - INDEX VECTOR GENERATION        ; p - SHAPE OF OPERAND
;*  r - REVERSE OPERAND        ;	 c - CLASSIFICATION
;*  e - EXECUTE STRING OPERAND        ; s - CONVERT TO STRING
;*  ? - ROLL RANDOM VECTOR        ; ^ - SORT VECTOR
;*  b - BRANCH TO LABEL
;*
;* DYADIC (TWO OPERAND) OPERATORS:
;*
;*  + - ADDITION        ;        ; - - SUBTRACTION
;*  x - MULTIPLICATION        ;	 % - DIVISION
;*  m - MODULUS        ;        ; & - LOGICAL AND
;*  ! - LOGICAL OR        ;	 | - EXCLUSIVE OR
;*  g - GREATEST        ;        ; l - LEAST
;* == - TEST FOR EQUALITY        ;-= - TEST FOR INEQUALITY
;*  > - TEST FOR GREATER THAN        ; < - TEST FOR LESS THAN
;* >= - TEST FOR GREATOR OR EQUAL	<= - TEST FOR LESS OR EQUAL
;*  = - ASSIGNMENT        ;	 / - EXTRACTION
;*  ; - JOIN        ;        ; t - TAKE
;*  d - DROP        ;        ; f - FIND
;*  | - EXCLUSIVE OR        ;	 u - UNION OF SETS
;*  n - TRANSLATE
;*
;* OTHER OPERATORS:
;*
;* [] - INDEX ACCESS        ;	() - NEST
;*  \ - TRAVEL        ;        ; $ - FUNCTION DEFINITION
;*
;* SYSTEM VARIABLES:
;*
;*  B$ - BUFFER SIZE        ;	C$ - CHARACTER VECTOR
;*  F$ - FORMATTED I/O        ;	K$ - READ KEYSTROKE
;*  L$ - LINE NUMBER        ;	O$ - ORIGIN VALUE
;*  P$ - PARAMETER        ;	R$ - REMAINDER
;*  S$ - RANDOM SEED        ;	T$ - TERMINAL I/O
;*  W$ - AVAILABEL WORKSPACE
;*
;* Copyright 1984-2005 Dave Dunfield
;* All rights reserved.
;*
;* DATA AREAS
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
ROM             = OSRAM                           ;PROGRAMM GOES HERE
RAM             = OSRAM+7168	DATA GOES HERE
HIRAM           = OSUTIL-1024	TOP OF RAM
;*
LEVEL           = RAM+130
EXEC            = LEVEL+1
TEMP            = EXEC+1
TEMP0           = TEMP+2
TEMP1           = TEMP0+2
TEMP2           = TEMP1+2
TEMP3           = TEMP2+2
TEMP4           = TEMP3+2
TEMP5           = TEMP4+2
TXTTMP          = TEMP5+2
PARM            = TXTTMP+2
LINCT           = PARM+2
GOTO            = LINCT+2
NAMPTR          = GOTO+2
DIVREM          = NAMPTR+2
TXTPTR          = DIVREM+2
SAVSTK          = TXTPTR+2
RAMTOP          = SAVSTK+2
ASSFLG          = RAMTOP+2
ERRFLG          = ASSFLG+1
INPSTK          = ERRFLG+1
ID              = INPSTK+2
STACK           = RAM+1024
;* WORKSPACE CONTENTS
FREE            = RAM+1024
ORIGIN          = FREE+2
SEED            = ORIGIN+2
BUFSIZ          = SEED+2
FREMEM          = BUFSIZ+2
SYMTAB          = FREMEM+2
;*
        ORG     ROM
;* PROGRAM ENTRY
APL
        LBSR    SYSMSG
        FCN     'MAPL version 1.0'
        CLRA                                      ;	INDICATE ERR MSGS
        SWI
        FCB     105                               ;TURN OFF ERROR MESSAGES
        LDY     #CONTIN                           ;POINT TO CONTINUE NAME
        SWI
        FCB     10                                ;GET NAME
        LEAY    8,X                               ;POINT TO IT
        SWI
        FCB     68                                ;DOES IT EXIST?
        LBEQ    LDGO                              ;IF SO, LOAD IT
        BRA     DEFCLR                            ;DEFAULT CLEAR
;* ')CLEAR' COMMAND
CLEAR
        LBSR    SKIP                              ;LOOK FOR PARAMETER
        BEQ     DEFCLR                            ;ASSUME DEFAULT
CLER1
        LDA     ,Y+                               ;GET CHAR
        CMPA    #$0D                              ;CONTINUE
        BNE     CLER1                             ;TO END OF LINE
        LEAY    -1,Y                              ;BACKUP TO CR
        LBSR    SKBK                              ;BACKUP TO NUMBER
        LBSR    VALNUM                            ;VALID DIGIT?
        LBNE    UNCMD                             ;INVALID
        LBSR    GETDEC                            ;GET DECIMAL
        BRA     CLRGO                             ;CONTINUE
DEFCLR
        LDD     #1000                             ;DEFAULT SYMBOL TABLE SIZE
CLRGO
        ADDD    #SYMTAB+1	OFFSET FOR SYMBOL TABLE ADDRESS
        STD     FREMEM                            ;POINT TO FREE MEMORY
        STD     >FREE                             ;INDICATE HOW MUCH IS FREE
        CLR     >SYMTAB                           ;REMOVE SYMBOLS
        LDD     #1024                             ;DEFAULT BUFFER SIZE
        STD     BUFSIZ                            ;SAVE BUFFER SIZE
        LDY     #CID                              ;POINT TO NEW ID
        LBSR    WSISET                            ;SET UP WSID
        LDD     #1                                ;GET A 1 ORIGIN
        STD     ORIGIN                            ;SAVE ORIGIN VALUE
        COMA                                      ;	GARBAGE VALUE
        STD     SEED                              ;SET UP SEED
CLMSG
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
CID
        FCN     'CLEAR WS'
        LDS     #STACK                            ;POINT TO SYSTEM STACK
        STS     SAVSTK                            ;INTIALIZE IT
;* ')RESET' SYSTEM COMMAND
RESET
        LBSR    DOREST                            ;DO A RESET
;* COMMAND INTERPRETER
CMD
        BSR     INIWS                             ;INIT WORKSPACE PARMS
        LDS     SAVSTK                            ;SET UP STACK
        LBSR    DSPSTR                            ;DISPLAY MESSAGE
        FCN     '      '	SPACE OVER
        LBSR    GETRAM                            ;GET A LINE OF INPUT
        LBSR    SKIP                              ;SKIP TO COMMAND
        BEQ     CMD                               ;IF NONE, TRY AGAIN
        CMPA    #'*'                             ;COMMENT?
        BEQ     CMD                               ;IF SO, GO FOR IT
        CMPA    #')'                              ;SYSTEM COMMAND?
        LBNE    EDIT                              ;NO, PROCESS EXPRESSION
        LDX     #CMDTAB                           ;POINT TO COMMAND TABLE
        LBSR    CLOOK                             ;LOOK UP AND EXECUTE COMMAND
        BRA     CMD                               ;GET NEXT
INIWS
        CLR     EXEC                              ;INSURE NOTHING RUNNING
        LDD     #0
        STD     INPSTK                            ;SAVE INPUT STACK POINTER
        LDD     RAMTOP                            ;GET TOP OF RAM
        STD     TEMP5                             ;SAVE FREE MEMORY INDICATOR
        RTS
;* ')LOAD' COMMAND
LOAD
        LBSR    FILNAM                            ;GET FILENAME
        SWI
        FCB     10                                ;TELL DOS
        LBNE    UNCMD                             ;GET UPSET IF BAD
        LEAY    8,X                               ;POINT TO NAME
LDGO
        LDX     #FREE                             ;POINT TO FREE SPACE
        SWI
        FCB     53                                ;LOAD FILE
        BEQ     LOA2                              ;IT'S OK, CONTINUE
LOA1
        LBSR    SYSMSG                            ;INDICATE SYSTEM ERROR
        FCN     'WS NOT FOUND'
        RTS
;* PERFORM INIT
LOA2
        LBSR    WSISET                            ;SET NAME
        LDS     #STACK                            ;RESET STACK
        STS     SAVSTK                            ;SAVE NEW
        LBSR    DOREST                            ;PERFORM RESET
        BSR     INIWS                             ;INIT WORKSPACE
        LBSR    DSPSTR                            ;DISPLAY STRING
        FCN     'WSID IS '	MESSAGE TO DISPLAY
        LBSR    DWSID                             ;DISPLAY
        LDY     #LXNAME                           ;POINT TO LATENT EXPRESSION
        LBSR    LOOKUP                            ;IS IT FOUND?
        BNE     CMD1                              ;NO, SKIP IT
PROCMD
        LBSR    EXPR                              ;EVALUATE EXPRESSION
CMD1
        LBRA    CMD                               ;PERFORM COMMAND
;* ')DROP' COMMAND
DROP
        LBSR    FILNAM                            ;GET FILENAME
        SWI
        FCB     10                                ;TELL DOS
        LBNE    UNCMD                             ;GET UPSET IF INVALID
        SWI
        FCB     73                                ;THROW IT AWAY
        BNE     LOA1                              ;IF NOT FOUND
        RTS
;*
;* FUNCTION EDITOR
;*
EDIT
        CMPA    #'$'                              ;CREATE A FUNCTION?
        LBNE    PROCMD                            ;PROCESS COMMAND
        STY     TEMP                              ;SAVE POINTER
        LBSR    SFSYM                             ;SKIP FORWARD
        BNE     NAMOK                             ;NAME IS OK
DEFERR
        LBSR    SYSMSG                            ;DISPLAY MESSAGE,
        FCN     'DEFN ERROR'
        LBRA    CMD                               ;AND BACK FOR COMMAND
NAMOK
        STY     TEMP3                             ;SAVE Y REG
        LBSR    DOREST                            ;PERFORM A RESET
        LDY     TEMP3                             ;RESTORE
        LEAY    -1,Y                              ;BACKUP TO FIRST CHAR OF SYMBOL
        CLRA
        CLRB                                      ;	GET A ZERO
        STD     TEMP3                             ;INITIALIZE LINE NUMBER
        LBSR    LOOKUP                            ;LOOK FOR ENTRY
        BEQ     FUNFND                            ;FUNCTION EXISTS
        LDY     TEMP                              ;POINT TO NAME
        LBSR    SKP                               ;ADVANCE TO NEXT CRAP
        LDX     FREE                              ;POINT TO FREE RAM
        CLR     ,X+                               ;RESAVE
        STX     TEMP2                             ;SAVE POINTER TO FUNCTION BEING EDITED
CRED1
        LDA     ,Y+                               ;GET CHAR
        STA     ,X+                               ;SAVE
        CMPA    #$0D                              ;END?
        BNE     CRED1                             ;NO, CONTINUE
        LDA     #$FF                              ;GET END OF FUNCTION INDICATOR
        STA     ,X+                               ;SAVE IN RAM
        INC     TEMP3+1                           ;START ON LINE 1
        BRA     EDTRUN                            ;EDIT THE FUNCTION
;* FUNCTION EXISTED, COPY IT OVER
FUNFND
        STX     TEMP                              ;SAVE POINTER TO SYMBOL TABLE ENTRY
        TSTA                                      ;	IS IT AN UNLOCKED FUNCTION?
        BNE     DEFERR                            ;CAN'T EDIT UNLESS IT'S A FUNCTION
        LDY     B,X                               ;GET POINTER TO FUNCTION ADDRESS
        LDX     FREE                              ;POINT TO AVAILABEL MEMORY
        CLR     ,X+                               ;CLEAR BYTE FOR FUNCTION
        STX     TEMP2                             ;RESAVE
;* INSERT NAME AS LINE #0
        LDU     TEMP                              ;POINT TO SYMBOL TABLE ENTRY AGAIN
        LDB     ,U++                              ;GET LENGTH
        ANDB    #$1F                              ;MASK LENGTH
        LEAU    B,U                               ;INDICATE THIS IS IT
EDX1
        LDA     ,-U                               ;GET CHARACTER
        STA     ,X+                               ;SAVE IN NAME
        DECB                                      ;	REDUCE COUNT
        BNE     EDX1                              ;AND KEEP DOING IT
CPYFUN
        LDA     ,Y+                               ;GET CHARACTER FROM FUNCTION
        STA     ,X+                               ;SAVE IN WORKSPACE BUFFER
        CMPA    #$0D                              ;END OF LINE?
        BNE     CPYF1                             ;NO, ADVANCE TO NEXT
        INC     TEMP3+1                           ;ADVANCE LINE NUMBER
        BCC     CPYF1                             ;AND SKIP IF NO CARRY
        INC     TEMP3                             ;ADVANCE HIGH DIGIT
CPYF1
        CMPA    #$FF                              ;END OF FUNCTION?
        BNE     CPYFUN                            ;CONTINUE TILL WE COPY IT ALL
;* START UP THE EDITOR
EDTRUN
        LEAX    -1,X                              ;BACKUP TO END OF FILE MARKER
EDTLIN
        LDA     #'['                              ;GET STARTING BRACE
        LBSR    PUTCHR                            ;DISPLAY
        LDD     TEMP3                             ;GET LINE NUMBER
        LBSR    DECOUT                            ;DISPLAY
        LDA     #']'                              ;GET POINTER
        LBSR    PUTCHR                            ;DISPLAY
        LBSR    SPACE                             ;AND A BLANK
        LBSR    GETRAM                            ;GET A LINE
        LBSR    SKP                               ;IS IT COMMAND
        BEQ     EDTLIN                            ;BAD, TRY AGAIN
        CMPA    #'$'                              ;END OF DEFINITION
        LBEQ    RESAVE                            ;RESAVE EDITED FUNCTION
        CMPA    #'['                              ;IS IT COMMAND?
        BEQ     EDCMD                             ;EXECUTE EDIT COMMAND
        LBSR    DELETE                            ;DELETE THIS LINE
        LBSR    INSERT                            ;INSERT THIS LINE
INCLIN
        INC     TEMP3+1                           ;ADVANCE LINE NUMBER
        BCC     EDTLIN                            ;IF NO CARRY, EVERYTHING OK
        INC     TEMP3                             ;AND GO FOR BROKE
        BRA     EDTLIN                            ;EDIT LINE
ERRDEF
        PSHS    X                                 ;SAVE POINTER
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
        FCN     'DEFN ERROR'
        PULS    X                                 ;RESTORE
        BRA     EDTLIN                            ;BACK TO LINE
;*
;* EDITOR COMMAND
;*
EDCMD
        LEAY    1,Y                               ;SKIP '['
        LBSR    SKIP                              ;ADVANCE TO NEXT
        CMPA    #'$'                              ;IS IT DISPLAY
        BNE     EDC1                              ;NOT A QUAD
        LBSR    SFNUM                             ;LOOK FOR NUMBER
        BEQ     EDC2                              ;SHOW ALL
        LBSR    GETDIG                            ;GET NUMBER
        BRA     EDC3                              ;IT'S OK
EDC2
        LBSR    DSPSTR                            ;DISPLAY MSG
        FCN     '     $'	DISPLAY
        LDX     TEMP2                             ;POINT TO SPACE
        LBSR    OULI                              ;DISPLAY
        LDD     #1                                ;DISPLAY LINE 1
EDC3
        LBSR    FNDLIN                            ;POINT TO LINE
DISP
        LDA     ,X                                ;ARE WE AT END
        CMPA    #$FF                              ;TEST FOR END OF FILE
        BEQ     EDC5                              ;QUIT IF END
        LBSR    DSPLIN                            ;DISPLAY A LINE
        LDD     TEMP3                             ;GET NUMBER
        ADDD    #1                                ;ADVANCE
        STD     TEMP3                             ;AND RESAVE
        BRA     DISP                              ;AND CONTINUE
;* DELETE LINES
EDC1
        CMPA    #'D'                              ;IS IT DELETE LINE?
        BNE     EDC4                              ;NO, TRY POSITION
        LBSR    SFNUM                             ;LOOK FOR LINE NUMBER
        BEQ     ERRDEF                            ;CAN'T DELETE
        LBSR    GETDIG                            ;GET NUMBER
        CMPD    #0                                ;TRYING TO DELETE 0?
        BEQ     ERRDEF                            ;INVALID
        LBSR    FNDLIN                            ;LOCATE LINE
        LBSR    DELETE                            ;GET RID OF IT
EDC5
        LBRA    EDTLIN                            ;NEXT COMMAND
;* INSERT LINE(S)
EDC4
        CMPA    #'I'                              ;INSERT?
        BNE     EDCP                              ;NO, FORGET IT
        LBSR    SFNUM                             ;ARE WE OK?
        LBEQ    ERRDEF                            ;NO, NO NUMBER
        LBSR    GETDIG                            ;GET THE NUMBER
        CMPD    #0                                ;CANNOT INSERT IN LINE 0
        LBEQ    ERRDEF                            ;SAY SO
        LBSR    FNDLIN                            ;LOCATE THE LINE
EDCZ
        LDA     #'('                              ;DISPLAY MESSAGE
        LBSR    PUTCHR                            ;OUTPUT
        LDD     TEMP3                             ;GET LINE NUMBER
        LBSR    DECOUT                            ;OUTPUT
        LDA     #')'                              ;CLOSING PROMPT
        LBSR    PUTCHR                            ;DISPLAY
        LBSR    SPACE                             ;SPACE OVER
        LBSR    GETRAM                            ;GET A LINE
        LBSR    SKP                               ;IS IT THE END
        BEQ     EDCX                              ;IF SO, QUIT
        LBSR    INSERT                            ;PUT IT HERE
        LDD     TEMP3                             ;GET LINE NUMBER
        ADDD    #1                                ;ADVANCE
        STD     TEMP3                             ;AND GO AGAIN
        BRA     EDCZ                              ;AND GET NEXT LINE
EDCX
        LBRA    EDTLIN                            ;BACK FOR NEXT COMMAND
;* POSITION TO LINE
EDCP
        LBSR    VALNUM                            ;IS IT VALID?
        LBNE    ERRDEF                            ;NO, GET UPSET
        LEAY    -1,Y                              ;BACKUP TO IT
        LBSR    SFNUM                             ;LOOK FOR NUMBER
        PSHS    A                                 ;SAVE CHARACTER
        LBSR    GETDIG                            ;GET NUMBER
        LBSR    FNDLIN                            ;LOCATE IT
        PULS    A                                 ;GET CHARACTER BACK
        CMPA    #'$'                              ;DO WE DISPLAY?
        BNE     EDCX                              ;NO, JUST GO THERE
        PSHS    X                                 ;SAVE POSITION
        LBSR    DSPLIN                            ;DISPLAY
        PULS    X                                 ;RESTORE X
        LBRA    EDTLIN                            ;AND GO HOME
;* SAVE NEW FUNCTION DEFINITION, INSERT AT BEGINNING OF SYMBOL TABLE
RESAVE
        LDA     1,Y                               ;GET NEXT CHARACTER
        STA     ASSFLG                            ;SAVE
        CLRA
        CLRB                                      ;	GET A ZERO
        STD     TEMP3                             ;SET LINE NUMBER
        LDX     TEMP2                             ;POINT TO START
        TFR     X,Y                               ;COPY IT
        LBSR    SFSYM                             ;SKIP TO END
        LBEQ    ERRDEF                            ;INVALID DEFN
        STB     TEMP4                             ;SAVE LENGTH
        STY     TEMP3                             ;SAVE POINTER TO SYMBOL
        LEAY    -1,Y                              ;BACKUP
        LBSR    LOOKUP                            ;LOOK FOR IT
        BNE     NOER1                             ;DON'T ERASE
        LBSR    ERASYM                            ;ERASE IT
NOER1
        LDX     TEMP3                             ;POINT TO WORKSPACE
RE2
        LDA     ,X+                               ;GET SYMBOL CHAR
        CMPA    #$FF                              ;END OF PROGRAM?
        BNE     RE2                               ;NO
        TFR     X,D                               ;COPY
        SUBD    TEMP3                             ;CONVERT TO OFFSET VALUE
        STD     TEMP1                             ;SAVE OFFSET VALUE
;* RIFLE THROUGH SYMBOL TABLE, LOOKING FOR END, AND ADDING OFFSET TO THE
;* EXISTING SYMBOLS
        LDX     #SYMTAB-2	POINT TO SYMBOL TABLE
RIF0
        LEAX    2,X                               ;ADVANCE
RIF1
        LDB     ,X++                              ;GET OFFSET
        TFR     B,A                               ;COPY TO A
        ANDA    #$E0                              ;MASK LENGTH
        ANDB    #$1F                              ;MASK TYPE
        BEQ     RIF2                              ;HIT THE END
        LEAX    B,X                               ;OFFSET TO DATA AREA
        CMPA    #$60                              ;IS IT LABEL TYPE
        BEQ     RIF0                              ;IF SO, DON'T ADJUST
        LDD     ,X                                ;GET ADDRESS
        ADDD    TEMP1                             ;ADD OFFSET
        STD     ,X++                              ;RESAVE
        BRA     RIF1                              ;AND CONTINUE
;* ADVANCE SYMBOL TABLE ENOUGH FOR ENTRY
RIF2
        LDB     TEMP4                             ;GET LENGTH
        ADDB    #4                                ;ADD TYPE/ADDRESS BYTES
        LEAY    B,X                               ;POINT TO ABOVE ADDRESS
RIF3
        LDA     ,-X                               ;GET BYTE FROM TABLE
        STA     ,-Y                               ;SAVE IN NEW LOCATION
        CMPX    #SYMTAB                           ;ARE WE PAST BEGINNING?
        BHI     RIF3                              ;NO, KEEP GOING
;* CREATE SYMBOL TABLE ENTRY
        LDB     TEMP4                             ;GET LENGTH
        LDA     ASSFLG                            ;RESTORE TYPE
        CMPA    #'$'                              ;IS IT LOCK?
        BNE     NOLOKI                            ;DON'T LOCK
        ORB     #$20                              ;SET TYPE TO ONE
NOLOKI
        STB     ,X+                               ;SAVE LENGTH IN TABLE
        CLR     ,X+                               ;AND SET NEST BYTE
        LDY     TEMP3                             ;POINT TO ENTRY
        ANDB    #$1F                              ;REMOVE TYPE INFO
RIF4
        LDA     ,-Y                               ;GET CHARACTER
        STA     ,X+                               ;SAVE IN TABLE
        DECB                                      ;	REDUCE COUNT
        BNE     RIF4                              ;CONTINUE
        LDD     FREMEM                            ;POINT TO FREE MEMORY
        STD     ,X                                ;SET ADDRESS
;* MOVE MEMORY AHEAD, TO MAKE ROOM
        LDX     TEMP3                             ;GET PROGRAM ADDRESS
        LDD     TEMP1                             ;GET SIZE
        LEAY    D,X                               ;ADVANCE TO END OF PROGRAM
        PSHS    Y                                 ;SAVE POINTER
        LEAX    D,Y                               ;ADVANCE TO EXTRA SPACE FOR COPY
RIF5
        LDA     ,-Y                               ;GET BYTE
        STA     ,-X                               ;SAVE IN NEW LOCATION
        CMPY    FREMEM                            ;HIT THE BEGINNING?
        BHI     RIF5                              ;NO, KEEP GOING
        PULS    X                                 ;RESTORE POINTER TO TEXT
RIF6
        LDA     ,X+                               ;GET FROM PROGRAM
        STA     ,Y+                               ;SAVE
        CMPA    #$FF                              ;AT THE END?
        BNE     RIF6                              ;NO, SKIP IT
        LDD     FREE                              ;GET FREE MEMORY
        ADDD    TEMP1                             ;ADD IN PROGRAM SIZE
        STD     FREE                              ;RESAVE
        LBRA    CMD                               ;GET NEXT COMMAND
;*
;* EDITOR SUBROUTINES
;*
;* DISPLAY LINE (X)
DSPLIN
        LDA     #'['                              ;GET OPANING BRACE
        LBSR    PUTCHR                            ;OUTPUT
        LDD     TEMP3                             ;GET LINE NUMBER
        LBSR    DECOUT                            ;DISPLAY
        LDA     #']'                              ;CLOSING BRACE
        LBSR    PUTCHR                            ;DISPLAY
        LBSR    SPACE                             ;DISPLAY A SPACE
        PSHS    X,Y                               ;SAVE POINTER
        TFR     X,Y                               ;COPY IT OVER
        LBSR    SFSYM                             ;LOOK FOR SYMBOL
        BEQ     EXTSPC                            ;IF NONE, EXTRA SPACE
        CMPA    #':'                              ;WAS IT A LABEL?
        BEQ     NOESPC                            ;YES, OUTDENT IT ONE COLUMN
EXTSPC
        LBSR    SPACE                             ;DISPLAY
NOESPC
        PULS    X,Y                               ;RESTORE REGS
;* DISPLAY MESSAGE (X)
OULI
        LDA     ,X+                               ;GET CHARACTER FROM LINE
        BEQ     OULX                              ;IF ZERO, TERMINATE
        LBSR    PUTCHR                            ;DISPLAY
        CMPA    #$0A                              ;END OF LINE?
        BNE     OULI                              ;NO, CONTINUE
OULX
        RTS
;* MOVE TO AND FIND LINE INDICATED BY D
FNDLIN
        LDX     TEMP2                             ;POINT TO TEXT
FNDL1
        PSHS    A,B,Y                             ;SAVE INDICATORS
        CLRA
        CLRB                                      ;	START WITH ZERO
FND1
        LDY     ,S                                ;GET VALUE
        BEQ     FND4                              ;LINE IS FOUND
        LEAY    -1,Y                              ;DECREMENT
        STY     ,S                                ;AND RESAVE
        ADDD    #1                                ;INCREMENT LINE NUMBER
        PSHS    A                                 ;SAVE CHARACTER
FND2
        LDA     ,X+                               ;ADVANCE
        CMPA    #$FF                              ;IS IT END OF FILE?
        BEQ     FND3                              ;IF SO, QUIT
        CMPA    #$0D                              ;END OF LINE
        BNE     FND2                              ;GIVE UP
        PULS    A                                 ;RESTORE CHARACTER
        BRA     FND1                              ;AND KEEP LOOKING
FND3
        PULS    A                                 ;RESTORE CHARACTER
        LEAX    -1,X                              ;BACKUP TO VALUE
FND4
        STD     TEMP3                             ;SAVE NUMBER
        PULS    A,B,Y,PC	GO HOME
;* DELETE LINE POINTED TO BY X
DELETE
        PSHS    X,Y                               ;SAVE POINTERS
        TFR     X,Y                               ;COPY TO Y REGISTER
DEL1
        LDA     ,X+                               ;GET CHARACTER FROM LINE
        CMPA    #$FF                              ;END OF LINE
        BEQ     DEL3                              ;IF SO, QUIT
        CMPA    #$0D                              ;END OF LINE?
        BNE     DEL1                              ;NO, KEEP LOOKING
DEL2
        LDA     ,X+                               ;GET CHARACTER FROM TEXT
        STA     ,Y+                               ;SAVE IN OLD POSITION
        CMPA    #$FF                              ;END OF TEXT?
        BNE     DEL2                              ;NO, KEEP GOING
DEL3
        PULS    X,Y,PC                            ;GO HOME
;*
;* FIND END OF FILE
;*
FNDEOF
        LDA     ,X+                               ;GET CHARACTER FROM FILE
        CMPA    #$FF                              ;ARE WE AT END?
        BNE     FNDEOF                            ;NO, KEEP LOOKING\
        RTS
;*
;* INSERT LINE INTO TEXT
;*
INSERT
        PSHS    X,Y                               ;SAVE POINTERS
        CLRB                                      ;	CLEAR LENGTH
INS1
        INCB                                      ;	ADVANCE COUNT
        LDA     ,Y+                               ;LOOK FOR END OF LINE
        CMPA    #$0D                              ;END OF LINE?
        BNE     INS1                              ;NO, SKIP IT
        BSR     FNDEOF                            ;FIND END OF FILE
        LEAY    B,X                               ;ADVANCE TO NEXT
INS2
        LDA     ,-X                               ;GET CHARACTER FROM TEXT
        STA     ,-Y                               ;AND SAVE AT NEW POSITION
        CMPX    ,S                                ;ARE WE BACK TO NEW POSITION
        BHI     INS2                              ;KEEP GOING TILL WE GET TO END
        PULS    X,Y                               ;GET POINTERS BACK
INS3
        LDA     ,Y+                               ;GET CHARACTER FROM BUFFER
        STA     ,X+                               ;SAVE IN TEXT
        DECB                                      ;	REDUCE COUNT
        BNE     INS3                              ;AND KEEP COPYING
        RTS
;*
;* SYSTEM SUBROUTINES
;*
;* GET A LINE OF INPUT
;*
GETRAM
        LDY     #RAM                              ;POINT TO RAM
        BRA     GETLIN                            ;GET INPUT LINE
GETLF
        LBSR    LFCR                              ;NEW LINE
GETLIN
        LDA     #$0D                              ;GET CR
        STA     ,Y+                               ;SABE IN RAM LOCATION
        CLRB                                      ;	INDICATE AT POSITION ZERO
GET1
        TSTB                                      ;	TEST FOR OVER LIMIT
        BMI     GETLF                             ;IF SO, TRY AGAIN
        BSR     GETCHR                            ;GET INPUT CHARACTER
        CMPA    #$03                              ;CONTROL-C
        BEQ     INPBRK                            ;IF SO, INTERRUPT
        CMPA    #$7F                              ;DELETE?
        BEQ     DELCHR                            ;IF SO, DELETE IT
        STA     B,Y                               ;SAVE IN BUFFER
        INCB                                      ;	ADVANCE TO NEXT
        LBSR    PUTCHR                            ;DISPLAY
        CMPA    #$0A                              ;CARRIAGE RETURN?
        BNE     GET1                              ;NO, SKIP IT
        RTS
DELCHR
        DECB                                      ;	BACKUP OVER CHARACTER
        PSHS    X                                 ;SAVE POINTER
        LBSR    DSPSTR                            ;DISPLAY
        FCB     $08,$20,$08,0	MESSAGE TO DELETE
        PULS    X                                 ;RESTORE
        BRA     GET1                              ;AND GO AGAIN
INPBRK
        LDA     #$0D                              ;GET CR
        STA     B,Y                               ;SAVE IT
        LEAY    -1,Y                              ;BACKUP TO BEFORE CR
        LBSR    PUTCHR                            ;DISPLAY NEW LINE
        LBRA    BREAK                             ;PERFORM BREAK
;* READ A CHARACTER
GETCHR
        SWI
        FCB     34                                ;GET A CHARACTER
        CMPA    #$41                              ;<'A'?
        BLO     CHROK                             ;IF SO, IT'S OK
        CMPA    #$5A                              ;>'Z'?
        BHI     NOC1                              ;NO CONVERSION
        ORA     #$20                              ;CONVERT TO LOWER CASE
CHROK
        RTS
NOC1
        CMPA    #$61                              ;<'A' (LOWER)?
        BLO     CHROK                             ;IT'S OK
        CMPA    #$7A                              ;>'Z' (LOWER)?
        BHI     CHROK                             ;IF SO, IT'S OK
        ANDA    #$5F                              ;CONVERT TO UPPER CASE
        RTS
;*
;* DISPLAY STRING
;*
DSPSTR
        PULS    X                                 ;GET POINTER TO MESSAGE
DSP1
        LDA     ,X+                               ;GET FROM TEXT
        BEQ     DSP2                              ;QUIT
        BSR     PUTCHR                            ;DISPLAY
        BRA     DSP1                              ;AGAIN
DSP2
        TFR     X,PC                              ;RETURN
;*
;* DISPLAY SYSTEM MESSAGE
;*
SYSMSG
        PULS    X                                 ;GET X FROM PC
SY1
        LDA     ,X+                               ;GET CHAR
        BEQ     ENM1                              ;END OF MESSAGE
        BSR     PUTCHR                            ;OUTPUT
        BRA     SY1                               ;AND DISPLAY
ENM1
        PSHS    X                                 ;SAVE PC AGAIN
;* DISPLAY LFCR ON TERMINAL
LFCR
        LDA     #$0D                              ;NEW LINE
        BSR     PUTOUT                            ;DISPLAY
        LDA     #$0A                              ;LF
;* DISPLAY A CHARACTER
PUTCHR
        CMPA    #$0D                              ;END OF LINE?
        BEQ     LFCR                              ;IF SO, DISPLAY LFCR
PUTOUT
        SWI
        FCB     33                                ;DISPLAY
        RTS
;* DISPLAY A SPACE
SPACE
        LDA     #' '                              ;GET A SPACE
        BRA     PUTCHR                            ;AND DISPLAY
;* SKIP WITHOUT ADVANCING
SKP
        LDA     ,Y+                               ;GET CHR
        CMPA    #' '                              ;TEST FOR BLANK
        BEQ     SKP                               ;AND FIND A NON-BLANK
        LEAY    -1,Y                              ;BACKUP TO IT
        CMPA    #$0D                              ;TEST FOR END OF LINE
        RTS
;* SKIP TO NEXT NON-BLANK
SKIP
        LDA     ,Y+                               ;GET CHARACTER
        CMPA    #' '                              ;BLANK?
        BEQ     SKIP                              ;TRY AGAIN
        CMPA    #$0D                              ;CR?
        BNE     OKRTS                             ;SKIP IT
        LEAY    -1,Y                              ;BACKUP
        ORCC    #4                                ;SET Z FLAG
OKRTS
        RTS
;* SKIP BACK BUT CHECK HERE FIRST
SKBKP
        LEAY    1,Y                               ;ADVANCE FIRST
;* SKIP BACKWARD TO NEXT NON-BLANK
SKBK
        LDA     ,-Y                               ;BACKUP
        CMPA    #' '                              ;SPACE?
        BEQ     SKBK                              ;CONTINUE
        CMPA    #$0D                              ;START OF LINE?
        RTS
;* SKIP FORWARD THROUGH A NUMBER
SFNUM
        LDB     #-1                               ;START WITH MINUS ONE
SFN1
        INCB                                      ;	ADVANCE FOR LENGTH
        LDA     ,Y+                               ;ADVANCE
        BSR     VALNUM                            ;IS IT A VALID DIGIT?
        BEQ     SFN1                              ;IF SO, CONTINUE
        LEAY    -1,Y                              ;BACKUP TO START OF NUMBER
        TSTB                                      ;	CHECK FOR ZERO LENGTH
        RTS
;* SKIP FORWARD THROUGH A VARIABLE
SFSYM
        LDB     #-1                               ;START WITH MINUS ONE
SFS1
        INCB                                      ;	ADVANCE FOR LENGTH
        LDA     ,Y+                               ;ADVANCE
        BSR     VALSYM                            ;IS IT VALID?
        BEQ     SFS1                              ;AND CONTINUE
        LEAY    -1,Y                              ;BACKUP
        TSTB                                      ;	TEST FOR ZERO LENGTH
        RTS
;* SET Z FLAG IF PASSED CHARACTER IS A VALID NUMBER
VALNUM
        CMPA    #'0'                              ;IN RANGE?
        BLO     BADSYM                            ;NO, IT'S BAD
        CMPA    #'9'                              ;IN RANGE?
        BHI     BADSYM                            ;NO, IT'S BAD
        BRA     VALOK                             ;VALUE IS OK
;* SET Z FLAG IS PASSED CHARACTER IS A VALID SYMBOL
VALSYM
        CMPA    #'@'                              ;IN RANGE?
        BLO     BADSYM                            ;NO, IT'S BAD
        CMPA    #'Z'                              ;IN RANGE?
        BHI     BADSYM                            ;NO, IT'S BAD
VALOK
        ORCC    #4                                ;INDICATE OK
BADSYM
        RTS
;*
;* GETS NUMERIC VALUE FROM LINE(Y)., RETURNS IN D
;*
GETDEC
        LEAY    1,Y                               ;ADVANCE
GETDIG
        LDD     #0                                ;START OF RESULT
        PSHS    A,B,X                             ;SAVE VALUE AND MULTIPLIER
        LDX     #1                                ;FIRST MULTIPLIER
GETD1
        LDA     ,-Y                               ;GET DIGIT
        BSR     VALNUM                            ;IS IT A VALID NUMBER
        BNE     GETD2                             ;END OF NUMBER
        SUBA    #$30                              ;CONVERT TO BINARY
        TFR     A,B                               ;COPY TO B
        CLRA                                      ;	CLEAR IT
        LBSR    MULT                              ;TIMES MULTIPLIER
        ADDD    ,S                                ;ADD TO OLD VALUE
        STD     ,S                                ;RESAVE
        LDD     #10                               ;TIMES 10
        LBSR    MULT                              ;PERFORM
        TFR     D,X                               ;COPY TO X
        BRA     GETD1                             ;GET NEXT DIGIT
GETD2
        CMPA    #'_'                              ;NEGATIVE PREFIX?
        BNE     DETD3                             ;NO, IT'S OK
        CLRA                                      ;	GET A ZERO
        CLRB                                      ;	FOR D ACCUMULATOR
        SUBD    ,S                                ;CONVERT NUMBER
        STD     ,S                                ;RESAVE
        LEAY    -1,Y                              ;BACKUP
DETD3
        PULS    A,B,X,PC	RESTORE VALUES
;*
;* LOOK UP ENTRY IN SYMBOL TABLE, ON EXIT, IF ENTRY IS FOUND, Z FLAG IS
;* SET AND X POINTS TO A COPY OF THE SYMBOL TABLE ENTRY IN RAM. B HAS OFFSET
;* FOR ADDRESS, AND A CONTAINS TYPE
;* IF ENTRY IS NOT FOUND, Z FLAG IS CLEAR, AND X POINTS TO FIRST FREE SYMBOL
;* TABLE SPACE
;*
LOOKUP
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
CHKENT
        PSHS    X,Y                               ;SAVE REGSITERS
        LDB     ,X+                               ;GET LENGTH OF NAME
        ANDB    #$1F                              ;REMOVE TYPE BITS
        BEQ     ENDST                             ;DIDN'T FIND IT
        LDA     ,X+                               ;GET NEST INFO
        BNE     NOSYM                             ;DON'T RECOGNISE IT
CHKV
        LDA     ,Y                                ;GET CHARACTER FROM SOURCE
        CMPA    ,X+                               ;IS IT OK
        BNE     NOSYM                             ;NOT A VARIABLE
        LEAY    -1,Y                              ;BACKUP
        DECB                                      ;	REDUCE COUNT
        BNE     CHKV                              ;AND KEEP CHECKING
        LDA     ,Y                                ;GET CHARACTER FROM VARIABLE
        LBSR    VALSYM                            ;VALID SYMBOL?
        BEQ     NOSYM                             ;HAVN'T FOUND IT YET
        PULS    X                                 ;RESTORE TABLE POSITION
        LEAS    2,S                               ;SKIP Y VALUE
        LBSR    SKBKP                             ;SKIP BACK TO NEXT
        LDA     ,X                                ;GET LENGTH
        TFR     A,B                               ;SAVE TYPE INFO IN B
        ANDB    #$1F                              ;MASK OFF LENGTH
        ADDB    #2                                ;SKIP TO TYPE BYTE
        LSRA                                      ;	SHIFT
        LSRA                                      ;	TYPE
        LSRA                                      ;	BACK
        LSRA                                      ;	TO
        LSRA                                      ;	POSITION
        ORCC    #4                                ;SET Z FLAG
        RTS
NOSYM
        PULS    X,Y                               ;RESTORE REGSTERS
        LDA     ,X                                ;ADVANCE TO NEXT
        ANDA    #$1F                              ;MASK OFF TYPE
        ADDA    #4                                ;ADD THREE BYTES FOR ADDRESS
        LEAX    A,X                               ;SKIP TO NEXT ENTRY
        BRA     CHKENT                            ;AND CHECK THIS ENTRY
ENDST
        PULS    X,Y                               ;RESTORE POINTER
        ANDCC   #$FB                              ;CLEAR Z FLAG
        RTS
;*
;* CREATE A SYMBOL TABLE ENTRY, TYPE PASSED IN A
;*
CRESYM
        LSLA                                      ;	SHIFT
        LSLA                                      ;	TYPE INTO HIGH BITS
        LSLA                                      ;	FOR ENTRY IN
        LSLA                                      ;	SYMBOL
        LSLA                                      ;	TABLE
        PSHS    A                                 ;SAVE TYPE
        LDX     #SYMTAB                           ;POINT TO TABLE
CRE1
        LDA     ,X+                               ;GET LINK
        ANDA    #$1F                              ;MASK OFF LENGTH INFO
        BEQ     CRE2                              ;END OF TABLE
        ADDA    #3                                ;CONVERT TO COMPLETE OFFSET
        LEAX    A,X                               ;SKIP THIS ENTRY
        BRA     CRE1                              ;LOOK AGAIN
CRE2
        CLRB                                      ;	SET OFFSET
CRE3
        LDA     ,Y                                ;GET CHARACTER FROM TEXT
        LBSR    VALSYM                            ;IS IT VALID
        BNE     CRE4                              ;NO MORE
        INCB                                      ;	ADVANCE
        STA     B,X                               ;SAVE SYMBOL IN TABLE
        LEAY    -1,Y                              ;BACKUP TO NEXT
        BRA     CRE3                              ;AND KEEP CREATING
CRE4
        TFR     B,A                               ;COPY TO A
        ORA     ,S+                               ;ADD IN TYPE BITS
        STA     -1,X                              ;SAVE LENGTH IN TABLE
        CLR     ,X                                ;INDICATE LEVEL ZERO NEST
        INCB                                      ;	SKIP TO TYPE FIELD IN ENTRY
        LEAX    B,X                               ;ADVANCE POINTER
        LDD     FREE                              ;POINT TO FREE MEMORY
        STD     ,X                                ;INDICATE WHERE SYMBOL WILL BE
        CLR     2,X                               ;INDICATE LAST ENTRY
        RTS
;*
;* PERFORMS 16 BIT MULTIPLICATION (D=X;*D)
;*
MULT
        PSHS    D,X                               ;SAVE PARAMETERS
        LDA     1,S
        LDB     3,S
        MUL
        PSHS    A,B                               ;RESAVE
        LDA     2,S
        LDB     5,S
        MUL
        ADDB    ,S
        STB     ,S
        LDA     3,S
        LDB     4,S
        MUL
        ADDB    ,S
        STB     ,S
        PULS    A,B                               ;GET RESULT
        LEAS    4,S                               ;SKIP CRAP
        RTS
;*
;* PERFORMS 16 BIT DIVISION. (X=X/D, D=REMAINDER.)
;*
DIV
        PSHS    D,X
        LDD     #0
        LDX     #17
DIV1
        ANDCC   #$FE
DIV2
        ROL     3,S
        ROL     2,S
        LEAX    -1,X
        BEQ     DIV3
        ROLB
        ROLA
        CMPD    ,S
        BLO     DIV1
        SUBD    ,S
        ORCC    #1
        BRA     DIV2
DIV3
        LEAS    2,S
        PULS    X
        RTS
;*
;* GET FILENAME FROM INPUT LINE
;*
FILNAM
        PSHS    Y                                 ;SAVE Y
FIL1
        LDA     ,Y+                               ;GET CHAR
        CMPA    #' '                              ;SPACE?
        BEQ     FIL2                              ;MARKS END
        CMPA    #$0D                              ;CR?
        BNE     FIL1                              ;NO, MORE FILENAME
FIL2
        LDA     #'.'                              ;GET DOT
        STA     -1,Y                              ;SAVE
        LDD     #$4150                            ;GET 'AP'
        STD     ,Y++                              ;SET UP IN NAME
        LDD     #$4C0D                            ;GET 'L' AND CR
        STD     ,Y                                ;SET UP IN NAME
        PULS    Y                                 ;RESTORE FILENAME POINTER
        RTS
;*
;* EVALUATES AN EXPRESSION
;*
EXPR
        LDA     ,Y+                               ;GET CHARACTER
        CMPA    #$0D                              ;END OF LINE?
        BNE     EXPR                              ;KEEP LOOKING
EXEX
        CLR     ERRFLG                            ;INSURE NO ERROR SET
        LEAY    -1,Y                              ;BACKUP
        PSHS    Y                                 ;SAVE IT
        BSR     DOEXPR                            ;EXECUTE ROUTINE
        CMPA    #':'                              ;LABEL DEFINITION?
        BEQ     EXEXE                             ;IF SO, OK
        CMPA    #$0D                              ;END OF LINE?
        BNE     EX1                               ;NO, DON'T DISPLAY
EXEXE
        TST     ASSFLG                            ;WAS IT ASSIGNMENT
        BNE     EX1                               ;NO, DON'T DISPLAY
        LDD     INPSTK                            ;ARE WE INPUTTING?
        BNE     EX1                               ;YES, DON'T OUTPUT
        LBSR    DISPLY                            ;DISPLAY
        LBSR    LFCR                              ;NEW LINE
EX1
        PULS    Y,PC                              ;GO HOME
;* CALCULATE AN EXPRESSION
DOEXPR
        CLR     ASSFLG                            ;INSURE WE KNOW IF ASSIGNMENT
        LDD     TEMP5                             ;GET FREE RAM ADDRESS
        SUBD    BUFSIZ                            ;SUBTRACT WORK BUFFER
        CMPD    FREE                              ;ARE WE OVER MEMORY LIMIT
        LBLS    WSFUL                             ;INDICATE FULL
        STD     TEMP5                             ;RESAVE
EXP1
        LDX     TEMP5                             ;POINT TO WORKSPACE
        LEAY    -1,Y                              ;BACKUP
        LBSR    GETVAL                            ;GET FIRST VALUE
        LBNE    SYNTAX                            ;FIRST VALUE MUST EXIST
NXTOPR
        LBSR    MVWRK                             ;INSURE LAST RESULT IS IN WORKSPACE
        LBSR    SKBKP                             ;GET NEXT OPERATOR
        STY     TXTPTR                            ;SAVE OPERATOR LOCATION
        CMPA    #$0D                              ;START OF LINE?
        BEQ     ENDEXP                            ;IF SO, QUIT
        CMPA    #':'                              ;LABEL?
        BEQ     ENDEXP                            ;IF SO, EXIT
        CMPA    #'['                              ;START OF INDEX EXPRESSON
        BEQ     ENDEXP                            ;IF SO, QUIT
        CLR     ASSFLG                            ;INSURE '(' DISPLAYS
        CMPA    #'('                              ;START OF NESTED EXPRESSION
        BNE     DOEX1                             ;NO, CALCULATE IT
ENDEXP
        PSHS    A                                 ;SAVE ENDING CHARACTER
        LDD     TEMP5                             ;POINT TO WORK BUFFER
        ADDD    BUFSIZ                            ;RELEASE OUR LEVEL
        STD     TEMP5                             ;AND RESAVE
        PULS    A,PC                              ;GO HOME
;* PERFORM OPERATION
DOEX1
        LEAY    -1,Y                              ;BACKUP TO LAST
;* DETERMINE LENGTH OF PASSED STRUCTURE
DSIP1
        CMPA    #'p'                              ;CHECK FOR LENGTH
        BNE     DSIP2                             ;NOT SHAPE
        LDD     1,X                               ;GET LENGTH
        STD     3,X                               ;AND SAVE IT
        LDD     #1                                ;SET LENGTH TO 1
        STD     1,X                               ;SET LENGTH
        STB     ,X                                ;SET TYPE TO INTEGER
        BRA     NXTOPR                            ;AND GT NEXT OPERAND
;* CREATE AN ASCENTING VECTOR
DSIP2
        CMPA    #'i'                              ;IS IT VECTOR?
        BNE     DSIP3                             ;NO, TRY NEXT
        PSHS    X                                 ;SAVE POSITION
        LDA     ,X+                               ;GET TYPE
        CMPA    #1                                ;INTEGER?
        LBNE    CDOM                              ;NO, ERROR
        LDD     ,X++                              ;GET LENGTH
        CMPD    #1                                ;SINGLE ELEMENT?
        LBNE    CLEN                              ;NO, ERROR
        LDD     ,X                                ;GET DATA
        STD     -2,X                              ;SET LENGTH
        BEQ     IOTZ                              ;SPECIAL CASE
        ADDD    ORIGIN                            ;ADVANCE
IOT1
        SUBD    #1                                ;REDUCE COUNT
        STD     ,X++                              ;SAVE
        CMPD    ORIGIN                            ;ARE WE AT START YET?
        BNE     IOT1                              ;AND GO BACK
IOTZ
        PULS    X                                 ;RESTORE REGISTERS
        LBRA    NXTOPR
;* REVERSE OPERAND VECTOR
DSIP3
        CMPA    #'r'                              ;REVERSE?
        BNE     DSIP4                             ;NO, TRY NEXT
        PSHS    X,Y,U                             ;SAVE REGISTERS
        LDD     1,X                               ;GET LENGTH
        BEQ     REV2                              ;NOTHING TO DO
        LEAY    3,X                               ;GET START OF VECTOR
        TST     ,X                                ;WHAT FORM ARE WE
        BEQ     CREV                              ;REVERSING CHARACTER ARRAY
        LSLB
        ROLA                                      ;	DOUBLE FOR TWO BYTE ENTRIES
        LEAX    D,Y                               ;POINT TO END OF STRING
REV1
        LDD     ,Y++                              ;GET CHARACTER FROM START
        LDU     ,--X                              ;AND GET OTHER ONE
        PSHS    Y                                 ;SAVE
        CMPX    ,S++                              ;TEST FOR WRAPPED
        BLO     REV2                              ;IF SO, WE ARE DONE
        STD     ,X                                ;SAVE NEW RESULT
        STU     -2,Y                              ;AND OTHER ONE
        BRA     REV1                              ;KEEP GOING
CREV
        LEAX    D,Y                               ;SKIP TO END
REV3
        LDA     ,-X                               ;GET CHARACTER
        LDB     ,Y+                               ;AND GET OTHER CHARACTER
        PSHS    Y                                 ;SAVE REG
        CMPX    ,S++                              ;ARE WE THERE?
        BLO     REV2                              ;IF SO, EXIT
        STB     ,X                                ;SET NEW VALUE
        STA     -1,Y                              ;AND NEW VALUE HERE
        BRA     REV3                              ;CONTINUE REVERSING
REV2
        PULS    X,Y,U                             ;RESTORE REGISTERS
        LBRA    NXTOPR                            ;NEXT OPERATOR
;* GENERATE RANDOM VECTORS
DSIP4
        CMPA    #'?'                              ;RANDOM OPERATOR?
        BNE     DSIP5                             ;NO, TRY NEXT
        PSHS    X,Y                               ;SAVE REGISTERS
        LDA     ,X+                               ;GET TYPE
        LBEQ    CDOM                              ;CAN'T USE CHARACTERS
        LDY     ,X++                              ;GET LENGTH
        BEQ     RND2                              ;ZERO LENGTH, SKIP IT
RND1
        PSHS    X                                 ;SAVE POINTER
        LDD     SEED                              ;GET RANDOM SEED
        LDX     #13709                            ;GET FIRST VALUE
        LBSR    MULT                              ;MULTIPLY IT
        ADDD    #13849                            ;AND DO THE ADDITION
        STD     SEED                              ;RESAVE SEED
        TFR     D,X                               ;COPY FOR DIV
        LDD     [,S]                              ;GET LIMIT VALUE
        BEQ     RND3                              ;ZERO, RESULT IS ZERO
        LBSR    DIV                               ;PERFORM DIVISION
        ADDD    ORIGIN                            ;CONVERT FOR ORIGIN VALUE
RND3
        PULS    X                                 ;RESTORE POINTER
        STD     ,X++                              ;SAVE BACK IN VECTOR
        LEAY    -1,Y                              ;REDUCE LENGTH
        BNE     RND1                              ;DO THEM ALL
RND2
        PULS    X,Y                               ;RESTORE REGISTERS
        LBRA    NXTOPR
;* CLASSIFY DATA TYPE
DSIP5
        CMPA    #'c'                              ;IS IT CLASSIFY?
        BNE     DSIP6                             ;NO, TRY NEXT
        LDB     ,X                                ;GET TYPE
        CLRA                                      ;	ZERO HIGH BYTE
        STD     3,X                               ;SAVE DATA
        LDB     #1                                ;GET LENGTH + TYPE
        STD     1,X                               ;SAVE LENGTH
        STB     ,X                                ;SAVE TYPE
        LBRA    NXTOPR
;* GENERATE ASSENDING VECTOR INDEX
DSIP6
        CMPA    #'^'                              ;ASSEND?
        LBNE    DSIP7                             ;NO, TRY NEXT
        PSHS    Y,U                               ;SAVE REGISTERS
        LEAX    1,X                               ;SKIP TO DATA
        LDY     FREE                              ;POINT TO FREE RAM
        LDD     ,X                                ;GET LENGTH
        LEAU    D,Y                               ;ADVANCE FOR FLAG VECTOR SPACE
        PSHS    U                                 ;SAVE FREE LOCATION
        BEQ     ASC8                              ;ZERO LENGTH, NOTHING TO DO
ASC0
        CLR     ,Y+                               ;CLEAR ONE FLAG
        SUBD    #1                                ;REDUCE COUNT
        BNE     ASC0                              ;CLEAR THEM ALL
ASC8
        LDA     #1                                ;RESULT IS ALWAYS AN INTEGER
        STA     ,U+                               ;SET TYPE OF RESULT
        LDD     ,X++                              ;GET LENGTH AGAIN
        STD     ,U++                              ;SET LENGTH OF RESULT
        BEQ     ASC1                              ;IF ZERO LENGTH, NOTHING TO DO
        TFR     D,Y                               ;SAVE LENGTH
        STD     TEMP1                             ;AND KEEP IT
        LDA     -3,X                              ;GET TYPE
        BEQ     ASC5                              ;CHARACTER SORT
ASC2
        PSHS    X,Y                               ;SAVE REGISTERS
        PSHS    U                                 ;SAVE LOCATION
        CLRA                                      ;	START
        CLRB                                      ;	WITH ZERO
        LDY     TEMP1                             ;GET LENGTH
        LDU     FREE                              ;POINT TO FLAG VECTOR
ASC3
        TST     ,U+                               ;TEST FOR ELEMENT ALREADY SELECTED
        BNE     ASC4                              ;IF SO, DON'T LOOK AT IT
        CMPD    ,X                                ;TEST FOR SMALLEST ELEMENT
        BHI     ASC4                              ;NO, SKIP IT
        STY     TEMP3                             ;SAVE ELEMENT NUMBER
        STU     TEMP2                             ;SAVE FLAG VECTOR ADDRESS
        LDD     ,X                                ;USE THIS AS THE NEW VALUE
ASC4
        LEAX    2,X                               ;SKIP TO NEXT ELEMENT
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     ASC3                              ;KEEP GOING TILL WE DO IT ALL
        LDX     TEMP2                             ;GET FLAG VECTOR ADDRESS
        DEC     -1,X                              ;SET FLAG
        PULS    U                                 ;RESTORE RESULT ADDRESS
        LDD     TEMP3                             ;GET ELEMENT NUMBER
        SUBD    #1                                ;CONVERT TO ZERO OFFSET
        ADDD    ORIGIN                            ;AND ADJUST FOR ORIGIN
        STD     ,U++                              ;SAVE IN RSULT
        PULS    X,Y                               ;RESTORE POINTERS
        LEAY    -1,Y                              ;REDUCE REMAINING COUNT
        BNE     ASC2                              ;AND DO THEM ALL
ASC1
        PULS    X,Y,U                             ;RESTORE POINTERS
        LBRA    NXTOPR
ASC5
        PSHS    X,Y                               ;SAVE REGISTERS
        PSHS    U                                 ;SAVE LOCATION
        CLRA                                      ;	START
        LDY     TEMP1                             ;GET LENGTH
        LDU     FREE                              ;POINT TO FLAG VECTOR
ASC6
        TST     ,U+                               ;TEST FOR ELEMENT ALREADY SELECTED
        BNE     ASC7                              ;IF SO, DON'T LOOK AT IT
        CMPA    ,X                                ;TEST FOR SMALLEST ELEMENT
        BHI     ASC7                              ;NO, SKIP IT
        STY     TEMP3                             ;SAVE ELEMENT NUMBER
        STU     TEMP2                             ;SAVE FLAG VECTOR ADDRESS
        LDA     ,X                                ;USE THIS AS THE NEW VALUE
ASC7
        LEAX    1,X                               ;SKIP TO NEXT ELEMENT
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     ASC6                              ;KEEP GOING TILL WE DO IT ALL
        LDX     TEMP2                             ;GET FLAG VECTOR ADDRESS
        DEC     -1,X                              ;SET FLAG
        PULS    U                                 ;RESTORE RESULT ADDRESS
        LDD     TEMP3                             ;GET ELEMENT NUMBER
        SUBD    #1                                ;CONVERT TO ZERO OFFSET
        ADDD    ORIGIN                            ;AND ADJUST FOR ORIGIN
        STD     ,U++                              ;SAVE IN RSULT
        PULS    X,Y                               ;RESTORE POINTERS
        LEAY    -1,Y                              ;REDUCE REMAINING COUNT
        BNE     ASC5                              ;AND DO THEM ALL
        BRA     ASC1                              ;GO HOME
;* EXECUTE STRING
DSIP7
        CMPA    #'e'                              ;EXECUTE?
        BNE     DSIP8                             ;NO, TRY STRING FORMAT
        LDA     ,X+                               ;GET TYPE
        LBNE    CDOM                              ;NOT VALID
        LDD     ,X++                              ;GET LENGTH OF STRING
        BEQ     NOEXEC                            ;NOTHING TO EXECUTE
        CMPD    #128                              ;ARE WE OVER LENGTH
        LBHS    CLEN                              ;INDICATE EXEC OVER 255 CHARACTERS
        PSHS    Y                                 ;SAVE POINTERS
        LEAY    B,X                               ;POINT TO BUFFER
        TFR     Y,X                               ;COPY TO X
        LDA     #$0D                              ;GET CR
        STA     ,Y+                               ;SAVE IT
DS71
        LDA     ,-X                               ;GET CHARACTER FROM BUFFER
        STA     ,Y+                               ;SAVE IN OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     DS71                              ;CONTINUE
        LDA     #$0D                              ;GET CR
        STA     ,Y                                ;SAVE IT
        LBSR    DOEXPR                            ;PERFORM EXPRESSION
        PULS    Y                                 ;RESTORE Y REGISTER
DS72
        LBRA    NXTOPR                            ;GET NEXT OPERAND
;* EXECUTE OF NULL LENGTH VECTOR, DO NOTHING, NO OUTPUT
NOEXEC
        LDX     #IOTA0                            ;POINT TO DEFAULT PARAMETER
        DEC     ASSFLG                            ;DON'T DISPLAY EXECUTE OF NULL
        BRA     DS72                              ;AND GO HOME
;* FORMAT NUMERIC VALUE TO STRING
DSIP8
        CMPA    #'s'                              ;IS IT FORMAT STRING?
        BNE     BRANCH                            ;NO, TRY BRANCH
        PSHS    Y,U                               ;SAVE REGISTERS
        LDU     FREE                              ;AND A PLACE TO PUT IT
        CLR     ,U+                               ;CHARACTER DATA
        LEAU    2,U                               ;ADVANCE PAST LENGTH FOR NOW
        LDY     #0                                ;LENGTH OF OUTPUT
        LDA     ,X+                               ;GET TYPE
        LBEQ    CDOM                              ;INDICATE DOMAIN ERROR
        LDD     ,X++                              ;GET LENGTH
        BEQ     DECS1                             ;EXIT IF ZERO
DECS2
        PSHS    A,B,X                             ;SAVE REGISTERS
        LDX     ,X                                ;GET NUMBER TO DISPLAY
DECS
        LDD     #10                               ;DIVIDE BY 10
        LBSR    DIV                               ;PERFORM DIVISION
        ORB     #$30                              ;CONVERT TO NUMBER
        STB     ,U+                               ;SAVE DIGIT
        LEAY    1,Y                               ;ADVANCE LENGTH
        CMPX    #0                                ;OVER YET?
        BNE     DECS                              ;NO, KEEP GOING
        PULS    A,B,X                             ;RESTORE REGISTERS
        SUBD    #1                                ;ARE WE DONE?
        BEQ     DECS1                             ;IF SO, QUIT
        PSHS    A                                 ;SAVE A
        LDA     #' '                              ;GET SPACE
        STA     ,U+                               ;SAVE
        PULS    A                                 ;RESTORE
        LEAY    1,Y                               ;ADVANCE LENGTH
        LEAX    2,X                               ;ADVANCE TO NEXT
        BRA     DECS2                             ;AND CONTINUE
DECS1
        LDX     FREE                              ;POINT TO OUTPUT
        STY     1,X                               ;SET UP LENGTH
        PULS    Y,U                               ;RESTORE REGS
        LBRA    NXTOPR                            ;AND GET NEXT
;* BRANCH OPERATOR
BRANCH
        CMPA    #'b'                              ;IS IT BRANCH?
        BNE     TRAVEL                            ;NO, TRY TRAVEL
        LDA     ,X                                ;GET TYPE
        LBEQ    CDOM                              ;INDICATE DOMAIN ERROR
        LDD     1,X                               ;GET LENGTH
        BEQ     NOBRA                             ;DON'T BRANCH
        CMPD    #1                                ;IS IT PROPER LENGTH?
        LBNE    CLEN                              ;INDICATE LENGTH ERROR
        LDD     3,X                               ;GET VALUE
        STD     GOTO                              ;SAVE IN FLAG
NOBRA
        DEC     ASSFLG                            ;INSURE NO JUMP
        LBRA    NXTOPR                            ;GO FOR IT
;* OPERATOR TRAVEL
TRAVEL
        CMPA    #'\'                              ;IS IT TRAVEL
        LBNE    REDUC                             ;NO, TRY REDUCTION
        LBSR    SKBKP                             ;GET NEXT OPERATOR
        TST     ,X                                ;TEST TYPE OF OPERAND
        LBEQ    CDOM                              ;NOT VALID WITH CHARACTER
        PSHS    X,Y                               ;SAVE REGISTERS
        LDB     #1                                ;GET TYPE OF RESULT
        STB     ,X+                               ;SAVE TYPE
        LDY     ,X                                ;GET LENGTH
        LEAY    1,Y                               ;CONVERT
        CLRA                                      ;	ZERO HIGH BYTE
        STD     ,X++                              ;SAVE NEW LENGTH
        LDA     [2,S]                             ;GET OPERATOR BACK
        CMPA    #'+'                              ;ADDITION?
        BNE     CMP1                              ;NO, TRY MULTIPLY
        CLRA
        CLRB                                      ;	INITIAL VALUE IS ZERO
CMPA
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END OF OPERAND, QUIT
        ADDD    ,X++                              ;ADD NEXT ELEMENT
        BRA     CMPA                              ;DO NEXT
CMP1
        CMPA    #'x'                              ;MULTIPLY?
        BNE     CMP2                              ;NO, TRY LOGICAL AND
        LDD     #1                                ;INITIAL VALUE IS ONE
CMPB
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END OF OPERAND, QUIT
        PSHS    X                                 ;SAVE POINTER TO OPERAND
        LDX     ,X                                ;GET VALUE
        LBSR    MULT                              ;PERFORM MULTIPLY
        PULS    X                                 ;RESTORE POINTER
        LEAX    2,X                               ;ADVANCE TO NEXT
        BRA     CMPB                              ;GO AGAIN
CMP2
        CMPA    #'&'                              ;LOGICAL AND?
        BNE     CMP3                              ;NO, TRY LOGICAL OR
        LDD     #$FFFF                            ;INTIAL VALUE
CMPC
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END, QUIT
        ANDA    ,X+                               ;AND HIGH BYTE
        ANDB    ,X+                               ;AND LOW BYTE
        BRA     CMPC                              ;AND CONTINUE
CMP3
        CMPA    #'!'                              ;LOGICAL OR?
        BNE     CMP6                              ;NO, TRY XOR
        CLRA
        CLRB                                      ;	START WITH ZERO
CMPD
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END, QUIT
        ORA     ,X+                               ;OR HIGH BYTE
        ORB     ,X+                               ;OR LOW BYTE
        BRA     CMPD                              ;GO AGAIN
CMP9
        PULS    X,Y                               ;RESTORE REGISTERS
        LEAY    -1,Y                              ;BACKUP PAST OPERATOR
        STD     3,X                               ;SAVE VALUE OR RESULT
        LBRA    NXTOPR                            ;AND GET NEXT
CMP6
        CMPA    #'|'                              ;XOR?
        BNE     CMP4                              ;NO, TRY GREATOR OF
        CLRA
        CLRB                                      ;	START WITH ZERO
CMPZ
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END IF DONE
        EORA    ,X+                               ;XOR HIGH BYTE
        EORB    ,X+                               ;XOR LOW BYTE
        BRA     CMPZ                              ;CONTINUE
CMP4
        CMPA    #'g'                              ;GREATOR OF?
        BNE     CMP5                              ;NO, TRY LESS OF
        CLRA
        CLRB                                      ;	START WITH ZERO
CMPE
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END, QUIT
        CMPD    ,X++                              ;TEST FOR GREATOR
        BHS     CMPE                              ;NO, SKIP IT
        LDD     -2,X                              ;REPLACE VALUE
        BRA     CMPE                              ;AND TRY AGAIN
CMP5
        CMPA    #'l'                              ;LESS OF?
        BNE     CSYNT                             ;NO, GET UPSET
        LDD     #$FFFF                            ;START WITH FFFF
CMPF
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     CMP9                              ;END, QUIT
        CMPD    ,X++                              ;TEST FOR LESS
        BLS     CMPF                              ;NO, SKIP IT
        LDD     -2,X                              ;REPLACE VALUE
        BRA     CMPF                              ;AND GO AGAIN
CSYNT
        LDY     TXTPTR                            ;POINT TO TEXT
        LBRA    SYNTAX
;*
;* EXTRACT OPERATOR
;*
REDUC
        CMPA    #'/'                              ;EXTRACT?
        LBNE    DYADIC                            ;NO, TRY DYADIC FUNCTIONS
        PSHS    X,U                               ;SAVE REGISTERS
        LBSR    GETPRM                            ;GET PARAMETER
        LDU     ,S                                ;GET POINTER BACK
        LDA     ,X+                               ;GET TYPE OF OPERAND?
        LBEQ    CDOM                              ;DOMAIN ERROR IF CHARACTER
        CLRA
        CLRB                                      ;	GET A ZERO
        STD     TEMP                              ;CLEAR LENGTH SAVER
        LDD     ,X++                              ;GET LENGTH
        PSHS    Y                                 ;SAVE Y POINTER
        CMPD    1,U                               ;IS LENGTH THE SAME?
        LEAU    3,U                               ;SKIP TO DATA
        TFR     U,Y                               ;SAVE FOR LATER
        BNE     RED1                              ;NO, TRY SCALER OPERATION
        ADDD    #1                                ;ADVANCE
        TST     -3,U                              ;CHARACTER?
        BEQ     RED5                              ;DO IT FOR CHARACTER
RED2
        SUBD    #1                                ;DEC. COUNT
        BEQ     RED3                              ;SAVE
        PSHS    A,B                               ;SAVE
        LDD     ,X++                              ;TEST FOR NUMBER
        BEQ     RED4                              ;DON'T INCLUDE THIS ELEMENT
        LDD     ,U                                ;GET ELEMENT
        STD     ,Y++                              ;SAVE IN OUTPUT
        LDD     TEMP                              ;GET LENGTH
        ADDD    #1                                ;ADVANCE
        STD     TEMP                              ;RESAVE
RED4
        PULS    A,B                               ;RESTORE
        LEAU    2,U                               ;ADVANCE
        BRA     RED2                              ;RESAVE
RED3
        LDD     TEMP                              ;GET LENGTH
        BRA     RED9                              ;SET LENGTH
RED1
        CMPD    #1                                ;TEST FOR LENGTH 1?
        LBNE    CLEN                              ;INVALID
        LDD     ,X                                ;GET VALUE
        BNE     RED8                              ;WORKED
        CLRA
        CLRB                                      ;	ZERO LENGTH
RED9
        PULS    Y                                 ;RESTORE POINTER
        PULS    X,U                               ;AND REGISTERS
        STD     1,X                               ;SET LENGTH
        LBRA    NXTOPR
RED8
        PULS    Y                                 ;RESTORE Y
        PULS    X,U                               ;RESTORE POINTERS
        LBRA    NXTOPR
RED5
        SUBD    #1                                ;DEC. COUNT
        BEQ     RED3                              ;SAVE
        PSHS    A,B                               ;SAVE ACC
        LDD     ,X++                              ;TEST FOR NUMBER
        BEQ     RED6                              ;DON'T INCLUDE THIS ELEMENT
        LDA     ,U                                ;GET ELEMENT
        STA     ,Y+                               ;SAVE IN OUTPUT
        LDD     TEMP                              ;GET LENGTH
        ADDD    #1                                ;ADVANCE
        STD     TEMP                              ;RESAVE
RED6
        PULS    A,B                               ;RESTORE
        LEAU    1,U                               ;ADVANCE
        BRA     RED5                              ;RESAVE
;*
;* DYADIC OPERATORS
;*
DYADIC
        CMPA    #';'                              ;IS IT JOIN?
        BNE     SEARCH                            ;NO, TRY NEXT
        PSHS    X,Y,U                             ;SAVE REGISTERS
        LBSR    GETPRM                            ;GET OPERAND VALUE
        STY     2,S                               ;SAVE NEW TEXT POSITION
        LDU     ,S                                ;GET OLD OPERAND LOCATION
        LDA     ,U+                               ;GET TYPE FOR OLD OPERAND
        CMPA    ,X+                               ;TEST AGAIN OTHER OPERAND TYPE
        LBNE    CDOM                              ;MISMATCHED, ERROR
        LDD     ,X++                              ;GET LENGTH OF NEW OPERAND
        BEQ     CON1                              ;IF ZERO, IT'S OK
        PSHS    A,B                               ;SAVE LENGTH
        ADDD    ,U                                ;ADD TO OLD OPERAND LENGTH
        LDY     ,U                                ;GET OLD LENGTH
        STD     ,U++                              ;SAVE NEW LENGTH VALUE
        TFR     Y,D                               ;PUT OLD LENGTH IN D
        PULS    Y                                 ;GET NEW LENGTH IN Y
        TST     -3,U                              ;CHECK FOR CHARACTER DATA
        BEQ     CON3                              ;IT'S CHARACTER
        LSLB
        ROLA                                      ;	DOUBLE FOR WORD ELEMENTS
        LEAU    D,U                               ;OFFSET TO NEW LOCATION
CON2
        LDD     ,X++                              ;GET ELEMENT FROM OLD OPERAND
        STD     ,U++                              ;SAVE IN NEW OPERAND
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     CON2                              ;GO AGAIN
CON1
        PULS    X,Y,U                             ;RESTORE REGISTERS
        LBRA    NXTOPR
CON3
        LEAU    D,U                               ;SKIP TO END OF CHARACTER ARRAY
CON4
        LDA     ,X+                               ;GET CHARACTER FROM OLD
        STA     ,U+                               ;SAVE IN NEW
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     CON4                              ;GO AGAIN
        BRA     CON1                              ;AND GO HOME
;* FIND SUBSTRING
SEARCH
        CMPA    #'f'                              ;IS IT SEARCH?
        LBNE    ADROP                             ;NO, TRY EQUALS TEST
        PSHS    X,U                               ;SAVE REGS
        LBSR    GETPRM                            ;GET PARAMETER VALUE
        LDU     ,S                                ;GET OLD OPERAND POINTER BACK
        LDA     ,X                                ;GET TYPE
        CMPA    ,U+                               ;IS IT SAME?
        LBNE    CDOM                              ;NO, ERROR
        STA     TEMP1                             ;SAVE FOR LATER REF
        PSHS    Y                                 ;SAVE TEXT POINTER
        LDD     ,U++                              ;GET LENGTH OF STRING WE LOOK FOR
        LBEQ    CLEN                              ;INDICATE INVALID LENGTH
        LDY     1,X                               ;GET LENGTH OF SOURCE STRING
        STY     TEMP2                             ;SAVE FOR LATER REF
        LBSR    CALLEN                            ;GET LENGTH
        LEAX    D,X                               ;ADVANCE TO NEXT
        EXG     X,U                               ;SWAP
        STX     TEMP                              ;SAVE BACKUP POSITION
        LEAX    -3,X                              ;BACKUP TO START
        LBSR    CALLEN                            ;CALCULATE LENGTH
        LEAX    D,X                               ;SKIP TO END
        PSHS    X                                 ;SAVE POINTER
        LEAY    1,Y                               ;ADVANCE FOR DEC
        TST     TEMP1                             ;CHARACTER VALUES?
        BEQ     SER1                              ;LOOK FOR CHARACTER STRING
SER2
        LEAY    -1,Y                              ;BACKUP
        BEQ     SER7                              ;GO FOR IT
        LDD     ,--U                              ;GET VALUE FROM SOURCE
        CMPD    ,--X                              ;MATCH?
        BEQ     SER3                              ;OK
        LDX     ,S                                ;RESTORE POINTER
        BRA     SER2
SER3
        CMPX    TEMP                              ;HAVE WE REACHED END?
        BNE     SER2                              ;NO, WE ARE STILL HERE
SER5
        TFR     Y,D                               ;GET VALUE
        LDX     TEMP                              ;POINT TO DATA SPACE
        ADDD    -2,X                              ;BACKUP TO FIRST CHARACTER OF SUBSTRING
        PSHS    A,B                               ;SAVE
        LDD     TEMP2                             ;GET LENGTH
        SUBD    ,S++                              ;AND CALCULATE FINAL VALUE
        ADDD    #1                                ;CONVERT TO PROPER OFFSET
SER8
        ADDD    ORIGIN                            ;AND OFFSET FOR ORIGIN VALUE
        PULS    U                                 ;RESTORE POINTER
        PULS    Y                                 ;RESTORE Y POINTER
        PULS    X,U                               ;RESTORE X POINTER
        STD     3,X                               ;SAVE VALUE
        LDD     #1                                ;LENGTH/TYPE=1
        STB     ,X                                ;SET TYPE
        STD     1,X                               ;SET LENGTH
        LBRA    NXTOPR                            ;GET NEXT OPERAND
SER7
        LDD     TEMP2                             ;GET OPERAND LENGTH
        BRA     SER8
SER1
        LEAY    -1,Y                              ;BACKUP
        BEQ     SER7                              ;GO FOR IT
        LDA     ,-U                               ;GET VALUE FROM SOURCE
        CMPA    ,-X                               ;MATCH?
        BEQ     SER6                              ;OK
        LDX     ,S                                ;RESTORE POINTER
        BRA     SER1
SER6
        CMPX    TEMP                              ;HAVE WE REACHED END?
        BNE     SER1                              ;NO, WE ARE STILL HERE
        BRA     SER5                              ;GO HOME
;* DROP ELEMENTS FROM START OF VECTOR
ADROP
        CMPA    #'d'                              ;DROP?
        BNE     TAKE                              ;NO, TRY NEXT
        PSHS    X,U                               ;SAVE REGISTERS
        LBSR    GETPRM                            ;GET FORWARD PARAMETER
        LDU     ,S                                ;RESTORE REGISTERS
        LDA     ,X+                               ;GET TYPE
        LBEQ    CDOM                              ;INDICATE DOMAIN ERROR
        LDD     ,X++                              ;GET LENGTH
        CMPD    #1                                ;INSURE LENGTH OF ONE
        LBNE    CLEN                              ;INDICATE BAD LENGTH
        LEAU    1,U                               ;SKIP TYPE
        LDD     ,U                                ;GET LENGTH
        SUBD    ,X                                ;PERFORM DROP
        BCC     DRP1                              ;ALL IS OK
        CLRA
        CLRB                                      ;	SET LENGTH TO ZERO
DRP1
        STD     ,U                                ;SET NEW LENGTH,
        PULS    X,U                               ;RESTORE REGISTERS
        LBRA    NXTOPR                            ;GET NEXT OPERATOR
;* TAKE A NUMBER OF ELEMENTS FROM THE START OF A STRUCTURE
TAKE
        CMPA    #'t'                              ;TAKE?
        BNE     MEMBER                            ;NO, TRY SOMETING ELSE
        PSHS    X,U                               ;SAVE REGISTERS
        LBSR    GETPRM                            ;GET PARAMETER
        PULS    U                                 ;GET POINTER TO OLD
        LDA     ,X+                               ;GET TYPE OF NEW
        LBEQ    CDOM                              ;INDICATE INVALID
        LDD     ,X++                              ;GET LENGTH?
        CMPD    #1                                ;IS IT ONE?
        LBNE    CLEN                              ;INDICATE LENGTH ERROR
        PSHS    Y                                 ;SAVE TEXT POINTER
        LDY     ,X++                              ;GET REQUESTED LENGTH
        TFR     U,X                               ;COPY TO X
        LEAU    3,U                               ;ADVANCE TO DATA SPACE
        STU     TEMP                              ;SAVE
        LDU     FREE                              ;GET POINTER TO FREE SPACE
        STY     1,U                               ;SAVE LENGTH
        LDA     ,X                                ;GET TYPE OF OLD
        STA     ,U                                ;AND SAVE
        PSHS    A                                 ;SAVE ON STACK
        LBSR    CALLEN                            ;CALCULATE LENGTH
        LEAX    D,X                               ;SKIP TO END
        EXG     X,U                               ;SWAP
        LBSR    CALLEN                            ;LENGTH OF NEW
        LEAX    D,X                               ;SKIP TO END
        LEAY    1,Y                               ;ADVANCE
        TST     ,S+                               ;CHECK TYPE
        BEQ     TAK4                              ;TAKEING A CHARACTER
TAK1
        CMPU    TEMP
        BLS     TAK12
        LEAY    -1,Y                              ;BACKUP
        BEQ     TAK2                              ;END, QUIT
        LDD     ,--U                              ;GET FROM OLD
        STD     ,--X                              ;SAVE IN NEW
        BRA     TAK1
TAK12
        CLRA
        CLRB                                      ;	START WITH ZERO
TAK3
        LEAY    -1,Y                              ;BACKUP
        BEQ     TAK2                              ;EXIT IF END
        STD     ,--X                              ;RESAVE
        BRA     TAK3                              ;GO AGAIN
TAK2
        PULS    Y,U                               ;RESTORE TEXT POINTER
        LDX     FREE                              ;POINT TO NEW VALUE
        LBRA    NXTOPR                            ;GO AGAIN
TAK4
        CMPU    TEMP
        BLS     TAK41
        LEAY    -1,Y                              ;BACKUP
        BEQ     TAK2                              ;END, QUIT
        LDA     ,-U                               ;GET FROM OLD
        STA     ,-X                               ;SAVE IN NEW
        BRA     TAK4                              ;NO, IT'S OK
TAK41
        LDA     #' '                              ;GET SPACE
TAK5
        LEAY    -1,Y                              ;BACKUP
        BEQ     TAK2                              ;EXIT IF END
        STA     ,-X                               ;RESAVE
        BRA     TAK5                              ;GO AGAIN
;* MEMBER, DETERMINE IF EACH ELEMENT IS A MEMBER OF THE OTHER SET
MEMBER
        CMPA    #'u'                              ;MEMBER OPERATOR?
        BNE     XLATE                             ;NO, TRY TRANSLATE
        PSHS    X,U                               ;SAVE REGS
        LBSR    GETPRM                            ;GET PARAMETER
        PULS    U                                 ;GET REGISTER
        PSHS    Y                                 ;SAVE REGISTERS
        LDA     ,U+                               ;GET TYPE OF FIRST
        CMPA    ,X+                               ;SAME AS SECOND?
        LBNE    CDOM                              ;NO, GET UPSET
        LDD     FREE                              ;GET FREE POINTER
        ADDD    BUFSIZ                            ;GET SECOND BUFFER
        TFR     D,Y                               ;POINT U AT IT
        PSHS    A,B                               ;SAVE IT
        LDA     #1                                ;INTEGER
        STA     ,Y+                               ;SET TYPE
        LDD     ,X++                              ;GET LENGTH OF RIGHT OPERATOR
        STD     ,Y++                              ;SAVE IT
        BEQ     MEMEND                            ;SPECIAL CASE, QUIT
        TST     -3,X                              ;IS IT CHARACTER?
        BEQ     MEMCHR                            ;IF SO, DO IT FOR CHARACTERS
MEMLP
        PSHS    A,B,Y,U                           ;SAVE REGS
        LDD     ,X++                              ;GET ELEMENT WE ARE TESTING
        LDY     ,U++                              ;GET LENGTH OF LEFT OPERAND
        BEQ     MEML0                             ;DOES NOT EXIST
MEMLX
        CMPD    ,U++                              ;DUZ IT MATCH
        BEQ     MEML1                             ;OK
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     MEMLX                             ;CONTINUE
MEML0
        CLRB
        BRA     MEML2                             ;CONTINUE
MEML1
        LDB     #1                                ;INDICATE FOUND
MEML2
        CLRA                                      ;	ZERO HIGH BYTE
        LDY     2,S                               ;GET POINTER
        STD     ,Y                                ;SAVE
        PULS    A,B,Y,U                           ;RESTORE REGS
        LEAY    2,Y                               ;ADVANCE
        SUBD    #1                                ;MORE ELEMENTS
        BNE     MEMLP                             ;CONTINUE
        BRA     MEMEND
MEMCHR
        PSHS    A,B,Y,U                           ;SAVE REGS
        LDA     ,X+                               ;GET ELEMENT WE ARE TESTING
        LDY     ,U++                              ;GET LENGTH OF LEFT OPERAND
        BEQ     MEMC0                             ;DOES NOT EXIST
MEMCX
        CMPA    ,U+                               ;DOS IT MATCH
        BEQ     MEMC1                             ;OK
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     MEMCX                             ;CONTINUE
MEMC0
        CLRB
        BRA     MEMC2                             ;CONTINUE
MEMC1
        LDB     #1                                ;INDICATE FOUND
MEMC2
        CLRA                                      ;	ZERO HIGH BYTE
        LDY     2,S                               ;GET POINTER
        STD     ,Y                                ;SAVE
        PULS    A,B,Y,U                           ;RESTORE REGS
        LEAY    2,Y                               ;ADVANCE
        SUBD    #1                                ;MORE ELEMENTS
        BNE     MEMCHR                            ;CONTINUE
MEMEND
        PULS    X,Y,U                             ;RESTORE REGS
        LBRA    NXTOPR                            ;CONTINUE
;* TRANSLATE TABLE LOOKUP
XLATE
        CMPA    #'n'                              ;TRANSLATE OPERATOR?
        LBNE    OPSYS                             ;NO, TRY OPSYS
        PSHS    X,U                               ;SAVE REGS
        LBSR    GETPRM                            ;GET PARAMETER
        PULS    U                                 ;GET REGISTER
        PSHS    Y                                 ;SAVE REGISTERS
        LDA     ,U+                               ;GET TYPE OF FIRST
        CMPA    ,X+                               ;SAME AS SECOND?
        LBNE    CDOM                              ;NO, GET UPSET
        LDD     FREE                              ;GET FREE POINTER
        ADDD    BUFSIZ                            ;GET SECOND BUFFER
        TFR     D,Y                               ;POINT U AT IT
        PSHS    A,B                               ;SAVE IT
        LDA     #1                                ;INTEGER
        STA     ,Y+                               ;SET TYPE
        LDD     ,U++                              ;GET LENGTH OF RIGHT OPERATOR
        STD     ,Y++                              ;SAVE IT
        BEQ     XLAEND                            ;SPECIAL CASE, QUIT
        TST     -1,X                              ;IS IT CHARACTER?
        BEQ     XLACHR                            ;IF SO, DO IT FOR CHARACTERS
XLALP
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDD     ,U++                              ;GET ELEMENT WE ARE TESTING
        LDY     ,X++                              ;GET LENGTH OF LEFT OPERAND
        BEQ     XLAL0                             ;DOES NOT EXIST
XLALX
        CMPD    ,X++                              ;DUZ IT MATCH
        BEQ     XLAL1                             ;OK
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     XLALX                             ;CONTINUE
XLAL0
        LDY     [2,S]                             ;POINT TO END
        LEAY    1,Y                               ;ADVANCE PAST END
XLAL1
        LEAY    -1,Y                              ;BACKUP TO ORIGIN ZERO
        TFR     Y,D                               ;COPY
        ADDD    ORIGIN                            ;OFFSET
        LDY     4,S                               ;GET POINTER
        STD     ,Y                                ;SAVE
        PULS    A,B,X,Y                           ;RESTORE REGS
        LEAY    2,Y                               ;ADVANCE
        SUBD    #1                                ;MORE ELEMENTS
        BNE     XLALP                             ;CONTINUE
        BRA     XLAEND
XLACHR
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDA     ,U+                               ;GET ELEMENT WE ARE TESTING
        LDY     ,X++                              ;GET LENGTH OF LEFT OPERAND
        BEQ     XLAC0                             ;DOES NOT EXIST
XLACX
        CMPA    ,X+                               ;DOS IT MATCH
        BEQ     XLAC1                             ;OK
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     XLACX                             ;CONTINUE
XLAC0
        LDY     [2,S]                             ;GET HIGHEST VALIE
        LEAY    1,Y                               ;BACKUP TO ORIGIN ZERO
XLAC1
        LEAY    -1,Y                              ;ADVANCE
        TFR     Y,D                               ;COPY TO D
        ADDD    ORIGIN                            ;CONVERT
        LDY     4,S                               ;GET POINTER
        STD     ,Y                                ;SAVE
        PULS    A,B,X,Y                           ;RESTORE REGS
        LEAY    2,Y                               ;ADVANCE
        SUBD    #1                                ;MORE ELEMENTS
        BNE     XLACHR                            ;CONTINUE
XLAEND
        PULS    X,Y,U                             ;RESTORE REGS
        LBRA    NXTOPR                            ;CONTINUE
;* OPERATING SYSTEM INTERFACE
OPSYS
        CMPA    #'o'                              ;OPERATING SYSTEM INTERFACE?
        BNE     EQUTST                            ;NO, TRY EQUALITY TEST
        PSHS    X,Y,U                             ;SAVE OPERAND POINTER
        LBSR    GETPRM                            ;GET PARAMETER
        STY     2,S                               ;RESET LINE PTR
        LDY     ,S                                ;'Y' POINTS TO FIRST
        LBSR    OSFUNC                            ;EXECUTE OS FUNCTION
        PULS    X,Y,U                             ;RESTORE ALL REGS
        LBRA    NXTOPR                            ;AND GET NEXT OPERATOR
;* EQUALS AND ASSOCIATED FUNCTIONS
EQUTST
        CMPA    #'='                              ;EQUALS?
        LBNE    DYFNS                             ;NO, SKIP IT
        PSHS    X,U                               ;SAVE U REGISTER
        LDA     ,Y                                ;GET NEXT OPERAND
        LEAY    -1,Y                              ;BACKUP
        LDU     #DYGE                             ;INDICATE GREATER/EQUALS
        CMPA    #'>'                              ;TEST FOR GE
        BEQ     DODYA1                            ;DO IT
        LDU     #DYLE                             ;TEST FOR LT
        CMPA    #'<'                              ;IS THIS IT?
        BEQ     DODYA1                            ;IF SO, DO IT
        LDU     #DYEQ                             ;POINT AT HANDLER
        CMPA    #'='                              ;EQUALS
        BNE     EQU1                              ;NOT IT
        TST     ,X                                ;IS IT NUMERIC?
        BEQ     CEQU                              ;IT'S CHARACTER
DODYA1
        LBRA    DODYA                             ;GO FOR IT
;* CHARACTER EQUALITY TEST
EQU1
        LDU     #DYNE                             ;POINT AT IT
        CMPA    #'-'                              ;IS THIS IT?
        BNE     EQU9                              ;MUST BE ASSIGNMENT
        TST     ,X                                ;IS THIS IT?
        BNE     DODYA1                            ;GO FOR IT
CEQU
        LDU     #DCEQU                            ;POINT TO EQUALS
        CMPA    #'='                              ;IS IT EQUALS
        BEQ     CEQ2                              ;IT'S OK
        LDU     #DCNEQ                            ;POINT TO NOT EQUALS
CEQ2
        STU     TEMP2                             ;SAVE POINTER
        LBSR    GETPRM                            ;GET SECOND OPERAND
        TST     ,X+                               ;TEST FOR TYPE
        LBNE    CDOM                              ;INVALID
        LDU     ,S                                ;POINT TO OLD PARM
        LEAU    1,U                               ;SKIP TYPE
        LDD     ,X++                              ;GET LENGTH
        CMPD    ,U++                              ;ARE THEY THE SAME?
        BNE     CEQU1                             ;NO, TRY SCALAR COMPARISIONS
        ADDD    #1                                ;ADVANCE FOR LATER DEC
CEQ1
        SUBD    #1                                ;BACKUP
        BEQ     CEQ3                              ;END, GET OUT
        PSHS    A                                 ;SAVE REGISTERS
        JSR     [TEMP2]                           ;PERFORM IT
        LEAX    1,X                               ;NEXT
        PULS    A                                 ;GET THEM BACK
        BRA     CEQ1                              ;AND DO IT
CEQU1
        CMPD    #1                                ;IS THIS A SCALAR?
        BNE     CEQU2                             ;NO, TRY NEXT
        LDD     -2,U                              ;GET LENGTH BACK
        ADDD    #1                                ;ADVANCE FOR LATER DEC
CEQ4
        SUBD    #1                                ;DEC
        BEQ     CEQ3                              ;GET OUT
        PSHS    A                                 ;SAVE IT
        JSR     [TEMP2]                           ;DO IT
        PULS    A                                 ;RESTORE
        BRA     CEQ4                              ;GO AGAIN
CEQU2
        LDD     -2,U                              ;GET IT
        CMPD    #1                                ;IS THIS IT?
        LBNE    CLEN                              ;GET REAL
        LDD     -2,X                              ;GET LENGTH BACK
        STD     -2,U                              ;SET OUTPUT LENGTH
        ADDD    #1                                ;ADVANCE
CEQ5
        SUBD    #1                                ;DECREMENT COUNTER
        BEQ     CEQ3                              ;QUIT IF DONE
        PSHS    A                                 ;SAVE REGSITER
        LDA     ,U                                ;GET VALUE
        STA     1,U                               ;AND SAVE ONE UP
        JSR     [TEMP2]                           ;DO IT
        LEAX    1,X                               ;NEXT
        PULS    A                                 ;RESTORE
        BRA     CEQ5                              ;DO IT AGAIN
;* ASSIGNMENT
EQU9
        PULS    X,U                               ;RESTORE REGISTERS
        LEAY    1,Y                               ;ADVANCE
        LBSR    SKBKP                             ;SKIP BACK
        LBSR    ASSIGN                            ;PERFORM ASSIGNMENT
        DEC     ASSFLG                            ;SET ASSIGNMENT FLAG
        LBRA    NXTOPR                            ;GET NEXT OPERATOR
;* SAVE OUTPUT VECTOR AND CONVERT TO INTEGER (WORDS)
CEQ3
        LDX     ,S                                ;GET POINTER TO OUTPUT
        PSHS    Y                                 ;SAVE POINTER
        LDY     1,X                               ;GET LENGTH
        LEAY    1,Y                               ;ADVANCE FOR LATER DEC
        LDA     #1                                ;GET TYPE
        STA     ,X                                ;SAVE TYPE
        LBSR    CALLEN                            ;GET LENGTH
        LEAX    D,X                               ;OFFSET
        CLRA                                      ;	CLEAR HIGH ORDER BYTE
CEQ6
        LEAY    -1,Y                              ;BACKUP
        BEQ     CEQ7                              ;IF END, GO HOME
        LDB     ,-U                               ;GET CHAR FROM OUTPUT
        STD     ,--X                              ;SAVE IN OUTPUT
        BRA     CEQ6                              ;AND GO AGAIN
CEQ7
        PULS    Y                                 ;RESTORE Y (AGAIN)
        PULS    X,U                               ;RESTORE REGSITERS
        LBRA    NXTOPR
;* CHARACTER EQUALS LOGIC
DCEQU
        LDA     ,X                                ;GET CHAR
        CMPA    ,U                                ;TEST FOR OK
        BNE     DCR0                              ;FALSE
DCR1
        LDA     #1                                ;GET ONE
        STA     ,U+
        RTS
;* CHARACTER NOT EQUALS LOGIC
DCNEQ
        LDA     ,X                                ;GET CHAR
        CMPA    ,U                                ;TEST FOR NOT EQUAL
        BNE     DCR1                              ;TRUE
DCR0
        CLRA                                      ;	FALSE
        STA     ,U+
        RTS
;* STANDARD DYADIC FUNCTONS
DYFNS
        PSHS    X,U                               ;SAVE U REG
        LDU     #DOTAB                            ;POINT TO TABLE
DOD1
        TST     ,U                                ;CHECK FOR END OF TABLE
        LBEQ    FUNVAL                            ;INVALID, QUIT
        CMPA    ,U+                               ;IS THIS IT?
        BEQ     DOD2                              ;YES, GRAB IT
        LEAU    2,U                               ;SKIP TO NEXT
        BRA     DOD1                              ;AND KEEP LOOKING
DOD2
        LDU     ,U                                ;GET HANDLER ADDRESS
DODYA
        LBSR    GETPRM                            ;GET PARAMETER VALUE
        STU     TEMP2                             ;SAVE HANDLER ADDRESS
        LDU     ,S                                ;GET OLD OPERAND VALUE
        LDA     ,X+                               ;GET TYPE
        LBEQ    CDOM                              ;NOT FOR CHARACTER VALUES
        LDA     ,U+                               ;TEST TYPE OF OTHER OPERAND
        LBEQ    CDOM                              ;CHARACTER STILL INVALID
        LDD     ,X++                              ;GET LENGTH
        CMPD    ,U++                              ;SAME AS OTHER?
        BNE     TSCALE                            ;NO, TRY SCALAR OPERATION
        ADDD    #1                                ;OFFSET FOR ZERO
ZX1
        SUBD    #1                                ;REDUCE COUNT
        BEQ     ZX2                               ;END, QUIT
        PSHS    A,B,X                             ;SAVE VALUES
        JSR     [TEMP2]                           ;PERFORM OPERATION
        PULS    A,B,X                             ;RESTORE REGISTERS
        LEAX    2,X                               ;ADVANCE IN NEW
        LEAU    2,U                               ;ADVANCE IN OLD
        BRA     ZX1                               ;GO AGAIN
ZX2
        PULS    X,U                               ;RESTORE REGISTERS
        LBRA    NXTOPR
TSCALE
        CMPD    #1                                ;TEST FOR SCALER OPERATION
        BNE     TSCAL2                            ;NO, TRY OTHER WAY
        LDD     -2,U                              ;GET LENGTH
        ADDD    #1                                ;ADD FOR LATER DEC
TSL2
        SUBD    #1                                ;REDUCE COUNT
        BEQ     ZX2                               ;END, QUIT
        PSHS    A,B,X                             ;SAVE REGISTERS
        JSR     [TEMP2]                           ;PERFORM OPERATION
        PULS    A,B,X                             ;RESTORE REGISTERS
        LEAU    2,U                               ;ADVANCE POINTER
        BRA     TSL2                              ;AND GO IT AGAIN
TSCAL2
        LDD     -2,U                              ;GET OTHER LENGTH
        CMPD    #1                                ;TEST FOR LENGTH ONE
        LBNE    CLEN                              ;INVALID LENGTHS
        LDD     -2,X                              ;GET LENGTH OF NEW OPERAND
        STD     -2,U                              ;SET LENGTH OR RESULT
        ADDD    #1                                ;ADVANCE FOR LATER DEC
TSC2
        SUBD    #1                                ;REDUCE COUNT
        BEQ     ZX2                               ;END, QUIT
        PSHS    A,B,X                             ;SAVE REGISTERS
        LDD     ,U                                ;GET VALUE
        STD     2,U                               ;SAVE LATER
        JSR     [TEMP2]                           ;PERFORM OPERATION
        PULS    A,B,X                             ;RESTORE REGISTERS
        LEAX    2,X                               ;ADVANCE IN NEW
        LEAU    2,U                               ;ADVANCE IN OLD
        BRA     TSC2                              ;AND CONTINUE
;*
;* DYADIC FUNCTION TABLE
;*
DOTAB
        FCC     '+'                               ;ADDITION
        FDB     DYADD
        FCC     '-'                               ;SUBTRACTON
        FDB     DYSUB
        FCC     'x'                               ;MULTIPLICATION
        FDB     DYMUL
        FCC     '%'                               ;DIVIDE
        FDB     DYDIV
        FCC     'g'                               ;GREATEST
        FDB     DYCEIL
        FCC     'l'                               ;LEAST
        FDB     DYFLOR
        FCC     '&'                               ;LOGICAL AND
        FDB     DYAND
        FCC     '!'                               ;LOGICAL OR
        FDB     DYOR
        FCC     'm'                               ;MODULUS
        FDB     DYMOD
        FCC     '>'                               ;GREATER THAN
        FDB     DYGT
        FCC     '<'                               ;LESS THAN
        FDB     DYLT
        FCC     '|'                               ;EXCLUSIVE OR
        FDB     DYXOR
        FCB     0
;* DYADIC FUNCTION ROUTINES
DYADD
        LDD     ,X                                ;GET NEW VALUE
        ADDD    ,U                                ;ADD OLD VALUE
        STD     ,U                                ;SAVE BACK
        RTS
DYSUB
        LDD     ,X                                ;GET NEW VALUE
        SUBD    ,U                                ;SUBTRACT OLD VALUE
        STD     ,U                                ;SAVE BACK
        RTS
DYMUL
        LDD     ,X                                ;GET NEW
        LDX     ,U                                ;GET OLD
        LBSR    MULT                              ;DO MULTIPLY
        STD     ,U                                ;RESAVE
        RTS
DYDIV
        LDD     ,U                                ;GET OLD
        LBEQ    CDOM                              ;INDICATE ERROR IF %0
        LDX     ,X                                ;GET NEW
        LBSR    DIV                               ;DO DIVISION
        STX     ,U                                ;SAVE RESULT
        STD     DIVREM                            ;SAVE REMAINDER
        RTS
DYMOD
        LDD     ,X                                ;GET NEW VALUE
        LBEQ    CDOM                              ;DIVISION BY ZERO
        LDX     ,U                                ;GET OLD VALUE
        LBSR    DIV                               ;DO DIVISION
        STD     ,U                                ;SAVE RESULT
        RTS
DYCEIL
        LDD     ,U                                ;GET OLD VALUE
        CMPD    ,X                                ;PERFORM TEST
        BHI     DYRTS                             ;OK, GO HOME
DYSWP
        LDD     ,X                                ;GET OTHER VALUE
        STD     ,U                                ;AND SAVE
DYRTS
        RTS
DYFLOR
        LDD     ,U                                ;GET OLD VALUE
        CMPD    ,X                                ;PERFORM TEST
        BLO     DYRTS                             ;OK, GO HOME
        BRA     DYSWP                             ;SWAP
DYAND
        LDD     ,U                                ;GET OLD
        ANDA    ,X                                ;AND HIGH BYTE
        ANDB    1,X                               ;AND LOW BYTE
        STD     ,U                                ;RESAVE
        RTS
DYOR
        LDD     ,U                                ;GET OLD
        ORA     ,X                                ;OR HIGH BYTE
        ORB     1,X                               ;OR LOW BYTE
        STD     ,U                                ;SAVE RESULT
        RTS
DYXOR
        LDD     ,U                                ;GET OLD
        EORA    ,X                                ;XOR HIGH BYTE
        EORB    1,X                               ;XOR LOW BYTE
        STD     ,U                                ;RESAVE
        RTS
DYGT
        LDD     ,X                                ;GET NEW
        CMPD    ,U                                ;TEST AGAINST OLD
        BHI     RET1                              ;ITS TRUE
        BRA     RET0
DYLT
        LDD     ,X                                ;GET NEW
        CMPD    ,U                                ;TEST AGAINST OLD
        BLO     RET1                              ;TRUE
        BRA     RET0                              ;FALES
DYGE
        LDD     ,X                                ;GET NEW
        CMPD    ,U                                ;TEST AGAINST OLD
        BHS     RET1                              ;OK
RET0
        CLRB
        BRA     RETX
DYLE
        LDD     ,X                                ;GET NEW
        CMPD    ,U                                ;TEST AGAINST OLD
        BHI     RET0                              ;FALSE
RET1
        LDB     #1                                ;TRUE
RETX
        CLRA                                      ;	CLEAR HIGH BYTE,
        STD     ,U                                ;SAVE VALUE
        RTS
DYEQ
        LDD     ,X                                ;GET NEW
        CMPD    ,U                                ;TEST AGAINAT OLD
        BEQ     RET1                              ;OK
        BNE     RET0                              ;FALSE
DYNE
        LDD     ,X                                ;GET NEW
        CMPD    ,U                                ;TEST AGAINST OLD
        BEQ     RET0                              ;FALSE
        BRA     RET1                              ;TRUE
;* EXECUTE FUNCTION WITH A VALUE
FUNVAL
        PULS    X,U                               ;RESTORE STACK
        STX     TEMP                              ;SAVE PARAMETER ADDRESS
        LEAY    1,Y                               ;BACK FOR FUNCTION NAME
        LBSR    LOOKUP                            ;LOOK FOR IT
        CMPA    #2                                ;IS IT A FUNCTION
        LBHS    CSYNT                             ;SYNTAX ERROR
        LBSR    FUNC                              ;PERFORM FUNCTION
        LBRA    NXTOPR                            ;GET NEXT OPERATOR
;*
;* DISPLAYS VALUE OF A STRUCTURE (X)
;*
DISPLY
        PSHS    X,U                               ;SAVE VARIABLES
        LDA     ,X+                               ;GET TYPE
        BEQ     CHROUT                            ;IT'S CHARACTER DATA
        LDD     ,X++                              ;GET LENGTH
        BEQ     NULOUT                            ;NOTHING TO OUTPUT
        PSHS    D                                 ;SAVE TEMP
        ADDD    ,S                                ;DOUBLE FOR INTEGERS
        LEAU    D,X                               ;SKIP TO END
        PULS    X                                 ;GET # ELEMENTS IN X
DIS1
        LDD     ,--U                              ;GET VALUE
        BSR     DECOUT                            ;OUTPUT
        LBSR    SPACE                             ;DISPLAY SPACE
        LEAX    -1,X                              ;REDUCE COUNT
        BNE     DIS1                              ;AND CONTINUE
        BRA     NULOUT                            ;GO AWAY
CHROUT
        LDD     ,X++                              ;GET LENGTH
        BEQ     NULOUT                            ;NULL STRING
        LEAU    D,X                               ;SKIP TO END
        TFR     D,X                               ;COPY TO X
DIS2
        LDA     ,-U                               ;GET CHARACTER
        LBSR    PUTCHR                            ;OUTPUT
        LEAX    -1,X                              ;REDUCE LENGTH,
        BNE     DIS2                              ;KEEP GOING
NULOUT
        PULS    X,U,PC                            ;BACK TO WORK
;*
;* DISPLAY NUMBER (D) IN DECIMAL
;*
DECOUT
        PSHS    X,Y
        TFR     D,X                               ;COPY
        LDY     #0                                ;START WITH ZERO CHARS
DEC1
        LDD     #10                               ;DIVIDE BY 10
        LBSR    DIV                               ;PERFORM DIVISION
        PSHS    B                                 ;SAVE IT
        LEAY    1,Y                               ;ADVANCE
        CMPX    #0                                ;OVER YET?
        BNE     DEC1                              ;NO, KEEP GOING
DEC2
        PULS    A                                 ;GET CHAR BACK
        ORA     #$30                              ;CONVERT TO DISPLAYABLE
        LBSR    PUTCHR                            ;OUTPUT IT
        LEAY    -1,Y                              ;REDUCE COUNT OF CHARACTERS
        BNE     DEC2                              ;AND CONTINUE
        PULS    X,Y,PC
;*
;* GETS A VALUE FOR THE WORKSPACE (,X)
;*
GETPRM
        LDX     FREE                              ;POINT TO FREE SPACE
        STY     TXTPTR                            ;SAVE TEXT POSITION
        BSR     GETVAL                            ;GET VALUE
        LBNE    CSYNT                             ;IF NONE, PROCLAIM ERROR
        RTS
GETVAL
        PSHS    X,U                               ;SAVE REGSITERS
        LBSR    SKBKP                             ;BACKUP
        CMPA    #')'                              ;EXPRESSION
        BNE     GETV0                             ;NO, CONTINUE
        LBSR    DOEXPR                            ;DO EXPRESSION
        CMPA    #'('                              ;CLOSED PROPERLY?
        LBNE    SYNTAX                            ;INDICATE INVALID
        STX     ,S                                ;SAVE OUTPUT ADDRESS
        LBSR    SKBK                              ;BACKUP
        BRA     NV1                               ;GO AGAIN
GETV0
        CMPA    #']'                              ;IS IT INDEX?
        LBNE    GETN0                             ;NO, EVERYTHING IS OK
;* LOOK UP INDEX VALUE
        LBSR    DOEXPR                            ;GET VALUE
        CMPA    #'['                              ;CLOSE PROPERLY
        LBNE    SYNTAX                            ;INVALID SYNTAX
        LDA     ,X                                ;GET TYPE
        CMPA    #1                                ;IS IT INTEGER?
        LBNE    DOMAIN                            ;INDICATE DOMAIN ERROR
        LBSR    SKBK                              ;BACKUP
        STX     ,S                                ;SAVE POINTER TO ENTRY
        LDD     TEMP5                             ;GET BUFFER ADDRESS
        SUBD    BUFSIZ                            ;ALLOCATE ANOTHER BUFFER
        STD     TEMP5                             ;RESAVE
        LBSR    GETPRM                            ;GET VALUE
        LDD     TEMP5                             ;GET BUFFER ADDRESS
        ADDD    BUFSIZ                            ;RELEASE BUFFER
        STD     TEMP5                             ;RESAVE
        LDU     ,S                                ;GET ORIG. PARM BACK
        LDD     1,X                               ;GET LENGTH
        SUBD    #1                                ;CONVERT TO OFFSET FROM ZERO
        STD     TEMP4                             ;SAVE FOR REF
        LDA     ,X                                ;GET ARG. TYPE
        LEAX    3,X                               ;SKIP TO DATA
        STA     ,U+                               ;SET DEST TYPE
        BEQ     CHRI                              ;CHARACTER INDEX
        LDD     ,U++                              ;GET LENGTH
NUMI
        PSHS    A,B                               ;SAVE
        LDD     ,U                                ;GET INDEX VALUE
        SUBD    ORIGIN                            ;SUBTRACT ORIGIN VALUE
        PSHS    A,B                               ;SAVE VALUE ON STACK
        LDD     TEMP4                             ;GET VALUE
        SUBD    ,S++                              ;CONVERT TO PROPER OFFSET
        LBCS    INDEX                             ;INDICATE INDEX ERROR
        LSLB
        ROLA                                      ;	DOUBLE FOR TWO BYTE ENTRIES
        LDD     D,X                               ;GET OPERAND
        STD     ,U++                              ;SAVE IN OUTPUT
        PULS    A,B                               ;GET LENGTH BACK
        SUBD    #1                                ;REDUCE
        BNE     NUMI                              ;AND KEEP GOING
NV1
        ORCC    #4                                ;SET Z FLAG
        PULS    X,U,PC                            ;GO HOME
CHRI
        LDD     ,U++                              ;SAVE VALUE
        STY     TXTPTR                            ;SAVE TEXT POINTER
        TFR     U,Y                               ;POINT TO CHARACTER SPACE
CHRI1
        PSHS    A,B                               ;SAVE
        LDD     ,U++                              ;GET INDEX VALUE
        SUBD    ORIGIN                            ;SUBTRACT ORIGIN VALUE
        PSHS    A,B                               ;SAVE VALUE ON STACK
        LDD     TEMP4                             ;GET VALUE
        SUBD    ,S++                              ;CONVERT TO PROPER OFFSET
        BCS     CIDX                              ;INDICATE INDEX ERROR
        LDA     D,X                               ;GET OPERAND
        STA     ,Y+                               ;SAVE IN OUTPUT
        PULS    A,B                               ;GET LENGTH BACK
        SUBD    #1                                ;REDUCE
        BNE     CHRI1                             ;AND KEEP GOING
        LDY     TXTPTR                            ;GI IT AGAIN
        BRA     NV1
CIDX
        LDY     TXTPTR                            ;GET TEXT POINTER AGAIN
        LBRA    INDEX                             ;GET UPSET
;* TEST FOR NUMBER
GETN0
        LBSR    VALNUM                            ;IS IT A NUMBER?
        BNE     GETV1                             ;NO, TRY STRING
        LDA     #1                                ;INDICATE ONE VARIABLE
        STA     ,X                                ;SET TYPE
        LEAX    3,X                               ;SKIP POSITION
        LDU     #0                                ;START WITH ZERO ELEMENTS
GETN1
        LBSR    SKBKP                             ;LOOK FOR NUMBER
        LBSR    VALNUM                            ;VALID NUMBER?
        BNE     GETV9                             ;LAST NUMBER
        LEAU    1,U                               ;ADVANCE
        LBSR    GETDEC                            ;GET A NUMBER
        STD     ,X++                              ;SAVE VALUE
        BRA     GETN1                             ;AND TRY AGAIN
GETV1
        CMPA    #$27                              ;IS IT A CHARACTER VALUE?
        BNE     GETV2                             ;NO, TRY NEXT
;* GETS A CHARACTER VALUE FOR THE WORKSPACE
        CLR     ,X                                ;INDICATE CHARACTER DATA
        LEAX    3,X                               ;SKIP FOR NOW
        LDU     #0                                ;START WITH ZERO CHARACTER
GETC2
        LDA     ,-Y                               ;GET NEXT CHARACTER
        CMPA    #$27                              ;CLOSING QUOTE?
        BEQ     GETC3                             ;IF SO, QUIT
        CMPA    #$0D                              ;END OF LINE?
        LBEQ    SYNTAX                            ;INDICATE ERROR
GETC5
        LEAU    1,U                               ;INC. NUMBER OF CHARACTERS IN STRING
        STA     ,X+                               ;SAVE IN OUTPUT VALUE
        BRA     GETC2                             ;NO TRY FOR ANOTHER
GETC3
        LDA     -1,Y                              ;GET PRECEDING CHAR
        CMPA    #$27                              ;QUOTE?
        BNE     GETC4                             ;NO, TERMINATE
        LDA     ,-Y                               ;GET CHARACTER
        BRA     GETC5
GETC4
        LBSR    SKBK                              ;ADVANCE BACKWARDS
GETV9
        LDX     ,S                                ;GET OFFSET
        STU     1,X                               ;SAVE SIZE
        ORCC    #4                                ;SET Z FLAG
        PULS    X,U,PC                            ;BACKUP AND RETURN
;* TEST FOR SYSTEM VARIABLE
GETV2
        CMPA    #'$'                              ;SYS VAR?
        BNE     GETV3                             ;NO, TRY SYMBOL
        LDB     #1                                ;GET TYPE, INTEGER
        STB     ,X+                               ;SAVE IN RAM
        CLRA                                      ;	SET LENGTH TO 1
        STD     ,X++                              ;SAVE LENGTH
        LDA     ,-Y                               ;GET SYMBOL LENGTH
        CMPA    #'L'                              ;IS IT LINE NUMBER?
        BNE     SYS1                              ;NO, TRY ORIGIN
        LDD     LINCT                             ;GET COUNTER
        BRA     SYS9                              ;AND EXIT WITH IT
SYS1
        CMPA    #'O'                              ;ORIGIN?
        BNE     SYS2                              ;NO, TRY WSSIZE.
        LDD     ORIGIN                            ;GET ORIGIN VALUE
        BRA     SYS9                              ;AND EXIT
SYS2
        CMPA    #'W'                              ;IS IT WORKSPACE SIZE?
        BNE     SYS3                              ;NO, TRY DIV REM
        LDD     TEMP5                             ;GET FREE ADDRESS
        SUBD    FREE                              ;CONVERT TO SIMPLE OFFSET
        BRA     SYS9                              ;END EXIT
SYS3
        CMPA    #'R'                              ;REMAINDER?
        BNE     SYS4                              ;NO, TRY SEED
        LDD     DIVREM                            ;GET REMANDER
        BRA     SYS9                              ;AND EXIT
SYS4
        CMPA    #'S'                              ;SEED?
        BNE     ATOM                              ;NO, TRY ATOMIC VECTOR
        LDD     SEED                              ;GET SEED VALUE
        BRA     SYS9                              ;AND SAVE
ATOM
        CMPA    #'C'                              ;CHARACTER STRING?
        BNE     SY5                               ;NO, TRY NEXT
        CLR     -3,X                              ;INDICATE CHARACTER
        LDD     #256                              ;LENGTH OF IT
        STD     -2,X                              ;SET IT UP
        CLRA                                      ;	START WITH NULL
AV1
        DECA                                      ;	BACKUP THROUGH CHARACTER SET
        STA     ,X+                               ;SAVE IN VECTOR
        BNE     AV1                               ;KEEP GOING
        BRA     SYSX                              ;GO  HOME
SY5
        CMPA    #'B'                              ;BUFFER SIZE?
        BNE     SYSPRM                            ;NO, TRY PARM
        LDD     BUFSIZ                            ;GET BUFFER SIZE
SYS9
        STD     ,X                                ;SAVE VALUE
SYSX
        LBSR    SKBK                              ;SKIP BACK TO NEXT
        ORCC    #4                                ;SET Z FLAG
        PULS    X,U,PC                            ;AND GO HOME
;* LOOK FOR SYMBOL IN TABLE
GETV3
        LBSR    VALSYM                            ;IS IT A SYMBOL
        BNE     GETV4                             ;NOT VALID
        LDD     #IOTA0                            ;DEFAULT PARAMETER
        STD     TEMP                              ;SAVE
        LBSR    LOOKUP                            ;LOOK UP VALUE
        LBNE    VALUE                             ;INDICATE VALUE ERROR
        CMPA    #2                                ;IS IT A VARIABLE
        BNE     GETV5                             ;NO, TRY LABEL
        LDX     B,X                               ;POINT TO VARIABLE ENTRY
        BRA     GETV6                             ;GO FOR IT
GETV5
        CMPA    #3                                ;IS IT A LABEL?
        BNE     GETV7                             ;NO, TRY.
        LDD     B,X                               ;GET VALUE
        LDX     ,S                                ;GET STACK VALUE
        STD     3,X                               ;SAVE IT
        LDB     #1                                ;GET TYPE
        CLRA                                      ;	ZERO HIGH BYTE
        STB     ,X                                ;SAVE TYPE
        STD     1,X                               ;SAVE LENGTH
        BRA     GETV6
GETV7
        LBSR    FUNC                              ;CALL FUNCTION
GETV6
        LEAS    2,S                               ;SKIP X VALUE FROM STACK
        ORCC    #4                                ;SET Z FLAG
        PULS    U,PC                              ;AND GO HOME
GETV4
        ANDCC   #$FB                              ;CLEAR Z FLAG
        PULS    X,U,PC                            ;AND RETURN
;* 'P$' SYSTEM VARIABLE
SYSPRM
        CMPA    #'P'                              ;IS IT PARAMETER
        BNE     KREAD                             ;NO, TRY TO READ TERMINAL
        LBSR    SKBK                              ;BACKUP
        LDX     PARM                              ;GET PARAMETER POINTER
        BRA     GETV6                             ;RETURN
;* READ A SINGLE KEYBOARD KEY
KREAD
        CMPA    #'K'                              ;READ KEYBOARD?
        BNE     INTER                             ;NO, TRY READ LINE
        CLR     -3,X                              ;SET TYPE TO CHARACTER
        LDD     #1                                ;GET LENGTH OF ONE
        STD     -2,X                              ;SAVE
        LBSR    GETCHR                            ;READ A CHARACTER
        STA     ,X                                ;SAVE IT
SYSX1
        BRA     SYSX                              ;GO HOME
;* READ LINE FROM TERMINAL
INTER
        CMPA    #'F'                              ;FORMATTED INPUT?
        BNE     INNUM                             ;NO, TRY FOR NUMERIC INPUT
        PSHS    Y                                 ;SAVE VARIABLE POINTER
        LDY     TEMP5                             ;GET BUFFER ADDRESS
        LEAY    -128,Y                            ;BACKUP TO FREE RAM
        LBSR    GETLIN                            ;READ IT
        DECB                                      ;	BACKUP
        CLRA                                      ;	SET HIGH BYTE TO ZERO
        STA     -3,X                              ;SET TYPE TO CHARACTER
        STD     -2,X                              ;SET LENGTH
        BEQ     INTER2                            ;ZERO LENGTH
INTER1
        DECB                                      ;	BACKUP
        LDA     B,Y                               ;GET CHARACTER FROM BUFFER
        STA     ,X+                               ;SAVE IN OUTPUT
        TSTB                                      ;	BACKUP
        BNE     INTER1                            ;SAVE IT ALL
INTER2
        PULS    Y                                 ;RESTORE TEXT POINTER
        BRA     SYSX1                             ;AND GO HOME
INNUM
        CMPA    #'T'                              ;TERMINAL INP?
        LBNE    SYNTAX                            ;NO, GET UPSET
INN1
        LDD     RAMTOP                            ;GET TOP OF RAM
        PSHS    A,B,Y                             ;SAVE
        LDY     NAMPTR                            ;POINT TO NAME
        LDD     LINCT                             ;GET LINE COUNTER
        PSHS    A,B,Y                             ;SAVE
        LDY     GOTO                              ;GET GOTO POINTER
        LDD     PARM                              ;GET PARAMETERS
        PSHS    A,B,Y                             ;SAVE
        LDY     SAVSTK                            ;SAVED STACK POINTER
        LDD     INPSTK                            ;GET INPUT STACK
        PSHS    A,B,Y                             ;SAVE
        STS     INPSTK                            ;SAVE OUR STACK POINTER
        LDD     TEMP5                             ;GET BUFFER ADDRESS
        STD     RAMTOP                            ;SAVE IT BACK
INN2
        LDA     #'?'                              ;GET PROMPT
        LBSR    PUTCHR                            ;DISPLAY
        LDY     TEMP5                             ;POINT TO RAM ADDRESS
        LEAY    -128,Y                            ;BACKUP FOR SOME BUFFER SPACE
        STY     TEMP5                             ;RESERVE THIS BUFFER
        LBSR    GETLIN                            ;GET A LINE
        LBSR    SKP                               ;ADVANCE
        CMPA    #$0D                              ;CR?
        BEQ     INN2                              ;IF SO, GO AGAIN
        LDA     #$0D                              ;GET CR
        STA     -1,Y                              ;SAVE
        LBSR    EXPR                              ;DO EXPRESSION
INNP3
        LDD     RAMTOP                            ;GET BUFFER ADRESS
        STD     TEMP5                             ;RESAVE
        LDS     INPSTK                            ;GET INPUT STACK
        PULS    A,B,Y                             ;GET VALUES BACK
        STD     INPSTK                            ;SAVE INPUT FLAG
        STY     SAVSTK                            ;RESAVE STACK
        PULS    A,B,Y                             ;GET MORE
        STD     PARM                              ;SAVE PARM POINTER
        STY     GOTO                              ;SAVE GOTO FLAG
        PULS    A,B,Y                             ;GET LINCT AND NAMPTR
        STD     LINCT                             ;SAVE LINE COUNT
        STY     NAMPTR                            ;RESAVE
        PULS    A,B,Y                             ;GET TOP OF RAM
        STD     RAMTOP                            ;AND RESAVE
        TST     ERRFLG                            ;DID AN ERROR OCCUR?
        BNE     INN1                              ;IF SO, GO AGAIN
        LBSR    SKBK                              ;BACKUP
        LBRA    GETV6                             ;AND GO HOME
;*
;* ASSIGN VALUE(X) TO VARIABLE
;*
ASSIGN
        PSHS    X,U                               ;SAVE VALUE
        STY     TEMP3                             ;SAVE FOR LATER
        LDA     ,Y                                ;GET VALUE
        CMPA    #']'                              ;INDEXED ASSIGNMENT
        LBEQ    IASS                              ;INDICATE SO
        CMPA    #'$'                              ;IS IT A SYSTEM VARIABLE?
        BNE     ASI1                              ;NO, NORMAL ASSIGNMENT
        LDA     ,-Y                               ;GET NEXT CHARACTER
        CMPA    #'O'                              ;SETORIGIN?
        BNE     ASN1                              ;NO, TRY SEED
        LDU     #ORIGIN                           ;SAVE VALUE
        BRA     ASN9                              ;AND QUIT
ASN1
        CMPA    #'C'                              ;CHARACTER?
        BEQ     ASN8                              ;PERFORM DUMP
        CMPA    #'S'                              ;SET RANDOM SEED?
        BNE     ASN2                              ;NO, TRY NEXT
        LDU     #SEED                             ;SAVE RANDOM SEED
        BRA     ASN9                              ;SAVE VALUE
ASN2
        CMPA    #'B'                              ;BUFFER SIZE
        BNE     LGOTO                             ;TRY GOTO LINE
        LDU     #BUFSIZ                           ;POINT TO IT
ASN9
        LDA     ,X                                ;GET TYPE
        LBEQ    DOMAIN                            ;INVALID
        LDD     1,X                               ;GET LENGTH
ASN89
        CMPD    #1                                ;SINGLE ELEMENT?
        LBNE    LENGTH                            ;NO, IT'S INVALID
        LDD     3,X                               ;GET VALUE
        STD     ,U                                ;SAVE IN DEST
ASN8
        LBSR    SKBK                              ;BACKUP
        PULS    X,U,PC                            ;RETURN
;* BRANCH BY CHANGEING VALUE OF 'L$'
LGOTO
        CMPA    #'L'                              ;IS IT 'L'$
        BNE     TEROUT                            ;NO, SAY ERROR
        LDA     ,X                                ;GET TYPE
        LBEQ    DOMAIN                            ;INVALID
        LDD     1,X                               ;GET LENGTH
        BEQ     ASN8                              ;IF ZERO, IGNORE
        LDU     #GOTO
        BRA     ASN89
;* DISPLAY VALUE ON TERMINAL
TEROUT
        CMPA    #'T'                              ;TERMINAL I/O?
        BNE     FRMOUT                            ;NO, TRY FORMATTED
        LBSR    DISPLY                            ;DISPLAY IT
        LBSR    LFCR                              ;NEW LINE
        BRA     ASN8                              ;GO HOME
FRMOUT
        CMPA    #'F'                              ;FORMATTED OUTPUT?
        LBNE    SYNTAX                            ;NO, GET UPSET
        LBSR    DISPLY                            ;OUTPUT IT
        BRA     ASN8                              ;AND GO IT AGAIN
;* LOOK UP SYMBOL VALUE
ASI1
        LBSR    VALSYM                            ;IS IT A VALID SYMBOL NAME
        LBNE    SYNTAX                            ;NO, GET UPSET
        LBSR    CALLEN                            ;GET LENGTH
        PSHS    A,B                               ;SAVE LENGTH
        LBSR    LOOKUP                            ;LOOK FOR DATA
        BNE     NEWV                              ;CREATE NEW VARIABLE
        CMPA    #2                                ;IS IT A VARIABLE
        LBNE    SYNTAX                            ;INDICATE INVALID SYNTAX
        STX     TEMP4                             ;SAVE FOR LATER
        LDX     B,X                               ;GET ADDRESS OF VARIABLE
        LBSR    CALLEN                            ;DO THEY NEED SAME SPACE
        CMPD    ,S                                ;ARE THEY SAME
        BEQ     ASI2                              ;IF SO, NO NEED TO CHANGE
        LDX     TEMP4                             ;SYMBOL TABLE ENTRY BACK
        LBSR    ERASYM                            ;ERASE SYMBOL
NEWV
        LDA     #2                                ;GET TYPE
        LDY     TEMP3                             ;POINT TO NAME
        LBSR    CRESYM                            ;CREATE SYMBOL
        PULS    A,B                               ;GET LENGTH
        LDU     ,X                                ;GET ADDRESS OF SYMBOL
        LDX     ,S                                ;GET SYMBOL VALUE
        PSHS    Y                                 ;SAVE POINTER
        TFR     D,Y                               ;COPY TO Y
ASI3
        LDA     ,X+                               ;GET BYTE FROM STRUCTURE
        STA     ,U+                               ;RESAVE
        LEAY    -1,Y                              ;BACKUP
        BNE     ASI3                              ;KEEP SAVEING
        PULS    Y                                 ;RESTORE Y
        STU     FREE                              ;SAVE FREE VALUE
        PULS    X,U,PC
ASI2
        PULS    A,B                               ;GET COUNT
        LDU     ,S                                ;GET OLD VALUE ADDRESS
        PSHS    Y                                 ;SAVE POINTR
        TFR     D,Y                               ;COPY
ASI4
        LDA     ,U+                               ;GET DATA FROM OLD
        STA     ,X+                               ;SAVE IN NEW
        LEAY    -1,Y                              ;BACKUP
        BNE     ASI4                              ;INSERT
        PULS    Y                                 ;RESTORE POINTER
        PULS    X,U,PC                            ;COND CONTINUE
;* INDEXED ASSIGNEMENT TO AN EXISTING VARIABLE
IASS
        LBSR    DOEXPR                            ;GET ASSIGNMENT VALUE
        CMPA    #'['                              ;TEST FOR PROPER TERMINATION
        LBNE    SYNTAX                            ;INDICATE INVALID
        DEC     ASSFLG                            ;SET LAST OPERATOR
        LDA     ,X+                               ;GET TYPE OF INDEX VALUE
        CMPA    #1                                ;IS IT AN INTEGER VALUE
        LBNE    DOMAIN                            ;IF NOT, SAY SO
        PSHS    X                                 ;SAVE POINTER TO VALUE
        LBSR    SKBK                              ;BACKUP AGAIN
        LBSR    LOOKUP                            ;FIND VARIABLE
        LBNE    VALUE                             ;IT'S BAD
        CMPA    #2                                ;IS IT A VARIABLE?
        LBNE    SYNTAX                            ;NO, GIVE UP
        LDX     B,X                               ;POINT TO VARIABLE ADDRESS
        PULS    U                                 ;GET INDEX BACK
        STY     TXTPTR                            ;SAVE TEXT POINTER
        LDY     ,S                                ;GET SOURCE VALUE
        LDA     ,X                                ;GET TYPE OF VARIABLE
        CMPA    ,Y+                               ;SAME AS TYPE OF ARGUMENT
        BNE     CDOM                              ;NO, COMPLAIN
        CLR     TEMP                              ;INDICATE SINGLE MODE
        LDD     ,Y++                              ;GET LENGTH OF SOURCE
        CMPD    #1                                ;LENGTH ONE IS SPECIAL CASE
        BEQ     IDA0                              ;IF SO, IT'S OK
        CMPD    ,U                                ;SAME SIZE AS INDEX
        BNE     CLEN                              ;INDICATE LENGTH ERROR
        DEC     TEMP                              ;INDICATE NORMAL MODE
IDA0
        LDD     ,U++                              ;GET LENGTH OF INDEX
        BEQ     CLEN                              ;INDICATE LENGTH ERROR IS ZERO LENGTH INDEX
IDA1
        PSHS    A,B                               ;SAVE IT
        LDD     ,U++                              ;GET INDEX VALUE
        SUBD    ORIGIN                            ;SET ORIGIN VALUE
        PSHS    A,B                               ;SAVE IN STACK
        LDD     1,X                               ;GET LENGTH OF DEST VARIABLE
        SUBD    #1                                ;CONVERT TO ZERO OFFSET
        SUBD    ,S++                              ;CONVERT OFFSET
        LBCS    CIDX                              ;INDEX ERROR IF OVER
        TST     ,X                                ;CHARACTER INFO?
        BEQ     IDA2                              ;IF SO, DON'T DOUBLE ADDRESS
        LSLB
        ROLA                                      ;	DOUBLE FOR TWO BYTE ENTRIES
        PSHS    U                                 ;SAVE Y POINTER
        ADDD    #3                                ;OFFSET FOR TYPE AND LENGTH
        LEAU    D,X                               ;POINT TO OFFSET
        LDD     ,Y++                              ;GET VALUE FROM SOURCE
        STD     ,U                                ;SAVE IN DATA
        LDA     TEMP                              ;ADVANCE?
        BNE     IDA3
        LEAY    -2,Y                              ;BACKUP
        BRA     IDA3                              ;END
IDA2
        PSHS    U                                 ;SAVE POINTER
        ADDD    #3                                ;OFFSET FOR TYPE AND LENGTH
        LEAU    D,X                               ;OFFSET TO AREA
        LDA     ,Y+                               ;GET CHARACTER
        STA     ,U                                ;SAVE BACK
        TST     TEMP                              ;NORMAL?
        BNE     IDA3                              ;YES, GOT FOR IT
        LEAY    -1,Y                              ;BACKUP
IDA3
        PULS    U                                 ;RESTORE POINTER
        PULS    A,B                               ;RESTORE COUNT
        SUBD    #1                                ;OVER YET?
        BNE     IDA1                              ;NO, GO AGAIN
        LDY     TXTPTR                            ;RESTORE TEXT POINTER
        PULS    X,U,PC                            ;GO HOME
CLEN
        LDY     TXTPTR
        LBRA    LENGTH
CDOM
        LDY     TXTPTR
        LBRA    DOMAIN
;*
;* RETURN LENGTH (IN BYTES) OF STRUCTURE(X)
;*
CALLEN
        LDD     1,X                               ;GET SHAPE
        TST     ,X                                ;IS IT CHARACTER
        BEQ     CALL1                             ;YES, DON'T DOUBLE
        LSLB
        ROLA                                      ;	DOUBLE FOR TWO BYTE ENTRIES
CALL1
        ADDD    #3                                ;AND IN LENGTH, AND TYPE DATA
        RTS
;*
;* INSURE DATA IS IN WORKSPACE
;*
MVWRK
        PSHS    Y,U                               ;SAVE POINTER
        CMPX    TEMP5                             ;IS IT IN WORKSPACE?
        BEQ     MVRTS                             ;ALL IS OK
        LDU     TEMP5                             ;POINT
        LDA     ,X+                               ;GET POINTER
        STA     ,U+                               ;SAVE
        LDY     ,X++                              ;GET LENGTH
        STY     ,U++                              ;SAVE
        TSTA                                      ;	CHARACTER MOVE?
        BEQ     CHRMV                             ;IF SO, SPECIAL
MV1
        CMPY    #0                                ;ZERO LENGTH?
        BEQ     MVRTS                             ;IF SO, QUIT
        LEAY    -1,Y                              ;BACKUP
        LDD     ,X++                              ;GET FROM SOURCE
        STD     ,U++                              ;SAVE
        BRA     MV1                               ;OK
CHRMV
        CMPY    #0                                ;ZERO LENGTH?
        BEQ     MVRTS                             ;IF SO, QUIT
        LEAY    -1,Y                              ;BACKUP
        LDD     ,X+                               ;GET CHAR
        STD     ,U+                               ;SAVE CHAR
        BRA     CHRMV                             ;OK
MVRTS
        LDX     TEMP5                             ;POINT TO SPACE
        PULS    Y,U,PC                            ;HOME
;*
;* LOOK UP AND EXECUTE COMMAND
;*
CLOOK
        PSHS    Y                                 ;SAVE COMMAND POINTER
CL5
        LDA     ,X+                               ;GET CHARACTER FROM TABLE
        BMI     CCHK                              ;LAST ONE, CHECK IT
        CMPA    ,Y+                               ;DOES IT MATCH?
        BEQ     CL5                               ;YES, KEEP LOOKING
CL2
        LDA     ,X+                               ;GET NEXT
        BPL     CL2                               ;LOOK FOR END
CL3
        LEAX    2,X                               ;SKIP ADDRESS
        PULS    Y                                 ;RESTORE POINTER
        BRA     CLOOK                             ;AND GO AGAIN
CCHK
        ANDA    #$7F                              ;REMOVE HIGH BIT
        BEQ     CL4                               ;END OF TABLE
        CMPA    ,Y+                               ;IS IT SAME AS FROM BUFFER?
        BNE     CL3                               ;NO, GO AGAIN
CL4
        LEAS    2,S                               ;CLEAN UP STACK
        LBSR    SKP                               ;ADVANCE TO PARAMETERS
        JMP     [,X]                              ;EXECUTE CODE
;*
;* ERROR MESSAGES
;*
SYMSG
        FCN     'SYNTAX'
VALMSG
        FCN     'VALUE'
DOMMSG
        FCN     'DOMAIN'
LENMSG
        FCN     'LENGTH'
INDMSG
        FCN     'INDEX'
BRKMSG
        FCC     'INTERRUPT'
        FCB     $0D
;*
;* ERROR HANDLERS
;*
REBRK
        LDD     RAMTOP                            ;GET BUFFER ADRESS
        STD     TEMP5                             ;RESAVE
        LDS     INPSTK                            ;GET INPUT STACK
        PULS    A,B,Y                             ;GET VALUES BACK
        STD     INPSTK                            ;SAVE INPUT FLAG
        STY     SAVSTK                            ;RESAVE STACK
        PULS    A,B,Y                             ;GET MORE
        STD     PARM                              ;SAVE PARM POINTER
        STY     GOTO                              ;SAVE GOTO FLAG
        PULS    A,B,Y                             ;GET LINCT AND NAMPTR
        STD     LINCT                             ;SAVE LINE COUNT
        STY     NAMPTR                            ;RESAVE
        PULS    A,B,Y                             ;GET TOP OF RAM
        STD     RAMTOP                            ;AND RESAVE
BREAK
        LDD     INPSTK                            ;ARE WE INPUTTING?
        BNE     REBRK                             ;YES, FIX IT UP
        LDA     EXEC                              ;EXECUTING FUNCTION?
        BEQ     BRK0                              ;OK TO DISPLAY
        LDA     [NAMPTR]	GET TYPE BITS
        ANDA    #$20                              ;IS IT LOCKED
        BEQ     BRK0                              ;NO, IT'S OK
        LBSR    RELEAS                            ;RELEASE THIS ONE
        BRA     BREAK                             ;ALWAYS A DOMAIN ERROR
BRK0
        LDX     #BRKMSG                           ;DISPLAY
        LBSR    OULI                              ;DISPLAY
        BRA     ERR0                              ;AND CONTINUE
;* WORKSACE IS FULL
WSFUL
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
        FCN     'WS FULL'
        BRA     ERR0                              ;CONTINUE
SYNTAX
        LDX     #SYMSG
        BRA     ERROR
VALUE
        LDX     #VALMSG
        BRA     ERROR
DOMAIN
        LDX     #DOMMSG
        BRA     ERROR
LENGTH
        LDX     #LENMSG
        BRA     ERROR
INDEX
        LDX     #INDMSG
ERROR
        LDA     EXEC                              ;EXECUTING FUNCTION?
        BEQ     OKDISP                            ;OK TO DISPLAY
        LDA     [NAMPTR]	GET TYPE BITS
        ANDA    #$20                              ;IS IT LOCKED
        BEQ     OKDISP                            ;NO, IT'S OK
        LDD     INPSTK                            ;INPUTTING?
        BNE     OKDISP                            ;CONTINUE
        LBSR    RELEAS                            ;RELEASE THIS ONE
        BRA     DOMAIN                            ;ALWAYS A DOMAIN ERROR
OKDISP
        LBSR    OULI                              ;DISPLAY MESSAGE
        LBSR    SYSMSG
        FCN     ' ERROR'
ERR0
        LDA     EXEC                              ;EXECUTING FUNCTION?
        BEQ     ERR01                             ;NO
        LDX     NAMPTR                            ;POINT TO ENTRY
        LDD     LINCT                             ;GET LINE COUNTER
        LBSR    DSPNAM                            ;DISPLAY IT
        LBSR    LFCR                              ;NEW LINE
        LDD     LINCT                             ;LINE ZERO?
        BEQ     ERR9
ERR01
        CLRB                                      ;	START WITH ZERO OFFSET
ERR1
        LDA     ,Y                                ;GET CHARACTER FROM Y REGISTER
        CMPA    #$0D                              ;END OF LINE?
        BEQ     ERR5                              ;IF SO, TOO BAD
        INCB                                      ;	ADVANCE
        LEAY    -1,Y                              ;AND BACKUP IN LINE
        BRA     ERR1                              ;CONTINUE
ERR5
        LEAY    1,Y                               ;BACK TO BEFORE CR
ERR2
        LDA     ,Y+                               ;GET CHARACTER
        LBSR    PUTCHR                            ;DISPLAY
        CMPA    #$0A                              ;END OF LINE?
        BNE     ERR2                              ;NO, KEEP GOING
        TSTB                                      ;	CHECK FOR OVER
        BEQ     ERR4                              ;ALL DONE
ERR3
        DECB                                      ;	REDUCE COUNT
        BEQ     ERR4                              ;OK
        LBSR    SPACE                             ;SPACE OVER
        BRA     ERR3                              ;TILL WE ARE UNDER IT
ERR4
        LDA     #'^'                              ;GET ERROR MARK
        LBSR    PUTCHR                            ;DISPLAY
        LBSR    LFCR                              ;NEW LINE
ERR9
        DEC     ERRFLG                            ;INDICATE ERROR HAPPENED
        LDD     INPSTK                            ;ARE WE INPUTTING
        LBNE    INNP3                             ;IF SO, RECOVER
        LBRA    CMD                               ;ENTER COMMAND MODE
;* DISPLAY NAME OF FUNCTION, A,B= LINE NUMBER, X= NAME POINTER
DSPNAM
        PSHS    A,B                               ;SAVE REGS
        LDB     ,X+                               ;GET LENGTH OF NAME
        ANDB    #$1F                              ;MASKOFF SHIT
ERRP
        LDA     B,X                               ;GET CHARACTER
        LBSR    PUTCHR                            ;DISPLAY
        DECB                                      ;	REDUCE COUNT
        BNE     ERRP                              ;KEEP GOING
        LDA     #'['                              ;START
        LBSR    PUTCHR                            ;DISPLAY
        PULS    A,B                               ;RESTORE IT
        LBSR    DECOUT                            ;DISPLAY
        LDA     #']'                              ;CLOSING BRACE
        LBRA    PUTCHR                            ;DISPLAY
;*
;* START A FUNCTION
;*
FUNC
        PSHS    Y                                 ;SAVE TEXT POINTER
        LDY     RAMTOP                            ;GET TOP OF FREE RAM
        PSHS    Y                                 ;RESAVE
        LDY     NAMPTR                            ;GET NAME POINTER
        PSHS    Y                                 ;SAVE
        STX     NAMPTR                            ;SAVE OUR NAME
        LDY     B,X                               ;GET TEXT POINTER
        LDX     LINCT                             ;GET LINE COUNTER
        LDD     GOTO                              ;GET GOTO POINTER
        PSHS    A,B,X                             ;SAVE
        LDX     PARM                              ;SAVE OUT GOTO VALUE
        LDD     SAVSTK                            ;GET SAVED STACK VALUE
        PSHS    A,B,X                             ;SAVE
        LDD     TEMP                              ;GET TEMPORARY STORAGE
        STD     PARM                              ;SAVE PARAMETER
        CLRA                                      ;	CLEAR IT
        CLRB                                      ;	START WITH LINE #0
        STD     LINCT                             ;SET LINE NUMBER
        STD     GOTO                              ;SAVE WHERE WE WANT TO GO
        PSHS    Y                                 ;SAVE POINTER TO LOCAL SYMBOLS
        INC     LEVEL                             ;DOWN ANOTHER LEVEL
        INC     EXEC                              ;EXECUTING
        STS     SAVSTK                            ;SAVE STACK
        LDD     TEMP5                             ;GET TOP OF FREE RAM
        STD     RAMTOP                            ;SET IT UP
;* FIX UP FOR LOCAL SYMBOLS
LCVAR
        LBSR    SKIP                              ;ADVANCE TO NEXT
        CMPA    #$0D                              ;END OF LINE?
        BEQ     FNGO                              ;GO AHEAD
        CMPA    #';'                              ;SEMI?
        LBNE    SYNTAX                            ;INDICATE SYNTAX ERROR
        LBSR    SFSYM                             ;ADVANCE
        PSHS    Y                                 ;SAVE
        LEAY    -1,Y                              ;BACK TO SYMBOL
        LBSR    LOOKUP                            ;LOOK FOR IT
        BNE     LCV1                              ;DON'T ZAP IF NOT THERE
        LDA     LEVEL                             ;GET OUR LEVEL
        STA     1,X                               ;INDICATE THAT IT IS NESTED
LCV1
        PULS    Y                                 ;RESTORE Y REG
        BRA     LCVAR                             ;AND GO AGAIN
;* CREATE LABEL ENTRIES IN SYMBOL TABLE
FNGO
        LDU     #0
FUNGT
        LDA     ,Y+                               ;GET CHAR FROM LINE
        BMI     FNGOX                             ;END OF FILE, QUIT
        CMPA    #$0D                              ;LOOK FOR CARRAGE RETURN
        BNE     FUNGT                             ;LOOK TILL WE FIND
        LEAU    1,U                               ;ADVANCE
        LBSR    SFSYM                             ;SKIP FORWARD
        BEQ     FUNGT                             ;NO SYMBOL, GET UPSET
        CMPA    #':'                              ;LABEL?
        BNE     FUNGT                             ;NO, SKIP IT
        PSHS    Y                                 ;SAVE POINTER
        LEAY    -1,Y                              ;BACKUP
        LBSR    LOOKUP                            ;DOES IT EXIST?
        BNE     FNGOZ                             ;NO, DON'T SAVE IT
        LDA     LEVEL                             ;GET LEVEL
        STA     1,X                               ;SAVE IT
FNGOZ
        LDY     ,S                                ;GET POINTER BACK
        LEAY    -1,Y                              ;BACKUP
        LDA     #3                                ;INDICATE LABEL
        LBSR    CRESYM                            ;SAVE IT
        STU     ,X                                ;SAVE LINE NUMBER
        PULS    Y                                 ;RESTORE Y
        BRA     FUNGT                             ;CONTINUE
FNGOX
        LDX     #IOTA0                            ;POINT TO EMPTY VECTOR FOR DEFAULT RETURN
        LDY     ,S                                ;GET TEXT POINTER
;* START IT UP
FNXLIN
        LDA     ,Y+                               ;ADVANCE TO NEXT
        CMPA    #$0D                              ;END OF LINE?
        BNE     FNXLIN                            ;CONTINUE
        LDD     GOTO                              ;IS THIS WEHERE WE WANT TO GO?
        BEQ     GOTOK                             ;GOTO IS OK
        PSHS    X                                 ;SAVE X
        LDX     2,S                               ;GET TEXT ADRESS
        LBSR    FNDL1                             ;LOCATE THE LINE
        TFR     X,Y                               ;COPY BACK
        PULS    X                                 ;RESTORE X
        LDD     TEMP3                             ;GET LINE NUMBER
        BRA     GOT1
GOTOK
        LDD     LINCT                             ;GET LINE COUNTER
        ADDD    #1                                ;ADVANCE
GOT1
        STD     LINCT                             ;RESAVE
        CLRA
        CLRB
        STD     GOTO                              ;RESET GOTO FLAG
        LDA     ,Y                                ;GET NEXT CHARACTER
        CMPA    #$FF                              ;END OF FUNCTION?
        BEQ     EFUNC                             ;NO, GO AGAIN
        CMPA    #'*'                             ;COMMENT?
        BEQ     FNXLIN                            ;GO TO NEXT LINE
        SWI
        FCB     35                                ;LOOK FOR KEYBOARD KEY
        CMPA    #$03                              ;CONTROL C?
        LBEQ    BREAK                             ;INTERRUPT PROGRAM
NOINT1
        LBSR    EXPR                              ;EXECUTE
        BRA     FNXLIN
;* END OF A FUNCTION
EFUNC
        PULS    Y                                 ;GET POINTER BACK
        PSHS    X                                 ;SAVE IT
EFUN1
        LBSR    SKIP                              ;LOOK FOR IT
        CMPA    #$0D                              ;END?
        BEQ     EFUPOT                            ;IF SO, EXIT
        LBSR    SFSYM                             ;SKIP TO END
        PSHS    Y                                 ;SAVE IT
        LEAY    -1,Y                              ;BACKUP
        LBSR    LOOKUP                            ;LOOK FOR IT
        BNE     EFUN3                             ;NOT FOUND
        LBSR    ERASYM                            ;ERASE IT
EFUN3
        PULS    Y                                 ;RESTORE POINTER
        BRA     EFUN1                             ;AND GO AGAIN
EFUPOT
        LDA     ,Y+                               ;GET CHAR
        BMI     EFUN2                             ;END, QUIT
        CMPA    #$0D                              ;END OF LINE?
        BNE     EFUPOT                            ;GO
        LBSR    SFSYM                             ;SCAN FOR SYMBOL
        BEQ     EFUPOT                            ;NONE, SKIP IT
        CMPA    #':'                              ;IS IT LOCAL LABEL?
        BNE     EFUPOT                            ;NO, SKIP IT
        PSHS    Y                                 ;SAVE IT
        LEAY    -1,Y                              ;BACKUP
        LBSR    LOOKUP                            ;LOOK FOR IT
        BNE     NOFUNE                            ;DON'T ERASE
        LBSR    ERASYM                            ;ERASE IT
NOFUNE
        PULS    Y                                 ;RESTORE Y
        BRA     EFUPOT                            ;CONTINUE
;* REPLACE SMUDGED VARIABLES
EFUN2
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
        LDA     LEVEL                             ;GET OUR LEVEL
EFUN4
        LDB     ,X                                ;GET TYPE BYTE
        ANDB    #$1F                              ;MASK GARBAGE
        BEQ     EFUN5                             ;END OF TABLE
        CMPA    1,X                               ;IS THIS ONE WE NESTED?
        BNE     EFUN6                             ;NO, SKIP IT
        CLR     1,X                               ;RELEASE IT
EFUN6
        ADDB    #4                                ;ADVANCE EXTRA BYTES
        ABX                                       ;	SKIP AHEAD
        BRA     EFUN4                             ;GO IT AGAIN
EFUN5
        PULS    X                                 ;RESTORE REGISTERS
        PULS    A,B,Y                             ;RESTORE PARAMETER ADDRESS
        STD     SAVSTK                            ;REPLACE SAVED STACK POINTER
        STY     PARM                              ;SET PARAMETER VALUE
        PULS    A,B,Y                             ;RESTORE NAME POINTER
        STD     GOTO                              ;SAVE
        STY     LINCT                             ;SAVE LINE COUNTER
        PULS    A,B,Y                             ;RESTORE VARIABLES
        STD     NAMPTR                            ;RESET LINE COUNTER
        STY     RAMTOP                            ;SET BUFFER ADDRESS
        DEC     LEVEL                             ;RESET MODE
        DEC     EXEC                              ;RELEASE EXECUTION FLAG
        CLR     ASSFLG                            ;NO ASSIGNMENT
        PULS    Y,PC                              ;BACKUP AND RETURN
;*
;* SYSTEM COMMAND DEFINTIONS
;*
;* CONTINUE COMMAND
CONCMD
        LDY     #CONTIN                           ;POINT AT FILENAME
        LBSR    SAV5                              ;PERFORM SAVE
;* ')OFF' COMMAND
OFF
        CLRA                                      ;	INDICATE MESSAGES
        SWI
        FCB     104                               ;WITH DOS COMMAND
        CLRA                                      ;	SET ZERO RC
        SWI
        FCB     0                                 ;RETURN TO OS
;* ')LBLS' COMMAND
LBLS
        LDA     #$60                              ;GET TYPE
        STA     TEMP                              ;SAVE IT
        BRA     FNST1                             ;SAVE SINGLE TYPE LIST
;* ')VARS' COMMAND
VARS
        LDA     #$40                              ;INDICATE LOOKING FOR VARIABLES
        STA     TEMP                              ;SET INDICATOR
FNST1
        LDA     #$E0                              ;SET MASK
        BRA     SRCSY                             ;SEARCH SYMBOL TABLE
;* ')FNS' COMMAND
FNS
        CLR     TEMP                              ;INDICATE LOOKING FOR FUNCTIONS
        LDA     #$C0                              ;PROPER MASK
SRCSY
        STA     TEMP+1                            ;SAVE IN LOCATION
        LDA     #$FF                              ;GET END OF TABLE POINTER
        STA     [FREE]                            ;INITIALIZE WORKSPACE
        LDX     #SYMTAB                           ;POINT TO TABLE
FNS1
        LDB     ,X+                               ;GET LENGTH
        TFR     B,A                               ;SAVE FOR TYPE REFERENCE
        ANDB    #$1F                              ;REMOVE TYPE INFO
        BEQ     FNS4                              ;QUIT IF END
        ANDA    TEMP+1                            ;MASK OFF TYPE INFO
        CMPA    TEMP                              ;DOES IT MATCH?
        BNE     FNS3                              ;NO, SKIP IT
        LDY     FREE                              ;POINT TO WORK SPACE
INW0
        PSHS    B,Y                               ;SAVE WRKSPC POINTER
        LDA     ,Y                                ;IS THIS THE END?
        CMPA    #$FF                              ;END OF TABLE?
        BEQ     INW2                              ;PUT IT HERE
INW1
        LDA     ,Y+                               ;GET CHARCTER FROM TABLE
        BEQ     INW3                              ;DON'T PUT IT HERE
        CMPA    B,X                               ;ARE WE OVER
        BLO     INW3                              ;DON'T PUT IT HERE
        BHI     INW2                              ;YES, GO FOR IT
        DECB                                      ;	BACKUP
        BNE     INW1                              ;KEEP GOING TILL DONE
        BRA     INW2                              ;INSERT IT HERE
INW3
        PULS    B,Y                               ;RESTORE
INW5
        LDA     ,Y+                               ;ADVANCE
        BNE     INW5                              ;TILL WE FIND NEXT
        BRA     INW0                              ;AND TRY AGAIN
INW2
        LDA     ,Y+                               ;FIND END
        CMPA    #$FF                              ;KEEP LOOKING
        BNE     INW2                              ;NOT HERE
        PULS    B                                 ;RESTORE LENGTH
        INCB                                      ;	ADVANCE FOR ZERO VALUE
INW4
        LDA     ,Y                                ;GET DATA FROM TABLE
        STA     B,Y                               ;SAVE HIGHER UP
        LEAY    -1,Y                              ;BACKUP FOR LATER
        CMPY    ,S                                ;ARE WE BACK YET?
        BHS     INW4                              ;NO, KEEP LOOKING
        PULS    Y                                 ;RESTORE POITION
        DECB                                      ;	CONVERT BACK TO LENGTH
FNS2
        LDA     B,X                               ;GET CHARACTER
        STA     ,Y+                               ;SAVE IN RAM
        DECB                                      ;	REDUCE COUNT
        BNE     FNS2                              ;AND KEEP GOING
        CLR     ,Y                                ;INDICATE END OF ENTRY
FNS3
        LDB     -1,X                              ;GET LENGTH AGAIN
        ANDB    #$1F                              ;REMOVE TYPE INFO
        ADDB    #3                                ;OFFSET TO NEXT
        ABX     B,X                               ;SKIP TO NEXT
        BRA     FNS1                              ;AND TRY AGAIN
FNS4
        LDX     FREE                              ;POINT TO WORKSPACE
FNS5
        CLRB                                      ;	SET PRINT POSITION TO ZERO
FNS6
        LDA     ,X+                               ;GET DATA FROM WORKSPACE
        BEQ     FNS7                              ;ADVANCE TO NEXT
        CMPA    #$FF                              ;END OF TABLE?
        BEQ     FNS8                              ;IF SO, STOP
        LBSR    PUTCHR                            ;DISPLAY
        INCB                                      ;	INDICATE WE ADVANCED
        BRA     FNS6                              ;AND CONTINUE
FNS7
        LBSR    SPACE                             ;DISPLAY A SPACE
        INCB                                      ;	ADVANCE
        BITB    #$07                              ;TEST FOR AT A TAB STOP
        BNE     FNS7                              ;NO, KEEP GOING
        CMPB    #60                               ;ARE WE OVER LIMIT?
        BLO     FNS6                              ;NO, WE ARE OK
        LBSR    LFCR                              ;NEW LINE
        BRA     FNS5                              ;AND TRY AGAIN
FNS8
        TSTB                                      ;	ARE WE AT BEGINNING OF LINE?
        BEQ     NOLF                              ;NO NEED TO NEW LINE
        LBSR    LFCR                              ;NEW LINE
NOLF
        RTS
;* ')SYSTEM' COMMAND
SYSTEM
        PSHS    Y                                 ;SAVE COMMAND
        CLRA
        SWI
        FCB     104                               ;ENABLE DOS MESSAGES
        PULS    Y                                 ;RESTORE COMMAND
        LBSR    SKP                               ;CHECK FOR OPERAND
        BEQ     DOSENT                            ;EXECUTE DOS COMMAND
        SWI
        FCB     100                               ;EXECUTE COMMAND
        BRA     SYST1                             ;AND QUIT
DOSENT
        SWI
        FCB     101                               ;ENTER DOS
SYST1
        CLRA                                      ;	DISABLE MESSAGES
        SWI
        FCB     105                               ;WITH DOS COMMAND
        RTS
;* ')LIB' COMMAND
LIB
        LBSR    SKP                               ;LOOK FOR NAME
        BNE     LIB1                              ;DON'T ASSUME DEFAULT
        LDY     #DEFNAM                           ;POINT TO DEFAULT NAME
        BRA     LIB2                              ;AND DISPLAY IT
LIB1
        LBSR    FILNAM                            ;GET FILENAME
LIB2
        SWI
        FCB     9                                 ;GET FILENAME
        LBNE    UNCMD                             ;ERROR, QUIT
        SWI
        FCB     94                                ;DISPLAY DIRECTORY
        BEQ     LIB3                              ;OK
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
        FCN     'LIBRARY EMPTY'
LIB3
        RTS
;* ')WSID' COMMAND
WSID
        LBSR    SKP                               ;LOOK FOR OPERAND
        BEQ     WSID1                             ;IF NONE, SHOW IT
        LBSR    FILNAM                            ;GET FILENAME
        SWI
        FCB     10                                ;GET FROM OS
        LBNE    UNCMD                             ;FAILED
        LEAY    8,X                               ;SKIP TO NAME FIELD
        LBSR    DSPSTR                            ;DISPLAY MESSAGE
        FCN     'WAS '
        BSR     DWSID                             ;DISPLAY WHAT IT WAS
WSISET
        LDB     #8                                ;MOVE EIGHT CHARACTERS
        LDX     #ID                               ;POINT TO ID
WSID3
        LDA     ,Y+                               ;GET CHAR
        STA     ,X+                               ;SAVE ID
        DECB                                      ;	REDUCE COUNT
        BNE     WSID3                             ;AND SAVE IT ALL
WSID2
        RTS
WSID1
        LBSR    DSPSTR                            ;DISPLAY MESSAGE
        FCN     'IS '
;* DISPLAY WORKSPACE ID
DWSID
        LDX     #ID                               ;POINT TO ID
        LDB     #8                                ;MAX EIGHT CHARACTERS
WSID4
        LDA     ,X+                               ;GET CHAR
        BEQ     WSID5                             ;QUIT
        LBSR    PUTCHR                            ;OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     WSID4                             ;AND CONTINUE
WSID5
        LBSR    LFCR                              ;NEW LINE
        RTS
NOTSI
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
        FCN     'NOT WITH SI'
        RTS
;* ')SAVE' COMMAND
SAVE
        LBSR    SKP                               ;LOOK FOR PARAMETER
        BNE     SAV1                              ;USER SUPPLIED FILENAME
        LDX     #ID                               ;POINT TO SAVED ID
        LDB     #8                                ;MAX EIGHT CHARACTERS
        LDY     #CID                              ;POINT TO CID
SAV6
        LDA     ,X+                               ;GET CHARACTER FROM ID
        CMPA    ,Y+                               ;IS IT SAME AS CLEAR
        BNE     SAV7                              ;NO, IT'S OK
        DECB                                      ;	REDUCE COUNT
        BNE     SAV6                              ;KEEP LOOKING
        LBRA    CLMSG                             ;GET UPSET
SAV7
        LDX     #ID                               ;POINT TO ID
        LDB     #8                                ;MOVE EIGHT CHARACTERS
        LDY     #RAM                              ;POINT TO INPUT BUFFER
        PSHS    Y                                 ;SAVE POINTER
SAV3
        LDA     ,X+                               ;GET CHAR
        BEQ     SAV4                              ;END, GO AGAIN
        STA     ,Y+                               ;SAVE IN OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     SAV3                              ;AND KEEP GOING
SAV4
        LDA     #$0D                              ;GET CR
        STA     ,Y                                ;SAVE IN FILENAME
        PULS    Y                                 ;RESTORE POINTER
SAV1
        LBSR    FILNAM                            ;GET FILENAME
SAV5
        LDD     SAVSTK                            ;GET SAVED STACK
        CMPD    #STACK                            ;DO WE HAVE SI?
        BNE     NOTSI                             ;NOT WITH SI
        SWI
        FCB     10                                ;TELL DOS
        LBNE    UNCMD                             ;IF BAD, SKIP IT
        LEAY    8,X                               ;POINT TO FILENAME
        LBSR    WSISET                            ;SET ID
        LDD     FREE                              ;GET FIRST FREE ADDRESS
        SUBD    #FREE                             ;AND CALCULATE OFFSET
        TFR     D,X                               ;COPY TO X FOR DIVIDE
        LDD     #512                              ;SIZE OF DISK SECTORS
        LBSR    DIV                               ;PERFORM DIVISION
        CMPD    #0                                ;ANY REMAINDER
        BEQ     SAV2                              ;NO INC
        LEAX    1,X                               ;ADVANCE FOR REMAINDER OF SECTOR
SAV2
        TFR     X,D                               ;COPY SIZE TO D
        LDX     #FREE                             ;POINT TO START OF WS
        SWI
        FCB     54                                ;SAVE FILE OUT
        LBNE    SYSERR                            ;INDICATE SYSTEM ERROR
        RTS
;* ')ERASE' COMMAND
ERASE
        LBSR    SFSYM                             ;LOOK FOR SYMBOLS
        LBEQ    UNCMD                             ;INVALID COMMAND
        STY     TEMP                              ;SAVE FOR LATER
        LBSR    DOREST                            ;PERFORM RESET
        LDY     TEMP                              ;AND GET POINTER BACK
        LEAY    -1,Y                              ;BACKUP TO SYMBOL
        LBSR    LOOKUP                            ;LOOK FOR SYMBOL
        BNE     NOTFNS                            ;DOES NOT EXIST
        BSR     ERASYM                            ;ERASE IT
        BRA     NOTF1
NOTFNS
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
        FCN     'NOT FOUND'
NOTF1
        LBRA    CMD                               ;GO HOME
;*
;* ERASES SYMBOL TABLE ENTRY POINTED TO BY "X" REGISTER
;*
;* DETERMINE TYPE OF SYMBOL
ERASYM
        PSHS    X                                 ;SAVE POINTER TO SYMBOL
        LDA     ,X                                ;GET TYPE/LENGTH
        TFR     A,B                               ;COPY
        ANDA    #$E0                              ;MASK OFF LENGTH
        ANDB    #$1F                              ;MASK OFF TYPE
        ADDB    #2                                ;ADVANCE PAST TYPE/LENGTH, NEST
        ABX                                       ;	ADVANCE PAST NAME
        LDY     ,X++                              ;GET LENGTH
        STY     TEMP1                             ;SAVE ADDRESS
        CLR     TEMP2                             ;SET ZERO OFFSET
        CLR     TEMP2+1                           ;SET ZERO OFFSET
        CMPA    #$60                              ;IS IT LABEL TYPE SYMBOL?
        BEQ     RMSYM                             ;IF SO, IT'S A SPECIAL CASE
;* DETERMINE SIZE OF SYMBOL
ERANXT
        LDY     FREE                              ;USE FREE FOR OFFSET
        LDB     ,X                                ;GET TYPE/LENGTH
        TFR     B,A                               ;COPY
        ANDA    #$E0                              ;MASK OFF LENGTH
        ANDB    #$1F                              ;MASK OFF TYPE
        BEQ     FREOFF                            ;END OF TABLE, REMOVE IT
        ADDB    #2                                ;ADVANCE PAST TYPE/LENGTH, NEST BYTES
        ABX                                       ;	SKIP NAME AS WELL
        LDY     ,X++                              ;GET ADDRESS
        CMPA    #$60                              ;IS IT LABEL TYPE SYMBOL?
        BEQ     ERANXT                            ;IF SO, CONTINUE LOOKING
FREOFF
        TFR     Y,D                               ;GET ADDRESS
        SUBD    TEMP1                             ;CONVERT TO OFFSET
        STD     TEMP2                             ;SAVE OFFSET
;* REMOVE SYMBOL TABLE ENTRY, AND ADJUST ADDRESSES
RMSYM
        PULS    X                                 ;RESTORE POINTER TO SYMBOL
        LDB     ,X                                ;GET LENGTH
        ANDB    #$1F                              ;MASK OFF LENGTH
        ADDB    #4                                ;OFFSET TO NEXT
        LEAY    B,X                               ;POINT TO NEXT SYMBOL
RMS1
        LDB     ,Y+                               ;GET CHAR FROM SYMBOL
        STB     ,X+                               ;SAVE
        TFR     B,A                               ;COPY
        ANDA    #$E0                              ;MASK LENGTH
        ANDB    #$1F                              ;CALCULATE LENGTH
        BEQ     RMS2                              ;IF END, QUIT
        ADDB    #3                                ;OFFSET FOR NEXT
        PSHS    A                                 ;SAVE SYMBOL TYPE
RMS11
        LDA     ,Y+                               ;GET BYTE
        STA     ,X+                               ;SAVE
        DECB                                      ;	REDUCE COUNT
        BNE     RMS11                             ;CONTINUE COPYING
        PULS    A                                 ;RESTORE TYPE
        CMPA    #$60                              ;LABEL TYPE?
        BEQ     RMS1                              ;IF SO, FORGET IT
        LDD     -2,X                              ;GET ADRESS
        SUBD    TEMP2                             ;SUBTRACT OFFSET
        STD     -2,X                              ;RESAVE
        BRA     RMS1                              ;AND CONTINUE
;* MOVE MEMORY BACK REQUIRED AMOUNT
RMS2
        LDD     TEMP2                             ;GET OFFSET
        BEQ     NOMOVE                            ;DON'T MOVE IF NO OFFSET
        LDY     TEMP1                             ;GET SYMBOL ADDRESS
        LEAX    D,Y                               ;POINT TO NEW LOCATION
        CMPX    FREE                              ;SPACIAL CASE FOR LAST VARIABLE IN TABLE
        BHS     SAVFRE                            ;IF SO, SAVE IT
RMS3
        LDA     ,X+                               ;GET FROM MEMORY
        STA     ,Y+                               ;SAVE IN OLD LOCATION
        CMPX    FREE                              ;ARE WE OVER
        BLO     RMS3                              ;GO FOR IT
SAVFRE
        STY     FREE                              ;RESAVE
NOMOVE
        RTS
;* ')SI' COMMAND
SI
        LDX     NAMPTR                            ;POINT TO NAME
        LDD     LINCT                             ;GET LINE COUNTER
        LDY     SAVSTK                            ;POINT TO SAVED STACK POINTER
        CMPY    #STACK                            ;AT TOP?
        BEQ     NOSUSP                            ;NONE
SI1
        LBSR    DSPNAM                            ;DISPLAY
        LDX     ,Y                                ;GET POINTER TO LOCAL VARIABLE LIST
        LBSR    OULI                              ;DISPLAY VARIABLES
        LDX     10,Y                              ;POINT TO NAME
        LDD     8,Y                               ;GET LINE NUMBER
        LDY     2,Y                               ;GET NEXT SAVED STACK POINTER
        CMPY    #STACK                            ;ARE WE AT TOP?
        BNE     SI1                               ;CONTINUE
        RTS
;* ')REL' RELEASE ONE SUSPENDED FUNCTION
RELEAS
        LDY     SAVSTK                            ;GET STACK POINTER
        CMPY    #STACK                            ;AT TOP?
        BEQ     NOSUSP                            ;INDICATE NOTHING TO BE EXCITED ABOUT
REL1
        PULS    A,B                               ;GET PROGRAM COUNTER
        STD     16,Y                              ;SET RETURN ADDRESS
        TFR     Y,S                               ;COPY IT OVER
        LBRA    EFUNC                             ;AND DO IT
NOSUSP
        LBSR    SYSMSG                            ;DISPLAY MESSAGE
        FCN     'NO SI IN WS'
        RTS
;* PERFORM A RESET
DOREST
        PULS    A,B                               ;GET PC
        STD     TEMP4                             ;SAVE VALUE
DORES1
        LDY     SAVSTK                            ;CKECK FOR STACK EMPTY
        CMPY    #STACK                            ;ARE WE AT TOP?
        BEQ     CLALL                             ;IF SO, CLEAR IT
        BSR     REL1                              ;RELEASE THIS BUNCH
        BRA     DORES1                            ;AND CONTINUE
CLALL
        LDD     #HIRAM                            ;TOP OF RAM
        STD     RAMTOP                            ;SET UP RAM TOP
        LDD     #IOTA0                            ;POINT TO NULL VECTOR
        STD     PARM                              ;SET UP PARAMETER VALUE
        CLR     LEVEL                             ;SET LEVEL ZERO
        JMP     [TEMP4]                           ;RETURN TO CALLER
;* ')STATUS' COMMAND
STATUS
        LBSR    DSPSTR                            ;DISPLAY STRING
        FCN     'WORKSPACE NAME: '
        LBSR    DWSID                             ;DISPLAY IT
        LBSR    DSPSTR                            ;DISPLAY STRING
        FCN     'SYMBOLS IN USE: '
        LDY     #$0                               ;INDICATE ZERO SYMBOLS
        LDX     #SYMTAB                           ;POINT TO START OF TABLE
STSYM
        LDB     ,X+                               ;GET STARTING VALUE
        ANDB    #$1F                              ;MASK TYPE BITS
        BEQ     STSY1                             ;END OF TABLE
        LEAY    1,Y                               ;THIS IS ONE
        ADDB    #3                                ;OFFSET FOR SYMBOL TABLE ENTRIES
        ABX                                       ;	ADVANCE
        BRA     STSYM                             ;CONTINUE LOOKING
STSY1
        TFR     Y,D                               ;COPY TO D
        LBSR    DECOUT                            ;DISPLAY IT
        PSHS    X                                 ;SAVE X
        LBSR    DSPSTR                            ;DISPLAY STRING
        FCB     $0D
        FCN     'SYMBOL TABLE SIZE: '
        LDD     FREMEM                            ;POINT TO END OF SYMBOL TABLE
        SUBD    #SYMTAB+1	CONVERT TO SIMPLE OFFSET
        LBSR    DECOUT                            ;DISPLAY IT
        LBSR    DSPSTR                            ;DISPLAY STRING
        FCB     $0D
        FCN     'SYMBOL TABLE FREE: '
        LDD     FREMEM                            ;GET FREE MEMORY SPACE
        SUBD    ,S++                              ;CONVERT TO BINARY VALUE
        LBSR    DECOUT                            ;DISPLAY
        LBSR    DSPSTR                            ;DISPLAY STRING
        FCB     $0D
        FCN     'WORKSPACE REMAINING: '
        LDD     RAMTOP                            ;POINT TO TOP OF RAM
        SUBD    FREE                              ;CONVERT TO FREE SPACE
        LBSR    DECOUT                            ;DISPLAY
        LBRA    LFCR                              ;NEW LINE
;* UNKNOWN SYSTEM COMMAND
UNCMD
        LBSR    SYSMSG
        FCN     'INCORRECT COMMAND'
        RTS
;* SYSTEM ERROR HAS OCCURED
SYSERR
        PSHS    A,B,X,Y
        LBSR    SYSMSG
        FCN     'SYSTEM ERROR'
        PULS    A,B                               ;; Get D
        SWI
        FCB     27
        SWI
        FCB     21
        PULS    A,B                               ;; Get X
        SWI
        FCB     27
        SWI
        FCB     21
        PULS    A,B                               ;; Get Y
        SWI
        FCB     27
        SWI
        FCB     21
        PULS    A,B                               ;; Get PC
        SWI
        FCB     27
        SWI
        FCB     21
        TFR     S,D                               ;; Get S
        SWI
        FCB     27
        SWI
        FCB     21
        TFR     U,D                               ;; Get U
        SWI
        FCB     27
        SWI
        FCB     22
        LBRA    CMD
;*
;* SYSTEM COMMAND TEXT TABLE
;*
CMDTAB
        FCC     'OF'
        FCB     'F'+$80
        FDB     OFF
        FCC     'CLEA'
        FCB     'R'+$80
        FDB     CLEAR
        FCC     'FN'
        FCB     'S'+$80
        FDB     FNS
        FCC     'VAR'
        FCB     'S'+$80
        FDB     VARS
        FCC     'LBL'
        FCB     'S'+$80
        FDB     LBLS
        FCC     'SY'
        FCB     'S'+$80
        FDB     SYSTEM
        FCC     'LI'
        FCB     'B'+$80
        FDB     LIB
        FCC     'WSI'
        FCB     'D'+$80
        FDB     WSID
        FCC     'SAV'
        FCB     'E'+$80
        FDB     SAVE
        FCC     'LOA'
        FCB     'D'+$80
        FDB     LOAD
        FCC     'DRO'
        FCB     'P'+$80
        FDB     DROP
        FCC     'ERAS'
        FCB     'E'+$80
        FDB     ERASE
        FCC     'S'
        FCB     'I'+$80
        FDB     SI
        FCC     'RE'
        FCB     'L'+$80
        FDB     RELEAS
        FCC     'RESE'
        FCB     'T'+$80
        FDB     RESET
        FCC     'CONTINU'
        FCB     'E'+$80
        FDB     CONCMD
        FCC     'STA'
        FCB     'T'+$80
        FDB     STATUS
        FCB     $80
        FDB     UNCMD
;* DEFAULT VECTOR STRING, EMPTY NUMERIC VECTOR
IOTA0
        FCB     $01                               ;TYPE = NUMERIC
        FDB     0                                 ;LENGTH = ZERO
;*
;* STRINGS
;*
DEFNAM
        FCC     '*.APL'
        FCB     $0D
        FCC     'e@LX'
        FCB     $0D
LXNAME          =                                 *-2
CONTIN
        FCN     'CONTINUE.APL'
;*
;* STANDARD OPERATING SYSTEM INTERFACE, SUPPORTS
;* OPERATING SYSTEM COMMANDS, AND FILE I/O
;* ON ENTRY, 'X' POINT TO LEFT OPERAND, 'Y' POINTS TO RIGHT OPERAND
;*
;* FUNCTIONS:
;*   0 - EXECUTE DOS COMMAND
;*   1 - OPEN FILE/READ
;*   2 - OPEN FILE/WRITE
;*   3 - TEST FOR FILE EXISTANCE
;*   4 - READ MEMORY (ADDR, ADDR, ADDR ...)
;*   5 - WRITE MEMORY (ADDR, DATA, DATA ...)
;*   6 - EXECUTE ssr (IN=ssr,AB,X,Y,U - OUT=RC,AB,X,Y,U)
;*   <file>o<char>   - Write file
;*   <file>o0	    - Read file
;*   <file>o1	    - Close file
;*   <file>o2	    - Rewind file
;*
OSFUNC
        LDA     ,X                                ;GET TYPE
        DECA                                      ;	INTEGER
        LBNE    CDOM                              ;ERROR
        LDD     1,X                               ;GET LENGTH
        CMPD    #261                              ;SPECIAL FILE STUFF?
        LBEQ    OSFILE                            ;ITS A FILE ACCESS
;* NON FILE ACCESS
OSFNF
        CMPD    #1                                ;FUNCTION CODE
        LBNE    CLEN                              ;OUT OF RAMGE
        LDD     3,X                               ;GET VALUE
        TSTA                                      ;	HIGH ZERO?
        LBNE    CDOM                              ;ERROR
;* CHECK FOR EXECUTE OPERATING SYSTEM COMMAND
        TSTB
        BNE     OSOPEN                            ;NO, TRY OPEN
        LBSR    OSROT                             ;ROTATE IT
        LDA     #$0D                              ;GET CR, TERMINATE COMMAND
        STA     ,U                                ;SAVE IT
        LEAY    3,Y                               ;POINT TO COMMAND
        SWI
        FCB     100                               ;EXECUTE
OSAVRC
        BEQ     OSRCZ                             ;RC IS ZERO
        TFR     A,B                               ;COPY TO B
        BRA     OSRC1                             ;RETURN RC
OSRCZ
        CLRB                                      ;	SET ZERO RC
OSRC1
        CLRA                                      ;	CLEAR HIGH BYTE
OSRES
        LDX     2,S                               ;GET POINTER BACK
        STD     3,X                               ;SAVE VALUE
        LDB     #1                                ;GET TYPE AND LENGTH
        STB     ,X                                ;SAVE IT
        STD     1,X                               ;SAVE LENGTH
        RTS
;* OPEN FILE FOR READ
OSOPEN
        DECB                                      ;	TEST FOR OPEN READ
        BNE     OSOPW                             ;NO, TRY FOR OPEN WRITE
        LBSR    OSROT                             ;SWAP IT
        CLR     ,U                                ;INDICATE END
        LEAY    3,Y                               ;PT TO TEXT
        SWI
        FCB     10                                ;GET IT
        BNE     OSAVRC                            ;INVALID
        LDU     2,S                               ;PT TO OPERAND
        LDD     #261                              ;LENGTH
        STA     ,U+                               ;SAVE TYPE
        STD     ,U++                              ;SAVE LENGTH
        SWI
        FCB     55                                ;OPEN FOR READ
        BNE     OSAVRC                            ;INDICATE OK
        RTS
;* OPEN FILE FOR OUTPUT
OSOPW
        DECB                                      ;	OPEN FOR WRITE?
        BNE     OSTFIL                            ;NO, TRY CLOSE
        LBSR    OSROT                             ;SWAP IT
        CLR     ,U                                ;SET TERMINATOR
        LEAY    3,Y                               ;DO IT
        SWI
        FCB     10                                ;OK?
        BNE     OSAVRC                            ;NO, GET UPSET
        LDU     2,S                               ;PT TO OPERAND
        LDD     #261                              ;SIZE OPERAND
        STA     ,U+                               ;SET TYPE
        STD     ,U++                              ;SAVE LENGTH
        SWI
        FCB     56                                ;OPEN FILE FOR WRITE
        BNE     OSAVRC                            ;SAVE RC
OSRM2
        RTS
;* TEST FOR FILE EXISTANCE
OSTFIL
        DECB                                      ;	TEST FOR FILE?
        BNE     OSRMEM                            ;NO, TRY NEXT
        LBSR    OSROT                             ;ROTATE OPERAND
        CLR     ,U                                ;SET DELIMITER
        LEAY    3,Y                               ;ADVANCE
        SWI
        FCB     10                                ;GET FILENAME
        BNE     OSAVRC                            ;BAD, QUIT
        SWI
        FCB     68                                ;LOOK FOR IT
        BRA     OSAVRC                            ;SAVE RC
;* READ MEMORY
OSRMEM
        LDA     ,Y                                ;INTEGER DATA ONLY
        CMPA    #1                                ;INTEGER?
        LBNE    CDOM                              ;ERROR, WRONG TYPE
        DECB                                      ;	READ MEMORY?
        BNE     OSWMEM                            ;WRITE MEMORY
        LDD     1,Y                               ;GET LENGTH
        PSHS    A,B                               ;SAVE PTR
        LEAY    3,Y                               ;ADVANCE TO DATA
OSRM1
        LDD     ,S++                              ;GET COUNT
        BEQ     OSRM2                             ;EXIT
        SUBD    #1                                ;REDUCE COUNT
        STD     ,--S                              ;RESAVE
        LDX     ,Y                                ;GET ADDRESS
        LDB     ,X                                ;GET DATA
        CLRA                                      ;	ZERO HIGH
        STD     ,Y++                              ;SET VALUE
        BRA     OSRM1                             ;AND CONTINUE
;* WRITE MEMORY
OSWMEM
        DECB                                      ;	WRITE MEMORY?
        BNE     OSSSR                             ;NO, TRY OSR
        LDD     1,Y                               ;GET LENGTH
        LBEQ    CLEN                              ;ZERO LENGTH INVALID
        SUBD    #1                                ;CONVERT
        STD     1,Y                               ;SET LENGTH TO L-1
        PSHS    A,B                               ;SAVE REGS
        ROLB                                      ;	X2
        LSLA                                      ;	FOR INTEGER ENTRIES
        LEAY    3,Y                               ;ADVANCE TO DATA
        LEAY    D,Y                               ;POINT TO DATA
        LDX     ,Y                                ;GET ADDRESS
OSWM1
        LDD     ,S++                              ;GET COUNT
        BEQ     OSRM2                             ;END, EXIT
        SUBD    #1                                ;REDUCE LENGTH
        STD     ,--S                              ;RESAVE
        LDD     ,--Y                              ;GET DATA TO WRITE
        LDA     ,X                                ;GET OLD DATA
        STB     ,X+                               ;WRITE NEW DATA
        EXG     A,B                               ;SWAP
        CLRA                                      ;	ZERO HIGH
        STD     ,Y                                ;AND REWRITE
        BRA     OSWM1                             ;CONTINUE
;* PERFORM A DOS SYSTEM REQUEST
OSSSR
        DECB                                      ;	IS THIS IT?
        LBNE    CDOM                              ;NO, EXIT
        LDD     1,Y                               ;GET LENGTH
        CMPD    #5                                ;FOUR ELEMENTS?
        LBNE    CLEN                              ;LENGTH ERROR
        LDD     11,Y                              ;GET SSR NUMBER
        STB     OSSRNO+1	SET IT
        LDD     9,Y                               ;GET A,B
        LDX     7,Y                               ;GET X
        LDU     3,Y                               ;GET 'U'
        LDY     5,Y                               ;GET 'Y'
OSSRNO
        SWI
        FCB     0                                 ;SYSTEM REQUEST
        PSHS    CC,X                              ;SAVE REGS
        LDX     5,S                               ;GET PTR TO DATA
        STU     3,X                               ;SAVE 'U'
        STY     5,X                               ;SAVE 'Y'
        STD     9,X                               ;SAVE 'A'+'B'
        TFR     A,B                               ;B = RC
        PULS    CC,Y                              ;RESTORE REGS
        BNE     OSSR                              ;NON-ZERO
        CLRB
OSSR
        CLRA                                      ;	ZERO HIGH
        STD     11,X                              ;SET RC
        STY     7,X                               ;SET 'X' VALUE
        RTS
;* ACCESSING A FILE
OSFILE
        LEAU    3,X                               ;SET UP FILE PTR
        LDA     ,Y+                               ;TEST TYPE
        BNE     OSFFUN                            ;FILE FUNCTIONS
;* WRITE FILE
        LDX     ,Y+                               ;GET LENGTH
        BEQ     OSWR2                             ;NULL LINE
OSWR1
        TFR     X,D                               ;COPY IT
        LDA     D,Y                               ;GET CHARACTER
        SWI
        FCB     61                                ;WRITE CHAR
        BNE     OSAVR2                            ;ERROR, RETURN CODE
        LEAX    -1,X                              ;REDUCE COUNT
        BNE     OSWR1                             ;AND CONTINUE
OSWR2
        LDA     #$0D                              ;CR
        SWI
        FCB     61                                ;WRITE CHARACTER
        BRA     OSAVR2                            ;AND EXIT
;* OTHER FILE FUNCTIONS
OSFFUN
        LDD     ,Y++                              ;GET LENGTH
        CMPD    #1                                ;PROPER?
        LBNE    CLEN                              ;NO
        LDD     ,Y                                ;GET VALUE
        TSTA
        LBNE    CDOM                              ;OUT OF RAMGE
;* READ DATA FILE FILE
        TSTB                                      ;	ZERO?
        BNE     OSFCLO                            ;CLOSE FILE
        CLR     -3,Y                              ;INDICATE CHARACTER
        LDX     #-1                               ;START WITH -1
OSRE1
        SWI
        FCB     59                                ;READ CHARACTER FROM FILE
        BNE     OSAVR2                            ;ERROR
        STA     ,Y+                               ;SAVE IN DATA AREA
        LEAX    1,X                               ;INCREASE LENGTH
        CMPA    #$0D                              ;CR?
        BNE     OSRE1                             ;CONTINUE
        LDY     2,S                               ;GET PTR BACK
        STX     1,Y                               ;SET LENGTH
;* ROTATE OPERAND VALUE(Y)
OSROT
        PSHS    Y                                 ;SAVE REGISTERS
        TST     ,Y                                ;WHAT FORM ARE WE
        LBNE    CDOM                              ;REVERSING CHARACTER ARRAY
        LDD     1,Y                               ;GET LENGTH
        BEQ     OSREND                            ;NOTHING TO DO
        LEAX    3,Y                               ;GET START OF VECTOR
        LEAY    D,X                               ;SKIP TO END
        TFR     Y,U                               ;COPY IT
OSREV
        LDA     ,-Y                               ;GET CHARACTER
        LDB     ,X+                               ;AND GET OTHER CHARACTER
        PSHS    X                                 ;SAVE POSITION
        CMPY    ,S++                              ;ARE WE THERE?
        BLO     OSREND                            ;IF SO, EXIT
        STB     ,Y                                ;SET NEW VALUE
        STA     -1,X                              ;AND NEW VALUE HERE
        BRA     OSREV                             ;CONTINUE REVERSING
OSREND
        PULS    Y,PC                              ;RESTORE REGISTERS
;* CLOSE FILE
OSFCLO
        DECB
        BNE     OSFREW                            ;TRY REWIND
        SWI
        FCB     57                                ;CLOSE FILE
OSAVR2
        LBRA    OSAVRC                            ;AND RETURN
;* REWIND FILE
OSFREW
        DECB
        LBNE    CDOM                              ;NOT REWIND, EXIT
        SWI
        FCB     62                                ;REWIND FILE
        BRA     OSAVR2                            ;RETURN CODE
