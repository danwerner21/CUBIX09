;	title	RAID 6809 DEBUGGER
;*
;* RAID: Runtime Aid for Interactive Debugging (6809 debugger)
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
ROM             = OSUTIL-4096                     ;RAID    PROGRAM STORAGE (JUST UNDER UTILS)
RAM=ROM-160                                       ;RAID RAM
STACK=ROM                                         ;SYSTEM STACK (TOP OF RAM)
DDADR=19                                          ;DIRECTORY DISK ADDRESS OFFSET
DRADR=21                                          ;DIRECTORY LOAD ADDRESS
;*
        ORG     RAM                               ;MONITOR RAM
;*
SWIADR
        RMB     2                                 ;SWI VECTOR ADDRESS
DEVICE
        RMB     2                                 ;INPUT VECTOR
SAVCC
        RMB     1                                 ;SAVED CONDITION CODE REGISTER
SAVA
        RMB     1                                 ;SAVED 6809 A REGISTER
SAVB
        RMB     1                                 ;SAVED 6809 B REGISTER
SAVDP
        RMB     1                                 ;SAVED DIRECT PAGE REGISTER
SAVX
        RMB     2                                 ;SAVED X REGISTER
SAVY
        RMB     2                                 ;SAVED Y REGISTER
SAVU
        RMB     2                                 ;SAVED U REGISTER
SAVPC
        RMB     2                                 ;SAVED PROGRAM COUNTER
SAVS
        RMB     2                                 ;SAVED S REGISTER
TEMP
        RMB     2                                 ;TEMPORARY STORAGE
HELD
        RMB     1                                 ;OUTPUT IS HELD
STPFLG
        RMB     1                                 ;REGISTER DISPLAY WHILE STEPPING FLAG
PTRSAV
        RMB     2                                 ;SINGLE STEP AND DISASSEMBLER CODE POINTER
INSTYP
        RMB     1                                 ;DISASSEMBLED INSTRUCTION TYPE
POSBYT
        RMB     1                                 ;POSTBYTE STORAGE AREA
REGIND
        RMB     2                                 ;INDIRECT REGISTER ADDRESS
BRKTAB
        RMB     24                                ;BREAKPOINT TABLE
DSPBUF
        RMB     50                                ;DISASSEMBLER DISPLAY BUFFER
INSRAM
        RMB     7                                 ;INSTRUCTION EXECUTION ADDRESS
;*
        ORG     ROM                               ;MONITOR CODE
;*
;* INITIALIZATIONS
;*
RAID
        CMPA    #'?'                              ;QUERY OPERAND?
        BNE     RAID1                             ;NO, ITS OK
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'Use: RAID[/<device] [<load file> [<operands>]]'
        RTS
RAID1
        LDS     #STACK                            ;SET UP STACK
        LDX     #SAVCC                            ;POINT TO START
RAID2
        CLR     ,X+                               ;CLEAR IT
        CMPX    #DSPBUF                           ;AT BUFFER?
        BLO     RAID2                             ;KEEP GOING
        LDD     #RAM                              ;DEFAULT STACK AT TOP OF RAM
        STD     SAVS                              ;SAVE IT
        LDA     #$D0                              ;SET CC
        STA     SAVCC                             ;SAVE IT
;* GET RAID CONSOLE DEVICE
        SWI
        FCB     39                                ;GET CONSOLE DEVICE
        STA     >DEVICE                           ;SET IT
        LDA     ,Y                                ;GET CHAR
        CMPA    #'/'                              ;QUALIFIER?
        BNE     NOQUAL                            ;NO, ITS OK
        LEAY    1,Y                               ;ADVANCE
        SWI
        FCB     6                                 ;GET NUMBER
        LBNE    ABORT                             ;INVALID, EXIT
        ANDB    #7                                ;INSURE IN RANGE
        STB     >DEVICE                           ;SAVE IT
;* IF A FILE IS SPECIFIED, LOAD IT
NOQUAL
        SWI
        FCB     4                                 ;MORE PARMS?
        BEQ     NOPARM                            ;NO, ITS OK
        SWI
        FCB     10                                ;GET FILENAME
        LBNE    ABORT                             ;ERROR
        SWI
        FCB     70                                ;LOOK IT UP
        LBNE    ABORT                             ;ERROR
        LDD     DDADR,X                           ;GET DISK ADDRESS
        LDX     DRADR,X                           ;GET RUN ADDRESS
        STX     >SAVPC                            ;PT TO IT
        SWI
        FCB     78                                ;LOAD FILE IN
        LBNE    ABORT                             ;ERROR
        LBSR    WRMSG                             ;MESSAGE
        FCN     'Loaded at $'
        LDD     >SAVPC                            ;GET ADDR BACK
        LBSR    WRDOUT                            ;OUTPUT
        LBSR    LFCR                              ;NEW LINE
NOPARM
        STY     >SAVY                             ;SAVE PTR
;* PATCH INTO DOS FOR VECTORS
        LDX     #SWIHND                           ;POINT TO HANDLER
        LDA     #20                               ;SWI VECTOR
        SWI
        FCB     103                               ;SET IT
        STD     >SWIADR                           ;SAVE OLD HANDLER ADDRESS
MAIN
        LDS     #STACK                            ;FIX STACK IN CASE ERROR
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCN     'Raid> '
        LBSR    GETECH                            ;GET CHARACTER
        LBSR    SPACE                             ;OUTPUT SPACE
        LDX     #CMDTAB                           ;LOOK UP COMMANDS
LKCMD
        CMPA    ,X+                               ;IS THIS IT
        BEQ     CFOUND                            ;YES
        LEAX    2,X                               ;SKIP ADDRESS
        TST     ,X                                ;HIT END?
        BNE     LKCMD                             ;NO, KEEP LOOKING
;* ERROR HAS OCCURED
ERROR
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCC     ' ?'
        FCB     $0D
        BRA     MAIN                              ;TRY AGAIN
;* COMMAND WAS FOUND
CFOUND
        JSR     [,X]                              ;EXECUTE CODE
        BRA     MAIN                              ;AND TRY AGAIN
;* COMMAND LOOKUP TABLE
CMDTAB
        FCB     'M'                               ;DISPLAY MEMORY
        FDB     MEMORY                            ;ADDRESS OF HANDLER
        FCB     'E'                               ;SUBSTITUTE MEMORY
        FDB     SUBMEM
        FCB     'Q'                               ;EXIT DEBUGGER
        FDB     QUIT
        FCB     'D'                               ;DISASSEMBLE
        FDB     DISASM
        FCB     'R'                               ;DISPLAY REGISTERS
        FDB     DISREG
        FCB     'C'                               ;CHANGE REGISTER
        FDB     CHGREG
        FCB     'V'                               ;VIEW BREAKPOINTS
        FDB     DSPBRK
        FCB     'B'                               ;SET BREAKPOINT
        FDB     SETBRK
        FCB     'S'                               ;STEP
        FDB     GOSTEP
        FCB     'G'                               ;GO
        FDB     GOEXEC
        FCB     0                                 ;MARK END OF TABLE
;*
;* 'Q'UIT & RETURN TO OS
;*
QUIT
        LBSR    LFCR                              ;NEW LINE
        LDX     >SWIADR                           ;GET VECTOR
        LDA     #20                               ;SWI VECTOR
        SWI
        FCB     103                               ;SET IT
        CLRA
ABORT
        SWI
        FCB     0
;*
;* 'M'EMORY COMMAND, DISPLAY MEMORY
;*
MEMORY
        LBSR    GETRNG                            ;GET ADDRESS
        BNE     ERROR                             ;INVALID
        STD     TEMP                              ;SAVE
MEM1
        LBSR    LFCR                              ;NEW LINE
        LBSR    CHKCHR                            ;CHECK FOR CHAR
        LBEQ    MAIN                              ;ESCAPE, QUIT
        TFR     X,D                               ;GET ADDRESS
        PSHS    A,B                               ;SAVE FOR LATER
        LBSR    WRDOUT                            ;DISPLAY
        LDB     #16                               ;DISPLAY 16 TO A LINE
MEM2
        LBSR    SPACE                             ;OUTPUT A SPACE
        BITB    #3                                ;ON A BOUNDARY?
        BNE     MEM3                              ;NO, SPACE
        LBSR    SPACE                             ;EXTRA SPACE
MEM3
        LDA     ,X+                               ;GET BYTE
        LBSR    HEXOUT                            ;DISPLAY
        DECB                                      ;	REDUCE COUNT
        BNE     MEM2                              ;CONTINUE
        LDB     #4                                ;FOUR SPACE
MEM4
        LBSR    SPACE                             ;DISPLAY A SPACE
        DECB                                      ;	REDUCE COUNT
        BNE     MEM4                              ;CONTINUE
        PULS    X                                 ;RESTORE X
        LDB     #16                               ;COUNT OF 16
MEM5
        LDA     ,X+                               ;GET CHAR
        CMPA    #' '                              ;<SPACE
        BLO     MEM6                              ;CONVERT TO DOT
        CMPA    #$7F                              ;PRINTABLE?
        BLO     MEM7                              ;OK TO DISPLAY
MEM6
        LDA     #'.'                              ;CHANGE TO DOT
MEM7
        LBSR    PUTCHR                            ;OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     MEM5                              ;DISPLAY THEM ALL
        CMPX    TEMP                              ;PAST END?
        BLS     MEM1                              ;NO, KEEP GOING
        LBRA    LFCR                              ;NEW LINE
;*
;* 'E'DIT MEMORY COMMAND
;*
SUBMEM
        LBSR    GETADR                            ;GET ADDRESS
        LBNE    ERROR                             ;INVALID
        TFR     D,X                               ;COPY
SUBM1
        LBSR    LFCR                              ;NEW LINE
        TFR     X,D                               ;GET ADDRESS
        LBSR    WRDOUT                            ;OUTPUT
        LDB     #8                                ;NEW COUNT
SUBM2
        LBSR    SPACE                             ;SEPERATOR
        LDA     ,X                                ;GET BYTE
        LBSR    HEXOUT                            ;DISPLAY
        LDA     #'-'                              ;PROMPT
        LBSR    PUTCHR                            ;OUTPUT
        LBSR    GETBYT                            ;GET A BYTE
        BNE     SUBM4                             ;INVALID
        STA     ,X                                ;RESAVE
SUBM3
        LEAX    1,X                               ;ADVANCE
        DECB                                      ;	REDUCE COUNT
        BNE     SUBM2                             ;MORE, CONTINUE
        BRA     SUBM1                             ;NEW LINE
SUBM4
        CMPA    #$0D-$37	CR?
        LBEQ    LFCR                              ;IF SO, QUIT
        CMPA    #' '-$37	SPACE?
        BNE     SUBM5                             ;NO
        LBSR    SPACE                             ;FILL FOR TWO DIGITS
        BRA     SUBM3                             ;ADVANCE
SUBM5
        CMPA    #$08-$37	BACKSPACE?
        LBNE    ERROR                             ;INVALID
        LEAX    -1,X                              ;BACKUP
        BRA     SUBM1                             ;NEW LINE
;*
;* 'D'ISASSEMBLE MEMORY COMMAND
;*
DISASM
        LBSR    GETRNG                            ;GET ADDRESS
        LBNE    ERROR                             ;INVALID, QUIT
        TFR     X,Y                               ;COPY TO Y
        STD     TEMP                              ;SAVE
        LBSR    LFCR                              ;NEW LINE
        LDU     #DSPBUF                           ;POINT TO INPUT BUFFER
