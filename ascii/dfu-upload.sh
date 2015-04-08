#!/bin/sh

dfu-programmer atmega16u2 erase
dfu-programmer atmega16u2 flash "./vga.hex"
dfu-programmer atmega16u2 reset
