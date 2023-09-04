;*
;* DIR: Enhanced directory display utility
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE
TSIZ            = 24                              ;SIZE OF DIR TABLE
DIRLOC          = 0                               ;STARTING DIRECTORY LOCATION
        ORG     OSRAM
DIR
        CMPA    #'?'                              ;QUERY OPERAND?
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIERS
        SWI
        FCB     25
        FCC     'Use: DIR[/DISK/LOAD/SIZE/TOTAL/NOHEADER/PROT]'
        FCN     ' [<directory>]'
        RTS
;* PARSE	FOR COMMAND QUALIFIERS
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
        RTS
;* FIRST	GET PARAMETERS,	AND ADJUST FOR DEFAULTS
MAIN
        LDA     SIZE                              ;SEE IF '/SIZE' SPECIFIED
        ANDA    RUNADR                            ;OR '/RUNADR'
        ANDA    DSKADR                            ;OR '/DISKADR'
        ANDA    ATTR                              ;OR '/ATTRIBUTES'
        STA     INFO                              ;IF SO, SET INFORMATION MODE (SINGLE COLUMN)
        SWI
        FCB     4                                 ;LOOK FOR PARAMETER
        BEQ     DEFPRM                            ;NONE, USE DEFAULT
        PSHS    Y                                 ;SAVE OPERAND POINTER
ADVP
        SWI
        FCB     5                                 ;GET CHAR FROM OP
        BEQ     ADVP2                             ;END OF LINE ?
        CMPA    #']'                              ;END OF DIRECTORY
        BEQ     ADVP1                             ;IF SO, MABY HAFTA INSERT ;*.;*
        CMPA    #':'                              ;END OF OPRAND?
        BNE     ADVP                              ;IF SO, OK
        LDA     ,Y                                ;GET NEXT
        CMPA    #'['                              ;DIRECTORY?
        BEQ     ADVP                              ;ALLOW IT
;* END OF DIRECTORY SPECIFICATION, SEE IF FILE SPEC SUPPLIED
ADVP1
        LDA     ,Y                                ;GETR NEXT CHAR
        BEQ     ADVP3                             ;IF END, INSERT DEFAULT
        CMPA    #$0D                              ;END OF LINE?
        BEQ     ADVP3                             ;YES, INSERT DEFAULT
        CMPA    #' '                              ;END OF OPERAND?
        BNE     ADVP2                             ;NO, FILE SPEC MUST BE SUPPLIED
ADVP3
        LDX     #DEFNAM                           ;POINT TO DEFAULT FILENAME
ADVP4
        LDA     ,X+                               ;GET CHAR FROM DEFAULT
        STA     ,Y+                               ;APPEND TO OPERAND
        BNE     ADVP4                             ;CONTINUE TILL ALL MOVED
;* OPERAND IS OK, GET NAME AND BEGIN SCANNING DIRECTORY
ADVP2
        PULS    Y                                 ;RESTORE POINTER TO OPERAND
        BRA     SUPPRM                            ;PROCESS PARAMETER
;* NO OPERAND WAS SUPPLIED, POINT TO DEFAULT (ALL FILES)
DEFPRM
        LDY     #DEFNAM                           ;POINT TO DEFAULT OPERAND
SUPPRM
        SWI
        FCB     9                                 ;INFORM DOS OF FILENAME
        LBNE    ABORT                             ;OPERAND WAS INVALID, QUIT
        LDA     -1,X                              ;GET DRIVE
        STA     DRIVE                             ;SAVE IT
        SWI
        FCB     76                                ;SELECT DRIVE
;* INITIALIZE RAM TABLE
        LDA     #$FF                              ;INDICATE END OF TABLE
        STA     RAM+512                           ;PLACE AT BEGINNING OF TABLE
;* OPEN DIRECTORY, AND START READING
        LDD     #DIRLOC                           ;DIRECTORY STARTS HERE
RDSEC
        STD     SECTOR                            ;SAVE CURRENT DIRECTORY SECTOR
        LDX     #RAM                              ;POINT TO WORK AREA
        SWI
        FCB     92                                ;READ SECTOR
        LBNE    ABORT                             ;DISK ERROR, QUIT
;* TEST THIS DIRECTORY ENTRY FOR	MATCH
RDENT
        LDA     ,X                                ;GET FIRST CHAR
        BEQ     NXTENT                            ;UNUSED ENTRY, SKIP
        SWI
        FCB     19                                ;DUZ IT MATCH STORED FILENAME?
        BNE     NXTENT                            ;NO, SKIP
