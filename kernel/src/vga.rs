pub struct Vga;

impl Vga {
    pub fn print_char(char: Char) {
        let vga_buffer = 0xB8000 as *mut u8;

        unsafe {
            *vga_buffer = char.ascii_character;
            *vga_buffer.offset(1) = char.color_code.to_byte();
        }
    }
}

pub struct Char {
    pub ascii_character: u8,
    pub color_code: ColorCode,
}

// note: this could be denser, stored in a single byte
pub struct ColorCode {
    pub fg: FgColor,
    pub bg: BgColor,
    pub blink: bool,
}

impl ColorCode {
    pub fn to_byte(&self) -> u8 {
        (self.blink as u8) << 7 | self.bg.to_byte() | self.fg.to_byte()
    }
}

pub enum FgColor {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Brown,
    LightGray,
    DarkGray,
    LightBlue,
    LightGreen,
    LightCyan,
    LightRed,
    LightMagenta,
    Yellow,
    White,
}

impl FgColor {
    pub fn to_byte(&self) -> u8 {
        use FgColor::*;
        match self {
            Black => 0,
            Blue => 1,
            Green => 2,
            Cyan => 3,
            Red => 4,
            Magenta => 5,
            Brown => 6,
            LightGray => 7,
            DarkGray => 8,
            LightBlue => 9,
            LightGreen => 10,
            LightCyan => 11,
            LightRed => 12,
            LightMagenta => 13,
            Yellow => 14,
            White => 15,
        }
    }
}

pub enum BgColor {
    Black,
    Blue,
    Green,
    Cyan,
    Red,
    Magenta,
    Brown,
    LightGray,
}

impl BgColor {
    fn to_byte(&self) -> u8 {
        (match self {
            BgColor::Black => 0,
            BgColor::Blue => 1,
            BgColor::Green => 2,
            BgColor::Cyan => 3,
            BgColor::Red => 4,
            BgColor::Magenta => 5,
            BgColor::Brown => 6,
            BgColor::LightGray => 7,
        }) << 4
    }
}
