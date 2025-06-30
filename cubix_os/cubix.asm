;	title	CUBIX 6809 Operating System
;*
;* CUBIX Operating System for the 6809
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*

        IFDEF   6809PC
;* MEMORY LOCATIONS FOR DUODYNE
ROM             EQU $E000                         ; OS FIRMWARE
RAM             EQU $0400                         ; OS LOCAL STORAGE (1K)
USRRAM          EQU $2000                         ; START OF USER SUPPLIED RAM
USREND          EQU ROM-1                         ; RAMTEST STOPS HERE
        ENDIF

        IFDEF   duodyne
;* MEMORY LOCATIONS FOR DUODYNE
ROM             EQU $E000                         ; OS FIRMWARE
RAM             EQU $1000                         ; OS LOCAL STORAGE (1K)
USRRAM          EQU $2000                         ; START OF USER SUPPLIED RAM
USREND          EQU ROM-257                       ; RAMTEST STOPS HERE
        ENDIF

        IFDEF   nhyodyne
;* MEMORY LOCATIONS FOR NHYODYNE
ROM             EQU $E000                         ; OS FORMWARE
RAM             EQU ROM-1024                      ; OS LOCAL STORAGE
USRRAM          EQU $2000                         ; START OF USER SUPPLIED RAM
USREND          EQU ROM-1                         ; RAMTEST STOPS HERE
        ENDIF

;* MISC CONSTANTS
NDEV            EQU 8                             ; NUMBER OF SERIAL DEVICES SUPPORTED
NDSK            EQU 4                             ; # OF DISK DRIVES SUPPORTED
DIRSEC          EQU 0                             ; DIRECTORY STARTS HERE
LNKSEC          EQU 1                             ; STARTING LINK SECTOR ON DISK
DEFATR          EQU %11110000                     ; DEFAULT FILE ATTRIBUTES
;* RETURN CODES
RCBOP           EQU 1                             ; BAD OPERAND
RCNOTF          EQU 2                             ; FILE NOT FOUND
RCPRO           EQU 3                             ; FILE PROTECTION VIOLATION
RCORE           EQU 4                             ; NOT OPEN FOR READ
RCOWE           EQU 5                             ; NOT OPEN FOR WRITE
RCEOF           EQU 6                             ; END OF FILE ENCOUNTERED
RCEXI           EQU 7                             ; FILE ALREADY EXISTS
RCNOS           EQU 8                             ; NO DISK SPACE AVAILABLE
RCDSK           EQU 9                             ; DISK ERROR
RCDEV           EQU 10                            ; INVALID DEVICE
RCDNL           EQU 11                            ; DOWNLOAD FAILURE
RCCMD           EQU 255                           ; BAD COMMAND
;* FILE PERMISSIONS
RPERM           EQU %10000000                     ; READ PERMISSION
WPERM           EQU %01000000                     ; WRITE PERMISSION
EPERM           EQU %00100000                     ; EXECUTE PERMISSION
DPERM           EQU %00010000                     ; DELETE PERMISSION
;* DISK CONTROL BLOCK DESCRIPTION
        ORG     0
DRIVE
        RMB     1                                 ; DRIVE ID
NCYL
        RMB     1                                 ; # TRACKS
NHEAD
        RMB     1                                 ; # HEADS
NSEC
        RMB     1                                 ; # SECTORS/TRACK
CYL
        RMB     1                                 ; CURRENT CYLINDER
HEAD
        RMB     1                                 ; CURRENT HEAD
SEC
        RMB     1                                 ; CURRENT SECTOR
CSIZE           EQU *
;* DIRECTORY ENTRY DESCRIPTION
        ORG     0
DPREFIX
        RMB     8                                 ; DIRECTORY PREFIX
DNAME
        RMB     8                                 ; FILENAME
DTYPE
        RMB     3                                 ; FILETYPE
DDADR
        RMB     2                                 ; DISK ADDRESS
DRADR
        RMB     2                                 ; RUN ADDRESS
DATTR
        RMB     1                                 ; FILE ATTRIBUTES
;* FILE CONTROL BLOCK DESCRIPTION
        ORG     0
OTYPE
        RMB     1                                 ; TYPE OF OPEN (READ/WRITE ETC.)
ODRIVE
        RMB     1                                 ; DRIVE FILE IS ON
OFIRST
        RMB     2                                 ; FIRST SECTOR IN ILE
OSECTOR
        RMB     2                                 ; SECTOR BEING READ/WRITTEN
OLSTSEC
        RMB     2                                 ; LAST SECTOR READ/WRITTEN
OOFFSET
        RMB     2                                 ; OFFSET INTO SERIAL BUFFER
OSIZ            EQU *
;* RAM VARIABLES
        ORG     RAM
INBUFF
        RMB     80                                ; INPUT BUFFER
IRAM            EQU *                             ; START OF INITIALIZED RAM
DCTRL
        RMB     CSIZE*NDSK                        ; DRIVE CONTROL BLOCKS
CONIN
        RMB     1                                 ; SELECTED CONSOLE INPUT
CONOUT
        RMB     1                                 ; SELECTED CONSOLE OUTPUT
;* DITAB MARKS START OF VECTOR TABLE
;* SERIAL DEVICE DRIVERS
DITAB
        RMB     NDEV*2                            ; DEVICE INPUT DRIVERS
DOTAB
        RMB     NDEV*2                            ; DEVICE OUTPUT DRIVERS
;* DISK DRIVERS
XHOME
        RMB     2                                 ; DISK HOME HEAD ROUTINE
XRDSEC
        RMB     2                                 ; DISK READ SECTOR ROUTINE
XWRSEC
        RMB     2                                 ; DISK WRITE SECTOR ROUTINE
XFORMAT
        RMB     2                                 ; DISK FORMAT ROUTINE
;* MACHINE VECTORS
SWIVEC
        RMB     2                                 ; SWI HANDLER VECTOR
SWI2VEC
        RMB     2                                 ; SWI2 INTERRUPT VECTOR
SWI3VEC
        RMB     2                                 ; SWI3 INTERRUPT VECTOR
IRQVEC
        RMB     2                                 ; IRQ HANDLER VECTOR
FIRQVEC
        RMB     2                                 ; FIRQ HANDLER VECTOR
NMIVEC
        RMB     2                                 ; NMI HANDLER VECTOR
;* MSGFLG MARKS START OF FLAG TABLES
MSGFLG
        RMB     1                                 ; MESSAGE ENABLED FLAG
DBGFLG
        RMB     1                                 ; DEBUG FLAG
TRCFLG
        RMB     1                                 ; TRACE ENABLED FLAG
NUMFLG          EQU 3                             ; # FLAGS SUPPORTED
;* DEFAULT DIRECTORY
DEFDRV
        RMB     1                                 ; DEFAULT DRIVE
DEFDIR
        RMB     8                                 ; DEFAULT DIRECTORY
;* SYSTEM DIRECTORY
SYSDRV
        RMB     1                                 ; SYSTEM DRIVE
SYSDIR
        RMB     8                                 ; SYSTEM DIRECTORY
DRIVEMAP
        RMB     8                                 ; DRIVE MAPPINGS
;* NON-INITIALIZED GLOBAL RAM
FDRIVE
        RMB     1                                 ; CURRENT DISK DRIVE
PREFIX
        RMB     8                                 ; DIRECTORY PREFIX
FNAME
        RMB     8                                 ; FILENAME
FTYPE
        RMB     3                                 ; FILETYPE
TEMP
        RMB     2                                 ; TEMPORARY STORAGE
TEMP1
        RMB     2                                 ; MORE TEMPORARY STORAGE
TEMP2
        RMB     2                                 ;STILL MORE
TEMP3
        RMB     2                                 ;STILL MORE
TEMP4
        RMB     2                                 ;STILL MORE
SAVB
        RMB     1                                 ;CALLERS 'B' REGISTER
SAVX
        RMB     2                                 ;CALLERS 'X' REGISTER
SAVY
        RMB     2                                 ;CALLERS 'Y' REGISTER
SAVDRV
        RMB     1                                 ;CALLERS ACTIVE DRIVE
SAVSTK
        RMB     2                                 ;CALLERS STACK POINTER
WRKCHG
        RMB     1                                 ;WORK SECTOR CHANGED
WRKDRV
        RMB     1                                 ;CURRENT WORK SECTOR DRIVE
WRKSEC
        RMB     2                                 ;CURRENT WORK SECTOR
CMDDRV
        RMB     1                                 ;CURRENT COMMAND FILE DRIVE
CMDSEC
        RMB     2                                 ;CURRENTLY OPEN COMMAND FILE SECTOR
CMDOFF
        RMB     2                                 ;OFFSET INTO COMMAND FILE SECTOR
CMDSTK
        RMB     2                                 ;COMMAND PROCESSOR STACK PTR
CMDRC
        RMB     1                                 ;COMMAND FILE RETURN CODES
OLDSTK
        RMB     2                                 ;STACK FROM BEFORE TEMP ENTRY
