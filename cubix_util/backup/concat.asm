;*
;* CONCAT: File concatination utility
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000       APPLICATION RAM AREA
OSEND           = $DBFF       END OF GENERAL RAM
OSUTIL          = $D000       UTILITY ADDRESS SPACE
        ORG     OSRAM
;*
CONCAT
        CMPA    #'?'                              ;QUERY?
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIERS
        SWI
        FCB     25
        FCN     'Use: CONCAT[/QUIET] <destination> <source1> [<source2>] ...'
        RTS
;* PARSE FOR COMMAND QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR FROM COMMAND LINE
        CMPA    #'/'                              ;IS IT A QUALIFIER?
        BNE     MAIN                              ;NO, CONTINUE WITH MAIN PROGRAM
        LEAX    QTABLE,PCR	POINT TO QUALIFIER TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;IS IT IN RANGE
        BHS     QERR                              ;IF SO, IT'S INVALID
        LEAX    QFLAGS,PCR	POINT TO QUALIFIER FLAGS
        CLR     B,X                               ;SET THE FLAG
        BRA     QUAL                              ;LOOK FOR ANOTHER QUALIFIER
QERR
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Invalid qualifier: '
        LDA     ,Y+                               ;GET CHARACTER
DSQU1
        SWI
        FCB     33                                ;DISPLAY
        LDA     ,Y+                               ;GET NEXT CHAR
        BEQ     GOABO                             ;NULL IS DELIMITER
        CMPA    #'/'                              ;START OF ANOTHER QUALIFIER?
        BEQ     GOABO                             ;IF SO, QUIT
        CMPA    #' '                              ;SPACE?
        BEQ     GOABO                             ;IF SO, QUIT
        CMPA    #$0D                              ;END OF LINE?
        BNE     DSQU1                             ;NO, KEEP DUMPING
GOABO
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCB     $27,0                             ;CHARACTERS TO DISPLAY
        LDA     #1                                ;INVALID OPERAND RETURN CODE
        LBRA    ABORT
;* OPEN OUTPUT FILE
MAIN
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;ERROR
        LDU     #OUTFIL                           ;PT TO FILE POINTER
        SWI
        FCB     56                                ;OPEN OUTPUT FILE TO WRITE
        BNE     ABORT                             ;ERROR
;* OPEN INPUT FILE
OPENIN
        SWI
        FCB     10
        BNE     ABORT1
        LDX     #RAM
        SWI
        FCB     53
        BNE     ABORT
        LDA     #$FF
        STA     ,X+                               ;INCASE EXACTLY ONE BLOCK
;* WRITE TO OUTPUT
        LDX     #RAM
WR1
        LDA     ,X+
        BMI     WR2
        TFR     A,B
        SWI
        FCB     61
        CMPB    #$0D
        BNE     WR1
        LDD     LINECT
        ADDD    #1
        STD     LINECT
        BRA     WR1
WR2
        SWI
        FCB     4
        BNE     OPENIN
        LDA     QUIET
        BEQ     QUI1
        SWI
        FCB     24
        FCN     'Total of '
        LDD     LINECT
        SWI
        FCB     26
        SWI
        FCB     25
        FCN     ' lines written to output file.'
QUI1
        CLRA
ABORT1
        PSHS    A,CC
        SWI
        FCB     57
        PULS    A,CC
ABORT
        SWI
        FCB     0
;* QUALIFIER TABLE
QTABLE
        FCB     $82
        FCC     '/QUIET'
        FCB     $80                               ;END OF TABLE
QMAX            = 1
;* QUALIFIER FLAGS
QFLAGS          = *
QUIET
        FCB     $FF
;* LOCAL RAM STORAGE
LINECT
        FDB     0
OUTFIL
        RMB     522                               ;OUTPUT BUFFER
RAM             = *
