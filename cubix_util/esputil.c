#include <stdio.h>


void putesp0(unsigned int value)
{
asm(value)
{
        TFR     B,A
        LDX     #$2500
?putesp01 LDB     $1102
        ANDB    #$02
        BEQ     ?putesp02
        LEAX    -1,X
        BNE     ?putesp01
        BRA     ?putesp03
?putesp02 STA     $1100
?putesp03 NOP
};
}

int getesp0()
{
        int result;

        result=asm
{
        LDX     #$FF00
?getesp01 LDB     $1102
        ANDB    #$02
        BEQ     ?getesp02
        LEAX    -1,X
        BNE     ?getesp01
        LDD     #$FFFF
        BRA     ?getesp05
?getesp02 LDX     #$FF00
?getesp03 LDB     $1102
        ANDB    #$01
        BNE     ?getesp04
        LEAX    -1,X
        BNE     ?getesp03
        LDD     #$FFFF
        BRA     ?getesp05
?getesp04 LDB     $1100
        LDA     #$00
?getesp05 NOP
};
        return result;
}


char mainMenu()
{
        char result;

        printf("    ESP IO Configuration \n\r\n\r");
        printf("    1. Video Configuration \n\r");
        printf("    \n\r");
        printf("    \n\r");
        printf("    \n\r");
        printf("    9. Exit\n\r\n\r");
        printf("    Selection ==>");

        result=getch();
        printf("%c\n\r",result);
        return result;
}

void fontMenu()
{
        char input_line[21];
        unsigned int value;

        for(;;)
        {

        printf("             Set ESP IO Font \n\r\n\r");
        printf("    1.FONT_4X6         16.FONT_8X19\n\r");
        printf("    2.FONT_5X7         17.FONT_9X15\n\r");
        printf("    3.FONT_5X8         18.FONT_9X18\n\r");
        printf("    4.FONT_6X8         19.FONT_10X20\n\r");
        printf("    5.FONT_6X9         20.FONT_BIGSERIF_8X14\n\r");
        printf("    6.FONT_6X10        21.FONT_BIGSERIF_8X16\n\r");
        printf("    7.FONT_6X12        22.FONT_BLOCK_8X14\n\r");
        printf("    8.FONT_6X13        23.FONT_BROADWAY_8X14\n\r");
        printf("    9.FONT_7X13        24.FONT_COMPUTER_8X14\n\r");
        printf("   10.FONT_7X14        25.FONT_COURIER_8X14\n\r");
        printf("   11.FONT_8X8         26.FONT_LCD_8X14\n\r");
        printf("   12.FONT_8X9         27.FONT_OLDENGL_8X16\n\r");
        printf("   13.FONT_8X13        28.FONT_SANSERIF_8X14\n\r");
        printf("   14.FONT_8X14        29.FONT_SANSERIF_8X16\n\r");
        printf("   15.FONT_8X16        30.FONT_SLANT_8X14\n\r");
        printf("                       31.FONT_WIGGLY_8X16\n\r\n\r");
        printf("   32. Exit\n\r\n\r\n\r");
        printf("    Selection ==>");

        getstr(input_line, 20);
        value = atoi(input_line);
        if(value>31) return;
        if(value>0)
        {
                value--;
                putesp0(16);
                putesp0(value);
        }
        }
}

void videoMenu()
{
        char result;

        for(;;)
        {
        printf("    ESP IO Video Configuration \n\r\n\r");
        printf("    1. Set Font \n\r");
        printf("    \n\r");
        printf("    \n\r");
        printf("    \n\r");
        printf("    9. Exit\n\r\n\r");
        printf("    Selection ==>");

        result=getch();
        printf("%c\n\r",result);
        switch (result)
                {
                case '1':
                        fontMenu();
                        break;
                case '9':
                        return;
                }

        }
}


main(ac, av) int ac;
int *av[];
{
        char result;

        for (;;)
        {
                result = mainMenu();

                switch (result)
                {
                case '1':
                        videoMenu();
                        break;
                case '9':
                        return (0);
                }
        }
}
