#include <stdio.h>

char floppy35720dcb[9]={80,2,9};
char floppy35144dcb[9]={80,2,18};
char floppy525360dcb[9]={40,2,8};
char floppy52512dcb[9]={80,2,15};

#ifdef PC6809
char hdddcb[9]={254,1,255};
#else
char hdddcb[9]={255,1,255};
#endif


char *last;
int dskcfgptr;
int dparmtable;



void GetDiskTable()
{
    dskcfgptr= asm {
        SWI
        FCB 111
    };
}

void GetConfigTable()
{
    dparmtable= asm {
        SWI
        FCB 112
    };
}

int strncmp(char *p1,char *p2,int len)
{
    int c;
    c=0;

    while(c<len)
    {
        if(*p1++!=*p2++) return 1;
        c++;
        if(*p2==0) break;
    }
    return 0;
}

void strncpy(char *p1,char *p2,int len)
{
    int c;
    c=0;

    while(c<len)
    {
        *p1++=*p2++;
        c++;
        if(*p2==0) break;
    }
}

char *strtok(s, delim)
	char *s;
	char *delim;
{
	char *spanp;
	int c;
    int sc;
	char *tok;

	if (s == NULL && (s = last) == NULL)
		return (NULL);

	/*
	 * Skip (span) leading delimiters (s += strspn(s, delim), sort of).
	 */
cont:
	c = *s++;
	for (spanp = (char *)delim; (sc = *spanp++) != 0;) {
		if (c == sc)
			goto cont;
	}

	if (c == 0) {		/* no non-delimiter characters */
		last = NULL;
		return (NULL);
	}
	tok = s - 1;

	/*
	 * Scan token (scan for delimiters: s += strcspn(s, delim), sort of).
	 * Note that delim must have one NUL; we stop if we see that, too.
	 */
	for (;;) {
		c = *s++;
		spanp = (char *)delim;
		do {
			if ((sc = *spanp++) == c) {
				if (c == 0)
					s = NULL;
				else
					s[-1] = 0;
				last = s;
				return (tok);
			}
		} while (sc != 0);
	}
	/* NOTREACHED */
}

int parsecmd(int ac,char *parm1, char *parm2, char *token1, char *token2,char *flags)
{
  int r;
  char *token;
  r=0;

  if(ac==3)
  {
    strncpy(flags,parm1,5);
    token=parm2;
  }
  else
  {
    flags[0]=0;
    token=parm1;
  }

  if (token != NULL)
  {
    token = strtok(token, "=");
    if (token != NULL)
    {
      strncpy(token1, token, 29);
      r = 1;
      token = strtok(NULL, "=");
      if (token != NULL)
      {
        strncpy(token2, token, 29);
        r = 2;
      }
    }
  }
  return r;
}


void prtdevice(char dev)
{
  switch (dev & 0xf0)
  {
  case 0x00:
    printf("UNKNOWN");
     return;
  case 0x10:
    printf("FD");
    break;
  case 0x20:
    printf("IDE");
    break;
  case 0x30:
    printf("FPSD");
    break;
    case 0x40:
    printf("USB");
    break;
  default:
    printf("UNKNOWN");
    return;
  }
  printf("%d", dev & 0x0f);
}


void prttable(char *bytes)
{
  int i;

  printf("\n\r CUBIX Drive assignment:\n\r");
  for (i = 0; i < 8; i++)
  {
    printf("  %c:=", i / 2 + 'A');
    prtdevice(*(bytes + i++));
    printf(":%d\n\r", *(bytes + i));
  }
}


void prtusage()
{
  printf(" Usage: \n\r");
  printf("    ASSIGN D:=[{D:|<device>[<unitnum>]:[<slicenum>]}] {/flags} \n\r");
  printf("      ex: ASSIGN		(display all active drive assignments) \n\r");
  printf("          ASSIGN /?		(display version and usage) \n\r");
  printf("          ASSIGN C:=FD0:	(assign C: to floppy unit 0) \n\r");
  printf("          ASSIGN C:=IDE0:1	(assign C: to IDE unit0, slice 1) \n\r");
  printf("\n\r POSSIBLE DEVICES:\n\r");
  printf("          FPSDx:  FRONT PANEL SD DISK (ADDR 0x2x)\n\r");
  printf("          FD0:    FLOPPY DISK UNIT 0\n\r");
  printf("          FD1:    FLOPPY DISK UNIT 1\n\r");
  printf("          IDE0:   PRIMARY PPIDE FIXED DISK\n\r");
  printf("          IDE1:   SECONDARY PPIDE FIXED DISK\n\r");
  printf("          USB:    USB BASS STORAGE\n\r");
  printf("\n\r POSSIBLE FLAGS:\n\r");
  printf("          /35     3.5 INCH FLOPPY (DEFAULT)\n\r");
  printf("          /525    5.25 INCH FLOPPY\n\r");
}

