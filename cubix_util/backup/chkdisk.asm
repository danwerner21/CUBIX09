;*
;* CHKDISK: File system allocaton and disk media check.
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE
DIRLOC          = 0                               ;DIRECTORY LOCATION
LNKLOC          = 1                               ;LINK SECTOR LOCATION
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
;*
        ORG     OSRAM                             ;PUT IT HERE
CHKDISK
        CMPA    #'?'                              ;HELP REQUEST?
        BNE     QUAL                              ;NO, DO FSCK
        SWI
        FCB     25
        FCN     'Use: CHKDISK[/NOALLOC/NOMEDIA/QUIET/REBUILD] <drive>'
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
        FCB     $27,00
        LDA     #1                                ;INDICATE INVALID OPERAND
        BRA     ABORT                             ;ERROR
;*
;* PERFORM TESTS
;*
MAIN
        SWI
        FCB     88                                ;CLEAN DISK
        SWI
        FCB     16                                ;GET DRIVE ID
        BNE     ABORT                             ;INVALID OPERAND
        SWI
        FCB     76                                ;SELECT DRIVE
        SWI
        FCB     82                                ;GET ITS SIZE
        STD     >DRVSIZ                           ;SAVE DRIVE SIZE
        SUBD    #1                                ;ACTUAL HIGEST SECTOR
        INCA                                      ;	(D/256+1 FOR PARTIAL)
        STA     >LNKSIZ                           ;SAVE IT
;* FIRST, LOAD IN LINK SECTORS
        LDX     #WRKSPC                           ;PT TO WORK AREA
        LBSR    LDLINK                            ;LOAD LINK SECTS
        STX     >DATSPC                           ;SAVE PTR TO IT
        LBSR    LDLINK                            ;READ AGAIN
;* PERFORM ALLOCATION TABLE CHECK
        LDA     >ALLOC                            ;DO ALLOCATION
        LBEQ    NOALL                             ;NO
        LDA     >QUIET                            ;BEING QUIET?
        BEQ     MAIN1                             ;YES
        SWI
        FCB     25                                ;NEW LINE
        FCN     'Checking Allocation...'
;* RELEASE DIRECTORY SECTORS
MAIN1
        LDD     #DIRLOC                           ;GET DIR LOC
        LBSR    UNCHAIN                           ;RELEASE IT
;* RELEASE LINK SECTORS
        INC     >SECTYP                           ;INDICATE DOING LINKS
        LDD     #LNKLOC                           ;GET LINK LOCATION
        LBSR    UNCHAIN                           ;RELEASE LINKS
;* READ DIRECTORY, RELEASING ALL FILE CHAINS
        INC     >SECTYP                           ;ANDICATE DOING FILES
        LDD     #DIRLOC                           ;PT TO DIRECTORY LOCATION
MAIN2
        STD     >DIRSEC                           ;SAVE PTR
        SWI
        FCB     84                                ;READ WORK SECTOR
        TFR     X,D                               ;GET ADDRESS
        ADDD    #512                              ;CALCULATE END
        STD     >TEMP                             ;SAVE INDICATOR
MAIN3
        LDA     ,X                                ;FILE IN USE?
        BEQ     MAIN4                             ;YES, RELEASE IT
;* FILE EXISTS, RELEASE ITS LINKS
        LDD     DDADR,X                           ;GET DISK ADDRESS
        LBSR    UNCHAIN                           ;RELEASE SECTOR CHAIN
MAIN4
        LEAX    32,X                              ;NEXT ENTRY
        CMPX    >TEMP                             ;OVER?
        BLO     MAIN3                             ;NO, KEEP LOOKING
        JSR     TQUIT                             ;TEST FOR EXIT
        LDD     >DIRSEC                           ;GET CURRENT SECTOR
        SWI
        FCB     77                                ;LOOK UP ITS LINK
        BEQ     MAIN5                             ;END OF FILE, STOP
        CMPD    #0                                ;INSURE DIRECTORY IS NOT CORRUPT
        BNE     MAIN2                             ;CONTINUE
