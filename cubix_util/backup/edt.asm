;	title	EDT SCREEN EDITOR
;*
;* EDT: A terminal independant screen editor
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
;* SCREEN HANDLING CHARACTERS
OSRAM           = $2000                           ; APPLICATION RAM AREA
OSEND           = $DBFF                           ; END OF GENERAL RAM
OSUTIL          = $D000                           ; UTILITY ADDRESS SPACE
CL              = $80                             ;CLEAR SCREEN
CE              = $81                             ;CLEAR TO END OF LINE
CD              = $82                             ;CLEAR TO END OF SCREEN
SO              = $83                             ;SPECIAL EFFECTS ON
SE              = $84                             ;SPECIAL EFFECTS OFF
SF              = $85                             ;SCROLL FORWARD
;* KEYBOARD INPUT CHARACTERS
KUP             = $80                             ;UP KEY
KDO             = $81                             ;DOWN KEY
KDP             = $8B                             ;DELETE PREVIOUS
KCM             = $8D                             ;COMMAND MODE
;* STANDARD TEXT INPUT CHARACTERS
NL              = $0D                             ;NEW LINE (CARRIAGE RETURN)
TAB             = $09                             ;TAB CHARACTER
;* MISC CONSTANTS
LINES           = 24                              ;# LINES ON THE SCREEN
COLS            = 80                              ;COLUMNS
DATA_BEGINS     = $3000                           ;Must be page aligned and after the last byte of code !
DATA_BEGINS_P   = $30                             ;Page number for data_begins
;*
        ORG     OSRAM
;*
;* TERMINAL INITIALIZATION.
;*
ENTRY
        LDX     ISTPTR                            ;GET INPUT STRING POINTER
        SWI
        FCB     23                                ;OUTPUT TO TERMINAL
        SWI
        FCB     4                                 ;GET OPERANDS
        CMPA    #'?'                              ;QUERY OPERATION?
        BNE     EDT1                              ;NO, KEEP GOING
        SWI
        FCB     25                                ;ISSUE MESSAGE
        FCN     'Use: EDT <file>'
ABORT
        SWI
        FCB     0                                 ;EXIT
EDT1
        LDA     #DATA_BEGINS_P                    ;GET HIGH ADDRSS OF DATA
        TFR     A,DP                              ;SET UP DP
        SETDP   DATA_BEGINS_P                     ;INFORM ASSEMBLER
;* INIT LOCAL VARIABLES & SAME FILENAME
        LDX     #NAMBUF                           ;POINT TO NAME BUFFER
        LDA     [GXYPTR]	GOTOXY DEFINED?
        BNE     EDT2                              ;YES, ITS OK
        CLR     WINDOW                            ;SWITCH TO LINE MODE
EDT2
        LDA     ,Y+                               ;GET CHAR
        STA     ,X+                               ;SAVE IN BUFFER
        CMPA    #$0D                              ;END OF LINE?
        BNE     EDT2                              ;NO, KEEP GOING
        CLR     -1,X                              ;ZERO THE BUFFER
        LDY     #NAMBUF                           ;POINT TO NAME
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;INVALID, EXIT
;* LOAD FILE
        SWI
        FCB     68                                ;DOES IT EXIST
        BEQ     EDT3                              ;YES IT DOES
        LDD     #NEWMSG                           ;POINT TO NEW MESSAGE
        STD     ERRMSG                            ;SAVE IT OUT
        LDX     #T_BUFF                           ;POINT TO BUFFER
        BRA     EDT3A                             ;AND PROCEED
EDT3
        LDX     #T_BUFF                           ;POINT TO TEXT BUFFER
        SWI
        FCB     53                                ;LOAD FILE
EDT3A
        LDA     #$FF                              ;END OF FILE
        STA     ,X                                ;MARK POSITION
;* MOVE TO HOME POSITION
EDT4
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     CX                                ;ZERO 'X' AND 'Y'
        STD     NEWPOS                            ;NO RE-POSITION
        LDD     #T_BUFF                           ;POINT TO TEXT BUFFER
        STD     SCRTOP                            ;SET START OF SCREEN
        STD     TXTPOS                            ;SET START OF LINE
        DEC     REFLAG                            ;SET REFRESH FLAG
;* PROMPT FOR AND EXECUTE SCREEN MODE COMMANDS
SCR
        LDA     WINDOW                            ;IN WINDOW MODE?
        LBPL    LINE                              ;LINE MODE COMMAND
        LDU     NEWPOS                            ;HAS POSITION CHANGED
        BEQ     SCR1                              ;NO, ITS OK
        JSR     REPOS                             ;REPOSITION TO IT
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     NEWPOS                            ;INSURE NO FURTHER POSITION
SCR1
        JSR     POSITC                            ;POSITION THE CURSOR
        STB     TEMP                              ;SAVE 'X' FOR LATER
        PSHS    U                                 ;SAVE REGS
;* UPDATE SCREEN IF R=IRED
        LDA     REFLAG                            ;REFRESH R=IRED?
        BEQ     SCR2                              ;NO, ITS OK
        JSR     REFALL                            ;REFRESH SCREEN
;* WRITE ANY PENDING ERROR MESSAGES
SCR2
        LDX     ERRMSG                            ;ANY ERROR MESSAGES?
        BEQ     SCR3                              ;NO, ITS OK
        JSR     GOTOLST                           ;MOVE TO IT
        JSR     WSO                               ;ENABLE SPECIAL EFFECTS
        SWI
        FCB     23                                ;OUTPUT MESSAGE
        JSR     WSE                               ;DISABLE SPECIAL EFFECTS
        JSR     WCD                               ;CLEAR END OF DISPLAY
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     ERRMSG                            ;RESET ERROR MESSAGE FLAG
SCR3
        JSR     GOTOXX                            ;MOVE TO POSITION
        PULS    U                                 ;RESTORE 'U'
;* GET A KEY & EXECUTE COMMANDS
KEY
        LDS     #STACK                            ;FIX STACK
        JSR     GETKEY                            ;GET A KEY COMMAND
        CMPA    #KDO                              ;DOWN KEY?
        BEQ     KEY1                              ;DON'T RESET
        CMPA    #KUP                              ;UP KEY?
        BEQ     KEY1                              ;DON'T RESET
        LDB     TEMP                              ;GET 'X' POSITION
        STB     CX                                ;SAVE ACTUAL 'X'
KEY1
        PSHS    A                                 ;SAVE CHAR
        LDB     CX                                ;GET 'X' POSITION
        CLRA                                      ;	ZERO HIGH
        LEAY    D,U                               ;'Y' = PTR TO CHAR
        LDA     ,S+                               ;SPECIAL CHAR?
        BPL     EDTKEY                            ;EDIT KEY (TEXT) CHANGE
        LSLA                                      ;	X2 FOR TWO BYTE ENTRIES
        LDX     #CMDTAB                           ;POINT TO TABLE
        JSR     [A,X]                             ;EXECUTE COMMAND
        BRA     SCR                               ;GET NEXT COMMAND
;* STANDARD INPUT KEY ENTERED, INSERT IT INTO THE TEXT
EDTKEY
        JSR     EDIT                              ;BEGIN EDIT, Y = PTR TO CHAR
;* IF INSERT MODE OR END OF LINE, INSERT
        LDB     ,Y                                ;GET CHAR
        BMI     EDTK1                             ;EOF, DO INSERT
        CMPB    #NL                               ;END OF LINE?
        BEQ     EDTK1                             ;DO INSERT
        CMPA    #NL                               ;NEW LINE?
        BEQ     EDTK1                             ;YES, INSERT
        TST     INSFLAG                           ;INSERTING?
        BEQ     EDTK4                             ;DON'T INSERT
;* INSERT 1 CHARACTER INTO THE LINE
EDTK1
        PSHS    A,Y                               ;SAVE IT
EDTK2
        TFR     B,A                               ;SAVE CHAR
        LEAY    1,Y                               ;ADVANCE TO NEXT
        LDB     ,Y                                ;GET CHAR
        STA     ,Y                                ;AND
        BPL     EDTK2                             ;DO THEM ALL
        INC     EDTLEN                            ;ADVANCE LENGTH
        PULS    A,Y                               ;RESTORE 'Y'
;* WRITE THE ENTERED CHARACTER OUT
EDTK4
        STA     ,Y                                ;WRITE IN CHAR
        INC     CX                                ;ADVANCE 'X' POSITION
        CMPA    #NL                               ;NEW LINE ENTERED?
        BNE     EDTK5                             ;NO, ITS OK
        JSR     UPDATE                            ;UPDATE THE CHANGES
        JSR     REFBOT                            ;REFRESH BOTTOM OF SCREEN
        CLR     CX                                ;ZERO 'X'
        JSR     FWDLIN                            ;ADVANCE A LINE
        BRA     EDTK6                             ;AND PROCEED
EDTK5
        TFR     Y,U                               ;PTR TO CHAR
        JSR     REFLIN                            ;UPDATE THE LINE
EDTK6
        JMP     SCR                               ;AND GET NEXT COMMAND
;*
;* PROMPT FOR & EXECUTE LINE MODE COMMAND
;*
ECMD
        JSR     GOTOLST                           ;MOVE THERE
        SWI
        FCB     24                                ;OUTPUT TEXT
        FCN     'Command: '
        JSR     WCD                               ;CLEAR DISPLAY
        LDX     #COMMAND	POINT TO COMMAND BUFFER
        BSR     GETLIN                            ;GET INPUT LINE
RCMD
        JSR     GOTOLST                           ;MOVE THERE
        JSR     WSO                               ;ENABLE SPECIAL EFFECTS
        DEC     VIDEO                             ;SET VIDEO FLAG
        LDX     #COMMAND	POINT TO COMMAND
RCMD1
        LDA     ,X+                               ;GET CHAR
        BMI     RCMD2                             ;END OF THE ROAD
        JSR     WRCHR                             ;DISPLAY IT
        BRA     RCMD1                             ;AND PROCEED
RCMD2
        JSR     WSE                               ;END SPECIALS
        CLR     VIDEO                             ;RESET VIDEO FLAG
        JSR     WCD                               ;CLEAR IT
        JSR     UPDATE                            ;UPDATE CHANGES
        JSR     EXEC                              ;EXECUTE COMMAND
        LDD     ERRMSG                            ;ANY ERRORS
        BNE     RCMD3                             ;YES, DON'T OVERWRITE
        LDD     #NULLMSG	POINT TO NULL MESSAGE
        STD     ERRMSG                            ;SAVE IT
RCMD3
        RTS
;*
;* GET A LINE OF INPUT
;*
GETLIN
        CLRB                                      ;	ZERO COUNT
GETL1
        LDA     WINDOW                            ;WINDOW MODE
        BPL     GETL4                             ;NO, LINE BY LINE
        JSR     GETKEY                            ;GET A KEY
        CMPA    #KDP                              ;DELETE PREVIOUS
        BNE     GETL2                             ;NO, ITS OK
GETL1A
        DECB                                      ;	REDUCE COUNT
        BMI     GETLIN                            ;INVALID, STOP
        SWI
        FCB     24                                ;OUTPUT STRING
        FCB     8,' ',8,0	ERASE CHAR
        BRA     GETL1                             ;AND GET NEXT
GETL2
        CMPA    #KCM                              ;COMMAND KEY
        BEQ     GETL3                             ;AND SAVE IT
        STA     B,X                               ;WRITE CHAR
        BMI     GETL1                             ;IGNORE IF SPECIAL
        INCB                                      ;	ADVANCE B
        JSR     WRCHR                             ;DISPLAY IT
        BRA     GETL1                             ;AND PROCEED
GETL2A
        SWI
        FCB     22                                ;NEW LINE
GETL3
        LDA     #-1                               ;GET EOL MARKER
        STA     B,X                               ;WRITE EOL MARKER
        RTS
;* LINE BY LINE INPUT
GETL4
        SWI
        FCB     34                                ;READ A CHAR
        CMPA    #8                                ;BACKSPACE?
        BEQ     GETL1A                            ;YES, HANDLE IT
        CMPA    #$7F                              ;DELETE
        BEQ     GETL1A                            ;YES, HANDLE IT
        CMPA    #$0D                              ;NEW LINE
        BEQ     GETL2A                            ;SPECIAL CASE
        STA     B,X                               ;WRITE IT OUT
        INCB                                      ;	ADVANCE COUNT
        SWI
        FCB     33                                ;DISPLAY IT
        BRA     GETL4                             ;AND PROCEED
