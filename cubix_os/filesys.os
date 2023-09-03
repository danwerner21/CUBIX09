;*
;* CUBIX File System management routines
;*
;* LOCATE NEXT WORK SECTOR IN CHAIN
;*
FNDLNK
        PSHS    A
        LSLB                                      ;DOUBLE FOR
        ROLA                                      ;TWO BYTE ID'S
        ANDA    #$01                              ;MASK OFF BITS (512/SECTOR)
        ADDD    #WRKSPC                           ;POINT TO WORKSPACE
        TFR     D,X                               ;SET UP POINTER
        PULS    B                                 ;RESTORE HIGH ID
        ADDB    #LNKSEC                           ;ADVANCE TO LINK SECTOR
        CLRA                                      ;ZERO HIGH
        PSHS    X                                 ;SAVE PTR
        BSR     RDWRK                             ;READ WORK SECTOR
        PULS    X                                 ;RESTORE
        LDD     ,X                                ;GET DATA
        CMPD    #$FFFF                            ;END OF FILE?
GRTS
        RTS
;*
;* READ WORK SECTOR FROM DISK
;*
RDWRK
        PSHS    A                                 ;SAVE ACCA
        LDX     #WRKSPC                           ;POINT TO IT
        LDA     >SDRIVE                           ;CURRENT DRIVE
        CMPA    >WRKDRV                           ;ARE WE ON IT?
        BNE     RDW1                              ;WRITE IT CHANGED
        LDA     ,S                                ;RESTORE SECTOR ID
        CMPD    >WRKSEC                           ;DO WE ALREADY HAVE IT?
        BEQ     RRTS                              ;YES, ITS OK
RDW1
        BSR     WRTST                             ;WRITE IF NESSARY
        LDA     >SDRIVE                           ;GET DRIVE
        STA     >WRKDRV                           ;SET WORK DRIVE
        LDA     ,S                                ;RESTORE SECTOR ID
        STD     >WRKSEC                           ;SET IT UP
        JSR     RDISK                             ;READ DISK
RRTS
        PULS    A,PC
;*
;* PURGE OPEN WORK SECTOR, INSURE IT GETS WRITTEN. SET
;* SAVED SECTOR TO $FFFF, SO WE FORCE NEW READ
;*
PURGE
        BSR     WRTST                             ;WRITE IF NESSARY
PURGE1
        PSHS    A,B                               ;SAVE REGISTERS
        LDD     #$FFFF                            ;GET NON-EXISTANT
        STD     >WRKSEC                           ;SET WORK SECTOR
        STA     >WRKDRV                           ;SET WORK DRIVE
        CLRA    SET 'Z'
        PULS    A,B,PC
;*
;* WRITE WORK SECTOR IF IT HAS BEEN CHANGED
;*
WRTST
        TST     >WRKCHG                           ;HAS IT CHANGED?
        BEQ     GRTS                              ;NO, SKIP IT
;*
;* WRITE WORK SECTOR BACK TO DISK
;*
WRWRK
        PSHS    A,B,X                             ;SAVE REGS
        LDA     >SDRIVE                           ;GET SELECTED DRIVE
        PSHS    A                                 ;SAVE IT
        LDA     >WRKDRV                           ;GET WORK DRIVE
        STA     >SDRIVE                           ;SET IT UP
        LDD     >WRKSEC                           ;GET ID
        LDX     #WRKSPC                           ;POINT TO WORKSPACE
        JSR     WDISK                             ;WRITE IT
        CLR     >WRKCHG                           ;INDICTE FRESH
        PULS    A                                 ;RESTORE DRIVE
        STA     >SDRIVE                           ;RESAVE
        CLRA                                      ;ZERO RETURN
        PULS    A,B,X,PC
;*
;* LOCATE  FILE, ISSUE ERROR MESSAGE IF NOT FOUND
;*
LOCERR

        BSR     LOCDIR                            ;LOOK IT UP
        BEQ     FILFND                            ;FINE, RETURN

;* ATTEMPT TO OPEN FILE FAILED, NOT FOUND
NOTFND
        LDY     #NOTMSG                           ;INDICATE NOT FOUND
        LDA     #RCNOTF                           ;NOT FOUND RC
;* PROCESS FOR FILE RELATED ERRORS
FILERR
        PSHS    A,CC                              ;SAVE A & CC
        TST     >MSGFLG                           ;MESSAGES ENABLED
        BEQ     NOFMSG                            ;NO, SKIP IT
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     'Error processing file: '
        FCB     $00
        JSR     SHOSAV                            ;DISPLAY IT
        JSR     LFCR
NOFMSG
        TFR     Y,X                               ;COPY IT
        PULS    A,CC                              ;RESTORE CONDITIONS
        JMP     ERRMRC                            ;OUTPUT MESSAGE
;*
;* LOCATE A FILE IN THE DIRECTORY, LEAVES 'X' POINTING AT IT
;*
LOCDIR
        LDA     >FDRIVE                           ;GET FILES DRIVE ID
        STA     >SDRIVE                           ;SAVE IT
        LDD     #DIRSEC                           ;STARTING SECTOR OF DIR
LOCSEC
        JSR     RDWRK                             ;READ IT
