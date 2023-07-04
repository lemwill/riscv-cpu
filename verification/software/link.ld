/* Specify the output format */
OUTPUT_FORMAT("elf32-littleriscv", "elf32-littleriscv", "elf32-littleriscv")
OUTPUT_ARCH(riscv)

/* Program entry point */
ENTRY(_start)

/* Memory layout */
MEMORY
{
    RAM (wx) : ORIGIN = 0x00000000, LENGTH = 1K
}

/* Section placement */
SECTIONS
{
    /* Code section */
    .text : 
    {
        . = ALIGN(4);
        *(.text)
        *(.text.*)
        . = ALIGN(4);
    } > RAM

    /* Read-only data section */
    .rodata :
    {
        . = ALIGN(4);
        *(.rodata)
        *(.rodata.*)
        . = ALIGN(4);
    } > RAM

    /* Data section */
    .data : 
    {
        . = ALIGN(4);
        *(.data)
        *(.data.*)
        . = ALIGN(4);
    } > RAM

    /* BSS section */
    .bss : 
    {
        . = ALIGN(4);
        _bss = .;
        *(.bss)
        *(.bss.*)
        . = ALIGN(4);
        _ebss = .;
    } > RAM

    /* Stack and Heap */
    _end = .;
    PROVIDE(end = .);
    _stack_top = ORIGIN(RAM) + LENGTH(RAM);
}
