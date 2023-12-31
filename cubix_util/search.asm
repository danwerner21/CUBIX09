;*
;* SEARCH: Global file search for text or binary strings
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
;* DIRECTORY STRUCTURE
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
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
;* FILE ATTRIBUTES
RPERM=%10000000
WPERM=%01000000
EPERM=%00100000
DPERM=%00010000
;*
DIRLOC=0                                          ;DIRECTORY STARTS HERE
;*
        ORG     OSUTIL                            ;UTILITY SPACE
SEARCH
        CMPA    #'?'                              ;QUERY REQUEST?
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIERS
        SWI
        FCB     25
        FCC     'Use: SEARCH[/BINARY/CASE/HEX/TOTAL]'
        FCN     ' <filespec> <search string>'
        RTS
;* PERFORM SEARCH
;* PARSE FOR COMMAND QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR FROM COMMAND LINE
        CMPA    #'/'                              ;IS IT A QUALIFIER?
        BNE     MAIN                              ;NO, DO PGM
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
        FCN     /Invalid qualifier: /
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
        LBRA    ABORT                             ;GIVE UP
;* MAIN PROGRAM
MAIN
        SWI
        FCB     9                                 ;GET PATTERN
        LBNE    ABORT                             ;BAD, GIVE UP
        LDA     -1,X                              ;GET DRIVE
        SWI
        FCB     76                                ;Select this drive
        LDU     #BUFFER                           ;POINT TO BUFFER
        CLR     BUFSIZ                            ;BUFFER SIZE INDICATOR
        TST     HEX                               ;IS STRING HEX
        BNE     STRIN                             ;NO, INPUT A STRING
;* INPUT HEX BYTES TO SEARCH FOR
HEXIN
        SWI
        FCB     7                                 ;GET HEX NUMBER
        LBNE    ABORT                             ;INVALID, QUIT
        TFR     X,D                               ;COPY
        STB     ,U+                               ;SAVE IT
        INC     BUFSIZ                            ;ADVANCE SIZE
        SWI
        FCB     4                                 ;MORE OPERANDS?
        BNE     HEXIN                             ;GET NEXT OPERAND
        BRA     GOTOP                             ;WE HAVE OEPRAND
;* INPUT A STRING VALUE
STRIN
        SWI
        FCB     4                                 ;GET VALUE
        BEQ     BADSTR                            ;ITS BAD
        LEAY    1,Y                               ;SKIP IT
        STA     TEMP                              ;SAVE
        CMPA    ,Y                                ;NULL STRING?
        BEQ     BADSTR                            ;ITS BAD
STR1
        LDA     ,Y+                               ;GET CHAR FROM STRING
        BEQ     BADSTR                            ;ITS BAD
        CMPA    TEMP                              ;ARE WE AT END?
        BEQ     GOTOP                             ;WE HAVE IT
        INC     BUFSIZ                            ;ADVANCE
        STA     ,U+                               ;SAVE
        CMPA    #$0D                              ;CR?
        BNE     STR1                              ;NO, ITS OK
;* STRING OPERAND IS INVALID
BADSTR
        SWI
        FCB     43                                ;INVALID OPERAND MESSAGE
        LBRA    ABORT                             ;GO HOME
;* WE HAVE SEARCH OPERAND
GOTOP
        LDD     #DIRLOC                           ;DIRECTORY STARTS HERE
SCAND
        STD     SECTOR                            ;SAVE DIRECTORY SECTOR
        LDX     #DIRBUF                           ;POINT TO FREE SPACE
        SWI
        FCB     92                                ;READ DISK
        LBNE    ABORT                             ;DISK ERROR
SCAND1
        SWI
        FCB     19                                ;DOES THIS ONE MATCH?
        BEQ     SCANF                             ;IF SO, SCAN THE FILE
NXTDIR
        LEAX    32,X                              ;SKIP TO NEXT
        CMPX    #DIRBUF+512	BEYOND END?
        BLO     SCAND1                            ;NO, WE ARE OK
        LDD     SECTOR                            ;GET SECTOR NUMBER
        SWI
        FCB     77                                ;GET NEXT SECTOR
        BNE     SCAND                             ;CONTINUE IF MORE
        LDD     FMATCH                            ;DID ANY FILES MATCH?
        BEQ     NOMAT                             ;NO, ERROR
        CMPD    #1                                ;SEARCHED ONLY ONE
        BEQ     SEREND                            ;IF SO, NO GRAND TOTAL
        SWI
        FCB     24                                ;DISPLAY MSG
        FCN     'Searched '
        SWI
        FCB     26                                ;DISPLAY
        SWI
        FCB     24                                ;DISPLAY MSG
        FCN     ' files, for a total of '
        LDD     GMATCH                            ;GET GRAND TOTAL MATCHES
        SWI
        FCB     26                                ;DISPLAY
        SWI
        FCB     25                                ;DISPLLY MESSAGE
        FCN     ' matches.'