LOCFIL

        JSR     COMNAM                            ;DOES IT MATCH
        BEQ     FILFND                            ;YES
        LEAX    32,X                              ;ADVANCE TO NEXT
        CMPX    #WRKSPC+512                       ;OVER?
        BLO     LOCFIL                            ;KEEP LOOKING
        LDD     >WRKSEC                           ;GET SECTOR
        JSR     FNDLNK                            ;GET ITS LINK
        BNE     LOCSEC                            ;MORE TO FIND
        LDA     #RCNOTF                           ;FILE NOT FOUND
FILFND
        RTS
;*
;* DISPLAY DIRECTORY USING SAVED FILENAME AS A MASK
;*
DISDIR
        BSR     LOCERR                            ;LOCATE FILE
SHOME
        BSR     SHONAM                            ;OUTPUT NAME
        JSR     LFCR                              ;NEW LINE
NOSHO
        LEAX    32,X                              ;NEXT ENTRY
        CMPX    #WRKSPC+512                       ;OVER?
        BLO     SHOFIL                            ;MORE TO GO
        LDD     >WRKSEC                           ;GET WORKSECTOR
        JSR     FNDLNK                            ;LOCATE LINK
        BEQ     FILFND                            ;NO, QUIT
        JSR     RDWRK                             ;READ NEW SECTOR
SHOFIL
        JSR     COMNAM                            ;DOES IT MATCH?
        BNE     NOSHO                             ;DON'T OUTPUT
        BRA     SHOME                             ;DISPLAY IT

;*
;* SHOW SAVED FILENAME
;*
SHOSAV
        PSHS    A,B,X                             ;SAVE REGS
        LDX     #FDRIVE                           ;POINT TO IT
        LDA     ,X+                               ;GET DRIVE ID
        ADDA    #'A'                              ;OFFSET
        JSR     PUTCHR
        LDA     #':'
        JSR     PUTCHR
        BRA     SHON1                             ;DISPLAY IT
;*
;* DISPLAYS FILENAME(X) IN DIRECTORY FORMAT
;*
SHONAM
        PSHS    A,B,X                             ;SAVE REGISTERS
SHON1
        LDA     #'['                              ;OPENING BRACKET
        JSR     PUTCHR                            ;OUTPUT
        BSR     DISP8                             ;DISPLAY IT
        LDA     #']'                              ;CLOSING BRACKET
        JSR     PUTCHR                            ;OUTPUT
        BSR     DISP8                             ;DISPLAY NAME
        LDA     #'.'
        JSR     PUTCHR
        LDB     #3                                ;TYPE IS THREE
        BSR     DISPX
        PULS    A,B,X,PC
DISP8
        LDB     #8                                ;8 CHARS FOR PREFIX AND TYPE
DISPX
        LDA     ,X+                               ;GET CHAR
        BEQ     SHRT                              ;SHORT, ADVANCE
        JSR     PUTCHR                            ;DISPLAY
SHRT
        DECB                                      ;REDUCE COUNT
        BNE     DISPX                             ;KEEP GOING
        RTS
;*
;* CALCULATE DRIVE SIZE IN 'D'
;*
CURSIZ
        LDA     >SDRIVE                           ;GET SELECTED DRIVE
DRVSIZ
        PSHS    U
        JSR     GETCTL1                           ;GET CONTROL BLOCK
        LDB     NSEC,U                            ;GET # SECS/TRACK
        LDA     NHEAD,U                           ;GET # HEADS
        MUL                                       ;GET SECS/CYLINDER
        LDA     NCYL,U                            ;GET # CYLINDERS
        MUL                                       ;CALCULATE TOTAL SIZE
        PULS    U,PC                              ;RETURN
;*
;* CREATES A FILE
;*
CREATE
        JSR     VALID                             ;OK AS SINGLE FLE
        LBNE    BADOPR                            ;NO, INVALID
        JSR     LOCDIR                            ;LOOK FOR IT
        BNE     CRE1                              ;ITS OK
;* FILE ALREADY EXISTS
FEXISTS
        LDY     #EXIMSG                           ;FILE EXISTS
        LDA     #RCEXI                            ;EXISTS
        JMP     FILERR                            ;INDICATE ERROR
CRE1
        BSR     FRESEC                            ;ALLOCATE A SECTOR
        STD     >TEMP1                            ;SAVE IT
        LDD     #DIRSEC                           ;DIRECTORY STARTS HERE
CRE2
        JSR     RDWRK                             ;READ WORK SECTOR
        LDB     #16                               ;ENTRIES/SECTOR
CRE3
        TST     ,X                                ;IS IT FREE?
        BEQ     CRE6                              ;YES, PUT IT HERE
        LEAX    32,X                              ;ADVANCE TO NEXT
        DECB                                      ;REDUCE COUNT
        BNE     CRE3                              ;KEEP LOOKING
        LDD     >WRKSEC                           ;GET DIRECTORY SEC ID
        JSR     FNDLNK                            ;FIND LINK
        BNE     CRE2                              ;AND KEEP GOING
        LDD     >TEMP1                            ;GET OUR FREE SECTOR
        STD     ,X                                ;POINT DIRECTORY AT IT
        JSR     CHGWRK                            ;INDICATE WE CHANGED
        PSHS    A,B                               ;SAVE ID
        BSR     FRESEC                            ;GET FREE
        STD     >TEMP1                            ;SAVE NEW FREE
        JSR     WRWRK                             ;WRITE WORK SECTOR
        PULS    A,B                               ;RESTORE DIRECTORY SECTOR ID
        STD     >WRKSEC                           ;INDICATE CURRENT WORKSECTOR
        LDX     #WRKSPC                           ;PT TO IT