;* NAME MATCHES,	INSERT INTO TABLE
        LDY     #RAM+512	POINT TO TABLE
INSNAM
        PSHS    X,Y                               ;SAVE TABLE AND DIRECTORY POINTERS
        LDA     ,Y                                ;TEST FOR END OF TABLE
        BMI     INSERT                            ;YES, INSERT HERE
        LDB     #19                               ;COMPARE 19 CHARS (FULL NAME)
CMPNAM
        LDA     ,X+                               ;GET CHAR FROM DIRECTORY
        CMPA    ,Y+                               ;COMPARE WITH TABLE ENTRY
        BLO     INSERT                            ;LESS, INSERT NAME HERE
        BNE     CMPN1                             ;MUST BE HIGHER, SKIP THIS ENT
        DECB                                      ;	REDUCE COUNT
        BNE     CMPNAM                            ;KEEP GOING
;* ENTRY	WAS NOT	LESS THAN THIS ONE, TRY	NEXT
CMPN1
        PULS    X,Y                               ;RESTORE TABLE AND DIRECTORY POINTERS
        LEAY    TSIZ,Y                            ;ADVANCE TO NEXT TABLE ENTRY
        BRA     INSNAM                            ;PERFORM TEST AGAIN
;* INSERT NAME HERE
INSERT
        LDX     2,S                               ;GET TABLE POINTER
INS1
        LDA     ,X+                               ;TEST FOR END OF TABLE
        BMI     INS15                             ;YES, WE FOUND END
        LEAX    TSIZ-1,X	ADVANCE REMAINDER OF ENTRY
        BRA     INS1                              ;AND KEEP LOOKING FOR IT
INS15
        LEAY    TSIZ,X                            ;ADVANCE EXTRA SPACE FOR NEW ENTRY
INS2
        LDA     ,-X                               ;GET CHAR FROM OLD
        STA     ,-Y                               ;SAVE IN NEW POSITION
        CMPX    2,S                               ;ARE WE AT INSERT POSITION YET?
        BHI     INS2                              ;NO, KEEP MOVEING
        PULS    X,Y                               ;RESTORE TABLE AND DIRECTORY POINTERS
        PSHS    X                                 ;SAVE DIRECTORY POSITION
        LDB     #TSIZ                             ;MOVE # CHARS (DIR ENT)
INS3
        LDA     ,X+                               ;GET CHAR FROM DIRECTORY
        STA     ,Y+                               ;SAVE IN TABLE
        DECB                                      ;	REDUCE COUNT
        BNE     INS3                              ;MOCE ENTIRE NAME
        PULS    X                                 ;RESTORE DIRECTORY POSITION
;* ADVANCE TO NEXT DIRECTORY ENTRY, AND TEST IT
NXTENT
        LEAX    32,X                              ;ADVANCE TO NEXT ENTRY
        CMPX    #RAM+512	ARE WE OVER THE SECTOR LIMIT
        BLO     RDENT                             ;NO, TEST THIS ONE
        LDD     SECTOR                            ;GET SECTOR NUMBER BACK
        SWI
        FCB     77                                ;FIND NEXT LINK
        BNE     RDSEC                             ;IF MORE, KEEP LOOKING
;* WE HAVE ALL MATCHING NAMES IN	TABLE, NOW DISPLAY IT
        LDY     #RAM+512	POINT TO TABLE
DISP0
        CLR     XPOS                              ;STARTS AT COLUMN NUMBER 0
DISP1
        LDA     ,Y                                ;GET CHAR FROM TABLE
        LBMI    DISPEND                           ;END OF TABLE, QUIT
        PSHS    Y                                 ;SAVE POINTER
        LDA     NOHEAD                            ;DO WE HAVE HEADERS?
        BEQ     DIROK                             ;NO, DISPLAY NORMALLY
        LDB     #8                                ;COMPARE 8 CHARS
        LDX     #SAVDIR                           ;POINT TO SAVED DIRECTORY NAME
CMPDIR
        LDA     ,X+                               ;GET CHAR FROM SAVED
        CMPA    ,Y+                               ;SAME AS OURS?
        BNE     DISPDIR                           ;NO, NEW DIRECTORY
        DECB                                      ;	REDUCE COUNT
        BNE     CMPDIR                            ;KEEP TESTING TILL DUN
        BRA     DIROK                             ;NO HEADER TO DISPLAY, (SAME DIR)