;*
;* EXECUTE LINE MODE COMMANDS
;*
LINE
        LDX     ERRMSG                            ;GET ERROR MESSAGE
        BEQ     LINE1                             ;NONE
        SWI
        FCB     23                                ;DISPLAY IT
        SWI
        FCB     22                                ;NEW LINE
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     ERRMSG                            ;RE-WRITE IT
LINE1
        LDU     NEWPOS                            ;HAS POSITION CHANGED
        BEQ     LINE2                             ;NO, ITS OK
        JSR     REPOS                             ;REPOSITION TO IT
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     NEWPOS                            ;INSURE NO FURTHER POSITION
        BRA     LINE3                             ;AND PROCEED
LINE2
        LDA     REFLAG                            ;DO WE REFRESH
        BEQ     LINE7                             ;NO, ITS OK
LINE3
        LDU     TXTPOS                            ;GET TEXT POSITION
LINE4
        LDA     ,U+                               ;GET CHAR
        BMI     LINE5                             ;END OF FILE
        CMPA    #NL                               ;NEW LINE
        BEQ     LINE6                             ;YES, EXIT
        SWI
        FCB     33                                ;DISPLAY
        BRA     LINE4                             ;AND PROCEED
LINE5
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     '*EOF*'                           ;INDICATE END OF FILE
LINE6
        SWI
        FCB     22                                ;NEW LINE
        CLR     REFLAG                            ;ZERO IT
LINE7
        SWI
        FCB     24                                ;PROMPT
        FCN     ';* '
        LDX     #COMMAND	POINT TO COMMAND BUFFER
        JSR     GETLIN                            ;GET INPUT LINE
        BSR     EXEC                              ;EXECUTE COMMAND
        JMP     SCR                               ;AND PROCEED
;*
;* TEST FOR NUMERIC DIGIT
;*
ISDIGIT
        CMPA    #'0'                              ;IS IT DIGIT?
        BLO     ISDIG1                            ;NO, ITS NOT
        CMPA    #'9'                              ;TEST AGAIN
        BHI     ISDIG1                            ;ITS NOT
        ORCC    #%00000100	SET 'Z', INDICATE FOUND
ISDIG1
        RTS
;*
;* GET NUMBER FROMLINE(Y)
;*
GETNUM
        JSR     SKIP                              ;ADVANCE TO NON-BLANK
        LDX     #0                                ;BEGIN WITH ZERO
GETN1
        LDA     ,Y                                ;GET NEXT
        BSR     ISDIGIT                           ;IS IT A DIGIT?
        BNE     SKIP                              ;NO, EXIT
        LDD     #10                               ;X 10
        SWI
        FCB     107                               ;DO MUTIPLY
        TFR     D,X                               ;SWAP BACK
        LDB     ,Y+                               ;RESTORE VALUE
        SUBB    #'0'                              ;CONVERT
        ABX                                       ;	INCLUDE
        BRA     GETN1                             ;AND PROCEED
;*
;* LOOKUP THE LINE BY NUMBER(X)
;*
FINDLIN
        LDU     #T_BUFF                           ;POINT TO TEXT BUFFER
FINDL1
        LEAX    -1,X                              ;REDUCE COUNT
        BEQ     FINDL4                            ;WE HAVE IT
FINDL2
        LDA     ,U+                               ;GET CHAR
        BMI     FINDL3                            ;END, EXIT
        CMPA    #NL                               ;NEW-LINE
        BNE     FINDL2                            ;WAIT FOR IT
        BRA     FINDL1                            ;AND PROCEED
FINDL3
        LEAU    -1,U                              ;BACKUP
FINDL4
        RTS
;*
;* SKIP AHEAD TO NON-BLANK
;*
SKIP
        LDA     ,Y+                               ;GET CHAR
        CMPA    #' '                              ;BLANK?
        BEQ     SKIP                              ;KEEP LOOKING
        LDA     ,-Y                               ;SET FLAGS AGAIN
        RTS
;*
;* EXECUTE A LINE MODE COMMAND(Y)
;*
EXEC
        LDY     #COMMAND	POINT TO COMMAND BUFFER
        CLR     START                             ;ZERO FIRST PARM FLAG
        CLR     TEMP+2                            ;ZERO RANGE GIVEN FLAG
        CLR     TEMP+3                            ;ZERO TAGGS USED FLAG
GETRNG
        BSR     SKIP                              ;ADVANCE POSITIN
;* NUMBER, LOOKUP LINE
        BSR     ISDIGIT                           ;IS IT A NUMBER
        BNE     GETRN1                            ;NOT A NUMBER
        BSR     GETNUM                            ;GET LINE NUMBER
        BSR     FINDLIN                           ;LOCATE LINE POSITION
        BRA     GETRN5                            ;AND PROCEED
;* '=' TAGGED LINES
GETRN1
        LEAY    1,Y                               ;ADVANCE
        CMPA    #'='                              ;TAGGED LINES?
        BNE     GETRN2                            ;NO, TRY NEXT
        DEC     TEMP+3                            ;INDICATE TAGGS USED
        LDU     TAG                               ;GET FIRST TAG
        BEQ     GETRN1A                           ;NO TAGGS DEFINED
        LDX     TAG1                              ;'X' = EOT
        BRA     GETRN5A                           ;AND PROCEED
GETRN1A
        LDD     #NOTAGG                           ;POINT TO MESSAGE
        STD     ERRMSG                            ;SET IT UP
        RTS                                       ;	EXIT
;* '/' WHOLE FILE
GETRN2
        CMPA    #'/'                              ;ENTIRE FILE?
        BNE     GETRN3                            ;NO, TRY NEXT
        JSR     FINDEOF                           ;LOCATE END OF FILE
        TFR     U,X                               ;'X' = EOT
        LDU     #T_BUFF                           ;GET START OF BUFFER
        BRA     GETRN5A                           ;AND PROCEED
;* ';*', CURRENT LINE
GETRN3
        LDU     TXTPOS                            ;GET TEXT POSITION
        CMPA    #'*'                              ;CURRENT LINE
        BEQ     GETRN4                            ;YES, HANDLE IT
        TFR     U,X                               ;'X' = VALUE ALSO
        LEAY    -1,Y                              ;BACKUP TO IT
        BRA     GETRN5B                           ;AND PROCEED
GETRN4
        LDU     TXTPOS                            ;GET POSITION
GETRN5
        TFR     U,X                               ;'X' = POSITION
GETRN5A
        DEC     TEMP+2                            ;INDICATE OPERAND RECEIVED
GETRN5B
        JSR     SKIP                              ;SKIP BLANKS
        LDA     ,Y+                               ;GET NEXT CHAR
;* TEST FOR ADD OF SUBTRACT FROM RANGE
        CMPA    #'+'                              ;ADDITION?
        BNE     GETRN7                            ;NO, ITS OK
        JSR     GETNUM                            ;GET NUMBER
GETRN6
        LDA     ,U                                ;GET CHAR
        BMI     GETRN9                            ;EOF, EXIT
        LEAU    1,U                               ;ADVANCE
        CMPA    #NL                               ;NEWLINE
        BNE     GETRN6                            ;NOT IT
        LEAX    -1,X                              ;REDUCE COUNT
        BNE     GETRN6                            ;KEEP TRYING
        BRA     GETRN9                            ;CONTINUE
;* TEST FOR SUBTRACT FROM RANGE
GETRN7
        CMPA    #'-'                              ;SUBTRACTION?
        BNE     GETRN10                           ;NO, ITS OK
        JSR     GETNUM                            ;GET NUMBER
        LEAX    1,X                               ;ADVANCE FOR LATER
GETRN8
        CMPU    #T_BUFF                           ;ARE WE UNDER?
        BLS     GETRN9                            ;YES, EXIT
        LDA     ,-U                               ;GET CHAR
        CMPA    #NL                               ;NEW LINE?
        BNE     GETRN8                            ;KEEP LOOKING
        LEAX    -1,X                              ;BACKUP COUNT
        BNE     GETRN8                            ;KEEP GOING
        LEAU    1,U                               ;BACKUP TO IT
GETRN9
        TFR     U,X                               ;SET NEW END OF RANGE
        DEC     TEMP+2                            ;INDICATE OPERAND RECEIVED
        LDA     ,Y+                               ;GET NEXT COMMAND
GETRN10
        LDB     START                             ;BEGINNING RANGE ALREADY GIVEN
        BNE     GETRN11                           ;DON'T SAVE
        STU     START                             ;SET STARTING RANGE
        TFR     X,U                               ;'U' = END ADDRESS
GETRN11
        STU     END                               ;SET ENDING RANGE
        CMPA    #','                              ;RANGE SEPERATOR?
        LBEQ    GETRNG                            ;NO, KEEP GOING
        LDU     START                             ;GET FIRST IN RANGE
        LDX     END                               ;GET LAST IN RANGE
        CMPU    END                               ;ARE WE OVER?
        BLS     GETRN12                           ;NO, ITS OK
        EXG     U,X                               ;SWAP
        STU     START                             ;RESAVE
GETRN12
        LDB     ,X                                ;GET CHAR
        BMI     GETRN13                           ;EOF, EXIT
        LEAX    1,X                               ;ADVANCE
        CMPB    #NL                               ;NEW LINE
        BNE     GETRN12                           ;KEP GOING
GETRN13
        STX     END                               ;AND PROCEED
;* WE HAVE COMMAND CHARACTER, PROCEED
DOCMD
        BSR     TOUPPER                           ;INSURE UPPERCASE
        TSTA                                      ;	NULL COMMAND
        BPL     DOCM1                             ;NO, TRY NEXT
        STU     NEWPOS                            ;REPOSITION
;* EXIT BACK TO CALLER
DOQUIT
        LDA     TEMP+3                            ;TAGGS USED?
        BEQ     DOQUI1                            ;NO, ITS OK
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     TAG                               ;ZERO TAG START
        STD     TAG1                              ;ZERO TAG END
        DEC     REFLAG                            ;INSURE REFRESH
DOQUI1
        RTS
;* CONVERT CHAR IN A TO UPPERCASE
TOUPPER
        CMPA    #'a'                              ;LOWER?
        BLO     DOQUI1                            ;NO, ITS OK
        CMPA    #'z'                              ;LOWER?
        BHI     DOQUI1                            ;NO, ITS OK
        ANDA    #$5F                              ;CONVERT
        RTS
;* 'Q' QUIT COMMAND
DOCM1
        CMPA    #'Q'                              ;IS IT QUIT?
        BNE     DOCM2                             ;NO, ITS NOT
        LDA     ,Y                                ;GET NEXT CHAR
        BSR     TOUPPER                           ;INSURE UPPERCASE
        CMPA    #'Q'                              ;FORCE QUIT?
        BEQ     DOCM1A                            ;IF SO, NO TEST
        LDA     FCHANGE                           ;HAS FILE CHANGED
        BEQ     DOCM1A                            ;NO PROBLEM
        LDD     #FCHMSG                           ;INDICATE FILE CHANGED
        STD     ERRMSG                            ;SAVE IT
        RTS
;* GET HERE FROM E'X'IT COMMAND, CLOSE FILE & TERMINATE
DOEXIT
        SWI
        FCB     57                                ;CLOSE FILE
        SWI
        FCB     86                                ;FLUSH DISK
;* PERFORM VIDEO CLEANUP AND EXIT
DOCM1A
        LDA     WINDOW                            ;WINDOW MODE
        BPL     DOCM1B                            ;NO, DON'T CLEAR
        JSR     WCL                               ;CLEAR SCREEN
DOCM1B
        CLRA                                      ;	ZERO RETURN CODE
        SWI
        FCB     0                                 ;GO HOME
;* '?' LOCATE COMMAND
DOCM2
        CMPA    #'?'                              ;FIND COMMAND?
        BNE     DOCM3                             ;NO, TRY NEXT
        TFR     Y,X                               ;'X' = PTR TO SEARCH STRING
        LDA     TEMP+2                            ;DEFAULT?
        BNE     DOCM2A                            ;NO, ITS OK
        JSR     FINDEOF                           ;LOCATE END OF FILE
        STU     END                               ;RESET END
        LDU     START                             ;GET START BACK
        LDB     CX                                ;GET 'X'
        INCB                                      ;	ADVANCE
        LEAU    D,U                               ;OFFSET TO IT
;* LOOK FOR THE DATA
DOCM2A
        CMPU    END                               ;ARE WE OVER?
        BHS     DOCM2E                            ;YES, ERROR
        BSR     PMATCH                            ;DO WE HAVE A PARTIAL MATCH
        BNE     DOCM2C                            ;DIDN'T FIND
        STU     NEWPOS                            ;MOVE TO IT
DOCM2B
        JMP     DOQUIT                            ;EXIT
