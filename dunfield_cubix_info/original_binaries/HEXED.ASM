*
* SYSTEM MEMORY LOCATIONS FOR USE BY APPLICATION PROGRAMS
*
OSRAM	EQU	$2000		USER APPLICATION RAM STARTS HEDE
OSEND	EQU	$DBFF		LAST LOCATION OF USER (NON-SYSTEM) RAM
OSUTIL	EQU	$D000		RAM FOR UTILITY PROGRAM USAGE
*
	title	HEXIDECIMAL SCREEN EDITOR
*
* HEXED: A terminal independant screen oriented file patch utility
*
* Copyright 1983-2005 Dave Dunfield
* All rights reserved.
*
HEX_D	EQU	8		START OF HEX DISPLAY
TEXT_D	EQU	60		START OF TEXT
*
	ORG	OSRAM		APPLICATION AREA
*
ENTRY	LDX	ISTPTR		GET INPUT STRING POINTER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	23		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	4		SYSTEM REQUEST NUMBER
	CMPA	#'?'		QUERY?
	BNE	MAIN		NO, PROCEED
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'Use: HEXED <filename>'
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	0		SYSTEM REQUEST NUMBER
*
MAIN	LDA	[GXYPTR]	DEFINED?
	BNE	MAIN1		NO, ITS OK
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'TTY not defined'
	LDA	#99		RC=99
ABORT	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	0		SYSTEM REQUEST NUMBER
MAIN1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	10		SYSTEM REQUEST NUMBER
	BNE	ABORT		REPORT ERROR
	LDX	#D_BUFF		POINT TO DATA BUFFER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	53		SYSTEM REQUEST NUMBER
	BNE	ABORT		REPORT ERROR
	STX	ENDADR		SAVE END ADDRESS
	LDU	#D_BUFF		BEGIN AT START OF BUFFER
*
* VISUAL MODE MAIN LOOP
*
VMODE1	JSR	DSCREEN		DISPLAY SCREEN
* DISPLAY ANY ERROR MESSAGES
VMODE2	LDX	ERRMSG		ANY MSGS?
	BEQ	VMODE2A		NO, ITS OK
VERROR	LDD	#23		LAST LINE
	JSR	GOTOXY		RE-POSITION
	JSR	WSO		SPECIALS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	23		SYSTEM REQUEST NUMBER
	JSR	WSE		END OF IT
	JSR	WCD		CLEAR END OF SCREEN
	CLRA			ZERO HIGH
	CLRB			ZERO LOW
	STD	ERRMSG		RESET FLAG
* POSITION CURSOR TO APPRIOPRIATE POSITION
VMODE2A	LDA	POSIT		GET POSITION
	ANDA	#%00001111	GET 'X' POSITION
	LDB	MODE		GET MODE
	BMI	VMODE3		TEXT MODE
* HEXIDECIMAL ENTRY MODE
	PSHS	A		SAVE DATA
	LSLA			X2
	ADDA	,S+		X3
	ADDA	#HEX_D		OFFSET TO HEX DISPLAY
	BRA	VMODE4		AND PROCEED
* TEXT ENTRY MODE
VMODE3	ADDA	#TEXT_D		OFFSET TO TEXT
VMODE4	LDB	POSIT		GET POSITION
	LSRB			/
	LSRB			16
	LSRB			TO CALC
	LSRB			ROWS
	ADDB	#4		OFFSET TO DATA
	JSR	GOTOXY		POSITION CURSOR
VMODE5	JSR	GETKEY		GET A KEY
	LDB	POSIT		GET POSITION
	TFR	U,X		GET BASE ADDRESS
	ABX			'X' = ADDRESS IN TEXT
	TSTA			SPECIAL KEY?
	LBPL	ENTKEY		ENTRY KEY
* REFRESH SCREEN
	CMPA	#$8C		CLEAR?
	BEQ	VMODE1		YES, REFRESH
