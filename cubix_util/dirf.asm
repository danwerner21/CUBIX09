;*
;* DIRF: Writes file names from directory to a file
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE
DIRLOC          = 0                               ;DIRECTORY LOCATION
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
        ORG     OSUTIL                            ;PROGRAM LOCATION
;* TEST FOR HELP R=EST
DIRF
        CMPA    #'?'                              ;HELP?
        BNE     QUAL                              ;NO
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCC     'Use: DIRF[/NODISK/NODIRECTORY/NOTYPE] <file> '
        FCN     '<pattern> [<prefix> [<postfix>]]'
        RTS
;* TEST FOR QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR FROM LINE
        CMPA    #'/'                              ;QUALIFIER?
        BNE     MAIN                              ;NO, START UP PGM
        LDX     #QTABLE                           ;PT TO TABLE
        SWI
        FCB     18                                ;LOOKUP QUALIFIER
        CMPB    #NUMQ                             ;IN RANGE?
        BHS     QERR                              ;NO, INVALID
        LDX     #QFLAGS                           ;PT TO FLAGS
        CLR     B,X                               ;SET THE FLAG
        BRA     QUAL                              ;GET NEXT
;* QUALIFIER WAS INVALID, REPORT
QERR
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Invalid qualifier: '
        LDA     ,Y+                               ;GET CHAR
        LDA     ,Y+                               ;GET CHAR
QSHOW
        SWI
        FCB     33                                ;DISPLAY IT
        SWI
        FCB     5                                 ;LOOK FOR TERMINATOR
        BEQ     QEND                              ;EXIT
        CMPA    #'/'                              ;ALSO TERMINATOR
        BNE     QSHOW                             ;SHOW EM ALL
QEND
        SWI
        FCB     25                                ;MESSAGE
        FCB     $27,00                            ;CLOSING QUITE
        LDA     #1                                ;BAD OPERAND RC
        RTS
;* INVALID OPERAND
BADOPR
        SWI
        FCB     43                                ;BAD OPERAND MESSAGE
ABORT
        RTS
;* MAIN PGM, EVALUATE OPERANDS
MAIN
        STY     >TEMP                             ;SAVE PT
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;ERROR, EXIT
        SWI
        FCB     9                                 ;GET DIRECT PATTERN
        BNE     ABORT                             ;ERROR
        CLR     >PREFIX                           ;INDICATE NO PREFIX
        CLR     >POST                             ;INDICATE NO POSTFIX
        SWI
        FCB     4                                 ;MORE OPERANDS
        BEQ     NOPRE                             ;NO PREFIX
        LEAY    1,Y                               ;SKIP FIRST DELIM
        STA     >DELIM                            ;SAVE DELIMITER
        LDX     #PREFIX                           ;POINT TO BUFFER
GETPRE
        LDA     ,Y+                               ;GET CHAR
        BEQ     BADOPR                            ;INVALID
        CMPA    #$0D                              ;END OF LINE
        BEQ     BADOPR                            ;INVALID
        STA     ,X+                               ;SAVE
        CMPA    >DELIM                            ;DELIMITER?
        BNE     GETPRE                            ;NO, KEEP GOING
        CLR     -1,X                              ;INDICATE END
        SWI
        FCB     4                                 ;MORE OPERANDS?
        BEQ     NOPRE                             ;END OF LINE
        LEAY    1,Y                               ;SKIP FIRST DELIM
        STA     >DELIM                            ;SAVE DELIMITER
        LDX     #POST                             ;POINT TO POST STRING
GETPOS
        LDA     ,Y+                               ;GET CHAR
        BEQ     BADOPR                            ;INVALID
        CMPA    #$0D
        BEQ     BADOPR                            ;ERROR
        STA     ,X+                               ;SAVE
        CMPA    >DELIM                            ;END
        BNE     GETPOS
        CLR     -1,X                              ;ZAP IT
;* RESTORE FILENAMES
NOPRE
        LDY     >TEMP                             ;GET PTR BACK
        SWI
        FCB     10                                ;GET NAME
        LDU     #OUTFIL                           ;PT TO IT
        SWI
        FCB     56                                ;OPEN FILE
        SWI
        FCB     9                                 ;GET PATTERN BACK
        LDA     -1,X                              ;GET DRIVE
        STA     >DISK                             ;SAVE IT
        SWI
        FCB     76                                ;SELECT DRIVE
;* LOOK UP FILES IN DIRECTORY
        LDD     #DIRLOC                           ;PT TO IT
LOKDIR
        STD     >TEMP                             ;SAVE SECTOR
        LDX     #WRKSPC                           ;TO TO WORK
        SWI
        FCB     92                                ;READ SECTOR
