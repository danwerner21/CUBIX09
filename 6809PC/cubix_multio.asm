;__MULTI IO DRIVERS______________________________________________________________________________________________________________
;
; 	CUBIX ISA MULTI IO drivers for 6809PC
;
;	Entry points:
;		MULTIOINIT  - JSR ed during OS init
;		KBD_GETKEY  - read a character from the ps/2 keyboard ('A' POINTS TO BYTE)
;		LPT_OUT	    - send a character to the printer
;________________________________________________________________________________________________________________________________
;
;*
;*        HARDWARE I/O ADDRESSES
;*
;
MULTIO_BASE     EQU CUBIX_IO_BASE+$3E0
KBD_DAT         EQU MULTIO_BASE+$1E               ;
KBD_ST          EQU MULTIO_BASE+$1F               ;
KBD_CMD         EQU MULTIO_BASE+$1F               ;

LPT_0           EQU MULTIO_BASE+$10               ;
LPT_1           EQU MULTIO_BASE+$11               ;
LPT_2           EQU MULTIO_BASE+$12               ;



;__________________________________________________________________________________________________
;
; STATUS BITS (FOR KBD_STATUS)
;
KBD_EXT         EQU $01                           ; BIT 0, EXTENDED SCANCODE ACTIVE
KBD_BREAK       EQU $02                           ; BIT 1, THIS IS A KEY UP (BREAK) EVENT
KBD_KEYRDY      EQU $80                           ; BIT 7, INDICATES A DECODED KEYCODE IS READY
;
; STATE BITS (FOR KBD_STATE, KBD_LSTATE, KBD_RSTATE)
;
KBD_SHIFT       EQU $01                           ; BIT 0, SHIFT ACTIVE (PRESSED)
KBD_CTRL        EQU $02                           ; BIT 1, CONTROL ACTIVE (PRESSED)
KBD_ALT         EQU $04                           ; BIT 2, ALT ACTIVE (PRESSED)
KBD_WIN         EQU $08                           ; BIT 3, WIN ACTIVE (PRESSED)
KBD_SCRLCK      EQU $10                           ; BIT 4, CAPS LOCK ACTIVE (TOGGLED ON)
KBD_NUMLCK      EQU $20                           ; BIT 5, NUM LOCK ACTIVE (TOGGLED ON)
KBD_CAPSLCK     EQU $40                           ; BIT 6, SCROLL LOCK ACTIVE (TOGGLED ON)
KBD_NUMPAD      EQU $80                           ; BIT 7, NUM PAD KEY (KEY PRESSED IS ON NUM PAD)
;
KBD_DEFRPT      EQU $40                           ; DEFAULT REPEAT RATE (.5 SEC DELAY, 30CPS)
KBD_DEFSTATE    EQU KBD_NUMLCK|KBD_CAPSLCK|KBD_SCRLCK ; DEFAULT STATE (NUM LOCK ON)

KBD_WAITTO      EQU $30FF                         ; DEFAULT TIMEOUT
LPT_WAITTO      EQU $30FF                         ; DEFAULT TIMEOUT
;
;__________________________________________________________________________________________________
; DATA
;__________________________________________________________________________________________________
;
KBD_SCANCODE
        FCB     0                                 ; RAW SCANCODE
KBD_KEYCODE
        FCB     0                                 ; RESULTANT KEYCODE AFTER DECODING
KBD_STATE
        FCB     KBD_DEFSTATE                      ; STATE BITS (SEE ABOVE)
KBD_LSTATE
        FCB     0                                 ; STATE BITS FOR "LEFT" KEYS
KBD_RSTATE
        FCB     0                                 ; STATE BITS FOR "RIGHT" KEYS
KBD_STATUS
        FCB     0                                 ; CURRENT STATUS BITS (SEE ABOVE)
KBD_REPEAT
        FCB     KBD_DEFRPT                        ; CURRENT REPEAT RATE
KBD_IDLE
        FCB     0                                 ; IDLE COUNT
KBD_TEMP
        FCB     0,0                               ; WORKING STORAGE

