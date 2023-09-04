;*
;* COPY: Flexible file copy utility
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE
DIRLOC          = 0                               ;DIRECTORY LOCATION
MAXBUF          = 50                              ;MAX. # OF SECTORS TO BUFFER
;* DIRECTORY STRUCTURE
        ORG     0
DPREFIX
        RMB     8                                 ;PREFIX
DNAME
        RMB     8                                 ;FILENAME
DTYPE
        RMB     3                                 ;FILE TYPE
DDADR
        RMB     2                                 ;DISK ADDRESS
DRADR
        RMB     2                                 ;RUN ADDRESS
DATTR
        RMB     1                                 ;FILE ATTRIBUTES
;* FILE CONTROL BLOCK STRUCTURE
        ORG     0
OTYPE
        RMB     1                                 ;OPEN TYPE
ODRIVE
        RMB     1                                 ;OPEN DRIVE
OFIRST
        RMB     2                                 ;FIRST SECTOR
OSECTOR
        RMB     2                                 ;NEXT SECTOR TO BE ACCESSED
OLSTSEC
        RMB     2                                 ;LAST SECTOR TO BE ACCESSED
OOFFSET
        RMB     2                                 ;OFFSET FOR CHAR OPERATIONS
;* FILE PERMISSION BITS
RPERM           = %10000000	READ PERMISSION
WPERM           = %01000000	WRITE PERMISSION
EPERM           = %00100000	EXECUTE PERMISSION
DPERM           = %00010000	DELETE PERMISSION
;*
        ORG     OSRAM                             ;PUT IT HERE
COPY
        CMPA    #'?'                              ;HELP R=EST?
        BNE     QUAL                              ;NO, DO COPY
        SWI
        FCB     25
        FCN     'Use: COPY[/MOVE/NEW/PROT/QUIET/REPLACE] <source> <destination>'
ABORT
        SWI
        FCB     0                                 ;RETURN TO DOS
;* EVALUATE QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR
        CMPA    #'/'                              ;QUALIFIER?
        BNE     MAIN                              ;NO QUALIFIERS
        LDX     #QTABLE                           ;PT TO TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;OVER?
        BHS     QERR                              ;INVALID
        LDX     #QFLAGS                           ;PT TO FLAGS
        CLR     B,X                               ;ZAP IT
        BRA     QUAL                              ;CONTINUE
QERR
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Invalid qualifier: '
        LDA     ,Y+                               ;GET CHAR
QERR1
        SWI
        FCB     33                                ;OUTPUT
        SWI
        FCB     5                                 ;GET NEXT CHAR
        BEQ     QERR2                             ;END, EXIT
        CMPA    #'/'                              ;NEXT QUALIFIER
        BNE     QERR1                             ;ITS OK
QERR2
        SWI
        FCB     25
        FCB     $27,0
        LDA     #1                                ;INDICATE INVALID OPERAND
        BRA     ABORT                             ;ERROR
;*
;* MAIN PGM
;*
;* GET SOURCE PATTERN
MAIN
        SWI
        FCB     9                                 ;GET PATTERN
        BNE     ABORT                             ;ERROR
        LEAX    -1,X                              ;BACKUP TO DRIVE
        STX     >DOSBUF                           ;SAVE PTR TO DOS BUFFER
        LDU     #SRCDRV                           ;PT TO SAVED PATTERN
        LDB     #DDADR+1	NAME + DRIVE
CPY1
        LDA     ,X+                               ;GET CHAR
        STA     ,U+                               ;SAVE IN BUFFER
        DECB                                      ;	COUNT
        BNE     CPY1                              ;MOVE ALL
;* GET DEST PATTERN
        SWI
        FCB     14                                ;GET DIRECTORY NAME
        TFR     X,U                               ;CPY IT
        LDB     #DDADR-DNAME	SIZE OF NAME & TYPE