CRE5
        CLR     ,X+                               ;CLEAR IT
        CMPX    #WRKSPC+512                       ;ARE WE OVER
        BLO     CRE5                              ;DO ALL
        LDX     #WRKSPC                           ;PT TO IT AGAIN
CRE6
        PSHS    Y                                 ;SAVE
        LDY     #PREFIX                           ;PT TO SAVED NAME
        LDB     #19                               ;19 CHARS IN NAME
CRE7
        LDA     ,Y+                               ;GET CHAR
        STA     ,X+                               ;SAVE IN ENTRY
        DECB                                      ;REDUCE COUNT
        BNE     CRE7                              ;CONTINUE
        PULS    Y                                 ;RESTORE
        LEAX    -19,X                             ;BACK TO START
        LDD     >TEMP4                            ;GET LOAD ADDRESS
        STD     DRADR,X                           ;SET IT,
        LDA     #DEFATR                           ;GET DEF ATTRIBUTES
        STA     DATTR,X                           ;SET THEM
        LDD     >TEMP1                            ;GET DISK ADDRESS
        STD     DDADR,X                           ;SET IT
;*
;* SET WORK SECTOR CHANGED FLAG
;*
CHGWRK
        CLR     >WRKCHG
        DEC     >WRKCHG                           ;SET IT
        ORCC    #4                                ;SET 'Z'
        RTS
;*
;* LOCATE A FREE SECTOR ON THE DISK, CLAIM IT AND SET
;* FLAG TO $FFFF (END OF FILE). ATEMPT TO ALLOCATE IN SECTOR
;* WHICH AS ALREADY LOADED IN ORDER TO REDUCE DISK I/O.
;*
FRESEC
        JSR     CURSIZ                            ;CALCULATE SIZE OF DISK
        STD     >TEMP                             ;SAVE IT
        SUBD    #1                                ;CONVERT TO HIGHEST SECTOR ID
        ADDA    #LNKSEC                           ;COMPUTE LARGEST LINK SECTOR # (D/256+LNK)
        PSHS    A                                 ;SAVE
        TST     >WRKSEC                           ;LOW?
        BNE     FRES1                             ;NO LINK IN CORE
        LDB     >WRKSEC+1                         ;GET SECTOR ID
        CMPA    >WRKSEC+1                         ;IS IT IN RANGE?
        BLO     FRES1                             ;NO LINK IN CORE
        CMPB    #LNKSEC                           ;IN RANGE?
        BLO     FRES1                             ;NO LINK IN CORE
        BSR     FNDFRE                            ;LOOK FOR IT
FRES1
        LDB     #LNKSEC                           ;LOOK IN FIRST
FRES2
        BSR     FNDFRE                            ;LOOK FOR IT
        INCB    ADVANCE
        CMPB    ,S                                ;ARE WE OVER?
        BLS     FRES2                             ;NO, LEEP GOING
;* NO DISK SPACE AVAILABLE
NOSPAC
        LDX     #NOSMSG                           ;NO SPACE
        LDA     #RCNOS                            ;RETURN CODE
        JMP     ERRMRC                            ;REPORT ERROR
;* LOOK FOR FREE SECTOR
FNDFRE
        CLRA                                      ;HIGH ADDRESS TO ZERO
        PSHS    B,X,Y                             ;SAVE REGS
        JSR     RDWRK                             ;READ WORK SECTOR
FNDF1
        LDD     ,X++                              ;IS IT FREE
        BEQ     FNDF3                             ;YES
        CMPX    #WRKSPC+512                       ;OVER?
        BLO     FNDF1                             ;NO, KEEP LOOKING
FNDF2
        PULS    B,X,Y,PC                          ;GO HOME
FNDF3
        TFR     X,D                               ;GET VALUE
        SUBD    #WRKSPC+2                         ;CONVERT TO BYTE OFFSET
        LSRA                                      ;CONVERT ADDRESS IN WS
        RORB                                      ;TO SECTOR # IN WS
        LDA     ,S                                ;GET SECTOR ID BACK
        SUBA    #LNKSEC                           ;CONVERT TO PURE SECTOR #
        CMPD    >TEMP                             ;WITHIN DISK SIZE?
        BHS     FNDF2                             ;NO, RETURN WITH BAD NEWS
        LEAS    1,S                               ;SKIP SAVED 'B' REGISTER
        LDY     #$FFFF                            ;GET SECTOR IN USE FLAG
        STY     -2,X                              ;WRITE IT
        PULS    X,Y                               ;RESTORE REGS
        LEAS    3,S                               ;CLEAR UP STACK
        BRA     CHGWRK                            ;INDICATE CHANGED