;
;  IBM PC STANDARD PARALLEL PORT (SPP):
;
;  PORT 0 (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | PD7   | PD6   | PD5   | PD4   | PD3   | PD2   | PD1   | PD0   |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  PORT 1 (INPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | /BUSY | /ACK  | POUT  | SEL   | /ERR  | 0     | 0     | 0     |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;  PORT 2 (OUTPUT):
;
;	D7	D6	D5	D4	D3	D2	D1	D0
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;     | STAT1 | STAT0 | ENBL  | PINT  | SEL   | RES   | LF    | STB   |
;     +-------+-------+-------+-------+-------+-------+-------+-------+
;
;
;__________________________________________________________________________________________________
; MULTI IO INITIALIZATION
;__________________________________________________________________________________________________
;
MULTIOINIT:
;
        JSR     LFCR                              ; AND CRLF
        LDX     #MIOMESSAGE1
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF
; KEYBOARD INITIALIZATION
        LDX     #MESSAGE2
        JSR     WRSTR                             ; DO PROMPT
        LDD     #MULTIO_BASE                      ; GET BASE PORT
        JSR     WRHEXW                            ; PRINT BASE PORT
        JSR     LFCR                              ; AND CRLF
;
        JSR     KBD_PROBE                         ; DETECT A KEYBOARD, ABORT IF NOT FOUND
        BCS     >
; LPT INITIALIZATION ROUTINE
        LDX     #MIOMESSAGE5
        JSR     WRSTR                             ; DO PROMPT
        JSR     LFCR                              ; AND CRLF

        LDA     #$00
        STA     LPT_0   		; PORT 0 (DATA)
	LDA     #%00001000		; SELECT AND ASSERT RESET, LEDS OFF
        STA     LPT_2   		; PORT 2 (STATUS)
	JSR	LDELAY			; HALF SECOND DELAY
	LDA	#%00001100		; SELECT AND DEASSERT RESET, LEDS OFF
	STA     LPT_2   		; PORT 2 (STATUS)
	CLC				; SIGNAL SUCCESS
	RTS				; RETURN
!
        SEC
        RTS                                       ; DONE


KBD_PROBE:
;
        LDA     #$AA                              ; CONTROLLER SELF TEST
        JSR     KBD_PUTCMD                        ; SEND IT
        JSR     KBD_GETDATA                       ; CONTROLLER SHOULD RESPOND WITH $55 (ACK)
;
        CMPA    #$55                              ; IS IT THERE?
        BEQ     >                                 ; IF SO, CONTINUE
        LDX     #MIOMESSAGE3                      ; PRINT NOT PRESENT ERROR
        JSR     WRSTR
        JSR     LFCR                              ; AND CRLF
;
        SEC                                       ; SET ERROR
        RTS                                       ; BAIL OUT
;
!
        LDX     #MIOMESSAGE4                      ; PRINT KB FOUND
        JSR     WRSTR
        JSR     LFCR                              ; AND CRLF

;
        LDA     #$60                              ; SET COMMAND REGISTER
        JSR     KBD_PUTCMD                        ; SEND IT
        LDA     #$20                              ; XLAT DISABLED, MOUSE DISABLED, NO INTS
        JSR     KBD_PUTDATA                       ; SEND IT

        JSR     KBD_GETDATA                       ; GOBBLE UP $AA FROM POWER UP, AS NEEDED

        JSR     KBD_RESET                         ; RESET THE KEYBOARD
        JSR     KBD_SETLEDS                       ; UPDATE LEDS BASED ON CURRENT TOGGLE STATE BITS
        JSR     KBD_SETRPT                        ; UPDATE REPEAT RATE BASED ON CURRENT SETTING

        CLC                                       ; SIGNAL SUCCESS
        RTS


;
;__________________________________________________________________________________________________
; HARDWARE INTERFACE
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
KBD_PUTCMD:
; PUT A CMD BYTE FROM A TO THE KEYBOARD INTERFACE WITH TIMEOUT
;
        LDX     #KBD_WAITTO                       ; SETUP TO LOOP
KBD_PUTCMD0:
        LDB     KBD_ST                            ; STATUS PORT
        ANDB    #$02                              ; ISOLATE EMPTY BIT
        BEQ     KBD_PUTCMD1                       ; EMPTY, GO TO WRITE
        JSR     DELAY                             ; WAIT A BIT
        DEX
        BNE     KBD_PUTCMD0                       ; LOOP UNTIL COUNTER EXHAUSTED

        SEC                                       ; TIMED OUT
        RTS
KBD_PUTCMD1:
        STA     KBD_CMD                           ; WRITE TO COMMAND PORT

        CLC                                       ; SIGNAL SUCCESS
        RTS
;
;__________________________________________________________________________________________________
KBD_PUTDATA:
;
; PUT A DATA BYTE FROM A TO THE KEYBOARD INTERFACE WITH TIMEOUT
;
        LDX     #KBD_WAITTO                       ; SETUP TO LOOP
KBD_PUTDATA0:
        LDB     KBD_ST                            ; STATUS PORT
        ANDB    #$02                              ; ISOLATE OUTPUT EMPTY BIT
        BEQ     KBD_PUTDATA1                      ; EMPTY, GO TO WRITE
        JSR     DELAY                             ; WAIT A BIT
        DEX
        BNE     KBD_PUTDATA0                      ; LOOP UNTIL COUNTER EXHAUSTED

        SEC                                       ; TIMED OUT
        RTS
KBD_PUTDATA1:
        STA     KBD_DAT                           ; WRITE TO DATA PORT

        CLC                                       ; SIGNAL SUCCESS
        RTS
;
;__________________________________________________________________________________________________
KBD_GETDATA:
;
; GET A RAW DATA BYTE FROM KEYBOARD INTERFACE INTO A WITH TIMEOUT
;
        LDX     #KBD_WAITTO                       ; SETUP TO LOOP
KBD_GETDATA0:
        LDA     KBD_ST                            ; GET STATUS PORT
        ANDA    #$01                              ; ISOLATE INPUT PENDING BIT
        BNE     KBD_GETDATA1                      ; READY, GET DATA
        JSR     DELAY                             ; WAIT A BIT
        DEX
        BNE     KBD_GETDATA0                      ; LOOP UNTIL COUNTER EXHAUSTED
        LDA     #$00

        SEC                                       ; NO DATA, RETURN ZERO
        RTS
KBD_GETDATA1:

        LDA     KBD_DAT                           ; GET DATA PORT
        CLC                                       ; SET FLAGS
        RTS
;
;__________________________________________________________________________________________________
KBD_GETDATAX:
;
; GET A RAW DATA BYTE FROM KEYBOARD INTERFACE INTO A WITH NOTIMEOUT
;
        LDA     KBD_ST                            ; STATUS PORT
        ANDA    #$01                              ; ISOLATE INPUT PENDING BIT
        BNE     KBD_GETDATA1                      ; BYTE PENDING, GO GET IT
        LDA     #$00

        SEC                                       ; NO DATA, RETURN ZERO
        RTS
;
;__________________________________________________________________________________________________
; RESET KEYBOARD
;__________________________________________________________________________________________________
;
KBD_RESET:
        LDA     #$FF                              ; RESET COMMAND
        JSR     KBD_PUTDATA                       ; SEND IT
        JSR     KBD_GETDATA                       ; GET THE ACK
        LDX     #$F100                            ; SETUP LOOP COUNTER
KBD_RESET0:
        PSHS    X                                 ; PRESERVE COUNTER
        JSR     KBD_GETDATA                       ; TRY TO GET THE RESPONSE
        PULS    X                                 ; RECOVER COUNTER
        BNE     KBD_RESET1                        ; GOT A BYTE?  IF SO, GET OUT OF LOOP
        DEX
        BNE     KBD_RESET0                        ; LOOP TILL COUNTER EXHAUSTED

        SEC                                       ; SIGNAL FAILURE
        RTS                                       ; DONE
KBD_RESET1:

        CLC                                       ; SIGNAL SUCCESS (RESPONSE IS IGNORED...)
        RTS                                       ; DONE
;
;__________________________________________________________________________________________________
; UPDATE KEYBOARD LEDS BASED ON CURRENT TOGGLE FLAGS
;__________________________________________________________________________________________________
;
KBD_SETLEDS:
        LDA     #$ED                              ; SET/RESET LED'S COMMAND
        JSR     KBD_PUTDATA                       ; SEND THE COMMAND
        JSR     KBD_GETDATA                       ; READ THE RESPONSE
        CMPA    #$FA                              ; MAKE SURE WE GET ACK
        BEQ     >

        SEC
        RTS                                       ; ABORT IF NO ACK
!
        LDA     KBD_STATE                         ; LOAD THE STATE BYTE
        RORA                                      ; ROTATE TOGGLE KEY BITS AS NEEDED
        RORA
        RORA
        RORA
        ANDA    #$07                              ; CLEAR THE IRRELEVANT BITS
        JSR     KBD_PUTDATA                       ; SEND THE LED DATA
        JSR     KBD_GETDATA                       ; READ THE ACK
        CMPA    #$FA                              ; MAKE SURE WE GET ACK
        BEQ     >

        SEC
        RTS                                       ; ABORT IF NO ACK
!
        LDA     #$00                              ; A=0
        STA     KBD_STATUS                        ; CLEAR STATUS

        CLC
        RTS
;
;__________________________________________________________________________________________________
; UPDATE KEYBOARD REPEAT RATE BASED ON CURRENT SETTING
;__________________________________________________________________________________________________
;
KBD_SETRPT:
        LDA     #$F3                              ; COMMAND = SET TYPEMATIC RATE/DELAY
        JSR     KBD_PUTDATA                       ; SEND IT
        JSR     KBD_GETDATA                       ; GET THE ACK
        CMPA    #$FA                              ; MAKE SURE WE GET ACK
        BEQ     >

        SEC
        RTS                                       ; ABORT IF NO ACK
!
        LDA     KBD_REPEAT                        ; LOAD THE CURRENT RATE/DELAY BYTE
        JSR     KBD_PUTDATA                       ; SEND IT
        JSR     KBD_GETDATA                       ; GET THE ACK
        CMPA    #$FA                              ; MAKE SURE WE GET ACK
        BEQ     >

        SEC
        RTS                                       ; ABORT IF NO ACK
!
        CLC
        RTS

;__GETKEY__________________________________________________________________________________________
; Get char from Keyboard, return in A
;__________________________________________________________________________________________________
KBD_GETKEY:
        JSR     KBD_DECODE
        BCC     >
        LDA     #$FF                              ;
        STA     >PAGER_D                          ; SAVE 'D'
        SEC
        RTS
!
        LDA     KBD_KEYCODE
        STA     >PAGER_D                          ; SAVE 'D'
        LDA     KBD_STATUS
        ANDA    #$7F
        STA     KBD_STATUS
        CLC
        RTS

;
;__________________________________________________________________________________________________
; DECODING ENGINE
;__________________________________________________________________________________________________
;
;__________________________________________________________________________________________________
KBD_DECODE:
;
;  RUN THE DECODING ENGINE UNTIL EITHER: 1) NO MORE SCANCODES ARE AVAILABLE
;  FROM THE KEYBOARD, OR 2) A DECODED KEY VALUE IS AVAILABLE
;
;  RETURNS A=0 AND Z SET IF NO KEYCODE READY, OTHERWISE A DECODED KEY VALUE IS AVAILABLE.
;  THE DECODED KEY VALUE AND KEY STATE IS STORED IN KBD_KEYCODE AND KBD_STATE.
;
;  KBD_STATUS IS NOT CLEARED AT START. IT IS THE JSR ER'S RESPONSIBILITY
;  TO CLEAR KBD_STATUS WHEN IT HAS RETRIEVED A PENDING VALUE.  IF DECODE IS JSR ED
;  WITH A KEYCODE STILL PENDING, IT WILL JUST RETURN WITHOUT DOING ANYTHING.
;
; Step 0: Check keycode buffer
;   if status[keyrdy]
;     return
;
; Step 1: Get scancode
;   if no scancode ready
;     return
;   read scancode
;
; Step 2: Detect and handle special keycodes
;   if scancode == $AA
;     *** handle hot insert somehow ***
;
; Step 3: Detect and handle scancode prefixes
;   if scancode == $E0
;     set status[extended]
;     goto Step 1
;
;   if scancode == $E1
;     *** handle pause key somehow ***
;
; Step 4: Detect and flag break event
;   *** scancode set #1 variation ***
;     set status[break] = high bit of scancode
;     clear high order bit
;     continue to Step 5
;   *** scancode set #2 variation ***
;     if scancode == $F0
;       set status[break]
;       goto Step 1
;
; Step 5: Map scancode to keycode
;   if status[extended]
;     apply extended-map[scancode] -> keycode
;   else if state[shifted]
;     apply shifted-map[scancode] -> keycode
;   else
;     apply normal-map[scancode] -> keycode
;
; Step 6: Handle modifier keys
;   if keycode is modifier (shift, ctrl, alt, win)
;     set (l/r)state[<modifier>] = not status[break]
;     clear modifier bits in state
;     set state = (lstate OR rstate OR state)
;     goto New Key
;
; Step 7: Complete procesing of key break events
;   if status[break]
;     goto New Key
;
; Step 8: Handle toggle keys
;   if keycode is toggle (capslock, numlock, scrolllock)
;     invert (XOR) state[<toggle>]
;     update keyboard LED's
;     goto New Key
;
; Step 9: Adjust keycode for control modifier
;   if state[ctrl]
;     if keycode is 'a'-'z'
;       subtract 20 (clear bit 5) from keycode
;     if keycode is '@'-'_'
;       subtract 40 (clear bit 6) from keycode
;
; Step 10: Adjust keycode for caps lock
;   if state[capslock]
;     if keycode is 'a'-'z' OR 'A'-'Z'
;       toggle (XOR) bit 5 of keycode
;
; Step 11: Handle num pad keys
;   clear state[numpad]
;   if keycode is numpad
;     set state[numpad]
;     if state[numlock]
;       toggle (XOR) bit 4 of keycode
;     apply numpad-map[keycode] -> keycode
;
; Step 12: Detect unknown/invalid keycodes
;   if keycode == $FF
;     goto New Key
;
; Step 13: Done
;   set status[keyrdy]
;   return
;
; New Key:
;   clear status
;   goto Step 1
;
KBD_DEC0:                                         ; CHECK KEYCODE BUFFER
        LDA     KBD_STATUS                        ; GET CURRENT STATUS
        ANDA    #KBD_KEYRDY                       ; ISOLATE KEY READY FLAG
        BEQ     KBD_DEC1
        SEC
        RTS                                       ; ABORT IF KEY IS ALREADY PENDING

