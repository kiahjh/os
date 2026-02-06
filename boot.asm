; boot.asm - Bootloader with string printing
[BITS 16]
[ORG 0x7C00]

start:
    ; Set up segment registers
    xor ax, ax          ; AX = 0
    mov ds, ax          ; Data Segment = 0
    mov es, ax          ; Extra Segment = 0

    ; Load kernel from disk
    mov ah, 0x02        ; BIOS read sectors function
    mov al, 4           ; Number of sectors to read (4 x 512 = 2KB)
    mov ch, 0           ; Cylinder 0
    mov cl, 2           ; Start from sector 2 (sector 1 is our bootloader)
    mov dh, 0           ; Head 0
    mov dl, 0x80        ; First hard drive
    mov bx, 0x8000      ; Destination address (ES:BX)
    int 0x13            ; Call BIOS
    jc disk_error       ; Jump if carry flag set (error)

    cli
    lgdt [gdt_descriptor] ; load our GDT
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:protected_mode_start

[BITS 32]
protected_mode_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    jmp check_cpuid

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
    hlt

no_long_mode:
    hlt

disk_error:
    ; Print 'E' and the error code in AH
    mov ah, 0x0E
    mov al, 'E'
    int 0x10
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

    ; Jump to the kernel
    mov rax, 0x8000
    jmp rax

; ----------------------------------------
;                  Data
; ----------------------------------------

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