LOK1
        SWI
        FCB     19                                ;DOES NAME MATCH?
        BEQ     OUTNAM                            ;YES, OUTPUT IT
LOK2
        LEAX    32,X                              ;TO NEXT ENTRY
        CMPX    #WRKSPC+512	ARE WE PAST END
        BLO     LOK1                              ;NO, FIND NEXT
        LDD     >TEMP                             ;GET SECTOR
        SWI
        FCB     77                                ;LOOKUP LINK
        BNE     LOKDIR                            ;CHECK THIS SECTOR
;* END OF DIR, CLOSE FILES & EXIT
        SWI
        FCB     57                                ;CLOSE OUTPUT FILE
        RTS
;* WE FOUND A NAME, OUTPUT IT
OUTNAM
        PSHS    X                                 ;SAVE X
        LDY     #PREFIX                           ;PT TO AREA
OUT1
        LDA     ,Y+                               ;GET CHAR
        BEQ     OUT2                              ;END
        SWI
        FCB     61                                ;OUTPUT CHARACTER
        BRA     OUT1                              ;EXIT
OUT2
        LDA     >NODISK                           ;DISPLAY DISK?
        BEQ     OUT3                              ;NO, DON'T
        LDA     >DISK                             ;GET DISK DRIVE
        ADDA    #'A'                              ;CONVERT
        SWI
        FCB     61                                ;OUTPUT
        LDA     #':'                              ;SEPERATOR
        SWI
        FCB     61                                ;OUTPUT
OUT3
        LDA     >NODIR                            ;OUTPUT DIRECTORY?
        BEQ     OUT6                              ;NO, DON'T
        LDA     #'['                              ;PREFIX
        SWI
        FCB     61                                ;OUTPUT
        LDB     #8                                ;MAX 8 CHARS
OUT4
        LDA     ,X+                               ;GET CHAR FROM NAME
        BEQ     OUT5                              ;END
        SWI
        FCB     61                                ;OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     OUT4                              ;END
OUT5
        LDA     #']'                              ;POSTFIX
        SWI
        FCB     61                                ;OUTPUT
        LDX     ,S                                ;RESTORE X
;* OUTPUT FILENAME
OUT6
        LDB     #8                                ;MAX 8 CHARS
        LEAX    DNAME,X                           ;ADVANCE TO NAME
OUT7
        LDA     ,X+                               ;GET CHAR
        BEQ     OUT8                              ;END
        SWI
        FCB     61                                ;OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     OUT7                              ;CONTINUE
OUT8
        LDX     ,S                                ;RESTORE X
        LDA     >NOTYPE                           ;DISPLAY TYPE?
        BEQ     OUT10                             ;NO, SKIP IT
        LEAX    DTYPE,X                           ;POINT TO IT
        LDA     #'.'                              ;SEPERATOR
        SWI
        FCB     61                                ;OUTPUT
        LDB     #3                                ;MAX 3 CHARS
OUT9
        LDA     ,X+                               ;GET CHAR
        BEQ     OUT10                             ;END
        SWI
        FCB     61                                ;DISPLAY
        DECB                                      ;	BACKUP COUNT
        BNE     OUT9                              ;CONTINUE
OUT10
        LDX     #POST                             ;POINT TO POSTFIX
OUT11
        LDA     ,X+                               ;GET CHAR
        BEQ     OUT12                             ;END
        SWI
        FCB     61                                ;OUTPUT
        BRA     OUT11                             ;NEXT
OUT12
        LDA     #$0D                              ;END OF LINE
        SWI
        FCB     61                                ;OUTPUT
        PULS    X                                 ;RESTORE 'X'
        LBRA    LOK2                              ;CONTINUE LOOKING
;*
;* QUALIFIER TABLE
;*
QTABLE
        FCB     $85
        FCC     '/NODISK'
        FCB     $85
        FCC     '/NODIRECTORY'
        FCB     $84
        FCC     '/NOTYPE'
        FCB     $80
NUMQ            = 3
QFLAGS          = *
NODISK
        FCB     $FF                               ;DON'T INCLUDE DISK PREFIX
NODIR
        FCB     $FF                               ;DON'T INCLUDE DIRECTORY
NOTYPE
        FCB     $FF                               ;DON'T INCLUDE TYPE
;* MISC LOCAL VARIABLES
DISK
        RMB     1                                 ;DIRECTORY DISK DRIVE
TEMP
        RMB     2                                 ;TEMP STORAGE
DELIM
        RMB     1                                 ;STRING DELIMITER
WRKSPC
        RMB     512                               ;DIRECTORY LOOKUP SECTOR
OUTFIL
        RMB     522                               ;OUTPUT FILE BUFFER
PREFIX
        RMB     64                                ;PREFIX STRING
POST
        RMB     64                                ;POSTFIX STRING