KBD_DEC1:                                         ; PROCESS NEXT SCANCODE
        JSR     KBD_GETDATAX                      ; GET THE SCANCODE
        BCC     KBD_DEC2
        SEC
        RTS                                       ; NO KEY READY, RETURN WITH A=0, SET ERROR

KBD_DEC2:                                         ; DETECT AND HANDLE SPECIAL KEYCODES
        STA     KBD_SCANCODE                      ; SAVE SCANCODE
        CMPA    #$AA                              ; KEYBOARD INSERTION?
        BNE     KBD_DEC3                          ; NOPE, BYPASS
        JSR     LDELAY                            ; WAIT A BIT
        JSR     KBD_RESET                         ; RESET KEYBOARD
        JSR     KBD_SETLEDS                       ; SET LEDS
        JSR     KBD_SETRPT                        ; SET REPEAT RATE
        JMP     KBD_DECNEW                        ; RESTART THE ENGINE

KBD_DEC3:                                         ; DETECT AND HANDLE SCANCODE PREFIXES
        CMPA    #$E0                              ; EXTENDED KEY PREFIX $E0?
        BNE     KBD_DEC3B                         ; NOPE MOVE ON
        LDB     KBD_STATUS                        ; GET STATUS
        ORB     #KBD_EXT                          ; SET EXTENDED BIT
        STB     KBD_STATUS                        ; SAVE STATUS
        JMP     KBD_DEC1                          ; LOOP TO DO NEXT SCANCODE

