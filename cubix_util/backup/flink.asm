;*
;* FLINK: Link/Unlink file directory entries
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
;* DIRECTORY STRUCTURE
OSRAM           = $2000                           ; APPLICATION RAM AREA
OSEND           = $DBFF                           ; END OF GENERAL RAM
OSUTIL          = $D000                           ; UTILITY ADDRESS SPACE

        ORG     0
FPREFIX
        RMB     8                                 ;DIRECTORY PREFIX
FNAME
        RMB     8                                 ;FILE NAME
FTYPE
        RMB     3                                 ;FILE TYPE
FDADDR
        RMB     2                                 ;DISK ADDRESS
FLADDR
        RMB     2                                 ;LOAD ADDRESS
FPROT
        RMB     1                                 ;FILE PROTECTIONS
FSPARE
        RMB     8                                 ;USER SPARE
FDSIZE          = *                               ;SIZE OF DIR ENTRY
;* PROTECTION BITS IN "FPROT" FIELD
RPERM           = %10000000	READ PERMISSION
WPERM           = %01000000	WRITE PERMISSION
EPERM           = %00100000	EXECUTE PERMISSION
DPERM           = %00010000	DELETE PERMISSION
        ORG     OSUTIL                            ;UTILITY SPACE
;*
FLINK
        CMPA    #'?'                              ;QUERY?
        BNE     QUAL                              ;NO, TEST FOR QUALIFIERS
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     'Use: FLINK/UNLINK <file> [file ...]'
ABORT
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
;* INVALID QUALIFIER RECEIVED
QERR
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     'Invalid qualifier: '
        LDA     ,Y+                               ;GET CHARACTER
DSQU1
        SWI
        FCB     33                                ;DISPLAY
        SWI
        FCB     5                                 ;GET NEXT CHAR
        BEQ     GOABO                             ;END, EXIT
        CMPA    #'/'                              ;NEXT QUALIFIER
        BNE     DSQU1                             ;NO, KEEP DUMPING
GOABO
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCB     $27,00                            ;ENDING QUOTE
        LDA     #1                                ;INVALID OPERAND RC
        RTS
;*
;* MAIN PROGRAM
;*
MAIN
        LDA     >QFLAGS                           ;UNLINK MODE?
        BEQ     MAIN5                             ;YES, DO UNLINK
;*
;* LINK MODE, LINK DIRECTORY ENTRIES TO EXISTING FILES
;*
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;ERROR, EXIT
        LDA     -1,X                              ;GET DRIVE SPEC
        STA     >DRIVE                            ;SAVE IT
        SWI
        FCB     69                                ;LOOKUP FILE
        BNE     ABORT                             ;ERROR, EXIT
        LEAX    FDADDR,X	OFFSET TO DISK ADDRESS
        LDU     #SAVDIR                           ;SAVE AREA
        LDB     #FDSIZE-FDADDR	GET SIZE
MAIN1
        LDA     ,X+                               ;GET CHAR
        STA     ,U+                               ;SAVE IT
        DECB                                      ;	REDUCE COUNT
        BNE     MAIN1                             ;AND CONTINUE
;* CREATE NEW FILE, AND COPY IN OTHER DIRECTORY INFO
MAIN2
        SWI
        FCB     10                                ;GET NAME
        BNE     ABORT                             ;ERROR, EXIT
        LDA     -1,X                              ;GET DRIVE SPEC
        CMPA    >DRIVE                            ;IS IT SAME?
        BNE     MAIN4                             ;NO, REPORT ERROR
        SWI
        FCB     72                                ;CREATE THE FILE
        BNE     ABORT                             ;ERROR, EXIT
        STD     >SECTOR                           ;SAVE SECTOR ID
        LEAX    FDADDR,X	OFFSET TO ADDRESS
        LDU     #SAVDIR                           ;POINT TO SAVED ENTRY
        LDB     #FDSIZE-FDADDR	GET SIZE
MAIN3
        LDA     ,U+                               ;GET CHAR
        STA     ,X+                               ;WRITE TO DIR
        DECB                                      ;	REDUCE COUNT
        BNE     MAIN3                             ;AND CONTINUE
        SWI
        FCB     85                                ;INDICATE WE CHANGED
        LDD     >SECTOR                           ;GET SECTOR LINK OF NEW FILE
        SWI
        FCB     80                                ;RELEASE CHAIN
        SWI
        FCB     4                                 ;MODE OPERANDS
        BNE     MAIN2                             ;CONTINUE
        RTS
;* LINK NAME SPECIFIED A DIFFERENT DRIVE THAN SOURCE
MAIN4
        LDY     #ERRMSG                           ;POINT TO ERROR MESSAGE
        SWI
        FCB     52                                ;OUTPUT ERROR MESSAGE
        LDA     #100                              ;ERROR CODE
        RTS
;*
;* UNLINK MODE, UNLINK FILES FROM DIRECTORY ENTRIES
;*
MAIN5
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT1                            ;ERROR, EXIT
        SWI
        FCB     69                                ;LOOKUP FILE
        BNE     ABORT1                            ;ERROR, EXIT
        LDA     FPROT,X                           ;GET FILE PROTECTIONS
        BITA    #DPERM                            ;DELETE ALLOWED?
        BEQ     MAIN7                             ;NO, REPORT ERROR
        LDB     #FDSIZE                           ;GET DIRECTORY SIZE
MAIN6
        CLR     ,X+                               ;ZERO ONE BYTE
        DECB                                      ;	REDUCE COUNT
        BNE     MAIN6                             ;DO THEM ALL
        SWI
        FCB     85                                ;MAKE WORK SECTOR AS CHANGED
        SWI
        FCB     4                                 ;MORE OPERANDS?
        BNE     MAIN5                             ;YES, HANDLE THEM
ABORT1
        RTS
;* FILE DOES NOT HAVE "DELETE" PERMISSION, REPORT VIOLATION
MAIN7
        SWI
        FCB     45                                ;ISSUE "PROTECTION VIOLATION"
        RTS
;* STRINGS & CONSTANTS
ERRMSG
        FCN     'Cannot link between drives.'
QTABLE
        FCB     $82
        FCC     '/UNLINK'
        FCB     $80                               ;END OF TABLE
QMAX            = 1                               ;# QUALIFIERS
;* QUALIFIER FLAGS
QFLAGS
        FCB     $FF                               ;UNLINK MODE
;* TEMPORARY STORAGE
DRIVE
        RMB     1                                 ;SOURCE FILE DRIVE
SECTOR
        RMB     2                                 ;NEW DISK SECTOR
SAVDIR
        RMB     FDSIZE-FDADDR	SAVED DIR ENTRY
