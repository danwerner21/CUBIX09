;	TITLE	I/O DRIVERS
;***************************************************************
;*     I/O drivers for the CUBIX operating system.             *
;***************************************************************
;*
;* CUBIX SYSTEM ADDRESSES
;*
        INCLUDE cubix_values.asm
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

        LDA     #00
        STA     CONSOLEDEVICE                     ; set console device for driver output

        JSR     PAGER_INIT                        ; INIT PAGER
;
        LDB     #02                               ;INIT SERIAL PORT
        JSR     MD_PAGERA
;
        LDB     #27                               ;INIT DSKY/NG
        JSR     MD_PAGERA
;
        LDB     #21                               ;INIT IDE
        JSR     MD_PAGERA
        RTS

WRSER:
        LDB     #00                               ;WRITE SERIAL PORT
        JMP     MD_PAGERA

RDSER:
        LDB     #01                               ;READ SERIAL PORT
        JSR     MD_PAGERA
        CMPA    #$FF
        BEQ     >
        ORCC    #%00000100                        ; SET 'Z'
        RTS
!
        LDA     #$FF                              ; CLEAR 'Z'
        RTS                                       ;
;

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
;        LDA     #$03                              ; HOME DISK
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
;*	CMPA	#$10			; FLOPPY?
;*	BNE 	>			;
;*	JMP	Z80WDRIVE		; USE Z80 C:
;*!
        CMPA    #$20                              ; IDE?
        BNE     >                                 ;
        LDB     #22                               ;IDE_READ_SECTOR
        JSR     MD_PAGERA
        BSR     CPYHOSTBUF
        LDA     DISKERROR                         ; GET ERROR CONDITION
!
        RTS
CPYHOSTBUF:
        PSHS    Y
        LDY     #$0000
!
        LDA     HSTBUF,Y
        STA     ,X+
        INY
        CMPY    #$0200
        BNE     <
        PULS    Y
        RTS

;*
;* WRITE A SECTOR TO DISK ('U' POINTS TO DCB) FROM MEMORY(X)
;*
DWRSEC
; START BY POPULATING THE HOST BUFFER
        PSHS    Y
        LDY     #$0000
!
        LDA     ,X+
        STA     HSTBUF,Y
        INY
        CMPY    #$0200
        BNE     <
        PULS    Y
; NOW DO SOME DRIVE MAGIC
        JSR     DECODEDRIVE
        ANDA    #$F0
;*	CMPA	#$10			; FLOPPY?
;*	BNE 	>			;
;*	JMP	Z80WDRIVE		; USE Z80 C:
;*!
        CMPA    #$20                              ; IDD?
        BNE     >                                 ;
        LDB     #23                               ;IDE_WRITE_SECTOR
        JSR     MD_PAGERA
        LDA     DISKERROR                         ; GET ERROR CONDITION
!
        RTS

DECODEDRIVE:
        PSHS    y
        LDA     HEAD,U
        STA     CURRENTHEAD
        LDA     CYL,U
        STA     CURRENTCYL
        LDA     SEC,U
        STA     CURRENTSEC
        CLRA
        LDB     DRIVE,U                           ; GET DRIVE
        ASLB                                      ; a=a*2
        TFR     D,Y
        LDA     DRIVEMAP,Y
        LDB     DRIVEMAP+1,Y
        STA     CURRENTDEVICE
        STB     CURRENTSLICE
        PULS    y,pc

        INCLUDE ../nhyodyne/cubix_pager.asm

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
        FDB     RDNULL,RDSER,0,0,0,0,0,0
        FDB     WRNULL,WRSER,0,0,0,0,0,0
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
        FCB     $21,$03                           ; TABLE IS DRIVE TYPE, SLICE OFFSET
        FCB     $21,$02                           ; DRIVE IDS ARE $00=NONE, $1x=FLOPPY, $2X=PPIDE
        FCB     $21,$01                           ;     LOW NIBBLE IS DEVICE ADDRESS
        FCB     $21,$00                           ; SLICE OFFSET IS THE UPPER 8 BITS OF THE DRIVE LBA ADDRESS
                                                  ; ALLOWING IDE DRIVES TO HOST UP TO 256 VIRTUAL DRIVES PER PHYSICAL DRIVE

RISIZ           EQU *-RITAB                       ;SIZE OF INITILAIZED RAM
;
