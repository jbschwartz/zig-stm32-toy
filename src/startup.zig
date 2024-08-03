// Symbols are provided by the linker script.
extern const _stack_start_address: u32;

extern const _data_source_address: u32;
extern var _data_start_address: u32;
extern const _data_end_address: u32;

extern var _bss_start_address: u32;
extern const _bss_end_address: u32;

const Vector = ?*const fn () callconv(.C) void;

// The linker weakly assigns these symbols to the default handler.
extern fn nmiHandler() void;
extern fn hardFaultHandler() void;
extern fn svCallHandler() void;
extern fn pendSVHandler() void;
extern fn sysTickHandler() void;

export const vector_table linksection(".vector_table") = [_]Vector{
    @ptrCast(&_stack_start_address),
    // The reset handler is a naked function so cast for the correct calling convention.
    @ptrCast(&resetHandler),
    nmiHandler,
    hardFaultHandler,
    null,
    null,
    null,
    null,
    null,
    null,
    null,
    svCallHandler,
    null,
    pendSVHandler,
    sysTickHandler,
};

// The linker looks for a `defaultHandler` symbol.
export fn defaultHandler() void {
    while (true) {}
}

export fn resetHandler() callconv(.Naked) noreturn {
    // Set the stack pointer.
    _ = asm volatile (
        \\ ldr r0, =_stack_start_address
        \\ mov sp, r0
    );

    const bss_start_address: [*]u8 = @ptrCast(&_bss_start_address);
    const bss_end_address: [*]const u8 = @ptrCast(&_bss_end_address);
    const bss_size = @intFromPtr(bss_end_address) - @intFromPtr(bss_start_address);

    // Zero out the BSS section.
    for (bss_start_address[0..bss_size]) |*byte| {
        byte.* = 0;
    }

    const data_source_address: [*]const u8 = @ptrCast(&_data_source_address);
    const data_size = @intFromPtr(&_data_end_address) - @intFromPtr(&_data_start_address);

    const source_data: []const u8 = data_source_address[0..data_size];
    const destination_data: [*]u8 = @ptrCast(&_data_start_address);

    // Copy the data section from flash to RAM.
    for (source_data, destination_data) |source_byte, *destination_byte| {
        destination_byte.* = source_byte;
    }

    // Enable the clock for SYSCFG and COMP.
    var register: *volatile u32 = @ptrFromInt(0x40021018);
    register.* = 0x00000001;

    // Map the memory to the main flash.
    register = @ptrFromInt(0x40010000);
    register.* = 0x00000000;

    // Branch off the main function.
    _ = asm volatile ("b main");
}

// "F:\arm-gnu\13.3 rel1\bin\arm-none-eabi-objdump.exe" -D -Mforce-thumb .\zig-out\bin\zig32.elf
// arm-none-eabi-objcopy .\zig-out\bin\zig32.elf -O binary zig32.bin
