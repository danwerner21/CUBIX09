;	TITLE	I/O DRIVERS
;***************************************************************
;*     I/O drivers for the CUBIX operating system.             *
;***************************************************************
;*
;* CUBIX SYSTEM ADDRESSES
;*
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
        JSR     DECODEDRIVE
        ANDA    #$F0
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
        CMPA    #$20                              ; IDE?
        BNE     >                                 ;
        JMP     IDE_READ_SECTOR                   ; USE DIRECT ATTACHED IDE
!
        RTS


;*
;* WRITE A SECTOR TO DISK ('U' POINTS TO DCB) FROM MEMORY(X)
;*
DWRSEC
        JSR     DECODEDRIVE
        ANDA    #$F0
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
        CMPA    #$20                              ; IDD?
        BNE     >                                 ;
        JMP     IDE_WRITE_SECTOR                  ; USE DIRECT ATTACHED IDE
!
        RTS

DECODEDRIVE:
        PSHS    y
        LDA     DRIVE,U                           ; GET DRIVE
        ASLA                                      ; a=a*2
        TFR     A,Y
        LDA     DRIVEMAP,Y
        LDB     DRIVEMAP+1,Y
        JSR     DMPREG1
        STA     CURRENTDEVICE
        STB     CURRENTSLICE
        PULS    y,pc
CURRENTDEVICE:
        FCB     $00
CURRENTSLICE:
        FCB     $00

        INCLUDE ../nhyodyne/cubix_serial.asm
        INCLUDE ../nhyodyne/cubix_ide.asm


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
; DRIVE MAPPING TABLE
        FCB     $00,$00                           ; TABLE IS DRIVE TYPE, SLICE OFFSET
        FCB     $00,$00                           ; DRIVE IDS ARE $00=NONE, $1x=FLOPPY, $2X=PPIDE
        FCB     $21,$00                           ;     LOW NIBBLE IS DEVICE ADDRESS
        FCB     $21,$01                           ; SLICE OFFSET IS THE UPPER 8 BITS OF THE DRIVE LBA ADDRESS
                                                  ; ALLOWING IDE DRIVES TO HOST UP TO 256 VIRTUAL DRIVES PER PHYSICAL DRIVE

RISIZ           EQU *-RITAB                       ;SIZE OF INITILAIZED RAM
;
