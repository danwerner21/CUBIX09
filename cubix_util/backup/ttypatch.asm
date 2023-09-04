	title	TERMINAL DEFINITION EDITOR
*
* TTYPATCH: Terminal definition editor
*
* Copyright 1983-2005 Dave Dunfield
* All rights reserved.
*
NSIZE	EQU	25		MAXIMUM NAME WIDTH
ISIZE	EQU	25		MAXIMUM ITEM SIZE
INUM	EQU	13		# INPUT ENTRIES
FNUM	EQU	15		# FUNCTION ENTRIES
ONUM	EQU	8		# OUTPUT ENTRIES
*
	ORG	0
DPREFIX	RMB	8		DIRECTORY PREFIX
FNAME	RMB	8		FILE NAME
FTYPE	RMB	3		FILE TYPE
DSKADR	RMB	2		DISK SECTOR ADDRESS
LODADR	RMB	2		LOAD ADDRESS
FPROT	RMB	1		PROTECTION BITS
*
	ORG	$2000
	CMPA	#'?'		QUESTION?
	BNE	MAIN		NO, ITS OK
	SSR	25		DISPLAY MESSAGE
	FCCZ	'Use: ttypatch'
	SSR	0
MAIN	SSR	25		DISPLAY MESSAGE
	FCC	'     *** TTY patch utility ***'
	FCB	$0A,$0D
	FCC	'Carriage-return to exit a Sub-Menu'
	FCB	$0A,0
* ZERO INITIALIZED DATA
MAIN1	JSR	CLRAM
* MAIN MENU
MAIN2	LDS	#STACK		POINT TO STACK
	LDX	#MMENU		POINT TO MAIN MENU
	LDB	#'1'		ZERO COUNT
MAIN3	LDA	,X		MORE DATA
	BEQ	MAIN4		NO, NONE
	SSR	24		OUTPUT STRING
	FCCZ	'   '		SPACE OVER MENU
	TFR	B,A		GET VALUE
	SSR	33		OUTPUT
	SSR	24		OUTPUT STRING
	FCCZ	' - '
	SSR	23		DISPLAY TEXT
	SSR	22		NEW LINE
	INCB			ADVANCE COUNT
	BRA	MAIN3		AND DO NEXT
MAIN4	SSR	24		OUTPUT STRING
	FCCZ	'Function? '
	SSR	34		GET CHAR
* FUNCTION SELECTED
MAIN5	SSR	33		ECHO
	SSR	22		NEW LINE
* '1' - INPUT KEYS
	SUBA	#'1'		CONVERT
	BNE	MAIN6		NO, TRY NEXT
	LDX	#INAMES		POINT TO INPUT NAMES
	LDU	#IDATA		POINT TO DATA AREA
	BRA	SUBMEN		DO SUBMENU
* '2' - FUNCTION KEYS
MAIN6	DECA			DEFINE FUNCTION?
	BNE	MAIN7		NO, TRY NEXT
	LDX	#FNAMES		POINT TO NAMES
	LDU	#FDATA		POINT TO DATA
	BRA	SUBMEN		DO SUB MENU
* '3' - OUTPUT STRINGS
MAIN7	DECA			DEFINE OUTPUT?
	BNE	MAIN9		NO, TRY NEXT
	LDX	#ONAMES		POINT TO PUTPUT NAMES
	LDU	#ODATA		POINT TO OUTPUT DATA
SUBMEN	LDA	#-1		INSURE NO XY
	JSR	DMENU		DO THE MENU
	JMP	MAIN2		AND RETURN
* '5' - LOAD SETTINGS
MAIN9	DECA			IS IT LOAD?
	BNE	MAIN10		NO, TRY NEXT
	JSR	LDPGM		LOAD THE FILE
* OUTPUT KEYS INTO MEMORY
	JSR	CLRAM		ZERO THE RAM DATABASE
	LDU	#ODATA		POINT TO OUTPUT DATA
	LDB	#ONUM		GET # ENTRIES
MAIN9A	PSHS	B,U		SAVE REG
	LDD	,X++		GET ADDRESS
	SUBD	FLOAD		CONVERT
	ADDD	#LOAD		TO READ ADDRESS
	TFR	D,Y		'Y' = PTR TO ENTRY
MAIN9B	LDA	,Y+		GET CHAR
	STA	,U+		WRITE IT OUT
	BPL	MAIN9C		ITS OK
	LDA	,Y+		GET CHAR
	STA	,U+		WRITE IT OUT
	BRA	MAIN9B		AND CONTINUE
