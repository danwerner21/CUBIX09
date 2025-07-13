BS              EQU 8                             ; BACKSPACE
CR              EQU $D                            ; ENTER KEY
ESC             EQU $1B                           ; ESCAPE CODE
SPACE           EQU $20                           ; SPACE (BLANK)
STKBUF          EQU 58                            ; STACK BUFFER ROOM
LBUFMX          EQU 250                           ; MAX NUMBER OF CHARS IN A BASIC LINE
MAXLIN          EQU $FA                           ; MAXIMUM MS BYTE OF LINE NUMBER
;*        PSEUDO  OPS
SKP1            EQU $21                           ; OP CODE OF BRN - SKIP ONE BYTE
SKP2            EQU $8C                           ; OP CODE OF CMPX # - SKIP TWO BYTES
SKP1LD          EQU $86                           ; OP CODE OF LDA # - SKIP THE NEXT BYTE
;*                             ; AND LOAD THE VALUE OF THAT BYTE INTO ACCA - THIS
;*                             ; IS USUALLY USED TO LOAD ACCA WITH A NON ZERO VALUE

END_OF_USER_RAM EQU $D7FF
STRING_SPACE_SIZE EQU -3000