DISS1
        LBSR    DISASS                            ;DISASSEMBLE
        TFR     U,X                               ;COPY
        LBSR    WRLIN                             ;OUTPUT
        LBSR    CHKCHR                            ;END?
        BEQ     DISS2                             ;YES, QUIT
        CMPY    TEMP                              ;OVER?
        BLO     DISS1                             ;TRY AGAIN
DISS2
        RTS
;*
;* 'R'EGISTER DISPLAY COMMAND
;*
DISREG
        LDX     #REGTXT                           ;POINT TO TEXT
        LDY     #SAVCC                            ;POINT TO VALUE
        BSR     RSUB1                             ;'CC='
        LBSR    WRLIN                             ;' ['
        LDU     #CCBITS                           ;POINT TO BIT TABLE
        LDB     -1,Y                              ;GET BITS BACK
        PSHS    Y                                 ;SAVE POINTER
        LDY     #8                                ;EIGHT BITS IN BYTE
REGB1
        LDA     ,U+                               ;GET BIT IDENTIFIER
        ASLB                                      ;	IS IT SET?
        BCS     RBITS                             ;YES, DISPLAY IT
        LDA     #'-'                              ;NO, DISPLAY DASH
RBITS
        LBSR    PUTCHR                            ;OUTPUT A CHARACTER
        LEAY    -1,Y                              ;REDUCE COUNT
        BNE     REGB1                             ;MORE TO GO
        PULS    Y                                 ;RESTORE Y
        BSR     RSUB1                             ;'] A='
        BSR     RSUB1                             ;' B='
        BSR     RSUB1                             ;' DP='
        BSR     RSUB2                             ;' X='
        BSR     RSUB2                             ;' Y='
        BSR     RSUB2                             ;' U='
        BSR     RSUB2                             ;' PC='
        BSR     RSUB2                             ;' S='
        LBRA    LFCR                              ;QUIT
;* DISPLAY 8 BIT REGISTER VALUE
RSUB1
        LBSR    WRLIN                             ;OUTPUT BYTE VALUE
        LDA     ,Y+                               ;GET REGISTER VALUE
        LBRA    HEXOUT                            ;OUTPUT IN HEX
;* DISPLAY 16 BIT REGISTER VALUE
RSUB2
        LBSR    WRLIN                             ;OUTPUT WORD VALUE
        LDD     ,Y++                              ;GET REGISTER VALUE
        LBRA    WRDOUT                            ;OUTPUT IN HEX
;* TABLE OF TEXT FOR REGISTER DISPLAY
REGTXT
        FCN     'CC='
        FCN     ' ['
        FCN     '] A='
        FCN     ' B='
        FCN     ' DP='
        FCN     ' X='
        FCN     ' Y='
        FCN     ' U='
        FCN     ' PC='
        FCN     ' S='
;* TABLE OF CONDITION CODE BIT MEANINGS
CCBITS
        FCC     'EFHINZVC'
;*
;* 'C'HANGE REGISTER COMMAND
;*
CHGREG
        LBSR    GETECH                            ;GET OPERAND
        CMPA    #' '                              ;A+B?
        BEQ     CHG4                              ;YES
        LDX     #CHGTAB                           ;POINT TO TABLE
        CLRB                                      ;	ZERO INDICATOR
CHG1
        CMPA    ,X                                ;IS THIS IT?
        BEQ     CHG2                              ;YES
        INCB                                      ;	ADVANCE COUNT
        TST     ,X+                               ;END OF TABLE
        BNE     CHG1                              ;NO, KEEP TRYING
        LBRA    ERROR                             ;INDICATE ERROR
CHG2
        LBSR    SPACE                             ;OUTPUT SPACE
        LDX     #SAVCC                            ;POINT TO START OF REGISTERS
        CMPB    #4                                ;16 BIT?
        BHS     R16                               ;YES
        LEAX    B,X                               ;OFFSET TO ADDRESS
        LBSR    GETBYT                            ;GET NEW VALUE
        LBNE    ERROR                             ;INVALID
        STA     ,X                                ;SAVE IN REGISTER
        BRA     CHG3                              ;AND QUIT
CHG4
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCN     '[AB] '
        LDX     #SAVA                             ;POINT TO 'D'
        BRA     R17                               ;MAKE LIKE 16 BIT REG
R16
        LEAX    4,X                               ;OFFSET TO 16 BIT REGISTERS
        SUBB    #4                                ;CONVERT TO ZERO ORIGIN
        ASLB                                      ;	DOUBLE FOR WORD VALUES
        LEAX    B,X                               ;MOVE TO CORRECT OFFSET
R17
        LBSR    GETADR                            ;GET WORD VALUE
        LBNE    ERROR                             ;INVALID
        STD     ,X                                ;SET REGISTER VALUE
CHG3
        LBRA    LFCR                              ;QUIT
;* TABLE OF REGISTER NAMES
CHGTAB
        FCN     'CABDXYUPS'
;*
;* 'V'IEW BREAKPOINTS
;*
DSPBRK
        LDA     #'0'                              ;START WITH BRKPT ZERO
        LDX     #BRKTAB                           ;POINT TO TABLE
DSPB1
        PSHS    A                                 ;SAVE NUMBER
        LDA     #'B'                              ;PRECEDE WITH 'B'
        LBSR    PUTCHR                            ;OUTPUT
        LDA     ,S                                ;GET NUMBER BACK
        LBSR    PUTCHR                            ;OUTPUT
        LDA     #'='                              ;AND FOLLOW WITH '='
        LBSR    PUTCHR                            ;OUTPUT
        LDD     ,X++                              ;GET VALUE
        BNE     DSPB2                             ;NON-ZERO, DISPLAY
        LBSR    WRMSG                             ;OUTPUT MESSAGE INSTEAD
        FCN     '****'
        BRA     DSPB3                             ;CONTINUE
DSPB2
        LBSR    WRDOUT                            ;OUTPUT VALUE
DSPB3
        LBSR    SPACE                             ;SEPERATE WITH SPACE
        LEAX    1,X                               ;SKIP OPCODE SAVE
        PULS    A                                 ;RESTORE NUMBER
        INCA                                      ;	ADVANCE
        CMPA    #'8'                              ;BEYOND END?
        BLO     DSPB1                             ;NO, CONTINUE
        LBRA    LFCR                              ;NEW LINE AND QUIT
;*
;* 'B'REAKPOINT COMMAND
;*
SETBRK
        LBSR    GETECH                            ;GET CHARACTER
        SUBA    #'0'                              ;CONVERT TO NUMBER
        CMPA    #8                                ;IN RANGE?
        LBHS    ERROR                             ;NO, QUIT
        PSHS    A                                 ;SAVE NUMBER
        ASLA                                      ;	DOUBLE FOR 16 BIT VALUES
        ADDA    ,S+                               ;TRIPLE FOR OPCODE BYTE
        LDX     #BRKTAB                           ;POINT TO BREAKPOINT TABLE
        LEAX    A,X                               ;ADVANCE TO BREAKPOINT
        LBSR    SPACE                             ;SEPERATE WITH SPACE
        LBSR    GETADR                            ;GET VALUE
        LBNE    ERROR                             ;INVALID
        STD     ,X                                ;SAVE IN TABLE
        LBRA    LFCR                              ;NEW LINE AND QUIT
;*
;* 'S'TEP COMMAND
;*
GOSTEP
        LBSR    GETADR                            ;GET ADDRESS
        BEQ     GOS1                              ;ADDRESS SUPPLIED, GO
        CMPA    #' '-$37	WAS IT SPACE?
        LBNE    ERROR                             ;NO, ERROR
        BRA     GOS2                              ;CONTINUE
GOS1
        STD     SAVPC                             ;SAVE NEW ADDRESS
GOS2
        LBSR    LFCR                              ;OUTPUT MESSAGE
GOSTP1
        LBSR    STEPDI                            ;STEP AND DISPLAY INSTRUCTION
        TST     STPFLG                            ;DISPLAY REGISTERS?
        BMI     NODSR                             ;NO, DON'T DISPLAY
STPREG
        LBSR    DISREG                            ;DISPLAY REGISTERS
NODSR
        LBSR    GETCHR                            ;GET KEY FROM TERMINAL
        CMPA    #'?'                              ;DISPLAY REGS?
        BEQ     STPREG                            ;IF SO, DISPLAY
        CMPA    #' '                              ;STEP TO NEXT?
        BEQ     GOSTP1                            ;IF SO, STEP
        CMPA    #$1B                              ;EXIT STEPPING?
        BEQ     GOSTP2                            ;IF SO, QUIT
        CMPA    #$0D                              ;TOGGLE REGISTER DISPLAY?
        BNE     NODSR                             ;IF NOT, IGNORE
        COM     STPFLG                            ;TOGGLE DISPLAY FLAG
        BRA     NODSR                             ;GET NEXT KEY
GOSTP2
        RTS
;*
;* 'G'O COMMAND
;*
GOEXEC
        LBSR    GETADR                            ;GET ADDRESS FROM TERMINAL
        BEQ     GOEX1                             ;IF ENTERED, EXECUTE THERE
        CMPA    #' '-$37	WAS IT SPACE?
        BEQ     GOEX2                             ;YES, CONTINUE FROM LAST PC
        LBRA    ERROR                             ;INVALID KEY, ABORT
GOEX1
        STD     SAVPC                             ;SAVE NEW PROGRAM COUNTER
GOEX2
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCN     ' ->$'
        LDD     SAVPC                             ;GET PC ADDRESS
        LBSR    WRDOUT                            ;DISPLAY ON TERMINAL
        LBSR    LFCR                              ;NEW LINE
;* STEP ONE INST. BEFORE INSERTING BREAKPOINTS, SO THAT BREAKPOINTS
;* CAN BE USED WITHIN LOOPS ETC
        LBSR    STEP                              ;STEP ONE INSTRUCTION
;* INSERT BREAKPOINTS
        LDX     #BRKTAB                           ;POINT TO BREAKPOINT TABLE
        LDB     #8                                ;EIGHT BREAKPOINTS
GOEX3
        LDY     ,X++                              ;GET BREAKPOINT ADDRESS
        BEQ     GOEX4                             ;NO BREAKPOINT, QUIT
        LDA     ,Y                                ;GET OPCODE
        STA     ,X                                ;SAVE IN TABLE
        LDA     #$3F                              ;GET 'SWI' BREAKPOINT OPCODE
        STA     ,Y                                ;SAVE IN CODE SPACE
GOEX4
        LEAX    1,X                               ;ADVANCE TO NEXT IN TABLE
        DECB                                      ;	REDUCE COUNT OF BRKPTS
        BNE     GOEX3                             ;DO ALL EIGHT
        LDS     SAVS                              ;RESTORE STACK POINTER
        LDA     SAVCC                             ;GET SAVED CC
        LDB     SAVDP                             ;GET SAVED DPR
        PSHS    A,B                               ;SAVE ON STACK FOR LAST RESTORE
        LDD     SAVA                              ;RESTORE A, B REGISTERS
        LDX     SAVX                              ;RESTORE X REGISTER
        LDY     SAVY                              ;RESTORE Y REGISTER
        LDU     SAVU                              ;RESTORE U REGISTER
        PULS    CC,DP                             ;RESTORE CC + DP
        JMP     [SAVPC]                           ;EXECUTE USER PGM
