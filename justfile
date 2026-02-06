_default:
    @just --choose

build:
    nasm boot.asm -f bin -o boot.bin
    cd kernel && cargo build --release && rust-objcopy -O binary target/x86_64-kernel/release/kernel kernel.bin
    cat boot.bin kernel/kernel.bin > os.bin
    # Pad os.bin to at least 3 sectors (bootloader + 4 kernel sectors)
    truncate -s 2560 os.bin

run: build
    qemu-system-x86_64 -hda os.bin

boot:
    nasm boot.asm -f bin -o boot.bin
    qemu-system-x86_64 -hda boot.bin

boot-32-bit:
    nasm boot.asm -f bin -o boot.bin
    qemu-system-i386 -hda boot.bin
