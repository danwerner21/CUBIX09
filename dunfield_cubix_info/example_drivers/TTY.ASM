	TITLE	TERMINAL INDEPENDANT SCREEN INTERFACE
*
* Terminal independant screen interface routines. These functions
* provide a screen oriented interface which is compatible with most
* modern terminals.
*
* The following features are assumed to be available:
*
*	1) Absolute cursor positioning
*	2) Clear entire screen
*	3) Clear from cursor to end of line
*	4) Clear from cursor to end of display
*	5) One special video effect (Reverse etc.)
*	6) Forward screen scrolling (Such as line-feed on bottom line)
*
* Copyright 1983-2004 Dave Dunfield
*
* SPECIAL FUNCTION CODES RECOGNIZED BY PUTCHR
*
CLS	EQU	$80		CLEAR ENTIRE SCREEN
CLE	EQU	$81		CLEAR TO END OF LINE
CLD	EQU	$82		CLEAR TO END OF DISPLAY
SON	EQU	$83		SPECIAL EFFECT ON (REVERSE VIDEO)
SOFF	EQU	$84		SPECIAL EFFECT OFF
SCROLL	EQU	$85		SCROLL SCREEN FORWARD
*
* INPUT CODES RETURNED BY GETKEY
*
* "STANDARD" KEYS, SHOULD BE CONSISTENT BETWEEN ALL SCREEN
* ORIENTED APPLICATIONS.
CUP	EQU	$80		CURSOR UP
CDOWN	EQU	$81		CURSOR DOWN
CRIGHT	EQU	$82		CURSOR RIGHT
CLEFT	EQU	$83		CURSOR LEFT
PUP	EQU	$84		PAGE UP
PDOWN	EQU	$85		PAGE DOWN
PRIGHT	EQU	$86		PAGE RIGHT
PLEFT	EQU	$87		PAGE LEFT
PHOME	EQU	$88		MOVE TO HOME POSITION
PEND	EQU	$89		MOVE TO END POSITION
DELC	EQU	$8A		DELETE CHARACTER UNDER CURSOR
DELP	EQU	$8B		DELETE PREVIOUS CHARACTER
CLEAR	EQU	$8C		CLEAR (REFRESH) SCREEN
* "FUNCTION" KEYS FOR APPLICATION SPECIFIC FUNCTIONS, WHENEVER
* POSSIBLE, CONSISTENCY SHOULD BE MAINTAINED WITH THE EDITORS
* USE OF THESE KEYS (SHOWN IN BRACKETS).
F1	EQU	$8D		(EXECUTE LINE MODE COMMAND)
F2	EQU	$8E		(REEXECUTE LAST COMMAND)
F3	EQU	$8F		(TOGGLE INSERT/OVERWRITE MODE)
F4	EQU	$90		(TOGGLE END OF LINE DISPLAY)
F5	EQU	$91		(DISPLAY CURSOR POSITION)
F6	EQU	$92		(CURRENT LINT TO TOP)
F7	EQU	$93		(TAG LINE(S))
F8	EQU	$94		(DELETE LINE)
F9	EQU	$95		(DELETE TO END OF LINE)
F10	EQU	$96		(INSERT DELETED LINE)
F11	EQU	$97		(WORD RIGHT)
F12	EQU	$98		(WORD LEFT)
F13	EQU	$99		(UNDEFINED)
F14	EQU	$9A		(UNDEFINED)
F15	EQU	$9B		(UNDEFINED)
*
*    TERMINAL INITIALIZATION ROUTINE. THIS ROUTINES SENDS THE PREDEFINED
* STRING TO THE TERMINAL, ALLOWING FUNCTION KEYS AND OR MODES TO BE SET
* UP WHEN THE SCREEN APPLICATION IS INVOKED.
*
*    THIS MUST BE THE FIRST CODE TO OCCUR IN THE '.EXE' FILE. THE "TTYPATCH"
* UTILITY KEYS ON THIS CODE SEQUENCE TO DETERMINE IF THE FILE USES THIS
* INTERFACE AND THUS MAY BE PATCHED, AND ALSO TO DETERMINE THE ADDRESS OF
* TERMINAL INDEPENDANCE TABLES.
*
ENTRY	LDX	ISTPTR		GET INPUT STRING POINTER
	SSR	23		OUTPUT TO TERMINAL
*
* THE MAIN PROGRAM CODE FOR THE APPLICATION SHOULD OCCUR HERE.
*
MAIN	EQU	*		MAINLINE CODE GOES HERE
*
* TERMINAL INDEPENDANT SCREEN HANDLING ROUTINES
*
* PUTCHR    - WRITE CHAR(A), [A >= $80 - SPECIAL FUNCTION]
* GOTOXY    - MOVE CURSOR POSITION A='X', B='Y' (ORIGIN 0)
* GETKEY    - GET KEY IN(A), [A >= $80 - SPECIAL CODE]
*
* WRITE A CHARACTER TO THE DISPLAY
*
PUTCHR	TSTA			SPECIAL CASE?
	BMI	PUTC1		YES, HANDLE IT
	SSR	33		DISPLAY IT
	RTS
