;PAGE
;SBTTL "--- MEMORY ORGANIZATION ---"

TRUE            = $FF
FALSE           = 0

DSTART          = 0                               ; START OF DIRECT-PAGE RAM

MSTACK          = MSTART+$FE                      ; TOP OF MACHINE STACK (254 BYTES)
IOBUFF          = MSTART+$100                     ; 256-BYTE DISK I/O BUFFER
ZSTACK          = MSTART+$200                     ; Z-STACK (255 WORDS)
ZSTAKL          = 255                             ; LENGTH OF Z-STACK IN WORDS
TOPSTA          = (2*ZSTAKL)+ZSTACK               ; TOP OF Z-STACK
PTABLE          = MSTART+$400                     ; PAGING TABLE ($140 BYTES/$A0 WORDS)
LRUMAP          = MSTART+$550                     ; TIMESTAMP MAP ($A0 BYTES)
LOCALS          = MSTART+$600                     ; LOCAL VARIABLE STORAGE (32 BYTES)
BUFFER          = MSTART+$620                     ; I/O LINE BUFFER (32 BYTES)
BUFSAV          = MSTART+$640                     ; I/O AUX BUFFER (32 BYTES)
ZIP             = MSTART+$700                     ; START OF EXECUTABLE CODE
ZCODE           = ZIP+$1700                       ; START OF Z-CODE (ASSUME 5.75K ZIP)

; Z-CODE HEADER OFFSETS

ZVERS           = 0                               ; VERSION BYTE
ZMODE           = 1                               ; MODE SELECT BYTE
ZID             = 2                               ; GAME ID WORD
ZENDLD          = 4                               ; START OF NON-PRELOADED Z-CODE
ZBEGIN          = 6                               ; EXECUTION ADDRESS
ZVOCAB          = 8                               ; START OF VOCABULARY TABLE
ZOBJEC          = 10                              ; START OF OBJECT TABLE
ZGLOBA          = 12                              ; START OF GLOBAL VARIABLE TABLE
ZPURBT          = 14                              ; START OF "PURE" Z-CODE
ZSCRIP          = 16                              ; FLAG WORD
ZSERIA          = 18                              ; 3-WORD ASCII SERIAL NUMBER
ZFWORD          = 24                              ; START OF FWORDS TABLE
ZLENTH          = 26                              ; LENGTH OF Z-PROGRAM IN WORDS
ZCHKSM          = 28                              ; Z-CODE CHECKSUM WORD

;	SBTTL "--- ZIP D-PAGE VARIABLES ---"

OPCODE          = DSTART                          ; CURRENT OPCODE
ARGCNT          = OPCODE+1                        ; # ARGUMENTS
ARG1            = OPCODE+2                        ; ARGUMENT #1 (WORD)
ARG2            = OPCODE+4                        ; ARGUMENT #2 (WORD)
ARG3            = OPCODE+6                        ; ARGUMENT #3 (WORD)
ARG4            = OPCODE+8                        ; ARGUMENT #4 (WORD)

LRU             = OPCODE+10                       ; (BYTE) LEAST RECENTLY USED PAGE INDEX
ZPURE           = LRU+1                           ; (BYTE) 1ST VIRTUAL PAGE OF PURE Z-CODE
PMAX            = LRU+2                           ; (BYTE) MAXIMUM # SWAPPING PAGES
ZPAGE           = LRU+3                           ; (BYTE) CURRENT SWAPPING PAGE
PAGE0           = LRU+4                           ; (BYTE) 1ST ABS PAGE OF SWAPPING SPACE
TABTOP          = LRU+5                           ; (WORD) ADDRESS OF LAST P-TABLE ENTRY
STAMP           = LRU+7                           ; (BYTE) CURRENT TIMESTAMP (BM 11/24/84)
SWAP            = LRU+8                           ; (BYTE) EARLIEST BUFFER (BM 11/24/84)

ZPCH            = LRU+9                           ; HIGHEST-ORDER BIT OF PC
ZPCM            = ZPCH+1                          ; MIDDLE 8 BITS OF PC
ZPCL            = ZPCH+2                          ; LOWER 8 BITS OF PC
ZPCPNT          = ZPCH+3                          ; POINTER TO ACTUAL PC PAGE (WORD)
ZPCFLG          = ZPCH+5                          ; FLAG: "TRUE" IF ZPCPNT VALID

