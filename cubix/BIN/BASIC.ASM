*
* SYSTEM MEMORY LOCATIONS FOR USE BY APPLICATION PROGRAMS
*
OSRAM	EQU	$2000		USER APPLICATION RAM STARTS HEDE
OSEND	EQU	$DBFF		LAST LOCATION OF USER (NON-SYSTEM) RAM
OSUTIL	EQU	$D000		RAM FOR UTILITY PROGRAM USAGE
*
;build	SET	cubix
CODE	EQU	$2000
RAM	EQU	$3000
STACK	EQU	$D000
;
__FOR	EQU	$1000
__GOSUB	EQU	__FOR+1
;
		ORG	RAM
pgm_start	RMB	2	; Program starting line pointer
runptr		RMB	2	; Executing line pointer
readptr		RMB	2	; Data read line pointer
dataptr		RMB	2	; Data read element pointer
line		RMB	2	; Current line number
randseed	RMB	2	; Random number seed
temp		RMB	2	; Temporary location
temp1		RMB	2	; Temporary location
ctl_ptr		RMB	1	; Control stack pointer
expr_type 	RMB	1	; Expression type (0=Num, 1=Char)
nest		RMB	1	; Expression nesting level
mode		RMB	1	; Execution mode (0=Interactive, 1=Run)
keypress	RMB	1	; Key has been pressed
file		RMB	2	; Active file indicator
files		RMB	10*2	; File handles
buffer		RMB	100	; General buffer
sa1		RMB	100	; String accumulator#1
sa2		RMB	100	; String accumulator#2
ctl_stk		RMB	100	; Control stack
char_vars	RMB	260*2	; Character variable pointers
num_vars	RMB	260*2	; Numeric variable values
dim_vars	RMB	260*2	; Dimensioned variable pointers
dim_check	RMB	260*2	; Dimensioned variable sizes
?heap		EQU	*
;
	ORG	CODE
	CMPA	#'?'		; Help?
	BNE	begin		; No
	FCB	$3F,25		; Output message
	FCCZ	'Use: BASIC [program]'
	FCB	$3F,0
begin	LDS	#STACK
	LDA	#=RAM		; Point to RAM
	TFR	A,DP		; Set DP
	SETDP	=RAM
_NEW:	LBSR	clrall		; Zero all of RAM
	FCB	$3F,4		; SSR 11 - check for data
	BEQ	top		; Not it
	LBSR	xload		; Load the file
	LDX	pgm_start	; Start of program
	LBSR	_run1		; Execute
top:	LDS	#stack		; Reset stack
	CLR	file		; Reset to console
	CLR	file+1		; Reset to console
	LBSR	putm		; Output message
	FCC	'Ready'		; Text
	FCB	$0A,$0D,0	; Newline
top1:	CLRA			; Zero high
	STA	ctl_ptr		; Disable program
	STA	mode		; Not running
	LDY	#buffer		; Point to buffer
	LBSR	gets		; Get string
	LBSR	edit		; Do line edit
	BEQ	top1		; No prompt on edit
	LDA	buffer		; Get data
	BPL	top2		; Not a keyboard
	LEAY	1,Y		; Skip keyword
	BSR	execute		; Process keyword
	BRA	top		; next command
top2	BEQ	top		; Null line
	LDA	#LET		; Assume LET
	BSR	execute		; Process LET
	BRA	top		; And continue
;
; Execute a BASIC command
;
execute:ANDA	#$7F		; Strip high bit
	CMPA	#TO		; In range
	LBHS	synerr		; Error
	TFR	A,B		; B = value
	CLR	file		; Reset to console
	CLR	file+1		; Reset to console
	LBSR	switch		; Perform switch
	FDB	synerr,_LET,_EXIT,_LIST,_NEW,_RUN,_CLEAR
	FDB	_GOSUB,_GOTO,_RETURN,_PRINT,_FOR
	FDB	_NEXT,_IF,_LIF,_REM,_STOP,_END,_INPUT
	FDB	_DIM,_ORDER,_READ,_DATA,_POKE
	FDB	_SAVE,_LOAD,_OPEN,_CLOSE
_EXIT	CLRA			; Zero return code
	FCB	$3F,0		; And exit
; Clear program
clrpgm:	TST	mode		; Running?
	BEQ	clrall		; No - clear all
	LDX	pgm_start	; Get program start
	BEQ	clrpg2		; No program
clrpg1	LBSR	free		; Release it
	LDX	2,X		; Get next
	BNE	clrpg1		; Release all
	STX	pgm_start	; Zero pointer
clrpg2:	RTS
clrall:	LDX	#RAM		; Point to buffer
clra1	CLR	,X+		; Zero one byte
	CMPX	#?heap		; At heap?
	BLS	clra1		; Zero it all
	RTS
; Process load/save filename
lsname:	LBSR	evalchr		; Get string
	LDY	#sa1		; Point to it
	BSR	ucsa1		; Convert to upper case
lsn1	FCB	$3F,11		; Accept filename
	LBNE	top		; Error
	LDD	#'BA'		; Get .BA
	STD	,X		; Set extension
	LDA	#'S'		; Get 'S'
	STA	2,X		; Set extension
	PULS	X		; X = return address
	LEAS	-522,S		; Allocate buffer
	TFR	S,U		; U = buffer
	JMP	,X
;
; Load program
;
xload	BSR	lsn1		; Get name
	BRA	load0
_LOAD	BSR	lsname		; Get name
load0:	FCB	$3F,55		; Open for read
	BNE	load3		; Failed
	BSR	clrpgm		; Zero
	STU	file		; Save file
load1:	LDY	#buffer		; Point to buffer
	LBSR	gets		; Get line
	TSTB			; End of file
	BEQ	load2		; Exit
	LBSR	edit		; Edit line
	BRA	load1		; Do them all
load2:	LDU	file		; Get FCB
	FCB	$3F,57		; Closeit
load3:	TST	mode		; Running?
;	LBEQ	top		; No, stop
	BEQ	load4
	LDX	pgm_start	; Get start
	LDS	#STACK		; Reset stack
	LBSR	_run2		; And proceed
	LBRA	top		; And proceed
load4:	LEAS	522,S		; Clean stack
	RTS
;
; Save program
;
_SAVE	BSR	lsname		; Get name
	FCB	$3F,56		; Open for write
	BNE	save1		; Error - exit
	STU	file		; File pointer
	LDX	#0		; Lowest line
	LDU	#65535		; Highest line
	LBSR	_list1		; Write the file
	LDU	file		; Get FCB
	FCB	$3F,57		; Close
save1	LEAS	522,S		; Clean stack
	RTS
; Translate SA1 to upper case for Cubix filenames
ucsa1	PSHS	Y		; Save pointer
ucsa2	LBSR	getuc		; Get char
	BEQ	ucsa3		; End
	STA	-1,Y		; Set to upper
	BRA	ucsa2		; Continue
ucsa3	PULS	Y,PC		; Restore & return
;
; Get file specification
;
getfil:	LDA	#'#'		; Indiciator
	LBSR	expect		; Expect it
getf1:	LBSR	evalnum		; Get number
	CMPD	#9		; Are we over
	LBHI	synerr		; Report error
	LSLB			; x2
	LDX	#files		; Get file
	ABX			; X = handle address
	ABX			; x2
	LDU	,X		; Get handle
	RTS
;
; Open a file for read/write
;
_OPEN	BSR	getfil		; Get file number
	BNE	fooerr		; Already open
	STX	temp1		; Save handle pointer
	LBSR	expectc		; ',' required
	LBSR	evalchr		; Get filename
	LDD	sa1		; Get name
	SUBA	#'*'		; Device name?
	BEQ	opend		; Open device
	LDD	#522		; File control block
	LBSR	malloc		; Get memory
	TFR	D,U		; U = handle
	LBSR	expectc		; ',' required
	LBSR	get_next	; Get next data
	PSHS	A,Y		; Save Y
	LDY	#sa1		; Point to filename
	BSR	ucsa1		; Convert to upper
	FCB	$3F,10		; Get DOS filename
	BNE	openf		; Open failed
	PULS	A,Y		; Restore
	CMPA	#'W'		; Open for write
	BEQ	openw		; Open for write
	CMPA	#'R'		; Open for read
	BNE	openf		; Report error
	FCB	$3F,55		; Open for read
	BEQ	openok		; Opened OK
openf:	TFR	U,X		; X = buffer address
	LBSR	free		; Release it
fnoerr:	LDA	#ERRfno		; File not open
	LBRA	error		; Report error
openw	FCB	$3F,56		; Open for write
	BNE	openf		; Failed
openok:	LDX	temp1		; Get handle address
	STU	,X		; Write it
	RTS
opend:	SUBB	#'0'		; Convert to binary
	CMPB	#7		; In range?
	BHI	fnoerr		; Fail
	INCB			; +1
	TFR	D,U		; U = value
	BRA	openok		; Save new pointer
;
fooerr:	LDA	#ERRfoo		; File already open
	LBRA	error		; Report error