MAIN9C	BNE	MAIN9B		AND PROCEED
	PULS	B,U		RESTORE 'U'
	LEAU	ISIZE,U		ADVANCE TO NEXT
	DECB			REDUCE COUNT
	BNE	MAIN9A		KEEP GOING
* COPY INPUT & FUNCTION KEYS
	LDU	#IDATA		POINT TO INPUT DATA
	LDB	#INUM+FNUM	GET # KEYS
MAIN9D	PSHS	U		SAVE ENTRY
MAIN9E	LDA	,X+		GET CHAR
	STA	,U+		WRITE IT
	BNE	MAIN9E		PROCEED
	PULS	U		RESTORE U
	LEAU	ISIZE,U		OFFSET BY SIZE
	DECB			REDUCE COUNT
	BNE	MAIN9D		AND PROCEED
	JMP	MAIN2		AND PROCEED
* '6' - SAVE SETTINGS
MAIN10	DECA			SAVE ?
	BNE	MAIN11		NO, TRY NEXT
	JSR	LDPGM		LOAD PROGRAM INTO RAM
	LEAU	ONUM*2,X	'U'= OUTPUT PTR
* COPY INPUT & FUNCTION KEYS
	LDY	#IDATA		POINT TO INPUT DATA
	LDB	#INUM+FNUM	GET # KEYS
MAIN10A	PSHS	Y		SAVE FOR LATER
MAIN10B	LDA	,Y+		GET CHAR
	STA	,U+		WRITE IT OUT
	BNE	MAIN10B		AND PROCEED
	PULS	Y		RESTORE 'Y'
	LEAY	ISIZE,Y		SKIP IT
	DECB			REDUCE COUNT
	BNE	MAIN10A		COPY THEM ALL
	CLR	,U+		INDICATE END OF INPUTS
* COPY OUTPUT STRINGS
	LDY	#ODATA		POINT TO OUTPUT DATA
	LDB	#ONUM		GET # OUTPUTS
MAIN10C	PSHS	B,Y		SAVE REGS
	TFR	U,D		GET ADDRESS
	SUBD	#LOAD		CONVERT TO ZERO OFFSET
	ADDD	FLOAD		CONVERT TO PGM OFFSET
	STD	,X++		SAVE VECTOR
MAIN10D	LDA	,Y+		GET CHAR
	STA	,U+		WRITE CHAR
	BPL	MAIN10E		ITS OK
	LDA	,Y+		GET CHAR
	STA	,U+		WRITE IT
	BRA	MAIN10D		AND PROCEED
MAIN10E	BNE	MAIN10D		DO THEM ALL
	PULS	B,Y		RESTORE REGISTER
	LEAY	ISIZE,Y		ADVANCE TO NEXT
	DECB			REDUCE COUNT
	BNE	MAIN10C		AND PROCEED
* RE-SAVE THE FILE
	LDX	#LOAD		POINT TO LOAD ADDRESS
	LDB	FSIZE		GET FILE SIZE
	CLRA			ZERO HIGH
	SSR	54		SAVE THE FILE
	JMP	MAIN2		AND PROCEED
* EXIT THE PROGRAM
MAIN11	DECA			TEST FOR EXIT
	BNE	MAIN12		NO, REPORT ERROR
	CLRA			ZERO RC
	SSR	0
*
MAIN12	SSR	25		ISSUE MESSAGE
	FCCZ	'**ERROR**'
	JMP	MAIN2		AND PROCEED
* LOAD FILE INTO MEMORY
LDPGM	SSR	24		DISPLAY PROMPT
	FCCZ	'Filename? '
	SSR	3		GET INPUT LINE
	SSR	4		MORE DATA?
	BEQ	LODERR		NO, EXIT
	SSR	10		GET FILENAME
	BNE	LODERR		ERROR
	SSR	70		LOCATE FILE
	BNE	LODERR		ERROR
	LDD	LODADR,X	GET LOAD ADDRESS
	STD	FLOAD		WRITE IT OUT
	LDD	DSKADR,X	GET DISK ADDRESS
	LDX	#LOAD		GET INPUT ADDRESS
	SSR	78		LOAD CHAIN
	TFR	X,D		'A' = # 256 BYTE BLOCKS
	SUBD	#LOAD		CONVERT TO OFFSET
	LSRA			'A' = # 512 BYTE BLOCKS
	STA	FSIZE		SET FILE SIZE
	LDA	>LOAD		GET FIRST INST.
	CMPA	#$BE		IS IT 'LDX >'
	BNE	LODBAD		BAD FILE
	LDD	>LOAD+3		GET FOLLOWING INST
	CMPD	#$3F17		IS IT 'SSR 23'
	BNE	LODBAD		BAD FILE
	LDD	LOAD+1		GET ADDRESS
	SUBD	FLOAD		CONVERT TO ZERO OFFSET
	ADDD	#LOAD		OFFSET TO SCREEN POSITION
	TFR	D,X		SET UP 'X'
	RTS
