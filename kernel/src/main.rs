#![no_std]
#![no_main]
#![allow(unused)]

use crate::vga::Vga;
use core::panic::PanicInfo;

mod idt;
mod pic;
mod vga;

#[unsafe(no_mangle)]
pub extern "C" fn _start() -> ! {
    idt::load_idt();
    pic::remap();
    pic::unmask_keyboard();

    // enable interrupts
    unsafe { core::arch::asm!("sti") }

    let mut vga = Vga::new();
    vga.println("> $ ");

    loop {}
}

#[panic_handler]
fn panic(_info: &PanicInfo) -> ! {
    loop {}
}
