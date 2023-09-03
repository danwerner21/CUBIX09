;	TITLE	I/O DRIVERS
;***************************************************************
;*     Sample I/O drivers for the CUBIX operating system.      *
;*-------------------------------------------------------------*
;* The drivers are designed to deal with four 6551 type serial *
;* devices, and a 765 type floppy disk controller controlling  *
;* up to four standard 40 track single or double sided floppy  *
;* diskette drives.                                            *
;*-------------------------------------------------------------*
;* Although these drivers are fully functional and may be used *
;* in a port of the system, their primary purpose is intended  *
;* to be as an example of CUBIX to I/O driver interfaceing. As *
;* such the device control side of the drivers (Which will be  *
;* VERY system specific) has been kept very simple and easy to *
;* follow. In particular, no interrupt lines are used, and all *
;* I/O operations are accomplished via software polling.       *
;*-------------------------------------------------------------*
;*             Copyright 1983-2004 Dave Dunfield               *
;***************************************************************
;*
;* CUBIX SYSTEM ADDRESSES
;*
DRIVERS         EQU $E99F		FIRST FREE LOCATION IN ROM
;* $E99F FOR NO VDU, $E09F FOR VDU

;*
;* DISK CONTROL BLOCK FORMAT
;*
;	ORG	0
;DRIVE	RMB	1		DRIVE ID (ADDRESS)
;NCYL	RMB	1		NUMBER OF CYLINDERS
;NHEAD	RMB	1		NUMBER OF HEADS
;NSEC	RMB	1		NUMBER OF SECTORS/TRACK
;CYL	RMB	1		CURRENT CYLINDER
;HEAD	RMB	1		CURRENT HEAD
;SEC	RMB	1		CURRENT SECTOR
;*
;*
;* INITIALIZE SYSTEM HARDWARE. ON ENTRY 'Y'
;* POINTS TO SYSTEM TABLE TO BE FILLED IN.
;*
;* INITIALIZE CUBIX SYSTEM TABLE
HWINIT
        LDX     #RITAB                            ;POINT TO OUR TABLE
        LDB     #RISIZ                            ;SIZE OF TABLE
HWIN1
        LDA     ,X+                               ;GET A BYTE FROM TABLE
        STA     ,Y+                               ;WRITE IT TO CUBIX RAM
        DECB                                      ;REDUCE COUNT
        BNE     HWIN1                             ;MOVE ENTIRE TABLE

        JSR     SERIALINIT
        JSR     PPIDE_INIT
;*	JSR	SETUPDRIVE
        RTS

;* NULL DEVICE DRIVERS
RDNULL
        LDA     #$FF                              ;INDICATE NO CHARACTER
WRNULL
        RTS     IGNORE OPERATION

;*
;* FORMAT DISK ('U' POINTS TO DCB), INTERLEAVE FACTOR IN 'A'
;*
DFORMAT
;*	LDAA	DRIVE,U			; GET DRIVE
;*	CMPA	#$01			; DRIVE B?
;*	BNE 	NOTFDB			;
;*	JMP	FORMFL			; DIRECT ATTACHED FLOPPY FORMAT
;*NOTFDB:
        RTS

;*
;* HOME HEAD ON DRIVE ('U' POINTS TO DCB)
;*
DHOME
;*	LDAA	DRIVE,U			; GET DRIVE
;*	CMPA	#$01			; DRIVE A?
;*	BNE 	NOTHDB			;
;*	LDAA	#$00
;*	JMP	SETTRACK		; DIRECT ATTACHED FLOPPY HOME
;*NOTHDB:
        LDA     #$03                              ; HOME DISK
;	JSR	ECB_OUTCHAR		;
;	LDA	DRIVE,U			; GET DRIVE
;	JSR	ECB_ENC_OUTCHAR		; SEND TO Z80
        RTS


;*
;* READ A SECTOR, FROM DISK ('U' POINTS TO DCB) TO MEMORY(X)
;*
DRDSEC
;*	JSR	SEGDISPLAY

        LDA     DRIVE,U                           ; GET DRIVE
;*	CMPA	#$00			; DRIVE A?
;*	BNE 	NOTRDA			;
;JMP	Z80RDRIVE		; USE Z80 A:
;*NOTRDA
;*	CMPA	#$01			; DRIVE B?
;*	BNE 	NOTRDB			;
;*	JMP	READFL			; USE DIRECT ATTACHED FLOPPY
;*NOTRDB
;*	CMPA	#$02			; DRIVE C?
;*	BNE 	NOTRDC			;
;*	JMP	Z80RDRIVE		; USE Z80 C:
;*NOTRDC
        CMPA    #$03                              ; DRIVE D?
        BNE     NOTRDD                            ;
        JMP     IDE_READ_SECTOR                   ; USE DIRECT ATTACHED IDE
