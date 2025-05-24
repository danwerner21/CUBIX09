;*
;* MON09: A software debug monitor for the 6809
;*
;* The monitor is currently setup to run on a system which has 8K of ROM
;* (for MON09) at the top of the memory may ($E000-$FFFF), and RAM
;* from $0000-$BFFF. The 256 byte block from $DF00-$DFFF is used for I/O devices
;* etc. MON09 uses 256 bytes of memory at the very top of available RAM,
;* and the user stack pointer is initialized to point to the beginning of
;* this area, allowing the user stack to grow downward into free user RAM.
;*
;* ?COPY.TXT 1985-2007 Dave Dunfield
;* **See COPY.TXT**.
;*
;*
;*   Modified for the 6809PC board by D. Werner 5/17/2025
;*   Single 6551 UART supported at 9600,n,8,1
;*
;*   Commands have been removed to conserve
;*   ROM space


;* HARDWARE INFORMATION
ROM             EQU $F000                         ; MON09 code goes here
RAM             EQU $BF00                         ; MON09 data goes here
STACK           EQU RAM+$F0                       ; MON09 Stack (Top of RAM)
;*
IOSPACE         EQU $EF00
UART1DATA       EQU IOSPACE+$84                   ; SERIAL PORT 1 (I/O Card)
UART1STATUS     EQU IOSPACE+$85                   ; SERIAL PORT 1 (I/O Card)
UART1COMMAND    EQU IOSPACE+$86                   ; SERIAL PORT 1 (I/O Card)
UART1CONTROL    EQU IOSPACE+$87                   ; SERIAL PORT 1 (I/O Card)
;*
;*
        ORG     RAM                               ;Internal MON09 variables
;*
;* MON09 INTERNAL MEMORY
;*
SWIADR:
        RMB     2                                 ;SWI VECTOR ADDRESS
SWI2ADR:
        RMB     2                                 ;SWI2 VECTOR ADDRESS
SWI3ADR:
        RMB     2                                 ;SWI3 VECTOR ADDRESS
IRQADR:
        RMB     2                                 ;IRQ VECTOR ADDRESS
FIRQADR:
        RMB     2                                 ;FIRQ VECTOR ADDRESS
SAVCC:
        RMB     1                                 ;SAVED CONDITION CODE REGISTER
SAVA:
        RMB     1                                 ;SAVED 6809 A REGISTER
SAVB:
        RMB     1                                 ;SAVED 6809 B REGISTER
SAVDP:
        RMB     1                                 ;SAVED DIRECT PAGE REGISTER
SAVX:
        RMB     2                                 ;SAVED X REGISTER
SAVY:
        RMB     2                                 ;SAVED Y REGISTER
SAVU:
        RMB     2                                 ;SAVED U REGISTER
SAVPC:
        RMB     2                                 ;SAVED PROGRAM COUNTER
SAVS:
        RMB     2                                 ;SAVED S REGISTER
TEMP:
        RMB     2                                 ;TEMPORARY STORAGE
STPFLG:
        RMB     1                                 ;REGISTER DISPLAY WHILE STEPPING FLAG
PTRSAV:
        RMB     2                                 ;SINGLE STEP AND DISASSEMBLER CODE POINTER
INSTYP:
        RMB     1                                 ;DISASSEMBLED INSTRUCTION TYPE
POSBYT:
        RMB     1                                 ;POSTBYTE STORAGE AREA
BRKTAB:
        RMB     24                                ;BREAKPOINT TABLE
DSPBUF:
        RMB     50                                ;DISASSEMBLER DISPLAY BUFFER
INSRAM:
        RMB     7                                 ;INSTRUCTION EXECUTION ADDRESS
;*
        ORG     ROM                               ;MONITOR CODE
;*
;* INITIALIZATIONS.
;*
RESET:
        LDS     #STACK                            ;SET UP STACK

        LDX     #SWIADR                           ;POINT TO START
CLRRAM:
        CLR     ,X+                               ;CLEAR IT
        CMPX    #INSRAM                           ;AT BUFFER?
        BLO     CLRRAM                            ;KEEP GOING

        LBSR    INIT                              ;INITIALIZE UART
        LDD     #RAM                              ;DEFAULT STACK AT TOP OF RAM
        STD     SAVS                              ;SAVE IT
        LDA     #$D0                              ;SET CC
        STA     SAVCC                             ;SAVE IT
MONITOR:
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCB     $0A,$0D,$0A,$0D,$0A,$0D
        FCC     '  ____ ___  ___  ___  ___  _____'
        FCB     $0A,$0D
        FCC     ' / __/( _ )/ _ \/ _ \/ _ \/ ___/'
        FCB     $0A,$0D
        FCC     '/ _ \/ _  / // /\_, / ___/ /__'
        FCB     $0A,$0D
        FCC     '\___/\___/\___//___/_/   \___/'
        FCB     $0A,$0D
        FCC     'MON09 Version 3.3a   1985-2007 Dave Dunfield'
        FCB     $0A,$0D
        FCC     '** Press ? for a list of commands **'
        FCB     $0A,$FF
MAIN
        LDS     #STACK                            ;FIX STACK IN CASE ERROR
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCN     '* '
        LBSR    GETECH                            ;GET CHARACTER
        CLRB                                      ;INDICATE NO SECOND CHAR
;* LOOK FOR COMMAND IN TABLE
LOOKC
        LDX     #CMDTAB                           ;POINT TO COMMAND TABLE
        CLR     TEMP                              ;INDICATE NO PARTIAL MATCH
