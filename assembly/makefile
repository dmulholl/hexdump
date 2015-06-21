hexdump: hexdump.o
	ld -dynamic-linker /lib/ld-linux.so.2 -lc -o hexdump hexdump.o

hexdump.o: hexdump.s
	as -o hexdump.o hexdump.s

clean:
	rm hexdump hexdump.o
