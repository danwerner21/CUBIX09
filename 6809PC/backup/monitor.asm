        PRAGMA  CD

;__MONITOR_________________________________________________________________________________________
;
;	MINI ROM MONITOR FOR THE DUODYNE 6809 PROCESSOR
;
;	WRITTEN BY: DAN WERNER -- 1/14/2024
;	based on the ROM by Andrew Lynch
;
;___________________________________________________________________________________________________
;
; DATA CONSTANTS
;___________________________________________________________________________________________________
;

; REGISTERS FOR GO
SP              EQU $0100                         ; S-HIGH
; END REGISTERS FOR GO
CKSM            EQU $0102                         ; CHECKSUM
BYTECT          EQU $0103                         ; BYTE COUNT
XHI             EQU $0104                         ; XREG HIGH
XLOW            EQU $0105                         ; XREG LOW

MONSTACK        EQU $1000                         ; STACK POINTER

IOSPACE         EQU $EF00
UART1DATA       EQU IOSPACE+$84                   ; SERIAL PORT 1 (I/O Card)
UART1STATUS     EQU IOSPACE+$85                   ; SERIAL PORT 1 (I/O Card)
UART1COMMAND    EQU IOSPACE+$86                   ; SERIAL PORT 1 (I/O Card)
UART1CONTROL    EQU IOSPACE+$87                   ; SERIAL PORT 1 (I/O Card)

;
;
;

        ORG     $F000


;___________________________________________________________________________________________________
;
; 	INITIALIZE 6809
;___________________________________________________________________________________________________
MAIN:
        LDS     #MONSTACK                         ; RESET STACK POINTER
        CLRA                                      ; set direct page register to 0
        TFR     A,DP                              ;

        CLRA                                      ; CLEAR ACCUMULATOR A

        LDA     #$00                              ; RESET UART
        STA     UART1STATUS                       ;
        LDA     #$0B                              ;
        STA     UART1COMMAND                      ;
        LDA     #$1E                              ; 9600, 8 BITS, NO PARITY, 1 STOP BIT
        STA     UART1CONTROL                      ;


alivea:
        LDA     UART1STATUS                       ; GET STATUS
        ANDA    #%00010000                        ; IS TX READY
        BEQ     alivea                            ; NO, WAIT FOR IT
        LDA     #'*'
        STA     UART1DATA                         ; WRITE DATA


;__CONTRL_________________________________________________________________________________________
;
; 	MONITOR MAIN LOOP
;__________________________________________________________________________________________________
CONTRL:
        JSR     DISPLAY_CRLF                      ; DISPLAY CRLF
        LDA     #'>'                              ; CARRIAGE RETURN
        JSR     WRSER1                            ; OUTPUT CHARACTER
        JSR     IOF_CONINW                        ;
        JSR     WRSER1                            ; OUTPUT CHAR TO CONSOLE
;
        CMPA    #'D'                              ; IS DUMP MEMORY?
        BEQ     DUMP                              ;
        CMPA    #'L'                              ; IS LOAD?
        BEQ     MLOAD                             ; YES, JUMP
        CMPA    #'M'                              ; IS CHANGE?
        BEQ     CHANGE                            ; YES, JUMP
        CMPA    #'P'                              ; IS PRINT?
        BEQ     PRINT                             ; YES, JUMP
        CMPA    #'G'                              ; IS GO?
        BEQ     GO                                ; YES JUMP
;
; COMMAND NOT FOUND ISSUE ERROR
        LDA     #'?'                              ; PRINT '?'
        JSR     WRSER1                            ; OUTPUT CHARACTER
        JSR     DISPLAY_CRLF                      ; DISPLAY CRLF
        JMP     CONTRL                            ; RECEIVE NEXT CHARACTER

MLOAD:
        JMP     MONLOAD


DUMP:
        JSR     OUTS                              ;
        JSR     BADDR                             ;
        PSHS    X                                 ;
        JSR     OUTS                              ;
        JSR     BADDR                             ;
        PULS    X                                 ;
        JSR     DISPLAY_CRLF                      ;