DOCM2C
        LEAU    1,U                               ;SKIP TO NEXT
        BRA     DOCM2A                            ;ADVANCE
DOCM2D
        LDA     REFLAG                            ;DID WE FIND ANY?
        BNE     DOCM2B                            ;YES, A-OK
DOCM2E
        LDD     #NOTFND                           ;POINT TO ERROR
        STD     ERRMSG                            ;INDICTE NOT FOUND
        RTS
;* TEST FOR STRING(U) BEGINNING WITH STRING(X)
PMATCH
        PSHS    X,U                               ;SAVE REGS
PMAT1
        LDA     ,X+                               ;GET CHAR
        BMI     PMAT2                             ;WE FOUND
        CMPA    ,U+                               ;DO IT MATCH
        BEQ     PMAT1                             ;YES
        PULS    X,U,PC                            ;RESTORE & RETURN
PMAT2
        CLRA                                      ;	SET 'Z'
        PULS    X,U,PC                            ;RESTORE & RETURN
;* 'S'UBSTITUTE COMMAND
DOCM3
        CMPA    #'S'                              ;SUBSTITUTE?
        BNE     DOCM4                             ;NO, TRY NEXT
        LDA     ,Y+                               ;GET DELIMITER
        BMI     DOCM3I                            ;FORMAT ERROR
        STA     TEMP                              ;SAVE FOR LATER
;* PARSE OFF THE SEARCH STRING
        LDX     #E_BUFF                           ;USE EDIT BUFFER
        CLRB                                      ;	ZERO COUNT
DOCM3A
        LDA     ,Y+                               ;GET NEXT CHAR
        BMI     DOCM3I                            ;FORMAT ERROR
        CMPA    TEMP                              ;DO IT MATCH?
        BEQ     DOCM3B                            ;YES, IT DOES
        STA     ,X+                               ;WRITE IT OUT
        INCB                                      ;	ADVANCE
        BRA     DOCM3A                            ;CONTINUE
DOCM3B
        LDA     #-1                               ;EOF MARKER
        STA     ,X                                ;WRITE IT
        STB     TEMP                              ;SAVE LENGTH
        BEQ     DOCM3I                            ;FORMAT ERROR
;* LOCATE THE NEXT OCCURANCE OF THE TEXT
        LDX     #E_BUFF                           ;RESET TO BUFFER
DOCM3C
        CMPU    END                               ;ARE WE PAST END?
        BHS     DOCM2D                            ;YES, EXIT
        BSR     PMATCH                            ;DO IT MATCH?
        BNE     DOCM3J                            ;NO, ADVANCE
;* WE FOUND A STRING, SUBSTITUTE
        STU     NEWPOS                            ;NEW POSITION TO MOVE TO
        PSHS    A,X,Y,U                           ;SAVE REGS
        LDB     #-1                               ;START WITH -1
DOCM3D
        INCB                                      ;	ADVANCE COUNT
        LDA     ,Y+                               ;GET CHAR
        BPL     DOCM3D                            ;DO TILL END
DOCM3E
        STA     FCHANGE                           ;INDICATE FILE CHANGED
        STA     REFLAG                            ;INDICATE RFRESH R=IRED
        STB     ,S                                ;SAVE LENGTH ON STACK
        CLRA                                      ;	ZERO HIGH
        TFR     D,Y                               ;'Y' = LENGTH OF SUB STRING
        LDX     3,S                               ;GET PTR BACK
        SUBB    TEMP                              ;B = SUB - SEARCH
        BEQ     DOCM3G                            ;SAME LENGTH
        BLO     DOCM3F                            ;WE HAVE TO DELETE
;* SUBSTITUTE TEXT IS LONGER, INSERT INTO FILE
        JSR     INSERT                            ;DO INSERT
        ADDD    END                               ;ADVANCE END BY # INSERTED
        STD     END                               ;AND RESAVE
        BRA     DOCM3H                            ;AND CONTINUE
;* SUBSTITUTE TEXT IS SHORTER, DELETE FROM FILE
DOCM3F
        NEGB                                      ;	CALCULATE DIFFERENCE
        JSR     DELETE                            ;DELETE THE DATA
        PSHS    A,B                               ;SAVE
        LDD     END                               ;GET END
        SUBD    ,S++                              ;DO SUBTRACT
        STD     END                               ;RESAVE
DOCM3G
        JSR     COPY                              ;PERFORM COPY
DOCM3H
        PULS    A,X,Y,U                           ;RESTORE REG'S
        LEAU    A,U                               ;SKIP NEW TEXT
        BRA     DOCM3C                            ;PROCEED
;* INVALID SERARCH STRING
DOCM3I
        LDD     #INVSER                           ;GET MESSAGE
        STD     ERRMSG                            ;SET MESSAGE
        RTS
;* NO MATCH, ADVANCE TO NEXT
DOCM3J
        LEAU    1,U                               ;ADVANCE
        BRA     DOCM3C                            ;AND CONTINUE
;* 'T'AG LINES
DOCM4
        CMPA    #'T'                              ;DO WE TAG?
        BNE     DOCM5                             ;NO, TRY NEXT
        STU     TAG                               ;SET TAG
        LEAX    -1,X                              ;BACKUP
        STX     TAG1                              ;SET IT
        DEC     REFLAG                            ;CAUSE REFRESH
        RTS
;* 'C' COPY LINES
DOCM5
        CMPA    #'C'                              ;COPY COMMAND?
        BNE     DOCM6                             ;NO, TRY NEXT
        BSR     DOCM5A                            ;EXEC
        JMP     DOQUIT                            ;AND PROCEED
;* PERFORM COPY OF INDICATED LINES
DOCM5A
        LDU     TXTPOS                            ;GET POSITION
        CMPU    START                             ;ARE WE IN TEXT
        BLS     DOCM5B                            ;ITS OK
        CMPA    END                               ;ARE WE IN TEXT?
        BHS     DOCM5B                            ;NO, ITS OK
        LDD     #INVDEST	POINT TO MESSAGE
        STD     ERRMSG                            ;SAVE IT
        LEAS    2,S                               ;SKIP SAVED PC
        RTS
;* RANGE IS OK, COPY LINES
DOCM5B
        LDD     END                               ;GET END
        SUBD    START                             ;GET SIZE
        TFR     D,Y                               ;'Y' = LENGTH
        LDX     START                             ;POINT TO TEXT
        JSR     INSERT                            ;DO INERT
        DEC     REFLAG                            ;REFRESH
        RTS
;* 'M'OVE LINES
DOCM6
        CMPA    #'M'                              ;MOVE LINES?
        BNE     DOCM7                             ;NO, TRY NEXT
        BSR     DOCM5A                            ;INSERT THE TEXT
        LDU     START                             ;GET STARTING ADDRESS
        CMPU    TXTPOS                            ;ARE WE IN RANGE
        BLO     DOCM7A                            ;ITS OK
        LEAU    D,U                               ;OFFSET TO IT
        BRA     DOCM7A                            ;AND PROCEED
;* 'D'ELETE LINES
DOCM7
        CMPA    #'D'                              ;DELETE?
        BNE     DOCM8                             ;NO, PROCEED
        LDD     END                               ;GET END
        SUBD    START                             ;CALCULATE LENGTH
DOCM7A
        JSR     DELETE                            ;PERFORM DELETE
        DEC     REFLAG                            ;DO REFRESH
        JMP     DOQUIT                            ;CLEAN UP AND EXIT
;* 'L'IST FILE LINES
DOCM8
        CMPA    #'L'                              ;LIST?
        BNE     DOCM9                             ;NO, TRY NEXT
        BSR     OSTART                            ;BEGIN LARGE OUTPUT
DOCM8A
        CMPU    END                               ;ARE WE OVER?
        BHS     OSTOP                             ;YES, EXIT
        LDA     ,U+                               ;GET CHAR
        CMPA    #NL                               ;NEW LINE?
        BEQ     DOCM8B                            ;SPECIAL CASE
        SWI
        FCB     33                                ;DISPLAY IT
        BRA     DOCM8A                            ;AND PROCEED
DOCM8B
        SWI
        FCB     22                                ;NEW LINE
        BRA     DOCM8A
;* TERMINATE LARGE OUTPUT
OSTOP
        LDA     WINDOW                            ;WINDOW MODE?
        BPL     OSTOPX                            ;NO, NOTHING SPECIAL
        SWI
        FCB     24                                ;OUTPUT MESSAGE
        FCB     $0A,$0D                           ;NEW LINE
        FCN     'Press any key to continue...'
        JSR     GETKEY                            ;GET INPUT KEY
        DEC     REFLAG                            ;FORCE REFRESH
OSTOPX
        JMP     DOQUIT                            ;EXIT
;* BEGIN LARGE OUTPUT
OSTART
        LDA     WINDOW                            ;WINDOW MODE?
        LBMI    WCL                               ;YES, CLEAR DISPLAY
        RTS
;* 'P'RINT LINES IN FORMATTED FASHON
DOCM9
        CMPA    #'P'                              ;PRINT?
        BNE     DOCM10                            ;NO, TRY NEXT
        BSR     OSTART                            ;BEGIN LARGE OUTPUT
        LDX     #1                                ;ZERO LINE COUNT
        LDU     #T_BUFF                           ;POINT TO TEXT BUFFER
DOCM9A
        CMPU    START                             ;AT BEGINNING?
        BHS     DOCM9B                            ;YES, WE ARE THERE
        LDA     ,U+                               ;GET CHAR
        CMPA    #NL                               ;NEW LINE
        BNE     DOCM9A                            ;KEEP LOOKING
        LEAX    1,X                               ;ADVANCE # LINES
        BRA     DOCM9A                            ;AND PROCEED
DOCM9B
        LDA     #' '                              ;ASSUME NOT CURRENT
        CMPU    TXTPOS                            ;CURRENT LINE?
        BNE     DOCM9C                            ;YES, ASSUMTION CORRECT
        LDA     #'*'                              ;WE ARE ON TAGGED LINE
DOCM9C
        SWI
        FCB     33                                ;DISPLAY CHAR
        CMPX    #9999                             ;OVER 4 DIGITS?
        BHI     DOCM9D                            ;YES
        SWI
        FCB     21                                ;DISPLAY SPACE
        CMPX    #999                              ;OVER 3 DIGITS
        BHI     DOCM9D                            ;YES
        SWI
        FCB     21                                ;DISPLAY SPACE
        CMPX    #99                               ;OVER 2 DIGITS
        BHI     DOCM9D                            ;YES
        SWI
        FCB     21                                ;DISPLAY SPACE
        CMPX    #9                                ;OVER 1 DIGIT
        BHI     DOCM9D                            ;YES
        SWI
        FCB     21                                ;DISPLAY SPACE
DOCM9D
        TFR     X,D                               ;GET VALUE
        SWI
        FCB     26                                ;DISPLAY LINE NUMBER
        LDA     #' '                              ;ASSUME NOT TAGGED
        CMPU    TAG                               ;ARE WE TAGGED
        BLO     DOCM9E                            ;NO
        CMPU    TAG1                              ;SECOND TEST
        BHI     DOCM9E                            ;NO
        LDA     #'='                              ;INDICATE TAGGED
DOCM9E
        SWI
        FCB     33                                ;DISPLAY
        SWI
        FCB     21                                ;ANOTHER SPACE
DOCM9F
        LDA     ,U+                               ;GET CHAR
        BMI     OSTOP1                            ;END OF FILE
        CMPA    #NL                               ;NEW LINE
        BEQ     DOCM9G                            ;SPECIAL CASE
        SWI
        FCB     33                                ;DISPLAY
        BRA     DOCM9F                            ;PROCEED
DOCM9G
        SWI
        FCB     22                                ;NEW LINE
        LEAX    1,X                               ;ADVANCE LINE NUMBER
        CMPU    END                               ;END OF TEXT
        BLO     DOCM9B                            ;NO, TRY AGAIN
OSTOP1
        JMP     OSTOP                             ;EXIT
;* 'F'ILE INFORMATION
DOCM10
        CMPA    #'F'                              ;FILE INFO?
        LBNE    DOCM11                            ;NO, TRY NEXT
        JSR     OSTART                            ;BEGIN LARGE OUTPUT
        LDU     #T_BUFF                           ;POINT TO START OF BUFFER
        LDX     #0                                ;LINE COUNT
DOCM10A
        CMPU    START                             ;ARE WE THERE?
        BNE     DOCM10B                           ;NO, WE ARE NOT
        STX     TEMP                              ;SAVE FOR LATER
