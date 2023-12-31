;        TITLE   IMAGE BUILDER
;*
;* BUILD: Build an executable or downloadable file from ASM output
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
;* DIRECTORY STRUCTURE

OSRAM           = $2000                           ; START OF OS OPERATING AREA

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
        ORG     OSRAM                             ;DOS APPLICATION PROGRAM SPACE
;* PROGRAM ENTRY
BUILD
        CMPA    #'?'                              ;QUERY OPERAND?
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIER
        SWI
        FCB     25
        FCN     'Use: BUILD[/KEEP/MHX/QUIET] <object file>'
        SWI
        FCB     0
;*
;* PARSE	FOR QUALIFIERS
;*
QUAL
        LDA     ,Y                                ;GET CHAR FROM COMMAND LINE
        CMPA    #'/'                              ;IS IT A QUALIFIER?
        BNE     MAIN                              ;NO, GET PARAMETERS
        LDX     #QTABLE                           ;POINT TO QUALIFIER TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;IS IT IN RANGE
        BHS     QERR                              ;IF SO, IT'S INVALID
        LDX     #QFLAGS                           ;POINT TO QUALIFIER FLAGS
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
;* MAIN BUILD PROGRAM
MAIN
        SWI
        FCB     11                                ;GET FILENAME
        BNE     ABORT                             ;ERROR, EXIT
        STX     FILPTR                            ;SAVE FILE POINTER
        LDD     #$4f42                            ;FIRST TWO CHARS OF TYPE 'OB'
        STD     ,X                                ;SAVE
        LDA     #'J'                              ;NEXT CHAR OF TYPE
        STA     2,X                               ;SAVE IN FILENAME
        LDA     MHX                               ;ARE WE DOING A 'MHX' FILE?
        LBEQ    DOMHX                             ;IF SO, BUILD IT
        SWI
        FCB     70                                ;LOOKUP FILE
        BNE     ABORT                             ;GET UPSET IF ERROR
        LDD     DDADR,X                           ;GET DISK ADDRESS
        STD     >SECTOR                           ;SAVE FOR LATER
        LDX     #WRKSPC                           ;POINT TO WORKSPACE
        STX     >OFFSET                           ;SAVE OFFSET
        SWI
        FCB     92                                ;READ A SECTOR
        BNE     ABORT                             ;ERROR
;* READ OBJECT FILE, AND BUILD EXECUTABLE IMAGE IN RAM
        LDX     #0                                ;ASSUME OFFSET ZERO
NXCHR
        LBSR    RDCHR                             ;READ CHARACTER FROM FILE
        CMPA    #$CF                              ;IS IT A SPECIAL CASE
        BNE     NORCHR                            ;NO, IT'S NORMAL
        LBSR    RDCHR                             ;GET NEXT CHARACTER
        CMPA    #$CF                              ;IS IT XPARENT '$CF'?
        BEQ     NORCHR                            ;IF SO, IT'S OK
        TSTA                                      ;	IS THIS THE END?
        BEQ     SAVMOD                            ;IF SO, SAVE IT
        DECA                                      ;	TEST FOR SET ADDRESS
        BNE     INVCMD                            ;NO, IT'S INVALID
;* ADDRESS CHANGE RECORD, SET UP NEW ADDRESS
        LBSR    RDCHR                             ;GET HIGH BYTE
        TFR     A,B                               ;SAVE IN B
        LBSR    RDCHR                             ;GET NEXT BYTE
        EXG     A,B                               ;SWAP HIGH AND LOW
;* IF CODE HAS ALREADY BEEN OUTPUT, CALCULATE 'X'=
;* THE ADDRESS WITHIN THE OUTPUT MODULE. OTHERWISE
        TST     SETADR                            ;HAS RUN ADDRESS BEEN FIXED YET?
        BEQ     NXCH1                             ;YES, DO NOT CHANGE
        SUBD    RUNADR                            ;CONVERT TO OFFSET
        ADDD    #MODBUF                           ;OFFSET TO MUDULT
NXCH1
        TFR     D,X                               ;'X' = POINTER TO BUFFER
        BRA     NXCHR                             ;AND GET NEXT CHAR
