#include "esp.h"

int esp0_outbyte(char value)
{
        int timeout=0x2500;
        while((*ESPStatusPtr & 0x02))
        {
                timeout--;
                if(timeout==0) return -1;
        }
        *ESP0Ptr=value;
        return 0;
}

int esp1_outbyte(char value)
{
        int timeout=0x2500;
        while((*ESPStatusPtr & 0x10))
        {
                timeout--;
                if(timeout==0) return -1;
        }
        *ESP1Ptr=value;
        return 0;
}


int esp0_inbytewait()
{
        int timeout=0xFF00;

        while(!(*ESPStatusPtr & 0x01))
        {
                timeout--;
                if(timeout==0) return -1;
        }

        return *ESP0Ptr & 0xff;
}

int esp1_inbytewait()
{
        int timeout=0xFF00;

        while(!(*ESPStatusPtr & 0x08))
        {
                timeout--;
                if(timeout==0) return -1;
        }

        return *ESP1Ptr & 0xff;
}

void esp0_outstruct(char *data,int len)
{
    int x=0;
    for(x=0;x<len;x++)
        esp0_outbyte(*data++);
}

void esp0_outlong(long value)
{
    esp0_outbyte(((unsigned char *)(&value))[3]);  //LSB
    esp0_outbyte(((unsigned char *)(&value))[2]);
    esp0_outbyte(((unsigned char *)(&value))[1]);
    esp0_outbyte(((unsigned char *)(&value))[0]);  //MSB
}

void esp0_outint(int value)
{
    esp0_outbyte(((unsigned char *)(&value))[1]);  //LSB
    esp0_outbyte(((unsigned char *)(&value))[0]);  //MSB
}

void esp1_outstruct(char *data,int len)
{
    int x=0;
    for(x=0;x<len;x++)
        esp1_outbyte(*data++);
}
void esp1_outlong(long value)
{
    esp1_outbyte(((unsigned char *)(&value))[3]);  //LSB
    esp1_outbyte(((unsigned char *)(&value))[2]);
    esp1_outbyte(((unsigned char *)(&value))[1]);
    esp1_outbyte(((unsigned char *)(&value))[0]);  //MSB
}
void esp1_outint(int value)
{
    esp1_outbyte(((unsigned char *)(&value))[1]);  //LSB
    esp1_outbyte(((unsigned char *)(&value))[0]);  //MSB
}
