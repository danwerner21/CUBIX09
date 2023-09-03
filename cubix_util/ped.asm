	title	CUBIX SCREEN EDITOR
*
* PED: Version of 'ED' for my homebrew portable
*
* Copyright 1983-2005 Dave Dunfield
* All rights reserved.
*
TEXT	EQU	OSRAM+$1F00	START OF TEXT BUFFER
STACK	EQU	TEXT-1		EDITOR STACK
NLINES	EQU	23		# LINES - 1
*
* TEMPORARY STORAGE
*
	ORG	OSRAM+$800
XPOS	RMB	1		CURSOR X POSITION
YPOS	RMB	1		CURSOR Y POSITION
TXTPOS	RMB	2		SCREEN TOP POSITION
OLDPOS	RMB	1		OLD CURSOR POSITION
CURFLG	RMB	1		CURSOR FLAG
INSFLG	RMB	1		INSERT CHARACTER FLAG
TEMP	RMB	2		TEMPORARY STORAGE
SNRPOS	RMB	2		POSITION IN SNARF BUFFER
NAMBUF	RMB	25		SAVED FILENAME
INPBUF	RMB	64		LOTSA SPACE FOR SEARCH
DLBUF	EQU	*		LINE DELETE BUFFER
	ORG	XPOS+256
SNARF	EQU	*		BUFFER FOR DELETE TO BUFFER
	ORG	OSRAM
*
* INITIALIZATION AND STARTUP CODE
*
EDIT	LDS	#STACK		SET UP STACK
	CMPA	#'?'		QUERY OPERATION?
	BNE	EDIT1		NO, ITS OK
	SSR	25		OUTPUT MESSAGE
	FCCZ	'Use: ED <file>'
	SSR	0
EDIT1	LDA	#=XPOS		POSITION
	TFR	A,DP		SET DIRECT PAGE
	SETDP	=XPOS		INFORM ASSEMBLER
* SAVE FILENAME
	LDX	#NAMBUF		POINT TO NAME BUFFER
SAVNAM	LDA	,Y+		GET CHARACTER FROM INPUT LINE
	STA	,X+		SAVE IN FILE BUFFER
	CMPA	#$0D		TEST FOR END OF LINE
	BNE	SAVNAM		KEEP GOING TILL NAME SAVED
	LDY	#NAMBUF		POINT AT FILENAME
	SSR	10		GET FILENAME
	LBNE	ABORT		GIVE UP
	LDX	#TEXT		POINT TO TEXT POSITION
	STX	TXTPOS		INITIAL POSITION
	SSR	68		DUZ IT EXIST
	BNE	NEWFIL		NO, IT'S A NEW FILE
	LDX	#TEXT		POINT TO TEXT AREA
	SSR	53		LOAD FILE
	LBNE	ABORT		IF ERROR, GET UPSET
	LBSR	CLS		CLEAR SCREEN
	LBSR	REFSCR		REFRESH THE SCREE
	BRA	NOTNEW		NOT A NEW FILE
NEWFIL	LBSR	CLS		CLEAR SCREEN
	LDA	#$FF		END OF FILE MARKER
	STA	TEXT		INITIALIZE NEW FILE TO ZIP
	LBSR	REFSCR		SET UP SCREEN
	LDX	#NEWMSG		MESSAGE TO DISPLAY
	LBSR	ERRMSG		DISPLAY
NOTNEW	LDA	#$0D		GET CARRIAGE RETURN
	STA	DLBUF		CLEAR DELETED LINE
	LDA	#$FF		GET END CHARACTER
	STA	SNARF		SAVE IN SNARF BUFFER
	STA	INSFLG		SET INSERT MODE
	LDD	#SNARF		POINT TO SNARF BUFFER
	STD	SNRPOS		SAVE SNARF POSITION
	CLR	CURFLG		CLEAR CURSOR FLAG
*
* COMMAND HANDLER
*
EDTCMD	TST	CURFLG		WAS LAST COMMAND MOVE CURSOR
	BNE	NORES		IF SO, DON'T RESET POSITION
	LDA	XPOS		GET POSITION
	STA	OLDPOS		RESET POSITION
NORES	LBSR	CURPOS		POSITION CURSOR
	LBSR	GETKEY		GET ONE CHARACTER
	CLR	CURFLG		INDICATE NO SPECIAL OPERATION
	BSR	EXECMD		EXECUTE COMMAND
	BRA	EDTCMD		KEEP PROCESSING
*
* EXECUTES AN EDIT COMMAND
*
EXECMD	TSTA			TEST FOR CHARACTER TO INSERT
	BMI	CURUP		NO, IT'S A COMMAND
*
* NORMAL CHARACTER, INSERT IT INTO TEXT
*
	CMPA	#$0D		IS IT A CARRIAGE RETURN
	BEQ	CRSPEC		IF SO, SPECIAL CASE
	PSHS	A		SAVE CHARACTER
	LBSR	LOCADR		FIND OUR ADDRESS
	BMI	GINSCH		IF EOF, INSERT
	CMPA	#$0D		CARRIAGE RETURN?
	BEQ	GINSCH		DEFINATELY INSERT
	TST	INSFLG		ARE WE INSERTING
	BPL	NOINST		IF NOT, DON'T INSERT
GINSCH	LBSR	INSCHR		INSERT CHARACTER
NOINST	PULS	A		RESTORE CHARACTER
	STA	,X		INSERT INTO TEXT
	LBSR	REFLIN		REFRESH THIS LINE
	LBRA	ADVCHR		AND ADVANCE ONE CHARACTER
* INSERTING CARRIAGE RETURN
CRSPEC	LBSR	LOCADR		GET OUR ADDRESS
	LBSR	INSCHR		INSERT CHARACTER
	LDA	#$0D		GET CARRIAGE RETURN
	STA	,X		SAVE IN TEXT
	LBSR	REFBOT		REFRESH BOTTOM OF SCREEN
	LBRA	ADVCHR		AND ADVANCE TO NEXT POSITION
*
* PROCESS EDIT COMMAND
*
* CURSOR UP COMMAND
*
CURUP	DEC	CURFLG		INDICATE SPECIAL CURSOR MOVE
	ANDA	#$7F		CONVERT TO NORMAL CHARACTER
	LBEQ	BAKLIN		IF SO, GO BACK A LINE
*
* CURSOR DOWN COMMAND
*
	DECA			TEST FOR CURSOR DOWN
	LBEQ	ADVLIN		IF SO, GO DOWN
*
* CURSOR FORWARD COMMAND
*
	CLR	CURFLG		CLEAR SPECIAL FLAG
	DECA			TEST FOR CURSOR FORWARD
	LBEQ	ADVCHR		IF SO, ADVANCE A CHARACTER
*
* CURSOR BACKWARD COMMAND
*
	DECA			TEST FOR CURSOR BACKUP
	LBEQ	BAKCHR		IF SO, BACKUP
