*
* SYSTEM MEMORY LOCATIONS FOR USE BY APPLICATION PROGRAMS
*
OSRAM	EQU	$2000		USER APPLICATION RAM STARTS HEDE
OSEND	EQU	$DBFF		LAST LOCATION OF USER (NON-SYSTEM) RAM
OSUTIL	EQU	$D000		RAM FOR UTILITY PROGRAM USAGE
*
*
* CHKDISK: File system allocaton and disk media check.
*
* Copyright 1983-2005 Dave Dunfield
* All rights reserved.
*
DIRLOC	EQU	0		DIRECTORY LOCATION
LNKLOC	EQU	1		LINK SECTOR LOCATION
* DIRECTORY STRUCTURE
	ORG	0
DPREFIX	RMB	8		PREFIX
DNAME	RMB	8		FILENAME
DTYPE	RMB	3		FILE TYPE
DDADR	RMB	2		DISK ADDRESS
DRADR	RMB	2		RUN ADDRESS
DATTR	RMB	1		FILE ATTRIBUTES
*
	ORG	OSRAM		PUT IT HERE
CHKDISK	CMPA	#'?'		HELP REQUEST?
	BNE	QUAL		NO, DO FSCK
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'Use: CHKDISK[/NOALLOC/NOMEDIA/QUIET/REBUILD] <drive>'
ABORT	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	0		SYSTEM REQUEST NUMBER
* EVALUATE QUALIFIERS
QUAL	LDA	,Y		GET CHAR
	CMPA	#'/'		QUALIFIER?
	BNE	MAIN		NO QUALIFIERS
	LDX	#QTABLE		PT TO TABLE
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	18		SYSTEM REQUEST NUMBER
	CMPB	#QMAX		OVER?
	BHS	QERR		INVALID
	LDX	#QFLAGS		PT TO FLAGS
	CLR	B,X		ZAP IT
	BRA	QUAL		CONTINUE
QERR	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	/Invalid qualifier: '/
	LDA	,Y+		GET CHAR
QERR1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	5		SYSTEM REQUEST NUMBER
	BEQ	QERR2		END, EXIT
	CMPA	#'/'		NEXT QUALIFIER
	BNE	QERR1		ITS OK
QERR2	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	/'/
	LDA	#1		INDICATE INVALID OPERAND
	BRA	ABORT		ERROR
*
* PERFORM TESTS
*
MAIN	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	88		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	16		SYSTEM REQUEST NUMBER
	BNE	ABORT		INVALID OPERAND
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	76		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	82		SYSTEM REQUEST NUMBER
	STD	>DRVSIZ		SAVE DRIVE SIZE
	SUBD	#1		ACTUAL HIGEST SECTOR
	INCA			(D/256+1 FOR PARTIAL)
	STA	>LNKSIZ		SAVE IT
* FIRST, LOAD IN LINK SECTORS
	LDX	#WRKSPC		PT TO WORK AREA
	LBSR	LDLINK		LOAD LINK SECTS
	STX	>DATSPC		SAVE PTR TO IT
	LBSR	LDLINK		READ AGAIN
* PERFORM ALLOCATION TABLE CHECK
	LDA	>ALLOC		DO ALLOCATION
	LBEQ	NOALL		NO
	LDA	>QUIET		BEING QUIET?
	BEQ	MAIN1		YES
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'Checking Allocation...'
* RELEASE DIRECTORY SECTORS
MAIN1	LDD	#DIRLOC		GET DIR LOC
	LBSR	UNCHAIN		RELEASE IT
* RELEASE LINK SECTORS
	INC	>SECTYP		INDICATE DOING LINKS
	LDD	#LNKLOC		GET LINK LOCATION
	LBSR	UNCHAIN		RELEASE LINKS
* READ DIRECTORY, RELEASING ALL FILE CHAINS
	INC	>SECTYP		ANDICATE DOING FILES
	LDD	#DIRLOC		PT TO DIRECTORY LOCATION
MAIN2	STD	>DIRSEC		SAVE PTR
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	84		SYSTEM REQUEST NUMBER
	TFR	X,D		GET ADDRESS
	ADDD	#512		CALCULATE END
	STD	>TEMP		SAVE INDICATOR
MAIN3	LDA	,X		FILE IN USE?
	BEQ	MAIN4		YES, RELEASE IT
* FILE EXISTS, RELEASE ITS LINKS
	LDD	DDADR,X		GET DISK ADDRESS
	LBSR	UNCHAIN		RELEASE SECTOR CHAIN
MAIN4	LEAX	32,X		NEXT ENTRY
	CMPX	>TEMP		OVER?
	BLO	MAIN3		NO, KEEP LOOKING
	JSR	TQUIT		TEST FOR EXIT
	LDD	>DIRSEC		GET CURRENT SECTOR
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	77		SYSTEM REQUEST NUMBER
	BEQ	MAIN5		END OF FILE, STOP
	CMPD	#0		INSURE DIRECTORY IS NOT CORRUPT
	BNE	MAIN2		CONTINUE