;*
;* GETS A RANGE OF ADDRESS, RETURNS WITH START IN X, END IN D
;*
GETRNG
        BSR     GETADR                            ;GET FIRST
        BNE     GRGRTS                            ;INDICATE INVALID
        TFR     D,X                               ;SAVE
        LDA     #','                              ;GET COMMA
        LBSR    PUTCHR                            ;OUTPUT
        BSR     GETADR                            ;GET ADDRESS
        BEQ     GRGRTS                            ;RANGE IS OK
        CMPA    #' '-$37	SPACE?
        BNE     GRGRTS                            ;NO, INVALID
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCN     'FFFF'
        LDD     #$FFFF                            ;ASSUME TOP OF RAM
        ORCC    #4                                ;INDICATE OK
GRGRTS
        RTS
;*
;* GETS AN ADDRESS (IN D) FROM THE INPUT DEVICE
;*
GETADR
        BSR     GETBYT                            ;GET A BYTE
        BNE     GETB1                             ;INVALID
        TFR     A,B                               ;COPY FOR LATER
        BSR     GETBYT                            ;GET NEXT BYTE
        BNE     GETB1                             ;INVALID
        EXG     A,B                               ;PUT HIGH FIRST
        RTS
;*
;* GETS A SINGLE BYTE (IN HEX) FROM THE INPUT DEVICE
;*
GETBYT
        BSR     GETNIB                            ;GET NIBBLE
        BNE     GETB3                             ;BAD
        ASLA                                      ;	ROTATE
        ASLA                                      ;	INTO
        ASLA                                      ;	HIGH
        ASLA                                      ;	NIBBLE
        PSHS    A                                 ;SAVE
        BSR     GETNIB                            ;GET NIBBLE
        BNE     GETB2                             ;INVALID
        ORA     ,S+                               ;INSERT HIGH
GETB4
        ORCC    #$04                              ;SET 'Z' FLAG
        RTS
GETB2
        LEAS    1,S                               ;SKIP SAVED NAME
GETB1
        RTS
GETB3
        CMPA    #$27-$37	SINGLE QUOTE?
        BNE     GETB1                             ;NO, ABORT
        LBSR    GETCHR                            ;GET A CHARACTER
        LBSR    PUTCHR                            ;ECHO ON TERM
        BRA     GETB4                             ;INDICATE OK, AND RETURN
;*
;* GETS A SINGLE HEX NIBBLE FROM THE INPUT DEVICE
;*
GETNIB
        LBSR    GETECH                            ;GET CHAR
        SUBA    #'0'                              ;CONVERT
        CMPA    #9                                ;NUMERIC?
        BLS     GETN1                             ;YES, OK
        SUBA    #7                                ;CONVERT TO ALPHA
        CMPA    #$A                               ;UNDER?
        BLO     GETN2                             ;YES, BAD
        CMPA    #$F                               ;OVER?
        BHI     GETN2                             ;INDICATE BAD
GETN1
        ORCC    #$04                              ;SET 'Z' FLAG, INDICATE OK
        RTS
GETN2
        ANDCC   #$FB                              ;CLEAR 'Z' FLAG, INDICATE INVALID
        RTS
;*
;* OUTPUT A WORD (IN HEX) FROM REGISTER D
;*
WRDOUT
        BSR     HEXOUT                            ;OUTPUT FIRST BYTE
        TFR     B,A                               ;COPY
;*
;* OUTPUT A BYTE (IN HEX) FROM REGISTER A
;*
HEXOUT
        PSHS    A                                 ;SAVE
        LSRA                                      ;	ROTATE
        LSRA                                      ;	UPPER NIBBLE
        LSRA                                      ;	INTO
        LSRA                                      ;	LOWER
        BSR     HOUT                              ;OUTPUT
        PULS    A                                 ;RESTORE
;*
;* OUTPUT A NIBBLE (IN HEX) FROM REGISTER A
;*
HOUT
        ANDA    #$0F                              ;REMOVE OTHER HALF
        ADDA    #'0'                              ;CONVERT TO PRINTABLE
        CMPA    #'9'                              ;IS IT IN RANGE?
        BLS     HOUT1                             ;YES, ITS OK
        ADDA    #7                                ;CONVERT TO ALPHA
HOUT1
        BRA     PUTCHR                            ;OUTPUT CHARACTER
;*
;* WRITE ERROR MESSAGE FOLLOWING TEXT
;*
WRMSG
        PSHS    X                                 ;SAVE X
        LDX     2,S                               ;GET OLD PC
        BSR     WRLIN                             ;OUTPUT LINE
        STX     2,S                               ;UPDATE OLD PC
        PULS    X,PC                              ;RESTORE X, RETURN
;*
;* DISPLAY MESSAGE(X)
;*
WRLIN
        LDA     ,X+                               ;GET CHAR FROM MESSAGE
        BEQ     WRLND                             ;END, QUIT
        CMPA    #$0D                              ;CR?
        BEQ     LFCR                              ;IF SO, NEW LINE, RETURN
        BSR     PUTCHR                            ;OUTPUT TO TERM
        BRA     WRLIN                             ;KEEP GOING
WRLND
        RTS
;*
;* GET CHAR. FROM TERMINAL, AND ECHO
;*
GETECH
        LBSR    GETCHR                            ;GET CHARACTER
        CMPA    #' '                              ;SPACE?
        BLO     WRLND                             ;IF < DON'T DISPLAY
        CMPA    #$61                              ;LOWER CASE?
        BLO     PUTCHR                            ;OK
        ANDA    #$5F                              ;CONVERT TO UPPER
        BRA     PUTCHR                            ;ECHO
;*
;* DISPLAY A SPACE ON THE TERMINAL
;*
SPACE
        PSHS    A                                 ;SAVE A
        LDA     #' '                              ;GET SPACE
        BRA     LFC1                              ;DISLAY AND GO HOME
;*
;* DISPLAY LINE-FEED, CARRIAGE RETURN ON TERMINAL
;*
LFCR
        PSHS    A                                 ;SAVE
        LDA     #$0A                              ;GET LF
        BSR     PUTCHR                            ;OUTPUT
        LDA     #$0D                              ;GET CR
LFC1
        BSR     PUTCHR                            ;OUTPUT
        PULS    A,PC                              ;RESTORE AND GO HOME
;*
;* WRITE A CHARACTER TO ALL ENABLED OUTPUT DEVICES
;*
PUTCHR
        LBRA    WRCON
;*
;* CHECK FOR <ESC> FROM TERMINAL. ALSO PERFORM <LF>, <CR>
;* SCREEN OUTPUT FLOW CONTROL
;*
CHKCHR
        LDB     HELD                              ;GET I/O CONFIG
        BNE     CHKC1                             ;ALREADY HELD
        LBSR    RDCON                             ;READ TERMINAL
        CMPA    #$0A                              ;LINE-FEED?
        BNE     CHKC3                             ;NO, IGNORE IT
CHKC1
        LBSR    GETCHR                            ;GET KEY FROM CONSOLE
        LDB     #$FF
        CMPA    #$0A                              ;LF?
        BEQ     CHKC2                             ;YES, ALLOW
        CLRB                                      ;	DISABLE HELD BIT
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BEQ     CHKC2                             ;ALLOW
        CMPA    #$1B                              ;ESCAPE?
        BNE     CHKC1                             ;NO, IGNORE
CHKC2
        STB     HELD                              ;RESAVE I/O CONFIG BYTE
CHKC3
        CMPA    #$1B                              ;TEST FOR ESCAPE CHARACTER
        RTS
;*
;* STEP ONE INSTRUCTION
;*
STEPDI
        LDY     SAVPC                             ;GET PC
        LDU     #DSPBUF                           ;GET INPUT BUFFER
        LBSR    DISASS                            ;DISPLAY
        LDX     #DSPBUF                           ;POINT TO IT
        LBSR    WRLIN                             ;DISPLAY
        BRA     STEPCE                            ;AND PERFORM STEP
;*
;* STEP WITHOUT DISPLAYING INSTRUCTION
;*
STEP
        LDY     SAVPC                             ;GET PROGRAM COUNTER
        LDU     #DSPBUF                           ;POINT TO FREE RAM FOR DISASEMBLY OUTPUT
        LBSR    DISASS                            ;PERFROM DISASSEMBLY
STEPCE
        STY     SAVPC                             ;SAVE NEW PC
        LDU     PTRSAV                            ;GET POINTER BACK
        LDD     ,U+                               ;GET OPCODE
;* TEST FOR LONG CONDITIONAL BRANCHES
LCBRAN
        CMPA    #$10                              ;PREFIX?
        BNE     LOBRAN                            ;NO, GOT FOR IT
        LDB     ,U                                ;GET OPCODE
        CMPB    #$22                              ;IN RANGE?
        BLO     LOBRAN                            ;NO
        CMPB    #$2F                              ;IN RANGE?
        BHI     LOBRAN                            ;NO
        LDA     ,U+                               ;GET OPCOIDE BYTE
        LBSR    TSTCON                            ;TEST CONDITIONAL
        BEQ     LBRAN1                            ;YES, DO IT
        RTS
;* TEST FOR LONG BRANCHES
LOBRAN
        CMPA    #$16                              ;IS IT LBRA?
        BNE     LBRANS                            ;NO, TRY LBSR
LBRAN1
        LDD     ,U++                              ;GET OFFSET
        LEAX    D,U                               ;PERFORM BRANCH
        BRA     SAVNPC                            ;SAVE NEW PC
;* TEST FOR LONG BRANCH TO SUB
LBRANS
        CMPA    #$17                              ;'LBSR'?
        BNE     SCOBRA                            ;NO, TRY SHORT CONDITIONALS
        LDD     ,U++                              ;GET OFFSET
        LEAX    D,U                               ;SET UP ADDRESS
        BRA     SAVSTK
;* TEST FOR SHORT CONDITIONAL BRANCHES
SCOBRA
        CMPA    #$22                              ;< 'BHI'?
        BLO     SHBRAN                            ;NO, TRY SHORT BRANCHES
        CMPA    #$2F                              ;> 'BLE'?
        BHI     SHBRAN                            ;NO, TRY SHORT BRANCHES
        LBSR    TSTCON                            ;SEE OF CONDITIONAL IS OK
        BEQ     SBRAN1                            ;YES, DO IT
        RTS
;* TEST FOR SHORT BRANCHES
SHBRAN
        CMPA    #$20                              ;SHORT BRANCH?
        BNE     SBRANS                            ;NO, TRY SHORT BRANCH TO SUB
SBRAN1
        LDB     ,U+                               ;GET OFFSET
        LEAX    B,U                               ;EMULATE JUMP
        BRA     SAVNPC                            ;SAVE NEW PC
;* TEST FOR SHORT BRANCH TO SUBROUTINE
SBRANS
        CMPA    #$8D                              ;'BSR'?
        BNE     TSTTFR                            ;NO, TRY TRANSFER
        LDB     ,U+                               ;GET OFFSET
        LEAX    B,U                               ;PERFORM BRANCH
SAVSTK
        LDY     SAVS                              ;GET STACK POINTER
        STU     ,--Y                              ;PUSH ADDRESS
        STY     SAVS                              ;RESAVE
SAVNPC
        STX     SAVPC                             ;SAVE IT
        RTS
;* TEST FOR TRANSFER
TSTTFR
        CMPA    #$1F                              ;TRANSFER?
        BNE     TSTEXG                            ;NO, TRY EXCHANGE
        BSR     LOKREG                            ;LOOKUP REGISTER
        RTS