DUMP_LOOP:
        JSR     DUMP_LINE                         ;
        CMPX    XHI                               ;
        BMI     DUMP_LOOP                         ;
        JMP     CONTRL                            ; RECEIVE NEXT CHARACTER


GO:
        JSR     BADDR                             ; GET ADDRESS
        JSR     OUTS                              ; PRINT SPACE
        LDX     XHI                               ; LOAD X WITH ADDRESS
        JMP     $0000,X                           ; JUMP TO ADDRESS

; CHANGE MEMORY(M AAAA DD NN)
CHANGE:
        JSR     BADDR                             ; BUILD ADDRESS
        JSR     OUTS                              ; PRINT SPACE
        JSR     OUT2HS                            ;
        JSR     BYTE                              ;
        LEAX    -1,X                              ;
        STA     ,X                                ;
        CMPA    ,X                                ;
        BNE     LOAD19                            ; MEMORY DID NOT CHANGE
        JMP     CONTRL                            ;

; PRINT CONTENTS OF STACK
PRINT:
        STS     SP                                ;
        LDX     SP                                ;
        LDB     #$09                              ;
PRINT2: ;
        JSR     OUT2HS                            ; OUT 2 HEX & SPACE
        DECB                                      ;
        BNE     PRINT2                            ; DONE? IF NO DO MORE
        JMP     CONTRL                            ; DONE? IF YES RETURN TO MAIN LOOP


MONLOAD:

LOAD3:
        JSR     IOF_CONINW
        CMPA    #'S'
        BNE     LOAD3                             ; FIRST CHAR NOT (S)
        JSR     IOF_CONINW                        ; READ CHAR
        CMPA    #'9'
        BEQ     LOAD21
        CMPA    #'1'
        BNE     LOAD3                             ; SECOND CHAR NOT (1)
        CLR     CKSM                              ; ZERO CHECKSUM
        JSR     BYTE                              ; READ BYTE
        SUBA    #$02
        STA     BYTECT                            ; BYTE COUNT
; BUILD ADDRESS
        BSR     BADDR
; STORE DATA
LOAD11:
        JSR     BYTE
        DEC     BYTECT
        BEQ     LOAD15                            ; ZERO BYTE COUNT
        STA     ,X                                ; STORE DATA
        LEAX    1,X
        BRA     LOAD11

LOAD15:
        INC     CKSM
        BEQ     LOAD3
LOAD19:
        LDA     #'?'
        JSR     WRSER1
LOAD21:
C1
        JMP     CONTRL



DUMP_LINE:
        JSR     OUTADDR                           ;
        JSR     OUTS                              ;
        PSHS    X                                 ;
        LDB     #$10                              ;
DUMP_LINE_LOOP:
        JSR     OUT2HS                            ; OUT 2 HEX & SPACE
        DECB                                      ;
        BNE     DUMP_LINE_LOOP                    ; DONE? IF NO DO MORE
        PULS    X                                 ;
        JSR     OUTS                              ;
        LDA     #':'                              ;
        JSR     WRSER1                            ;
        LDB     #$10                              ;
DUMP_LINE_LOOPA:
        LDA     0,X                               ;
        CMPA    #32                               ;
        BMI     DUMP_LINE_INVALID
        CMPA    #127                              ;
        BPL     DUMP_LINE_INVALID
        JSR     WRSER1                            ;
        JMP     DUMP_LINE_VALID
DUMP_LINE_INVALID:                                ;
        LDA     #'.'                              ;
        JSR     WRSER1                            ;
DUMP_LINE_VALID:                                  ;
        LEAX    1,X                               ;
        DECB                                      ;
        BNE     DUMP_LINE_LOOPA                   ; DONE? IF NO DO MORE
        JSR     DISPLAY_CRLF                      ;
        RTS

; INPUT HEX CHAR
INHEX:
        JSR     IOF_CONINW                        ;
        PSHS    A                                 ;
        JSR     WRSER1                            ;
        PULS    A                                 ;
        CMPA    #$30                              ;
        BMI     C1                                ; NOT HEX
        CMPA    #$39                              ;
        BLE     IN1HG                             ;
        CMPA    #$41                              ;
        BMI     C1                                ; NOT HEX
        CMPA    #$46                              ;
        BGT     C1                                ; NOT HEX
        SUBA    #$07                              ;