KBD_DEC3B:                                        ; HANDLE SCANCODE PREFIX $E1 (PAUSE KEY)
        CMPA    #$E1                              ; EXTENDED KEY PREFIX $E1
        BNE     KBD_DEC4                          ; NOPE MOVE ON
        LDA     #$EE                              ; MAP TO KEYCODE $EE
        STA     KBD_KEYCODE                       ; SAVE IT
; SWALLOW NEXT 7 SCANCODES
        LDX     #7                                ; LOOP 7 TIMES
KBD_DEC3B1:
        PSHS    X
        JSR     KBD_GETDATA                       ; RETRIEVE NEXT SCANCODE
        PULS    X
        DEX
        BNE     KBD_DEC3B1                        ; LOOP AS NEEDED
        JMP     KBD_DEC6                          ; RESUME AFTER MAPPING

KBD_DEC4:                                         ; DETECT AND FLAG BREAK EVENT
        CMPA    #$F0                              ; BREAK (KEY UP) PREFIX?
        BNE     KBD_DEC5                          ; NOPE MOVE ON
        LDB     KBD_STATUS                        ; GET STATUS
        ORB     #KBD_BREAK                        ; SET BREAK BIT
        STB     KBD_STATUS                        ; SAVE STATUS
        JMP     KBD_DEC1                          ; LOOP TO DO NEXT SCANCODE

