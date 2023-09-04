;*
;* MOVEAPL: Move the memory origin address for an APL workspace
;*
;* Copyright 1984-2005 Dave Dunfield
;* All rights reserved.
;*
;* WORKSPACE DEFINTIONS
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE
        ORG     OSRAM+512
FREE
        RMB     2                                 ;FREE MEMORY LOCATION
ORIGIN
        RMB     2                                 ;ORIGIN VALUE
SEED
        RMB     2                                 ;RANDOM NUMBER SEED
BUFSIZ
        RMB     2                                 ;WORK BUFFER ALLOCATION SIZE
FREMEM
        RMB     2                                 ;FREE MEMORY ABOVE SYMBOL TABLE
SYMTAB          = *                               ;SYMBOL TABLE STARTS HERE
;* FILE PERMISSIONS
RPERM           = %10000000	READ PERMISSION
WPERM           = %01000000	WRITE PERMISSION
EPERM           = %00100000	EXECUTE PERMISSION
DPERM           = %00010000	DELETE PERMISSION
;* DIRECTORY ENTRY DESCRIPTION
        ORG     0
DPREFIX
        RMB     8                                 ;DIRECTORY PREFIX
DNAME
        RMB     8                                 ;FILENAME
DTYPE
        RMB     3                                 ;FILETYPE
DDADR
        RMB     2                                 ;DISK ADDRESS
DRADR
        RMB     2                                 ;RUN ADDRESS
DATTR
        RMB     1                                 ;FILE ATTRIBUTES
DPASS
        RMB     2                                 ;FILE PASSWORD
;*
        ORG     OSRAM                             ;SET UP POINTER TO OS RAM
;* PROGRAM ENTRY
MOVEAPL
        CMPA    #'?'                              ;QUERY COMMAND?
        BNE     MAIN                              ;NO, CONTINUE
        SWI
        FCB     25                                ;OUTPUT MESSAGE
        FCN     'Use: MOVEAPL <filename> <address>'
ABORT
        SWI
        FCB     0                                 ;EXIT
;* PARSE THE COMMAND LINE PARAMEMTERS AND LOOKUP THE WORKSPACE FILE
MAIN
        SWI
        FCB     11                                ;GET FILENAME
        BNE     ABORT                             ;ERROR, QUIT
        LDD     #$4150                            ;FIRST TWO 'AP'
        STD     ,X                                ;SET IT UP
        LDA     #'L'                              ;LAST
        STA     2,X                               ;SAVE IT
        SWI
        FCB     7                                 ;GET ADDRESS
        BNE     ABORT                             ;ERROR
        STX     NEWADR                            ;SAVE OFFSET
        SWI
        FCB     69                                ;LOOKUP DIRECTORY ENTRY
        BNE     ABORT                             ;ERROR, INVALID
        LDA     DATTR,X                           ;GET FILE ATTRIBUTES
        ANDA    #RPERM+WPERM                      ;TEST READ & WRITE PERMISSION
        CMPA    #RPERM+WPERM                      ;INSURE BOTH ARE ENABLED
        BEQ     MAIN1                             ;ITS OK
        SWI
        FCB     45                                ;ISSUE ERROR MESSAGE
        BRA     ABORT                             ;AND EXIT
;* CALCULATE ADJUSTMENT OFFSET & LOAD THE WORKSPACE
MAIN1
        LDD     NEWADR                            ;GET NEW ADDRESS
        SUBD    DRADR,X                           ;CALCULATE OFFSET TO NEW
        STD     OFFSET                            ;SAVE OFFSET
        LDD     DDADR,X                           ;GET DISK ADDRESS
        LDX     #FREE                             ;GET WORKSPACE
        SWI
        FCB     78                                ;LOAD THE FILE INTO MEMORY
        BNE     ABORT                             ;ERROR, EXIT
;* FIXUP CONSTANT POINTERS IN WORKSPACE
        LDD     FREE                              ;GET FREE MEMORY POINTER
        ADDD    OFFSET                            ;ADJUST
        STD     FREE                              ;RESAVE
        LDD     FREMEM                            ;POINTER TO END OF SYMBOL TABLE
        ADDD    OFFSET                            ;ADJUST
        STD     FREMEM                            ;RESAVE
;* RIFLE THROUGH SYMBOL TABLE, & FIX OFFSETS
        LDX     #SYMTAB                           ;POINT TO SYMBOL TABLE
MAIN2
        LDA     ,X++                              ;GET SYMBOL TYPE & LENGTH
        TFR     A,B                               ;ANOTHER COPY
        ANDA    #%11100000	GET TYPE OF FUNCTION
        ANDB    #%00011111	GET LENGTH OF NAME
        BEQ     MAIN4                             ;END OF TABLE, EXIT
        LEAX    B,X                               ;SKIP NAME
        CMPA    #%01100000	IS IT A LABEL?
        BEQ     MAIN3                             ;IF SO, DON'T ADJUST
        LDD     ,X                                ;GET SYMBOL ADDRESS
        ADDD    OFFSET                            ;ADD IN OFFSET
        STD     ,X                                ;RESAVE IT
MAIN3
        LEAX    2,X                               ;SKIP TO NEXT
        BRA     MAIN2                             ;AND CONTINUE
;* END OF TABLE HAS BEEN FOUND, COMPUTE SIZE OF WORKSPACE AND
;* RESAVE IT TO THE DISK. ALSO ADJUST RUN ADDRESS IN DIRECTORY.
MAIN4
        LDD     FREE                              ;GET FREE MEMORY
        SUBD    NEWADR                            ;CONVERT TO SIZE
        TFR     D,X                               ;COPY TO 'X' FOR DIVIDE
        LDD     #512                              ;DIVIDE BY SECTOR SIZE
        SWI
        FCB     108                               ;PERFORM DIVIDE
        CMPD    #0                                ;ANY REMAINDER
        BEQ     MAIN5                             ;NO, ITS OK
        LEAX    1,X                               ;ADVANCE
MAIN5
        TFR     X,D                               ;SET IT UP
        LDX     #FREE                             ;POINT TO WORK SPACE
        SWI
        FCB     54                                ;SAVE THE FILE
        LBNE    ABORT                             ;INDICATE INVALID
        SWI
        FCB     68                                ;LOOKUP DIRECTORY ENTRY
        LDD     NEWADR                            ;GET NEW ADDRESS
        STD     DRADR,X                           ;SET IT
        SWI
        FCB     85                                ;INFORM DOS THAT IT CHANGED
        CLRA                                      ;	ZERO RETURN CODE
        SWI
        FCB     0                                 ;AND EXIT
;* LOCAL VARIABLES
NEWADR
        RMB     2                                 ;NEW ADDRESS FOR WORKSPACE
OFFSET
        RMB     2                                 ;OFFSET TO NEW ADDRESS
