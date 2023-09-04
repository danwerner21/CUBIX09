;        TITLE   CUBIX LINE EDITOR
;*
;* EDIT: A line oriented text editor
;*
;* Copyright 1983-2005 Dave Dunfield
;* All rights reserved.
;*
OSRAM           = $2000                           ;APPLICATION RAM AREA
OSEND           = $DBFF                           ;END OF GENERAL RAM
OSUTIL          = $D000                           ;UTILITY ADDRESS SPACE

        ORG     OSRAM                             ;DOS APPLICATION SPACE
;*
RAM             = OSRAM+$600                      ;START OF AVAILABLE RAM, COMMAND BUFFER
EDBUF           = RAM+128                         ;EDIT BUFFER
SERBUF          = EDBUF+128                       ;SERIAL BUFFER
TEMP            = SERBUF+522                      ;TEMPORARY STORAGE
TEMP1           = TEMP+2                          ;TEMPORARY STORAGE
SAVPTR          = TEMP1+2                         ;SAVED FILE POSITION (FOR :S AND :R)
FILNAM          = SAVPTR+2                        ;SAVED FILENAME
AUTSTR          = FILNAM+25                       ;STRING FOR AUTOMATIC COMMAND
STACK           = RAM+1024                        ;EDITOR STACK
TEXT            = STACK                           ;RAM TEXT AREA
;*
EDIT
        CMPA    #'?'                              ;HELP COMMAND
        BNE     QUAL                              ;NO, LOOK FOR QUALIFIERS
        SWI
        FCB     25
        FCN     'Use: EDIT[/BATCH/QUIET] <file> [<cmd file>]'
        SWI
        FCB     0
QUAL
        LDA     ,Y                                ;GET CHARACTER FROM OPERAND
        CMPA    #'/'                              ;QUALIFIER?
        BNE     MAIN                              ;NO, CONTINUE
        LDX     #QTABLE                           ;POINT TO QUALIFIER TABLE
        SWI
        FCB     18                                ;LOOK IT UP
        CMPB    #QMAX                             ;IS IT VALID?
        BHS     QERR                              ;NO, GET UPSET
        LDX     #FCMD                             ;POINT TO FLAG COMMAND SPACE
        CLR     B,X                               ;SET THIS FLAG
        BRA     QUAL                              ;CONTINUE
;* QUALIFIER WAS NOT FOUND
QERR
        SWI
        FCB     24                                ;DISPLAY MSG
        FCN     'Invalid Qualifier: '
        LDA     ,Y+                               ;GET CHAR
DSQU1
        SWI
        FCB     33                                ;DISPLAY
        SWI
        FCB     5                                 ;TEST FOR TERMINATOR
        BEQ     GOABO                             ;YES, EXIT
        CMPA    #'/'                              ;NEXT QUALIFIER?
        BNE     DSQU1                             ;NO, CONTINUE
GOABO
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCB     $27,0                             ;QUOTE, LF, CR
        LDA     #1                                ;RETURN CODE = 1
        SWI
        FCB     0
;* CONTINUE WITH EDITOR
MAIN
        PSHS    Y                                 ;SAVE POINTER TO FILENAME
        LDX     #FILNAM                           ;POINT TO SAVED NAME
EDI1
        LDA     ,Y+                               ;GET CHAR FROM PARAMETER LINE
        STA     ,X+                               ;SAVE IN SAVED FILENAME
        BEQ     EDI2                              ;ZERO EXITS
        CMPA    #' '                              ;SO DUZ SPACE
        BEQ     EDI2                              ;EXIT
        CMPA    #$0D                              ;END OF FILE?
        BNE     EDI1                              ;NO, KEEP SAVEING
EDI2
        PULS    Y                                 ;RESTORE FILENAME POINTER
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;INVALID, GET UPSET
        SWI
        FCB     68                                ;DOES IT EXIST?
        BEQ     FILEXI                            ;IF SO, IT EXISTS
        LDA     #$FF                              ;END OF FILE MARKER
        STA     TEXT                              ;CLEAR THE FILE
        TST     QCMD                              ;QUIET?
        BEQ     GOEDIT                            ;YES, DON'T DISPLAY MESSAGE
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'NEW FILE:'
        BRA     GOEDIT                            ;GET COMMAND
FILEXI
        LDX     #TEXT                             ;POINT TO TEXT BUFFER
        SWI
        FCB     53                                ;LOAD FILE
        BNE     ABORT                             ;FAILED, GIVE UP
GOEDIT
        TST     FCMD                              ;IS FILE INPUT?
        BNE     GOED1                             ;NO, SKIP IT
        SWI
        FCB     10                                ;GET FILENAME
        BNE     ABORT                             ;UPSET
        LBSR    OPENR                             ;OPEN INPUT FILE
        BNE     ABORT                             ;ERROR, EXIT
