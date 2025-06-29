;__ESP DRIVERS______________________________________________________________________________________________________________
;
; 	CUBIX ISA DUAL ESP IO drivers for 6809PC
;
;	Entry points:
;		MULTIOINIT  - JSR ed during OS init
;		KBD_GETKEY  - read a character from the ps/2 keyboard ('A' POINTS TO BYTE)
;		LPT_OUT	    - send a character to the printer
;________________________________________________________________________________________________________________________________
;
;*
;*        HARDWARE I/O ADDRESSES
;*
;
ESP_BASE        EQU CUBIX_IO_BASE+$100
ESP0_DAT        EQU ESP_BASE                      ;
ESP1_DAT        EQU ESP_BASE+1                    ;
ESP_STAT        EQU ESP_BASE+2                    ;



;__________________________________________________________________________________________________
;
; STATUS BITS (FOR KBD_STATUS)
;
ESP0_RDY        EQU $01                           ; BIT 0, ESP0 READY
ESP0_BUSY       EQU $02                           ; BIT 1, ESP0 BUSY
ESP1_RDY        EQU $08                           ; BIT 3, ESP1 READY
ESP1_BUSY       EQU $10                           ; BIT 4, ESP1 BUSY
;
;__________________________________________________________________________________________________
; DATA
;__________________________________________________________________________________________________
;
;
;__________________________________________________________________________________________________
; ESP IO INITIALIZATION
;__________________________________________________________________________________________________
;
ESPINIT:
;
        JSR     LFCR                              ; AND CRLF
        LDX     #ESPMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
; KEYBOARD INITIALIZATION
        LDX     #MESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #ESP_BASE                      ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     LFCR                              ; AND CRLF
;
        JSR     ESP0_PROBE                         ; DETECT ESP0
        JSR     LFCR                              ; AND CRLF
        JSR     ESP1_PROBE                         ; DETECT ESP1
        JSR     LFCR                              ; AND CRLF
        RTS                                       ; DONE


ESP0_PROBE:
;
        LDX     #ESPMESSAGE2                      ; PRINT 'ESP0'
        JSR     WRSTR

        LDA     #$FF                              ; ESP IDENTITY PROBE
        JSR     PUTESP0                           ; SEND IT
        JSR     KBD_GETDATA                       ; CONTROLLER SHOULD RESPOND WITH 'ESP32V1'
        BCS     ESP_ERROR

        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'E'
        BNE     ESP_ERROR
        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'S'
        BNE     ESP_ERROR
        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'P'
        BNE     ESP_ERROR
        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'3'
        BNE     ESP_ERROR
        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'2'
        BNE     ESP_ERROR
        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'V'
        BNE     ESP_ERROR
        JSR     GETESP0
        BCS     ESP_ERROR
        CMPA    #'1'
        BNE     ESP_ERROR
        LDX     #ESPMESSAGE5                      ; PRINT 'FOUND'
        JSR     WRSTR
        CLC
        RTS
;
;
ESP_ERROR:
        LDX     #ESPMESSAGE4                      ; PRINT NOT FOUND
        JSR     WRSTR
        JSR     LFCR                              ; AND CRLF
        RTS

;
ESP1_PROBE:
;
        LDX     #ESPMESSAGE3                      ; PRINT 'ESP1'
        JSR     WRSTR

        LDA     #$FF                              ; ESP IDENTITY PROBE
        JSR     PUTESP1                           ; SEND IT
        JSR     KBD_GETDATA                       ; CONTROLLER SHOULD RESPOND WITH 'ESP32V1'
        BCS     ESP_ERROR

        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'E'
        BNE     ESP_ERROR
        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'S'
        BNE     ESP_ERROR
        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'P'
        BNE     ESP_ERROR
        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'3'
        BNE     ESP_ERROR
        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'2'
        BNE     ESP_ERROR
        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'V'
        BNE     ESP_ERROR
        JSR     GETESP1
        BCS     ESP_ERROR
        CMPA    #'1'
        BNE     ESP_ERROR
        LDX     #ESPMESSAGE5                      ; PRINT 'FOUND'
        JSR     WRSTR
        CLC
        RTS


;
;__________________________________________________________________________________________________
; HARDWARE INTERFACE
;__________________________________________________________________________________________________
;
; a=VALUE AND RETURN
; Carry set on timeout
;
;__________________________________________________________________________________________________
PUTESP0:
        PSHS    X,B
        LDX     #$2500
!
        LDB     ESP_STAT
        ANDB    #ESP0_BUSY
        BEQ     >
        DEX
        BNE     <
        PULS    X,B
        SEC
        RTS
!
        STA     ESP0_DAT
        PULS    X,B
        CLC
        RTS

GETESP0:
        PSHS    X,B
        LDX     #$FF00
!
        LDB     ESP_STAT
        ANDB    #ESP0_BUSY
        BEQ     >
        DEX
        BNE     <
        PULS    X,B
        SEC
        RTS
!
        LDX     #$FF00
!
        LDB     ESP_STAT
        ANDB    #ESP0_OUTPUT
        BNE     >
        DEX
        BNE     <
        PULS    X,B
        SEC
        RTS
!
        LDA     ESP0_DAT
        PULS    X,B
        CLC
        RTS

PUTESP1:
        PSHS    X,B
        LDX     #$2500
!
        LDB     ESP_STAT
        ANDB    #ESP1_BUSY
        BEQ     >
        DEX
        BNE     <
        PULS    X,B
        SEC
        RTS
!
        STA     ESP1_DAT
        PULS    X,B
        CLC
        RTS

GETESP1:
        PSHS    X,B
        LDX     #$FF00
!
        LDB     ESP_STAT
        ANDB    #ESP1_BUSY
        BEQ     >
        DEX
        BNE     <
        PULS    X,B
        SEC
        RTS
!
        LDX     #$FF00
!
        LDB     ESP_STAT
        ANDB    #ESP1_OUTPUT
        BNE     >
        DEX
        BNE     <
        PULS    X,B
        SEC
        RTS
!
        LDA     ESP1_DAT
        PULS    X,B
        CLC
        RTS



;
; DRIVER DATA
;__________________________________________________________________________________________________
; MESSAGES
;__________________________________________________________________________________________________
ESPMESSAGE1:
        FCC     "DUAL ESP IO:"
        FCB     00
ESPMESSAGE2:
        FCC     "  ESP0: "
        FCB     00
ESPMESSAGE3:
        FCC     "  ESP1: "
        FCB     00
ESPMESSAGE4:
        FCC     "NOT "
ESPMESSAGE5:
        FCC     "FOUND."
        FCB     00
