;__IDE DRIVERS___________________________________________________________________________________________________________________
;
; 	CUBIX IDE disk drivers 6809PC - XT IDE ISA CARD
;
;	Entry points:
;		XTIDE_INIT   	- CALLED DURING OS INIT
;		IDE_READ_SECTOR  - read a sector from drive  ('U' POINTS TO DCB, X TO MEMORY)
;		IDE_WRITE_SECTOR - write a sector to drive   ('U' POINTS TO DCB, X TO MEMORY)
;________________________________________________________________________________________________________________________________
;

XTIDE_DATA_LO   = CUBIX_IO_BASE+$300
XTIDE_DATA_HI   = CUBIX_IO_BASE+$301
XTIDE_ERR       = CUBIX_IO_BASE+$302
XTIDE_FECODE    = CUBIX_IO_BASE+$302
XTIDE_SEC_CNT   = CUBIX_IO_BASE+$304
XTIDE_LBALOW    = CUBIX_IO_BASE+$306
XTIDE_LBAMID    = CUBIX_IO_BASE+$308
XTIDE_LBAHI     = CUBIX_IO_BASE+$30A
XTIDE_DEVICE    = CUBIX_IO_BASE+$30C
XTIDE_COMMAND   = CUBIX_IO_BASE+$30E
XTIDE_STATUS    = CUBIX_IO_BASE+$30E




;IDE COMMAND CONSTANTS.  THESE SHOULD NEVER CHANGE.
XTIDE_CMD_RECAL = $10
XTIDE_CMD_READ  = $20
XTIDE_CMD_WRITE = $30
XTIDE_CMD_INIT  = $91
XTIDE_CMD_ID    = $EC
XTIDE_CMD_FEAT  = $EF
XTIDE_CMD_SPINDOWN = $E0
XTIDE_CMD_SPINUP = $E1



XTIDETIMEOUT:
        .BYTE   $00,$00


        IFNDEF   BIOS6809PC
;__XTIDE_INIT________________________________________________________________________________________
;
;  INIT AND DISPLAY IDE INFO
;____________________________________________________________________________________________________
;
XTIDE_INIT:
        JSR     LFCR                              ; AND CRLF
        LDX     #MESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
;
        LDX     #MESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #XTIDE_DATA_LO                    ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
;
        JSR     XTIDE_PROBE                       ; DETECT AN ATA DEVICE, ABORT IF NOT FOUND
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
;__XTIDE_PROBE_______________________________________________________________________________________
;
;  XTPROBE FOR IDE HARDWARE
;____________________________________________________________________________________________________
;
XTIDE_PROBE:
;
; BELOW TESTS FOR EXISTENCE OF AN IDE CONTROLLER ON THE
; PPIDE INTERFACE.  WE WRITE A VALUE OF ZERO FIRST SO THAT
; THE PPI BUS HOLD WILL RETURN A VALUE OF ZERO IF THERE IS
; NOTHING CONNECTED TO PPI PORT A.  THEN WE READ THE STATUS
; REGISTER.  IF AN IDE CONTROLLER IS THERE, IT SHOULD ALWAYS
; RETURN SOMETHING OTHER THAN ZERO.  IF AN IDE CONTROLLER IS
; THERE, THEN THE VALUE WRITTEN TO PPI PORT A IS IGNORED
; BECAUSE THE WRITE SIGNAL IS NEVER PULSED.

; CHECK SIGNATURE

        LDX     #$0000
;       SOMETIMES THE CF-XTIDE WILL ONLY READ 80, THIS CAN BE RESET BY WRITING ZEROS UNTIL VALUES ARE PROPERLY READ
!
        LDB     XTIDE_DATA_LO
        CMPB    #$80
        BNE     >
        LDB     #$00
        STB     XTIDE_DATA_LO
        NOP
        STB     XTIDE_DATA_HI
        NOP
        STB     XTIDE_LBALOW
        NOP
        STB     XTIDE_LBAMID
        NOP
        STB     XTIDE_LBAHI
        NOP
        STB     XTIDE_DEVICE
        NOP
        STB     XTIDE_COMMAND
        NOP
        STB     XTIDE_STATUS
        NOP
        INX
        CPX     #$0300
        BNE     <
        BRA     XTIDE_PROBE_FAIL                  ; TIMED OUT
!
        LDB     XTIDE_SEC_CNT
        CMPB    #$01
        BNE     XTIDE_PROBE_FAIL                  ; IF NOT '01' THEN REPORT NO IDE PRESENT
        CLC
        JMP     XTIDE_PROBE_SUCCESS
XTIDE_PROBE_FAIL:
        SEC
XTIDE_PROBE_SUCCESS:
        RTS                                       ; DONE, NOTE THAT A=0 AND Z IS SET

;*__IDE_READ_INFO___________________________________________________________________________________
;*
;*  READ IDE INFORMATION
;*	CARRY SET ON ERROR
;* 	A=MST/SLV
;*____________________________________________________________________________________________________
IDE_READ_INFO:
; SET DRIVE BIT
        ANDA    #$01                              ; ONLY WANT THE 1 BIT (MST/SLV)
        ASLA                                      ; SHIFT 4
        ASLA                                      ;
        ASLA                                      ;
        ASLA                                      ;
        ORA     #$E0                              ; E0=MST  F0=SLV
        STA     XTIDE_DEVICE

        JSR     IDE_WAIT_NOT_BUSY                 ;MAKE SURE DRIVE IS READY
        BCS     IDE_READ_INFO_ABORT

        LDA     #$01                              ; ENABLE 8-BIT MODE (XT-CF-LITE)
        STA     XTIDE_FECODE
        LDA     #XTIDE_CMD_FEAT
        STA     XTIDE_COMMAND

        NOP                                       ; TINY DELAY, JUST IN CASE
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP


        LDA     #XTIDE_CMD_ID                     ; ID COMMAND
        STA     XTIDE_COMMAND

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
        ENDIF