GOED1
        LDU     #TEXT                             ;LOOK FOR TEXT
        STU     SAVPTR                            ;SAVE FOR LATER
        LDA     #$0D                              ;GET CR
        STA     AUTSTR                            ;INIT AUTO COMMAND STRING
EDMSG
        TST     QCMD                              ;QUIET?
        BEQ     GOCMD                             ;NO OUTPUT
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'EDIT:'
GOCMD
        LDS     #STACK                            ;POINT TO STACK
        LBSR    GETLIN                            ;GET A LINE
        SWI
        FCB     4                                 ;NULL?
        BNE     COM1                              ;NO, TRY PRINT
GODISP
        LBSR    DSPLIN                            ;DISPLAY IT
        BRA     GOCMD                             ;AND AGAIN
;* LOOK FOR COMMAND
COM1
        LDA     ,Y+                               ;GET COMMAND
        CMPA    #$61                              ;LOWER CASE?
        BLO     NOCP                              ;NO, ITS OK
        ANDA    #$5F                              ;CONVERT TO UPPER
NOCP
        LDB     ,Y                                ;GET NEXT CHAR
        ANDB    #$5F                              ;CONVERT TO UPPER
;* 'QUIT' COMMAND
        CMPA    #'Q'                              ;QUIT?
        BNE     PRINT                             ;NO, TRY NEXT
        CMPB    #'U'                              ;R=IRE AT LEAST 'QU'
        LBNE    UNCMDB                            ;GET UPSET
        CLRA                                      ;	ZERO RETURN CODE
ABORT
        SWI
        FCB     0                                 ;GO HOME
;* 'PRINT' COMMAND
PRINT
        CMPA    #'P'                              ;IS IT PRINT?
        BNE     COM2                              ;NO, TRY NEXT
        LBSR    GETOP1                            ;GET OPERAND
PR1
        STU     TEMP                              ;SAVE FOR LATER
        TST     ,U                                ;AT END OF FILE?
        BMI     EOF                               ;YES, REPORT
        LBSR    DSPADV                            ;DISPLAY AND ADVANCE
        DECB                                      ;	REDUCE COUNT
        BNE     PR1                               ;CONTINUE
        LDU     TEMP                              ;BACKUP TO LAST LINE
        BRA     GOCMD                             ;BACK FOR NEXT COMMAND.
;* 'NEXT' COMMAND
COM2
        CMPA    #'N'                              ;IS IT 'NEXT'
        BNE     COM3                              ;NO, TRY NEXT
        LBSR    GETOP1                            ;GET OPERAND
NEX1
        LBSR    ADVLIN                            ;ADVANCE
        BMI     EOF                               ;REPORT EOF
        DECB                                      ;	REDUCE COUNT
        BNE     NEX1                              ;CONTINUE
        BRA     GODISP                            ;NEXT COMMAND
;* END OF FILE WAS FOUND
EOF
        LBSR    DSPEOF                            ;DISPLAY END OF FILE
        BRA     GOCMD                             ;NEXT COMMAND
TOF
        TST     QCMD                              ;QUIET MODE?
        BEQ     GOCMD                             ;YES, DON'T DISPLAY
        SWI
        FCB     24                                ;DISPLAY MSG
        FCN     'TOF:'
GOLFCR
        SWI
        FCB     22                                ;NEW LINE
        BRA     GOCMD
;* 'UP' COMMAND
COM3
        CMPA    #'U'                              ;WAS IT UP?
        BNE     COM4                              ;NO, TRY NEXT
        LBSR    GETOP1                            ;GET OPERAND
UP1
        LBSR    BAKLIN                            ;BACKUP
        BNE     TOF                               ;TOP OF FILE
        DECB                                      ;	REDUCE COUNT
        BNE     UP1                               ;CONTINUE
        LBRA    GODISP                            ;GO SHO IT
;* INSERT COMMAND
COM4
        CMPA    #'I'                              ;INSERT?
        BNE     COM5                              ;NO, TRY DELETE
        TST     QCMD                              ;QUIET?
        BEQ     INSP
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     'INPUT:'
INSP
        LBSR    GETLIN                            ;GET A LINE
        LDA     ,Y                                ;GET LINE
        CMPA    #$0D                              ;NULL (ZERO LENGTH)?
        LBEQ    EDMSG                             ;IF SO, EXIT
        LBSR    INSERT                            ;INSERT THE LINE
        BRA     INSP                              ;GET NEXT COMMAND
