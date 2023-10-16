;________________________________________________________________________________________________________________________________
;
;	Nhyodyne Cubix banked driver code
;       Intended for RAM BANK $0C
;
;  DWERNER 10/15/2023 	Initial
;________________________________________________________________________________________________________________________________

PAGER_STACK     = $02F5
PAGER_U         = $02F7
PAGER_D         = $02F8
PAGER_X         = $02FA
PAGER_Y         = $02FC
PAGER_S         = $02FE
CONSOLEDEVICE   = $0100                           ; (BYTE)
DISKERROR       = $01F7                           ; (BYTE)
CURRENTHEAD     = $01F8                           ; (BYTE)
CURRENTCYL      = $01F9                           ; (BYTE)
CURRENTSEC      = $01FA                           ; (BYTE)
CURRENTDEVICE   = $01FB                           ; (BYTE)
CURRENTSLICE    = $01FC                           ; (WORD)
farpointer      = $01FE                           ; (WORD)                      ;


        ORG     $8800

; for Nhyodyne:
; RAM BANK $0C is RAM area for Drivers
; RAM BANK $0E is operating bank for DOS/65 $8000-$FFFF
; RAM BANK $0F is fixed bank $0000-$7FFF
; ROM BANKS $00 and $0C-$0F are reserved for ROMWBW code (AS A SECONDARY CPU)

;       Area from $0C:8000 to $0C:8800 reserved for work RAM for drivers (FOR SECONDARY CPU, UNDER ROMWBW)
;       Area from $0C:8000 to $0C:8800 reserved for ROM for drivers (FOR PRIMARY CPU, NO ROMWBW)
;

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
        .WORD   drv_noop                          ; FUNCTION 18 -
        .WORD   drv_noop                          ; FUNCTION 19 -
        .WORD   drv_noop                          ; FUNCTION 20 -
;
        .WORD   PPIDE_INIT                        ; FUNCTION 21 - init floppy device
        .WORD   IDE_READ_SECTOR                   ; FUNCTION 22 - read a sector from floppy device
        .WORD   IDE_WRITE_SECTOR                  ; FUNCTION 23 - write a sector to floppy device
;
        .WORD   drv_noop                          ; FUNCTION 24 -
        .WORD   drv_noop                          ; FUNCTION 25 -
        .WORD   drv_noop                          ; FUNCTION 26 -
;
;        .WORD   DSKY_INIT       ; FUNCTION 40 -
;        .WORD   DSKY_SHOW       ; FUNCTION 41 -
;        .WORD   DSKY_BIN2SEG    ; FUNCTION 42 -
;        .WORD   DSKY_RESET      ; FUNCTION 43 -
;        .WORD   DSKY_STAT       ; FUNCTION 44 -
;        .WORD   DSKY_GETKEY     ; FUNCTION 45 -
;        .WORD   DSKY_BEEP       ; FUNCTION 46 -
;        .WORD   DSKY_DSPL       ; FUNCTION 47 -
;        .WORD   DSKY_PUTLED     ; FUNCTION 48 -
;        .WORD   DSKY_BLANK      ; FUNCTION 49 -
;


;__DRIVERS___________________________________________________________________________________________
;
        INCLUDE cubix_serial.asm
        INCLUDE cubix_ide.asm
;.INCLUDE "doside.asm"
;.INCLUDE "dosdskyn.asm"
;.INCLUDE "dosmd.asm"
;.INCLUDE "dosflp.asm"
;.INCLUDE "dospager.asm"



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
