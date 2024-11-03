
reboot.bin: reboot.asm
	asm02 -L -b reboot.asm
	rm -f reboot.build

clean:
	rm -f reboot.lst
	rm -f reboot.bin