;* NORMAL CHARACTER, SAVE IT IN THE MODULE. IF THIS IS
;* THE FIRST CHARACTER OUTPUT, ESTABLISH FILE RUN ADDRESS
;* AND SET UP POINTER INTO MODULE
NORCHR
        LDB     SETADR                            ;HAS FLAG BEEN SET?
        BNE     NORCH1                            ;YES, ITS HAS
        STX     RUNADR                            ;SET UP RUN ADDRESS
        LDX     #MODBUF                           ;BEGIN AT START OF MODULE
        DEC     SETADR                            ;INDICATE RUN ADDRESS
NORCH1
        STA     ,X+                               ;SAVE IN GENERATING MODULE
        CMPX    HIADR                             ;ARE WE ABOVE OUR HIGHEST?
        BLS     NXCHR                             ;NO, GET NEXT CHARACTER
        STX     HIADR                             ;SAVE THIS AS OUR NEW HIGH ADDRESS
        BRA     NXCHR                             ;READ NEXT
;* INVALID COMMAND
INVCMD
        SWI
        FCB     25                                ;MESSAGE
        FCN     'Invalid OBJ file format'
        LDA     #99                               ;RETURN CODE
        SWI
        FCB     0                                 ;EXIT
;* MODULE IS BUILT, SAVE IT OUT
SAVMOD
        LDA     KEEP                              ;DO WE KEEP FILE?
        BEQ     SAVM1                             ;YES, DON'T DELETE
        SWI
        FCB     73                                ;DELETE THE FILE
SAVM1
        LDX     FILPTR                            ;GET FILE POINTER
        LDD     #$4558                            ;FIRST TWO CHARS 'EX'
        STD     ,X                                ;WRITE IT OUT
        STA     2,X                               ;SET LAST CHAR
;* DISPLAY STATS ON THE OUTPUT FILE
        LDA     QUIET                             ;BEING QUIET?
        BEQ     SAVM2                             ;YES, NO DISPLAY
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Load addr= $'	MESSAGE
        LDD     RUNADR                            ;GET RUN ADDRESS
        SWI
        FCB     27                                ;DISPLAY
        SWI
        FCB     22                                ;NEW LINE
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     'File Size= '
        LDD     HIADR                             ;GET HIGHEST ADDRESS
        SUBD    #MODBUF                           ;CONVERT TO OFFSET
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     ' Bytes.'
SAVM2
        LDD     HIADR                             ;GET HIGHEST ADDRESS
        SUBD    #MODBUF                           ;CONVERT TO OFFSET
        LSRA                                      ;	CONVERT TO SECTOR ADDR
        INCA                                      ;	ADD ONE FOR PARTIAL SECTORS
        TFR     A,B                               ;COPY TO LOW BYTE
        CLRA                                      ;	CLEAR HIGH BYTE
        LDX     #MODBUF                           ;POINT TO MODULE BUFFER
        SWI
        FCB     54                                ;WRITE FILE
        BNE     ABORT1                            ;COULDN'T WRITE
        SWI
        FCB     68                                ;FIND DIRECTORY ENTRY
        LDD     RUNADR                            ;GET RUN ADDRESS
        STD     DRADR,X                           ;SAVE NEW RUN ADDRESS
        SWI
        FCB     85                                ;INDICATE WE CHANGED
;*
;* INDICATE WE CREATED A FILE
;*
CREFIL
        LDA     QUIET                             ;KEEPING QUIET?
        BEQ     CREF1                             ;IF SO, SAY NOTHING
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Output file is: '
        SWI
        FCB     30                                ;DISPLAY
        SWI
        FCB     22                                ;NEW LINE
CREF1
        CLRA                                      ;	ZERO RC
ABORT1
        SWI
        FCB     0                                 ;BACK TO OS
;*
;* CREATE A MOTOROLA HEX FORMAT OUTPUT FILE
;*
DOMHX
        LDX     #MODBUF                           ;POINT TO MODULE BUFFER
        TFR     X,Y                               ;SET UP OUTPUT PTR
        SWI
        FCB     53                                ;LOAD THE OBJECT FILE
        STX     HIADR                             ;SET HIGH ADDRESS
        LDA     KEEP                              ;DO WE KEEP THE FILE?
        BEQ     DOMHX1                            ;YES, DON'T DELETE
        SWI
        FCB     73                                ;DELETE THE FILE