CPY2
        CLR     ,U+                               ;CLEAR IT
        DECB
        BNE     CPY2                              ;DO AM ALL
        LDA     #'*'
        STA     ,X                                ;SET FILENAME
        STA     DTYPE-DNAME,X	SET TYPE
        SWI
        FCB     5                                 ;ANY MORE?
        BEQ     ENAM                              ;NO, THATS ALL
        LEAY    -1,Y                              ;BACKUP
        CLR     ,X                                ;NOWILD
        LDB     #8                                ;8 CHARS/NAME
CPY3
        SWI
        FCB     5                                 ;GET CHAR
        BEQ     ENAM                              ;THATS ALL
        CMPA    #'.'                              ;TYPE?
        BEQ     CPY4                              ;GET TYPE
        DECB                                      ;	BACKUP
        BMI     BADOP                             ;INVALID
        STA     ,X+                               ;SAVE
        BRA     CPY3                              ;CONTINUE
CPY4
        LEAX    B,X                               ;ADVANCE TO TYPE
        CLR     ,X                                ;NO WILDCARD
        LDB     #3                                ;THREE CHARS
CPY5
        SWI
        FCB     5                                 ;GET CHAR
        BEQ     ENAM
        DECB
        BMI     BADOP                             ;INVALID
        STA     ,X+                               ;SAVE
        BRA     CPY5                              ;KEEP GOING
BADOP
        SWI
        FCB     25
        FCN     'Bad destination pattern'
        LDA     #1
        SWI
        FCB     0                                 ;QUIT
;* WE HAVE DESTIANTION FILENAME
ENAM
        LDX     >DOSBUF                           ;PT TO NAME
        LDB     #DDADR+1	NAME+DRIVE
        LDU     #DSTDRV
ENAM1
        LDA     ,X+                               ;GET CHAR
        STA     ,U+                               ;SAV IN BUFFER
        DECB
        BNE     ENAM1                             ;CONTINUE
;* LOOK UP FILES MATCHING SOURCE PATTERN IN DIRECTORY
        LBSR    SELSRC                            ;SELECT SOURC FILE PATTERN
        LDD     #DIRLOC                           ;GET DIRECTORY LOCATION
LOOKUP
        STD     >DIRSEC                           ;SAVE IT
        LBSR    SELSRC                            ;GET SOURCE PATTERN
        LDX     #WRKSPC                           ;PT TO WORKSPACE
        SWI
        FCB     92                                ;READ IT
        LBNE    ABORT                             ;ERROR, INDICATE INVALID
        LDA     #$FF
        STA     >DIRCHG                           ;INDICATE NO DIR CHANGE
LOOK1
        SWI
        FCB     19                                ;DUZ IT MATCH?
        BEQ     CPYGO                             ;DO IT
NXTFIL
        LEAX    32,X                              ;ADVANCE TO NEXT SECTOR
        CMPX    #WRKSPC+512	ARE WE OVER?
        BLO     LOOK1                             ;NO, KEEP IT UP
        LDA     >DIRCHG                           ;CHANGED?
        BNE     NXTF1                             ;NO
        LDD     >DIRSEC                           ;PT TO IT
        LDX     #WRKSPC                           ;PT TO DATA
        SWI
        FCB     93                                ;WRITE IT OUT
NXTF1
        LDD     >DIRSEC                           ;GET SECTOR
        SWI
        FCB     77                                ;LOOKUP ITS LINK
        BNE     LOOKUP                            ;MORE, KEEP LOOKING
        LDA     >FOUND                            ;DID WE LOCATE ANY
        BEQ     QUIT                              ;YS, ITS OK
        SWI
        FCB     44                                ;ISSUE ERROR MESSAGE
QUIT
        SWI
        FCB     0                                 ;GO HOME
