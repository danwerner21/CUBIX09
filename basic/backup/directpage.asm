        ORG     0

ENDFLG
        RMB     1                                 ; STOP/END FLAG: POSITIVE=STOP, NEG=END
CHARAC
        RMB     1                                 ; TERMINATOR FLAG 1
ENDCHR
        RMB     1                                 ; TERMINATOR FLAG 2
TMPLOC
        RMB     1                                 ; SCRATCH VARIABLE
IFCTR
        RMB     1                                 ; IF COUNTER - HOW MANY IF STATEMENTS IN A LINE
DIMFLG
        RMB     1                                 ; *DV* ARRAY FLAG 0=EVALUATE, 1=DIMENSIONING
VALTYP
        RMB     1                                 ; *DV* *PV TYPE FLAG: 0=NUMERIC, $FF=STRING
GARBFL
        RMB     1                                 ; *TV STRING SPACE HOUSEKEEPING FLAG
ARYDIS
        RMB     1                                 ; DISABLE ARRAY SEARCH: 00=ALLOW SEARCH
INPFLG
        RMB     1                                 ; *TV INPUT FLAG: READ=0, INPUT<>0
RELFLG
        RMB     1                                 ; *TV RELATIONAL OPERATOR FLAG
TEMPPT
        RMB     2                                 ; *PV TEMPORARY STRING STACK POINTER
LASTPT
        RMB     2                                 ; *PV ADDR OF LAST USED STRING STACK ADDRESS
TEMPTR
        RMB     2                                 ; TEMPORARY POINTER
TMPTR1
        RMB     2                                 ; TEMPORARY DESCRIPTOR STORAGE (STACK SEARCH)
FPA2
        RMB     4                                 ; FLOATING POINT ACCUMULATOR #2 MANTISSA
BOTSTK
        RMB     2                                 ; BOTTOM OF STACK AT LAST CHECK
TXTTAB
        RMB     2                                 ; *PV BEGINNING OF BASIC PROGRAM
VARTAB
        RMB     2                                 ; *PV START OF VARIABLES
ARYTAB
        RMB     2                                 ; *PV START OF ARRAYS
ARYEND
        RMB     2                                 ; *PV END OF ARRAYS (+1)
FRETOP
        RMB     2                                 ; *PV START OF STRING STORAGE (TOP OF FREE RAM)
STRTAB
        RMB     2                                 ; *PV START OF STRING VARIABLES
FRESPC
        RMB     2                                 ; UTILITY STRING POINTER
MEMSIZ
        RMB     2                                 ; *PV TOP OF STRING SPACE
OLDTXT
        RMB     2                                 ; SAVED LINE NUMBER DURING A "STOP"
BINVAL
        RMB     2                                 ; BINARY VALUE OF A CONVERTED LINE NUMBER
OLDPTR
        RMB     2                                 ; SAVED INPUT PTR DURING A "STOP"
TINPTR
        RMB     2                                 ; TEMPORARY INPUT POINTER STORAGE
DATTXT
        RMB     2                                 ; *PV 'DATA' STATEMENT LINE NUMBER POINTER
DATPTR
        RMB     2                                 ; *PV 'DATA' STATEMENT ADDRESS POINTER
DATTMP
        RMB     2                                 ; DATA POINTER FOR 'INPUT' & 'READ'
VARNAM
        RMB     2                                 ; *TV TEMP STORAGE FOR A VARIABLE NAME
VARPTR
        RMB     2                                 ; *TV POINTER TO A VARIABLE DESCRIPTOR
VARDES
        RMB     2                                 ; TEMP POINTER TO A VARIABLE DESCRIPTOR
RELPTR
        RMB     2                                 ; POINTER TO RELATIONAL OPERATOR PROCESSING ROUTINE
TRELFL
        RMB     1                                 ; TEMPORARY RELATIONAL OPERATOR FLAG BYTE
;* FLOATING POINT ACCUMULATORS #3,4 & 5 ARE MOSTLY
;* USED AS SCRATCH PAD VARIABLES.
;** FLOATING POINT ACCUMULATOR #3 :PACKED: ($40-$44)
V40
        RMB     1
V41
        RMB     1
V42
        RMB     1
V43
        RMB     1
V44
        RMB     1
;** FLOATING POINT ACCUMULATOR #4 :PACKED: ($45-$49)
V45
        RMB     1
V46
        RMB     1
V47
        RMB     1
V48
        RMB     2
;** FLOATING POINT ACCUMULATOR #5 :PACKED: ($4A-$4E)
V4A
        RMB     1
V4B
        RMB     2
V4D
        RMB     2
;** FLOATING POINT ACCUMULATOR #0
FP0EXP
        RMB     1                                 ; *PV FLOATING POINT ACCUMULATOR #0 EXPONENT
FPA0
        RMB     4                                 ; *PV FLOATING POINT ACCUMULATOR #0 MANTISSA
