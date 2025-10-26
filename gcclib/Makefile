all:  	libcubix.a test.s19

crt0.o: crt0.s
	as6809 -l -o -g crt0.s
	mv crt0.rel crt0.o

libgcc1.o: libgcc1.s
	as6809 -l -o -g libgcc1.s
	mv libgcc1.rel libgcc1.o

esplowlevel.o: esplowlevel.c
	gcc6809 -fno-builtin -nostdlib esplowlevel.c  -c

graphics.o: graphics.c
	gcc6809 -fno-builtin -nostdlib graphics.c  -c

strlen.o: strlen.c
	gcc6809 -fno-builtin -nostdlib strlen.c  -c

puts.o: puts.c
	gcc6809 -fno-builtin -nostdlib puts.c  -c

outbyte.o: outbyte.c
	gcc6809 -fno-builtin -nostdlib outbyte.c -c

printf.o: printf.c outbyte.c
	gcc6809 -fno-builtin -nostdlib printf.c -c

getch.o: getch.c
	gcc6809 -fno-builtin -nostdlib getch.c -c

toupper.o: toupper.c
	gcc6809 -fno-builtin -nostdlib toupper.c -c

gettim.o: gettim.c
	gcc6809 -fno-builtin -nostdlib gettim.c -c

test.s19: test.c libcubix.a
	gcc6809 -fno-builtin -nostdlib test.c -c
	aslink -n -m  -s -o -b .text=0x2020 -b .startup=0x2000 -l libcubix.a test.o

libcubix.a: libgcc1.o strlen.o puts.o outbyte.o printf.o getch.o gettim.o toupper.o esplowlevel.o graphics.o crt0.o
	-aslib d libcubix.a    libgcc1.o outbyte.o strlen.o puts.o printf.o getch.o toupper.o gettim.o esplowlevel.o graphics.o crt0.o
	aslib qc libcubix.a    libgcc1.o outbyte.o strlen.o puts.o printf.o getch.o toupper.o gettim.o esplowlevel.o graphics.o crt0.o

clean:
	@rm -f *.hlr
	@rm -f *.a
	@rm -f *.o
	@rm -f *.rel
	@rm -f *.out
	@rm -f *.com
	@rm -f *.co6
	@rm -f *.map
	@rm -f *.lst
	@rm -f *.ihx
	@rm -f *.bin
	@rm -f *.s19

cleandust:
	@rm -f *.o
	@rm -f *.out
	@rm -f *.map
	@rm -f *.lst