SDRIVE
        RMB     1                                 ;CURRENTLY SELECTED DRIVE
ERRCNT
        RMB     1                                 ;DISK ERROR RETRY COUNT
CMDBUF
        RMB     80                                ;COMMAND BUFFER PARAMETER SAVE AREA
STACK           EQU RAM+512                       ;SYSTEM STACK
WRKSPC          EQU STACK                         ;WORK AREA
;*
        ORG     ROM
;* MISC FIXED CONSTANTS
ROMCHK
        FDB     $FFFF                             ;BLANK SPACE TO INSERT CHECKSUM
        IFDEF   test
        LDD     #ssr
        STD     >tvector
        JMP     begin
        ENDIF
MBASE
        FDB     USRRAM                            ;BASE MEMORY ADDRESS
;*
;* HARDWARE INITIALIZATION ROUTINE
;*
DOINIT
        LDY     #IRAM                             ;POINT TO INITIALIZED RAM
        JMP     HWINIT                            ;INIT HARDWARE
;*
;* APPLICATION PROGRAM INTERFACE
;*
SSR
        STB     >SAVB                             ;APPLICS SAVED 'B'
        STX     >SAVX                             ;APPLICS SAVED 'X'
        STY     >SAVY                             ;APPLICS SAVED 'Y'
        LDB     >SDRIVE                           ;GET DOS DRIVE
        STB     >SAVDRV                           ;SET SAVED DRIVE
        LEAY    10,S                              ;ADDR OF SAVED PC
        LDX     ,Y                                ;GET IT
        LDB     ,X+                               ;GET OPERAND BYTE
        STX     ,Y                                ;SAVE UPDATED PC
        CMPB    #NUMSSR                           ;IS IT A VALID CALL #
        BHS     INVSSR                            ;INVALID CALL
        ASLB                                      ;DOUBLE FOR TWO BYTE ENTRIES
        LDX     #SSRTAB                           ;OFFSET TO IT
        ABX                                       ;UNSIGNED ADD
        LDD     ,X                                ;GET ADDRESS
        STD     >TEMP                             ;SAVE SO WE CAN EXEC
        STY     >SAVSTK                           ;SAVE STACK POINTER
        LDA     >DBGFLG                           ;DEBUGGING?
        BNE     DBGSSR                            ;YES, OUTPUT DATA
        PULS    CC,A,B,DP,X,Y,U                   ;RESTORE APPLICS REGS
        JMP     [TEMP]                            ;EXECUTE SYSTEM CALL
DBGSSR
        JSR     WRLIN                             ;OUTPUT LINE
        FCC     'SSR '
        FCB     $00
        LDX     ,Y                                ;RECOVER PC
        LDB     -1,X                              ;GET NUMBER BACK
        JSR     WRDEC8                            ;OUTPUT
        JSR     WRLIN
        FCC     ' - '
        FCB     $00
        PULS    CC,A,B,DP,X,Y,U
        BSR     DMPREG1                           ;DISPLAY REGS
        JMP     [TEMP]
INVSSR
        TFR     Y,S                               ;FIX STACK
        JSR     WRLIN                             ;OUTPUT LINE
        FCC     'Invalid SSR '
        FCB     $00
        JSR     WRDEC8                            ;OUTPUT
        JSR     WRLIN                             ;OUTPUT LINE
        FCC     ' at $'
        FCB     $00
        LDD     ,S++                              ;GET ADDR
        SUBD    #2                                ;BACK TO ADDRESS
        JSR     WRHEXW                            ;OUTPUT
        JSR     LFCR                              ;NEW LINE
        JMP     DOSKCM                            ;RE-ENTER, INSURE NO COMMAND
DMPREG
        BSR     DMPREG1                           ;BSR SO PC ON STACK,4
        RTS
;* DEBUG ROUTINE
DMPREG1
        PSHS    CC,A,B                            ;SAVE REGS
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     'PC='
        FCB     $00
        LDD     5,S                               ;GET PC
        SUBD    #2                                ;BACK UP TO SSR ADDRESS
        JSR     WRHEXW                            ;OUTPUT HEX WORD
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' CC='
        FCB     $00
        LDA     ,S                                ;GET CONDITION CODE
        JSR     WRHEX                             ;OUTPUT HEX BYTE
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' DP='
        FCB     $00
        TFR     DP,A                              ;GET DIRECT PAGE
        JSR     WRHEX                             ;OUTPUT HEX BYTE
        JSR     WRLIN                             ;OUTPUT MESSAHE
        FCC     ' A='
        FCB     $00
        LDA     1,S                               ;GET SAVED 'A'
        JSR     WRHEX                             ;OUTPUT HEX BYTE
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' B='
        FCB     $00
        LDA     2,S                               ;GET SAVED 'B'
        JSR     WRHEX                             ;OUTPUT HEX BYTE
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' X='
        FCB     $00
        TFR     X,D                               ;GET 'X'
        JSR     WRHEXW                            ;OUTPUT HEX WORD
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' Y='
        FCB     $00
        TFR     Y,D                               ;GET 'Y'
        JSR     WRHEXW                            ;OUTPUT HEX WORD
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' U='
        FCB     $00
        TFR     U,D                               ;GET 'U'
        JSR     WRHEXW                            ;OUTPUT HEX WORD
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     ' S='
        FCB     $00
        TFR     S,D                               ;GET 'S'
        ADDD    #7                                ;DISCOUNT WHAT WE STACKED
        JSR     WRHEXW                            ;OUTPUT HEX WORD
        JSR     LFCR                              ;OUTPUT NEW LINE
        PULS    CC,A,B,PC                         ;RESTORE & RETURN
;*
;* ZERO WORK RAM & INIT HARDWARE DEVICES
;*
BEGIN

        LDS     #STACK                            ;SET UP SYSTEM STACK
        LDX     #RAM                              ;POINT TO START OF RAM
BEG1
        CLR     ,X+                               ;ZERO IT
        CMPX    #STACK                            ;AT END?
        BLO     BEG1                              ;CONTINUE
        JSR     DOINIT                            ;INITIALIZE HARDWARE
        JSR     PURGE1                            ;INITIALIZE WORK SECTOR
        CLR     >ERRCNT                           ;INDICATE NO ERRORS

;        IFNDEF  test
;;* PERFORM CHECKSUM TEST OF ROM
;        JSR     WRLIN                             ;OUTPUT MESSAGE
;        FCC     'ROM... '
;        LDX     #ROMCHK+2                         ;CHECKSUM STARTS HERE
;        CLRA                                      ;ZERO HIGH
;        CLRB                                      ;ZERO LOW
;ROMT1
;        ADDB    ,X+                               ;ADD IN ONE BYTE
;        ADCA    #0                                ;INSURE HIGH INCREMENTS
;        CMPX    #0                                ;AT END OF ROM?
;        BNE     ROMT1                             ;NO, KEEP TRYING
;        CMPD    >ROMCHK                           ;DOES CHECKSUM MATCH?
;        BEQ     ROMT2                             ;YES, ITS OK
;;* ROM TEST FAILED
;        JSR     WRMSG                             ;OUTPUT MESSAGE
;        FCC     'Failed'
;        DEC     >ERRCNT                           ;SET FLAG, INDICATE ERROR
;        BRA     ROMT3
;* ROM TEST PASSED
;ROMT2
;        BSR     SPASS                             ;DISPLAY PASSED MESSAGE
;        ENDIF
;;* PERFORM WALKING BIT TEST OF RAM
;ROMT3
;        JSR     WRLIN                             ;OUTPUT MESSAGE
;        FCC     'RAM... '
;        LDX     >MBASE                            ;GET BASE RAM ADDRESS
;RAMT1
;        LDA     ,X                                ;GET ORIGINAL DATA BYTE
;        LDB     #%10000000                        ;BEGIN WITH LEFTMOST BIT
;RAMT2
;        STB     ,X                                ;WRITE TEST PATTERN
;        CMPB    ,X                                ;DOES IT MATCH
;        BNE     RAMT5                             ;NO, FAILED
;        LSRB                                      ;SHIFT BIT
;        BNE     RAMT2                             ;DO NEXT BIT
;        STA     ,X+                               ;RESTORE ORIGINAL DATA
;;* ON EVEN PAGE BOUNDARYS, TEST FOR ABORT KEY
;        TFR     X,D                               ;GET ADDRESS
;        TSTB                                      ;EVEN BOUNDARY?
;        BNE     RAMT3                             ;NO, DON'T TEST
;        JSR     TSTCHR                            ;ANY CHARACTERS RECEIVED?
;        CMPA    #$1B                              ;ESCAPE ABORTS?
;        BEQ     RAMT4                             ;ABORT RAM TEST
;;* CONTINUE TILL AT END OF USER RAM
;RAMT3
;        CMPX    #USREND                           ;ARE WE OVER?
;        BLO     RAMT1                             ;NO, ITS OK
;;* FINISHED, RAM TEST PASSED
;        BSR     SPASS                             ;INDICATE SUCCESS
;        BRA     HELLO                             ;AND PROCEED
;* DISPLAY 'PASSED' MESSAGE
;SPASS
;        JSR     WRMSG                             ;OUTPUT MESSAGE
;        FCC     'Passed'
;        RTS
;;* RAM TEST ABORTED BY ESCAPE
;RAMT4
;        JSR     WRMSG                             ;OUTPUT MESSAGE
;        FCC     'Aborted'
;        BRA     RAMT6                             ;AND CONTINUE
;;* RAM TEST FAILED,
;RAMT5
;        STA     ,X                                ;RESAVE OLD VALUE
;        JSR     WRLIN                             ;OUTPUT FAILED MESSAGE
;        FCC     'Failed at $'
;        TFR     X,D                               ;GET ADDRESS
;        JSR     WRHEXW                            ;DISPLAY IN HEX
;        JSR     LFCR                              ;NEW LINE
;RAMT6
;        DEC     >ERRCNT                           ;INDICATE ERRORS
;* ISSUE HEARALD MESSAGE & START THE BALL ROLLING
HELLO
        JSR     WRMSG
        FCB     $0A
        FCC     'CUBIX version 1.5'
        FCB     $0A,$0D,$0A
        FCC     'Copyright 1983-2005 Dave Dunfield'
        FCB     $0A,$0D
        FCC     'All rights reserved'
        FCB     $0A,$0D,0

