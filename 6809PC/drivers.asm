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

;
        JSR     WRMSG
        FCB     $0A
        FCC     '______________________________________________________________________'
        FCB     $0D,$0A,$0D,$0A
        FCC     'Cubix -- detecting hardware'
        FCB     $0D,$0A
        FCC     '______________________________________________________________________'
        FCB     0
;
        LDB     #02                               ;INIT SERIAL PORT
        JSR     MD_PAGERA
;
        LDB     #05                               ;INIT ESP IO
        JSR     MD_PAGERA
;
        LDB     #21                               ;INIT IDE
        JSR     MD_PAGERA
;
        LDB     #24                               ;INIT CH375
        JSR     MD_PAGERA
;
        LDB     #51                               ;INIT MULTI IO
        JSR     MD_PAGERA
;
        JSR     WRMSG
        FCC     '______________________________________________________________________'
        FCB     0
;
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
        RTS

WRESPVID:
        LDB     #03                               ;WRITE ESP VIDEO
        JMP     MD_PAGERA

RDESPPS2:
        LDB     #04                               ;READ ESP PS2
        JSR     MD_PAGERA
        CMPA    #$FF
        BEQ     >
        ORCC    #%00000100                        ; SET 'Z'
        RTS
!
        LDA     #$FF                              ; CLEAR 'Z'
        RTS

WRLPT:
        LDB     #53                               ;WRITE LPT PORT
        JMP     MD_PAGERA                         ;

RDKYB:
        LDB     #52                               ;READ KEYBOARD
        JSR     MD_PAGERA
        CMPA    #$FF
        BEQ     >
        ORCC    #%00000100                        ; SET 'Z'
        RTS
!
        LDA     #$FF                              ; CLEAR 'Z'
        RTS

WRSERESP0:
        LDB     #56                               ;WRITE ESP SERIAL PORT 0
        JMP     MD_PAGERA

WRSERESP1:
        LDB     #59                               ;WRITE ESP SERIAL PORT 1
        JMP     MD_PAGERA

WRNETCONN:
        LDB     #62                               ;WRITE TO Network Console Connection
        JMP     MD_PAGERA

RDESP0:
        LDB     #57                               ;READ ESP SERIAL PORT 0
RDESP:
        JSR     MD_PAGERA
        CMPA    #$FF
        BEQ     >
        ORCC    #%00000100                        ; SET 'Z'
        RTS
!
        LDA     #$FF                              ; CLEAR 'Z'
        RTS

RDESP1:
        LDB     #60                               ;READ ESP SERIAL PORT 1
        BRA     RDESP

RDNETCONN:
        LDB     #63                               ;READ Network Console Connection
        BRA     RDESP


WRESPRAW0:
        LDB     #65                               ;WRITE ESP0 value
        JMP     MD_PAGERA

WRESPRAW1:
        LDB     #66                               ;WRITE ESP1 value
        JMP     MD_PAGERA

RDESPRAW0:
        LDB     #67                               ;READ ESP0 value
        JMP     MD_PAGERA

RDESPRAW1:
        LDB     #68                               ;READ ESP1 value
        JMP     MD_PAGERA




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
        RTS


;*
;* READ A SECTOR, FROM DISK ('U' POINTS TO DCB) TO MEMORY(X)
;*
DRDSEC
        JSR     DECODEDRIVE
        ANDA    #$F0
        CMPA    #$40                              ; USB?
        BNE     >                                 ;
        LDB     #25                               ;USB_READ_SECTOR
        JSR     MD_PAGERA
        BSR     CPYHOSTBUF
        LDA     DISKERROR                         ; GET ERROR CONDITION
        CMPA    #$00
        RTS
!
        CMPA    #$20                              ; IDE?
        BNE     >                                 ;
        LDB     #22                               ;IDE_READ_SECTOR
        JSR     MD_PAGERA
        BSR     CPYHOSTBUF
        LDA     DISKERROR                         ; GET ERROR CONDITION
        CMPA    #$00
        RTS
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
        CMPA    #$40                              ; USB?
        BNE     >                                 ;
        LDB     #26                               ; USB_WRITE_SECTOR
        JSR     MD_PAGERA
        LDA     DISKERROR                         ; GET ERROR CONDITION
        CMPA    #$00
        RTS
!
        CMPA    #$20                              ; IDE?
        BNE     >                                 ;
        LDB     #23                               ;IDE_WRITE_SECTOR
        JSR     MD_PAGERA
        LDA     DISKERROR                         ; GET ERROR CONDITION
        CMPA    #$00
        RTS
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

        INCLUDE ../6809PC/cubix_pager.asm

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
        FCB     0,254,1,255,0,0,0                 ;ADR 0, 254 CYL, 1 HEAD, 255 SEC/TRK   - CYL 0 unusable by OS
        FCB     1,254,1,255,0,0,0                 ;ADR 1, 254 CYL, 1 HEAD, 255 SEC/TRK   - CYL 0 unusable by OS
        FCB     2,254,1,255,0,0,0                 ;ADR 2, 254 CYL, 1 HEAD, 255 SEC/TRK   - CYL 0 unusable by OS
        FCB     3,254,1,255,0,0,0                 ;ADR 3, 254 CYL, 1 HEAD, 255 SEC/TRK   - CYL 0 unusable by OS
;* CONSOLE DEVICE ASSIGNMENTS
        FCB     2                                 ;CONSOLE INPUT DEVICE
        FCB     2                                 ;CONSOLE OUTPUT DEVICE
;* SERIAL DEVICE DRIVERS
        FDB     RDNULL,RDSER,RDESPPS2,RDKYB,WRSERESP0,WRSERESP1,WRNETCONN,0
        FDB     WRNULL,WRSER,WRESPVID,WRLPT,RDESP0,RDESP1,RDNETCONN,0

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
        FCB     0                                 ;DEFAULT DRIVE (A)
        FCC     'MAIN'                            ;DEFAULT DIRECTORY
        FCB     0,0,0,0                           ;(FILLER)
        FCB     0                                 ;SYSTEM DRIVE (A)
        FCC     'SYSTEM'                          ;SYSTEM DIRECTORY
        FCB     0,0                               ;(FILLER)
; DRIVE MAPPING TABLE
        FCB     $20,$00                           ; TABLE IS DRIVE TYPE, SLICE OFFSET
        FCB     $20,$01                           ; DRIVE IDS ARE $00=NONE, $2X=xt-CF-IDE, $4x=CH375 USB
        FCB     $20,$02                           ; LOW NIBBLE IS DEVICE ADDRESS (Device address+$20 for FPSD)
        FCB     $40,$00                           ; SLICE OFFSET IS THE UPPER 8 BITS OF THE DRIVE LBA ADDRESS
; ALLOWING IDE DRIVES TO HOST UP TO 256 VIRTUAL DRIVES PER PHYSICAL DRIVE
RISIZ           EQU *-RITAB                       ;SIZE OF INITILAIZED RAM
;