LOOK1
        CMPD    ,X++                              ;DOES IT MATCH
        BEQ     LOOK3                             ;YES IT DOES
        CMPA    -2,X                              ;DOES FIRST CHAR MATCH?
        BNE     LOOK2                             ;NO, DON'T RECORD
        DEC     TEMP                              ;SET FLAG
LOOK2
        LEAX    2,X                               ;ADVANCE TO NEXT
        TST     ,X                                ;HAVE WE HIT THE END
        BNE     LOOK1                             ;NO, KEEP LOOKING
        TSTB                                      ;ALREADY HAVE TWO CHARS?
        BNE     ERROR                             ;YES, ERROR
        LDB     TEMP                              ;ANY PARTIAL MATCHES?
        BEQ     ERROR                             ;NO, ERROR
        TFR     A,B                               ;SAVE CHAR IN 'A'
        LBSR    GETECH                            ;GET NEXT CHAR
        EXG     A,B                               ; SWAP BACK
        BRA     LOOKC                             ;AND CONTINUE
;* COMMAND WAS FOUND, EXECUTE IT
LOOK3
        LBSR    SPACE                             ;OUTPUT SPACE
        JSR     [,X]                              ;EXECUTE COMMAND
        BRA     MAIN                              ;AND RETURN
;* ERROR HAS OCCURED
ERROR
        LBSR    WRMSG                             ;OUTPUT MESSAGE
        FCC     ' ?'
        FCB     $FF
        BRA     MAIN                              ; TRY AGAIN
;* COMMAND LOOKUP TABLE
CMDTAB
        FCB     'D','M'                           ; DISPLAY MEMORY
        FDB     MEMORY
        FCB     'D','I'                           ; DISASSEMBLE
        FDB     DISREG
        FCB     'D','V'                           ;DISPLAY VECTORS
        FDB     DISVEC
        FCB     'C','R'                           ;CHANGE REGISTER
        FDB     CHGREG
        FCB     'C','V'                           ;CHANGE VECTORS
        FDB     CHGVEC
        FCB     'E',0                             ;SUBSTITUTE MEMORY
        FDB     SUBMEM
        FCB     'L',0                             ;DOWNLOAD
        FDB     LOAD
        FCB     'G',0                             ;GO
        FDB     GOEXEC
        FCB     'F','M'                           ;FILL MEMORY
        FDB     FILMEM
        FCB     'R','R'                           ;REPEATING READ
        FDB     RDLOOP
        FCB     'R','W'                           ;REPEATING WRITE
        FDB     WRLOOP
        FCB     'W',0                             ;WRITE MEMORY
        FDB     WRIMEM
        FCB     'M','M'                           ;MOVE MEMORY
        FDB     MOVMEM
        FCB     'X','R'                           ;REPEATING 16 BIT READ
        FDB     XRLOOP
        FCB     'X','W'                           ;REPEATING 16 BIT WRITE
        FDB     XWLOOP
        FCB     '+',0                             ;HEX ADDITION
        FDB     HEXADD
        FCB     '-',0                             ;HEX SUBTRACTION
        FDB     HEXSUB
        FCB     '?',0                             ;HELP COMMAND
        FDB     HELP
        FCB     0                                 ;MARK END OF TABLE
;*
;* 'F' - FILL MEMORY
;*
FILMEM
        LBSR    GETRNG                            ;GET ADDRESSES
        STD     TEMP                              ;SAVE IT
        LBSR    SPACE                             ;SPACE OVER
        LBSR    GETBYT                            ;GET DATA BYTE
        BNE     ERROR                             ;INVALID
FILL1
        STA     ,X+                               ;WRITE IT
        CMPX    TEMP                              ;ARE WE THERE
        BLS     FILL1                             ;NO, KEEP GOING
        LBRA    LFCR                              ;NEW LINE
;*
;* 'MM' - MOVE MEMORY
;*
MOVMEM
        LBSR    GETRNG                            ;GET A RANGE
        STD     TEMP                              ;SAVE LAST VALUE
        LBSR    SPACE                             ;SEPERATOR
        LBSR    GETADR                            ;GET DEST ADDRESS
        TFR     D,Y                               ;SET IT UP
MOVM1
        LDA     ,X+                               ;GET SOURCE BYTE
        STA     ,Y+                               ;SAVE IN DEST
        CMPX    TEMP                              ;SAVE IT
        BLS     MOVM1                             ;KEEP MOVEING
        LBRA    LFCR                              ;NEW LINE
;*
;* 'DM' - DISPLAY MEMORY
;*
MEMORY
        LBSR    GETRNG                            ;GET ADDRESS
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
        DECB                                      ;REDUCE COUNT
        BNE     MEM2                              ;CONTINUE
        LDB     #4                                ;FOUR SPACE
MEM4
        LBSR    SPACE                             ;DISPLAY A SPACE
        DECB                                      ;REDUCE COUNT
        BNE     MEM4                              ; CONTINUE
        PULS    X                                 ;RESTORE X
        LDB     #16                               ;COUNT OF 16
MEM5
        LDA     ,X+                               ;GET CHAR
        CMPA    #' '                              ; <SPACE
        BLO     MEM6                              ; CONVERT TO DOT
        CMPA    #$7F                              ; PRINTABLE?
        BLO     MEM7                              ; OK TO DISPLAY
MEM6
        LDA     #'.'                              ;CHANGE TO DOT
