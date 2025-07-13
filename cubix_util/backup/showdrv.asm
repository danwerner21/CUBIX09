;*
;* SHOWDRV:  Show the current Drive Mapping
;*
;* Dan Werner 9/4/2023
;*

OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE

;*
        ORG     OSUTIL                            ;PROGRAM LOCATION

SHOWDRV:
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCC     'Active Disk Drives:'
        FCB     $0D,$0A
        FCN     '--------------------------'
        SWI
        FCB     111                               ; GET DISK TABLE IN D
        TFR     D,X
        LDY     #$0000
!
        TFR     Y,A
        ADDA    #'A'
        SWI
        FCB     33
        SWI
        FCB     24
        FCN     ':    '
        LDB     ,X+
        LDA     ,X+
        JSR     SHOWDRIVETYPE
        JSR     SHOWDRIVESLICE
        SWI
        FCB     22
        INY
        CMPY    #4
        BNE     <
        SWI
        FCB     22
        RTS

SHOWDRIVETYPE:
        PSHS    A
        TFR     B,A
        ANDB    #$F0
        CMPB    #$00
        BNE     >
        SWI
        FCB     24
        FCN     'NONE.'
        PULS    A
        RTS
!
        CMPB    #$10
        BNE     >
        SWI
        FCB     24
        FCN     'FLOPPY UNIT '
        BRA     SHOWDRIVETYPE1
!
        CMPB    #$20
        BNE     SHOWDRIVETYPE2
        SWI
        FCB     24
        FCN     'IDE UNIT '
SHOWDRIVETYPE1:
        SWI
        FCB     29
        PULS    A
        RTS
!
SHOWDRIVETYPE2:
        CMPB    #$40
        BNE     SHOWDRIVETYPE3
        SWI
        FCB     24
        FCN     'USB UNIT '
        BRA     SHOWDRIVETYPE1
SHOWDRIVETYPE3:
        SWI
        FCB     24
        FCN     'UNKNOWN.'
        PULS    A
        RTS
SHOWDRIVESLICE:
        CMPB    #$20
        BNE     >
        TFR     A,B
        CLRA
        SWI
        FCB     24
        FCN     ', SLICE '
        SWI
        FCB     26
!
        RTS