DOMHX1
        LDX     FILPTR                            ;GET FILE POINTER
        LDD     #$4d48                            ;GET FIRST TWO CHARS 'MH'
        STD     ,X                                ;SET TYPE
        LDA     #'X'                              ;GET LAST CHAR
        STA     2,X                               ;SET LAST CHAR
        LDU     #OUTFIL                           ;GET OUTPUT PTR
        SWI
        FCB     56                                ;OPEN FILE FOR WRITE
        BNE     ABORT1                            ;ERROR, DON'T WRITE
;* WRITE THE FILE FROM THE MEMORY IMAGE
GENREC
        CLRB                                      ;	START HERE
        LDX     #MODBUF                           ;POINT TO BUFFER
GENR1
        CMPY    HIADR                             ;ARE WE OVER?
        LBHS    INVCMD                            ;INVALID
        LDA     ,Y+                               ;GET CHAR
        CMPA    #$CF                              ;SPECIAL CHARACTER?
        BNE     CHRNOR                            ;NO, IT'S OK
        LDA     ,Y+                               ;READ NEXT CHARACTER
        CMPA    #$CF                              ;SPECIAL CHARACTER?
        BEQ     CHRNOR                            ;NORMAL CHARACTER
        TSTA                                      ;	IS IT END OF FILE?
        BEQ     CLOSE                             ;IF SO, CLOSE FILE AND RETIRE
        DECA                                      ;	TEST FOR ADDRESS CHANGE
        LBNE    INVCMD                            ;INVALID ENTRY
        BSR     WRREC                             ;WRITE OUT RECORD
        LDA     ,Y+                               ;GET HIGH BYTE OF ADDRESS
        STA     RUNADR                            ;SET RUN ADDRESS
        LDA     ,Y+                               ;GET LOW BYTE OF ADDRESS
        STA     RUNADR+1	SET LOW BYTE OF RUN ADDRESS
        BRA     GENREC                            ;GENERATE A NEW RECORD
CHRNOR
        STA     ,X+                               ;SAVE IN RECORD
        INCB                                      ;	ADVANCE B REGISTER
        CMPB    #32                               ;ARE WE OVER ONE RECORD?
        BLO     GENR1                             ;IF NOT, KEEP GOING
        BSR     WRREC                             ;WRITE A RECORD
        BRA     GENREC                            ;AND START A NEW ONE
;*
;* CLOSE FILE
;*
CLOSE
        BSR     WRREC                             ;OUTPUT LAST RECORD IF ANY
        LDX     #S9REC                            ;LAST MESSAGE
CLOS1
        LDA     ,X                                ;GET CHARACTER FROM MESSAGE
        BSR     WRCHAR                            ;OUTPUT CHARACTER
        LDA     ,X+                               ;GET CHAR BACK
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BNE     CLOS1                             ;NO, KEEP GOING
CLSFIL
        SWI
        FCB     57                                ;CLOSE FILE
        LBRA    CREFIL                            ;OUTPUT MESSAGE
;*
;* WRITES A RECORD TO THE OUTPUT FILE
;*
WRREC
        TSTB                                      ;	WHAT IS LENGTH?
        BEQ     NOREC                             ;DON'T WRITE RECORD
        LDU     #OUTFIL                           ;PT TO OUTPUT
        LDX     #MODBUF                           ;POINT TO BUFFER
        LDA     #'S'                              ;GET RECORD
        BSR     WRCHAR                            ;OUTPUT CHAR
        LDA     #'1'                              ;TYPE ONE
        BSR     WRCHAR                            ;OUTPUT CHAR
        PSHS    B                                 ;SAVE LENGTH
        STB     OFFSET                            ;SAVE COUNT
        ADDB    #3                                ;ADVANCE FOR LENGTH BYTES
        TFR     B,A                               ;SAVE FOR LATER
        ADDA    RUNADR                            ;ADD IN HIGH ADDRESS
        ADDA    RUNADR+1	AND LOW ADDRESS
        STA     SETADR                            ;START CHECKSUM
        TFR     B,A                               ;RESTORE LENGTH
        BSR     WRBYTE                            ;OUTPUT
        LDD     RUNADR                            ;GET RUN ADDRESS
        BSR     WRBYTE                            ;OUTPUT
        TFR     B,A                               ;COPY TO ACCA
        BSR     WRBYTE                            ;OUTPUT LOW ADDRESS