;
; Close an open file
;
_CLOSE	BSR	getfil		; Get filename
	BEQ	fnoerr		; Get name
	CMPU	#8		; 1-8 = Device
	BLS	close1		; Device - no need to clear
	FCB	$3F,57		; Close file
	EXG	X,U		; X = pointer
	LBSR	free		; Release buffer
	EXG	X,U		; X = handle address
close1:	CLR	,X		; Zero handle
	CLR	1,X		; Zero handle
	RTS
;
; POKE command
;
_POKE	LBSR	getnum		; Get value
	TFR	D,U		; U = value
	LBSR	expectc		; Expect it
	LBSR	getnum		; Get next value
	STB	,U		; Write it
	RTS
;
; IF statements
;
_IF:	LBSR	pgm		; Program only
	LBSR	evalnum		; Get expression
	TFR	D,X		; X = result
	LDA	#THEN|128	; 'THEN'
	LBSR	expect		; Expect it
	CMPX	#0		; Execute
	LBEQ	skpstmt		; No
_if1:	LBSR	skip		; Skip to next
	LBSR	isdigit		; Is it a number?
	LBEQ	_goto1		; Yes, handle it
	LEAS	2,S		; Clean stack
	LBRA	_run4
_LIF:	LBSR	pgm		; Program only
	LBSR	evalnum		; Get expression
	TFR	D,X		; X = resuly
	LDA	#THEN|128	; 'THEN'
	LBSR	expect		; Expect it
	CMPX	#0		; Execute
	BNE	_if1		; Yes
	LBRA	_rem1		; No
;
; Input request
;
_INPUT:	LDA	#'#'		; File spec?
	LBSR	test_next	; Is there one?
	BNE	inp1		; No, handle normally
	LBSR	getf1		; Get the handle
	LBEQ	fnoerr		; Not open
	STU	file		; Set input file
	BRA	inp2		; And continue
inp1:	LDD	#'? '		; Default prompt
	STD	sa1		; Save
	CLR	sa1+2		; Zero terminate
	LBSR	skip		; Advance
	CMPA	#'"'		; Character?
	BNE	_input1		; No prompt
	LBSR	eval		; Get prompt
inp2:	LBSR	expectc		; Expect it
_input1	LBSR	getvar		; Get input variable
	CLRA			; Zero flag
	PSHS	A,X,Y		; Save address & cmdptr
_input0	LDD	file		; File output
	BNE	inp3		; Don't prompt
	LDX	#sa1
	LBSR	puts		; Display it
inp3:	LDY	#sa2		; Point to accumulator2
	LBSR	gets		; Get input
	TST	expr_type	; Get expression type
	BEQ	_input4		; Not character
; Character input
	LDX	1,S		; Get address
	LDX	char_vars,X	; Get pointer
	BEQ	_input2		; Not already defined
	LBSR	free		; Release it
_input2	LDX	#sa2		; Point to buffer
	LBSR	strlen		; Get length
	LBSR	malloc		; Allocate memory
	LDU	1,S		; Get address
	STD	char_vars,U	; Save new address
	LDU	#sa2		; Point to buffer
_input3	LDA	,U+		; Get from source
	STA	,X+		; Save in dest
	BNE	_input3		; Do them all
	PULS	A,X,Y,PC	; Restore * return
; Numeric input
_input4	LDA	#'-'		; Negative?
	LBSR	test_next	; Is this it?
	BNE	_input5		; Not negative
	DEC	,S		; Set flag
_input5	PSHS	Y		; Save pointer
	LBSR	getnum		; Get number
	CMPY	,S++		; Did it move?
	BNE	_input6		; Accepted
	LBSR	putm		; Output message
	FCCZ	'Input error'
	LDD	file		; From file
	LBNE	err3		; Abort
	LBSR	lfcr		; New line
	BRA	_input0		; Reprompt
_input6	TST	,S+		; Negate?
	BEQ	_input7		; It's OK
	COMA
	COMB
	ADDD	#1
_input7	PULS	X,Y		; Restore X & Y
	PSHS	A,B		; Save D
	LBSR	addr1		; Compute address
	PULS	A,B
	STD	,X		; Save
	RTS
;
; ORDER statement
;
_ORDER:	LBSR	evalnum		; Get value
	LBSR	findl		; Locate line
	STX	readptr		; Save read pointer
	PSHS	Y		; Save Y
	LEAY	4,X		; Y = text portion
	LBSR	get_next	; Get token
	CMPA	#DATA|128	; Is it a DATA statement?
	BNE	daterr		; No, report error
	STY	dataptr		; Save data pointer
	PULS	Y,PC		; Restore and return
daterr:	LDA	#ERRdat		; 'Data'
	LBRA	error		; Report error
;
; READ statement
;
_READ:	LBSR	address		; Get variable address
	LDA	expr_type	; Get expression type
	LDU	line		; Get line number
	PSHS	A,X,Y		; Save type, address, cmdptr, line
	LDY	dataptr		; Get data pointer
	LDX	readptr		; Get read pointer
	BEQ	daterr		; No data
	LBSR	skip		; Advance
	BNE	_read1		; Not end of line
	LDX	2,X		; Get new read pointer
	BEQ	daterr		; No data
	STX	readptr		; Save new read pointer
	LEAY	4,X		; New cmdptr
	LBSR	get_next	; Get token
	CMPA	#DATA|128	; 'DATA'?
	BNE	daterr		; Report error
_read1	LDD	,X		; Get line number
	STD	line		; Set new line number
	LBSR	eval		; Evaluate
	TFR	D,U		; U = result
	LBSR	tnc		; Remove ','
	STY	dataptr		; Save new data pointer
	PULS	A,X,Y		; Restore
	CMPA	expr_type	; Does it match?
	TSTA			; Character?
	BNE	_read2		; Yes, handle it
	STU	,X		; Save new value
	BRA	_read5		; And try for next
_read2	TFR	X,U		; U = variable address
	LDX	,U		; Get address
	BNE	_read3		; Not existing
	LBSR	free		; Release memory
	CLR	,U		; Zero it
	CLR	1,U		; Zero it
_read3	LDX	#sa1		; Point to sa
	TST	,S		; Value present?
	BEQ	_read5		; No, leave it
	LBSR	strlen		; Get length
	LBSR	malloc		; Allocate memory
	STD	,U		; Set new addresss
	LDU	#sa1		; Point to acc
_read4	LDA	,U+		; Get from source
	STA	,X+		; Write to dest
	BNE	_read4		; Do them all
_read5	LBSR	tnc		; More
	BEQ	_READ		; Keep going
	RTS
;
; Stop execution
;
_STOP:	LBSR	pgm		; Program only
	LBSR	putm		; Output message
	FCCZ	'STOP'
	LBRA	err3		; And exit
_END:	LBSR	pgm		; Program only
	LBRA	top		; Exit
BREAK:	LBSR	putm		; Output message
	FCCZ	'^C'
	LBRA	err3		; And proceed
;
; Execute program
;
_RUN	LBSR	direct		; Direct only
	LBSR	_CLEAR		; Clear variables
	LDX	pgm_start	; Assume start of program
	LBSR	skip		; Advance
	LBSR	is_e_end	; End of expression?
	BEQ	_run1		; Yes
	LBSR	evalnum		; Get number
	LBSR	findl		; Locate number
_run1	DEC	mode		; Indicate running
_run2	STX	runptr		; Set run line
	LDX	runptr		; Get run pointer
	BEQ	_run7		; Program has ended
	LBSR	testc		; Test for character
	BEQ	_run3		; No data
	CMPA	#'C'-$40	; Control-C
	BEQ	BREAK		; Terminate
	STA	keypress	; Save for later
_run3	LDD	,X		; Get line number
	STD	line		; Save new line number
	LEAY	4,X		; Y = line text
_run4	LBSR	skip		; Advance
	TSTA			; Special case?
	BMI	_run5		; Yes, assume LET
	LDA	#LET		; Assume LET
	BRA	_run6		; And proceed
_run5	LEAY	1,Y		; Skip command
_run6	LBSR	execute		; Execute command
	LBSR	get_next	; Get next char
	CMPA	#':'		; Another statement
	BEQ	_run4		; Do it
	TSTA			; End of line
	LBNE	synerr		; Report error
	LDX	runptr		; Get line pointer
	LDX	2,X		; Get link
	BNE	_run2		; And proceed
_run7	CLR	mode
_run8	RTS
;
; Remark
:
_DATA:	LBSR	pgm		; Program only
_REM:	TST	mode		; Running?
	BEQ	_run8		; No action
_rem1:	LDX	runptr		; Get run pointer
	LDX	2,X		; Get link
	LEAS	2,S		; Clean stack
	BRA	_run2		; And continue