*
* ADVANCE LINE COMMAND
*
	DECA			TEST FOR LINE
	BNE	CMD0		NO, TRY NEXT
ALINE	CLR	XPOS		SET POSITION TO ZERO
	LBRA	ADVLIN		ADVANCE A LINE
*
* BACK LINE COMMAND
*
CMD0	DECA			TEST FOR BACK LINE
	BNE	CMD1		NO, TRY NEXT COMMAND
	LDA	XPOS		GET OLD POSITION
	LBEQ	BAKLIN		IF ALREADY AT ZERO, GO BACK A LINE
	CLR	XPOS		INDICATE ZERO POSITION
	RTS
*
* TOGGLE INSERT COMMAND
*
CMD1	DECA			TEST FOR REFRESH COMMAND
	BNE	CMD2		NO, TRY NEXT COMMAND
	LDX	#INSON		GET INSERT ON MESSAGE
	COM	INSFLG		CHANGE INSERT FLAG
	BMI	INMSG		ISSUE MESSAGE
	LDX	#INSOFF		GET INSERT OFF MESSAGE
INMSG	LBRA	ERRMSG		ISSUE MESSAGE
*
* DELETE CHARACTER COMMAND
*
CMD2	DECA			TEST FOR DELETE
	BNE	CMD3		NO, TRY NEXT COMMAND
DELGO	LBSR	LOCADR		GET OUR ADDRESS
	LBSR	DELCHR		DELETE THE CHARACTER
	CMPA	#$0D		DID WE DELETE A CARRIAGE RETURN
	BEQ	DELCR		IF SO, SPECIAL CASE
	TSTA			TEST FOR NO DELETE
	BMI	DELRTS		IF SO, NO ACTION
	LBRA	REFLIN		REFRESH THIS LINE
DELCR	TFR	X,D		GET OUR POSITION
	CMPD	#TEXT		ARE WE HOME
	BEQ	NODEOF		IF SO, NO NEED TO DELETE
	LDA	,X		GET NEXT CHARACTER
	BPL	NODEOF		DIDN'T TRY TO DELETE END OF FILE
	STA	1,X		RESET END OF FILE
	LDA	#$0D		GET CARRIAGE RETURN
	CMPA	-1,X		DO WE ALREADY HAVE A CARRIAGE RETURN THERE?
	BEQ	NODEOF		IF SO, WE ARE OK
	STA	,X		RESAVE INTO TEXT
NODEOF	LBRA	REFBOT		REFRESH SCREEN BOTTOM
DELRTS	RTS			QUIT WHILE WE ARE AHEAD
*
* DELETE PREVIOUS COMMAND
*
CMD3	DECA			TEST FOR DELETE PREV
	BNE	CMD4		NO, TRY NEXT
	LBSR	BAKCHR		BACKUP A CHARACTER
	LBSR	CURPOS		POSITION CURSOR
	BRA	DELGO		CONTINUE WITH DELETE
*
* COMMAND COMMAND, PROMPT FOR EDITOR COMMAND
*
CMD4	DECA			TEST FOR QUIT
	LBNE	CMD5		NO, TRY NEXT COMMAND
	LBSR	CLRCMD		BOTTOM LINE, CLEARED
	SSR	24		DISPLAY MESSAGE
	FCCZ	'Command: '
	LBSR	GETCMD		GET COMMAND INPUT
	LBSR	CNVBUF		CONVERT TO UPPERCASE
	LDX	#CMDTAB		POINT TO COMMAND TABLE
	SSR	4		SKIP ANY BLANKS
	BEQ	REFR1		IF NULL LINE, REFRESH SCREEN
	SSR	18		GET COMMAND FROM BUFFER
	DECB			TEST FOR EXIT OR QUIT
	BMI	QUIT		IF QUIT, GO AWAY
	BNE	APPEND		NO, TRY APPEND FILE COMMAND
* SAVING FILE, FIND OUT HOW MANY BLOCKS TO SAVE
SAVFIL	LDY	#NAMBUF		POINT AT FILENAME
	SSR	10		GET NAME
	BSR	SAVOUT		SAVEOUT FILE
	LBNE	WAIKEY		ERROR, DON'T EXIT
QUIT	LBSR	CLS		CLEAR SCREEN
	CLRA			SET RC=0
* RETURN TO DOS
ABORT	SSR	0		REENTER DOS
*
* SAVES FILE ON DISK
*
SAVOUT	LBSR	FNDEOF		LOCATE END OF FILE
	TFR	X,D		COPY TO ACC'S
	SUBD	#TEXT+1		CONVERT TO FILE LENGTH
	TFR	A,B		COPY HIGH TO LOW
	CLRA			CLEAR CARRY
	RORB			SHIFT OUT LOW, =*512
	INCB			ADD ONE FOR PARTIAL SECTOR
	LDX	#TEXT		POINT TO FILE IN MEMORY
	SSR	54		SAVE FILE
	RTS
*
* APPENDS A FILE TO THE CURRENT ONE
*
APPEND	DECB			TEST FOR ABBEND
	BNE	SAVE		NO, TRY SAVE COMMAND
	SSR	10		GET FILENAME
	BNE	WAIKEY		WAIT IF IT'S INVALID
	LBSR	FNDEOF		LOCATE END OF FILE
	LEAX	-1,X		BACKUP TO END OF FILE MARKER
	SSR	53		LOAD THE FILE
	BEQ	REFR1		ALLOW HIM TO SEE ERROR
WAIKEY	LDX	#WAIMSG		POINT AT KEY MESSAGE
	SSR	23		DISPLAY
	LBSR	GETKEY		WAIT FOR INPUT
REFR1	LBSR	CLS		CLEAR SCREEN
	LBRA	REFSCR		AND PERFORM REFRESH
*
* SAVE IN OLD OR NEW FILE
*
SAVE	DECB			TEST FOR SAVE
	BNE	PACK		NO, TRY PACK
	SSR	4		ANY OPERANDS?
	BNE	NEWNAM		IF SO, USE OLD NAME
	LDY	#NAMBUF		POINT AT SAVED NAME
NEWNAM	SSR	10		GET FILENAME
	BNE	WAIKEY		NAME IS OK, SAVE FILE
	LBSR	SAVOUT		SAVE FILE ON DISK
	LBNE	WAIKEY		ERROR, EXIT
	LBRA	CURHOM		HOME CURSOR AND CONTINUE
*
* PACK FILE, REMOVE BLANKS AND INSERT TAB CHARACTERS IF POSSIBLE
*
PACK	DECB			TEST FOR 'TABS'
	BNE	UNPACK		NO, TRY UNPACK
	LDX	#TEXT		POINT TO TOP OF FILE
	STX	TXTPOS		RESET TEXT POSITION
	TFR	X,Y		COPY TO NEXT POINTER
