# Os creation
**Real Mode**: 16-bit
**Protected Mode**: 32-bit
**Long Mode**: 64-bit
## asm reference
cmp: compares two things, then sets some flag somewhere if they are equal, and something else if their not, and then
jne/je: jump if not equal/equal
db: define byte
mov: move value from one register to another


## `boot.asm` v1 file
```asm
; boot.asm
    cli
hang:
    jmp hang

    times 512-($-$$) db 0
    db 0x55
    db 0xAA
```

Boot sector loaded by BIOS is 512 bytes. Hence why it has `times 512-($-$$) db 0`.

## `boot.asm` v2 file
```asm
    mov ax, 0x7c0
    mov ds, ax

    mov si, msg
    cld
ch_loop:lodsb
    or al, al
    jz hang
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp ch_loop

hang:
    jmp hang
    msg db 'Hello, World', 13, 10, 0
    times 510-($-$$) db 0
    db 0x55
    db 0xAA
```
in `msg db 'Hello, World', 13, 10, 0` -> 13: /r, 10: /n, 0: null terminator

## `boot.asm` v3
```asm
[ORG 0x7c00]
    xor ax, ax
    mov ds, ax
    cld

    mov si, welcome_msg
    call bios_print

hang:
    jmp hang

    welcome_msg db 'Hello, World', 13, 10, 0

bios_print:
    lodsb
    or al, al
    jz done
    mov ah, 0x0E
    mov bh, 0
    int 0x10
    jmp bios_print

done:
    ret

    times 510-($-$$) db 0
    db 0x55
    db 0xAA
```

## `boot.asm` v4
added macro
```asm
%macro BiosPrint 1
    mov si, word %1
ch_loop:lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp ch_loop
done:
%endmacro

[ORG 0x7c00]
    xor ax, ax
    mov ds, ax
    cld

    BiosPrint msg ; called here

hang:
    jmp hang

    welcome_msg db 'Hello, World', 13, 10, 0

    times 510-($-$$) db 0
    db 0x55
    db 0xAA
```

## `boot.asm` v5
added macro
```asm
%macro BiosPrint 1
    mov si, word %1
ch_loop:lodsb
    or al, al
    jz done
    mov ah, 0x0E
    int 0x10
    jmp ch_loop
done:
%endmacro

[ORG 0x7c00]
    xor ax, ax
    mov ds, ax
    cld

    BiosPrint welcome_msg ; called here

hang:
    jmp hang

    welcome_msg db 'Hello, World', 13, 10, 0

    times 510-($-$$) db 0
    db 0x55
    db 0xAA
```

## Questions for AI
To look up: `cld`, `lodsb` -> `cld`: clear direction flag, `lodsb`: load byte from memory into `AL` and increment `RSI`

## Random test
created encode.asm
```asm
mov cx, 0xFF
times 510-($-$$) db 0
db 0x55
db 0xAA
```
ran `hexdump encode.bin`, and got hex output. 
`cx` register in 16-bit (Real Mode)
`ecx` register in 32-bit (Protected Mode)
`rcx` register in 64-bit (Long Mode)
if you use ecx in 16-bit, it will over-ride something

## Babystep 4: rewrite boot.asm (v6)

## dereferencing pointers
```c
int my_name = 7;
int* my_ptr = &my_name;

int my_func(int a, int b) {
    return a + b;
}

my_func(my_ptr, 8);
```

`*my_ptr` <- c or rust
`[my_ptr]` <- asm