* EXAMINE TABLE FOR ALLOCATED/UNUSED BLOCKS
MAIN5	LDX	#WRKSPC		PT TO WORK AREA
	LDU	>DATSPC		GET DATA AREA
	LDY	#0		START WITH SECTOR ZERO
	STY	>TEMP		ZERO COUNTERS
EXAM	LDD	,X		IS IT FREE
	BEQ	EXAM2		YES
	CLR	>FLAG		INDICATE CHANGED
	CLR	,U		ZERO LOW
	CLR	1,U		ZERO HIGH
	LDD	>ERRORS		GET TOTAL
	ADDD	#1		ADVANCE
	STD	>ERRORS		RESAVE
	LDA	>TEMP		GET FLAG
	BNE	EXAM1		ALREADY SET
	DEC	>TEMP		SET FLAG
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'Blocks allocated, but not used:'
EXAM1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	21		SYSTEM REQUEST NUMBER
	TFR	Y,D		GET SECTOR ID
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	27		SYSTEM REQUEST NUMBER
	INC	>TEMP+1		ADVANCE COUNTER
	LDA	>TEMP+1		GET VALUE
	BITA	#7		PAST END?
	BNE	EXAM2		NO
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	22		SYSTEM REQUEST NUMBER
EXAM2	LEAY	1,Y		NEXT SECTOR
	LEAX	2,X		NEXT RAM LOC
	LEAU	2,U		NEXT IN REAL SECTORS
	CMPY	>DRVSIZ		OVER?
	BLO	EXAM		NO, TRY AGAIN
	LDA	>TEMP+1		GET COUNT
	BITA	#7		NEW LINE
	BEQ	EXAM3		NOT NESSARY
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	22		SYSTEM REQUEST NUMBER
* HAVE REPORTED THEM ALL
EXAM3	LDA	>QUIET
	BEQ	NOALL		BE QUIET
	LDD	>ERRORS		GET TOTAL
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	26		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	' allocation error(s)'
NOALL	LDA	>MEDIA		DO MEDIA TEST?
	LBEQ	NOMED		NO, NO MEDIA TEST
	LDA	>QUIET
	BEQ	QUI2		BE QUIET
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'Checking Media...'
QUI2	CLRA
	CLRB
	STD	>ERRORS		CLEAR COUNT
MED1	STD	>DIRSEC		SAVE SECTOR ID
	LDX	#WRKSPC		PT TO WORK AREA
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	92		SYSTEM REQUEST NUMBER
	BEQ	MED3		OK, DO NEXT
	LDD	>ERRORS
	ADDD	#1		ADVANCE COUNT
	STD	>ERRORS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'Media error in sector '
	LDD	>DIRSEC		GET SECTOR
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	26		SYSTEM REQUEST NUMBER
	LDD	>DIRSEC		GET SECTOR BACK
	LDX	>DATSPC		ADVANCE
	LSLB
	ROLA			X2 FOT TWO BYTE ENTRIES
	LEAX	D,X		ADVANCE TO IT
	LDD	,X		GET IT
	BNE	MED2		ALLOCATED
	LDD	#$FFFF
	STD	,X		MARK AS BUSY
	CLR	>FLAG		INDICATE CHANGE
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	' - MARKED'
	BRA	MED3		CONTINUE
MED2	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	' - ***ALREADY ALLOCATED***'
MED3	JSR	TQUIT		TEST FOR EXIT
	LDD	>DIRSEC		GET SECTOR
	ADDD	#1		NEXT SECTOR
	CMPD	>DRVSIZ		COMPARE WITH DISK
	LBLO	MED1		KEEP GOING
	LDA	>QUIET		KEEPING QUIET?
	BEQ	NOMED		YES
	LDD	>ERRORS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	26		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	' media error(s)'
* PERFORM UPDATES IF NESSARY
NOMED	LDA	>FLAG		ANY CHANGES
	BNE	NOREB		NO, SKIP IT
	LDA	>REBUILD	REBUILD AUTOMATICALLY?
	BEQ	GOREB		YES
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'Write updated link table?'
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	34		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	33		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	22		SYSTEM REQUEST NUMBER
	ANDA	#$5F		CONVERT
	CMPA	#'Y'		YES?
	BNE	NOREB		DON'T REBUILD
GOREB	LDX	>DATSPC		PT TO AREA
	LBSR	SALINK		SAVE IT OUT
	LDA	>QUIET
	BEQ	NOREB
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'Disk allocation rebuilt'
NOREB	CLRA			ZERO RC
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	0		SYSTEM REQUEST NUMBER
TQUIT	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	35		SYSTEM REQUEST NUMBER
	CMPA	#$1B
	BNE	GORET
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	25		SYSTEM REQUEST NUMBER
	FCCZ	'<Aborted>'
	BRA	NOREB
