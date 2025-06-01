;	PAGE
;	SBTTL "--- WARMSTART ROUTINE ---"

        SETDP   0
        ORG     ZIP                               ; START OF EXECUTABLE CODE

        CLRA                                      ; USE PAGE ZERO
        TFR     A,DP                              ; AS THE DIRECT PAGE

IRQVEC          EQU $10C

        LDX     #DIRQSV                           ;SET VECTOR
        STX     IRQVEC+1
        LDA     #$7E                              ;JMP OP
        STA     IRQVEC

;	ORCC	#%01010000	; DISABLE INTERRUPTS
; 	LDA	INT60		; DISABLE
;	ANDA	#%11111110	; THE 60HZ
        STA     INT60                             ; INTERRUPT
        STA     ROMOFF                            ; AND THE ROMS
        LDS     #MSTACK                           ; GIVE THE STACK A NEW HOME
        JMP     COLD                              ; PERFORM ONE-TIME INITIALIZATION

; WARMSTART ENTRY

START:
        LDS     #MSTACK                           ; RESET MACHINE STACK


; TEST TO SEE IF ZIP IS ALL LOADED

        LDX     #3
TSTEND:
        LDA     ENDTST-1,X
        CMPA    ENDCMP-1,X
        BNE     ENDERR
        LEAX    -1,X
        BNE     TSTEND
        BRA     ENDOK
ENDERR:
        LDA     #16
        JMP     ZERROR                            ;

ENDCMP:
        FCN      'END'

; CLEAR ALL DIRECT-PAGE VARIABLES

ENDOK:
        LDX     #DSTART
ST0:
        CLR     ,X+
        CMPX    #ZPGTOP
        BLO     ST0

        INC     STAMP                             ; INIT TIMESTAMP TO 1 (BM 11/24/84)

; RESET THE PAGING TABLE

        LDX     #PTABLE
        LDA     #$FF
ST1A:
        STA     ,X+
        CMPX    #PTABLE+$140
        BLO     ST1A

; CLEAR THE TIMESTAMP MAP (BM 11/24/84)

        LDX     #LRUMAP
ST1B:
        CLR     ,X+
        CMPX    #LRUMAP+$A0
        BLO     ST1B

; GET THE FIRST SECTOR OF Z-CODE

        LDD     #ZCODE                            ; POINT TO 1ST
        STD     DBUFF                             ; Z-CODE LOCATION
        JSR     GETDSK                            ; FETCH BLOCK #0 FROM DRIVE 0

; EXTRACT GAME DATA FROM Z-CODE HEADER

        LDA     ZCODE+ZENDLD                      ; GET MSB OF ENDLOAD POINTER
        INCA                                      ; ADD ONE TO GET
        STA     ZPURE                             ; 1ST PAGE IN "PURE" CODE
        ADDA    #HIGH ZCODE                       ; ADD BASE ADDRESS TO GET
        STA     PAGE0                             ; 1ST PAGE OF SWAPPING SPACE

        LDB     #MEMTOP                           ; TOP PAGE OF MEMORY
        SUBB    PAGE0                             ; SUBTRACT ADDRESS OF PAGING BUFFER
        BLS     NORAM
        CMPB    #8
        BHS     SETNP                             ; MUST HAVE AT LEAST 8 SWAPPING PAGES

; *** ERROR #0 -- INSUFFICIENT RAM ***

NORAM:
        CLRA
        JSR     ZERROR

; [B] HAS # FREE SWAPPING PAGES

SETNP:
        CMPB    #$A0                              ; MAKE SURE # PAGES
        BLO     SETA0                             ; DOESN'T EXCEED
        LDB     #$A0                              ; $A0 (BM 11/24/84)
SETA0:
        STB     PMAX                              ; SET MAXIMUM # FREE PAGES
        LDX     #PTABLE                           ; ADD BASE ADDR OF P-TABLE
        ABX                                       ; TO PAGING LIMIT
        ABX                                       ; TWICE (FOR WORD-ALIGNMENT)
        STX     TABTOP                            ; TO GET ADDR OF HIGHEST TABLE ENTRY

        LDA     ZCODE+ZMODE                       ; GET MODE BYTE
        ORA     #%00001000                        ; SET THE "TANDY" ID BIT
        STA     ZCODE+ZMODE                       ; (WE DON'T WANT ANY DIRTY WORDS)
        ANDA    #%00000010                        ; ISOLATE STAT-LINE FORMAT BIT
        STA     TIMEFL                            ; 0=SCORE/MOVES, NZ=HOURS/MINUTES

        LDD     ZCODE+ZBEGIN                      ; GET START ADDRESS OF Z-CODE
        STD     ZPCM                              ; HIGH BITS AT ZPCH ALREADY CLEARED

        LDD     ZCODE+ZGLOBA                      ; GET RELATIVE ADDR OF GLOBAL TABLE
        ADDD    #ZCODE                            ; CONVERT TO ABSOLUTE ADDRESS
        STD     GLOBAL

        LDD     ZCODE+ZFWORD                      ; DO SAME FOR FWORDS TABLE
        ADDD    #ZCODE
        STD     FWORDS

        LDD     ZCODE+ZVOCAB                      ; AND VOCABULARY TABLE
        ADDD    #ZCODE
        STD     VOCAB

; GRAB THE REST OF THE PRELOAD

        LDA     ZPURE                             ; GET # PAGES IN PRELOAD + 1
        STA     TEMP                              ; USE AS AN INDEX
LDPRE:
        JSR     GETDSK                            ; GRAB THE BLOCK
        DEC     TEMP
        BNE     LDPRE                             ; KEEP READING TILL DONE

        LDU     #TOPSTA                           ; INIT THE ZSP
        STU     OZSTAK                            ; REMEMBER ITS POSITION

        JSR     CLS                               ; CLEAR THE SCREEN
        COM     SCRIPT                            ; ENABLE SCRIPTING

        LDA     SFLAG                             ; SCRIPTING FLAG
        STA     ZCODE+ZSCRIP+1

; FALL INTO MAIN LOOP

        END
