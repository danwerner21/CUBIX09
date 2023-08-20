;*
;* CUBIX Internal (built in) command handlers
;*
;* FORMAT COMMAND
;*
INIT
        JSR     PURGE                             ;INSURE NO DISK I/O IN PROG
        JSR     GETDRV                            ;GET DRIVE ID
        STA     >SDRIVE                           ;SELECT IT
        JSR     GETCTL                            ;PT 'U' TO CTRL BLOCK
        LDD     #$0203                            ;DEFAULT INTERLEAVE & ALLOCATION
        STD     >TEMP4                            ;SAVE IT
;* GET FORMAT OPERANDS
INI00
        JSR     SKIP                              ;ANY MORE OPERANDS?
        BEQ     INI1                              ;NO, THTS ALL
        LDX     #INITAB                           ;POINT TO TABLE
        JSR     TLOOKE                            ;GET DATA
        PSHS    B                                 ;SAVE ID
        JSR     GETNUM                            ;GET VALUE
        PULS    A                                 ;RESTORE A
        TSTA    INTERLEAVE?
        BNE     INI01                             ;NO
        STB     >TEMP4                            ;SAVE INTERLEAVE
        BRA     INI00                             ;TRY FOR NEXT
INI01
        DECA    DIRECTORY?
        BNE     INI02                             ;NO, USE STANDARD OPTIONS
        STB     >TEMP4+1                          ;SET DIRECTORY ALLOCATION
        BRA     INI00                             ;TRY FOR NEXT
INI02
        DECA    CONVERT
        CMPA    #3                                ;IN RANGE?
        LBHI    BADOPR                            ;NO, REPORT ERROR
        STB     A,U                               ;SET UP DRIVE
        BRA     INI00                             ;TRY FOR NEXT
;* DISPLAY FORMAT
INI1
        JSR     WRLIN
        FCC     'Formatting '
        LDA     >SDRIVE
        JSR     SHODRV                            ;SHOW THE DISK
        LDX     #INITAB                           ;POINT TO TABLE
        CLRA                                      ;DISPLAY INTERLEAVE
        LDB     >TEMP4                            ;GET INTERLEAVE FACTOR
        JSR     SHODRB                            ;DISPLAY IT
        LDA     #1                                ;DISPLAY DIRECTORY EXTENSION
        LDB     >TEMP4+1                          ;GET DIRECTORY EXTENSION
        JSR     SHODRA                            ;DISPLAY IT
        JSR     WRLIN                             ;MESSAGE
        FCB     $0A,$0D                           ;NEW LINE
        FCC     'Ok? '
        JSR     GETCHR
        JSR     PUTCHR                            ;ECHO
        ANDA    #$DF                              ;GET IT
        CMPA    #'Y'
        LBNE    LFCR
        JSR     LFCR                              ;NEW LINE
;* FORMAT PHYSICAL DISK
        LDA     >TEMP4                            ;GET INTERLEAVE FACTOR
        JSR     FORMAT                            ;FORMAT THE DISK
        LDA     >TEMP4+1                          ;GET DIRECTORY ALLOC
        STA     >TEMP4                            ;LOCAL COPY OF DIR ALLOC
;* SET UP DIRECTORY & LINK TABLE ON DISK
        LDX     #WRKSPC                           ;POINT TO IT
INI2
        CLR     ,X+                               ;CLEAR ONE
        CMPX    #WRKSPC+512                       ;ARE WE OVER?
        BLO     INI2                              ;NO, KEEP CLEARING
;* WRITE BASE DIRECTORY SECTOR
        LDX     #WRKSPC                           ;PT BACK TO IT
        LDD     #DIRSEC                           ;DIRECTORY SECTOR
        JSR     WDISK                             ;WRITE DIRECTORY (NO FILES)
;* WRITE NON-BASE LINK SECTORS
        JSR     CURSIZ                            ;GET SIZE OF CURRENT DRIVE
        SUBD    #1                                ;CONVERT TO HIGHEST SECTOR ID
        TFR     A,B                               ;COPY A&B = D/256(ENTRIES/LINKSEC)
        STD     >TEMP3                            ;SAVE FOR LATER
        LDD     #LNKSEC+1                         ;POINT TO LINK SECTOR
INI3
        DEC     >TEMP3+1                          ;REDUCE COUNT
        BMI     INI4                              ;END
        JSR     WDISK                             ;WRITE IT
        ADDD    #1                                ;NEXT SECTOR
        BRA     INI3                              ;KEEP GOING
;* WRITE NON-BASE DIRECTORY SECTORS
INI4
        DEC     >TEMP4                            ;BACKUP
        BMI     INI5                              ;THATS ALL
        JSR     WDISK                             ;WRITE IT
        ADDD    #1                                ;NEXT ONE
        BRA     INI4                              ;DO EM ALL
;* WRITE BASE LINK SECTOR
INI5
        LDD     #$FFFF                            ;END OF CHAIN INDICATOR
        STD     DIRSEC*2,X                        ;SET DIRECTORY FREE
        LEAX    LNKSEC*2,X                        ;OFFSET TO IT
        LDD     #LNKSEC+1                         ;POINT TO LINK SECTOR
INI6
        DEC     >TEMP3                            ;REDUCE COUNT
        BMI     INI7                              ;END
        STD     ,X++                              ;WRITE IT OUT
        ADDD    #1                                ;ADVANCE
        BRA     INI6                              ;DO EM ALL
INI7
        PSHS    A,B                               ;SAVE SECTOR ID
        TST     >TEMP4+1                          ;ANY ADDITIONAL DIR?
        BEQ     INI8                              ;NO
        STD     >2*DIRSEC+WRKSPC                  ;SET IT