;* LOOKUP REGISTER, AND SIMULATE IF PC XFER OR EXCHANGE
LOKREG
        LDA     ,U                                ;GET POSTBYTE
        ANDA    #$0F                              ;REMOVE HIGH REGISTER
        CMPA    #5                                ;IS IT PC?
        BNE     LOK1                              ;NO, IT'S OK TO EXECUTE
        LDA     ,U                                ;GET REG POSTBYTE BACK
        LSRA                                      ;	SHIFT
        LSRA                                      ;	HIGH REGISTER
        LSRA                                      ;	TO LOW (LEAVE X 2)
LOK2
        LDX     #TFREGT                           ;POINT TO TABLE
        ANDA    #$0F                              ;INSURE WE GET VALID REG
        LDX     A,X                               ;GET ADDRESS OF VARIABLE
        LDD     ,X                                ;GET REGISTER VALUE
        BRA     STDPC                             ;SAVE IT
LOK1
        LEAS    2,S                               ;SKIP LAST CALL
        LBRA    NOREXE                            ;EXECUTE NORMAL INSTRUCTION
;* TEST FOR EXCHANGE
TSTEXG
        CMPA    #$1E                              ;IS IT EXCHANGE
        BNE     TSTRTS                            ;NO, TRY RTS
        LDY     SAVPC                             ;GET OLD PC VALUE
        LDA     ,U                                ;GET REGISTER
        ANDA    #$F0                              ;USE HIGH ONLY
        CMPA    #$50                              ;IS PC FIRST?
        BNE     TSTE1                             ;NO, SKIP
        LDA     ,U                                ;GET REG BACK
        LSLA                                      ;	DOUBLE
        BSR     LOK2                              ;GET ADDRESS OF REG TO SWAP WITH
        BRA     TSTE2                             ;PERFORM MOVE TO PC
TSTE1
        BSR     LOKREG                            ;GET REGISTER SEE IF PC IS LOW REGISTER
TSTE2
        STY     ,X                                ;SAVE PC IN REGISTER
        RTS
;* TEST FOR 'RTS' INSTRUCTIONS
TSTRTS
        CMPA    #$39                              ;IS IT 'RTS'
        BNE     TPULS                             ;NO, TRY PULS
        LDU     SAVS                              ;POINT TO STACK
        PULU    A,B                               ;GET DATA
        STU     SAVS                              ;RESAVE SP
STDPC
        STD     SAVPC
        RTS
;* TEST FOR 'PULS' INSTRUCTION
TPULS
        CMPA    #$35                              ;PULLING FROM S?
        BNE     TPULU                             ;NO, TRY PULU
        LDX     SAVS                              ;GET SAVED 'S' REG
        LDY     #PULSTAB	POINT TO TABLE
        BSR     DOPUL                             ;PERFORM PULL
        STX     SAVS                              ;RESAVE NEW 'S' REGISTER
        RTS
;* TEST FOR A 'PULU' INSTRUCTION
TPULU
        CMPA    #$37                              ;IS IT 'PULU'?
        BNE     JSREXT                            ;NO, TRY JSR EXTENDED
        LDX     SAVU                              ;GET SAVED 'U'
        LDY     #PULUTAB	POINT TO TABLE
        BSR     DOPUL                             ;PERFORM PULL
        STX     SAVU                              ;RESAVE 'S'
        RTS
;* PERFORM PUL OPERATIONS
DOPUL
        LDA     ,U                                ;GET POSTBYTE
        LDB     #4                                ;TEST FOR FIRST FOUR BITS (8 BIT REG)
DOPUL1
        DECB                                      ;	DECREMENT COUNT
        LSRA                                      ;	SHIFT
        BCC     DOPUL2                            ;NOTHING, GO AGAIN
        PSHS    A,B                               ;SAVE REGS
        TSTB                                      ;	ARE WE INTO 16 BITS?
        BMI     PUL16                             ;YES, PERFORM 16 BITS
        LDA     ,X+                               ;PULL A BYTE
        STA     [,Y++]                            ;SAVE IN REGISTER
        BRA     DOPUL3                            ;GO AGAIN
PUL16
        LDD     ,X++                              ;GET 16 BIT VALUE
        STD     [,Y++]                            ;SAVE IN REGISTER
DOPUL3
        PULS    A,B                               ;RESTORE
        BRA     DOPUL1                            ;CONTINUE
DOPUL2
        LEAY    2,Y                               ;ADVANCE
        TSTA                                      ;	ARE WE CONE
        BNE     DOPUL1                            ;CONTINUE
        RTS
;* TEST FOR 'JSR' EXTENDED
JSREXT
        CMPA    #$BD                              ;IS IT EXTENDED JSR
        BNE     JMPEXT                            ;NO, TRY JUMP EXTENDED
        BSR     DJMPEX                            ;FAKE JUMP
        BRA     PSHPC                             ;SAVE PC
;* TEST FOR 'JMP' EXTENDED
JMPEXT
        CMPA    #$7E                              ;IS IT JMP EXTENDED?
        BNE     JSRDIR                            ;NO, TRY JMP DIRECT
DJMPEX
        LDD     ,U++                              ;GET ADDRESS
        BRA     STDPC                             ;SAVE IT
;* TEST FOR 'JSR' DIRECT
JSRDIR
        CMPA    #$9D                              ;'JSR' DIRECT PAGE?
        BNE     JMPDIR                            ;NO, TRY JUMP
        BSR     DJMPDI                            ;DO IT
        BRA     PSHPC                             ;SAVE PC
;* TEST FOR 'JMP' DIRECT PAGE
JMPDIR
        CMPA    #$0E                              ;IS IT JUMP DIRECT PAGE?
        BNE     JSRIND                            ;NO, TRY JUMP INDEXED
DJMPDI
        LDB     ,U+                               ;GET LOW ADDRESS
        LDA     SAVDP                             ;GET DIRECT PAGE
        BRA     STDPC                             ;SAVE IT
;* TEST FOR 'JSR' INDEXED
JSRIND
        CMPA    #$AD                              ;IS IT 'JSR' INDEXED?
        BNE     JMPIND                            ;NO
        BSR     DJMPIN                            ;DO IT
PSHPC
        LDX     SAVS                              ;GET ADDRESS
        STU     ,--X                              ;SAVE
        STX     SAVS                              ;RESAVE
        RTS
;* TEST FOR 'JMP' INDEXED
JMPIND
        CMPA    #$6E                              ;IS IT JUMP INDEXED?
        LBNE    NOREXE                            ;NO, TRY JST EXTENDED
;* FIRST POINT Y AT REGISTER INVOLVED
DJMPIN
        LDA     ,U+                               ;GET POSTBYTE
        PSHS    A                                 ;SAVE IT
        ANDA    #$60                              ;MASK OTHER CRAP
        LSRA                                      ;	CONVERT
        LSRA                                      ;	REGISTER
        LSRA                                      ;	INTO INDEX VALUE
        LSRA                                      ;	SHIFT IT OVER
        LDX     #INDTAB                           ;POINT TO TABLE
        LDY     A,X                               ;GET REGISTER ADDRESS
        STY     REGIND                            ;SAVE IT
        LDY     ,Y                                ;GET REGSTER CONTENTS
        LDA     ,S                                ;GET POSTBYTE BACK
        ANDA    #$9F                              ;MASK IT
        BMI     NOT5BO                            ;NOT A FIVE BIT OFFSET
;* FIVE BIT REGISTER OFFSET
        ANDA    #$1F                              ;MASK FOR CRAP
        CMPA    #$10                              ;NEGATIVE?
        BLO     SINOK                             ;NO, IT'S OK
        ORA     #$E0                              ;CONVERT TO NEGATIVE
SINOK
        LEAX    A,Y                               ;GET ADDRESS
        BRA     XSAVPC                            ;SAVE IT
;* TEST FOR NO OFFSET
NOT5BO
        ANDA    #$EF                              ;REMOVE INDIRECT BIT
        CMPA    #$84                              ;NO OFFSET?
        BNE     TOFF8                             ;NO, TRY OFFSET OF 8
        TFR     Y,X                               ;COPY
        BRA     XSAVPC                            ;SAVE IT
;* TEST FOR EIGHT BIT OFFSET
TOFF8
        CMPA    #$88                              ;8 BIT OFSET?
        BNE     TOFF16                            ;NO, TRY 16 BIT OFFSET
        LDB     ,U+                               ;GET OFFSET
        BRA     BSAVOF                            ;GO FOR IT
;* TEST FOR 16 BIT OFFSET
TOFF16
        CMPA    #$89                              ;16 BIT OFFSET?
        BNE     TOFFA                             ;TRY A ACCUMULATOR OFFSET
        LDD     ,U+                               ;GET OFFSET
        LEAX    D,Y                               ;DO IT
        BRA     XSAVPC                            ;SAVE IT
;* TEST FOR ACCA OFFSET
TOFFA
        CMPA    #$86                              ;OFFSET BY ACCA
        BNE     TOFFB                             ;NO, TRY B
        LDB     SAVA                              ;GET ACCA
        BRA     BSAVOF                            ;SAVE IT
;* TEST FOR ACCB OFFSET
TOFFB
        CMPA    #$85                              ;B OFFSET
        BNE     TOFFD                             ;NO, TRY D OFFSET
        LDB     SAVB                              ;GET B
BSAVOF
        LEAX    B,Y                               ;DO OFFSET
        BRA     XSAVPC                            ;SAVE IT
;* TEST FOR ACCD OFFSET
TOFFD
        CMPA    #$8B                              ;IS IT D OFFSET?
        BNE     TAINC1                            ;NO, TRY AUTO INC
        LDD     SAVA                              ;GET D ACCUMULATOR
        LEAX    D,Y                               ;DO IT
        BRA     XSAVPC                            ;SAVE IT
;* TEST FOR AUTO INCREMENT
TAINC1
        CMPA    #$80                              ;AUTO INC BY 1?
        BNE     TAINC2                            ;NO, TRY AUTO INC BY 2
        LEAX    ,Y+                               ;GET ADDRESS
        BRA     RSVREG                            ;RESAVE REGISTER
;* TEST FOR DOUBLE AUTO INCREMENT
TAINC2
        CMPA    #$81                              ;AUTO INC BY 1?
        BNE     TADEC1                            ;NO, TRY AUTO DEC
        LEAX    ,Y++                              ;GET ADDRESS
        BRA     RSVREG                            ;RESAVE REGISTER
;* TEST FOR AUTO DECREMENT
TADEC1
        CMPA    #$82                              ;AUTO DEC?
        BNE     TADEC2                            ;NO, TRY AUTO DEC BY TWO
        LEAX    ,-Y                               ;GET ADDRESS
        BRA     RSVREG                            ;RESAVE REGISTER
;* TEST FOR DOUBLE AUTO DECREMENT
TADEC2
        CMPA    #$83                              ;DOUBLE AUTO DEC
        BNE     TPCO8                             ;NO, TRY PC OFFSET
        LEAX    ,--Y                              ;GET OFFSET
RSVREG
        STY     [REGIND]	RESAVE REGISTER CONTENTS
XSAVPC
        BRA     SAVXPC                            ;SAVE NEW PC
