;* THIS ROUTINE PICKS UP THE NEXT INPUT CHARACTER FROM
;* BASIC. THE ADDRESS OF THE NEXT BASIC BYTE TO BE
;* INTERPRETED IS STORED AT CHARAD.
GETNCH
        INC     CHARAD+1                          ; *PV INCREMENT LS BYTE OF INPUT POINTER
        BNE     GETCCH                            ; *PV BRANCH IF NOT ZERO (NO CARRY)
        INC     CHARAD                            ; *PV INCREMENT MS BYTE OF INPUT POINTER
GETCCH
        FCB     $B6                               ; *PV OP CODE OF LDA EXTENDED
CHARAD
        FCB     $00,$00
        JMP     BROMHK                            ; JUMP BACK INTO THE BASIC RUM


;* CONSOLE IN
LA171
        BSR     KEYIN                             ; GET A CHARACTER FROM CONSOLE IN
        BEQ     LA171                             ; LOOP IF NO KEY DOWN
        RTS

;*
;* THIS ROUTINE GETS A KEYSTROKE FROM THE KEYBOARD IF A KEY
;* IS DOWN. IT RETURNS ZERO TRUE IF THERE WAS NO KEY DOWN.
;*
;*
LA1C1
KEYIN
        SWI
        FCB     35
        BNE     NOCHAR
        ANDA    #$7F
        RTS
NOCHAR
        CLRA
        RTS



;* CONSOLE OUT
PUTCHR
        PSHS    A                                 ;
        CMPA    #CR                               ; IS IT CARRIAGE RETURN?
        BEQ     NEWLINE                           ; YES
        SWI
        FCB     33
        INC     LPTPOS                            ; INCREMENT CHARACTER COUNTER
        LDA     LPTPOS                            ; CHECK FOR END OF LINE PRINTER LINE
        CMPA    LPTWID                            ; AT END OF LINE PRINTER LINE?
        BLO     PUTEND                            ; NO
NEWLINE
        CLR     LPTPOS                            ; RESET CHARACTER COUNTER
        LDA     #13
        SWI
        FCB     33
        LDA     #10                               ; DO LINEFEED AFTER CR
        SWI
        FCB     33
PUTEND
        PULS    A                                 ;
        RTS