;
; For statement
;
_FOR:	LBSR	pgm		; Program only
	LBSR	address		; Get variable address
	LBSR	chknum		; Insure numeric
	LDB	ctl_ptr		; Get control pointer
	LDU	#ctl_stk	; Point at stack
	LEAU	B,U		; U = ctrl-stack
	LEAU	B,U		; x2
	ADDB	#6		; ++6
	STB	ctl_ptr		; Resave pointer
	STX	8,U		; Save variable address
	LDA	#EQ|128		; '='
	LBSR	expect		; Expect it
	LBSR	evalnum		; Evaluate expression
	STD	[8,U]		; Set variable
	LDA	#TO|128		; 'TO'
	LBSR	expect		; Expect it
	LBSR	evalnum		; Get final
	STD	6,U		; Set limit
	LDD	#1		; Assume step=1
	STD	4,U		; Set step
	LDA	#STEP|128	; 'STEP'
	LBSR	test_next	; Does it occur?
	BNE	_for1		; No
	LBSR	evalnum		; Get number
	STD	4,U		; Set new step value
_for1	LDD	runptr		; Get run pointer
	STD	,U		; Save runptr
	STY	2,U		; save cmdptr
	LDD	#__FOR		; FOR indicator
	STD	10,U		; Save
	RTS
;
; NEXT statement
;
_NEXT:	LBSR	pgm		; Program only
	LDB	ctl_ptr		; Get control pointer
	SUBB	#6		; Backup
	LSLB			; x2
	LDU	#ctl_stk	; Point to stack
	LEAU	B,U		; Offset to entry
	LDD	10,U		; Get indicator
	CMPD	#__FOR		; FOR loop?
	LBNE	nsterr		; Report error
	LBSR	skip		; Advance
	LBSR	is_l_end	; End of statement
	BEQ	_next1		; No variable specified
	LBSR	address		; Get variable address
	CMPX	8,U		; Does it match?
	LBNE	nsterr		; No - error
_next1	LDX	8,U		; Get address
	LDD	,X		; Get variable
	ADDD	4,U		; Advance by step
	STD	,X		; Resave
	TST	4,U		; Negative step?
	BMI	_next3		; Yes, handle it
	CMPD	6,U		; Are we over limit
	BGT	_next4		; Yes, stop
_next2	LDX	,U		; Get run ptr
	STX	runptr		; Set new run pointer
	LDD	,X		; Get line number
	STD	Line		; Set new line number	
	LDY	2,U		; Get cmdptr
	RTS
_next3	CMPD	6,U		; Are we under limit
	BGE	_next2		; No, keep going
_next4	LDB	ctl_ptr		; Get pointer
	SUBB	#6		; Backup
	STB	ctl_ptr		; Resave
	RTS
;
; Dimension a variable
;
_DIM	LBSR	getvar		; Get variable
	TFR	X,U		; U = address
	LDX	dim_vars,U	; Get existing
	BEQ	_dim1		; Not existing
	LBSR	free		; Release it
_dim1	LBSR	evalnum		; Get number
	ADDD	#1		; Adjust
	STD	dim_check,U	; Save size
	LSLB			; x2
	ROLA			; x2
	LBSR	malloc		; Allocate the memory
	STD	dim_vars,U	; Save address
	LBSR	tnc		; More?
	BEQ	_dim		; Yes, process
	RTS
;
; Assign value to variable
;
_LET	LBSR	address		; Get variable address
	LDA	expr_type	; Get expression type
	PSHS	A		; Save for later
	LDA	#EQ|128		; Assignment
	LBSR	expect		; Expect it
	LBSR	eval		; Evaluate
	TST	expr_type	; Numeric?
	BNE	_let1		; No, do char
	TST	,S+		; Num var?
	LBNE	synerr		; No, error
	STD	,X		; Write value
	RTS
_let1	TST	,S+		; Char var?
	LBEQ	synerr		; No, error
	TFR	X,U		; U = pointer
	LDX	,X		; Assigned
	BNE	_let2		; No
	LBSR	free		; Release the memory
_let2:	LDX	#sa1		; Point to SA1
	TST	,X		; Non-0?
	BNE	_let3		; Yes, handle it
	CLRA			; Zero high
	CLRB			; Zero low
	STD	,U		; Clear pointer
	RTS
_let3:	BSR	strlen		; Get length of string
	LBSR	malloc		; Allocate storage
	STD	,U		; U = variable pointer
	LDU	#sa1		; Point to string acc
_let4:	LDA	,U+		; Get from source
	STA	,X+		; Save in dest
	BNE	_let4		; Do them all
	RTS
; Get length of string(X)
strlen	PSHS	X		; Save start address
strl1	LDA	,X+		; Get char
	BNE	strl1		; Find end
	TFR	X,D		; D = end
	LDX	,S		; Restore X
	SUBD	,S++		; Compute length
	RTS
;
; Print data
;
_PRINT	CLR	,-S		; Zero flag
	BSR	chkfil		; Check for file output
_pri1:	LBSR	skip		; Next char
	LBSR	is_l_end	; End of statement
	BNE	_pri2		; No
	DEC	,S		; Set flag
	BRA	_pri4		; And continue
_pri2	LBSR	eval		; Evaluate expression
	TST	expr_type	; Numeric?
	BNE	_pri3		; No, character
	LDU	#sa1		; Accumulator1
	LBSR	num2str		; Convert to string
	LBSR	space		; Output space
_pri3	LDX	#sa1		; Point to sa1
	LBSR	puts		; Output
_pri4	LBSR	tnc		; More?
	BEQ	_pri1		; Yes, do another
	LDA	,S+		; Get marker
	LBEQ	lfcr		; New line
	RTS
;
; Check for file output
;
chkfil	LDA	#'#'		; Device id
	LBSR	test_next	; Device ID?
	BNE	chkfi1		; No, nothing special
	LBSR	getf1		; Get filename
	LBEQ	fnoerr		; Not open
	LDA	#','		; Comma
	LBSR	expect		; Expect it
	STU	file		; Set output handle
chkfi1:	RTS
;
; List program
;
_LIST	BSR	chkfil		; Check for file
	LBSR	skip		; Get next
	LDX	#0		; Low = 0
	LDU	#$FFFF		; High = top
	LBSR	isdigit		; Line number?
	BNE	_list1		; No, assume these
	LBSR	getnum		; Get number
	TFR	D,X		; Low = line
	LBSR	get_next	; Get next char
	TFR	D,U		; U = same line
	CMPA	#','		; Separator?
	BNE	_list1		; No, just this line
	LBSR	skip		; Advance
	LDU	#$FFFF		; Assume top again
	LBSR	isdigit		; Ending line?
	BNE	_list1		; No, do it
	LBSR	getnum		; Get ending line
	TFR	D,U		; U = ending line
; Display program from X to U
_list1	PSHS	X,Y,U		; Save values
	LDY	pgm_start	; Get address
	BEQ	_list10		; No program
_list2	LDD	,Y		; Get line number
	CMPD	,S		; < lowest
	BLO	_list9		; Don't display
	CMPD	4,S		; > Highest
	BHI	_list9		; Don't display
	LBSR	putn		; Display number
	LBSR	space		; Display
	LEAU	4,Y		; Skip to text
_list3	LDA	,U+		; Get next char
	BPL	_list7		; Not special
	ANDA	#$7F		; Get name
	TFR	A,B		; Copy
	LDX	#rwordz		; Point to reserved words
_list4	TST	,X+		; Get next
	BNE	_list4		; Find end
	DECA			; Reduce
	BNE	_list4		; Till we have it
_list5:	LDA	,X+		; Get char
	BEQ	_list6		; End
	LBSR	putc		; output
	BRA	_list5		; Do them all
_list6:	CMPB	#ADD		; Special case
	BHS	_list3		; No
	LBSR	space		; Extra output
	CMPB	#REM		; Remark
	BNE	_list3		; No, continue
_list6b	LDA	,U+		; Get char
	BEQ	_list8		; End of line
	LBSR	putc		; Display
	BRA	_list6b		; Continue
_list7	BEQ	_list8		; End of line
	LBSR	putc		; Output
	BRA	_list3		; And continue
_list8	LBSR	lfcr		; New line
_list9	LDY	2,Y		; Point to next
	BNE	_list2		; And proceed
_list10	PULS	X,Y,U,PC	; Restore and return
;
; GOSUB
;
_GOSUB	LDB	ctl_ptr		; Get stack pointer
	LDX	#ctl_stk	; Point to control stack
	ABX			; Adjust
	ABX			; x2
	LDU	runptr		; Get run pointer
	STU	,X		; ctl_stk[ctl_ptr++] = runptr
	STY	2,X		; ctl_stk[ctl_ptr++] = cmdptr
	LDU	#__GOSUB	; Indicate GOSUB
	STU	4,X		; ctl_stk[ctl_ptr++] = _GOSUB
	ADDB	#3		; ++ ++ ++
	STB	ctl_ptr		; Resave pointer
_GOTO	LBSR	pgm		; Insure in program
_goto1	LBSR	evalnum		; Get number
	LBSR	findl		; Locate line
	LEAS	2,S		; Clean stack
	LBRA	_run2		; And proceed