;* TEST FOR EIGHT BIT OFFSET FROM PCR
TPCO8
        CMPA    #$8C                              ;8 BIT PC RELATIVE?
        BNE     TPCO16                            ;NO, TRY 16 BIT PC RELATIVE
        LDB     ,U+                               ;GET BYTE
        LEAX    B,U                               ;OFFSET IT
        BRA     SAVXPC                            ;RESAVE PC
;* TEST FOR 16 BIT OFFSET FROM PCR
TPCO16
        CMPA    #$8D                              ;16 BIT OFFSET
        BNE     TEIND                             ;NO, TRY EXTENDED INDIRECT
        LDD     ,U++                              ;GET VALUE
        LEAX    D,U                               ;POINT TO NEW LOCATION
        BRA     SAVXPC                            ;RESAVE
;* EXTENDED ADDRESSING VIA INDEXED POSTBYTE
TEIND
        LDX     ,U++                              ;GET ADDRESS
;* SAVE CALCULATED ADDRESS IN REGISTER, BUT FIRST CHECK FOR INDIRECTION
SAVXPC
        PULS    A                                 ;RESTORE POSTBYTE
        BITA    #$10                              ;INDIRECT?
        BEQ     NINXIN                            ;NOT INDIRECT
        LDX     ,X                                ;PERFORM A LEVEL OF INDIRECTION
NINXIN
        STX     SAVPC                             ;SAVE IT
        RTS
;* NORMAL EXECUTABLE INSTRUCTION, COPY IT INTO OUR RAM, THEN EXECUTE IT
NOREXE
        LEAU    -1,U                              ;BACKUP TO INSTRUCTION
        LDX     #INSRAM                           ;POINT TO RAM FOR INSTRUCTION
;* COPY INSTRUCTION INTO RAM
NORE1
        CMPU    SAVPC                             ;ARE WE THERE
        BHS     NORE2                             ;END OF INSTRUCTION
        LDA     ,U+                               ;GET DATA
        STA     ,X+                               ;SAVE IN RAM
        BRA     NORE1                             ;CONTINUE
;* INSERT A JUMP AFTER IT
NORE2
        LDA     #$7E                              ;GET 'JMP' EXTENDED INSTRUCTION
        STA     ,X+                               ;SAVE IT
        LDD     #NORE3                            ;POINT AT ADDRESS TO JUMP TO
        STD     ,X                                ;SAVE IT
        STS     REGIND                            ;SAVE SP
        LDS     SAVS                              ;RESTORE STACK POINTER
        LDA     SAVCC                             ;GET CC
        LDB     SAVDP                             ;GET DP
        PSHS    A,B                               ;SAVE CC AND DP
        LDD     SAVA                              ;RESTORE A, B
        LDX     SAVX                              ;RESTORE X
        LDY     SAVY                              ;RESTORE Y
        LDU     SAVU                              ;RESTORE U
        PULS    CC,DP                             ;RESTORE CC AND DP
        JMP     INSRAM                            ;EXECUTE INSTRUCTION
;* INSTRUCTION SHOULD RETURN TO HERE
NORE3
        PSHS    CC,DP                             ;SAVE REGS
        STD     SAVA                              ;SAVE REGS
        STX     SAVX                              ;SAVE X
        STY     SAVY                              ;SAVE Y
        STU     SAVU                              ;SAVE U
        PULS    A,B                               ;GET REGS BACK
        STA     SAVCC                             ;SAVE CC
        STB     SAVDP                             ;SAVE DP
        STS     SAVS                              ;SAVE STACK POINTER
        LDS     REGIND                            ;RESTORE OUR STACK
        RTS
;*
;* SUBROUTINE TO EVALUATE CONDITIONAL BRANCH OPCODES, AND DETERMINE
;* IF THEY ARE TO BE EXECUTED
;*
TSTCON
        LDB     #3                                ;TEST FOR THREE CONDITIONALS
        CMPA    #$2F                              ;IS IT 'BLE'?
        BNE     TSTC0                             ;NO, ITS NORMAL
        LDB     #6                                ;HANDLE WRETCHED 'BLE' CASE
TSTC0
        SUBA    #$22                              ;CONVERT OPCODE TO SIMPLE INDEX
        ASLA                                      ;	ROTATE.
        ASLA                                      ;	TWICE FOR FOUR BYTE ENTRIES
        LDX     #CONTAB                           ;POINT TO TABLE
        LEAX    A,X                               ;ADVANCE TO TABLE ENTRY
        LDA     SAVCC                             ;GET CONDITION CODES
        ANDA    ,X+                               ;MASK OUT NON-APPLICABLE ONES
TSTC1
        CMPA    ,X+                               ;DOES IT MATCH?
        BEQ     TSTC2                             ;IT'S OK
        DECB                                      ;	REDUCE COUNT
        BNE     TSTC1                             ;CONTINUE
        LDA     #255                              ;INDICATE CONDITIONAL NOT MET
        RTS
TSTC2
        CLRA                                      ;	INDICATE CONDITIONAL MET
        RTS
;*
;* DISASSEMBLE OPCODE POINTED TO BY Y. PLACE IN OUTPUT BUFFER POINTED TO BY U
;*
DISASS
        STY     PTRSAV                            ;SAVE INSTRUCTION POINTER
        PSHS    U                                 ;SAVE INST POINTER
        LDD     #$2000+26	GET SPACE+NUMBER OF BYTES TO CLEAR
DISA1
        STA     ,U+                               ;SET A SPACE
        DECB                                      ;	REDUCE COUNT
        BNE     DISA1                             ;CONTINUE
        LDX     #OPTAB1                           ;POINT TO GENERAL OPCODE TABLE
        LDA     ,Y                                ;GET DATA BYTE
        CMPA    #$10                              ;PREFIX BYTE?
        BEQ     SETOP2                            ;NEW TABLE
        CMPA    #$11                              ;OTHER PREFIX BYTE
        BNE     OPFIND                            ;NO, IT'S OK
        LDX     #OPTAB3                           ;POINT TO THIRD TABLE
        BRA     OPFNXT                            ;OK
SETOP2
        LDX     #OPTAB2                           ;POINT TO SECOND OPERAND TABLE
OPFNXT
        LEAY    1,Y                               ;SKIP PREFIX BYTE
;* LOOK FOR OPCODE IN TABLE
OPFIND
        LDA     ,X+                               ;GET BYTE FROM TABLE
        CMPA    ,Y                                ;IS THIS IT?
        BEQ     FNDOPC                            ;FOUND IT
        CMPA    #$CF                              ;END OF TABLE?
        BEQ     BADOPC                            ;IF SO, FAKE AN OPCODE
        LEAX    2,X                               ;ADVANCE
        BRA     OPFIND                            ;KEEP LOOKING
BADOPC
        LDY     PTRSAV                            ;INSURE WE ARE AT BEGINNING
;* LOCATED OPCODE, GENERATE STRING
FNDOPC
        LEAY    1,Y                               ;SKIP TO POSTBYTE
        LDA     ,X+                               ;GET DATA
        STA     INSTYP                            ;SAVE FOR LATER
        LDB     ,X                                ;GET INSTRUCTION NUMBER
        LDA     #4                                ;FOUR BYTES/ENTRY
        MUL                                       ;	CALCULATE ENTRY OFFSET
        LDX     #ITABLE                           ;POINT TO INSTRUCTION TABLE
        LEAX    D,X                               ;ADVANCE TO IT
        LDB     #4                                ;SIZE OF INSTRIUCTION FIELD
FNDO1
        LDA     ,X+                               ;GET CHAR
        STA     ,U+                               ;SAVE IN OUTPUT
        DECB                                      ;	MOVE FOUR CHARACTERS
        BNE     FNDO1                             ;CONTINUE
FNDO2
        LDA     INSTYP                            ;GET TYPE BITS BACK
        ANDA    #$0F                              ;REMOVE CRAP
        LBEQ    ENDIS                             ;NO OPERANDS
;* INSERT SPACES FOR OPERAND
        LDB     #' '                              ;GET A SPACE
        STB     ,U+                               ;SAVE IN OUTPUT
        STB     ,U+                               ;SAVE IN OUTPUT
        DECA                                      ;	IS 8 BIT IT IMMEDIATE?
        BNE     IMM16                             ;NO, TRY 16 BIT IMMEDIATE
;* EIGHT BIT IMMEDIATE ADDRESSING OPERAND
IMM8
        LDA     #'#'                              ;INDICATE IMMEDIATE
        STA     ,U+                               ;SAVE IT
        BRA     OP8                               ;QUIT
;* SIXTEEN BIT IMMEDIATE ADDRESSING
IMM16
        DECA                                      ;	IS THIS IT?
        BNE     DIRECT                            ;NO, TRY DIRECT
        LDA     #'#'                              ;INDICATE IMMEDIATE
        STA     ,U+                               ;SAVE IT
        BRA     OP16                              ;16 BIT OPERAND
;* DIRECT PAGE ADDRESSING
DIRECT
        DECA                                      ;	IS THIS IT?
        BNE     EXTEND                            ;NO, TRY EXTENDED
        LDA     #'<'                              ;INDICATE DIRECT
        STA     ,U+                               ;SAVE IT
OP8
        LDA     ,Y+                               ;GET OPERAND BYTE
        LBSR    WRHEXB                            ;OUTPUT
        BRA     ENDIS1                            ;END GO HOME
;* EXTENDED ADDRESSING
EXTEND
        DECA                                      ;	IS THIS IT?
        BNE     INDEX                             ;NO, TRY INDEXED
OP16
        LDD     ,Y++                              ;GET OPCODES
        LBSR    WRHEXW                            ;OUTPUT WORD
ENDIS1
        LBRA    ENDIS                             ;GO HOME
;* INDEXED ADDRESSING MODES
INDEX
        DECA                                      ;	IS IT INDEXED?
        LBNE    PSHPUL                            ;NO, TRY PUSH OR PUL
        LDA     ,Y+                               ;GET POST BYTE
        STA     POSBYT                            ;SAVE FOR LATER
;* TEST FOR FIVE BIT OFFSET
        BMI     NO5BO                             ;NOT A FIVE BIT OFFSET
        ANDA    #$1F                              ;CONVERT TO POSTBYTE
        BRA     EVLX1                             ;INSERT REGISTER AND CONTINUE
;* TEST FOR INDIRECT MODE
NO5BO
        BITA    #$10                              ;TEST FOR INDIRECT
        BEQ     NOIND                             ;NOT INDIRECT
        LDB     #'['                              ;GET OPENING
        STB     ,U+                               ;SAVE IN OUTPUT
;* TEST FOR NO OFFSET
NOIND
        ANDA    #$8F                              ;REMOVE REGS AND INDIRECT BIT
        CMPA    #$84                              ;NO OFFSET?
        BEQ     INSR1                             ;INSERT REGISTER AND EXIT
;* TEST FOR EIGHT BIT OFFSET
        CMPA    #$88                              ;EIGHT BIT OFFSET
        BNE     EVL1                              ;NO, TRY NEXT
        LDA     ,Y+                               ;GET BYTE OFFSET
EVLX1
        LBSR    WRHEXB                            ;OUTPUT
        BRA     INSR1                             ;CONTINUE
;* TEST FOR 16 BIT OFFSET
EVL1
        CMPA    #$89                              ;16 BIT OFSET?
        BNE     EVL2                              ;NO, TRY NEXT
        LDD     ,Y++                              ;GET OPERAND
        LBSR    WRHEXW                            ;OUTPUT
        BRA     INSR1                             ;INSERT REGISTER
