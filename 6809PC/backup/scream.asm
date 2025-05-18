        PRAGMA  CD

;__SCREAM_______________________________________________________
;
; This is a quick program that can be put on a ROM to test the
; 6809PC board.
;
;_______________________________________________________________

IOSPACE         EQU $EF00
UART1DATA       EQU IOSPACE+$84                   ; SERIAL PORT 1 (I/O Card)
UART1STATUS     EQU IOSPACE+$85                   ; SERIAL PORT 1 (I/O Card)
UART1COMMAND    EQU IOSPACE+$86                   ; SERIAL PORT 1 (I/O Card)
UART1CONTROL    EQU IOSPACE+$87                   ; SERIAL PORT 1 (I/O Card)


;Command Register
;No bit is affected by a software reset, however, all bits are set to zero on a hardware reset.
;Bit 7 6 5  configuration
;    x x 0  no parity bit
;    0 0 1  send and receive with odd parity
;    0 1 1  send and receive with even parity
;    1 0 1  send: parity=1; receive: parity not evaluated
;    1 1 1  send: parity=0; receive: parity not evaluated
;
;Bit 4  0: no echo
;       1: echo (received characters are being sent again,
;                bits 2 and 3 must be 0 for that)
;
;Bit 3 2  sender interr.   RTS level   sender
;    0 0  no               high        off
;    0 1  yes              low         on
;    1 0  no               low         on
;    1 1  no               low         send BRK
;
;Bit 1  0: interrupt gets triggered by bit 3 in status register
;       1: no interrupt
;
;Bit 0  0: disable transceiver and interrupts, /DTR high
;       1: enable transceiver and interrupts, /DTR low
;
;Control Register
;Bits 0 to 3 are set to zero on a software reset, and all bits are set to zero on a hardware reset.
;Bit 7  0: 1 stop bit
;       1: a) with 8 data bits and 1 parity bit: 1 stop bit
;          b) with 5 data bits and no parity bit: 1.5 stop bits
;          c) otherwise 2 stop bits
;
;Bit 6 5  data bits
;    0 0  8
;    0 1  7
;    1 0  6
;    1 1  5
;
;Bit 4  0: external receive clock
;       1: builtin clock as receive clock
;
;Bit 3 2 1 0  baud rate
;    0 0 0 0  1/16 times external clock
;    0 0 0 1  50 bps
;    0 0 1 0  75 bps
;    0 0 1 1  109.92 bps
;    0 1 0 0  134.58 bps
;    0 1 0 1  150 bps
;    0 1 1 0  300 bps
;    0 1 1 1  600 bps
;    1 0 0 0  1200 bps
;    1 0 0 1  1800 bps
;    1 0 1 0  2400 bps
;    1 0 1 1  3600 bps
;    1 1 0 0  4800 bps
;    1 1 0 1  7200 bps
;    1 1 1 0  9600 bps
;    1 1 1 1  19200 bps


;
        ORG     $F000
COLD_START:


        LDA     #$00                              ; RESET UART
        STA     UART1STATUS                       ;
        LDA     #$0B                              ;
        STA     UART1COMMAND                      ;
        LDA     #$1E                              ; 9600, 8 BITS, NO PARITY, 1 STOP BIT
        STA     UART1CONTROL                      ;

        LDA     #'A'
        STA     $1000

WRSER1a:
        LDA     UART1STATUS                       ; GET STATUS
        ANDA    #%00010000                        ; IS TX READY
        BEQ     WRSER1a                           ; NO, WAIT FOR IT

;        LDA     #'A'

        INC     $1000
        LDA     $1000

        LSRA                                      ; OUT HEX LEFT BCD DIGIT
        LSRA                                      ;
        LSRA                                      ;
        LSRA                                      ;
        ANDA    #$0F
        ADDA    #$30                              ;
        CMPA    #$39                              ;
        BLS     OUTHR1                            ;
        ADDA    #$07                              ;
OUTHR1:
        STA     UART1DATA                         ; WRITE DATA

WRSER2a:
        LDA     UART1STATUS                       ; GET STATUS
        ANDA    #%00010000                        ; IS TX READY
        BEQ     WRSER2a                           ; NO, WAIT FOR IT


        LDA     $1000

        ANDA    #$0F                              ; OUT HEC RIGHT DIGIT
        ADDA    #$30                              ;
        CMPA    #$39                              ;
        BLS     OUTHR2                            ;
        ADDA    #$07                              ;
OUTHR2:
        STA     UART1DATA                         ; WRITE DATA

        JMP     WRSER1a



        ORG     $FFFE                             ; SET RESET VECTOR TO
RESETV:
        FDB     $F000
        END
