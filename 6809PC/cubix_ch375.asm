;__IDE DRIVERS___________________________________________________________________________________________________________________
;
; 	CUBIX IDE disk drivers 6809PC - CH375 USB STORAGE
;
;	Entry points:
;		CH375INIT      	 - CALLED DURING OS INIT
;		CH_READSEC       - read a sector from drive
;		CH_WRITESEC      - write a sector to drive
;________________________________________________________________________________________________________________________________
;
; CH375 HARDWARE ADDRESS
CH0BASE         = $1260
CH0DATA         = CH0BASE
CH0COMMAND      = CH0BASE+1
;
; CH375/376 COMMANDS
;
CH_CMD_VER      = $01                             ; GET IC VER
CH_CMD_RESET    = $05                             ; FULL CH37X RESET
CH_CMD_EXIST    = $06                             ; CHECK EXISTS
CH_CMD_MAXLUN   = $0A                             ; GET MAX LUN NUMBER
CH_CMD_PKTSEC   = $0B                             ; SET PACKETS PER SECTOR
CH_CMD_SETRETRY = $0B                             ; SET RETRIES
CH_CMD_MODE     = $15                             ; SET USB MODE
CH_CMD_TSTCON   = $16                             ; TEST CONNECT
CH_CMD_ABRTNAK  = $17                             ; ABORT DEVICE NAK RETRIES
CH_CMD_STAT     = $22                             ; GET STATUS
CH_CMD_RD5      = $28                             ; READ USB DATA (375)
CH_CMD_WR5      = $2B                             ; WRITE USB DATA (375)
CH_CMD_DSKMNT   = $31                             ; DISK MOUNT
CH_CMD_BYTE_LOC = $39                             ; BYTE LOCATE
CH_CMD_BYTERD   = $3A                             ; BYTE READ
CH_CMD_BYTERDGO = $3B                             ; BYTE READ GO
CH_CMD_BYTEWR   = $3C                             ; BYTE WRITE
CH_CMD_BYTEWRGO = $3D                             ; BYTE WRITE GO
CH_CMD_DSKCAP   = $3E                             ; DISK CAPACITY
CH_CMD_AUTOSET  = $4D                             ; USB AUTO SETUP
CH_CMD_DSKINIT  = $51                             ; DISK INIT
CH_CMD_DSKRES   = $52                             ; DISK RESET
CH_CMD_DSKSIZ   = $53                             ; DISK SIZE
CH_CMD_DSKRD    = $54                             ; DISK READ
CH_CMD_DSKRDGO  = $55                             ; CONTINUE DISK READ
CH_CMD_DSKWR    = $56                             ; DISK WRITE
CH_CMD_DSKWRGO  = $57                             ; CONTINUE DISK WRITE
CH_CMD_DSKINQ   = $58                             ; DISK INQUIRY
CH_CMD_DSKRDY   = $59                             ; DISK READY

CH375INIT:
        JSR     LFCR
        JSR     CH_DETECT
        BNE     NOTDETECTED

        LDX     #CHMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF

        JSR     CH_DISKINIT
        BCS     >

        LDX     #CHMESSAGE3
        JSR     WRSTR                             ; DO PROMPT

        LDD     HSTBUF
        JSR     WRHEXW                            ; PRINT BASE PORT

        LDD     HSTBUF+2
        JSR     WRHEXW                            ; PRINT BASE PORT

        JSR     LFCR                              ; AND CRLF
        CLC
        RTS
!
        LDX     #CHMESSAGE5
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        SEC
        RTS
NOTDETECTED:
        LDX     #CHMESSAGE6
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        SEC
        RTS

CH_DETECT:
        LDX     #CHMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF

        LDX     #MESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #CH0BASE                          ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     CH_RESET

CH_DETECT1:
        LDA     #CH_CMD_EXIST                     ; LOAD COMMAND
        JSR     CH_CMD                            ; SEND COMMAND
        LDA     #$AA                              ; LOAD CHECK PATTERN
        JSR     CH_WR                             ; SEND IT
        JSR     CH_NAP                            ; SMALL DELAY
        JSR     CH_RD                             ; GET ECHO
        CMPA    #$55                              ; SHOULD BE INVERTED
        RTS                                       ; RETURN

CH_CMD:
        STA     CH0COMMAND                        ; SEND COMMAND
        JSR     CH_NAP                            ;
        RTS
;
; GET STATUS
;
CH_STAT:
        LDA     CH0COMMAND                        ; READ STATUS
        RTS
;
; READ A BYTE FROM DATA PORT
;
CH_RD:
        LDA     CH0DATA                           ; READ BYTE
        RTS
;
; WRITE A BYTE TO DATA PORT
;
CH_WR:
        STA     CH0DATA                           ; WRITE BYTE
        RTS

CH_NAP:
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        RTS
        PSHS    X
        LDX     #$500
!
        DEX
        BNE     <
        PULS    X,PC

CH_RESET:
        PSHS    X,Y
        LDA     #CH_CMD_RESET
        JSR     CH_CMD                            ; SEND COMMAND
        LDY     #$0F