;* BEGINNING OF FILE COMMAND
COM5
        CMPA    #'B'                              ;BEGIN?
        BNE     COM6                              ;NO, SKIP IT
        LDU     #TEXT                             ;POINT TO BEGINNING
        TST     ,U                                ;IS IT NULL
        BMI     TOF                               ;NO, DISPLAY IT
        LBRA    GODISP                            ;INDICATE TOP OF FILE
;* END OF FILE COMMAND
COM6
        CMPA    #'E'                              ;GO TO END OF FILE?
        BNE     COM7                              ;NO, TRY NEXT
        CMPB    #'X'                              ;IS IT EXIT
        LBEQ    EXIT
        LBSR    FNDEOF                            ;LOCATE END OF FILE
        LEAU    -1,U                              ;BACKUP TO IT
EOF1
        BRA     EOF                               ;INDICATE WE ARE THERE
;* DELETE LINES COMMAND
COM7
        CMPA    #'D'                              ;DELETE?
        BNE     COM8                              ;NO, TRY NEXT
        CMPB    #'E'                              ;IS IT 'DE'?
        LBNE    UNCMDB                            ;NO, COMPLAIN
        LEAY    1,Y                               ;SKIP 'E'
        LBSR    GETOP1                            ;GET OPERAND
        PSHS    U                                 ;SAVE POINTER
DEL1
        LBSR    ADVLIN                            ;ADVANCE A LINE
        BMI     GODEL                             ;GO DELETE IT
        DECB                                      ;	REDUCE COUNT
        BNE     DEL1                              ;GOT FOR IT
GODEL
        LDX     ,S                                ;GET POINT TO START
GODEL1
        LDA     ,U+                               ;GET CHARACTER FROM LINE
        STA     ,X+                               ;SAVE
        BPL     GODEL1                            ;SAVE IT ALL
        PULS    U                                 ;RESTORE POINTER
EOFTST
        LDA     ,U                                ;GET STATUS
        BMI     EOF1                              ;INDICATE IF EOF
        LBRA    GOCMD                             ;GET NEXT COMMAND
;* 'CHANGE' COMMAND
COM8
        CMPA    #'C'                              ;TEST FOR CHANGE
        LBNE    LOCATE                            ;NO, TRY NEXT
        CMPB    #'A'                              ;CHANGE ALL?
        BEQ     CHA1                              ;IF SO, SKIP IT
        CMPB    #'D'                              ;IS IT CHANGE DISPLAY?
        BEQ     CHA1                              ;YES
        CMPB    #'H'                              ;CHANGE LINE?
        BNE     CHA                               ;NO, SKIP IT
CHA1
        LEAY    1,Y                               ;SKIP
CHA
        CLR     TEMP+1                            ;INDICATE NO DISPLAY
        CLR     TEMP1
        CLR     TEMP1+1
        SWI
        FCB     4                                 ;SKIP AHEAD
        LBEQ    BADOPR                            ;NO OPERATOR
        STA     TEMP                              ;SAVE DELIMITER
        LEAY    1,Y                               ;SKIP DELIMITER
        PSHS    U                                 ;SAVE U
;* TEST FOR CHANGE LINE
        CMPB    #'H'                              ;CHANGE LINE?
        BNE     CHAL                              ;NO, TRY CHANGE ALL
        LBSR    DOCHG                             ;DO CHANGE
        LBNE    CNOTR                             ;NOT FOUND
CHL1
        LDD     TEMP1
        ADDD    #1
        STD     TEMP1
        LBSR    DOCH1                             ;DO IT AGAIN
        BEQ     CHL1                              ;CONTINUE
        LDU     ,S                                ;RESTORE
        LBSR    DELETE                            ;DELETE THIS LINE
        LDY     #EDBUF                            ;POINT TO BUFFER
        LBSR    INSERT                            ;INSERT IT
        PULS    U                                 ;RESTORE
        BSR     SHOCHG                            ;DISPLAY IT
        LBRA    GODISP
CNOTR
        PULS    U                                 ;RESTORE TEXT POINTER
CNOTF
        SWI
        FCB     25
        FCN     'Not found.'
        LBRA    GOCMD
SHOCHG
        LDA     QCMD
        BEQ     SHOR
        LDD     TEMP1
        BEQ     CNOTF
        SWI
        FCB     26                                ;OUTPUT IN DEC
        SWI
        FCB     25
        FCN     ' occurances changed.'
SHOR
        RTS
;* CHANGE ALL OCCURENCES
CHAL
        CMPB    #'A'                              ;CHANGE FILE?
        BEQ     GOCHG                             ;YES
        CMPB    #'D'                              ;CHANGE DISPLAY?
        BNE     CHGF                              ;NO, JUST FIRST OCCURRANCE
        DEC     TEMP+1                            ;SET FLAG