;* DISPLAY DIRECTORY HEADER
DISPDIR
        LDD     NDIR                              ;GET DIRECTORY COUNT
        BEQ     DISPD9                            ;FIRST ONE, DON'T DISPLAY TOTALS
        LBSR    FSUM                              ;DISPAY FILE TOTAL SUMMARY
DISPD9
        LDD     NDIR                              ;GET NUMBER AGAIN
        ADDD    #1                                ;INCREMENT
        STD     NDIR                              ;RESAVE
        CLRA                                      ;	GET A ZERO
        CLRB                                      ;	16 BYTE ZERO
        STD     FTOTAL                            ;CLEAR INTERMEDIATE FILE TOTALS
        LBSR    LFCR                              ;NEW LINE
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     'Directory '
        LDA     >DRIVE                            ;GET DRIVE
        ADDA    #'A'
        SWI
        FCB     33                                ;OUTPUT
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     ':['                              ;INFO
        LDB     #8                                ;DISPAY MAX 8 CHARS
        LDY     ,S                                ;GET POINTER TO ENTRY BACK
        LDX     #SAVDIR                           ;POINT TO SAVED DIRECTORY
DISPD1
        LDA     ,Y+                               ;GET CHAR FROM ENTRY
        STA     ,X+                               ;SAVE IN NEW SAVED DIRECTORY NAME
        BEQ     DISPD2                            ;DON'T DISPLAY ZERO PADS
        SWI
        FCB     33                                ;DISPLAY ON TERMINAL
DISPD2
        DECB                                      ;	REDUCE COUNT
        BNE     DISPD1                            ;KEEP DISPLAYING
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCB     ']',$0A,0
        CLR     XPOS                              ;START IN COLUMN ZERO
DIROK
        PULS    Y                                 ;RESTORE FILE POINTER
        LDD     FTOTAL                            ;GET FILE TOTAL
        ADDD    #1                                ;INCREMENT
        STD     FTOTAL                            ;RESAVE
        LDD     GTOTAL                            ;GET GRAND TOTAL
        ADDD    #1                                ;INCREMENT
        STD     GTOTAL                            ;RESAVE
        LDA     TOTAL                             ;ARE WE ASKING FOR '/TOTAL'S ONLY?
        BEQ     TOTON                             ;IF SO, DON'T DISPLAY NAME
        LDX     #23                               ;DEFAULT SPACEING FOR '/NOHEAD'
        LDA     NOHEAD                            ;IS '/NOHEAD' IN EFFECT?
        BEQ     NOH1                              ;IF SO, DISPLAY SEPERATE DIRECTORY HEADER
        LEAY    8,Y                               ;ADVANCE PAST DIRECTORY
        LEAX    -8,X                              ;REDUCE FIELD WIDTH FOR FILENAME
        LDA     INFO                              ;ARE WE DISPLAYING INFORMATION WITH FILES?
        BEQ     NOH15                             ;IF SO, DON'T DISPLAY NAME IN COLUMNS
;* DISPLAY FILENAMES IN SHORT FORM (COLUMNS)
        LDX     #14                               ;FIELD WIDTH FOR COLUMN DISPLAY
        LDB     #8                                ;SIZE OF FILENAME
        LBSR    DISPB                             ;DISPLAY FILENAME
        LDA     #'.'                              ;SEPERATOR FOR TYPE
        SWI
        FCB     33                                ;DISPLAY
        LDB     #3                                ;SIZE OF FILETYPE
        LBSR    DISPB                             ;DISPLAY FILETYPE
        LEAY    TSIZ-19,Y	SKIP EXTRA INFO
;* FILL WITH SPACES TO NEXT COLUMN
        INC     XPOS                              ;ADVANCE COLUMN NUMBER
        LDA     XPOS                              ;GET COLUMN NUMBER
        CMPA    #5                                ;ARE WE OVER?
        BHS     DISPN                             ;IF SO, GO TO A NEW LINE
SPAC1
        LDA     #' '                              ;GET SPACE
        SWI
        FCB     33                                ;DISPLAY
        LEAX    -1,X                              ;REDUCE FIELD WIDTH
        BNE     SPAC1                             ;FILL FIELD
        LBRA    DISP1                             ;DISPLAY NEXT ENTRY
DISPN
        LBSR    LFCR1                             ;PERFORM LINE-FEED, CARRIAGE RETURN
        LBRA    DISP0                             ;DISPLAY NEXT ENTRY, AT COLUMN ZERO
