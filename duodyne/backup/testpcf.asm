;*
;*
;* D. WERNER
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
PAGSIZ          = 22                              ;PAGE SIZE
ESCCHR          = $1B                             ;ESCAPE CHARACTER
TAB             = $09                             ;TAB CHARACTER
CR              = $0D                             ;CARRIAGE RETURN
LF              = $0A                             ;LINE-FEED
MD_PAGERA       = $0200                           ; PAGE DRIVER ADDRESS

I2C_BASE        = $DF56
PCF_ID          = $AA
CPU_CLK         = 12
;
PCF_RS0         = I2C_BASE
PCF_RS1         = PCF_RS0+1
PCF_OWN         = $55                             ; PCF'S ADDRESS IN SLAVE MODE
;
HSTBUF          = $0300



        ORG     OSRAM                             ;DOS UTILITY RUN AREA

        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'TEST PCF . . . Scanning I2C Devices'

        LDB     #43
        JSR     MD_PAGERA
;
; display x axis header 00-0F

        SWI
        FCB     21
        SWI
        FCB     21
        SWI
        FCB     21
        LDA     #$00
        STA     xaxis
lp1:
        SWI
        FCB     21

        LDA     xaxis
        INC     xaxis
        SWI
        FCB     28
        INCA
        CMPA    #$10
        BNE     lp1
        SWI
        FCB     22

; start of line loop 00-07
        LDA     #$00
        STA     yaxis
        STA     addr                              ; prefix
        LDA     #8
        STA     YWORK
lp3b:
        LDA     yaxis
        SWI
        FCB     28

        LDA     yaxis
        ADDA    #$10
        STA     yaxis

        LDA     #':'
        SWI
        FCB     33

; set up x axis loop
        LDA     #16
        STA     XWORK
lp2b:
        SWI
        FCB     21

; i2c challenge
; . issue device start command
; . write address to device
; . issue device stop command.
; . delay
; . display response

;	call	_i2c_start
;	ld	a,(addr)
;	ld	c,a
;	call	_i2c_write
;	ld	(rc),a
;	call	_i2c_stop

        JSR     PCF_WAIT_FOR_BB
        CMPA    #$00
        LBNE    NOBB
;
        LDA     addr
        CMPA    #$00
        BEQ     SKP
        CMPA    #$AA
        BEQ     SKP
        STA     PCF_RS0
        JSR     PCF_START                         ; GENERATE START CONDITION
;
        LDB     #$00                              ; delay
!
        NOP
        DECB
        CMPB    #$00
        BNE     <
        JSR     PCF_WAIT_FOR_ACK                  ; AND ISSUE THE SLAVE ADDRESS

        CMPA    #$00
        BEQ     lp4f
SKP:
        LDA     #'-'                              ; display no
        SWI
        FCB     33
        LDA     #'-'                              ; display no
        SWI
        FCB     33
        BRA     lp5f

lp4f:
        LDA     addr
        ASRA
        ANDA    #$7F
        SWI
        FCB     28

lp5f:
        INC     addr                              ; next address
        INC     addr                              ; next address
        JSR     PCF_STOP

        DEC     XWORK
        LDA     XWORK
        CMPA    #$00
        BNE     lp2b                              ; of line

        SWI
        FCB     22

        DEC     YWORK
        LDA     YWORK
        CMPA    #$00
        LBNE    lp3b                              ; all done

;-------------------------------------------------------------------------
        LDX     #HSTBUF
        STX     POINTER
        LDX     #TESTMESSAGECONTROL
        LDY     #TESTMESSAGECONTROLEND-TESTMESSAGECONTROL
        JSR     MOVETOHOST

        LDA     #$3C
        LDY     #TESTMESSAGECONTROLEND-TESTMESSAGECONTROL
        LDX     #HSTBUF
        LDB     #42
        JSR     MD_PAGERA
        JSR     RESULT

        LDB     #43
        JSR     MD_PAGERA

;
;
;
;

        LDX     #HSTBUF
        STX     POINTER
        LDX     #TESTMESSAGEDATA
        LDY     #TESTMESSAGEDATAEND-TESTMESSAGEDATA
        JSR     MOVETOHOST

        LDA     #$3C
        LDY     #TESTMESSAGEDATAEND-TESTMESSAGEDATA
        LDX     #HSTBUF
        LDB     #42
        JSR     MD_PAGERA
        JSR     RESULT

;-------------------------------------------------------------------------
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'TEST PCF . . . Getting SD Block'


; send "I" command

        LDX     #HSTBUF
        STX     POINTER
        LDX     #SDSEND2
        LDY     #1
        JSR     MOVETOHOST

        LDA     #$25
        LDY     #1
        LDX     #HSTBUF
        LDB     #42
        JSR     MD_PAGERA
        JSR     RESULT

; send "R" command

        LDX     #HSTBUF
        STX     POINTER
        LDX     #SDSEND1
        LDY     #1
        JSR     MOVETOHOST

        LDA     #$25
        LDY     #1
        LDX     #HSTBUF
        LDB     #42
        JSR     MD_PAGERA
        JSR     RESULT