GOCHG
        LDU     #TEXT                             ;POINT TO RAM
CHAL1
        PSHS    U                                 ;SAVE IT
        LBSR    DOCHG                             ;PERFORM CHANGE
        BNE     NEXTL                             ;NOT ON THIS LINE
CHAL2
        LDD     TEMP1
        ADDD    #1
        STD     TEMP1
        LBSR    DOCH1
        BEQ     CHAL2
        PULS    U
        PSHS    Y,U
        LBSR    DELETE
        LDY     #EDBUF
        LBSR    INSERT
        PULS    Y,U
        LDA     TEMP+1                            ;TEST FOR CHANGE DISPLAY
        BEQ     CHAL3                             ;NO, OK
        LBSR    DSPADV                            ;DSPLAY LINE
        BRA     CHAL5                             ;TEST FOR END OF FILE
CHAL3
        LDA     ,U+
        BMI     CHAL4
        CMPA    #$0D
        BNE     CHAL3
        BRA     CHAL5
NEXTL
        LEAS    2,S
CHAL5
        LDA     ,U
        BPL     CHAL1
CHAL4
        PULS    U
        BSR     SHOCHG
        LBRA    GOCMD
;* CHANGE FIRST OCCURANCE
CHGF
        LBSR    DOCHG
        LBNE    CNOTR
;* COPY REMAINDER OF LINE OVER
MTC3
        LDA     ,U+                               ;GET CHARACTER FROM LINE
        STA     ,X+                               ;SAVE IN OUTPUT
        CMPA    #$0D                              ;END OF LINE?
        BNE     MTC3                              ;COPY REMAINDER OF LINE OVER
        LDU     ,S                                ;GET TEXT POINTER
        LBSR    DELETE                            ;DELETE THIS LINE
        LDY     #EDBUF                            ;POINT TO EDIT BUFFER
        LBSR    INSERT                            ;PUT IT IN
        PULS    U
        LBRA    GODISP
;* PERFORM CHANGE TO TEXT, ON ENTRY, Y POINTS TO CHANGE COMMAND OPERANDS
;* ON EXIT, Z FLAG IS SET IT CHANGE WAS FOUND, AND U POINTS TO REMAINDER
;* OF LINE, OTHERWISE, U POINTS TO START OF NEXT LINE
DOCHG
        LDX     #EDBUF                            ;POINT TO EDITING BUFFER
        LDA     ,U                                ;CHECK POSITION
        LBMI    EOF                               ;WE ARE AT END OF TEXT
DOCH1           = *
MTCH1
        PSHS    X,Y,U                             ;SAVE POINTERS
MTCH
        LDA     ,Y+                               ;GET CHARACTER
        CMPA    TEMP                              ;IS IT DELIMITER?
        BEQ     MTCF                              ;WE FOUND IT
        LDA     ,U+                               ;GET CHAR FROM BUFFER
        STA     ,X+                               ;SAVE IN EDIT BUFFER
        CMPA    #$0D                              ;DID WE HIT END
        BEQ     MTNOTF                            ;NOT FOUND
        CMPA    -1,Y                              ;DOES IT MATCH US
        BEQ     MTCH                              ;WE FOUND
        PULS    X,Y,U                             ;RESTORE REGS
        LEAX    1,X                               ;ADVANCE IN BUFFER
        LEAU    1,U                               ;ADVANCE IN TEXT
        BRA     MTCH1                             ;NOT FOUND
MTNOTF
        LDY     2,S                               ;RESTORE
        LEAS    6,S                               ;SKIP TWO SAVED U'S
        LDA     #1                                ;CLEAR Z FLAG
        RTS
;* INSERT CHANGE BUFFER CONTENTS
MTCF
        LDX     ,S++                              ;GET POINTER TO THIS PART
MTC1
        LDA     ,Y+                               ;GET CHARACTER FROM LINE
        CMPA    #$0D                              ;END OF LINE
        BEQ     MTC2                              ;INVALID OPERATOR
        CMPA    TEMP                              ;DELIMITER?
        BEQ     MTC2                              ;IF SO, QUIT
        STA     ,X+                               ;SAVE IN BUFFER
        BRA     MTC1                              ;AND CONTINUE
MTC2
        PULS    Y                                 ;RESTORE Y
        LEAS    2,S                               ;SKIP SAVED U
        RTS
;* LOCATE COMMAND
LOCATE
        CMPA    #'/'                              ;LOCATE?
        BNE     REPEAT                            ;NO, SKIP IT
LOC1
        LBSR    ADVLIN                            ;ADVANCE A LINE
        LBMI    EOF                               ;INDICATE WE HIT THE END
LOC2
        PSHS    Y,U                               ;SAVE POINTERS
