;*
;* TYPE: Display file/memory/disk on console or list device
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
PAGSIZ          = 22                              ;PAGE SIZE
ESCCHR          = $1B                             ;ESCAPE CHARACTER
TAB             = $09                             ;TAB CHARACTER
CR              = $0D                             ;CARRIAGE RETURN
LF              = $0A                             ;LINE-FEED
;* DIRECTORY ENTRY STRUCTURE
        ORG     0
DPREFIX
        RMB     8                                 ;DIRECTRY PREFIX
DNAME
        RMB     8                                 ;FILENAME
DTYPE
        RMB     3                                 ;FILETYPE
DDADR
        RMB     2                                 ;DISK ADDRESS
DRADR
        RMB     2                                 ;RUN ADDRESS
DATTR
        RMB     1                                 ;FILE ATTRIBUTES
;*
        ORG     OSUTIL                            ;DOS UTILITY RUN AREA
TYPE
        CMPA    #'?'                              ;QUERY?
        BNE     QUAL                              ;SHOW HOW IT'S DONE
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCC     'Use: TYPE[/DISK/DUMP/MEMORY/PAGE] <file> or'
        FCN     ' <address> [<device>]'
        RTS
;* PARSE FOR COMMAND QUALIFIERS
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
        FCN     '/Invalid qualifier: '
        LDA     ,Y+                               ;GET CHARACTER
DSQU1
        SWI
        FCB     33                                ;DISPLAY
        SWI
        FCB     5                                 ;GET NEXT CHAR
        BEQ     GOABO                             ;END, EXIT
        CMPA    #'/'                              ;START OF ANOTHER QUALIFIER?
        BNE     DSQU1                             ;NO, KEEP DUMPING
GOABO
        SWI
        FCB     25,$22,0                          ;DISPLAY MESSAGE
        LDA     #1                                ;INVALID OPERAND RETURN CODE
        RTS
;* MAIN PGM
MAIN
        STS     SAVSTK                            ;SAVE STACK
        SWI
        FCB     40                                ;GET DEFAULT DEVICE
        STA     >DEVICE                           ;SET DEFAULT
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     MEMADR                            ;INIT TO ZERO OFFSET
        LDA     MEMORY                            ;ARE WE REFERENCING MEMORY?
        BEQ     MEMREF                            ;IF SO, DISPLAY IT
        LDA     DISK                              ;ARE WE DISPLAYING DATA FROM DISK
        BNE     GETFIL                            ;NO, GET FILENAME
;* READ ABSOLUTE DISK ADDRESES
        SWI
        FCB     8                                 ;GET ADDRESS
        LBNE    ABORT                             ;ERROR, QUIT
        BSR     GETDEV                            ;GET DEVICE
        TFR     X,D                               ;COPY TO D
        BRA     DMPF1                             ;DUMP IT
;* GET DEVICE IF ANY
GETDEV
        PSHS    X
        SWI
        FCB     4                                 ;MORE OPERANDS?
        BEQ     GETD1                             ;NO, EXIT
        SWI
        FCB     6                                 ;GET DEVICE ID
        LBNE    ABORT                             ;ERROR
        BITB    #7                                ;INSURE IN RANGE
        STB     >DEVICE                           ;SET NEW DEVICE
GETD1
        PULS    X,PC
;* DISPLAY MEMORY
MEMREF
        SWI
        FCB     7                                 ;GET ADDRESS
        LBNE    ABORT                             ;GET UPSET IF INVALID
        STX     MEMADR                            ;SAVE MEMORY ADDRESS
        BSR     GETDEV                            ;GET DEVICE
MEMGO
        BSR     DMPRAM                            ;DISPLAY IT
        BRA     MEMGO                             ;CONTINUE
;* DISPLAY A FILE
GETFIL
        SWI
        FCB     10                                ;GET FILENAME
        LBNE    ABORT                             ;ERROR, QUIT
        BSR     GETDEV                            ;GET DEVICE
        SWI
        FCB     70                                ;LOOKUP FOR READ
        LBNE    ABORT                             ;IF NOT THERE, QUIT
        LDD     DDADR,X                           ;GET ADDRESS
