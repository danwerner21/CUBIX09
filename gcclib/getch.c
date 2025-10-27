
char getch()
{
        char f=' ';
        asm ("swi\n\t"
            ".byte 34");
        asm ("sta	,u");
        return f;
}

char getc()
{
        char f=' ';
        asm ("swi\n\t"
            ".byte 35");
        asm ("sta	,u");
        return f;
}