DOCM10B
        LDA     ,U+                               ;GET CHAR
        BMI     DOCM10C                           ;END OF LINE
        CMPA    #NL                               ;NEW LINE
        BNE     DOCM10B                           ;KEEP LOOKING
        LEAX    1,X                               ;ADVANCE
        BRA     DOCM10A                           ;AND KEEP LOOKING
DOCM10C
        TFR     U,D                               ;GET EOF POSITION
        SUBD    #T_BUFF+1	CONVERT
        TFR     D,U                               ;'U' = # CHARACTERS
        TFR     X,D                               ;'D' = # LINES
        SWI
        FCB     24                                ;OUTPUT STRING
        FCN     'Filename: '
        LDX     #NAMBUF                           ;POINT TO NAME BUFFER
        SWI
        FCB     23                                ;DISPLAY NAME
        BSR     DLINCHR                           ;DISPLAY # LINES & CHARS
        LDU     START                             ;GET STARTING POSITION
        LDX     #0                                ;RESET # LINES
DOCM10D
        CMPU    END                               ;ARE WE OVER?
        BHS     DOCM10E                           ;NO, WE ARE NOT
        LDA     ,U+                               ;GET CHAR
        CMPA    #NL                               ;NEW LINE?
        BNE     DOCM10D                           ;NO, KEEP LOOKING
        LEAX    1,X                               ;ADVANCE COUNT
        BRA     DOCM10D                           ;AND KEEP GOING
DOCM10E
        SWI
        FCB     24                                ;DISPLAY TEXT
        FCN     'Position: '
        LDD     TEMP                              ;GET ID
        ADDD    #1                                ;ADVANCE
        SWI
        FCB     26                                ;DISPLAY
        LDD     END                               ;GET END
        SUBD    START                             ;CALCULATE SIZE
        TFR     D,U                               ;'U' = # CHARS
        TFR     X,D                               ;'D' = # LINES
        BSR     DLINCHR                           ;DISPLAY # LINES & CHARS
        SWI
        FCB     24                                ;DISPLAY TEXT
        FCN     'There are '
        LDA     FCHANGE                           ;IS FILE CHANGED?
        BNE     DOCM10F                           ;YES, RECORD IT
        SWI
        FCB     24                                ;DISPLAY TEXT
        FCN     'no '                             ;INDICTE NEGATIVE
DOCM10F
        SWI
        FCB     25                                ;MORE TEXT
        FCN     'unsaved changes.'
DOCM10G
        JMP     OSTOP                             ;TERMINATE OUTPUT
;* DISPLAY # LINES(D) & CHARACTERS(U)
DLINCHR
        SWI
        FCB     24                                ;MORE TEXT
        FCN     ', '
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     24                                ;MORE TEXT
        FCN     ' Lines, '
        TFR     U,D                               ;GET EOF
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     25                                ;REST OF LINE
        FCN     ' Characters'
        RTS
;* 'I'NPUT NEW TEXT
DOCM11
        CMPA    #'I'                              ;INPUT?
        BNE     DOCM12                            ;NO, TRY NEXT
        JSR     OSTART                            ;BEGIN LARGE OUTPUT
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'Input:'
DOCM11A
        LDX     #E_BUFF                           ;POINT TO EDIT BUFFER
        JSR     GETLIN                            ;GET INPUT LINE
        LDA     WINDOW                            ;GET WINDOW STAT
        BPL     DOCM11B                           ;NO SPECIAL
        SWI
        FCB     22                                ;NEW LINE
DOCM11B
        TSTB                                      ;	ZERO LENGTH?
        BEQ     DOCM10G                           ;YES, EXIT
        LDA     #NL                               ;INCLUDE NEW LINE
        STA     B,X                               ;WRITE IT
        INCB                                      ;	ADVANCE
        CLRA                                      ;	ZERO HIGH
        TFR     D,Y                               ;'Y' = INPUT LENGTH
        JSR     INSERT                            ;INSERT INTO TEXT
        LEAU    D,U                               ;ADVANCE TO NEXT LINE
        BRA     DOCM11A                           ;KEEP GOING
;* 'V'ISUAL MODE SWITCH
DOCM12
        CMPA    #'V'                              ;SWAP MODES
        BNE     DOCM13                            ;NO, TRY NEXT
        STU     NEWPOS                            ;SET NEW POSITION
        CLRA                                      ;	ZERO HIGH
        CLRB                                      ;	ZERO LOW
        STD     CX                                ;ZERO CURSORS
        LDA     [GXYPTR]	GOTOXY DEFINED?
        BEQ     DOCM12A                           ;NO, SKIP IT
        DEC     REFLAG                            ;SWAP IT
        COM     WINDOW                            ;TOGGLE FLAG
DOCM12A
        JMP     DOQUIT                            ;EXIT
;* EXECUTE DOS COMMAND
DOCM13
        CMPA    #'$'                              ;DOS COMMAND
        BNE     DOCM14                            ;ERROR
        JSR     OSTART                            ;BEGIN OUTPUT
        BSR     CONVERT                           ;CONVERT INPUT
        PSHS    DP,U                              ;SAVE FOR LATER
        SWI
        FCB     100                               ;EXECUTE COMMAND
        PULS    DP,U                              ;RESTORE PTR
        DEC     ,U                                ;SET EOL
        JMP     OSTOP                             ;END EXIT
;* CONVERT COMMAND LINE TO UPPERCASE, ZERO TERMINATED
CONVERT
        PSHS    Y                                 ;SAVE 'Y'
CONV1
        LDA     ,Y                                ;GET CHAR
        BMI     CONV2                             ;END OF LINE, ZERO TERMINATE
        JSR     TOUPPER                           ;CONVERT TO UPPER
        STA     ,Y+                               ;WRITE IT OUT
        BRA     CONV1                             ;AND PROCEED
CONV2
        CLR     ,Y                                ;ZERO END
        TFR     Y,U                               ;SAVE EOL INDICATOR
        PULS    Y                                 ;RESTORE 'Y'
        SWI
        FCB     4                                 ;TEST FOR OPERANDS
        RTS
;* 'R'EAD FILE AT POSITION
DOCM14
        CMPA    #'R'                              ;READ COMMAND
        BNE     DOCM15                            ;NO, TRY NEXT
        BSR     GETFN                             ;GET FILENAME
        SWI
        FCB     55                                ;OPEN FILE FOR READ
        BNE     GETFN2                            ;ERROR, EXIT
        DEC     REFLAG                            ;INDICATE REFRESH R=IRED
;* READ IN EACH BLOCK & INSERT INTO TEXT
DOCM14A
        LDU     #COMMAND	POINT TO BUFFER
        LDX     #E_BUFF                           ;POINT TO BUFFER
        SWI
        FCB     58                                ;READ INTO BUFFER
        BNE     DOCM15D                           ;END, EXIT
;* SCAN BLOCK LOOKING FOR EOF
DOCM14B
        LDA     ,X                                ;GET CHAR
        BMI     DOCM14C                           ;END, EXIT
        LEAX    1,X                               ;ADVANCE
        CMPX    #E_BUFF+512	ARE WE OVER?
        BLO     DOCM14B                           ;NO, KEEP LOOKING
DOCM14C
        TFR     X,D                               ;GET VALUE
        SUBD    #E_BUFF                           ;GET # CHARACTERS
        TFR     D,Y                               ;'Y' = # CHARS
        LDU     START                             ;GET POSITION
        LDX     #E_BUFF                           ;POINT TO BUFFER
        JSR     INSERT                            ;PERFORM INSERT
        LEAU    D,U                               ;ADVANCE TO NEXT
        STU     START                             ;RESAVE
        BRA     DOCM14A                           ;AND PROCEED
;* GET FILENAME FOR DOS
GETFN
        BSR     CONVERT                           ;CONVERT FILENAME
        BNE     GETFN1                            ;ITS OK
        LDY     #NAMBUF                           ;POINT TO NAME BUFFER
GETFN1
        SWI
        FCB     10                                ;GET FILENAME
        BEQ     GETFN3                            ;A-OK, EXIT
        DEC     ,U                                ;SET EOL INDICATOR
        LEAS    2,S                               ;SKIP SAVED SP
GETFN2
        JMP     OSTOP                             ;EXIT WITH PROMPT
GETFN3
        DEC     ,U                                ;SET EOL INDICATOR
        LDU     #COMMAND	SET UP PTR TO BUFFER
        RTS
;* 'W'RITE CONTENTS OF RANGE
DOCM15
        CMPA    #'W'                              ;WRITE COMMAND?
        BEQ     DOCM15A                           ;YES, PROCESS
;* E'X'IT AND SAVE FILE
        SUBA    #'X'                              ;EXIT AND SAVE?
        BNE     BADCMD                            ;NO, TRY NEXT
DOCM15A
        STA     TEMP+1                            ;SAVE COMMAND
        LDA     TEMP+2                            ;DEFAULT?
        BNE     DOCM15B                           ;NO, ITS OK
        JSR     FINDEOF                           ;LOCATE END OF FILE
        STU     END                               ;POINT TO END
        LDU     #T_BUFF                           ;POINT TO START OF FILE
        STU     START                             ;POINT TO START OF RANGE
DOCM15B
        BSR     GETFN                             ;GET FILENAME
        SWI
        FCB     56                                ;OPEN THE FILE FOR WRITE
        BNE     GETFN2                            ;REPORT ERROR
        LDX     START                             ;POINT TO START OF RANGE
DOCM15C
        LDA     ,X+                               ;GET CHAR
        SWI
        FCB     61                                ;WRITE FILE
        BNE     DOCM15D                           ;ERROR, EXIT
        CMPX    END                               ;OVER END?
        BLO     DOCM15C                           ;NO, KEEP GOING
        CLR     FCHANGE                           ;INDICATE NOT CHANGED
        LDA     TEMP+1                            ;GET COMMAND
        LBEQ    DOEXIT                            ;IT SO, TERMINATE
;* CLOSE FILE & TERMINATE COMMAND
DOCM15D
        SWI
        FCB     57                                ;CLOSE FILE
        SWI
        FCB     86                                ;FLUSH DISK (INCASE CRASH)
        CLR     COMMAND                           ;INSURE NO COMMAND
        CLR     DELLEN                            ;INSURE NO DELETE BUFFER
        JMP     DOQUIT                            ;AND EXIT
;* COMMAND IN NOT RECOGNIZED
BADCMD
        LDD     #UNCMSG                           ;POINT TO MESSAGE
        STD     ERRMSG                            ;SET ERROT MESSAGE
        RTS
;*
;* UNKNOWN KEY ENTERED
;*
UNKEY
        LDD     #UNKMSG                           ;POINT TO MESSAGE
        STD     ERRMSG                            ;SET ERROR MESSAGE
        RTS
;*
;* TOGGLE EOL DISPLAY
;*
TOGEOL
        COM     EOLFLAG                           ;SWAP FLAG STATE
;* COMMAND TO FORCE RE-REFRESH
REDRAW
        DEC     REFLAG                            ;INDICTE REFRESH R=IRED
        JMP     UPDATE                            ;AND UPDATE ANY CHANGES
;*
;* TOGGLE INSERT MODE
;*
TOGINS
        LDD     #INSMSG                           ;POINT TO ON MESSAGE
        COM     INSFLAG                           ;SWAP FLAG STATE
        BMI     TOGIN1                            ;CORRECT
        LDD     #OVWMSG                           ;POINT TO OFF MESSAGE
TOGIN1
        STD     ERRMSG                            ;SAVE MESSAGE
        RTS
;*
;* DISPLAY CURSOR POSITION
;*
DISCUR
        JSR     GOTOLST                           ;MOVE THERE
        JSR     WSO                               ;ENABLE SPECIAL EFFECTS
        SWI
        FCB     24                                ;OUTPUT STRING
        FCN     ' Cursor: '
        LDB     CY                                ;GET 'Y' POSITION
        BSR     WRDEC                             ;DISPLAY
        SWI
        FCB     24                                ;MORE TEXT
        FCN     ' down, '
        LDB     HORZ                              ;GET ACTUAL 'X' POSITION
        BSR     WRDEC                             ;DISPLAY
        SWI
        FCB     24                                ;MORE TEXT
        FCN     ' over, at character '
        LDB     CX                                ;GET CHAR 'X' POSITION
        BSR     WRDEC                             ;DISPLAY
        SWI
        FCB     24                                ;MORE TEXT
        FCN     ' in line '
        JMP     WSE                               ;DISABLE SPECIAL EFFECTS
WRDEC
        CLRA                                      ;	ZERO HIGH
        ADDD    #1                                ;ADVANCE IT
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        RTS
;*
;* DELETE PREVIOUS CHARACTER
;*
DELPRE
        JSR     BACKCHR                           ;BACKUP A CHARACTER
        JSR     POSITC                            ;REPOSITION CURSOR
        STB     CX                                ;RESET 'C' POSITION
        JSR     GOTOXX                            ;MOVE TO POSITION
