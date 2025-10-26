
puts(char *outptr)
{
        /* assume that first parameter is aleady in X
        asm ("ldx %0\n\t"
                : "=m" (outptr));
        */

        asm ("swi\n\t"
            ".byte 23");
}