* UP ARROW
	CMPA	#$80		UP ARROW?
	BNE	VCMD1		NO, TRY NEXT
	SUBB	#16		CONVERT
	BCC	SAVPOS		ITS OK
	ADDB	#16		GO BACK
	LEAU	-16,U		BACKUP
* TEST FOR VALID UP RANGE
TSTUP	CMPU	#D_BUFF		IN RANGE?
	BHS	REFRESH		ITS OK
	LDX	#HOMEMSG	HOME MESSAGE
	STX	ERRMSG		DISPLAY IT
HOME	LDU	#D_BUFF		RESET PTR
	CLRB			ZERO POSITION
REFRESH	STB	POSIT		SET IT
	JSR	DSCR1		PARTIAL UPDATE
	JMP	VMODE2		AND PROCEED
* DOWN ARROW
VCMD1	CMPA	#$81		DOWN ARROW?
	BNE	VCMD2		NO, TRY NEXT
	ADDB	#16		NEXT LINE
	BCC	SAVPOS		NO, ITS OK
	SUBB	#16		CONVERT BACK
	LEAU	16,U		ADVANCE A ROW
*
TSTDOWN	LDX	ENDADR		GET END
	LEAX	-256,X		CALCULATE BACK PAGE
	PSHS	X		SAVE IT
	CMPU	,S++		TEST IT
	BLS	REFRESH		ITS OK
	LDX	#ENDMSG		GET MESSAGE
	STX	ERRMSG		DISPLAY IT
END	LDU	ENDADR		GET END
	LEAU	-256,U		BACKUP SCREEN
	LDB	#$FF		END OF SCREEN
	BRA	REFRESH		AND PROCEED
* RIGHT ARROW
VCMD2	CMPA	#$82		RIGHT ARROW?
	BNE	VCMD3		NO, ITS OK
	INCB			ADVANCE 'B'
SAVPOS	STB	POSIT		SAVE POSITION
	JMP	VMODE2		AND PROCEED
* LEFT ARROW
VCMD3	CMPA	#$83		LEFT ARROW?
	BNE	VCMD4		AND PROCEED
	DECB			BACKUP
	BRA	SAVPOS		SAVE POSITION
* PAGE UP
VCMD4	CMPA	#$84		PAGE UP?
	BNE	VCMD5		NO, TRY NEXT
	LEAU	-256,U		BACKUP
	BRA	TSTUP		AND TRY IT
* PAGE DOWN
VCMD5	CMPA	#$85		PAGE DOWN?
	BNE	VCMD6		NO, TRY NEXT
	LEAU	256,U		SKIP AHEAD
	BRA	TSTDOWN		AND TRY IT
* HOME & END
VCMD6	CMPA	#$88		HOME?
	BEQ	HOME		DO IT
	CMPA	#$89		END?
	BEQ	END		DO IT
* TOGGLE DATA ENTRY MODE
	CMPA	#$8F		F3?
	BNE	VCMD7		NO, TRY NEXT
	COM	MODE		RESET MODE
	JMP	VMODE2		AND PROCEED
* COMMAND EXEC KEY
VCMD7	CMPA	#$8D		F1?
	BEQ	ECMD		EXECUTE COMMAND
	CMPA	#$8E		F2?
	BEQ	RECMD		RE-EXECUTE
* INVALID KEY ENTERRED
INVKEY	LDX	#BADKEY		POINT TO MESSAGE
	JMP	VERROR
*
* RE-EXECUTE LINE MODE COMMAND
*
RECMD	LDY	#CMDBUF		SET UP PTR
	BRA	RECMD1		AND PROCEED
*
* EXECUTE LINE MODE COMMAND
*
ECMD	LDD	#23		COMMAND INPUT LINE
	JSR	GOTOXY		MOVE THERE
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'Command: '
	JSR	WCD		CLEAR REST
* READ INPUT COMMAND
	LDX	#CMDBUF		POINT TO INPUT BUFFER
	TFR	X,Y		SET UP PTR