;* TEST FOR A ACCUMULATOR OFFSET
EVL2
        CMPA    #$86                              ;IS IT 'A' OFFSET?
        BNE     EVL3                              ;NO, TRY NEXT
        LDA     #'A'                              ;GET ACCA
        BRA     SAIREG                            ;GO HOME
;* TEST FOR B ACCUMULATOR OFFSET
EVL3
        CMPA    #$85                              ;IS IT 'B' OFFSET?
        BNE     EVL4                              ;NO, TRY NEXT
        LDA     #'B'                              ;GET B
        BRA     SAIREG                            ;GO HOME
;* TEST FRO 'D' ACCUMULATOR OFFSET
EVL4
        CMPA    #$8B                              ;D OFFSET?
        BNE     EVL5                              ;NO, TRY NEXT
        LDA     #'D'                              ;GET D REGISTER
SAIREG
        STA     ,U+                               ;SAVE IT
INSR1
        BRA     INSREG
;* TEST FOR EXTENDED INDIRECT
EVL5
        CMPA    #$8F                              ;EXTENDED INDIRECT?
        BNE     EVL6                              ;NO, TRY NEXT
        LDD     ,Y++                              ;GET OFFSET
        LBSR    WRHEXW                            ;OUTPUT
        BRA     EVLFIN                            ;AND CONTINUE
;* TEST FOR PC OFFSET, 8 BIT
EVL6
        CMPA    #$8C                              ;EIGHT BIT PC OFFSET?
        BNE     EVL7                              ;NO, TRY NEXT
        LDA     ,Y+                               ;GET OFFSET
        LBSR    WRHEXB                            ;OUTPUT
        BRA     WRPCRG                            ;OUTPUT PC REGISTER
;* TEST FOR PC OFFSET, 16 BIT
EVL7
        CMPA    #$8D                              ;PC OFFSET?
        BNE     INSREG                            ;NO, INSERT REGISTER
        LDD     ,Y++                              ;GET OFFSET
        LBSR    WRHEXW                            ;OUTPUT
WRPCRG
        LDX     #PCRG                             ;POINT TO STRING
WRPR1
        LDA     ,X+                               ;GET CHAR
        STA     ,U+                               ;SAVE
        CMPA    #'R'                              ;END?
        BNE     WRPR1                             ;NO, CONTINUE
        BRA     EVLFIN                            ;END IT NOW
;* INSERT REGISTER BITS
INSREG
        LDA     #','                              ;GET COMMA
        STA     ,U+                               ;SAVE IT
        LDA     POSBYT                            ;GET POSTBYTE
        LDB     #'-'                              ;GET MINUS
        ANDA    #$8F                              ;REMOVE CRAP
        CMPA    #$82                              ;DECREMENT BY ONE?
        BEQ     DEC1                              ;DECREMENT BY ONE
        CMPA    #$83                              ;DECREMENT BY TWO?
        BNE     NODEC                             ;NO, DON'T DEC
        STB     ,U+                               ;SAVE
DEC1
        STB     ,U+                               ;AGAIN
NODEC
        LDA     POSBYT                            ;GET POSTBYTE
        LSRA                                      ;	SHIFT
        LSRA                                      ;	REGISTER
        LSRA                                      ;	BITS
        LSRA                                      ;	INTO
        LSRA                                      ;	BOTTOM
        LDB     #'X'                              ;GET 'X'
        ANDA    #$03                              ;REMOVE CRAP
        BEQ     EVLEND                            ;ITS 'X'
        LDB     #'Y'                              ;GET 'Y'
        DECA                                      ;	TEST FOR 'Y'
        BEQ     EVLEND                            ;YES
        LDB     #'U'                              ;GET 'U'
        DECA                                      ;	TEST
        BEQ     EVLEND                            ;ITS 'U'
        LDB     #'S'                              ;MUST BE 'S'
EVLEND
        STB     ,U+                               ;SAVE IN OUTPUT
EVLFIN
        LDA     POSBYT                            ;GET POSTBYTE
        LDB     #'+'                              ;GET PLUS
        ANDA    #$8F                              ;GET TYPE
        CMPA    #$80                              ;IS IT INC BY ONE
        BEQ     INC1                              ;IF SO, WE HAVE IT
        CMPA    #$81                              ;INC BY TWO?
        BNE     NOINC                             ;NO INCREMENT
        STB     ,U+                               ;SAVE ONE
INC1
        STB     ,U+                               ;SAVE TWO
NOINC
        LDA     POSBYT                            ;GET POSTBYTE
        BPL     NOIND1                            ;FIVE BIT OFFSET
        BITA    #$10                              ;INDIRECT?
        BEQ     NOIND1                            ;NO INDIRECT
        LDA     #']'                              ;CLOSING BRACE
        STA     ,U+                               ;SAVE IT
NOIND1
        LBRA    ENDIS                             ;END IT
;* PULS OR PULL OPCODES
PSHPUL
        DECA                                      ;	IS IT PUSH OR PULL?
        BNE     TFREXG                            ;NO, TRY TRANSFER OR EXCHANGE
        LDA     ,Y+                               ;GET POSTBYTE
        LDX     #PSHTAB                           ;GET 'CC'
PSH1
        LSRA                                      ;	SHIFT OUT BITS
        BCC     PSHNXT                            ;SKIP THIS ONE
        PSHS    A,B                               ;SAVE REGS
        LDD     ,X++                              ;GET DATA
        CMPA    #'U'                              ;SAVEING U REGISTER
        BNE     PSH4                              ;NO, IT'S OK
        TST     INSTYP                            ;SPECIAL CASE
        BPL     PSH4                              ;OK
        LDA     #'S'                              ;CONVERT
PSH4
        STA     ,U+                               ;SAVE IT
        TSTB                                      ;	MORE?
        BEQ     PSH2                              ;NO, SKIP IT
        STB     ,U+                               ;SAVE
PSH2
        PULS    A,B                               ;RESTORE REGS
        TSTA                                      ;	MORE BITS?
        BEQ     PSH3                              ;NO, QUIT
        PSHS    A                                 ;RESAVE
        LDA     #','                              ;GET COMMA
        STA     ,U+                               ;SAVE
        PULS    A                                 ;GET IT BACK
        BRA     PSH1                              ;CONTINUE
PSHNXT
        LEAX    2,X                               ;ADVANCE
        TSTA                                      ;	ARE WE OK
        BNE     PSH1                              ;KEEP TRYING
PSH3
        LBRA    ENDIS                             ;DONE
;* TRANSFER AND EXCHANGE POSTBYTE OPCODES
TFREXG
        DECA                                      ;	TRANSFER OR EXCHANGE?
        BNE     SBRAN                             ;TRY SHORT BRANCH
        LDA     ,Y                                ;GET POSTBYTE
        LSRA                                      ;	SHIFT
        LSRA                                      ;	INTO
        LSRA                                      ;	LOW
        LSRA                                      ;	NIBBLE
        BSR     TFRREG                            ;GET REGISTER
        LDA     #','                              ;SEPERATOR
        STA     ,U+                               ;SAVE
        LDA     ,Y+                               ;GET POSTBYTE AGAIN
        BSR     TFRREG                            ;PLACE IT
        LBRA    ENDIS                             ;GO HOME
;* CALCULATE TRANSFER REGISTER
TFRREG
        ANDA    #$0F                              ;REMOVE HIGH CRAP
        ASLA                                      ;	MULTIPLY BY TWO
        LDX     #REGTAB                           ;POINT TO TABLE
        LDD     A,X                               ;GET REGISTER VALUE
        STA     ,U+                               ;SAVE IT
        TSTB                                      ;	SECOND BYTE?
        BEQ     TFRET                             ;NO, SKIP IT
        STB     ,U+                               ;SAVE IT
TFRET
        RTS
;* SHORT BRANCH
SBRAN
        DECA                                      ;	SHORT BRANCH
        BNE     LBRAN                             ;NO, TRY LONG BRANCH
        LDB     ,Y+                               ;GET OPERATOR
        LEAX    B,Y                               ;GET NEW ADDRESS
        TFR     X,D                               ;COPY
        BRA     SAVADR                            ;FINISH
;* LONG BRANCH
LBRAN
        LDD     ,Y++                              ;GET OPERAND
        PSHS    Y                                 ;SAVE Y
        ADDD    ,S++                              ;ADD OFFSET TO REG
SAVADR
        LBSR    WRHEXW                            ;OUTPUT WORD.
ENDIS
        LDA     #$0D                              ;GET CR
        STA     ,U                                ;SAVE IT
;* INSERT ADDRESS/BYTE DATA
        LDU     ,S                                ;RESTORE U REGISTER
        PSHS    Y                                 ;SAVE POINTER TO END
        LDX     PTRSAV                            ;POINT TO STARTING ADDRESS
        TFR     X,D                               ;COPY
        LBSR    WRHEX                             ;OUTPUT
        TFR     B,A                               ;COPY
        LBSR    WRHEX                             ;OUTPUT
        CLRB                                      ;	START WITH ZERO
END1
        CMPX    ,S                                ;ARE WE AT END?
        BHS     END2                              ;IF SO, QUIT
        INCB                                      ;	ADVANCE
        LEAU    1,U                               ;ADVANCE
        LDA     ,X+                               ;GET BYTE
        LBSR    WRHEX                             ;OUTPUT
        BRA     END1                              ;CONTINUE
END2
        LEAS    2,S                               ;RESTORE STACK
        LDU     ,S                                ;RESTORE U REGISTER
        LEAU    20,U                              ;ADVANCE TO TEXT FIELD
        LDX     PTRSAV                            ;GET POINTER BACK
END3
        DECB                                      ;	REDUCE COUNT
        BMI     END4                              ;CONTINUE
        LDA     ,X+                               ;GO IT AGAIN
        CMPA    #' '                              ;< SPACE?
        BLO     END5                              ;YES
        CMPA    #$7F                              ;> 7F?
        BLO     END6                              ;OK
END5
        LDA     #'.'                              ;CONVERT TO DOT
END6
        STA     ,U+                               ;SAVE
        BRA     END3
END4
        PULS    U,PC                              ;GO HOME
;*
;* SUBROUTINES
;*
WRHEXB
        PSHS    A                                 ;SAVE IT
        LDA     #'$'                              ;INDICATE HEX
        STA     ,U+                               ;SAVE
        BRA     WRHEX1                            ;CONTINUE
WRHEXW
        PSHS    B                                 ;SAVE B
        LDB     #'$'                              ;INDICATE HEX
        STB     ,U+                               ;SAVE IT
        BSR     WRHEX                             ;OUTPUT
WRHEX1
        PULS    A                                 ;RESTORE
WRHEX
        PSHS    A                                 ;SAVE IT
        LSRA                                      ;	SHIFT
        LSRA                                      ;	HIGH BYTE
        LSRA                                      ;	INTO
        LSRA                                      ;	LOW FOR OUTPUT
        BSR     WRHEXN                            ;OUTPUT NIBBLE
        PULS    A                                 ;RETORE
WRHEXN
        ANDA    #$0F                              ;REMOVE CRAP
        ADDA    #$30                              ;CONVERT
        CMPA    #$39                              ;OK?
        BLS     WRNOK                             ;OK
        ADDA    #7                                ;CONVERT
WRNOK
        STA     ,U+                               ;SAVE IT
        RTS
