;	title	8080 SIMULATOR
;*
;* 8080 microprocessor emulator, allowing software for the Intel 8080
;* to be executed on the Motorola 6809.
;*
;* The following operations/instruction are not supported
;* by the simulator:
;*
;*  1).... ENABLE/DISABLE INTERRUPTS (EI, DI)
;*  2).... PARITY FLAG, (JPE, JPO, CPE, CPO, RPE, RPO)
;*  3..... INPUT/OUTPUT INSTRUCTIONS, (IN, OUT)
;*
;* If the simulator encounters an unsupported opcode, an opcode
;* which is not defined, or a "HALT" instruction, it will display
;* an appropriate message and terminate.
;*
;* The 8080 "OUT" instruction is used to communicate with the 6809
;* operating system, via the "SSR" interface, the port number given
;* in the "OUT" instruction is taken to be the number of the system
;* call to be executed. The 8080 'BC' register pair is mapped into
;* the 6809 'D' (A&B) accumulator, the 'DE' register pair is mapped
;* into 'Y', and the 'HL' register pair is mapped into 'X'. When the
;* function returns, the registers will be mapped back, and the 8080
;* 'A' register will contain the DOS return code. No flags are set.
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
;* FILE PERMISSIONS
RPERM           = %10000000                       ;READ PERMISSION
WPERM           = %01000000                       ;WRITE PERMISSION
EPERM           = %00100000                       ;EXECUTE PERMISSION
DPERM           = %00010000                       ;DELETE PERMISSION
;* DOS RETURN CODES
RCPRO           = 3                               ;PROTECTION VIOLATION
;*
        ORG     OSRAM                             ;DOS UTILITY SPACE
AREGHB          = AREG/256
;* PROGRAM ENTRY
        BRA     SIM80
;* 8080 PROCESSOR REGISTER SET
AREG
        FCB     0                                 ;SAVED A REGISTER
CCREG
        FCB     0                                 ;SAVED CONDITION CODES
BREG
        FCB     0                                 ;SAVED B REGISTER
CREG
        FCB     0                                 ;SAVED C REGISTER
DREG
        FCB     0                                 ;SAVED D REGISTER
EREG
        FCB     0                                 ;SAVED E REGISTER
HREG
        FCB     0                                 ;SAVED H REGISTER
LREG
        FCB     0                                 ;SAVED L REGISTER
SREG
        FDB     OSEND                             ;SAVED STACK POINTER
;* SIMULATOR LOCAL STORAGE
QFLAGS          = *                               ;QUALIFIER FLAGS START HERE
DEBUG
        FCB     $FF                               ;DEBUG ENABLED
TRACE
        FCB     $FF                               ;TRACE MODE ENABLED
SNGLST
        FCB     $FF                               ;SINGLE STEP DISPLAY
BRKPTS
        FDB     0,0,0,0                           ;BREAKPOINT TABLE (0-3)
        FDB     0,0,0,0                           ;BREAKPOINT TABLE (4-7)
TEMP
        FDB     0                                 ;TEMPORARY STORAGE
;*
SIM80
        CMPA    #'?'                              ;HELP REQUEST?
        BNE     QUAL                              ;NO
        SWI
        FCB     25                                ;ISSUE MESSAGE
        FCN     'Use: SIM80[/DEBUG] <8080 code filename>'
        SWI
        FCB     0                                 ;EXIT
;* EVALUATE QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR
        CMPA    #'/'                              ;QUALIFIER?
        BNE     MAIN                              ;NO QUALIFIERS
        LDX     #QTABLE                           ;PT TO TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;OVER?
        BHS     QERR                              ;INVALID
        LDX     #QFLAGS                           ;PT TO FLAGS
        CLR     B,X                               ;ZAP IT
        BRA     QUAL                              ;CONTINUE
QERR
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Invalid qualifier: '
        LDA     ,Y+                               ;GET CHAR
QERR1
        SWI
        FCB     33                                ;OUTPUT
        SWI
        FCB     5                                 ;GET NEXT CHAR
        BEQ     QERR2                             ;END, EXIT
        CMPA    #'/'                              ;NEXT QUALIFIER
        BNE     QERR1                             ;ITS OK
QERR2
        SWI
        FCB     25,$22,0
        LDA     #1                                ;INDICATE INVALID OPERAND
        SWI
        FCB     0                                 ;EXIT
;* MAIN PROGRAM
MAIN
        LDA     #AREGHB                           ;POINT TO DIRECT PAGE
        TFR     A,DP                              ;SET UP DP
        SETDP   AREGHB                            ;LET ASSEMBLER IN ON IT
        SWI
        FCB     11                                ;GET FILENAME
        BNE     ABO1                              ;ERROR
        LDD     #$3830                            ;GET TYPE '80'
        STD     ,X                                ;SET IT
        CLR     2,X                               ;ZERO LAST
        SWI
        FCB     4                                 ;SKIP TO OPERAND
        STY     DREG                              ;POINT D-E TO PARAMETERS
        SWI
        FCB     69                                ;LOOK UP DIRECTORY ENTRY
        BNE     ABO1                              ;ERROR
        LDA     DATTR,X                           ;GET ATTRIBUTES
        BITA    #EPERM                            ;OK TO EXECUTE?
        BNE     OKEXE                             ;YES, ITS OK
        SWI
        FCB     45                                ;PROTECTION ERROR
ABO1
        SWI
        FCB     0                                 ;QUIT
OKEXE
        LDX     DRADR,X                           ;GET LOAD ADDRESS
        TFR     X,U                               ;COPY TO 8080 PC
        SWI
        FCB     53                                ;LOAD CODE
        BNE     ABO1                              ;FAILED, REPORT ERROR
        TST     DEBUG                             ;ARE WE DEBUGGING?
        LBNE    NXTINS                            ;NO, FULL SPEED AHEAD
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCN     'Entry point = $'
        TFR     U,D                               ;GET STARTING PC
        SWI
        FCB     27                                ;OUTPUT
BUGLF
        SWI
        FCB     22                                ;NEW LINE
BUGGER
        SWI
        FCB     24                                ;OUTPUT PROMPT
        FCN     '8080> '	PROMPT
        SWI
        FCB     3                                 ;GET INPUT LINE
        SWI
        FCB     4                                 ;SKIP TO COMMAND
        BEQ     BUGGER                            ;IF NULL, IGNORE
        LDX     #DCMD                             ;POINT TO COMMAND TABLE
        SWI
        FCB     18                                ;ISSUE COMMAND
        TSTB                                      ;	IS IT SET COMMAND
        LBNE    DSPCMD                            ;NO, TRY CLEAR
        LDX     #DOPT                             ;POINT TO OPTION TABLE
        SWI
        FCB     18                                ;LOOK IT UP