ECMD1	JSR	GETKEY		GET A KEY
	TSTA			SPECIAL KEY?
	BMI	ECMD2		YES, HANDLE IT
	STA	,X+		WRITE IT
	JSR	DCHAR		WRITE CHAR
	BRA	ECMD1		AND PROCEED
* SPECIAL KEY ENTERED
ECMD2	CLR	,X		TERMINATE LINE
	CMPA	#$8B		DELETE PREVIOUS?
	BNE	ECMD3		NO, TRY NEXT
	CMPX	#CMDBUF		AT COMMAND BUFFER
	BLS	ECMD		YES, DON'T DELETE
	LEAX	-1,X		BACKUP
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCB	8,' ',8,0	WIPE IT OUT
	BRA	ECMD1		GET NEXT KEY
* COMMAND KEY, RE-EXECUTE COMMAND
ECMD3	CMPA	#$8D		F1?
	BNE	INVKEY		INDICATE INVALID
RECMD1	LDD	#21		RESET POINTER
	JSR	GOTOXY		NEW LINE
	JSR	WCD		CLEAR DISPLAY
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	4		SYSTEM REQUEST NUMBER
	BEQ	ECMD3B		NULL, EXIT
	JSR	TOUPPER		INSURE ITS UPPERCASE
	LEAY	1,Y		SKIP COMMAND CHAR
* 'W'RITE FILE COMMAND
	CMPA	#'W'		WRITE OUT FILE
	BNE	ECMD4		NO, TRY NEXT
	LDD	ENDADR		GET END ADDRESS
	SUBD	#D_BUFF		'D' = SIZE OF FILE
	TFR	A,B		B = # 256 BYTE BLOCKS
	LSRB			B = # 512 BYTE BLOCKS
	CLRA			ZERO HIGH
	LDX	#D_BUFF		POINT TO BUFFER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	54		SYSTEM REQUEST NUMBER
	BNE	ECMD3A		REPORT ERROR
	CLR	CHANGED		INDICATE SAVED
	BRA	ECMD3B		AND PROCEED
ECMD3A	LDX	#DOSERR		INDICATE DOS ERROR
	STX	ERRMSG		SET IT
ECMD3B	JMP	VMODE2		RETURN TO MAIN SCREEN
* 'Q'UIT COMMAND
ECMD4	CMPA	#'Q'		QUIT?
	BNE	ECMD5		NO, TRY NEXT
	LDA	CHANGED		MODIFIED?
	BEQ	ECMD4A		NO, ITS OK
	LDA	,Y		GET NEXT
	JSR	TOUPPER
	CMPA	#'Q'		ANYWAY?
	BEQ	ECMD4A		ITS OK
	LDX	#QUIMSG		POINT TO MESSAGE
	JMP	VERROR		INDICATE ERROR
ECMD4A	JSR	WCLS		CLEAR SCREEN
	CLRA			ZERO RC
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	0		SYSTEM REQUEST NUMBER
* 'G'OTO COMMAND
ECMD5	CMPA	#'G'		GOTO?
	BNE	ECMD6		NO, TRY NEXT
	BSR	CVCAP		CONVERT INPUT TO CAPS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	7		SYSTEM REQUEST NUMBER
	BNE	ECMD6B		REPORT ERROR
	TFR	X,D		COPY IT
REPOS	PSHS	B		SAVE LOW
	CLRB			ZERO LOW
	ADDD	#D_BUFF		OFFSET TO DATA BUFFER
	TFR	D,U		SET UP 'U'
	PULS	B		RESTORE POSIT
	JMP	TSTDOWN		TEST FOR IT
* CONVERT INPUT LINE TO UPPERCASE
CVCAP	TFR	Y,X		'X' = INP PTR
CVCAP1	LDA	,X		GET CHAR
	JSR	TOUPPER		CONVERT TO UPPERCASE
	STA	,X+		WRITE IT BACK OUT
	BNE	CVCAP1		AND PROCEED
	RTS