;* IF NO ERRORS, EXECUTE THE STARTUP FILE
        LDA     >ERRCNT                           ;GET ERROR FLAG
        BNE     CMD                               ;ERRORS, DO NOT EXECUTE
        LDY     #IPLFILE                          ;POINT TO IPL FILE
        JSR     GETNAM                            ;GET FILE NAME
        LDU     #CMD                              ;ADDRESS TO RETURN TO
        PSHS    U                                 ;SAVE ON STACK (FAKE JSR)
        STS     >SAVSTK                           ;SAVE STACK INCASE ERROR
        JSR     LOCDIR                            ;LOCATE FILE IN DIRECTORY
        BNE     CMD                               ;NOT FOUND, REPORT ERROR
        JMP     EXE3                              ;EXECUTE FILE
;*
;* COMMAND INTERPRETER
;*
CMD
        LDS     #STACK                            ;SET UP STACK
        JSR     WRTST                             ;WRITE OUT WORK SECTOR IF MODIFIED
        JSR     GLINE                             ;GET LINE OF INPUT
        BSR     EXECMD                            ;EXECUTE COMMAND
RCRET
        BEQ     CMD                               ;NO RETURN CODE TO DISPLAY
        TFR     A,B                               ;WRITE IT
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCC     'Rc='
        FCB     $00
        JSR     WRDEC8                            ;OUTPUT IN DECIMAL
        JSR     LFCR                              ;NEW LINE
        BRA     CMD                               ;GET NEXT COMMAND
;* RE-ENTRY POINT
REENT
        PSHS    CC                                ;SAVE CC
        LDX     #0                                ;GET A ZERO
        STX     >OLDSTK                           ;CLEAR RETURN STACK
        LDX     >CMDSTK                           ;GET CMD STACK
        BNE     CMDGO                             ;KEEP IT GOING
        PULS    CC                                ;RESTORE CC
        BRA     RCRET                             ;AND CONTINUE
CMDGO
        PULS    CC
        JMP     CMDRET                            ;RETURN TO COMMAND
;* TEMPORARY DOS ENTRY
TMPENT
        STS     >OLDSTK                           ;SAVE OLD STACK
DOSKCM
        CLRA
        CLRB
        STD     >CMDSTK                           ;ZERO COMAND STACK
        BRA     CMD                               ;CONTINUE
;*
;* EXECUTE DOS COMMAND(Y)
;*
EXECMD
        STS     >SAVSTK                           ;SAVE STACK POINTER
        LDA     >SDRIVE                           ;GET DISK DRIVE
        STA     >SAVDRV                           ;SAVE SELECTED DRIVE
        JSR     SKIP                              ;LOOK FOR NULL COMMAND
        BEQ     NULCMD                            ;DON'T EXECUTE NULL
        STY     >TEMP2                            ;SAVED POINTER TO COMMAND
        CMPA    #'@'                              ;EXECUTE COMMAND FILE?
        LBEQ    COMFIL                            ;DO IT
        LDX     #CMDNAM                           ;POINT TO COMMAND TABLE
        JSR     TLOOK                             ;LOOK FOR IT
        CMPB    #NUMCMD                           ;IS IT OVER?
        BHS     EXE                               ;YES, TRY USER DEFINED
        ASLB                                      ;TWO BYTE ENTRIES
        LDX     #CMDADR                           ;GET COMMAND ADDRESSES
        JMP     [B,X]                             ;EXECUTE COMMAND
NULCMD
        RTS
;*
;* RUN COMMAND
;*
RUN
        JSR     GETSNA                            ;GET FILENAME
RUN1
        LDA     #'E'                              ;GET TYPE
        LDB     #'X'                              ;GET TYPE
        STD     ,X++                              ;SAVE IT
        STA     ,X                                ;WRITE IT
        JSR     LOCERR                            ;DOES IT EXIST
;* FILE HAS BEEN FOUND, EXECUTE
RUN2
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #EPERM                            ;CAN WE EXECUTE?
        LBEQ    PROERR                            ;NO, REPORT ERROR
        LDD     DDADR,X                           ;GET DISK ADDRESS
        LDX     DRADR,X                           ;GET RUN ADDRESS
        STX     >TEMP1                            ;SAVE
        JSR     LCHAIN                            ;LOAD THE CHAIN
        LDB     >SDRIVE                           ;GET OUR CURRENT DRIVE
        JSR     SKIP                              ;SKIP TO COMMANDS
        JMP     [TEMP1]                           ;PASS CONTROL TO HIM
;*
;* COMMAND WAS NOT RECOGNIZED, SEARCH SYSTEM DIRECTORY LOOKING
;* FOR FILE WITH NAME MATCHING COMMAND.
;*
EXE
        CLR     >TEMP1                            ;INDICATE IMPLIED RUN
        LDX     #SYSDRV                           ;PT TO SYSTEM DIRECTORY (& DRIVE)
        JSR     GETDIR1                           ;GET DIR & DRIVE
        BSR     NAMGET                            ;GET NAME
        LDA     #'*'                              ;WILDCARD
        STA     ,X                                ;SAVE TYPE
        LDA     >FDRIVE                           ;GET FILENAME DRIVE
        STA     >SDRIVE                           ;SELECT DRIVE
        LDD     #DIRSEC                           ;GET DIRECTORY SECTOR
EXE1
        JSR     RDWRK                             ;READ A WORK SECTOR
EXE2
        JSR     COMNAM                            ;DOES IT MATCH
        BEQ     EXE3                              ;YES, IT DOES
;* NAMES DON'T MATCH, ADVANCE TO NEXT ENTRY
        LEAX    32,X                              ;NEXT
        CMPX    #WRKSPC+512                       ;OVER?
        BLO     EXE2                              ;NO, KEEP LOOKING
        LDD     >WRKSEC                           ;GET SECTOR
        JSR     FNDLNK                            ;LOCATE LINK
        BNE     EXE1                              ;READ IT & LOOK
;* COMMAND IS INVALID, REPORT ERROR
BADCMD
        LDX     #UNCMD                            ;PT TO MESSAGE
        LDA     #RCCMD                            ;GET RC
        BRA     ERRMRC                            ;REPORT ERROR
;* COMMAND MATCHES FILENAME, CHECK TYPE FOR EXECUTE
EXE3
        LDA     DTYPE+2,X                         ;GET TYPE
        STA     >FTYPE+2                          ;SAVE IT
        LDD     DTYPE,X                           ;GET REST OF TYPE
        STD     >FTYPE                            ;SAVE IT
;* WE HAVE FOUND EXECUTABLE FILE
        CMPD    #'@'*256                          ;IS IT A COMMAND FILE?
        LBEQ    COMGO                             ;YES, EXECUTE
        CMPA    #'E'                              ;'EX'?
        BNE     EXE4                              ;NO, LOOK FOR CMD PROC
        CMPB    #'X'                              ;'EX'?
        BNE     EXE4                              ;NO, LOOK FOR CMD PROC
        CMPA    DTYPE+2,X                         ;INSURE ITS 'EXE'
        BEQ     RUN2                              ;YES, EXECUTE
;* UNKNOWN FILETYPE, TRY FOR USER COMMAND PROCESSOR
EXE4
        TFR     X,Y                               ;'Y' POINTS TO DIR ENTRY
        LDX     #FNAME                            ;POINT TO TYPE
        STD     ,X++                              ;SAVE IT
        LDA     DTYPE+2,Y                         ;GET LAST CHR
        STA     ,X+                               ;SAVE IT
EXE5
        CLR     ,X+                               ;CLEAR IT
        CMPX    #FNAME+8                          ;OVER?
        BLO     EXE5                              ;ALL OUT
        LDY     >TEMP2                            ;RESTORE COMMAND POINTER
        JMP     RUN1                              ;TRY THIS ONE
