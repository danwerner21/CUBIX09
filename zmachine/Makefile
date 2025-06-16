all:  	zip.s19


zip.s19: cubixzip.asm eq.asm warm.asm main.asm subs.asm dispatch.asm ops0.asm ops1.asm ops2.asm opsx.asm \
	 read.asm paging.asm zstring.asm objects.asm io.asm bugger.asm screen.asm disk.asm
	lwasm --6809 --6800compat cubixzip.asm -s --list=cubixzip.lst --map=cubixzip.map --output=cubixzip.s --format=srec
	srec_cat cubixzip.s -o zip.s19 -data-only
	srec_cat cubixzip.s -exclude 0x0000 0x2000 -offset -0x2000  -o zip.exe   -binary
	sed -i -e '$$aS9' zip.s19
	@cp zip.s19 ../bin/utilities



pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubixzip.asm cubixzip.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/eq.asm eq.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/warm.asm warm.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/main.asm main.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/subs.asm subs.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/dispatch.asm dispatch.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/ops0.asm ops0.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/ops1.asm ops1.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/ops2.asm ops2.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/opsx.asm opsx.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/read.asm read.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/paging.asm paging.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/zstring.asm zstring.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/objects.asm objects.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/io.asm io.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/bugger.asm bugger.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/screen.asm screen.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/disk.asm disk.asm


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