;* SET PSW, BC, DE, HL, SP
        CMPB    #4                                ;IS IT S SET REG?
        BHI     SPC                               ;NO, TRY SET PC
        ASLB                                      ;	CONVERT TO TWO TIMES OFFSET
        LDX     #AREG                             ;POINT TO PSW
        ABX                                       ;	ADD IN OFFSET
        PSHS    X                                 ;SAVE OFFSET
        SWI
        FCB     7                                 ;GET HEX VALUE
        TFR     X,D                               ;COPY TO D
        PULS    X                                 ;RESTORE REGISTER
        BNE     BGBAK                             ;IF INVALID, DON'T SAVE
        STD     ,X                                ;SET REGISTER
BGBAK
        LBRA    BUGGER                            ;DO IT AGAIN
;* SET PC
SPC
        SUBB    #5                                ;IS IT SET PC?
        BNE     STRACE                            ;NO, TRY SET TRACE MODE
        SWI
        FCB     7                                 ;GET HEX VALUE
        BNE     BGBAK                             ;GIVE UP IF INVALID
        TFR     X,U                               ;SET PC
        BRA     BGBAK                             ;DO IT AGAIN
;* SET TRACE MODE
STRACE
        DECB                                      ;	IS IT TRACE?
        BNE     NTRACE                            ;NO, TRY SET TRACE OFF
        CLR     TRACE                             ;SET TRACE MODE
        BRA     BGBAK                             ;RETURN
;* SET TRACE OFF
NTRACE
        DECB                                      ;	TRACE OFF?
        BNE     SETBRK                            ;NO, TRY SET BREAKPOINT
        LDA     #$FF                              ;GET OFF FLAG
        STA     TRACE                             ;SAVE
        BRA     BGBAK                             ;AND RETRUN
;* SET UP A BREAKPOINT
SETBRK
        DECB                                      ;	IS IT A BREAKPOINT?
        BNE     BADOPT                            ;IT'S A BAD OPTION
        SWI
        FCB     6                                 ;GET BRKPT NUMBER
        LBNE    BUGGER                            ;IT'S BAD, GET UPSET
        CMPD    #8                                ;OVER?
        BHS     BADOPT                            ;INDICATE BAD
        LDX     #BRKPTS                           ;POINT TO BREAKPOINT TABLE
        ASLB                                      ;	CONVERT TO OFFSET
        ABX                                       ;	GET ADDRESS INTIO TABLE
        PSHS    X                                 ;SAVE IT
        SWI
        FCB     7                                 ;GET HEX ADDRESS
        TFR     X,D                               ;COPY TO D
        PULS    X                                 ;RESTORE
        STD     ,X                                ;SAVE VALUE
        BRA     BGBAK                             ;RETURN
BADOPT
        SWI
        FCB     24
        FCN     'Invalid operand.'
        LBRA    BUGLF
;* DISPLAY COMMAND
DSPCMD
        DECB                                      ;	DISPLAY?
        BNE     MEMCMD                            ;NO, TRY MEMORY
        SWI
        FCB     24                                ;DISPLAY PC
        FCN     'PC='
        TFR     U,D
        SWI
        FCB     27
        LBSR    DSPRG                             ;OUTPUT REGISTERS
        SWI
        FCB     25
        FCN     'Breakpoints:'
        CLRB
        LDX     #BRKPTS                           ;POINT TO BREAKPOINT TABLE
OTBRK
        TFR     B,A                               ;GET NUMBER
        ADDA    #$30                              ;CONVERT TO ASCII
        SWI
        FCB     33                                ;OUTPUT
        LDA     #'='
        SWI
        FCB     33                                ;DISPLAY SEPERATOR
        PSHS    B
        LDD     ,X++                              ;GET VALUE
        SWI
        FCB     27                                ;OUTPUT
        PULS    B                                 ;RESTORE B
        INCB                                      ;	ADVANCE
        CMPB    #7                                ;PAST LIMIT?
        LBHI    BUGLF
        SWI
        FCB     24                                ;OUTPUT MESSAGE,
        FCN     ', '
        BRA     OTBRK                             ;AND CONTINUE
;* MEMORY DISPLAY COMMAND
MEMCMD
        DECB                                      ;	IS IT MEMORY?
        BNE     STCMD                             ;NO, TRY STORE
        SWI
        FCB     7                                 ;GET HIGH ADDRESS
        LBNE    BUGGER                            ;IT'S A BUGGER IF ITS BAD
        STX     TEMP                              ;SAVE FOR LATER
        SWI
        FCB     7                                 ;GET ENDING ADDRESS
        LBNE    BUGGER                            ;ALSO BAD
        LDY     TEMP                              ;GET DATA
        STX     TEMP                              ;SAVE ENDING ADDRESS
SHMEM
        TFR     Y,D                               ;GET ADDRESS
        SWI
        FCB     27                                ;OUTPUT
        PSHS    Y                                 ;SAVE POINTER
        LDB     #16                               ;16 BYTES/LINE
OTBYT
        SWI
        FCB     21                                ;DISPLAY A SPACE
        LDA     ,Y+                               ;GET BYTE
        SWI
        FCB     28                                ;OUTPUT
        DECB                                      ;	REDUCE COUNT
        BNE     OTBYT                             ;DISPLAY ENTIRE LINE
        SWI
        FCB     21
        SWI
        FCB     21                                ;SEPERATOR
        PULS    Y                                 ;RESTORE POINTER
        LDB     #16                               ;16 BYTES/LINE
OTASC
        LDA     ,Y+                               ;GET DATA
        CMPA    #' '                              ;PRRINTABLE?
        BLO     UNPRT                             ;NO
        CMPA    #$7F                              ;PRINTABLE?
        BHS     UNPRT                             ;NO
        BRA     ASCEND
UNPRT
        LDA     #'.'
ASCEND
        SWI
        FCB     33                                ;OUTPUT
        DECB                                      ;	BACKUP COUNT
        BNE     OTASC
        SWI
        FCB     22                                ;NEW LINE
        CMPY    TEMP                              ;OVER END
        BHI     BUG1
        SWI
        FCB     35                                ;CHECK FOR KEY
        BNE     SHMEM
BUG1
        LBRA    BUGGER
;* STORE COMMAND
STCMD
        DECB                                      ;	ZIS IT?
        BNE     EXICMD                            ;NO, TRY EXIT
        SWI
        FCB     7                                 ;GET ADDRESS
        LBNE    BUGGER                            ;QUIT
ST1
        PSHS    X                                 ;SAVE ADDRESS
        SWI
        FCB     7                                 ;GET OPERAND
        TFR     X,D
        PULS    X                                 ;GET ADDRESS BACK
        LBNE    BUGGER
        STB     ,X+                               ;SAVE IN MEMORY
        SWI
        FCB     4                                 ;CHECK FOR END OF LINE
        BNE     ST1                               ;KEEP GOING
        LBRA    BUGGER
