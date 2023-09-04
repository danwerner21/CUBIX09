;***************************************************************************
;*                           CUBIX HELP UTILITY.                           ;*
;*-------------------------------------------------------------------------;*
;* ACCESSES HELP INFORMATION FROM A HELP LIBRARY, IN THE DIRECTORY [HELP]. ;*
;* DEFAULT HELP LIBRARY IS THE FILE [HELP]SYSTEM.HLP. OTHER HELP LIBRARYS  ;*
;* CAN BE SPECIFIED USING THE OPERATOR '/'. EG: 'HELP /LIBRARY <OPERANDS>' ;*
;* WOULD USE THE FILE [HELP]LIBRARY.HLP AS THE HELP LIBRARY.               ;*
;*-------------------------------------------------------------------------;*
;* LIBRARY FILE FORMAT IS AS FOLLOWS:                                      ;*
;*                                                                         ;*
;* ANY TEXT IN THE FILE UP TO THE START OF SUBCLASS CHARACTER '{' IS DISP- ;*
;* DISPLAYED FOR HELP WITHOUT OPERANDS (THE BASE NEST LEVEL). THE NAMES OF ;*
;* ANY SUBCLASS'S ARE DISPLAYED UNDER 'Additional information available:'  ;*
;* A SUBCLASS OF HELP IS A SECTION OF TEXT, ENCLOSED BEWEEN THE CHARACTERS ;*
;* '{' AND '}'. THE SUBCLASS NAME IS A SINGLE (UNBROKEN)  WORD  IMMEDIATLY ;*
;* FOLLOWING THE '{', AND IS THE NAME  DISPLAYED  UNDER  ADDITIONAL  INFO. ;*
;* THE SUBCLASS NAME, AND THE REMAINDER OF THE LINE IT IS ON IS THE  TITLE ;*
;* OF THE SUBCLASS, AND IS DISPLAYED WHENEVER IT OR ONE OF IT'S SUBCLASSES ;*
;* IS ACCESSED. SUBCLASSES MAY BE CONTAINED WITHIN SUBCLASSES, PROVIDING A ;*
;* COMPLETE TREE STRUCTURE FOR HELP INFORMATION.  HELP  FOR  A  PARTICULAR ;*
;* SUBCLASS IS OBTAINED BY ADDING THE SUBCLASS NAME TO THE  PARAMETERS  TO ;*
;* HELP COMMAND. EG: 'HELP /LIBRARY SUBCLASS1 SUBCLASS1.1 ETC...'          ;*
;*-------------------------------------------------------------------------;*
;*                       SAMPLE HELP FILE:                                 ;*
;* This text is displayed whenever a help command is issued with no  other ;*
;* operands (except the library if specified). It  should  contain  simple ;*
;* instructions on using HELP etc.                                         ;*
;* {SUB1 (First subclass of main help)                                     ;*
;*  This information is displayed for 'HELP SUB1'}                         ;*
;* {SUB2 (Second subclass of help)                                         ;*
;*  This information is displayed for 'HELP SUB2'                          ;*
;* {SUB2.1 (First subclass of SUB2)                                        ;*
;*  This information is displayed for 'HELP SUB2 SUB2.1'}}                 ;*
;* {SUB3 (Third subclass of help)                                          ;*
;*  This information is displayed for 'HELP SUB3'.                         ;*
;* {SUB3.1 (First subclass of SUB3)                                        ;*
;*  This information is displayed for 'HELP SUB3 SUB3.1'                   ;*
;* {SUB3.1.1 (First subclass of SUB3.1)                                    ;*
;*  This information is displayed for 'HELP SUB3 SUB3.1 SUB3.1.1'.}        ;*
;* {SUB3.1.2 (Second subclass of SUB3.1)                                   ;*
;*  This information is displayed for 'HELP SUB3 SUB3.1 SUB3.1.2'.}}       ;*
;* {SUB3.2 (Second subclass of SUB3)                                       ;*
;*  This information is displayed for 'HELP SUB3 SUB3.2'}}                 ;*
;***************************************************************************
;*                         SAMPLE USAGE:                                   ;*
;*  ;*HELP SUB3 SUB3.1          <-- ;*NOTE: DEFAULT LIBRARY [HELP]SYSTEM.HLP ;*
;*  SUB3 (Third subclass of help)                                          ;*
;*  SUB3.1 (First subclass of SUB3)                                        ;*
;*                                                                         ;*
;*   This information is displayed for 'HELP SUB3 SUB3.1'                  ;*
;*                                                                         ;*
;*   Additional information available:                                     ;*
;*                                                                         ;*
;*   SUB3.1.1           SUB3.1.2                                           ;*
;*   ;*                                                                     ;*
;*-------------------------------------------------------------------------;*
;*                                             D. F. DUNFIELD, JAN 14/1984 ;*
;***************************************************************************
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
BTXT            = '{'                             ;BEGINNING OF TEXT CHARACTER
ETXT            = '}'                             ;END OF TEXT CHARACTER
;*
        ORG     0
