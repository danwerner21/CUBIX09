;__SERIAL DRIVERS________________________________________________________________________________________________________________
;
; 	CUBIX serial drivers for 6809PC
;
;	Entry points:
;		SERIALINIT  - called during OS init
;		RDSER1	    - read a byte from serial port ('A' POINTS TO BYTE)
;		WRSER1	    - write a byte from serial port  ('A' POINTS TO BYTE)
;________________________________________________________________________________________________________________________________
;
;*
;*        HARDWARE I/O ADDRESSES
;*
; UART 6551 SERIAL
UART1DATA       EQU CUBIX_IO_BASE+$F84            ; SERIAL PORT 1 (I/O Card)
UART1STATUS     EQU CUBIX_IO_BASE+$F85            ; SERIAL PORT 1 (I/O Card)
UART1COMMAND    EQU CUBIX_IO_BASE+$F86            ; SERIAL PORT 1 (I/O Card)
UART1CONTROL    EQU CUBIX_IO_BASE+$F87            ; SERIAL PORT 1 (I/O Card)



;__SERIALINIT____________________________________________________________________________________________________________________
;
;	INITIALIZE SERIAL PORTS
;________________________________________________________________________________________________________________________________
;
SERIALINIT:
        LDA     #$00                              ; RESET UART
        STA     UART1STATUS                       ;
        LDA     #$0B                              ;
        STA     UART1COMMAND                      ;
        LDA     #$1E                              ; 9600, 8 BITS, NO PARITY, 1 STOP BIT
        STA     UART1CONTROL                      ;
        RTS
        RTS

;__WRSER1________________________________________________________________________________________________________________________
;
;	WRITE CHARACTER(A) TO UART
;________________________________________________________________________________________________________________________________
;
WRSER1
!
        LDB     UART1STATUS                       ; GET STATUS
        ANDB    #%00010000                        ; IS TX READY
        BEQ     <                                 ; IF NOT REPEAT
        STA     UART1DATA                         ; WRITE DATA
        RTS

;__RDSER1________________________________________________________________________________________________________________________
;
;	READ CHARACTER FROM UART TO (A)
;________________________________________________________________________________________________________________________________
;
RDSER1
        LDA     UART1STATUS                       ; GET STATUS REGISTER
        ANDA    #%00001000                        ; IS RX READY
        BEQ     >                                 ; No DATA IS READY
        LDA     UART1DATA                         ; GET DATA CHAR
        RTS

        RTS
!
        LDA     #$FF                              ;
        STA     >PAGER_D                          ; SAVE 'D'
        RTS                                       ;