WRE1
        LDA     ,X                                ;GET BYTE OF DATA
        BSR     WRBYTE                            ;OUTPUT
        LDA     ,X+                               ;GET BYTE BACK
        ADDA    SETADR                            ;ADD TO CHECKSUM
        STA     SETADR                            ;RESAVE CHECKSUM
        DEC     OFFSET                            ;IS THIS IT?
        BNE     WRE1                              ;NO, KEEP GOING
WRE2
        LDA     #$FF                              ;GET -1
        SUBA    SETADR                            ;CALCULATE CHECKSUM VALUE
        BSR     WRBYTE                            ;OUTPUT
        LDA     #$0D                              ;NEW LINE
        BSR     WRCHAR                            ;OUTPUT CHAR
        PULS    B                                 ;RESTORE LENGTH
        CLRA                                      ;	ZERO HIGH BYTE
        ADDD    RUNADR                            ;OFSET INTO MEMORY ADDRESS
        STD     RUNADR                            ;RESAVE
NOREC
        RTS
;*
;* WRITES A BYTE IN HEX TO THE SERIAL FILE
;*
WRBYTE
        PSHS    A                                 ;SAVE A REGISTER
        ASRA
        ASRA                                      ;	ROTATE HIGH NIBBLE
        ASRA                                      ;	INTO LOW NIBBLE
        ASRA
        BSR     WRNIB                             ;OUTPUT A NIBBLE
        PULS    A                                 ;RESTORE LOW NIBBLE
WRNIB
        ANDA    #$F                               ;REMOVE HIGH GARBAGE
        ADDA    #$30                              ;CONVERT TO ASCII
        CMPA    #$3A                              ;IS IT '0' TO '9'
        BLO     WRCHAR                            ;IF SO, IT'S OK
        ADDA    #7                                ;CONVERT TO ALPHA
;* WRITE A CHARACTER TO THE OUTPUT FILE
WRCHAR
        SWI
        FCB     61                                ;OUTPUT CHARACTER
        BEQ     NOREC                             ;SUCCESS, CONTINUE
        SWI
        FCB     0                                 ;ABORT WRITE
;*
;* READ A CHARACTER FROM THE INPUT FILE
;*
RDCHR
        PSHS    B,X                               ;SAVE REGS
        LDX     >OFFSET                           ;GET OFFSET INFO FILE
        CMPX    #WRKSPC+512	OVER LIMIT?
        BLO     RDC1                              ;NO, WE ARE OK
        LDD     >SECTOR                           ;GET SECTOR
        SWI
        FCB     77                                ;LOOKUP LINK
        LBEQ    INVCMD                            ;INVALID FILE
        STD     >SECTOR                           ;RESAVE SECTOR
        LDX     #WRKSPC                           ;POINT TO WORK AREA
        SWI
        FCB     92                                ;READ SECTOR
RDC1
        LDA     ,X+                               ;GET CHAR
        STX     >OFFSET                           ;RESAVE OFFSET
        PULS    B,X,PC
;*
;* END OF FILE RECORD FOR MHX FORMAT
;*
S9REC
        FCC     'S9030000FC'
        FCB     $0D
;*
;* QUALIFIER  TABLE
;*
QTABLE
        FCB     $82
        FCC     '/KEEP'
        FCB     $82
        FCC     '/MHX'
        FCB     $82
        FCC     '/QUIET'
        FCB     $80
QMAX            = 3                               ;TWO OUTPUT FORMATS APPLICABLE
;* QUALIFIER FLAG TABLE
QFLAGS          = *
KEEP
        FCB     $FF                               ;KEEP '.OBJ' FILE
MHX
        FCB     $FF                               ;WRITE MHX FILE
QUIET
        FCB     $FF                               ;KEEP QUIET
;*
FILPTR
        FDB     0                                 ;POINTER TO FILE SPACE
RUNADR
        FDB     0                                 ;FILE RUN ADDRESS
HIADR
        FDB     0                                 ;HIGEST ADDRESS IN GENERATION
SETADR
        FCB     0                                 ;FLAG THAT ADDRESS HAS BEEN SET
SECTOR
        RMB     2                                 ;INPUT FILE SECTOR
OFFSET
        RMB     2                                 ;INPUT FILE DRIVE
WRKSPC
        RMB     512                               ;INPUT FILE BUFFER
OUTFIL
        RMB     522                               ;OUTPUT FILE BUFFER
MODBUF          = *