MPCH            = ZPCH+7                          ; HIGHEST-ORDER BIT OF MEM POINTER
MPCM            = MPCH+1                          ; MIDDLE 8 BITS OF MEM POINTER
MPCL            = MPCH+2                          ; LOW-ORDER 8 BITS OF MEMORY POINTER
MPCPNT          = MPCH+3                          ; ACTUAL POINTER TO MEMORY (WORD)
MPCFLG          = MPCH+5                          ; FLAG: "TRUE" IF MPCPNT VALID

GLOBAL          = MPCH+7                          ; GLOBAL VARIABLE POINTER (WORD)
VOCAB           = GLOBAL+2                        ; VOCAB TABLE POINTER (WORD)
FWORDS          = GLOBAL+4                        ; FWORDS TABLE POINTER (WORD)

OZSTAK          = GLOBAL+6                        ; ZSP SAVE REGISTER (FOR ZCALL)

CSTEMP          = OZSTAK+2                        ; SET IF TEMP CHARSET IN EFFECT
CSPERM          = CSTEMP+1                        ; CURRENT PERM CHARSET
STBYTF          = CSTEMP+2                        ; 0=1ST, 1=2ND, 2=3RD, 0=LAST

ZSTWRD          = CSTEMP+3                        ; WORD STORAGE (WORD)
ZSTBUI          = ZSTWRD+2                        ; Z-STRING INPUT BUFFER (6 BYTES)
ZSTBUO          = ZSTWRD+8                        ; Z-STRING OUTPUT BUFFER (6 BYTES)
RTABP           = ZSTWRD+14                       ; RESULT TABLE POINTER
STABP           = ZSTWRD+15                       ; SOURCE TABLE POINTER
PZSTFO          = ZSTWRD+16                       ; FWORD TABLE BLOCK OFFSET

VAL             = ZSTWRD+17                       ; VALUE RETURN REGISTER (WORD)
TEMP            = VAL+2                           ; TEMPORARY REGISTER (WORD)
TEMP2           = VAL+4                           ; ANOTHER TEMPORARY REGISTER (WORD)
MASK            = VAL+6                           ; BIT-MASK REGISTER (WORD)
SQUOT           = VAL+8                           ; SIGN OF QUOTIENT
SREM            = VAL+9                           ; SIGN OF REMAINDER
MTEMP           = VAL+10                          ; MATH TEMP REGISTER (WORD)

DRIVE           = VAL+12                          ; DRIVE NUMBER
DBUFF           = DRIVE+1                         ; DISK I/O BUFFER POINTER (WORD)
DBLOCK          = DRIVE+3                         ; Z-BLOCK # (WORD)
TRACK           = DRIVE+5                         ; TRACK/SECTOR ADDRESS (WORD)

TIMEFL          = DRIVE+7                         ; "TRUE" IF TIME MODE

CHRPNT          = TIMEFL+1                        ; I/O BUFFER INDEX
CPSAV           = CHRPNT+1                        ; SAVE REGISTER FOR [CHRPNT]
BINDEX          = CHRPNT+2                        ; BUFFER DISPLAY INDEX
LINCNT          = CHRPNT+3                        ; # LINES DISPLAYED SINCE LAST USL
IOCHAR          = CHRPNT+4                        ; CURRENT I/O CHARACTER
GDRIVE          = CHRPNT+5                        ; GAME-SAVE DEFAULT DRIVE #
GPOSIT          = CHRPNT+6                        ; GAME-SAVE DEFAULT POSITION
RAND1           = CHRPNT+7                        ; RANDOM NUMBER REGISTER
RAND2           = CHRPNT+8                        ; DITTO
CYCLE           = CHRPNT+9                        ; TIMER FOR CURSOR BLINK (WORD)
BLINK           = CHRPNT+11                       ; MASK FOR CURSOR BLINK
CFLAG           = CHRPNT+12                       ; CURSOR ENABLE FLAG
SCRIPT          = CHRPNT+13                       ; SCRIPTING ENABLE FLAG
IHOLD           = CHRPNT+14                       ; INTERRUPT HOLD
TPOSIT          = CHRPNT+15                       ; TEMP GAME POSITION
TDRIVE          = CHRPNT+16                       ; TEMP GAME DRIVE

ZPGTOP          = CHRPNT+15                       ; END OF DIRECT-PAGE VARIABLES