DPREFIX
        RMB     8
DNAME
        RMB     8
DTYPE
        RMB     3
DDADR
        RMB     2
DRADR
        RMB     2
DATTR
        RMB     1
;*
        ORG     OSUTIL                            ;DOS UTILITY SPACE
HELP
        CMPA    #'?'                              ;EXPLAIN R=EST?
        BNE     MAIN                              ;NO, TRY MAIN PGM
        SWI
        FCB     25                                ;MESSAGE
        FCN     'Use: HELP[/<library>] [<topic>] [<subtopic>] ...'
        RTS
MAIN
        STS     SAVSP                             ;SAVE OUR STACK POINTER
        LDS     #INPBUF+$7F	SET UP STACK
        PSHS    Y                                 ;SAVE COMMAND POINTER
        LDY     #DEFNAM                           ;PT TO DEFAULT
        SWI
        FCB     12                                ;READ IT IN
        LDA     -1,X                              ;GET SYSTEM DRIVE
        LDX     #DEFDIR                           ;PT TO IT
        STA     ,X                                ;SET DEFAULT TO SYSTEM DRIVE
        LDY     #DEFNAM                           ;PT TO NAME AGAIN
        SWI
        FCB     13                                ;GET NAME (WITH PROPER DIR DEFAULT)
        PULS    Y                                 ;RESTORE Y
        SWI
        FCB     4                                 ;ADVANCE TO NEXT
        CMPA    #'/'                              ;HELP LIBRARY?
        BNE     NOUFIL                            ;NOT A USER SUPPLIED FILE
        LEAY    1,Y                               ;SKIP '/'
        LDX     #DEFDIR                           ;POINT TO DEFAULT FILENAME
        SWI
        FCB     13
        LBNE    ABORT                             ;INVALID, QUIT
NOUFIL
        LDD     #$484c                            ;'HL'
        STD     ,X
        LDA     #'P'
        STA     2,X
HELP1
        LDD     #OPLIN                            ;POINT TO OPERAND LINE
        STD     OPPOS                             ;SAVE OPERAND POSITION
        CLR     IDENT                             ;DO NOT INDENT
        CLR     ERRFLG                            ;CLEAR ERROR FLAG
        SWI
        FCB     70                                ;LOOKUP FOR READ
        BNE     ABORT                             ;IF NOT THERE, GET UPSET
        LDD     DDADR,X                           ;GET SECTOR
        STD     >WRKSEC
        LDX     #WRKSPC                           ;PT TO IT
        STX     >WRKOFF
        SWI
        FCB     92                                ;READ WORK
        SWI
        FCB     4                                 ;CHECK FOR PARAMETERS
        LBNE    OPRND                             ;OPERAND WAS PRESENT
;* GENERAL HELP
GENHLP
        LBSR    RDCHR                             ;GET CHARACTER FROM SOURCE
        LBNE    CLOSE                             ;IF ERROR, CLOSE
        CMPA    #BTXT                             ;END OF TEXT?
        BEQ     SUBSUM                            ;SUMMARIZE SUB CLASSES
        LBSR    OUTCHR                            ;OUTPUT CHARACTER
        BRA     GENHLP                            ;KEEP GOING
;* ABORT TO DOS
ABORT
        LDS     SAVSP                             ;RETURN TO DOS
        TSTA                                      ;	SET RETURN CODE
        RTS
SUBSUM
        SWI
        FCB     22                                ;NEW LINE
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'Additional information available:'
SUBNEW
        LDA     #4                                ;FOUR NAMES/LINE
        STA     NUMOUT                            ;NUMBER OF NAMES OUTPUT
        SWI
        FCB     22                                ;NEW LINE
DSPNXT
        LDB     #19                               ;MAX NINTEEN CHARACTERS
