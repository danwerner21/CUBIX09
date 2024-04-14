;__FRONT PANEL DRIVERS_____________________________________________________________________________________________________________
;
; 	Duodyne Front Panel Driver
;
;	Entry points:
;               FP_INIT
;               FP_SETLED
;               FP_GETSWITCH
;________________________________________________________________________________________________________________________________
;
;
FP_PORT         = $DF54                           ; PORT
;
;
;__FP_INIT___________________________________________________________________________________________
;
;  FRONT PANEL INFO
;____________________________________________________________________________________________________
;
FP_INIT:
        JSR     LFCR                              ; AND CRLF
        LDX     #FPMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        LDD     #FP_PORT                          ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     LFCR                              ; AND CRLF
        LDX     #FPMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDA     #$00
        STA     FP_PORT
;
;
        LDX     #$0008
        LDB     FP_PORT
FP_INIT1:
        LDA     #$00
        ROLB
        ADCA    #'0'
        PSHS    B
        JSR     PUTCHR
        PULS    B
        DEX
        CMPX    #$0000
        BNE     FP_INIT1

        JSR     LFCR                              ; AND CRLF
        RTS                                       ; DONE
;
;__FP_SETLED_________________________________________________________________________________________
;
;  SET LED OUTPUT ON FRONT PANEL
;  A=VALUE TO DISPLAY
;____________________________________________________________________________________________________
FP_SETLED:
        STA     FP_PORT
        RTS
;__FP_GETSWITCH______________________________________________________________________________________
;
;  GET SWITCHES FROM FRONT PANEL
;  A=SWITCH VALUE
;____________________________________________________________________________________________________
FP_GETSWITCH:
        LDA     FP_PORT
        RTS                                       ; DONE


;__FPSD_INIT__________________________________________________________________________________________
;
;  INIT AND DISPLAY SD INFO
;____________________________________________________________________________________________________
;
FPSD_INIT:
        JSR     LFCR                              ; AND CRLF
        LDX     #FPSDMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF

        LDA     PCF_FAIL_FLAG
        CMPA    #$00
        BNE     FPSD_INIT_ERROR

        LDX     #FPSDMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDA     #$25                              ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     WRHEX
        JSR     LFCR                              ; AND CRLF

        LDX     #FPSDSENDINFO                     ; GET SD INFO
        LDY     #1
        LDA     #$25                              ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     PCF_SENDBYTES_INTERNAL
        LDX     #FPSDSENDREAD                     ; READ BYTES
        LDY     #1
        LDA     #$25                              ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     PCF_SENDBYTES_INTERNAL
        LDX     #HSTBUF
        LDY     #5
        LDA     #$25                              ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     PCF_READBYTES_INTERNAL

        LDA     HSTBUF                            ; SHOULD RESPOND WITH "SD" FOLLOWED BY IMAGE SIZE
        CMPA    #'S'
        BNE     FPSD_INIT_ERROR
        LDA     HSTBUF+1
        CMPA    #'D'
        BNE     FPSD_INIT_ERROR
        LDX     #FPSDMESSAGE6
        JSR     WRSTR

        LDA     HSTBUF+2
        JSR     WRHEX
        LDA     HSTBUF+3
        JSR     WRHEX
        LDA     HSTBUF+4
        JSR     WRHEX
        LDA     HSTBUF+5
        JSR     WRHEX
        JSR     LFCR                              ; AND CRLF
        LDA     #$00
        STA     FPSDFAILFLAG
        CLC
        RTS
FPSD_INIT_ERROR:
        LDX     #FPSDMESSAGE3
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        LDA     #$FF
        STA     FPSDFAILFLAG
        RTS





