all:  	scream.com monitor.com loader.bin cubixdrv.sys

cubixdrv.sys: cubixdrv.asm cubix_serial.asm cubix_ide.asm cubix_dskyng.asm cubix_dsky.asm
	lwasm --6809   --6800compat cubixdrv.asm -s --list=cubixdrv.lst --map=cubixdrv.map --output=cubixdrv.s --format=srec
	srec_cat  cubixdrv.s -exclude 0x0000 0x8800 -o  cubixdrv.hex  -intel -address-length=2
	srec_cat  cubixdrv.s -offset -0x8800 -o cubixdrv.sys -binary
	@rm cubixdrv.s
	@cp cubixdrv.sys ../bin/nhyodyne

loader.bin: loader.asm
	z80asm -b -l -m loader.asm  2> loader.err
	cat loader_addr0100.bin loader_addr8000.bin > loader.bin
	@rm loader_addr0100.bin
	@rm loader_addr8000.bin
	@rm loader.o

scream.com: scream.asm
	lwasm --6809 scream.asm -s --list=scream.lst --map=scream.map --output=scream.s --format=srec
	srec_cat  scream.s -exclude 0x0000 0xF000 -offset -0x8000 -o  scream.hex  -intel -address-length=2
	srec_cat  scream.s -offset -0xEFE0 -o scream.com -binary
	@rm scream.s
	truncate scream.com -s 4130
	@cp scream.com ../bin/nhyodyne

monitor.com: monitor.asm
	lwasm --6809 monitor.asm -s --list=monitor.lst --map=monitor.map --output=monitor.s --format=srec
	srec_cat  monitor.s -exclude 0x0000 0xF000 -offset -0x8000 -o  monitor.hex  -intel -address-length=2
	srec_cat  monitor.s -offset -0xEFE0 -o monitor.com -binary
	@rm monitor.s
	truncate monitor.com -s 4130
	@cp monitor.com ../bin/nhyodyne

pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/scream.asm scream.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/monitor.asm monitor.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/drivers.asm drivers.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_dsky.asm cubix_dsky.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_floppy.asm cubix_floppy.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_ide.asm cubix_ide.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_serial.asm cubix_serial.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_dskyng.asm cubix_dskyng.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_pager.asm cubix_pager.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubixdrv.asm cubixdrv.asm
	pretty6502 -p2 -a0 -du -mu -c50 -l ./backup/loader.asm loader.asm

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