KBD_DEC5:                                         ; MAP SCANCODE TO KEYCODE
        LDA     KBD_STATUS                        ; GET STATUS
        ANDA    #KBD_EXT                          ; EXTENDED BIT SET?
        BEQ     KBD_DEC5C                         ; NOPE, MOVE ON

; PERFORM EXTENDED KEY MAPPING
        LDB     KBD_SCANCODE                      ; GET SCANCODE
        LDA     #$00
        TFR     D,X
        LDX     KBD_MAPEXT                        ; POINT TO START OF EXT MAP TABLE
KBD_DEC5A:
        LDA     KBD_MAPEXT,X                      ; GET FIRST BYTE OF PAIR FROM EXT MAP TABLE
        INX
        CMPA    #$00                              ; END OF TABLE?
        LBEQ    KBD_DECNEW                        ; UNKNOWN OR BOGUS, START OVER
        CMPA    KBD_SCANCODE                      ; DOES MATCH BYTE EQUAL SCANCODE?
        BEQ     KBD_DEC5B                         ; YES! JUMP OUT
        INX                                       ; BUMP TO START OF NEXT PAIR
        JMP     KBD_DEC5A                         ; LOOP TO CHECK NEXT TABLE ENTRY
KBD_DEC5B:
        LDA     KBD_MAPEXT,X                      ; GET THE KEYCODE VIA MAPPING TABLE
        STA     KBD_KEYCODE                       ; SAVE IT
        JMP     KBD_DEC6

KBD_DEC5C:                                        ; PERFORM REGULAR KEY (NOT EXTENDED) KEY MAPPING
        LDA     KBD_SCANCODE                      ; GET THE SCANCODE
        CMPA    #KBD_MAPSIZ                       ; COMPARE TO SIZE OF TABLE
        BHI     KBD_DEC6                          ; PAST END, SKIP OVER LOOKUP

; SETUP POINTER TO MAPPING TABLE BASED ON SHIFTED OR UNSHIFTED STATE
        LDB     KBD_STATE                         ; GET STATE
        ANDB    #KBD_SHIFT                        ; SHIFT ACTIVE?
        BEQ     KBD_DEC5D                         ; NON-SHIFTED, MOVE ON

        LDB     KBD_SCANCODE                      ; GET THE SCANCODE
        LDA     #$00
        TFR     D,X
        LDA     KBD_MAPSHIFT,X                    ; GET SHIFTED
        BRA     >
KBD_DEC5D:
        LDB     KBD_SCANCODE                      ; GET THE SCANCODE
        LDA     #$00
        TFR     D,X
        LDA     KBD_MAPSTD,X                      ; GET STANDARD
!
        STA     KBD_KEYCODE                       ; SAVE KEYCODE

KBD_DEC6:                                         ; HANDLE MODIFIER KEYS
        LDA     KBD_KEYCODE                       ; MAKE SURE WE HAVE KEYCODE
        CMPA    #$B8                              ; END OF MODIFIER KEYS
        BGE     KBD_DEC7                          ; BYPASS MODIFIER KEY CHECKING
        CMPA    #$B0                              ; START OF MODIFIER KEYS
        BLO     KBD_DEC7                          ; BYPASS MODIFIER KEY CHECKING

        LDX     #4                                ; LOOP COUNTER TO LOOP THRU 4 MODIFIER BITS
        SUBA    #$AF                              ; SETUP A TO DECREMENT THROUGH MODIFIER VALUES
        LDB     #$00                              ; SETUP B TO ROATE THROUGH MODIFIER STATE BITS
        SEC                                       ; SET CARRY FOR ROTATE

KBD_DEC6A:
        ROLB                                      ; SHIFT TO NEXT MODIFIER STATE BIT
        DECA                                      ; L-MODIFIER?
        BEQ     KBD_DEC6B                         ; YES, HANDLE L-MODIFIER MAKE/BREAK
        DECA                                      ; R-MODIFIER?
        BEQ     KBD_DEC6C                         ; YES, HANDLE R-MODIFIER MAKE/BREAK
        DEX
        BNE     KBD_DEC6A                         ; LOOP THRU 4 MODIFIER BITS
        JMP     KBD_DEC7                          ; FAILSAFE, SHOULD NEVER GET HERE!

KBD_DEC6B:                                        ; LEFT STATE KEY MAKE/BREAK (STATE BIT TO SET/CLEAR IN B)
        LDX     #KBD_LSTATE                       ; POINT TO LEFT STATE BYTE
        JMP     KBD_DEC6D                         ; CONTINUE

KBD_DEC6C:                                        ; RIGHT STATE KEY MAKE/BREAK (STATE BIT TO SET/CLEAR IN B)
        LDX     #KBD_RSTATE                       ; POINT TO RIGHT STATE BYTE
        JMP     KBD_DEC6D                         ; CONTINUE

KBD_DEC6D:                                        ; BRANCH BASED ON WHETHER THIS IS A MAKE OR BREAK EVENT
        LDA     KBD_STATUS                        ; GET STATUS FLAGS
        ANDA    #KBD_BREAK                        ; BREAK EVENT?
        BEQ     KBD_DEC6E                         ; NO, HANDLE A MODIFIER KEY MAKE EVENT
        JMP     KBD_DEC6F                         ; YES, HANDLE A MODIFIER BREAK EVENT

