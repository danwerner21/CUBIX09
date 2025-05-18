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
UART0           EQU $DF58                         ; DATA IN/OUT
UART1           EQU $DF59                         ; CHECK RX
UART2           EQU $DF5A                         ; INTERRUPTS
UART3           EQU $DF5B                         ; LINE CONTROL
UART4           EQU $DF5C                         ; MODEM CONTROL
UART5           EQU $DF5D                         ; LINE STATUS
UART6           EQU $DF5E                         ; MODEM STATUS
UART7           EQU $DF5F                         ; SCRATCH REG.


;__SERIALINIT____________________________________________________________________________________________________________________
;
;	INITIALIZE SERIAL PORTS
;________________________________________________________________________________________________________________________________
;
SERIALINIT:
; these are all set by Bios prior to activating the 6809 card.
;	LDA		#$80		;
;	STA		UART3		; SET DLAB FLAG
;	LDA		#12			; SET TO 12 = 9600 BAUD
;	STA		UART0		; save baud rate
;	LDA		#00			;
;	STA		UART1		;
;	LDA		#0F			;
;	STA		UART3		; SET 8 BIT DATA, 1 STOPBIT
        LDA             #$81            ; Enable FIFOs
        STA             UART2           ;
        LDA             #$2B            ; Enable Auto Flow Control $0B to disable AFC
        STA             UART4
        RTS



;__WRSER1________________________________________________________________________________________________________________________
;
;	WRITE CHARACTER(A) TO UART
;________________________________________________________________________________________________________________________________
;
WRSER1
!
        LDB     UART5                             ; READ LINE STATUS REGISTER
        ANDB    #$20                              ; TEST IF UART IS READY TO SEND (BIT 5)
        CMPB    #$00
        BEQ     <                                 ; IF NOT REPEAT
        STA     UART0                             ; THEN WRITE THE CHAR TO UART
        RTS

;__RDSER1________________________________________________________________________________________________________________________
;
;	READ CHARACTER FROM UART TO (A)
;________________________________________________________________________________________________________________________________
;
RDSER1
        LDA     UART5                             ; READ LINE STATUS REGISTER
        ANDA    #$01                              ; TEST IF DATA IN RECEIVE BUFFER
        CMPA    #$00
        BEQ     >                                 ; NO DATA
        LDA     UART0                             ; THEN READ THE CHAR FROM THE UART
        STA     >PAGER_D                          ; SAVE 'D'
        ORCC    #%00000100                        ; SET 'Z'
        RTS
!
        LDA     #$FF                              ;
        STA     >PAGER_D                          ; SAVE 'D'
        RTS                                       ;