void toupper(char *name)
{
  while (*name)
  {
    if ((*name > 96) && (*name < 123))
      *name = *name & 0x5F;
    name++;
  }
}

void updatedosmap(char drive,char dcb[])
{
  char *table;
  table = (unsigned char *)dparmtable+(drive*7);
  *(table+1)=dcb[0];
  *(table+2)=dcb[1];
  *(table+3)=dcb[2];
}

void mapdrive(char *bytes, char *token1, char *token2, char *flags)
{
  char drive;
  char newdevice;
  char *token;
  unsigned char slice;

  drive = (token1[0] & 0x5F) - 65;
  newdevice = 0xff;
  slice = 0x00;

  if ((drive < 0) || (drive > 3))
  {
    printf("Assigned drive must be in the range of A-D.\n\r");
    return;
  }
  printf("Currently:   %c:=", drive + 65);
  prtdevice(*(bytes + (drive * 2)));
  printf(":%u \n\r", *(bytes + (drive * 2) + 1));

  toupper(token2);
  if (!strncmp(token2, "FPSD5:", 6))
    {
    newdevice = 0x35;
    updatedosmap(drive,hdddcb);
    }
  if (!strncmp(token2, "FPSD6:", 6))
    {
    newdevice = 0x36;
    updatedosmap(drive,hdddcb);
    }
  if (!strncmp(token2, "FPSD7:", 6))
    {
    newdevice = 0x37;
    updatedosmap(drive,hdddcb);
    }
  if (!strncmp(token2, "FD0:", 4))
   {
    newdevice = 0x10;
    updatedosmap(drive,floppy35720dcb);
    if (!strncmp(flags, "/525", 4))
    {
      updatedosmap(drive,floppy525360dcb);
    }
   }
  if (!strncmp(token2, "FD1:", 4))
   {
    newdevice = 0x11;
    updatedosmap(drive,floppy35720dcb);
    if (!strncmp(flags, "/525", 4))
    {
      updatedosmap(drive,floppy525360dcb);
    }
   }
  if (!strncmp(token2, "IDE0:", 7))
   {
    newdevice = 0x20;
    updatedosmap(drive,hdddcb);
   }
  if (!strncmp(token2, "IDE1:", 7))
  {
    newdevice = 0x21;
    updatedosmap(drive,hdddcb);
  }
  if (!strncmp(token2, "USB:", 7))
   {
    newdevice = 0x40;
    updatedosmap(drive,hdddcb);
   }
  if (newdevice == 0xFF)
  {
    printf("Unkown device assignment. \n\r");
    return;
  }
  token = strtok(token2, ":");
  token = strtok(NULL, ":");
  if (token != NULL)
  {
    slice=token[0]-48;
    if((slice<0) || (slice>9)) slice=0;
  }

  *(bytes + (drive * 2))= newdevice;
  *(bytes + (drive * 2)+1)= slice;

  printf("Changed to:  %c:=", drive + 65);
  prtdevice(*(bytes + (drive * 2)));
  printf(":%u ", *(bytes + (drive * 2) + 1));
   if (!strncmp(flags, "/525", 4))
    {
      printf("(360K)");
    }
  printf("\n\r");
  return;
}

main(ac,av)
   int ac;
   int *av[];
{
  int result;
  char token1[30];
  char token2[30];
  char flags[30];

  result = parsecmd(ac,av[1],av[2], token1, token2,flags);

  GetDiskTable();
  GetConfigTable();


  switch (result)
  {
  case 0:
    prttable((unsigned char *)dskcfgptr);
    break;
  case 1:
    prtusage();
    break;
  case 2:
    mapdrive((unsigned char *)dskcfgptr, token1, token2, flags);
    break;
  }

  return (0);
}
