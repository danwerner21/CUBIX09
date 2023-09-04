;*
;* CHGDISK: Change the disk between load and execution
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
;* DIRECTORY STRUCTURE
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
        RMB     2                                 ;DISK ADDRESS
DRADR
        RMB     2                                 ;RUN ADDRESS
DATTR
        RMB     1                                 ;FILE ATTRIBUTES
;* ATTRIBUTE DEFINITIONS
RPERM           EQU %10000000	READ PERMISSION
WPERM           EQU %01000000	WRITE PERMISSSION
EPERM           EQU %00100000	EXECUTE PERMISSION
DPERM           EQU %00010000	DELETE PERMISSION
;* RETURN CODES
RCPRO           EQU 3                             ;PROTECTION VIOLATION
;*
        ORG     OSUTIL-512
;*
CHGDISK
        CMPA    #'?'                              ;HELP REQUEST?
        BNE     MAIN                              ;NO, START IT UP
        SWI
        FCB     25                                ;MESSAGE
        FCN     'Use: CHGDISK [<command string>]'
ABORT
        RTS
MAIN
        SWI
        FCB     4                                 ;COMMAND SUPPLIED?
        BNE     CMDSUP                            ;YES
        SWI
        FCB     88                                ;CLEAR DOS DISK BUFFERS
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     'Insert command disk, and enter command:'
        SWI
        FCB     1                                 ;GET INPUT LINE
        SWI
        FCB     4                                 ;IS IT ENTERED?
        BEQ     ABORT                             ;NO, EXIT
;* WE HAVE COMMAND TO EXECUTE
CMDSUP
        SWI
        FCB     12                                ;GET COMMAND NAME
        LDD     #$4558                            ;FIRST TO OF 'EXE' 'EX'
        STD     ,X                                ;SET TYPE
        STA     2,X                               ;SET LAST 'E'
        SWI
        FCB     69                                ;LOOKUP IN DIRECTORY
        BNE     ABORT                             ;ERROR
        LDA     DATTR,X                           ;GET FILE ATTRIBUTES
        BITA    #EPERM                            ;ALLOWED TO EXECUTE?
        BNE     EXEOK                             ;OK TO EXECUTE
        SWI
        FCB     45                                ;ISSUE PROTECTION ERROR
        RTS
;* LOAD IN FILE & EXECUTE
EXEOK
        LDD     DDADR,X                           ;GET DISK ADDRESS
        LDX     DRADR,X                           ;GET RUN ADDRESS
        STX     >EXEADR                           ;SAVE ADDRESS
        SWI
        FCB     78                                ;LOAD IN FILE
;* WE HAVE FILE IN RAM, PROMPT FOR DISK CHANGE, AND EXECUTE
        SWI
        FCB     88                                ;CLEAR DOS DISK BUFFERS
        SWI
        FCB     24                                ;ISSUE MESSAGE
        FCN     'Insert disks for command execution, press <return>:'
CHKRET
        SWI
        FCB     34                                ;GET CHAR
        CMPA    #$0D                              ;CR?
        BNE     CHKRET                            ;NO, WAIT FOR IT
        SWI
        FCB     22                                ;NEW LINE
        JMP     [EXEADR]	EXECUTE COMMAND
;* MISC LOCAL VARIABLES
EXEADR
        RMB     2                                 ;EXECUTION ADDRESS OF COMMAND
