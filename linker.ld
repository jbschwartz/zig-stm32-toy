/* A basic linker script for the STM32F042x6. */

MEMORY
{
    FLASH (rx): ORIGIN = 0x08000000, LENGTH = 32K
    RAM (rxw): ORIGIN = 0x20000000, LENGTH = 6K
}

/* Note the start of the stack for the vector table. */
_stack_start_address = ORIGIN(RAM) + LENGTH(RAM);

/* Ensure that the vector table is included by the linker. */
EXTERN(vector_table);

/* Weakly default handlers if they are not defined in the program. */
PROVIDE(nmiHandler = defaultHandler);
PROVIDE(hardFaultHandler = defaultHandler);
PROVIDE(svCallHandler = defaultHandler);
PROVIDE(pendSVHandler = defaultHandler);
PROVIDE(sysTickHandler = defaultHandler);

SECTIONS
{
    .text : {
        . = ALIGN(4);

        *(.vector_table)
        *(.text)

        . = ALIGN(4);
    } >FLASH

    .data : {
        . = ALIGN(4);
        _data_start_address = .;

        *(.data)
        *(.data*)

        . = ALIGN(4);
        _data_end_address = .;
    } >RAM AT >FLASH

    /* Get the address of the data section in flash. */
    _data_source_address = LOADADDR(.data);

    .bss : {
        . = ALIGN(4);
        _bss_start_address = .;

        *(.bss)
        *(.bss*)

        . = ALIGN(4);
        _bss_end_address = .;
    } >RAM

    /DISCARD/ : {
        *(.ARM.attributes)
        *(.ARM.exidx)
    }
}