EXICMD
        DECB                                      ;	IS IT EXIT
        BNE     GOCMD                             ;NO, TRY GO
        CLRA                                      ;	SET ZERO RC
        SWI
        FCB     0                                 ;GO HOME
;* DEBUG RUN
GOCMD
        DECB
        BNE     STEP                              ;NO, TRY STEP
        DECB                                      ;	GET $FF
        STA     SNGLST                            ;INSURE NO SINGLE STEP
        BRA     GOEXE
STEP
        DECB                                      ;	TRY FOR STEP
        BNE     BADCMD                            ;NO, IT'S BAD
        CLR     SNGLST                            ;SET SINGLE STEP MODE
        BRA     GOEXE                             ;AND CONTINUE
BADCMD
        SWI
        FCB     24
        FCN     'Invalid command.'
        LBRA    BUGLF
;*
;* 8080 DEBUG EMULATOR...
;*
GOEXE
        TST     SNGLST                            ;SINGLE STEPPING?
        BNE     NOSNGL                            ;DON'T SINGLE STEP
        LDA     #':'                              ;GET PROMPT
        SWI
        FCB     33                                ;OUTPUT
REA1
        SWI
        FCB     34                                ;GET CHARACTER
        CMPA    #' '                              ;SPACE
        BEQ     TRC1                              ;IF SO, GO AHEAD
        CMPA    #$0D                              ;CR?
        BNE     REA1                              ;NO, ASK AGAIN
        LBRA    BUGLF                             ;REENTER MONITOR
NOSNGL
        TST     TRACE                             ;ARE WE TRACEING?
        BNE     NOT1                              ;NO, DON'T DISPLAY
        SWI
        FCB     35                                ;TEST FOR KEY
        CMPA    #$1B                              ;ESCAPE?
        LBEQ    BUGGER                            ;IF SO, QUIT
TRC1
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'PC='
        TFR     U,D                               ;GET PC
        SWI
        FCB     27                                ;DISPLAY IN HEX
        SWI
        FCB     24                                ;MESSAGE
        FCN     ' OP='
        LDA     ,U                                ;GET OPCODE
        SWI
        FCB     28                                ;OUTPUT
NOT1
        LDB     ,U+                               ;GET OPCODE
        CLRA                                      ;	ZERO HIGH BYTE
        ASLB                                      ;	X 2 FOR TWO BYTE
        ROLA                                      ;	(16 BIT) ADDRESSES IN TABLE
        LDX     #TABLE                            ;POINT TO TABLE
        JSR     [D,X]                             ;EXECUTE CODE
        TST     SNGLST                            ;SINGLE STEPPING?
        BEQ     DSPR2
        TST     TRACE                             ;ARE WE TRACING
        BNE     CKBRK                             ;NO, KEEP QUIET
DSPR2
        BSR     DSPRG                             ;DISPLAY REGISTERS
;* SEARCH FOR BREAKPOINTS
CKBRK
        LDX     #BRKPTS                           ;POINT TO BREAKPOINT TABLE
        CLRB                                      ;	ZERO COUNTER
BKCK
        CMPU    ,X++                              ;IS THIS IT?
        BEQ     BRKFND                            ;IF SO, SAY WE FOUND
        INCB                                      ;	ADVANCE
        CMPB    #8                                ;ARE WE OVER
        BLO     BKCK                              ;KEEP TRYING
        BRA     GOEXE                             ;NO BREAKPOINT
;* BREAKPOINT WAS FOUND
BRKFND
        SWI
        FCB     24                                ;MESSAGE
        FCN     'Breakpoint '
        CLRA
        SWI
        FCB     26
        SWI
        FCB     24
        FCN     ' at $'
        TFR     U,D
        SWI
        FCB     27
        LBRA    BUGLF
;* DISPLAY REGSITERS
DSPRG
        SWI
        FCB     24                                ;MESSAGE
        FCN     ' SP='
        LDD     SREG                              ;GET SP
        SWI
        FCB     27                                ;OUTPUT
        SWI
        FCB     24                                ;MESSAGE
        FCN     ' PSW='
        LDD     AREG                              ;GET A AND FLAGS
        SWI
        FCB     27                                ;OUTPUT
        SWI
        FCB     24                                ;MESSAGE
        FCN     ' BC='
        LDD     BREG
        SWI
        FCB     27
        SWI
        FCB     24
        FCN     ' DE='
        LDD     DREG
        SWI
        FCB     27
        SWI
        FCB     24
        FCN     ' HL='
        LDD     HREG
        SWI
        FCB     27
        SWI
        FCB     22                                ;NEW LINE
        RTS
;*
;* FAST 8080 SIMULATOR
;*
NXTINS
        LDB     ,U+                               ;GET OPCODE
        CLRA                                      ;	ZERO HIGH BYTE
        ASLB                                      ;	X 2 FOR TWO BYTE
        ROLA                                      ;	(16 BIT) ADDRESSES IN TABLE
        LDX     #TABLE                            ;POINT TO TABLE
        JSR     [D,X]                             ;EXECUTE CODE
        BRA     NXTINS                            ;AND ADVANCE
;*
;* SUBROUTINE TO	GET ADDRESS IN X REGISTERFROM OPERAND
;*
GETADR
        LDD     ,U++
        EXG     B,A
        TFR     D,X
        RTS
