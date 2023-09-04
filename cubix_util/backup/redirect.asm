;*
;* REDIRECT: Switch console output to/from a file
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
        ORG     OSUTIL
;*
REDIR
        CMPA    #'?'                              ;QUERY?
        BNE     QUAL                              ;SHOW HOW IT'S DONE
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'Use: REDIRECT[/ALL/CLOSE/WRITE] <filename> [<device>]'
        RTS
;* PARSE FOR COMMAND QUALIFIERS
QUAL
        LDA     ,Y                                ;GET CHAR FROM COMMAND LINE
        CMPA    #'/'                              ;IS IT A QUALIFIER?
        BNE     MAIN                              ;NO, GET PARAMETERS
        LDX     #QTABLE                           ;POINT TO QUALIFIER TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;IS IT IN RANGE
        BHS     QERR                              ;IF SO, IT'S INVALID
        LDX     #QFLAGS                           ;POINT TO QUALIFIER FLAGS
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
        RTS
;* MAINLINE CODE
MAIN
        LDA     ACTIVE                            ;GET ACTIVE COUNT
        INC     ACTIVE                            ;ADVANCE COUNT
        CMPA    #16                               ;PAST I/O DRIVERS?
        BHS     MAIN1                             ;IF SO, WE ARE FINISHED
        SWI
        FCB     102                               ;LOOKUP ENTRY
        CMPD    #DRIVER                           ;ALREADY INSTALLED?
        BNE     MAIN                              ;NO, ITS NOT
        CLR     ACTIVE                            ;INDICATE INSTALLED
MAIN1
        LDA     CLOSE                             ;CLOSING FILE?
        BEQ     DOCLOSE                           ;YES, CLOSE IT
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;ERROR, EXIT
        SWI
        FCB     4                                 ;MORE OPERANDS?
        BNE     MAIN2                             ;YES, TAKE THEM
;* NO DEVICE SPECIFIED, USE CONSOLE
        SWI
        FCB     40                                ;GET CURENT CONSOLE
        BRA     MAIN3                             ;AND CONTINUE
;* DEVICE IS SPECIFIED
MAIN2
        SWI
        FCB     6                                 ;GET DEVICE ID
        TFR     B,A                               ;COPY TO 'A'
MAIN3
        CMPA    #8                                ;IN RANGE?
        BLO     OPEN                              ;YES, ITS OK
;* INVALID DEVICE SPECIFIED
        SWI
        FCB     50                                ;OUTPUT 'INVALID DEVICE' MESSAGE
ABORT
        RTS
;* CLOSE OPEN FILE
DOCLOSE
        TST     ACTIVE                            ;ALREADY ACTIVE?
        BNE     ERROR2                            ;NO, REPORT ERROR
        LDU     #FCB                              ;POINT TO FCB
        SWI
        FCB     57                                ;CLOSE THE FILE
        LDX     SDRIVER                           ;GET OLD DRIVER
        LDA     DEVICE                            ;GET VECTOR ID
        SWI
        FCB     103                               ;REPLACE VECTOR
        CLRA                                      ;	ZERO RC
        RTS
;* REDIRECT IS NOT ACTIVE, CANNOT CLOSE
ERROR2
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     'REDIRECT is not active.'
        LDA     #101                              ;RETURN CODE
        RTS
;* OPEN FILE & PERFORM ASIGNMENT
OPEN
        TST     ACTIVE                            ;ALREADY ACTIVE?
        BEQ     ERROR1                            ;YES, REPORT ERROR
        LDU     #FCB                              ;POINT TO FCB
        TST     WRITE                             ;OPEN FOR WRITE?
        BEQ     OPWRITE                           ;YES, DO IT
;* READ OPERATION, INSTALL INPUT DRIVER
        STA     DEVICE                            ;SAVE DEVICE ID
        SWI
        FCB     55                                ;OPEN FILE FOR READ
        BNE     ABORT                             ;ERROR, ABORT
        LDX     #IDRIVER                          ;POINT TO INPUT DRIVER
        BRA     INSTALL                           ;INSTALL IT
;* WRITE OPERATION, INSTALL OUTPUT DRIVER
OPWRITE
        ADDA    #8                                ;OFFSET TO WRITE DRIVER
        STA     DEVICE                            ;SAVE IT
        SWI
        FCB     56                                ;OPEN FILE FOR WRITE
        BNE     ABORT                             ;ERROR, ABORT
        LDX     #ODRIVER                          ;POINT TO OUTPUT DRIVER
;* COPY DRIVER OVER
INSTALL
        LDY     #DRIVER                           ;POINT TO DRIVER
        LDB     #100                              ;100 BYTES MAX