CH_RES1:
        LDX     #$FFFF
!
        DEX
        BNE     <
        DEY
        BNE     CH_RES1
        PULS    X,Y,PC


;
; POLL WAITING FOR INTERRUPT
;
CH_POLL:
        PSHS    B,X,Y
        LDY     #$0030
CH_POLL0:
        LDX     #$8000                            ; PRIMARY LOOP COUNTER
CH_POLL1:
        JSR     CH_STAT                           ; GET INT STATUS
        ANDA    #%10000000
        BEQ     CH_POLL2                          ; CHECK BIT
        DEX
        BNE     CH_POLL1                          ; INNER LOOP AS NEEDED
        DEY
        BNE     CH_POLL0                          ; OUTER LOOP AS NEEDED
        PULS    B,X,Y
        SEC
        RTS                                       ; AND RETURN
CH_POLL2:
        LDA     #CH_CMD_STAT                      ; GET STATUS
        JSR     CH_CMD                            ; SEND IT
        JSR     CH_NAP                            ; SMALL DELAY
        JSR     CH_RD                             ; GET RESULT
        PULS    B,X,Y
        CLC
        RTS                                       ; AND RETURN



CH_DISKINIT:
        PSHS    X,Y

	; RESET THE BUS
	LDA	#CH_CMD_MODE		; SET MODE COMMAND
	JSR	CH_CMD			; SEND IT
	LDA	#7			; RESET BUS
	JSR	CH_WR			; SEND IT
	JSR	CH_NAP			; SMALL WAIT
	JSR	CH_RD			; GET RESULT
	JSR	CH_NAP			; SMALL WAIT
;
	; ACTIVATE USB MODE
	LDA	#CH_CMD_MODE		; SET MODE COMMAND
	JSR	CH_CMD			; SEND IT
	LDA	#6			; USB ENABLED, SEND SOF
	JSR	CH_WR			; SEND IT
	JSR	CH_NAP			; SMALL WAIT
	JSR	CH_RD			; GET RESULT
	JSR	CH_NAP			; SMALL WAIT

;
        LDY     #$100
CH_DISKINIT1:
        LDA     #CH_CMD_DSKINIT
        JSR     CH_CMD                            ; SEND COMMAND

        LDX     #$8000
!
        DEX
        BNE     <

        JSR     CH_POLL

        CMPA    #$14                              ; SUCCESS?
        BEQ     CHUSB_RESET1A                     ; IF SO, CHECK READY
        CMPA    #$16                              ; NO MEDIA
        BEQ     CHUSB_NOMEDIA                     ; HANDLE IT
        JSR     CH_NAP                            ; SMALL DELAY
        DEY
        BNE     CH_DISKINIT1                      ; LOOP AS NEEDED
        JMP     CH_DISKINIT_TO                    ; HANDLE TIMEOUT

CHUSB_RESET1A:
        JSR     CH_DSKSIZ                         ; GET AND RECORD DISK SIZE
        PULS    X,Y,PC

CH_DISKINIT_TO:
        SEC
        PULS    X,Y,PC

CHUSB_NOMEDIA:
        LDX     #CHMESSAGE7
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        SEC
        PULS    X,Y,PC

CH_DSKSIZ:
        LDA     #CH_CMD_DSKSIZ                    ; DISK SIZE COMMAND
        JSR     CH_CMD                            ; SEND IT
        JSR     CH_POLL                           ; WAIT FOR RESULT

        CMPA    #$14                              ; SUCCESS?
        BNE     CHUSB_CMDERR                      ; HANDLE CMD ERROR
        JSR     CH_CMD_RD                         ; SEND READ USB DATA CMD
        JSR     CH_RD                             ; GET RD DATA LEN

        CMPA    #$08                              ; MAKE SURE IT IS 8
        BNE     CHUSB_CMDERR                      ; HANDLE CMD ERROR

        JSR     CH_RD
        STA     HSTBUF
        JSR     CH_RD
        STA     HSTBUF+1
        JSR     CH_RD
        STA     HSTBUF+2
        JSR     CH_RD
        STA     HSTBUF+3
        JSR     CH_RD
        JSR     CH_RD
        JSR     CH_RD
        JSR     CH_RD
        CLC
        RTS                                       ; AND DONE
CHUSB_CMDERR:
        SEC
        RTS                                       ; AND DONE

CHUSB_IOERR:
        LDA     #$02                              ; SET ERROR CONDITION
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        SEC
        RTS                                       ; AND DONE


; SEND READ USB DATA COMMAND
; USING BEST OPCODE FOR DEVICE
;
CH_CMD_RD:
        LDA     #CH_CMD_RD5
        JMP     CH_CMD
;
; SEND WRITE USB DATA COMMAND
; USING BEST OPCODE FOR DEVICE
;
CH_CMD_WR:
        LDA     #CH_CMD_WR5
        JMP     CH_CMD

CH_READSEC:
	LDA	#CH_CMD_DSKRD		; DISK READ COMMAND
	JSR	CHUSB_RWSTART		; SEND CMD AND LBA