;* INSTRUCTION TABLE
TABLE
        FDB     NOP                               ;00- 8080 NOP INSTRUCTION
        FDB     LXIB                              ;01- LXI B
        FDB     STAXB                             ;02- STAX B
        FDB     INXB                              ;03- INX B
        FDB     INRB                              ;04- INR B
        FDB     DCRB                              ;05- DCR B
        FDB     MVIB                              ;06- MVI B
        FDB     RLC                               ;07- RLC
        FDB     INVOP                             ;08-
        FDB     DADB                              ;09- DAD B
        FDB     LDAXB                             ;0A- LDAX B
        FDB     DCXB                              ;0B- DCX B
        FDB     INRC                              ;0C- INRC
        FDB     DCRC                              ;0D- DCR C
        FDB     MVIC                              ;0E- MVI C,X
        FDB     RRC                               ;0F- RRC
        FDB     INVOP                             ;10-
        FDB     LXID                              ;11- LXI D
        FDB     STAXD                             ;12- STAX D
        FDB     INXD                              ;13- INX D
        FDB     INRD                              ;14- INR D
        FDB     DCRD                              ;15- DCR D
        FDB     MVID                              ;16- MVI D,X
        FDB     RAL                               ;17- RAL
        FDB     INVOP                             ;18-
        FDB     DADD                              ;19- DAD D
        FDB     LDAXD                             ;1A- LDAX D
        FDB     DCXD                              ;1B- DCX D
        FDB     INRE                              ;1C- INR E
        FDB     DCRE                              ;1D- DCR E
        FDB     MVIE                              ;1E- MVI E,X
        FDB     RAR                               ;1F- RAR
        FDB     INVOP                             ;20- (RIM)
        FDB     LXIH                              ;21- LXI H,XX
        FDB     SHLD                              ;22- SHLD
        FDB     INXH                              ;23- INX H
        FDB     INRH                              ;24- INR H
        FDB     DCRH                              ;25- DCR H
        FDB     MVIH                              ;26- MVI H,X
        FDB     DAA                               ;27- DAA
        FDB     INVOP                             ;28-
        FDB     DADH                              ;29- DAD H
        FDB     LHLD                              ;2A- LHLD
        FDB     DCXH                              ;2B- DCX H
        FDB     INRL                              ;2C- INR L
        FDB     DCRL                              ;2D- DCR L
        FDB     MVIL                              ;2E- MVI L,X
        FDB     CMA                               ;2F- CMA
        FDB     INVOP                             ;30- (SIM)
        FDB     LXIS                              ;31- LXI SP,XX
        FDB     STA                               ;32- STA
        FDB     INXS                              ;33- INX SP
        FDB     INRM                              ;34- INR M
        FDB     DCRM                              ;35- DCR M
        FDB     MVIM                              ;36- MVI M,X
        FDB     STC                               ;37- STC
        FDB     INVOP                             ;38-
        FDB     DADS                              ;39- DAD SP
        FDB     LDA                               ;3A- LDA
        FDB     DCXS                              ;3B- DCX SP
        FDB     INRA                              ;3C- INR A
        FDB     DCRA                              ;3D- DCR A
        FDB     MVIA                              ;3E- MVI A,XX
        FDB     CMC                               ;3F- CMC
        FDB     NOP                               ;40- MOV B,B
        FDB     MOVBC                             ;41- MOV B,C
        FDB     MOVBD                             ;42- MOV B,D
        FDB     MOVBE                             ;43- MOV B,E
        FDB     MOVBH                             ;44- MOV B,H
        FDB     MOVBL                             ;45- MOV B,L
        FDB     MOVBM                             ;46- MOV B,M
        FDB     MOVBA                             ;47- MOV B,A
        FDB     MOVCB                             ;48- MOV C,B
        FDB     NOP                               ;49- MOV C,C
        FDB     MOVCD                             ;4A- MOV C,D
        FDB     MOVCE                             ;4B- MOV C,E
        FDB     MOVCH                             ;4C- MOV C,H
        FDB     MOVCL                             ;4D- MOV C,L
        FDB     MOVCM                             ;4E- MOV C,M
        FDB     MOVCA                             ;4F- MOV C,A
        FDB     MOVDB                             ;50- MOV D,B
        FDB     MOVDC                             ;51- MOV D,C
        FDB     NOP                               ;52- MOV D,D
        FDB     MOVDE                             ;53- MOV D,E
        FDB     MOVDH                             ;54- MOV D,H
        FDB     MOVDL                             ;55- MOV D,L
        FDB     MOVDM                             ;56- MOV D,M
        FDB     MOVDA                             ;57- MOV D,A
        FDB     MOVEB                             ;58- MOV E,B
        FDB     MOVEC                             ;59- MOV E,C
        FDB     MOVED                             ;5A- MOV E,D
        FDB     NOP                               ;5B- MOV E,E
        FDB     MOVEH                             ;5C- MOV E,H
        FDB     MOVEL                             ;5D- MOV E,L
        FDB     MOVEM                             ;5E- MOV E,M
        FDB     MOVEA                             ;5F- MOV E,A
        FDB     MOVHB                             ;60- MOV H,B
        FDB     MOVHC                             ;61- MOV H,C
        FDB     MOVHD                             ;62- MOV H,D
        FDB     MOVHE                             ;63- MOV H,E
        FDB     NOP                               ;64- MOV H,H
        FDB     MOVHL                             ;65- MOV H,L
        FDB     MOVHM                             ;66- MOV H,M
        FDB     MOVHA                             ;67- MOV H,A
        FDB     MOVLB                             ;68- MOV L,B
        FDB     MOVLC                             ;69- MOV L,C
        FDB     MOVLD                             ;6A- MOV L,D
        FDB     MOVLE                             ;6B- MOV L,E
        FDB     MOVLH                             ;6C- MOV L,H
        FDB     NOP                               ;6D- MOV L,L
        FDB     MOVLM                             ;6E- MOV L,M
        FDB     MOVLA                             ;6F- MOV L,A
        FDB     MOVMB                             ;70- MOV M,B
        FDB     MOVMC                             ;71- MOV M,C
        FDB     MOVMD                             ;72- MOV M,D
        FDB     MOVME                             ;73- MOV M,E
        FDB     MOVMH                             ;74- MOV M,H
        FDB     MOVML                             ;75- MOV M,L
        FDB     HLT                               ;76- HLT
        FDB     MOVMA                             ;77- MOV M,A
        FDB     MOVAB                             ;78- MOV A,B
        FDB     MOVAC                             ;79- MOV A,C
        FDB     MOVAD                             ;7A- MOV A,D
        FDB     MOVAE                             ;7B- MOV A,E
        FDB     MOVAH                             ;7C- MOV A,H
        FDB     MOVAL                             ;7D- MOV A,L
        FDB     MOVAM                             ;7E- MOV A,M
        FDB     NOP                               ;7F- MOV A,A
        FDB     ADDB                              ;80- ADD B
        FDB     ADDC                              ;81- ADD C
        FDB     ADDD                              ;82- ADD D
        FDB     ADDE                              ;83- ADD E
        FDB     ADDH                              ;84- ADD H
        FDB     ADDL                              ;85- ADD L
        FDB     ADDM                              ;86- ADD M
        FDB     ADDA                              ;87- ADD A
        FDB     ADCB                              ;88- ADC B
        FDB     ADCC                              ;89- ADC C
        FDB     ADCD                              ;8A- ADC D
        FDB     ADCE                              ;8B- ADC E
        FDB     ADCH                              ;8C- ADC H
        FDB     ADCL                              ;8D- ADC L
        FDB     ADCM                              ;8E- ADC M
        FDB     ADCA                              ;8F- ADC A
        FDB     SUBB                              ;90- SUB B
        FDB     SUBC                              ;91- SUB C
        FDB     SUBD                              ;92- SUB D
        FDB     SUBE                              ;93- SUB E
        FDB     SUBH                              ;94- SUB H
        FDB     SUBL                              ;95- SUB L
        FDB     SUBM                              ;96- SUB M
        FDB     SUBA                              ;97- SUB A
        FDB     SBBB                              ;98- SBB B
        FDB     SBBC                              ;99- SBB C
        FDB     SBBD                              ;9A- SBB D
        FDB     SBBE                              ;9B- SBB E
        FDB     SBBH                              ;9C- SBB H
        FDB     SBBL                              ;9D- SBB L
        FDB     SBBM                              ;9E- SBB M
        FDB     SBBA                              ;9F- SBB A
        FDB     ANAB                              ;A0- ANA B
        FDB     ANAC                              ;A1- ANA C
        FDB     ANAD                              ;A2- ANA D
        FDB     ANAE                              ;A3- ANA E
        FDB     ANAH                              ;A4- ANA H
        FDB     ANAL                              ;A5- ANA L
        FDB     ANAM                              ;A6- ANA M
        FDB     ANAA                              ;A7- AND A
        FDB     XRAB                              ;A8- XRA B
        FDB     XRAC                              ;A9- XRA C
        FDB     XRAD                              ;AA- XRA D
        FDB     XRAE                              ;AB- XRA E
        FDB     XRAH                              ;AC- XRA H
        FDB     XRAL                              ;AD- XRA L
        FDB     XRAM                              ;AE- XRA M
        FDB     XRAA                              ;AF- XRA A
        FDB     ORAB                              ;B0- ORA B
        FDB     ORAC                              ;B1- ORA C
        FDB     ORAD                              ;B2- ORA D
        FDB     ORAE                              ;B3- ORA E
        FDB     ORAH                              ;B4- ORA H
        FDB     ORAL                              ;B5- ORA L
        FDB     ORAM                              ;B6- ORA M
        FDB     ORAA                              ;B7- ORA A
        FDB     CMPB                              ;B8- CMP B
        FDB     CMPC                              ;B9- CMP C
        FDB     CMPD                              ;BA- CMP D
        FDB     CMPE                              ;BB- CMP E
        FDB     CMPH                              ;BC- CMP H
        FDB     CMPL                              ;BD- CMP L
        FDB     CMPM                              ;BE- CMP M
        FDB     CMPA                              ;BF- CMP A
        FDB     RNZ                               ;C0- RNZ
        FDB     POPB                              ;C1- POP B
        FDB     JNZ                               ;C2- JNZ
        FDB     JMP                               ;C3- JMP
        FDB     CNZ                               ;C4- CNZ
        FDB     PUSHB                             ;C5- PUSH B
        FDB     ADI                               ;C6- ADI
        FDB     UNSUPP                            ;C7- RST 0
        FDB     RZ                                ;C8- RZ
        FDB     RET                               ;C9- RET
        FDB     JZ                                ;CA- JZ
        FDB     INVOP                             ;CB-
        FDB     CZ                                ;CC- CZ
        FDB     CALL                              ;CD- CALL
        FDB     ACI                               ;CE- ACI
        FDB     UNSUPP                            ;CF- RST 1
        FDB     RNC                               ;D0- RNC
        FDB     POPD                              ;D1- POP D
        FDB     JNC                               ;D2- JNC
        FDB     SYS                               ;D3- OUT
        FDB     CNC                               ;D4- CNC
        FDB     PUSHD                             ;D5- PUSH D
        FDB     SUI                               ;D6- SUI
        FDB     UNSUPP                            ;D7- RST 2
        FDB     RC                                ;D8- RC
        FDB     INVOP                             ;D9-
        FDB     JC                                ;DA- JC
        FDB     UNSUPP                            ;DB- IN
        FDB     CCC                               ;DC- CC
        FDB     INVOP                             ;DD-
        FDB     SBI                               ;DE- SBI
        FDB     UNSUPP                            ;DF- RST 3
        FDB     UNSUPP                            ;E0- RPO
        FDB     POPH                              ;E1- POP H
        FDB     UNSUPP                            ;E2- JPO
        FDB     XTHL                              ;E3- XTHL
        FDB     UNSUPP                            ;E4- CPO
        FDB     PUSHH                             ;E5- PUSH H
        FDB     ANI                               ;E6- ANI
        FDB     UNSUPP                            ;E7- RST 4
        FDB     UNSUPP                            ;E8- RPE
        FDB     PCHL                              ;E9- PCHL
        FDB     UNSUPP                            ;EA- JPE
        FDB     XCHG                              ;EB- XCHG
        FDB     UNSUPP                            ;EC- CPE
        FDB     INVOP                             ;ED-
        FDB     XRI                               ;EE- XRI
        FDB     UNSUPP                            ;EF- RST 5
        FDB     RP                                ;F0- RP
        FDB     POPP                              ;F1- POP PSW
        FDB     JP                                ;F2- JP
        FDB     UNSUPP                            ;F3- DI
        FDB     CP                                ;F4- CP
        FDB     PUSHP                             ;F5- PUSH PSW
        FDB     ORI                               ;F6- ORI
        FDB     UNSUPP                            ;F7- RST 6
        FDB     RM                                ;F8- RM
        FDB     SPHL                              ;F9- SPHL
        FDB     JM                                ;FA- JM
        FDB     UNSUPP                            ;FB- ED
        FDB     CM                                ;FC- CM
        FDB     INVOP                             ;FD-
        FDB     CPI                               ;FE- CPI
        FDB     UNSUPP                            ;FF- RST 7
