;*
;* SHOWDRV:  Show the current Drive Mapping
;*
;* Dan Werner 9/4/2023
;*

OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE

        ORG     0
DPREFIX
        RMB     8
DNAME
        RMB     8
DTYPE
        RMB     3
DDADR
        RMB     2
DRADR
        RMB     2
DATTR
        RMB     1
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
        LDY     #$0004
        LDA     #'A'
!
        SWI
        FCB     33
        SWI
        FCB     24
        FCN     ':    '
        LDB     ,X+
        JSR     SHOWDRIVETYPE
        LDB     ,X+
        JSR     SHOWDRIVESLICE
        SWI
        FCB     22
        INCA
        DEY
        CMPY    #0
        BNE     <
        RTS

SHOWDRIVETYPE:
        PSHS    A
        TFR     B,A
        ANDB    #$F0
        CMPB    #$00
        BNE     >
        FCB     24
        FCN     'NONE.'
        PULS    A
        RTS
!
        CMPB    #$10
        BNE     >
        FCB     24
        FCN     'FLOPPY UNIT '
        BRA     SHOWDRIVETYPE1
!
        CMPB    #$20
        BNE     SHOWDRIVETYPE2
        FCB     24
        FCN     'IDE UNIT '
SHOWDRIVETYPE1:
        SWI
        FCB     29
        PULS    A
        RTS
SHOWDRIVETYPE2:
        FCB     24
        FCN     'UNKNOWN.'
        PULS    A
        RTS
SHOWDRIVESLICE:
        RTS
NODISK
        FCB     $FF                               ;DON'T INCLUDE DISK PREFIX
NODIR
        FCB     $FF                               ;DON'T INCLUDE DIRECTORY
NOTYPE
        FCB     $FF                               ;DON'T INCLUDE TYPE
;* MISC LOCAL VARIABLES
DISK
        RMB     1                                 ;DIRECTORY DISK DRIVE
TEMP
        RMB     2                                 ;TEMP STORAGE
DELIM
        RMB     1                                 ;STRING DELIMITER
WRKSPC
        RMB     512                               ;DIRECTORY LOOKUP SECTOR
OUTFIL
        RMB     522                               ;OUTPUT FILE BUFFER
PREFIX
        RMB     64                                ;PREFIX STRING
POST
        RMB     64                                ;POSTFIX STRING
