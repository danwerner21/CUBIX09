# CUBIX09

This is a port of the excellent CUBIX operating system by Dave Dunfield for various homebrew SBCs.

Supported SBCs include:
* Andrew Lynch's   Nhyodyne and Duodyne systems
* Retrobrewcomputers.org's   6x0x system (todo)

---
More information about Dunfield Development services is included in the dunfield_cubix_info folder in this repo.
---
Dunfield Development Services (DDS) offers software and firmware
development services specializing in systems and embedded applications.
For more information, visit: https://dunfield.themindfactory.com/

CUBIX Operating System Version 1.5

  CUBIX is a stand alone ROM based disk operating system for the 6809
processor. It provides many "big system" features on hardware which can
be constructed from a handfull of chips.

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
New SSRs
* 111 get drive table
* 112 get drive parameters table

---
To Do List for this port:
* ADD FLOPPY DRIVE SUPPORT (Nhyodyne)
* add support for front panel display (Duodyne)
* add support for DiskIO SD card (Duodyne)
* add support for front panel SD card (Duodyne)
* Enable Cubix FLOPPY Format Function (Duodyne/Nhyodyne)
* Fix XMODEM CRC problem
* convert Xmodem EXEs to S19s
* DSKY V1 support (Duodyne/Nhyodyne)
* DSKY functions should abort if no DSKY is there.
* ESP32 support  (Duodyne/Nhyodyne)
* TMS VDP support  (Duodyne/Nhyodyne)
* color VDU support  (Duodyne/Nhyodyne)
* RTC and NVRAM support  (Duodyne/Nhyodyne)
* Microsoft Basic
* Pull MONITOR code from Duodyne repo into this one
* 6x0x Version
---

```
Memory Map:

Standard Cubix memory Map:
            $0000-$1FFF - I/O devices (Incl. memory mapped video etc).
            $2000-$DFFF - Random Access Memory.
            $E000-$FFFF - CUBIX Operating System ROM
            

Significant Bank 0 Fixed Nhyodyne Device Driver Storage Locations:
CONSOLEDEVICE   = $0100          (BYTE)
DSKY_BUF        = $01EA          (8 BYTES)
DSKY_HEXBUF     = $01F3          (4 BYTES)
DISKERROR       = $01F7          (BYTE)            
CURRENTHEAD     = $01F8          (BYTE)
CURRENTCYL      = $01F9          (BYTE)
CURRENTSEC      = $01FA          (BYTE)
CURRENTDEVICE   = $01FB          (BYTE)
CURRENTSLICE    = $01FC          (WORD)
farpointer      = $01FE          (WORD)

            
Nhyodyne Map:
            $0000-$00FF - FREE WORKING RAM
            $0100       - CONSOLEDEVICE
            $0101-$01E9 - FREE WORKING RAM
            $01EA-$01F2 - DSKY_BUF
            $01F3-$01F6 - DSKY_HEXBUF
            $01F7       - DISKERROR       
            $01F8       - CURRENTHEAD     
            $01F9       - CURRENTCYL      
            $01FA       - CURRENTSEC      
            $01FB       - CURRENTDEVICE   
            $01FC       - CURRENTSLICE    
            $01FE       - farpointer      
            $0200-$02FF - PAGER CODE
            $0300-$04FF - DISK BUFFER
            $0500-$05FF - Memory Mapped IO
            $0600-$1FFF - FREE WORKING RAM
            $2000-$DBFF - Application Random Access Memory.     
            $DC00-$DFFF - OS LOCAL STORAGE   
            $E000-$F944 - CUBIX Operating System 
            $F945-$FEFF - CUBIX Low Memory Device Drivers
            $FF00-$FFF1 - OS VECTORS AND CONFIG TABLES
            $FFF2-$FFFF - HARDWARE VECTORS

Duodyne Map:
            $0000-$00FF - FREE WORKING RAM
            $0100       - CONSOLEDEVICE
            $0101-$01E9 - FREE WORKING RAM
            $01EA-$01F2 - DSKY_BUF
            $01F3-$01F6 - DSKY_HEXBUF
            $01F7       - DISKERROR       
            $01F8       - CURRENTHEAD     
            $01F9       - CURRENTCYL      
            $01FA       - CURRENTSEC      
            $01FB       - CURRENTDEVICE   
            $01FC       - CURRENTSLICE    
            $01FE       - farpointer      
            $0200-$02FF - PAGER CODE
            $0300-$04FF - DISK BUFFER
            $0500-$0FFF - FREE WORKING RAM
            $1000-$13FF - OS LOCAL STORAGE   
            $1400-$1FFF - FREE WORKING RAM
            $2000-$DBFF - Application Random Access Memory.     
            $DC00-$DEFF - OS LOCAL STORAGE   
            $DF00-$DFFF - Memory Mapped IO
            $E000-$F944 - CUBIX Operating System 
            $F945-$FEFF - CUBIX Low Memory Device Drivers
            $FF00-$FFF1 - OS VECTORS AND CONFIG TABLES
            $FFF2-$FFFF - HARDWARE VECTORS

```

---
## Setting up a new filesystem

Cubix supports four concurrent drives A,B,C and D.

Default drive configuration for Cubix can be found at the bottom of the respective drivers.asm file and is in the following format:

```
; DRIVE MAPPING TABLE
        FCB     $21,$00                           ; TABLE IS DRIVE TYPE, SLICE OFFSET
        FCB     $21,$01                           ; DRIVE IDS ARE $00=NONE, $1x=FLOPPY, $2X=PPIDE
        FCB     $21,$02                           ;     LOW NIBBLE IS DEVICE ADDRESS
        FCB     $11,$00                           ; SLICE OFFSET IS THE UPPER 8 BITS OF THE DRIVE LBA ADDRESS
                                                  ; ALLOWING IDE DRIVES TO HOST UP TO 256 VIRTUAL DRIVES PER PHYSICAL DRIVE
```
Note that the above drive table is configured for a secondary IDE address and for floppy drive 1.

The ASSIGN.EXE program can be used to remap drives in real time.

A disk image (DISK.IMG) is provided in this repo that can be written to a device to bootstrap the system. It conformes to the default drive mapping table above.   Cubix HDDs are configured as 32mb drives, therfore at least a 32mb drive is required without altering the disk geometry.

It is expected that you set Cubix's system directory to the SYSTEM folder on drive B:
```
SET SYSTEM A:[SYSTEM]
```
more information on Cubix drives and directories can be found in the Cubix user documentation in this repo.

## Starting Cubix from CP/M

Cubix can be started from CP/M by launching the cubix.com file located in the bin folder for each respective system.  

Cubix can also be started by uploading the cubix.s19 file located in the bin folder for each respective system. Then transferring control to $E000.