;*
;* OPEN A FILE FOR READ
;*
OPENR
        PSHS    B,X                               ;SAVE REGS
        JSR     LOCRED                            ;DOES IT EXIST
        LDD     DDADR,X                           ;GET DISK ADDRESS
        STD     OFIRST,U                          ;SAVE IT
        STD     OSECTOR,U                         ;INDICATE CURRENT SECTOR
        CLRA
        CLRB                                      ;ZERO OFFSET
        STD     OOFFSET,U                         ;INDICATE OFFSET INTO FILE
        STD     OLSTSEC,U                         ;INDICATE THIS IS FIRST
        LDB     >FDRIVE                           ;GET FILE DRIVE
        LDA     #1                                ;INDICATE FILE OPEN/READ
        STD     OTYPE,U                           ;INDICATE
        LDA     >SAVDRV                           ;GET PREVIOUS DRIVE
        STA     >SDRIVE                           ;RESET IT
        CLRA                                      ;ZERO RC
        PULS    B,X,PC
;*
;* READ CHARACTER FROM FILE
;*
READC
        PSHS    B,X                               ;SAVE REGS
        LEAX    OSIZ,U                            ;OFFSET TO DATA
        LDA     ODRIVE,U                          ;GET DRIVE
        STA     >SDRIVE                           ;SELECT
        LDD     OOFFSET,U                         ;GET OFFSET
        BNE     REC1                              ;NON-ZERO, ITS OK
        LDA     OTYPE,U                           ;GET OPEN TYPE
        DECA                                      ;OPEN FOR READ?
        BNE     ORERR                             ;NO, REPORT ERROR
        LDD     OSECTOR,U                         ;GET SECTOR
        CMPD    #$FFFF                            ;END OF FILE?
        BEQ     EOF                               ;YES, REPORT ERROR
        JSR     RDISK                             ;READ IT IN
        LDD     OOFFSET,U                         ;RESTORE OFFSET
REC1
        LEAX    D,X                               ;OFFSET TO CHAR
        ADDD    #1                                ;ADVANCE
        CMPD    #512                              ;ARE WE OVER
        BLO     REC2                              ;NO, ITS OK
        PSHS    X                                 ;SAVE 'X'
        LDD     OSECTOR,U                         ;GET SECTOR
        STD     OLSTSEC,U                         ;SAVE LAST SECTOR
        JSR     FNDLNK                            ;LOOK UP ITS LINK
        STD     OSECTOR,U                         ;SAVE NEW SECTOR
        PULS    X                                 ;RESTORE PTR TO CAHR
        CLRA
        CLRB
REC2
        STD     OOFFSET,U                         ;NEW OFFSET
        LDA     >SAVDRV                           ;GET PREVIOUS DRIVE
        STA     >SDRIVE                           ;RESET IT
        LDA     ,X+                               ;GET CHARACTER
        CMPA    #$FF                              ;END OF FILE?
        BEQ     EOF                               ;YES
        ORCC    #4                                ;INDICATE SUCESS
        PULS    B,X,PC
;*
;* READ A BLOCK FROM A FILE
;*
READB
        PSHS    B,X                               ;SAVE REGS
        LDA     OTYPE,U                           ;GET OPEN TYPE
        DECA                                      ;OPEN READ?
        BNE     ORERR                             ;NO, REPORT ERROR
        LDA     ODRIVE,U
        STA     >SDRIVE                           ;SET DRIVE
        LDD     OSECTOR,U
        CMPD    #$FFFF                            ;END OF FILE?
        BEQ     EOF
        STD     OLSTSEC,U                         ;SAVE LAST
        JSR     RDISK                             ;READ IT
        JSR     FNDLNK                            ;FIND ITS LINK
        STD     OSECTOR,U                         ;RESAVE
        LDA     >SAVDRV                           ;GET PREVIOUS DRIVE
        STA     >SDRIVE                           ;RESET SYSTEM DRIVE
        CLRA
        CLRB
        STD     OOFFSET,U                         ;CLEAR OFFSET
        PULS    B,X,PC
;*
;* LOOK UP FILE WITH INTENT TO READ
;*
LOCRED
        JSR     LOCERR                            ;FIND IT
        LDA     DATTR,X                           ;GET ATTRS
        BITA    #RPERM                            ;CAN WE READ?
        BNE     CLOC2                             ;YES, ITS OK
;* FILE PROTECTON VIOLATION
PROERR
        LDY     #PROMSG                           ;MESSAGE
        LDA     #RCPRO                            ;PROTECTION VIOLATION
        JMP     FILERR                            ;FILE ERROR
;* ATTEMPT TO READ FILE NOT OPEN FOR READ
ORERR
        LDX     #OREMSG
        LDA     #RCORE
        JMP     ERRMRC
;* ATTEMPT TO READ PAST EOF
EOF
        LDA     #RCEOF
        JMP     ERRRET
;*
;* REWIND A FILE
;*
REWIND
        PSHS    A,B                               ;SAVE REGS
        LDD     OFIRST,U                          ;GET FIRST SECTOR ID
        STD     OSECTOR,U                         ;POINT TO IT
        CLRA
        CLRB
        STD     OOFFSET,U                         ;SET OFFSET
        STD     OLSTSEC,U                         ;INDICATE THIS IS FIRST
        PULS    A,B,PC
