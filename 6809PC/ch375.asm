;*
;* CH375 Test
;*
;*
;*
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
PAGSIZ          = 22                              ;PAGE SIZE
ESCCHR          = $1B                             ;ESCAPE CHARACTER
TAB             = $09                             ;TAB CHARACTER
CR              = $0D                             ;CARRIAGE RETURN
LF              = $0A                             ;LINE-FEED

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

;* vars
        ORG     0
USBCAPACITY:
        RMB     8                                 ; USB CAPACITY

;*
        ORG     OSUTIL                            ;DOS UTILITY RUN AREA
CH375:
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'TEST CH375 USB CARD'
        SWI
        FCB     22

        JSR     CH_DETECT
        BNE     NOTDETECTED

        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     '  CH375 DETECTED.'

        JSR     CH_DISKINIT
        BCS     >

        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     '  CH375 MEDIA SIZE: 0x'

        LDD     USBCAPACITY
        SWI
        FCB     27

        LDD     USBCAPACITY+2
        SWI
        FCB     27

        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     ' SECTORS.'

        LDD     #0000
        RTS
!
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     '  CH375 MEDIA ERROR.'
        RTS


NOTDETECTED:
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     '  CH375 NOT DETECTED.'
        RTS

CH_DETECT:
        JSR     CH_RESET
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'CH375 USB:'
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
        LDY     #$20
CH_DISKINIT1:
        LDA     #CH_CMD_DSKINIT
        JSR     CH_CMD                            ; SEND COMMAND

        LDX     #$5000
!
        DEX
        BNE     <

        JSR     CH_POLL
        SWI
        FCB     28                                ; OUTPUT A
        SWI
        FCB     21                                ; OUTPUT SPACE

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
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     '  CH375 NO MEDIA.'
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

        SWI
        FCB     28                                ; OUTPUT A
        SWI
        FCB     21                                ; OUTPUT SPACE

        CMPA    #$08                              ; MAKE SURE IT IS 8
        BNE     CHUSB_CMDERR                      ; HANDLE CMD ERROR

        JSR     CH_RD
        STA     USBCAPACITY
        JSR     CH_RD
        STA     USBCAPACITY+1
        JSR     CH_RD
        STA     USBCAPACITY+2
        JSR     CH_RD
        STA     USBCAPACITY+3
        JSR     CH_RD
        JSR     CH_RD
        JSR     CH_RD
        JSR     CH_RD
        CLC
        RTS                                       ; AND DONE
CHUSB_CMDERR:
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