;*
;* DELETE CHARACTER
;*
DELCHR
        JSR     EDIT                              ;BEGIN EDITING LINE
        TFR     Y,U                               ;SAVE FOR LATER
        LDA     ,U                                ;GET CHAR
        BMI     DELC3                             ;EOF, DO NOT DELETE
DELC1
        LDB     1,Y                               ;GET NEXT CHAR
        STB     ,Y+                               ;WRITE TO TEXT
        BPL     DELC1                             ;DO THEM ALL
        DEC     EDTLEN                            ;REDUCE LENGTH
DELC2
        CMPA    #NL                               ;DELETED NEWLINE?
        LBNE    REFLIN                            ;NO, JUST UPDATE ONE LINE
        JSR     UPDATE                            ;UPDATE IT
        LDA     REFLAG                            ;ARE WE REFRESHING?
        BEQ     REFBOT                            ;NO, DO EXPLICITILY
DELC3
        RTS
;*
;* DELETE LIPUT LINE
;*
DELLIN
        BSR     DELPREP                           ;PREPERATION
DELL1
        LDA     ,Y+                               ;GET CHAR FROM BUFFER
        STA     ,X+                               ;WRITE IN BUFFER
        BMI     DELL2                             ;END OF FILE
        INCB                                      ;	ADVANCE
        CMPA    #NL                               ;NEWLINE?
        BNE     DELL1                             ;NO, ERROR
DELL2
        CLRA                                      ;	ZERO HIGH
        STB     DELLEN                            ;SET LENGTH
        JSR     DELETE                            ;PERFORM DELETE
;* REFRESH FROM CURRENT POSITION TO BOTTOM OF SCREEN
REFBOT
        LDB     CY                                ;GET 'Y' POSITION
        LDU     TXTPOS                            ;GET START OF LINE
        JMP     REFSCR                            ;CONTINUE
;*
;* DELETE TO END OF LINE (EXCLUSIVE)
;*
DELEOL
        BSR     DELPREP                           ;PEROFRM PREPERATION
DELEO1
        LDA     ,Y+                               ;GET CHAR FROM BUFFER
        STA     ,X+                               ;WRITE IN DELETE BUFFER
        BMI     DELEO2                            ;EOF, EXIT
        CMPA    #NL                               ;END OF LINE?
        BEQ     DELEO2                            ;EOF, EXIT
        INCB                                      ;	ADVANCE COUNT
        BRA     DELEO1                            ;CONTINUE
DELEO2
        CLRA                                      ;	ZERO HIGH
        STB     DELLEN                            ;SET LENGTH
        JSR     DELETE                            ;PERORM DELETE
        JMP     WCE                               ;CLEAR END OF LINE
;* PREPREATION FOR DELETE OPERATION
DELPREP
        JSR     UPDATE                            ;UPDATE CHANGES
        LDB     CX                                ;GET 'X' POSITION
        CLRA                                      ;	ZERO HIGH
        ADDD    TXTPOS                            ;'D' = POSITION
        TFR     D,U                               ;'U' = INPUT PTR
        TFR     D,Y                               ;'Y' = INPUT PTR
        LDX     #D_BUFF                           ;POINT TO DELETE BUFFER
        CLRB                                      ;	ZERO COUNT
        RTS
;*
;* INSERT DELETED TEXT
;*
INSDEL
        BSR     DELPREP                           ;PREPERATION
        LDB     DELLEN                            ;GET LENGTH OF DELETE BUFFER
        CLRA                                      ;	ZERO HIGH
        TFR     D,Y                               ;'Y' = LENGTH OF DATA
        JSR     INSERT                            ;PERFORM INSERT
        BRA     REFBOT                            ;AND PROCEED
;*
;* GOTO START OF FILE
;*
HOME
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        JMP     EDT4                              ;AND GOTO HOME
;*
;* MOVE CURRENT LINE TO TOP OF SCREEN
;*
CURTOP
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        LDD     TXTPOS                            ;GET LINE POSITION
        STD     SCRTOP                            ;SET SCREEN TOP
        CLR     CY                                ;RESET TO TOP
        DEC     REFLAG                            ;INDICATE REFRESH R=IRED
        RTS
;*
;* TAG LINES
;*
TAGLIN
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        LDU     TXTPOS                            ;GET CURRENT POSITION
        LDX     TAG                               ;AND FIRST TAG
        BNE     TAGL1                             ;ALREADY TAGGED
        STU     TAG                               ;SET BEGINNING TAG
        STU     TAG1                              ;SET ENDING TAG
        CLRA                                      ;	ZERO 'X'
        STA     HORZ                              ;RESET COUNTER
        LDB     CY                                ;GET 'Y'
        JSR     GOTOXY                            ;RESET CURSOR
        JMP     REFLIN                            ;REFRESH THE LINE
TAGL1
        CMPU    TAG                               ;DOES IT MATCH
        BEQ     TAGL3                             ;DELETE THE TAGS
        BHI     TAGL2                             ;IN PROPER ORDER
        EXG     X,U                               ;SWAP VALUES
TAGL2
        STX     TAG                               ;SET BEGINNING TAG
        STU     TAG1                              ;SET ENDING TAG
        JMP     REFALL                            ;REFRESH SCREEN
TAGL3
        LDX     #0                                ;ZERO STARTNG TAG
        TFR     X,U                               ;ZERO ENDING TAG
        BRA     TAGL2                             ;AND SET IT
;*
;* MOVE WORD RIGHT
;*
WRDRT
        LDA     ,Y                                ;GET CHAR
        CMPA    #NL                               ;AT END OF LINE?
        BEQ     FWDCHR                            ;IF SO, ADVANCE
WRDRT1
        LDA     ,Y                                ;GET CHAR
        BMI     WRDRT2                            ;EOF, EXIT
        CMPA    #' '                              ;CONTROL CODE
        BLS     WRDRT2                            ;YES, EXIT
        LEAY    1,Y                               ;ADVANCE
        INC     CX                                ;ADVANCE 'X' POSITION
        BRA     WRDRT1                            ;ADN PROCEED
WRDRT2
        LDA     ,Y+                               ;GET NEXT CHAR
        BMI     WRDRT4                            ;EOF, EXIT
        CMPA    #NL                               ;NEW LINE
        BEQ     WRDRT4                            ;EOL, EXIT
        CMPA    #' '                              ;CONTROL CODE?
        BHI     WRDRT4                            ;NEW WORD, EXIT
        INC     CX                                ;ADVANCE 'X' POSITION
        BRA     WRDRT2                            ;AND PROCEED
;*
;* MOVE CURSOR TO END OF LINE
;*
CUREOL
        LDA     #$FF                              ;HIGH NUMBER
        STA     CX                                ;SET POSITION
        LDA     ,Y                                ;GET CHAR
        CMPA    #NL                               ;AT END ALREADY?
        BEQ     FWDLIN                            ;YES, GOTO NEXT
WRDRT4
        RTS
;*
;* MOVE FORWARD A CHARACTER
;*
FWDCHR
        LDA     ,Y                                ;GET DATA
        CMPA    #NL                               ;NEW LINE?
        BEQ     FWDC1                             ;YES, SPECIAL CASE
        INC     CX                                ;ADVANCE
        RTS
FWDC1
        CLR     CX                                ;ZERO POSITION
;*
;* MOVE FORWARD A LINE
;*
FWDLIN
        PSHS    A,B,X                             ;SAVE REGISTERS
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        LDU     TXTPOS                            ;GET TEXT POSITION
FWDL1
        LDA     ,U                                ;GET CHAR
        BMI     FWDL2                             ;END OF FILE
        LEAU    1,U                               ;ADVANCE
        CMPA    #NL                               ;NEW LINE?
        BNE     FWDL1                             ;NO, KEEP LOOKING
        STU     TXTPOS                            ;NEW POSITION
        LDB     CY                                ;GET POSITION
        CMPB    #LINES-2	PAST END OF SCREEN?
        BHS     FWDL3                             ;YES, SPECIAL CASE
        INC     CY                                ;ADVANCE CY
FWDL2
        PULS    A,B,X,PC	RESTORE & RETURN
FWDL3
        LDX     SCRTOP                            ;GET TOP OF SCREEN
FWDL4
        LDA     ,X+                               ;GET CHAR
        CMPA    #NL                               ;NEW LINE
        BNE     FWDL4                             ;NO, KEEP GOING
        STX     SCRTOP                            ;RESAVE SCREEN TOP
;* SOME TERMINALS MAY NOT PERFORM FOREWARD SCROLLING WHEN "SF" IS
;* PRINTED ON THE BOTTOM LINE... IF SO, REPLACE NEXT SECTION WITH
;* CODE SIMILAR TO THAT FOUND IN "BACKLIN".
        LDA     #SF                               ;SCROLL FORWARD COMMAND
        JSR     PUTCHR                            ;OUTPUT IT
        JSR     REFSCR                            ;REFRESH SCREEN (DRAW NEXT LINE)
        PULS    A,B,X,PC	RESTORE & RETURN
;*
;* MOVE FORWARD A PAGE
;*
FWDPAG
        PSHS    A,B                               ;SAVE REGISTERS
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        LDB     #LINES-2	GET # LINES
        LDU     SCRTOP                            ;GET TOP OF SCREEN
FWDP1
        LDA     ,U                                ;GET CHAR
        BMI     FWDP2                             ;END OF FILE
        LEAU    1,U                               ;ADVANCE
        CMPA    #NL                               ;NEWLINE?
        BNE     FWDP1                             ;NO, TRY NEXT
        DECB                                      ;	REDUCE COUNT
        BNE     FWDP1                             ;KEEP GOING
;* RESET POSITIONS & EXIT
FWDP2
        STU     SCRTOP                            ;SET SCREEN TOP
        STU     TXTPOS                            ;SET TEXT POSITION
        CLR     CY                                ;ZERO 'Y' POSITION
        DEC     REFLAG                            ;INDICATE REFRESH R=IRED
        PULS    A,B,PC                            ;RESTORE & RETURN
;*
;* MOVE WORD LEFT
;*
WRDLT
        LDB     CX                                ;GET 'X' POSITION
        BEQ     BACKCHR                           ;END OF ROPE, BACKUP
WRDLT1
        LDA     ,-Y                               ;GET CHAR
        CMPA    #' '                              ;IN SPACE?
        BHI     WRDLT2                            ;YES, QUIT
        DECB                                      ;	REDUCE COUNT
        BNE     WRDLT1                            ;AND CONTINUE
        BRA     WRDLT4                            ;SOL, EXIT
WRDLT2
        LEAY    1,Y                               ;ADVANCE
WRDLT3
        LDA     ,-Y                               ;GET CHAR
        CMPA    #' '                              ;IN WORD?
        BLS     WRDLT4                            ;NO, EXIT
        DECB                                      ;	REDUCE COUNT
        BNE     WRDLT3                            ;AND PROCEED
WRDLT4
        STB     CX                                ;RESAVE 'X' POSITION
        RTS
;*
;* MOVE CURSOR TO START OF LINE
;*
CURSOL
        LDA     CX                                ;GET 'X' POSITION
        BEQ     BACKLIN                           ;BACKUP A LINE
        CLR     CX                                ;RESET TO ZERO
        RTS
;*
;* BACKUP A CHARACTER
;*
BACKCHR
        DEC     CX                                ;REDUCE COUNT
        LDA     CX                                ;GET VALUE
        INCA                                      ;	WAS IT ZERO
        BEQ     BACKLIN                           ;OVERFLOW, BACKUP LINE
        RTS
;*
;* BACKUP A LINE
;*
BACKLIN
        PSHS    A,B,X                             ;SAVE REGISTERS
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        LDU     TXTPOS                            ;GET CURRENT TEXT POSITION
        LEAU    -1,U                              ;BACKUP INCASE AT START OF LINE
BACKL1
        CMPU    #T_BUFF                           ;AT START OF BUFFER?
        BLO     BACKL2                            ;YES, EXIT
        LDA     ,-U                               ;GET PRECEEDING CHAR
        CMPA    #NL                               ;NEWLINE?
        BNE     BACKL1                            ;NO, KEEP LOOKING
BACKL2
        LEAU    1,U                               ;ADVANCE TO LINE
        STU     TXTPOS                            ;SAVE LINE POSITION
        DEC     CY                                ;REDUCE COUNT
        BPL     BACKL7                            ;NO OVERFLOW
;* BACKUP PAST TOP OF SCREEN
        LDX     SCRTOP                            ;GET TOP OF SCREEN
        LDB     #LINES/2	GET HALF SCREEN