;*
;* SWI HANDLER
;*
SWIHND
        LDY     #BRKTAB                           ;POINT TO BREAKPOINT TABLE
        LDX     10,S                              ;GET STORED PC
        LEAX    -1,X                              ;BACKUP TO BREAKPOINT ADDRESS
        LDB     #8                                ;CHECK EIGHT BREAKPOINTS
SWIHN1
        CMPX    ,Y                                ;IS THIS IT?
        BEQ     SWIHN2                            ;YES
        LEAY    3,Y                               ;SKIP OPCODE
        DECB                                      ;	REDUCE COUNT
        BNE     SWIHN1                            ;CONTINUE
        LDB     2,S                               ;RESTORE B
        LDX     4,S                               ;RESTORE X
        LDY     6,S                               ;RESTORE Y
        JMP     [SWIADR]	NOT A BREAKPOINT, EXECUTE SWI HANDLER
SWIHN2
        STB     INSTYP                            ;SAVE BREAKPOINT NUMBER
        LDX     #SAVCC                            ;POINT TO START OF SAVED REGS
        LDB     #10                               ;MOVE 10
SWIHN25
        LDA     ,S+                               ;GET BYTE
        STA     ,X+                               ;SAVE
        DECB                                      ;	DECREMENT COUNT
        BNE     SWIHN25                           ;DO THEM ALL
        PULS    X                                 ;GET PC
        LEAX    -1,X                              ;SET BACK TO REAL PC
        STX     SAVPC                             ;SAVED PC
        STS     SAVS                              ;SAVE STACK POINTER
        LBSR    WRMSG                             ;DISPLAY MESSAGE
        FCN     'Breakpoint #'
        LDA     #$38                              ;GET NUMBER, PLUS ASCII CONVERT
        SUBA    INSTYP                            ;CONVERT TO PROPER DIGIT
        LBSR    PUTCHR                            ;DISPLAY
        LBSR    LFCR                              ;NEW LINE
        TST     STPFLG                            ;TO WE DISPLAY
        BNE     BRKRES                            ;NO
        LBSR    DISREG                            ;DISPLAY
BRKRES
        LDX     #BRKTAB                           ;POINT TO BREAKPOINT TABLE
        LDB     #8                                ;DO IT EIGHT TIMES
SWIHN3
        LDY     ,X++                              ;GET REG
        BEQ     SWIHN4                            ;NO BRK, NEXT
        LDA     ,X                                ;GET OPCODE
        STA     ,Y                                ;REPLACE IN RAM
SWIHN4
        LEAX    1,X                               ;SKIP OPCODE
        DECB                                      ;	REDUCE COUNT
        BNE     SWIHN3                            ;GO AGAIN
        LBRA    MAIN                              ;DO PROMPT
;* CONSTANTS
PCRG
        FCC     ',PCR'
;* TRANSFER/EXCHANGE REGISTER TABLE
REGTAB
        FCN     'D'                               ;0
        FCN     'X'                               ;1
        FCN     'Y'                               ;2
        FCN     'U'                               ;3
        FCN     'S'                               ;4
        FCC     'PC'                              ;5
        FCN     '?'                               ;6
        FCN     '?'                               ;7
        FCN     'A'                               ;8
        FCN     'B'                               ;9
        FCC     'CC'                              ;A
        FCC     'DP'                              ;B
        FCN     '?'                               ;C
        FCN     '?'                               ;D
        FCN     '?'                               ;E
        FCN     '?'                               ;F
;* PUSH/PULL REGISTER TABLE
PSHTAB
        FCC     'CC'
        FCN     'A'
        FCN     'B'
        FCC     'DP'
        FCN     'X'
        FCN     'Y'
        FCN     'U'
        FCN     'PC'
;*
;* OPCODE TABLE, OPCODE BYTE, TYPE BYTE, TEXT BYTE
;*
OPTAB1
        FCB     $86,1,1                           ;'LDA' INSTRUCTIONS
        FCB     $96,3,1
        FCB     $A6,5,1
        FCB     $B6,4,1
        FCB     $C6,1,2                           ;'LDB' INSTRUCTIONS
        FCB     $D6,3,2
        FCB     $E6,5,2
        FCB     $F6,4,2
        FCB     $CC,2,3                           ;'LDD' INSTRUCTIONS
        FCB     $DC,3,3
        FCB     $EC,5,3
        FCB     $FC,4,3
        FCB     $CE,2,4                           ;'LDU' INSTRUCTIONS
        FCB     $DE,3,4
        FCB     $EE,5,4
        FCB     $FE,4,4
        FCB     $8E,2,5                           ;'LDX' INSTRUCTIONS
        FCB     $9E,3,5
        FCB     $AE,5,5
        FCB     $BE,4,5
        FCB     $97,3,6                           ;'STA' INSTRUCTINOS
        FCB     $A7,5,6
        FCB     $B7,4,6
        FCB     $D7,3,7                           ;'STB' INSTRUCTIONS
        FCB     $E7,5,7
        FCB     $F7,4,7
        FCB     $DD,3,8                           ;'STD' INSTRUCTIONS
        FCB     $ED,5,8
        FCB     $FD,4,8
        FCB     $DF,3,9                           ;'STU' INSTRUCTIONS
        FCB     $EF,5,9
        FCB     $FF,4,9
        FCB     $9F,3,10	'STX' INSTRUCTIONS
        FCB     $AF,5,10
        FCB     $BF,4,10
        FCB     $3A,0,11	'ABX'
        FCB     $89,1,12	'ADCA'
        FCB     $99,3,12
        FCB     $A9,5,12
        FCB     $B9,4,12
        FCB     $C9,1,13	'ADCB'
        FCB     $D9,3,13
        FCB     $E9,5,13
        FCB     $F9,4,13
        FCB     $8B,1,14	'ADDA'
        FCB     $9B,3,14
        FCB     $AB,5,14
        FCB     $BB,4,14
        FCB     $CB,1,15	'ADDB'
        FCB     $DB,3,15
        FCB     $EB,5,15
        FCB     $FB,4,15
        FCB     $C3,2,16	'ADDD'
        FCB     $D3,3,16
        FCB     $E3,5,16
        FCB     $F3,4,16
        FCB     $48,0,17	'ASLA'
        FCB     $58,0,18	'ASLB'
        FCB     $08,3,19	'ASL'
        FCB     $68,5,19
        FCB     $78,4,19
        FCB     $47,0,20	'ASRA'
        FCB     $57,0,21	'ASRB'
        FCB     $07,3,22	'ASR'
        FCB     $67,5,22
        FCB     $77,4,22
        FCB     $85,1,23	'BITA'
        FCB     $95,3,23
        FCB     $A5,5,23
        FCB     $B5,4,23
        FCB     $C5,1,24	'BITB'
        FCB     $D5,3,24
        FCB     $E5,5,24
        FCB     $F5,4,24
        FCB     $4F,0,25	'CLRA'
        FCB     $5F,0,26	'CLRB'
        FCB     $0F,3,27	'CLR'
        FCB     $6F,5,27
        FCB     $7F,4,27
        FCB     $81,1,28	'CMPA'
        FCB     $91,3,28
        FCB     $A1,5,28
        FCB     $B1,4,28
        FCB     $C1,1,29	'CMPB'
        FCB     $D1,3,29
        FCB     $E1,5,29
        FCB     $F1,4,29
        FCB     $8C,2,30	'CMPX'
        FCB     $9C,3,30
        FCB     $AC,5,30
        FCB     $BC,4,30
        FCB     $43,0,31	'COMA'
        FCB     $53,0,32	'COMB'
        FCB     $03,3,33	'COM'
        FCB     $63,5,33
        FCB     $73,4,33
        FCB     $3C,1,34	'CWAI'
        FCB     $19,0,35	'DAA'
        FCB     $4A,0,36	'DECA'
        FCB     $5A,0,37	'DECB'
        FCB     $0A,3,38	'DEC'
        FCB     $6A,5,38
        FCB     $7A,4,38
        FCB     $88,1,39	'EORA'
        FCB     $98,3,39
        FCB     $A8,5,39
        FCB     $B8,4,39
        FCB     $C8,1,40	'EORB'
        FCB     $D8,3,40
        FCB     $E8,5,40
        FCB     $F8,4,40
        FCB     $1E,7,41	'EXG'
        FCB     $1F,7,42	'TFR'
        FCB     $34,6,43	'PSHS'
        FCB     $36,$86,44	'PSHU'
        FCB     $35,6,45	'PULS'
        FCB     $37,$86,46	'PULU'
        FCB     $4C,0,47	'INCA'
        FCB     $5C,0,48	'INCB'
        FCB     $0C,3,49	'INC'
        FCB     $6C,5,49
        FCB     $7C,4,49
        FCB     $0E,3,50	'JMP'
        FCB     $6E,5,50
        FCB     $7E,4,50
        FCB     $9D,3,51	'JSR'
        FCB     $AD,5,51
        FCB     $BD,4,51
        FCB     $32,5,52	'LEAS'
        FCB     $33,5,53	'LEAU'
        FCB     $30,5,54	'LEAX'
        FCB     $31,5,55	'LEAY'
        FCB     $44,0,56	'LSRA'
        FCB     $54,0,57	'LSRB'
        FCB     $04,3,58	'LSR'
        FCB     $64,5,58
        FCB     $74,4,58
        FCB     $3D,0,59	'MUL'
        FCB     $40,0,60	'NEGA'
        FCB     $50,0,61	'NEGB'
        FCB     $00,3,62	'NEG'
        FCB     $60,5,62
        FCB     $70,4,62
        FCB     $12,0,63	'NOP'
        FCB     $8A,1,64	'ORA'
        FCB     $9A,3,64
        FCB     $AA,5,64
        FCB     $BA,4,64
        FCB     $CA,1,65	'ORB'
        FCB     $DA,3,65
        FCB     $EA,5,65
        FCB     $FA,4,65
        FCB     $1A,1,66	'ORCC'
        FCB     $84,1,67	'ANDA'
        FCB     $94,3,67
        FCB     $A4,5,67
        FCB     $B4,4,67
        FCB     $C4,1,68	'ANDB'
        FCB     $D4,3,68
        FCB     $E4,5,68
        FCB     $F4,4,68
        FCB     $1C,1,69	'ANDCC'
        FCB     $49,0,70	'ROLA'
        FCB     $59,0,71	'ROLB'
        FCB     $09,3,72	'ROL'
        FCB     $69,5,72
        FCB     $79,4,72
        FCB     $46,0,73	'RORA'
        FCB     $56,0,74	'RORB'
        FCB     $06,3,75	'ROR'
        FCB     $66,5,75
        FCB     $76,4,75
        FCB     $3B,0,76	'RTI'
        FCB     $39,0,77	'RTS'
        FCB     $82,1,78	'SBCA'
        FCB     $92,3,78
        FCB     $A2,5,78
        FCB     $B2,4,78
        FCB     $C2,1,79	'SBCB'
        FCB     $D2,3,79
        FCB     $E2,5,79
        FCB     $F2,4,79
        FCB     $1D,0,80
        FCB     $80,1,81	'SUBA'
        FCB     $90,3,81
        FCB     $A0,5,81
        FCB     $B0,4,81
        FCB     $C0,1,82	'SUBB'
        FCB     $D0,3,82
        FCB     $E0,5,82
        FCB     $F0,4,82
        FCB     $83,2,83	'SUBD'
        FCB     $93,3,83
        FCB     $A3,5,83
        FCB     $B3,4,83
        FCB     $3F,1,84	'SWI'                    ;(SSR INTERFACE)
        FCB     $13,0,85	'SYNC'
        FCB     $4D,0,86	'TSTA'
        FCB     $5D,0,87	'TSTB'
        FCB     $0D,3,88	'TST'
        FCB     $6D,5,88
        FCB     $7D,4,88
        FCB     $16,9,99	'LBRA'
        FCB     $17,9,100	'LBSR'
        FCB     $20,8,101	'BRA'
        FCB     $21,8,102	'BRN'
        FCB     $22,8,103	'BHI'
        FCB     $23,8,104	'BLS'
        FCB     $24,8,105	'BCC'
        FCB     $25,8,106	'BCS'
        FCB     $26,8,107	'BNE'
        FCB     $27,8,108	'BEQ'
        FCB     $28,8,109	'BVC'
        FCB     $29,8,110	'BVS'
        FCB     $2A,8,111	'BPL'
        FCB     $2B,8,112	'BMI'
        FCB     $2C,8,113	'BGE'
        FCB     $2D,8,114	'BLT'
        FCB     $2E,8,115	'BGT'
        FCB     $2F,8,116	'BLE'
        FCB     $8D,8,132	'BSR'
        FCB     $CF,0,0         'FCB', UNKNOWN OPCODE