INI8
        LDD     #$FFFF                            ;END OF CHAIN INDICATOR
        STD     ,X++                              ;CLOSE OFF LINKS
        PULS    A,B                               ;RESTORE SECTOR ID
INI9
        DEC     >TEMP4+1                          ;REDUCE COUNT
        BMI     INI10                             ;EXIT
        ADDD    #1                                ;NEXT SECTOR
        STD     ,X++                              ;SET LINK FOR DIRECTORY
        BRA     INI9                              ;DO EM ALL
INI10
        LDD     #$FFFF                            ;END OF CHAIN INDICATOR
        STD     -2,X                              ;CLOSE OFF DIRECTORY
        LDX     #WRKSPC                           ;RESET
        LDD     #LNKSEC                           ;PT TO IT
        JMP     WDISK                             ;WRITE TO DISK
;*
;* READ DISK COMMAND
;*
CREAD
        JSR     GETDRV
        STA     >SDRIVE
        JSR     GETNUM                            ;GET SECTOR ID
        PSHS    X                                 ;SAVE
        JSR     GETHEX                            ;GET MEMORY ADDRESS
        PSHS    X                                 ;SAVE
        LDX     #1                                ;DEFAULT TO ONE
        JSR     SKIP                              ;ADVANCE
        BEQ     CRD1                              ;NO MORE
        JSR     GETNUM                            ;GET # SECTORS
CRD1
        TFR     X,Y                               ;SET UP COUNTER
        PULS    X                                 ;RESTORE MEM ADDR
        PULS    A,B                               ;RESTORE SECTOR ID
CRD2
        JSR     RDISK                             ;READ IT
        LEAX    512,X                             ;NEXT LOCATION
        ADDD    #1                                ;NEXT SECTOR
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     CRD2
        RTS
;*
;* WRITE DISK COMMAND
;*
CWRITE
        JSR     GETDRV
        STA     >SDRIVE
        JSR     GETNUM                            ;GET SECTOR ID
        PSHS    X                                 ;SAVE
        JSR     GETHEX                            ;GET MEMORY ADDRESS
        PSHS    X                                 ;SAVE
        LDX     #1                                ;DEFAULT TO ONE
        JSR     SKIP                              ;ADVANCE
        BEQ     CWR1                              ;NO MORE
        JSR     GETNUM                            ;GET # SECTORS
CWR1
        TFR     X,Y                               ;SET UP COUNTER
        PULS    X                                 ;RESTORE MEM ADDR
        PULS    A,B                               ;RESTORE SECTOR ID
CWR2
        JSR     WDISK                             ;WRITE IT
        LEAX    512,X                             ;NEXT LOCATION
        ADDD    #1                                ;NEXT SECTOR
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     CWR2
        RTS
;*
;* 'FILES' COMMAND, DISPLAY DISK DIRECTORY
;*
FILES
        LDX     #PREFIX                           ;POINT TO FILENAME
        LDB     #19                               ;CLEAR 19 CHARS
FIL1
        CLR     ,X+
        DECB
        BNE     FIL1
        LDA     #'*'                              ;WILDCARD
        STA     >PREFIX+8
        STA     >PREFIX+16
        PSHS    Y                                 ;SAVE CMD PTR
        JSR     GETDIR                            ;GET DIRECTORY NAME
        JSR     TSTERM                            ;ANY MORE?
        PULS    Y                                 ;RESTORE Y
        BEQ     FIL2                              ;NO, DISPAY
        JSR     GETNAM                            ;GET FULL FILE PATTERN
FIL2
        JMP     DISDIR                            ;OUTPUT IT
;*
;* 'CREATE' COMMAND, CREATE A FILE
;*
CREFIL
        LDD     >MBASE                            ;DEFAULT LOAD ADDRESS
        STD     >TEMP4                            ;SAVE IT
        JSR     GETVAL                            ;GET FILENAME
        JSR     SKIP                              ;MORE OPERANDS?
        BEQ     CREF1                             ;NO, SKIP IT
        JSR     GETHEX                            ;GET VALUE
        STX     >TEMP4                            ;SAVE IT
CREF1
        JMP     CREATE                            ;MAKE THE FILE
;*
;* 'DELETE' COMMAND
;*
DELFIL
        JSR     GETNAM                            ;GET FILENAME
DELETE
        JSR     LOCERR                            ;LOOK IT UP
        JSR     VALID                             ;VALID AS A SINGLE?
        BNE     MULDEL                            ;NO.
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #DPERM                            ;CAN WE DELETE
        LBEQ    PROERR                            ;NO, REPORT ERROR
        CLR     ,X                                ;INDICATE THIS ENTRY FREE
        JSR     CHGWRK                            ;MARK IT AS CHANGED
        LDD     DDADR,X                           ;GET DISK ADDRESS
;* RELEASE ALL CAHINED SECTORS
UNCHAIN
        JSR     FNDLNK                            ;LOCATE ITS LINK
        BEQ     UNC1                              ;LAST ONE
        CMPD    #0                                ;DID WE GET LOOSE SOMEHOW
        BEQ     UNC1                              ;STOP
        CLR     ,X                                ;ZERO THE ENTRY...
        CLR     1,X                               ;MAKEING IT FREE
        JSR     CHGWRK                            ;INDICATE WE CHANGED
        BRA     UNCHAIN                           ;CONTINUE
UNC1
        CLR     ,X
        CLR     1,X
        JMP     CHGWRK                            ;END OF DELETE
