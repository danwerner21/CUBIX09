;__PCF DRIVER____________________________________________________________________________________________________________________
;
; PCF8584 I2C DRIVER
;
;       Entry points:
;               PCF_INIT
;               PCF_SENDBYTES
;               PCF_READBYTES
;               PCF_INITDEV
;
;________________________________________________________________________________________________________________________________
;
;
PCF_BASE        = $DF56                           ; PORT
PCF_ID          = $AA
CPU_CLK         = 8
;
PCF_RS0         = PCF_BASE
PCF_RS1         = PCF_RS0+1
PCF_OWN         = $55                             ; PCF_ID>>1   PCF'S ADDRESS IN SLAVE MODE  (LWASM does not seem to have a bit shift operator)
;
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
PCF_START_      = PCF_PIN|PCF_ES0|PCF_STA|PCF_ACK
PCF_STOP_       = PCF_PIN|PCF_ES0|PCF_STO|PCF_ACK
;PCF_REPSTART_   = PCF_ES0|PCF_STA|PCF_ACK
PCF_IDLE_       = PCF_PIN|PCF_ES0|PCF_ACK
;
; STATUS REGISTER BITS
;
;PCF_PIN        =  %10000000
PCF_INI         = %01000000                       ; 1 if not initialized
PCF_STS         = %00100000
PCF_BER         = %00010000
PCF_AD0         = %00001000
PCF_LRB         = %00001000
PCF_AAS         = %00000100
PCF_LAB         = %00000010
PCF_BB          = %00000001
;
; THE PCF8584 TARGETS A TOP I2C CLOCK SPEED OF 90KHZ AND SUPPORTS DIVIDERS FOR
; 3, 4.43, 6, 8 AND 12MHZ TO ACHEIVE THIS.
;
; +--------------------------------------------------------------------------------------------+
; | div/clk |  2MHz |  4MHz  |  6MHz | 7.38Mhz |  10MHz | 12MHz |  16MHz | 18.432Mhz |  20MHz  |
; +----------------------------------------------------------------------------------+---------+
; |   3MHz  | 60Khz | 120Khz |       |         |        |       |        |           |         |
; | 4.43MHz |       |  81Khz |       |         |        |       |        |           |         |
; |   6MHz  |       |        | 90Khz | 110Khz  |        |       |        |           |         |
; |   8MHz  |       |        |       |  83Khz  | 112Khz |       |        |           |         |
; |  12MHz  |       |        |       |         |        | 90Khz | 120Khz |   138Khz  |  150Khz |
; +----------------------------------------------------------------------------------+---------+
;
; CLOCK CHIP FREQUENCIES
;
PCF_CLK3        = $00
PCF_CLK443      = $10
PCF_CLK6        = $14
PCF_CLK8        = $18
PCF_CLK12       = $1C
;
; TRANSMISSION FREQUENCIES
;
PCF_TRNS90      = $00                             ;  90 kHz */
PCF_TRNS45      = $01                             ;  45 kHz */
PCF_TRNS11      = $02                             ;  11 kHz */
PCF_TRNS15      = $03                             ; 1.5 kHz */
;
; BELOW VARIABLES CONTROL PCF CLOCK DIVISOR PROGRAMMING
; HARD-CODED FOR NOW
;
PCF_CLK         = PCF_CLK8
PCF_TRNS        = PCF_TRNS90
;
; TIMEOUT AND DELAY VALUES (ARBITRARY)
;
PCF_PINTO       = 65000
PCF_ACKTO       = 65000
PCF_BBTO        = 65000
PCF_LABDLY      = 65000
;
;
;__PCF_INIT___________________________________________________________________________________________
;
;  FRONT PANEL INIT
;____________________________________________________________________________________________________
;
PCF_INIT:
        JSR     LFCR                              ; AND CRLF
        LDX     #PCFMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        LDD     #PCF_BASE                         ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     SPACE
        JSR     PCF_INITDEV
        LDA     PCF_FAIL_FLAG
        CMPA    #$00
        BNE     >
        LDX     #PCF_PCFOK
        JSR     WRSTR
!
        JSR     LFCR                              ; AND CRLF
        RTS                                       ; DONE
PCFMESSAGE1:
        FCC     "I2C PCF:"
        FCB     $0D,$0A
        FCN     " IO=0x"
;-----------------------------------------------------------------------------
;
PCF_INITDEV:
        LDA     #PCF_PIN                          ; S1=80H: S0 SELECTED, SERIAL
        STA     PCF_RS1                           ; INTERFACE OFF
        NOP
        LDA     PCF_RS1                           ; CHECK TO SEE S1 NOW USED AS R/W
        ANDA    #$7F                              ; CTRL. PCF8584 DOES THAT WHEN ESO
        BNE     PCF_FAIL                          ; IS ZERO
