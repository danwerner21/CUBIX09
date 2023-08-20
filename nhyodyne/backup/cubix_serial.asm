;__SERIAL DRIVERS________________________________________________________________________________________________________________
;
; 	CUBIX serial drivers for 6809 IO card
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
; UART 16C550 SERIAL
UART0           EQU $FE68                         ; DATA IN/OUT
UART1           EQU $FE69                         ; CHECK RX
UART2           EQU $FE6A                         ; INTERRUPTS
UART3           EQU $FE6B                         ; LINE CONTROL
UART4           EQU $FE6C                         ; MODEM CONTROL
UART5           EQU $FE6D                         ; LINE STATUS
UART6           EQU $FE6E                         ; MODEM STATUS
UART7           EQU $FE6F                         ; SCRATCH REG.


;__SERIALINIT____________________________________________________________________________________________________________________
;
;	INITIALIZE SERIAL PORTS
;________________________________________________________________________________________________________________________________
;
SERIALINIT:
; these are all set by CP/M prior to activating the 6809 card. If 6809 is the primary CPU, these need to be set
;	LDA		#$80		;
;	STA		UART3		; SET DLAB FLAG
;	LDA		#12			; SET TO 12 = 9600 BAUD
;	STA		UART0		; save baud rate
;	LDA		#00			;
;	STA		UART1		;
;	LDA		#03			;
;	STA		UART3		; SET 8 BIT DATA, 1 STOPBIT
;	STA		UART4		;
        RTS



;__WRSER1________________________________________________________________________________________________________________________
;
;	WRITE CHARACTER(A) TO UART
;________________________________________________________________________________________________________________________________
;
WRSER1
        PSHS    B
!
        LDA     UART5                             ; READ LINE STATUS REGISTER
        ANDA    #$20                              ; TEST IF UART IS READY TO SEND (BIT 5)
        CMPA    #$00
        BEQ     <                                 ; IF NOT REPEAT
        STA     UART0                             ; THEN WRITE THE CHAR TO UART
        PULS    B,PC

;__RDSER1________________________________________________________________________________________________________________________
;
;	READ CHARACTER FROM UART TO (A)
;________________________________________________________________________________________________________________________________
;
RDSER1
        LDA     UART5                             ; READ LINE STATUS REGISTER
        ANDA    #$01                              ; TEST IF DATA IN RECEIVE BUFFER
        CMPA    #$00
        BEQ     RDSER1N                           ; NO DATA
        LDA     UART0                             ; THEN READ THE CHAR FROM THE UART
        ORCC    #%00000100                        ; SET 'Z'
        RTS
RDSER1N
        LDA     #$FF                              ;
        RTS                                       ;