;*
;* 8080 INSTRUCTION HANDLERS
;*
LXIB
        LDD     ,U++
        EXG     A,B
        STD     BREG
NOP
        RTS
LXID
        LDD     ,U++
        EXG     A,B
        STD     DREG
        RTS
LXIH
        LDD     ,U++
        EXG     A,B
        STD     HREG
        RTS
LXIS
        LDD     ,U++
        EXG     A,B
        STD     SREG
        RTS
;*
STAXB
        LDA     AREG
        STA     [BREG]
        RTS
STAXD
        LDA     AREG
        STA     [DREG]
        RTS
;*
INXB
        LDD     BREG
        ADDD    #1
        STD     BREG
        RTS
INXD
        LDD     DREG
        ADDD    #1
        STD     DREG
        RTS
INXH
        LDD     HREG
        ADDD    #1
        STD     HREG
        RTS
INXS
        LDD     SREG
        ADDD    #1
        STD     SREG
        RTS
;*
DCXB
        LDD     BREG
        SUBD    #1
        STD     BREG
        RTS
DCXD
        LDD     DREG
        SUBD    #1
        STD     DREG
        RTS
DCXH
        LDD     HREG
        SUBD    #1
        STD     HREG
        RTS
DCXS
        LDD     SREG
        SUBD    #1
        STD     SREG
;*
INRA
        INC     AREG
        BRA     FLNC
INRB
        INC     BREG
        BRA     FLNC
INRC
        INC     CREG
        BRA     FLNC
INRD
        INC     DREG
        BRA     FLNC
INRE
        INC     EREG
        BRA     FLNC
INRH
        INC     HREG
        BRA     FLNC
INRL
        INC     LREG
        BRA     FLNC