IN1HG:  ;
        RTS                                       ;

; BUILD ADDRESS
BADDR:
        BSR     BYTE                              ; READ 2 FRAMES
        STA     XHI
        BSR     BYTE
        STA     XLOW
        LDX     XHI                               ; (X) ADDRESS WE BUILT
        RTS

; INPUT BYTE (TWO FRAMES)
BYTE:
        BSR     INHEX                             ; GET HEX CHAR
        ASLA
        ASLA
        ASLA
        ASLA
        TFR     A,B                               ; TAB
        TSTA                                      ; TAB
        BSR     INHEX
        ANDA    #$0F                              ; MASK TO 4 BITS
        PSHS    B                                 ; ABA
        ADDA    ,S+                               ; ABA
        TFR     A,B                               ; TAB
        TSTA                                      ; TAB
        ADDB    CKSM
        STB     CKSM
        RTS



MONOUTHL:
        LSRA                                      ; OUT HEX LEFT BCD DIGIT
        LSRA                                      ;
        LSRA                                      ;
        LSRA                                      ;

MONOUTHR:                                         ;
        ANDA    #$0F                              ; OUT HEC RIGHT DIGIT
        ADDA    #$30                              ;
        CMPA    #$39                              ;
        BLS     OUTHR1                            ;
        ADDA    #$07                              ;
OUTHR1:
        JMP     WRSER1                            ;

OUT2H:
        LDA     0,X                               ; OUTPUT 2 HEX CHAR
        BSR     MONOUTHL                          ; OUT LEFT HEX CHAR
        LDA     0,X                               ;
        BSR     MONOUTHR                          ; OUT RIGHT HEX CHAR
        LEAX    1,X
        RTS

OUTADDR:
        PSHS    X                                 ;
        PULS    A                                 ;
        PSHS    A                                 ;
        BSR     MONOUTHL                          ; OUT LEFT HEX CHAR
        PULS    A                                 ;
        BSR     MONOUTHR                          ; OUT RIGHT HEX CHAR
        PULS    A                                 ;
        PSHS    A                                 ;
        BSR     MONOUTHL                          ; OUT LEFT HEX CHAR
        PULS    A                                 ;
        BSR     MONOUTHR                          ; OUT RIGHT HEX CHAR
        RTS

OUT2HS:
        BSR     OUT2H                             ; OUTPUT 2 HEX CHAR + SPACE
OUTS:
        LDA     #$20                              ; SPACE
        JMP     WRSER1                            ;



;__________________________________________________________________________________________________________

DISPLAY_CRLF:
        LDA     #$0D                              ; PRINT CR
        JSR     WRSER1                            ; OUTPUT CHARACTER
        LDA     #$0A                              ; PRINT LF
        JSR     WRSER1                            ; OUTPUT CHARACTER
        RTS


WRSER1:
        PSHS    A
WRSER1a:
        LDA     UART1STATUS                       ; GET STATUS
        ANDA    #%00010000                        ; IS TX READY
        BEQ     WRSER1a                           ; NO, WAIT FOR IT

        PULS    A
        STA     UART1DATA                         ; WRITE DATA
        RTS


IOF_CONINW:                                       ;
SERIAL_INCHW1:
RDSER1:
        LDA     UART1STATUS                       ; GET STATUS REGISTER
        ANDA    #%00001000                        ; IS RX READY
        BEQ     SERIAL_INCHW1                     ; LOOP UNTIL DATA IS READY
        LDA     UART1DATA                         ; GET DATA CHAR
        RTS


;_____________________________________________________________________________________________________
;   Default ISRs.  Will be changed by OS Setup
SWIVEC:
IRQVEC:
        RTI



        ORG     $FFF2                             ; SET RESET VECTOR TO MAIN PROGRAM
        FDB     SWIVEC
        FDB     MAIN
        FDB     MAIN
        FDB     IRQVEC
        FDB     MAIN
        FDB     MAIN
        FDB     MAIN
        ENDC