MEM7
        LBSR    PUTCHR                            ;OUTPUT
        DECB                                      ;REDUCE COUNT
        BNE     MEM5                              ; DISPLAY THEM ALL
        CMPX    TEMP                              ; PAST END?
        BLS     MEM1                              ; NO, KEEP GOING
        LBRA    LFCR                              ; NEW LINE
;*
;* 'W' - WRITE TO MEMORY
;*
WRIMEM
        LBSR    GETADR                            ;GET ADDRESS
        TFR     D,X                               ;SET IT UP
        LBSR    SPACE                             ; STEP OVER
        LBSR    GETBYT                            ;GET BYTE
        STA     ,X                                ;WRITE TO MEMORY
        LBRA    LFCR                              ; NEW LINE
;*
;* 'E' - EDIT MEMORY
;*
SUBMEM
        LBSR    GETADR                            ;GET ADDRESS
        TFR     D,X                               ;COPY
SUBM1
        LBSR    LFCR                              ; NEW LINE
        TFR     X,D                               ;GET ADDRESS
        LBSR    WRDOUT                            ; OUTPUT
        LDB     #8                                ;NEW COUNT
SUBM2
        LBSR    SPACE                             ; SEPERATOR
        LDA     ,X                                ;GET BYTE
        LBSR    HEXOUT                            ; DISPLAY
        LDA     #'-'                              ; PROMPT
        LBSR    PUTCHR                            ; OUTPUT
        LBSR    GETBYT                            ; GET A BYTE
        BNE     SUBM4                             ; INVALID
        STA     ,X                                ;RESAVE
SUBM3
        LEAX    1,X                               ;ADVANCE
        DECB                                      ;REDUCE COUNT
        BNE     SUBM2                             ;MORE, CONTINUE
        BRA     SUBM1                             ;NEW LINE
SUBM4
        CMPA    #$0D                              ;CR?
        LBEQ    LFCR                              ;IF SO, QUIT
        CMPA    #' '                              ;SPACE?
        BNE     SUBM5                             ;NO
        LBSR    SPACE                             ;FILL FOR TWO DIGITS
        BRA     SUBM3                             ;ADVANCE
SUBM5
        CMPA    #$08                              ; BACKSPACE?
        LBNE    ERROR                             ; INVALID
        LEAX    -1,X                              ; BACKUP
        BRA     SUBM1                             ; NEW LINE
;*
;* 'DV' - DISPLAY VECTORS
;*
DISVEC
        LDX     #VECTXT                           ; POINT TO VECTOR TEXT
        LDY     #SWIADR                           ; POINT TO FIRST VECTOR
DISV1
        LBSR    WRLIN                             ; OUTPUT A MESSAGE
        LDD     ,Y++                              ; GET A VECTOR
        LBSR    WRDOUT                            ; OUTPUT VECTOR ADDRESS
        LDA     ,X                                ;MORE TEXT?
        BNE     DISV1                             ; AND CONTINUE
        LBRA    LFCR                              ; NEW LINE
VECTXT
        FCN     'SWI='
        FCN     ' SWI2='
        FCN     ' SWI3='
        FCN     ' IRQ='
        FCN     ' FIRQ='
        FCB     0                                 ; END OF TABLE
;*
;* 'CV' - CHANGE VECTOR
;*
CHGVEC
        LBSR    GETECH                            ;GET CHAR & ECHO
        CMPA    #'S'                              ;SWI?
        BNE     CHGV1                             ;NO
        LDA     #'1'                              ;SAME AS '1'
        BRA     CHGV3                             ;CONTINUE
CHGV1
        CMPA    #'I'                              ;IRQ?
        BNE     CHGV2                             ;NO, ITS OK
        LDA     #'4'                              ;CONVERT
        BRA     CHGV3                             ;AND CONTINUE
CHGV2
        CMPA    #'F'                              ;FIRQ?
        BNE     CHGV3                             ;NO
        LDA     #'5'                              ;CONVERT
CHGV3
        SUBA    #'1'                              ;TEST IT
        CMPA    #4                                ;CHECK RANGE
        LBHI    ERROR                             ; INVALID
        LDX     #SWIADR                           ;POINT TO IT
CHGV4
        LSLA                                      ;X2 FOR 2 BYTE ENTRIES
        LEAX    A,X     ADVANCE TO VECTOR
        LBSR    SPACE                             ; SEPERATOR
        LBSR    GETADR                            ;GET NEW VALUE
        STD     ,X                                ; WRITE NEW VECTOR
        LBRA    LFCR                              ; NEW LINE & EXIT
;*
;* 'DR' - DISPLAY REGISTERS
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
        LDA     ,U+                               ; GET BIT IDENTIFIER
        ASLB                                      ;IS IT SET?
        BCS     RBITS                             ;YES, DISPLAY IT
        LDA     #'-'                              ;NO, DISPLAY DASH
RBITS
        LBSR    PUTCHR                            ; OUTPUT A CHARACTER
        LEAY    -1,Y                              ; REDUCE COUNT
        BNE     REGB1                             ; MORE TO GO
        PULS    Y                                 ; RESTORE Y
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
        LDA     ,Y+                               ; GET REGISTER VALUE
        LBRA    HEXOUT                            ;OUTPUT IN HEX
;* DISPLAY 16 BIT REGISTER VALUE
RSUB2
        LBSR    WRLIN                             ; OUTPUT WORD VALUE
        LDD     ,Y++                              ; GET REGISTER VALUE
        LBRA    WRDOUT                            ; OUTPUT IN HEX
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
;* 'CR' - CHANGE REGISTER
;*
CHGREG
        LBSR    GETECH      GET OPERAND
        CMPA    #' '        A+B?
        BEQ     CHG4        YES
        LDX     #CHGTAB     POINT TO TABLE
        CLRB    ZERO INDICATOR
