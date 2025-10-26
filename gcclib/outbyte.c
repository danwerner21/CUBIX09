
void outbyte(char b)
{
        /* assume that first parameter is aleady in x    */
asm ("tfr b,a\n\t"
     "swi\n\t"
     ".byte 33");
}
