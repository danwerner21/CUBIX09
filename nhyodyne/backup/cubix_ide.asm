;__IDE DRIVERS___________________________________________________________________________________________________________________
;
; 	CUBIX IDE disk drivers for direct attached disk-io card
;
;	Entry points:
;		PPIDE_INIT   	- CALLED DURING OS INIT
;		IDE_READ_SECTOR  - read a sector from drive  ('U' POINTS TO DCB, X TO MEMORY)
;		IDE_WRITE_SECTOR - write a sector to drive   ('U' POINTS TO DCB, X TO MEMORY)
;________________________________________________________________________________________________________________________________
;
HSTBUF          = $0300
PPIDE_PPI       = $0560                           ; PORT A
;
PPIDELO         = PPIDE_PPI+0                     ; LSB
PPIDEHI         = PPIDE_PPI+1                     ; MSB
PPIDECNTRL      = PPIDE_PPI+2                     ; CONTROL SIGNALS
PPIDEPPIC       = PPIDE_PPI+3                     ; CONTROL BYTE PPI 82C55

PPIDE_A0_LINE   = $01                             ;DIRECT FROM 8255 TO IDE INTERFACE
PPIDE_A1_LINE   = $02                             ;DIRECT FROM 8255 TO IDE INTERFACE
PPIDE_A2_LINE   = $04                             ;DIRECT FROM 8255 TO IDE INTERFACE
PPIDE_CS0_LINE  = $08                             ;INVERTER BETWEEN 8255 AND IDE INTERFACE
PPIDE_CS1_LINE  = $10                             ;INVERTER BETWEEN 8255 AND IDE INTERFACE
PPIDE_WR_LINE   = $20                             ;INVERTER BETWEEN 8255 AND IDE INTERFACE
PPIDE_RD_LINE   = $40                             ;INVERTER BETWEEN 8255 AND IDE INTERFACE
PPIDE_RST_LINE  = $80                             ;INVERTER BETWEEN 8255 AND IDE INTERFACE

PPIDE_DATA      = PPIDE_CS0_LINE
PPIDE_ERR       = PPIDE_CS0_LINE+PPIDE_A0_LINE
PPIDE_SEC_CNT   = PPIDE_CS0_LINE+PPIDE_A1_LINE
PPIDE_LBALOW    = PPIDE_CS0_LINE+PPIDE_A1_LINE+PPIDE_A0_LINE
PPIDE_LBAMID    = PPIDE_CS0_LINE+PPIDE_A2_LINE
PPIDE_LBAHI     = PPIDE_CS0_LINE+PPIDE_A2_LINE+PPIDE_A0_LINE
PPIDE_DEVICE    = PPIDE_CS0_LINE+PPIDE_A2_LINE+PPIDE_A1_LINE
PPIDE_COMMAND   = PPIDE_CS0_LINE+PPIDE_A2_LINE+PPIDE_A1_LINE+PPIDE_A0_LINE
PPIDE_STATUS    = PPIDE_CS0_LINE+PPIDE_A2_LINE+PPIDE_A1_LINE+PPIDE_A0_LINE
PPIDE_CONTROL   = PPIDE_CS1_LINE+PPIDE_A2_LINE+PPIDE_A1_LINE
PPIDE_ASTATUS   = PPIDE_CS1_LINE+PPIDE_A2_LINE+PPIDE_A1_LINE+PPIDE_A0_LINE


;IDE COMMAND CONSTANTS.  THESE SHOULD NEVER CHANGE.
PPIDE_CMD_RECAL = $10
PPIDE_CMD_READ  = $20
PPIDE_CMD_WRITE = $30
PPIDE_CMD_INIT  = $91
PPIDE_CMD_ID    = $EC
PPIDE_CMD_SPINDOWN = $E0
PPIDE_CMD_SPINUP = $E1


PPRD_IDE_8255   = %10010010                       ;IDE_8255_CTL OUT, IDE_8255_LSB/MSB INPUT
PPWR_IDE_8255   = %10000000                       ;ALL THREE PORTS OUTPUT

;ALLOCATE THE FOLLOWING DATA AREAS TO UNUSED RAM SPACE
DEBCYLL:
        .BYTE   0                                 ; DEBLOCKED CYLINDER LSB
DEBCYLM:
        .BYTE   0                                 ; DEBLOCKED CYLINDER MSB
