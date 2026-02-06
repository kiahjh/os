_default:
    @just --choose

boot:
    nasm boot.asm -f bin -o boot.bin
    qemu-system-x86_64 -hda boot.bin

boot-32-bit:
    nasm boot.asm -f bin -o boot.bin
    qemu-system-i386 -hda boot.bin