DMPF1
        STD     SECTOR                            ;SAVE SECTOR NUMBER
        LDX     #WRKSPC                           ;POINT TO IT
        SWI
        FCB     92                                ;READ A WORK SECTOR
        BSR     DMPRAM                            ;DISPLAY THIS PORTION
        LDD     SECTOR                            ;GET SECTOR NUMBER BACK
        SWI
        FCB     77                                ;GET NEXT SECTOR NUMBER
        BEQ     DMPEND                            ;END OF FILE, QUIT
        CMPD    #0                                ;NO MORE?
        BNE     DMPF1                             ;GET THIS ONE
DMPEND
        CLRA                                      ;	ZERO RETURN CODE
        RTS
;*
;* DUMPS RAM POINTED TO BY X, FOR ONE 1 SECTOR SIZE
;*
DMPRAM
        TST     DUMP                              ;ARE WE DUMPING IN HEX FORMAT
        BEQ     DUMPH                             ;IF SO, DUMP IN HEX
;* DUMP AS ASCII TEXT
        LDY     #512                              ;1 SECTOR
        LDB     LINPOS                            ;GET LINE POSITION
DSPASC1
        LDA     ,X+                               ;GET DATA
        LBMI    XQUIT                             ;END OF FILE
        CMPA    #' '                              ;PRINTABLE CHARACTER?
        BHS     DSPASC4                           ;YES, ITS OK
;* CHECK FOR CARRIAGE RETURN (END OF LINE)
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BNE     DSPASC2                           ;NO, TRY NEXT
        LBSR    CHKPAG                            ;CHECK FOR PAGE STOP
        CLRB                                      ;	ZERO LINE POSITION
        BRA     DSPASC5                           ;AND EXIT
;* CHECK FOR TAB AND SKIP TO TAB STOP
DSPASC2
        CMPA    #TAB                              ;IS IT A TAB?
        BNE     DSPASC5                           ;NO, TRY NEXT
        LDA     #' '                              ;INDICATE SPACE
DSPASC3
        BSR     OUTPUT                            ;WRITE THE SPACE
        INCB                                      ;	ADVANCE COUNT
        BITB    #%00000111	AT NEXT TAB STOP?
        BNE     DSPASC3                           ;NO, KEEP GOING
        BRA     DSPASC5                           ;TEST AGAIN
;* NORMAL CHARACTER TO OUTPUT
DSPASC4
        INCB                                      ;	ADVANCE COUNT
        BSR     OUTPUT                            ;DISPLAY
DSPASC5
        LEAY    -1,Y                              ;BACKUP
        BNE     DSPASC1                           ;CONTINUE LOOKING
        STB     LINPOS                            ;RESAVE POSITION
        RTS
;*
;* DUMP IN HEX
;*
DUMPH
        LDY     #32                               ;32 LINES/SECTOR
DMP0
        LDD     MEMADR                            ;GET MEMORY ADDRESS
        BSR     HEXOUT                            ;DISPLAY IT
        TFR     B,A                               ;GET LOW ADDRESS
        BSR     HEXOUT                            ;DISPLAY IT
        LDD     MEMADR                            ;GET ADDRESS BACK
        ADDD    #16                               ;ADD 16 BYTES
        STD     MEMADR                            ;RESAVE
        LDB     #16                               ;GET NUMBER BYTES/LINE
        PSHS    B,X                               ;SAVE
DMP1
        LDA     #' '                              ;GET SPACE
        BITB    #$03                              ;AT A FOUR BYTE BOUNDARY?
        BNE     NOT4                              ;NO, SKIP IT
        BSR     OUTPUT                            ;EXTRA SPACE
NOT4
        BSR     OUTPUT                            ;SPACE
        LDA     ,X+                               ;GET CHAR FROM RAM
        BSR     HEXOUT                            ;DISPLAY IT
        DECB                                      ;	REDUCE COUNT
        BNE     DMP1                              ;CONTINUE
        LDA     #' '                              ;SPACE
        BSR     OUTPUT                            ;DISPLAY
        BSR     OUTPUT                            ;DISPLAY
        BSR     OUTPUT                            ;DISPLAY
        BSR     OUTPUT                            ;DISPLAY
        PULS    B,X                               ;RESTORE REGS
DMP2
        LDA     ,X+                               ;GET CHAR
        CMPA    #' '                              ;< SPACE
        BLO     UPRT                              ;NOT PRINTABLE
        CMPA    #$7F                              ;DELETE?
        BLO     PRTOK                             ;OK TO DISPLAY
