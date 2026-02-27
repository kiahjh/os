use core::arch::asm;

const PIC1_COMMAND: u16 = 0x20;
const PIC1_DATA: u16 = 0x21;
const PIC2_COMMAND: u16 = 0xA0;
const PIC2_DATA: u16 = 0xA1;

/// Write a byte to an x86 I/O port
fn outb(port: u16, value: u8) {
    unsafe {
        asm!("out dx, al", in("dx") port, in("al") value);
    }
}

/// Read a byte from an x86 I/O port
fn inb(port: u16) -> u8 {
    let value: u8;
    unsafe {
        asm!("in al, dx", in("dx") port, out("al") value);
    }
    value
}

pub fn remap() {
    unsafe {
        // Save current masks (which IRQs are enabled/disabled)
        let mask1 = inb(PIC1_DATA);
        let mask2 = inb(PIC2_DATA);
        // ICW1: start initialization sequence
        outb(PIC1_COMMAND, 0x11);
        outb(PIC2_COMMAND, 0x11);
        // ICW2: set interrupt vector offsets
        outb(PIC1_DATA, 0x20); // PIC1 starts at interrupt 32 (0x20)
        outb(PIC2_DATA, 0x28); // PIC2 starts at interrupt 40 (0x28)
        // ICW3: tell PICs about each other
        outb(PIC1_DATA, 0x04); // PIC1 has a slave on IRQ2
        outb(PIC2_DATA, 0x02); // PIC2 cascade identity
        // ICW4: set 8086 mode
        outb(PIC1_DATA, 0x01);
        outb(PIC2_DATA, 0x01);
        // Restore saved masks
        outb(PIC1_DATA, mask1);
        outb(PIC2_DATA, mask2);
    }
}

/// Send End of Interrupt signal to PIC1.
/// You MUST call this at the end of every IRQ handler,
/// otherwise the PIC won't send you any more interrupts.
pub fn send_eoi() {
    unsafe {
        outb(PIC1_COMMAND, 0x20);
    }
}

/// Unmask only IRQ1 (keyboard), mask everything else
pub fn unmask_keyboard() {
    unsafe {
        outb(PIC1_DATA, 0xFD); // 0xFD = 11111101 in binary — bit 1 is 0 (enabled), rest are 1 (masked)
        outb(PIC2_DATA, 0xFF); // mask all IRQs on PIC2
    }
}
