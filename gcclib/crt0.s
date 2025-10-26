
	.module crt0.S

	.globl _main


;The startup is heavily dependent on the type of machine and
;OS environment that is available at the start point.
;For the most part, the general idea is the same across machines,
;but the implementation is vastly different.  This is managed via
;conditional compiles throughout the startup code for each of the
;supported machines.

;             $2000-$DFFF - Application Random Access Memory.
#define __PROG_SIZE
__STACK_TOP = 0xdfff


	;; Declare all linker sections, and combine them into a single bank
        .area .startup
        .area .text
        .area .direct
	.area .base
	.area .romcall
	.area .rodata
	.area .data
	.area .ctors
	.area .dtors
	.area .gcc_except_table
	.area .bss
	.area .noinit
	.area .vector

	.area	.startup

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; __start : Entry point to the program
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.globl	__start
__start:

	;; Initialize the stack
	lds	#__STACK_TOP
        tfr     y,x
;	;; Call any initializer functions
;	ldy	#l_.ctors
;	beq	__ctors_done
;	LEA	(u,s_.ctors)
;__ctors_loop:
;	jsr	[,u++]
;	leay	-2,y
;	bne	__ctors_loop
;__ctors_done:

	;; Set up the environment
	;/* TODO */

	;; Set up argc/argv
	pshs	x
	;ldx	MEM(__argc)

	;; Call the main function.  The exit code will
	;; be returned in the X register, unless compiled
	;; with -mdret, in which case it comes back in D.
	jsr	_main

;	ldy	#l_.dtors
;	beq	__dtors_done
;	LEA	(u,s_.dtors)
;__dtors_loop:
;	jsr	[,u++]
;	leay	-2,y
;	bne	__dtors_loop
;__dtors_done:

	;; If main returns, then invoke exit() to stop the program
	jmp	__exit

	;; Set up the entry point for the linked binary
	.end	__start

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;; __exit : Exit point from the program
;;; For simulation, this writes to a special I/O register that
;;; the simulator interprets as end-of-program.
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
	.globl	__exit
__exit:
        swi
        .byte 00