CHG1
        CMPA    ,X      IS THIS IT?
        BEQ     CHG2        YES
        INCB    ADVANCE COUNT
        TST     ,X+     END OF TABLE
        BNE     CHG1        NO, KEEP TRYING
        LBRA    ERROR       INDICATE ERROR
CHG2
        LBSR    SPACE       OUTPUT SPACE
        LDX     #SAVCC      POINT TO START OF REGISTERS
        CMPB    #4      16 BIT?
        BHS     R16     YES
        LEAX    B,X     OFFSET TO ADDRESS
        LBSR    GETBYT      GET NEW VALUE
        LBNE    ERROR       INVALID
        STA     ,X      SAVE IN REGISTER
        BRA     CHG3        AND QUIT
CHG4
        LBSR    WRMSG       OUTPUT MESSAGE
        FCN     '[AB] '
        LDX     #SAVA       POINT TO 'D'
        BRA     R17     MAKE LIKE 16 BIT REG
R16
        LEAX    4,X     OFFSET TO 16 BIT REGISTERS
        SUBB    #4      CONVERT TO ZERO ORIGIN
        LSLB    DOUBLE FOR WORD VALUES
        LEAX    B,X     MOVE TO CORRECT OFFSET
R17
        LBSR    GETADR      GET WORD VALUE
        STD     ,X      SET REGISTER VALUE
CHG3
        LBRA    LFCR        QUIT
;* TABLE OF REGISTER NAMES
CHGTAB
        FCN     'CABDXYUPS'
;*
;* 'G' - GO (EXECUTE)
;*
GOEXEC
        LBSR    GETPC       GET ADDRESS
        LBSR    LFCR        NEW LINE
        LDS     SAVS        RESTORE STACK POINTER
        LDA     SAVCC       GET SAVED CC
        LDB     SAVDP       GET SAVED DPR
        PSHS    A,B     SAVE ON STACK FOR LAST RESTORE
        LDD     SAVA        RESTORE A, B REGISTERS
        LDX     SAVX        RESTORE X REGISTER
        LDY     SAVY        RESTORE Y REGISTER
        LDU     SAVU        RESTORE U REGISTER
        PULS    CC,DP       RESTORE CC + DP
        JMP     [SAVPC]     EXECUTE USER PGM
;*
;* 'RR' - REPEATING READ
;*
RDLOOP:
        LBSR    GETADR                            ;GET ADDRESS
        TFR     D,X                               ;SET UP 'X'
        LBSR    LFCR                              ;NEW LINE
RDLP1:
        LDA     ,X                                ;READ LOCATION
        LBSR    CHKCHR                            ;ABORT?
        BNE     RDLP1                             ;NO, ITS OK
        RTS
;*
;* 'RW' - REPEATING WRITE
;*
WRLOOP:
        LBSR    GETADR                            ;GET ADDRESS
        TFR     D,X                               ;SET UP 'X'
        LBSR    SPACE                             ;SPACE OVER
        LBSR    GETBYT                            ;GET DATA
        LBNE    ERROR                             ;INVALID
        PSHS    A                                 ;SAVE ACCA
        LBSR    LFCR                              ;NEW LINE
WRLP1:
        LDA     ,S                                ;GET CHAR
        STA     ,X                                ;WRITE IT OUT
        LBSR    CHKCHR                            ;ABORT COMMAND?
        BNE     WRLP1                             ;CONTINUE
        PULS    A,PC                              ;GO HOME
;*
;* 'XR' - REPEATING 16 BIT READ
;*
XRLOOP
        LBSR    GETADR      GET ADDRESS
        TFR     D,X     SET UP 'X'
        LBSR    LFCR        NEW LINE
XRLP1
        LDD     ,X      READ LOCATION
        LBSR    CHKCHR      ABORT?
        BNE     XRLP1       NO, ITS OK
        RTS
;*
;* 'XW' - REPEATING 16 BITWRITE
;*
XWLOOP
        LBSR    GETADR      GET ADDRESS
        TFR     D,X     SET UP 'X'
        LBSR    SPACE       SPACE OVER
        LBSR    GETADR      GET DATA
        PSHS    A,B     SAVE ACCA
        LBSR    LFCR        NEW LINE
XWLP1
        LDD     ,S      GET CHAR
        STD     ,X      WRITE IT OUT
        LBSR    CHKCHR      ABORT COMMAND?
        BNE     XWLP1       CONTINUE
        PULS    A,B,PC      GO HOME
;*
;* '+' - HEXIDECIMAL ADDITION
;*
HEXADD
        LBSR    GETADR      GET FIRST VALUE
        PSHS    A,B     SAVE IT
        LDA     #'+'        PLUS SIGN
        LBSR    PUTCHR      DISPLAY
        LBSR    GETADR      GET SECOND VALUE
        ADDD    ,S      PERFORM ADDITION
        BRA     HEXSHO      DISPLAY IT
;*
;* '-' - HEXIDECIMAL SUBTRACTION
;*
HEXSUB
        LBSR    GETADR      GET FIRST
        PSHS    A,B     SAVE IT
        LDA     #'-'        MINUS SIGN
        LBSR    PUTCHR      DISPLAY
        LBSR    GETADR      GET SECOND ADDRESS
        PSHS    A,B     SAVE IT
        LDD     2,S     GET FIRST VALUE
        SUBD    ,S++        PERFORM SUBTRACTION
