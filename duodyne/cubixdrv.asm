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
        .WORD   drv_noop                          ; FL_SETUP                          ; FUNCTION 18 - init floppy device
        .WORD   drv_noop                          ; FL_READ_SECTOR                    ; FUNCTION 19 - read a sector from floppy device
        .WORD   drv_noop                          ; FL_WRITE_SECTOR                   ; FUNCTION 20 - write a sector to floppy device
;
        .WORD   PPIDE_INIT                        ; FUNCTION 21 - init PPIDE device
        .WORD   IDE_READ_SECTOR                   ; FUNCTION 22 - read a sector from PPIDE device
        .WORD   IDE_WRITE_SECTOR                  ; FUNCTION 23 - write a sector to PPIDE device
;
        .WORD   drv_noop                          ; FUNCTION 24 -
        .WORD   drv_noop                          ; FUNCTION 25 -
        .WORD   drv_noop                          ; FUNCTION 26 -
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
;


;__DRIVERS___________________________________________________________________________________________
;
        INCLUDE cubix_serial.asm
        INCLUDE cubix_ide.asm
        INCLUDE cubix_dskyng.asm
;        INCLUDE cubix_dsky.asm
;        INCLUDE cubix_floppy.asm
;        INCLUDE cubix_esp32.asm




drv_noop:
        RTS

;*
;* OUTPUT LFCR TO CONSOLE
;*
LFCR:
        LDA     #10
        BSR     PUTCHR
        LDA     #13
        BSR     PUTCHR
        RTS
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
        PULS    A,B
        RTS
;*
;* OUTPUT NUMBER IN 'D' TO CONSOLE IN HEX
;*
WRHEXW
        BSR     WRHEX                             ;OUTPUT
        EXG     A,B                               ;SWAP
        BSR     WRHEX                             ;OUTPUT
        EXG     A,B                               ;BACK
        RTS
;*
;* OUTPUT 'A' NUMBER TO CONSOLE IN HEX
;*
WRHEX
        PSHS    A                                 ;SAVE IT
        LSRA                                      ;SHIFT
        LSRA                                      ;HIGH NIBBLE
        LSRA                                      ;INTO
        LSRA                                      ;LOW NIBBLE
        BSR     HOUT                              ;HIGH
        LDA     ,S                                ;GET LOW
        BSR     HOUT                              ;OUTPUT
        PULS    A,PC                              ;RESTORE IT
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
