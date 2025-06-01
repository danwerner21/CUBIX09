all:  	zip.s19


zip.s19: cubixzip.asm eq.asm warm.asm
	lwasm --6809 cubixzip.asm -s --list=cubixzip.lst --map=cubixzip.map --output=cubixzip.s --format=srec
	srec_cat cubixzip.s -o zip.s19 -data-only
	sed -i -e '$$aS9' zip.s19
	@cp zip.s19 ../bin/utilities



pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubixzip.asm cubixzip.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/eq.asm eq.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/warm.asm warm.asm


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