HEXSHO
        STD     ,S      SAVE RESULT
        LDA     #'='        =ALS SIGN
        LBSR    PUTCHR      DISPLAY
        PULS    A,B     RESTORE RESULT
        LBSR    WRDOUT      OUTPUT
        LBRA    LFCR        NEW LINE & RETURN
;*
;* '?' - HELP COMMAND
;*
HELP
        LDX     #HTEXT      POINT TO HELP TEXT
HLP1
        LDB     #25     COLUMN COUNTER
HLP2
        LDA     ,X+     GET CHAR FROM TEXT
        BEQ     HLP4        EXIT THIS LINE
        CMPA    #'|'        SEPERATOR?
        BEQ     HLP3        YES, EXIT
        LBSR    PUTCHR      OUTPUT
        DECB    BACKUP
        BRA     HLP2        NEXT
HLP3
        LBSR    SPACE       OUTPUT SPACE
        DECB    REDUCE COUNT
        BNE     HLP3        KEEP GOING
        LBSR    WRMSG       OUTPUT MESSAGE
        FCN     '- '        SEPERATOR
        BRA     HLP2        AND CONTINUE
HLP4
        LBSR    LFCR        NEW LINE
        LBSR    CHKCHR      TEST FOR CHARACTER ENTERED
        BEQ     HLP5        IF SO, EXIT
        LDA     ,X      IS THIS THE END?
        BPL     HLP1        NO, KEEP GOING
HLP5
        RTS
;*
;* 'DL' - DOWNLOAD
;*
LOAD
        LBSR    LFCR        NEW LINE
DLO1
        BSR     DLOAD       DOWNLOAD RECORD
        BCC     DLO2        END
        LDA     ,S      GET OLD I/O CONFIG
        LDA     #'.'        GET DOT
        LBSR    PUTCHR      OUTPUT
        BRA     DLO1        CONTINUE
DLO2
        LBRA    LFCR        New line & return
;* Download a record in either MOTOROLA or INTEL hex format
DLOAD
        LBSR    GETCHR      Get a character
        CMPA    #':'        Start of INTEL record?
        BEQ     DLINT       Yes, download INTEL
        CMPA    #'S'        Start of MOTOROLA record?
        BNE     DLOAD       No, keep looking
;* Download a record in MOTOROLA hex format
DLMOT
        LBSR    GETCHR      GET NEXT CHAR
        CMPA    #'0'        HEADER RECORD?
        BEQ     DLOAD       SKIP IT
        CMPA    #'9'        END OF FILE?
        BEQ     DLEOF       END OF FILE
        CMPA    #'1'        DATA RECORD?
        BNE     LODERR      LOAD ERROR
        LBSR    GETBYT      GET LENGTH
        BNE     LODERR      Report error
        STA     TEMP        START CHECKSUM
        SUBA    #3      CONVERT
        STA     TEMP+1      Set length
        LBSR    GETBYT      Get first byte of address
        BNE     LODERR      Report error
        TFR     A,B     Save for later
        ADDA    TEMP        Include in checksum
        STA     TEMP        Resave
        LBSR    GETBYT      Get next byte of address
        BNE     LODERR      Report error
        EXG     A,B     Swap
        TFR     D,X     Set pointer
        ADDB    TEMP        Include in checksum
        STB     TEMP        Resave checksum
DLMOT1
        LBSR    GETBYT      Get a data byte
        STA     ,X+     Save in RAM
        ADDA    TEMP        Include checksum
        STA     TEMP        Resave
        DEC     TEMP+1      Reduce length
        BNE     DLMOT1      Do them all
        LBSR    GETBYT      Get a byte
        ADDA    TEMP        Add computed checksum
        INCA    Test for success
        BEQ     DLRTS       Download OK
;* Error occured on loading
LODERR
        LBSR    WRMSG       OUTPUT
        FCC     ' ?Load error'
        FCB     $FF
        LBRA    MAIN        BACK FOR COMMAND
;* Return indicating another record
DLRTS
        ORCC    #$01        SET 'C' FLAG
DLEOF
        RTS
;* Download record in INTEL format
DLINT
        LBSR    GETBYT      Get count
        BNE     LODERR      Report error
        STA     TEMP        Start checksum
        STA     TEMP+1      Record length
        CMPA    #0      Test & clear C
        BEQ     DLEOF       End of file
;* Get address
        LBSR    GETBYT      Get first byte of address
        BNE     LODERR      Report error
        TFR     A,B     Save for later
        ADDA    TEMP        Include in checksum
        STA     TEMP        Resave
        LBSR    GETBYT      Get next byte of address
        BNE     LODERR      Report error
        EXG     A,B     Swap
        TFR     D,X     Set pointer
        ADDB    TEMP        Include in checksum
        STB     TEMP        Resave checksum
;* Get record type
        LBSR    GETBYT      Get type value
        BNE     LODERR      Report error
        ADDA    TEMP        Include checksum
        STA     TEMP        Resave checksum
;* Get data bytes
DLINT1
        LBSR    GETBYT      Get data byte
        BNE     LODERR      Report error
        STA     ,X+     Write to memory
        ADDA    TEMP        Include checksum
        STA     TEMP        Resave checksum
        DEC     TEMP+1      Reduce length
        BNE     DLINT1      Do them all
;* Get checksum
        JSR     GETBYT      Read a byte
        BNE     LODERR      Report error
        ADDA    TEMP        Include checksum
        BEQ     DLRTS       Report success
        BRA     LODERR      Report failure