;*
;* LOOKUP A FILE WITH INTENT TO WRITE
;*
LOCWRI
        JSR     LOCDIR                            ;LOOK FOR IT
        BEQ     CLOC1                             ;IT EXISTS
        JSR     CREATE                            ;CREATE IT
        BRA     CLOC2                             ;AND RETURN
CLOC1
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #WPERM                            ;CAN WE WRITE?
        BEQ     PROERR                            ;PROTECTON VIOLATION
CLOC2
        LDD     >WRKSEC                           ;GET DIRECTORY SECT
        ORCC    #$04                              ;SET 'Z'
        RTS
;*
;* OPEN A FILE FOR WRITE
;*
OPENW
        PSHS    B,X                               ;SAVE REGS
        BSR     LOCWRI                            ;DOES IT EXIST
        LDD     DDADR,X                           ;GET DISK ADDRESS
        STD     OFIRST,U                          ;SAVE IT
        STD     OSECTOR,U                         ;INDICATE CURRENT SECTOR
        CLRA
        CLRB                                      ;ZERO OFFSET
        STD     OOFFSET,U                         ;INDICATE OFFSET INTO FILE
        STD     OLSTSEC,U                         ;INDICATE THIS IS FIRST SECTOR
        LDA     >FDRIVE                           ;GET FILE DRIVE
        STA     ODRIVE,U                          ;SET IT UP
        LDA     #2                                ;INDICATE FILE OPEN/WRITE
        STA     OTYPE,U                           ;INDICATE
        LDA     >SAVDRV
        STA     >SDRIVE
        CLRA    ZERO RC
        PULS    B,X,PC
;*
;* WRITE CHARACTER TO A FILE
;*
WRITEC
        PSHS    A,B,X                             ;SAVE REGS
        LEAX    OSIZ,U                            ;POINT TO DATA
        LDD     OOFFSET,U                         ;GET OFFSET
        CMPD    #512                              ;ARE WE OVER?
        BLO     WRC1                              ;NO, ITS OK
        BSR     WRITEB                            ;OUTPUT THE BLOCK
        LDD     OOFFSET,U                         ;GET OFFSET
WRC1
        LEAX    D,X                               ;POINT TO CHAR
        ADDD    #1                                ;INCREMENT
        STD     OOFFSET,U                         ;RESAVE
        LDA     ,S                                ;GET CHAR BACK
        STA     ,X                                ;WRITE IN BUFFER
        ORCC    #4                                ;INDICATE SUCESS
        PULS    A,B,X,PC
;* ATTEMPT TO WRITE FILE NOT OPEN FOR WRITE
OWERR
        LDX     #OWEMSG
        LDA     #RCOWE
        JMP     ERRMRC
;*
;* WRITE A BLOCK TO A FILE
;*
WRITEB
        PSHS    B,X                               ;SAVE REGS
        LDA     OTYPE,U                           ;GET TYPE
        CMPA    #2                                ;WRITE?
        BNE     OWERR                             ;NO, INVALID
        LDA     ODRIVE,U                          ;GET DRIVE
        STA     >SDRIVE                           ;SELECT DRIVE
        LDD     OSECTOR,U                         ;GET SECTOR
        CMPD    #$FFFF                            ;ARE WE PAST END?
        BNE     WRB1                              ;NO, ITS OK
        JSR     FRESEC                            ;GET A SECTOR
        PSHS    A,B                               ;SAVE IT
        LDD     OLSTSEC,U                         ;GET LAST SECTOR
        JSR     FNDLNK                            ;GET ITS LINK
        PULS    A,B                               ;RESTORE
        STD     ,X                                ;SAVE IT
        JSR     CHGWRK                            ;INDICATE SECTOR CHANGED
        LDX     1,S                               ;RESTORE MEMORY POINTER
WRB1
        STD     OLSTSEC,U                         ;SAVE LAST SECTOR
        JSR     WDISK                             ;WRITE THE SECTOR
        JSR     FNDLNK                            ;LOCATE LINK
        STD     OSECTOR,U                         ;SAVE ID OF NEXT SECTOR
        LDA     >SAVDRV                           ;GET PREVIOUS DRIVE
        STA     >SDRIVE                           ;RESET DRIVE ID
        CLRA
        CLRB
        STD     OOFFSET,U                         ;INDICATE NO CHAR WRITE
        PULS    B,X,PC
;*
;* CLOSE OPEN FILE
;*
CLOSE
        PSHS    B,X                               ;SAVE REGS
        LDA     OTYPE,U                           ;GET TYPE
        CMPA    #2                                ;OPEN FOR WRITE?
        BNE     CLO4                              ;NO, SKIP IT
;* UPDATE LAST SECTOR IF ANY DATA, OR FIRST IN FILE
        LDA     ODRIVE,U                          ;GET DRIVE ID
        STA     >SDRIVE                           ;SELECT IT
        LDD     OOFFSET,U                         ;DATA IN LAST SECT?
        BNE     CLO0                              ;YES, WRITE IT
        LDX     OLSTSEC,U                         ;GET SECTOR
        BNE     CLO3                              ;IS A LAST, OK
