;	PAGE
;	SBTTL "--- DEBUGGER ---"

; --------
; DEBUGGER
; --------

; ENTRY: BREAKPOINT # IN [B]

DOBUG:
        LDA     #'B'                              ; "BUG:"
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC
        LDA     #'P'
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC
        JSR     COLON

        STB     ,X+                               ; SHOW BREAKPOINT ID
        JSR     BUGSP                             ; SPACE

        LDA     OPCODE
        BPL     P2OP                              ; 2-OP IF POSITIVE
        CMPA    #176
        BLO     P1OP                              ; 1-OP
        CMPA    #192
        BLO     POP0                              ; 0-OP
        CMPA    #224
        BLO     POPE                              ; EXTENDED 2-OP

        LDA     #'X'                              ; OR X-OP
        BRA     POPC

P2OP:
        LDA     #'2'
        BRA     POPC

P1OP:
        LDA     #'1'
        BRA     POPC

POP0:
        LDA     #'0'
        BRA     POPC

POPE:
        LDA     #'E'

POPC:
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC


        LDA     #'-'                              ; "-OP:"
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC
;DISPLAY
        LDA     #'O'
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC

        LDA     #'P'
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC

        BSR     COLON

        LDA     OPCODE                            ; SHOW OPCODE
        BSR     INHEX
        BSR     BUGSP

        LDA     #'P'                              ; "PC:"
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC

        LDA     #'C'
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC

        BSR     COLON

        TST     ZPCH                              ; IF ZPCH <> 0
        BEQ     DOBZ                              ; PRINT "0"
        LDA     #'1'                              ; ELSE PRINT "1"
        BRA     TOPPC

DOBZ:
        LDA     #'0'
TOPPC:
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC


        LDA     ZPCM                              ; PRINT ZPCM & L
        BSR     INHEX
        LDA     ZPCL
        BSR     INHEX
        BSR     BUGSP

        RTS

; -------------
; PRINT A COLON
; -------------

COLON:
        LDA     #':'
        BRA     POOP

; -------------
; PRINT A SPACE
; -------------

BUGSP:
        LDA     #$20
        BRA     POOP

; ----------------
; PRINT [A] IN HEX
; ----------------

INHEX:
        TFR     A,B
        LSRA                                      ; SHIFT HIGH NIBBLE INTO PLACE
        LSRA
        LSRA
        LSRA

        BSR     TOASC                             ; CONVERT HIGH NIBBLE & SHOW
        TFR     B,A

TOASC:
        ANDA    #%00001111
        CMPA    #10                               ; CONVERT LOW NIBBLE & SHOW
        BLO     IH1
        ADDA    #7
IH1:
        ADDA    #$30

POOP:
        PSHS    A,B,X,Y,U,CC
        SWI
        FCB     33                                ;DISPLAY
        PULS    A,B,X,Y,U,CC

        RTS