BACKL3
        CMPX    #T_BUFF                           ;ARE WE AT START?
        BLS     BACKL4                            ;YES, EXIT
        LDA     ,-X                               ;GET PREVIOUS CHAR
        CMPA    #NL                               ;NEW LINE?
        BNE     BACKL3                            ;PROCEED
        DECB                                      ;	REDUCE COUNT
        BNE     BACKL3                            ;AND PROCEED
        LEAX    1,X                               ;ADVANCE TO LINE
BACKL4
        STX     SCRTOP                            ;RESET TOP OF SCREEN
        CLRB                                      ;	ZERO 'B'
BACKL5
        CMPB    CX                                ;ARE WE OVER?
        BHS     BACKL6                            ;YES, WE ARE THERE
        INCB                                      ;	ADVANCE
        LDA     ,U+                               ;GET CHAR
        CMPA    #NL                               ;NEW LINE?
        BNE     BACKL5                            ;PROCEED
        LEAU    -1,U                              ;BACKUP
BACKL6
        STU     NEWPOS                            ;INDICATE MOVE TO
        DEC     REFLAG                            ;INSURE REFRESH
BACKL7
        PULS    A,B,X,PC	RESTORE                  ;* RETURN
;*
;* GOTO END OF FILE
;*
FEND
        JSR     UPDATE                            ;UPDATE CHANGES
        JSR     FINDEOF                           ;LOCATE END
        STU     NEWPOS                            ;REPOSITION
        STU     SCRTOP                            ;SET START OF SCREEN
        STU     TXTPOS                            ;SET START OF LINE
;*
;* BACKUP A PAGE
;*
BACKPAG
        PSHS    A,B                               ;SAVE REGS
        JSR     UPDATE                            ;UPDATE ANY CHANGES
        LDB     #LINES-1	ZERO COUNTER
        LDU     SCRTOP                            ;GET TOP OF SCREEN
BACKP1
        CMPU    #T_BUFF                           ;AT START OF BUFFER?
        BLS     BACKP2                            ;YES, EXIT
        LDA     ,-U                               ;GET NEXT CHAR
        CMPA    #NL                               ;NEWLINE?
        BNE     BACKP1                            ;NO, ITS NOT
        DECB                                      ;	REDUCE CONT
        BNE     BACKP1                            ;KEEP GOING
        LEAU    1,U                               ;ADVANCE
BACKP2
        JMP     FWDP2                             ;RESAVE REGISTERS
;*
;* LOCATE THE END OF FILE
;* EXIT:   ;U = PTR TO END OF FILE MARKER
;*
FINDEOF
        PSHS    A                                 ;SAVE 'A'
        LDU     SCRTOP                            ;BEGIN AT TOP OF SCREEN
FINDE1
        LDA     ,U+                               ;GET NEXT CHAR
        BPL     FINDE1                            ;KEEP LOOKING
        LEAU    -1,U                              ;BACKUP TO MARKER
        PULS    A,PC                              ;RETORE & RETURN
;*
;* INSERT A BLOCK OF DATA INTO THE FILE
;* ENTRY:    U = PTR TO INSERT AT
;*   ;D = # CHARACTERS TO INSERT
;*   ;X = PTR TO DATA TO OVERWRITE
;*   ;Y = # CHARACTERS TO OVERWRITE
;*
INSERT
        PSHS    A,B,X,Y,U	SAVE REGS
        BSR     FINDEOF                           ;LOCATE END OF FILE
        LEAU    1,U                               ;INCLUDE EOF
        LEAX    D,U                               ;POINTER TO NEW END
        CMPX    #OSEND                            ;ARE WE OVER?
        BHI     INSERR                            ;REPORT ERROR
;* ADJUST FILE TO PROVIDE SPACE
INSE0
        LDA     ,-U                               ;GET CHAR FROM FILE
        STA     ,-X                               ;WRITE TO NEW DATA
        CMPU    6,S                               ;ARE WE BACK TO PTR
        BHI     INSE0                             ;NO, KEEP GOING
;* ADJUST TOP OF SCREEN
        CMPU    SCRTOP                            ;PTR < SCRTOP?
        BHS     INSE1                             ;NO, ITS OK
        LDD     SCRTOP                            ;GET TOP OF SCREEN
        ADDD    ,S                                ;ADJUST
        STD     SCRTOP                            ;RESAVE
;* ADJUST TEXT POSITION
INSE1
        CMPU    TXTPOS                            ;PTR < TXTPOS?
        BHS     INSE2                             ;NO, ITS OK
        LDD     TXTPOS                            ;GET TOP OF SCREEN
        ADDD    ,S                                ;ADJUST
        STD     TXTPOS                            ;RESAVE
;* ADJUST TAG POSITIONS
INSE2
        CMPU    TAG                               ;PTR < TAG?
        BHS     INSE3                             ;NO, ITS OK
        LDD     TAG                               ;GET FIRST TAGE
        ADDD    ,S                                ;ADJUST
        STD     TAG                               ;RESAVE
INSE3
        CMPU    TAG1                              ;PTR < TAG1
        BHS     INSE4                             ;NO, ITS OK
        LDD     TAG1                              ;GET SECOND TAG
        ADDD    ,S                                ;ADJUST
        STD     TAG1                              ;RESAVE
;* ADJUST OVERWRITE POINTER
INSE4
        CMPU    2,S                               ;PTR < OVERWRITE
        BHS     INSE5                             ;NO, ITS OK
        LDD     2,S                               ;GET OVERWRITE POINTER
        ADDD    ,S                                ;ADJUST
        STD     2,S                               ;RESAVE
;* COPY IN THE NEW TEXT
INSE5
        LDX     2,S                               ;RESTORE SOURCE POINTER
        JSR     COPY                              ;PERFORM COPY
        PULS    A,B,X,Y,U,PC	RESTORE & RETURN
;* ERROR, CANNOT INSERT TEXT
INSERR
        LDD     #INEMSG                           ;POINT TO MESSAGE
        STD     ERRMSG                            ;SAVE IT
        PULS    A,B,X,Y,U,PC	RESTORE & RETURN
;*
;* COPY MEMORY SUBROUTINE
;* ENTRY:    X = SOURCE PTR
;*   ;U = DEST PTR
;*   ;Y = LENGTH
;*
COPY
        LEAY    1,Y                               ;ADVANCE FOR DEC
COPY1
        LEAY    -1,Y                              ;REDUCE COUNT
        BEQ     COPY2                             ;EXIT
        LDA     ,X+                               ;GET CHAR FROM SOURCE
        STA     ,U+                               ;WRITE INTO DEST
        BRA     COPY1                             ;AND PROCEED
COPY2
        LDA     #-1                               ;GET SET FLAG
        STA     FCHANGE                           ;INDICATE FILE CHANGED
        RTS
;*
;* DELETE DATA FROM FILE
;* ENTRY:    U = PTR TO LOCATION TO DELETE
;*   ;D = # CHARACTERS TO DELETE
DELETE
        PSHS    A,B,X,U                           ;SAVE DATA
        LEAX    D,U                               ;'X' = POS + LEN
;* ADJUST LINE POSITION IF WE DELETE
        CMPU    TXTPOS                            ;PTR < TEXTPOS?
        BHS     DELE2                             ;NO, ITS OK
        LDD     TXTPOS                            ;GET ADDRESS
        SUBD    ,S                                ;ADJUST
        CMPD    4,S                               ;NEW TXTPOS < PTR ?
        BHS     DELE1                             ;NO, ITS OK
        TFR     U,D                               ;TXTPOS = PTR
DELE1
        STD     TXTPOS                            ;SET POSITION
        STD     NEWPOS                            ;ADJUST POSITION
;* ADJUST SCREEN TOP IF WE DELETE
DELE2
        CMPU    SCRTOP                            ;PTR < SCRTOP?
        BHS     DELE4                             ;NO, ITS OK
        LDD     SCRTOP                            ;GET ADDRESS
        SUBD    ,S                                ;ADJUST
        CMPD    4,S                               ;NEW SCRTOP < PTR?
        BHS     DELE3                             ;NO, ITS OK
        TFR     U,D                               ;SCRTOP = PTR
DELE3
        STD     SCRTOP                            ;SET POSITION
        DEC     REFLAG                            ;INDICATE REFRESH R=IRED
;* ADJUST TAGGED LINE POSITIONS
DELE4
        CMPU    TAG                               ;PTR < TAG?
        BHS     DELE5                             ;NO, ITS OK
        LDD     TAG                               ;GET TAG
        SUBD    ,S                                ;ADJUST
        STD     TAG                               ;RESAVE
DELE5
        CMPU    TAG1                              ;PTR < TAG1
        BHS     DELE6                             ;NO, ITS OK
        LDD     TAG1                              ;GET TAG1
        SUBD    ,S                                ;ADJUST
        STD     TAG1                              ;RESAVE
;* PERFORM DELETE FROM TEXT
DELE6
        LDA     ,X+                               ;GET CHAR
        STA     ,U+                               ;WRITE IT
        BPL     DELE6                             ;DO ALL DATA
        LDA     #-1                               ;GET SET FLAG
        STA     FCHANGE                           ;INDICATE FILE CHANGED
        PULS    A,B,X,U,PC	RESTORE & RETURN
;*
;* BEGIN EDITING CURRENT LINE, IF NOT ALREADY IN EDIT
;* BUFFER, COPY IT THERE.
;* EXIT:   ;Y = PTR TO CURRENT CHAR IN EDIT BUFFER
;*
EDIT
        PSHS    A,B,X,U                           ;RESTORE & RETURN
        LDX     #E_BUFF                           ;POINT TO EDIT BUFFER
        LDB     CX                                ;GET 'X' POSITION
        CLRA                                      ;	ZERO HIGH
        LEAY    D,X                               ;OFFSET TO POSITION
        LDA     CHANGE                            ;LINE ALREADY IN BUFFER?
        BNE     EDIT4                             ;YES, ALL IS OK
;* COPY EDIT LINE OVER
        LDU     TXTPOS                            ;GET LINE POSITION
        CLR     EDTLEN                            ;ZERO COUNT
EDIT1
        INC     EDTLEN                            ;ADVANCE COUNT
        LDA     ,U                                ;GET CHAR
        BMI     EDIT2                             ;EOF, EXIT
        LEAU    1,U                               ;ADVANCE
        STA     ,X+                               ;WRITE IT OUT
        CMPA    #NL                               ;NEW LINE?
        BEQ     EDIT3                             ;EXIT
        BRA     EDIT1                             ;AND KEEP COPYING
;* END OF FILE ENCOUNTERED, INSERT CARRIAGE RETURN
EDIT2
        LDA     #NL                               ;GET A NEWLINE
        STA     ,X+                               ;WRITE IT OUT
        LDB     CY                                ;GET 'Y' POSITION
        INCB                                      ;	ADVANCE
        JSR     REFSCR                            ;DISPLAY "EOF" MARKER
        JSR     GOTOXX                            ;RESTORE CURSOR
;* WE HAVE EDIT LINE
EDIT3
        LDA     #-1                               ;GET SET FLAG
        STA     ,X                                ;WRITE END OF LINE
        STA     CHANGE                            ;INDICATE CHANGED
        STA     FCHANGE                           ;INDICATE FILE CHANGED
EDIT4
        PULS    A,B,X,U,PC	RESTORE & RETURN
;*
;* UPDATE ANY CHANEGS WHICH ARE PENDING
;*
UPDATE
        PSHS    A,B,X,Y,U	SAVE REGS
        LDA     CHANGE                            ;ANY CHANGES?
        BEQ     UPDAT6                            ;NO, ITS OK
        LDU     TXTPOS                            ;POINT TO CURRENT LINE
        TFR     U,X                               ;'X' = COPY
        CLRB                                      ;	ZERO COUNT
UPDAT1
        LDA     ,X                                ;GET CHAR
        BMI     UPDAT2                            ;END OF BUFFER
        INCB                                      ;	ADVANCE COUNTER
        LEAX    1,X                               ;ADVANCE PTR
        CMPA    #NL                               ;NEW LINE?
        BNE     UPDAT1                            ;KEEP GOING
UPDAT2
        CLRA                                      ;	ZERO HIGH
        PSHS    B                                 ;SAVE COUNT
        LDB     EDTLEN                            ;GET EDIT BUFFER LENGTH
        TFR     D,Y                               ;'Y' = EDIT LENGTH
        PULS    B                                 ;RESTORE IT
        LDX     #E_BUFF                           ;POINT TO EDIT BUFFER
        SUBB    EDTLEN                            ;CHECK LENGTHS
        BHS     UPDAT3                            ;BUFFER IS LARGER