LOC3
        LDA     ,U                                ;GET CHARACTER FROM BUFFER
        BMI     HITEOF                            ;FOUND END OF FILE
        LDA     ,Y+                               ;DO WE HAVE IT
        CMPA    #$0D                              ;END OF LINE
        BEQ     FNDIT                             ;IF SO, WE FOUND
        CMPA    ,U+                               ;IS THIS IT?
        BEQ     LOC3                              ;IF CONTINUES TO MATCH, GO FOR IT
        PULS    Y,U                               ;RESTORE REGS
        LEAU    1,U                               ;SKIP TO NEXT
        BRA     LOC2                              ;KEEP LOOKING
HITEOF
        LEAU    -1,Y                              ;BACKUP
        LBRA    EOF                               ;GET UPSET
FNDIT
        LDA     ,-U                               ;BACKUP
        CMPA    #$0D                              ;LOOK FOR CR
        BNE     FNDIT                             ;KEEP LOOKING
        LEAU    1,U                               ;SKIP AEHEAD
        LBRA    GODISP
;* REPEAT A LINE
REPEAT
        CMPA    #'+'                              ;REPEAT?
        BNE     WRITE                             ;NO, TRY NEXT
        LBSR    GETOP1                            ;GET OPERAND
        LDX     #EDBUF                            ;POINT TO EDIT BUFFER
        PSHS    U                                 ;SAVE POINTER
REP1
        LDA     ,U+                               ;GET CHAR. FROM TEXT
        STA     ,X+                               ;SAVE IN TEXT
        CMPA    #$0D                              ;END?
        BNE     REP1                              ;NO, MOVE ENTIRE LINE
        PULS    U                                 ;RESTORE POINTER
        STB     TEMP                              ;SAVE FOR LATER
REP2
        LDY     #EDBUF                            ;POINT TO BUFFER
        LBSR    INSERT                            ;PUT IT IN
        DEC     TEMP                              ;REDUCE COUNT
        BNE     REP2                              ;KEEP AT IT
        BRA     GOCMD1                            ;GET NEXT COMMAND
;* WRITE FILE TO SEPERATE FILE
WRITE
        CMPA    #'W'                              ;IS IT 'WRITE'?
        BNE     READ                              ;NO, TRY NEXT
        LBSR    GETOP1                            ;GET OPERAND
        PSHS    B                                 ;SAVE COUNT
        LBSR    UCASE                             ;CONVERT TO UPPER
        SWI
        FCB     10                                ;GET FILENAME
        BNE     GOCMD1                            ;INVALID, QUIT
        LDB     ,S+                               ;RESTORE B
        BNE     WRLINS                            ;YES
        LBSR    SAVFIL                            ;SAVE IT
        BRA     GOCMD1                            ;QUIT
WRLINS
        LBSR    OPENW                             ;OPEN FOR WRITE
        BNE     GOCMD1                            ;BAD, QUIT
        TFR     U,X                               ;COPY POINTER
        LDY     #0                                ;START WITH ZERO
WRLI1
        LDA     ,X                                ;GET CHAR
        BMI     WRLI2                             ;IF END, CLOSE IT
        LBSR    WRITEC                            ;WRITE CHAR
        BNE     GOCMD1                            ;ERROR, QUIT
        LDA     ,X+                               ;GET CHAR BACK
        CMPA    #$0D                              ;END OF LINE?
        BNE     WRLI1                             ;OK
        LEAY    1,Y                               ;ADVANCE LINE COUNT
        DECB                                      ;	REDUCE COUNT
        BNE     WRLI1                             ;CONTINUE
WRLI2
        LBSR    CLOSE                             ;CLOSE FILE
        TST     QCMD                              ;BEING QUIET?
        BEQ     GOCMD1                            ;IF SO, SAY NOTHING
        TFR     Y,D                               ;COPY TO D
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     25
        FCN     ' lines written.'
GOCMD1
        LBRA    GOCMD                             ;BACK FOR ANOTHER COMMAND
;* READ ANOTHER FILE INTO THIS ONE
READ
        CMPA    #'R'                              ;IS IT READ?
        BNE     QUERY                             ;NO, TRY NEXT
        LBSR    UCASE                             ;CONVERT TO UPPER
        SWI
        FCB     10                                ;GET FILE NAME
        BNE     GOCMD1                            ;INVALID
        LDA     ,U                                ;ARE WE AT EOF?
        BPL     READ1                             ;NO, DO IT HARD WAY
        TFR     U,X                               ;POINT AT END OF FILE
        SWI
        FCB     53                                ;LOAD FILE
        BRA     GOCMD1                            ;AND CONTINUE