;* FILENAME CONTAINED WILDCARDS, PROMPT FOR EACH FILE
MULDEL
        LDD     #DIRSEC                           ;DIRECTORY STARTS HERE
MULD1
        JSR     RDWRK                             ;READ WORK SECTOR
MULD2
        JSR     COMNAM                            ;IS THIS ONE?
        BNE     MULD3                             ;NO
        JSR     SHONAM                            ;DISPLAY
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #DPERM                            ;CAN WE DELETE
        BNE     MULD5                             ;YES WE CAN
        JSR     WRMSG                             ;OUTPUT MESSAGE
        FCC     ' Protected'
        BRA     MULD3
MULD5
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' (Y/N/Q)?'
        JSR     GETCHR                            ;GET CHAR
        JSR     PUTCHR                            ;ECHO
        JSR     LFCR                              ;NEW LINE
        ANDA    #$DF                              ;CONVERT TO UPPER
        CMPA    #'Q'                              ;QUIT?
        BEQ     MULD4
        CMPA    #'Y'                              ;DO WE KILL?
        BNE     MULD3                             ;NO
        CLR     ,X                                ;ZAP IT
        JSR     CHGWRK                            ;INDICATE CHANGED
        PSHS    B,X                               ;SAVE REGS
        LDD     >WRKSEC                           ;GET WORK SECTOR
        STD     >TEMP1                            ;SAVE
        LDD     DDADR,X                           ;GET DISK ADDRESS
        BSR     UNCHAIN                           ;RELEASE
        LDD     >TEMP1                            ;GET SECTOR BACK
        JSR     RDWRK                             ;RE-READ
        PULS    B,X
MULD3
        LEAX    32,X                              ;ADVANCE TO NEXT
        CMPX    #WRKSPC+512                       ;ARE WE OVER?
        BLO     MULD2                             ;NO
        LDD     >WRKSEC                           ;GET SECTOR ID
        JSR     FNDLNK                            ;LOOK FOR LINK
        BNE     MULD1
MULD4
        RTS
;*
;* BINARY LOAD A FILE AT MEMORY(X)
;*
BLOAD
        PSHS    X                                 ;SAVE ADDRESS
        JSR     LOCRED                            ;LOOKUP FILE
        LDD     DDADR,X                           ;GET DISK ADDRESS
        PULS    X                                 ;RESTORE MEMORY ADDRESS
        BRA     LCHAIN                            ;LOAD IN THE CHAIN
;*
;* 'LOAD' COMMAND, LOADS A FILE INTO MEMORY
;*
LODFIL
        JSR     GETVAL                            ;GET FILENAME
        JSR     LOCRED                            ;INSURE IT EXISTS
        LDD     DDADR,X                           ;GET DISK ADDRESS
        PSHS    A,B                               ;SAVE
        LDX     DRADR,X                           ;GET RUN ADDRESS
        JSR     SKIP                              ;ANY MORE OPERANDS
        BEQ     LODF1                             ;NO, CONTINUE
        JSR     GETHEX                            ;GET ADDRESS
LODF1
        PULS    A,B                               ;RESTORE DISK ADDR
;* LOAD A CHAIN OF SECTORS
LCHAIN
        JSR     RDISK                             ;READ DISK
        LEAX    512,X                             ;MOVE TO NEXT ADDRESS
        PSHS    X                                 ;SAVE PTR
        JSR     FNDLNK                            ;LOOKUP LINK
        PULS    X                                 ;RESTORE
        BNE     LCHAIN                            ;KEEP GOING
OKRET
        RTS
;*
;* BINARY SAVE OF A FILE FROM MEMORY(X) FOR # SECTORS(D)
;*
BSAVE
        STX     >TEMP4                            ;SET LOAD ADDRESS
        STD     >TEMP3                            ;SAVE # SECTORS
        BRA     SAVF1                             ;PERFORM SAVE
;*
;* 'SAVE' COMMAND, SAVES A FILE AS A BLOCK
;*
SAVFIL
        JSR     GETVAL                            ;GET FILENAME
        JSR     GETHEX                            ;GET START ADDRESS
        STX     >TEMP4                            ;SET UP DEFAULT LOAD-ADR
        JSR     GETNUM                            ;GET # SECTORS
        STX     >TEMP3                            ;SAVE LENGTH
SAVF1
        TST     >TEMP3+1                          ;TEST FOR INVALID LENMGTH
        LBEQ    BADOPR                            ;INVALID
        JSR     LOCWRI                            ;OPEN FILE, WE WILL WRITE IT
        LDD     DDADR,X                           ;GET DISK ADDRESS
SAVF2
        STD     >TEMP2                            ;SAVE SECTOR ID
        LDX     >TEMP4                            ;GET LOAD ADDRESS
        JSR     WDISK                             ;WRITE THE SECTOR
        LEAX    512,X                             ;ADVANCE 1 BLOCK
        STX     >TEMP4                            ;NEW LOAD ADDRESS
        LDD     >TEMP2                            ;GET OPEN SECTOR
        DEC     >TEMP3+1                          ;REDUCE NUMBER
        BEQ     SAVF3                             ;QUIT IF DONE
        JSR     FNDLNK                            ;LOOK UP ITS LINK
        BNE     SAVF2                             ;THERE IS SPACE, ITS OK
        JSR     FRESEC                            ;GET A FREE SECTOR
        PSHS    A,B                               ;SAVE ID
        LDD     >TEMP2                            ;GET OPEN SECTOR
        JSR     FNDLNK                            ;GET LINK BACK
        PULS    A,B                               ;GET NEW SECT BACK
        STD     ,X                                ;SET LINK CHAIN
        JSR     CHGWRK                            ;INDICATE CHANGED
        BRA     SAVF2                             ;WRITE NEXT SECTOR
