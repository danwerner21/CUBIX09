all:  	cubixdrv.sys cubix.s19 duocubix.com testpcf.exe

cubixdrv.sys: cubixdrv.asm cubix_serial.asm cubix_ide.asm cubix_dskyng.asm cubix_dsky.asm cubix_values.asm cubix_fp.asm cubix_i2c.asm
	lwasm --6809   --6800compat cubixdrv.asm -s --list=cubixdrv.lst --map=cubixdrv.map --output=cubixdrv.s --format=srec
	srec_cat  cubixdrv.s -exclude 0x0000 0x8800 -o  cubixdrv.hex  -intel -address-length=2
	srec_cat  cubixdrv.s -offset -0x8800 -o cubixdrv.sys -binary
	srec_cat  cubixdrv.s -exclude 0x0000 0x8800 -o cubixdrv.s19
	@rm cubixdrv.s

duocubix.com: loader.asm cubix.s19 cubixdrv.sys
	z80asm -b -l -m loader.asm  2> loader.err
	srec_cat  loader_addr0100.bin -binary  -o  cubix_loader.1  -Data_Only
	srec_cat  cubix.s19 -offset -0x0100 -o  cubix_loader.2  -Data_Only
	srec_cat  cubix_loader.1 cubix_loader.2 -o duocubix.com  -binary
	@rm	cubix_loader.1
	@rm	cubix_loader.2
	@rm	loader_addr0100.bin
	@cp duocubix.com ../bin/duodyne

cubix.s19: cubix_boot.asm cubixdrv.sys
	lwasm --6809   --6800compat cubix_boot.asm -s --list=cubix_boot.lst --map=cubix_boot.map --output=cubix_boot.s --format=srec
	srec_cat  cubix_boot.s -o  cubix_boot.1  -Data_Only
	srec_cat  ../cubix_os/duo_cubix.s19 -offset -0xCE00 -o  cubix_boot.2  -Data_Only
	srec_cat  cubixdrv.s19 -offset -0x5500 -o  cubix_boot.3  -Data_Only
	srec_cat  cubix_boot.1 cubix_boot.2 cubix_boot.3 -o  cubix.s19
	@rm	cubix_boot.1
	@rm	cubix_boot.2
	@rm	cubix_boot.3
	@cp cubix.s19 ../bin/duodyne

testpcf.exe: testpcf.asm
	lwasm --6809 testpcf.asm -s --list=testpcf.lst --map=testpcf.map --output=testpcf.s --format=srec
	srec_cat testpcf.s -o testpcf.s19 -data-only
	srec_cat testpcf.s -o testpcf.exe -binary
	sed -i -e '$$aS9' testpcf.s19
	@cp testpcf.s19 ../bin/duodyne
	@cp testpcf.exe ../bin/duodyne

pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/drivers.asm drivers.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_dsky.asm cubix_dsky.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_floppy.asm cubix_floppy.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_ide.asm cubix_ide.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_serial.asm cubix_serial.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_dskyng.asm cubix_dskyng.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_pager.asm cubix_pager.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_boot.asm cubix_boot.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_fp.asm cubix_fp.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_i2c.asm cubix_i2c.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubixdrv.asm cubixdrv.asm
	pretty6502 -p2 -a0 -du -mu -c50 -l ./backup/loader.asm loader.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/testpcf.asm testpcf.asm

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
	@rm -f *.bin
	@rm -f *.sys


cleandust:
	@rm -f *.o
	@rm -f *.out
	@rm -f *.map
	@rm -f *.lst