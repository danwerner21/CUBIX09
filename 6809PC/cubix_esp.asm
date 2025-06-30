;__ESP DRIVERS______________________________________________________________________________________________________________
;
; 	CUBIX ISA DUAL ESP IO drivers for 6809PC
;
;	Entry points:
;		ESPINIT     - INIT HARDWARE
;		ESPVIDEOOUT - OUTPUT A CHARACTER TO VIDEO (ANSI)
;               ESPPS2IN    - read a character from the ps/2 keyboard ('A' POINTS TO BYTE)
;               ESPPS2BUFL  - return number of characters in the keyboard buffer in 'A'
;               ESPCURSORV  - Set Cursor Visibility (A=0 cursor off, A=1 cursor on)
;		ESPSER0OUT  - OUTPUT A CHARACTER TO Serial 0 ('A' POINTS TO BYTE)
;               ESPSER0IN   - read a character from Serial 0 ('A' POINTS TO BYTE)
;               ESPSER0BUFL - return number of characters in the Serial 0 buffer in 'A'
;		ESPSER1OUT  - OUTPUT A CHARACTER TO Serial 1 ('A' POINTS TO BYTE)
;               ESPSER1IN   - read a character from Serial 1 ('A' POINTS TO BYTE)
;               ESPSER1BUFL - return number of characters in the Serial 1 buffer in 'A'
;		ESPNETCOUT  - OUTPUT A CHARACTER TO Network Console Connection ('A' POINTS TO BYTE)
;               ESPNETCIN   - read a character from Network Console Connection ('A' POINTS TO BYTE)
;               ESPNETCBUFL - return number of characters in the Network Connection buffer in 'A'
;               PUTESP0     - put opcode/data to ESP0
;               PUTESP1     - put opcode/data to ESP1
;               GETESP0     - get opcode/data from ESP0
;               GETESP1     - get opcode/data from ESP1
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
        IFNDEF  BIOS6809PC
ESPINIT:
;
        JSR     LFCR                              ; AND CRLF
        LDX     #ESPMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
; KEYBOARD INITIALIZATION
        LDX     #MESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #ESP_BASE                         ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     LFCR                              ; AND CRLF
;
        JSR     ESP0_PROBE                        ; DETECT ESP0
        JSR     LFCR                              ; AND CRLF
        JSR     ESP1_PROBE                        ; DETECT ESP1
        JSR     LFCR                              ; AND CRLF
        RTS                                       ; DONE


ESP0_PROBE:
;
        LDX     #ESPMESSAGE2                      ; PRINT 'ESP0'
        JSR     WRSTR

        LDA     #$FF                              ; ESP IDENTITY PROBE
        JSR     PUTESP0                           ; SEND IT
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
        LDX     #$20
!
        LDA     #00
        JSR     PUTESP0
        LEAX    -1,X
        BNE     <
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
        LDX     #$20
!
        LDA     #00
        JSR     PUTESP1
        LEAX    -1,X
        BNE     <
        CLC
        RTS

;__________________________________________________________________________________________________
; ESPCURSORV  - Set Cursor Visibility (A=0 cursor off, A=1 cursor on)
;__________________________________________________________________________________________________
;
ESPCURSORV:
        PSHS    A
        LDA     #05                               ; ESP OPCODE
        JSR     PUTESP0                           ; SEND IT
        PULS    A
        JSR     PUTESP0                           ; SEND IT
        RTS
;__________________________________________________________________________________________________
; ESPSER0OUT  - OUTPUT A CHARACTER TO Serial 0 ('A' POINTS TO BYTE)
;__________________________________________________________________________________________________
;
ESPSER0OUT:
        PSHS    A
        LDA     #08                               ; ESP OPCODE
        JSR     PUTESP0                           ; SEND IT
        PULS    A
        JSR     PUTESP0                           ; SEND IT
        RTS
;__________________________________________________________________________________________________
; ESPSER0IN   - read a character from Serial 0 ('A' POINTS TO BYTE)
;__________________________________________________________________________________________________
;
ESPSER0IN:
        LDA     #10                               ; ESP IN FROM Serial 0
        JMP     ESPCHIN
;__________________________________________________________________________________________________
; ESPSER1OUT  - OUTPUT A CHARACTER TO Serial 1 ('A' POINTS TO BYTE)
;__________________________________________________________________________________________________
;
ESPSER1OUT:
        PSHS    A
        LDA     #08                               ; ESP OPCODE
        JSR     PUTESP1                           ; SEND IT
        PULS    A
        JSR     PUTESP1                           ; SEND IT
        RTS
;__________________________________________________________________________________________________
; ESPSER1IN   - read a character from Serial 1 ('A' POINTS TO BYTE)
;__________________________________________________________________________________________________
;
ESPSER1IN:
        LDA     #10                               ; ESP IN FROM Serial 1
