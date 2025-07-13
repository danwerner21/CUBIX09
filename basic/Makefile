all:	exbasic.s19


exbasic.s19: exbasic.asm constants.asm directpage.asm tokens.asm consoleio.asm disk.asm
	lwasm  --6809 --6800compat exbasic.asm -s --list=exbasic.lst --map=exbasic.map --output=exbasic.s --format=srec
	srec_cat exbasic.s -o exbasic.s19 -data-only
	sed -i -e '$$aS9' exbasic.s19
	@cp exbasic.s19 ../bin/utilities

pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/exbasic.asm exbasic.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/directpage.asm directpage.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/constants.asm constants.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/tokens.asm tokens.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/consoleio.asm consoleio.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/disk.asm disk.asm


clean:
	@rm -f *.o
	@rm -f *.1
	@rm -f *.2
	@rm -f *.3
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