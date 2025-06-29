all:  	scream.hex monitor.hex mon09.hex cubixdrv.s19 cubix.s19

cubixdrv.s19: cubixdrv.asm cubix_serial.asm cubix_ide.asm cubix_values.asm cubix_multio.asm cubix_esp.asm
	lwasm --6809   --6800compat cubixdrv.asm -s --list=cubixdrv.lst --map=cubixdrv.map --output=cubixdrv.s --format=srec
	srec_cat  cubixdrv.s -exclude 0x0000 0xc100 -o cubixdrv.s19
	@rm cubixdrv.s

cubix.s19: cubix_boot.asm cubixdrv.sys
	lwasm --6809   --6800compat cubix_boot.asm -s --list=cubix_boot.lst --map=cubix_boot.map --output=cubix_boot.s --format=srec
	srec_cat  cubix_boot.s -o  cubix_boot.1  -Data_Only
	srec_cat  ../cubix_os/pc_cubix.s19 -offset -0xBE00 -o  cubix_boot.2  -Data_Only
	srec_cat  cubixdrv.s19 -offset -0x7F00 -o  cubix_boot.3  -Data_Only
	srec_cat  cubix_boot.1 cubix_boot.2 cubix_boot.3 -o  cubix.s19 -data-only
	@rm	cubix_boot.1
	@rm	cubix_boot.2
	@rm	cubix_boot.3
	@rm	cubix_boot.s
	sed -i -e '$$aS9' cubix.s19
	@cp cubix.s19 ../bin/6809PC

scream.hex: scream.asm
	lwasm --6809 --6800compat scream.asm -s --list=scream.lst --map=scream.map --output=scream.s --format=srec
	srec_cat  scream.s  -o  scream.hex  -intel -address-length=2
	@rm scream.s
	@cp scream.hex ../bin/6809PC

monitor.hex: monitor.asm
	lwasm --6809 --6800compat monitor.asm -s --list=monitor.lst --map=monitor.map --output=monitor.s --format=srec
	srec_cat  monitor.s -o  monitor.hex  -intel -address-length=2
	@rm monitor.s
	@cp monitor.hex ../bin/6809PC


mon09.hex: mon09.asm
	lwasm --6809 --6800compat mon09.asm -s --list=mon09.lst --map=mon09.map --output=mon09.s --format=srec
	srec_cat  mon09.s -o  mon09.hex  -intel -address-length=2
	@rm mon09.s
	@cp mon09.hex ../bin/6809PC

pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/scream.asm scream.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/monitor.asm monitor.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/mon09.asm mon09.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_values.asm cubix_values.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_pager.asm cubix_pager.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_serial.asm cubix_serial.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_ide.asm cubix_ide.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_multio.asm cubix_multio.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubixdrv.asm cubixdrv.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/drivers.asm drivers.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_boot.asm cubix_boot.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/cubix_esp.asm cubix_esp.asm


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