UPRT
        LDA     #'.'                              ;CONVERT TO DOT
PRTOK
        BSR     OUTPUT                            ;DISPLAY
        DECB                                      ;	REDUCE COUNT
        BNE     DMP2                              ;CONTINUE
        BSR     CHKPAG                            ;NEWLINE & CHECK PAGE
        LEAY    -1,Y                              ;BACKUP A LINE
        BNE     DMP0                              ;CONTINUE
EPAGE
        RTS
;* OUTPUT CONTENTS OF ACCA IN HEX
HEXOUT
        PSHS    A                                 ;SAVE IT
        RORA
        RORA
        RORA
        RORA                                      ;	SHIFT UPPER NIBBLE INTO LOWER
        BSR     HOUT                              ;DISPLAY NIBBLE
        PULS    A                                 ;RESTORE A
HOUT
        ANDA    #$0F                              ;MASK OFF CRAP
        ADDA    #'0'                              ;CONVERT TO ASCII
        CMPA    #'9'                              ;OVER NUMERIC?
        BLS     OUTPUT                            ;OK TO DISPLAY
        ADDA    #$7                               ;CONVERT TO ALPHA
;* OUTPUT ROUTINE
OUTPUT
        PSHS    B                                 ;SAVE REGS
        LDB     >DEVICE
        SWI
        FCB     36                                ;OUTPUT TO DEVICE
        PULS    B,PC                              ;RESTORE REGS
;* CHECK FOR PAGE END OR <ESCAPE> ABORT COMMAND
CHKPAG
        LDA     #$0A                              ;LINE-FEED
        BSR     OUTPUT                            ;WRITE IT OUT
        LDA     #$0D                              ;CARRIAGE RETURN
        BSR     OUTPUT                            ;WRITE IT OUT
        LDA     PAGE                              ;ARE WE PAGEING
        BNE     CHKP1                             ;DON'T PAGE IT
        DEC     PAGPOS                            ;TEST FOR PAGE UNDERFLOW
        BNE     CHKP1                             ;NO PAGE YET
        LDA     #PAGSIZ                           ;RESTORE PAGE SIZE
        STA     PAGPOS                            ;SAVE PAGE POSITION
        SWI
        FCB     34                                ;WAIT FOR A KEY
        BRA     CHKP2                             ;AND CONTINUE
CHKP1
        SWI
        FCB     35                                ;IS THERE A CHARACTER
CHKP2
        CMPA    #ESCCHR                           ;IS IT AN ESCAPE?
        BNE     EPAGE                             ;NO, SKIP IT
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     '<Aborted>'
;* EXIT WITH ZERO RETURN CODE
XQUIT
        CLRA                                      ;	ZERO RC
ABORT
        LDS     SAVSTK                            ;GET STACK POINTER BACK
        TSTA                                      ;	SET FLAGS FOR RETURN CODE
        RTS
;* QUALIFIER TABLE
QTABLE
        FCB     $82
        FCC     '/PAGE'
        FCB     $82
        FCC     '/DUMP'
        FCB     $82
        FCC     '/DISK'
        FCB     $82
        FCC     '/MEMORY'
        FCB     $80                               ;END OF TABLE
QMAX            = 4                               ;LARGEST QUALIFIER VALUE
;* QUALIFIER FLAGS
QFLAGS          = *
PAGE
        FCB     $FF                               ;PAGE OUTPUT
DUMP
        FCB     $FF                               ;DUMP IN HEX FORMAT
DISK
        FCB     $FF                               ;DISPLAY FROM DISK
MEMORY
        FCB     $FF                               ;DISPLAY MEMORY
;*
LINPOS
        FCB     0                                 ;POSITION IN LINE
PAGPOS
        FCB     PAGSIZ                            ;POSITION IN PAGE
DEVICE
        RMB     1                                 ;OUTPUT DEVICE NUMBER
MEMADR
        RMB     2                                 ;MEMORY ADDRESS
SECTOR
        RMB     2                                 ;CURRENT SECTOR
SAVSTK
        RMB     2                                 ;SAVED STACK POINTER
;*
WRKSPC          = *                               ;WORK AREA