GOLIN	CLR	TEMP		INDICATE ON LINE ZERO
NOCOM	INC	TEMP		ADVANCE ONE IN LINE
	LDA	,X+		GET CHARACTER FROM X
	STA	,Y+		SAVE IN DEST
	BMI	ENPAK		END OF PACK
	CMPA	#$0D		END OF LINE?
	BEQ	GOLIN		IF SO, COULD BE COMMENT ON NEXT LINE
	CMPA	#' '		IS IT A SPACE?
	BNE	NOCOM		NOT A SPACE
	PSHS	X		SAVE X POINTER
SKPSPC	LDA	TEMP		TEST FOR AT POSITION
	ANDA	#7		TEST FOR A TAB POSITION
	BEQ	TABOK		IF SO, TAB IS OK HERE
	INC	TEMP		ADVANCE IN TEXT
	LDA	,X+		GET CHARACTER FROM SOURCE
	CMPA	#' '		SPACE?
	BEQ	SKPSPC		KEEP SKIPPING
	PULS	X		GET POSITION BACK
SAVSPC	LDA	,X+		GET CHARACTER FROM LINE
	STA	,Y+		SAVE IN DEST
	CMPA	#' '		TEST FOR SPACE
	BEQ	SAVSPC		FINISH SAVEING THE SPACES
	CMPA	#$0D		CARRIAGE RETURN?
	BEQ	GOLIN		IF SO, START NEW LINE
	BRA	NOCOM		SAVE THIS SPACE
TABOK	LDB	#9		GET A TAB CHARACTER
	STB	-1,Y		CHANGE SPACE TO TAB
	PULS	A,B		FIX UP STACK
	BPL	NOCOM		KEEP MOVEING
ENPAK	BRA	UEOF		REFRESH SCREEN
*
* UNPACK TAB SPACES, REPLACING WITH BLANKS
*
UNPACK	DECB			TEST FOR 'UNPACK'
	BNE	DOS		NO, TRY DOS ENTRY
	LDX	#TEXT		POINT TO START OF TEXT
UGOLIN	STX	TXTPOS		REMEMBER WHERE WE ARE
	CLR	TEMP		STARTING ON COLUMN ZERO
	LDY	#SNARF		POINT TO SNARF BUFFER
UMOVL	INC	TEMP		INDICATE ON NEXT POSITION
	LDA	,X+		GET CHARACTER FROM SOURCE
	STA	,Y+		SAVE IN CREATED LINE
	BMI	UEOF		END OF FILE
	CMPA	#9		IS IT A TAB?
	BEQ	UTAB		TAB IS SPECIAL CASE
	CMPA	#$0D		CARRIAGE RETURN?
	BNE	UMOVL		IF NOT, KEEP MOVEING
	BRA	UCR		HANDLE CARRIAGE RETURN
* TAB, FILL WITH SPACES
UTAB	LDA	#' '		GET SPACE
	STA	-1,Y		REPLACE TAB WITH SPACE
UFILL	LDB	TEMP		GET HORZ POSITION
	ANDB	#7		TEST FOR TAB STOP
	BEQ	UMOVL		WE ARE AT A TAB STOP
	STA	,Y+		ADD ONE SPACE TO THE LINE
	INC	TEMP		INDICATE WE ARE AT THE END
	BRA	UFILL		KEEP GOING
* CARRIAGE RETURN, END OF LINE
UCR	TFR	X,D		GET POINTER
	SUBD	TXTPOS		CONVERT TO SIMPLE OFFSET
	STD	TEMP		SAVE FOR LATER
	LDX	TXTPOS		GET OUR POSITION
	TFR	Y,D		GET POSITION IN LINE
	SUBD	#SNARF		CONVERT TO SIMPLE OFFSET
	SUBD	TEMP		FIND OUT HOW MANY BYTES MORE
	BEQ	UNOINS		DON'T INSERT IF NO EXTRA
	LBSR	INSMUL		INSERT EXTRA SPACE
UNOINS	LDY	#SNARF		POINT TO SNARF BUFFER
UMOV	LDA	,Y+		GET CHARACTER FROM LINE
	STA	,X+		SAVE IN DESTINATION LINE
	CMPA	#$0D		TEST FOR END OF LINE
	BNE	UMOV		KEEP GOING
	BRA	UGOLIN		KEEP LOOKING
* END OF FILE, RESET PARAMETERS
UEOF	LDA	#$FF		GET MARKER
	STA	SNARF		INDICATE NO SNARF BUFFER
	LBRA	TOPF		GO TO TOP OF FILE
*
* TEMPORARY DOS ENTRY
*
DOS	DECB			TEST FOR 'DOS'
	BNE	INVCMD		NO, COMMAND WAS INVALID
	LBSR	CLS		CLEAR SCREEN
	PSHS	DP		SAVE DIRECT PAGE REGISTER
	SSR	4		TEST FOR OPERAND
	BNE	DOCMD		DO DOS COMMAND
	SSR	101		ENTER DOS
	PULS	DP		RESTORE DIRECT PAGE
	LBRA	REFR1		REFRESH AND CONTINUE
* COMMAND WAS SUPPLIED
DOCMD	SSR	100		EXECUTE COMMAND
	PULS	DP		RESTORE DP
	LBRA	WAIKEY		WAIT FOR KEY BEFORE RESUMEING
* COMMAND WAS UNRECOGNISED
INVCMD	LDX	#ICMMSG		INDICATE INVALID COMMAND
*
* ISSUES ERROR MESSAGE ON LINE 23, IN INVERSE VIDEO
*
ERRMSG	PSHS	X		SAVE POINTER TO MESSAGE
	LBSR	CLRCMD		COMMAND LINE & CLEAR
	CLR	>INVCHR		INSURE WE STOP AT END
	LDX	#INVON		SET INVERSE VIDEO
	SSR	23		DISPLAY
	PULS	X		GET MSG POINTER BACK
	SSR	23		DISPLAY
	LDX	#INVOFF		SET NORMAL VIDEO
	SSR	23		DISPLAY
	RTS
*
* PAGE FORWARD C0MMAND
*
CMD5	DECA			TEST FOR PAGE FORWARD COMMAND
	BNE	CMD6		NO, TRY PAGE BACKWARD
	LDX	TXTPOS		GET TEXT POSITION
	LDB	#NLINES-1	# LINES TO MOVE
PAGE	LDA	,X+		GET POSITION
	LBMI	ADVEOF		GONE BEYOND END OF SCREEN
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BNE	PAGE		KEEP LOOKING
	DECB			REDUCE COUNT
	BNE	PAGE		KEEP LOOKING
	STX	TXTPOS		RESAVE TEXT POSITION
PAGCR	LDA	,X+		GET BYTE FROM TEXT
	BMI	PAGEOF		END OF FILE IS ON SCREEN
	CMPA	#$0D		TEST FOR NEW LINE
	BNE	PAGCR		KEEP LOOKING
	INCB			INDICATE ANOTHER LINE
	CMPB	#NLINES-1	TEST FOR BEYOND END
	BLT	PAGCR		KEEP LOOKING
