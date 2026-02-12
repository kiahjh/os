#![no_std]
#![no_main]

use core::panic::PanicInfo;

use crate::vga::{BgColor, Char, ColorCode, FgColor, Vga};

mod vga;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    Vga::print_char(Char {
        ascii_character: b'M',
        color_code: ColorCode {
            fg: FgColor::Cyan,
            bg: BgColor::Brown,
            blink: false,
        },
    });

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
