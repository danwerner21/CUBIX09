;__FLOPPY DRIVERS________________________________________________________________________________________________________________
;
; 	CUBIX floppy drivers for MBC FDC card
;
;	Entry points:
;		FL_SETUP        - called during OS init
;		FL_READ_SECTOR	- read a sector from drive
;		FL_WRITE_SECTOR	- write a sector to drive
;
;________________________________________________________________________________________________________________________________
;
;*
;* HARDWARE I/O ADDRESSES
;*
FDC_MSR         = $0530                           ; ADDRESS OF MAIN STATUS REGISTER
FDC_DATA        = $0531                           ; FLOPPY DATA REGISTER
FDC_RESET       = $0533                           ; FLOPPY RESET
FDC_DCR         = $0535                           ; LOAD CONTROL REGISTER
FDC_DOR         = $0536                           ; CONFIGURATION CONTROL REGISTER
FDC_TC          = $0537                           ; TERMINAL COUNT

;
; FDC COMMANDS
;
CFD_READ        = %00000110                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,DTL --> ST0,ST1,ST2,C,H,R,N
CFD_READDEL     = %00001100                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,DTL --> ST0,ST1,ST2,C,H,R,N
CFD_WRITE       = %00000101                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,DTL --> ST0,ST1,ST2,C,H,R,N
CFD_WRITEDEL    = %00001001                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,DTL --> ST0,ST1,ST2,C,H,R,N
CFD_READTRK     = %00000010                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,DTL --> ST0,ST1,ST2,C,H,R,N
CFD_READID      = %00001010                       ; CMD,HDS/DS --> ST0,ST1,ST2,C,H,R,N
CFD_FMTTRK      = %00001101                       ; CMD,HDS/DS,N,SC,GPL,D --> ST0,ST1,ST2,C,H,R,N
CFD_SCANEQ      = %00010001                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,STP --> ST0,ST1,ST2,C,H,R,N
CFD_SCANLOEQ    = %00011001                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,STP --> ST0,ST1,ST2,C,H,R,N
CFD_SCANHIEQ    = %00011101                       ; CMD,HDS/DS,C,H,R,N,EOT,GPL,STP --> ST0,ST1,ST2,C,H,R,N
CFD_RECAL       = %00000111                       ; CMD,DS --> <EMPTY>
CFD_SENSEINT    = %00001000                       ; CMD --> ST0,PCN
CFD_SPECIFY     = %00000011                       ; CMD,SRT/HUT,HLT/ND --> <EMPTY>
CFD_DRVSTAT     = %00000100                       ; CMD,HDS/DS --> ST3
CFD_SEEK        = %00001111                       ; CMD,HDS/DS --> <EMPTY>
CFD_VERSION     = %00010000                       ; CMD --> ST0

CFD_MFM         = %01000000                       ;