;* CLEAR REMAINING SECTOR TO ZERO
CLO0
        LEAX    OSIZ,U                            ;PT TO AREA
        LEAX    D,X                               ;ADVANCE TO DATA AREA
CLO1
        CMPD    #512                              ;ARE WE OVER?
        BHS     CLO2                              ;YES, STOP
        CLR     ,X                                ;SET TO ZERO
        COM     ,X+                               ;& CONVERT TO FF
        ADDD    #1                                ;ADVANCE
        BRA     CLO1                              ;AND CONTINUE
;* WRITE IT TO THE DISK
CLO2
        LEAX    OSIZ,U                            ;OFFSET AGAIN
        BSR     WRITEB                            ;WRITE IT
;* MARK LAST SECTOR WRITTEN AS EOF
CLO3
        LDD     OLSTSEC,U                         ;ITS NOW LAST ONE
        JSR     FNDLNK                            ;GET ITS LINK
        LDD     #$FFFF                            ;EOF MARKER
        STD     ,X                                ;WRITE IT
;* IF NOT LAST SECTOR IN FILE, RELEASE REST
        LDD     OSECTOR,U                         ;GET SECTOR
        CMPD    #$FFFF                            ;LAST ONE IN FILE?
        BEQ     CLO4                              ;IS OK
        JSR     UNCHAIN                           ;REMOVE SECTOR LINKS
CLO4
        CLR     OTYPE,U                           ;INDICATE FILE IS CLOSED
        LDA     >SAVDRV                           ;RESET DRIVE
        STA     >SDRIVE
        CLRA
        PULS    B,X,PC                            ;GO HOME
;*
;* SEEK ABSOLUTE FROM START OF FILE
;*
SEEKABS
        JSR     REWIND                            ;BACK TO START
;*
;* SEEK FORWARD RELATIVE
;*
SEEKREL
        PSHS    A,B,X                             ;SAVE SECTOR ID
        LDB     OTYPE,U                           ;GET TYPE
        DECB                                      ;OPEN FOR READ?
        LBNE    ORERR                             ;NO, REPORT ERROR
        LDA     ODRIVE,U                          ;GET DRIVE
        STA     >SDRIVE                           ;SELECT IT
        LDD     OOFFSET,U                         ;GET OFFSET?
        ADDD    ,S                                ;ADD OFFSET
;* ADVANCE TILL WE ARE ON CORRECT SECTOR
SEEK1
        CMPD    #512                              ;ARE WE OVER?
        BLO     SEEK2                             ;NO, SET OFFSET & EXIT
        PSHS    A,B                               ;SAVE ID
        LDD     OSECTOR,U                         ;GET NEXT SECTOR
        CMPD    #$FFFF                            ;END OF FILE?
        LBEQ    EOF                               ;ERROR
        STD     OLSTSEC,U                         ;SET AS OLD
        JSR     FNDLNK                            ;LOOKUP LINK
        STD     OSECTOR,U                         ;SAVE PTR TO NEXT
        PULS    A,B                               ;RESTORE IT
        SUBD    #512                              ;INDICATE WE ADVANCED
        BRA     SEEK1                             ;CONTINUE
;* SKIPPED SECTORS, IF NON-ZERO OFFSET, READ IN DATA
SEEK2
        STD     OOFFSET,U                         ;SET OFFSET
        BEQ     SEEK3                             ;ZERO, DON'T READ DATA
        LDD     OSECTOR,U                         ;GET SECTOR
        CMPD    #$FFFF                            ;EOF?
        LBEQ    EOF                               ;YES, ERROR
        LEAX    OSIZ,U                            ;ADVANCE TO DATA
        JSR     RDISK                             ;READ A BLOCK
SEEK3
        LDA     >SAVDRV                           ;GET DRIVE
        STA     >SDRIVE                           ;SET IT
        CLRA    ZERO RC
        PULS    A,B,X,PC                          ;BACK TO END
;*
;* REPORT POSITION IN FILE
;*
FTELL
        PSHS    X,Y                               ;SAVE REGS
        LDA     ODRIVE,U                          ;GET DRIVE
        STA     >SDRIVE                           ;SELECT IT
        LDY     #0                                ;START AT POSITION ZERO
        LDD     OFIRST,U                          ;GET ID OF FIRST
FTEL1
        CMPD    OSECTOR,U                         ;ARE WE THERE?
        BEQ     FTEL2                             ;YES
        LEAY    512,Y                             ;ADVANCE 1 SECTOR SIZE
        JSR     FNDLNK                            ;LOCATE LINK
        BNE     FTEL1                             ;TRY THIS ONE
FTEL2
        LDD     OOFFSET,U                         ;GET OFFSET
        PSHS    Y                                 ;SAVE 'Y'
        ADDD    ,S++                              ;INCLUDE IN RESULT
        PSHS    A
        LDA     >SAVDRV                           ;GET DRIVE
        STA     >SDRIVE
        CLRA    'Z' RC
        PULS    A,X,Y,PC
