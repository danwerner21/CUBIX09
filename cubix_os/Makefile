all:  	cubix.com


cubix.com: cubix.asm command.os comfile.os filesys.os ../nhyodyne/loader.bin
	lwasm --define=nhyodyne --define=dist --6809  --6800compat cubix.asm -s --list=cubix.lst --map=cubix.map --output=cubix.s --format=srec
	srec_cat  cubix.s -exclude 0x0000 0xE000 -offset -0x8000 -o  cubix.hex  -intel -address-length=2
	srec_cat  cubix.s -exclude 0x0000 0xE000 -offset -0xE000 -o  cubix.s1  -binary
	cat ../nhyodyne/loader.bin cubix.s1 >cubix.com
	@rm cubix.s
	@rm cubix.s1
	@cp cubix.com ../bin/nhyodyne


pretty:
	cp *.asm ./backup
	cp *.os ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix.asm cubix.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/command.os command.os
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/comfile.os comfile.os
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/filesys.os filesys.os

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

cleandust:
	@rm -f *.o
	@rm -f *.out
	@rm -f *.map
	@rm -f *.lst