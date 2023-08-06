/*
 * This macro provides a facility to perform conditional runtime debugging
 * in your C programs. The "assert(c)" macro evaluates a condition (c), and
 * if it is NOT true, a message is generated on STDERR indicating the
 * condition which failed, the source file name and source file line.
 *
 * The assert() macro is only processed if the symbol DEBUG is #defined
 * If DEBUG is not defined, all instances of assert() become null
 * definitions, and generate no code. Calls to assert() should NOT be
 * followed by a semicolon(;), eg: assert(i<10)
 *
 * This file **REQUIRES** the extended pre-processor (MCP).
 *
 * Copyright 1999-2005 Dave Dunfield
 * All rights reserved.
 */
#ifdef DEBUG
	#ifndef EOF
		#error Must #include standard I/O before <assert.h>
	#endif
	#define	assert(c) if(!(c))putstr("Assert ("#c") fail: "#__FILE__"("#__LINE__")\n");
#else
	#define assert(c)
#endif
