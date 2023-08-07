/*
 * DDS MICRO-C Setjmp/Longjmp definitions
 *
 * This file **REQUIRES** the extended pre-processor (MCP).
 *
 * Copyright 1988-2005 Dave Dunfield
 * All rights reserved.
 */
#define jmp_buf struct{Jmp_Buf[2];}
