# GhettoVGA v0.2 (http://dpeckett.com)
# No Fuss VGA for the Arduino uno rev3 and similar.
#
# Copyright (c) 2015, DAMIAN PECKETT <damian@pecke.tt>
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
# 
# 1. Redistributions of source code must retain the above copyright notice, this
#    list of conditions and the following disclaimer. 
# 2. Redistributions in binary form must reproduce the above copyright notice,
#    this list of conditions and the following disclaimer in the documentation
#    and/or other materials provided with the distribution.
# 
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS" AND
# ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
# WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE
# DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR
# ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES
# (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
# LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND
# ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
# (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
# SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
#
# Font glyphs copyright (c) 1981 Michael C. Koss
# http://mckoss.com/jscript/tinyalice.htm
#
# To Connect (atmega16u2):
# Connect all grounds on the VGA connector together.
# Connect VGA ground to the Arduino Gnd.
# Place a 120ohm resistor from the MOSI2 pin (Pin 4 on ICSP) to PB7 (Pin 4 on JP2)
# *Optional Protection* Place a 1N4148 diode from PB7 (anode) to Gnd (cathode). 
# Connect the VGA red, blue and green inputs together and connect to PB7.
# Connect VGA vsync to PB5 (Pin 3 on JP2).
# Connect VGA hsync to PB4 (Pin 1 on JP2).
#
# To Assemble:
# avr-as -mmcu=atmega16u2 -o ghettovga.o ghettovga.s
# avr-ld -m avr35 -o ghettovga.bin ghettovga.o
# avr-objcopy -j .text -j .data -O ihex ghettovga.bin vghettovga.hex
#
# To Upload:
# Temporarily short pins 5 and 6 on the atmega16u2 ICSP header.
# dfu-programmer atmega16u2 erase
# dfu-programmer atmega16u2 flash "./ghettovga.hex"
# dfu-programmer atmega16u2 reset
#
# To Restore Arduino Bootloader
# Temporarily short pins 5 and 6 on the atmega16u2 ICSP header.
# Retrieve the appropriate usb-serial hex from:
# https://github.com/arduino/Arduino/tree/master/hardware/arduino/avr/firmwares/atmegaxxu2/arduino-usbserial
# Use dfu-programmer to flash hex to atmega16u2
#
# This source code is a work in progress and probably requires a thorough
# refactor. There are likely many bugs, please email me if you think you 
# can fix one! This code generates a very tight VGA signal that should work with
# the great majority of monitors, digital and analog.

# Output pins
.equ DD_SS, 0
.equ DD_SCK, 1
.equ DD_MOSI, 2
.equ HSYNC, 4
.equ VSYNC, 5
.equ BLANK, 7

# LED pins
.equ RXLED, 4
.equ TXLED, 5

# Ports
.equ SFR_DDRB,  0x04
.equ SFR_PORTB, 0x05
.equ SFR_DDRD,  0x0A
.equ SFR_PORTD, 0x0B
.equ TCCR0B, 0x45
.equ TCNT0,  0x46
.equ TIMSK0, 0x6E
.equ TCCR1B, 0x81
.equ TCNT1L, 0x84
.equ TCNT1H, 0x85
.equ TIMSK1, 0x6F
.equ OCR1AL, 0x88
.equ OCR1AH, 0x89
.equ OCR1BL, 0x8A
.equ OCR1BH, 0x8B
.equ OCR1CL, 0x8C
.equ OCR1CH, 0x8D
.equ SPCR, 0x4C
.equ SPSR, 0x4D
.equ SPDR, 0x4E
.equ SREG, 0x3F
.equ UDR1, 0xCE
.equ UBRR1L, 0xCC
.equ UBRR1H, 0xCD
.equ UCSR1A, 0xC8
.equ UCSR1B, 0xC9
.equ UCSR1C, 0xCA
.equ UCSR1D, 0xCB

# special registers
.equ XLO, 26
.equ XHI, 27
.equ YLO, 28
.equ YHI, 29
.equ ZLO, 30
.equ ZHI, 31

# variables
.equ status,         16
.equ tmp,            17
.equ tmp2,           18
.equ tmp3,           19
.equ hcount,         20
.equ hvar,           21
.equ v_hdr_indx,     22
.equ v_text_indx,    23
.equ v_subchar_indx, 24