; get sector
        LDA     #$25
        LDY     #512
        LDX     #HSTBUF
        LDB     #41
        JSR     MD_PAGERA
        JSR     RESULT

; ouput results
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'SD INQUIRE:'
        LDA     $0300
        SWI
        FCB     33
        LDA     $0301
        SWI
        FCB     33
        LDA     #':'
        SWI
        FCB     33
        LDA     $0302
        SWI
        FCB     28
        LDA     $0303
        SWI
        FCB     28
        LDA     $0304
        SWI
        FCB     28
        LDA     $0305
        SWI
        FCB     28
        SWI
        FCB     22

; send "S" command
        LDX     #HSTBUF
        STX     POINTER
        LDX     #SDSEND
        LDY     #5
        JSR     MOVETOHOST

        LDA     #$25
        LDY     #5
        LDB     #42
        LDX     #HSTBUF
        JSR     MD_PAGERA
        JSR     RESULT

; send "R" command

        LDX     #HSTBUF
        STX     POINTER
        LDX     #SDSEND1
        LDY     #1
        JSR     MOVETOHOST

        LDA     #$25
        LDY     #1
        LDX     #HSTBUF
        LDB     #42
        JSR     MD_PAGERA
        JSR     RESULT

; get sector
        LDA     #$25
        LDY     #512
        LDX     #HSTBUF
        LDB     #41
        JSR     MD_PAGERA
        JSR     RESULT

        RTS


NOBB:
        JSR     PCF_BBERR
        RTS

MOVETOHOST:
        LDA     ,X+
        PSHS    X
        LDX     POINTER
        STA     ,X+
        STX     POINTER
        PULS    X
        DEY
        CMPY    #$0000
        BNE     MOVETOHOST
        RTS


;-----------------------------------------------------------------------------
_i2c_start:
PCF_START:
        LDA     #PCF_START_
        STA     PCF_RS1
        RTS
_i2c_stop:
PCF_STOP:
        LDA     #PCF_STOP_                        ; issue
        STA     PCF_RS1                           ; stop
        RTS                                       ; command
;
;-----------------------------------------------------------------------------
;
; CONTROL REGISTER BITS
;
PCF_PIN         = %10000000
PCF_ES0         = %01000000
PCF_ES1         = %00100000
PCF_ES2         = %00010000
PCF_EN1         = %00001000
PCF_STA         = %00000100
PCF_STO         = %00000010
PCF_ACK         = %00000001
;
; STATUS REGISTER BITS
;
;PCF_PIN  	.EQU  10000000B
PCF_INI         = %01000000                       ; 1 if not initialized
PCF_STS         = %00100000
PCF_BER         = %00010000
PCF_AD0         = %00001000
PCF_LRB         = %00001000
PCF_AAS         = %00000100
PCF_LAB         = %00000010
PCF_BB          = %00000001
;
PCF_START_      = PCF_PIN|PCF_ES0|PCF_STA|PCF_ACK
PCF_STOP_       = PCF_PIN|PCF_ES0|PCF_STO|PCF_ACK
;
; TIMEOUT AND DELAY VALUES (ARBITRARY)
;
PCF_PINTO       = 65000
PCF_ACKTO       = 65000
PCF_BBTO        = 65000
PCF_LABDLY      = 65000
;
PCF_STATUS:
        FCB     $00
;
;--------------------------------------------------------------------------------
;
; RETURN NZ/FF IF TIMEOUT ERROR
; RETURN NZ/01 IF FAILED TO RECEIVE ACKNOWLEDGE
; RETURN Z/00  IF RECEIVED ACKNOWLEDGE
;
PCF_WAIT_FOR_ACK:
        PSHS    X,Y
        LDX     #$0000
        STX     ACKWRK
;
PCF_WFA0:
        LDA     PCF_RS1                           ; READ PIN
        STA     PCF_STATUS                        ; STATUS
;
        PSHS    D
        LDD     ACKWRK
        ADDD    #$0001
        STD     ACKWRK
        TFR     D,X
        PULS    D
        CMPX    #PCF_ACKTO
        BEQ     PCF_WFA1                          ; WE HAVE
;
        ANDA    #PCF_PIN                          ; UNTIL WE GET PIN
        CMPA    #$00                              ; UNTIL WE GET PIN
        BNE     PCF_WFA0                          ; OR TIMEOUT
;
        LDA     PCF_STATUS                        ; WE GOT PIN SO NOW
        ANDA    #PCF_LRB                          ; CHECK WE HAVE
        CMPA    #$00                              ; CHECK WE HAVE
        BEQ     >                                 ; RECEIVED ACKNOWLEDGE
        LDA     #$01
        BRA     PCF_WFA2
!
        LDA     #$00
        BRA     PCF_WFA2
PCF_WFA1:
        LDA     #$FF
PCF_WFA2:
        PULS    X,Y                               ; EXIT WITH NZ = FF
        RTS
