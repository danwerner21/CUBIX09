# CUBIX09

This is a port of the excellent CUBIX operating system by Dave Dunfield for various homebrew SBCs.

Supported SBCs include:
* Andrew Lynch's   Nhyodyne and Duodyne(todo) systems
* Retrobrewcomputers.org's   6x0x system (todo)

---
More information about Dunfield Development services is included in the dunfield_cubix_info folder in this repo.
---
Dunfield Development Services (DDS) offers software and firmware
development services specializing in systems and embedded applications.
For more information, visit: http://www.dunfield.com

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
  -  Powerful screen (window) text editor.
  -  6809 Assembler.
  -  6809 debugger.
  -  Micro APL interpreter.
  -  Micro C compiler.
  -  Micro FORTH compiler.
  -  Intel 8080 simulator with integrated debugger.

---

To Do List for this port:
ADD REMAPABLE DRIVES
ADD SLICES
ADD MULTIPLE IDE DRIVE SUPPORT
DRIVE MAPPER UTILITY

MICRO C

ADD FLOPPY DRIVE SUPPORT

Microsoft Basic

Create an XMODEM program

MONITOR

PAGER SUPPORT