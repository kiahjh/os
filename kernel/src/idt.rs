/// Interrupt Descriptor Table (IDT) module.
use core::ptr::addr_of;

use crate::{pic, vga::Vga};

#[repr(C, packed)]
#[derive(Copy, Clone)]
pub struct IdtEntry {
    offset_low: u16,
    selector: u16,
    ist: u8,
    type_attr: u8,
    offset_mid: u16,
    offset_high: u32,
    reserved: u32,
}

impl IdtEntry {
    pub const fn empty() -> Self {
        IdtEntry {
            offset_low: 0,
            selector: 0,
            ist: 0,
            type_attr: 0,
            offset_mid: 0,
            offset_high: 0,
            reserved: 0,
        }
    }

    pub fn new(handler: u64, selector: u16) -> Self {
        IdtEntry {
            offset_low: handler as u16,
            selector,
            ist: 0,
            type_attr: 0x8E,
            offset_mid: (handler >> 16) as u16,
            offset_high: (handler >> 32) as u32,
            reserved: 0,
        }
    }
}

#[repr(C, packed)]
pub struct IdtDescriptor {
    limit: u16,
    base: u64,
}

static mut IDT: [IdtEntry; 256] = [IdtEntry::empty(); 256];

pub fn load_idt() {
    unsafe {
        let handler_addr = keyboard_handler_wrapper as u64;
        IDT[33] = IdtEntry::new(handler_addr, 0x18)
    }

    let descriptor = IdtDescriptor {
        limit: (core::mem::size_of::<[IdtEntry; 256]>() - 1) as u16,
        base: addr_of!(IDT) as u64,
    };

    unsafe {
        core::arch::asm!("lidt[{}]", in(reg) &descriptor);
    }
}

#[unsafe(no_mangle)]
extern "C" fn keyboard_handler() {
    let scancode = pic::inb(0x60);
    let mut vga = Vga::new();

    unsafe {
        let high = scancode >> 4;
        let low = scancode & 0xF;
        let to_hex = |n: u8| -> u8 { if n < 10 { b'0' + n } else { b'A' + n - 10 } };
        vga.print_char(b'0');
        vga.print_char(b'x');
        vga.print_char(to_hex(high));
        vga.print_char(to_hex(low));
        vga.newline();
    }

    pic::send_eoi();
}

#[unsafe(no_mangle)]
#[unsafe(naked)]
unsafe extern "C" fn keyboard_handler_wrapper() {
    core::arch::naked_asm!(
        "push rax",
        "push rcx",
        "push rdx",
        "push rsi",
        "push rdi",
        "push r8",
        "push r9",
        "push r10",
        "push r11",
        "call keyboard_handler",
        "pop r11",
        "pop r10",
        "pop r9",
        "pop r8",
        "pop rdi",
        "pop rsi",
        "pop rdx",
        "pop rcx",
        "pop rax",
        "iretq",
    );
}