SAVF3
        JSR     FNDLNK                            ;LOK UP LINK
        BEQ     OKRET                             ;NO FURTHER LINKS
        PSHS    A,B                               ;SAVE REGS
        LDD     #$FFFF                            ;GET END OF FILE MARKER
        STD     ,X                                ;MARK SECTOR
        STA     >WRKCHG                           ;INDICATE CHANGED
        PULS    A,B                               ;GET CHAINED SECTOR BACK
        JMP     UNCHAIN                           ;SET IT FREE
;*
;* 'RETURN' COMMAND
;*
RETURN
        LDD     >OLDSTK                           ;GET OLD STACK
        BEQ     NOSUSP                            ;NONE, SKIP IT
        TFR     D,S                               ;SET UP STACK
        CLRA                                      ;ZERO IT
        RTS
NOSUSP
        JSR     WRMSG                             ;OUTPUT MESSAGE
        FCC     'No suspended program'
        LDS     >SAVSTK                           ;RESTORE STACK
DNLRTS
        CLRA                                      ;ZERO RC
        RTS
;*
;* 'DOWNLOAD' COMMAND
;*
DNLD
        JSR     GETDEV                            ;GET DEVICE ID
        STB     >TEMP2                            ;SAVE IT
        CLR     >TEMP3+1                          ;ZERO COUNT
        LDD     #$FFFF                            ;INIT LOW ADDR
        STD     >TEMP4                            ;SAVE LOW ADDRESS
        CLRA
        CLRB
        PSHS    A,B                               ;SAVE HIGH ADDR
DNL0
        LDA     #$0D
        JSR     PUTCHR                            ;OUTPUT
        LDA     >TEMP3+1
        JSR     WRHEX                             ;OUTPUT IN HEX
        INC     >TEMP3+1
        BSR     DNL1                              ;DOWNLOAD RECORD
        BNE     DNLEND                            ;END, QUIT
        CMPX    ,S                                ;HIGEST YET?
        BLS     DNL0                              ;NO, SKIP
        STX     ,S                                ;SAVE HIGH
        BRA     DNL0                              ;OK, KEEP GOING
DNLEND
        JSR     LFCR                              ;NEW LINE
        PULS    A,B                               ;GET HIGEST
        SUBD    >TEMP4                            ;CALCULATE SIZE
        SUBD    #1                                ;CONVERT
        LSRA                                      ;/512, CONVERT TO # SECTORS
        INCA    CONVERT
        STA     >TEMP3+1                          ;SAVE LENGTH
        JSR     SKIP                              ;OPERAND?
        BEQ     DNLRTS                            ;NO FILE TO SAVE INTO
        JSR     GETVAL                            ;GET FILENAME
        JMP     SAVF1                             ;PERFORM SAVE
;* DOWNLOAD A RECORD FROM A DEVICE
DNLDEV
        STA     >TEMP2                            ;SAVE DEVICE ID
DNL1
        BSR     RDDLC                             ;GET CHAR
        CMPA    #'S'                              ;START OF RECORD?
        BNE     DNL1                              ;NO
        BSR     RDDLC                             ;GET NEXT CHAR
        CMPA    #'0'                              ;HEADER?
        BEQ     DNL1                              ;IGNORE
        CMPA    #'9'                              ;END OF FILE
        BNE     DNL2                              ;YES, END OF FILE
        LDA     #RCEOF
        RTS
DNL2
        CMPA    #'1'                              ;DATA RECORD
        BNE     LODERR                            ;INVALID
        BSR     GETBYT                            ;GET LENGTH
        STA     >TEMP2+1                          ;START CKSUM
        SUBA    #3                                ;CONVERT
        STA     >TEMP3                            ;SAVE LENGTH
        BSR     GETBYT                            ;GET HIGH ADDR
        PSHS    A                                 ;SAVE
        BSR     GETBYT                            ;GET LOW ADDR
        TFR     A,B                               ;SAVE
        ADDA    ,S                                ;ADD HIGH
        ADDA    >TEMP2+1                          ;& CKSUM
        STA     >TEMP2+1                          ;RESAVE
        PULS    A                                 ;RESTORE
        TFR     D,X                               ;SET UP PTR
        CMPD    >TEMP4                            ;HIGHER?
        BHS     DNL3                              ;YES
        STD     >TEMP4                            ;NEW VALUE
DNL3
        BSR     GETBYT                            ;GET BYTE
        STA     ,X+                               ;SAVE IT
        ADDA    >TEMP2+1                          ;INCL CKSUM
        STA     >TEMP2+1                          ;RESAVE CKSUM
        DEC     >TEMP3                            ;REDUCE LENGTH
        BNE     DNL3                              ;GET FULL REC.
        BSR     GETBYT                            ;GET CKSUM
        ADDA    >TEMP2+1                          ;+ CALC CKSUM
        INCA    TEST FOR OK
        BEQ     DNL4                              ;YES, GET NEXT REC
LODERR
        LDX     #DNLMSG                           ;PT TO ERROR MESSAGE
        LDA     #RCDNL                            ;RETURN CODE
        JMP     ERRMRC                            ;RETURN
RDDLC
        LDB     >TEMP2                            ;GET DEV
        JMP     RDDEV                             ;GET CHAR
GETBYT
        BSR     GETNIB                            ;GET IT
        LSLA
        LSLA
        LSLA
        LSLA
        PSHS    A
        BSR     GETNIB
        ORA     ,S+