FP0SGN
        RMB     1                                 ; *PV FLOATING POINT ACCUMULATOR #0 SIGN
COEFCT
        RMB     1                                 ; POLYNOMIAL COEFFICIENT COUNTER
STRDES
        RMB     5                                 ; TEMPORARY STRING DESCRIPTOR
FPCARY
        RMB     1                                 ; FLOATING POINT CARRY BYTE
;** FLOATING POINT ACCUMULATOR #1
FP1EXP
        RMB     1                                 ; *PV FLOATING POINT ACCUMULATOR #1 EXPONENT
FPA1
        RMB     4                                 ; *PV FLOATING POINT ACCUMULATOR #1 MANTISSA
FP1SGN
        RMB     1                                 ; *PV FLOATING POINT ACCUMULATOR #1 SIGN
RESSGN
        RMB     1                                 ; SIGN OF RESULT OF FLOATING POINT OPERATION
FPSBYT
        RMB     1                                 ; FLOATING POINT SUB BYTE (FIFTH BYTE)
COEFPT
        RMB     2                                 ; POLYNOMIAL COEFFICIENT POINTER
LSTTXT
        RMB     2                                 ; CURRENT LINE POINTER DURING LIST
CURLIN
        RMB     2                                 ; *PV CURRENT LINE # OF BASIC PROGRAM, $FFFF = DIRECT
DEVCFW
        RMB     1                                 ; *TV TAB FIELD WIDTH
DEVLCF
        RMB     1                                 ; *TV TAB ZONE
DEVPOS
        RMB     1                                 ; *TV PRINT POSITION
DEVWID
        RMB     1                                 ; *TV PRINT WIDTH
RSTFLG
        RMB     1                                 ; *PV WARM START FLAG: $55=WARM, OTHER=COLD
RSTVEC
        RMB     2                                 ; *PV WARM START VECTOR - JUMP ADDRESS FOR WARM START
TOPRAM
        RMB     2                                 ; *PV TOP OF RAM
IKEYIM
        RMB     1                                 ; *TV INKEY$ RAM IMAGE
ZERO
        RMB     2                                 ; *PV DUMMY - THESE TWO BYTES ARE ALWAYS ZERO
;* THE FOLLOWING BYTES ARE MOVED DOWN FROM ROM
LPTCFW
        RMB     1                                 ; 16
LPTLCF
        RMB     1                                 ; 112
LPTWID
        RMB     1                                 ; 132
LPTPOS
        RMB     1                                 ; 0
EXECJP
        RMB     2                                 ; LB4AA
VAB
        RMB     1                                 ; = LOW ORDER FOUR BYTES OF THE PRODUCT
VAC
        RMB     1                                 ; = OF A FLOATING POINT MULTIPLICATION
VAD
        RMB     1                                 ; = THESE BYTES ARE USE AS RANDOM DATA
VAE
        RMB     1                                 ; = BY THE RND STATEMENT

;* EXTENDED BASIC VARIABLES
TRCFLG
        RMB     1                                 ; *PV TRACE FLAG 0=OFF ELSE=ON
USRADR
        RMB     2                                 ; *PV ADDRESS OF THE START OF USR VECTORS

;* EXTENDED BASIC SCRATCH PAD VARIABLES
VCF
        RMB     2
VD1
        RMB     2
VD3
        RMB     2
VD5
        RMB     2
VD7
        RMB     1
VD8
        RMB     1
VD9
        RMB     1
VDA
        RMB     1
SW3VEC
        RMB     3
SW2VEC
        RMB     3
SWIVEC
        RMB     3
NMIVEC
        RMB     3
IRQVEC
        RMB     3
FRQVEC
        RMB     3
USRJMP
        RMB     3                                 ; JUMP ADDRESS FOR BASIC'S USR FUNCTION
RVSEED
        RMB     1                                 ; * FLOATING POINT RANDOM NUMBER SEED EXPONENT
        RMB     4                                 ; * MANTISSA: INITIALLY SET TO $804FC75259

;**** USR FUNCTION VECTOR ADDRESSES (EX BASIC ONLY)
USR0
        RMB     2                                 ; USR 0 VECTOR
        RMB     2                                 ; USR 1
        RMB     2                                 ; USR 2
        RMB     2                                 ; USR 3
        RMB     2                                 ; USR 4
        RMB     2                                 ; USR 5
        RMB     2                                 ; USR 6
        RMB     2                                 ; USR 7
        RMB     2                                 ; USR 8
        RMB     2                                 ; USR 9
SAVFCB:
        RMB     2                                 ; POINTER FOR FCB


        ORG     $CE00
STRSTK
        RMB     8*5                               ; STRING DESCRIPTOR STACK
LINHDR
        RMB     2                                 ; LINE INPUT BUFFER HEADER
LINBUF
        RMB     LBUFMX+1                          ; BASIC LINE INPUT BUFFER
STRBUF
        RMB     41                                ; STRING BUFFER
