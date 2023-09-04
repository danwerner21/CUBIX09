;*
;* LDIR: List directories
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
DIRLOC          = 0                               ;STARTING DIRCTORY LOCATION
        ORG     OSRAM                             ;DOS UTILITY SPACE
LDIR
        CMPA    #'?'                              ;IS IT '?' QUERY?
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIERS
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'Use: LDIR[/TOTAL] [<filespec>]'
        RTS
;* PARSE FOR COMMAND QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR FROM COMMAND LINE
        CMPA    #'/'                              ;IS IT A QUALIFIER?
        BNE     MAIN                              ;NO, CONTINUE WITH MAIN PROGRAM
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
        LBRA    ABORT                             ;GO HOME
;* MAIN PROGRAM
MAIN
        PSHS    Y
        LDY     #ALLFIL                           ;ALL FILES
        SWI
        FCB     9                                 ;CLEAR TO ';*', GET DEFAULT DRIVE
        LDA     -1,X                              ;GET DEFAULT DRIVE
        LDX     #DEFDIR                           ;PT TO DEFAULT
        STA     ,X                                ;SAVE IT
        PULS    Y                                 ;RESTORE Y
        SWI
        FCB     15                                ;GET DIR NAME
        LDA     -9,X                              ;GET ACTUAL DRIVE
        SWI
        FCB     76                                ;SELECT DRIVE
        SWI
        FCB     5                                 ;ANY MORE?
        BEQ     ENAM                              ;NO, THATS ALL
        LEAY    -1,Y                              ;BACKUP
        CLR     ,X                                ;NOWILD
        LDB     #8                                ;8 CHARS/NAME
SUP1
        SWI
        FCB     5                                 ;GET CHAR
        BEQ     ENAM                              ;THATS ALL
        CMPA    #'.'                              ;TYPE?
        BEQ     SUP2                              ;GET TYPE
        DECB                                      ;	BACKUP
        BMI     BADOP                             ;INVALID
        STA     ,X+                               ;SAVE
        BRA     SUP1                              ;CONTINUE
SUP2
        LEAX    B,X                               ;ADVANCE TO TYPE
        CLR     ,X                                ;NO WILDCARD
        LDB     #3                                ;THREE CHARS
SUP3
        SWI
        FCB     5                                 ;GET CHAR
        BEQ     ENAM                              ;END
        DECB                                      ;	REDUCE
        BMI     BADOP                             ;INVALID
        STA     ,X+                               ;SAVE
        BRA     SUP3                              ;KEEP GOING
BADOP
        SWI
        FCB     25
        FCN     'Bad file pattern'
        LDA     #1
        SWI
        FCB     0                                 ;QUIT
ENAM
        LDX     #RAM+512	POINT TO RAM
CLR
        CLR     ,X+                               ;CLEAR ONE BYTE
        CMPX    #RAM+4098	END OF RAM
        BLO     CLR                               ;KEEP GOING
        LDD     #DIRLOC                           ;GET DIECTORY SECTOR
RDNXT
        STD     DIRSEC                            ;SAVE DIRECTORY SECTOR WE ARE IN
        LDX     #RAM                              ;POINT TO WORK AREA
        SWI
        FCB     92                                ;READ DISK
        LBNE    ABORT
TSTNAM
        SWI
        FCB     19                                ;IS THIS A MATCH?
        BEQ     MATCH                             ;IF SO, HANDLE IT
NXTFIL
        LEAX    32,X                              ;ADVANCE TO NEXT FILE ENTRY
        CMPX    #RAM+512	ARE WE OVER LIMIT
        BLO     TSTNAM                            ;IF NOT, TRY THIS ONE
        LDD     DIRSEC                            ;GET SECTOR WE ARE IN
        SWI
        FCB     77                                ;FIND LINK
        BNE     RDNXT                             ;MORE SECTORS, TRY THEM TOO
DISDIR
        LDA     TOTAL                             ;TOTALS ONLY?
        BEQ     END2                              ;IF SO, DON'T DISPLAY
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'Directories:'
        LDX     #RAM+512	POINT TO FREE SPACE
DSPLIN
        SWI
        FCB     22                                ;NEW LINE
        LDB     #6                                ;SIX NAMES/LINE
        STB     TEMP                              ;SAVE IN TEMP SPACE
DSPNAM
        TST     ,X                                ;GET CHARACTER FROM NAME
        BEQ     ENDIT                             ;THATS IS LAST ONE
        LDB     #8                                ;EIGHT CHARACTERS/NAME
DS8
        LDA     ,X+                               ;GET CHARACTER FROM NAME
        BNE     NOSPA                             ;NO SPACE NEEDED
        LDA     #' '                              ;GET A SPACE