;
;
; Specify Command:
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+
; |Byte |  7  |	 6  |  5  |  4	|  3  |	 2  |  1  |  0	|
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+
; |  0	|  0  |	 0  |  0  |  0	|  0  |	 0  |  1  |  1	|
; |  1	| ----- STEP RATE ----- | -- HEAD UNLOAD TIME - |
; |  2	| ------------ HEAD LOAD TIME ----------- | NDM |
; +-----+-----+-----+-----+-----+-----+-----+-----+-----+
;
;
; Step Rate (milliseconds):		 Head Unload Time (milliseconds):	Head Load Time (milliseconds):
; +------+------+------+------+------+	 +------+------+------+------+------+	+------+------+------+------+------+
; |	 |	   BITRATE	     |	 |	|	  BITRATE	    |	|      |	 BITRATE	   |
; |  VAL | 1.0M | 500K | 300K | 250K |	 |  VAL | 1.0M | 500K | 300K | 250K |	|  VAL | 1.0M | 500K | 300K | 250K |
; +------+------+------+------+------+	 +------+------+------+------+------+	+------+------+------+------+------+
; |    0 |  8.0 | 16.0 | 26.7 | 32.0 |	 |    0 |  128 |  256 |	 426 |	512 |	|    0 |  128 |	 256 |	426 |  512 |
; |    1 |  7.5 | 15.0 | 25.0 | 30.0 |	 |    1 |    8 |   16 | 26.7 |	 32 |	|    1 |    1 |	   2 |	3.3 |	 4 |
; |    2 |  7.0 | 14.0 | 23.3 | 28.0 |	 |    2 |   16 |   32 | 53.3 |	 64 |	|    2 |    2 |	   4 |	6.7 |	 8 |
; |  ... |  ... |  ... |  ... |	 ... |	 |  ... |  ... |  ... |	 ... |	... |	|  ... |  ... |	 ... |	... |  ... |
; |   14 |  1.0 |  2.0 |  3.3 |	 4.0 |	 |   14 |  112 |  224 |	 373 |	448 |	|  126 |  126 |	 252 |	420 |  504 |
; |   15 |  0.5 |  1.0 |  1.7 |	 2.0 |	 |   15 |  120 |  240 |	 400 |	480 |	|  127 |  127 |	 254 |	423 |  508 |
; +------+------+------+------+------+	 +------+------+------+------+------+	+------+------+------+------+------+
;
; IBM PS/2 CALLS FOR:
;   STEP RATE: 3ms (6ms FOR ALL 41mm OR 720K DRIVES)
;   HEAD LOAD TIME: 15ms

DOR_INIT        = %00001100                       ; SOFT RESET INACTIVE, DMA ENABLED
DOR_BR250       = DOR_INIT
DOR_BR500       = DOR_INIT



FLOPPY_RETRIES  = 6                               ; HOW ABOUT SIX RETIRES?
FLOPPY_RETRIES1 = 2                               ; TWO ITERATIONS OF RECAL?

;__FL_SETUP______________________________________________________________________________________________________________________
;
;	SETUP FLOPPY DRIVE SETTINGS
;________________________________________________________________________________________________________________________________
;
FL_SETUP:
        LDX     #FMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
;
        LDX     #FMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #FDC_MSR                          ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     FD_DETECT                         ; CHECK FOR FDC
        CMPA    #$00
        BEQ     >                                 ; CONTINUE IF FOUND
        LDX     #FMESSAGE3
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        LDA     #$FF
        RTS                                       ; BAIL OUT
!
        LDX     #FMESSAGE4
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        LDA     #DOR_INIT                         ; RESET SETTINGS
        STA     FDC_DOR

        JSR     CHECKINT                          ;
        LDA     #CFD_SPECIFY                      ; SPECIFY COMMAND
        JSR     PFDATA                            ; OUTPUT TO FDC
        LDA     #$7F                              ; 6 MS STEP, 480 MS HEAD UNLOAD
        JSR     PFDATA                            ; OUTPUT TO FDC
        LDA     #$05                              ; 508 MS HEAD LOAD, NON-DMA MODE
        JSR     PFDATA                            ; OUTPUT TO FDC

        JSR     CHECKINT                          ; SEND SEVERAL INTERRUPTS TO ENSURE PROPER STATE
        JSR     CHECKINT                          ;
        JSR     CHECKINT                          ;
        JSR     CHECKINT                          ;
        JSR     CHECKINT                          ;
        JSR     CHECKINT                          ;

        LDA     #$00
        STA     CURRENTDEVICE
        LDA     #%00010000
        STA     DSKUNIT
        JSR     RECAL                             ;
        LDA     #39                               ;
        STA     CURRENTCYL                        ;
        JSR     SETTRK1
        JSR     RECAL                             ;

        LDA     #$01
        STA     CURRENTDEVICE
        LDA     #%00100001
        STA     DSKUNIT
        JSR     RECAL                             ;
        LDA     #39                               ;
        STA     CURRENTCYL                        ;
        JSR     SETTRK1
        JSR     RECAL                             ;
        LDA     #DOR_INIT                         ; RESET SETTINGS
        STA     FDC_DOR
        RTS


;__FL_READ_SECTOR________________________________________________________________________________________________________________
;
; 	READ A FLOPPY SECTOR
;________________________________________________________________________________________________________________________________
;
;
FL_READ_SECTOR:
        LDA     FLOPPY_DETCT
        CMPA    #$00
        BEQ     >
        RTS
