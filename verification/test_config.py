import os
import platform
from cocotb_test.simulator import run
import pytest


tests_dir = os.path.dirname(__file__)
src_dir = os.path.dirname(__file__) + "/../src"

# https://veripool.org/papers/Verilator_Accelerated_OSDA2020.pdf
# Resources on accelerating Verilator
compile_args_value = [
    "--trace-fst",
    "--trace-structs",
    # "-Wno-WIDTHTRUNC",
    # "-Wno-WIDTHEXPAND",
    "-output-split",
    "15000",
    # "--trace-threads",
    # "2",
    # "-x-assign",
    # "fast",
    # "-x-initial",
    # "fast",
    # "--noassert",
    # "--prof-exec",
    # "--prof-cfuncs",
    # "--trace-max-array",
    # "600",
    # "--trace-max-width",
    # "600",
    "-j",
    "8",
    "-CFLAGS",
    "-O0",
    "--timescale",
    "1ns/10ps"
]

make_args_value = []
if platform.system() == "Darwin":  # Check if the OS is macOS
    make_args_value.extend(["CXX=clang++", "-j", "8"])


def test_dff_verilog():
    run(
        verilog_sources=[
            os.path.join(src_dir, "utilities/common.sv"),
            os.path.join(src_dir, "utilities/memory_interface.sv"),
            os.path.join(src_dir, "utilities/axi_stream.sv"),
            os.path.join(src_dir, "utilities/registers.sv"),
            os.path.join(src_dir, "utilities/sram.sv"),
            os.path.join(src_dir, "pipeline_stages/stage1_fetch.sv"),
            os.path.join(src_dir, "pipeline_stages/stage2_decode.sv"),
            os.path.join(src_dir, "pipeline_stages/stage3_execute.sv"),
            os.path.join(src_dir, "pipeline_stages/stage4_memory.sv"),
            os.path.join(src_dir, "pipeline_stages/stage5_writeback.sv"),
            os.path.join(src_dir, "pipeline_stages/instructioncache.sv"),
            os.path.join(src_dir, "pipeline_stages/datacache.sv"),
            os.path.join(src_dir, "pipeline_stages/forwarding_unit.sv"),
            os.path.join(src_dir, "cpu.sv")
        ],
        toplevel="cpu",
        module="tests.test_basic",
        compile_args=compile_args_value,
        sim_args=compile_args_value,
        make_args=make_args_value,
        waves=False,
    )
