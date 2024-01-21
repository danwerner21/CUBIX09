;________________________________________________________________________________________________________________________________
;
;	Duodyne CUBIX CP/M loader program
;
;  DWERNER 04/24/2022 	Initial
;  PSUMMERS 8/7/2022    Accept a command line argument for CPU to switch to (0-9)
;  DWERNER 10/15/2023   MODIFY CODE FOR CUBIX09
;  DWERNER 01/21/2024 	Duodyne conversion

;________________________________________________________________________________________________________________________________
BDOS:           EQU $0005                         ; BDOS invocation vector
DEFFCB:         EQU $5C                           ; Location of default FCB

        SECTION ADDR0100
        ORG     0100H
; TODO:  RE-ENABLE THIS CODE
; Check for cpu unit
;        LD      A,(DEFFCB+1)                      ; Get first char of filename
;
;        CP      '9' + 1                           ; > '9'
;        JR      NC,go                             ; YES, NOT 0-9, Invalid argument
;
;        SUB     '0'                               ; < '0'?
;        JR      C,go                              ; YES, NOT 0-9, Invalid argument

;        CPL                                       ; to port and save
;        LD      (CPUunit),A                       ; Unit 0 = FFH, 1 = FEH etc
;
go:
        LD      C,9
        LD      DE,MSGFIL
        CALL    BDOS                              ; Do it
        DI                                        ; DISABLE INTERRUPTS
        LD      A,(CPUunit)                       ; GET CPU PORT
        LD      C,$95
        IN      A,(C)                             ; ENABLE 6502
; should never get here
        NOP
        NOP
        NOP
        NOP
        NOP
        NOP
        HALT

;
CPUunit:
        DB      095h                              ; Default CPU unit port
;

MSGFIL:
        DB      0AH,0DH
        DM      "CUBIX LOADED INTO RAM, TO START CUBIX TYPE:"
        DB      0AH,0DH
        DB      0AH,0DH
        DM      "W DF50 9C"
        DB      0AH,0DH
        DM      "G 1000"
        DB      0AH,0DH
        DB      0AH,0DH
        DM      "INTO 6809 MONITOR"
        DM      "$"

.END