DEBSEHD:
        .BYTE   0                                 ; DEBLOCKED SECTOR AND HEAD (HS)
PPIDETMP:
        .BYTE   0                                 ; TEMP
PPIDELOTMP:
        .BYTE   0
PPIDECOMMAND:
        .BYTE   0
PPIDETIMEOUT:
        .BYTE   $00,$00
PPIDEWORKVAR:
        .BYTE   $00,$00


;__PPIDE_INIT_________________________________________________________________________________________
;
;  INIT AND DISPLAY IDE INFO
;____________________________________________________________________________________________________
;
PPIDE_INIT:
        JSR     LFCR                              ; AND CRLF
        JSR     LFCR                              ; AND CRLF
        LDX     #MESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
        JSR     IDE_PPIDETECT                     ; TEST FOR PPI HARDWARE
        BNE     IDE_ABORT                         ; BAIL OUT IF NOT THERE
;
        LDX     #MESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #PPIDE_PPI                        ; GET BASE PORT
        STD     PPIDEWORKVAR
        JSR     WRHEXW                            ; PRINT BASE PORT
;
        JSR     PPIDE_RESET                       ; RESET THE BUS
        JSR     PPIDE_PROBE                       ; DETECT AN ATA DEVICE, ABORT IF NOT FOUND
        BCS     IDE_ABORT
        JMP     IDE_PRINT_INFO
IDE_ABORT:
        LDX     #MESSAGE3
        JSR     WRSTR                             ; DO PROMPT
        JMP     IDE_INITA
IDE_PRINT_INFO:
        JSR     LFCR                              ; AND CRLF
        LDX     #MESSAGE4
        JSR     WRSTR                             ; DO PROMPT
        LDA     #$00
        JSR     IDE_READ_INFO                     ; GET DRIVE INFO, ABORT IF ERROR
        LDX     #MESSAGE5
        JSR     WRSTR                             ; DO PROMPT
        LDA     #$01
        JSR     IDE_READ_INFO                     ; GET DRIVE INFO, ABORT IF ERROR
IDE_INITA:
        JSR     LFCR                              ; AND CRLF
        RTS                                       ; DONE
;
;__PPIDE_PROBE_______________________________________________________________________________________
;
;  PROBE FOR IDE HARDWARE
;____________________________________________________________________________________________________
;
PPIDE_PROBE:
;
; BELOW TESTS FOR EXISTENCE OF AN IDE CONTROLLER ON THE
; PPIDE INTERFACE.  WE WRITE A VALUE OF ZERO FIRST SO THAT
; THE PPI BUS HOLD WILL RETURN A VALUE OF ZERO IF THERE IS
; NOTHING CONNECTED TO PPI PORT A.  THEN WE READ THE STATUS
; REGISTER.  IF AN IDE CONTROLLER IS THERE, IT SHOULD ALWAYS
; RETURN SOMETHING OTHER THAN ZERO.  IF AN IDE CONTROLLER IS
; THERE, THEN THE VALUE WRITTEN TO PPI PORT A IS IGNORED
; BECAUSE THE WRITE SIGNAL IS NEVER PULSED.

        LDA     #$00
        STA     PPIDELO                           ; PPI PORT A, DATALO
        JSR     IDE_WAIT_NOT_BUSY                 ; WAIT FOR BUSY TO CLEAR
        BCS     PPIDE_PROBE_FAIL                  ; IF TIMEOUT, REPORT NO IDE PRESENT
        LDA     #PPIDE_STATUS                     ; GET STATUS
        JSR     IDE_READ
        ANDB    #%01000000
        CMPB    #$00
        BEQ     PPIDE_PROBE_FAIL                  ; IF NOT RDY BIT (BIT 6) THEN REPORT NO IDE PRESENT

; CHECK SIGNATURE
        LDA     #PPIDE_SEC_CNT
        JSR     IDE_READ
        CMPB    #$01
        BNE     PPIDE_PROBE_FAIL                  ; IF NOT '01' THEN REPORT NO IDE PRESENT
        LDA     #PPIDE_LBALOW
        JSR     IDE_READ
        CMPB    #$01
        BNE     PPIDE_PROBE_FAIL                  ; IF NOT '01' THEN REPORT NO IDE PRESENT
        LDA     #PPIDE_LBAMID
        JSR     IDE_READ
        CMPB    #$00
        BNE     PPIDE_PROBE_FAIL                  ; IF NOT '00' THEN REPORT NO IDE PRESENT
        LDA     #PPIDE_LBAHI
        JSR     IDE_READ
        CMPB    #$00
        BNE     PPIDE_PROBE_FAIL                  ; IF NOT '00' THEN REPORT NO IDE PRESENT
        CLC
        JMP     PPIDE_PROBE_SUCCESS