KBD_DEC6E:                                        ; HANDLE STATE KEY MAKE EVENT
        ORB     ,X                                ; OR IN THE BIT TO SET
        STB     ,X                                ; SAVE THE RESULT
        JMP     KBD_DEC6G                         ; CONTINUE

KBD_DEC6F:                                        ; HANDLE STATE KEY BREAK EVENT
        EORB    #$FF                              ; FLIP ALL BITS TO SETUP FOR A CLEAR OPERATION
        ANDB    ,X                                ; AND IN THE FLIPPED BITS TO CLEAR DESIRED BIT
        STB     ,X                                ; SAVE THE RESULT
        JMP     KBD_DEC6G                         ; CONTINUE

KBD_DEC6G:                                        ; COALESCE L/R STATE FLAGS
        LDA     KBD_STATE                         ; GET EXISTING STATE BITS
        ANDA    #$F0                              ; GET RID OF OLD MODIFIER BITS
        ORA     KBD_LSTATE                        ; MERGE IN LEFT STATE BITS
        ORA     KBD_RSTATE                        ; MERGE IN RIGHT STATE BITS
        STA     KBD_STATE                         ; SAVE IT
        JMP     KBD_DECNEW                        ; DONE WITH CURRENT KEYSTROKE

KBD_DEC7:                                         ; COMPLETE PROCESSING OF EXTENDED AND KEY BREAK EVENTS
        LDA     KBD_STATUS                        ; GET CURRENT STATUS FLAGS
        ANDA    #KBD_BREAK                        ; IS THIS A KEY BREAK EVENT?
        LBNE    KBD_DECNEW                        ; PROCESS NEXT KEY

KBD_DEC8:                                         ; HANDLE TOGGLE KEYS
        LDA     KBD_KEYCODE                       ; GET THE CURRENT KEYCODE INTO A
        LDB     #KBD_CAPSLCK                      ; SETUP E WITH CAPS LOCK STATE BIT
        CMPA    #$BC                              ; IS THIS THE CAPS LOCK KEY?
        BEQ     KBD_DEC8A                         ; YES, GO TO BIT SET ROUTINE
        LDB     #KBD_NUMLCK                       ; SETUP E WITH NUM LOCK STATE BIT
        CMPA    #$BD                              ; IS THIS THE NUM LOCK KEY?
        BEQ     KBD_DEC8A                         ; YES, GO TO BIT SET ROUTINE
        LDB     #KBD_SCRLCK                       ; SETUP E WITH SCROLL LOCK STATE BIT
        CMPA    #$BE                              ; IS THIS THE SCROLL LOCK KEY?
        BEQ     KBD_DEC8A                         ; YES, GO TO BIT SET ROUTINE
        JMP     KBD_DEC9                          ; NOT A TOGGLE KEY, CONTINUE

KBD_DEC8A:                                        ; RECORD THE TOGGLE
        EORB    KBD_STATE                         ; SET THE TOGGLE KEY BIT FROM ABOVE
        STB     KBD_STATE                         ; SAVE IT
        TFR     B,A
        JSR     KBD_SETLEDS                       ; UPDATE LED LIGHTS ON KBD
        JMP     KBD_DECNEW                        ; RESTART DECODER FOR A NEW KEY

KBD_DEC9:                                         ; ADJUST KEYCODE FOR CONTROL MODIFIER
        LDA     KBD_STATE                         ; GET THE CURRENT STATE BITS
        ANDA    #KBD_CTRL                         ; CHECK THE CONTROL BIT
        BEQ     KBD_DEC10                         ; CONTROL KEY NOT PRESSED, MOVE ON
        LDA     KBD_KEYCODE                       ; GET CURRENT KEYCODE IN A
        CMPA    #'a'                              ; COMPARE TO LOWERCASE A
        BLO     KBD_DEC9A                         ; BELOW IT, BYPASS
        CMPA    #'z'                              ; COMPARE TO LOWERCASE Z+1
        BHI     KBD_DEC9A                         ; ABOVE IT, BYPASS
        ANDA    #$DF                              ; KEYCODE IN LOWERCASE A-Z RANGE CLEAR BIT 5 TO MAKE IT UPPERCASE
KBD_DEC9A:
        CMPA    #'@'                              ; COMPARE TO @
        BLO     KBD_DEC10                         ; BELOW IT, BYPASS
        CMPA    #'_'                              ; COMPARE TO _+1
        BHI     KBD_DEC10                         ; ABOVE IT, BYPASS
        ANDA    #$BF                              ; CONVERT TO CONTROL VALUE BY CLEARING BIT 6
        STA     KBD_KEYCODE                       ; UPDATE KEYCODE TO CONTROL VALUE

KBD_DEC10:                                        ; ADJUST KEYCODE FOR CAPS LOCK
        LDA     KBD_STATE                         ; LOAD THE STATE FLAGS
        ANDA    #KBD_CAPSLCK                      ; CHECK CAPS LOCK
        BEQ     KBD_DEC11                         ; CAPS LOCK NOT ACTIVE, MOVE ON
        LDA     KBD_KEYCODE                       ; GET THE CURRENT KEYCODE VALUE
        CMPA    #'a'                              ; COMPARE TO LOWERCASE A
        BLO     KBD_DEC10A                        ; BELOW IT, BYPASS
        CMPA    #'z'                              ; COMPARE TO LOWERCASE Z+1
        BHI     KBD_DEC10A                        ; ABOVE IT, BYPASS
        JMP     KBD_DEC10B                        ; IN RANGE LOWERCASE A-Z, GO TO CASE SWAPPING LOGIC
