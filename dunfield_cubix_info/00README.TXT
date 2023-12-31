CUBIX Operating System Version 1.5

  CUBIX is a stand alone ROM based disk operating system for the 6809
processor. It provides many "big system" features on hardware which can
be constructed from a handfull of chips.

  This release of CUBIX is designed to be ported from an IBM P.C. "host"
system. The complete package consists of the following files and directories:

  00README.TXT - This file
  MACROS       - Macro to implement SSR directive under DDS XASM09
  GOASM.BAT    - Batch file to assemble utilities
  DOCS\*.*     - Documentation on cubix system
  BIN\*.*      - CUBIX binary images
  EXAMPLE\*.*  - CUBIX programming examples
  OS\*.*       - Operating system source code
  UTIL\*.*     - Utilities and applications
  DWG\*.*      - Drawing files for the demo system (hardware)

  NOTE: the file BIN\OS_DEMO.HEX contains a pre-configured version of CUBIX
for the included hardware design. BIN\OS_DISK.HEX contains the standard un-
ported distribution version as described in the documentation.

  For detailed information on "porting" CUBIX to a particular 6809 system,
see the "PORT.TXT" manual in the DOCUMENT directory.

CUBIX Features:
---------------
  -  Rom based (8K including I/O drivers) for instant access.
  -  Portable, easily implemented on any 6809 system.
  -  Integral command line interpreter can be invoked from
     within application programs.
  -  Built in command file language allows "programs" to be
     written using CUBIX commands and utilities as statements.
  -  Over 100 system calls provide a built in library of
     common I/O, file access and utility functions.
  -  Includes many utility programs for manipulation and
     diagnostics of files, directories and disks.
  -  Any device driver (including disks) can be installed
     or replaced via system calls at any time.

Included applications:
----------------------
  -  Powerful screen (window) text editor.
  -  6809 Assembler.
  -  6809 debugger.
  -  Micro APL interpreter.
  -  Micro C compiler.
  -  Micro FORTH compiler.
  -  Intel 8080 simulator with integrated debugger.


This archive contains schematic drawings for a fairly simple 6809 based
computer system with 48K of memory, a floppy disk interface, and two
serial (TTY) ports. This system is suitable for running the CUBIX 6809
disk operating system, and is directly compatible with the distribution
"OS_DEMO" version of the CUBIX system (no "porting" or other modifications
required).

Most of the parts for this system are very common, and you may already
have them if you have a well-stocked junkbox.

6809 System - Files:
--------------------
   CPU09.DWG     - Schematic diagram - CPU section
   SER09.DWG     - Schematic diagram - Serial Interfaces
   DISK09.DWG    - Schematic diagram - Floppy Disk Controller

6809 system parts list:
-----------------------
 R1-R4    10k 1/4w 10% resistor
 C1-C2    10uf 10v tantalum capacitor
 U1       68B09 microprocessor I.C.
 U2-U12   74LS138 3-8 decoder I.C.
 U3       74LS00 quad NAND gate I.C.
 U4-U9    6264 8k by 8 RAM I.C.
 U10      2764 8k by 8 EPROM I.C.
 U11      74LS04 hex invertor I.C.
 U13-U14  6551A ACIA (uart) I.C. (2Mhz)
 U15      1488 quad RS-232 line driver I.C.
 U16      1489 quad RS-232 line receiver I.C.
 U17      765 floppy disk controller I.C.
 U18      74LS175 quad D-type flop-flop I.C.
 U19      74LS153 dual 4-1 data selector I.C.
 U20      74LS139 dial 2-4 decoder I.C.
 U21      9216 integrated data separator I.C.
 U22      74LS161 synchronous 4-bit counter I.C.
 U23      74LS74 dual flip-flop I.C.
 U24      74LS14 hex schmitt trigger I.C.
 U25-U26  7438 quad NAND gate with open collector output I.C.
 X1       7.3728 Mhz crystal
 X2       8.0 Mhz packaged oscilator I.C.

Notes:
------
All data and address lines of CPU and 2764, 6264s, 6551's and 765
peripheral chips are tied together (not shown on schematic diagrams).

Bypass capacitors should be placed across power rails or all IC's.

Four of the 8Kx8 RAM's can be replaced with a single 32K RAM by ANDing
the RAMx selects and connecting A13-A14 to the 32K RAM chip. The remaining
two RAM's may be replaced in a similar manner except that you only have two
RAMx selects remaining, and will therefore "waste" 16K of the 32K device.

The system can be run with a single 32K RAM chip (connected as described
above) by re-configuring the CUBIX operating system and utility programs
to re-position the upper boundary address of available memory. This will
(of course) reduce the memory available to applications.

Additional serial ports can be added (or removed) by duplicating the
ACIA (uart) and related circuitry and connecting to extra chip selects
available on U12. You will also have to add driver entries for the new
ports in the CUBIX I/O driver source file.

The 6809's Q clock is used as the baud rate clock for the 6551's. This
means that the CPU MUST run at 1.8432 Mhz (7.3728 Mhz crystal). You can
put a 1.8432Mhz crystal on the 6551's, and crank the 6809 up to its
maximum 2.0 Mhz (8.0 Mhz), but be warned that many 6551's have problems
when the baud clock and bus clock are not synchronized.

You can replace the 6551's with your favorite UART as long as you
interface it properly, and replace the serial I/O drivers in the CUBIX
driver source file.

The 765 floppy disk controller is the same device that is used on most
IBM PC's (and clones). An obsolete PC/XT disk controller card is a good
place to look for most of the components in the floppy disk interface.
Intel makes a compatible chip called the 8272, which can be used in this
design with no changes.

The 8Mhz packaged oscilator in the disk interface can be replaced with
a descrete 8Mhz oscilator circuit, or any other circuit which yeilds a
8 Mhz square wave (16Mhz/2, 32Mhz/4 etc.)

The 9216 integrated data separator is probably the only difficult to
find part in the design. The makers of the FDC chip (NEC, Intel etc.)
have application notes showing descrete data separators (Also, look
at the schematics for PC/XT FDC cards). The single-chip solution is much
easier if you can find one. These too often appear on PC/XT diskette
cards, often in the disguise of: UM8326, which is a compatible device.

Complete schematic diagrams for the system are contained in the files
*.DWG. You may view/print then with our MICROCAD drawing package:

     MICROCAD CPU09 /D     <- View on VGA monitor
     MCPRINT SER09 LASER   <- Print on HP laserjet series (LPT1)
     MCPRINT DISK09 EPSON  <- Print on EPSON dot matrix (LPT1)

MICROCAD is available "free" from our WEB PAGE and on our DEMO disks, as
part of the EMBEDRAW package. For details on editing the drawing, or printing
it to devices attached to different ports, see the MICROCAD documentation.


All programs, documentation, source code and other information in this
archive is copyright 1987-2004 Dave Dunfield. All rights are reserved.

  CUBIX is provided on an "as is" basis, with no warranty of any kind.
In no event shall the author be liable for any damages arising from its
use or distribution.

-----------------------------------------------------------------------
Dunfield Development Services (DDS) offers software and firmware
development services specializing in systems and embedded applications.
For more information, visit: http://www.dunfield.com
