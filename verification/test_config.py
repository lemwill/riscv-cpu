import os
import platform
from cocotb_test.simulator import run
import pytest
import inspect

tests_dir = os.path.dirname(__file__)
src_dir = os.path.dirname(__file__) + "/../src"

os.environ["SIM"] = "verilator"

# https://veripool.org/papers/Verilator_Accelerated_OSDA2020.pdf
# Resources on accelerating Verilator
compile_args_value = [
    "--trace",
    "--trace-fst",
    "--trace-structs",
    "--public-flat-rw",
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
    "--trace-max-array",
    "4000",
    "--trace-max-width",
    "4000",
    "-j",
    "8",
    "-CFLAGS",
    "-O0",
    "--timescale",
    "1ns/10ps",
]

make_args_value = []
if platform.system() == "Darwin":  # Check if the OS is macOS
    make_args_value.extend(["CXX=clang++", "-j", "8"])

verilog_sources = [
    os.path.join(src_dir, "utilities/common.sv"),
    os.path.join(src_dir, "utilities/memory_interface.sv"),
    os.path.join(src_dir, "utilities/axi_stream.sv"),
    os.path.join(src_dir, "utilities/registers.sv"),
    os.path.join(src_dir, "utilities/pipeline_logger.sv"),
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
]


# def test_dff_verilog():
#     run(
#         verilog_sources=[
#             os.path.join(src_dir, "utilities/common.sv"),
#             os.path.join(src_dir, "utilities/memory_interface.sv"),
#             os.path.join(src_dir, "utilities/axi_stream.sv"),
#             os.path.join(src_dir, "utilities/registers.sv"),
#             os.path.join(src_dir, "utilities/pipeline_logger.sv"),
#             os.path.join(src_dir, "utilities/sram.sv"),
#             os.path.join(src_dir, "pipeline_stages/stage1_fetch.sv"),
#             os.path.join(src_dir, "pipeline_stages/stage2_decode.sv"),
#             os.path.join(src_dir, "pipeline_stages/stage3_execute.sv"),
#             os.path.join(src_dir, "pipeline_stages/stage4_memory.sv"),
#             os.path.join(src_dir, "pipeline_stages/stage5_writeback.sv"),
#             os.path.join(src_dir, "pipeline_stages/instructioncache.sv"),
#             os.path.join(src_dir, "pipeline_stages/datacache.sv"),
#             os.path.join(src_dir, "pipeline_stages/forwarding_unit.sv"),
#             os.path.join(src_dir, "cpu.sv")
#         ],
#         toplevel="cpu",
#         module="tests.test_basic",
#         compile_args=compile_args_value,
#         sim_args=compile_args_value,
#         make_args=make_args_value,
#         waves=False,
#         sim_build="output"
#     )


def format_parameters(parameters):
    """Convert parameters dictionary to a path-friendly string."""
    return "__".join(f"{key}_{value}" for key, value in parameters.items())


def run_test(parameters=None):
    # Get the calling function's name
    caller_function_name = inspect.stack()[1].function
    print(caller_function_name)
    print("==================================================================================================")
    formatted_parameters = format_parameters(parameters or {})
    sim_build_path = os.path.join(
        "output/", f"{caller_function_name}_{formatted_parameters}")

    print(f"tests.{caller_function_name}")

    run(
        parameters=parameters or {},
        extra_env=parameters or {},
        verilog_sources=verilog_sources,
        toplevel="cpu",
        # Use the function name as the module
        module=f"tests.{caller_function_name}",
        compile_args=compile_args_value,
        sim_args=compile_args_value,
        plus_args=["--trace"],
        sim_build=sim_build_path,
        make_args=make_args_value,
        waves=False,
    )
