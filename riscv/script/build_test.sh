#!/bin/sh
set -e
prefix='/mnt/d/Sam/environment/riscv-tool'
rpath=$prefix/bin/
# clearing test dir
rm -rf ../testdata
mkdir ../testdata
# compiling rom
${rpath}riscv32-unknown-elf-as -o ../sys/rom.o -march=rv32i ../sys/rom.s
# compiling testcase
cp ../testcase/${1%.*}.c ../testdata/test.c
${rpath}riscv32-unknown-elf-gcc -o ../testdata/test.o -I ../sys -c ../testdata/test.c -O2 -march=rv32i -mabi=ilp32 -Wall
# linking
${rpath}riscv32-unknown-elf-ld -T ../sys/memory.ld ../sys/rom.o ../testdata/test.o -L $prefix/riscv32-unknown-elf/lib/ -L $prefix/lib/gcc/riscv32-unknown-elf/10.1.0/ -lc -lgcc -lm -lnosys -o ../testdata/test.om
# converting to verilog format
${rpath}riscv32-unknown-elf-objcopy -O verilog ../testdata/test.om ../testdata/test.data
# converting to binary format(for ram uploading)
${rpath}riscv32-unknown-elf-objcopy -O binary ../testdata/test.om ../testdata/test.bin
# decompile (for debugging)
${rpath}riscv32-unknown-elf-objdump -D ../testdata/test.om > ../testdata/test.dump