* FILE FORMAT IS INVALID
LODBAD	LDY	#BADFIL		POINT TO MESSAGE
	SSR	52		ISSUE MESSAGE
LODERR	JMP	MAIN2		AND PROCEED
*
* CLEAR THE RAM DATABASE
*
CLRAM	PSHS	X		SAVE REG
	LDX	#IDATA		POINT TO IT
CLR1	CLR	,X+		ZERO BYTE
	CMPX	#IEND		ARE WE OVER?
	BLO	CLR1		NO, KEEP GOING
	PULS	X,PC		RESTORE & RETURN
*
* DISPLAY MENU OF SELECTIONS(X), DATA AREA(U)
*
DMENU	PSHS	A,X,U		SAVE REGISTER
DMENU0	CLR	,S		ZERO COUNT
	LDU	1,S		GET TABLE ADDRESS
DMENU1	LDA	,U		MORE ENTRIES?
	BEQ	DMENU4		NO, NONE
	SSR	24		SPACE OVER
	FCCZ	'   '		OVER
	LDA	,S		GET INDEX CHAR
	ADDA	#'A'		OFFSET
	SSR	33		DISPLAY
	SSR	24		SEPERATOR
	FCCZ	' - '
	CLRB			ZERO COUNT
DMENU2	LDA	,U+		GET CHAR
	BEQ	DMENU3		MORE, QUIT
	INCB			ADVANCE COUNT
	SSR	33		DISPLAY
	BRA	DMENU2		DO THEM ALL
DMENU3	SSR	21		DISPLAY SPACE
	INCB			ADVANCE COUNT
	CMPB	#NSIZE		ARE WE OVER?
	BLO	DMENU3		DO THEM ALL
	SSR	24		SEPERATOR
	FCCZ	': '
	LDA	,S		GET ITEM NUMBER
	LDB	#ISIZE		GET ITEM SIZE
	MUL			CALCULATE OFFSET
	ADDD	3,S		GET ADDRESS
	TFR	D,X		GET ADDRESS
	JSR	DISDAT		DISPLAY IT
	SSR	22		NEW LINE
	INC	,S		NEXT ITEM
	BRA	DMENU1		AND PROCEED
* WE HAVE END OF LIST, GET SELECTION
DMENU4	SSR	24		DISPLAY PROMPT
	FCCZ	'Select? '
DMENU5	SSR	34		GET CHAR
	CMPA	#$0D		ESCAPE
	BEQ	DMENU9		ABORT
	TFR	A,B		GET CHAR
	ANDB	#$5F		CONVERT TO UPPER
	SUBB	#'A'		CONVERT TO OFFSET
	CMPB	,S		ARE WE OK
	BHS	DMENU5		NO, REQUEST NEXT
* WE HAVE SELECTION
	PSHS	B		SAVE FOR LATER
	LDX	2,S		GET TEXT PTR BACK
DMENU6	DECB			REDUCE COUNT
	BMI	DMENU8		WE HAVE IT
DMENU7	LDA	,X+		GET CHAR
	BNE	DMENU7		PROCEED
	BRA	DMENU6		TEST NEXT
* WE FOUND TITLE
DMENU8	SSR	23		DISPLAY TITLE
	SSR	22		NEW LINE
	PULS	B		RESTORE NUMBER
	LDA	#ISIZE		GET ITEM SIZE
	MUL			CALCULATE OFFSET
	ADDD	3,S		INCLUDE ADDRESS
	TFR	D,X		GET CHAR
	BSR	GETSTR		GET STRING
	JMP	DMENU0		NEXT MENU
DMENU9	SSR	22		NEW LINE
	PULS	A,X,U,PC	RESTORE & RETURN
*
* DISPLAY DATA LINE(X)
*
DISDAT	CLRB			ZERO COUNT
DISD1	LDA	,X+		GET CHAR
	BEQ	DISD5		END, EXIT
	BPL	DISD4		NORMAL CHAR
	TFR	A,B		'B' = CHAR
	SSR	24		OUTPUT
	FCCZ	'<'
	LDA	#'X'		ASSUME 'X'
	BITB	#%01000000	TEST
	BEQ	DISD2		ASSUMPTION CORRECT
	LDA	#'Y'		FIX MISTAKE
