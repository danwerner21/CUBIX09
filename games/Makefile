all:  	startrek.s19


startrek.s19: startrek.c
	gcc6809 -fno-builtin -nostdlib startrek.c  -c
	aslink -n -m  -s -o -b .text=0x2020 -b .startup=0x2000 -l ../gcclib/libcubix.a startrek.o
	srec_cat startrek.s19  -exclude 0x0000 0x1FFF -offset -0x2000 -o startrek.s1
	srec_cat startrek.s1  -o startrek.exe -binary
	@cp startrek.s19 ../bin/utilities
	@cp startrek.exe ../bin/utilities


clean:
	@rm -f *.exe
	@rm -f *.o
	@rm -f *.out
	@rm -f *.com
	@rm -f *.co6
	@rm -f *.map
	@rm -f *.lst
	@rm -f *.hex
	@rm -f *.s19
	@rm -f *.s

cleandust:
	@rm -f *.o
	@rm -f *.out
	@rm -f *.map
	@rm -f *.lst