;
; Return from subroutine
;
_RETURN	LBSR	pgm		; Program only
	LDB	ctl_ptr		; Get control stack pointer
	SUBB	#3		; Backup
	STB	ctl_ptr		; Resave
	LDX	#ctl_stk	; Point to stack
	ABX			; Offset
	ABX			; Offset
	LDD	4,X		; Get flag
	CMPD	#__GOSUB	; Is it GOSUB
	BNE	nsterr		; No - error
	LDU	,X		; Get new runptr
	STU	runptr		; Set runptr
	LDY	2,X		; Set new cmdptr
	LDD	,U		; Get line number
	STD	line		; Set current line
;
; Skip rest of statement
;
skpstmt:LDA	,Y		; Get data
	BEQ	isle1		; End of line
	CMPA	#':'		; New statement?
	BEQ	isle1		; End of statement
	LEAY	1,Y		; Next
	CMPA	#'"'		; Quote?
	BNE	skpstmt		; No special action
skps1:	LDA	,Y		; Get next
	BEQ	isle1		; End of statement
	LEAY	1,Y		; Skip character
	CMPA	#'"'		; End of quote?
	BNE	skps1		; continue quote
	BRA	skpstmt		; continue skip
; Incorrect ctl_stk usage
nsterr:	LDA	#ERRnst		; 'Nesting'
;
; Report an error
;
error	LDX	#emsg		; Point to error messages
	CLR	file		; Reset to console
	CLR	file+1		; Reset to console
	TSTA			; At message?
	BEQ	err2		; We have it
err1	TST	,X+		; Get next
	BNE	err1		; Find end
	DECA			; Reduce count
	BNE	err1		; Find it
err2	LBSR	puts		; Display message
	LBSR	putm		; Output message
	FCCZ	' error'	; Text
err3	TST	mode		; Running?
	BEQ	err4		; No, do nothing
	LBSR	putm		; Display message
	FCCZ	' in line '	; Text
	LDD	line		; Get current line
	LBSR	putn		; Display
err4	LBSR	lfcr		; New line
	LBRA	top		; And restart
;
; Test for end of expression
;
is_e_end: CMPA	#TO+128
	BLO	isee1
	CMPA	#ADD+128
	BLO	tsne1
isee1:	CMPA	#')'
	BEQ	isle1
	CMPA	#','
	BEQ	isle1
;
; Test for end of statement
;
is_l_end: TSTA
	BEQ	isle1
	CMPA	#':'
isle1:	RTS
;
; Test for terminator character
;
isterm	CMPA	#' '
	BEQ	isle1
	CMPA	#$09
	RTS
;
; Advance to next non-blank & retrieve data
;
skip:	LDA	,Y		; Get data
	BEQ	skipx		; End of data
	CMPA	#' '		; Space?
	BNE	skipx		; End of data
	LEAY	1,Y		; Advance
	BRA	skip		; And proced
;
; Advance to, retrieve and skip next non-blank
;
get_next: LDA	,Y		; Get data
	BEQ	skipx		; Zero - backup
	LEAY	1,Y		; Advance
	CMPA	#' '		; Space
	BEQ	get_next	; Keep looking
skipx	RTS
;
; Test for specific character occuring next and remove if found
;
tnc:	LDA	#','		; Test for comma
test_next: PSHS	A		; Save character
	BSR	skip		; Get next char
	CMPA	,S+		; Does it match?
	BNE	isle1		; No
	LEAY	1,Y		; Advance
tsne1:	ORCC	#4		; Set Z
	RTS
;
; Expect a specific token
;
expectb	LDA	#'('		; Opening bracket
	BRA	expect
expectc	LDA	#','		; Comma
expect:	PSHS	A		; Save character
	BSR	get_next	; Get next character
	CMPA	,S+		; Does it match?
	BEQ	isle1		; Yes
synerr:	CLRA			; Error 0 - SYNTAX
	LBRA	error		; Report error
;
; Test for alphabetic or numeric
;
isalnum:BSR	isalpha		; Test for alpha
	BEQ	isle1		; Yes
;
; Test for digit
;
isdigit: CMPA	#'0'
	BLO	isle1
	CMPA	#'9'
	BLS	tsne1
	RTS
;
; Test for ALPHA
;
isalpha:CMPA	#'A'
	BLO	isle1
	CMPA	#'Z'
	BLS	tsne1
	RTS
;
; Get character from command & convert to upper case
;
getuc:	LDA	,Y		; Get character
	BEQ	getuc2		; End - stop
	CMPA	#'a'		; Lower?
	BLO	getuc1		; No change
	CMPA	#'z'		; Lower?
	BHI	getuc1		; No change
	ANDA	#$DF		; Convert to upper
getuc1	LEAY	1,Y		; Next
getuc2:	RTS
;
; Loopup word(Y) in reserved word list
;
lookup	PSHS	A,X,U		; Save
	LDU	#rwords		; Point to table
	CLRB			; Zero counter
	TFR	Y,X		; Save backup
look1	LDA	,U		; End of list?
	BEQ	look3		; We found it
	LBSR	getuc		; Get character from input
	CMPA	,U+		; Does it match?
	BEQ	look1		; Keep looking
	INCB			; Next
look2	LDA	,U+		; Next word?
	BNE	look2		; Find it
	TFR	X,Y		; Restore pointer
	LDA	,U		; Are we at end?
	BNE	look1		; No, keep looking
	CLRB			; Zero result
	PULS	A,X,U,PC	; And return
look3	LDA	-1,U		; Get last character
	BSR	isalnum		; alphanumeric?
	BNE	look5		; It's OK
	LDA	,Y		; Get next from source
	BSR	isalnum		; Alphanumeric?
	BEQ	look2		; Yes, keep looking
look5	LBSR	skip		; Advance to next
	INCB			; Adjust
	PULS	A,X,U,PC	; Restore & return
;
; Get a number from 'Y', return in D
;
getnum	PSHS	A,B,X		; Save registers
	LDB	#10		; Assume BASE-10
	LDA	,Y		; Get next
	CMPA	#'$'		; Hex indicator
	BNE	getn0		; No
	LEAY	1,Y		; Skip indicator
	LDB	#16		; Switch to base-16
getn0	CLRA			; Zero high
	TFR	D,X		; X = base
	CLRB			; Zero low
getn1	STD	,S		; Save
	LBSR	getuc		; Get char
	BEQ	getn4		; End of line
	TFR	A,B		; Into B
	SUBB	#'0'		; 0-9
	CMPB	#10		; In range?
	BLO	getn2		; It's OK
	SUBB	#7		; A-F
	CMPB	#10		; <A
	BLO	getn3		; Exit
	CMPB	#15		; >F
	BHI	getn3		; Exit
getn2	CLRA			; Zero high
	PSHS	X		; Save base
	CMPD	,S++		; Are we over?
	BHS	getn3		; Yes, exit
	STD	temp		; And save
	LDD	,S		; Get value
	BSR	xMUL		; D = D * 10
	ADDD	temp		; Add in new
	BRA	getn1		; And continue
getn3	LEAY	-1,Y		; Backup
getn4	PULS	A,B,X,PC	; Restore and return
;
; Performs 16 bit multiplication (D=X*D)
;
xMUL	PSHS	A,B,X		Save parameters
	LDA	1,S
	LDB	3,S
	MUL
	PSHS	A,B
	LDA	2,S
	LDB	5,S
	MUL
	ADDB	,S
	STB	,S
	LDA	3,S
	LDB	4,S
	MUL
	ADDB	,S
	STB	,S
	PULS	A,B		Get result
	LEAS	4,S		Clean stack
	RTS
;
; Performs 16 bit division. (X=X/D, D=Remainder)
;
xDIV	PSHS	A,B,X
	CLRA
	CLRB
	CMPD	,S
	BEQ	diverr
	LDX	#17
div1	ANDCC	#$FE
div2	ROL	3,S
	ROL	2,S
	LEAX	-1,X
	BEQ	div3
	ROLB
	ROLA
	CMPD	,S
	BLO	div1
	SUBD	,S
	ORCC	#1
	BRA	div2
div3	LEAS	2,S
	PULS	X,PC
diverr	LDA	#ERRdiv		; 'Divide by zero'
	LBRA	error		; Report error
;
; Insert line(D) in program
;
insert:	PSHS	A,B,X,Y,U	; Save 
	LDB	#4		; line#,link
ins1	INCB			; Advance
	LDA	,Y+		; Get next
	BNE	ins1		; Count them all
	BSR	malloc		; Allocate
	TFR	D,U		; U = address
	LDD	,S		; Get line#
	STD	,U		; Set line#
	LEAX	4,U		; Point to text
	LDY	4,S		; Get cmd pointer
ins2	LDA	,Y+		; Get from source
	STA	,X+		; Save in dest
	BNE	ins2		; Copy entire line
	LDD	,S		; Get line number
	LDX	pgm_start	; Get start address
	BEQ	ins3		; No program - allocate here
	CMPD	,X		; Are we lower?
	BHS	ins4		; No - keep looking
ins3	STX	2,U		; Set link
	STU	pgm_start	; Set new start
	PULS	A,B,X,Y,U,PC	; And return
ins4	TFR	X,Y		; Y = old
	LDX	2,X		; X = new
	BEQ	ins5		; Insert here
	CMPD	,X		; Are we lower?
	BHI	ins4		; No, keep looking