# used for flashing characters
.equ timvfcnt,       25 
.equ blink,          5

# line offset counter
.equ line_base_lo, 14
.equ line_base_hi, 15

# counter for screen scroll
.equ scroll_dst_lo, 10
.equ scroll_dst_hi, 11
.equ scroll_src_lo, 12
.equ scroll_src_hi, 13

# Buffer for serial commands
# Using registers in order to keep SRAM free
.equ ser0, 6
.equ ser1, 7
.equ ser2, 8
.equ ser3, 9

# interrupt vector table for atmega16u2
.org 0x00
jmp reset
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp new_line
jmp active_video
jmp hsync_pulse
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl
jmp unhndl

#---------
unhndl:
reti

# --------
reset:

# set up stack
ldi	tmp, 0xFF
out	0x3d, tmp
ldi	tmp, 0x02
out	0x3e, tmp

jmp main

# --------
# Disable HSYNC and during backporch period prepare for next line
new_line:
# save status register
in status, SREG

# Got roughly 20 cycles to prepare for new line

# Are we in an active pixel region?
cpi v_hdr_indx, 45
brlo v_header
brsh v_active

v_header:
# vertical front porch region, first 10 lines
cpi v_hdr_indx, 10
brlo v_header_blank

# vsync region, lines 10/11
cpi v_hdr_indx, 12
brlo v_sync

# vertical backporch region, 33 lines
cpi v_hdr_indx, 13
brsh v_header_blank

# Finish Vsync pulse, v_hdr_indx = 13
# disable vsync
sbi SFR_PORTB, VSYNC

v_header_blank:
# Disable hsync
sbi SFR_PORTB, HSYNC

# increment and continue
inc v_hdr_indx
rjmp finish_new_line

v_active:
# Disable hsync
sbi SFR_PORTB, HSYNC

# are we done?
# 15 Vertical Lines
cpi v_text_indx, 15
brne finish_new_line

# We are done,
# Starting new frame
clr v_hdr_indx
clr v_text_indx
clr v_subchar_indx

# Return character pointer to start of memory
# Line counter points to 0x100
ldi tmp2, 0x01
mov line_base_hi, tmp2
clr line_base_lo

rjmp v_header_blank

v_sync:
# increment header index
inc v_hdr_indx
# enable vsync/hsync
cbi SFR_PORTB, VSYNC
cbi SFR_PORTB, HSYNC

# increment blink frame counter
inc timvfcnt

# trigger at roughly 2 hz
sbrs timvfcnt, 5
rjmp clear_blink

# blink bit must be set
ldi tmp2, 0x80
mov blink, tmp2
rjmp finish_new_line

# clear blink bit
clear_blink:
clr blink

finish_new_line:
# restore character counter to parent line
mov XHI, line_base_hi
mov XLO, line_base_lo

# restore status register
out SREG, status
reti

# --------
# Begin Putting Pixels On The Screen
active_video:
# save status register
in status, SREG

# Don't draw in vsync region
cpi v_hdr_indx, 10
breq finish_video_line
cpi v_hdr_indx, 11
breq finish_video_line

# Unblank Video
cbi SFR_DDRB, BLANK

# 32 horizontal characters
# 2 characters per byte
ldi hcount, 16

# Preload first byte to be drawn to screen
ld ZLO, X+
eor ZLO, blink
lpm hvar, Z
swap hvar
ld ZLO, X+
eor ZLO, blink
lpm tmp2, Z
or hvar, tmp2

# Start delay to center video
ldi tmp2, 8
pixel_start_del:
dec tmp2
brne pixel_start_del

# Main pixel writing loop, 19 cycles per iteration
pixel_loop:
# 2 cycle
sts SPDR, hvar

# first character, 7 cycles
ld ZLO, X+
eor ZLO, blink
lpm hvar, Z
swap hvar
# second character. 7 cycles
ld ZLO, X+
eor ZLO, blink
lpm tmp2, Z
or hvar, tmp2

# 3 cycles
dec hcount
brne pixel_loop

# Right margin after text
ldi tmp2, 14
pixel_end_del:
dec tmp2
brne pixel_end_del

finish_video_line:

# Blank video
sbi SFR_DDRB, BLANK

# restore status register
out SREG, status
reti

# --------
# Fire hsync to finish line
hsync_pulse:
# save status register
in status, SREG

# Enable hsync, active low
cbi SFR_PORTB, HSYNC

# Skip increments on header lines
# header = (10 lines front porch + 2 lines sync + 33 lines back porch)
cpi v_hdr_indx, 45
brlo line_finish

# Got ~30 cycles to finish this line

# Increment sub character counter
inc v_subchar_indx

# Are we done with this character?
# 32 VGA lines per character 480/32 = 15 lines
cpi v_subchar_indx, 32
brlo same_character

# Yep new character
clr v_subchar_indx

# Increment the number of text rows
inc v_text_indx

# New row, increment to next character row
# 32 characters per horizontal line
ldi tmp2, 32
add line_base_lo, tmp2
clr tmp2
adc line_base_hi, tmp2

# Still rendering the same character
same_character:

# Blank upper/lower two lines of character
# Vertical space between character rows 
# blocks 0-2 are blank
cpi v_subchar_indx, 2
brlo charpage6

# blocks 2-7 are first pixel
cpi v_subchar_indx, 7
brlo charpage1

# blocks 7-13 are second pixel
cpi v_subchar_indx, 13
brlo charpage2

# blocks 13-19 are third pixel
cpi v_subchar_indx, 19
brlo charpage3

# blocks 19-25 are fourth pixel
cpi v_subchar_indx, 25
brlo charpage4

# blocks 25-30 are fifth pixel
cpi v_subchar_indx, 30
brlo charpage5

# blocks 30-32 are blank
rjmp charpage6

# Pretty messy but 32px/5px does not result in a power of 2, no bitwise cheating
# Not particularly slow however
charpage1:
ldi ZHI, 0x0A
rjmp line_finish

charpage2:
ldi ZHI, 0x0B
rjmp line_finish

charpage3:
ldi ZHI, 0x0C
rjmp line_finish

charpage4:
ldi ZHI, 0x0D
rjmp line_finish

charpage5:
ldi ZHI, 0x0E
rjmp line_finish

# the blank area
charpage6:
ldi ZHI, 0x0F

line_finish:
# restore status register
out SREG, status
reti

# --------
main:

#set portb pins as outputs
sbi SFR_DDRB, DD_SS
sbi SFR_DDRB, DD_SCK
sbi SFR_DDRB, DD_MOSI
sbi SFR_DDRB, HSYNC
sbi SFR_DDRB, VSYNC
# Enable blanking
sbi SFR_DDRB, BLANK

# set ss, vsync, and hsync high (active low)
sbi SFR_PORTB, DD_SS
sbi SFR_PORTB, HSYNC
sbi SFR_PORTB, VSYNC
# blanking pin will be pulled low by tristate
cbi SFR_PORTB, BLANK

# Serial leds
sbi SFR_DDRD, RXLED
sbi SFR_DDRD, TXLED
sbi SFR_PORTD, RXLED
sbi SFR_PORTD, TXLED

# extended IO access
clr YHI

# set the spi port to master
ldi tmp, 0x50
sts SPCR, tmp

# SPI double rate Fosc/2
ldi tmp, 0x01
sts SPSR, tmp

# Set USART to double speed mode
ldi tmp, 2
sts UCSR1A, tmp

# Set the USART baud rate to 115.2k
clr tmp
sts UBRR1H, tmp
ldi tmp, 16
sts UBRR1L, tmp

# Use 8 bit character size, 1 stop bit
ldi tmp, 0x06
sts UCSR1C, tmp

# Enable the USART receiver / transmitter
ldi tmp, 0x18
sts UCSR1B, tmp

# Each iteration takes 31.75us, 508 cycles
ldi tmp, 0x01
sts OCR1AH, tmp
ldi tmp, 0xFC
sts OCR1AL, tmp

# Begin active video after 1.89us, 30 cycles
ldi tmp, 0x00
sts OCR1BH, tmp
ldi tmp, 0x1E
sts OCR1BL, tmp

# Fire new hsync after 28us, 448 cycles
ldi tmp, 0x01
sts OCR1CH, tmp
ldi tmp, 0xC0
sts OCR1CL, tmp