;*__IDE_READ_SECTOR___________________________________________________________________________________
;*
;*  READ IDE SECTOR (IN LBA) INTO BUFFER
;*
;*____________________________________________________________________________________________________
IDE_READ_SECTOR:
        JSR     IDE_WAIT_NOT_BUSY                 ;MAKE SURE DRIVE IS READY
        BCS     IDE_READ_SECTOR_ERROR             ; IF TIMEOUT, REPORT NO IDE PRESENT
IDE_READ_SECTOR_1:
        IFNDEF   BIOS6809PC
        JSR     IDE_SETUP_LBA                     ;TELL IT WHICH SECTOR WE WANT
        ENDIF
        LDA     #XTIDE_CMD_READ
        STA     XTIDE_COMMAND

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


;*__IDE_WAIT_NOT_BUSY_______________________________________________________________________________
;*
;*  WAIT FOR IDE CHANNEL TO BECOME READY
;*
;*____________________________________________________________________________________________________
IDE_WAIT_NOT_BUSY:
        PSHS    A,B
        LDA     #$00
        STA     XTIDETIMEOUT
        STA     XTIDETIMEOUT+1
IDE_WAIT_NOT_BUSY1:
        LDB     XTIDE_STATUS                      ;WAIT FOR RDY BIT TO BE SET
        ANDB    #$80
        BEQ     IDE_WAIT_NOT_BUSY2
        INC     XTIDETIMEOUT
        BNE     IDE_WAIT_NOT_BUSY1
        INC     XTIDETIMEOUT+1
        BNE     IDE_WAIT_NOT_BUSY1
        SEC
        JMP     IDE_WAIT_NOT_BUSY3
IDE_WAIT_NOT_BUSY2:
        CLC
IDE_WAIT_NOT_BUSY3:
        PULS    PC,A,B

;*__IDE_WAIT_DRQ______________________________________________________________________________________
;*
;*	WAIT FOR THE DRIVE TO BE READY TO TRANSFER DATA.
;*
;*____________________________________________________________________________________________________
IDE_WAIT_DRQ:
        PSHS    A,B,Y
        LDA     #$00
        STA     XTIDETIMEOUT
        STA     XTIDETIMEOUT+1
IDE_WAIT_DRQ1:
        LDB     XTIDE_STATUS                      ;WAIT FOR DRQ BIT TO BE SET
        ANDB    #%10001000                        ; MASK OFF BUSY(7) AND DRQ(3)
        CMPB    #%00001000                        ; WE WANT BUSY(7) TO BE 0 AND DRQ (3) TO BE 1
        BEQ     IDE_WAIT_DRQ2
        ANDB    #%00000001                        ; IS ERROR?
        CMPB    #%00000001                        ;
        BEQ     IDE_WAIT_DRQE
        INC     XTIDETIMEOUT
        BNE     IDE_WAIT_DRQ1
        INC     XTIDETIMEOUT+1
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
        LDB     XTIDE_DATA_LO
        STB     HSTBUF,Y                          ;
        INY
        LDB     XTIDE_DATA_HI
        STB     HSTBUF,Y                          ;
        INY
        CMPY    #$0200                            ;
        BNE     IDEBUFRD                          ;
        RTS                                       ;


        IFNDEF   BIOS6809PC
;*__IDE_WRITE_SECTOR__________________________________________________________________________________
;*
;*  WRITE IDE SECTOR (IN LBA) FROM BUFFER
;*
;*____________________________________________________________________________________________________
IDE_WRITE_SECTOR:
        JSR     IDE_WAIT_NOT_BUSY                 ;MAKE SURE DRIVE IS READY
        BCS     IDE_WRITE_SECTOR_ERROR            ; IF TIMEOUT, REPORT NO IDE PRESENT
        JSR     IDE_SETUP_LBA                     ;TELL IT WHICH SECTOR WE WANT
        LDA     #XTIDE_CMD_WRITE
        STA     XTIDE_COMMAND
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

;*__IDE_WRITE_BUFFER___________________________________________________________________________________
;*
;*  WRITE IDE BUFFER LITTLE ENDIAN
;*
;*____________________________________________________________________________________________________
IDE_WRITE_BUFFER:
        LDY     #$0000                            ; INDEX
IDEBUFWT:
        LDB     HSTBUF,Y                          ;
        STB     XTIDE_DATA_LO
        INY
        LDB     HSTBUF,Y                          ;
        STB     XTIDE_DATA_HI
        INY
        CMPY    #$0200                            ;
        BNE     IDEBUFWT                          ;
        RTS                                       ;



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
;*____________________________________________________________________________________________________
IDE_SETUP_LBA:
        PSHS    D
        LDB     CURRENTDEVICE
        ANDB    #$01                              ; only want drive cfg
        ASLB                                      ; SHIFT 4
        ASLB                                      ;
        ASLB                                      ;
        ASLB                                      ;
        ORB     #$E0                              ; E0=MST  F0=SLV
        STB     XTIDE_DEVICE

        LDB     CURRENTSLICE
        STB     XTIDE_LBAHI

        LDB     CURRENTCYL                        ;
        INCB                                      ; CYL 0 reserved for boot image
        STB     XTIDE_LBAMID

        LDB     CURRENTSEC                        ;
        STB     XTIDE_LBALOW

        LDB     #$01
        STB     XTIDE_SEC_CNT

        PULS    D,PC
        ENDIF