SEREND
        CLRA                                      ;	ZERO RETURN CODE
        BRA     ABORT                             ;QUIT
NOMAT
        SWI
        FCB     44                                ;FILE NOT FOUND
ABORT
        SWI
        FCB     0                                 ;GO HOME
;* MATCHING FILE WAS FOUND, SEARCH IT
SCANF
        PSHS    X                                 ;SAVE POINTER INTO ENTRY
        LDD     FMATCH                            ;FILE MATCH,
        ADDD    #1                                ;INCREMENT
        STD     FMATCH                            ;RESAVE
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Scanning file: '
        SWI
        FCB     31                                ;DISPLAY
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #RPERM                            ;CAN WE READ
        BNE     PROTOK
        SWI
        FCB     25
        FCN     ' - Protection violation'
        LBRA    NXTDIR                            ;GET NEXT
PROTOK
        SWI
        FCB     22                                ;NEW LINE
        CLRA
        CLRB
        STD     BYTCT                             ;SAVE BYTE COUNT
        STD     NMATCH                            ;SAVE NUMBER OF MATCHES
        INCB
        STD     LINCT                             ;CURRENT LINE COUNTER
;* READ SECTORS FROM FILE, AND SCAN THEM
        LDD     DDADR,X                           ;GET DISK ADDRESS
SCSEC
        STD     FSEC                              ;SAVE
        LDX     #WRKBUF                           ;POINT TO WORK BUFFER
        STX     WRKPTR                            ;SAVE POINTER
        SWI
        FCB     92                                ;READ SECTOR
        BNE     ABORT                             ;INVALID
;* SCAN 1K SECTOR(X) FOR CONTENTS OF BUFFER
        LDY     #BUFF1                            ;POINT TO BUFFER
        LDB     BUFSIZ                            ;GET BUFFER SIZE
;* FILL COMPARE BUFFER FROM FILE
SCAN1
        BSR     RDFIL                             ;READ FILE
        STA     ,Y+                               ;SAVE IN BUFFER
        DECB                                      ;	REDUCE COUNT
        BNE     SCAN1                             ;CONTINUE
;* COMPARE COMPARE BUFFER WITH FILE CONTENTS
SCAN2
        LDX     #BUFFER                           ;POINT TO BUFFER
        LDY     #BUFF1                            ;POINT TO OTHER BUFFER
        LDB     BUFSIZ                            ;GET BUFFER SIZE
SCAN3
        LDA     ,X+                               ;GET CHAR FROM BUFFER
        CMPA    ,Y+                               ;COMPARE WITH OTHER
        BNE     SCAN4                             ;NO MATCH
        DECB                                      ;	REDUCE COUNT
        BNE     SCAN3                             ;KEEP LOOKING
;* STRING WAS FOUND
        LDD     NMATCH                            ;GET NUMBER OF MATCHES
        ADDD    #1                                ;ADVANCE
        STD     NMATCH                            ;RESAVE
        LDA     TOTAL                             ;IS IT TOTAL ONLY?
        BEQ     SCAN4                             ;YES, DON'T DISPLAY
        LDA     BINARY                            ;BINARY ONLY?
        BEQ     BINDI                             ;IF DSO, DISPLAY OFFSET ONLY
        SWI
        FCB     24                                ;DISPLAY MSG
        FCN     'Line: '
        LDD     LINCT                             ;GET LINE COUNTER
        SWI
        FCB     26                                ;DISPLAY
        SWI
        FCB     24                                ;DISPLAY MSG
        FCN     ', '