ins5	LDD	2,Y		; Get old link
	STD	2,U		; Set new link
	STU	2,Y		; Link us to old
	PULS	A,B,X,Y,U,PC	; And proceed
;
; Allocate a block of memory: char *malloc(d)
;
malloc	PSHS	A,B,Y,U		; Save registers
	LDU	#?heap		; Point to beginning of heap
; Search for free block of memory
ma?1	LDA	,U		; Get flag
	BEQ	ma?4		; End of list, allocate here
	LDX	1,U		; Get size
	DECA			; Un-allocated?
	BNE	ma?2		; No, try next
; Found free block, see if its large enough
	CMPX	,S		; Large enough?
	BHS	ma?3		; Yes, its ok
; This block not suitable, advance to next
ma?2	LEAX	3,X		; Include overhead
	TFR	X,D		; Get into acc
	LEAU	D,U		; Advance to next
	BRA	ma?1		; And try again
; This block is OK to re-allocate
ma?3	TFR	X,D		; Get into ACC
	SUBD	,S		; Calculate remaining
	SUBD	#3		; Convert for overhead
	BLS	ma?6		; Leaved it alone
	TFR	D,Y		; Save for later
; Split this block into two blocks
	LDD	,S		; Get size of block
	LEAX	D,U		; Offset to next
	CLR	3,X		; Set it free
	INC	3,X		; Indicate de-allocated
	STY	4,X		; Save size of block
	BRA	ma?5		; And proceed
; Allocate on end of memory
ma?4	TFR	S,D		; Get stack pointer
	SUBD	,S		; Adjust for buffer size
	SUBD	#1000		; Adjust for margin
	PSHS	U		; Save pointer
	CMPD	,S++		; Test it
	BLS	ma?9		; No, fail
; Ok to proceed, allocate memory
	LDD	,S		; Get size
	LEAX	D,U		; Offset to new area
	CLR	3,X		; Indicate end of list
ma?5	STD	1,U		; Save block size
ma?6	LDB	#2		; Get 'Allocated' flag
	STB	,U		; Set it
	LEAU	3,U		; U points to area
	TFR	U,X		; X points to area
	LDY	,S		; Get size
	BEQ	ma?8		; Zero length
ma?7	CLR	,U+		; Zero one byte
	LEAY	-1,Y		; Reduce count
	BNE	ma?7		; Do them all
ma?8	STX	,S		; Save
	PULS	A,B,Y,U,PC	; Restore & return
ma?9	LDA	#ERRmem		; "Out of memory"
	LBRA	error		; Report error
	
;
; Release a block of memory: free(x)
;
free	LEAX	-3,X		; Backup to "real" beginning
	PSHS	A,B,X,Y,U	; Save for compare
; Search the allocation list for this block
	LDU	#?heap		; Point to beginning of heap
fr?10	LDA	,U		; Get address
	BEQ	fr?12		; End of list
	CMPU	2,S		; Is this it?
	BEQ	fr?11		; Yes, handle it
	LDD	1,U		; Get size
	LEAU	D,U		; Advance for size
	LEAU	3,U		; Include overhead
	BRA	fr?10		; And keep looking
; Mark this block as un-allocated
fr?11	LDA	#1		; Get 'deallocated' flag
	STA	,U		; Set block
; Garbage collection, scan allocation list and join any
; contiguous de-allocated blocks into single areas.
; Also, truncate list at last allocated block.
fr?12	LDU	#?heap		; Point to beginning of heap
fr?20	LDA	,U		; Get allocation flag
	BEQ	fr?25		; End, quit
	LDX	1,U		; Get size of block
	DECA			; Test for de-allocated
	BNE	fr?23		; No, its not
; This block is free, check following blocks
fr?21	TFR	X,D		; 'D' = offset
	LEAY	D,U		; 'Y' = next block
	LDA	3,Y		; Get next flag
	BEQ	fr?24		; End of list, its ok
	DECA			; Test for allocated?
	BNE	fr?22		; Yes, stop looking
; Next block is also free
	LDD	4,Y		; Get size of next block
	LEAX	D,X		; Add in size of next block
	LEAX	3,X		; Inlude overhead
	BRA	fr?21		; And keep looking
; Resave this block size
fr?22	STX	1,U		; Save new block size
; Advance to next block in list
fr?23	TFR	X,D		; Get length
	LEAU	D,U		; Offset to next
	LEAU	3,U		; Include overhead
	BRA	fr?20		; And keep looking
; Mark this block as end of list
fr?24	CLR	,U		; Indicate end of list
fr?25	PULS	A,B,X,Y,U	; Restore & return
	LEAX	3,X		; Skip ahead
	RTS
;
; Delete line (D) from program
;	unsigned lnumber
;	struct	*link
;	char	text[]
;
delete:	LDX	pgm_start	; Get program start address
	BEQ	del4		; No program
del1	CMPD	,X		; Does it match?
	BNE	del3		; No, try next
	LDD	2,X		; Get link
	CMPX	pgm_start	; First_line?
	BNE	del2		; No, release it
	STD	pgm_start	; Set new start address
	BRA	free		; Release this memory
del2	STD	2,U		; Set last link
	BRA	free		; Release this memory
del3	TFR	X,U		; Save pointer to last
	LDX	2,X		; Get link
	BNE	del1		; And proceed
del4	RTS
;
; Tokenize input line and add/replace source if required
;
edit:	LDY	#buffer		; Point to buffer
	TFR	Y,U		; Secondary pointer
edit1	TST	,Y		; Get data
	BEQ	edit4		; End of data
	LBSR	lookup		; Is it a reserved word
	BEQ	edit2		; No, nothing special
	ORB	#%10000000	; Convert to token value
	STB	,U+		; Save in output
	CMPB	#REM+128	; Remark?
	BNE	edit1		; And continue
edit1a	LDA	,Y+		; Get char
	BEQ	edit4		; End of line
	STA	,U+		; Save
	BRA	edit1a		; Do them all
edit2	LDA	,Y+		; Get character
	CMPA	#'a'		; Lower?
	BLO	edit2a		; No
	CMPA	#'z'		; Lower?
	BHI	edit2a		; No
	ANDA	#$DF		; Convert to upper
edit2a	STA	,U+		; Write to source
	CMPA	#'"'		; Quoted string?
	BNE	edit1		; No - next token
edit3	LDA	,Y+		; Get next char
	BEQ	edit4		; End - exit
	STA	,U+		; Write to buffer
	CMPA	#'"'		; End of string?
	BNE	edit3		; No, keep copying
	BRA	edit1		; Next token
edit4	CLR	,U		; Zero terminate
	LDY	#buffer		; Back to beginning
	LBSR	skip		; First non-blank
	LBSR	isdigit		; Is it a number?
	BNE	edit5		; No, do nothing
	LBSR	getnum		; Get number
	PSHS	A,B		; Save
	LBSR	delete		; Delete existing line
	LBSR	skip		; More data
	TSTA			; End of line
	PULS	A,B		; Restore
	BEQ	edit5		; No
	LBSR	insert		; Insert the line
	CLRA			; Indicate we edited
edit5	RTS
;
; Locate given line in source
;
findl:	LDX	pgm_start	; Get program start
	BEQ	findl2		; Not found
findl1	CMPD	,X		; Does this one match?
	BEQ	edit5		; Yes
	LDX	2,X		; Get next one
	BNE	findl1		; And keep looking
findl2	LDA	#ERRlin		; 'Line number'
	LBRA	error		; Report error
;
; Get variable index (into X)
;
getvar:	LBSR	get_next	; Get next 
	LBSR	isalpha		; Alphabetic
	LBNE	synerr		; No, Syntax error
	SUBA	#'A'		; Convert to
	ANDA	#%00011111	; Wrap for H/L case
	TFR	A,B		; B = value
	CLRA			; Zero high
	LDX	#20		; *10 (words)
	LBSR	xMUL		; D = ((c-'A')&0x1F)*10
	TFR	D,X		; X = index
	LDA	,Y		; Get next
	LBSR	isdigit		; Is it a number?
	BNE	getv1		; No, value is OK
	SUBA	#'0'		; Convert to zero offset
	LSLA			; x2
	LEAX	A,X		; Add to index
	LEAY	1,Y		; Skip digit
	LDA	,Y		; Get next char
getv1:	CLRB			; Assume numeric
	CMPA	#'$'		; Character suffix?
	BNE	getv2		; No, assumption correct
	LEAY	1,Y		; Skip '$'
	INCB			; Indicate character
getv2:	STB	expr_type	; save type
	RTS
;
; Compute variable address for assignment
;
address: BSR	getvar		; Get variable name
	BEQ	addr1		; Numeric
	LEAX	char_vars,X	; Offset to char var address
	RTS