;*
;* SUSPEND FILE OPERATION
;*
SUSPEND
        PULS    A,B                               ;GET PC FROM STACK
        STD     >TEMP4                            ;SAVE RETURN ADDRESS
        LDD     OLSTSEC,U                         ;GET LAST SECTOR
        LDX     OOFFSET,U                         ;GET OFFSET
        LDY     OFIRST,U                          ;GET FIRST SECT
        PSHS    A,B,X,Y                           ;SAVE IT
        LDD     OTYPE,U                           ;GET TYPE&DRIVE
        PSHS    A,B                               ;SAVE IT
        CMPA    #2                                ;WUZ IT WRITE?
        BNE     SUSP2                             ;DON'T SAVE
        CMPX    #0                                ;ZERO OFFSET

        BEQ     SUSP2                             ;DON'T SAVE
;* CHARACTER WRITE, WITH NON-ZERO OFFSET
        LDA     ODRIVE,U                          ;GET DRIVE
        STA     >SDRIVE                           ;SELECT IT
        LDD     OSECTOR,U                         ;GET SECTOR
        CMPD    #$FFFF                            ;OK TO WRITE?
        BNE     SUSP1                             ;ITS OK
        JSR     FRESEC                            ;GRAB A SECTOR
        PSHS    A,B                               ;SAVE ID
        LDD     OLSTSEC,U                         ;GET LAST
        JSR     FNDLNK                            ;GET ITS LINK
        PULS    A,B                               ;RESTORE ID OF FREE
        STD     ,X                                ;SET IT
        STD     OSECTOR,U                         ;SET UP NEW SECTOR
SUSP1
        LEAX    OSIZ,U                            ;SET UP PTR
        JSR     WDISK                             ;OUTPUT SECTOR TO DISK
        LDA     >SAVDRV                           ;GET DRIVE
        STA     >SDRIVE                           ;RESET IT
SUSP2
        LDX     >SAVX                             ;RESTORE X
        LDY     >SAVY                             ;RESTORE Y
        LDB     >SAVB                             ;RESTORE B
        CLRA    ZERO RC
        JMP     [TEMP4]                           ;GOT FOR TI
;*
;* RESUME FILE OPERATION
;*
RESUME
        PULS    A,B                               ;GET PC
        STD     >TEMP4                            ;SAVE RETURN ADDRESS
        PULS    A,B                               ;RESTORE REGS
        STD     OTYPE,U                           ;RESTORE TYPE
        STB     >SDRIVE                           ;SELECT DRIVE
        PULS    A,B,X,Y                           ;RESTORE REST
        STX     OOFFSET,U                         ;SET OFFSET
        STY     OFIRST,U                          ;SET FIRST
;* IF OLSTSEC IS ZERO, NO READ/WRITE TO DISK YET, OSECTOR IS FIRST IN FILE
        STD     OLSTSEC,U                         ;RESET LAST SECTOR
        BNE     RESU1                             ;ITS OK
        STY     OSECTOR,U                         ;SET CURRENT SECTOR
        BRA     RESU2                             ;CONTINUE
;* ELSE OSECTOR IS NEXT AFTER OLSTSEC
RESU1
        JSR     FNDLNK                            ;GET LINK
        STD     OSECTOR,U                         ;SET UP NEXT SECTOR
;* CHECK FOR ACTUAL SECTOR IN MEMORY
RESU2
        LDD     OOFFSET,U                         ;CHAR OPERATIONS?
        BEQ     RESU3                             ;NO, ALL IS OK
;* NON-ZERO OFFSET, SECTOR MUST BE READ INTO RAM
        LDD     OSECTOR,U                         ;GET SECTOR
        LEAX    OSIZ,U                            ;ADVANCE TO BUFFER
        JSR     RDISK                             ;READ IN SECTOR
RESU3
        LDA     >SAVDRV                           ;RESTORE DRIVE
        STA     >SDRIVE                           ;RESET IT
        BRA     SUSP1                             ;RETURN TO CALLER
;*
;* CALCULATE CYLINDER, SECTOR, AND HEAD FROM ABSOLUTE SECTOR NUMBER
;*
SECTOR
        PSHS    A,B,X                             ;SAVE SECTOR ID
        TFR     D,X                               ;SECT ID IN 'X'
        LDA     NSEC,U                            ;GET SECTORS/TRACK
        LDB     NHEAD,U                           ;GET # HEADS
        MUL                                       ;CALCULATE SECTORS/CYLINDER
        JSR     DIV16                             ;X=CYLINDER ID, D=SECTOR IN CYLINDER
        CLR     HEAD,U                            ;ASSUME HEAD 0
SEC1
        CMPB    NSEC,U                            ;WHICH HEAD?
        BLO     SEC2                              ;ASSUMPTION CORRECT
        SUBB    NSEC,U                            ;CONVERT
        INC     HEAD,U                            ;ADVANCE TO NEXT HEAD
        BRA     SEC1                              ;TRY AGAIN
SEC2
        STB     SEC,U                             ;INDICATE SECTOR
        TFR     X,D                               ;GET CYLINDER ID
        STB     CYL,U                             ;SAVE CYLINDER ID
        PULS    A,B,X,PC