!
        LDA     CURRENTDEVICE
        ANDA    #$01
        ORA     #%00010000
        STA     DSKUNIT                           ;
        LDA     #$00
        STA     FLRETRY                           ; BLANK RETRIES
        STA     FLRETRY1
        LDA     #DOR_INIT
        ORA     DSKUNIT                           ;
        STA     FDC_DOR                           ; OUTPUT TO CONTROLLER

READFL1:
        LDA     #CFD_READ|CFD_MFM                 ; BIT 6 SETS MFM, 06H IS READ COMMAND
        STA     FCMD                              ; SET COMMAND
        JSR     DSKOP                             ; DO DISK OPERATION

        CMPA    #$00
        BEQ     READFLDONE                        ; OPERATION SUCCESSFUL
        INC     FLRETRY                           ; LET'S RETRY
        LDA     FLRETRY
        CMPA    #FLOPPY_RETRIES
        BNE     READFL1
        JSR     RECAL                             ; AFTER X RETRIES, LET'S RECAL THE HEAD
        JSR     SETTRACK                          ;
        LDA     #$00                              ;
        STA     FLRETRY                           ; MORE RETRIES!
        INC     FLRETRY1
        LDA     FLRETRY1
        CMPA    #FLOPPY_RETRIES1
        BNE     READFL1
        LDA     #$FF                              ; A = 0 ON RETURN = OPERATION OK
        RTS                                       ; A = $FF ON RETURN = OPERATION ERROR
READFLDONE:
        LDA     #$00                              ; A = 0 ON RETURN = OPERATION OK
        RTS

;__FL_WRITE_SECTOR_______________________________________________________________________________________________________________
;
; 	WRITE A FLOPPY SECTOR
;________________________________________________________________________________________________________________________________
;
FL_WRITE_SECTOR:
        LDA     FLOPPY_DETCT
        CMPA    #$00
        BEQ     >
        RTS
!
        LDA     CURRENTDEVICE
        ANDA    #$01
        ORA     #%00010000
        STA     DSKUNIT                           ;
        LDA     #$00
        STA     FLRETRY                           ; BLANK RETRIES
        STA     FLRETRY1

WRITEFL1:
        LDA     #CFD_WRITE|CFD_MFM                ; BIT 6 SETS MFM, 05H IS WRITE COMMAND
        STA     FCMD
        JSR     DSKOP

        CMPA    #$00
        BEQ     WRITEFLDONE
        INC     FLRETRY
        LDA     FLRETRY
        CMPA    #FLOPPY_RETRIES
        BNE     WRITEFL1
        JSR     RECAL
        JSR     SETTRACK
        LDA     #$00
        STA     FLRETRY
        INC     FLRETRY1
        LDA     FLRETRY1
        CMPA    #FLOPPY_RETRIES1
        BNE     WRITEFL1
        LDA     #$FF                              ; INVALIDATE CACHE
        RTS                                       ; A = $FF ON RETURN = OPERATION ERROR
WRITEFLDONE:
        LDA     #$00                              ; A = 0 ON RETURN = OPERATION OK
        RTS


;__DSKOP__________________________________________________________________________________________________________________________
;
; 	PERFORM A DISK OPERATION
;________________________________________________________________________________________________________________________________
;
DSKOP:
        SEI
        JSR     CHECKINT                          ; CHECK INTERRUPT STATUS, MAKE SURE IT IS CLEAR
        CMPA    #$FF                              ; DID IT RETURN WITH ERROR CODE?
        BEQ     DSKEXIT                           ; IF YES, EXIT WITH ERROR CODE
;
        JSR     SETTRACK                          ; PERFORM SEEK TO TRACK
;
        LDA     FCMD                              ; WHAT COMMAND IS PENDING?
        CMPA    #CFD_READ|CFD_MFM                 ; IS IT A READ COMMAND?
        BNE     GWRR_POLL                         ;
        JMP     RDD_POLL                          ;