addr1:	LDA	#'('		; Array index?
	LBSR	test_next	; Occuring next?
	BNE	addr3		; Not an array
	LBSR	chknum		; Insure numeric
	PSHS	U		; Save U
	LEAU	dim_check,X	; U = check address
	LDX	dim_vars,X	; X = variable
	CLR	nest		; Zero nesting count
	LBSR	evalsub		; Evaluate expression
	CMPD	,U		; Are we over
	BLO	addr2		; No, index is OK
dimerr:	LDA	#ERRdim		; "Dimension error"
	LBRA	error		; Report error
addr2	LEAX	D,X		; Offset
	LEAX	D,X		; Offset (16 bit)
	PULS	U,PC
addr3	LEAX	num_vars,X	; Offset to num variable address
addr4	RTS
;
; Test for direct only and report error
;
direct	TST	mode		; Direct mode?
	BEQ	addr4		; Yes
	LDA	#ERRpgm		; "Illegal program"
	LBRA	error
;
; Test for program only and report error
;
pgm	TST	mode		; Program running
	BNE	addr4		; Yes
	LDA	#ERRdir		; "Illegal direct"
	LBRA	error		; Report error
;
; Clear all variables
;
_CLEAR:	LDU	#0		; Begin with zero
clv1	LDX	char_vars,U	; Get char var pointer
	BEQ	clv2		; No char var
	LBSR	free		; Release the storage
clv2	LDX	dim_vars,U	; Get dim var pointer
	BEQ	clv3		; No dim var
	LBSR	free		; Release the storage
clv3	CLRA			; Zero high
	CLRB			; Zero low
	STD	num_vars,U	; Clear numeric
	STD	char_vars,U	; Clear char
	STD	dim_vars,U	; Clear dim
	LEAU	2,U		; Skip ahead
	CMPU	#260*2		; Are we over?
	BLO	clv1		; Do them all
	RTS
;
; Evaluate number only (no Chars)
;
evalnum:BSR	eval		; Evaluate expression
chknum:	TST	expr_type	; Is it numeric?
	BEQ	evcok		; Yes - OK
typerr:	LDA	#ERRtyp		; "Wrong type"
	LBRA	error		; Issue error
;
; Evaluate character only
;
evalchr:BSR	eval		; Evaluate expression
chkchr:	TST	expr_type	; Is it character?
	BEQ	typerr		; Report error
evcok:	RTS
;
; Evaluate an expression (Result in D)
;
eval:	CLR	nest		; Reset nesting level
	BSR	evalsub		; Evaluate sub-expression
	DEC	nest		; Were we at level-1
	LBNE	synerr		; No, report error
	RTS
;
; Evaluate a sub-expression
;
; Stack variables:
;	uc	Ostack[10]	22
;	uw	Nstack[20]	2
;	uc	Optr		1
;	uc	Nptr		0
evalbra:LBSR	expectb		; Check for bracket
evalsub:PSHS	A,B,X,U		; Save registers
	LEAS	-32,S		; Allocate local space
	INC	nest		; Advance nesting level
	CLRB			; Zero low
	STB	,S		; Nptr = 0
	STB	1,S		; Optr = 0
	STB	22,S		; Ostack[0] = 0;
	LBSR	getval		; Get initial value
	TFR	D,U		; U = value
	INC	,S		; ++Nptr
	LDB	,S		; B = Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	STU	B,X		; Nstack[++Nptr] = v
	TST	expr_type	; String operation?
	BEQ	evsn1		; No, try numeric
; String operations
evss0	LBSR	skip		; Get next character
	LBSR	is_e_end	; End of expression
	LBEQ	evse1a		; Exit
	LEAY	1,Y		; Advance
	ANDA	#$7F		; Remove high bit
	PSHS	A		; Save operator
	LDX	#sa2		; Point to acc2
	LBSR	getcval		; Get character value
	LDX	#sa1		; Point to SA1
	LDU	#sa2		; Point to SA2
	PULS	A		; Restore operator
	CMPA	#ADD		; Concatinate
	BNE	evss3		; No, try next
; Concatinate two strings
evss1:	LDA	,X+		; Get next
	BNE	evss1		; Go to end
	LEAX	-1,X		; Backup to last
evss2	LDA	,U+		; Get char
	STA	,X+		; Write to string
	BNE	evss2		; Do them all
	BRA	evss0		; And proceed
; Compare two strings
evss3	LDB	,X+		; Get from source
	CMPB	,U+		; Match?
	BNE	evss6		; Mismatch
	TSTB			; End of string?
	BNE	evss3		; No, keep comparing
evss4:	CMPA	#NE		; == ?
	BEQ	evss5		; Yes
	CMPA	#EQ		; <> ?
	LBNE	synerr		; Syntax error
	EORB	#$01
evss5	CLRA			; Zero high
	TFR	D,U		; U = value
	LDB	,S		; Get Nptr
	LSLB			; x2
	LEAX	2,S		; Address Nstack
	STU	B,X		; Nstack[Nptr] = value
	CLR	expr_type	; Set numeric
	BRA	evss0		; And proceed
evss6:	LDB	#1		; Indicate <>
	BRA	evss4		; And continue
; Numeric operations
evsn1	LBSR	skip		; Get next character
	LBSR	is_e_end	; End of expression
	LBEQ	evsn3		; Exit
	LEAY	1,Y		; Next
	ANDA	#$7F		; Remove high bit
	SUBA	#ADD-1		; 0 based priority table
	STA	32,S		; Save for later
	LDU	#priority	; Point to priority table
	LDA	A,U		; A = priority[c]
	LDB	1,S		; B = Optr
	LEAX	22,S		; X = Ostack
	LDB	B,X		; B = Ostack[Optr]
	CMPA	B,U		; priority[c] <= priority[Ostack[Optr]]?
	BHI	evsn2		; No, skip
	LDB	1,S		; B = Optr
	DEC	1,S		; --Optr
	LEAX	22,S		; X = Ostack
	LDA	B,X		; A = Ostack[Optr--]
	LDB	,S		; B = Nptr
	DEC	,S		; --Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	LDU	B,X		; U = Nstack[Nptr--]
	SUBB	#2		; Backup
	LDX	B,X		; X = Nstack[Nptr]
	LBSR	arith		; D = arith(Ostack[Optr--],Nstack[Nptr],v)
	TFR	D,U		; U = D
	LDB	,S		; B = Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	STU	B,X		; Nstack[Nptr] = arith(...)
evsn2	LBSR	getval		; Get value
	LBSR	chknum		; Insure numeric
	TFR	D,U		; U = result
	INC	,S		; ++Nptr
	LDB	,S		; B = ++Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	STU	B,X		; Nstack[++Nptr] = get_value()
	LDA	32,S		; A = c
	INC	1,S		; ++Optr
	LDB	1,S		; B = Optr
	LEAX	22,S		; X = Ostack
	STA	B,X		; Ostack[++Optr] = c
	BRA	evsn1		; Do all
; Clean up pending operations
evsn3	LDB	1,S		; Get Optr
	BEQ	evse1		; None pending
	DEC	1,S		; --Optr
	LEAX	22,S		; X = Ostack
	LDA	B,X		; A = Ostack[Optr--]
	LDB	,S		; B = Nptr
	DEC	,S		; --Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	LDU	B,X		; U = Nstack[Nptr--]
	SUBB	#2		; B = Backup
	LDX	B,X		; X = Nstack[Nptr]
	LBSR	arith		; arith(Ostack[Optr--],Nstack[Nptr],v)
	TFR	D,U		; U = D
	LDB	,S		; B = Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	STU	B,X		; Nstack[Nptr] = arith(...)
	BRA	evsn3		; Do them all
evse1	LDA	,Y		; Get data
evse1a	CMPA	#')'		; Closing brace?
	BNE	evse2		; No
	DEC	nest		; --nest
	LEAY	1,Y		; Skip ')'
evse2	LDB	,S		; B = Nptr
	LSLB			; x2
	LEAX	2,S		; X = Nstack
	LDD	B,X		; Get value
	LEAS	32,S		; Release stack
	STD	,S		; Set return value
	PULS	A,B,X,U,PC	; Restore and return
;
; Get value element for expression
;
getval	CLR	expr_type	; Assume numeric
	LBSR	skip		; Advance to non-blank
	LBSR	isdigit		; Is it a number?
	LBEQ	getnum		; Process number
	CMPA	#'$'		; Hex input?
	LBEQ	getnum		; Process number
	LEAY	1,Y		; Skip operator
	CMPA	#'('		; Nesting
	LBEQ	evalsub		; New sub-expression
	CMPA	#'!'		; NOT?
	BNE	gval1		; No, try next
	BSR	getval		; Get value
gval0:	COMA			; Invert high
	COMB			; Invert low
	LBRA	chknum		; And exit
gval1:	CMPA	#SUB|128	; Negate
	BNE	gval2		; No, try next
	BSR	getval		; Get value
getvc:	SUBD	#1		; Adjust
	BRA	gval0
gval2:	CMPA	#ASC|128	; Valid function?
	BLO	gvar1		; No, try variable
	SUBA	#ASC|128	; Convert to zero basc
	TFR	A,B		; B = value
	LBSR	expectb		; Get bracket
	LBSR	switch		; Execute handler
	FDB	oASC,oABS,oNUM,oRND,oKEY,oPEEK,oLEN,oUSR
