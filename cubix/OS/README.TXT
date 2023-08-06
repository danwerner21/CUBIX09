Files in this directory:

    CUBIX        - Main Module for CUBIX
    FILESYS.OS   - File System management functions
    COMMAND.OS   - Internal Command Handlers
    COMFILE.OS   - Command (BATCH) file processor
    SIMULATE.SYS - Sample I/O drivers for D6809 simulator
    SAMPLE.SYS   - Sample I/O drivers for 6551 / uPD765
    TMPVARS      - CUBIX OS temporary variable usage info.

To assemble CUBIX (Using MACRO & ASM09 from my XASM package):

    macro CUBIX asmode=demo osver=1.5 >CUBIX.ASM
    asm09 CUBIX -t
    del CUBIX.ASM

To calculate the checksum (Using HEXFMT from the XASM package):

    hexfmt CUBIX.HEX c=$0002,$1FFF,$0000
