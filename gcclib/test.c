#include "stdio.h"
#include "graphics.h"


main()
{
       	char *ptr = "Hello world!";
	char *np = 0;
	int i = 5;
	unsigned int bs = sizeof(int)*8;
	int mi;
	char buf[80];

        printf("printf test\n\r");
	ClearDisplay();
 	SetCursor(0);

	mi = (1 << (bs-1)) + 1;
	printf("%s\n\r", ptr);
	printf("%s is null pointer\n\r", np);
	printf("%d = 5\n\r", i);
	printf("%d = - max int\n\r", mi);
	printf("char %c = 'a'\n\r", 'a');
	printf("hex %x = ff\n\r", 0xff);
	printf("hex %02x = 00\n\r", 0);
	printf("signed %d = unsigned %u = hex %x\n\r", -3, -3, -3);
	printf("%d %s(s)%", 0, "message");
	printf("\n\r");
	printf("%d %s(s) with %%\n\r", 0, "message");
	sprintf(buf, "justif: \"%-10s\"\n\r", "left"); printf("%s", buf);
	sprintf(buf, "justif: \"%10s\"\n\r", "right"); printf("%s", buf);
	sprintf(buf, " 3: %04d zero padded\n\r", 3); printf("%s", buf);
	sprintf(buf, " 3: %-4d left justif.\n\r", 3); printf("%s", buf);
	sprintf(buf, " 3: %4d right justif.\n\r", 3); printf("%s", buf);
	sprintf(buf, "-3: %04d zero padded\n\r", -3); printf("%s", buf);
	sprintf(buf, "-3: %-4d left justif.\n\r", -3); printf("%s", buf);
	sprintf(buf, "-3: %4d right justif.\n\r", -3); printf("%s", buf);

	struct time t =gettime();
	printf("Time %d:%02d:%02d\n\r",t.hour,t.minute,t.second);

	struct date d =getdate();
	printf("Date %d/%d/%02d\n\r",d.month,d.day,d.year);

	int c=0;
	for(c=0;c<16;c++)
	{
		SetBrushColor(c);
		SetPenColor(15);
		DrawFilledRectangle(10,10+(c*20),150,30+(c*20));

		SetBrushColor(0);
		SetPenColor(15);
		sprintf(buf," COLOR: %d",c);
		OutString(155,13+(c*20),8,0,25,buf);
	}
	SetPenWidth(1);
	SetPenColor(4);
	DrawRectangle(0,0,639,479);

	printf("Press Keys to test Keyboard - 'x' to exit\n\r");

	for(;;)
	{
		char c = getch();
		printf("->%c<-",c);
		if(c=='x')
		{
			printf("\n\rDONE.\n\r");
			_exit();
		}
	}


        _exit();
        _start();
}
