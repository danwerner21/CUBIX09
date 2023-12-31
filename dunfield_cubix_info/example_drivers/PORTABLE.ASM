*
* PORTABLE COMPUTER - SCREEN DRIVER STUB (FOR "TTY" INTERFACE)
*
	ORG	OSUTIL
VC4404	LDX	ISTPTR		GET INPUT STRING POINTER
	SSR	23		OUTPUT TO TERMINAL
	RTS
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
GETKTAB	FCB	'Z'-$40,0	CURSOR UP
	FCB	'J'-$40,0	CURSOR DOWN
	FCB	'U'-$40,0	CURSOR RIGHT
	FCB	'H'-$40,0	CURSOR LEFT
	FCB	'E'-$40,0	PAGE UP
	FCB	'D'-$40,0	PAGE DOWN
	FCB	'U'+$40,0	PAGE RIGHT
	FCB	'H'+$40,0	PAGE LEFT
	FCB	'Z'+$40,0	HOME
	FCB	'J'+$40,0	END
	FCB	$FF,0		DELETE CHAR
	FCB	$7F,0		DELETE PREVIOUS
	FCB	'X'-$40,0	CLEAR SCREEN
* FUNCTION KEYS INPUT LOOKUP TABLES
	FCB	'1'+$80,0	F1
	FCB	'2'+$80,0	F2
	FCB	'3'+$80,0	F3
	FCB	'4'+$80,0	F4
	FCB	'5'+$80,0	F5
	FCB	'6'+$80,0	F6
	FCB	'7'+$80,0	F7
	FCB	'8'+$80,0	F8
	FCB	'9'+$80,0	F9
	FCB	'0'+$80,0	F10
	FCB	'='+$80,0	F11
	FCB	'-'+$80,0	F12
	FCB	$85,0		F13
	FCB	$86,0		F14
	FCB	$8D,0		F15
	FCB	0		END OF TABLE
* OUTPUT STRINGS
TTYPTR1	FCB	0
TTYPTR2	FCB	'P'-$40,%11000000,' ',%10000000,' ',0
TTYPTR3	FCB	'X'-$40,0
TTYPTR4	FCB	'V'-$40,0
TTYPTR5	FCB	'W'-$40,0
TTYPTR6	FCB	'N'-$40,0
TTYPTR7	FCB	'O'-$40,0
TTYPTR8	FCB	'P'-$40,'7',' ','J'-$40,0
