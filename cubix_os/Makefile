all:  	nhy_cubix.com duo_cubix.s19 pc_cubix.s19


nhy_cubix.com: cubix.asm command.os comfile.os filesys.os ../nhyodyne/loader.bin ../nhyodyne/cubix_values.asm ../nhyodyne/drivers.asm
	lwasm --define=nhyodyne --define=dist --6809  --6800compat cubix.asm -s --list=nhy_cubix.lst --map=nhy_cubix.map --output=nhy_cubix.s --format=srec
	srec_cat  nhy_cubix.s -exclude 0x0000 0xE000 -offset -0x8000 -o  nhy_cubix.hex  -intel -address-length=2
	srec_cat  nhy_cubix.s -exclude 0x0000 0xE000 -offset -0xE000 -o  nhy_cubix.s1  -binary
	srec_cat  nhy_cubix.s -exclude 0x0000 0xE000 -o  nhy_cubix.s19 -Data_Only
	cat ../nhyodyne/loader.bin nhy_cubix.s1 >nhy_cubix.com
	@rm nhy_cubix.s
	@rm nhy_cubix.s1
	@cp nhy_cubix.com ../bin/nhyodyne/cubix.com

duo_cubix.s19: cubix.asm command.os comfile.os filesys.os  ../duodyne/cubix_values.asm ../duodyne/drivers.asm
	lwasm --define=duodyne --define=dist --6809  --6800compat cubix.asm -s --list=duo_cubix.lst --map=duo_cubix.map --output=duo_cubix.s --format=srec
	srec_cat  duo_cubix.s -exclude 0x0000 0xE000 -offset -0x8000 -o  duo_cubix.hex  -intel -address-length=2
	srec_cat  duo_cubix.s -exclude 0x0000 0xE000 -offset -0xE000 -o  duo_cubix.s1  -binary
	srec_cat  duo_cubix.s -exclude 0x0000 0xE000 -o  duo_cubix.s19 -Data_Only
	@rm duo_cubix.s
	@rm duo_cubix.s1

pc_cubix.s19: cubix.asm command.os comfile.os filesys.os  ../6809PC/cubix_values.asm ../6809PC/drivers.asm
	lwasm --define=6809PC --define=dist --6809  --6800compat cubix.asm -s --list=pc_cubix.lst --map=pc_cubix.map --output=pc_cubix.s --format=srec
	srec_cat  pc_cubix.s -exclude 0x0000 0xE000 -offset -0x8000 -o  pc_cubix.hex  -intel -address-length=2
	srec_cat  pc_cubix.s -exclude 0x0000 0xE000 -offset -0xE000 -o  pc_cubix.s1  -binary
	srec_cat  pc_cubix.s -exclude 0x0000 0xE000 -o  pc_cubix.s19 -Data_Only
	@rm pc_cubix.s
	@rm pc_cubix.s1

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