GWRR_POLL:
        JMP     WRR_POLL                          ;
DSKEXIT:
        LDA     #0                                ; SET MOTOR OFF
        STA     FDC_DOR                           ; OUTPUT TO CONTROLLER
        LDA     #$FF                              ; SET IF ERROR
        CLI
        RTS

SNDFDWR:
        CLC
        LDA     DSKUNIT                           ; GET DISK UNIT NUMBER
        ANDA    #$01                              ; MASK FOR TWO DRIVES.
        STA     TMPSTORAGE                        ; PARK IT IN TEMP
        LDA     CURRENTHEAD                       ; GET HEAD SELECTION
        ANDA    #$01                              ; INSURE SINGLE BIT
        ASLA                                      ;
        ASLA                                      ; MOVE HEAD TO BIT 2 POSITION
        ORA     TMPSTORAGE                        ; OR HEAD TO UNIT BYTE IN COMMAND BLOCK
        STA     TMPSTORAGE                        ; STORE IN UNIT
        LDA     FCMD                              ;
        JSR     PFDATA                            ; PUSH COMMAND TO I8272
        LDA     TMPSTORAGE                        ;
        JSR     PFDATA                            ;
        LDA     CURRENTCYL                        ;
        JSR     PFDATA                            ;
        LDA     CURRENTHEAD                        ;
        JSR     PFDATA                            ;
        CLC                                       ;
        LDA     CURRENTSEC                       ;
        INCA                              ;
        JSR     PFDATA                            ;
        LDA     #$02                              ;
        JSR     PFDATA                            ; WHAT DENSITY
        LDA     #$09                              ;
        JSR     PFDATA                            ; ASSUME SC (SECTOR COUNT)  EOT
        LDA     #$1B                              ;
        JSR     PFDATA                            ; WHAT GAP IS NEEDED
        LDA     #$FF                              ; DTL, IS THE LAST COMMAND BYTE TO I8272
        JSR     PFDATAS
        RTS


; PERFORM READ
; FROM READ TO READ MUST NOT EXCEED 25US WORST CASE MIN. (AT 2MHZ IS 2,000,000 CYCLES PER SECOND == 50 CYCLE BUDGET.)
;
RDD_POLL:
        LDX     #$00
        LDY     #$00
        JSR     SNDFDWR                           ;
RDS1:
        LDA     FDC_MSR                           ; GET STATUS  (4 CYCLES)
        BPL     RDS1                              ; FDC IS NOT READY, WAIT FOR IT (UP TO 4 CYCLES)
        ANDA    #%00100000                        ; EXECUTION MODE? (2 CYCLES)
        BEQ     DSKOPEND                          ; NO, ERROR
RDS1A:
        LDA     FDC_DATA                          ; GET DATA (4 CYCLES)
        STA     HSTBUF,Y                          ; WRITE IT (5 CYCLES)
        INY                                       ; (2 CYCLES)
        BNE     RDS1                              ; KEEP GOING (UP TO 4 CYCLES)   TOTAL =
        LDX     #$00
RDS2:
        LDA     FDC_MSR                           ; GET STATUS
        BPL     RDS2                              ; FDC IS NOT READY, WAIT FOR IT (UP TO 4 CYCLES)
        ANDA    #%00100000                        ; EXECUTION MODE?
        BEQ     DSKOPEND                          ; NO, ERROR
RDS2A:
        LDA     FDC_DATA                          ; GET DATA
        STA     HSTBUF+256,Y                      ; WRITE IT
        INY
        BNE     RDS2                              ; KEEP GOING
DSKOPEND:
        LDA     FDC_TC
        JSR     FDDELAY
;
        JSR     GFDATA                            ;GET ERROR TYPE
        STA     FLERR
;* CLEAR OUT ANY REMAINING DATA
RESUL3:
        JSR     GFDATA                            ;READ BYTE FROM FDC
        CMPA    #$00
        BNE     RESUL3                            ;CLEAR THEM ALL
        LDA     FLERR                             ;
        ANDA    #%11000000                        ;
        RTS


WRR_POLL:
        JSR     SNDFDWR                           ;