INRM
        INC     [HREG]
FLNC
        PSHS    CC
        LDB     CCREG
        PULS    CC
        ANDCC   #$FE                              ;INSURE NO CARRY
        LBSR    FLAGS                             ;SET FLAGS
        ANDB    #1                                ;ISOLATE CARRY
        ORB     CCREG
        STB     CCREG
        RTS
;*
DCRA
        DEC     AREG
        BRA     FLNC
DCRB
        DEC     BREG
        BRA     FLNC
DCRC
        DEC     CREG
        BRA     FLNC
DCRD
        DEC     DREG
        BRA     FLNC
DCRE
        DEC     EREG
        BRA     FLNC
DCRH
        DEC     HREG
        BRA     FLNC
DCRL
        DEC     LREG
        BRA     FLNC
DCRM
        DEC     [HREG]
        BRA     FLNC
;*
DADS
        LDD     SREG
        BRA     DADE
DADB
        LDD     BREG
        BRA     DADE
;*
DADD
        LDD     DREG
        BRA     DADE
;*
DADH
        LDD     HREG
DADE
        ADDD    HREG
        STD     HREG
SETCY
        BCS     STC                               ;SET CARRY IF REQUIRED
        LDA     CCREG
        ANDA    #$FE
        STA     CCREG
        RTS
;*
STC
        LDA     CCREG
        ORA     #1
        STA     CCREG
        RTS
CMC
        LDA     CCREG
        EORA    #1
        STA     CCREG
        RTS
;*
CMA
        COM     AREG
        RTS
;*
MVIA
        LDA     ,U+
        STA     AREG
        RTS
MVIB
        LDA     ,U+
        STA     BREG
        RTS
MVIC
        LDA     ,U+
        STA     CREG
        RTS
MVID
        LDA     ,U+
        STA     DREG
        RTS
MVIE
        LDA     ,U+
        STA     EREG
        RTS
MVIH
        LDA     ,U+
        STA     HREG
        RTS
MVIL
        LDA     ,U+
        STA     LREG
        RTS
MVIM
        LDA     ,U+
        STA     [HREG]
        RTS
;*
MOVAB
        LDA     BREG
        BRA     SAVA
MOVAC
        LDA     CREG
        BRA     SAVA
MOVAD
        LDA     DREG
        BRA     SAVA
MOVAE
        LDA     EREG
        BRA     SAVA
MOVAH
        LDA     HREG
        BRA     SAVA
MOVAL
        LDA     LREG
        BRA     SAVA
MOVAM
        LDA     [HREG]
SAVA
        STA     AREG
        RTS
;*
MOVBA
        LDA     AREG
        BRA     SAVB
MOVBC
        LDA     CREG
        BRA     SAVB
MOVBD
        LDA     DREG
        BRA     SAVB
MOVBE
        LDA     EREG
        BRA     SAVB
MOVBH
        LDA     HREG
        BRA     SAVB
MOVBL
        LDA     LREG
        BRA     SAVB
MOVBM
        LDA     [HREG]
SAVB
        STA     BREG
        RTS
;*
MOVCA
        LDA     AREG
        BRA     SAVC
MOVCB
        LDA     BREG
        BRA     SAVC
MOVCD
        LDA     DREG
        BRA     SAVC
MOVCE
        LDA     EREG
        BRA     SAVC
MOVCH
        LDA     HREG
        BRA     SAVC
MOVCL
        LDA     LREG
        BRA     SAVC
MOVCM
        LDA     [HREG]
SAVC
        STA     CREG
        RTS
;*
MOVDA
        LDA     AREG
        BRA     SAVD
MOVDB
        LDA     BREG
        BRA     SAVD
MOVDC
        LDA     CREG
        BRA     SAVD
MOVDE
        LDA     EREG
        BRA     SAVD
MOVDH
        LDA     HREG
        BRA     SAVD
MOVDL
        LDA     LREG
        BRA     SAVD
MOVDM
        LDA     [HREG]
SAVD
        STA     DREG
        RTS
;*
MOVEA
        LDA     AREG
        BRA     SAVE
MOVEB
        LDA     BREG
        BRA     SAVE
MOVEC
        LDA     CREG
        BRA     SAVE
MOVED
        LDA     DREG
        BRA     SAVE
MOVEH
        LDA     HREG
        BRA     SAVE
MOVEL
        LDA     LREG
        BRA     SAVE
MOVEM
        LDA     [HREG]
SAVE
        STA     EREG
        RTS
;*
MOVHA
        LDA     AREG
        BRA     SAVH
MOVHB
        LDA     BREG
        BRA     SAVH
MOVHC
        LDA     CREG
        BRA     SAVH
MOVHD
        LDA     DREG
        BRA     SAVH
MOVHE
        LDA     EREG
        BRA     SAVH
MOVHL
        LDA     LREG
        BRA     SAVH
MOVHM
        LDA     [HREG]
SAVH
        STA     HREG
        RTS
;*
MOVLA
        LDA     AREG
        BRA     SAVL
MOVLB
        LDA     BREG
        BRA     SAVL
MOVLC
        LDA     CREG
        BRA     SAVL
MOVLD
        LDA     DREG
        BRA     SAVL
MOVLE
        LDA     EREG
        BRA     SAVL
MOVLH
        LDA     HREG
        BRA     SAVL
MOVLM
        LDA     [HREG]
SAVL
        STA     LREG
        RTS
;*
MOVMA
        LDA     AREG
        BRA     SAVM
MOVMB
        LDA     BREG
        BRA     SAVM
MOVMC
        LDA     CREG
        BRA     SAVM
MOVMD
        LDA     DREG
        BRA     SAVM
MOVME
        LDA     EREG
        BRA     SAVM
MOVMH
        LDA     HREG
        BRA     SAVM
MOVML
        LDA     LREG
SAVM
        STA     [HREG]
        RTS
;*
LDAXB
        LDA     [BREG]
        STA     AREG
        RTS
LDAXD
        LDA     [DREG]
        STA     AREG
        RTS
;*
LDA
        LBSR    GETADR
        LDA     ,X
        STA     AREG
        RTS
STA
        LBSR    GETADR
        LDA     AREG
        STA     ,X
        RTS
LHLD
        LBSR    GETADR
        LDD     ,X
        EXG     A,B
        STD     HREG
        RTS
SHLD
        LBSR    GETADR
        LDD     HREG
        EXG     A,B
        STD     ,X
        RTS
PCHL
        LDU     HREG
        RTS
SPHL
        LDD     HREG
        STD     SREG
        RTS
;*
CMPA
        LDB     AREG
        BRA     CMPF
CMPB
        LDB     BREG
        BRA     CMPF
CMPC
        LDB     CREG
        BRA     CMPF
CMPD
        LDB     DREG
        BRA     CMPF
