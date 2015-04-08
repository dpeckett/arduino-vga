#!/bin/sh

avr-as -mmcu=atmega16u2 -o vga.o sync.s
avr-ld -m avr35 -o vga.bin vga.o
avr-objcopy -j .text -j .data -O ihex vga.bin vga.hex