WRS1:   ;
        LDA     FDC_MSR                           ; GET STATUS
        BPL     WRS1                              ; NOT READY
        ANDA    #%00100000                        ; EXECUTION MODE?
        BEQ     WRS3                              ; NO, ERROR
        LDA     HSTBUF,Y                          ; WRITE IT
        STA     FDC_DATA                          ; WRITE TO FDC
        INY
        BNE     WRS1                              ; DO NEXT
WRS2:   ;
        LDA     FDC_MSR                           ; GET STATUS
        BPL     WRS2                              ; NOT READY
        ANDA    #%00100000                        ; EXECUTION MODE?
        BEQ     WRS3                              ; NO, ERROR
        LDA     HSTBUF+256,Y                      ; WRITE IT
        STA     FDC_DATA                          ; WRITE TO FDC
        INY
        BNE     WRS2                              ; DO NEXT
WRS3:
        JMP     DSKOPEND                          ;


;__SETTRACK__________________________________________________________________________________________________________________________
;
; 	SEEK TO A TRACK ON GIVEN UNIT
; 	A: TRACK #
;________________________________________________________________________________________________________________________________
;
SETTRACK:
        LDA     #DOR_INIT
        ORA     DSKUNIT                           ; SET MOTOR ON
        STA     FDC_DOR                           ; OUTPUT TO CONTROLLER

; ANY INTERUPT PENDING
; IF YES FIND OUT WHY/CLEAR
        JSR     CHECKINT                          ; CHECK INTERRUPT STATUS, MAKE SURE IT IS CLEAR
        CMPA    #$FF                              ; DID IT RTSURN WITH ERROR CODE?
        BNE     SETTRK1
        JMP     SETTRKEXIT                        ;

;
SETTRK1:
        LDA     CURRENTCYL                        ; GET TRACK
        CMPA    #$00                              ;
        BEQ     RECAL                             ; IF 0 PERFORM RECAL INSTEAD OF SEEK
        LDA     #CFD_SEEK                         ; SEEK COMMAND
        JSR     PFDATA                            ; PUSH COMMAND
        LDA     DSKUNIT                           ; SAY WHICH UNIT
        ANDA    #$01
        JSR     PFDATA                            ; SEND THAT
        LDA     CURRENTCYL                        ; TO WHAT TRACK
        JSR     PFDATA                            ; SEND THAT TOO
        JMP     WAINT                             ; WAIT FOR INTERRUPT SAYING DONE
RECAL:
        LDA     #DOR_INIT
        ORA     DSKUNIT                           ; SET MOTOR ON
        STA     FDC_DOR                           ; OUTPUT TO CONTROLLER
        LDA     #CFD_RECAL                        ; RECAL TO TRACK 0
        JSR     PFDATA                            ; SEND IT
        LDA     DSKUNIT                           ; SAY WHICH UNIT
        ANDA    #$01
        JSR     PFDATA                            ; SEND THAT TOO
;
WAINT:
        PSHS    A,X
        LDX     #100
        JSR     FDVDELAY
        PULS    A,X
!
        JSR     CHECKINT
        LDA     FDC_MSR                           ; READ SEEK STATUS
        ANDA    #%00001111                        ; ANY DRIVES SEEKING?
        BNE     <                                 ; YES, WAIT FOR THEM
;
SETTRKEXIT:
        RTS

;__PFDATA__________________________________________________________________________________________________________________________
;
; WRITE A COMMAND OR PARAMETER SEQUENCE
;
; TRANSFERS ARE SYNCHONIZED BY MSR D7 <RQM> AND D6 <DIO>
;	RQM  DIO
;	0	0	BUSY
;	1	0	WRITE TO DATA REGISTER PERMITTED
;	1	1	BYTE FOR READ BY HOST PENDING
;	0	1	BUSY
;
;________________________________________________________________________________________________________________________________
;
PFDATA:
        PSHS    A                                 ; SAVE DATA BYTE
        LDY     #$00