PAGEOF	STB	YPOS		POINT AT EOF LINE
	CLR	XPOS		ZERO 'X' POSITION
	LBRA	REFSCR		REFERESH SCREEN
*
* BACK PAGE COMMAND
*
CMD6	DECA			TEST FOR BACKUP COMMAND
	BNE	CMD7		NO, TRY NEXT
PGGO	CLR	YPOS		POSITION TO TOP OF SCREEN
	CLR	XPOS		CLEAR 'X' POSITION
	LDB	#NLINES		NUMBER OF LINES TO MOVE
PGBAK	LDA	#-1		START WITH -1
	STA	TEMP		ZERO NUMBER OF LINES MOVED
	LDX	TXTPOS		GET TOP OF SCREEN POSITION
	CMPX	#TEXT		ARE WE AT TOP?
	LBEQ	ADVEOF		IF SO, STOP HERE
PGB1	INC	TEMP		ADVANCE COUNT
PGB2	CMPX	#TEXT		AT TOP?
	BEQ	TOPSCR		YES, STOP
	LDA	,-X		BACKUP ONE CHARACTER
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BNE	PGB2		IF NOT, KEEP LOOKING
	DECB			REDUCE COUNT
	BNE	PGB1		KEEP GOING TILL WE FIND
	LEAX	1,X		ADVANCE TO START OF LINE
TOPSCR	STX	TXTPOS		RESAVE POSITION
	LBRA	REFSCR		REFRESH SCREEN
*
* DELETE TO END OF LINE
*
CMD7	DECA			TEST FOR DELETE END OF LINE
	BNE	CMD8		NO, TRY NEXT COMMAND
DELSN	LBSR	LOCADR		LOCATE ADDRESS
	LBMI	ADVEOF		IF SO, ABORT WITH ERROR
	PSHS	X		SAVE ADDRESS
	TFR	X,Y		COPY FOR ADVANCE
	PSHS	X		SAVE X REG
	LDX	#DLBUF		DELETE LINE BUFFER
FINCR	LDA	,Y+		GET CHARACTER
	STA	,X+		SAVE IN BUFFER
	CMPA	#$0D		TEST FOR END OF LINE
	BNE	FINCR		KEEP LOOKING
	PULS	X		RESTORE X
MOVBAC	LDA	,Y+		GET CHARACTER
	STA	,X+		COPY BACK TO LINE
	BPL	MOVBAC		KEEP GOING TILL WE FIND
	PULS	X		GET X VALUE BACK
	LBRA	DELCR		REFRESH AND FIX IF END OF FILE
*
* HELP COMMAND, DISPLAY THE FILE [SYSTEM]ED.HLP
*
CMD8	DECA			TEST FOR HELP
	BNE	CMD9		NO, TRY NEXT COMMAND
	LDD	XPOS		GET CURSOR POSITIONS
	PSHS	A,B		SAVE CURSOR ADDRESS
	LDY	#HLPFIL		HELP FILENAME
	SSR	10		GET FILENAME
	LBSR	CLS		CLEAR SCREEN
	LDU	#SNARF
	SSR	55		OPEN FILE
	BNE	WAIHLP		IF ERROR, GO BACK
DISHLP	SSR	59		GET A CHARACTER
	BNE	WAIHLP		END OF HELP DISPLAY
HDISP	SSR	33		DISPLAY
	CMPA	#$0D		TEST FOR NEW LINE
	BNE	DISHLP		DISPLAY NEXT CHARACTER
	LDA	#$0A		GET LINEFEED
	BRA	HDISP		DISPLAY WITH NEXT
* WAIT FOR A CHARACTER BEFORE PROCEDING
WAIHLP	LDX	#WAIMSG		MESSAGE
	LBSR	ERRMSG		DISPLAY MESSAGE
	LBSR	GETKEY		GET A CHARACTER
	LBSR	CLS		NEW SCREEN
	PULS	A,B		GET CURSOR POSITION BACK
	STD	XPOS		RESAVE POSITION
	LBRA	REFSCR		REFRESH SCREEN
*
* TOP OF FILE COMMAND
*
CMD9	DECA			TEST FOR TOF COMMAND
	BNE	CMD10		IF NOT, TRY NEXT
TOPF	LDX	#TEXT		POINT TO TEXT
	CLR	YPOS		MOVE TO TOP OF SCREEN
	CLR	XPOS		ZERO 'X' POSITION
	BRA	TOPSCR		AND SAVE TOP ADDRESS
*
* BOTTOM OF FILE COMMAND
*
CMD10	DECA			TEST FOR BOT OF FILE KEY
	BNE	CMD11		NO, TRY NEXT COMMAND
	BSR	FNDEOF		FINE END OF FILE
	STX	TXTPOS		SET SCREEN POSITION
	LBSR	PGGO		SKIP BACK UP SCREEN
	LDA	TEMP		GET # LINES
	STA	YPOS		SET 'Y' POSITION
	RTS
* LOCATES END OF FILE. (IN X)
FNDEOF	LDX	TXTPOS		START AT TOP
FNDBOT	LDA	,X+		GET POSITION
	BPL	FNDBOT		KEEP LOOKING
	RTS
*
* UNDELETE LINE
*
CMD11	DECA			TEST FOR UNDELETE
	BNE	CMD12		NO, TRY NEXT
	LBSR	LOCADR		FIND OUR ADDRESS
	LDY	#DLBUF		GET ADDRESS OF BUFFER
	CLRB			START WITH ZERO CHARACTER
INS1	INCB			+1 TO GO
	LDA	,Y+		GET CHARACTER
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BNE	INS1		IF NOT, KEEP LOOKING
	CLRA			SET ZERO HIGH BYTE
	LBSR	INSMUL		GET MULTIPLE SPACES
	PSHS	X		SAVE OUR POSITION
	LDY	#DLBUF		GET LINE BUFFER AGAIN
INS2	LDA	,Y+		GET CHARACTER
	STA	,X+		SAVE IN MEMORY
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BNE	INS2		IF NOT, KEEP LOOKING
	PULS	X		RESTORE OUR POSITION
	LBRA	REFBOT		NEW SCREEN
*
* DELETE TO BUFFER COMMAND
*
CMD12	DECA			TEST FOR SNARF
	BNE	CMD13		NO, TRY NEXT
	LBSR	DELSN		DELETE LINE
	LDY	#DLBUF		GET DELETE BUFFER
	LDX	SNRPOS		GET POSITION
SAVL	LDA	,Y+		GET CHARACTER FROM DELETE BUFFER
	STA	,X+		SAVE IN POSITION
	CMPA	#$0D		TEST FOR END
	BNE	SAVL		SAVE WHOLE LINE
	LDA	#$FF		GET END OF FILE
	STA	,X		SAVE IN BUFFER
	STX	SNRPOS		RESAVE SNARF POSITION
	RTS