;* ONLY TOTALS ARE BEING	DISPLAYED, DON'T GIVE HIM THE NAMES
TOTON
        LEAY    TSIZ,Y                            ;ADVANCE TO NEXT ENTRY
        LBRA    DISP1                             ;CHECK NEXT ENTRY
;* NOHEAD IS IN EFFECT, DISPLAY DIRECTORY PREFIX
NOH1
        LDA     >DRIVE
        ADDA    #'A'
        SWI
        FCB     33                                ;OUTPUT DRIVE
        SWI
        FCB     24
        FCN     ':['
        LDB     #8                                ;SIZE OF DIRECTORY NAME
        LBSR    DISPB                             ;DISPLAY DIRECTORY NAME
        LDA     #']'                              ;DIRECTORY END CHARACTER
        SWI
        FCB     33
;* DISPLAY FILENAME, AND	ANY INFO R=ESTED
NOH15
        LDB     #8                                ;SIZE OF FILENAME
        LBSR    DISPB                             ;DISPLAY FILENAME
        LDA     #'.'                              ;FILENAME SEPERATOR
        SWI
        FCB     33                                ;DISPLAY
        LDB     #3                                ;SIZE OF FILETYPE
        LBSR    DISPB                             ;DISPLAY FILETYPE
        LDA     INFO                              ;TEST FOR INFO TO DISPLAY
        BNE     NOSIZ                             ;NO, DISPLAY NEXT FILENAME
;* PAD WITH SPACES
NOH2
        LDA     #' '                              ;GET SPACE
        SWI
        FCB     33                                ;DISPLAY
        LEAX    -1,X                              ;REDUCE COUNT
        BNE     NOH2                              ;FILL FIELD
;* TEST FOR '/RUNADR' DISPLAY
        LDA     RUNADR                            ;DO WE WISH TO DISPLAY RUNADDRESS
        BNE     NORUN                             ;NO, DON'T DISPLAY
        LDD     2,Y                               ;GET RUN ADDRESS
        SWI
        FCB     27                                ;DISPLAY IN HEX
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     '     '                           ;SPACES
;* TEST FOR '/DSKADR' DISPLAY
NORUN
        LDA     DSKADR                            ;DO WE WANT DISK ADDRESS DISPLAYED
        BNE     NODSK                             ;NO, DON'T DISPLAY
        LDD     ,Y                                ;GET DISK ADDRESS
        SWI
        FCB     27                                ;DISPLAY
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     '     '                           ;SPACES
;* TEST FOR '/ATTRIBUTES' DISPLAY
NODSK
        LDA     ATTR                              ;ATTRIBUTES
        BNE     NOATTR                            ;NO
        LDB     4,Y                               ;GET ATTRIBUTES
        LDX     #ATRTAB                           ;PT TO TABLE
        LDA     #9                                ;FLAGS
        STA     XPOS                              ;SAVE IT
NODS1
        TSTB                                      ;	ANY LEFT
        BEQ     NODS2                             ;NO
        LDA     ,X+                               ;GET CHAR
        LSLB                                      ;	SHIFT IT
        BCC     NODS1                             ;NONE
        DEC     XPOS                              ;INDICATE CHAR OUT
        SWI
        FCB     33                                ;OUTPUT
        BRA     NODS1                             ;CONTINUE
NODS2
        SWI
        FCB     21                                ;DISPLAY SPACE
        DEC     XPOS                              ;REDUCE
        BNE     NODS2                             ;MORE, KEEP GOING
;* TEST FOR '/SIZE' DISPLAY
NOATTR
        LDA     SIZE                              ;DO WE WISH TO DISPLAY SIZE?
        BNE     NOSIZ                             ;NO, DON'T DISPLAY
        PSHS    Y                                 ;SAVE POINTER TO ENTRY
        LDD     ,Y                                ;GET DISK ADDRESS
        LDY     #0                                ;START WITH SIZE OF ZERO
;* TRAVERSE LINK	CHAIN, DETERMINING SIZE	OF FILE
SIZ1
        LEAY    1,Y                               ;INCREMENT SIZE BY ONE SECTOR
        SWI
        FCB     77                                ;LOOK FOR NEXT CHAIN
        BNE     SIZ1                              ;KEEP TRAVERSING
        TFR     Y,D                               ;COPY SIZE TO D FOR DISPLAY
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        PULS    Y                                 ;RESTORE POINTER TO ENTRY
NOSIZ
        LEAY    TSIZ-19,Y	SKIP INFO
        LBRA    DISPN                             ;DISPLAY NEXT ENTRY
