# Potental TODO:

### General IO
* Printer output
* Set Console input/output

### ADD GRAPHICS AND SOUND COMMANDS?
* Clear Screen
* Set Colors
* Set Font
* Set Cursor
* Set Video Mode
* Scroll Screen

* Set Pallette
* Set Glyph Options
* Set Brush Color

* Draw Bitmap
* Draw Ellipse
* Draw Glyph
* Draw Line
* Draw Rectangle
* Draw Filled Ellipse
* Draw Filled Rectangle
* Invert Rectangle

* Get Pixel Value
* Set Pixel

* Draw line To
* Move Cursor To
* Set Line Ends
* Set Pen Color
* Set Pen Width

* Set Mouse Cursor
* Set Mouse Position

* Clear Sprites
* Set Sprite Map
* Set Sprite Location
* Set Sprite Visibility

* Play Audio String
* Play Sound
* Set Volume
     

### ADD DISK COMMANDS?    
* Directory
* Delete file
* open file
* close file
* write file
* read file
     
     
# Description

This is a heavily modifiedport of Microsoft Extended BASIC, as used in 
the Tandy Color Computer 2. This was forked from a port by Grant Searle.  
See http://searle.x10host.com/6809/Simple6809.html

Here are notes on some quirks of this variant of BASIC where it
differs from some other versions of Microsoft BASIC. This may help in
porting programs such as games:

General: All keywords and variables must be entered in upper case,
although you can use lower case in strings.

RND() function:

RND(0) returns a random floating point number between 0 and 1. RND(n),
where n is greater than 0, returns an integer between 0 and n. Most
BASICs return a value between 0 and 1 for any argument value (1 seems
to be commonly used in many programs).

FRE() function:

This is not present, but you can use the pseudo-variable MEM instead
to report the amount of free memory.

INPUT command:

The command does not allow you to specify a prompt string to be
displayed, as many other versions of BASIC do. You can work around
this by using a PRINT statement to display the prompt before calling
INPUT.

EXIT command:

This command returns you to the os.