BINDI
        SWI
        FCB     24
        FCN     'Offset: '
        LDB     BUFSIZ                            ;GET BUFFER SIZE
        CLRA                                      ;	ZERO HIGH
        PSHS    A,B                               ;SAVE
        LDD     BYTCT                             ;GET BYTE COUNT
        SUBD    ,S                                ;CONVERT
        STD     ,S                                ;SAVE
        SWI
        FCB     26                                ;DISPLAY
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     ' ($'
        PULS    A,B                               ;RESTORE
        SWI
        FCB     27                                ;DISPLAY
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     ')'
SCAN4
        LDX     #BUFF1                            ;POINT TO COMPARE BUFFER
        LDB     BUFSIZ                            ;GET SIZE
SCAN5
        LDA     1,X                               ;GET CHAR
        STA     ,X+                               ;RESAVE
        DECB                                      ;	REDUCE COUNT
        BNE     SCAN5                             ;CONTINUE
        BSR     RDFIL                             ;READ A CHAR
        STA     -1,X                              ;SAVE
        BRA     SCAN2                             ;CONTINUE
;*
;* RDFILE
;*
RDFIL
        PSHS    B,X                               ;SAVE REG
        LDD     BYTCT                             ;GET BYTE COUNT
        ADDD    #1                                ;ADVANCE
        STD     BYTCT                             ;RESAVE
        LDX     WRKPTR                            ;GET POINTER
        CMPX    #WRKBUF+512	ADVANCE
        BLO     RDFOK                             ;OK
        LDD     FSEC                              ;GET FILE SECTOR
        SWI
        FCB     77                                ;NEW SECTOR?
        BEQ     FILEOF                            ;END OF FILE
        LDX     #WRKBUF                           ;SET IT UP
        STD     FSEC                              ;RESAVE
        SWI
        FCB     92                                ;READ DISK
        LBNE    ABORT                             ;BAD
RDFOK
        LDA     ,X+                               ;GET CHAR
        BPL     RDFO1                             ;NORMAL
        LDB     BINARY                            ;ARE WE TREATING AS BINARY
        BNE     FILEOF                            ;NO, END OF FILE
RDFO1
        STX     WRKPTR                            ;RESAVE POINTER
        CMPA    #$0D                              ;NEW LINE?
        BNE     RDF1                              ;NO
        LDX     LINCT                             ;GET LINE COUNT
        LEAX    1,X                               ;ADVANCE
        STX     LINCT                             ;RESAVE
RDF1
        LDB     CASE                              ;IS LOWER CASE CONVERT ENABLED?
        BNE     RDF2                              ;NO, SKIP IT
        CMPA    #$61                              ;LOWER CASE?
        BLO     RDF2                              ;NO, DON'T CONVERT
        CMPA    #$7A                              ;LOWER CASE?
        BHI     RDF2                              ;NO, DON'T CONVERT
        ANDA    #$5F                              ;CONVERT TO UPPER CASE
RDF2
        PULS    B,X,PC
FILEOF
        LEAS    5,S                               ;SKIP SAVED X AND PC
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Total of '
        LDD     NMATCH                            ;GET NUMBER OF MATCHES
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     ' matches were found.'
        LDD     GMATCH                            ;GET GRAND MATCH TOTAL
        ADDD    NMATCH                            ;ADD IN THIS MATCHES
        STD     GMATCH                            ;SAVE
        PULS    X                                 ;RESTORE POINTER
        LBRA    NXTDIR
;* STRINGS
QTABLE
        FCB     $82
        FCC     '/HEX'                            ;HEX INPUT
        FCB     $82
        FCC     '/BINARY'	BINARY INPUT FILE
        FCB     $82
        FCC     '/TOTAL'	TOTAL MATCHES ONLY
        FCB     $82
        FCC     '/CASE'                           ;CASE CONVERSION
        FCB     $80
QMAX            = 4
;*
QFLAGS          = *
HEX
        FCB     $FF                               ;HEX INPUT STRING
BINARY
        FCB     $FF                               ;BINARY INPUT FILE
TOTAL
        FCB     $FF                               ;DISPLAY TOTALS ONLY
CASE
        FCB     $FF                               ;FORCE CASE CONVERSIONS
;*
;* LOCAL STORAGE
;*
FMATCH
        FDB     0
GMATCH
        FDB     0
TEMP
        RMB     2
SECTOR
        RMB     2
FSEC
        RMB     2
BUFSIZ
        RMB     1
WRKPTR
        RMB     2
NMATCH
        RMB     2
LINCT
        RMB     2
BYTCT
        RMB     2
BUFFER
        RMB     80
BUFF1
        RMB     80
DIRBUF
        RMB     512
WRKBUF
        RMB     512
