
char *ESP0Ptr = (char *)0x1100; // ESP0 IO PORT
char *ESP1Ptr = (char *)0x1101; // ESP0 IO PORT
char *ESPStatusPtr = (char *)0x1102; // ESP status IO PORT

extern int esp0_outbyte(char value);
extern int esp0_inbytewait();
extern int esp1_outbyte(char value);
extern int esp1_inbytewait();
extern void esp0_outstruct(char *data,int len);
extern void esp0_outlong(long value);
extern void esp0_outint(int value);
extern void esp1_outstruct(char *data,int len);
extern void esp1_outlong(long value);
extern void esp1_outint(int value);