# load default message into memory
ldi YHI, 0x01
clr YLO

# fill framebuffer with blank characters
ldi tmp, 240
ldi tmp3, 0xA0
fillmem:
st Y+, tmp3
st Y+, tmp3
dec tmp
brne fillmem

# clear counters
clr v_hdr_indx
clr v_text_indx
clr v_subchar_indx
ldi XHI, 0x01
clr XLO

# clear blink timers
clr timvfcnt
clr blink

# /1 scaler, CTC mode
ldi tmp, 0x09
sts TCCR1B, tmp

# enable interrupts
ldi tmp, 0x0e
sts TIMSK1, tmp

# Enable global interrupts
sei

# Loop to read in serial data
loop:
# Check if any serial data waiting
lds tmp, UCSR1A
sbrc tmp, 7
rjmp read_serial
rjmp loop

read_serial:
# Light up RX LED
cbi SFR_PORTD, RXLED

# shuffle serial buffer
mov ser0, ser1
mov ser1, ser2
mov ser2, ser3
lds tmp, UDR1
mov ser3, tmp

# Have to use odd branch structure due to
# relocation limitation

# Was it a draw or write command?
# 0x8D, D=DRAW, 0xFA, A=ACCESS/READ
# 0x8C, C=CLEAR
mov tmp, ser0
cpi tmp, 0xFD
brne not_write_cmd
rjmp write_character

# Compare against read command
not_write_cmd:
mov tmp, ser1
cpi tmp, 0xFA
brne not_read_cmd
rjmp read_character

# Compare against scroll command
not_read_cmd:
mov tmp, ser3
cpi tmp, 0xFB
brne not_scroll_cmd
rjmp scroll_line

# Compare against clear command
not_scroll_cmd:
cpi tmp, 0xFC
brne not_clear_cmd
rjmp clear_screen

# Didn't match any commands continue
not_clear_cmd:
rjmp read_serial_end

clear_screen:

# Clear all the characters on the screen
ldi YHI, 0x01
clr YLO

# Fill all the pixels on the screen with blank characters
ldi tmp, 240
ldi tmp3, 0xA0
fillmem2:
st Y+, tmp3
st Y+, tmp3
dec tmp
brne fillmem2

# continue
rjmp read_serial_end

# Scroll the screen upwards a single line
scroll_line:

# Set up pointers
ldi tmp, 0x01
mov scroll_src_hi, tmp
mov scroll_dst_hi, tmp
ldi tmp, 0x20
mov scroll_src_lo, tmp
clr scroll_dst_lo

scroll_mem:
# set y to source pointer
mov YLO, scroll_src_lo
mov YHI, scroll_src_hi

# read character
ld tmp, Y+

# save pointer
mov scroll_src_lo, YLO
mov scroll_src_hi, YHI

# load destination pointer
mov YLO, scroll_dst_lo
mov YHI, scroll_dst_hi

# store character
st Y+, tmp

# save pointer
mov scroll_dst_lo, YLO
mov scroll_dst_hi, YHI

# Compare destination pointer to framebuffer end - 1line
ldi tmp, 0xC0
cp YLO, tmp
ldi tmp, 0x02
cpc YHI, tmp
brne scroll_mem

# continue
rjmp read_serial_end

read_character:
# Light up TXLED
cbi SFR_PORTD, TXLED

# parse x,y coordinate

# point at base sram address
# Add column offset to YLO
ldi YHI, 0x01
mov YLO, ser1

# Multiply the number of rows by 32 (number horizontal characters)
# Do this by shifting 4 bits to the left
# No hardware multiplication available
clr tmp
lsl ser2
rol tmp
lsl ser2
rol tmp
lsl ser2
rol tmp
lsl ser2
rol tmp
lsl ser2
rol tmp

# load character
ld tmp, Y

# Add the character row offset
add YLO, ser2
adc YHI, tmp

# Transmit character
# Make sure no tx pending
wait_serial_tx:
lds tmp3, UCSR1A
sbrs tmp3, 5
rjmp wait_serial_tx

# Write character
sts UDR1, tmp

# Clear TXLED
sbi SFR_PORTD, TXLED

# continue
rjmp read_serial_end