;* FOUND A FILE, PERFORM COPY
CPYGO
        STX     >DIRPTR                           ;SAVE DIRECTORY PTR
        CLR     >FOUND                            ;INDICATE WE FOUND FILE
        LDD     DRADR,X                           ;GET RUN ADDRESS
        STD     RUNADR                            ;SAVE
        LDA     >SRCDRV                           ;GET SOURCE DRIVE?
        CMPA    >DSTDRV                           ;SAME DRIVE?
        BNE     FRCPY                             ;NO, FORCE COPY
;* IF MOVEING, FILES ON SAME DRIVE, PERFORM RENAME FUNCTION
        LDA     >MOVE                             ;ARE WE MOVEING?
        LBEQ    RENAME                            ;YES, PEFORM RENAME INSTEAD
;* SET UP CONTROL BLOCK FOR OPEN READ FILE
FRCPY
        LDA     DATTR,X                           ;GET FILE ATTRIBUTES
        STA     >ATTR                             ;SAVE ATTRIBUTES
        BITA    #RPERM                            ;CAN WE READ IT
        BEQ     PROERR                            ;PROTECTION ERrOR
        LDU     #SRCFIL                           ;GET SOURCE FILE CTRL BLOCK
        LDA     #1                                ;INDICATE READ
        STA     OTYPE,U
        LDA     >SRCDRV                           ;GET DRIVE
        STA     ODRIVE,U
        LDD     DDADR,X                           ;GET DISK ADDRESS
        STD     OFIRST,U	FIRST SEC IN FILE
        STD     OSECTOR,U	NEXT SEC TO ACCESS
        CLRA
        CLRB
        STD     OLSTSEC,U	NO LAST SECTOR
        STD     OOFFSET,U	NO OFSET
;* OPEN DESTINATION FILE FOR WRITE
        LBSR    SELDST                            ;SELECT DESTINATION
LKFIL
        SWI
        FCB     68                                ;DOES FILE EXIST?
        BNE     CREF                              ;NO, CREATE IT
        LBSR    ASK                               ;PROMPT FOR ACTION
        CMPA    #'C'                              ;CHANGING NAME
        BEQ     LKFIL                             ;YES
        CMPA    #'R'                              ;REPLACE?
        BEQ     NOASK                             ;IF SO, DO IT
;* SKIP TO NEXT FILE IN DIRECTORY
GONXT
        LBSR    SELSRC                            ;GET SOURCE PATTERN
        LDX     >DIRPTR                           ;GET POSITION
        LBRA    NXTFIL                            ;LOOK AT NEXT
;* CAN'T READ OR WRITE FILE, PROTECTION ERROR
PROERR
        SWI
        FCB     45                                ;ISSUE ERROR
        BRA     GONXT                             ;AGAIN
;* FILE DIDN'T EXIST, CREATE IT
CREF
        SWI
        FCB     72                                ;CREATE IT
        BNE     GONXT                             ;DIDN'T WORK, SKIP IT
;* COPY FILE IF POSSIBLE
NOASK
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #WPERM                            ;CAN WE WRITE
        BEQ     PROERR                            ;INVALID
        LDA     >QUIET
        BEQ     QUI1
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Copy '
        LBSR    SHOSRC                            ;SHO DRIVE
QUI1
        LDU     #DSTFIL                           ;POINT TO BUFFER
        LDA     #2                                ;WRITE
        STA     OTYPE,U
        LDA     >DSTDRV                           ;DRIVE
        STA     ODRIVE,U
        LDD     DDADR,X                           ;GET ADDRESS
        STD     OFIRST,U
        STD     OSECTOR,U
        CLRA
        CLRB
        STD     OLSTSEC,U	NO LAST
        STD     OOFFSET,U	NO OFFSET
        LDD     >RUNADR                           ;GET RUN ADDRESS
        STD     DRADR,X                           ;SET IT
        TST     >ATFLG                            ;SET ATTRIBUTES?
        BNE     SETA1                             ;NO, SKIP IT
        LDA     >ATTR                             ;GET ATTRS
        STA     DATTR,X                           ;SAVE EM