KBD_DEC10A:
        CMPA    #'A'                              ; COMPARE TO UPPERCASE A
        BLO     KBD_DEC11                         ; BELOW IT, BYPASS
        CMPA    #'Z'                              ; COMPARE TO UPPERCASE Z+1
        BHI     KBD_DEC11                         ; ABOVE IT, BYPASS
        JMP     KBD_DEC10B                        ; IN RANGE UPPERCASE A-Z, GO TO CASE SWAPPING LOGIC
KBD_DEC10B:
        LDA     KBD_KEYCODE                       ; GET THE CURRENT KEYCODE
        EORA    #$20                              ; FLIP BIT 5 TO SWAP UPPER/LOWER CASE
        STA     KBD_KEYCODE                       ; SAVE IT

KBD_DEC11:                                        ; HANDLE NUM PAD KEYS
        LDA     KBD_STATE                         ; GET THE CURRENT STATE FLAGS
        ANDA    #~KBD_NUMPAD                      ; ASSUME NOT A NUMPAD KEY, CLEAR THE NUMPAD BIT
        STA     KBD_STATE                         ; SAVE IT

        LDA     KBD_KEYCODE                       ; GET THE CURRENT KEYCODE
        ANDA    #%11100000                        ; ISOLATE TOP 3 BITS
        CMPA    #%11000000                        ; IS IN NUMPAD RANGE?
        BNE     KBD_DEC12                         ; NOPE, GET OUT

        LDA     KBD_STATE                         ; LOAD THE CURRENT STATE FLAGS
        ORA     #KBD_NUMPAD                       ; TURN ON THE NUMPAD BIT
        STA     KBD_STATE                         ; SAVE IT

        ANDA    #KBD_NUMLCK                       ; IS NUM LOCK BIT SET?
        BEQ     KBD_DEC11A                        ; NO, SKIP NUMLOCK PROCESSING
        LDA     KBD_KEYCODE                       ; GET THE KEYCODE
        EORA    #$10                              ; FLIP VALUES FOR NUMLOCK
        STA     KBD_KEYCODE                       ; SAVE IT

KBD_DEC11A:                                       ; APPLY NUMPAD MAPPING
        LDB     KBD_KEYCODE                       ; GET THE CURRENT KEYCODE
        SUBB    #$C0                              ; KEYCODES START AT $C0
        LDA     #$00
        STD     KBD_TEMP
        LDD     #KBD_MAPNUMPAD                    ; LOAD THE START OF THE MAPPING TABLE
        CLC
        ADDD    KBD_TEMP
        TFR     D,X                               ; INDEX IN X

        LDA     ,X                                ; GET IT IN A
        STA     KBD_KEYCODE                       ; SAVE IT

KBD_DEC12:                                        ; DETECT UNKNOWN/INVALID KEYCODES
        LDA     KBD_KEYCODE                       ; GET THE FINAL KEYCODE
        CMPA    #$FF                              ; IS IT $FF (UNKNOWN/INVALID)
        BEQ     KBD_DECNEW                        ; IF SO, JUST RESTART THE ENGINE

KBD_DEC13:                                        ; DONE - RECORD RESULTS
        LDA     KBD_STATUS                        ; GET CURRENT STATUS
        ORA     #KBD_KEYRDY                       ; SET KEY READY BIT
        STA     KBD_STATUS                        ; SAVE IT
        LDA     #$00                              ; A=0
        CLC                                       ; SIGNAL SUCCESS WITH A=1, CARRY CLEAR
        RTS

KBD_DECNEW:                                       ; START NEW KEYPRESS (CLEAR ALL STATUS BITS)
        LDA     #$00                              ; A=0
        STA     KBD_STATUS                        ; CLEAR STATUS
        JMP     KBD_DEC1                          ; RESTART THE ENGINE

DELAY:
        PSHS    A,B,X,Y,U
        PULS    A,B,X,Y,U
        PSHS    A,B,X,Y,U
        PULS    A,B,X,Y,U
        PSHS    A,B,X,Y,U
        PULS    A,B,X,Y,U
        PSHS    A,B,X,Y,U
        PULS    A,B,X,Y,U
        RTS

LDELAY:
        PSHS    A,B,X,Y,U
        LDX     #$100
!
        JSR     DELAY
        DEX
        BNE     <
        PULS    A,B,X,Y,U
        RTS

;
; DRIVER DATA
;__________________________________________________________________________________________________
; MESSAGES
;__________________________________________________________________________________________________
MIOMESSAGE1:
        FCC     "ISA MULTI-IO:"
        FCB     00
MIOMESSAGE3:
        FCC     "  KBD: VT82C42 NOT FOUND."
        FCB     00
MIOMESSAGE4:
        FCC     "  KBD: INITIALIZED."
        FCB     00
MIOMESSAGE5:
        FCC     "  LPT: INITIALIZED."
        FCB     00

