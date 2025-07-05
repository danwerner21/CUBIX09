#include <stdio.h>

FILE *reader1;
FILE *reader2;


unsigned char xbuff1[522];
unsigned char xbuff2[522];


main(ac,av)
   int ac;
   int *av[];
{
    int st1;
    int st2;
    int i;
    int b;

    b=0;
    if(ac<3)
    {
        printf("Use: COMP <FILENAME> <FILENAME>\n\r");
        return 0;
    }

    reader1 = fopenr(av[1]);
    reader2 = fopenr(av[2]);
    printf("Begin Compare:\n\r");

    for(;;)
    {
        st1=fgetb(xbuff1, 512, reader1);
        st2=fgetb(xbuff2, 512, reader2);

        printf("Block %d:\n\r",b);
        for(i=0;i<512;i++)
        {

                if(xbuff1[i]!=xbuff2[i])
                {
                        printf("error block=%d,address=%d (%d,%d)\n\r",b,i,xbuff1[i],xbuff2[i]);
                }
        }
        b++;

        if(st1==0) break;
        if(st2==0) break;
    }
    return 0;
}
