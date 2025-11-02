
struct time
{
    char hour;
    char minute;
    char second;
};

struct date
{
    char month;
    char day;
    char year;
};

extern char randseed();
extern struct time gettime();
extern struct date getdate();
extern char getch();
extern char getc();
extern int printf(char *format, ...);
extern int sprintf(char *out,char *format, ...);
extern void outbyte(char b);
extern int puts(char *outptr);
extern unsigned _start();
extern char tolower(char c);
extern char toupper(char c);
extern char islower(char c);
extern char isupper(char c);
extern char isdigit(char c);
extern char isxdigit(char c);
extern char isprint(char c);
extern int abs_value(int x);
extern void strcpy(char *dest, char *src);
extern int strcmp(char *str1, char *str2);
extern void strcat(char *dest, char *src);