OUTSUB
        LBSR    RDCHR                             ;GET CHARACTER FROM SOURCE
        BNE     ENSUB                             ;END OF SUB
        CMPA    #' '                              ;TEST FOR TERMINATOR
        BEQ     ENSUB                             ;END OF SUB
        CMPA    #$0D                              ;TEST FOR TERMINATOR
        BEQ     ENSUB                             ;END OF SUB
        DECB                                      ;	REDUCE COUNT
        LBSR    OUTCHR                            ;OUTPUT
        BRA     OUTSUB                            ;KEEP GOING
ENSUB
        SWI
        FCB     21                                ;SPACE
        DECB                                      ;	REDUCE COUNT
        BNE     ENSUB                             ;KEEP GOING
        LBSR    SKPEND                            ;SKIP TO END OF THIS ONE
        LBSR    FNDSEC                            ;FIND ANOTHER SECTOR
        BNE     ASKHLP                            ;GO HOME AND QUIT
        DEC     NUMOUT                            ;REDUCE NUMBER OUTPUT
        BNE     DSPNXT                            ;DISPLAY NEXT NAME
        BRA     SUBNEW                            ;START A NEW LINE
;* PROMPT FOR EXTRA INFO
ASKHLP
        SWI
        FCB     22                                ;NEW LINE
NXTCMD
        LDX     #OPLIN                            ;POINT TO START OF LINE
        SWI
        FCB     22                                ;NEW LINE
        LDY     #INPBUF                           ;POINT TO INPUT BUFFER
WRTPI
        CMPX    OPPOS                             ;ARE WE AT END
        BHS     PRMPT                             ;PROMPT FOR INPUT
        LDA     ,X+                               ;GET CHARACTER
        STA     ,Y+                               ;SAVE Y POINTER
        SWI
        FCB     33                                ;OUTPUT
        BRA     WRTPI                             ;KEEP GOING
PRMPT
        CMPX    #OPLIN                            ;ARE WE AT BEGINNING
        BEQ     PRMP1                             ;IF SO, SKIP PREFIX
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     'Sub'                             ;PREFIX
PRMP1
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     'Topic? '                         ;MESSAGE
        STY     NUMOUT                            ;SAVE POINTER TO INPUT BUFFER
        TFR     Y,X                               ;MOVE TO INPUT BUFFER
INPT
        CMPX    NUMOUT                            ;ARE WE BELOW OPERAND?
        BLO     NXTCMD                            ;IF SO, ISSUE AGAIN
        SWI
        FCB     34                                ;GET KEY
        CMPA    #$7F                              ;DELETE
        BNE     NOTDEL                            ;NOT A DELETE
        LDA     #8                                ;CONVERT TO BS
NOTDEL
        SWI
        FCB     33                                ;OUTPUT
        CMPA    #3                                ;CTRL-C?
        LBEQ    NOERR1                            ;IF SO, EXIT
        CMPA    #$61                              ;ARE WE UPPER CASE?
        BLO     UCASE                             ;IF SO, IT'S OK
        ANDA    #$5F                              ;CONVERT TO UPPER
UCASE
        LEAX    -1,X                              ;BACKUP
        CMPA    #8                                ;IS IT DELETE?
        BEQ     INPT                              ;IF SO, TRY AGAIN
        LEAX    1,X                               ;FIX MISTAKE
        STA     ,X+                               ;AND SAVE CHARACTER
        CMPA    #$0D                              ;END OF LINE?
        BNE     INPT                              ;GET ANOTHER CHARACTER
        SWI
        FCB     4                                 ;TEST FOR NULL LINE
        BEQ     BACKUP                            ;IF SO, BACKUP
        LDD     ,Y                                ;GET CONTENTS OF LINE
        CMPD    #$3F0D                            ;IS IT QUERY?
        BNE     NOQUE                             ;NO, SKIP
        STB     ,Y                                ;CHANGE TO NULL LINE
NOQUE
        LDY     #INPBUF                           ;POINT TO LINE
        SWI
        FCB     22                                ;NEW LINE
        LDS     SAVSP                             ;RESTORE STACK
        LBRA    HELP1                             ;TRY AGAIN
BCKSKP
        SWI
        FCB     22                                ;NEW LINE
BACKUP
        LDX     OPPOS                             ;GET OPERAND POSITION
        CMPX    #OPLIN                            ;ARE WE AT BEGINNING?
        LBLS    NOERR1                            ;IF SO, STOP NOW
        LEAX    -1,X                              ;BACKUP PAST SPACE