;
;-----------------------------------------------------------------------------
;
; POLL THE BUS BUSY BIT TO DETERMINE IF BUS IS FREE.
; RETURN WITH A=00H/Z STATUS IF BUS IS FREE
; RETURN WITH A=FFH/NZ STATUS IF BUS
;
; AFTER RESET THE BUS BUSY BIT WILL BE SET TO 1 I.E. NOT BUSY
;
PCF_WAIT_FOR_BB:
        PSHS    X,Y
        LDX     #$0000
        STX     ACKWRK
PCF_WFBB0:
        LDA     PCF_RS1
        ANDA    #PCF_BB
        CMPA    #PCF_BB
        BNE     >
        LDA     #$00
        PULS    X,Y
        RTS
!
        PSHS    D
        LDD     ACKWRK
        ADDD    #$0001
        STD     ACKWRK
        TFR     D,X
        PULS    D
        CMPX    #PCF_BBTO
        BNE     PCF_WFBB0
        LDA     #$FF
        PULS    X,Y
        RTS

;
;-----------------------------------------------------------------------------
; DISPLAY ERROR MESSAGES
;
PCF_RDERR:
        PSHS    D,X,Y
        LDX     #PCF_RDFAIL
        BRA     PCF_PRTERR
;
PCF_INIERR:
        PSHS    D,X,Y
        LDX     #PCF_NOPCF
        BRA     PCF_PRTERR
;
PCF_SETERR:
        PSHS    D,X,Y
        LDX     #PCF_WRTFAIL
        BRA     PCF_PRTERR
;
PCF_REGERR:
        PSHS    D,X,Y
        LDX     #PCF_REGFAIL
        BRA     PCF_PRTERR
;
PCF_CLKERR:
        PSHS    D,X,Y
        LDX     #PCF_CLKFAIL
        BRA     PCF_PRTERR
;
PCF_IDLERR:
        PSHS    D,X,Y
        LDX     #PCF_IDLFAIL
        BRA     PCF_PRTERR
;
PCF_ACKERR:
        PSHS    D,X,Y
        LDX     #PCF_ACKFAIL
        BRA     PCF_PRTERR
;
PCF_RDBERR:
        PSHS    D,X,Y
        LDX     #PCF_RDBFAIL
        BRA     PCF_PRTERR
;
PCF_TOERR:
        PSHS    D,X,Y
        LDX     #PCF_TOFAIL
        BRA     PCF_PRTERR
;
PCF_ARBERR:
        PSHS    D,X,Y
        LDX     #PCF_ARBFAIL
        BRA     PCF_PRTERR
;
PCF_PINERR:
        PSHS    D,X,Y
        LDX     #PCF_PINFAIL
        BRA     PCF_PRTERR
;
PCF_BBERR:
        PSHS    D,X,Y
        LDX     #PCF_BBFAIL
        BRA     PCF_PRTERR
;
PCF_PRTERR:
        SWI
        FCB     23
        SWI
        FCB     22
        PULS    D,X,Y
        RTS

RESULT:
        PSHS    A
        SWI
        FCB     24
        FCN     'PCF ERROR REPORTED:'
        PULS    A
        SWI
        FCB     28
        SWI
        FCB     22
        RTS

;
PCF_NOPCF:
        FCN     "NO DEVICE FOUND"
PCF_WRTFAIL:
        FCN     "SETTING DEVICE ID FAILED"
PCF_REGFAIL:
        FCN     "CLOCK REGISTER SELECT ERROR"
PCF_CLKFAIL:
        FCN     "CLOCK SET FAIL"
PCF_IDLFAIL:
        FCN     "BUS IDLE FAILED"
PCF_ACKFAIL:
        FCN     "FAILED TO RECEIVE ACKNOWLEDGE"
PCF_RDFAIL:
        FCN     "READ FAILED"
PCF_RDBFAIL:
        FCN     "READBYTES FAILED"
PCF_TOFAIL:
        FCN     "TIMEOUT ERROR"
PCF_ARBFAIL:
        FCN     "LOST ARBITRATION"
PCF_PINFAIL:
        FCN     "PIN FAIL"
PCF_BBFAIL:
        FCN     "BUS BUSY"

oprval:
        FCB     0
xaxis:
        FCB     0
yaxis:
        FCB     0
addr:
        FCB     0
rc:
        FCB     0

XWORK:
        FCB     0,0
YWORK:
        FCB     0,0
ACKWRK:
        FCB     0,0


PORT:
        FCB     $00

TESTMESSAGECONTROL:
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
TESTMESSAGECONTROLEND:


TESTMESSAGEDATA:
        FCB     $40
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
        FCB     $14,$14,$14,$14,$14               ; =
        FCB     $22,$14,$7F,$14,$02               ; *
TESTMESSAGEDATAEND:

SDSEND:
        FCB     'S',$00,$00,$00,$02

SDSEND1:
        FCB     'R'

SDSEND2:
        FCB     'I',$00

POINTER:
        FCB     $FF,$FF