SETA1
        SWI
        FCB     85                                ;INDICATE CHANGED
;* MOVE DATA FROM SOURCE TO DEST
MVDAT
        LDU     #SRCFIL                           ;PT TO SOURCE
        LDX     #BUFFER                           ;PT TO BUFFER
        LDY     #MAXBUF                           ;MAX # SECS TO BUFFER
MVD1
        SWI
        FCB     58                                ;READ A BLOCK
        BNE     MVD3                              ;END OF FILE
        LEAX    512,X                             ;ADVANCE TO NEXT
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     MVD1                              ;KEEP GOING
        LDU     #DSTFIL                           ;PT TO DEST
        LDX     #BUFFER
        LDY     #MAXBUF
MVD2
        SWI
        FCB     60                                ;WRITE BLOCK
        LBNE    GONXT                             ;ERROR, DO NEXT
        LEAX    512,X                             ;NEXT SECTOR IN MEM
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     MVD2                              ;DO EM ALL
        BRA     MVDAT                             ;BACK TO SOURCE
;* END OF FILE, WRITE LAST BUFFER
MVD3
        LDU     #DSTFIL                           ;PT TO DEST
        LDX     #BUFFER                           ;PT TO DATA
MVD4
        CMPY    #MAXBUF                           ;ANY LEFT
        BHS     MVD5                              ;NO, CLOSE IT
        SWI
        FCB     60                                ;WRITE IT
        LBNE    GONXT                             ;ERROR
        LEAX    512,X                             ;ADVANCE
        LEAY    1,Y                               ;CONTINUE
        BRA     MVD4                              ;DO EM ALL
;* CLOSE FILE AND PROCEED
MVD5
        SWI
        FCB     57                                ;CLOSE FILE
        BNE     GONXT1                            ;ERROR
;* IF MOVEING, DELETE SOURCE FILE
        LDA     >MOVE                             ;ARE WE MOVEING
        BNE     GONXT1                            ;NO, ITS OK
        LBSR    GETSRC                            ;GET SOURCE NAME
        LDA     >QUIET
        BEQ     QUI2
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     'Delete '
        SWI
        FCB     30                                ;DISPLAY NAME
        SWI
        FCB     22                                ;NEW LINE
QUI2
        SWI
        FCB     73                                ;DELETE THE FILE
GONXT1
        LBRA    GONXT                             ;DO IT AGAIN
;*
;* 'MOVE' QUALIFIER, FILES ON SAME DISK, RENAME FILE
;*
RENAME
        LBSR    SELDST                            ;GET DESTINATION FILENAME
        SWI
        FCB     19                                ;SAME AS US
        LBEQ    GONXT                             ;DO NEXT
REN1
        SWI
        FCB     68                                ;DOES IT EXIST?
        BNE     REN4                              ;NO, OK TO RENAME
        LBSR    ASK                               ;PROMPT FOR ACTION
        CMPA    #'C'                              ;CHANGE NAME?
        BEQ     REN1                              ;IF SO, DO IT AGAIN SAM
        CMPA    #'R'                              ;REPLACE?
        LBNE    GONXT                             ;NO, SKIP IT & GET NEXT
        LDA     >QUIET
        BEQ     QUI3                              ;NO MESSAGE
        SWI
        FCB     24
        FCN     'Delete '
        SWI
        FCB     30                                ;SHOW IT
        SWI
        FCB     22                                ;NEW LINE
QUI3
        SWI
        FCB     73                                ;DELETE FILE
        LBNE    GONXT                             ;ERROR
;* DELETE IN OUR COPY OF DIRECTORY
        LDX     #WRKSPC                           ;PT TO OUR DATA
REN2
        SWI
        FCB     19                                ;NAME MATCH?
        BNE     REN3                              ;NO, DON'T ERASE
        CLR     ,X                                ;ZAP IT