READ1
        LBSR    OPENR                             ;OPEN FILE
        BNE     GOCMD1                            ;BAD, QUIT
READ2
        LDX     #RAM                              ;POINT TO RAM
        TFR     X,Y                               ;COPY FOR LATER INSERT
READ3
        LBSR    READC                             ;READ A CHAR
        BNE     GOCMD1                            ;END OF LINE
        STA     ,X+                               ;SAVE IT
        CMPA    #$0D                              ;TEST FOR END OF LINE
        BNE     READ3                             ;KEEP READING
        LBSR    INSERT                            ;INSERT LINE
        BRA     READ2                             ;AND GO AGAIN,
;* '?' QUERY FILE
QUERY
        CMPA    #'?'                              ;IS IT QUERY?
        BNE     DOSCMD                            ;NO, TRY NEXT
        LDY     #TEXT                             ;POINT TO START
        LDX     #0                                ;INDICATE NUMBER OF LINE
QUE1
        LDA     ,Y+
        BMI     QUE2                              ;GET OUT ON END OF FILE
        CMPA    #$0D                              ;IS IT A NEW LINE
        BNE     QUE1                              ;NO, KEEP LOOKING
        LEAX    1,X                               ;ADVANCE
        BRA     QUE1                              ;AND KEEP LOOKING
QUE2
        LEAY    -1,Y                              ;BACKUP TO EOF MARKER
        TFR     Y,D                               ;COPY TO D
        SUBD    #TEXT                             ;CONVERT TO SIMPLE NUMBER
        SWI
        FCB     26                                ;DISPLAY IN DECIMAL
        SWI
        FCB     24
        FCN     ' bytes, '
        TFR     X,D                               ;COPY NUMBER OF LINES
        SWI
        FCB     26                                ;DISPLAY
        SWI
        FCB     25
        FCN     ' lines'
        BRA     GOCMD2                            ;GET NEXT COMMAND
;* EXECUTE DOS COMMAND
DOSCMD
        CMPA    #'*'                              ;IS IT DOS COMMAND?
        BNE     AUTCMD                            ;NO, TRY NEXT
        LBSR    UCASE                             ;CONVERT TO UPPER CASE
        PSHS    U                                 ;SAVE TEXT POINTER
        SWI
        FCB     100                               ;EXECUTE COMMAND
        PULS    U                                 ;RESTORE POINTER
        BRA     GOCMD2                            ;BACK FOR NEXT COMMAND
;* SET AUTOMATIC COMMAND
AUTCMD
        CMPA    #'$'                              ;SET AUTO?
        BNE     SAVREST                           ;NO, TRY NEXT
        LDX     #AUTSTR                           ;POINT TO STRING
AUT1
        LDA     ,Y+                               ;GET STRING
        STA     ,X+                               ;SAVE
        CMPA    #$0D                              ;END OF LINE?
        BNE     AUT1                              ;CONTINUE
GOCMD2
        LBRA    GOCMD                             ;BACK FOR MORE
;* SAVE AND RESTORE
SAVREST
        CMPA    #':'                              ;IS IT COLON COMMAND
        BNE     UNCMD                             ;NO, TRY NEXT
        CMPB    #'S'                              ;IS IT A SAVE?
        BNE     REST1                             ;IS IT A REPEAT?
        STU     SAVPTR                            ;SAVE IT
        LBRA    GOCMD                             ;AND GET NEXT COMMAND
REST1
        CMPB    #'R'                              ;RESTORE
        BNE     UNCMDB                            ;NO, INDICATE WE ARE UPSET
        LDU     SAVPTR                            ;POINT TO SAVED LOCATION
        LEAU    1,U                               ;ADVANCE
        LBSR    BAK1                              ;POSITION TO START OF LINE
        LBRA    GODISP                            ;DISPLAY IT
;* DISPLAY VALUE FROM B ACCUMULATOR AS ERROR MESSAGE
UNCMDB
        TFR     B,A                               ;COPY
;* COMMAND WAS NOT RECOGNIZED
UNCMD
        SWI
        FCB     24
        FCB     $07
        FCN     '?EDIT: '
        LBSR    PUTCHR
        SWI
        FCB     22
        BRA     GCMD
;* BAD OPERAND
BADOPR
        SWI
        FCB     25
        FCN     'Bad operand.'
GCMD
        LBRA    GOCMD
;*
;* INSERT A LINE(Y) INTO THE TEXT
;*
INSERT
        CLRB                                      ;	START WITH ZERO
        PSHS    Y,U                               ;SAVE POINTERS
