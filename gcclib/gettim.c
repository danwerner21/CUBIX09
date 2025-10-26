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


char randseed()
{
        char *clockChipSecondsPtr = (char *)0x1f90;
        return *clockChipSecondsPtr;
}

struct time gettime()
{
        char *clockChipSecondsPtr = (char *)0x1f90;
        char *clockChipSecondsTensPtr = (char *)0x1f91;
        char *clockChipMinutesPtr = (char *)0x1f92;
        char *clockChipMinutesTensPtr = (char *)0x1f93;
        char *clockChipHoursPtr = (char *)0x1f94;
        char *clockChipHoursTensPtr = (char *)0x1f95;
        char *clockChipConfigPtr = (char *)0x1f9f;
        struct time t;

        *clockChipConfigPtr=4;
        t.second=(*clockChipSecondsPtr & 0x0f) + (*clockChipSecondsTensPtr & 0x0f) * 10 ;
        t.minute=(*clockChipMinutesPtr & 0x0f) + (*clockChipMinutesTensPtr & 0x0f) * 10 ;
        t.hour=(*clockChipHoursPtr & 0x0f) + (*clockChipHoursTensPtr & 0x0f) * 10 ;
        return t;
}

struct date getdate()
{
        char *clockChipDayPtr = (char *)0x1f96;
        char *clockChipDayTensPtr = (char *)0x1f97;
        char *clockChipMonthPtr = (char *)0x1f98;
        char *clockChipMonthTensPtr = (char *)0x1f99;
        char *clockChipYearPtr = (char *)0x1f9a;
        char *clockChipYearTensPtr = (char *)0x1f9b;
        struct date d;

        d.day=(*clockChipDayPtr & 0x0f) + (*clockChipMonthTensPtr & 0x0f) * 10 ;
        d.month=(*clockChipMonthPtr & 0x0f) + (*clockChipMonthTensPtr & 0x0f) * 10 ;
        d.year=(*clockChipYearPtr & 0x0f) +  (*clockChipYearTensPtr & 0x0f) * 10 ;
        return d;
}
