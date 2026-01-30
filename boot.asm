; boot.asm - Bootloader with string printing
[BITS 16]
[ORG 0x7C00]

start:
    ; Set up segment registers
    xor ax, ax      ; AX = 0
    mov ds, ax      ; Data Segment = 0
    mov es, ax      ; Extra Segment = 0
    ; Print our boot message
    mov si, real_mode_msg    ; SI points to our string
    call print_string
    cli
    lgdt [gdt_descriptor] ; load our GDT
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:protected_mode_start

; ----------------------------------------
; print_string: Prints a null-terminated string
; Input: SI = pointer to string
; ----------------------------------------
print_string:
    mov ah, 0x0E        ; BIOS teletype function
.loop:
    lodsb               ; Load byte at [SI] into AL, increment SI
    cmp al, 0           ; Is it null terminator?
    je .done            ; If yes, we're done
    int 0x10            ; Print character in AL
    jmp .loop           ; Next character
.done:
    ret

[BITS 32]
protected_mode_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    call protected_print
    hlt

protected_print:
    ; clear the screen
    mov edi, 0xB8000
    mov ecx, 2000
    mov eax, " "
    rep stosw

    ; print message
    mov eax, 0

print_loop:
    mov edi, 0xB8000

    push eax

    ; temporarily use ebx for eax*2
    mov ebx, eax
    mov eax, 2
    mul ebx

    add edi, eax ;eax now wrong
    mov ebx, edi
    add ebx, 1

    pop eax

    mov edx, protected_mode_msg
    add edx, eax

    mov cl, [edx]
    cmp cl, 0

    jne print_char
    ret

print_char:
    mov byte [edi], cl
    mov byte [ebx], 0x0F
    inc eax
    jmp print_loop

; ----------------------------------------
; Data
; ----------------------------------------
real_mode_msg: db "In real mode...", 0
protected_mode_msg: db "Welcome to protected mode :)", 0

; GDT
gdt_start:

gdt_null:
    dq 0

gdt_code:
    dw 0xFFFF       ; Limit bits 0-15 (how big the segment is)
    dw 0            ; Base bits 0-15 (where segment starts)
    db 0            ; Base bits 16-23
    db 10011010b    ; Access byte
    db 11001111b    ; Flags (4 bits) + Limit bits 16-19 (4 bits)
    db 0            ; Base bits 24-31

gdt_data:
    dw 0xFFFF       ; Limit bits 0-15
    dw 0            ; Base bits 0-15
    db 0            ; Base bits 16-23
    db 10010010b    ; Access byte (different!)
    db 11001111b    ; Flags + Limit bits 16-19
    db 0            ; Base bits 24-31

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT minus 1 (in bytes) always minus 1
    dd gdt_start                ; Address of GDT

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Padding and magic number
times 510-($-$$) db 0
dw 0xAA55