;*
;* GET FILENAME WITHOUT TYPE, NORMAL DEFAULT
;*
GETSNA
        JSR     GETDIR                            ;GET DIRECTORY
GETSN0
        LDA     #$FF                              ;FLAG
        STA     >TEMP1                            ;SET IT
NAMGET
        LDB     #8                                ;MAX EIGHT CHARS
GETSN1
        JSR     TSTERM                            ;TERMINATOR?
        BEQ     GOPAD                             ;YES, QUIT
        CMPA    #'/'                              ;SPECIAL TERMINATOR
        BNE     GETSN2
        LEAY    -1,Y                              ;BACKUP TO SLASH
GOPAD
        JMP     PAD
GETSN2
        STA     ,X+                               ;SAVE IT
        DECB                                      ;BACKUP
        BPL     GETSN1                            ;MORE
        TST     >TEMP1                            ;WERE WE 'RUN'ING
        BEQ     BADCMD                            ;NO,
;*
;* INVALID OPERAND
;*
BADOPR
        LDX     #BADOPM                           ;MESSAGE
        LDA     #RCBOP                            ;RETURN CODE
;*
;* ISSUE ERROR MESSAGE & RETURN TO CALLER WITH RETURN CODE
;*
ERRMRC
        PSHS    CC                                ;SAVE IT
;* VERIFY CONSOLE DEVICE IS VALID & RESET IF NOT
        LDB     >CONOUT                           ;GET OUTPUT
        CMPB    #NDEV                             ;IN RANGE
        BHS     ERRM1                             ;NO - ERROR
        LDY     #DOTAB                            ;POINT TO TABLE
        ASLB                                      ;X2
        LDY     B,Y                               ;INSTALLED?
        BNE     ERRM2                             ;YES, ITS OK
ERRM1
        LDB     #1                                ;DEFAULT DEVICE
        STB     >CONOUT                           ;RESET INPUT
ERRM2
        LDB     >CONIN                            ;GET INPUT
        CMPB    #NDEV                             ;IN RANGE
        BHS     ERRM3                             ;NO - ERROR
        LDY     #DITAB                            ;POINT TO TABLE
        ASLB                                      ;X2
        LDY     B,Y                               ;INSTALLED?
        BNE     ERRM4                             ;YES, ITS OK
ERRM3
        LDB     #1                                ;DEFAULT DEVICE
        STB     >CONIN                            ;RESET INPUT
ERRM4
        TST     >MSGFLG                           ;ARE MESSAGES ENABLED
        BEQ     NOEMSG                            ;NO, DON'T OUTPUT
        JSR     WRSTR                             ;OUTPUT
        JSR     LFCR                              ;NEW LINE
NOEMSG
        PULS    CC                                ;RESTORE CC
;* RETURN TO CALLER WITH NO ERROR MESSAGE
ERRRET
        PSHS    CC                                ;SAVE CC
        LDB     >SAVDRV                           ;GET SAVED DRIVE
        STB     >SDRIVE                           ;RESET SELECTED DRIVE
        LDX     >SAVX                             ;RESTORE 'X'
        LDY     >SAVY                             ;RESTORE 'Y'
        LDB     >SAVB                             ;RESTORE 'B'
        PULS    CC                                ;RESTORE CONDITION CODES
        BEQ     ZERORC                            ;ITS ZERO
        LDS     >SAVSTK                           ;GET SAVED SP
        RTS
ZERORC
        LDS     >SAVSTK                           ;GET STACK
        ORCC    #%00000100                        ;SET 'Z'
        RTS
;*
;* GET FILE WITHOUT TYPE, DEFAULT TO SYSTEM
;*
GETSYS
        LDX     #SYSDRV                           ;DEFAULT IS SYSTEM
;*
;* GET FILENAME WITHOUR TYPE, DEFAULT(X)
;*
GETSDI
        JSR     GETDIR1                           ;GET NAME
        JMP     GETSN0                            ;GET FILENAME
;*
;* COMPARES NAME(X) TO SAVED FILENAME
;*
COMNAM
        PSHS    A,B,X,Y                           ;SAVE REGS
        LDY     #PREFIX                           ;POINT TO SAVED
        LDA     ,X                                ;INSURE NAME IS NOT NULL
        BNE     NOTNUL                            ;ITS NOT,
        DECA                                      ;GET FF
        BRA     CEND                              ;QUIT
NOTNUL
        LDB     #8                                ;EIGHT CHARS NI PREFIX
        BSR     COMX                              ;COMPARE
        BNE     CEND                              ;NOT SAME, EXIT
        LDB     #8                                ;EIGHT CHARS IN NAME
        BSR     COMX                              ;COMPARE
        BNE     CEND                              ;NOT SAME
        LDB     #3                                ;THREE CHARS IN TYPE
        BSR     COMX                              ;COMPARE
CEND
        PULS    A,B,X,Y,PC                        ;GO HOME
COMX
        LDA     ,Y+                               ;GET CHAR FROM SAVED
        CMPA    #'*'                              ;WILDCARD?
        BEQ     RNXT                              ;RETURN WITH TRUE
        CMPA    ,X+                               ;DOES IT MATCH
        BNE     RNXT1                             ;NO, FAIL
        DECB                                      ;BACKUP
        BNE     COMX                              ;OK
        RTS
RNXT
        LEAX    1,X
RNXT1
        DECB                                      ;REDUCE COUNT
        BEQ     BRET                              ;DONE, QUIT
        LEAY    1,Y                               ;ADVANCE
        BRA     RNXT                              ;AND CONTINUE
BRET
        CMPA    #'*'                              ;WUZ IT WILDCARD
        RTS
;*
;* TEST SAVED FILENAME FOR VALIDITY AS A SINGLE FILE
;*
VALID
        PSHS    A,B,X                             ;SAVE REGS
        LDB     #19                               ;LENGTH OF NAME
        LDX     #PREFIX                           ;POINT TO NAME
VALTST
        LDA     ,X+                               ;GETCHAR
        CMPA    #'*'                              ;WILDCARD
        BEQ     RETNZ                             ;INVALID
        DECB                                      ;BACKUP
        BNE     VALTST                            ;CONTINUE
        CLRA                                      ;ZERO RETURN CODE
RETNZ
        TSTA                                      ;SET 'Z' FLAG
        PULS    A,B,X,PC
;*
;* GET FILENAME & INSURE ITS VALID
;*
GETVAL
        BSR     GETNAM                            ;GET FILENAME
        BSR     VALID                             ;TEST FOR VALID
        BNE     BADOP2                            ;INVALID, ERROR
        RTS
;*
;* GET A FILENAME FROM INPUT LINE
;*
GETNAM
        BSR     GETDIR                            ;GET DRIVE & DIRECTORY
GFNAM
        LDB     #8                                ;EIGHT CHARS/NAME
GF1
        BSR     VALCHR                            ;GET CHAR
        CMPA    #'.'                              ;SEPERATOR?
        BEQ     GFTYP                             ;YES
        STA     ,X+                               ;SAVE IT
        DECB                                      ;BACKUP
        BPL     GF1                               ;KEEP GOING
        BRA     BADOP2                            ;ERROR
GFTYP
        BSR     PAD                               ;PAD FILENAME
        LDB     #3                                ;THREE CHARS/TYPE
GF2
        JSR     TSTERM                            ;GET CHAR
        BEQ     GF3                               ;HIT END
        STA     ,X+                               ;SAVE IT
        DECB                                      ;REDUCE COUNT
        BPL     GF2                               ;KEEP GOING
BADOP2
        JMP     BADOPR                            ;ERROR
GF3
        BSR     PAD                               ;ZERO IT
        JSR     SKIP                              ;TO NEXT
        LDX     #PREFIX                           ;POINT TO IT
        CLRA                                      ;ZERO RC
        RTS
;* ABORT IF CHARACTER INVALID
VALCHR
        JSR     TSTERM                            ;TEST FOR CHAR OK
        BEQ     BADOP2                            ;INVALID
        RTS
;* PADS NAME WITH BLANKS UNTILL 'B' IS ZERO
PAD
        DECB                                      ;BACKUP COUNT
        BMI     GETD5                             ;THATS ALL
        CLR     ,X+                               ;CLEAR IT
        BRA     PAD
;*
;* GETS A DRIVE AND DIRECTORY FROM THE INPUT LINE
;*
GETDIR
        LDX     #DEFDRV                           ;PT TO IT
GETDIR1
        LDA     ,X+                               ;GET DEFAULT DRIVE
        STA     >FDRIVE                           ;SET IT
        JSR     SKIP                              ;ADVANCE
        BEQ     GETD1                             ;END OF LINE, NO DRIVE SPEC
        LDB     1,Y                               ;GET NEXT CHAR
        CMPB    #':'                              ;IS IT A DRIVE SPEC?
        BNE     GETD1                             ;NO, IGNORE IT
        BSR     GETDRV1                           ;GET DRIVE ID
        STA     >FDRIVE                           ;SET DRIVE ID