REN3
        LEAX    32,X                              ;ADVANCE
        CMPX    #WRKSPC+512	OVER?
        BLO     REN2                              ;NO, KEEP GOING
;* SWAP FILENAME
REN4
        LDX     >DIRPTR                           ;GET DIR POSITION
        LDA     >QUIET
        BEQ     QUI4                              ;KEEP MOUTH SHUT
        SWI
        FCB     24
        FCN     'Move '
        LBSR    SHOSRC                            ;DISPLAY
QUI4
        LDY     >DOSBUF                           ;GET DOS BUFFER
        LEAY    1,Y                               ;ADVANCE
        LDB     #DDADR                            ;SIZE
REN5
        LDA     ,Y+                               ;CHAR FROM DOS
        STA     ,X+                               ;UPDATE DIRECT
        DECB                                      ;	REDUCE COUNT
        BNE     REN5                              ;AND CONTINUE
        CLR     >DIRCHG                           ;INDICATE DIR CHANGED
        LBRA    GONXT                             ;GET NEXT FILE
;* ASK ABOUT FILE
ASK
        LDA     >NEW                              ;NEW FILES ONLY?
        BEQ     ASKRTS                            ;IF SO, EXIT
        LDA     #'R'                              ;INDICATE REPLACE
        TST     >REPL                             ;ARE WE REPLACING
        BEQ     ASKRTS                            ;EXIT
        SWI
        FCB     24                                ;MESSAGE
        FCN     'File '
        SWI
        FCB     30                                ;DISPLAY NAME
        SWI
        FCB     24                                ;MESSAGE
        FCN     ' exists(Skip/Replace/Change name)?'
        SWI
        FCB     34                                ;GET CHAR
        SWI
        FCB     33                                ;ECHO
        ANDA    #$5F                              ;CONVERT TO UPPER
        SWI
        FCB     22                                ;NEW LINE
        CMPA    #'C'                              ;CHANGING?
        BNE     ASKRTS                            ;NO
ASK1
        SWI
        FCB     24                                ;PROMPT
        FCN     'New name: '
        SWI
        FCB     3                                 ;GET LINE
        SWI
        FCB     10                                ;GET NAME
        BNE     ASK1                              ;GET IT WRITE
        LDA     #'C'                              ;INDICATE CHANGE
ASKRTS
        RTS
;* SHOW SOURCE FILE IDENTIFIER
SHOSRC
        PSHS    A,X                               ;SAVE REGS
        LDA     >SRCDRV                           ;GET SOURCE DRIVE
        ADDA    #'A'                              ;CONVERT
        SWI
        FCB     33                                ;OUTPUT
        LDA     #':'                              ;COLON
        SWI
        FCB     33                                ;OUTPUT
        LDX     >DIRPTR                           ;GET PTR
        SWI
        FCB     31                                ;DISPLAY
        SWI
        FCB     24                                ;MESSAGE
        FCN     ' to '
        SWI
        FCB     30                                ;SAVED FILE
        SWI
        FCB     22                                ;NEW LINE
        PULS    A,X,PC
;* GET SOURCE FILENAME INTO DOS BUFFER
GETSRC
        PSHS    X,Y                               ;SAVE REGS
        LDX     >DIRPTR                           ;GET DIRECTORY POINTER
        LDA     >SRCDRV                           ;GET SOURCE DRIVE
        LDY     >DOSBUF                           ;PT TO DOS BUFFER
        STA     ,Y+                               ;SAVE IT
        LDB     #DDADR                            ;LENGTH
GETS1
        LDA     ,X+                               ;GET LENGTH
        STA     ,Y+                               ;SAVE IT
        DECB                                      ;	BACKUP
        BNE     GETS1                             ;DO IT AGAIN
        PULS    X,Y,PC
;* SELECT SOURCE FILENAME PATTERN
SELSRC
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDX     >DOSBUF                           ;GET DOS BUFFER
        LDY     #SRCDRV                           ;PT TO SAVED
        LDA     ,Y                                ;GET DRIVE
        SWI
        FCB     76                                ;SELECT IT
        LDB     #DDADR+1	NAME+DRIVE
