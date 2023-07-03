# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

TOPLEVEL_LANG ?= verilog
SIM = verilator

VERILOG_SOURCES =  $(shell pwd)/common.sv $(shell pwd)/execution_unit.sv $(shell pwd)/cpu.sv
EXTRA_ARGS += --trace-fst --trace-structs --trace-max-array 2048
MODULE = test_dff
TOPLEVEL = cpu

include $(shell cocotb-config --makefiles)/Makefile.sim