CMPE
        LDB     EREG
        BRA     CMPF
CMPH
        LDB     HREG
        BRA     CMPF
CMPL
        LDB     LREG
        BRA     CMPF
CMPM
        LDB     [HREG]
        BRA     CMPF
CPI
        LDB     ,U+
CMPF
        LDA     AREG
        PSHS    B
        SUBA    ,S+
        LBRA    FLAGS
;*
SUBA
        LDB     AREG
        BRA     SUBF
SUBB
        LDB     BREG
        BRA     SUBF
SUBC
        LDB     CREG
        BRA     SUBF
SUBD
        LDB     DREG
        BRA     SUBF
SUBE
        LDB     EREG
        BRA     SUBF
SUBH
        LDB     HREG
        BRA     SUBF
SUBL
        LDB     LREG
        BRA     SUBF
SUBM
        LDB     [HREG]
        BRA     SUBF
SUI
        LDB     ,U+
SUBF
        LDA     AREG
        STB     AREG
        SUBA    AREG
        LBRA    SETA
;*
SBBA
        LDB     AREG
        BRA     SBBF
SBBB
        LDB     BREG
        BRA     SBBF
SBBC
        LDB     CREG
        BRA     SBBF
SBBD
        LDB     DREG
        BRA     SBBF
SBBE
        LDB     EREG
        BRA     SBBF
SBBH
        LDB     HREG
        BRA     SBBF
SBBL
        LDB     LREG
        BRA     SBBF
SBBM
        LDB     [HREG]
        BRA     SBBF
SBI
        LDB     ,U+
SBBF
        LDA     AREG
        STB     AREG
        LDB     CCREG
        ANDB    #1
        ADDB    AREG
        STB     AREG
        SUBA    AREG
        LBRA    SETA
;*
ADDA
        LDA     AREG
        BRA     ADDF
ADDB
        LDA     BREG
        BRA     ADDF
ADDC
        LDA     CREG
        BRA     ADDF
ADDD
        LDA     DREG
        BRA     ADDF
ADDE
        LDA     EREG
        BRA     ADDF
ADDH
        LDA     HREG
        BRA     ADDF
ADDL
        LDA     LREG
        BRA     ADDF
ADDM
        LDA     [HREG]
        BRA     ADDF
ADI
        LDA     ,U+
ADDF
        ADDA    AREG
        LBRA    SETA
;*
ADCA
        LDA     AREG
        BRA     ADCF
ADCB
        LDA     BREG
        BRA     ADCF
ADCC
        LDA     CREG
        BRA     ADCF
ADCD
        LDA     DREG
        BRA     ADCF
ADCE
        LDA     EREG
        BRA     ADCF
ADCH
        LDA     HREG
        BRA     ADCF
ADCL
        LDA     LREG
        BRA     ADCF
ADCM
        LDA     [HREG]
        BRA     ADCF
ACI
        LDA     ,U+
ADCF
        LDB     CCREG
        ANDB    #1
        ADDB    AREG
        STB     AREG
        ADDA    AREG
        LBRA    SETA
;*
XRAA
        LDA     AREG
        BRA     XRAF
XRAB
        LDA     BREG
        BRA     XRAF
XRAC
        LDA     CREG
        BRA     XRAF
XRAD
        LDA     DREG
        BRA     XRAF
XRAE
        LDA     EREG
        BRA     XRAF
XRAH
        LDA     HREG
        BRA     XRAF
XRAL
        LDA     LREG
        BRA     XRAF
XRAM
        LDA     [HREG]
        BRA     XRAF
XRI
        LDA     ,U+
XRAF
        EORA    AREG
        LBRA    CLRC
;*
ANAA
        LDA     AREG
        BRA     ANAF
ANAB
        LDA     BREG
        BRA     ANAF
ANAC
        LDA     CREG
        BRA     ANAF
ANAD
        LDA     DREG
        BRA     ANAF
ANAE
        LDA     EREG
        BRA     ANAF
ANAH
        LDA     HREG
        BRA     ANAF
ANAL
        LDA     LREG
        BRA     ANAF
ANAM
        LDA     [HREG]
        BRA     ANAF
ANI
        LDA     ,U+
ANAF
        ANDA    AREG
        BRA     CLRC
;*
ORAA
        LDA     AREG
        BRA     ORAF
ORAB
        LDA     BREG
        BRA     ORAF
ORAC
        LDA     CREG
        BRA     ORAF
ORAD
        LDA     DREG
        BRA     ORAF
ORAE
        LDA     EREG
        BRA     ORAF
ORAH
        LDA     HREG
        BRA     ORAF
ORAL
        LDA     LREG
        BRA     ORAF
ORAM
        LDA     [HREG]
        BRA     ORAF
ORI
        LDA     ,U+
ORAF
        ORA     AREG
CLRC
        ANDCC   #$FE                              ;CLEAR CARRY
SETA
        STA     AREG                              ;RESAVE RESULT
;* SET PROCESSOR	FLAGS
FLAGS
        PSHS    A,B,X                             ;SAVE REGISTERS
        TFR     CC,B                              ;SAVE CONDITION CODE REGISTER
        ANDB    #$2D                              ;REMOVE BITS WE DON'T WANT
        PSHS    B                                 ;AND SAVE
        LDA     #16                               ;FOUR BIT SHIFT
        MUL                                       ;	AND A HAS RESULT
        ORA     ,S+                               ;ADD IN PROCESSOR FLAGS
        ANDA    #$0F                              ;REMOVE GARBAGE
        LDX     #FLGTAB                           ;POINT TO TABLE
        LDB     A,X                               ;GET 8080 FLAG SET
        STB     CCREG                             ;SAVE
        PULS    A,B,X,PC                          ;RESTORE REGISTERS AND RETURN
;* Conversion table for 6809 <> 8080 processor flags
FLGTAB
        FCB     $00,$01,$10,$11,$40,$41,$50,$51
        FCB     $80,$81,$90,$91,$C0,$C1,$D0,$D1
;*
JMP
        LBSR    GETADR                            ;GET NEW PROGRAM COUNTER
        TFR     X,U
        RTS
JZ
        BSR     TSTZ
        BNE     JMP
        BRA     SK2
JNZ
        BSR     TSTZ
        BEQ     JMP
        BRA     SK2
JC
        BSR     TSTC
        BNE     JMP
        BRA     SK2
JNC
        BSR     TSTC
        BEQ     JMP
        BRA     SK2
JM
        BSR     TSTS
        BNE     JMP
        BRA     SK2
JP
        BSR     TSTS
        BEQ     JMP
SK2
        LEAU    2,U
        RTS
TSTZ
        LDA     #$40
        BRA     ETST
TSTC
        LDA     #$1
        BRA     ETST
TSTS
        LDA     #$80
ETST
        ANDA    CCREG
        RTS