;* EXAMINE TABLE FOR ALLOCATED/UNUSED BLOCKS
MAIN5
        LDX     #WRKSPC                           ;PT TO WORK AREA
        LDU     >DATSPC                           ;GET DATA AREA
        LDY     #0                                ;START WITH SECTOR ZERO
        STY     >TEMP                             ;ZERO COUNTERS
EXAM
        LDD     ,X                                ;IS IT FREE
        BEQ     EXAM2                             ;YES
        CLR     >FLAG                             ;INDICATE CHANGED
        CLR     ,U                                ;ZERO LOW
        CLR     1,U                               ;ZERO HIGH
        LDD     >ERRORS                           ;GET TOTAL
        ADDD    #1                                ;ADVANCE
        STD     >ERRORS                           ;RESAVE
        LDA     >TEMP                             ;GET FLAG
        BNE     EXAM1                             ;ALREADY SET
        DEC     >TEMP                             ;SET FLAG
        SWI
        FCB     25
        FCN     'Blocks allocated, but not used:'
EXAM1
        SWI
        FCB     21                                ;SPACE
        TFR     Y,D                               ;GET SECTOR ID
        SWI
        FCB     27                                ;OUTPUT
        INC     >TEMP+1                           ;ADVANCE COUNTER
        LDA     >TEMP+1                           ;GET VALUE
        BITA    #7                                ;PAST END?
        BNE     EXAM2                             ;NO
        SWI
        FCB     22                                ;NEW LINE
EXAM2
        LEAY    1,Y                               ;NEXT SECTOR
        LEAX    2,X                               ;NEXT RAM LOC
        LEAU    2,U                               ;NEXT IN REAL SECTORS
        CMPY    >DRVSIZ                           ;OVER?
        BLO     EXAM                              ;NO, TRY AGAIN
        LDA     >TEMP+1                           ;GET COUNT
        BITA    #7                                ;NEW LINE
        BEQ     EXAM3                             ;NOT NESSARY
        SWI
        FCB     22                                ;NEW LINE
;* HAVE REPORTED THEM ALL
EXAM3
        LDA     >QUIET
        BEQ     NOALL                             ;BE QUIET
        LDD     >ERRORS                           ;GET TOTAL
        SWI
        FCB     26                                ;DISPLAY
        SWI
        FCB     25                                ;MESSAGE
        FCN     ' allocation error(s)'
NOALL
        LDA     >MEDIA                            ;DO MEDIA TEST?
        LBEQ    NOMED                             ;NO, NO MEDIA TEST
        LDA     >QUIET
        BEQ     QUI2                              ;BE QUIET
        SWI
        FCB     25                                ;MESSAGE
        FCN     'Checking Media...'
QUI2
        CLRA
        CLRB
        STD     >ERRORS                           ;CLEAR COUNT
MED1
        STD     >DIRSEC                           ;SAVE SECTOR ID
        LDX     #WRKSPC                           ;PT TO WORK AREA
        SWI
        FCB     92                                ;READ THE DISK
        BEQ     MED3                              ;OK, DO NEXT
        LDD     >ERRORS
        ADDD    #1                                ;ADVANCE COUNT
        STD     >ERRORS
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Media error in sector '
        LDD     >DIRSEC                           ;GET SECTOR
        SWI
        FCB     26                                ;DISPLAY
        LDD     >DIRSEC                           ;GET SECTOR BACK
        LDX     >DATSPC                           ;ADVANCE
        LSLB
        ROLA                                      ;	X2 FOT TWO BYTE ENTRIES
        LEAX    D,X                               ;ADVANCE TO IT
        LDD     ,X                                ;GET IT
        BNE     MED2                              ;ALLOCATED
        LDD     #$FFFF
        STD     ,X                                ;MARK AS BUSY
        CLR     >FLAG                             ;INDICATE CHANGE
        SWI
        FCB     25                                ;MESSAGE
        FCN     ' - MARKED'
        BRA     MED3                              ;CONTINUE