GETD1
        PSHS    Y                                 ;SAVE
        TFR     X,Y                               ;SET UP PTR TO DEFAULT
        LDX     #PREFIX                           ;POINT TO PREFIX
        LDB     #8                                ;MOVE EIGHT
GETD2
        LDA     ,Y+                               ;GET FROM DEFAULT
        STA     ,X+                               ;SAVE IN NAME
        DECB                                      ;REDUCE COUNT
        BNE     GETD2                             ;MOVE EM ALL
        PULS    Y                                 ;RESTORE
        LDA     ,Y                                ;GET CHAR
        CMPA    #'['                              ;DIRECTORY ID
        BNE     GETD5                             ;NO, SKIP IT
        LDX     #PREFIX                           ;POINT TO PREFIX
        LEAY    1,Y                               ;ADVANCE
        LDB     #8                                ;UP TO EIGHT CHARS
GETD3
        JSR     VALCHR                            ;GET CHAR, INSURE VALID
        CMPA    #']'                              ;CLOSING?
        BEQ     GETD4                             ;YES
        STA     ,X+                               ;SAVE IT
        DECB                                      ;BACKUP
        BPL     GETD3                             ;KEEP GOING
BADOP1
        JMP     BADOPR
GETD4
        BSR     PAD                               ;PAD WITH BLANKS
        TST     >PREFIX                           ;IS IT NULL
        BEQ     BADOP1                            ;INVALID
GETD5
        CLRA
        RTS
;* GET A DRIVE & RETURN IN A
GETDRV
        JSR     SKIP                              ;ADVANCE TO OPERAND
GETDRV1
        LDD     ,Y++                              ;GET DATA
        CMPB    #':'                              ;COLON
        BNE     BADOP1                            ;NO
        SUBA    #'A'                              ;CONVERT
        CMPA    #4                                ;IN RANGE
        BHS     BADOP1                            ;NO
        ORCC    #4                                ;SET 'Z'
        RTS
;*
;* GETS A VALUE (DECIMAL OR HEX) FROM INPUT LINE
;*
GETNUM
        JSR     SKIP                              ;SKIP TO DATA
        BEQ     BADOP1                            ;INVALID
        CMPA    #'$'                              ;HEX?
        BNE     GETDV                             ;NO, GET DECIMAL
        LEAY    1,Y                               ;ADVANCE TO NEXT
;*
;* GETS A 16 BIT HEX NUMBER FOR X FROM THE INPUT LINE.
;*
GETHEX
        JSR     SKIP                              ;GET CHARACTER
        BEQ     BADOP1                            ;INDICATE BAD OPERAND
GETHV
        LDX     #0                                ;START WITH ZERO
GETL1
        JSR     TSTERM                            ;TEST FOR TERMINATOR
        BEQ     HEXEND                            ;IF SO, THIS IS IT
        SUBA    #'0'                              ;CONVERT TO BINARY
        CMPA    #10                               ;TEST FOR > '9'
        BLO     DIGOK                             ;IF NOT, DIGIT IS OK
        CMPA    #$11                              ;TEST FOR < 'A'
        BLT     BADOP1                            ;OPERAND IS INVALID
        SUBA    #7                                ;CONVERT TO ASCII
        CMPA    #$10                              ;TEST FOR 0-F
        BHS     BADOP1                            ;IF NOT, DIGIT IS BAD
DIGOK
        STA     >TEMP+1                           ;SAVE FOR LATER
        LDA     #5                                ;SHIFT FOUR TIMES
        STA     >TEMP                             ;SAVE COUNTER
DSHFT
        TFR     X,D                               ;COPY TO X
        LEAX    D,X                               ;MULTIPLY BY 2, = 1 BIT SHIFT
        DEC     >TEMP                             ;REDUCE COUNT
        BNE     DSHFT                             ;KEEP SHIFTING
        ORB     >TEMP+1                           ;STICK ON EXTRA DIGIT
        TFR     D,X                               ;COPY BACK TO X
        BRA     GETL1                             ;GET NEXT DIGIT
HEXEND
        JSR     SKIP                              ;ADVANCE TO NEXT OPERAND
        CLRA                                      ;INDICATE ZERO RETURN CODE
        RTS
;*
;* GETS A DECIMAL NUMBER FROM THE TERMINAL.
;*
GETDEC
        JSR     SKIP                              ;SKIP TO START OF OPERAND.
        LBEQ    BADOPR                            ;IF INVALID, GO BACK.
GETDV
        LDX     #0                                ;START WITH ZERO.
DECDIG
        JSR     TSTERM                            ;TEST FOR TERMINATOR
        BEQ     HEXEND                            ;IF THATS ALL, FORGET IT.
        SUBA    #'0'                              ;CONVERT TO BINARY.
        CMPA    #9                                ;TEST FOR INVALID.
        LBHI    BADOPR                            ;AGAIN, INVALID OPERAND.
        PSHS    A                                 ;SAVE ACC.
        LDD     #10                               ;MUL BY 10
        JSR     MUL16                             ;D=D*X
        ADDB    ,S+                               ;ADD IN DIGIT
        ADCA    #0                                ;INSURE HIGH GOES
        TFR     D,X                               ;COPY TO RESULT
        BRA     DECDIG                            ;GET NEXT
;*
WRDEC8
        CLRA                                      ;DISPLAY 8 BIT BUMBER (B) IN DECIMAL
;*
;* DISPLAYS 16 BIT NUMBER IN D AS A DECIMAL NUMBER,
;*
WRDEC
        PSHS    A,B,X,Y                           ;SAVE X-Y REGISTERS
        LDY     #0                                ;START WITH ZERO CHARACTERS
        TFR     D,X                               ;SET UP STARTING VALUE
WRDE1
        LDD     #10                               ;DIVIDE BY 10
        JSR     DIV16                             ;X=X/D, D=REMAINDER
        PSHS    B                                 ;SAVE REMAINDER
        LEAY    1,Y                               ;INDICATE ANOTHER ON STACK
        CMPX    #0                                ;ANY MORE?
        BNE     WRDE1                             ;NO, CONTINUE
WRDE2
        PULS    A                                 ;GET DIGIT BACK
        ADDA    #'0'                              ;CONVERT TO PRINTABLE FORM
        JSR     PUTCHR                            ;DISPLAY DECIMAL DIGIT
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     WRDE2                             ;IF NOT END, CONTINUE DISPLAYING
        PULS    A,B,X,Y,PC                        ;RESTORE INDEX REG'S
;*
;* GETS AND BUFFERS A LINE FROM THE TERMINAL, ON EXIT, Y REGISTER
;* POINTS TO LINE IN BUFFER.
;*
GLFCR
        JSR     LFCR                              ;START A NEW LINE
GLINE
        LDA     #'*'                              ;GET PROMPT CHARACTER
        JSR     PUTCHR                            ;DISPLAY
GLNOP
        LDY     #INBUFF                           ;POINT TO INPUT BUFFER
GLINE1
        TFR     Y,D                               ;GET POINTER INTO BUFFER
        CMPB    #80                               ;TEST FOR OVER LIMIT
        BHI     GLFCR                             ;INDICATE ERROR
        JSR     GETCHR                            ;GET CHARACTER FROM CONSOLE
        CMPA    #$7F                              ;TEST FOR DELETE
        BEQ     GLINE2                            ;YES, PERFORM DELETE
        CMPA    #8                                ;TEST FOR BACKSPACE
        BNE     GLINE3                            ;DON'T DELETE
GLINE2
        LEAY    -1,Y                              ;DELETE A CHARACTER
        JSR     WRLIN                             ;OUTPUT MESSAGE
        FCB     8,' ',8,0                         ;WIPE PREVIOUS CHARACTER
        BRA     GLINE1                            ;GET NEXT CHARACTER
GLINE3
        JSR     PUTCHR                            ;ECHO CHARACTER
        BSR     TOUPPER                           ;CONVERT TO UPPERCASE
        STA     ,Y+                               ;SAVE IN BUFFER
        CMPA    #$0D                              ;TEST FOR END OF LINE
        BNE     GLINE1                            ;GET NEXT CHARACTER
        LDY     #INBUFF                           ;POINT TO BUFFER
        JMP     LFCR                              ;START A NEW LINE
;*
;* SKIPS TO NEXT NON-BLANK CHARACTER IN INPUT LINE. AND TESTS IT FOR <CR>.
;*
SKIP
        LDA     ,Y+                               ;GET CHARACTER
        CMPA    #' '                              ;TEST FOR BLANK
        BEQ     SKIP                              ;IF SO, KEEP LOOKING
        TST     ,-Y                               ;BACKUP & TEST FOR ZERO
        BEQ     SKRTS                             ;YES, END WITH 'Z' SET
        CMPA    #$0D                              ;TEST FOR CARRIAGE RETURN
SKRTS
        RTS