*
* INSERT BUFFER COMMAND
*
CMD13	DECA			TEST FOR UNSNARF
	BNE	CMD14		NO, TRY ANOTHER
	LBSR	LOCADR		FIND OUR ADDRESS
	LDY	#SNARF		GET ADDRESS OF BUFFER
	PSHS	X		SAVE OUR POSITION
	LDX	#$FFFF		START WITH -1 CHARACTERS
SINS1	LEAX	1,X		+1 TO GO
	LDA	,Y+		GET CHARACTER
	BPL	SINS1		IF NOT, KEEP LOOKING
	TFR	X,D		SWAP TO D
	LDX	,S		GET X  VALUE BACK
	LBSR	INSMUL		GET MULTIPLE SPACES
	LDY	#SNARF		GET LINE BUFFER AGAIN
SINS2	LDA	,Y+		GET CHARACTER
	BMI	ENDSN		END OF SNARF
	STA	,X+		SAVE IN MEMORY
	BRA	SINS2		IF NOT, KEEP LOOKING
ENDSN	LDD	#SNARF		SNARF BUFFER ADDRESS
	STD	SNRPOS		RESET POINTER
	PULS	X		RESTORE OUR POSITION
	LBRA	REFBOT		NEW SCREEN
*
* RESET BUFFER COMMAND
*
CMD14	DECA			TEST FOR RESET
	BNE	CMD15		NO, TRY NEXT
	LDD	#SNARF		SNARF NUFFER ADDRESS
	STD	SNRPOS		SAVE POSITION
	LDX	#RESMSG		BUFFER RESET MESSAGE
	LBRA	ERRMSG		DISPLAY MESSAGE
*
* ADVANCE TO END OF LINE
*
CMD15	DECA			TEST FOR 'DOS'
	BNE	CMD16		NO, TRY NEXT
	LBSR	LOCADR		GET OUR ADDRESS
	CMPA	#$0D		ARE ALREADY AT END?
	BNE	FEOL		NO, SKIP IT
	LBSR	ALINE		ADVANCE A LINE
	LBSR	LOCADR		FIND OUR ADDRESS
FEOL	LDA	,X+		GET ADDRESS
	BMI	EOLFND		IF EOF, STOP
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BEQ	EOLFND		IF SO, GO BACK
	INC	XPOS		ADVANCE ONE POSITION
	BRA	FEOL		KEEP LOOKING
EOLFND	RTS
*
* FIND COMMAND
*
CMD16	DECA			TEST FOR FIND
	BNE	CMD17		NO, TRY NEXT COMMAND
	LBSR	CLRCMD		BOTTOM LINE, CLEARED
	SSR	24		ISSUE MESSAGE
	FCCZ	'Search for: '
	LBSR	GETCMD		GET INPUT LINE
GOLOOK	LBSR	LOCADR		FIND OUT WHERE WE ARE
LOOK	LDY	#INPBUF		POINT TO SEARCH BUFFER
	LDA	,X+		GET CHARACTER AND ADVANCE
	BMI	NOFIND		DIDN'T FIND IT
	PSHS	X		SAVE OUR POSITION
TST2	LDA	,Y+		GET CHARACTER FROM BUFFER
	BMI	FOUND		IF SO, WE FOUND
	CMPA	,X+		TEST AGAINST SOURCE
	BEQ	TST2		LOOKS LIKE THIS IS IT
	PULS	X		RESTORE POINTER
	BRA	LOOK		TRY THIS LOCATION
FOUND	PULS	X		RESTORE POSITION
	CLR	XPOS		CLEAR CURSOR POSITION
	CLR	YPOS		TO TOP OF SCREEN
BAKL	TFR	X,D		SWAP TO US
	CMPD	#TEXT		ARE WE THERE
	BEQ	OKGO		OK
	INC	XPOS		MOVE OVER ONE
	LDA	,-X		GET CHARACTER
	CMPA	#$0D		TEST FOR AT START
	BNE	BAKL		NO, SAY SO
	LEAX	1,X		ADVANCE AGAIN
	DEC	XPOS		FIX BECAUSE WE WERE OVER
OKGO	TFR	X,D		COPY TO D
	CMPD	TXTPOS		ARE WE ALREADY THERE?
	BEQ	UNCMD		NO NEED TO UPDATE SCREEN
	STX	TXTPOS		SAVE TEXT POSITION
	LBRA	REFSCR		REFRESH SCREEN
NOFIND	LDX	#SNFMSG		STRING NOT FOUND MESSAGE
	LBRA	ERRMSG		DISPLAT MESSAGE
*
* FIND NEXT COMMAND
*
CMD17	DECA			IS IT FINDNEXT?
	BEQ	GOLOOK		IF SO, DO IT
*
* INSERT TAB AS SPACES
*
CMD18	DECA			IS IT TAB?
	BNE	UNCMD		NO, SKIP IT
	LBSR	LOCADR		FIND CURRENT ADDRESS
	CLRB			START WITH ZERO SPACES
FNTAB	INC	XPOS		ADVANCE TO NEXT POSITION
	INCB			INDICATE ONE SPACE
	LDA	XPOS		GET X POSITION
	ANDA	#7		TEST FOR AT A TAB STOP
	BNE	FNTAB		IF NOT, KEEP GOING
	PSHS	B		SAVE COUNT ON STACK
	BSR	INSMUL		INSERT CHARACTERS
	PULS	B		RESTORE COUNT
	LDA	#' '		GET SPACE
INSP	STA	,X+		SAVE IN MEMORY
	SSR	33		DISPLAY SPACE
	DECB			REDUCE COUNT
	BNE	INSP		KEEP INSERTING
	LBRA	REFLIN		REFRESH LINE
* COMMAND WAS NOT RECOGNISED
UNCMD	RTS
*
* INSERTS ONE CHARACTER SPACE INTO THE TEXT POINTED TO BY X
*
INSCHR	LEAY	1,X		+1 FOR SECOND INSERT POINTER
	LDB	,X		GET CHARACTER
	BMI	INSEOF		END OF FILE INSERT
INSLP	LDA	,Y		GET CHARACTER FROM BEFORE
	STB	,Y+		SAVE AGAIN
	TFR	A,B		COPY TO B FOR LATER
	BPL	INSLP		IF NOT, KEEP GOING
INSEOF	STB	,Y		SET EOF IN TEXT
	RTS
*
* INSERTS NUMBERS OF CHARACTER IN B IN LINE POINTED TO BY X
*
INSMUL	PSHS	X,U		SAVE X REGISTER
FINEF	TST	,X+		GET CHARACTER
	BPL	FINEF		KEEP LOOKING
	LEAU	D,X		POINT TO END PLUS NUMBER OF CHARS NEEDED
	TFR	X,D		COPY TO ACC
	SUBD	,S		CONVERT TO SIMPLE NUMBER
	TFR	D,Y		SAVE IN Y FOR COUNT