DNL4
        RTS
GETNIB
        BSR     RDDLC                             ;GET CHAR
        SUBA    #'0'                              ;CONVERT
        CMPA    #9                                ;OK?
        BLS     GETN1                             ;YES
        CMPA    #$11                              ;<A
        BLO     LODERR                            ;INVALID
        SUBA    #7                                ;CONVERT
        CMPA    #$10                              ;IN RANGE
        BHS     LODERR                            ;INVALID
GETN1
        RTS
;*
;* 'CONNECT' COMMAND
;*
CNCT
        JSR     GETDEV                            ;GET DEVICE
        STB     >TEMP2                            ;SAVE
CNC1
        JSR     TSTCHR                            ;TEST FOR CHAR FROM CONSOLE
        BNE     CNC2                              ;NO, NONE
        CMPA    #$1B                              ;ESCAPE?
        LBEQ    LFCR                              ;IF SO, EXIT
        LDB     >TEMP2                            ;GET DEVICE BACK
        JSR     WRDEV                             ;OUTPUT TO DEVICE
CNC2
        LDB     >TEMP2                            ;GET DEVICE ID
        JSR     TSTDEV                            ;TEST FOR CHARACTER
        BNE     CNC1                              ;NO CHAR RECEIVED
        JSR     PUTCHR                            ;WRITE TO CONSOLE
        BRA     CNC1                              ;CONTINUE
;*
;* 'SET' COMMAND
;*
SET
        LDX     #SETTAB                           ;POINT TO TABLE
        JSR     TLOOK                             ;LOOK IT UP
        JSR     SKIP                              ;ADVANCE
        BEQ     BADOP3                            ;INVALID
        LDX     #SETADR
        ASLB
        JMP     [B,X]
;* SET DEFAULT
SET0
        JSR     GETDIR                            ;GET DEFAULT DIR
        JSR     SKIP                              ;ANY MORE INFO
        BNE     BADOP3
SETDEF
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDX     #DEFDRV                           ;POINT TO DEFAULT
        BRA     MOVDIR                            ;MOVE IT
;* SET COMMAND
SET1
        LDX     #SYSDRV                           ;DEFAULT FROM SYSTEM
        JSR     GETDIR1                           ;GET DIR
        JSR     SKIP
        BNE     BADOP3
SETCMD
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDX     #SYSDRV                           ;POINT TO IT
MOVDIR
        LDY     #FDRIVE                           ;POINT TO FILENAME
        LDB     #9                                ;MOVE 9 CHARS
MOVD1
        LDA     ,Y+                               ;GET 1
        STA     ,X+                               ;SAVE IT
        DECB
        BNE     MOVD1                             ;CONTINUE
        PULS    A,B,X,Y,PC
;* SET FILE
SET2
        JSR     GETVAL                            ;GET NAME
        JSR     LOCERR                            ;LOOK IT UP
SETF0
        PSHS    X                                 ;SAVE PTR
        LDX     #SFTAB                            ;PT TO TABLE
        JSR     TLOOKE                            ;LOOK IT UP
        TSTB                                      ;IS IT SET LOADADDRESS
        BNE     SETF1                             ;NO, TRY SOMETHING ELSE
        JSR     GETHEX                            ;GET ADDRESS
        TFR     X,D                               ;COPY
        PULS    X                                 ;RESTORE
        STD     DRADR,X                           ;SAVE
        BRA     SETF2                             ;TEST FOR END
SETF1
        DECB
        BNE     BADOP3
        BSR     GETATR                            ;GET ATTRIBUTES
        PULS    X                                 ;RESTORE
        STA     DATTR,X                           ;SAVE
SETF2
        JSR     SKIP                              ;ADVANCE
        BNE     SETF0
        JMP     CHGWRK                            ;INDICATE WE CHANGED
;* GET FILE ATTRIBUTES FROM COMMAND LINE
GETATR
        CLRA    CLEAR IT
        PSHS    A,B,X                             ;SAVE ON STACK
GETA1
        LDX     #ATRTAB                           ;POINT TO TABLE
        JSR     TSTERM                            ;GET CHARACTER
        BEQ     GETA4                             ;END
        LDB     #%10000000                        ;START WITH FIRST ATTR
GETA2
        CMPA    ,X+                               ;IS THIS IT?
        BEQ     GETA3                             ;YES
        LSRB                                      ;SHIFT IT
        BNE     GETA2                             ;MORE
BADOP3
        JMP     BADOPR                            ;REPORT ERROR
GETA3
        ORB     ,S                                ;INCLUDE IN ATTRIBUTES
        STB     ,S                                ;RESAVE
        BRA     GETA1                             ;AND CONTINUE
GETA4
        PULS    A,B,X,PC                          ;RESTORE REGS
ATRTAB
        FCC     'RWED????'                        ;AVAILABLE ATTRIBUTE BITS
;*
;* SET DRIVE COMMAND
;*
SET3
        JSR     PURGE                             ;INSURE ALL WRITTEN
        JSR     GETDRV                            ;GET DRIVE ID
        STA     >SDRIVE                           ;SELECT IT
        JSR     GETCTL                            ;GET CTRL BLOCK
        PSHS    Y                                 ;SAVE CMD POINTER
        JSR     HOME                              ;HOME HEAD
        PULS    Y                                 ;RESTORE CMD POINTER