;
        LDA     #PCF_OWN                          ; LOAD OWN ADDRESS IN S0,
        STA     PCF_RS0                           ; EFFECTIVE ADDRESS IS (OWN <<1)
        NOP
        LDA     PCF_RS0                           ; CHECK IT IS REALLY WRITTEN
        CMPA    #PCF_OWN
        LBNE    PCF_SETERR
;
        LDA     #PCF_PIN|PCF_ES1                  ; S1=0A0H
        STA     PCF_RS1                           ; NEXT BYTE IN S2
        NOP
        LDA     PCF_RS1
;
        LDA     #PCF_CLK|PCF_TRNS                 ; LOAD CLOCK REGISTER S2
        STA     PCF_RS0
        NOP
        LDA     PCF_RS0                           ; CHECK IT'S REALLY WRITTEN, ONLY
        ANDA    #$1F                              ; THE LOWER 5 BITS MATTER
        CMPA    #PCF_CLK|PCF_TRNS
        LBNE    PCF_CLKERR
;
        LDA     #PCF_IDLE_
        STA     PCF_RS1
        NOP
        LDA     PCF_RS1
        CMPA    #PCF_PIN|PCF_BB
        LBNE    PCF_IDLERR
;
        LDA     #$00
        STA     PCF_FAIL_FLAG
        RTS
;
PCF_FAIL:
        JSR     PCF_INIERR
        LDA     #$FF
        STA     PCF_FAIL_FLAG
        RTS
;
PCF_FAIL_FLAG:
        FCB     0
;
;
;--------------------------------------------------------------------------------
;
;       Y = COUNT
;       A = Device Address/Return Status
;   RETURN FF=ERROR
;          00=SUCCESS
;
PCF_SENDBYTES:
        LDA     PCF_FAIL_FLAG
        CMPA    #$00
        BNE     PCF_WERROR
        LDX     >PAGER_X
        LDY     >PAGER_Y                          ; RESTORE 'Y'
        LDD     >PAGER_D                          ; RESTORE 'D'
PCF_SENDBYTES_INTERNAL:
        PSHS    A,X,Y
        JSR     PCF_WAIT_FOR_BB                   ; DO WE HAVE THE BUS?
        CMPA    #$00
        BEQ     PCF_WB1                           ; YES
        PULS    A,X,Y
        LDA     #$FF
        STA     >PAGER_D                          ; STORE 'A'
        RTS
PCF_WB1:
        PULS    A,X,Y
        ASLA
        ANDA    #$FE
        STA     PCF_RS0                           ; send device address
        LDA     #PCF_START_                       ; begin transmission
        STA     PCF_RS1
!
        JSR     PCF_WAIT_FOR_PIN
        CMPA    #$00
        BNE     PCF_WERROR
        LDA     ,X+
        STA     PCF_RS0
        DEY
        CMPY    #$0000
        BNE     <
        JSR     PCF_WAIT_FOR_PIN
        CMPA    #$00
        BNE     PCF_WERROR
        LDA     #PCF_STOP_                        ; end transmission
        STA     PCF_RS1
        LDA     #$00
        STA     >PAGER_D                          ; STORE 'A'
        RTS
PCF_WERROR:
        LDA     #PCF_STOP_                        ; end transmission
        STA     PCF_RS1
        LDA     #$FF
        STA     >PAGER_D                          ; STORE 'A'
        RTS
;
;--------------------------------------------------------------------------------
;
;       Y = COUNT
;       A = Device Address/Return Status
;   RETURN FF=ERROR
;          00=SUCCESS
;
PCF_READBYTES:
        LDA     PCF_FAIL_FLAG
        CMPA    #$00
        BNE     PCF_RERROR
        LDX     >PAGER_X
        LDY     >PAGER_Y                          ; RESTORE 'Y'
        LDD     >PAGER_D                          ; RESTORE 'D'
PCF_READBYTES_INTERNAL:
        ASLA
        ORA     #$01
        STA     PCF_RS0                           ; send device address
        PSHS    A,X,Y
        JSR     PCF_WAIT_FOR_BB                   ; DO WE HAVE THE BUS?
        CMPA    #$00
        BEQ     PCF_RB1                           ; YES
        PULS    A,X,Y
        LDA     #$FF
        STA     >PAGER_D                          ; STORE 'A'
        RTS
PCF_RB1:
        PULS    A,X,Y
        LDA     #PCF_START_                       ; begin rcv
        STA     PCF_RS1
        JSR     PCF_WAIT_FOR_PIN
        LDA     PCF_RS0
!
        JSR     PCF_WAIT_FOR_PIN
        CMPA    #$00
        BNE     PCF_RERROR
        CMPY    #$0001
        BEQ     >
        LDA     PCF_RS0
        STA     ,X+
        DEY
        BRA     <
!
        LDA     #PCF_INI                          ; ack
        STA     PCF_RS1
        LDA     PCF_RS0
        STA     ,X+
        JSR     PCF_WAIT_FOR_PIN
        LDA     #PCF_STOP_                        ; end RCV
        STA     PCF_RS1
        LDA     PCF_RS0
        STA     ,X+
        LDA     #$00
        STA     >PAGER_D                          ; STORE 'A'
        RTS