;
	; READ THE SECTOR IN 64 BYTE CHUNKS
        LDX     #HSTBUF
	LDB	#8			; 8 CHUNKS OF 64 FOR 512 BYTE SECTOR
CHUSB_READ1:
	JSR	CH_POLL			; WAIT FOR DATA READY
	CMPA	#$1D			; DATA READY TO READ?
	BNE	CHUSB_IOERR		; HANDLE IO ERROR
	JSR	CH_CMD_RD		; SEND READ USB DATA CMD
	JSR	CH_RD			; READ DATA BLOCK LENGTH
	CMPA	#64			; AS EXPECTED?
	BNE	CHUSB_IOERR		; IF NOT, HANDLE ERROR
	; BYTE READ LOOP
        PSHS    B
	LDB	#64			; READ 64 BYTES
CHUSB_READ2:
	JSR	CH_RD			; GET NEXT BYTE
	STA	,X+	        	; SAVE IT
        DECB
        BNE 	CHUSB_READ2		; LOOP AS NEEDED
	PULS    B			; RESTORE LOOP CONTROL
;
	; PREPARE FOR NEXT CHUNK
	LDA	#CH_CMD_DSKRDGO	        ; CONTINUE DISK READ
	JSR	CH_CMD			; SEND IT
        DECB
	BNE	CHUSB_READ1		; LOOP TILL DONE
;
	; FINAL CHECK FOR COMPLETION & SUCCESS
	JSR	CH_POLL			; WAIT FOR COMPLETION
	CMPA	#$14			; SUCCESS?
	BNE     CHUSB_IOERR		; IF NOT, HANDLE ERROR
;
        lda     #$00
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
	CLC 				; SIGNAL SUCCESS
	RTS
;
;
;
CH_WRITESEC:
	LDA	#CH_CMD_DSKWR		; DISK WRITE COMMAND
	JSR	CHUSB_RWSTART		; SEND CMD AND LBA
;
	; WRITE THE SECTOR IN 64 BYTE CHUNKS
        LDX     #HSTBUF
	LDB	#8			; 8 CHUNKS OF 64 FOR 512 BYTE SECTOR
CHUSB_WRITE1:
	JSR	CH_POLL			; WAIT FOR DATA READY
	CMPA	#$1E			; DATA READY TO WRITE
	BNE	CHUSB_IOERR		; HANDLE IO ERROR
	JSR	CH_CMD_WR		; SEND WRITE USB DATA CMD
	LDA	#64			; 64 BYTE CHUNK
	JSR	CH_WR			; SEND DATA BLOCK LENGTH
;
	; BYTE WRITE LOOP
	PSHS	B			; SAVE LOOP CONTROL
	LDB     #64			; WRITE 64 BYTES
CHUSB_WRITE2:
	LDA	,X+	        	; GET NEXT BYTE
	JSR	CH_WR			; WRITE NEXT BYTE
	DECB
        BNE	CHUSB_WRITE2		; LOOP AS NEEDED
	PULS	B			; RESTORE LOOP CONTROL
;
	; PREPARE FOR NEXT CHUNK
	LDA	#CH_CMD_DSKWRGO	        ; CONTINUE DISK READ
	JSR	CH_CMD			; SEND IT
        DECB
	BNE	CHUSB_WRITE1		; LOOP TILL DONE
;
	; FINAL CHECK FOR COMPLETION & SUCCESS
	JSR	CH_POLL			; WAIT FOR COMPLETION
	CMPA	#$14			; SUCCESS?
	LBNE	CHUSB_IOERR		; IF NOT, HANDLE ERROR
;
        lda     #$00
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
	CLC	        		; SIGNAL SUCCESS
	RTS
;
; INITIATE A DISK SECTOR READ/WRITE OPERATION
; A: READ OR WRITE OPCODE
;
CHUSB_RWSTART:
	JSR	CH_CMD			; SEND R/W COMMAND
;
; SEND LBA, 4 BYTES, LITTLE ENDIAN
        LDA     CURRENTSEC
	JSR	CH_WR			; SEND BYTE
        LDA     CURRENTCYL
        INCA                                      ; CYL 0 reserved for boot image
	JSR	CH_WR			; SEND BYTE
        LDA     CURRENTSLICE                        ;
	JSR	CH_WR			; SEND BYTE
        LDA     #0              ;
	JSR	CH_WR			; SEND BYTE
; REQUEST 1 SECTOR
        LDA     #1                      ;
	JSR	CH_WR			; SEND BYTE
	RTS
;
CHMESSAGE1:
        FCN     'CH375 USB:'
CHMESSAGE2:
        FCN     '  CH375 DETECTED.'
CHMESSAGE3:
        FCN     '  CH375: BLOCKS=0x'
CHMESSAGE5:
        FCN     '  CH375 MEDIA ERROR.'
CHMESSAGE6:
        FCN     '  CH375 NOT DETECTED.'
CHMESSAGE7:
        FCN     '  CH375 NO MEDIA.'