DISD2	SSR	33		DISPLAY IT
	LDA	#'B'		ASSUME BINARY
	BITB	#%00100000	TEST
	BEQ	DISD3		ASSUMPTION CORRECT
	LDA	#'D'		FIX MISTAKE
DISD3	SSR	33		DISPLAY IT
	LDA	,X+		GET VALUE
	SSR	28		DISPLAY IT
	LDA	#'>'		INDICATE SPECIAL
* NORMAL CHAR TO DISPLAY
DISD4	JSR	PUTCHR		DISPLAY
	BRA	DISD1		AND BACK
DISD5	RTS
*
* READ STRING(X) FROM KEYBOARD WITH SPECIALS
*
GETSTR	CLRB			ZERO LOW
GETS1	SSR	34		READ CHARACTER
	CMPA	#$0D		SPECIAL CHARACTER
	BEQ	GETS2		YES, IT IS
	STA	B,X		WRITE IT
	INCB			ADVANCE
	JSR	PUTCHR		DISPLAY IT
	BRA	GETS1		AND PROCEED
*SPECIAL KEY PRESSED
GETS2	SSR	24		OUTPUT MESSAGE
	FCB	$0A,$0D		
	FCCZ	'(D)elete (C)ontinue (E)nter-CR (H)exchar (Q)uit '
	CMPX	#GDATA		SPECIAL CASE
	BNE	GETS3		NO, ITS NOT
	SSR	24		MORE TEXT
	FCCZ	'(X)out (Y)out '
GETS3	LDA	#'?'		PROMPT
	SSR	33		DISPLAY IT
	SSR	34		GET CHARACTER
	SSR	33		ECHO
	ANDA	#$5F		CONVERT TO CAPS
* 'C'ONTINUE ENTRY
	CMPA	#'C'		CONTINUE
	BEQ	GETS3A		YES, PROCEED
* 'D'ELETE PREVIOUS CHARACTER
	CMPA	#'D'		DELETE?
	BNE	GETS4		NO, TRY NEXT
	TSTB			AT ZERO?
	BEQ	GETS3A		YES, EXIT
	DECB			BACKUP
GETS3A	CLR	B,X		ZERO CHAR
	SSR	22		NEW LINE
	PSHS	B,X
	JSR	DISDAT		DISPLAY IT
	PULS	B,X
	BRA	GETS1		AND PROCEED
* 'E' INSERT ESCAPE ECHARACTER
GETS4	CMPA	#'E'		ESCAPE?
	BNE	GETS6		NO, TRY NEXT
	LDA	#$0D		GET ESCAPE
GETS4A	STA	B,X		SAVE IT
	INCB			ADVANCE COUNT
	BRA	GETS3A		AND PROCEED
* 'Q'UIT
GETS6	CMPA	#'Q'		QUIT?
	BNE	GETS7		NO, TRY NEXT
	SSR	22		NEW LINE
	CLR	B,X		ZERO END
	RTS
* 'H'EXIDECIMAL CHARSCTERS
GETS7	CMPA	#'H'		HEX?
	BEQ	GETS10B		YES, ITS OK
* 'X' AND 'Y' OFFSETS
	CMPX	#GDATA		SPECIAL CASE
	BEQ	GETS8		YES
GETS7A	LDA	#7		BEEP
	SSR	33		DISPLAY
	JMP	GETS2		AND PROCEED
GETS8	CMPA	#'X'		IS IT 'X'?
	BNE	GETS9		NO, TRY NEXT
	LDA	#%10000000	INDICATE 'X' ENTRY
	BRA	GETS10		AND PROCEED
GETS9	CMPA	#'Y'		IS IT 'Y'
	BNE	GETS7A		REPORT ERROR
	LDA	#%11000000	INDICATE 'Y' ENTRY
GETS10	PSHS	B		SAVE IT FOR LATER
	TFR	A,B		'B' = REGISTER
	SSR	24		DISPLAY
	FCB	$0A,$0D		OUTPUT MESSAGE
	FCCZ	'(B)inary (D)ecimal? '
	SSR	34		GET CHAR
	SSR	33		ECHO
	ANDA	#$5F		CONVERT TO UPPER
	CMPA	#'B'		BINARY
	BEQ	GETS10A		YES, ITS OK
	CMPA	#'D'		DECIMAL?
	BNE	GETS7A		ERROR
	ORB	#%00100000	SET TO 'DECIMAL'
GETS10A	TFR	B,A		'A' = VALUE
	PULS	B		RESTORE POSITION
	STA	B,X		WRITE IT
	INCB			ADVANCE
	SSR	24		OUTPUT MESSAGE
	FCB	$0A,$0D
	FCCZ	'Offset value (hex)? '