INS1
        LDA     ,Y+                               ;GET CHARACTER FROM LINE
        INCB                                      ;	ADVANCE COUNTER
        CMPA    #$0D                              ;IS IT CR?
        BNE     INS1                              ;NO, KEEP LOOKING
        BSR     FNDEOF                            ;LOCATE END OF FILE
        LEAX    B,U                               ;ADVANCE FOR REST
INS2
        LDA     ,-U                               ;SKIP BACK
        STA     ,-X                               ;SAVE BACK
        CMPU    2,S                               ;ARE WE OVER
        BHI     INS2                              ;CONTINUE
        PULS    Y,U                               ;RESTORE POSITION
INS3
        LDA     ,Y+                               ;GET CHAR
        STA     ,U+                               ;SAVE
        CMPA    #$0D                              ;END OF LINE?
        BNE     INS3                              ;NO, CONTINUE
        RTS
;*
;* DELETE A LINE FROM THE TEXT(U)
;*
DELETE
        PSHS    U                                 ;SAVE POINTER
        LBSR    ADVLIN                            ;ADVANCE A LINE
        LDX     ,S                                ;GET POINTER
DELI1
        LDA     ,U+                               ;GET CHAR FROM TEXT
        STA     ,X+                               ;SAVE IN RAM
        BPL     DELI1                             ;DO IT ALL
        PULS    U,PC                              ;GO HOME
;*
;* FINDS END OF FILE
;*
FNDEOF
        LDA     ,U+                               ;GET CHAR FROM FILE
        BPL     FNDEOF                            ;KEEP LOOKING
        RTS
;*
;* ADVANCE A LINE
;*
ADVLIN
        LDA     ,U+                               ;GET CHAR FROM LINE
        BMI     ADVEOF                            ;END OF FILE
        CMPA    #$0D                              ;END OF LINE?
        BNE     ADVLIN                            ;NO, KEEP LOOKING
        CLRA                                      ;	ZERO RET
        RTS
ADVEOF
        LEAU    -1,U                              ;BACKUP
        RTS
;*
;* BACKUP A LINE
;*
BAKLIN
        LEAU    -1,U                              ;BACK TO CR
BAK1
        CMPU    #TEXT                             ;ARE WE OVER
        BLO     BAKTOF                            ;AT TOP OF FILE
        BEQ     FNDTOP                            ;WE FOUND THE TOP
        LDA     ,-U                               ;GET CHAR
        CMPA    #$0D                              ;ARE WE OVER
        BNE     BAK1                              ;NO, KEEP LOOKING
        LEAU    1,U                               ;SKIP AHEAD
FNDTOP
        RTS
BAKTOF
        LDU     #TEXT
        LDA     #$FF                              ;SET M FLAG
        RTS
;*
;* DISPLAY A LINE
;*
DSPLIN
        PSHS    U                                 ;SAVE REG
        BSR     DSPADV                            ;DISPLAY
        PULS    U,PC
DSPADV
        TST     ,U                                ;END OF TEXT?
        BMI     DSPEOF                            ;IF SO, QUIT
        LDA     ,U+                               ;GET CHAR
        BSR     PUTCHR                            ;OUTPUT
        CMPA    #$0D                              ;END OF LINE
        BNE     DSPADV                            ;CONTINUE
LFCR
        LDA     #$0D                              ;CR
        BSR     PUTCHR
        LDA     #$0A                              ;LF
PUTCHR
        TST     QCMD                              ;QUIET?
        BEQ     PUTQC                             ;SKIP IT
        SWI
        FCB     33                                ;OUTPUT
PUTQC
        RTS
DSPEOF
        TST     QCMD
        BEQ     PUTQC
        SWI
        FCB     25
        FCN     'EOF:'
        RTS
;*
;* GET AN OPERAND
;*
GETOP1
        SWI
        FCB     4                                 ;ANYTHING ELSE?
        BEQ     DEFAU1                            ;DEFAULT TO ONE
        SWI
        FCB     8                                 ;GET NUMBER
        LBNE    GOCMD                             ;NO, SKIP OT
        TFR     X,D                               ;COPY TO D
        TSTA                                      ;	NON ZERO HIGH BYTE
        LBNE    BADOPR                            ;INVALID OPERAND
        RTS
DEFAU1
        LDD     #1                                ;ASSUME ONE
        RTS
;*
;* GET AN INPUT LINE FROM THE TERMINAL
;*
GETLFCR
        LBSR    LFCR                              ;NEW LINE
GETLIN
        LDY     #RAM                              ;POINT TO INPUT BUFFER
        CLRB                                      ;	START AT POSITION ZERO
        LDA     #'.'                              ;PROMPT
        LBSR    PUTCHR                            ;DISPLAY