;*
;* TESTS FOR VALID TERMINATOR CHARACTERS.
;*
TSTERM
        LDA     ,Y+                               ;GET CHARACTER AND ADVANCE
        BEQ     TSTE1                             ;IF NULL, INDICATE TERMINATOR
        CMPA    #' '                              ;TEST FOR SPACE
        BEQ     TRET                              ;IF SO, QUIT
        CMPA    #$0D                              ;IS IT A CARRIAGE RETURN
        BNE     TRET                              ;IF NOT, DON'T BACK UP
TSTE1
        LEAY    -1,Y                              ;BACK UP SO WE DON'T GO BEYOND
        ORCC    #%00000100                        ;SET 'Z'
TRET
        RTS
;*
;* CONVERT THE CHARACTER IN 'A' TO UPPER CASE
;*
TOUPPER
        CMPA    #'A'+$20                          ;ALREADY UPPERCASE?
        BLO     TRET                              ;YES, ITS OK
        CMPA    #'Z'+$20                          ;ALREADY UPPERCASE?
        BHI     TRET                              ;YES, ITS OK
        ANDA    #%01011111                        ;CONVERT TO UPPERCASE
        RTS
;*
;* LOOKS UP WORD(Y) IN TABLE(X). INDEX OF COMMAND IN TABLE IS
;* RETURNED IN THE B REGISTER, WITH ZERO BEING THE FIRST COMMAND.
;* FOR INFORMATION ON THE COMMAND TABLE FORMAT, SEE COMMAND TABLE.
;*
TLOOK
        CLRB                                      ;START WITH ZERO ENTRY
        BSR     SKIP                              ;SKIP LEADING BLANKS
TLOOK1
        LDA     ,X+                               ;GET CHAR FROM FILE
        BPL     TLOOK1                            ;ADVANCE TO CONTROL BYTE
        LEAX    -1,X                              ;BACKUP TO IT
        PSHS    Y                                 ;SAVE POSITION
        ANDA    #$7F                              ;REMOVE FLAG BIT
        BEQ     TLOOK6                            ;END OF TABLE ENCOUNTERED
        STA     >TEMP                             ;SAVE FOR LATER REF
TLOOK2
        LEAX    1,X                               ;ADVANCE IN TABLE
        DEC     >TEMP                             ;REDUCE COUNT
        LDA     ,X                                ;GET CHAR
        BSR     TOUPPER                           ;CONVERT TO UPPERCASE
        STA     >TEMP+1                           ;SAVE FOR LATER
        BSR     TSTERM                            ;TEST FOR TERMINATOR
        BEQ     TLOOK5                            ;IF SO, TEST IT
        CMPA    >TEMP+1                           ;TEST FOR SAME AS TABLE ENTRY
        BEQ     TLOOK2                            ;IF SO, IT'S OK
        CMPA    #'/'                              ;SLASH?
        BEQ     TLOOK4                            ;YES, ACCEPT IT
        CMPA    #'='                              ;EQUALS?
        BEQ     TLOOK4                            ;ACCEPT IT AS WELL
;* THIS ENTRY NOT FOUND, SKIP TO NEXT ONE
TLOOK3
        PULS    Y                                 ;RESTORE COMMAND POINTER
        INCB                                      ;INC. INDICATOR
        BRA     TLOOK1                            ;TRY NEXT ENTRY
TLOOK4
        LEAY    -1,Y                              ;BACKUP TO SPECIAL CHAR
TLOOK5
        ORA     >TEMP                             ;TEST FOR MINIMUM NUMBER OF CHARS
        BPL     TLOOK3                            ;IF NOT, SKIP THIS COMMAND
TLOOK6
        BSR     SKIP                              ;SKIP TO OPERANDS
        TSTB                                      ;SET FLAG IS ZERO
        PULS    X,PC                              ;CLEAN UP STACK
;*
;* OUTPUT NUMBER IN 'D' TO CONSOLE IN HEX
;*
WRHEXW
        BSR     WRHEX                             ;OUTPUT
        EXG     A,B                               ;SWAP
        BSR     WRHEX                             ;OUTPUT
        EXG     A,B                               ;BACK
        RTS
;*
;* WRITE MESSAGE, NO CARRIAGE RETURN AT END
;*
WRLIN
        PSHS    X                                 ;SAVE X
        LDX     2,S                               ;GET ADDRESS BACK
        BSR     WRSTR                             ;OUTPUT
        STX     2,S                               ;RESAVE
        ORCC    #%00000100                        ;ZERO RETURN CODE
        PULS    X,PC
;*
;* OUTPUT 'A' NUMBER TO CONSOLE IN HEX
;*
WRHEX
        PSHS    A                                 ;SAVE IT
        LSRA                                      ;SHIFT
        LSRA                                      ;HIGH NIBBLE
        LSRA                                      ;INTO
        LSRA                                      ;LOW NIBBLE
        BSR     HOUT                              ;HIGH
        LDA     ,S                                ;GET LOW
        BSR     HOUT                              ;OUTPUT
        PULS    A,PC                              ;RESTORE IT
;* OUTPUT NIBBLE IN HEX
HOUT
        ANDA    #%00001111                        ;REMOVE HIGH
        ADDA    #'0'                              ;CONVERT
        CMPA    #'9'                              ;OK?
        BLS     PUTCHR                            ;OK, OUTPUT
        ADDA    #7                                ;CONVERT TO 'A'-'F'
        BRA     PUTCHR                            ;OUTPUT
;*
;* WRITE STRING(X) TO CONSOLE
;*
WRSTR
        PSHS    A                                 ;SAVE A
WRST1
        LDA     ,X+                               ;GET CHAR
        BEQ     WRST2                             ;END, QUIT
        BSR     PUTCHR                            ;OUTPUT
        BRA     WRST1                             ;CONTINUE
;*
;* OUTPUT MESSAGE TO CONSOLE
;*
WRMSG
        PSHS    X                                 ;SAVE X
        LDX     2,S                               ;GET RETURN ADDRESS
        BSR     WRSTR                             ;OUTPUT STRING
        STX     2,S                               ;RESAVE NEW RETURN ADDR
        PULS    X                                 ;RESTORE X
;*
;* OUTPUT LFCR TO CONSOLE
;*
LFCR
        PSHS    A                                 ;SAVE IT
        LDA     #$0A                              ;GET LF
        BSR     PUTCHR                            ;OUTPUT
        LDA     #$0D                              ;GET CR
        BRA     SPC1                              ;CONTINUE
;*
;* OUTPUT SPACE TO CONSOLE
;*
SPACE
        PSHS    A                                 ;SAVE ACCA
        LDA     #' '                              ;GET SPACE
SPC1
        BSR     PUTCHR                            ;OUTPUT
WRST2
        PULS    A,PC                              ;RESTORE
;*
;* WRITE CHARACTER(A) TO CONSOLE DEVICE
;*
PUTCHR
        PSHS    A,B,X                             ;SAVE REGS
        LDB     >CONOUT                           ;GET CONSOLE OUTPUT DEVICE
        BRA     WRDEV1                            ;PROCEDE WITH OUTPUT
;*
;* WRITE CHARACTER(A) TO DEVICE(B)
;*
WRDEV
        PSHS    A,B,X                             ;SAVE REGS
WRDEV1
        CMPB    #NDEV                             ;CHECK FOR IN RANGE
        BHS     BADDEV                            ;INDICATE INVALID
        LDX     #DOTAB                            ;POINT TO STATUS TABLE
        ASLB                                      ;X2 FOR TWO BYTE ENTRIES
        LDX     B,X                               ;GET DEVICE DRIVER ADDRESS
        BEQ     BADDEV                            ;INDICATE INVALID DEVICE
        JSR     ,X                                ;EXECUTE OUTPUT DRIVER
        CLRA                                      ;ZERO RETURN CODE
        PULS    A,B,X,PC                          ;RESTORE & RETURN
;*
;* BAD DEVICE SPECIFIED
;*
BADDEV
        LDX     #DEVMSG                           ;POINT TO DEVICE MESSAGE
        LDA     #RCDEV                            ;BAD DEVICE RETURN CODE
        JMP     ERRMRC                            ;EXIT WITH ERROR
;*
;* READ A CHARACTER FROM DEVICE (B)
;*
RDDEV
        BSR     TSTDEV                            ;TEST FOR CHAR
        BNE     RDDEV                             ;WAIT FOR IT
        RTS
;*
;* TEST FOR CHARACTER FROM DEVICE(B)
;*
TSTDEV
        PSHS    B,X                               ;SAVE REGS
TSTDE1
        CMPB    #NDEV                             ;DEVICE IN RANGE?
        BHS     BADDEV                            ;INDICATE INVALUD
        LDX     #DITAB                            ;POINT TO STATUS TABLE
        ASLB                                      ;X2 FOR TWO BYTE ENTRIES
        LDX     B,X                               ;GET DEVICE DRIVER ADDRESS
        BEQ     BADDEV                            ;INDICATE INVALID
        JSR     ,X                                ;EXECUTE INPUT DRIVER
        PULS    B,X,PC                            ;RESTORE & RETURN
;*
;* TEST FOR A CHARACTER FROM THE CONSOLE DEVICE
;*
TSTCHR
        PSHS    B,X                               ;SAVE REGS
        LDB     >CONIN                            ;GET INPUT DEVICE
        BRA     TSTDE1                            ;AND CONTINUE