;* BUFFER IS LARGER, INSERT SPACE
        NEGB                                      ;	CONVERT TO POSITIVE VALUE
        JSR     INSERT                            ;INSERT SPACE
        BRA     UPDAT5                            ;AND PROCEED
UPDAT3
        BEQ     UPDAT4                            ;SAME LENGTH
;* BUFFER IS SMALLER, DELETE TEXT
        JSR     DELETE                            ;DELETE SOME TEXT
UPDAT4
        JSR     COPY                              ;PERFORM COPY
UPDAT5
        CLR     CHANGE                            ;INDICATE LINE NOT CHANGED
UPDAT6
        PULS    A,B,X,Y,U,PC	RESTORE & RETURN
;*
;* SET THE 'HORZ' VARIABLE TO THE CORRECT VALUE FOR THE CURRENT
;* CURSOR POSITION, AND SET UP A POINTER TO THE ACTUAL LINE
;* ON WHICH THE CURSOR IS ON (THIS WILL BE THE TEXT FILE OR
;* THE EDIT BUFFER).
;* ENTRY:	NONE
;* EXIT:   ;U = POINTER TO CHARACTER
;*   ;B = ACTUAL 'X' POSITION OF CURSOR
;*
POSITC
        PSHS    A,X                               ;SAVE REGISTERS
        LDU     TXTPOS                            ;GET LINE POSITION
        LDA     CHANGE                            ;GET CHANGEED FLAG
        BEQ     POSIT1                            ;NOT IN EDIT BUFFER
        LDU     #E_BUFF                           ;POINT TO EDIT BUFFER
;* LOCATE ACTUAL 'X' POSITION IN LINE
POSIT1
        TFR     U,X                               ;'X' = TEMP ADDRESS
        CLR     HORZ                              ;ZERO ACTUAL 'X' POSITION
        CLRB                                      ;	ZERO B
POSIT2
        CMPB    CX                                ;ARE WE AT 'X' POSITION
        BHS     POSIT4                            ;YES, EXIT
        LDA     ,X+                               ;GET CHAR
        BMI     POSIT4                            ;EOF, EXIT
        CMPA    #NL                               ;NEW LINE?
        BEQ     POSIT4                            ;YES, EXIT
        INCB                                      ;	REDUCE COUNT
        INC     HORZ                              ;ADVANCE 'X' POSITION
        CMPA    #TAB                              ;IS IT A TAB?
        BNE     POSIT2                            ;NO, KEEP GOING
        BSR     SKPTAB                            ;SKIP THE TAB STOP
        BRA     POSIT2                            ;AND TEST AGAIN
;* IF POSITION IS < LEFT MARGIN, SCROLL SRCEEN LEFT
POSIT4
        LDA     OFFSET                            ;GET LEFT MARGIN
        CMPA    HORZ                              ;> CURRENT POSITION?
        BHI     POSIT5                            ;YES, HANDLE IT
;* IF POSITION > RIGHT MARGIN, SCROLL SCREEN RIGHT
        ADDA    #COLS                             ;OFFSET TO RIGHT MARGIN
        CMPA    HORZ                              ;<= CURRENT POSITION
        BHI     POSIT6                            ;NO, DONT ADJUST
POSIT5
        SUBA    #COLS/2                           ;SCROLL SCREEN LEFT
        STA     OFFSET                            ;RESET OFFSET
        BSR     UPDATE                            ;INSURE CHANGES ARE UPDATED
        DEC     REFLAG                            ;INSURE REFRESH OCCURS
        BRA     POSIT4                            ;INSURE WE HAVE DONE ENOUGH
POSIT6
        PULS    A,X,PC                            ;RESTORE & RETURN
;*
;* REPOSITION THE CURSOR TO THE INDICATED ADDRESS
;* ENTRY: U = ADDRESS
;*
REPOS
        PSHS    A,B,X,U                           ;SAVE REGISTERS
;* CALCULATE NEW 'Y' ADDRESS
        CLRB                                      ;	ZERO 'Y' POSITION
        LDX     SCRTOP                            ;GET SCREEN TOP
REPO1
        CMPX    4,S                               ;ARE WE OVER?
        BHS     REPO2                             ;YES, QUIT
        LDA     ,X+                               ;GET CHAR
        CMPA    #NL                               ;END OF LINE?
        BNE     REPO1                             ;NO, ITS OK
        INCB                                      ;	ADVANCE 'Y' POSITION
        CMPB    #LINES-2	OVER SCREEN?
        BLS     REPO1                             ;NO, ITS OK
        LDX     4,S                               ;NO SENSE LOOKING FURTHOR
;* CALCULATE NEW 'X' ADDRESS
REPO2
        CLR     CX                                ;ZERO 'X' POSITION
        STB     CY                                ;SAVE 'Y' POSITION
REPO3
        CMPU    #T_BUFF                           ;START OF FILE?
        BLS     REPO4                             ;YES, EXIT
        LDA     -1,U                              ;GET CHAR
        CMPA    #NL                               ;START OF LINE?
        BEQ     REPO4                             ;YES, EXIT
        LEAU    -1,U                              ;REDUCE COUNT
        INC     CX                                ;ADVANCE POSITION
        BRA     REPO3                             ;AND CONTINUE
REPO4
        STU     TXTPOS                            ;SAVE LINE POSITION
        LDX     4,S                               ;RESTORE 'U'
        CMPX    SCRTOP                            ;ARE WE WITHIN SCREEN?
        BLO     REPO5                             ;YES, ITS OK
        CMPB    #LINES-2	ARE WE OVER?
        BLS     REPO6                             ;NO, ITS OK
REPO5
        CLR     CY                                ;RESET TO ZERO
        STU     SCRTOP                            ;RESET TOP OF SCREEN
        DEC     REFLAG                            ;INDICATE REFRESH R=IRED
REPO6
        PULS    A,B,X,U,PC	RESTORE & RETURN
;*
;* SKIP AHEAD A TAB STOP
;*
SKPTAB
        LDA     HORZ                              ;GET 'X' POSITION
        BITA    #%00000111	AT TAB STOP?
        BEQ     SKPT1                             ;YES, WE ARE
        INC     HORZ                              ;ADVANCE IT
        BRA     SKPTAB                            ;AND PROCEED
SKPT1
        RTS
;*
;* REFRESH ENTIRE SCREEN FROM TOP
;*
REFALL
        LDU     SCRTOP                            ;GET TOP OF SCREEN ADDRESS
        CLRB                                      ;	ZERO 'Y' POSITION
        STB     REFLAG                            ;SET REFRESH FLAG
;*
;* REFRESH SCREEN:
;* ENTRY:    U = PTR TO TEXT, B = VERT LINE
;*
REFSCR
        PSHS    A,B,U                             ;SAVE REGISTERS
        LDA     HORZ                              ;GET HORZ POSITION
        PSHS    A                                 ;SAVE FOR LATER
REFS1
        CLRA                                      ;	'X' POSITION
        STA     HORZ                              ;ZERO HORIZONTAL
        JSR     GOTOXY                            ;MOVE CURSOR
        LDA     ,U                                ;GET TEXT CHAR
        BMI     REFS2                             ;END OF FILE
        BSR     REFLIN                            ;DISPLAY LINE
        INCB                                      ;	ADVANCE COUNT
        CMPB    #LINES-1	ARE WE OVER?
        BHS     REFS3                             ;YES, WE ARE
        BRA     REFS1                             ;AND PROCEED
;* END OF FILE ENCOUNTERED
REFS2
        JSR     WSO                               ;SPECIAL EFFECTS
        SWI
        FCB     24                                ;DISPLAY MESSAGE
        FCN     '*EOF*'
        JSR     WSE                               ;RESET SPECIAL
REFS3
        JSR     WCD                               ;CLEAR END OF SCREEN
        PULS    A                                 ;RESTORE HORZ
        STA     HORZ                              ;RE-SAVE IT
        PULS    A,B,U,PC	RESTORE & RETURN
;*
;* REFRESH LINE:
;* ENTRY: U = PTR LINE TO DISPLAY
;* EXIT:  U = PTR TO NEXT LINE
;*
REFLIN
        LDA     OFFSET                            ;GET SCREEN OFFSET
        ADDA    #COLS                             ;CALCULATE LAST POSITION
        STA     TEMP+1                            ;SAVE FOR LATER
;* DISPLAY TAGGED LINES IN SPECIAL VIDEO
        CMPU    TAG                               ;ARE WE IN TAG RANGE?
        BLO     REFL0A                            ;NO, ITS OK
        CMPU    TAG1                              ;STILL IN TAG RANGE?
        BHI     REFL0A                            ;NO, ITS OK
        DEC     VIDEO                             ;SET VIDEO FLAG
        JSR     WSO                               ;DISPLAY TAGG INFO
;* SKIP ANY DATA WHICH PRECEEDS THE HORIZONTAL SCROLLING WINDOW
REFL0A
        LDA     HORZ                              ;GET 'X' POSITION
        CMPA    OFFSET                            ;ARE WE LOWER?
        BHS     REFL1                             ;NO, EXIT
        LDA     ,U                                ;GET CHAR
        BMI     REFL2A                            ;END OF FILE
        CMPA    #NL                               ;NEW LINE?
        BEQ     REFL2A                            ;EXIT
        LEAU    1,U                               ;ADVANCE
        INC     HORZ                              ;ADVANCE HORZ
        CMPA    #TAB                              ;IS IT A TAB?
        BNE     REFL0A                            ;NO, ALL IS OK
        BSR     SKPTAB                            ;SKIP TO NEXT TAB STOP
        BRA     REFL0A                            ;AND PROCEED
;* DISPLAY ANY DATA WHICH IS WITHIN THE HORIZONTAL SCROLLING WINDOW
REFL1
        LDA     HORZ                              ;GET 'X' POSITION
        CMPA    TEMP+1                            ;ARE WE OVER?
        BHS     REFL3                             ;YES, EXIT
        LDA     ,U                                ;GET CHAR
        BMI     REFL2A                            ;END OF FILE (NO EOL)
        CMPA    #NL                               ;NEW LINE CHAR?
        BEQ     REFL2                             ;YES, EXIT
        LEAU    1,U                               ;ADVANCE IT
        CMPA    #TAB                              ;IS IT A TAB?
        BEQ     REFL1A                            ;YES, HANDLE IT
        BSR     WRCHR                             ;DISPLAY THE CHARACTER
        BRA     REFL1                             ;AND PROCEED
;* TAB CHAR, ADVANCE TO TAB STOP
REFL1A
        SWI
        FCB     21                                ;OUTPUT A SPACE
        INC     HORZ                              ;ADVANCE POSITION
        LDA     HORZ                              ;GET POSITION
        BITA    #%00000111	AT TAB STOP?
        BNE     REFL1A                            ;NO, PROCEED
        BRA     REFL1                             ;AND PROCEED
;* END OF LINE, PRINT EOL CHAR IF ENABLED, AND CLEAR REMINDER
REFL2
        TST     EOLFLAG                           ;DO WE DISPLAY END OF LINE?
        BPL     REFL2A                            ;NO, WE DON'T
        BSR     WRCHR                             ;DISPLAY END OF LINE
        LDA     HORZ                              ;GET 'X' POSITION
        CMPA    TEMP+1                            ;ARE WE OVER?
        BHS     REFL3                             ;YES, DON'T CLEAR
REFL2A
        BSR     WCE                               ;CLEAR END OF LINE
;* SKIP ANY DATA WHICH FOLLOWS THE HORIZONTAL SCROLLING WINDOW.
REFL3
        LDA     ,U                                ;GET CHARCTER
        BMI     REFL4                             ;EOF, EXIT
        LEAU    1,U                               ;ADVANCE
        CMPA    #NL                               ;NEWLINE?
        BNE     REFL3                             ;NO, KEEP LOOKING
;* TURN OFF SPECIAL VIDEO
REFL4
        LDA     VIDEO                             ;SPECIAL MODE
        BEQ     REFL5                             ;NO, ITS OK
        CLR     VIDEO                             ;ZERO FLAG
        BSR     WSE                               ;DISABLE SPECIAL EFFECTS
REFL5
        RTS
;*
;* WRITE CHARACTER TO OUTPUT DEVICE: A = CHR
;*
WRCHR
        PSHS    A,B                               ;SAVE REGISTERS
        CMPA    #' '                              ;CONTROL CODE
        BHS     WRCH2                             ;NO, ITS OK