PPIDE_PROBE_FAIL:

        SEC
PPIDE_PROBE_SUCCESS:
        RTS                                       ; DONE, NOTE THAT A=0 AND Z IS SET

;*__IDE_READ_INFO___________________________________________________________________________________
;*
;*  READ IDE INFORMATION
;*	CARRY SET ON ERROR
;* 	A=MST/SLV
;*____________________________________________________________________________________________________
IDE_READ_INFO:
; SET DRIVE BIT
        LDB     #PPIDE_DEVICE
        STB     PPIDECOMMAND
        ANDA    #$01                              ; ONLY WANT THE 1 BIT (MST/SLV)
        ASLA                                      ; SHIFT 4
        ASLA                                      ;
        ASLA                                      ;
        ASLA                                      ;
        ORA     #$E0                              ; E0=MST  F0=SLV
        TFR     A,B
        LDA     #$00
        JSR     IDE_WRITE
        JSR     IDE_WAIT_NOT_BUSY                 ;MAKE SURE DRIVE IS READY
        BCS     IDE_READ_INFO_ABORT
        LDA     #PPIDE_COMMAND                    ;SELECT IDE REGISTER
        STA     PPIDECOMMAND
        LDD     #PPIDE_CMD_ID
        JSR     IDE_WRITE                         ;ASK THE DRIVE TO READ IT
        JSR     IDE_WAIT_DRQ                      ;WAIT UNTIL IT'S GOT THE DATA
        BCS     IDE_READ_INFO_ABORT
        JSR     IDE_READ_BUFFER                   ; GRAB THE 256 WORDS FROM THE BUFFER
        LDX     #MESSAGE6
        JSR     WRSTR
        LDA     HSTBUF+123
        JSR     WRHEX
        LDA     HSTBUF+122
        JSR     WRHEX
        LDA     HSTBUF+121
        JSR     WRHEX
        LDA     HSTBUF+120
        JSR     WRHEX
        JMP     IDE_READ_INFO_OK
IDE_READ_INFO_ABORT:
        LDX     #MESSAGE3
        JSR     WRSTR                             ;DO PROMPT
        JSR     LFCR                              ;AND CRLF
        SEC
        RTS                                       ;
IDE_READ_INFO_OK:
        JSR     LFCR                              ; AND CRLF
        CLC
        RTS


;__IDE_PPIDETECT____________________________________________________________________________________
;
;  PROBE FOR PPI HARDWARE
;____________________________________________________________________________________________________
;
IDE_PPIDETECT:
;
; TEST FOR PPI EXISTENCE
; WE SETUP THE PPI TO WRITE, THEN WRITE A VALUE OF ZERO
; TO PORT A (DATALO), THEN READ IT BACK.  IF THE PPI IS THERE
; THEN THE BUS HOLD CIRCUITRY WILL READ BACK THE ZERO. SINCE
; WE ARE IN WRITE MODE, AN IDE CONTROLLER WILL NOT BE ABLE TO
; INTERFERE WITH THE VALUE BEING READ.
        JSR     SET_PPI_WR
;
        LDA     #$00                              ; VALUE ZERO
        STA     PPIDELO                           ; PUSH VALUE TO PORT
        LDA     PPIDELO                           ; GET PORT VALUE
        CMPA    #$00
        RTS                                       ; AND RETURN
;


;*__IDE_READ_SECTOR___________________________________________________________________________________
;*
;*  READ IDE SECTOR (IN LBA) INTO BUFFER
;*
;*____________________________________________________________________________________________________
IDE_READ_SECTOR:
        JSR     IDE_WAIT_NOT_BUSY                 ;MAKE SURE DRIVE IS READY
        BCS     IDE_READ_SECTOR_ERROR             ; IF TIMEOUT, REPORT NO IDE PRESENT
