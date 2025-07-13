
;* DISPATCH TABLE FOR SECONDARY FUNCTIONS
;* TOKENS ARE PRECEEDED BY $FF
;* FIRST SET ALWAYS HAS ONE PARAMETER
FUNC_TAB
LAA29
        FDB     SGN                               ; SGN
        FDB     INT                               ; INT
        FDB     ABS                               ; ABS
        FDB     USRJMP                            ; USR
tag1a:
TOK_USR         EQU ((tag1a-FUNC_TAB)/2)+$7F
TOK_FF_USR      EQU ((tag1a-FUNC_TAB)/2)+$FF7F
        FDB     RND                               ; RND
        FDB     SIN                               ; SIN
        FDB     PEEK                              ; PEEK
        FDB     LEN                               ; LEN
        FDB     STR                               ; STR$
        FDB     VAL                               ; VAL
        FDB     ASC                               ; ASC
        FDB     CHR                               ; CHR$
        FDB     ATN                               ; ATN
        FDB     COS                               ; COS
        FDB     TAN                               ; TAN
        FDB     EXP                               ; EXP
        FDB     FIX                               ; FIX
        FDB     LOG                               ; LOG
        FDB     POS                               ; POS
        FDB     SQR                               ; SQR
        FDB     HEXDOL                            ; HEX$
;* LEFT, RIGHT AND MID ARE TREATED SEPARATELY
        FDB     LEFT                              ; LEFT$
tag1b
TOK_LEFT        EQU ((tag1b-FUNC_TAB)/2)+$7F
        FDB     RIGHT                             ; RIGHT$
        FDB     MID                               ; MID$
tag1c
TOK_MID         EQU ((tag1c-FUNC_TAB)/2)+$7F
;* REMAINING FUNCTIONS
        FDB     INKEY                             ; INKEY$
tag1d
TOK_INKEY       EQU ((tag1d-FUNC_TAB)/2)+$7F
        FDB     MEM                               ; MEM
        FDB     VARPT                             ; VARPTR
        FDB     INSTR                             ; INSTR
        FDB     STRING                            ; STRING$
tag1e
NUM_SEC_FNS     EQU (tag1e-FUNC_TAB)/2

;* THIS TABLE CONTAINS PRECEDENCES AND DISPATCH ADDRESSES FOR ARITHMETIC
;* AND LOGICAL OPERATORS - THE NEGATION OPERATORS DO NOT ACT ON TWO OPERANDS
;* S0 THEY ARE NOT LISTED IN THIS TABLE. THEY ARE TREATED SEPARATELY IN THE
;* EXPRESSION EVALUATION ROUTINE. THEY ARE:
;* UNARY NEGATION (-), PRECEDENCE &7D AND LOGICAL NEGATION (NOT), PRECEDENCE $5A
;* THE RELATIONAL OPERATORS < > = ARE ALSO NOT LISTED, PRECEDENCE $64.
;* A PRECEDENCE VALUE OF ZERO INDICATES END OF EXPRESSION OR PARENTHESES
;*
LAA51
        FCB     $79
        FDB     LB9C5                             ; +
        FCB     $79
        FDB     LB9BC                             ; -
        FCB     $7B
        FDB     LBACC                             ; *
        FCB     $7B
        FDB     LBB91                             ; /
        FCB     $7F
        FDB     L8489                             ; EXPONENTIATION
        FCB     $50
        FDB     LB2D5                             ; AND
        FCB     $46
        FDB     LB2D4                             ; OR

;* THIS IS THE RESERVED WORD TABLE
;* FIRST PART OF THE TABLE CONTAINS EXECUTABLE COMMANDS
LAA66
        FCC     "FO"                              ; 80
        FCB     $80+'R'
        FCC     "G"                               ; 81
        FCB     $80+'O'
TOK_GO          EQU $81
        FCC     "RE"                              ; 82
        FCB     $80+'M'
        FCB     ''+$80                            ; 83
        FCC     "ELS"                             ; 84
        FCB     $80+'E'
        FCC     "I"                               ; 85
        FCB     $80+'F'
        FCC     "DAT"                             ; 86
        FCB     $80+'A'
        FCC     "PRIN"                            ; 87
        FCB     $80+'T'
        FCC     "O"                               ; 88
        FCB     $80+'N'
        FCC     "INPU"                            ; 89
        FCB     $80+'T'
        FCC     "EN"                              ; 8A
        FCB     $80+'D'
        FCC     "NEX"                             ; 8B
        FCB     $80+'T'
        FCC     "DI"                              ; 8C
        FCB     $80+'M'
        FCC     "REA"                             ; 8D
        FCB     $80+'D'
        FCC     "RU"                              ; 8E
        FCB     $80+'N'
        FCC     "RESTOR"                          ; 8F
        FCB     $80+'E'
        FCC     "RETUR"                           ; 90
        FCB     $80+'N'
        FCC     "STO"                             ; 91
        FCB     $80+'P'
        FCC     "POK"                             ; 92
        FCB     $80+'E'
        FCC     "CON"                             ; 93
        FCB     $80+'T'
        FCC     "LIS"                             ; 94
        FCB     $80+'T'
        FCC     "CLEA"                            ; 95
        FCB     $80+'R'
        FCC     "NE"                              ; 96
        FCB     $80+'W'
        FCC     "EXE"                             ; 97
        FCB     $80+'C'
        FCC     "TRO"                             ; 98
        FCB     $80+'N'
        FCC     "TROF"                            ; 99
        FCB     $80+'F'
        FCC     "DE"                              ; 9A
        FCB     $80+'L'
        FCC     "DE"                              ; 9B
        FCB     $80+'F'
        FCC     "LIN"                             ; 9C
        FCB     $80+'E'
        FCC     "RENU"                            ; 9D
        FCB     $80+'M'
        FCC     "EDI"                             ; 9E
        FCB     $80+'T'
        FCC     "EXI"
        FCB     $80+'T'                           ; 9F
        FCC     "SAV"
        FCB     $80+'E'                           ; A0
        FCC     "LOA"
        FCB     $80+'D'                           ; A1