write_character:
# parse x,y coordinate

# point at base sram address
# Add column offset to YLO
ldi YHI, 0x01
mov YLO, ser1

# Multiply the number of rows by 32 (number horizontal characters)
# Do this by shifting 4 bits to the left
# No hardware multiplication available
clr tmp
lsl ser2
rol tmp
lsl ser2
rol tmp
lsl ser2
rol tmp
lsl ser2
rol tmp
lsl ser2
rol tmp

# Add the character row offset
add YLO, ser2
adc YHI, tmp

# Write character to frame buffer
st Y, ser3

read_serial_end:
# Clear RX Led
sbi SFR_PORTD, RXLED
rjmp loop

# ------- FONT GLYPH REGION --------
# BASED ON MCKOSS TINY ALICE
# http://mckoss.com/jscript/tinyalice.htm
# Implements ASCII character set from 0x20 - 0x60
# Plenty of room to implement full ascii charset
# Didn't need it in my project

# First row of each character
.org 0xA00
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x01
.byte 0x01
.byte 0x09
.byte 0x05
.byte 0x01
.byte 0x01
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x09
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x01
.byte 0x09
.byte 0x07
.byte 0x03
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x09
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0d
.byte 0x07
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x09
.byte 0x01
.byte 0x01
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x0f
.byte 0x07
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x01
.byte 0x01
.byte 0x09
.byte 0x05
.byte 0x01
.byte 0x01
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x09
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x01
.byte 0x09
.byte 0x07
.byte 0x03
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x09
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0d
.byte 0x07
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x09
.byte 0x01
.byte 0x01
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x0f
.byte 0x07
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x01
.byte 0x01
.byte 0x09
.byte 0x05
.byte 0x01
.byte 0x01
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x09
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x01
.byte 0x09
.byte 0x07
.byte 0x03
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x09
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0d
.byte 0x07
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x09
.byte 0x01
.byte 0x01
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x0f
.byte 0x07
.byte 0x0b
.byte 0x04
.byte 0x04
.byte 0x0c
.byte 0x04
.byte 0x0c
.byte 0x0e
.byte 0x0e
.byte 0x06
.byte 0x0a
.byte 0x0e
.byte 0x0e
.byte 0x0a
.byte 0x08
.byte 0x0a
.byte 0x0a
.byte 0x04
.byte 0x0c
.byte 0x04
.byte 0x0c
.byte 0x06
.byte 0x0e
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0e
.byte 0x06
.byte 0x08
.byte 0x0c
.byte 0x04
.byte 0x00
.byte 0x00
.byte 0x04
.byte 0x0a
.byte 0x0a
.byte 0x06
.byte 0x0a
.byte 0x04
.byte 0x04
.byte 0x02
.byte 0x08
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x02
.byte 0x0e
.byte 0x04
.byte 0x04
.byte 0x0c
.byte 0x0a
.byte 0x0e
.byte 0x06
.byte 0x0e
.byte 0x0e
.byte 0x04
.byte 0x00
.byte 0x00
.byte 0x02
.byte 0x00
.byte 0x08
.byte 0x04

# Second row of each character
.org 0xB00
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x07
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x07
.byte 0x01
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x01
.byte 0x03
.byte 0x0d
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x0d
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x0d
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x07
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x07
.byte 0x01
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x01
.byte 0x03
.byte 0x0d
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x0d
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x0d
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x07
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x07
.byte 0x01
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x01
.byte 0x03
.byte 0x0d
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0d
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x0d
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x0d
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0b
.byte 0x05
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x08
.byte 0x08
.byte 0x08
.byte 0x0a
.byte 0x04
.byte 0x04
.byte 0x0a
.byte 0x08
.byte 0x0e
.byte 0x0e
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x08
.byte 0x04
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x02
.byte 0x04
.byte 0x08
.byte 0x04
.byte 0x0a
.byte 0x00
.byte 0x00
.byte 0x04
.byte 0x0a
.byte 0x0e
.byte 0x0c
.byte 0x02
.byte 0x0a
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x0a
.byte 0x04
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x02
.byte 0x0a
.byte 0x0c
.byte 0x0a
.byte 0x02
.byte 0x0a
.byte 0x08
.byte 0x08
.byte 0x02
.byte 0x0a
.byte 0x0a
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x0e
.byte 0x04
.byte 0x0a