IDE_READ_SECTOR_1:
        JSR     IDE_SETUP_LBA                     ;TELL IT WHICH SECTOR WE WANT
        LDA     #PPIDE_COMMAND                    ;SELECT IDE REGISTER
        STA     PPIDECOMMAND
        LDD     #PPIDE_CMD_READ
        JSR     IDE_WRITE                         ; ASK THE DRIVE TO READ IT
        JSR     IDE_WAIT_DRQ                      ; WAIT UNTIL IT'S GOT THE DATA
        BCS     IDE_READ_SECTOR_ERROR             ; IF TIMEOUT, REPORT NO IDE PRESENT
        JSR     IDE_READ_BUFFER                   ; GRAB THE 256 WORDS FROM THE BUFFER
        CLRA                                      ; ZERO = 1 ON RETURN = OPERATION OK
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS
IDE_READ_SECTOR_ERROR:
        LDA     #$02                              ; SET ERROR CONDITION
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS

;*__IDE_WRITE_SECTOR__________________________________________________________________________________
;*
;*  WRITE IDE SECTOR (IN LBA) FROM BUFFER
;*
;*____________________________________________________________________________________________________
IDE_WRITE_SECTOR:
        JSR     IDE_WAIT_NOT_BUSY                 ;MAKE SURE DRIVE IS READY
        BCS     IDE_WRITE_SECTOR_ERROR            ; IF TIMEOUT, REPORT NO IDE PRESENT
        JSR     IDE_SETUP_LBA                     ;TELL IT WHICH SECTOR WE WANT
        LDA     #PPIDE_COMMAND
        STA     PPIDECOMMAND
        LDD     #PPIDE_CMD_WRITE
        JSR     IDE_WRITE                         ;TELL DRIVE TO WRITE A SECTOR
        JSR     IDE_WAIT_DRQ                      ;WAIT UNIT IT WANTS THE DATA
        BCS     IDE_WRITE_SECTOR_ERROR            ; IF TIMEOUT, REPORT NO IDE PRESENT
        JSR     IDE_WRITE_BUFFER                  ;GIVE THE DATA TO THE DRIVE
        JSR     IDE_WAIT_NOT_BUSY                 ;WAIT UNTIL THE WRITE IS COMPLETE
        BCS     IDE_WRITE_SECTOR_ERROR            ; IF TIMEOUT, REPORT NO IDE PRESENT
        CLRA                                      ; ZERO = 1 ON RETURN = OPERATION OK
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS
IDE_WRITE_SECTOR_ERROR:
        LDA     #$02
        STA     DISKERROR                         ; SAVE ERROR CONDITION FOR OS
        RTS

;*__PPIDE_RESET____________________________________________________________________________________
;*
;*  SOFT RESET IDE CHANNEL
;*
;*____________________________________________________________________________________________________
PPIDE_RESET:
;	PRTDBG "IDE RESET$"
        LDA     #PPIDE_RST_LINE
        STA     PPIDECNTRL                        ; ASSERT RST LINE ON IDE INTERFACE

        LDY     #$0100
;	PRTDBG "IDE RESET DELAY$"
RST_DLY:
        DEY
        CMPY    #$0000
        BNE     RST_DLY
        LDA     #$00
        STA     PPIDECNTRL                        ; DEASSERT RST LINE ON IDE INTERFACE

; IF A DSKYNG IS ACTIVE AND IS ON THE SAME PPI PORT AS THE PPISDa:a BEING
; RESET, THEN THE DSKYNG WILL ALSO BE RESET.  SO, THE DSKY IS ALSO INITIALIZED.
;    IF      USEDSKYNG = 1
;        JSR     DSKY_REINIT
;        ENDC

        RTS


;*__IDE_WAIT_NOT_BUSY_______________________________________________________________________________
;*
;*  WAIT FOR IDE CHANNEL TO BECOME READY
;*
;*____________________________________________________________________________________________________
IDE_WAIT_NOT_BUSY:
        PSHS    A,B
        LDA     #$00
        STA     PPIDETIMEOUT
        STA     PPIDETIMEOUT+1
IDE_WAIT_NOT_BUSY1:
        LDA     #PPIDE_STATUS                     ;WAIT FOR RDY BIT TO BE SET
        JSR     IDE_READ
        ANDB    #$80
        BEQ     IDE_WAIT_NOT_BUSY2
        INC     PPIDETIMEOUT
        BNE     IDE_WAIT_NOT_BUSY1
        INC     PPIDETIMEOUT+1
        BNE     IDE_WAIT_NOT_BUSY1
        SEC
        JMP     IDE_WAIT_NOT_BUSY3
IDE_WAIT_NOT_BUSY2:
        CLC
