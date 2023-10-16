all:  	monitor.hex

monitor.hex: mon09.asm
	lwasm --6809 mon09.asm -s --list=mon09.lst --map=mon09.map --output=mon09.s --format=srec
	srec_cat  mon09.s -exclude 0x0000 0xF000 -offset -0x8000 -o  mon09.hex  -intel -address-length=2
	@cp mon09.hex ../bin/nhyodyne/monitor.hex

pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/mon09.asm mon09.asm

clean:
	@rm -f *.o
	@rm -f *.out
	@rm -f *.com
	@rm -f *.co6
	@rm -f *.map
	@rm -f *.lst
	@rm -f *.hex
	@rm -f *.s19
	@rm -f *.s
	@rm -f *.sys


cleandust:
	@rm -f *.o
	@rm -f *.out
	@rm -f *.map
	@rm -f *.lst