* '/' HEXIDECIMAL SEARCH
ECMD6	CMPA	#'/'		HEX SEARCH?
	BNE	ECMD7		NO, TRY NEXT
	BSR	CVCAP		CONVERT TO CAPS
	CLR	TEMP		ZERO TEMP
	LDX	#FNDBUF		POINT TO FIND BUFFER
ECMD6A	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	4		SYSTEM REQUEST NUMBER
	BEQ	SEARCH		NO MORE OPS
	PSHS	X		SAVE 'X'
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	7		SYSTEM REQUEST NUMBER
	PULS	X		RESTORE 'X'
	BNE	ECMD6B		REPORT ERROR
	STB	,X+		WRITE IT
	INC	TEMP		ADVANCE COUNT
	BRA	ECMD6A		AND PROCEED
ECMD6B	LDX	#BADHEX		INDICATE INVALID
	JMP	VERROR		REPORT ERROR
* '?' SEARCH FOR TEXT
ECMD7	CMPA	#'?'		SEARCH?
	BNE	ECMD8		NO, TRY NEXT
	LDX	#FNDBUF		POINT TO FIND BUFFER
	LDB	#-1		BEGIN WITH -1
ECMD7A	INCB			ADVANCE IT
	LDA	,Y+		GET NEXT CHAR
	STA	,X+		WRITE INTO FIND BUFFER
	BNE	ECMD7A		CONTINUE
	STB	TEMP		SAVE FOR LATER
* PERFORM SEARCH
SEARCH	TFR	U,X		GET PTR
	LDB	POSIT		GET POSITION
	ABX			ADVANCE IT
SEARC1	LDY	#FNDBUF		POINT TO FIND BUFFER
	CLRB			ZERO COUNT
	LEAX	1,X		ADVANCE BY 1
SEARC2	CMPX	ENDADR		ARE WE OVER?
	BHS	SEARC3		YES, REPORT ERROR
	LDA	,Y+		GET CHAR
	CMPA	B,X		DOES IT MATCH?
	BNE	SEARC1		NO, KEEP LOOKING
	INCB			ADVANCE COUNT
	CMPB	TEMP		ARE WE OVER?
	BLO	SEARC2		NO, KEEP LOOKING
* WE FOUND STRING
	TFR	X,D		'D' = ADDRESS
	SUBD	#D_BUFF		ADJUST TO TEXT POSITION
	BRA	REPOS		POSITION US THERE
* STRING WAS NOT FOUND
SEARC3	LDX	#NOTFND		POINT TO MESSAGE
	JMP	VERROR		REPORT ERROR
*
ECMD8	LDX	#BADCMD		INVALID COMMAND
	JMP	VERROR		REPORT ERROR
*
* DATA ENTRY KEY PRESSED
*
ENTKEY	LDB	MODE		GET DATA MODE
	BMI	ENTK1		CHARACTER MODE
	BSR	GETHEX		CONVERT HEX
	LSLA			SHIFT
	LSLA			OVER
	LSLA			INTO HIGH
	LSLA			BITS
	STA	TEMP		SAVE FOR LATER
	JSR	GETKEY		GET NEXT KEY
	BSR	GETHEX		CONVERT TO HEX
	ORA	TEMP		INCLUDE FIRST
ENTK1	STA	,X		WRITE IN TEXT
	LDA	#-1		GET CHANGED FLAG
	STA	CHANGED		INDICATE CHANGED
* FOR CORRECT DATA, ADVANCE CURSOR POSITION
	LDA	POSIT		GET POSITION
	INC	POSIT		ADVANCE IT
* UPDATE SCREEN CHARACTERS
ENTK2	TFR	A,B		COPY FOR LATER
	ANDA	#%00001111	GET 'X' POSITION
	STA	TEMP		SAVE FOR LATER
	LSLA			X2
	ADDA	TEMP		x3
	ADDA	#HEX_D		OFFSET TO CHAR
	LSRB			/
	LSRB			16
	LSRB			TO CALC
	LSRB			ROWS
	ADDB	#4		OFFSET TO DATA
	JSR	GOTOXY		POSITION CURSOR
	LDA	,X		GET CHAR
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	28		SYSTEM REQUEST NUMBER
	LDA	TEMP		GET POSITION AGAIN
	ADDA	#TEXT_D		CONVERT TO OFFSET
	JSR	GOTOXY		MOVE THERE
	LDA	,X		GET CHAR
	JSR	DCHAR		DISPLAY IT
	JMP	VMODE2		AND RESTORE