;*
;* READ A CHARACTER FROM CONSOLE
;*
GETCHR
        BSR     TSTCHR                            ;TEST FOR CHAR
        BNE     GETCHR                            ;INDICATE NONE
        RTS
;*
;* INCLUDE ALL OTHER SUB-SYSTEMS
;*
        INCLUDE filesys.os                        ;FILE SYSTEM MANAGMENT
        INCLUDE command.os                        ;INTERNAL COMMANDS
        INCLUDE comfile.os                        ;BATCH FILE PROCESSOR
;*
;* MISC SYSTEM CALLS
;*
;* QUERY CONSOLE INPUT DEVICE
REDIN
        LDA     >CONIN                            ;LOAD DEVICE INPUT VECTOR
        BRA     RETZ                              ;RETURN SUCCESS
;* QUERY CONSOLE OUTPUT DEVICE
REDOUT
        LDA     >CONOUT                           ;LOAD DEVICE OUTPUT VECTOR
        BRA     RETZ                              ;RETURN SUCCESS
;* SET CONSOLE INPUT DEVICE
SETIN
        PSHS    B                                 ;SAVE REGISTER
        LDB     >CONIN                            ;LOAD OLD INPUT DEVICE
        STA     >CONIN                            ;SAVE NEW INPUT DEVICE
        BRA     REEXG                             ;SWAP & RETURN
;* SET CONSOLE OUTPUT DEVICE
SETOUT
        PSHS    B                                 ;SAVE REGISTER
        LDB     >CONOUT                           ;LOAD OLD OUTPUT DEVICE
        STA     >CONOUT                           ;SAVE NEW OUTPUT DEVICE
REEXG
        TFR     B,A                               ;COPY OLD DEVICE ID TO 'A'
        ORCC    #4                                ;SET 'Z' CODE
        PULS    B,PC                              ;RESTORE & RETURN
;* SELECT DISK DRIVE
SELDRV
        STA     >SDRIVE                           ;SELECT ACTIVE DISK DRIVE
RETZ
        ORCC    #4                                ;SET 'Z' CODE
        RTS
;* QUERY DEVICE VECTOR
QVECT
        PSHS    U                                 ;SAVE REGISTER
        LDU     #DITAB                            ;POINT TO TABLE
        LSLA                                      ;X2 FOR WORD ENTRIES
        LDD     A,U                               ;GET VECTOR
        BRA     RETZ1                             ;AND EXIT
;* SET DEVICE VECTOR
SVECT
        PSHS    U                                 ;SAVE REGISTER
        LDU     #DITAB                            ;POINT TO TABLE
        LSLA                                      ;X2  FOR WORD ENTRIES
        LEAU    A,U                               ;OFFSET TO ENTRY
        LDD     ,U                                ;GET OLD VECTOR VALUE
        STX     ,U                                ;SET NEW VECTOR VALUE
RETZ1
        ORCC    #4                                ;SET 'Z' CODE
        PULS    U,PC                              ;RESTORE & RETURN
GETDRVTBL                                         ;SSR 111-GET DRIVE TABLE
        LDD     #DRIVEMAP
        RTS
GETDRVPTBL                                        ;SSR 112-GET DRIVE PARAMETER TABLE
        LDD     #DCTRL
        RTS
;*
;* PERFORMS 16 BIT MULTIPLICATION (D=X*D)
;*
MUL16
        PSHS    D,X                               ;SAVE PARAMETERS
        LDA     1,S
        LDB     3,S
        MUL
        PSHS    A,B                               ;RESAVE
        LDA     2,S
        LDB     5,S
        MUL
        ADDB    ,S
        STB     ,S
        LDA     3,S
        LDB     4,S
        MUL
        ADDB    ,S
        STB     ,S
        PULS    A,B                               ;GET RESULT
        LEAS    4,S                               ;SKIP CRAP
        RTS
;*
;* PERFORMS 16 BIT DIVISION. (X=X/D, D=REMAINDER)
;*
DIV16
        PSHS    D,X
        LDD     #0
        LDX     #17
DIV1
        ANDCC   #$FE
DIV2
        ROL     3,S
        ROL     2,S
        LEAX    -1,X
        BEQ     DIV3
        ROLB
        ROLA
        CMPD    ,S
        BLO     DIV1
        SUBD    ,S
        ORCC    #1
        BRA     DIV2
DIV3
        LEAS    2,S
        PULS    X,PC
;* DISK DRIVERS
FORMAT
        JSR     [XFORMAT]
HOME
        CLR     CYL,U                             ;CYLINDER 0
        CLR     HEAD,U                            ;HEAD 0
        CLR     SEC,U                             ;SECTOR 0
        JMP     [XHOME]
RDSEC
        JMP     [XRDSEC]
WRSEC
        JMP     [XWRSEC]
;* INTERRUPT HANDLERS
SWI
        JMP     [SWIVEC]
SWI2
        JMP     [SWI2VEC]
SWI3
        JMP     [SWI3VEC]
IRQ
        JMP     [IRQVEC]
FIRQ
        JMP     [FIRQVEC]
NMI
        JMP     [NMIVEC]
;* STRINGS & MESSAGES
IPLFILE
        FCC     'STARTUP.*'
        FCB     $00
UNCMD
        FCC     'Unrecognized command'
        FCB     $00
BADOPM
        FCC     'Operand missing or invalid'
        FCB     $00
NOTMSG
        FCC     'File not found'
        FCB     $00
EXIMSG
        FCC     'File already exists'
        FCB     $00
NOSMSG
        FCC     'Insufficent disk space'
        FCB     $00
OREMSG
        FCC     'File not open for read'
        FCB     $00
OWEMSG
        FCC     'File not open for write'
        FCB     $00
PROMSG
        FCC     'File protection violation'
        FCB     $00
DEVMSG
        FCC     'Invalid device'
        FCB     $00
DNLMSG
        FCC     'Download format error'
        FCB     $00
;* COMMAND NAME TABLE
CMDNAM
        FCB     $84
        FCC     'FORMAT'
        FCB     $82
        FCC     'READ'
        FCB     $82
        FCC     'WRITE'
        FCB     $82
        FCC     'FILES'
        FCB     $82
        FCC     'CREATE'
        FCB     $83
        FCC     'DELETE'
        FCB     $82
        FCC     'LOAD'
        FCB     $82
        FCC     'SAVE'
        FCB     $82
        FCC     'RUN'
        FCB     $82
        FCC     'RETURN'
        FCB     $82
        FCC     'SET'
        FCB     $82
        FCC     'SHOW'
        FCB     $82
        FCC     'DOWNLOAD'
        FCB     $82
        FCC     'CONNECT'
        FCB     $80
;* COMMAND ADDRESS TABLE
CMDADR
        FDB     INIT
        FDB     CREAD
        FDB     CWRITE
        FDB     FILES
        FDB     CREFIL
        FDB     DELFIL
        FDB     LODFIL
        FDB     SAVFIL
        FDB     RUN
        FDB     RETURN
        FDB     SET
        FDB     SHOW
        FDB     DNLD
        FDB     CNCT
NUMCMD          EQU (*-CMDADR)/2                  ;NUMBER OF COMMANDS
;* APPLICATION PROGRAM INTERFACE ADDRESS TABLE
SSRTAB
        FDB     REENT                             ;00-DOS RE-ENTRY
;* PARAM. & LINE INPUT
        FDB     GLINE                             ;01-GET LINE/PROMPT
        FDB     GLFCR                             ;02-GET LINE/NEW LINE
        FDB     GLNOP                             ;03-GET LINE/NO PROMPT
        FDB     SKIP                              ;04-SKIP TO NEXT NON-BLANK, 'Z' IF EOL
        FDB     TSTERM                            ;05-GET CHR(Y+), TEST FOR TERMINATOR
        FDB     GETDEC                            ;06-GET DECIMAL NUMBER
        FDB     GETHEX                            ;07-GET HEX NUMBER
        FDB     GETNUM                            ;08-GET DECIMAL OR HEX VALUE
        FDB     GETNAM                            ;09-GET FILENAME
        FDB     GETVAL                            ;10-GET & INSURE SINGLE FILE
        FDB     GETSNA                            ;11-GET FILENAME/NO TYPE
        FDB     GETSYS                            ;12-GET FILENAME/NO TYPE/DEFAULT SYSTEM
        FDB     GETSDI                            ;13-GET FILENAME/NO TYPE/DEFAULT(X)
        FDB     GETDIR                            ;14-GET DIRECTORY NAME
        FDB     GETDIR1                           ;15-GET DIRECTORY, DEFAULT(X)
        FDB     GETDRV                            ;16-GET DRIVE ID
        FDB     GETATR                            ;17-GET ATTRIBUTES
        FDB     TLOOK                             ;18-TABLE LOOKUP
        FDB     COMNAM                            ;19-COMPARE NAMES
        FDB     VALID                             ;20-TEST FOR VALID AS SINGLE?