GETS10B	BSR	GETDIG		GET DIGIT
	LSLA
	LSLA
	LSLA
	LSLA
	PSHS	A
	BSR	GETDIG		GET NEXT
	ORA	,S+		INCLUDE
	JMP	GETS4A		AND PROCEED
* GET HEX DIGIT
GETDIG	SSR	34		GET CHAR
	CMPA	#'0'		IN RANGE?
	BLO	GETD2		ERROR
	CMPA	#'9'		IN RANGE?
	BLS	GETD1		YES, ITS OK
	ANDA	#$5F		CONVERT TO UPPER
	CMPA	#'A'		IN RANGE?
	BLO	GETD2		ERROR
	CMPA	#'F'		IN RANGE?
	BHI	GETD2		NO, ERROR
	SSR	33		ECHO
	SUBA	#'0'+7		CONVERT
	RTS
GETD1	SSR	33		ECHO
	SUBA	#'0'		CONVERT TO BINARY
	RTS
GETD2	LDA	#7		ERROR
	SSR	33		DISPLAY
	BRA	GETDIG		AND PROCEED
*
* DISPLAY CHARACTER IN SPECIAL FORM
*
PUTCHR	PSHS	A		SAVE REG
	CMPA	#' '		CONTROL CODE?
	BHS	PUTC1		NO, TRY NEXT
	LDA	#'^'		INDICATE CONTROL
	SSR	33		OUTPUT
	LDA	,S		GET CHAR
	ADDA	#'@'		CONVERT
	BRA	PUTC2		AND DISPLAY
PUTC1	CMPA	#$7F		IN RANGE?
	BLO	PUTC2		NO, ITS OK
	LDA	#'<'		OPENING
	SSR	33		DISPLAY
	LDA	,S		GET CHAR
	SSR	28		DISPLAY
	LDA	#'>'		CLOSING
PUTC2	SSR	33		DISPLAY
	PULS	A,PC		RESTORE & RETURN
*
* MISC. STRINGS AND CONSTANTS
*
BADFIL	FCCZ	'Cannot locate TTY interface'
* MAIN MENU ITEMS
MMENU	FCCZ	'Standard key definitions'
	FCCZ	'Function key definitions'
	FCCZ	'Control code definitions'
	FCCZ	'Load settings from program'
	FCCZ	'Save settings to program'
	FCCZ	'Exit TTYPATCH utility'
	FCB	0
* OUTPUT STRING NAMES
ONAMES	FCCZ	'Terminal initialization'
	FCCZ	'Cursor positioning'
	FCCZ	'Clear screen'
	FCCZ	'Clear to end of line'
	FCCZ	'Clear to end of screen'
	FCCZ	'Special effect ON'
	FCCZ	'Special effect OFF'
	FCCZ	'Scroll screen forward'
	FCB	0
* INPUT STRING NAMES
INAMES	FCCZ	'Cursor up'
	FCCZ	'Cursor down'
	FCCZ	'Cursor right'
	FCCZ	'Cursor left'
	FCCZ	'Page up'
	FCCZ	'Page down'
	FCCZ	'Page right'
	FCCZ	'Page left'
	FCCZ	'Home'
	FCCZ	'End'
	FCCZ	'Delete character'
	FCCZ	'Delete previous'
	FCCZ	'Clear'
	FCB	0
* FUNCTION KEY NAMES
FNAMES	FCCZ	'Function key 1'
	FCCZ	'Function key 2'
	FCCZ	'Function key 3'
	FCCZ	'Function key 4'
	FCCZ	'Function key 5'
	FCCZ	'Function key 6'
	FCCZ	'Function key 7'
	FCCZ	'Function key 8'
	FCCZ	'Function key 9'
	FCCZ	'Function key 10'
	FCCZ	'Function key 11'
	FCCZ	'Function key 12'
	FCCZ	'Function key 13'
	FCCZ	'Function key 14'
	FCCZ	'Function key 15'
	FCB	0
*
* MISC VARIABLES
*
FLOAD	FDB	LOAD		PGM LOAD ADDRESS
FSIZE	FCB	0
*
* FUNCTION KEY EDIT AREA
*
IDATA	RMB	ISIZE*INUM
FDATA	RMB	ISIZE*FNUM
ODATA	RMB	ISIZE*ONUM
GDATA	EQU	ODATA+ISIZE
IEND	RMB	100		END OF INIT, STACK SPACE
STACK	EQU	*
*
* PROGRAM LOAD ADDRESS
*
LOAD	EQU	*		LOAD ADDRESS