;* END OF RAM TABLE, DISPLAY CLOSING SUMMARIES
DISPEND
        LBSR    FSUM                              ;DISPLAY FILE SUMMARY FOR LAST DIRECTORY
        LDD     NDIR                              ;FIND OUT HOW MANY DIRECTORIES WE HIT
        CMPD    #1                                ;WAS THERE MORE THAN ONE?
        BLS     DISPEX                            ;NO, SKIP GRAND TOTAL
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCB     $0A,$0D                           ;NEW LINE
        FCN     'Grand total of '
        LDD     NDIR                              ;GET NUMBER OF DIRECTORIES
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     ' directories, '
        LDD     GTOTAL                            ;GET GRAND TOTAL OF FILES
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     ' files.'
DISPEX
        CLRA                                      ;	ZERO RETURN CODE
ABORT
        SWI
        FCB     0                                 ;RETURN TO DOS
;*   *** SUBROUTINES ***
;*
;* DISPLAY ENTRY	FOR MAX	CHARS IN B, DECREMENT FIELD POSITION (IN X)
DISPB
        LDA     ,Y+                               ;GET CHAR FROM ENTRY
        BEQ     DISPB1                            ;END OF ENTRY, QUIT
        SWI
        FCB     33                                ;DISPLAY
        LEAX    -1,X                              ;REDUCE FIELD POSITION
DISPB1
        DECB                                      ;	REDUCE COUNT OF ENTRY SIZE
        BNE     DISPB                             ;KEEP TRYING
        RTS
;* SUMMARISE FILES
FSUM
        TST     TOTAL                             ;ARE WE DISPLAYING TOTAL
        BEQ     FSUM1                             ;IS SO, SKIP EXTRA LFCR
        BSR     LFCR                              ;NEW LINE
FSUM1
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Total of '
        LDD     FTOTAL                            ;GET TOTAL
        SWI
        FCB     26                                ;OUTPUT NUMBER
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     ' files.'
        RTS
;* LFCR ROUTINE
LFCR
        BSR     LFCR1                             ;DISPLAY NEW LINE
        LDA     XPOS                              ;TEST FOR AT COLUMN ZERO
        BEQ     LFCRE                             ;IF SO, ALL DONE
LFCR1
        SWI
        FCB     22                                ;LFCR
LFCRE
        RTS
;* PREDEFINED STRINGS
DEFNAM
        FCN     '*.*'                             ;DEFAULT FILENAME OPERAND
ATRTAB
        FCC     'RWED????'	ATTRIBUTE TABLE
;* TABLE	OF VALID QUALIFIERS
QTABLE
        FCB     $82
        FCC     '/TOTAL'	DISPLAY TOTALS ONLY
        FCB     $82
        FCC     '/NOHEADER'	NO DIRECTORY HEADER
        FCB     $82
        FCC     '/SIZE'                           ;DISPLAY FILE SIZE
        FCB     $82
        FCC     '/LOAD'                           ;DISPLAY FILE RUN ADDRESS
        FCB     $82
        FCC     '/DISK'                           ;DISPLAY FILE DISK ADDRESS
        FCB     $82
        FCC     '/PROT'
        FCB     $80                               ;END OF TABLE
QMAX            = 6                               ;# QUALIFIERS
;* QUALIFIER FLAGS
QFLAGS          = *
TOTAL
        FCB     $FF                               ;TOTAL ONLY FLAG
NOHEAD
        FCB     $FF                               ;NO DIR. HEADER FLAG
SIZE
        FCB     $FF                               ;DISPLAY SIZE FLAG
RUNADR
        FCB     $FF                               ;DISPLAY RUN ADDRESS FLAG
DSKADR
        FCB     $FF                               ;DISPLAY DISK ADDRESS FLAG
ATTR
        FCB     $FF                               ;DISPLAY FILE ATTRIBUTES
INFO
        FCB     $FF                               ;0 IF ANY INFO PRINTING
SAVDIR
        FCB     0,0,0,0,0,0,0,0
XPOS
        FCB     0                                 ;OUTPUT COLUMN INDICATOR
NDIR
        FDB     0                                 ;NUMBER OF DIRECTORIES FOUND
FTOTAL
        FDB     0                                 ;INTERMEDIATE FILE TOTALS
GTOTAL
        FDB     0                                 ;GRAND FILE COUNT TOTAL
SECTOR
        RMB     2                                 ;SAVED CURRENT DIRECTORY SECTOR
DRIVE
        RMB     1                                 ;DOS DRIVE
RAM             = *                               ;FREE RAM