;*
;* GETS AN ADDRESS, DEFAULTS TO (PC)
;*
GETPC
        BSR     GETAD1      Get address
        BEQ     GETPC1      Normal data
        CMPA    #' '        Space?
        BNE     GETERR      Report error
        LBSR    WRMSG       Output message
        FCN     '->'        Display address
        LDD     SAVPC       Get PC value
        LBRA    WRDOUT      Display
GETPC1
        STD     SAVPC       Set new PC
        RTS
;*
;* GETS A RANGE OF ADDRESS, RETURNS WITH START IN X, END IN D
;*
GETRNG
        BSR     GETADR      Get first address
        TFR     D,X     Save in X
        LDA     #','        Separator
        LBSR    PUTCHR      Display
        BSR     GETAD1      Get second address
        BEQ     DLEOF       Normal data
        CMPA    #' '        Space?
        BNE     GETERR      No, report error
        LBSR    WRMSG       Output message
        FCN     'FFFF'
        LDD     #$FFFF      Assume top of RAM
        RTS
;*
;* GETS AN ADDRESS (IN D) FROM THE INPUT DEVICE
;*
GETADR
        BSR     GETAD1      Get word value
        BEQ     GETAD2      Its OK
GETERR
        LBRA    ERROR       Report error
;* Get word value without error checking
GETAD1
        BSR     GETBYT      Get HIGH byte
        BNE     GETAD3      Test for special register
        TFR     A,B     Copy for later
        BSR     GETBYT      Get LOW byte
        BNE     GETERR      Report error
        EXG     A,B     Correct order
GETAD2
        RTS
;* Handle special register names
GETAD3
        PSHS    X       Save X
        LDX     SAVX        Assume X
        CMPA    #'X'        Is it X?
        BEQ     GETAD4      Yes
        LDX     SAVY        Assume Y
        CMPA    #'Y'        Is it Y?
        BEQ     GETAD4      Yes
        LDX     SAVU        Assume U
        CMPA    #'U'        Is it U?
        BEQ     GETAD4      Yes
        LDX     SAVX        Assume S
        CMPA    #'S'        Is it S?
        BEQ     GETAD4      Yes
        LDX     SAVPC       Assume PC?
        CMPA    #'P'        Is it PC?
        BNE     GETAD5      No, error
GETAD4
        LDA     #'='        Separator
        LBSR    PUTCHR      Echo it
        TFR     X,D     D = value
        BSR     WRDOUT      Display it
        CLRA    Set 'Z'
        TFR     X,D     Get value back
GETAD5
        PULS    X,PC        Restore & return
;*
;* GETS A SINGLE BYTE (IN HEX) FROM THE INPUT DEVICE
;*
GETBYT
        BSR     GETNIB      Get FIRST nibble
        BNE     GETB3       Invalid, test for quote
        LSLA    Rotate
        LSLA    into
        LSLA    high
        LSLA    nibble
        PSHS    A       Save for later
        BSR     GETNIB      Get SECOND nibble
        BNE     GETB2       Report error
        ORA     ,S      Include high
GETB4
        ORCC    #$04        Indicate success (SET 'Z')
GETB2
        LEAS    1,S     Skip saved value
GETB1
        RTS
GETB3
        CMPA    #$27        Single quote?
        BNE     GETB1       No, abort
        LBSR    GETCHR      Get ASCII character
        LBSR    PUTCHR      Echo on terminal
        ORCC    #$04        Indicate success (SET 'Z')
        RTS
;*
;* GETS A SINGLE HEX NIBBLE FROM THE INPUT DEVICE
;*
GETNIB
        LBSR    GETECH      Get character
        SUBA    #'0'        Convert numbers
        CMPA    #9      Numeric?
        BLS     GETN1       Yes, OK
        SUBA    #7      Convert alphas
        CMPA    #$A     Under?
        BLO     GETN2       Yer, error
        CMPA    #$F     Over?
        BHI     GETN2       Yes, error
GETN1
        ORCC    #$04        SET 'Z' FLAG, INDICATE OK
        RTS
GETN2
        ADDA    #$37        Normalize character + clear Z
        RTS
;*
;* OUTPUT A WORD (IN HEX) FROM REGISTER D
;*
WRDOUT
        BSR     HEXOUT      Output first byte
        TFR     B,A     Get second byte
;*
;* OUTPUT A BYTE (IN HEX) FROM REGISTER A
;*
HEXOUT
        PSHS    A       Save low nibble
        LSRA    Rotate
        LSRA    upper nibble
        LSRA    into
        LSRA    lower nibble
        BSR     HOUT        Output high nibble
        PULS    A       Rertore low nibble
;*
;* OUTPUT A NIBBLE (IN HEX) FROM REGISTER A
;*
HOUT:
        ANDA    #$0F                              ; Remove upper half
        ADDA    #'0'                              ; Convert to printable
        CMPA    #'9'                              ; In range?
        BLS     HOUT1                             ; Yes, display
        ADDA    #7                                ;Convert to alpha
HOUT1:
        BRA     PUTCHR                            ; Output character
;*
;* WRITE ERROR MESSAGE FOLLOWING TEXT
;*
WRMSG:
        PSHS    X                                 ;SAVE X
        LDX     2,S                               ;GET OLD PC
        BSR     WRLIN                             ;OUTPUT LINE
        STX     2,S                               ;UPDATE OLD PC
        PULS    X,PC                              ;RESTORE X, RETURN
