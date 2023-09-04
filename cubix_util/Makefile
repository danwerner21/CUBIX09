all:  	asm.s19 asp.s19 basic.s19 build.s19 calc.s19 chgdisk.s19 chkdisk.s19 concat.s19 copy.s19 dir.s19 dirf.s19 ed.s19 edit.s19 edt.s19 \
 		flink.s19 forth.s19 help.s19 hexed.s19 ldir.s19 mapl.s19


asm.s19: asm.asm
	lwasm --6809 asm.asm -s --list=asm.lst --map=asm.map --output=asm.s --format=srec
	srec_cat asm.s -o asm.s19 -data-only
	sed -i -e '$$aS9' asm.s19
	@cp asm.s19 ../bin/utilities

asp.s19: asp.asm
	lwasm --6809 asp.asm -s --list=asp.lst --map=asp.map --output=asp.s --format=srec
	srec_cat asp.s -o asp.s19 -data-only
	sed -i -e '$$aS9' asp.s19
	@cp asp.s19 ../bin/utilities

basic.s19: basic.asm
	lwasm --6809 basic.asm -s --list=basic.lst --map=basic.map --output=basic.s --format=srec
	srec_cat basic.s -o basic.s19 -data-only
	sed -i -e '$$aS9' basic.s19
	@cp basic.s19 ../bin/utilities

build.s19: build.asm
	lwasm --6809 build.asm -s --list=build.lst --map=build.map --output=build.s --format=srec
	srec_cat build.s -o build.s19 -data-only
	sed -i -e '$$aS9' build.s19
	@cp build.s19 ../bin/utilities

calc.s19: calc.asm
	lwasm --6809 calc.asm -s --list=calc.lst --map=calc.map --output=calc.s --format=srec
	srec_cat calc.s -o calc.s19 -data-only
	sed -i -e '$$aS9' calc.s19
	@cp calc.s19 ../bin/utilities

chgdisk.s19: chgdisk.asm
	lwasm --6809 chgdisk.asm -s --list=chgdisk.lst --map=chgdisk.map --output=chgdisk.s --format=srec
	srec_cat chgdisk.s -o chgdisk.s19 -data-only
	sed -i -e '$$aS9' chgdisk.s19
	@cp chgdisk.s19 ../bin/utilities

chkdisk.s19: chkdisk.asm
	lwasm --6809 chkdisk.asm -s --list=chkdisk.lst --map=chkdisk.map --output=chkdisk.s --format=srec
	srec_cat chkdisk.s -o chkdisk.s19 -data-only
	sed -i -e '$$aS9' chkdisk.s19
	@cp chkdisk.s19 ../bin/utilities

concat.s19: concat.asm
	lwasm --6809 concat.asm -s --list=concat.lst --map=concat.map --output=concat.s --format=srec
	srec_cat concat.s -o concat.s19 -data-only
	sed -i -e '$$aS9' concat.s19
	@cp concat.s19 ../bin/utilities

copy.s19: copy.asm
	lwasm --6809 copy.asm -s --list=copy.lst --map=copy.map --output=copy.s --format=srec
	srec_cat copy.s -o copy.s19 -data-only
	sed -i -e '$$aS9' copy.s19
	@cp copy.s19 ../bin/utilities

dir.s19: dir.asm
	lwasm --6809 dir.asm -s --list=dir.lst --map=dir.map --output=dir.s --format=srec
	srec_cat dir.s -o dir.s19 -data-only
	sed -i -e '$$aS9' dir.s19
	@cp dir.s19 ../bin/utilities

dirf.s19: dirf.asm
	lwasm --6809 dirf.asm -s --list=dirf.lst --map=dirf.map --output=dirf.s --format=srec
	srec_cat dirf.s -o dirf.s19 -data-only
	sed -i -e '$$aS9' dirf.s19
	@cp dirf.s19 ../bin/utilities

ed.s19: ed.asm
	lwasm --6809 ed.asm -s --list=ed.lst --map=ed.map --output=ed.s --format=srec
	srec_cat ed.s -o ed.s19 -data-only
	sed -i -e '$$aS9' ed.s19
	@cp ed.s19 ../bin/utilities

edit.s19: edit.asm
	lwasm --6809 edit.asm -s --list=edit.lst --map=edit.map --output=edit.s --format=srec
	srec_cat edit.s -o edit.s19 -data-only
	sed -i -e '$$aS9' edit.s19
	@cp edit.s19 ../bin/utilities

edt.s19: edt.asm
	lwasm --6809 edt.asm -s --list=edt.lst --map=edt.map --output=edt.s --format=srec
	srec_cat edt.s -o edt.s19 -data-only
	sed -i -e '$$aS9' edt.s19
	@cp edt.s19 ../bin/utilities

flink.s19: flink.asm
	lwasm --6809 flink.asm -s --list=flink.lst --map=flink.map --output=flink.s --format=srec
	srec_cat flink.s -o flink.s19 -data-only
	sed -i -e '$$aS9' flink.s19
	@cp flink.s19 ../bin/utilities

forth.s19: forth.asm
	lwasm --6809 forth.asm -s --list=forth.lst --map=forth.map --output=forth.s --format=srec
	srec_cat forth.s -o forth.s19 -data-only
	sed -i -e '$$aS9' forth.s19
	@cp forth.s19 ../bin/utilities

help.s19: help.asm
	lwasm --6809 help.asm -s --list=help.lst --map=help.map --output=help.s --format=srec
	srec_cat help.s -o help.s19 -data-only
	sed -i -e '$$aS9' help.s19
	@cp help.s19 ../bin/utilities

hexed.s19: hexed.asm
	lwasm --6809 hexed.asm -s --list=hexed.lst --map=hexed.map --output=hexed.s --format=srec
	srec_cat hexed.s -o hexed.s19 -data-only
	sed -i -e '$$aS9' hexed.s19
	@cp hexed.s19 ../bin/utilities

ldir.s19: ldir.asm
	lwasm --6809 ldir.asm -s --list=ldir.lst --map=ldir.map --output=ldir.s --format=srec
	srec_cat ldir.s -o ldir.s19 -data-only
	sed -i -e '$$aS9' ldir.s19
	@cp ldir.s19 ../bin/utilities

mapl.s19: mapl.asm
	lwasm --6809 mapl.asm -s --list=mapl.lst --map=mapl.map --output=mapl.s --format=srec
	srec_cat mapl.s -o mapl.s19 -data-only
	sed -i -e '$$aS9' mapl.s19
	@cp mapl.s19 ../bin/utilities

pretty:
	cp *.asm ./backup
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/asm.asm asm.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/asp.asm asp.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/basic.asm basic.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/build.asm build.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/calc.asm calc.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/chgdisk.asm chgdisk.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/chkdisk.asm chkdisk.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/concat.asm concat.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/copy.asm copy.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/dir.asm dir.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/dirf.asm dirf.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/ed.asm ed.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/edit.asm edit.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/edt.asm edt.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/flink.asm flink.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/forth.asm forth.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/help.asm help.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/hexed.asm hexed.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/ldir.asm ldir.asm
	pretty6502 -p1 -a0 -du -mu -c50 -l ./backup/mapl.asm mapl.asm

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