* SPECIAL STRING TO OUTPUT
PUTC1	PSHS	A,X		SAVE REGISTERS
	LSLA			X2 FOR TWO BYTE ENTRIES
	LDX	#PUTTAB		POINT TO TABLE
	LDX	A,X		GET DATA TO WRITE
	SSR	23		DISPLAY IT
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
GOTOXY2	SSR	33		DISPLAY IT
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
	SSR	26		DISPLAY IN DECIMAL
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
GETK8	SSR	34		GET INPUT KEY
	STA	-1,X		WRITE INTO STRING
	CLR	,X		ZERO END
	BRA	GETK1		RETEST FOR MATCHES
* WE FOUND AN INPUT STRING
GETK7	TFR	B,A		GET CHAR
	CLR	>GETKBUF	ZERO BUFFER
	PULS	B,X,U,PC	RESTORE & RETURN
*
* DATA AREAS, ANY VARIABLES USED IN THE APPLICATION PROGRAM
* SHOULD BE PLACED IN THIS SECTION, SO THAT NO RESERVED
* STORAGE WILL BE USED AFTER THE TERMINAL INDEPENDANCE TABLES,
* ALLOWING THEM TO GROW (VIA "TTYPATCH").
*
GETKBUF	FCB	0,0,0,0,0	INPUT BUFFER
	FCB	0,0,0,0,0	FOR GET KEY
*
* TERMINAL INDEPENDANCE TABLES, PROVIDES "PUTCHR", "GOTOXY",
* AND "GETKEY" WITH THE INFORMATION NEEDED TO MANIPULATE THE
* TERMINAL SCREEN.
*
* THE EXAMPLE TABLES SHOWN ARE THE DEFAULT PROVIDED WITH ALL
* SYSTEM UTILITIES, WHICH PROVIDE FOR OPERATION USING A "VT100"
* OR COMPATABLE TERMINAL.
*
* *** DO NOT MODIFY THE ORDER OF THESE TABLES ***
*
* OUTPUT TRANSLATION TABLES
ISTPTR	FDB	TTYPTR1		INITIALIZATION STRING
GXYPTR	FDB	TTYPTR2		GOTO X-Y HANDLER
PUTTAB	FDB	TTYPTR3		CLEAR SCREEN
	FDB	TTYPTR4		CLEAR END OF LINE
	FDB	TTYPTR5		CLEAR END OF DISPLAY
	FDB	TTYPTR6		SPECIAL EFFECTS ON
	FDB	TTYPTR7		SPECIAL EFFECTS OFF
	FDB	TTYPTR8		SCROLL FORWARD
* STANDARD TERMINAL KEYS INPUT LOOKUP TABLE
GETKTAB	FCB	$1B,'[','A',0	CURSOR UP
	FCB	$1B,'[','B',0	CURSOR DOWN
	FCB	$1B,'[','C',0	CURSOR RIGHT
	FCB	$1B,'[','D',0	CURSOR LEFT
	FCB	$1B,'O','w',0	PAGE UP
	FCB	$1B,'O','x',0	PAGE DOWN
	FCB	$1B,'O','u',0	PAGE RIGHT
	FCB	$1B,'O','t',0	PAGE LEFT
	FCB	$1B,'O','P',0	HOME
	FCB	$1B,'O','Q',0	END
	FCB	$08,0		DELETE CHAR
	FCB	$7F,0		DELETE PREVIOUS
	FCB	$1B,'O','n',0	CLEAR SCREEN
* FUNCTION KEYS INPUT LOOKUP TABLES
	FCB	$1B,'O','M',0	F1
	FCB	$1B,'O','l',0	F2
	FCB	$0A,0		F3
	FCB	$1B,'O','v',0	F4
	FCB	$1B,'O','s',0	F5
	FCB	$1B,'O','y',0	F6
	FCB	$1B,'O','p',0	F7
	FCB	$1B,'O','S',0	F8
	FCB	$1B,'O','R',0	F9
	FCB	$1B,'O','m',0	F10
	FCB	$1B,'O','q',0	F11
	FCB	$1B,'O','r',0	F12
	FCB	$1B,'1',0	F13
	FCB	$1B,'2',0	F14
	FCB	$1B,'3',0	F15
	FCB	0		END OF TABLE
* OUTPUT STRINGS
TTYPTR1	FCB	$1B,'=',0
TTYPTR2	FCB	$1B,'[',%11100000,1,';',%10100000,1,'H',0,0,0
TTYPTR3	FCB	$1B,'[','H',$1B,'[','J',0
TTYPTR4	FCB	$1B,'[','K',0
TTYPTR5	FCB	$1B,'[','J',0
TTYPTR6	FCB	$1B,'[','7','m',0
TTYPTR7	FCB	$1B,'[','0','m',0
TTYPTR8	FCB	$1B,'[','2','4',';','1','H',$0A,0