MED2
        SWI
        FCB     25
        FCN     ' -  ;* ;* ;*ALREADY ALLOCATED ;* ;* ;*'
MED3
        JSR     TQUIT                             ;TEST FOR EXIT
        LDD     >DIRSEC                           ;GET SECTOR
        ADDD    #1                                ;NEXT SECTOR
        CMPD    >DRVSIZ                           ;COMPARE WITH DISK
        LBLO    MED1                              ;KEEP GOING
        LDA     >QUIET                            ;KEEPING QUIET?
        BEQ     NOMED                             ;YES
        LDD     >ERRORS
        SWI
        FCB     26
        SWI
        FCB     25
        FCN     ' media error(s)'
;* PERFORM UPDATES IF NESSARY
NOMED
        LDA     >FLAG                             ;ANY CHANGES
        BNE     NOREB                             ;NO, SKIP IT
        LDA     >REBUILD	REBUILD AUTOMATICALLY?
        BEQ     GOREB                             ;YES
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Write updated link table?'
        SWI
        FCB     34                                ;GET CHAR
        SWI
        FCB     33                                ;ECHO
        SWI
        FCB     22                                ;NEW LINE
        ANDA    #$5F                              ;CONVERT
        CMPA    #'Y'                              ;YES?
        BNE     NOREB                             ;DON'T REBUILD
GOREB
        LDX     >DATSPC                           ;PT TO AREA
        LBSR    SALINK                            ;SAVE IT OUT
        LDA     >QUIET
        BEQ     NOREB
        SWI
        FCB     25
        FCN     'Disk allocation rebuilt'
NOREB
        CLRA                                      ;	ZERO RC
        SWI
        FCB     0                                 ;BACK TO DOS
TQUIT
        SWI
        FCB     35
        CMPA    #$1B
        BNE     GORET
        SWI
        FCB     25
        FCN     '<Aborted>'
        BRA     NOREB
;*
;* LOAD DISK LINK TABLE INTO MEMORY(X)
;*
LDLINK
        LDA     >LNKSIZ                           ;GET SIZE
        STA     >TEMP                             ;SET UP
        LDD     #LNKLOC                           ;START OF LINK SECTORS
LDLNK1
        SWI
        FCB     92                                ;READ SECTOR
        BNE     ABORT1                            ;ERROR
        ADDD    #1                                ;ADVANCE SECTOR ID
        LEAX    512,X                             ;NEXT LOCATION
        DEC     >TEMP                             ;TEST NUMBER
        BNE     LDLNK1                            ;LOAD EM ALL
GORET
        RTS
ABORT1
        SWI
        FCB     0
;*
;* SAVE DISK LINK TABLE FROM MEMORY(X)
;*
SALINK
        SWI
        FCB     88                                ;PURGE DOS WORK SECTOR
        LDA     >LNKSIZ                           ;GET SIZE
        STA     >TEMP                             ;SET UP
        LDD     #LNKLOC                           ;START OF LINK SECTORS
SALNK1
        SWI
        FCB     93                                ;READ SECTOR
        BNE     ABORT1                            ;ERROR
        ADDD    #1                                ;ADVANCE SECTOR ID
        LEAX    512,X                             ;NEXT LOCATION
        DEC     >TEMP                             ;TEST NUMBER
        BNE     SALNK1                            ;LOAD EM ALL
        RTS
;*
;* UNCHAIN SECTORS FROM RAM TABLE
;*
UNCHAIN
        PSHS    X                                 ;SAVE 'X'