# Third row of each character
.org 0xC00
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x07
.byte 0x05
.byte 0x03
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x07
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x0f
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0f
.byte 0x01
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0d
.byte 0x0b
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x0b
.byte 0x01
.byte 0x09
.byte 0x0f
.byte 0x0f
.byte 0x07
.byte 0x0f
.byte 0x0d
.byte 0x0d
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x07
.byte 0x05
.byte 0x03
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x07
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x0f
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0f
.byte 0x01
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0d
.byte 0x0b
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x0b
.byte 0x01
.byte 0x09
.byte 0x0f
.byte 0x0f
.byte 0x07
.byte 0x0f
.byte 0x0d
.byte 0x0d
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x07
.byte 0x05
.byte 0x03
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x03
.byte 0x07
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x0f
.byte 0x05
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0f
.byte 0x01
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0d
.byte 0x0b
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x0b
.byte 0x01
.byte 0x09
.byte 0x0f
.byte 0x0f
.byte 0x07
.byte 0x0f
.byte 0x0d
.byte 0x0d
.byte 0x0e
.byte 0x0e
.byte 0x0c
.byte 0x08
.byte 0x0a
.byte 0x0c
.byte 0x0c
.byte 0x0a
.byte 0x0e
.byte 0x04
.byte 0x04
.byte 0x0c
.byte 0x08
.byte 0x0a
.byte 0x0e
.byte 0x0a
.byte 0x0c
.byte 0x0a
.byte 0x0c
.byte 0x04
.byte 0x04
.byte 0x0a
.byte 0x0a
.byte 0x0e
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x04
.byte 0x00
.byte 0x0a
.byte 0x0e
.byte 0x04
.byte 0x04
.byte 0x00
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x0e
.byte 0x00
.byte 0x0e
.byte 0x00
.byte 0x04
.byte 0x0a
.byte 0x04
.byte 0x02
.byte 0x04
.byte 0x0e
.byte 0x0e
.byte 0x0c
.byte 0x04
.byte 0x0e
.byte 0x06
.byte 0x00
.byte 0x00
.byte 0x08
.byte 0x00
.byte 0x02
.byte 0x02

# Fourth row of each character
.org 0xD00
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x01
.byte 0x05
.byte 0x0b
.byte 0x07
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x01
.byte 0x09
.byte 0x07
.byte 0x05
.byte 0x0f
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x03
.byte 0x0d
.byte 0x0d
.byte 0x0d
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x01
.byte 0x05
.byte 0x0b
.byte 0x07
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x01
.byte 0x09
.byte 0x07
.byte 0x05
.byte 0x0f
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x03
.byte 0x0d
.byte 0x0d
.byte 0x0d
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x05
.byte 0x07
.byte 0x07
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x01
.byte 0x05
.byte 0x0b
.byte 0x07
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x0f
.byte 0x01
.byte 0x09
.byte 0x07
.byte 0x05
.byte 0x0f
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x0b
.byte 0x0f
.byte 0x0f
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x03
.byte 0x0d
.byte 0x0d
.byte 0x0d
.byte 0x05
.byte 0x07
.byte 0x05
.byte 0x0d
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x01
.byte 0x0b
.byte 0x0b
.byte 0x08
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x0a
.byte 0x08
.byte 0x08
.byte 0x0a
.byte 0x0a
.byte 0x04
.byte 0x04
.byte 0x0a
.byte 0x08
.byte 0x0a
.byte 0x0e
.byte 0x0a
.byte 0x08
.byte 0x04
.byte 0x0a
.byte 0x02
.byte 0x04
.byte 0x0a
.byte 0x04
.byte 0x0e
.byte 0x0a
.byte 0x04
.byte 0x08
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x00
.byte 0x0e
.byte 0x06
.byte 0x08
.byte 0x0a
.byte 0x00
.byte 0x04
.byte 0x04
.byte 0x0a
.byte 0x04
.byte 0x04
.byte 0x00
.byte 0x00
.byte 0x04
.byte 0x0a
.byte 0x04
.byte 0x0c
.byte 0x02
.byte 0x02
.byte 0x02
.byte 0x0a
.byte 0x08
.byte 0x0a
.byte 0x02
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x0e
.byte 0x04
.byte 0x04