; Not an operator
gvar1:	LEAY	-1,Y		; Backup
	LDX	#sa1		; Char in sa1
	LBSR	isalpha		; Variable?
	BNE	getcval		; No, try character value
	LBSR	getvar		; X = variable index
	BEQ	gvar3		; Yes, handle it
; Character variable
	LDU	#sa1		; Point to SA1
gcharv:	PSHS	U		; Save dest
	LDX	char_vars,X	; Point to char variables
	BNE	gvar2		; Yes
	LDX	#nulls		; Point to null string
gvar2:	LDB	#-1		; Begin with -1
gvar21:	INCB			; Advance
	LDA	,X+		; Get from source
	STA	,U+		; Write it
	BNE	gvar21		; And continue
	PSHS	A,B		; Save
	LDA	#'('		; Indexed?
	LBSR	test_next	; Is this it?
	BNE	gvar22		; No
	LBSR	evalsub		; Evaluate sub-expression
	LBSR	chknum		; Must be numeric
	CMPD	,S		; In range?
	LBHS	dimerr		; No, out of range
	LDX	2,S		; Get acc
	LDA	B,X		; Get char
	CLRB			; Zero high
	STD	,X		; Set value
	INC	expr_type	; Set character
gvar22	PULS	A,B,U,PC	
; Numeric variable
gvar3	LDA	#'('		; Array?
	LBSR	test_next	; Is it array?
	BNE	gvar4		; Yes, handle it
	LBSR	evalsub		; Get index
	LBSR	chknum		; Insure numeric
	CMPD	dim_check,X	; Check for overflow
	LBHS	dimerr		; Report error
	LDX	dim_vars,X	; Get index
	LBEQ	dimerr		; Report error
	LSLB			; x2
	ROLA			; x2
	LDD	D,X		; Get value
	RTS
gvar4	LDD	num_vars,X	; Get value
	RTS
;
; Get character value (X=sa)
;
getcval:LBSR	get_next	; Get next value
	CMPA	#'"'		; Quoted string?
	BNE	getcv2		; No, try next
; Character string
getcv1:	LDA	,Y+		; Get value
	LBEQ	synerr		; Error
	STA	,X+		; Write to output
	CMPA	#'"'		; End of string?
	BNE	getcv1		; Yes, exit
	CLR	-1,X		; Zero terminate
	LDA	#1		; Character type
	STA	expr_type	; Set type
	RTS
getcv2:	TFR	X,U		; U = output
	LBSR	isalpha		; Variable?
	BNE	getcv3		; No, try next
	LEAY	-1,Y		; Backup
	LBSR	getvar		; X = variable index
	LBEQ	synerr		; Report error
	LBRA	gcharv		; Get value into [U]
getcv3:	CMPA	#CHR|128	; Convert number into character
	BNE	getcv4		; No, try next
	LBSR	evalbra		; Get subexpression
	LBSR	chknum		; Insure numeric
	INC	expr_type	; Set character
	STB	,X		; Save it
	CLR	1,X		; Zero terminate
	RTS
getcv4:	CMPA	#STR|128	; Convert string to number
	LBNE	synerr		; Report error
	LBSR	evalbra		; Get sub-expression
	LBSR	chknum		; Insure numeric
	INC	expr_type	; Set character
;
; Write number(D) into string(U)
;
uns2str	PSHS	A,B,X,Y		; Save value
	LDY	#0		; Zero counter
	TFR	D,X		; X = number
	BRA	num2s1		; Write it
num2str	PSHS	A,B,X,Y		; Save value
	LDY	#0		; Reset count
	TFR	D,X		; X = value
	TSTA			; Negative?
	BPL	num2s1		; Not negative
	COMA			; Invert
	COMB			; Invert
	ADDD	#1		; Negate
	TFR	D,X		; X = value
	LDA	#'-'		; Negative indicator
	STA	,U+		; Write it
num2s1	LDD	#10		; / 10
	LBSR	xDIV		; X = X / D
	PSHS	B		; Save result
	LEAY	1,Y		; Advance
	CMPX	#0		; More to go?
	BNE	num2s1		; Do them all
num2s2	PULS	A		; Get result
	ADDA	#'0'		; Convert to ASCII
	STA	,U+		; Write to output
	LEAY	-1,Y		; Reduce count
	BNE	num2s2		; Do them all
	CLR	,U		; Zero
	PULS	A,B,X,Y,PC	; Restore & return
; Numeric function handlers
oASC:	LBSR	evalsub		; Get sub-expression
	LBSR	chkchr		; Insure character
	LDB	sa1		; Get first character
	CLRA			; Zero high
	STA	expr_type	; Numeric result
	RTS 
oNUM:	LBSR	evalsub		; Evaluate sub-expression
	LBSR	chkchr		; Insure character
	PSHS	Y		; Save Y
	LDY	#sa1		; Point to string accumulator
	LBSR	getnum		; Get the number
	CLR	expr_type	; Numeric result
	PULS	Y,PC		; Restore & return
oABS:	LBSR	evalsub		; Evaluate sub-expression
	TSTA			; Check for negative
	BPL	getvno		; Number only
	LBRA	getvc		; Negate if so
oRND:	LBSR	evalsub		; Eval sub-expression
	PSHS	A,B		; Save result
	LDD	randseed	; Get random seed
	LDX	#13709		; First calculation
	LBSR	xMUL		; Perform it
	ADDD	#13849		; Add second
	STD	randseed	; Resave seed
	TFR	D,X		; Get result
	PULS	A,B		; Get value
	LBSR	xDIV		; D = X / D
	BRA	getvno		; Number only
oKEY:	LDA	#')'		; Looking for bracket
	LBSR	expect		; Test for it
	LDB	keypress	; Get last keystroke
	CLRA			; Zero high
	STA	keypress	; Reset
	RTS
oPEEK:	LBSR	evalsub		; Get value
	TFR	D,X		; X = result
	LDB	,X		; Get value
	CLRA			; Zero high
getvno:	LBRA	chknum		; Insure numeric
; Length of variable
oLEN:	LBSR	getvar		; Get variable
	LDA	#')'		; Terminator
	LBSR	expect		; Expect it
	TST	expr_type	; Type of variable
	BNE	olen1		; Character
	LDD	dim_vars,X	; Defined?
	LBEQ	dimerr		; No - error
	LDD	dim_check,X	; Get length
olen0:	CLR	expr_type	; Numeric
	RTS
olen1:	CLRA			; Zero high
	CLRB			; Zero low
	LDX	char_vars,X	; Get pointer
	BEQ	olen0		; Not defined
olen2	TST	,X+		; End of string?
	BEQ	olen0		; Yes, stop
	ADDD	#1		; Advance
	BRA	olen2		; And continue
; User supplied subroutine
oUSR:	LBSR	evalsub		; Get address
	LBSR	chknum		; Insure numeric
	STD	,--S		; Save
	STS	temp1		; Save stack pointer
ousr1:	LBSR	tnc		; Aother
	BNE	ousr3		; No
	DEC	nest		; Clear ','
	LBSR	evalsub		; Get value
	TST	expr_type	; Numeric?
	BEQ	ousr2		; Yes, pass result
	LDD	#sa1		; Point to string acc
ousr2:	STD	,--S		; Save value
	BRA	ousr1		; Do them all
ousr3:	LDX	temp1		; Get value
	PSHS	Y		; Save Y
	JSR	[,X]		; Execute handler
	PULS	Y		; Restore Y
	LDS	temp1		; Fix stack
	CLR	expr_type	; Returns numeric
	PULS	X,PC		; Clean and return
;
; Execute handler from following table via (A)
;
switch:	PSHS	X		; Save registers
	LDX	2,S		; Get PC
	ABX			; Offset
	LDX	B,X		; Get value
	STX	2,S		; Set new PC
	PULS	X,PC		; Restore & Branch
;
; Perform an arithmetic operation (X)(A)(U)
;
arith:	DECA			; Convert to zero offset
	CMPA	#GT-ADD		; Is it in range
	LBHI	synerr		; No, report error
	STU	temp		; Set secondary operand
	PSHS	X,U		; Save X & reserve room
	LSLA			; x2
	LDX	#atable		; Point to table
	LDX	A,X		; Get offset
	STX	2,S		; Set return address
	PULS	A,B,PC		; D = result * Launch
atable:	FDB	oADD,oSUB,oMUL,oDIV,oMOD,oAND
	FDB	oOR,oXOR,oEQ,oNE,oLE,oLT,oGE,oGT
oADD	ADDD	temp
	RTS
oSUB	SUBD	temp
	RTS
oMUL	TFR	U,X		; X = op2
	LBRA	xMUL		; D = X*D
oDIV	BSR	oMOD		; X=X/D
	TFR	X,D		; D=X/D
	RTS
oMOD	TFR	D,X		; X = op1
	LDD	temp		; Get value
	LBRA	xDIV		; X = X/D; d=X%D
oAND	ANDA	temp
	ANDB	temp+1
	RTS