SELS1
        LDA     ,Y+                               ;GET CHAR
        STA     ,X+                               ;SAVE
        DECB                                      ;	REDUCE COUNT
        BNE     SELS1                             ;MOVE ALL
        PULS    A,B,X,Y,PC
;* SELECT DESTINATION PATTERN ('U' PTS TO SUBSTITUTE NAME)
SELDST
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDU     >DIRPTR                           ;GET SUBSTITURE FILENAME
        LDY     #DSTDRV                           ;PT TP DEST
        LDX     >DOSBUF                           ;GET BUFFER
        LDA     ,Y+                               ;GET DRIVE
        STA     ,X+                               ;WRITE IT
        LDB     #DDADR                            ;LENGTH OF NAME
SELD1
        LDA     ,Y+                               ;GET CHAR FROM DEST
        CMPA    #'*'                              ;WILDCARD
        BEQ     SELD3                             ;HANDLE
        STA     ,X+                               ;SAVE IN DOS
        LEAU    1,U                               ;ADVANCE PATTERN
        DECB                                      ;	REDUCE COUNT
        BNE     SELD1                             ;CONTINUE
SELD2
        PULS    A,B,X,Y,PC
SELD3
        LDA     ,U+                               ;GET CHAR FROM SOURCE
        STA     ,X+                               ;SAVE IN DEST
        DECB                                      ;	REDUCE COUNT
        BEQ     SELD2                             ;END, QUIT
        CMPB    #DDADR-DNAME	AT NAME?
        BEQ     SELD1                             ;YES
        CMPB    #DDADR-DTYPE	AT TYPE?
        BEQ     SELD1                             ;YES
        LEAY    1,Y                               ;ADVANCE
        BRA     SELD3                             ;KEEP GOING
;* QUALIFIER TABLES
QTABLE
        FCB     $82
        FCC     '/QUIET'
        FCB     $82
        FCC     '/REPLACE'
        FCB     $82
        FCC     '/MOVE'
        FCB     $82
        FCC     '/PROT'
        FCB     $82
        FCC     '/NEW'
        FCB     $80
QMAX            = 5                               ;# QUALIFIERS
QFLAGS          = *
QUIET
        FCB     $FF                               ;QUIET FLAG
REPL
        FCB     $FF                               ;REPLACE FLAG
MOVE
        FCB     $FF                               ;MOVE FLAG
ATFLG
        FCB     $FF                               ;ATRIBUTE COPY
NEW
        FCB     $FF                               ;NEW FILES ONLY
;* MISC RAM VARIABLES
FOUND
        FCB     $FF                               ;FOUND FILES FLAG
DIRCHG
        RMB     1                                 ;DIRECTORY CHANGED
RUNADR
        RMB     2                                 ;FILE RUN ADDRESS
ATTR
        RMB     1                                 ;FILE ATTRIBUTES
DOSBUF
        RMB     2                                 ;PTR TO DOS FILNAME
DIRSEC
        RMB     2                                 ;CURRENT DIRECTORY SECTOR
DIRPTR
        RMB     2                                 ;DIR POINTER
SRCDRV
        RMB     1                                 ;SOURCE DRIVE
SRCPAT
        RMB     DDADR                             ;SOURCE FIELNAME BUFFER
DSTDRV
        RMB     1                                 ;DESTINATION DRIVE
DSTPAT
        RMB     DDADR                             ;DESTINATION FILENAME BUFFER
SRCFIL
        RMB     10                                ;SOURCE FILE CONTROL BLOCK
DSTFIL
        RMB     10                                ;DESTINATION FILE CONTROL BLOCK
WRKSPC
        RMB     512                               ;WORK SECTOR
BUFFER          = *                               ;BUFFER DATA HERE
