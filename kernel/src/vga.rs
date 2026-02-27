const VGA_START: u32 = 0xB8000;

pub struct Vga {
    line: u8,   // 0 - 24
    column: u8, // 0 - 79
}

impl Vga {
    pub fn new() -> Self {
        let mut new_vga = Vga { line: 0, column: 0 };
        new_vga.clear_all();
        new_vga
    }

    pub fn clear_all(&mut self) {
        for _ in 0..(80 * 25) {
            self.print_char(b' ');
        }
        self.line = 0;
        self.column = 0;
    }

    pub fn get_cursor_addr(&self) -> *mut u8 {
        let offset_index = (self.line as u32) * 80 + (self.column as u32);
        (VGA_START + offset_index * 2) as *mut u8
    }

    pub fn shift_cursor(&mut self) {
        if self.column == 79 {
            self.newline();
        } else {
            self.column += 1;
        }
    }

    pub fn newline(&mut self) {
        self.line += 1;
        self.column = 0;
    }

    pub fn print_char(&mut self, char: u8) {
        let char = Char::new(
            char,
            ColorCode {
                fg: FgColor::White,
                bg: BgColor::Black,
                blink: false,
            },
        );

        let cursor_addr = self.get_cursor_addr();

        unsafe {
            *cursor_addr = char.ascii_character;
            *cursor_addr.offset(1) = char.color_code.to_byte();
        };

        self.shift_cursor();
    }

    pub fn println(&mut self, text: &str) {
        for char in text.bytes() {
            self.print_char(char);
        }
        self.newline();
    }
}

pub struct Char {
    pub ascii_character: u8,
    pub color_code: ColorCode,
}

impl Char {
    pub fn new(ascii_character: u8, color_code: ColorCode) -> Self {
        Char {
            ascii_character,
            color_code,
        }
    }
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
