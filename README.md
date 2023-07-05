# riscv-cpu
This is a 32-bit CPU based on the RISC-V Instruction Set Architecture (ISA). 
It will include a 5-stage pipeline (Fetch, Decode, Execute, Memory and Write Back), 
an Arithmetic Logic Unit (ALU), a Control Unit, a Register file, and an Instruction Memory. 

# Prerequisites
## Verilator
Install latest version
https://verilator.org/guide/latest/install.html

## Cocotb
Install cocotb (>=1.8.0)
https://docs.cocotb.org/en/stable/install.html

# Run Cocotb Tests
```
cd verification
make
```
