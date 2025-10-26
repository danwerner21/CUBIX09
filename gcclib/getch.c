
char getch()
{
        char f=' ';
        asm ("swi\n\t"
            ".byte 34");
        asm ("sta	,u");
        return f;
}