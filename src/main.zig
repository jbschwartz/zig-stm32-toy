/// Busy wait for some amount of time.
fn delay() void {
    for (0..1000000) |_| {
        _ = asm volatile ("nop");
    }
}

export fn main() noreturn {
    // Turn on the clock to GPIOB by setting bit 18 of the RCC_AHBENR register.
    var register: *volatile u32 = @ptrFromInt(0x4002_1014);
    register.* |= (1 << 18);

    // Set pin 3 to output by setting `01` to bits 6/7 of the GPIO_MODER register.
    register = @ptrFromInt(0x4800_0400);
    register.* |= (1 << 6);
    register.* &= ~@as(u32, (1 << 7));

    register = @ptrFromInt(0x4800_0414);

    while (true) {
        // Blink the LED by toggling bit 3 of the GPIOB_ODR register.
        register.* |= (1 << 3);

        delay();

        register.* &= ~@as(u32, (1 << 3));

        delay();
    }
}