;* END OF EXECUTABLE COMMANDS. THE REMAINDER OF THE TABLE ARE NON-EXECUTABLE TOKENS
        FCC     "TAB"
        FCB     $80+'('
TOK_TAB         EQU $A2
        FCC     "T"
        FCB     $80+'O'
TOK_TO          EQU TOK_TAB+1
        FCC     "SU"
        FCB     $80+'B'
TOK_SUB         EQU TOK_TO+1
        FCC     "THE"
        FCB     $80+'N'
TOK_THEN        EQU TOK_SUB+1
        FCC     "NO"
        FCB     $80+'T'
TOK_NOT         EQU TOK_THEN+1
        FCC     "STE"
        FCB     $80+'P'
TOK_STEP        EQU TOK_NOT+1
        FCC     "OF"
        FCB     $80+'F'
TOK_OFF         EQU TOK_STEP+1
        FCB     '+'+$80
TOK_PLUS        EQU TOK_OFF+1
        FCB     '-'+$80
TOK_MINUS       EQU TOK_PLUS+1
        FCB     '*'+$80
TOK_TIMES      EQU TOK_MINUS+1
        FCB     '/'+$80
TOK_DIVIDE      EQU TOK_TIMES+1
        FCB     '^'+$80
TOK_POWER       EQU TOK_DIVIDE+1
        FCC     "AN"
        FCB     $80+'D'
TOK_AND         EQU TOK_POWER+1
        FCC     "O"
        FCB     $80+'R'
TOK_OR     EQU TOK_AND+1
        FCB     '>'+$80
TOK_GREATER     EQU TOK_OR+1
        FCB     '='+$80
TOK_EQUALS      EQU TOK_GREATER+1
        FCB     '<'+$80
TOK_LESS        EQU TOK_EQUALS+1
        FCC     "F"
        FCB     $80+'N'
TOK_FN          EQU TOK_LESS+1
        FCC     "USIN"
        FCB     $80+'G'
TOK_USING       EQU TOK_FN+1

;*
;* FIRST SET ALWAYS HAS ONE PARAMETER
LAB1A
        FCC     "SG"                              ; 80
        FCB     $80+'N'
        FCC     "IN"                              ; 81
        FCB     $80+'T'
        FCC     "AB"                              ; 82
        FCB     $80+'S'
        FCC     "US"                              ; 83
        FCB     $80+'R'
        FCC     "RN"                              ; 84
        FCB     $80+'D'
        FCC     "SI"                              ; 85
        FCB     $80+'N'
        FCC     "PEE"                             ; 86
        FCB     $80+'K'
        FCC     "LE"                              ; 87
        FCB     $80+'N'
        FCC     "STR"                             ; 88
        FCB     $80+'$'
        FCC     "VA"                              ; 89
        FCB     $80+'L'
        FCC     "AS"                              ; 8A
        FCB     $80+'C'
        FCC     "CHR"                             ; 8B
        FCB     $80+'$'
        FCC     "AT"                              ; 8C
        FCB     $80+'N'
        FCC     "CO"                              ; 8D
        FCB     $80+'S'
        FCC     "TA"                              ; 8E
        FCB     $80+'N'
        FCC     "EX"                              ; 8F
        FCB     $80+'P'
        FCC     "FI"                              ; 90
        FCB     $80+'X'
        FCC     "LO"                              ; 91
        FCB     $80+'G'
        FCC     "PO"                              ; 92
        FCB     $80+'S'
        FCC     "SQ"                              ; 93
        FCB     $80+'R'
        FCC     "HEX"                             ; 94
        FCB     $80+'$'
;* LEFT, RIGHT AND MID ARE TREATED SEPARATELY
        FCC     "LEFT"                            ; 95
        FCB     $80+'$'
        FCC     "RIGHT"                           ; 96
        FCB     $80+'$'
        FCC     "MID"                             ; 97
        FCB     $80+'$'