BACK1
        CMPX    #OPLIN                            ;ARE WE AT START OF LINE
        BEQ     GONXT                             ;IF SO, QUIT
        LDA     ,-X                               ;BACKUP
        CMPA    #' '                              ;IS IT SPACE?
        BNE     BACK1                             ;NO, TRY AGAIN
        LEAX    1,X                               ;SKIP AHEAD SPACE
GONXT
        STX     OPPOS                             ;RESAVE POSITION
        LBRA    NXTCMD                            ;TRY AGAIN
;*
;* OPERAND WAS SUPPLIED
;*
OPRND
        DEC     ERRFLG                            ;SET ERROR FINDING FLAG
        LBSR    FNDSEC                            ;FIND A SECTION
        LBNE    CLOSE                             ;IF NO MORE, STOP
        LDD     >WRKSEC
        LDX     >WRKOFF
        PSHS    A,B,X                             ;SAVE REGISTERS
        TFR     Y,X                               ;COPY TO X
        LDU     #SNGLOP                           ;POINT TO SINGLE OPERAND
CHKPRM
        LDA     ,X                                ;GET CHARACTER
        CMPA    #' '                              ;SPACE?
        BEQ     ENDCMP                            ;END OF COMPARE, SUCESS
        CMPA    #$0D                              ;CARRIAGE RETURN
        BEQ     ENDCMP                            ;END OF COMPARE, SUCESS
        LBSR    RDCHR                             ;READ A CHARACTER
        STA     ,U+                               ;SAVE IN SINGLE OPERAND
        CMPA    ,X+                               ;IS IT SAME?
        BEQ     CHKPRM                            ;IF SO, ALL SET
        LBSR    SKPEND                            ;SKIP TO END
        PULS    A,B,X                             ;Clean stack
        BRA     OPRND                             ;TRY AGAIN
ENDCMP
        LBSR    RDCHR                             ;GET CHARACTER FROM FILE
        STA     ,U+                               ;SAVE IN BUFFER
        CMPA    #' '                              ;IS IT SPACE?
        BEQ     ENDC1                             ;IF SO, QUIT
        CMPA    #$0D                              ;IS IT CARRIAGE RETURN
        BNE     ENDCMP                            ;IF NOT, KEEP COPYING
ENDC1
        LDA     #' '                              ;GET SPACE
        STA     -1,U                              ;RESET END INDICATOR
        TFR     X,Y                               ;COPY TO Y
        LDX     OPPOS                             ;POINT TO OPERAND LINE
        LDU     #SNGLOP                           ;POINT TO OPERAND
DMPOP
        LDA     ,U+                               ;GET CHARACTER FROM LINE
        STA     ,X+                               ;SAVE IN LINE
        CMPA    #' '                              ;IS IT END OF OPERAND
        BNE     DMPOP                             ;IF SO, LET HIM KNOW
        STX     OPPOS                             ;SAVE OPERAND POSITION
        PULS    A,B,X                             ;RESTORE REGISTERS
        STD     >WRKSEC
        STX     >WRKOFF
        LDX     #WRKSPC                           ;PT TO WORK AREA
        SWI
        FCB     92                                ;READ WORK SECTOR
        SWI
        FCB     22                                ;NEW LINE
        INC     >IDENT                            ;ADVANCE INDENT POSITION
        LDA     >IDENT                            ;GET INDENT
IND1
        DECA                                      ;	REDUCE INDENT COUNT
        BEQ     OUTLIN                            ;IF ZERO, THEN ALL SET
        SWI
        FCB     21                                ;INDENT ONE SPACE
        SWI
        FCB     21                                ;INDENT ONE SPACE
        BRA     IND1                              ;CHECK FOR NEXT INDENT
OUTLIN
        LBSR    RDCHR                             ;GET LINE
        LBNE    CLOSE                             ;IF ERROR, CLOSE
        LBSR    OUTCHR                            ;DISPLAY
        CMPA    #$0D                              ;TEST FOR CARRIAGE RETURN
        BNE     OUTLIN                            ;KEEP DISPLAYING
        CLR     ERRFLG                            ;CLEAR ERROR FLAG AS WE FOUND
        SWI
        FCB     4                                 ;CHECK FOR MORE PARAMETERS
        LBNE    OPRND                             ;IF MORE, TEST THEM
EOCLIN
        SWI
        FCB     22                                ;KEEP GOING, NEW LINE
OUTXT
        LBSR    RDCHR                             ;GET TEXT CHARACTERS
        CMPA    #ETXT                             ;END OF TEXT
        LBEQ    BCKSKP                            ;IF END, CLOSE
        CMPA    #BTXT                             ;START OF TEXT
        LBEQ    SUBSUM                            ;SUMMARY OF SUB CLASSES
        LBSR    OUTCHR                            ;OUTPUT
        BRA     OUTXT                             ;KEEP GOING
