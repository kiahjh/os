# Os creation
**Real Mode**: 16-bit  
**Protected Mode**: 32-bit  
**Long Mode**: 64-bit  
## asm reference
- cmp: compares two things, then sets some flag somewhere if they are equal, and something else if their not.
- jne/je: jump if not equal/equal
- db: define byte
- mov: copy value from one register to another


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

## Babystep 4: rewrite boot.asm (v5)
avoiding using the BIOS `int` printing capabilities
```asm
[ORG 0x7c00]      ; add to offsets
   xor ax, ax    ; make it zero
   mov ds, ax   ; DS=0
   mov ss, ax   ; stack starts at 0
   mov sp, 0x9c00   ; 2000h past code start

   cld

   mov ax, 0xb800   ; text video memory
   mov es, ax

   mov si, msg   ; show text string
   call sprint

   mov ax, 0xb800   ; look at video mem
   mov gs, ax
   mov bx, 0x0000   ; 'W'=57 attrib=0F
   mov ax, [gs:bx]

   mov  word [reg16], ax ;look at register
   call printreg16

hang:
   jmp hang

;----------------------
dochar:   call cprint         ; print one character
sprint:   lodsb      ; string char to AL
   cmp al, 0
   jne dochar   ; else, we're done
   add byte [ypos], 1   ;down one row
   mov byte [xpos], 0   ;back to left
   ret

cprint:   mov ah, 0x0F   ; attrib = white on black
   mov cx, ax    ; save char/attribute
   movzx ax, byte [ypos]
   mov dx, 160   ; 2 bytes (char/attrib)
   mul dx      ; for 80 columns
   movzx bx, byte [xpos]
   shl bx, 1    ; times 2 to skip attrib

   mov di, 0        ; start of video memory
   add di, ax      ; add y offset
   add di, bx      ; add x offset

   mov ax, cx        ; restore char/attribute
   stosw              ; write char/attribute
   add byte [xpos], 1  ; advance to right

   ret

;------------------------------------

printreg16:
   mov di, outstr16
   mov ax, [reg16]
   mov si, hexstr
   mov cx, 4   ;four places
hexloop:
   rol ax, 4   ;leftmost will
   mov bx, ax   ; become
   and bx, 0x0f   ; rightmost
   mov bl, [si + bx];index into hexstr
   mov [di], bl
   inc di
   dec cx
   jnz hexloop

   mov si, outstr16
   call sprint

   ret

;------------------------------------

xpos   db 0
ypos   db 0
hexstr   db '0123456789ABCDEF'
outstr16   db '0000', 0  ;register value string
reg16   dw    0  ; pass values to printreg16
msg   db "What are you doing, Dave?", 0
times 510-($-$$) db 0
db 0x55
db 0xAA
;==================================
```

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
