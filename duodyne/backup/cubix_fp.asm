;__FRONT PANEL DRIVERS_____________________________________________________________________________________________________________
;
; 	Duodyne Front Panel Driver
;
;	Entry points:
;               FP_INIT
;               FP_SETLED
;               FP_GETSWITCH
;________________________________________________________________________________________________________________________________
;
;
FP_PORT         = $DF54                           ; PORT
;
;
;__FP_INIT___________________________________________________________________________________________
;
;  FRONT PANEL INFO
;____________________________________________________________________________________________________
;
FP_INIT:
        JSR     LFCR                              ; AND CRLF
        LDX     #FPMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        LDD     #FP_PORT                          ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     LFCR                              ; AND CRLF
        LDX     #FPMESSAGE2
        JSR     WRSTR                             ; DO PROMPT
;
;
        LDX     #$0008
        LDB     FP_PORT
FP_INIT1:
        LDA     #$00
        ROLB
        ADDA     #'0'
        JSR     PUTCHR
        DEX
        CMPX    #$0000
        BNE     FP_INIT1

        JSR     LFCR                              ; AND CRLF
        RTS                                       ; DONE
;
;__FP_SETLED_________________________________________________________________________________________
;
;  SET LED OUTPUT ON FRONT PANEL
;  A=VALUE TO DISPLAY
;____________________________________________________________________________________________________
FP_SETLED:
        STA     FP_PORT
        RTS
;__FP_GETSWITCH______________________________________________________________________________________
;
;  GET SWITCHES FROM FRONT PANEL
;  A=SWITCH VALUE
;____________________________________________________________________________________________________
FP_GETSWITCH:
        LDA     FP_PORT
        RTS                                       ; DONE

FPMESSAGE1:
        FCC     "FRONT PANEL:"
        FCB     $0D,$0A
        FCN     " IO=0x"
FPMESSAGE2:
        FCN     " SWITCH: "