;* OPERAND TABLE NUMBER TWO, $10 PREFIX INSTRUCTIONS
OPTAB2
        FCB     $83,2,89	'CMPD'
        FCB     $93,3,89
        FCB     $A3,5,89
        FCB     $B3,4,89
        FCB     $8C,2,90	'CMPY'
        FCB     $9C,3,90
        FCB     $AC,5,90
        FCB     $BC,4,90
        FCB     $CE,2,91	'LDS'
        FCB     $DE,3,91
        FCB     $EE,5,91
        FCB     $FE,4,91
        FCB     $8E,2,92	'LDY'
        FCB     $9E,3,92
        FCB     $AE,5,92
        FCB     $BE,4,92
        FCB     $DF,3,93	'STS'
        FCB     $EF,5,93
        FCB     $FF,4,93
        FCB     $9F,3,94	'STY'
        FCB     $AF,5,94
        FCB     $BF,4,94
        FCB     $3F,0,95	'SWI2'
        FCB     $21,9,117	'LBRN'
        FCB     $22,9,118	'LBHI'
        FCB     $23,9,119	'LBLS'
        FCB     $24,9,120	'LBCC'
        FCB     $25,9,121	'LBCS'
        FCB     $26,9,122	'LBNE'
        FCB     $27,9,123	'LBEQ'
        FCB     $28,9,124	'LBVC'
        FCB     $29,9,125	'LBVS'
        FCB     $2A,9,126	'LBPL'
        FCB     $2B,9,127	'LBMI'
        FCB     $2C,9,128	'LBGE'
        FCB     $2D,9,129	'LBLT'
        FCB     $2E,9,130	'LBGT'
        FCB     $2F,9,131	'LBLE'
        FCB     $CF,1,0
;* OPERAND TABLE #3, $11 PREFIXES
OPTAB3
        FCB     $8C,2,96	'CMPS'
        FCB     $9C,3,96
        FCB     $AC,5,96
        FCB     $BC,4,96
        FCB     $83,2,97	'CMPU'
        FCB     $93,3,97
        FCB     $A3,5,97
        FCB     $B3,4,97
        FCB     $3F,0,98	'SWI3'
;* INSTRUCTION TEXT TABLE
ITABLE
        FCC     'FCB '                            ;0
        FCC     'LDA '                            ;1
        FCC     'LDB '                            ;2
        FCC     'LDD '                            ;3
        FCC     'LDU '                            ;4
        FCC     'LDX '                            ;5
        FCC     'STA '                            ;6
        FCC     'STB '                            ;7
        FCC     'STD '                            ;8
        FCC     'STU '                            ;9
        FCC     'STX '                            ;10
        FCC     'ABX '                            ;11
        FCC     'ADCA'                            ;12
        FCC     'ADCB'                            ;13
        FCC     'ADDA'                            ;14
        FCC     'ADDB'                            ;15
        FCC     'ADDD'                            ;16
        FCC     'ASLA'                            ;17
        FCC     'ASLB'                            ;18
        FCC     'ASL '                            ;19
        FCC     'ASRA'                            ;20
        FCC     'ASRB'                            ;21
        FCC     'ASR '                            ;22
        FCC     'BITA'                            ;23
        FCC     'BITB'                            ;24
        FCC     'CLRA'                            ;25
        FCC     'CLRB'                            ;26
        FCC     'CLR '                            ;27
        FCC     'CMPA'                            ;28
        FCC     'CMPB'                            ;29
        FCC     'CMPX'                            ;30
        FCC     'COMA'                            ;31
        FCC     'COMB'                            ;32
        FCC     'COM '                            ;33
        FCC     'CWAI'                            ;34
        FCC     'DAA '                            ;35
        FCC     'DECA'                            ;36
        FCC     'DECB'                            ;37
        FCC     'DEC '                            ;38
        FCC     'EORA'                            ;39
        FCC     'EORB'                            ;40
        FCC     'EXG '                            ;41
        FCC     'TFR '                            ;42
        FCC     'PSHS'                            ;43
        FCC     'PSHU'                            ;44
        FCC     'PULS'                            ;45
        FCC     'PULU'                            ;46
        FCC     'INCA'                            ;47
        FCC     'INCB'                            ;48
        FCC     'INC '                            ;49
        FCC     'JMP '                            ;50
        FCC     'JSR '                            ;51
        FCC     'LEAS'                            ;52
        FCC     'LEAU'                            ;53
        FCC     'LEAX'                            ;54
        FCC     'LEAY'                            ;55
        FCC     'LSRA'                            ;56
        FCC     'LSRB'                            ;57
        FCC     'LSR '                            ;58
        FCC     'MUL '                            ;59
        FCC     'NEGA'                            ;60
        FCC     'NEGB'                            ;61
        FCC     'NEG '                            ;62
        FCC     'NOP '                            ;63
        FCC     'ORA '                            ;64
        FCC     'ORB '                            ;65
        FCC     'ORCC'                            ;66
        FCC     'ANDA'                            ;67
        FCC     'ANDB'                            ;68
        FCC     'ANDC'                            ;69
        FCC     'ROLA'                            ;70
        FCC     'ROLB'                            ;71
        FCC     'ROL '                            ;72
        FCC     'RORA'                            ;73
        FCC     'RORB'                            ;74
        FCC     'ROR '                            ;75
        FCC     'RTI '                            ;76
        FCC     'RTS '                            ;77
        FCC     'SBCA'                            ;78
        FCC     'SBCB'                            ;79
        FCC     'SEX '                            ;80
        FCC     'SUBA'                            ;81
        FCC     'SUBB'                            ;82
        FCC     'SUBD'                            ;83
        FCC     'SSR'                             ;84
        FCC     'SYNC'                            ;85
        FCC     'TSTA'                            ;86
        FCC     'TSTB'                            ;87
        FCC     'TST '                            ;88
        FCC     'CMPD'                            ;89
        FCC     'CMPY'                            ;90
        FCC     'LDS '                            ;91
        FCC     'LDY '                            ;92
        FCC     'STS '                            ;93
        FCC     'STY '                            ;94
        FCC     'SWI2'                            ;95
        FCC     'CMPS'                            ;96
        FCC     'CMPU'                            ;97
        FCC     'SWI3'                            ;98
        FCC     'LBRA'                            ;99
        FCC     'LBSR'                            ;100
        FCC     'BRA '                            ;101
        FCC     'BRN '                            ;102
        FCC     'BHI '                            ;103
        FCC     'BLS '                            ;104
        FCC     'BCC '                            ;105
        FCC     'BCS '                            ;106
        FCC     'BNE '                            ;107
        FCC     'BEQ '                            ;108
        FCC     'BVC '                            ;109
        FCC     'BVS '                            ;110
        FCC     'BPL '                            ;111
        FCC     'BMI '                            ;112
        FCC     'BGE '                            ;113
        FCC     'BLT '                            ;114
        FCC     'BGT '                            ;115
        FCC     'BLE '                            ;116
        FCC     'LBRN'                            ;117
        FCC     'LBHI'                            ;118
        FCC     'LBLS'                            ;119
        FCC     'LBCC'                            ;120
        FCC     'LBCS'                            ;121
        FCC     'LBNE'                            ;122
        FCC     'LBEQ'                            ;123
        FCC     'LBVC'                            ;124
        FCC     'LBVS'                            ;125
        FCC     'LBPL'                            ;126
        FCC     'LBMI'                            ;127
        FCC     'LBGE'                            ;128
        FCC     'LBLT'                            ;129
        FCC     'LBGT'                            ;130
        FCC     'LBLE'                            ;131
        FCC     'BSR '                            ;132
;*
;* CONDITIONAL TABLE, FIRST BYTE IS MASK, NEXT THREE BYTES ARE POSSIBLE
;* BIT SETTINGS
;*
CONTAB
        FCB     $05,$00,$00,$00	'BHI', NO C OR Z
        FCB     $05,$01,$04,$05	'BLS', EITHER C OR Z
        FCB     $01,$00,$00,$00	'BCC', NO C
        FCB     $01,$01,$01,$01	'BCS', C SET
        FCB     $04,$00,$00,$00	'BNE', NO Z
        FCB     $04,$04,$04,$04	'BEQ', Z SET
        FCB     $02,$00,$00,$00	'BVC', V CLEAR
        FCB     $02,$02,$02,$02	'BVS', V SET
        FCB     $08,$00,$00,$00	'BPL', N CLEAR
        FCB     $08,$08,$08,$08	'BMI', N SET
        FCB     $0A,$00,$0A,$0A	'BGE', N=V
        FCB     $0A,$08,$02,$02	'BLT', N -= V
        FCB     $0E,$0A,$00,$00	'BGT', N=V, Z=0
        FCB     $0E,$08,$02,$04	'BLE', V-=N OR Z=1
        FCB     $0C,$06,$0E
;* TRANSFER AND EXCHANGE REGISTER TABLE
TFREGT
        FDB     SAVA
INDTAB
        FDB     SAVX
        FDB     SAVY
        FDB     SAVU
        FDB     SAVS
        FDB     SAVPC
;* PULL TABLE FOR PULS
PULSTAB
        FDB     SAVCC
        FDB     SAVA
        FDB     SAVB
        FDB     SAVDP
        FDB     SAVX
        FDB     SAVY
        FDB     SAVU
        FDB     SAVPC
;* PULL TABLE FOR PULU
PULUTAB
        FDB     SAVCC
        FDB     SAVA
        FDB     SAVB
        FDB     SAVDP
        FDB     SAVX
        FDB     SAVY
        FDB     SAVS
        FDB     SAVPC
;*
GETCHR
        PSHS    B,X
        LDB     >DEVICE
        BSR     DOSSR
        FCB     37
        PULS    B,X,PC
;*
RDCON
        PSHS    B,X
        LDB     >DEVICE
        BSR     DOSSR
        FCB     38                                ;READ CHAR SSR 37
        PULS    B,X,PC
;*
WRCON
        PSHS    B,X
        LDB     >DEVICE
        BSR     DOSSR
        FCB     36                                ;WRITE CHAR SSR 36
        PULS    B,X,PC
;* FAKE SYSTEM CALL
DOSSR
        PSHS    CC,A,B,DP,X,Y,U
        JMP     [SWIADR]