IDE_WAIT_NOT_BUSY3:
        PULS    PC,A,B
        RTS

;*__IDE_WAIT_DRQ______________________________________________________________________________________
;*
;*	WAIT FOR THE DRIVE TO BE READY TO TRANSFER DATA.
;*
;*____________________________________________________________________________________________________
IDE_WAIT_DRQ:
        PSHS    A,B,Y
        LDA     #$00
        STA     PPIDETIMEOUT
        STA     PPIDETIMEOUT+1
IDE_WAIT_DRQ1:
        LDA     #PPIDE_STATUS                     ;WAIT FOR DRQ BIT TO BE SET
        JSR     IDE_READ
        ANDB    #%10001000                        ; MASK OFF BUSY(7) AND DRQ(3)
        CMPB    #%00001000                        ; WE WANT BUSY(7) TO BE 0 AND DRQ (3) TO BE 1
        BEQ     IDE_WAIT_DRQ2
        ANDB    #%00000001                        ; IS ERROR?
        CMPB    #%00000001                        ;
        BEQ     IDE_WAIT_DRQE
        INC     PPIDETIMEOUT
        BNE     IDE_WAIT_DRQ1
        INC     PPIDETIMEOUT+1
        BNE     IDE_WAIT_DRQ1
IDE_WAIT_DRQE:
        SEC
        JMP     IDE_WAIT_DRQ3
IDE_WAIT_DRQ2:
        CLC
IDE_WAIT_DRQ3:
        PULS    PC,A,B,Y



;*__IDE_READ_BUFFER___________________________________________________________________________________
;*
;*  READ IDE BUFFER LITTLE ENDIAN
;*
;*____________________________________________________________________________________________________
IDE_READ_BUFFER:
        LDY     #$0000                            ; INDEX
IDEBUFRD:
        LDA     #PPIDE_DATA
        JSR     IDE_READ_NO_SETUP
        STB     HSTBUF,Y                          ; 'ID DRIVE' IDE RESPONSE IS LITTLE ENDIAN FORMAT
        INY
        STA     HSTBUF,Y                          ; 'ID DRIVE' IDE RESPONSE IS LITTLE ENDIAN FORMAT
        INY
        CMPY    #$0200                            ;
        BNE     IDEBUFRD                          ;
        RTS                                       ;

;*__IDE_WRITE_BUFFER___________________________________________________________________________________
;*
;*  WRITE IDE BUFFER LITTLE ENDIAN
;*
;*____________________________________________________________________________________________________
IDE_WRITE_BUFFER:
        LDY     #$0000                            ; INDEX
IDEBUFWT:
        LDA     #PPIDE_DATA
        STA     PPIDECOMMAND
        LDB     HSTBUF,Y                          ; SECTORS ARE BIG ENDIAN
        INY
        LDA     HSTBUF,Y                          ; SECTORS ARE BIG ENDIAN
        INYY                                      ;
        JSR     IDE_WRITE
        CMPY    #$0200                            ;
        BNE     IDEBUFWT                          ;
        RTS                                       ;


;-------------------------------------------------------------------------------

; LOW LEVEL I/O TO THE DRIVE.  THESE ARE THE ROUTINES THAT TALK
; DIRECTLY TO THE DRIVE, VIA THE 8255 CHIP.  NORMALLY A MAIN
; PROGRAM WOULD NOT CALL TO THESE.

;DO A READ BUS CYCLE TO THE DRIVE, USING THE 8255.
;INPUT A = IDE REGSITER ADDRESS
;OUTPUT D = WORD READ FROM IDE DRIVE
IDE_READ:
        JSR     SET_PPI_RD                        ; SETUP FOR A READ CYCLE
IDE_READ_NO_SETUP:
        STA     PPIDECNTRL                        ;DRIVE ADDRESS ONTO CONTROL LINES
        ORA     #PPIDE_RD_LINE                    ; ASSERT RD PIN
        STA     PPIDECNTRL
        PSHS    A
        LDB     PPIDELO                           ; READ LOWER BYTE
        LDA     PPIDEHI                           ; READ UPPER BYTE
        STA     PPIDELOTMP
        PULS    A                                 ; RESTORE REGISTER VALUE
        STA     PPIDECNTRL                        ;DRIVE ADDRESS ONTO CONTROL LINES
        EORA    #PPIDE_RD_LINE                    ; ASSERT RD PIN
        STA     PPIDECNTRL
        LDA     #$00
        STA     PPIDECNTRL                        ;DEASSERT ALL CONTROL PINS
        LDA     PPIDELOTMP
        RTS