* CONVERT CHAR IN 'A' TO HEX NIBBLE
GETHEX	TFR	A,B		SAVE CHAR
	CMPA	#'0'		IN RANGE?
	BLO	GETH2		BAD
	CMPA	#'9'		IN RANGE?
	BLS	GETH1		GOOD
	BSR	TOUPPER		CONVERT TO UPPERCASE
	CMPA	#'A'		IN RANGE?
	BLO	GETH2		BAD
	CMPA	#'F'		IN RANGE?
	BHI	GETH2		BAD
	SUBA	#7		PARTIAL CONVERT
* VALID HEX DIGIT ENTERED
GETH1	SUBA	#'0'		TOTAL CONVERT
	EXG	A,B		SWAP
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	TFR	B,A		GET CHAR BACK
	RTS
* INVALID HEX DIGIT ENTERED
GETH2	LEAS	2,S		SKIP SAVED PC
	LDD	#BADHEX		INDICATE INVALID
	STD	ERRMSG		SET MESSAGE
	LDA	POSIT		GET POSITION
	BRA	ENTK2		AND FIX SCREEN
* CONVERT CHAR(A) TO UPPER CASE
TOUPPER	CMPA	#'A'+$20	LOWER CASE 'A'?
	BLO	TOUPP1		NO, ITS OK
	CMPA	#'Z'+$20	LOWER CASE 'Z'?
	BHI	TOUPP1		NO, ITS OK
	ANDA	#%01011111	CONVERT TO UPPER
TOUPP1	RTS
*
* DRAW A SCREEN
*
DSCREEN	JSR	WCLS		CLEAR SCREEN
	LDB	#30		COUNT
	BSR	DDASH		DISPLAY DASHES
	JSR	WSO		SPECIAL EFFECTS ON
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	' HEXED Version 1.0 '
	JSR	WSE		SPECIAL EFFECTS OFF
	LDB	#30		COUNT
	BSR	DDASH		OUTPUT DASHES
	LDD	#$0002		NEW POSITION
	JSR	GOTOXY		POSITION CURSOR
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'File: '
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	30		SYSTEM REQUEST NUMBER
	LDD	#=TEXT_D+2	POSITION
	JSR	GOTOXY		POSITION CURSOR
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'Size: '
	LDD	ENDADR		GET END
	SUBD	#D_BUFF		CALCULATE SIZE
	PSHS	A,B		SAVE IT
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	26		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	' ($'
	PULS	A,B		RESTORE IT
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	27		SYSTEM REQUEST NUMBER
	LDA	#')'		CLOSING
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
DSCR1	LDD	#$0004		NEW POSITION
	JSR	GOTOXY		POSITION CURSOR
	LDB	#16		16x16 BYTE LINES
	TFR	U,X		'X' = ADDR
DSCR2	BSR	DLINE		DISPLAY LINE
	LEAX	16,X		ADVANCE IT
	DECB			REDUCE COUNT
	BNE	DSCR2		AND CONTINUE
	BRA	WCD
* DISPLAY LINE OF DASHES (B=LENGTH)
DDASH	LDA	#'-'		GET DASH
DDASH1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	DECB			REDUCE COUNT
	BNE	DDASH1		AND CONTINUE
	RTS
*
* DISPLAY 16 BYTE LINE(X)
*
DLINE	PSHS	A,B,X		SAVE REG'S
	TFR	X,D		GET ADDRESS
	SUBD	#D_BUFF		CONVERT ADDRESS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	27		SYSTEM REQUEST NUMBER
	LDA	#HEX_D-4	# SPACES
	BSR	SPACES		DISPLAY SPACES