CHGDRV
        LDX     #SDTAB                            ;POINT TO TABLE
        JSR     TLOOKE                            ;LOOK FOR IT
        PSHS    B                                 ;SAVE
        JSR     GETNUM                            ;GET IT
        TFR     X,D                               ;GET NUMBER
        PULS    A                                 ;RESTORE
        CMPA    #3                                ;VALID?
        BHI     BADOP3                            ;ERROR
        STB     A,U                               ;SET IT
        JSR     SKIP                              ;AT END?
        BNE     CHGDRV                            ;NO
        RTS
;*
;* LOOKUP TABLE ENTRY & INSURE IT ENDS WITH '='
;*
TLOOKE
        JSR     TLOOK                             ;LOOKUP ENTRY
        LDA     ,Y+                               ;GET NEXT CHAR
        CMPA    #'='                              ;IS IT EQUALS?
        BNE     BADOP3                            ;REPORT ERROR
        RTS
;*
;* SET MEMORY
;*
SET4
        JSR     GETHEX                            ;GET ADDRESS
ST1
        PSHS    X                                 ;SAVE ADDR
        JSR     GETHEX                            ;GET DATA
        TFR     X,D                               ;SAVE IT
        PULS    X                                 ;RECOVER
        STB     ,X+                               ;SAVE IT
        JSR     SKIP                              ;END OF LINE?
        BNE     ST1                               ;CONTINUE
        RTS
;* SET CONSOLE
SET5
        LDX     #IOTAB                            ;POINT TO TABLE
        JSR     TLOOKE                            ;LOOK IT UP
        CMPB    #2                                ;OVER?
        BHS     BADOP3                            ;INVALID
        PSHS    B                                 ;SAVE ID
        BSR     GETDEV                            ;GET DEVICE NUMBER
        PULS    A                                 ;GET ID BACK
        LDX     #CONIN
        STB     A,X                               ;SET IT
        JSR     SKIP
        BNE     SET5
        RTS
;* GET A DEVICE ID FROM THE CONSOLE
GETDEV
        JSR     GETNUM                            ;GET DECIMAL NUMBER
        CMPX    #NDEV                             ;IS IT OVER THE LIMIT
        LBHS    BADDEV                            ;YES, REPORT ERROR
        TFR     X,D                               ;'B' = DEVICE ID
        RTS
;* SET FLAG ON/OFF
STFLAG
        LSRB                                      ;CONVERT BACK
        PSHS    B                                 ;SAVE
        LDX     #OOTAB                            ;PT TO IT
        JSR     TLOOK                             ;LOOKUP IN TABLE
        PULS    A                                 ;RESTORE VECT NUM
        TSTB                                      ;IS IT OFF?
        BEQ     CLRFLG                            ;YES, CLEAR IT
        DECB                                      ;IS IT ON
        LBNE    BADOPR                            ;NO, ITS INVALID
;* SET AN OS FLAG
SETFLG
        PSHS    B,X
        LDB     #$FF
        BRA     GOFLG
;* CLEAR A OS FLAG
CLRFLG
        PSHS    B,X
        CLRB
GOFLG
        CMPA    #NUMFLG
        LBHS    BADOPR
        LDX     #MSGFLG
        LEAX    A,X
        LDA     ,X
        STB     ,X
        ORCC    #4
        PULS    B,X,PC
;*
;* SHOW COMMAND
;*
SHOW
        LDX     #SETTAB                           ;POINT TO IT
        JSR     TLOOK                             ;LOOK FOR IT
        LSLB
        LDX     #SHOADR
        JMP     [B,X]
;* SHOW DEFAULT
SHOW0
        LDX     #DEFDRV                           ;PT TO IT
        BRA     SDCMD                             ;SHOW IT
SHOW1
        LDX     #SYSDRV                           ;PT TO IT
SDCMD
        LDA     ,X+                               ;GET DRIVE ID
        ADDA    #'A'                              ;CONVERT
        JSR     PUTCHR
        JSR     WRLIN
        FCC     ':['
        LDB     #8
SDC1
        LDA     ,X+
        BEQ     SDC2
        JSR     PUTCHR
SDC2
        DECB
        BNE     SDC1
        LDA     #']'
        JSR     PUTCHR
        JMP     LFCR                              ;EXIT
;* SHOW FILE
SHOW2
        JSR     GETVAL                            ;GET NAME
        JSR     LOCERR                            ;LOOK IT UP
        JSR     WRLIN
        FCC     'File: '
        JSR     SHONAM                            ;OUTPUT
        JSR     WRLIN
        FCB     $0A,$0D
        FCC     'Disk address='
        LDD     DDADR,X
        JSR     WRDEC
        JSR     WRLIN
        FCC     ', Load address=$'
        LDD     DRADR,X
        JSR     WRHEXW
        JSR     WRLIN
        FCC     ', Protection='
        LDB     DATTR,X
        LDY     #ATRTAB
SH21
        LDA     ,Y+
        LSLB
        BCC     SH22
        JSR     PUTCHR
SH22
        TSTB
        BNE     SH21
        JSR     LFCR
        LDY     #0                                ;0 BLOCKS
        LDD     DDADR,X
SH23
        LEAY    1,Y                               ;ADVANCE
        JSR     FNDLNK                            ;LOOK UP LINK
        BNE     SH23                              ;FIND EM ALL
        JSR     WRLIN
        FCC     'File contains '
        TFR     Y,D
        JSR     WRDEC
        JSR     WRMSG
        FCC     ' block(s).'
        RTS
;* SHOW DISK FORMAT
SHOW3
        JSR     GETDRV
