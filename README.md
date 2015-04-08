# arduino-vga

Generating VGA video with an Arduino Uno / Atmega16u2 Microcontroller.

**To Connect (atmega16u2):**
* Connect all grounds on the VGA connector together.
* Connect VGA ground to the Arduino Gnd.
* Place a 120ohm resistor from the MOSI2 pin (Pin 4 on ICSP) to PB7 (Pin 4 on JP2)
* Connect the VGA red, blue and green inputs together and connect to PB7.
* Connect VGA vsync to PB5 (Pin 3 on JP2).
* Connect VGA hsync to PB4 (Pin 1 on JP2).

**To Assemble:**
* avr-as -mmcu=atmega16u2 -o ghettovga.o ghettovga.s
* avr-ld -m avr35 -o ghettovga.bin ghettovga.o
* avr-objcopy -j .text -j .data -O ihex ghettovga.bin vghettovga.hex

**To Upload:**
* Temporarily short pins 5 and 6 on the atmega16u2 ICSP header.
* dfu-programmer atmega16u2 erase
* dfu-programmer atmega16u2 flash "./ghettovga.hex"
* dfu-programmer atmega16u2 reset

**To Restore Arduino Bootloader**
* Temporarily short pins 5 and 6 on the atmega16u2 ICSP header.
* Retrieve the appropriate usb-serial hex from: http://bit.ly/1E3pMbU
* Use dfu-programmer to flash hex to atmega16u2

Font glyphs copyright (c) 1981 Michael C. Koss http://mckoss.com/jscript/tinyalice.htm