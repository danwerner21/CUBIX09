;	PAGE
;	SBTTL "--- OPCODE DISPATCH TABLES ---"

; 0-OPS

OPT0:
        FDB     ZRTRUE                            ; 0
        FDB     ZRFALS                            ; 1
        FDB     ZPRI                              ; 2
        FDB     ZPRR                              ; 3
        FDB     ZNOOP                             ; 4
        FDB     ZSAVE                             ; 5
        FDB     ZREST                             ; 6
        FDB     ZSTART                            ; 7
        FDB     ZRSTAK                            ; 8
        FDB     POPSTK                            ; 9
        FDB     ZQUIT                             ; 10
        FDB     ZCRLF                             ; 11
        FDB     ZUSL                              ; 12
        FDB     ZVER                              ; 13

NOPS0           EQU 14                            ; NUMBER OF 0-OPS

; 1-OPS

OPT1:
        FDB     ZZERO                             ; 0
        FDB     ZNEXT                             ; 1
        FDB     ZFIRST                            ; 2
        FDB     ZLOC                              ; 3
        FDB     ZPTSIZ                            ; 4
        FDB     ZINC                              ; 5
        FDB     ZDEC                              ; 6
        FDB     ZPRB                              ; 7
        FDB     BADOP1                            ; 8 (UNDEFINED)
        FDB     ZREMOV                            ; 9
        FDB     ZPRD                              ; 10
        FDB     ZRET                              ; 11
        FDB     ZJUMP                             ; 12
        FDB     ZPRINT                            ; 13
        FDB     ZVALUE                            ; 14
        FDB     ZBCOM                             ; 15

NOPS1           EQU 16                            ; NUMBER OF 1-OPS

; 2-OPS

OPT2:
        FDB     BADOP2                            ; 0 (UNDEFINED)
        FDB     ZEQUAL                            ; 1
        FDB     ZLESS                             ; 2
        FDB     ZGRTR                             ; 3
        FDB     ZDLESS                            ; 4
        FDB     ZIGRTR                            ; 5
        FDB     ZIN                               ; 6
        FDB     ZBTST                             ; 7
        FDB     ZBOR                              ; 8
        FDB     ZBAND                             ; 9
        FDB     ZFSETP                            ; 10
        FDB     ZFSET                             ; 11
        FDB     ZFCLR                             ; 12
        FDB     ZSET                              ; 13
        FDB     ZMOVE                             ; 14
        FDB     ZGET                              ; 15
        FDB     ZGETB                             ; 16
        FDB     ZGETP                             ; 17
        FDB     ZGETPT                            ; 18
        FDB     ZNEXTP                            ; 19
        FDB     ZADD                              ; 20
        FDB     ZSUB                              ; 21
        FDB     ZMUL                              ; 22
        FDB     ZDIV                              ; 23
        FDB     ZMOD                              ; 24

NOPS2           EQU 25                            ; NUMBER OF 2-OPS

; X-OPS

OPTX:
        FDB     ZCALL                             ; 0
        FDB     ZPUT                              ; 1
        FDB     ZPUTB                             ; 2
        FDB     ZPUTP                             ; 3
        FDB     ZREAD                             ; 4
        FDB     ZPRC                              ; 5
        FDB     ZPRN                              ; 6
        FDB     ZRAND                             ; 7
        FDB     ZPUSH                             ; 8
        FDB     ZPOP                              ; 9
        FDB     ZSPLIT                            ; 10
        FDB     ZSCRN                             ; 11

NOPSX           EQU 12                            ; NUMBER OF X-OPS