;*
;* READ SECTOR BY SECTOR ID(D) TO MEMORY(X)
;*
RDISK
        PSHS    A,B,X,Y,U                         ;SAVE REGISTERS
        CLR     >ERRCNT                           ;ZERO ERROR COUNT
        BSR     GETCTL                            ;SET UP 'U'
RTRY1
        LDD     ,S                                ;GET SECTOR
        BSR     SECTOR                            ;CALCULATE CYLINDER, HEAD & SECTOR
RTRY2
        LDX     2,S                               ;RESTORE 'X'
        JSR     RDSEC                             ;ATTEMPT READ
        BEQ     RDONE                             ;SUCESS, ITS OK
        INC     >ERRCNT                           ;ADVANCE
        LDB     >ERRCNT                           ;GET VALUE
        CMPB    #5                                ;TOO MANY ERRORS?
        BEQ     HDE                               ;YES, SKIP IT
        CMPB    #3                                ;TIME FOR RE-SEEK?
        BNE     RTRY2                             ;NO, DON'T RE-SEEK
        JSR     HOME                              ;RECALIBRATE
        BRA     RTRY1                             ;AND RESEEK
RDONE
        PULS    A,B,X,Y,U,PC
;*
;* GET DRIVE(A) CONTROL BLOCK IN 'D' & 'U'
;*
GETCTL
        LDA     >SDRIVE                           ;GET SELECTED DRIVE
GETCTL1
        LDB     #CSIZE                            ;SIZE OF EACH BLOCK
        MUL                                       ;CALCULATE OFFSET
        ADDD    #DCTRL                            ;OFFSET TO DATA AREA
        TFR     D,U                               ;SET UP U
        RTS
;*
;* WRITE SECTOR BY SECTOR ID(D) TO MEMORY(X)
;*
WDISK
        PSHS    A,B,X,Y,U                         ;SAVE REGISTERS
        CLR     >ERRCNT                           ;ZERO ERROR COUNT
        BSR     GETCTL                            ;SET UP 'U'
WTRY1
        LDD     ,S                                ;GET SECTOR
        BSR     SECTOR                            ;CALCULATE CYLINDER, HEAD & SECTOR
WTRY2
        LDX     2,S                               ;RESTORE 'X'
        JSR     WRSEC                             ;ATTEMPT WRITE
        BEQ     RDONE                             ;SUCCESS, ITS OK
        INC     >ERRCNT                           ;ADVANCE
        LDB     >ERRCNT                           ;GET VALUE
        CMPB    #5                                ;TOO MANY ERRORS?
        BEQ     HDE                               ;YES, SKIP IT
        CMPB    #3                                ;TIME FOR RE-SEEK
        BNE     WTRY2                             ;NO, DON'T RE-SEEK
        JSR     HOME                              ;RECALIBRATE
        BRA     WTRY1                             ;AND RESEEK
;* REPORT DISK ERROR
HDE
        STA     >TEMP                             ;SAVE ERROR CODE
        PULS    A,B,X,Y,U                         ;RESTORE REGS CUZ 'U' NOT SAVED
        CMPD    >WRKSEC                           ;WAS IT WORK SECTOR?
        BNE     HDE1                              ;NO, ITS NOT
        PSHS    A                                 ;SAVE A
        LDA     >SDRIVE                           ;GET CURRENT DRIVE
        CMPA    >WRKDRV                           ;ON WORK DRIVE?
        PULS    A                                 ;RESTORE A
        BNE     HDE1                              ;NOT WORK DRIVE
        JSR     PURGE1                            ;INSURE NO WORK SECTOR IN CORE
        CLR     >WRKCHG                           ;INSURE NO UPDATE RECORDED
HDE1
        JSR     WRLIN                             ;OUTPUT STRING
        FCC     'Error accessing block '
        FCB     $00
        JSR     WRDEC                             ;DISPLAY BLOCK
        JSR     WRLIN                             ;OUTPUT STRING
        FCC     ' on drive: '
        FCB     $00
        LDA     >SDRIVE                           ;GET DRIVE ID
        ADDA    #'A'                              ;OFFSET
        JSR     PUTCHR
        JSR     LFCR                              ;NEW LINE
        LDX     #DETAB                            ;PT TO TABLE
HDE2
        DEC     >TEMP                             ;REDUCE ERROR COUNT
        BEQ     HDE4                              ;THIS IS IT
HDE3
        LDA     ,X+                               ;GET CHAR
        BNE     HDE3                              ;KEEP LOOKING
        LDA     ,X                                ;MORE?
        BNE     HDE2                              ;NO, ERROR
        LEAX    1,X                               ;SKIP MARKER
HDE4
        JSR     WRSTR                             ;OUTPUT STRING
        JSR     LFCR                              ;NEW LINE
        LDA     #RCDSK                            ;INDICATE DISK ERROR
        JMP     ERRRET                            ;RETURN
;* DISK ERROR MESSAGES
DETAB
        FCC     'Disk format error'
        FCB     $00
        FCC     'Bad sector'
        FCB     $00
        FCC     'Sector not found'
        FCB     $00
        FCC     'Disk write protected'
        FCB     $00
        FCB     0                                 ;END OF TABLE
        FCC     'Disk system error'
        FCB     $00