;
; MAPPING
;__________________________________________________________________________________________________
;
KBD_MAPSTD:                                       ; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE
        FCB     $FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'`',$FF
        FCB     $FF,$B4,$B0,$FF,$B2,'q','1',$FF,$FF,$FF,'z','s','a','w','2',$FF
        FCB     $FF,'c','x','d','e','4','3',$FF,$FF,' ','v','f','t','r','5',$FF
        FCB     $FF,'n','b','h','g','y','6',$FF,$FF,$FF,'m','j','u','7','8',$FF
        FCB     $FF,',','k','i','o','0','9',$FF,$FF,'.','/','l',';','p','-',$FF
        FCB     $FF,$FF,$27,$FF,'[','=',$FF,$FF,$BC,$B1,$0D,']',$FF,'\',$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$C0,$FF,$C3,$C6,$FF,$FF,$FF
        FCB     $C9,$CA,$C1,$C4,$C5,$C7,$1B,$BD,$FA,$CE,$C2,$CD,$CC,$C8,$BE,$FF
        FCB     $FF,$FF,$FF,$E6,$EC
BD_MAPSTDEND:
;
KBD_MAPSIZ      EQU BD_MAPSTDEND-KBD_MAPSTD
;
KBD_MAPSHIFT:                                     ; SCANCODE IS INDEX INTO TABLE TO RESULTANT LOOKUP KEYCODE WHEN SHIFT ACTIVE
        FCB     $FF,$E8,$FF,$E4,$E2,$E0,$E1,$EB,$FF,$E9,$E7,$E5,$E3,$09,'~',$FF
        FCB     $FF,$B4,$B0,$FF,$B2,'Q','!',$FF,$FF,$FF,'Z','S','A','W','@',$FF
        FCB     $FF,'C','X','D','E','$','#',$FF,$FF,' ','V','F','T','R','%',$FF
        FCB     $FF,'N','B','H','G','Y','^',$FF,$FF,$FF,'M','J','U','&','*',$FF
        FCB     $FF,'<','K','I','O',')','(',$FF,$FF,'>','?','L',':','P','_',$FF
        FCB     $FF,$FF,$22,$FF,'{','+',$FF,$FF,$BC,$B1,$0D,'}',$FF,'|',$FF,$FF
        FCB     $FF,$FF,$FF,$FF,$FF,$FF,$08,$FF,$FF,$D0,$FF,$D3,$D6,$FF,$FF,$FF
        FCB     $D9,$DA,$D1,$D4,$D5,$D7,$1B,$BD,$FA,$DE,$D2,$DD,$DC,$D8,$BE,$FF
        FCB     $FF,$FF,$FF,$E6,$EC
;
KBD_MAPEXT:                                       ; PAIRS ARE [SCANCODE,KEYCODE] FOR EXTENDED SCANCODES
        FCB     $11,$B5,$14,$B3,$1F,$B6,$27,$B7
        FCB     $2F,$EF,$37,$FA,$3F,$FB,$4A,$CB
        FCB     $5A,$CF,$5E,$FC,$69,$F3,$6B,$F8
        FCB     $6C,$F2,$70,$F0,$71,$F1,$72,$F7
        FCB     $74,$F9,$75,$F6,$7A,$F5,$7C,$ED
        FCB     $7D,$F4,$7E,$FD,$00,$00
;
KBD_MAPNUMPAD:                                    ; KEYCODE TRANSLATION FROM NUMPAD RANGE TO STD ASCII/KEYCODES
        FCB     $F3,$F7,$F5,$F8,$FF,$F9,$F2,$F6,$F4,$F0,$F1,$2F,$2A,$2D,$2B,$0D
        FCB     $31,$32,$33,$34,$35,$36,$37,$38,$39,$30,$2E,$2F,$2A,$2D,$2B,$0D
;
;
;__________________________________________________________________________________________________
; KEYCODE VALUES RETURNED BY THE DECODER
;__________________________________________________________________________________________________
;
; VALUES 0-127 ARE STANDARD ASCII, SPECIAL KEYS WILL HAVE THE FOLLOWING VALUES:
;
; F1		$E0
; F2		$E1
; F3		$E2
; F4		$E3
; F5		$E4
; F6		$E5
; F7		$E6
; F8		$E7
; F9		$E8
; F10		$E9
; F11		$EA
; F12		$EB
; SYSRQ		$EC
; PRTSC		$ED
; PAUSE		$EE
; APP		$EF
; INS		$F0
; DEL		$F1
; HOME		$F2
; END		$F3
; PGUP		$F4
; PGDN		$F5
; UP		$F6
; DOWN		$F7
; LEFT		$F8
; RIGHT		$F9
; POWER		$FA
; SLEEP		$FB
; WAKE		$FC
; BREAK		$FD
;___________________________________________________________________________________________________________________
;
; CENTRONICS (LPT) INTERFACE DRIVER
;___________________________________________________________________________________________________________________
;
; BYTE OUTPUT
;
LPT_OUT:
        LDX     #LPT_WAITTO
!
	JSR	LPT_OST			; READY TO SEND?
	BNE	>        		; GO IF READY
        DEX
        BNE     <                       ; LOOP IF NOT READY
        SEC                             ; SIGNAL ERROR
        RTS
!
        STA	LPT_0   		; OUTPUT TO PORT 0 (DATA)
	LDA	#%00001101		; SELECT & STROBE, LEDS OFF
	STA     LPT_2			; OUTPUT DATA TO PORT
	JSR	DELAY
	LDA	#%00001100		; SELECT, LEDS OFF
	STA     LPT_2			; OUTPUT DATA TO PORT
	JSR	DELAY
        CLC
	RTS
;
; OUTPUT STATUS
;
LPT_OST:
	LDB	LPT_2           	; GET STATUS INFO
	ANDB	#%10000000		; ISOLATE /BUSY
	RTS				; DONE