oOR	ORA	temp
	ORB	temp+1
	RTS
oXOR	EORA	temp
	EORB	temp+1
	RTS
oEQ	CMPD	temp
	BEQ	cret1
cret0	CLRA
	CLRB
cretx	RTS
oNE	CMPD	temp
	BEQ	cret0
cret1	LDD	#1
	RTS
oLE	CMPD	temp
	BLE	cret1		; LE
	BRA	cret0
oLT	CMPD	temp
	BLT	cret1		; LO
	BRA	cret0
oGE	CMPD	temp
	BGE	cret1		; HS
	BRA	cret0
oGT	CMPD	temp
	BGT	cret1		; HI
	BRA	cret0
;
; Write number(D)
;
putn	PSHS	X,U		; Save U
	LDU	#buffer		; Point to buffer
	TFR	U,X		; X = output
	LBSR	uns2str		; Get number
	BSR	puts		; Output
	PULS	X,U,PC		; Restore & return
;
; Write message(PC)
;
putm:	PSHS	X		; Save X
	LDX	2,S		; Get PC
	BSR	puts		; Write it
	STX	2,S		; Resave
	PULS	X,PC		; Restore and return
;
; Write string(X)
;
puts:	LDA	,X+		; Get char
	BEQ	cretx		; End of string
	BSR	putc		; Write it
	BRA	puts		; And continue
;
; Output space
;
space:	LDA	#' '		; Get space
	BRA	putc		; Output
;
; Get string
;
gets:	PSHS	U		; Save U
	LDU	file		; Input from file?
	BNE	getsf
	CLRB			; Zero offset
gets1	FCB	$3F,34		; Read console device
	CMPA	#$03		; Ctrl-C
	LBEQ	break		; Exit
	CMPA	#$08		; Backspace?
	BEQ	gets2		; Handle it
	CMPA	#$7F		; Delete?
	BEQ	gets2		; Handle it
	CMPA	#$0D		; Carriage return?
	BEQ	gets3		; Handle it
	CMPB	#99		; Are we over?
	BHS	gets1		; Don't accept
	STA	B,Y		; Write it
	BSR	putc		; Echo
	INCB			; Advance
	BRA	gets1
gets2	TSTB			; At start?
	BEQ	gets1		; Ignore
	BSR	putm		; Output message
	FCB	8,' ',8,0	; Wipe character
	DECB			; Backup
	BRA	gets1		; And proceed
gets3:	CLR	B,Y		; Zero data
	PULS	U		; Restore U
;
; Write LFCR
;
lfcr:	LDA	#$0A		; LF
	BSR	putc		; Output
	LDA	#$0D		; CR
;
; Write character
;
putc	PSHS	A,B,U		; Save registers
	LDU	file		; Get handle
	BEQ	putc1		; Console
	CMPU	#8		; 1-8 = device
	BLS	putc2		; Device
	CMPA	#$0A		; LF?
	BEQ	putc3		; Don't write
	FCB	$3F,61		; Write file
	PULS	A,B,U,PC	; Restore & return
putc1	FCB	$3F,33		; Write console
	PULS	A,B,U,PC	; Restore & return
putc2	TFR	U,D		; D = device
	DECB			; Backup
	LDA	,S		; Get char back
	FCB	$3F,36		; Write device
putc3	PULS	A,B,U,PC	; Restore & return
;
; Reading from file or device
getsf:	CLRB			; Zero low
getsf1:	CMPU	#8		; Device?
	BLS	getsf3		; Reading device
	FCB	$3F,59		; Read file
	BNE	getsf4		; EOF
getsf2	CMPA	#$0D		; Do we have space?
	BEQ	getsf4		; EOL
	CMPB	#99		; Do we have space?
	BHS	getsf1		; No, don't save
	STA	B,Y		; Save in buffer
	INCB			; Advance
	BRA	getsf1		; And proceed
getsf3	PSHS	B		; Save index
	TFR	U,D		; D = device
	DECB			; 0 origin
	FCB	$3F,37		; Read device
	PULS	B		; Restore B
	BRA	getsf2		; And proceed
getsf4	CLR	B,Y		; Zero terminate
	PULS	U,PC		; Restore * return
;
; Test for characte from console
;
testc	FCB	$3F,35		; Test for char
	BEQ	testc1		; We have one
	CLRA			; Return zero
	RTS
testc1	TSTA			; Clear Z
	RTS
;
; Table of BASIC reserved words
;
rwordz:	FCB	0		; Marker for LIST
rwords:	FCCZ	'LET'
	FCCZ	'EXIT'
	FCCZ	'LIST'
	FCCZ	'NEW'
	FCCZ	'RUN'
	FCCZ	'CLEAR'
	FCCZ	'GOSUB'
	FCCZ	'GOTO'
	FCCZ	'RETURN'
	FCCZ	'PRINT'
	FCCZ	'FOR'
	FCCZ	'NEXT'
	FCCZ	'IF'
	FCCZ	'LIF'
	FCCZ	'REM'
	FCCZ	'STOP'
	FCCZ	'END'
	FCCZ	'INPUT'
	FCCZ	'DIM'
	FCCZ	'ORDER'
	FCCZ	'READ'
	FCCZ	'DATA'
	FCCZ	'POKE'
	FCCZ	'SAVE'
	FCCZ	'LOAD'
	FCCZ	'OPEN'
	FCCZ	'CLOSE'
	FCCZ	'TO'
	FCCZ	'STEP'
	FCCZ	'THEN'
	FCCZ	'+'
	FCCZ	'-'
	FCCZ	'*'
	FCCZ	'/'
	FCCZ	'%'
	FCCZ	'&'
	FCCZ	'|'
	FCCZ	'^'
	FCCZ	'='
	FCCZ	'<>'
	FCCZ	'<='
	FCCZ	'<'
	FCCZ	'>='
	FCCZ	'>'
	FCCZ	'CHR$'
	FCCZ	'STR$'
	FCCZ	'ASC'
	FCCZ	'ABS'
	FCCZ	'NUM'
	FCCZ	'RND'
	FCCZ	'KEY'
	FCCZ	'PEEK'
	FCCZ	'LEN'
	FCCZ	'USR'
nulls:	FCB	0
LET	EQU	1
EXIT	EQU	LET+1
LIST	EQU	EXIT+1
NEW	EQU	LIST+1
RUN	EQU	NEW+1
CLEAR	EQU	RUN+1
GOSUB	EQU	CLEAR+1
GOTO	EQU	GOSUB+1
RETURN	EQU	GOTO+1
PRINT	EQU	RETURN+1
FOR	EQU	PRINT+1
NEXT	EQU	FOR+1
IF	EQU	NEXT+1
LIF	EQU	IF+1
REM	EQU	LIF+1
STOP	EQU	REM+1
END	EQU	STOP+1
INPUT	EQU	END+1
DIM	EQU	INPUT+1
ORDER	EQU	DIM+1
READ	EQU	ORDER+1
DATA	EQU	READ+1
POKE	EQU	DATA+1
SAVE	EQU	POKE+1
LOAD	EQU	SAVE+1
OPEN	EQU	LOAD+1
CLOSE	EQU	OPEN+1
TO	EQU	CLOSE+1
STEP	EQU	TO+1
THEN	EQU	STEP+1
; Operators
ADD	EQU	THEN+1	; Also used as marker
SUB	EQU	ADD+1
MUL	EQU	SUB+1
DIV	EQU	MUL+1
MOD	EQU	DIV+1
AND	EQU	MOD+1
OR	EQU	AND+1
XOR	EQU	OR+1
EQ	EQU	XOR+1
NE	EQU	EQ+1
LE	EQU	NE+1
LT	EQU	LE+1
GE	EQU	LT+1
GT	EQU	GE+1
; Character Functions
CHR	EQU	GT+1
STR	EQU	CHR+1
; Numeric functions
ASC	EQU	STR+1	; Also used as a marker
ABS	EQU	ASC+1
NUM	EQU	ABS+1
RND	EQU	NUM+1
KEY	EQU	RND+1
PEEK	EQU	KEY+1
LEN	EQU	PEEK+1
USR	EQU	LEN+1
;
; Error messages
;
emsg:	FCCZ	'Syntax'
	FCCZ	'Illegal program'
	FCCZ	'Illegal direct'
	FCCZ	'Line number'
	FCCZ	'Wrong type'
	FCCZ	'Divide by zero'
	FCCZ	'Nesting'
	FCCZ	'Dimension'
	FCCZ	'Data'
	FCCZ	'Out of memory'
	FCCZ	'File not open'
	FCCZ	'File already open'
ERRsyn	EQU	0
ERRpgm	EQU	1
ERRdir	EQU	2
ERRlin	EQU	3
ERRtyp	EQU	4
ERRdiv	EQU	5
ERRnst	EQU	6
ERRdim	EQU	7
ERRdat	EQU	8
ERRmem	EQU	9
ERRfno	EQU	10
ERRfoo	EQU	11
; Priority of operations
priority FCB	0,1,1,2,2,2,3,3,3,1,1,1,1,1,1
