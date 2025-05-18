;__FRONT PANEL DRIVERS_____________________________________________________________________________________________________________
;
; 	Duodyne Front Panel Driver
;
;	Entry points:
;               FP_INIT
;               FP_SETLED
;               FP_GETSWITCH
;               FPSD_INIT
;               FPSD_READ_SECTOR
;               FPSD_WRITE_SECTOR
;               FPDIS_INIT
;               FPDIS_CLEAR
;               FPDIS_SETXY
;               FPDIS_OUTCH
;________________________________________________________________________________________________________________________________
;
;
FP_PORT         = $DF54                           ; PORT
FPDIS_I2C_ADDRESS = $3C
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
        LDD     >PAGER_D                          ; RESTORE 'D'
        STA     FP_PORT
        RTS
;__FP_GETSWITCH______________________________________________________________________________________
;
;  GET SWITCHES FROM FRONT PANEL
;  A=SWITCH VALUE
;____________________________________________________________________________________________________
FP_GETSWITCH:
        LDA     FP_PORT
        STD     >PAGER_D                          ; RESTORE 'D'
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
        LBNE    FPSD_INIT_ERROR

        LDA     #$25
        STA     I2C_ADDRESS
        JSR     FPSD_SCAN
        LDA     #$26
        STA     I2C_ADDRESS
        JSR     FPSD_SCAN
        LDA     #$27
        STA     I2C_ADDRESS
        JSR     FPSD_SCAN

        LDA     #$00
        STA     FPSDFAILFLAG
        CLC
        RTS

FPSD_SCAN:
        LDX     #FPSDMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDA     I2C_ADDRESS                       ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     WRHEX
        JSR     SPACE

        LDX     #FPSDSENDINFO                     ; GET SD INFO
        LDY     #1
        LDA     I2C_ADDRESS                       ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     PCF_SENDBYTES_INTERNAL
        LDX     #FPSDSENDREAD                     ; READ BYTES
        LDY     #1
        LDA     I2C_ADDRESS                       ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
        JSR     PCF_SENDBYTES_INTERNAL
        LDX     #HSTBUF
        LDY     #5
        LDA     I2C_ADDRESS                       ; DEFAULT ADDRESS BUG:SHOULD REALLY SCAN ALL APPLICABLE ADDRESSES
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

I2C_ADDRESS:
        FCB     00


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


;*__FPDIS_INIT________________________________________________________________________________________
;*
;*       SETUP   FRONT PANEL DISPLAY
;*
;*____________________________________________________________________________________________________
FPDIS_INIT:
        LDA     PCF_FAIL_FLAG                     ; skip if no PCF
        CMPA    #$00
        BNE     FPDIS_INIT_WERROR
        LDX     #FRONTPANELDISPLAYINIT
        LDY     #FRONTPANELDISPLAYINITEND-FRONTPANELDISPLAYINIT
        LDA     #FPDIS_I2C_ADDRESS
        JSR     PCF_SENDBYTES_INTERNAL
        JSR     LFCR                              ; AND CRLF
        LDX     #FPDISPSDMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        LDX     #FPDISPSDMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDA     #FPDIS_I2C_ADDRESS
        JSR     WRHEX                             ; PRINT BASE PORT
        JSR     LFCR                              ; AND CRLF
FPDIS_INIT_WERROR:
        RTS
FRONTPANELDISPLAYINIT:
        FCB     $80                               ; set command mode
        FCB     $AE                               ; set display off
        FCB     $81,$7F                           ; set contrast
        FCB     $A6                               ; normal display (a7=inverse)
        FCB     $20,00                            ; horizontal addressing mode
        FCB     $A0                               ; segment remap (inverse)
        FCB     $A8,$3F                           ; Multiplex ratio (64 pix)
        FCB     $C8                               ; set com scan direction
        FCB     $D3,$00                           ; set display offset
        FCB     $DA,$12                           ; pin hardware config
        FCB     $D5,$80                           ; display clock divisor
        FCB     $D9,$22                           ; set pre-charge
        FCB     $DB,$20                           ; set deselect level
        FCB     $8D,$14                           ; set charge pump
        FCB     $A4                               ; set display RAM on
        FCB     $AF                               ; set display on
        FCB     $40                               ; set start line
        FCB     $20,00                            ; horizontal addressing mode
        FCB     $21,0,127                         ; set col start/end
        FCB     $22,0,7                           ; set page start/end
        FCB     $AF                               ; set display on
FRONTPANELDISPLAYINITEND:

;*__FPDIS_CLEAR_______________________________________________________________________________________
;*
;*       CLEAR   FRONT PANEL DISPLAY
;*
;*____________________________________________________________________________________________________
FPDIS_CLEAR:
        LDA     #$00
        LDB     #$00
        JSR     FPDIS_SETXY
        LDY     #100
!
        LDA     #' '
        JSR     FPDIS_OUTCH
        DEY
        CMPY    #00
        BNE     <
        LDA     #$00
        LDB     #$00
        JSR     FPDIS_SETXY
        RTS

;*__FPDIS_SETXY_______________________________________________________________________________________
;*
;*       Set X,Y on FRONT PANEL DISPLAY
;*       X=A, Y=B
;*____________________________________________________________________________________________________
FPDIS_SETXY:
        LDD     >PAGER_D                          ; RESTORE 'D'
        STA     FPDIS_X
        STB     FPDIS_Y
        LDA     PCF_FAIL_FLAG                     ; skip if no PCF
        CMPA    #$00
        BNE     FPDIS_SETXY_WERROR