UNC1
        LSLB                                      ;	X 2
        ROLA                                      ;	FOR ENTRIES
        ADDD    #WRKSPC                           ;OFFSET TO WORKSPACE
        TFR     D,Y                               ;COPY IT TO INDEX
        LDD     ,Y                                ;GET NEXT SECTOR
        BEQ     UNC2                              ;GO LOOSE SOMEHOW
        CLR     ,Y                                ;CLEAR LOW
        CLR     1,Y                               ;CLEAR HIGH
        CMPD    >DRVSIZ                           ;IN RANGE?
        BLO     UNC1                              ;YES, ITS OK
        CMPD    #$FFFF                            ;END OF FILE?
        BEQ     UNC7                              ;ALL IS OK
;* LINK CHAIN POINTS BEYOND FILESYSTEM
        LDU     #OVRMSG                           ;PT TO MESSAGE
        BRA     UNC3                              ;AND CONTINUE
;* LINK CHAIN ENDED WITH ZERO
UNC2
        LDU     #ZERMSG                           ;PT TO MESSAGE
UNC3
        LDD     >ERRORS
        ADDD    #1                                ;ADVANCE ERROR COUNT
        STD     >ERRORS
        SWI
        FCB     24                                ;ERROR MESSAGE
        FCN     'Allocation error in '
        LDA     >SECTYP                           ;GET SECTOR TYPE
        BNE     UNC4                              ;NO, NOT DIRECTORY
        SWI
        FCB     24
        FCN     'DIRECTORY'
        BRA     UNC6
UNC4
        DECA                                      ;	IS IT LINKS?
        BNE     UNC5                              ;NO, NOT LINKS.
        SWI
        FCB     24
        FCN     'LINK TABLE'
        BRA     UNC6
UNC5
        SWI
        FCB     31                                ;DISPLAY FILENAME
UNC6
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     ', block '
        TFR     Y,D                               ;GET BLOCK ID
        SUBD    #WRKSPC                           ;CONVERT
        LSRA                                      ;	/2
        RORB                                      ;	FOR ACTUAL ID
        SWI
        FCB     26                                ;OUTPUT IN DECIMAL
        SWI
        FCB     22                                ;NEW LINE
        TFR     U,X                               ;GET PTR TO MESSAGE
        SWI
        FCB     23                                ;DISPLAY MESSAGE
        SWI
        FCB     22                                ;NEW LINE
UNC7
        PULS    X,PC                              ;RESTORE & RETURN
ZERMSG
        FCN     'Chain ends in unallocated (0) link'
OVRMSG
        FCN     'Link exceeds filesystem bounds'
;* QUALIFIER TABLES
QTABLE
        FCB     $84
        FCC     '/NOALLOC'
        FCB     $84
        FCC     '/NOMEDIA'
        FCB     $82
        FCC     '/QUIET'
        FCB     $82
        FCC     '/REBUILD'
        FCB     $80
QMAX            = 4                               ;# QUALIFIERS
QFLAGS          = *
ALLOC
        FCB     $FF                               ;ALLOCATION TEST
MEDIA
        FCB     $FF                               ;MEDIA TEST
QUIET
        FCB     $FF                               ;QUIET MODE
REBUILD
        FCB     $FF                               ;REBUILD MAP
;* MISC LOCAL VARIABLES
FLAG
        FCB     $FF                               ;INDICATES CHANGED SECTOR
ERRORS
        FDB     0                                 ;ERROR COUNT FLAG
SECTYP
        FCB     0                                 ;SECTOR TYPE BEING RELEASED
DIRSEC
        RMB     2                                 ;CURRENT DIRECTORY SECTOR
DRVSIZ
        RMB     2                                 ;DISK SIZE (IN SECTORS)
LNKSIZ
        RMB     1                                 ;SIZE OF LINK MAP (IN SECTORS)
DATSPC
        RMB     2                                 ;PTR TO DATA RAM
TEMP
        RMB     2                                 ;TEMPORARY STORAGE
;* WORK AREA
WRKSPC          = *
