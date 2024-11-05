
all: reboot.bin

lbr: reboot.lbr

clean:
	rm -f reboot.lst
	rm -f reboot.bin
	rm -f reboot.lbr

reboot.bin: reboot.asm include/bios.inc include/kernel.inc
	asm02 -L -b reboot.asm
	rm -f reboot.build

reboot.lbr: reboot.bin
	rm -f reboot.lbr
	lbradd reboot.lbr reboot.bin