GETL1
        TST     FCMD                              ;LOOK FOR FILE COMMAND
        BEQ     FINP                              ;FILE INPUT
        SWI
        FCB     34                                ;GET A CHARACTER
        CMPA    #$1B                              ;ESCAPE <AUTO COMMAND>
        BEQ     DOAUTO                            ;IF SO, HANDLE IT
        CMPA    #$08                              ;BACKSPACE?
        BEQ     DODEL
        CMPA    #$7F                              ;DELETE?
        BNE     NOTDEL                            ;NO, HANDLE AS USUAL
DODEL
        TSTB                                      ;	AT POSITION ZERO?
        BEQ     GETL1                             ;DO NOTHING
        DECB                                      ;	BACKUP
        SWI
        FCB     24                                ;DISPLAY MSG
        FCB     $08,$20,$08,0
        BRA     GETL1
FINP
        LBSR    READC                             ;READ A CHARACTER
        BNE     FINEOF                            ;FILE INPUT END OF FILE
NOTDEL
        LBSR    PUTCHR                            ;DISPLAY
        STA     B,Y                               ;SAVE IN BUFFER
        INCB                                      ;	ADVANCE
        BMI     GETLFCR                           ;OVERFLOW
        CMPA    #$0D                              ;ARE WE PAST
        BNE     GETL1                             ;GO AGAIN
INRT
        LBSR    LFCR
        RTS
DOAUTO
        LDX     #AUTSTR                           ;POINT TO AUTO STRING
DOAUT1
        LDA     ,X+                               ;GET CHAR FROM AUTO STRING
        STA     B,Y                               ;SAVE IN INPUT
        INCB                                      ;	ADVANCE
        CMPA    #$0D                              ;END OF LINE?
        BEQ     INRT                              ;IF SO, QUIT
        LBSR    PUTCHR                            ;DISPLAY
        BRA     DOAUT1                            ;CONTINUE
;* END OF FILE ON INPUT
FINEOF
        SWI
        FCB     25                                ;DISPLAY MESSAGE
        FCN     '?EOF?'
        LDA     #9                                ;RC=9
        SWI
        FCB     0
;* CONVERT INPUT BUFFER TO UPPER-CASE
UCASE
        TFR     Y,X                               ;COPY POINTER
UCASE0
        LDA     ,X+                               ;GET CHAR
        CMPA    #'A'+$20	<LC 'A'
        BLO     UCASE1                            ;OK
        CMPA    #'Z'+$20	>LC 'Z'
        BHI     UCASE1                            ;OK
        SUBA    #$20                              ;CONVERT TO UPPER
        STA     -1,X                              ;RESAVE
UCASE1
        CMPA    #$0D                              ;CR?
        BNE     UCASE0                            ;NO, KEEP CONVERTING
        RTS
;*
;* EXIT EDITOR, TERMINATE AND SAVE THE FILE
;*
EXIT
        LDY     #FILNAM                           ;POINT TO FILENAME
        SWI
        FCB     10                                ;GET IN BUFFER
        BSR     SAVFIL                            ;SAVE IT
        LBNE    GOCMD
        SWI
        FCB     0                                 ;EXIT
;* SAVE FILE USING BLOCK WRITE
SAVFIL
        LBSR    FNDEOF                            ;FIND END OF FILE
        LEAU    -1,U                              ;REDUCE BY ONE
        TFR     U,D                               ;SAVE
        SUBD    #TEXT                             ;GET SIZE OF FILE
        TFR     A,B                               ;COPY TO B
        CLRA                                      ;	ZERO HIGH BYTE
        LSRB                                      ;	512 BYTE BOUNDARIES
        INCB                                      ;	INCLUDE LAST SECTOR
        LDX     #TEXT                             ;POINT TO RAM BUFFER
        SWI
        FCB     54                                ;WRITE IT
        RTS
OPENR
        PSHS    U
        LDU     #SERBUF
        SWI
        FCB     55
        PULS    U,PC
OPENW
        PSHS    U
        LDU     #SERBUF
        SWI
        FCB     56
        PULS    U,PC
READC
        PSHS    U
        LDU     #SERBUF
        SWI
        FCB     59
        PULS    U,PC
WRITEC
        PSHS    U
        LDU     #SERBUF
        SWI
        FCB     61
        PULS    U,PC
CLOSE
        PSHS    U
        LDU     #SERBUF
        SWI
        FCB     57
        PULS    U,PC
;*
;* QUALIFIER TABLE
;*
QTABLE
        FCB     $82
        FCC     '/BATCH'
        FCB     $82
        FCC     '/QUIET'
        FCB     $80
QMAX            = 2                               ;MAX. NUMBER OF QUALIFIERS
;* EDITOR SWITCHES
FCMD
        FCB     $FF                               ;FILE COMMAND INPUT
QCMD
        FCB     $FF