SHODRV
        PSHS    A,U                               ;SAVE REGISTERS
        JSR     GETCTL1                           ;GET DRIVE CONTROL BLOCK
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     'Drive: '
        LDA     ,S                                ;GET DRIVE ID
        ADDA    #'A'                              ;CONVERT TO DRIVE ID
        JSR     PUTCHR                            ;OUTPUT IT
        JSR     LFCR                              ;NEW LINE
        LDX     #SDTAB                            ;POINT TO TABLE
        CLRA                                      ;DISPLAY ADDRESS
        LDB     DRIVE,U                           ;GET DRIVE ID
        BSR     SHODRB                            ;DISPLAY IT
        LDA     #1                                ;DISPLAY CYLINDERS
        LDB     NCYL,U                            ;GET # CYLINDERS
        BSR     SHODRA                            ;DISPLAY IT
        LDA     #2                                ;DISPLAY HEADS
        LDB     NHEAD,U                           ;GET # HEADS
        BSR     SHODRA                            ;DISPLAY IT
        LDA     #3                                ;DISPLAY SECTORS/TRACK
        LDB     NSEC,U                            ;GET # SECTORS/TRACK
        BSR     SHODRA                            ;DISPLAY IT
        PULS    A,U                               ;RESTORE REGS
        JMP     LFCR                              ;NEW LINE
        JMP     LFCR                              ;NEW LINE
        JMP     LFCR                              ;NEW LINE
        JMP     LFCR                              ;NEW LINE
        JMP     LFCR                              ;NEW LINE
        JMP     LFCR                              ;NEW LINE
        JMP     LFCR                              ;NEW LINE
SHODRA
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ', '                              ;STRING
SHODRB
        BSR     SHOTAB                            ;DISPLAY TABLE ENTRY
        LDA     #'='                              ;GET FOLLOWING '='
        JSR     PUTCHR                            ;OUTPUT IT
        JMP     WRDEC8                            ;AND DISPLAY VALUE
;*
;* DISPLAY ENTRY(A) IN TABLE(X)
;*
SHOTAB
        PSHS    B,X                               ;SAVE REGS
        INCA                                      ;ADVANCE FOR COUNT
SHOT1
        LDB     ,X+                               ;GET CHAR FROM TABLE
        BPL     SHOT1                             ;NOT FLAG, KEEP LOOKING
        ANDB    #%01111111                        ;IS IT LAST ONE?
        BEQ     SHOT4                             ;YES, RETURN NOT-FOUND
        DECA                                      ;IS THIS IT?
        BNE     SHOT1                             ;NO, KEEP LOOKING
SHOT2
        LDA     ,X+                               ;GET CHAR
        BMI     SHOT3                             ;END, EXIT
        JSR     PUTCHR                            ;DISPLAY
        BRA     SHOT2                             ;DO NEXT
SHOT3
        CLRA    ZERO RC
        PULS    B,X,PC
SHOT4
        LDA     #RCBOP                            ;INVALID OPERAND PASSED
        PULS    B,X,PC                            ;RETURN
;* SHOW CONSOLE I/O ASSIGNMENTS
SHOW5
        LDX     #IOTAB                            ;POINT TO TABLE
        CLRA                                      ;DISPLAY INPUT
        LDB     >CONIN                            ;GET INPUT
        BSR     SHODRB                            ;DISPLAY IT
        LDA     #1                                ;DISPLAY OUTPUT
        LDB     >CONOUT                           ;GET OUTPUT
        BSR     SHODRA                            ;DISPLAY IT
        JMP     LFCR                              ;NEW LINE
;* DISPLAY FLAGS
SHFLAG
        LSRB
        TFR     B,A                               ;COPY
        LDX     #SETTAB                           ;POINT TO TABLE
        BSR     SHOTAB                            ;DISPLAY IT
        LDA     #'='                              ;GET EQUALS SIGN
        JSR     PUTCHR                            ;OUTPUT IT
        LDX     #MSGFLG                           ;PT TO AREA
        LDA     B,X                               ;GET FLAG VALUE
        BEQ     SHOOFF                            ;OFF, SHOW IT
        LDA     #1                                ;CONVERT TO ON
SHOOFF
        LDX     #OOTAB                            ;POINT TO ON/OFF TABLE
        BSR     SHOTAB                            ;OUTPUT TABLE ENTRY
        JMP     LFCR                              ;NEW LINE & EXIT
;*
;* SHOW MEMORY COMAND
;*
SHOW4
        JSR     GETHEX                            ;	GET STARTING ADDRESS
        PSHS    X                                 ;SAVE IT
        JSR     SKIP                              ;	MORE OPERANDS?
        BEQ     EX1                               ;NO, THATS IT
        JSR     GETHEX                            ;	GET ENDING ADDRESS
EX1
        STX     >TEMP1                            ;	SAVE ADDR
        PULS    X                                 ;GET STARTING BACK
EX2
        TFR     X,D                               ;GET ADDRESS
        JSR     WRHEXW                            ;	DISPLAY
        LDB     #16                               ;16 BYTES/LINE
EX3
        BITB    #3                                ;BOUNDARY?
        BNE     EX4
        JSR     SPACE                             ;EXTRA SPACE
EX4
        JSR     SPACE                             ;OUTPUT SPACE
        LDA     ,X+                               ;GET DATA
        JSR     WRHEX                             ;OUTPUT
        DECB                                      ;BACKUP COUNT
        BNE     EX3                               ;DO EM ALL
        LDB     #4
EX5
        JSR     SPACE                             ;MORE SPACES
        DECB
        BNE     EX5
        LEAX    -16,X                             ;BACKUP
        LDB     #16
