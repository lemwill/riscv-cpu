# This file is public domain, it can be freely copied without restrictions.
# SPDX-License-Identifier: CC0-1.0

TOPLEVEL_LANG ?= verilog
SIM = verilator

VERILOG_SOURCES =  $(shell pwd)/../hdl/utilities/common.sv $(shell pwd)/../hdl/utilities/register_file.sv $(shell pwd)/../hdl/utilities/memory.sv $(shell pwd)/../hdl/utilities/arithmetic_logic_unit.sv $(shell pwd)/../hdl/pipeline_stages/fetch.sv $(shell pwd)/../hdl/pipeline_stages/decode.sv  $(shell pwd)/../hdl/pipeline_stages/execute.sv $(shell pwd)/../hdl/cpu.sv
EXTRA_ARGS += --trace-fst --trace-structs --trace-max-array 32768
MODULE = test_dff
TOPLEVEL = cpu
COCOTB_RESULTS_FILE = sim_build/results.xml

include $(shell cocotb-config --makefiles)/Makefile.sim