# Fifth row of each character
.org 0xE00
.byte 0x09
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x01
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x01
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x07
.byte 0x0d
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x01
.byte 0x09
.byte 0x0d
.byte 0x03
.byte 0x0f
.byte 0x01
.byte 0x0f
.byte 0x0b
.byte 0x0f
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x09
.byte 0x0f
.byte 0x0d
.byte 0x07
.byte 0x0f
.byte 0x0f
.byte 0x07
.byte 0x0f
.byte 0x0b
.byte 0x07
.byte 0x01
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x0d
.byte 0x03
.byte 0x0b
.byte 0x07
.byte 0x01
.byte 0x03
.byte 0x0f
.byte 0x07
.byte 0x0d
.byte 0x0f
.byte 0x07
.byte 0x0b
.byte 0x09
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x01
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x01
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x07
.byte 0x0d
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x01
.byte 0x09
.byte 0x0d
.byte 0x03
.byte 0x0f
.byte 0x01
.byte 0x0f
.byte 0x0b
.byte 0x0f
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x09
.byte 0x0f
.byte 0x0d
.byte 0x07
.byte 0x0f
.byte 0x0f
.byte 0x07
.byte 0x0f
.byte 0x0b
.byte 0x07
.byte 0x01
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x0d
.byte 0x03
.byte 0x0b
.byte 0x07
.byte 0x01
.byte 0x03
.byte 0x0f
.byte 0x07
.byte 0x0d
.byte 0x0f
.byte 0x07
.byte 0x0b
.byte 0x09
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x03
.byte 0x01
.byte 0x07
.byte 0x0b
.byte 0x05
.byte 0x01
.byte 0x03
.byte 0x05
.byte 0x01
.byte 0x05
.byte 0x05
.byte 0x0b
.byte 0x07
.byte 0x0d
.byte 0x05
.byte 0x03
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x0b
.byte 0x05
.byte 0x0b
.byte 0x01
.byte 0x09
.byte 0x0d
.byte 0x03
.byte 0x0f
.byte 0x01
.byte 0x0f
.byte 0x0b
.byte 0x0f
.byte 0x05
.byte 0x03
.byte 0x05
.byte 0x09
.byte 0x0f
.byte 0x0d
.byte 0x07
.byte 0x0f
.byte 0x0f
.byte 0x07
.byte 0x0f
.byte 0x0b
.byte 0x07
.byte 0x01
.byte 0x01
.byte 0x01
.byte 0x03
.byte 0x0d
.byte 0x03
.byte 0x0b
.byte 0x07
.byte 0x01
.byte 0x03
.byte 0x0f
.byte 0x07
.byte 0x0d
.byte 0x0f
.byte 0x07
.byte 0x0b
.byte 0x06
.byte 0x0a
.byte 0x0c
.byte 0x04
.byte 0x0c
.byte 0x0e
.byte 0x08
.byte 0x04
.byte 0x0a
.byte 0x0e
.byte 0x0c
.byte 0x0a
.byte 0x0e
.byte 0x0a
.byte 0x0a
.byte 0x04
.byte 0x08
.byte 0x02
.byte 0x0a
.byte 0x0c
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x04
.byte 0x0a
.byte 0x04
.byte 0x0e
.byte 0x06
.byte 0x02
.byte 0x0c
.byte 0x00
.byte 0x0e
.byte 0x00
.byte 0x04
.byte 0x00
.byte 0x0a
.byte 0x0c
.byte 0x0a
.byte 0x06
.byte 0x00
.byte 0x02
.byte 0x08
.byte 0x00
.byte 0x00
.byte 0x08
.byte 0x00
.byte 0x04
.byte 0x08
.byte 0x0e
.byte 0x0e
.byte 0x0e
.byte 0x0c
.byte 0x02
.byte 0x0c
.byte 0x04
.byte 0x08
.byte 0x0e
.byte 0x0c
.byte 0x00
.byte 0x08
.byte 0x02
.byte 0x00
.byte 0x08
.byte 0x04

# Blank characters, allows me to tighten pixel drawing loop
.org 0xF00
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
.byte 0xff