*
* LOAD DISK LINK TABLE INTO MEMORY(X)
*
LDLINK	LDA	>LNKSIZ		GET SIZE
	STA	>TEMP		SET UP
	LDD	#LNKLOC		START OF LINK SECTORS
LDLNK1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	92		SYSTEM REQUEST NUMBER
	BNE	ABORT1		ERROR
	ADDD	#1		ADVANCE SECTOR ID
	LEAX	512,X		NEXT LOCATION
	DEC	>TEMP		TEST NUMBER
	BNE	LDLNK1		LOAD EM ALL
GORET	RTS
ABORT1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	0		SYSTEM REQUEST NUMBER
*
* SAVE DISK LINK TABLE FROM MEMORY(X)
*
SALINK	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	88		SYSTEM REQUEST NUMBER
	LDA	>LNKSIZ		GET SIZE
	STA	>TEMP		SET UP
	LDD	#LNKLOC		START OF LINK SECTORS
SALNK1	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	93		SYSTEM REQUEST NUMBER
	BNE	ABORT1		ERROR
	ADDD	#1		ADVANCE SECTOR ID
	LEAX	512,X		NEXT LOCATION
	DEC	>TEMP		TEST NUMBER
	BNE	SALNK1		LOAD EM ALL
	RTS
*
* UNCHAIN SECTORS FROM RAM TABLE
*
UNCHAIN	PSHS	X		SAVE 'X'
UNC1	LSLB			X 2
	ROLA			FOR ENTRIES
	ADDD	#WRKSPC		OFFSET TO WORKSPACE
	TFR	D,Y		COPY IT TO INDEX
	LDD	,Y		GET NEXT SECTOR
	BEQ	UNC2		GO LOOSE SOMEHOW
	CLR	,Y		CLEAR LOW
	CLR	1,Y		CLEAR HIGH
	CMPD	>DRVSIZ		IN RANGE?
	BLO	UNC1		YES, ITS OK
	CMPD	#$FFFF		END OF FILE?
	BEQ	UNC7		ALL IS OK
* LINK CHAIN POINTS BEYOND FILESYSTEM
	LDU	#OVRMSG		PT TO MESSAGE
	BRA	UNC3		AND CONTINUE
* LINK CHAIN ENDED WITH ZERO
UNC2	LDU	#ZERMSG		PT TO MESSAGE
UNC3	LDD	>ERRORS
	ADDD	#1		ADVANCE ERROR COUNT
	STD	>ERRORS
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'Allocation error in '
	LDA	>SECTYP		GET SECTOR TYPE
	BNE	UNC4		NO, NOT DIRECTORY
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'DIRECTORY'
	BRA	UNC6
UNC4	DECA			IS IT LINKS?
	BNE	UNC5		NO, NOT LINKS.
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	'LINK TABLE'
	BRA	UNC6
UNC5	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	31		SYSTEM REQUEST NUMBER
UNC6	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	24		SYSTEM REQUEST NUMBER
	FCCZ	', block '
	TFR	Y,D		GET BLOCK ID
	SUBD	#WRKSPC		CONVERT
	LSRA			/2
	RORB			FOR ACTUAL ID
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	26		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	22		SYSTEM REQUEST NUMBER
	TFR	U,X		GET PTR TO MESSAGE
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	23		SYSTEM REQUEST NUMBER
	SWI			SOFTWARE INTERRUPT TO DOS
	FCB	22		SYSTEM REQUEST NUMBER
UNC7	PULS	X,PC		RESTORE & RETURN
ZERMSG	FCCZ	'Chain ends in unallocated (0) link'
OVRMSG	FCCZ	'Link exceeds filesystem bounds'
* QUALIFIER TABLES
QTABLE	FCB	$84
	FCC	'/NOALLOC'
	FCB	$84
	FCC	'/NOMEDIA'
	FCB	$82
	FCC	'/QUIET'
	FCB	$82
	FCC	'/REBUILD'
	FCB	$80
QMAX	EQU	4		# QUALIFIERS
QFLAGS	EQU	*
ALLOC	FCB	$FF		ALLOCATION TEST
MEDIA	FCB	$FF		MEDIA TEST
QUIET	FCB	$FF		QUIET MODE
REBUILD	FCB	$FF		REBUILD MAP
* MISC LOCAL VARIABLES
FLAG	FCB	$FF		INDICATES CHANGED SECTOR
ERRORS	FDB	0		ERROR COUNT FLAG
SECTYP	FCB	0		SECTOR TYPE BEING RELEASED
DIRSEC	RMB	2		CURRENT DIRECTORY SECTOR
DRVSIZ	RMB	2		DISK SIZE (IN SECTORS)
LNKSIZ	RMB	1		SIZE OF LINK MAP (IN SECTORS)
DATSPC	RMB	2		PTR TO DATA RAM
TEMP	RMB	2		TEMPORARY STORAGE
* WORK AREA
WRKSPC	EQU	*