;* CONSOLE OUTPUT
        FDB     SPACE                             ;21-OUTPUT SPACE
        FDB     LFCR                              ;22-OUTPUT LFCR
        FDB     WRSTR                             ;23-OUTPUT STRING(X)
        FDB     WRLIN                             ;24-OUTPUT STRING(PC)/NO LFCR
        FDB     WRMSG                             ;25-OUTPUT STRING(PC)/LFCR
        FDB     WRDEC                             ;26-OUTPUT WORD(D) DECIMAL
        FDB     WRHEXW                            ;27-OUTPUT WORD(D) IN HEX
        FDB     WRHEX                             ;28-OUTPUT BYTE(A) IN HEX
        FDB     HOUT                              ;29-OUTPUT NIBBLE(A) IN HEX
        FDB     SHOSAV                            ;30-DISPLAY SAVED FILENAME
        FDB     SHONAM                            ;31-DISPLAY FILENAME(X)
        FDB     SHOTAB                            ;32-SHOW TABLE(X) ENTRY(A)
;* SERIAL DEVICE I/O
        FDB     PUTCHR                            ;33-OUTPUT CHAR(A)
        FDB     GETCHR                            ;34-GET A CHAR
        FDB     TSTCHR                            ;35-TEST FOR CHAR
        FDB     WRDEV                             ;36-OUTPUT CHAR(A) TO DEVICE(B)
        FDB     RDDEV                             ;37-GET CHAR FROM DEVICE(B)
        FDB     TSTDEV                            ;38-TEST FOR CHAR FROM DEV(B)
        FDB     REDIN                             ;39-READ INPUT DEVICE NUMBER
        FDB     REDOUT                            ;40-READ OUTPUT DEVICE NUMBER
        FDB     SETIN                             ;41-SET INPUT DEVICE
        FDB     SETOUT                            ;42-SET OUTPUT DEVICE
;* CANNED ERROR MESSAGES
        FDB     BADOPR                            ;43-OPERAND MISSING OR INVALID
        FDB     NOTFND                            ;44-FILE NOT FOUND
        FDB     PROERR                            ;45-PROTECTION VIOLATION
        FDB     ORERR                             ;46-FILE NOT OPEN FOR READ
        FDB     OWERR                             ;47-FILE NOT OPEN FOR WRITE
        FDB     FEXISTS                           ;48-FILE ALREADY EXISTS
        FDB     NOSPAC                            ;49-INSUFFICENT DISK SPACE
        FDB     BADDEV                            ;50-INVALID DEVICE
        FDB     LODERR                            ;51-DOWNLOAD FORMAT ERROR
        FDB     FILERR                            ;52-ISSUE ERROR MSG(Y) FOR SAVED FILE
;* FILE I/O
        FDB     BLOAD                             ;53-LOAD COMPLETE FILE TO MEMORY
        FDB     BSAVE                             ;54-SAVE COMPLETE FILE FROM MEMORY
        FDB     OPENR                             ;55-OPEN A FILE FOR READ
        FDB     OPENW                             ;56-OPEN A FILE FOR WRITE
        FDB     CLOSE                             ;57-CLOSE A FILE
        FDB     READB                             ;58-READ BLOCK FROM FILE
        FDB     READC                             ;59-READ CHAR FROM FILE
        FDB     WRITEB                            ;60-WRITE A BLOCK TO FILE
        FDB     WRITEC                            ;61-WRITE A CHAR TO FILE
        FDB     REWIND                            ;62-RESET FILE TO BEGINNING
        FDB     SEEKREL                           ;63-SEEK RELATIVE POSITION IN FILE
        FDB     SEEKABS                           ;64-SEEK ABSOLUTE LOCATION IN FILE
        FDB     FTELL                             ;65-RETURN POSITION IN FILE
        FDB     SUSPEND                           ;66-SUSPEND FILE OPERATIONS
        FDB     RESUME                            ;67-RESUME FILE OPERATIONS
;* FILE SYSTEM MAINTAINENCE
        FDB     LOCDIR                            ;68-LOCATE FILE IN DIRECTORY, NO ERROR/MESSAGE
        FDB     LOCERR                            ;69-LOCATE FILE IN DIR/ISSUE ERROR IF NOT FOUND
        FDB     LOCRED                            ;70-LOCATE FILE WITH INTENT TO READ
        FDB     LOCWRI                            ;71-LOCATE FILE WITH INTENT TO WRITE
        FDB     CREATE                            ;72-CREATE A FILE
        FDB     DELETE                            ;73-DELETE A FILE
        FDB     SETDEF                            ;74-SET DEFAULT DIRECTORY
        FDB     SETCMD                            ;75-SET COMMAND DIRECTORY
        FDB     SELDRV                            ;76-SET CURRENT OS DRIVE
        FDB     FNDLNK                            ;77-LOCATE LINK FOR SECTOR
        FDB     LCHAIN                            ;78-LOAD CHAIN OF SECTOR TO MEMORY
        FDB     FRESEC                            ;79-ALLOCATE A FREE SECTOR
        FDB     UNCHAIN                           ;80-RELEASE SECTOR CHAIN
        FDB     DRVSIZ                            ;81-CALCULATE SIZE OF DISK(A)
        FDB     CURSIZ                            ;82-CALCULATE SIZE OF CURRENT DISK
        FDB     CALFRE                            ;83-CALCULATE # FREE SECTORS ON DISK
        FDB     RDWRK                             ;84-READ WORK SECTOR INTO DOS
        FDB     CHGWRK                            ;85-INDICATE WORK SECTOR CHANGED
        FDB     WRTST                             ;86-WRITE WORK SECTOR IF UPDATED
        FDB     WRWRK                             ;87-WRITE WORK SECTOR UNCONDITIONALLY
        FDB     PURGE                             ;88-CLEAR WORK SECTOR & FORCE READ
        FDB     GETCTL1                           ;89-GET CONTROL BLOCK
        FDB     GETCTL                            ;90-GET CTRL BLK FOR SELECTED
        FDB     SECTOR                            ;91-SET UP CTRL-BLOCK FROM DISK ID
        FDB     RDISK                             ;92-READ SECTOR(D) TO MEM(X) FROM DISK
        FDB     WDISK                             ;93-WRITE SECTOR(D) FROM MEM(X) TO DISK
        FDB     DISDIR                            ;94-DISPLAY DISK DIRECTORY
;* DIRECT DISK ACCESS
        FDB     DOINIT                            ;95-INIT HARDWARE
        FDB     HOME                              ;96-HOME HEAD ON DISK
        FDB     RDSEC                             ;97-READ SECTOR FROM TRACK
        FDB     WRSEC                             ;98-WRITE SECTOR FROM TRACK
        FDB     FORMAT                            ;99-FORMAT DISK
;* MISC DOS ROUTINES
        FDB     EXECMD                            ;100-EXECUTE DOS COMMAND
        FDB     TMPENT                            ;101-TEMPORARY DOS ENTRY
        FDB     QVECT                             ;102-QUERY DEVICE VECTOR
        FDB     SVECT                             ;103-SET DEVICE VECTOR
        FDB     SETFLG                            ;104-SET FLAG
        FDB     CLRFLG                            ;105-CLEAR FLAG
        FDB     SAVPRM                            ;106-SET COMMAND FILE PARAMETERS
        FDB     MUL16                             ;107-16 BIT MULTIPLY (D=X*D)
        FDB     DIV16                             ;108-16 BIT DIVISION (X=X/D, D=REMAINDER)
        FDB     DMPREG                            ;109-DISPLAY REGISTERS
        FDB     DNLDEV                            ;110-DOWNLOAD FROM DEVICE
        FDB     GETDRVTBL                         ;111-GET DRIVE TABLE
        FDB     GETDRVPTBL                        ;112-GET DRIVE PARAMETER TABLE
        IFDEF   6809PC
        FDB     WRESPRAW0                         ;113-WRITE ESP0 value
        FDB     WRESPRAW1                         ;114-WRITE ESP0 value
        FDB     RDESPRAW0                         ;115-READ ESP0 value
        FDB     RDESPRAW1                         ;116-READ ESP1 value
        ENDIF
NUMSSR          EQU (*-SSRTAB)/2                  ;# SSR'S IMPLEMENTED
;*
;* HARDWARE DEPENDANT I/O DRIVERS
;*
        IFDEF   nhyodyne
        INCLUDE ../nhyodyne/drivers.asm
        ENDIF
        IFDEF   duodyne
        INCLUDE ../duodyne/drivers.asm
        ENDIF
        IFDEF   6809PC
        INCLUDE ../6809PC/drivers.asm
        ENDIF

;*
;* INTERRUPT VECTORS
;*
        IFNDEF  test
        ORG     $FFF2                             ;VECTORS GO HERE
        FDB     SWI3
        FDB     SWI2
        FDB     FIRQ
        FDB     IRQ
        FDB     SWI
        FDB     NMI
        FDB     BEGIN                             ;RESET - COLD START OF SYSTEM
        ENDIF