NOTRDD
        RTS


;*
;* WRITE A SECTOR TO DISK ('U' POINTS TO DCB) FROM MEMORY(X)
;*
DWRSEC
;*	JSR	SEGDISPLAY
        LDA     DRIVE,U                           ; GET DRIVE
;*	CMPA	#$00			; DRIVE A?
;*	BNE 	NOTWDA			;
;	JMP	Z80WDRIVE		; USE Z80 A:
;*NOTWDA
;*	CMPA	#$01			; DRIVE B?
;*	BNE 	NOTWDB			;
;*	JMP	WRITEFL			; USE DIRECT ATTACHED FLOPPY
;*NOTWDB
;*	CMPA	#$02			; DRIVE C?
;*	BNE 	NOTWDC			;
;*	JMP	Z80WDRIVE		; USE Z80 C:
;*NOTWDC
        CMPA    #$03                              ; DRIVE D?
        BNE     NOTWDD                            ;
        JMP     IDE_WRITE_SECTOR                  ; USE DIRECT ATTACHED IDE
NOTWDD
        RTS


        INCLUDE ../nhyodyne/cubix_serial.asm
        INCLUDE ../nhyodyne/cubix_ide.asm
;*	include CUBIXOS\CUBFLP.asm	FLOPPY I/O DRIVERS
;*	include CUBIXOS\CUBDSKY.asm	DSKY I/O DRIVERS
;*	include CUBIXOS\CUBVDU.asm	DSKY VDU DRIVERS



        ORG     $FF00
;
; DISK COMMAND BLOCK
;
;* IGNORE ANY UNUSED INTERRUPTS
IGNORE
        RTI
;* RESULT CODES FOR FDC OPERATIONS
RESTAB
        FCB     3,0,2,0,0,3,4,1
;*
;* INITIALIZATION TABLE FOR CUBIX RAM
;*
RITAB           EQU *
;* DEFAULT DRIVE CHARACTISTICS
        FCB     0,80,2,9,0,0,0                    ;ADR 0, 80 CYL, 2 HEAD, 9 SEC/TRK
        FCB     1,255,1,255,0,0,0                 ;ADR 1, 255 CYL, 1 HEAD, 255 SEC/TRK
        FCB     2,255,1,255,0,0,0                 ;ADR 2, 255 CYL, 1 HEAD, 255 SEC/TRK
        FCB     3,255,1,255,0,0,0                 ;ADR 4, 255 CYL, 1 HEAD, 255 SEC/TRK
;* CONSOLE DEVICE ASSIGNMENTS
        FCB     1                                 ;CONSOLE INPUT DEVICE
        FCB     1                                 ;CONSOLE OUTPUT DEVICE
;* SERIAL DEVICE DRIVERS
        FDB     RDNULL,RDSER1,0,0,0,0,0,0
        FDB     WRNULL,WRSER1,0,0,0,0,0,0
;* DISK DEVICE DRIVERS
        FDB     DHOME,DRDSEC,DWRSEC,DFORMAT
;* 6809 HARDWARE VECTORS
        FDB     SSR                               ;SWI VECTOR (USED FOR SSRS)
        FDB     IGNORE                            ;SWI2 VECTOR
        FDB     IGNORE                            ;SWI3 VECTOR
        FDB     IGNORE                            ;IRQ  VECTOR
        FDB     IGNORE                            ;FIRQ VECTOR
        FDB     IGNORE                            ;NMI VECTOR
;* MISC FLAGS & VARIABLES
        FCB     $FF                               ;ERROR MESSAGES ENABLED
        FCB     0                                 ;TRACE DISABLED
        FCB     0                                 ;DEBUG DISABLED
        FCB     3                                 ;DEFAULT DRIVE (A)
        FCC     'MAIN'                            ;DEFAULT DIRECTORY
        FCB     0,0,0,0                           ;(FILLER)
        FCB     3                                 ;SYSTEM DRIVE (A)
        FCC     'SYSTEM'                          ;SYSTEM DIRECTORY
        FCB     0,0                               ;(FILLER)
RISIZ           EQU *-RITAB                       ;SIZE OF INITILAIZED RAM
;