;* REMAINING FUNCTIONS
        FCC     "INKEY"                           ; 98
        FCB     $80+'$'
        FCC     "ME"                              ; 99
        FCB     $80+'M'
        FCC     "VARPT"                           ; 9A
        FCB     $80+'R'
        FCC     "INST"                            ; 9B
        FCB     $80+'R'
        FCC     "STRING"                          ; 9C
        FCB     $80+'$'

;*
;* DISPATCH TABLE FOR COMMANDS TOKEN #
CMD_TAB
LAB67
        FDB     FOR                               ; 80
        FDB     GO                                ; 81
        FDB     REM                               ; 82
tag1f
TOK_REM         EQU ((tag1f-CMD_TAB)/2)+$7F
        FDB     REM                               ; 83 (')
tag1g
TOK_SNGL_Q      EQU ((tag1g-CMD_TAB)/2)+$7F
        FDB     REM                               ; 84 (ELSE)
tag1h
TOK_ELSE        EQU ((tag1h-CMD_TAB)/2)+$7F
        FDB     IF                                ; 85
tag1i
TOK_IF          EQU ((tag1i-CMD_TAB)/2)+$7F
        FDB     DATA                              ; 86
tag1j
TOK_DATA        EQU ((tag1j-CMD_TAB)/2)+$7F
        FDB     PRINT                             ; 87
tag1k
TOK_PRINT       EQU ((tag1k-CMD_TAB)/2)+$7F
        FDB     ON                                ; 88
        FDB     INPUT                             ; 89
tag1l
TOK_INPUT       EQU ((tag1l-CMD_TAB)/2)+$7F
        FDB     END                               ; 8A
        FDB     NEXT                              ; 8B
        FDB     DIM                               ; 8C
        FDB     READ                              ; 8D
        FDB     RUN                               ; 8E
        FDB     RESTOR                            ; 8F
        FDB     RETURN                            ; 90
        FDB     STOP                              ; 91
        FDB     POKE                              ; 92
        FDB     CONT                              ; 93
        FDB     LIST                              ; 94
        FDB     CLEAR                             ; 95
        FDB     NEW                               ; 96
        FDB     EXEC                              ; 97
        FDB     TRON                              ; 98
        FDB     TROFF                             ; 99
        FDB     DEL                               ; 9A
        FDB     DEF                               ; 9B
        FDB     LINE                              ; 9C
        FDB     RENUM                             ; 9D
        FDB     EDIT                              ; 9E
        FDB     EXIT                              ; 9F
        FDB     SAVE                              ; A0
        FDB     LOAD                              ; A1
tag1m
TOK_HIGH_EXEC   EQU ((tag1m-CMD_TAB)/2)+$7F
;
;* ERROR MESSAGES AND THEIR NUMBERS AS USED INTERNALLY
LABAF
        FCC     "NF"                              ; 0 NEXT WITHOUT FOR
        FCC     "SN"                              ; 1 SYNTAX ERROR
        FCC     "RG"                              ; 2 RETURN WITHOUT GOSUB
        FCC     "OD"                              ; 3 OUT OF DATA
        FCC     "FC"                              ; 4 ILLEGAL FUNCTION CALL
        FCC     "OV"                              ; 5 OVERFLOW
        FCC     "OM"                              ; 6 OUT OF MEMORY
        FCC     "UL"                              ; 7 UNDEFINED LINE NUMBER
        FCC     "BS"                              ; 8 BAD SUBSCRIPT
        FCC     "DD"                              ; 9 REDIMENSIONED ARRAY
        FCC     "/0"                              ; 10 DIVISION BY ZERO
        FCC     "ID"                              ; 11 ILLEGAL DIRECT STATEMENT
        FCC     "TM"                              ; 12 TYPE MISMATCH
        FCC     "OS"                              ; 13 OUT OF STRING SPACE
        FCC     "LS"                              ; 14 STRING TOO LONG
        FCC     "ST"                              ; 15 STRING FORMULA TOO COMPLEX
        FCC     "CN"                              ; 16 CAN'T CONTINUE
        FCC     "FD"                              ; 17 BAD FILE DATA
        FCC     "AO"                              ; 18 FILE ALREADY OPEN
        FCC     "DN"                              ; 19 DEVICE NUMBER ERROR
        FCC     "IO"                              ; 20 I/O ERROR
        FCC     "FM"                              ; 21 BAD FILE MODE
        FCC     "NO"                              ; 22 FILE NOT OPEN
        FCC     "IE"                              ; 23 INPUT PAST END OF FILE
        FCC     "DS"                              ; 24 DIRECT STATEMENT IN FILE
;* ADDITIONAL ERROR MESSAGES ADDED BY EXTENDED BASIC
L890B
        FCC     "UF"                              ; 25 UNDEFINED FUNCTION (FN) CALL
L890D
        FCC     "NE"                              ; 26 FILE NOT FOUND

LABE1
        FCC     " ERROR"
        FCB     $00
LABE8
        FCC     " IN "
        FCB     $00
LABED
        FCB     CR
LABEE
        FCC     "OK"
        FCB     CR,$00
LABF2
        FCB     CR
        FCC     "BREAK"
        FCB     $00