PCF_RERROR:
        LDA     #PCF_STOP_                        ; end RCV
        STA     PCF_RS1
        LDA     #$FF
        STA     >PAGER_D                          ; STORE 'A'
        RTS
;
;
;-----------------------------------------------------------------------------
;
; RETURN A=00/Z  IF SUCCESSFULL
; RETURN A=FF/NZ IF TIMEOUT
; RETURN A=01/NZ IF LOST ARBITRATION
; PCF_STATUS HOLDS LAST PCF STATUS
;
PCF_WAIT_FOR_PIN:
        PSHS    X
        LDX     #PCF_PINTO                        ; SET TIMEOUT VALUE
PCF_WFP0:
        LDA     PCF_RS1                           ; GET BUS
        STA     PCF_STATUS                        ; STATUS
        DEX                                       ; HAVE WE TIMED OUT
        CMPX    #$00
        BEQ     PCF_WFP1                          ; YES WE HAVE, GO ACTION IT
        ANDA    #PCF_PIN                          ; IS TRANSMISSION COMPLETE?
        CMPA    #$00
        BNE     PCF_WFP0                          ; KEEP ASKING IF NOT OR
        LDA     PCF_STATUS                        ; WE GOT PIN SO NOW
        ANDA    #PCF_LRB                          ; CHECK WE HAVE
        CMPA    #$00                              ; CHECK WE HAVE
        BEQ     >                                 ; RECEIVED ACKNOWLEDGE
        LDA     #$01
        BRA     PCF_WFP2
!
        LDA     #$00
        BRA     PCF_WFP2
PCF_WFP1:
        LDA     #$FF
PCF_WFP2:
        PULS    X                                 ; RET NZ, A=FF IF TIMEOUT
        RTS
;
PCF_STATUS
        FCB     $00
;-----------------------------------------------------------------------------
;
; POLL THE BUS BUSY BIT TO DETERMINE IF BUS IS FREE.
; RETURN WITH A=00H/Z STATUS IF BUS IS FREE
; RETURN WITH A=FFH/NZ STATUS IF BUS IS BUSY
;
; AFTER RESET THE BUS BUSY BIT WILL BE SET TO 1 I.E. NOT BUSY
;
PCF_WAIT_FOR_BB:
        LDX     #PCF_BBTO
PCF_WFBB0:
        LDA     PCF_RS1
        ANDA    #PCF_BB
        CMPA    #PCF_BB
        BEQ     >
        DEX
        CMPA    #$00
        BNE     PCF_WFBB0                         ; REPEAT IF NOT TIMED OUT
        LDA     #$FF                              ; RET NZ IF TIMEOUT
        RTS
!
        LDA     #$00
        RTS
;
;-----------------------------------------------------------------------------
; DISPLAY ERROR MESSAGES
;
PCF_RDERR:
        PSHS    X
        LDX     #PCF_RDFAIL
        BRA     PCF_PRTERR
;
PCF_INIERR:
        PSHS    X
        LDX     #PCF_NOPCF
        BRA     PCF_PRTERR
;
PCF_SETERR:
        PSHS    X
        LDX     #PCF_WRTFAIL
        BRA     PCF_PRTERR
;
PCF_CLKERR:
        PSHS    X
        LDX     #PCF_CLKFAIL
        BRA     PCF_PRTERR
;
PCF_IDLERR:
        PSHS    X
        LDX     #PCF_IDLFAIL
        BRA     PCF_PRTERR
;
PCF_ACKERR:
        PSHS    X
        LDX     #PCF_ACKFAIL
        BRA     PCF_PRTERR
;
PCF_RDBERR:
        PSHS    X
        LDX     #PCF_RDBFAIL
        BRA     PCF_PRTERR
;
PCF_TOERR:
        PSHS    X
        LDX     #PCF_TOFAIL
        BRA     PCF_PRTERR
;
PCF_ARBERR:
        PSHS    X
        LDX     #PCF_ARBFAIL
        BRA     PCF_PRTERR
;
PCF_PINERR:
        PSHS    X
        LDX     #PCF_PINFAIL
        BRA     PCF_PRTERR
;
PCF_BBERR:
        PSHS    X
        LDX     #PCF_BBFAIL
        BRA     PCF_PRTERR
;
PCF_PRTERR:
        JSR     WRSTR
        LDA     #$FF
        STA     PCF_FAIL_FLAG
        PULS    X
        RTS
;
;-----------------------------------------------------------------------------
; DEBUG HELPER
;
PCF_PCFOK:
        FCN     "PRESENT"
PCF_NOPCF:
        FCN     "NOT PRESENT"

PCF_WRTFAIL:
        FCN     "SETTING DEVICE ID FAILED"

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
