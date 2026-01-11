/* Define memory regions */
MEMORY
{
    TEXT        (rx) : ORIGIN = 0x00000000, LENGTH = 0x00100000  /* 1 MB */
    DATA        (rw) : ORIGIN = 0x00100000, LENGTH = 0x00100000  /* 1 MB */
    SMALL_DATA  (rw) : ORIGIN = 0x00200000, LENGTH = 0x00008000  /* 32 KB */
    BSS         (rw) : ORIGIN = 0x00208000, LENGTH = 0x000F8000  /* 1 MB - 32 KB */
}

/* Sections */
SECTIONS
{
    /* .text section for code */
    .text : {
        *(.text)
        *(.text*)
        *(.rodata*)
        *(.rodata*)
        *(.eh_frame)
    } > TEXT

    /* .init section */
    .init : {
        KEEP(*(.init))
    } > TEXT

    /* .fini section */
    .fini : {
        KEEP(*(.fini))
    } > TEXT

    /* .ctors and .dtors for C++ constructors/destructors */
    .ctors : {
        KEEP(*(.ctors))
    } > DATA

    .dtors : {
        KEEP(*(.dtors))
    } > DATA

    /* .init_array and .fini_array sections */
    .init_array : {
        __init_array_start = .;
        KEEP(*(.init_array))
        __init_array_end = .;
    } > DATA

    .fini_array : {
        __fini_array_start = .;
        KEEP(*(.fini_array))
        __fini_array_end = .;
    } > DATA

    /* .data section for initialized data */
    .data : {
        _data = .;
        *(.data)
        *(.data*)
    } > DATA

    /* .sdata section for small initialized data */
    .sdata : {
        *(.sdata)
        *(.sdata*)
    } > SMALL_DATA

    /* .sbss section for small uninitialized data */
    .sbss : {
        *(.sbss)
        *(.sbss*)
    } > SMALL_DATA

    /* .bss section for uninitialized data */
    .bss : {
        __bss_start = .;
        *(.bss)
        *(.bss*)
        *(COMMON)
        _end = .;
    } > BSS

    /* Stack section */
    .stack (NOLOAD) : {
        . = ALIGN(8);
        _stack_start = .;
        . = . + 0x1000; /* Stack size: 4KB */
        _stack_end = .;
    } > BSS

    /* End of the program */
    _end_of_program = .;
}

/* Define __global_pointer$ */
__global_pointer$ = ORIGIN(SMALL_DATA) + (LENGTH(SMALL_DATA) / 2);