;*
;* DISPLAY MESSAGE(X)
;*
WRLIN:
        LDA     ,X+                               ;GET CHAR FROM MESSAGE
        BEQ     WRLND                             ;END, QUIT
        CMPA    #$FF                              ;NEWLINE END, LFCR & EXIT
        BEQ     LFCR                              ;IF SO, NEW LINE, RETURN
        BSR     PUTCHR                            ;OUTPUT TO TERM
        BRA     WRLIN                             ;KEEP GOING
WRLND
        RTS
;*
;* GET CHAR. FROM TERMINAL, AND ECHO
;*
GETECH:
        BSR     GETCHR                            ;GET CHARACTER
        CMPA    #' '                              ;SPACE?
        BLS     WRLND                             ;IF < DON'T DISPLAY
        CMPA    #$61                              ;LOWER CASE?
        BLO     PUTCHR                            ;OK
        ANDA    #$5F                              ;CONVERT TO UPPER
        BRA     PUTCHR                            ;ECHO
;*
;* DISPLAY A SPACE ON THE TERMINAL
;*
SPACE:
        PSHS    A                                 ;SAVE A
        LDA     #' '                              ;GET SPACE
        BRA     LFC1                              ;DISLAY AND GO HOME
;*
;* DISPLAY LINE-FEED, CARRIAGE RETURN ON TERMINAL
;*
LFCR:
        PSHS    A                                 ;SAVE
        LDA     #$0A                              ;GET LF
        BSR     PUTCHR                            ;OUTPUT
        LDA     #$0D                              ;GET CR
LFC1:
        BSR     PUTCHR                            ;OUTPUT
        PULS    A,PC                              ;RESTORE AND GO HOME
;*
;* READ A CHARACTER FROM SELECTED INPUT DEVICE
;*
GETCHR:
        PSHS    X                                 ;SAVE 'X'
GETC1:
        LBSR    READ                              ;READ TERMINAL
        CMPA    #$FF
        BEQ     GETC1                             ;KEEP TRYING
        PULS    X,PC
;*
;* WRITE A CHARACTER TO ALL ENABLED OUTPUT DEVICES
;*
PUTCHR:
        PSHS    A,B,X                             ;SAVE REGS
        LBSR    WRITE                             ;OUTPUT TO TERMINAL
        PULS    A,B,X,PC                          ;RESTORE AND GO HOME
;*
;* CHECK FOR <ESC> FROM TERMINAL. ALSO PERFORM <SPACE>, <CR>
;* SCREEN OUTPUT FLOW CONTROL.
;*
CHKCHR:
        PSHS    X                                 ;SAVE PTR
        LBSR    READ                              ;READ TERMINAL
        CMPA    #' '                              ;SPACE?
        BNE     CHKC3                             ;NO, IGNORE IT
CHKC1:
        ORB     #%10000000                        ;SET HELD BIT
        LBSR    READ                              ;GET KEY FROM CONSOLE
        CMPA    #' '                              ;SPACE?
        BEQ     CHKC3                             ;YES, ALLOW
        ANDB    #%01111111                        ;DISABLE HELD BIT
        CMPA    #$0D                              ;CARRIAGE RETURN?
        BEQ     CHKC3                             ;ALLOW
        CMPA    #$1B                              ;ESCAPE?
        BNE     CHKC1                             ;NO, IGNORE
CHKC3:
        CMPA    #$1B                              ;TEST FOR ESCAPE CHARACTER
        PULS    X,PC
;*
;* SUBROUTINES
;*
WRHEXB
        PSHS    A       SAVE IT
        LDA     #'$'        INDICATE HEX
        STA     ,U+     SAVE
        BRA     WRHEX1      CONTINUE
WRHEXW
        PSHS    B       SAVE B
        LDB     #'$'        INDICATE HEX
        STB     ,U+     SAVE IT
        BSR     WRHEX       OUTPUT
WRHEX1
        PULS    A       RESTORE
WRHEX
        PSHS    A       SAVE IT
        LSRA    SHIFT
        LSRA    HIGH BYTE
        LSRA    INTO
        LSRA    LOW FOR OUTPUT
        BSR     WRHEXN      OUTPUT NIBBLE
        PULS    A       RETORE
WRHEXN
        ANDA    #$0F        REMOVE CRAP
        ADDA    #$30        CONVERT
        CMPA    #$39        OK?
        BLS     WRNOK       OK
        ADDA    #7      CONVERT
WRNOK
        STA     ,U+     SAVE IT
        RTS
;*
;* NMI HANDLER
;*
NMIHND
        LDX     #SAVCC      POINT TO START OF SAVED REGS
        LDB     #12     MOVE 12 BYTES
NMIH1
        LDA     ,S+     GET BYTE
        STA     ,X+     SAVE
        DECB    DECREMENT COUNT
        BNE     NMIH1       DO THEM ALL
        STS     SAVS        SAVE STACK POINTER
        LBSR    WRMSG       DISPLAY MESSAGE
        FCC     '*** NMI Interrupt ***'
        FCB     $FF     NEW LINE
        BRA     BRKREG      DISPLAY REGISTERS
;*
;* SWI HANDLER
;*
SWIHND
        LDY     #BRKTAB     POINT TO BREAKPOINT TABLE
        LDX     10,S        GET STORED PC
        LEAX    -1,X        BACKUP TO BREAKPOINT ADDRESS
        LDB     #8      CHECK EIGHT BREAKPOINTS