* DISPLAY HEX FIELDS
	LDB	#16		16 BYTES/LINE
DLINE1	LDA	,X+		GET ADDRESS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	28		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	21		SYSTEM REQUEST NUMBER
	DECB			REDUCE COUNT
	BNE	DLINE1		DO ALL
* DISPLAY TEXT FIELDS
	LDA	#TEXT_D-HEX_D-48
	BSR	SPACES		OUTPUT SPACES
	LDX	2,S		RESTORE 'X'
	LDB	#16		16 BYTES/LINE
DLINE2	LDA	,X+		GET CHAR
	BSR	DCHAR		DISPLAY CHAR
	DECB			REDUCE COUNT
	BNE	DLINE2		DO THEM ALL
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	22		SYSTEM REQUEST NUMBER
	PULS	A,B,X,PC	RESTORE & RETURN
* DISPLAY # SPACES
SPACES	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	21		SYSTEM REQUEST NUMBER
	DECA			REDUCE COUNT
	BNE	SPACES		DO THEM ALL
	RTS
* DISPLAY CHARACTER
DCHAR	CMPA	#' '		IN RANGE?
	BLO	DCHAR1		NO, CONVERT
	CMPA	#$7F		ALSO IN RANGE?
	BLO	DCHAR2		YES, ITS OK
DCHAR1	LDA	#'.'		CONVERT TO DOT
DCHAR2	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	RTS
* WRITE SPECIAL CONTROL CHARACTERS
WCLS	LDA	#$80		CLEAR SCREEN
	BRA	PUTCHR
WSO	LDA	#$83		SPECIAL ON
	BRA	PUTCHR
WSE	LDA	#$84		SPECIAL OFF
	BRA	PUTCHR
WCD	LDA	#$82		CLEAR DISPLAY
*
* WRITE A CHARACTER TO THE DISPLAY
*
PUTCHR	TSTA			SPECIAL CASE?
	BMI	PUTC1		YES, HANDLE IT
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	RTS
* SPECIAL STRING TO OUTPUT
PUTC1	PSHS	A,X		SAVE REGISTERS
	LSLA			X2 FOR TWO BYTE ENTRIES
	LDX	#PUTTAB		POINT TO TABLE
	LDX	A,X		GET DATA TO WRITE
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	23		SYSTEM REQUEST NUMBER
	PULS	A,X,PC		RESTORE & RETURN
*
* MOVE CURSOR POSITION
*
GOTOXY	PSHS	A,B,X		SAVE CHARS
	LDX	GXYPTR		POINT TO BUFFER
GOTOXY1	LDA	,X+		GET CHAR
	BEQ	GOTOXY6		END, EXIT
	BMI	GOTOXY3		SPECIAL CODE
* NORMAL CHARACTER, DISPLAY IT
GOTOXY2	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	BRA	GOTOXY1		AND PROCEED
* SPECIAL TRANSLATED (X/Y) CODE
GOTOXY3	LDB	,S		GET 'X' POSITION
	BITA	#%01000000	IS IT 'X'?
	BEQ	GOTOXY4		YES, ALL IS OK
	LDB	1,S		GET 'Y' POSITION
GOTOXY4	ADDB	,X+		INCLUDE OFFSET
	BITA	#%00100000	DECIMAL?
	BNE	GOTOXY5		YES, DO DECIMAL
	TFR	B,A		GET CHAR
	BRA	GOTOXY2		OUTPUT & PROCEED
GOTOXY5	CLRA			ZERO HIGH
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	26		SYSTEM REQUEST NUMBER
	BRA	GOTOXY1		AND PROCEED
GOTOXY6	PULS	A,B,X,PC	RESTORE & RETURN
*
* GET AN INPUT KEY FROM THE TERMINAL
*
GETKEY	PSHS	B,X,U		SAVE REGS
GETK1	LDU	#GETKTAB	POINT TO KEY TABLE
	LDB	#$80		FIRST FUNCTION CODE
