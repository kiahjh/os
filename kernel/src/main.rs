#![no_std]
#![no_main]

use core::panic::PanicInfo;

use crate::vga::Vga;

mod vga;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    let mut vga = Vga::new();
    vga.println("Hello, Kiah!");
    vga.println("Hello, Luke!");
    vga.println("Hello, Kara!");
    vga.println("Hello, Ellie!");
    vga.println("Hello, Jenna!");
    vga.println("Hello, Luke!");
    vga.println("Hello, Luke!");

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