;*
;* SUBROUTINE TO DISPLAY CHARACTER IN ACCA
;*
OUTCHR
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BEQ     LFCR                              ;IF SO, USE LFCR PAIR
        SWI
        FCB     33                                ;DISPLAY
        RTS
LFCR
        SWI
        FCB     22                                ;NEW LINE
        RTS
;*
;* SUBROUTINE ADVANCES TO START OF NEXT SECTION
;*
FNDSEC
        BSR     RDCHR                             ;ADVANCE IN SOURCE
        BNE     FNC1                              ;IF END, CLOSE FILE AND QUIT
        CMPA    #ETXT                             ;END OF TEXT?
        BEQ     FNC1                              ;NO MORE DATA
        CMPA    #BTXT                             ;START OF TEXT
        BNE     FNDSEC                            ;IF NOT, KEEP LOOKING
FNCL
        RTS
FNC1
        LDA     #$FF                              ;CLEAR Z FLAG
        RTS
;*
;* READ A CHAR FROM INPUT FILE
;*
RDCHR
        PSHS    B,X                               ;SAVE REG
        LDX     >WRKOFF                           ;GET OFFSET
        CMPX    #WRKSPC+512	PAST END?
        BLO     RDCH1                             ;ITS OK
        LDD     >WRKSEC                           ;GET SECTOR
        SWI
        FCB     77                                ;LOOKUP LINK
        BEQ     RDCEOF                            ;END
        STD     >WRKSEC                           ;SAVE
        LDX     #WRKSPC
        SWI
        FCB     92                                ;READ WRK SECT
RDCH1
        LDA     ,X+                               ;GET CHAR
        STX     >WRKOFF                           ;RESAVE
        CMPA    #$FF
        BEQ     RDCEOF
        ORCC    #4                                ;SET 'Z'
        PULS    B,X,PC
RDCEOF
        LDA     #$FF                              ;END OF FILE
        PULS    B,X,PC
;*
;* SUBROUTINE TO SKIP TO THE END OF CURRENT SECTION
;*
SKPEND
        LDA     #1                                ;GET A ONE
        STA     TLVL                              ;SET TEMPORARY LEVEL COUNTER
CHKLVL
        BSR     RDCHR                             ;GET CHARACTER FROM FILE
        BNE     CLOSE                             ;CLOSE FILE END EXIT
        CMPA    #BTXT                             ;BEGINNING OF TEXT CHARCTER?
        BNE     NOBTXT                            ;NOT BEGINNING
        INC     TLVL                              ;ADVANCE TEMPORARY LEVEL
NOBTXT
        CMPA    #ETXT                             ;END OF TXT?
        BNE     CHKLVL                            ;NO, GET NEXT
        DEC     TLVL                              ;REDUCE COUNT
        BNE     CHKLVL                            ;NO, TRY AGAIN
        RTS                                       ;	RETURN TO CALLER
;*
;* CLOSE FILE AND EXIT
;*
CLOSE
        TST     ERRFLG                            ;CHECK FOR ERROR FLAG
        BEQ     NOERR1                            ;NO ERROR
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'No help available for requested topic.'
        LBRA    NXTCMD                            ;GET NEXT COMMAND
NOERR1
        SWI
        FCB     22                                ;MOVE TO A NEW LINE
        LDS     SAVSP                             ;RESTORE STACK
        CLRA                                      ;	SET ZERO RC
        RTS
DEFDIR
        FCB     0,'H','E','L','P',0,0,0,0
DEFNAM
        FCN     'SYSTEM'
;*
WRKSEC
        RMB     2                                 ;SECTOR
WRKOFF
        RMB     2
IDENT
        RMB     1                                 ;START WITH IN INDENT OF ZERO
SAVSP
        RMB     2                                 ;TWO BYTES
ERRFLG
        RMB     1
OPPOS
        RMB     2                                 ;POINT TO OPERAND POSITION
NUMOUT
        RMB     1                                 ;NUMBER OF SUB.S OUTPUT
TLVL
        RMB     1                                 ;LEVEL POINTER
SNGLOP
        RMB     20                                ;BUFFER FOR OPERAND STORAGE
OPLIN
        RMB     80                                ;OPERAND BUFFER
WRKSPC
        RMB     512                               ;FILE SECTOR READ BUFFER
INPBUF          = *
