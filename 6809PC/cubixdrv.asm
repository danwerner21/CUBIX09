;________________________________________________________________________________________________________________________________
;
;	6809PC Cubix banked driver code
;
;  DWERNER 5/17/2025 	Initial
;________________________________________________________________________________________________________________________________

;*
        INCLUDE cubix_values.asm
;*

        ORG     $C100

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

        .WORD   ESPVIDEOOUT                       ; FUNCTION 03 - WRITE ESP VIDEO
        .WORD   ESPPS2IN                          ; FUNCTION 04 - READ ESP KEYBOARD
        .WORD   ESPINIT                           ; FUNCTION 05 - INIT ESP

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
        .WORD   drv_noop                          ;FL_SETUP                          ; FUNCTION 18 - init floppy device
        .WORD   drv_noop                          ;FL_READ_SECTOR                    ; FUNCTION 19 - read a sector from floppy device
        .WORD   drv_noop                          ;FL_WRITE_SECTOR                   ; FUNCTION 20 - write a sector to floppy device
;
        .WORD   XTIDE_INIT                        ; FUNCTION 21 - init XT IDE device
        .WORD   IDE_READ_SECTOR                   ; FUNCTION 22 - read a sector from XT IDE device
        .WORD   IDE_WRITE_SECTOR                  ; FUNCTION 23 - write a sector to XT IDE device
;
        .WORD   CH375INIT                         ; FUNCTION 24 - init CH375 USB device
        .WORD   CH_READSEC                        ; FUNCTION 25 - read a sector from CH375 USB device
        .WORD   CH_WRITESEC                       ; FUNCTION 26 - write a sector to CH375 USB device
;
        .WORD   drv_noop                          ; FUNCTION 27 -
        .WORD   drv_noop                          ; FUNCTION 28 -
        .WORD   drv_noop                          ; FUNCTION 29 -
;
        .WORD   drv_noop                          ; FUNCTION 30 -
        .WORD   drv_noop                          ; FUNCTION 31 -
        .WORD   drv_noop                          ; FUNCTION 32 -
;
        .WORD   drv_noop                          ; FUNCTION 33 -
        .WORD   drv_noop                          ; FUNCTION 34 -
        .WORD   drv_noop                          ; FUNCTION 35 -
;
        .WORD   drv_noop                          ; FUNCTION 36 -
        .WORD   drv_noop                          ; FUNCTION 37 -
        .WORD   drv_noop                          ; FUNCTION 38 -
;
        .WORD   drv_noop                          ; FUNCTION 39 -
        .WORD   drv_noop                          ; FUNCTION 40 -
        .WORD   drv_noop                          ; FUNCTION 41 -
;
        .WORD   drv_noop                          ; FUNCTION 42 -
        .WORD   drv_noop                          ; FUNCTION 43 -
        .WORD   drv_noop                          ; FUNCTION 44 -
;
        .WORD   drv_noop                          ; FUNCTION 45 -
        .WORD   drv_noop                          ; FUNCTION 46 -
        .WORD   drv_noop                          ; FUNCTION 47 -
;
        .WORD   drv_noop                          ; FUNCTION 48 -
        .WORD   drv_noop                          ; FUNCTION 49 -
        .WORD   drv_noop                          ; FUNCTION 50 -
;
        .WORD   MULTIOINIT                        ; FUNCTION 51 - INIT MULTI IO CARD
        .WORD   KBD_GETKEY                        ; FUNCTION 52 - KEYBOARD INPUT
        .WORD   LPT_OUT                           ; FUNCTION 53 - LPT OUTPUT
;
        .WORD   ESPPS2BUFL                        ; FUNCTION 54 - return number of characters in the keyboard buffer in 'A'
        .WORD   ESPCURSORV                        ; FUNCTION 55 - Set Cursor Visibility (A=0 cursor off, A=1 cursor on)
        .WORD   ESPSER0OUT                        ; FUNCTION 56 - OUTPUT A CHARACTER TO Serial 0 ('A' POINTS TO BYTE)
        .WORD   ESPSER0IN                         ; FUNCTION 57 - read a character from Serial 0 ('A' POINTS TO BYTE)
        .WORD   ESPSER0BUFL                       ; FUNCTION 58 - return number of characters in the Serial 0 buffer in 'A'
        .WORD   ESPSER1OUT                        ; FUNCTION 59 - OUTPUT A CHARACTER TO Serial 1 ('A' POINTS TO BYTE)
        .WORD   ESPSER1IN                         ; FUNCTION 60 - read a character from Serial 1 ('A' POINTS TO BYTE)
        .WORD   ESPSER1BUFL                       ; FUNCTION 61 - return number of characters in the Serial 1 buffer in 'A'
        .WORD   ESPNETCOUT                        ; FUNCTION 62 - OUTPUT A CHARACTER TO Network Console Connection ('A' POINTS TO BYTE)
        .WORD   ESPNETCIN                         ; FUNCTION 63 - read a character from Network Console Connection ('A' POINTS TO BYTE)
        .WORD   ESPNETCBUFL                       ; FUNCTION 64 - return number of characters in the Network Connection buffer in 'A'
        .WORD   PUTESP0                           ; FUNCTION 65 - put opcode/data to ESP0
        .WORD   PUTESP1                           ; FUNCTION 66 - put opcode/data to ESP1
        .WORD   GETESP0                           ; FUNCTION 67 - get opcode/data from ESP0
        .WORD   GETESP1                           ; FUNCTION 68 - get opcode/data from ESP1

;__DRIVERS___________________________________________________________________________________________
;
        INCLUDE cubix_serial.asm
        INCLUDE cubix_ide.asm
        INCLUDE cubix_multio.asm
        INCLUDE cubix_esp.asm
        INCLUDE cubix_ch375.asm



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
;       NOTE THAT EVENTUALLY THIS NEEDS TO BE THE SYSTEM SSR NOT A DIRECT CALL
        PSHS    A
        JSR     ESPVIDEOOUT
        PULS    A
        JMP     WRSER1



        fcb     00,00,00,00,00,00,00,00,00,00,00,00
        fcb     00,00,00,00,00,00,00,00,00,00,00,00
        fcb     00,00,00,00,00,00,00,00,00,00,00,00
        fcb     00,00,00,00,00,00,00,00,00,00,00,00
        END