GETK2	LDX	#GETKBUF	POINT TO KEY BUFFER
GETK3	LDA	,X+		GET CHAR
	BEQ	GETK6		PARTIAL MATCH
	CMPA	,U		GET CHAR FROM TABLE
	BNE	GETK4		DOSN'T MATCH
	LEAU	1,U		ADVANCE
	BRA	GETK3		KEEP LOOKING
* CHAR DID NOT MATCH, ADVANCE TO NEXT
GETK4	LDA	,U+		GET CHAR
	BNE	GETK4		KEEP LOOKING
	INCB			ADVANCE FUNCTION CODE
	LDA	,U		END OF TABLE?
	BNE	GETK2		NO, KEEP LOOKING
* HIT END OF TABLE, NO MATCHES
* REMOVE AND RETURN ONE CHAR FROM THE INPUT
	LDX	#GETKBUF	POINT TO BUFFER
	LDA	,X+		GET CHAR
	BEQ	GETK8		NONE, GET A KEY
GETK5	LDB	,X+		GET NEXT CHAR
	STB	-2,X		WRITE IT
	BNE	GETK5		DO THEM ALL
	ANDA	#%01111111	INSURE NO HIGH BUT
	PULS	B,X,U,PC	RETURN WITH CHAR
* HIT END OF STRING WITH ALL MATCHES
GETK6	LDA	,U		END OF STRING?
	BEQ	GETK7		YES, WE HAVE IT
GETK8	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	34		SYSTEM REQUEST NUMBER
	STA	-1,X		WRITE INTO STRING
	CLR	,X		ZERO END
	BRA	GETK1		RETEST FOR MATCHES
* WE FOUND AN INPUT STRING
GETK7	TFR	B,A		GET CHAR
	CLR	>GETKBUF	ZERO BUFFER
	PULS	B,X,U,PC	RESTORE & RETURN
*
* STRINGS & MESSAGES
*
BADKEY	FCCZ	'Invalid key'
BADHEX	FCCZ	'Invalid hex digit'
BADCMD	FCCZ	'Unknown command'
NOTFND	FCCZ	'Not found'
DOSERR	FCCZ	'Failed'
QUIMSG	FCCZ	"Unsaved changes, use 'qq' to quit anyway"
HOMEMSG	FCCZ	'Backup beyond start of file'
ENDMSG	FCCZ	'Advance beyond end of file'
* GETKEY INPUT BUFFER
GETKBUF	FCB	0,0,0,0,0	INPUT BUFFER
	FCB	0,0,0,0,0	FOR GET KEY
* OUTPUT TRANSLATION TABLES
ISTPTR	FDB	GETKTAB		INITIALIZATION STRING
GXYPTR	FDB	GETKTAB		GOTO X-Y HANDLER
PUTTAB	FDB	GETKTAB		CLEAR SCREEN
	FDB	GETKTAB		CLEAR END OF LINE
	FDB	GETKTAB		CLEAR END OF DISPLAY
	FDB	GETKTAB		SPECIAL EFFECTS ON
	FDB	GETKTAB		SPECIAL EFFECTS OFF
	FDB	GETKTAB		SCROLL FORWARD
* STANDARD TERMINAL KEYS INPUT LOOKUP TABLE
GETKTAB	FCB	0		CURSOR UP
	RMB	200		SAVE KEY SPACE
*
* RESERVED VARIABLES
*
ENDADR	FDB	D_BUFF		ENDING ADDRESS
CHANGED	FCB	0		FILE CHANGED FLAG
POSIT	FCB	0		CURSOR POSITION
MODE	FCB	0		TEXT/HEX MODE
ERRMSG	FDB	0		REPORT ERROR
TEMP	RMB	1		TEMPORARY STORAGE
CMDBUF	RMB	50		COMMAND INPUT BUFFER
FNDBUF	RMB	50		FIND BUFFER
D_BUFF	EQU	*		DATA BUFFER