INST1
        LDA     ,X+                               ;GET CHAR
        STA     ,Y+                               ;COPY IT OVER
        DECB                                      ;	DECREMENT COUNT
        BNE     INST1                             ;CONTINUE
        LDA     ALL                               ;GET 'ALL' FLAG
        STA     ALLFLAG                           ;SAVE DRIVERS ALLFLAG
;* TAKE OVER DEVICE INPUT VECTOR
        LDX     #DRIVER                           ;POINT TO DRIVER
        LDA     DEVICE                            ;GET DEVICE ID
        SWI
        FCB     103                               ;SET DEVICE DRIVER
        STD     SDRIVER                           ;SAVED DRIVER ADDRESS
        CLRA                                      ;	ZERO RETURN CODE
        RTS
;* REDIRECT IS ALREADY ACTIVE, REPORT ERROR
ERROR1
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     'REDIRECT is already active.'
        LDA     #100                              ;RETURN CODE
        RTS
;*
;* INPUT DRIVER, READS CHARACTER FROM FILE & RETURN
;*
IDRIVER
        STU     SAVEU                             ;SAVE 'U' REGISTER
        LDU     #FCB                              ;POINT TO INPUT FILE
        SWI
        FCB     59                                ;READ THE CHARACTER
        BNE     IDRIV1                            ;ERROR, ABORT
        LDU     SAVEU                             ;RESTORE 'U'
        ORCC    #%00000100                        ;SET 'Z' FLAG
        RTS
;* END OF FILE, RESTORE DRIVER, AND RETURN NO CHAR READY
IDRIV1
        LDX     SDRIVER                           ;GET SAVED DRIVER
        LDA     DEVICE                            ;GET DEVICE ID
        SWI
        FCB     103                               ;RESET VECTOR
        LDU     SAVEU                             ;RESTORE 'U'
        LDA     #$FF                              ;INDICATE NO CHARACTER
        RTS
;*
;* OUTPUT DRIVER, WRITES CHARACTER TO FILE & RETURN
;*
ODRIVER
        STU     SAVEU                             ;SAVE 'U' REGISTER
        TFR     A,B                               ;SAVE CHAR
        TST     ALLFLAG                           ;DO WE DO ALL?
        BEQ     ODRIV1                            ;YES, SAVE IT
        CMPA    #' '                              ;CONTROL CODE?
        BHS     ODRIV1                            ;NO, ITS OK
        CMPA    #$0A                              ;LINE-FEED?
        BNE     ODRIV2                            ;NO, DON'T SAVE
        LDA     #$0D                              ;CONVERT TO CARRIAGE-RETURN
ODRIV1
        LDU     #FCB                              ;GET FILE CONTROL BLOCK
        SWI
        FCB     61                                ;WRITE THE CHARACTER
        BNE     ODRIV3                            ;ERROR, RESET VECTORS
ODRIV2
        TFR     B,A                               ;RESTORE 'B'
        LDU     SAVEU                             ;RESTORE 'U'
        ORCC    #%00000100                        ;SET 'Z' FLAG
        RTS
;* ERROR DURING WRITE, RETURN TO NORMAL OUTPUT
ODRIV3
        PSHS    B                                 ;SAVE 'B'
        LDX     SDRIVER                           ;GET SAVED DRIVER
        LDA     DEVICE                            ;GET DEVICE
        SWI
        FCB     103                               ;RESTORE VECTOR
        LDU     SAVEU                             ;RESTORE 'U'
        PULS    A                                 ;RESTORE CHRA
        JMP     ,X                                ;EXECUTE DRIVER
;* QUALIFIER TABLE
QTABLE
        FCB     $82
        FCC     '/WRITE'
        FCB     $82
        FCC     '/CLOSE'
        FCB     $82
        FCC     '/ALL'
        FCB     $80                               ;END OF TABLE
QMAX            = 3
QFLAGS          = *
WRITE
        FCB     $FF                               ;ASSIGN FOR WRITE
CLOSE
        FCB     $FF                               ;CLOSE OPEN FILE
ALL
        FCB     $FF                               ;SAVE ALL CHARACTERS
ACTIVE
        FCB     0                                 ;REDIRECT IS ACTIVE FLAG
;* GLOBAL LOCATIONS
        ORG     OSEND-DSIZE                       ;1K FROM TOP OF RAM
DEVICE
        RMB     1                                 ;INPUT DEVICE
ALLFLAG
        RMB     1                                 ;GET ALL FLAG
SDRIVER
        RMB     2                                 ;OLD DRIVER VECTOR
SAVEU
        RMB     2                                 ;SAVED 'U' REGISTER
FCB
        RMB     522                               ;INPUT FILE CONTROL BLOCK
DRIVER
        RMB     100                               ;DRIVER GOES HERE
DSIZE           = *-DEVICE                        ;SIZE OF LOCAL STORAGE