CZ
        BSR     TSTZ
        BNE     CALL
        BRA     SK2
CNZ
        BSR     TSTZ
        BEQ     CALL
        BRA     SK2
CCC
        BSR     TSTC
        BNE     CALL
        BRA     SK2
CNC
        BSR     TSTC
        BEQ     CALL
        BRA     SK2
CM
        BSR     TSTS
        BNE     CALL
        BRA     SK2
CP
        BSR     TSTS
        BNE     SK2
CALL
        TFR     U,D
        ADDD    #2
        BSR     PUSH
        LBSR    GETADR
        TFR     X,U
        RTS
;*
PUSHH
        LDD     HREG
        BRA     PUSH
PUSHD
        LDD     DREG
        BRA     PUSH
PUSHB
        LDD     BREG
        BRA     PUSH
PUSHP
        LDD     AREG
PUSH
        LDX     SREG
        EXG     A,B
        STD     ,--X
        STX     SREG
        RTS
;*
POPP
        BSR     POP
        STD     AREG
        RTS
POPB
        BSR     POP
        STD     BREG
        RTS
POPD
        BSR     POP
        STD     DREG
        RTS
POPH
        BSR     POP
        STD     HREG
        RTS
POP
        LDX     SREG
        LDD     ,X++
        EXG     A,B
        STX     SREG
        RTS
;*
RET
        BSR     POP
        TFR     D,U
        RTS
RZ
        LBSR    TSTZ
        BNE     RET
        RTS
RNZ
        LBSR    TSTZ
        BEQ     RET
        RTS
RC
        LBSR    TSTC
        BNE     RET
        RTS
RNC
        LBSR    TSTC
        BEQ     RET
        RTS
RM
        LBSR    TSTS
        BNE     RET
        RTS
RP
        LBSR    TSTS
        BEQ     RET
        RTS
;*
XCHG
        LDD     DREG
        LDX     HREG
        STD     HREG
        STX     DREG
        RTS
;*
XTHL
        LDD     HREG
        EXG     A,B
        LDX     [SREG]
        STD     [SREG]
        TFR     X,D
        EXG     A,B
        STD     HREG
        RTS
;*
DAA
        LDA     AREG
        TFR     A,B
        ANDB    #$0F
        CMPB    #9
        BGT     AD6
        LDB     CCREG
        ANDB    #$10
        BEQ     NOAD6
AD6
        ADDA    #6
NOAD6
        TFR     A,B
        LSRB
        LSRB
        LSRB
        LSRB
        CMPB    #9
        BGT     AD26
        LDB     CCREG
        ANDB    #1
        BEQ     NOAD26
AD26
        ADDA    #$60
NOAD26
        LBRA    SETA
;*
RLC
        LDA     AREG
        TFR     A,B
        ANDCC   #$FE
        ANDB    #$80
        BEQ     NOCY1
        ORCC    #1
NOCY1
        ROLA
        STA     AREG
        LBRA    SETCY
RRC
        LDA     AREG
        TFR     A,B
        ANDCC   #$FE
        ANDB    #$1
        BEQ     NOCY2
        ORCC    #1
NOCY2
        RORA
        STA     AREG
        LBRA    SETCY
;*
RAL
        LDB     CCREG
        LDA     AREG
        ANDCC   #$FE
        ANDB    #1
        BEQ     NOCY3
        ORCC    #1
NOCY3
        ROLA
        STA     AREG
        LBRA    SETCY
RAR
        LDB     CCREG
        LDA     AREG
        ANDCC   #$FE
        ANDB    #1
        BEQ     NOCY4
        ORCC    #1
NOCY4
        RORA
        STA     AREG
        LBRA    SETCY
;* SYSTEM SERVICES INTERFACE
SYS
        LDA     ,U+                               ;GET OPERAND BYTE
        STA     CALNUM                            ;SET UP SYSTEM CALL
        CLR     AREG                              ;SET ZERO RETURN CODE
        LDD     BREG                              ;MAP B,C TO D ACCUMULATOR
        LDY     DREG                              ;MAP D,E TO Y REGISTER
        LDX     HREG                              ;MAP H,L TO X REGISTER
        TSTA                                      ;	Set condition code
        FCB     $3F                               ;SWI FOR ssr INTERFACE
CALNUM
        FCB     0                                 ;ssr  NUMBER
        BEQ     NORC                              ;RETURN CODE WAS OK
        STA     AREG                              ;SAVE RETURN CODE
NORC
        STX     HREG                              ;SET UP H-L REGISTERS
        STY     DREG                              ;AND NEW VALUES FOR D-E
        STD     BREG                              ;AND B,C GETS CHANGED TOO
        RTS
;* HALT INSTRUCTION
HLT
        CLRB                                      ;	SET RC=0
        SWI
        FCB     24
        FCN     'HLT at	'
        BRA     DSPADR
;* OPCODE NOT SUPPORTED BY SIMULATOR, PULL THE PLUG
UNSUPP
        LDB     #2                                ;SET RC=2
        SWI
        FCB     24
        FCN     'Unsupported opcode '
        BRA     SHOWOP
;* INVALID OPCODE WAS DETECTED, PULL THE	PLUG
INVOP
        LDB     #1                                ;SET RC=1
        SWI
        FCB     24
        FCN     'Invalid opcode	'
SHOWOP
        LDA     -1,U
        SWI
        FCB     28
        SWI
        FCB     24
        FCN     ' at '
DSPADR
        PSHS    B
        LEAU    -1,U
        TFR     U,D
        SWI
        FCB     27
        SWI
        FCB     22
        PULS    A
        TST     DEBUG
        BNE     TERMIT
        LEAS    2,S
        LBRA    BUGGER
TERMIT
        TSTA
ABORT
        SWI
        FCB     0
;* QUALIFIER TABLE
QTABLE
        FCB     $82
        FCC     '/DEBUG'
        FCB     $80
QMAX=1
;* DEBUG COMMAND TABLE
DCMD
        FCB     $82
        FCC     'SET'
        FCB     $82
        FCC     'DISPLAY'
        FCB     $82
        FCC     'MEMORY'
        FCB     $83
        FCC     'STORE'
        FCB     $82
        FCC     'EXIT'
        FCB     $82
        FCC     'GO'
        FCB     $83
        FCC     'STEP'
        FCB     $80
;* DEBUG OPTION TABLE
DOPT
        FCB     $81
        FCC     'PSW'
        FCB     $81
        FCC     'BC'
        FCB     $81
        FCC     'DE'
        FCB     $81
        FCC     'HL'
        FCB     $81
        FCC     'SP'
        FCB     $82
        FCC     'PC'
        FCB     $82
        FCC     'TRACE'
        FCB     $82
        FCC     'NOTRACE'
        FCB     $82
        FCC     'BRKPT'
        FCB     $80
