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
    mov esi, protected_success
    call protected_print_msg
    jmp check_cpuid

protected_print_msg:
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

    mov edx, esi
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

check_cpuid:
    pushfd                  ; Push FLAGS onto stack
    pop eax                 ; Pop into EAX
    mov ecx, eax            ; Save original in ECX
    xor eax, 1 << 21        ; Flip bit 21 (ID flag)
    push eax
    popfd                   ; Try to write it back to FLAGS
    pushfd
    pop eax                 ; Read FLAGS again
    push ecx
    popfd                   ; Restore original FLAGS
    cmp eax, ecx            ; Did bit 21 change?
    je no_cpuid             ; If same, CPUID not supported

check_long_mode:
    ; Check if extended CPUID functions are available
    mov eax, 0x80000000     ; Request highest extended function number
    cpuid
    cmp eax, 0x80000001     ; Do we have at least function 0x80000001?
    jb no_long_mode         ; If not, no Long Mode
    ; Check for Long Mode support
    mov eax, 0x80000001     ; Request extended feature flags
    cpuid
    test edx, 1 << 29       ; Bit 29 = Long Mode (LM) bit
    jz no_long_mode         ; If zero, no Long Mode
    ; If we get here, Long Mode is supported!
    mov esi, long_mode_ok_msg
    call protected_print_msg

setup_paging:
    ; Clear 3 pages (4096 * 3 = 12288 bytes) starting at 0x1000
    mov edi, 0x1000         ; Start address
    mov cr3, edi            ; Store PML4 address in CR3 (we'll need this later)
    xor eax, eax            ; EAX = 0
    mov ecx, 0x1000         ; 4096 bytes × 3 tables = 12288, in dwords = 3072
    rep stosd               ; Zero it all out

    ; PML4[0] -> points to PDPT
    mov edi, 0x1000             ; PML4 address
    mov dword [edi], 0x2003     ; PDPT address (0x2000) + flags (0x03)
    ; PDPT[0] -> points to PD
    mov edi, 0x2000             ; PDPT address
    mov dword [edi], 0x3003     ; PD address (0x3000) + flags (0x03)
    ; PD[0] -> maps 2MB page at physical address 0
    mov edi, 0x3000             ; PD address
    mov dword [edi], 0x0083     ; Physical address 0 + flags (0x83)

    ; Enable PAE (Physical Address Extension)
    mov eax, cr4
    or eax, 1 << 5              ; Set bit 5 (PAE)
    mov cr4, eax
    ; Enable Long Mode in EFER MSR
    mov ecx, 0xC0000080         ; EFER MSR number
    rdmsr                       ; Read MSR into edx:eax
    or eax, 1 << 8              ; Set bit 8 (Long Mode Enable)
    wrmsr                       ; Write it back
    ; Enable Paging
    mov eax, cr0
    or eax, 1 << 31             ; Set bit 31 (Paging)
    mov cr0, eax
    jmp CODE64_SEG:long_mode_start

; vvvvvvvvvvv error handlers vvvvvvvvvvvv

no_cpuid:
    mov esi, no_cpuid_msg
    call protected_print_msg
    hlt

no_long_mode:
    mov esi, no_long_mode_msg
    call protected_print_msg
    hlt

; ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^

; =======================================
;             64-bit
; =======================================

[BITS 64]
long_mode_start:
    ; Set up 64-bit data segments
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    ; We made it! Print something to prove it.
    mov rax, 0x0F640F6F0F4D0F21  ; "!Mo d" with attributes (reversed)
    mov qword [0xB8000], rax
    mov rax, 0x0F340F360F200F65  ; "e 64" with attributes
    mov qword [0xB8008], rax
    hlt


; ----------------------------------------
;                  Data
; ----------------------------------------
real_mode_msg: db "In real mode...", 0
protected_success: db "Welcome to protected mode :)", 0
no_cpuid_msg: db "Error: CPUID not supported", 0
no_long_mode_msg: db "Error: Long Mode not supported", 0
long_mode_ok_msg: db "Long Mode supported!", 0

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

gdt_code64:
    dw 0xFFFF       ; Limit bits 0-15
    dw 0            ; Base bits 0-15
    db 0            ; Base bits 16-23
    db 10011010b    ; Access byte (same as 32-bit code)
    db 10101111b    ; Flags: Long mode (bit 5), granularity
    db 0            ; Base bits 24-31

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1  ; Size of GDT minus 1 (in bytes) always minus 1
    dd gdt_start                ; Address of GDT

CODE_SEG equ gdt_code - gdt_start
CODE64_SEG equ gdt_code64 - gdt_start
DATA_SEG equ gdt_data - gdt_start

; Padding and magic number
times 510-($-$$) db 0
dw 0xAA55
