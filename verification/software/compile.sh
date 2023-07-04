riscv64-unknown-elf-as -o program.o program.s
riscv64-unknown-elf-ld -o program program.o
riscv64-unknown-elf-objcopy -O binary program program.bin
xxd -p -c 4 program.bin > program.hex