MOVL	LDA	,-X		GET CHARACTER
	STA	,-U		SAVE FARTHER IN LINE
	LEAY	-1,Y		BACKUP COUNT
	BNE	MOVL		AND KEEP GOING
	PULS	X,U,PC		RESTORE ADDRESS AND RETURN
*
* DELETES ONE CHARACTER FROM TEXT POINTED TO BY X
*
DELCHR	LDA	,X		GET CHARACTER WE ARE DELETING
	BMI	DELEOF		SPECIAL CASE
	PSHS	A,X		SAVE FOR LATER REFERENCE
DELLP	LDA	1,X		GET CHARACTER FROM SOURCE
	STA	,X+		SAVE IN TEXT
	BPL	DELLP		IF NOT, CONTINUE DELETING
	PULS	A,X,PC		RESTORE REGISTERS
*
* REFRESH BOTTOM OF SCREEN FROM CURRENT LOCATION
*
REFBOT	LDD	XPOS		GET POSITION
	PSHS	A,B		SAVE FOR LATER REFERENCE
	TFR	X,Y		COPY OUR POSITION
	LDB	#NLINES		LINES/SCREEN
	SUBB	YPOS		FIGURE OUT HOW MANY WE HAVE LEFT
	LBSR	DISTXT		REFRESH BOTTOM OF SCREEN
	PULS	A,B		RESTORE REGISTERS
	STD	XPOS		RESTORE CURSOR POSITION
DELEOF	RTS
*
* REFRESH CURRENT LINE
*
REFLIN	LDA	,X+		GET CHARACTER FROM SOURCE
	BMI	REFL1		DISPLAY END OF FILE
	CMPA	#$0D		TEST FOR END OF LINE
	BEQ	REFL2		OF SO, THATS IT
	LBSR	OUTPRT		OUTPUT IF DISPLAYABLE
	BRA	REFLIN		KEEP GOING TILL END OF LINE
REFL1	LDA	#$0D		GET CR
	STA	-1,X		INSERT CR
	LDA	#$FF		GET EOF MARKER
	STA	,X		WRITE IN TEXT
	BSR	REFL2		CLEAR END OF LINE
	SSR	22		NEWLINE
	LDX	#EOFMSG		GET MESSAGE
	SSR	23		DISPLAY
REFL2	LBRA	CLEOL		CLEAR REMAINDER
*
* ADVANCES ONE CHARACTER
*
ADVCHR	LBSR	LOCADR		FIND OUT POSITION
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BEQ	SKPLIN		SKIP TO NEXT LINE
	TSTA			TEST FOR END OF FILE
	BMI	AEOFG		INDICATE ERROR
	INC	XPOS		ADVANCE ONE POSITION
	RTS
SKPLIN	CLR	XPOS		INDICATE WE ARE AT BEGINNING OF LINE
*
* ROLLS SCREEN FORWARD ONE LINE
*
ADVLIN	LBSR	LOCLIN		FINDOUR LINE
	LDA	,X		GET CHARACTER
	BMI	AEOFG		IF SO, DISPLAY MESSAGE
	LDA	YPOS		GET Y POSITION
	CMPA	#NLINES-1	TEST FOR AT END
	BGE	SROLLD		IF SO, ROLL SCREEN
NXTL	LDA	,X+		GET CHARACTER
	BMI	ADVEOF		IF SO, GET UPSET
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BNE	NXTL		IF NOT, THATS ALL
	INC	YPOS		SKIP TO NEXT LINE
	BRA	POSLIN		SKIP TO CHARACTER ON LINE
SROLLD	LDY	TXTPOS		GET POSITION
LOKLIN	LDA	,Y+		GET CHARACTER FROM LINE
AEOFG	BMI	ADVEOF		ADVANCE BEYOND END OF FILE
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BNE	LOKLIN		KEEP LOOKING
	STY	TXTPOS		RESAVE TEXT POSITION
	SSR	24		ISSUE MESSAGE
	FCB	'D'-$40		SCROLL SCREEN
	FCB	$10,$1F+NLINES,' ' MOVE TO SECOND LAST
	FCB	'W'-$40,0	CLEAR TO END
	LDB	#NLINES-1	# LINES TO MOVE
ADLN	LDA	,Y+		GET LINE
	BMI	POSLIN		NO END MESSAGE
	CMPA	#$0D		TEST FOR NEW LINE
	BNE	ADLN		KEEP LOOKING
	DECB			REDUCE COUNT
	BNE	ADLN		KEEP LOOKING
	TFR	Y,X		POINT AT LINE TO DISPLAY
	LDA	,X		GET CHARACTER
	BPL	NOAEOF		END OF FILE WHILE ADVANCEING
EOFERR	LDA	#$0D		BACK TO START OF LINE
	SSR	33		DISPLAY
	LDX	#EOFMSG		POINT TO END OF FILE MESSAGE
	SSR	23		DISPLAY
	BRA	POSLIN		KEEP DISPLAYING
NOAEOF	LDA	,X+		GET CHARACTER FROM TEXT
	LBSR	OUTPRT		DISPLAY IF OK
	CMPA	#$0D		TEST FOR <CR>
	BNE	NOAEOF		IF NOT, KEEP GOING
* POSITION CURSOR ON LINE FOLLOWING
POSLIN	BSR	LOCLIN		FIND OUR LINE
	TST	CURFLG		TEST FOR SPECIAL CURSOR POSITION
	BEQ	NORPOS		NORMAL MODE
	LDB	OLDPOS		GET OLD POSITION
	BRA	SPCPOS		SPECIAL POSITION
NORPOS	LDB	XPOS		GET X POSITION
SPCPOS	BEQ	THER1		ALREADY THERE
	CLR	XPOS		SET TO ZERO
OKMV	LDA	,X+		GET CHARACTER
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BEQ	THER1		ALREADY THERE
	TSTA			TEST FOR $FF (EOF)
	BMI	THER1		THATS ALL FOLKS
	INC	XPOS		ADVANCE ONE LOCATION
	DECB			REDUCE OUR COUNT
	BNE	OKMV		KEEP LOOKING
THER1	RTS
ADVEOF	LDX	#OUTERR		ERROR MESSAGE
	LBRA	ERRMSG		DISPLAY
*
* BACKS UP ONE CHARACTER
*
BAKCHR	LBSR	LOCLIN		LOCATE OUR POSITION
	LDB	XPOS		GET X POSITION
	ABX			OFFSET INTO LINE
	CMPX	#TEXT		TEST FOR TEXT SPACE
	BLS	ADVEOF		ERROR
	LDA	,-X		GET CHARACTER FROM BEHIND
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BEQ	BKUPL		BACKUP A LINE
	DEC	XPOS		BACKUP IN SOURCE
	RTS
BKUPL	LDA	#127		X POSITION IS VERY HIGH
	STA	XPOS		SET POSITION
