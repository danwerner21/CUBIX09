;________________________________________________________________________________________________________________________________
;
;	Duodyne Cubix banked driver code
;
;  DWERNER 1/20/2024 	Initial
;________________________________________________________________________________________________________________________________

;*
        INCLUDE cubix_values.asm
;*

        ORG     $8800

;__DISPATCHER________________________________________________________________________________________
;
;  Function dispatcher
;  function to call is located in "farfunct"
;____________________________________________________________________________________________________
;
FUNCTION_DISPATCHER:
        ASLB                                      ; DOUBLE NUMBER FOR TABLE LOOKUP
        LDA     #$00
        TFR     D,X
        LDD     DISPATCHTABLE,X
        STD     farpointer
        LDD     >PAGER_D                          ; RESTORE 'D'
        JMP     [farpointer]


DISPATCHTABLE:
        .WORD   WRSER1                            ; FUNCTION 00 - WRITE SERIAL PORT
        .WORD   RDSER1                            ; FUNCTION 01 - READ SERIAL PORT
        .WORD   SERIALINIT                        ; FUNCTION 02 - SERIAL PORT INIT

        .WORD   drv_noop                          ; FUNCTION 03 - WRITE VIDEO
        .WORD   drv_noop                          ; FUNCTION 04 - READ KEYBOARD
        .WORD   drv_noop                          ; FUNCTION 05 - INIT INTERFACE

        .WORD   drv_noop                          ; FUNCTION 06
        .WORD   drv_noop                          ; FUNCTION 07
        .WORD   drv_noop                          ; FUNCTION 08

        .WORD   drv_noop                          ; FUNCTION 09
        .WORD   drv_noop                          ; FUNCTION 10
        .WORD   drv_noop                          ; FUNCTION 11

        .WORD   drv_noop                          ; FUNCTION 12
        .WORD   drv_noop                          ; FUNCTION 13
        .WORD   drv_noop                          ; FUNCTION 14

        .WORD   drv_noop                          ; FUNCTION 15 - called during OS init
        .WORD   drv_noop                          ; FUNCTION 16 - read a sector from drive
        .WORD   drv_noop                          ; FUNCTION 17 - write a sector to drive
;
        .WORD   FL_SETUP                          ; FUNCTION 18 - init floppy device
        .WORD   FL_READ_SECTOR                    ; FUNCTION 19 - read a sector from floppy device
        .WORD   FL_WRITE_SECTOR                   ; FUNCTION 20 - write a sector to floppy device
;
        .WORD   PPIDE_INIT                        ; FUNCTION 21 - init PPIDE device
        .WORD   IDE_READ_SECTOR                   ; FUNCTION 22 - read a sector from PPIDE device
        .WORD   IDE_WRITE_SECTOR                  ; FUNCTION 23 - write a sector to PPIDE device
;
        .WORD   FPSD_INIT                         ; FUNCTION 24 - init PPIDE device
        .WORD   FPSD_READ_SECTOR                  ; FUNCTION 25 - read a sector from PPIDE device
        .WORD   FPSD_WRITE_SECTOR                 ; FUNCTION 26 - write a sector to PPIDE device
;
        .WORD   DSKY_INIT                         ; FUNCTION 27 -
        .WORD   DSKY_SHOW                         ; FUNCTION 28 -
        .WORD   DSKY_BIN2SEG                      ; FUNCTION 29 -
        .WORD   DSKY_RESET                        ; FUNCTION 30 -
        .WORD   DSKY_STAT                         ; FUNCTION 31 -
        .WORD   DSKY_GETKEY                       ; FUNCTION 32 -
        .WORD   DSKY_BEEP                         ; FUNCTION 33 -
        .WORD   DSKY_DSPL                         ; FUNCTION 34 -
        .WORD   DSKY_PUTLED                       ; FUNCTION 35 -
        .WORD   DSKY_BLANK                        ; FUNCTION 36 -
        .WORD   FP_INIT                           ; FUNCTION 37 -
        .WORD   FP_SETLED                         ; FUNCTION 38 -
        .WORD   FP_GETSWITCH                      ; FUNCTION 39 -
        .WORD   PCF_INIT                          ; FUNCTION 40 -
        .WORD   PCF_READBYTES                     ; FUNCTION 41 -
        .WORD   PCF_SENDBYTES                     ; FUNCTION 42 -
        .WORD   PCF_INITDEV                       ; FUNCTION 43 -
;


;__DRIVERS___________________________________________________________________________________________
;
        INCLUDE cubix_serial.asm
        INCLUDE cubix_ide.asm
        INCLUDE cubix_dskyng.asm
        INCLUDE cubix_floppy.asm
        INCLUDE cubix_fp.asm
        INCLUDE cubix_i2c.asm
;        INCLUDE cubix_esp32.asm
;        INCLUDE cubix_dsky.asm



drv_noop:
        RTS

;*
;* OUTPUT LFCR TO CONSOLE
;*
LFCR:
        PSHS    a,b
        LDA     #10
        BSR     PUTCHR
        LDA     #13
        BSR     PUTCHR
        PULS    A,B,pc
SPACE:
        PSHS    a,b
        LDA     #32
        BSR     PUTCHR
        PULS    A,B,pc
;*
;* WRITE STRING(X) TO CONSOLE
;*
WRSTR:
        PSHS    A,B                               ;SAVE A
WRST1:
        LDA     ,X+                               ;GET CHAR
        BEQ     WRST2                             ;END, QUIT
        BSR     PUTCHR
        BRA     WRST1                             ;CONTINUE
WRST2:
        PULS    A,B,pc
;*
;* OUTPUT NUMBER IN 'D' TO CONSOLE IN HEX
;*
WRHEXW
        PSHS    d
        BSR     WRHEX                             ;OUTPUT
        EXG     A,B                               ;SWAP
        BSR     WRHEX                             ;OUTPUT
        EXG     A,B                               ;BACK
        PULS    d,pc

;*
;* OUTPUT 'A' NUMBER TO CONSOLE IN HEX
;*
WRHEX
        PSHS    A,B                               ;SAVE IT
        LSRA                                      ;SHIFT
        LSRA                                      ;HIGH NIBBLE
        LSRA                                      ;INTO
        LSRA                                      ;LOW NIBBLE
        BSR     HOUT                              ;HIGH
        LDA     ,S                                ;GET LOW
        BSR     HOUT                              ;OUTPUT
        PULS    A,B,PC                            ;RESTORE IT
;* OUTPUT NIBBLE IN HEX
HOUT
        ANDA    #%00001111                        ;REMOVE HIGH
        ADDA    #'0'                              ;CONVERT
        CMPA    #'9'                              ;OK?
        BLS     PUTCHR                            ;OK, OUTPUT
        ADDA    #7                                ;CONVERT TO 'A'-'F'
        BRA     PUTCHR                            ;OUTPUT
PUTCHR:
        JMP     WRSER1
        PSHS    B
        PSHS    A
        ASLB                                      ; DOUBLE NUMBER FOR TABLE LOOKUP
        LDA     #$00
        LDB     CONSOLEDEVICE
        TFR     D,X
        LDD     DISPATCHTABLE,X
        STD     farpointer
        PULS    A
        JSR     [farpointer]
        PULS    B
        RTS

        END