WRF1:
        LDA     FDC_MSR                           ; READ FDC STATUS
        STA     TMPSTORAGE
        ANDA    #$80                              ;
        BNE     >
        INY
        BNE     WRF1                              ; FDC IS NOT READY, WAIT FOR IT
        PULS    A
        LDA     #$FF
        RTS
!
        LDA     TMPSTORAGE
        ANDA    #$40                              ; TEST DIO BIT
        BNE     WRF2                              ; FDC IS OUT OF SYNC
        PULS    A                                 ; RESTORE DATA
        STA     FDC_DATA                          ; WRITE TO FDC
        JSR     FDDELAY
        JSR     FDDELAY
        JSR     FDDELAY
        RTS
; FDC IS OUT OF SYNC CLEAR IT OUT AND RE-TRY
WRF2:
        LDA     FDC_DATA                          ; READ DATA REGISTER
        JMP     WRF1                              ; AND CONTINUE

;__PFDATAS_________________________________________________________________________________________________________________________
;
; WRITE A COMMAND OR PARAMETER SEQUENCE (NO PAUSE)
;
; TRANSFERS ARE SYNCHONIZED BY MSR D7 <RQM> AND D6 <DIO>
;	RQM  DIO
;	0	0	BUSY
;	1	0	WRITE TO DATA REGISTER PERMITTED
;	1	1	BYTE FOR READ BY HOST PENDING
;	0	1	BUSY
;
;________________________________________________________________________________________________________________________________
;
PFDATAS:
        PSHS    A                                 ; SAVE DATA BYTE
WRF1S:
        LDA     FDC_MSR                           ; READ FDC STATUS
        STA     TMPSTORAGE
        ANDA    #$80                              ;
        BEQ     WRF1S                             ; FDC IS NOT READY, WAIT FOR IT
        LDA     TMPSTORAGE
        ANDA    #$40                              ; TEST DIO BIT
        BNE     WRF2S                             ; FDC IS OUT OF SYNC
        PULS    A                                 ; RESTORE DATA
        STA     FDC_DATA                          ; WRITE TO FDC
        RTS
; FDC IS OUT OF SYNC CLEAR IT OUT AND RE-TRY
WRF2S:
        LDA     FDC_DATA                          ; READ DATA REGISTER
        JMP     WRF1S                             ; AND CONTINUE



;__CHECKINT__________________________________________________________________________________________________________________________
;
; CHECK FOR ACTIVE FDC INTERRUPTS BEFORE GIVING I8272 COMMANDS
; POLL RQM FOR WHEN NOT BUSY AND THEN SEND FDC
; SENSE INTERRUPT COMMAND.  IF IT RTSURNS WITH NON ZERO
; ERROR CODE, PASS BACK TO JSRING ROUTINE FOR HANDLING
;________________________________________________________________________________________________________________________________
;
CHECKINT:
        LDY     #$00
!
        LDA     FDC_MSR                           ; READING OR WRITING IS KEYS TO D7 RQM
        ANDA    #$80
        BNE     >                                 ; WAIT FOR RQM TO BE TRUE. WAIT UNTIL DONE
        JSR     FDDELAY
        INY
        BNE     <
        JMP     ERRCLR

!
        LDA     FDC_MSR                           ; READING OR WRITING IS KEYS TO D7 RQM
        ANDA    #$40                              ; WAITING FOR INPUT?
        BEQ     SENDINT
        RTS

ERRCLR:
        LDY     #$00
!
        LDA     FDC_DATA                          ; CLEAR THE JUNK OUT OF DATA REGISTER
        LDA     FDC_MSR                           ; CHECK WITH RQM
        ANDA    #$80                              ; IF STILL NOT READY, READ OUT MORE JUNK
        BNE     >                                 ;
        JSR     FDDELAY
        INY
        BNE     <
!
        LDA     #$FF                              ; RETURN ERROR CODE -1
;
        RTS