*
* ROLLS SCREEN BACKWARD ONE LINE
*
BAKLIN	LDA	YPOS		TEST Y POSITION
	BEQ	SROLLU		ROLL SCREEN UP
	DEC	YPOS		BACKUP IN SCREEN
	BRA	POSLIN		POSITION IN LINE
* SCROLL SCREEN UPWARD
* USE THIS VERSION FOR TTYS WHICH SUPPORT BACKWARD SCROLLING
SROLLU	LDY	TXTPOS		GET OUR POSITION
	LEAY	-1,Y		BACKUP PAST END OF LAST LINE
SROLU1	LDA	,-Y		GET CHARACTER FROM LINE
	CMPA	#$0D		TEST FOR PREVIOUS LINE
	BEQ	SROLU2		IF SO, WE HAVE IT
	TFR	Y,D		COPY TO D
	CMPD	#TEXT-1		TEST FOR AT LOCATION 1
	BEQ	SROLU2		AT TOP LINE
	BLO	ADVEOF		INDICATE ERROR
	BRA	SROLU1		KEEP LOOKING
SROLU2	LEAY	1,Y		ADVANCE TO PROPER PLACE
	STY	TXTPOS		SAVE TEXT POSITION
	LDA	#'E'-$40	CODE TO SCROLL BACKWARDS
	SSR	33		SCROLL SCREEN
	LBSR	CLRCMD		CLEAR COMMAND FIELD
	LDA	#'Y'-$40	CODE TO HOME CURSOR
	SSR	33		HOME CURSOR
	TFR	Y,X		POINT AT LINE TO DISPLAY
	BRA	NOAEOF		DISPLAY LINE AND POSITION CURSOR
* USE THIS VERSION FOR TTYS NOT SUPPORTING BACKWARD SCROLL
*SROLLU	LDB	#NLINES/2	GET # LINES
*	LBSR	PGBAK		PERFORM BACK PAGE
*	LDA	TEMP		GET # LINES MOVED
*	DECA			GOTO ONE HIGHER LINE
*	BMI	POSLIN		NO LINES MOVED
*	STA	YPOS		SET POSITION
*	BRA	POSLIN		POSITION CURSOR
*
* LOCATES CURRENT ADDRESS
*
LOCADR	BSR	LOCLIN		GET LINE ADDRESS
	LDB	XPOS		GET HORIZ
	ABX			ADD TO ADDRES
	LDA	,X		GET CHARACTER FROM LINE
	RTS
*
* LOCATES START OF LINE CURSOR IS ONE
*
LOCLIN	LDX	TXTPOS		START AT TOP OF SCREEN
	LDB	YPOS		Y POSITION
	BEQ	THERE		ALREADY THERE
LOCA1	LDA	,X+		GET CHARACTER
	CMPA	#$0D		TEST FOR NEXT
	BNE	LOCA1		KEEP LOOKING
	DECB			REDUCE LINE
	BNE	LOCA1		KEEP LOOKING TILL WE GET THERE
THERE	RTS
*
* REFERESHES THE TERMINAL SCREEN
*
REFSCR	LDY	TXTPOS		GET OUR POSITION
	LDA	#'Y'-$40	HOME CURSOR MESSAGE
	SSR	33		DISPLAY
	LDB	#NLINES		# LINES TO DISPLAY
DISTXT	LDA	,Y+		GET CHARACTER FROM TEXT
	BMI	DISEOF		IF SO, INDICATE END OF FILE
	CMPA	#$0D		TEST FOR CARRIAGE RETURN
	BEQ	DISCR		DISPLAY CARRIAGE RETURN
	LBSR	OUTPRT		OUTPUT AS DISPLAYABLE CHARACTER
	BRA	DISTXT		KEEP DISPLAYING
DISCR	LBSR	CLEOL		CLEAR END OF LINE
	SSR	22		NEW LINE
	DECB			REDUCE COUNT
	BNE	DISTXT		KEEP DISPLAYING
	BRA	CURHOM		HOME CURSOR AND RETURN
DISEOF	LDX	#EOFMSG		END OF FILE MESSAGE
	SSR	23		DISPLAY
CURHOM	LDA	#'W'-$40	CLEAR TO END OF SCREEN
OUT4	SSR	33		DISPLAY MESSAGE
	RTS
*
* DISPLAYS CHARACTER ON SCREEN IF IT IS PRINTABLE
*
OUTPRT	CMPA	#$0D		TEST FOR <CR>
	BEQ	OUT4		IF SO, ALLOW IT TO PRINT
OUTDIF	PSHS	A,X		SAVE REGS
	CMPA	#$7F		TEST FOR DELETE
	BEQ	OUT2		SPECIAL DELETE NOTATION
	CMPA	#' '		TEST FOR NON-PRINT
	BLT	OUT3		OK TO DISPLAY
OUT1	SSR	33		DISPLAY CHAR
	PULS	A,X,PC
OUT2	LDA	#'-'-'@'	GET '-' FOR INVERSE
OUT3	ADDA	#'@'		CHANGE TO INDICATOR
	STA	>INVCHR		DISPLAY
	LDX	#INVON		OUTPUT MESSAGE
	SSR	23		DISPLAY
	PULS	A,X,PC		GET CHARACTER BACK
*
* GETS AN INPUT LINE FROM THE TERMINAL
*
GETCMD	LDY	#INPBUF		POINT TO SEARCH BUFFER
	CLRB			CHARACTER COUNT
GETC1	LBSR	GETKEY		GET A KEY
	STA	,Y+		SAVE IN BUFFER
	BMI	GETC2		END OF LINE
	BSR	OUTDIF		OUTPUT CHARACTER
	INCB			KEEP TRACK OF HOW MANY CHARACTERS WE HAVE
	BRA	GETC1		KEEP READING
GETC2	CMPA	#$88		TEST FOR DELETE
	BNE	CLRCMD		END OF INPUT
	DECB			REDUCE COUNT
	BMI	GETCMD		IF SO, START AGAIN
	LEAY	-2,Y		BACKUP ONE CHARACTER
	SSR	24		DISPLAY MESSAGE
	FCB	8,' ',8,0	DELETE CHARACTER BY WRITING OVER IT
	BRA	GETC1		KEEP GETTING CHARACTERS
CLRCMD	SSR	24		ISSUE MESSAGE
	FCB	$10,' '+NLINES,' ',0
CLEOL	SSR	24		ISUE MESSAGE
	FCB	'V'-$40,0
	RTS
*
* CONVERT BUFFER CONTENTS TO UPPERCASE, TERMINATED WITH CR
*
CNVBUF	LDY	#INPBUF		POINT AT BUFFER
CNVBF1	LDA	,Y		GET CHARACTER FROM BUFFER
	BMI	LSTBUF		LAST CHARACTER IN BUFFER
	CMPA	#$61		TEST FOR LOWER CASE
	BLT	NOCHG		IF NOT, IT'S OK
	ANDA	#$DF		CONVERT TO UPPER