NOSPA
        SWI
        FCB     33                                ;DISPLAY
        DECB                                      ;	REDUCE	COUNT
        BNE     DS8                               ;KEEP DISPLAYING
        SWI
        FCB     21                                ;SPACE
        SWI
        FCB     21                                ;SPACE
        DEC     TEMP                              ;THIS IS THE END
        BNE     DSPNAM                            ;KEEP GOING TILL WE DO ALL
        BRA     DSPLIN                            ;KEEP GOING
ENDIT
        LDA     TEMP                              ;GET POSITION INDICATOR
        CMPA    #6                                ;ARE WE AT BEGINNING
        BEQ     END1                              ;YES, SKIP EXTRA CRLF
        SWI
        FCB     22                                ;NEW LINE
END1
        SWI
        FCB     22                                ;NEW LINE
END2
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Total of '
        LDD     DTOTAL                            ;GET TOTAL NUMBER OF DIRECTORIES
        SWI
        FCB     26                                ;DISPLAY NUMBER
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     ' directories.'
        CLRA                                      ;	ZERO RETURN CODE
ABORT
        SWI
        FCB     0                                 ;BACK OFF
;*
;* NAMES MATCHED, INSERT INTO TABLE
;*
MATCH
        LDY     #RAM+512	POINT TO START OF TABLE
CMPN
        PSHS    X,Y                               ;SAVE REGISTERS
        TST     ,Y                                ;ARE WE AT END
        BEQ     INLST                             ;IF SO, INSERT IT HERE
        LDB     #8                                ;EIGHT CHARACTERS
CMP8
        LDA     ,X+                               ;GET CHARACTER FROM OUR NAME
        CMPA    ,Y+                               ;TEST FOR SAME AS DEST
        BLO     INSMOV                            ;IF DIFFERENT, THEN TRY HERE
        BNE     NOTSAM                            ;THEY ARE DIFFERENT
        DECB                                      ;	REDUCE COUNT
        BNE     CMP8                              ;TRY AGAIN
        BRA     NXTONE                            ;IGNORE IT, WE ALREADY HAVE IT
NOTSAM
        PULS    X,Y                               ;RESTORE REGISTERS
        LEAY    8,Y                               ;ADVANCE TO NEXT
        BRA     CMPN                              ;TRY AGAIN
INSMOV
        LDY     2,S                               ;GET OLD Y POINTER BACK
FNDEOF
        LEAY    8,Y                               ;ADVANCE TO NEXT NAME
        LDA     ,Y                                ;IS THIS THE END
        BNE     FNDEOF                            ;KEEP LOOKING TILL WE FIND
        LEAY    8,Y                               ;ADVANCE TO END OF FIELD
        LEAX    -8,Y                              ;BACKUP TO LAST
MOVE
        LDA     ,-X                               ;GET CHARACTER
        STA     ,-Y                               ;SAVE IN HIGHER MEMORY
        CMPX    2,S                               ;ARE WE AT START YET
        BNE     MOVE                              ;IF NOT, FORGET IT
        LDX     ,S                                ;RESTORE X REGISTER
        LDY     2,S                               ;GET Y POINTER BACK
INLST
        LDB     #8                                ;MOVE EIGHT CHARACERS
MOV8
        LDA     ,X+                               ;GET CHARACTER
        STA     ,Y+                               ;SAVE IN TABLE
        DECB                                      ;	REDUCE COUNT
        BNE     MOV8                              ;KEEP MOVEING
        LDD     DTOTAL                            ;GET TOTAL COUNT
        ADDD    #1                                ;INCREMENT COUNT
        STD     DTOTAL                            ;RESAVE
NXTONE
        PULS    X,Y                               ;RESTORE REGISTERS
        LBRA    NXTFIL                            ;TRY NEXT FILE IN DIRECTORY
;* STRINGS
DEFDIR
        FCB     0,'*',0,0,0,0,0,0,0
ALLFIL
        FCC     '*.*'
        FCB     $0D
;* QUALIFIER TABLE
QTABLE
        FCB     $82
        FCC     '/TOTAL'	TOTAL NUMBER OF DIRECTORIES ONLY
        FCB     $80
QMAX            = 1                               ;NUMBER OF QUALIFIERS
;*
QFLAGS          = *
TOTAL
        FCB     $FF
;* TEMP AND DEFINED STORAGE
DTOTAL
        FDB     0                                 ;TOTAL COUNT OF DIRECTORIES
TEMP
        RMB     1                                 ;A BYTE OF FREE STORAGE
DIRSEC
        RMB     2                                 ;AND SOME MORE
RAM             = *                               ;FREE RAM