;__SENDINT__________________________________________________________________________________________________________________________
;
; SENSE INTERRUPT COMMAND
;________________________________________________________________________________________________________________________________
;
SENDINT:
        LDA     #CFD_SENSEINT                     ; SENSE INTERRUPT COMMAND
        JSR     PFDATA                            ; SEND IT
        JSR     GFDATA                            ; GET RESULTS
        STA     ST0                               ; STORE THAT
        ANDA    #$C0                              ; MASK OFF INTERRUPT STATUS BITS
        CMPA    #$80                              ; CHECK IF INVALID COMMAND
        BEQ     ENDSENDINT                        ; YES, EXIT
        JSR     GFDATA                            ; GET ANOTHER (STATUS CODE 1)
        LDA     ST0                               ; GET FIRST ONE
        ANDA    #$C0                              ; MASK OFF ALL BUT INTERRUPT CODE 00 IS NORMAL
ENDSENDINT:
        RTS                                       ; ANYTHING ELSE IS AN ERROR


;__GFDATA__________________________________________________________________________________________________________________________
;
; GET DATA FROM FLOPPY CONTROLLER
;
; TRANSFERS ARE SYNCHONIZED BYT MSR D7 <RQM> AND D6 <DIO>
;	RQM  DIO
;	0	0	BUSY
;	1	0	WRITE TO DATA REGISTER PERMITTED
;	1	1	BYTE FOR READ BY HOST PENDING
;	0	1	BUSY
;
;________________________________________________________________________________________________________________________________
;
GFDATA:
        LDY     #$00
!
        LDA     FDC_MSR                           ; GET STATUS
        STA     TMPSTORAGE                        ;
        ANDA    #%10000000                        ; NOT READY, WAIT
        BNE     >                                 ;
        INY
        BNE     <
        LDA     #$00
        RTS
!
        LDA     TMPSTORAGE
        ANDA    #%01000000                        ; ANY DATA FOR US?
        BEQ     GFDATA1                           ; NO, SKIP IT
        LDA     FDC_DATA                          ; GET FDC DATA
GFDATA1:
        RTS

;__FD_DETECT______________________________________________________________________________________________________________________
;
; 	DETECT FLOPPY HARDWARE
;________________________________________________________________________________________________________________________________
FD_DETECT:
; BLINDLY RESET FDC (WHICH MAY OR MAY NOT EXIST)
        JSR     FC_RESETFDC                       ; RESET FDC

        LDA     FDC_MSR                           ; READ MSR
        CMPA    #$80
        BEQ     FD_DETECT1                        ; $80 IS OK
        CMPA    #$D0
        BEQ     FD_DETECT1                        ; $D0 IS OK
        LDA     #$FF                              ; NOT OK
        STA     FLOPPY_DETCT
        RTS
;
FD_DETECT1:
        LDX     #100
        JSR     FDVDELAY                          ; WAIT A BIT FOR FDC
        LDA     FDC_MSR                           ; READ MSR AGAIN
        CMPA    #$80
        BEQ     >                                 ; $80 IS OK
        CMPA    #$D0
        LDA     #$FF                              ; NOT OK
        STA     FLOPPY_DETCT
        RTS
!
        LDA     #$00                              ; OK
        STA     FLOPPY_DETCT
        RTS

FC_RESETFDC:
        LDA     FDC_RESET
        LDA     FDC_RESET
        LDX     #150
        JSR     FDVDELAY                          ; WAIT A BIT FOR FDC

        LDA     #$00
        STA     FDC_DOR
        JSR     FDDELAY
        LDA     #DOR_INIT
        STA     FDC_DOR
        LDX     #150                              ;
        JSR     FDVDELAY
        RTS


FDDELAY:
        PSHS    A
        PULS    A
        PSHS    A
        PULS    A
        RTS
FDVDELAY:
        PSHS    A
        PULS    A
        PSHS    A
        PULS    A
        DEX
        CPX     #$00
        BNE     FDVDELAY
        RTS


TMPSTORAGE:
        FCB     00
FMESSAGE1:
        FCC     "FD: MODE=MBC$"
        FCB     00
FMESSAGE2:
        FCC     " IO=0x$"
        FCB     00
FMESSAGE3:
        FCC     " NOT PRESENT$"
        FCB     00
FMESSAGE4:
        FCC     " PRESENT$"
        FCB     00