;*__FPSD_READ_SECTOR___________________________________________________________________________________
;*
;*  READ FRONT PANEL SD SECTOR (IN LBA) INTO BUFFER
;*
;*____________________________________________________________________________________________________
FPSD_READ_SECTOR:
        LDA     FPSDFAILFLAG
        CMPA    #$00
        BNE     FPSD_READ_SECTOR_ERROR

        JSR     FPSD_SETUP_LBA
        LDX     #FPSDSENDADDRESS
        LDY     #5
        LDA     FPSDDEVICE
        JSR     PCF_SENDBYTES_INTERNAL
        CMPA    #$FF
        BEQ     FPSD_READ_SECTOR_ERROR
        LDX     #FPSDSENDREAD                     ; READ BYTES
        LDY     #1
        LDA     FPSDDEVICE
        JSR     PCF_SENDBYTES_INTERNAL
        CMPA    #$FF
        BEQ     FPSD_READ_SECTOR_ERROR
        LDX     #HSTBUF
        LDY     #512
        LDA     FPSDDEVICE
        JSR     PCF_READBYTES_INTERNAL
        CMPA    #$FF
        BEQ     FPSD_READ_SECTOR_ERROR

        CLRA                                      ; ZERO = 1 ON RETURN = OPERATION OK
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS
FPSD_READ_SECTOR_ERROR:
        LDA     #$02                              ; SET ERROR CONDITION
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS

;*__FPSD_WRITE_SECTOR__________________________________________________________________________________
;*
;*  WRITE FRONT PANEL SD SECTOR (IN LBA) FROM BUFFER
;*
;*____________________________________________________________________________________________________
FPSD_WRITE_SECTOR:
        LDA     FPSDFAILFLAG
        CMPA    #$00
        BNE     FPSD_WRITE_SECTOR_ERROR

        PSHS    Y
        LDY     #$0201
!
        DEY
        LDA     HSTBUF,Y
        STA     HSTBUF+1,Y
        CMPY    #$0000
        BNE     <
        PULS    Y
        LDA     #'W'
        STA     HSTBUF

        JSR     FPSD_SETUP_LBA
        LDX     #FPSDSENDADDRESS
        LDY     #5
        LDA     FPSDDEVICE
        JSR     PCF_SENDBYTES_INTERNAL
        CMPA    #$FF
        BEQ     FPSD_WRITE_SECTOR_ERROR
        LDX     #HSTBUF
        LDY     #513
        LDA     FPSDDEVICE
        JSR     PCF_SENDBYTES_INTERNAL
        CMPA    #$FF
        BEQ     FPSD_WRITE_SECTOR_ERROR
        CLRA                                      ; ZERO = 1 ON RETURN = OPERATION OK
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS
FPSD_WRITE_SECTOR_ERROR:
        LDA     #$02
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS

;*__FPSD_SETUP_LBA____________________________________________________________________________________
;*
;*
;*       SETUP   LBA DATA
;*
;*
;*____________________________________________________________________________________________________
FPSD_SETUP_LBA:
        PSHS    D
        LDA     CURRENTDEVICE
        STA     DSKY_HEXBUF
        ANDA    #$0F
        ORA     #$20
        STA     FPSDDEVICE
        LDA     #$00
        STA     FPSDSENDADDRESS+1
        LDB     CURRENTSLICE
        STB     DSKY_HEXBUF+1
        STB     FPSDSENDADDRESS+2
        LDB     CURRENTCYL                        ;
        STB     DSKY_HEXBUF+2
        STB     FPSDSENDADDRESS+3
        LDB     CURRENTSEC                        ;
        STB     DSKY_HEXBUF+3
        STB     FPSDSENDADDRESS+4
        JSR     DSKY_BIN2SEG
        JSR     DSKY_SHOW
        PULS    D,PC


FPMESSAGE1:
        FCC     "FRONT PANEL:"
        FCB     $0D,$0A
        FCN     " IO=0x"
FPMESSAGE2:
        FCN     " SWITCH: "

FPSDMESSAGE1
        FCC     "FP-SD:"
        FCB     00
FPSDMESSAGE2
        FCC     " ADDR=0x"
        FCB     00
FPSDMESSAGE3
        FCC     " NOT PRESENT"
        FCB     00
FPSDMESSAGE6
        FCC     " TOTAL BYTES=0x"
        FCB     00

FPSDFAILFLAG:
        FCB     $FF
FPSDDEVICE:
        FCB     $FF
FPSDSENDADDRESS:
        FCB     'S',$00,$00,$00,$00
FPSDSENDREAD:
        FCB     'R'
FPSDSENDINFO:
        FCB     'I',$00