FPDIS_SETXY_INTERNAL:
        LDX     #FPDISSETXYCONTROL
        LDY     #FPDISSETXYCONTROLEND-FPDISSETXYCONTROL
        LDA     #FPDIS_I2C_ADDRESS
        JSR     PCF_SENDBYTES_INTERNAL
FPDIS_SETXY_WERROR:
        RTS
FPDISSETXYCONTROL:
        FCB     $80                               ; set command mode
        FCB     $21
FPDIS_X:
        FCB     $00
        FCB     127                               ; set col start/end
        FCB     $22
FPDIS_Y:
        FCB     $00
        FCB     7                                 ; set page start/end
        FCB     $AF                               ; set display on
FPDISSETXYCONTROLEND:


;*__FPDIS_OUTCH_______________________________________________________________________________________
;*
;*       Print Char on FRONT PANEL DISPLAY
;*      A=CHAR
;*____________________________________________________________________________________________________
FPDIS_OUTCH:
        PSHS    D,X,Y
        LDA     PCF_FAIL_FLAG                     ; skip if no PCF
        CMPA    #$00
        BNE     FPDIS_OUTCH_WERROR
        JSR     FPDIS_SETXY_INTERNAL
        LDD     >PAGER_D                          ; RESTORE 'D'
        LDX     FPDIS_OUTCHFONT
        CMPA    #$5A
        BLE     >
        SEC
        SBCA    #$20
        CMPA    #$30
        BGT     >
        SEC
        SBCA    #$2F
!
        LDB     #5
        MUL
        STD     FPDIS_TEMPWORD
        LDY     #FPDIS_OUTCHDATA+1
        LDX     #FPDIS_OUTCHFONT
!
        LDA     FPDIS_TEMPWORD,X
        STY     ,Y+
        INX
        CMPY    FPDIS_OUTCHDATA+7
        BNE     <
        LDX     #FPDIS_OUTCHDATA
        LDY     #7
        LDA     #FPDIS_I2C_ADDRESS
        JSR     PCF_SENDBYTES_INTERNAL
        LDA     FPDIS_X
        CLC
        ADDA    #6
        STA     FPDIS_X
        LDA     FPDIS_X
        CMPA    #150
        BLE     >
        INC     FPDIS_Y
        LDA     #$00
        STA     FPDIS_X
!
FPDIS_OUTCH_WERROR:
        PULS    D,X,Y
        RTS

FPDIS_OUTCHDATA:
        FCB     $40,$00,$00,$00,$00,$00,$00

FPDIS_OUTCHFONT:
        FCB     $00,$00,$00,$00,$00               ; _
        FCB     $3E,$41,$5D,$41,$3E               ; 0
        FCB     $00,$40,$7F,$42,$00               ; 1
        FCB     $42,$45,$49,$51,$62               ; 2
        FCB     $36,$49,$41,$41,$22               ; 3
        FCB     $10,$7F,$12,$14,$18               ; 4
        FCB     $11,$29,$45,$45,$47               ; 5
        FCB     $30,$49,$49,$49,$3E               ; 6
        FCB     $03,$05,$09,$11,$61               ; 7
        FCB     $36,$49,$49,$49,$36               ; 8
        FCB     $3E,$49,$49,$49,$06               ; 9
        FCB     $00,$00,$00,$00,$00               ; :
        FCB     $00,$00,$00,$00,$00               ; ;
        FCB     $00,$00,$00,$00,$00               ; <
        FCB     $14,$14,$14,$14,$14               ; =
        FCB     $00,$00,$00,$00,$00               ; >
        FCB     $00,$00,$00,$00,$00               ; ?
        FCB     $22,$14,$7F,$14,$02               ; *
        FCB     $7E,$09,$09,$09,$7E               ; A
        FCB     $36,$49,$49,$49,$7F               ; B
        FCB     $22,$41,$41,$41,$3E               ; C
        FCB     $3E,$41,$41,$41,$7F               ; D
        FCB     $41,$49,$49,$49,$7F               ; E
        FCB     $01,$01,$09,$09,$7F               ; F
        FCB     $38,$49,$49,$41,$3E               ; G
        FCB     $7F,$08,$08,$08,$7F               ; H
        FCB     $00,$41,$7F,$41,$00               ; I
        FCB     $3F,$40,$40,$40,$30               ; J
        FCB     $41,$22,$14,$08,$7F               ; K
        FCB     $40,$40,$40,$40,$7F               ; L
        FCB     $7F,$03,$04,$03,$7F               ; M
        FCB     $7F,$08,$04,$02,$7F               ; N
        FCB     $3E,$41,$41,$41,$3E               ; O
        FCB     $06,$09,$09,$09,$7F               ; P
        FCB     $7E,$61,$51,$41,$3E               ; Q
        FCB     $06,$49,$29,$19,$7F               ; R
        FCB     $30,$49,$49,$49,$06               ; S
        FCB     $01,$01,$7F,$01,$01               ; T
        FCB     $3F,$40,$40,$40,$3F               ; U
        FCB     $1F,$20,$40,$20,$1F               ; V
        FCB     $3F,$40,$78,$40,$3F               ; W
        FCB     $41,$36,$08,$36,$41               ; X
        FCB     $03,$04,$78,$04,$03               ; Y
        FCB     $43,$45,$49,$52,$62               ; Z
TESTMESSAGEDATAEND:
FPDIS_TEMPWORD:
        FCB     $00,$00

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
FPDISPMESSAGE1
        FCC     "FP-DISPLAY:"
        FCB     00
FPDISPMESSAGE2
        FCC     " ADDR=0x"
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
