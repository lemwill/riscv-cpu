
import os
import random
from pathlib import Path

import cocotb
from cocotb.clock import Clock
from cocotb.runner import get_runner
from cocotb.triggers import RisingEdge
from cocotb.types import LogicArray


@cocotb.test()
async def dff_simple_test(dut):
    """Test that d propagates to q"""

    # Set initial input value to prevent it from floating
    # dut.inp.value = 0

    clock = Clock(dut.clk, 10, units="us")  # Create a 10us period clock on port clk
    # Start the clock. Start it low to avoid issues on the first RisingEdge
    cocotb.start_soon(clock.start(start_high=False))

    # Synchronize with the clock. This will regisiter the initial `d` value
    for i in range(10):
        await RisingEdge(dut.clk)


def test_simple_dff_runner():

    hdl_toplevel_lang = os.getenv("HDL_TOPLEVEL_LANG", "verilog")
    sim = os.getenv("SIM", "verilator")

    proj_path = Path(__file__).resolve().parent

    verilog_sources = []
    vhdl_sources = []

    if hdl_toplevel_lang == "verilog":
        verilog_sources = [proj_path / "dff.sv"]
    else:
        vhdl_sources = [proj_path / "dff.vhdl"]

    runner = get_runner(sim)

    print(runner)
    runner.build(
        hdl_toplevel="dff",
        verilog_sources=verilog_sources,
        vhdl_sources=vhdl_sources,
        always=True,
    )

    runner.test(hdl_toplevel="dff", test_module="test_dff,")


if __name__ == "__main__":
    test_simple_dff_runner()