NOCHG	STA	,Y+		SAVE AND INC
	BRA	CNVBF1		KEEP CONVERTING
LSTBUF	LDA	#$0D		GET CARRIAGE RETURN
	STA	,Y		SAVE IN MEMORY
	LDY	#INPBUF		POINT AT BUFFER
	RTS
*
* CLEARS SCREEN
*
CLS	PSHS	A		SAVE REGISTERS
	LDA	#'X'-$40	CLEAR SCREEN
	SSR	33		DISPLAY
	CLR	XPOS		ZERO X POSITION
	CLR	YPOS		ZERO Y POSITION
	PULS	A,PC		RESTORE REGISTERS AND RETURN
*
* POSITIONS CURSOR
*
CURPOS	PSHS	A,B		SAVE REGISTERS
	LDA	#'P'-$40	GET ESCAPE CHARACTER
	SSR	33		OUTPUT
	LDA	YPOS		GET VERT VALUE
	ADDA	#' '		OFFSET
	SSR	33		DISPLAY
	LDA	XPOS		HORZ. POSITION
	ADDA	#' '
	SSR	33		DISPLAY
	PULS	A,B,PC		RESTORE REGISTERS AND RETURN
*
* KEYBOARD INPUT ROUTINE, EVALUATES INPUT CHARACTERS, LOOKING FOR ESCAPE
* SEQUENCES, AND RETURNS A RESULT AS FOLLOWES:
*
*   $80 - CURSOR UP COMMAND.		$81 - CURSOR DOWN COMMAND
*   $82 - CURSOR FORWARD COMMAND.	$83 - CURSOR BACKWARD COMMAND
*   $84 - ADVANCE LINE COMMAND.		$85 - BACKUP LINE COMMAND
*   $86 - TOGGLE INSERT MODE.		$87 - DELETE CHARACTER COMMAND
*   $88 - DELETE CHARACTER BEFORE CURSOR
*   $89 - EXIT EDITOR.			$8A - PAGE FORWARD
*   $8B - PAGE BACKWARD.		$8C - DELETE TO END OF LINE
*   $8D - KEYPAD HELP.			$8E - GO TO TOP OF FILE
*   $8F - GO TO BOTTOM OF FILE.		$90 - UNDELETE LINE
*   $91 - DELETE LINE TO BUFFER.	$92 - UNDELETE BUFFER
*   $93 - RESET BUFFER POINTER.		$94 - ADVANCE TO END OF LINE
*   $95 - FIND KEY.			$96 - FINDNEXT KEY
*   $97 - INSERT SPACES TO NEXT TAB STOP
*
* CONTROL CODES OTHER THAT CARRIAGE-RETURN OR TAB ARE NOT PASSED BACK TO
* THE CALLING ROUTINE UNLESS THEY ARE PRECEDED BY A <ESCAPE>
*
GETKEY	PSHS	X		SAVE REGISTERS
KEYIN	SSR	34		GET KEYBOARD INPUT CHARACTER
	CMPA	#' '		TEST FOR OTHER CHARACTERS
	BLO	SPCKEY		IF SO, FORGET ANY CONTROL CODES
	CMPA	#$7F		SPECIAL?
	BHS	SPCKEY		YES
NORCHR	PULS	X,PC
SPCKEY	CMPA	#$1B		ESCAPE?
	BNE	SPC0
	SSR	34		GET KEY
	PULS	X,PC		GO HOME
SPC0	LDX	#CURTAB
SPC1	TST	,X		END OF TABLE?
	BEQ	KEYIN		IGNORE
	CMPA	,X++		THIS ONE?
	BNE	SPC1		NO
	LDA	-1,X
	PULS	X,PC
*
* KEYCODE CONVERSION TABLE
*
* CURSOR MOVEMENT KEYS
*
CURTAB	FCB	'Z'-$40,$80	UP
	FCB	'J'-$40,$81	DOWN
	FCB	'U'-$40,$82	RIGHT
	FCB	'H'-$40,$83	LEFT
	FCB	'J'-$40+$80,$84	ADV LINE
	FCB	'Z'-$40+$80,$85	BAK LINE
	FCB	'H'-$40+$80,$85	ANOTHER BAK LINE
	FCB	'1'+$80,$86	TOGGLE INS
	FCB	$FF,$87		DEL CHR
	FCB	$7F,$88		DELETE PREVIOUS
	FCB	$0D+$80,$89	COMMAND KEY
	FCB	$04,$8A		FORWARD
	FCB	$05,$8B		REVERSE
	FCB	'2'+$80,$8C	DEL TO END OF LINE
	FCB	'0'+$80,$8D	HELP (CTRL SPACE)
	FCB	$85,$8E		TOF
	FCB	$84,$8F		EOF
	FCB	'3'+$80,$90	UNDELETE
	FCB	'4'+$80,$91	DELETE TO BUFFER
	FCB	'5'+$80,$92	UNDELETE BUFFER
	FCB	'6'+$80,$93	RESET BUFFER
	FCB	'U'-$40+$80,$94	ADVANCE TO EOL
	FCB	'7'+$80,$95	FIND
	FCB	'8'+$80,$96	FIND-NEXT
	FCB	$09,$97		TAB-ADVANCE TO TAB STOP
	FCB	$0D,$0D		ALLOW CR
	FCB	0
*
* COMMAND TABLE
*
CMDTAB	FCB	$84		REQUIRE AT LEAST 'QUIT'
	FCC	'QUIT'
	FCB	$82		REQUIRE AT LEAST 'EX'
	FCC	'EXIT'
	FCB	$82		REQUIRE AT LEAST 'AP'
	FCC	'APPEND'
	FCB	$82		REQUIRE AT LEAST 'SA'
	FCC	'SAVE'
	FCB	$83		REUQIRE AT LEAST 'TAB'
	FCC	'TABS'
	FCB	$83		REQUIRE AT LEAST 'SPA'
	FCC	'SPACES'
	FCB	$82		REQUIRE AT LEAST 'DO'
	FCC	'DOS'
	FCB	$80		INDICATE END OF TABLE
*
* MESSAGES
*
NEWMSG	FCCZ	'New file'
OUTERR	FCCZ	'File limit reached.'
WAIMSG	FCCZ	'Press any Key to Continue'
SNFMSG	FCCZ	'String not found'
RESMSG	FCCZ	'Buffer reset'
ICMMSG	FCCZ	'Unknown Command'
INSON	FCCZ	'Insert on'
INSOFF	FCCZ	'Insert off'
HLPFIL	FCCZ	'[SYSTEM]ED.HLP'	HELP FILE
EOFMSG	FCCZ	'[EOF]'			END OF FILE MESSAGE
INVON	FCB	'N'-$40			TURN ON INVERSE VIDEO
INVCHR	FCB	0			CHARACTER TO INVERSE
INVOFF	FCB	'O'-$40,0		TURN OFF INVERSE VIDEO