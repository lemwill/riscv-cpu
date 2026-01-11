import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge


@cocotb.test()
async def dff_simple_test(dut):
    """Basic test for CPU"""

    # Create a 10ns period clock (100MHz)
    clock = Clock(dut.clk, 10, unit="ns")
    # Start the clock
    cocotb.start_soon(clock.start(start_high=False))

    dut.rst.value = 1
    await RisingEdge(dut.clk)
    await RisingEdge(dut.clk)
    dut.rst.value = 0

    # Run for some cycles
    for i in range(100):
        await RisingEdge(dut.clk)