;* CONTROL CODE TO DISPLAY
        LDA     #SO                               ;SPECIAL EFFECTS ON
        LDB     #SE                               ;SPECIAL EFFECTS OFF
        TST     VIDEO                             ;INVERSE MODE?
        BEQ     WRCH1                             ;NO, ITS OK
        EXG     A,B                               ;SWAP MODEM
WRCH1
        BSR     PUTCHR                            ;SET EFFECTS
        LDA     ,S                                ;GET CHAR
        ADDA    #'@'                              ;CONVERT TO DISPLAY
        BSR     PUTCHR                            ;DISPLAY
        TFR     B,A                               ;GET TERMINATE CHAR
;* NORMAL CHARACTER TO DISPLAY
WRCH2
        BSR     PUTCHR                            ;OUTPUT CHAR
        INC     HORZ                              ;ADVANCE POSITION
        PULS    A,B,PC                            ;RESTORE & RETURN
;* SPECIAL CHRAACTER OUTPUT ROUTINES
WCL
        LDA     #CL                               ;GET CLEAR SCREEN CHAR
        BRA     PUTCHR                            ;OUTPUT & RETURN
WCD
        LDA     #CD                               ;GET CLEAR TO END CHAR
        BRA     PUTCHR                            ;OUTPUT & RETURN
WCE
        LDA     #CE                               ;GET CLEAR LINE CHAR
        BRA     PUTCHR                            ;OUTPUT & RETURN
WSO
        LDA     #SO                               ;SPECIAL EFFECTS ON
        BRA     PUTCHR                            ;OUTPUT & RETURN
WSE
        LDA     #SE                               ;SPECIAL EFFECTS OFF
;*
;* TERMINAL INDEPENDANT SCREEN HANDLING
;*
;* GOTOXY    - MOVE CURSOR POSITION A='X', B='Y'
;* GETKEY    - GET KEY FROM TTY, EXIT: A > $7F = SPECIAL CODE
;* PUTCHR    - WRITE CHAR(A), A > 80 = SPECIAL CODE
;*
;* WRITE A CHARACTER TO THE DISPLAY
;*
PUTCHR
        TSTA                                      ;	SPECIAL CASE?
        BMI     PUTC1                             ;YES, HANDLE IT
        SWI
        FCB     33                                ;DISPLAY IT
        RTS
;* SPECIAL STRING TO OUTPUT
PUTC1
        PSHS    A,X                               ;SAVE REGISTERS
        LSLA                                      ;	X2 FOR TWO BYTE ENTRIES
        LDX     #PUTTAB                           ;POINT TO TABLE
        LDX     A,X                               ;GET DATA TO WRITE
        SWI
        FCB     23                                ;DISPLAY IT
        PULS    A,X,PC                            ;RESTORE & RETURN
;* MOVE TO LAST LINE OF SCREEN
GOTOLST
        LDD     #LINES-1	POINT TO LAST LINE
        BRA     GOTOXY                            ;MOVE THERE
;* MOVE TO RELATIVE SCREEN ADDRESS
GOTOXX
        LDA     HORZ                              ;GET 'X' POSITION
        SUBA    OFFSET                            ;CONVERT TO SCREEN POSITION
        LDB     CY                                ;GET 'Y' POSITION
;*
;* MOVE CURSOR POSITION
;*
GOTOXY
        PSHS    A,B,X                             ;SAVE CHARS
        LDX     GXYPTR                            ;POINT TO BUFFER
GOTOXY1
        LDA     ,X+                               ;GET CHAR
        BEQ     GOTOXY6                           ;END, EXIT
        BMI     GOTOXY3                           ;SPECIAL CODE
;* NORMAL CHARACTER, DISPLAY IT
GOTOXY2
        SWI
        FCB     33                                ;DISPLAY IT
        BRA     GOTOXY1                           ;AND PROCEED
;* SPECIAL TRANSLATED (X/Y) CODE
GOTOXY3
        LDB     ,S                                ;GET 'X' POSITION
        BITA    #%01000000	IS IT 'X'?
        BEQ     GOTOXY4                           ;YES, ALL IS OK
        LDB     1,S                               ;GET 'Y' POSITION
GOTOXY4
        ADDB    ,X+                               ;INCLUDE OFFSET
        BITA    #%00100000	DECIMAL?
        BNE     GOTOXY5                           ;YES, DO DECIMAL
        TFR     B,A                               ;GET CHAR
        BRA     GOTOXY2                           ;OUTPUT & PROCEED
GOTOXY5
        CLRA                                      ;	ZERO HIGH
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        BRA     GOTOXY1                           ;AND PROCEED
GOTOXY6
        PULS    A,B,X,PC	RESTORE & RETURN
;*
;* GET AN INPUT KEY FROM THE TERMINAL
;*
GETKEY
        PSHS    B,X,U                             ;SAVE REGS
GETK1
        LDU     #GETKTAB	POINT TO KEY TABLE
        LDB     #$80                              ;FIRST FUNCTION CODE
GETK2
        LDX     #GKBUFF                           ;POINT TO KEY BUFFER
GETK3
        LDA     ,X+                               ;GET CHAR
        BEQ     GETK6                             ;PARTIAL MATCH
        CMPA    ,U                                ;GET CHAR FROM TABLE
        BNE     GETK4                             ;DOSN'T MATCH
        LEAU    1,U                               ;ADVANCE
        BRA     GETK3                             ;KEEP LOOKING
;* CHAR DID NOT MATCH, ADVANCE TO NEXT
GETK4
        LDA     ,U+                               ;GET CHAR
        BNE     GETK4                             ;KEEP LOOKING
        INCB                                      ;	ADVANCE FUNCTION CODE
        LDA     ,U                                ;END OF TABLE?
        BNE     GETK2                             ;NO, KEEP LOOKING
;* HIT END OF TABLE, NO MATCHES
;* REMOVE AND RETURN ONE CHAR FROM THE INPUT
        LDX     #GKBUFF                           ;POINT TO BUFFER
        LDA     ,X+                               ;GET CHAR
        BEQ     GETK8                             ;NONE, GET A KEY
GETK5
        LDB     ,X+                               ;GET NEXT CHAR
        STB     -2,X                              ;WRITE IT
        BNE     GETK5                             ;DO THEM ALL
        ANDA    #%01111111	INSURE NO HIGH BUT
        PULS    B,X,U,PC	RETURN WITH CHAR
;* HIT END OF STRING WITH ALL MATCHES
GETK6
        LDA     ,U                                ;END OF STRING?
        BEQ     GETK7                             ;YES, WE HAVE IT
GETK8
        SWI
        FCB     34                                ;GET INPUT KEY
        STA     -1,X                              ;WRITE INTO STRING
        CLR     ,X                                ;ZERO END
        BRA     GETK1                             ;RETEST FOR MATCHES
;* WE FOUND AN INPUT STRING
GETK7
        TFR     B,A                               ;GET CHAR
        CLR     >GKBUFF                           ;ZERO BUFFER
        PULS    B,X,U,PC	RESTORE & RETURN
;*
;* INFORMATIONAL AND ERROR MESSAGES
;*
UNKMSG
        FCN     'Invalid key'
UNCMSG
        FCN     'Unknown command'
INVSER
        FCN     'Invalid search string'
INVDEST
        FCN     'Invalid destination'
NOTAGG
        FCN     'No tagged lines'
NOTFND
        FCN     'Not found'
INEMSG
        FCC     'Out of memory - Changes lost'
        FCB     7
NULLMSG
        FCB     0
NEWMSG
        FCN     'New file'
INSMSG
        FCN     'Insert'
OVWMSG
        FCN     'Overwrite'
FCHMSG
        FCN     "Unsaved changes, use 'qq' to quit anyway"
;* SCREEN MODE COMMAND KEY TABLE
CMDTAB
        FDB     BACKLIN                           ;UP ARROW
        FDB     FWDLIN                            ;DOWN ARROW
        FDB     FWDCHR                            ;RIGHT ARROW
        FDB     BACKCHR                           ;LEFT ARROW
        FDB     BACKPAG                           ;PAGE UP
        FDB     FWDPAG                            ;PAGE DOWN
        FDB     CUREOL                            ;PAGE RIGHT
        FDB     CURSOL                            ;PAGE LEFT
        FDB     HOME                              ;HOME
        FDB     FEND                              ;END
        FDB     DELCHR                            ;DELETE CHARACTER
        FDB     DELPRE                            ;DELETE PREVIOUS CHAR
        FDB     REDRAW                            ;REDRAW SCREEN
;* FUNCTION KEYS
        FDB     ECMD                              ;1 EXECUTE COMMAND
        FDB     RCMD                              ;2 REPEAT LAST COMMAND
        FDB     TOGINS                            ;3 TOGGLE INSERT MORE
        FDB     TOGEOL                            ;4 TOGGLE END OF LINE DISPLAY
        FDB     DISCUR                            ;5 DISPLAY CURSOR
        FDB     CURTOP                            ;6 CURRENT LINE TO TOP
        FDB     TAGLIN                            ;7 TAG LINE(S)
        FDB     DELLIN                            ;8 DELETE LINE
        FDB     DELEOL                            ;9 DELETE TO END OF LINE
        FDB     INSDEL                            ;10 INSERT DELETED LINE
        FDB     WRDRT                             ;11 WORD RIGHT
        FDB     WRDLT                             ;12 WORD LEFT
        FDB     UNKEY                             ;13 UNKNOWN KEY
        FDB     UNKEY                             ;14 UNKNOWN KEY
        FDB     UNKEY                             ;15 UNKNOWN KEY
;*
;* DATA AREAS
;*
GKBUFF
        FCB     0,0,0,0,0	INPUT BUFFER
        FCB     0,0,0,0,0	FOR GET KEY
;*
;* OUTPUT TRANSLATION TABLES
;*
;* OUTPUT TRANSLATION TABLES
ISTPTR
        FDB     GETKTAB                           ;INITIALIZATION STRING
GXYPTR
        FDB     GETKTAB                           ;GOTO X-Y HANDLER
PUTTAB
        FDB     GETKTAB                           ;CLEAR SCREEN
        FDB     GETKTAB                           ;CLEAR END OF LINE
        FDB     GETKTAB                           ;CLEAR END OF DISPLAY
        FDB     GETKTAB                           ;SPECIAL EFFECTS ON
        FDB     GETKTAB                           ;SPECIAL EFFECTS OFF
        FDB     GETKTAB                           ;SCROLL FORWARD
;* STANDARD TERMINAL KEYS INPUT LOOKUP TABLE
GETKTAB
        FCB     0
;*
        ORG     DATA_BEGINS
;*
;* DATA AREA
;*
CX
        FCB     0                                 ;CURSOR 'X' POSITION
CY
        FCB     0                                 ;CURSOR 'Y' POSITION
HORZ
        FCB     0                                 ;ACTUAL HORIZONTAL POSITION
OFFSET
        FCB     0                                 ;OFFSET FRO START OF LINE
REFLAG
        FCB     0                                 ;REFRESH R=IRED FLAG
WINDOW
        FCB     -1                                ;WINDOW MODE FLAG
VIDEO
        FCB     0                                 ;VIDEO MODE FLAG
INSFLAG
        FCB     -1                                ;INSERT/OVERWITE FLAG
EOLFLAG
        FCB     0                                 ;END OF LINE DISPLAY FLAG
CHANGE
        FCB     0                                 ;LINE CHANGED FLAG
FCHANGE
        FCB     0                                 ;FILE CHANGED FLAG
EDTLEN
        FCB     0                                 ;LENGTH OF EDIT BUFFER
DELLEN
        FCB     0                                 ;LENGTH OF DELETE BUFFER
SCRTOP
        FDB     T_BUFF                            ;ADDRESS OF TOP OF SCREEN
TXTPOS
        FDB     T_BUFF                            ;ADDRESS OF START OF LINE
TAG
        FDB     0                                 ;START OF TAGGED RANGE
TAG1
        FDB     0                                 ;END OF TAGGED RANGE
START
        FDB     0                                 ;STARTING COMMAND RANGE
END
        FDB     0                                 ;ENDING COMMAND RANGE
NEWPOS
        FDB     0                                 ;NEW POSITION TO MOVE TO
ERRMSG
        FDB     0                                 ;ERROR MESSAGE
TEMP
        RMB     4                                 ;TEMPORARY STORAGE
NAMBUF
        RMB     25                                ;SAVED FILENAME
COMMAND
        RMB     50                                ;COMMAND BUFFER
E_BUFF
        RMB     256                               ;LINE EDIT BUFFER
D_BUFF
        RMB     300                               ;DELETE BUFFER & STACK

STACK           = *                               ;LOCATION OF STACK
T_BUFF          = *                               ;TEXT FILE STORAGE