ESPCH1IN:
        JSR     PUTESP1                           ; SEND IT
        BCS     >
        JSR     GETESP1                           ; GET IT
        BCS     >
        CMPA    #$00
        BEQ     >
        STA     >PAGER_D                          ; SAVE 'D'
        RTS
!
        LDA     #$FF
        STA     >PAGER_D                          ; SAVE 'D'
        RTS

;__________________________________________________________________________________________________
; ESPNETCOUT  - OUTPUT A CHARACTER TO Network Console Connection ('A' POINTS TO BYTE)
;               Connection Stored in 'consoleConnect' value
;__________________________________________________________________________________________________
;
ESPNETCOUT:
        PSHS    A
        LDA     #25                               ; ESP OPCODE
        JSR     PUTESP0                           ; SEND IT
        LDA     consoleConnect
        JSR     PUTESP0                           ; SEND IT
        PULS    A
        JSR     PUTESP0                           ; SEND IT
        RTS
;__________________________________________________________________________________________________
; ESPNETCIN   - read a character from Network Console Connection ('A' POINTS TO BYTE)
;__________________________________________________________________________________________________
;
ESPNETCIN:
        LDA     #26                               ; ESP OPCODE
        JSR     PUTESP0                           ; SEND IT
        LDA     consoleConnect
        JMP     ESPCH1IN

;__________________________________________________________________________________________________
; ESPPS2BUFL - Return number of characters in keyboard buffer
;__________________________________________________________________________________________________
;
ESPPS2BUFL:
        LDA     #04                               ; opcode to get buffer length
        JSR     PUTESP0                           ; SEND IT
        BCS     >
        JSR     GETESP0                           ; GET IT
        BCS     >
        STA     >PAGER_D                          ; SAVE 'D'
        RTS
!
        LDA     #$00
        STA     >PAGER_D                          ; SAVE 'D'
        RTS


;__________________________________________________________________________________________________
; ESPSER0BUFL - return number of characters in the Serial 0 buffer in 'A'
;__________________________________________________________________________________________________
;
ESPSER0BUFL:
        LDA     #11                               ; opcode to get buffer length
        JSR     PUTESP0                           ; SEND IT
        BCS     >
        JSR     GETESP0                           ; GET IT
        BCS     >
        STA     >PAGER_D                          ; SAVE 'D'
        RTS
!
        LDA     #$00
        STA     >PAGER_D                          ; SAVE 'D'
        RTS

;__________________________________________________________________________________________________
; ESPSER1BUFL - return number of characters in the Serial 1 buffer in 'A'
;__________________________________________________________________________________________________
;
ESPSER1BUFL:
        LDA     #11                               ; opcode to get buffer length
ESP1BUFL:
        JSR     PUTESP1                           ; SEND IT
        BCS     >
        JSR     GETESP1                           ; GET IT
        BCS     >
        STA     >PAGER_D                          ; SAVE 'D'
        RTS
!
        LDA     #$00
        STA     >PAGER_D                          ; SAVE 'D'
        RTS
;__________________________________________________________________________________________________
; ESPNETCBUFL - return number of characters in the Network Connection buffer in 'A'
;__________________________________________________________________________________________________
;
ESPNETCBUFL:
        LDA     #28                               ; opcode to get buffer length
        JMP     ESP1BUFL

        ENDIF
;__________________________________________________________________________________________________
; ESPVIDEOOUT - output character in 'A' to CRT (ANSI terminal emulation)
;__________________________________________________________________________________________________
;
ESPVIDEOOUT:
        PSHS    A
        LDA     #01                               ; ESP OUT TO SCREEN
        JSR     PUTESP0                           ; SEND IT
        PULS    A
        JSR     PUTESP0                           ; SEND IT
        RTS
;__________________________________________________________________________________________________
; ESPPS2IN - Fetch character out of Keyboard Buffer into 'A'  ($FF is no characters waiting)
;__________________________________________________________________________________________________
;
ESPPS2IN:
        LDA     #03                               ; ESP IN FROM PS2
ESPCHIN:
        JSR     PUTESP0                           ; SEND IT
        BCS     >
        JSR     GETESP0                           ; GET IT
        BCS     >
        CMPA    #$00
        BEQ     >
        IFNDEF  BIOS6809PC
        STA     >PAGER_D                          ; SAVE 'D'
        ENDIF
        RTS
!
        LDA     #$FF
        IFNDEF  BIOS6809PC
        STA     >PAGER_D                          ; SAVE 'D'
        ENDIF
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
        ANDB    #ESP0_RDY
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
        ANDB    #ESP1_RDY
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


        IFNDEF  BIOS6809PC
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
        ENDIF