EX6
        LDA     ,X+
        CMPA    #' '                              ;SPACE?
        BLO     EX7
        CMPA    #$7F                              ;DELETE
        BLO     EX8                               ;OK
EX7
        LDA     #'.'                              ;INDICATE BAD
EX8
        JSR     PUTCHR                            ;OUTPUT
        DECB    BACKUP
        BNE     EX6                               ;CONTINUE
        JSR     LFCR                              ;NEW LINE
        JSR     TSTCHR
        BEQ     EX9
        CMPX    >TEMP1                            ;PAST END?
        BLS     EX2                               ;NO, KEEP GOING
EX9
        CLRA
        RTS
;* SHOW FREE
SHOW6
        JSR     GETDRV                            ;GET DRIVE ID
        STA     >SDRIVE                           ;SELECT IT
        BSR     CALFRE                            ;CALCULATE SIZE & FREE
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     'Drive '
        LDA     >SDRIVE                           ;GET DRIVE ID
        ADDA    #'A'                              ;CONVERT TO PRINTABLE
        JSR     PUTCHR                            ;DISPLAY
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' has '
        LDD     >TEMP2                            ;GET DISK SIZE
        JSR     WRDEC                             ;DISPLAY IN DECIMAL
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' blocks, '
        LDD     >TEMP1                            ;GET FREE BLOCKS
        JSR     WRDEC                             ;OUTPUT IN DECIMAL
        JSR     WRMSG                             ;OUTPUT MESSAGE
        FCC     ' free'
        RTS
;*
;* CALCULATE # FREE SECTORS ON DISK
;*
CALFRE
        PSHS    X,Y
        JSR     CURSIZ                            ;GET DRIVE SIZE
        STD     >TEMP2                            ;SAVE # BLOCKS
        TFR     D,Y                               ;SAVE IT
        CLRA
        CLRB
        STD     >TEMP1                            ;SAVE COUNT
        LDB     #LNKSEC                           ;GET LINK SECTORS
DISF1
        STD     >TEMP                             ;CURRENT SECTOR
        JSR     RDWRK                             ;READ IT
DISF2
        LDD     ,X++                              ;GET SECTOR ID
        BNE     DISF3                             ;USED
        INCB                                      ;GET A ONE
        ADDD    >TEMP1                            ;ADVANCE COUNT
        STD     >TEMP1                            ;RESAVE COUNT
DISF3
        LEAY    -1,Y                              ;REDUCE BY ONE
        BEQ     DISF4                             ;ALL DONE
        CMPX    #WRKSPC+512                       ;ARE WE OVER
        BLO     DISF2                             ;NO, ITS OK
        LDD     >TEMP                             ;GET SECTOR
        ADDD    #1                                ;ADVANCE
        BRA     DISF1
DISF4
        LDD     >TEMP1                            ;RECOVER IT
        ORCC    #4
        PULS    X,Y,PC
;* 'SET' OPERAND TABLES
SETTAB
        FCB     $83
        FCC     'Message'
        FCB     $83
        FCC     'Debug'
        FCB     $82
        FCC     'Trace'
        FCB     $83
        FCC     'DEFAULT'
        FCB     $82
        FCC     'SYSTEM'
        FCB     $82
        FCC     'FILE'
        FCB     $82
        FCC     'DRIVE'
        FCB     $83
        FCC     'MEMORY'
        FCB     $82
        FCC     'CONSOLE'
        FCB     $82
        FCC     'FREE'
        FCB     $80
;* 'SET' OPERAND HANDLERS
SETADR
        FDB     STFLAG                            ;MESSAGE
        FDB     STFLAG                            ;DEBUG
        FDB     STFLAG                            ;TRACE
        FDB     SET0                              ;DEFAULT
        FDB     SET1                              ;SYSTEM
        FDB     SET2                              ;FILE
        FDB     SET3                              ;DRIVE
        FDB     SET4                              ;MEMORY
        FDB     SET5                              ;CONSOLE
        FDB     BADOPR                            ;FREE
        FDB     BADOPR                            ;INVALID
;* 'SHOW' OPERAND HANDLERS
SHOADR
        FDB     SHFLAG                            ;MESSAGE
        FDB     SHFLAG                            ;DEBUG
        FDB     SHFLAG                            ;TRACE
        FDB     SHOW0                             ;DEFAULT
        FDB     SHOW1                             ;SYSTEM
        FDB     SHOW2                             ;FILE
        FDB     SHOW3                             ;DRIVE
        FDB     SHOW4                             ;MEMORY
        FDB     SHOW5                             ;CONSOLE
        FDB     SHOW6                             ;FREE
        FDB     BADOPR                            ;INVALID
;* 'SET FILE' OPTIONS
SFTAB
        FCB     $81
        FCC     'LOAD_ADDRESS'
        FCB     $81
        FCC     'PROTECTION'
        FCB     $80
;* 'INITIALIZE' OPTIONS
INITAB
        FCB     $81
        FCC     'Interleave'
        FCB     $81
        FCC     'Directory extension'
;* 'SET DISK' OPTIONS
SDTAB
        FCB     $81
        FCC     'Address'
        FCB     $81
        FCC     'Cylinders'
        FCB     $81
        FCC     'Heads'
        FCB     $81
        FCC     'Sectors/Track'
        FCB     $80
;* FLAG ON/OFF TABLE
OOTAB
        FCB     $82
        FCC     'OFF'
        FCB     $82
        FCC     'ON'
        FCB     $80
;* 'SET CONSOLE' OPTIONS
IOTAB
        FCB     $81
        FCC     'Input'
        FCB     $81
        FCC     'Output'
        FCB     $80