;DO A WRITE BUS CYCLE TO THE DRIVE, VIA THE 8255
;INPUT PPIDECOMMAND = IDE REGISTER ADDRESS
;INPUT REGISTER D = WORD TO WRITE
;

IDE_WRITE:
        JSR     SET_PPI_WR                        ; SETUP FOR A WRITE CYCLE
        STB     PPIDELO                           ; WRITE LOWER BYTE
        STA     PPIDEHI                           ; WRITE UPPER BYTE
        LDA     PPIDECOMMAND
        STA     PPIDECNTRL                        ;DRIVE ADDRESS ONTO CONTROL LINES
        ORA     #PPIDE_WR_LINE                    ; ASSERT WRITE PIN
        STA     PPIDECNTRL
        EORA    #PPIDE_WR_LINE                    ; DE ASSERT WR PIN
        STA     PPIDECNTRL
        LDA     #$00
        STA     PPIDECNTRL                        ;DEASSERT ALL CONTROL PINS
        RTS


;-----------------------------------------------------------------------------------
; PPI SETUP ROUTINE TO CONFIGURE THE APPROPRIATE PPI MODE
;
;------------------------------------------------------------------------------------

SET_PPI_RD:
        PSHS    A
        LDA     #$00
        STA     PPIDECNTRL                        ;DEASSERT ALL CONTROL PINS
        LDA     #PPRD_IDE_8255
        STA     PPIDEPPIC                         ;CONFIG 8255 CHIP, READ MODE
        PULS    A,PC

SET_PPI_WR:
        PSHS    A
        LDA     #$00
        STA     PPIDECNTRL                        ;DEASSERT ALL CONTROL PINS
        LDA     #PPWR_IDE_8255
        STA     PPIDEPPIC                         ;CONFIG 8255 CHIP, WRITE MODE
        PULS    A,PC


MESSAGE1
        FCC     "PPIDE :"
        FCB     00
MESSAGE2
        FCC     " IO=0x"
        FCB     00
MESSAGE3
        FCC     " NOT PRESENT"
        FCB     00
MESSAGE4
        FCC     " PPIDE0: BLOCKS="
        FCB     00
MESSAGE5
        FCC     " PPIDE1: BLOCKS="
        FCB     00
MESSAGE6
        FCC     "0x"
        FCB     00


;*__IDE_SETUP_LBA_____________________________________________________________________________________
;*
;*
;        SETUP   LBA DATA
;*
;*____________________________________________________________________________________________________
IDE_SETUP_LBA:
        PSHS    D
;            IF      USEDSKYNG = 1
;                LDA     DRIVE,U
;                STA     DSKY_HEXBUF
;                LDA     HEAD,U
;                STA     DSKY_HEXBUF+1
;                LDA     CYL,U
;                STA     DSKY_HEXBUF+2
;                LDA     SEC,U
;                STA     DSKY_HEXBUF+3
;                JSR     DSKY_BIN2SEG
;                JSR     DSKY_SHOW
;                ENDC
        LDA     #PPIDE_DEVICE
        STA     PPIDECOMMAND
        LDA     #$00
        LDB     CURRENTDEVICE
        ANDB    #$01                              ; only want drive cfg
        ASLB                                      ; SHIFT 4
        ASLB                                      ;
        ASLB                                      ;
        ASLB                                      ;
        ORB     #$E0                              ; E0=MST  F0=SLV
        JSR     IDE_WRITE

        LDA     #PPIDE_LBAHI
        STA     PPIDECOMMAND
        LDA     #$00
        LDB     CURRENTHEAD
        ADDB    CURRENTSLICE
        JSR     IDE_WRITE

        LDA     #PPIDE_LBAMID
        STA     PPIDECOMMAND
        LDA     #$00
        LDB     CURRENTCYL                        ;
        JSR     IDE_WRITE

        LDA     #PPIDE_LBALOW
        STA     PPIDECOMMAND
        LDA     #$00
        LDB     CURRENTSEC                        ;
        JSR     IDE_WRITE

        LDA     #PPIDE_SEC_CNT
        STA     PPIDECOMMAND
        LDA     #$00
        LDB     #$01
        JSR     IDE_WRITE
        PULS    D,PC