SWIHN1
        CMPX    ,Y      IS THIS IT?
        BEQ     SWIHN2      YES
        LEAY    3,Y     SKIP OPCODE
        DECB    REDUCE COUNT
        BNE     SWIHN1      CONTINUE
        LDB     2,S     RESTORE B.
        LDX     4,S     RESTORE X.
        LDY     6,S     RESTORE Y.
        JMP     [SWIADR]    NOT A BREAKPOINT, EXECUTE SWI HANDLER
SWIHN2
        STB     INSTYP      SAVE BREAKPOINT NUMBER
        LDX     #SAVCC      POINT TO START OF SAVED REGS
        LDB     #10     MOVE 10
SWIHN25
        LDA     ,S+     GET BYTE
        STA     ,X+     SAVE
        DECB    DECREMENT COUNT
        BNE     SWIHN25     DO THEM ALL
        PULS    X       GET PC
        LEAX    -1,X        SET BACK TO REAL PC
        STX     SAVPC       SAVED PC
        STS     SAVS        SAVE STACK POINTER
        LBSR    WRMSG       DISPLAY MESSAGE
        FCN     '*** Breakpoint #'
        LDA     #$38        GET NUMBER, PLUS ASCII CONVERT
        SUBA    INSTYP      CONVERT TO PROPER DIGIT
        LBSR    PUTCHR      DISPLAY
        LBSR    WRMSG       OUTPUT MESSAGE
        FCC     ' ***'      TRAILING MESSAGE
        FCB     $FF     NEW LINE
BRKREG
        LBSR    DISREG      DISPLAY
BRKRES
        LDX     #BRKTAB     POINT TO BREAKPOINT TABLE
        LDB     #8      DO IT EIGHT TIMES
SWIHN3
        LDY     ,X++        GET REG
        BEQ     SWIHN4      NO BRK, NEXT
        LDA     ,X      GET OPCODE
        STA     ,Y      REPLACE IN RAM
SWIHN4
        LEAX    1,X     SKIP OPCODE
        DECB    REDUCE COUNT
        BNE     SWIHN3      GO AGAIN
        LBRA    MAIN        DO PROMPT
;* CONSTANTS
PCRG
        FCC     ',PCR'
;* TRANSFER/EXCHANGE REGISTER TABLE
REGTAB
        FCN     'D'     0
        FCN     'X'     1
        FCN     'Y'     2
        FCN     'U'     3
        FCN     'S'     4
        FCC     'PC'        5
        FCN     '?'     6
        FCN     '?'     7
        FCN     'A'     8
        FCN     'B'     9
        FCC     'CC'        A
        FCC     'DP'        B
        FCN     '?'     C
        FCN     '?'     D
        FCN     '?'     E
        FCN     '?'     F
;* PUSH/PULL REGISTER TABLE
PSHTAB:
        FCC     'CC'
        FCN     'A'
        FCN     'B'
        FCC     'DP'
        FCN     'X'
        FCN     'Y'
        FCN     'U'
        FCN     'PC'
;* VECTOR HANDLERS
SWI3:
        JMP     [SWI3ADR]
SWI2:
        JMP     [SWI2ADR]
IRQ:
        JMP     [IRQADR]
FIRQ:
        JMP     [FIRQADR]
;* HELP TEXT
HTEXT:
        FCB     0       NEW LINE TO START
        FCN     'CR <reg> <data>|Change register'
        FCN     'CV <vec> <addr>|Change interrupt vector'
        FCN     'DM <addr>,<addr>|Display memory in hex dump format'
        FCN     'DR|Display processor registers'
        FCN     'DV|Display interrupt vectors'
        FCN     'E <addr>|Edit memory'
        FCN     'FM <addr>,<addr> <data>|Fill memory'
        FCN     'G [<addr>]|Go (execute program)'
        FCN     'L|Load an image into RAM from uart2'
        FCN     'MM <addr>,<addr> <addr>|Move memory'
        FCN     'RR <addr>|Repeating READ access'
        FCN     'RW <addr> <data>|Repeating WRITE access'
        FCN     'W <addr> <data>|Write to memory'
        FCN     'XR <addr>|Repeating 16 bit read'
        FCN     'XW <addr> <word>|Repeating 16 bit write'
        FCN     '+ <value>+<value>|Hexidecimal addition'
        FCN     '- <value>-<value>|Hexidecimal subtraction'
        FCB     -1      END OF TABLE

;*
;* MACHINE DEPENDANT I/O ROUTINES FOR 6551 UART
;*
INIT:
        LDA     #$00                              ; RESET UART
        STA     UART1STATUS                       ;
        LDA     #$0B                              ;
        STA     UART1COMMAND                      ;
        LDA     #$1E                              ; 9600, 8 BITS, NO PARITY, 1 STOP BIT
        STA     UART1CONTROL                      ;
        RTS
;* READ UART
READ:
        LDA     UART1STATUS                       ; GET STATUS REGISTER
        ANDA    #%00001000                        ; IS RX READY
        BEQ     NOCHR                             ; No DATA IS READY
        LDA     UART1DATA                         ; GET DATA CHAR
        RTS
NOCHR:
        LDA     #$FF                              ; NO CHAR
        RTS
;* WRITE UART
WRITE:
        LDB     UART1STATUS                       ; GET STATUS
        ANDB    #%00010000                        ; IS TX READY
        BEQ     WRITE                             ; NO, WAIT FOR IT
        STA     UART1DATA                         ; WRITE DATA
        RTS

;*
;* MACHINE VECTORS
;*
        ORG     $FFF2
        FDB     SWI3
        FDB     SWI2
        FDB     FIRQ
        FDB     IRQ
        FDB     SWIHND
        FDB     NMIHND
        FDB     RESET
