
boot.bin: boot.asm
	asm02 -L -b boot.asm
	rm -f boot.build

clean:
	rm -f boot.lst
	rm -f boot.bin

