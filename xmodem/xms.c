/*
    Copyright 2001, 2002 Georges Menie (www.menie.org)

    This program is free software; you can redistribute it and/or modify
    it under the terms of the GNU Lesser General Public License as published by
    the Free Software Foundation; either version 2 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU Lesser General Public License for more details.

    You should have received a copy of the GNU Lesser General Public License
    along with this program; if not, write to the Free Software
    Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

    Converted for use with Cubix09 by Dan Werner
    11/5/2023
 */

#include <stdio.h>

#define SOH 0x01
#define STX 0x02
#define EOT 0x04
#define ACK 0x06
#define NAK 0x15
#define CAN 0x18
#define CTRLZ 0x1A

#define DLY_1S 12000
#define MAXRETRANS 25
FILE *reader;

/* CRC16 implementation acording to CCITT standards */
unsigned char xbuff[1030]; /* 1024 for XModem 1k + 3 head chars + 2 crc + nul */

static const unsigned int crc16tab[256] = {
    0x0000, 0x1021, 0x2042, 0x3063, 0x4084, 0x50a5, 0x60c6, 0x70e7,
    0x8108, 0x9129, 0xa14a, 0xb16b, 0xc18c, 0xd1ad, 0xe1ce, 0xf1ef,
    0x1231, 0x0210, 0x3273, 0x2252, 0x52b5, 0x4294, 0x72f7, 0x62d6,
    0x9339, 0x8318, 0xb37b, 0xa35a, 0xd3bd, 0xc39c, 0xf3ff, 0xe3de,
    0x2462, 0x3443, 0x0420, 0x1401, 0x64e6, 0x74c7, 0x44a4, 0x5485,
    0xa56a, 0xb54b, 0x8528, 0x9509, 0xe5ee, 0xf5cf, 0xc5ac, 0xd58d,
    0x3653, 0x2672, 0x1611, 0x0630, 0x76d7, 0x66f6, 0x5695, 0x46b4,
    0xb75b, 0xa77a, 0x9719, 0x8738, 0xf7df, 0xe7fe, 0xd79d, 0xc7bc,
    0x48c4, 0x58e5, 0x6886, 0x78a7, 0x0840, 0x1861, 0x2802, 0x3823,
    0xc9cc, 0xd9ed, 0xe98e, 0xf9af, 0x8948, 0x9969, 0xa90a, 0xb92b,
    0x5af5, 0x4ad4, 0x7ab7, 0x6a96, 0x1a71, 0x0a50, 0x3a33, 0x2a12,
    0xdbfd, 0xcbdc, 0xfbbf, 0xeb9e, 0x9b79, 0x8b58, 0xbb3b, 0xab1a,
    0x6ca6, 0x7c87, 0x4ce4, 0x5cc5, 0x2c22, 0x3c03, 0x0c60, 0x1c41,
    0xedae, 0xfd8f, 0xcdec, 0xddcd, 0xad2a, 0xbd0b, 0x8d68, 0x9d49,
    0x7e97, 0x6eb6, 0x5ed5, 0x4ef4, 0x3e13, 0x2e32, 0x1e51, 0x0e70,
    0xff9f, 0xefbe, 0xdfdd, 0xcffc, 0xbf1b, 0xaf3a, 0x9f59, 0x8f78,
    0x9188, 0x81a9, 0xb1ca, 0xa1eb, 0xd10c, 0xc12d, 0xf14e, 0xe16f,
    0x1080, 0x00a1, 0x30c2, 0x20e3, 0x5004, 0x4025, 0x7046, 0x6067,
    0x83b9, 0x9398, 0xa3fb, 0xb3da, 0xc33d, 0xd31c, 0xe37f, 0xf35e,
    0x02b1, 0x1290, 0x22f3, 0x32d2, 0x4235, 0x5214, 0x6277, 0x7256,
    0xb5ea, 0xa5cb, 0x95a8, 0x8589, 0xf56e, 0xe54f, 0xd52c, 0xc50d,
    0x34e2, 0x24c3, 0x14a0, 0x0481, 0x7466, 0x6447, 0x5424, 0x4405,
    0xa7db, 0xb7fa, 0x8799, 0x97b8, 0xe75f, 0xf77e, 0xc71d, 0xd73c,
    0x26d3, 0x36f2, 0x0691, 0x16b0, 0x6657, 0x7676, 0x4615, 0x5634,
    0xd94c, 0xc96d, 0xf90e, 0xe92f, 0x99c8, 0x89e9, 0xb98a, 0xa9ab,
    0x5844, 0x4865, 0x7806, 0x6827, 0x18c0, 0x08e1, 0x3882, 0x28a3,
    0xcb7d, 0xdb5c, 0xeb3f, 0xfb1e, 0x8bf9, 0x9bd8, 0xabbb, 0xbb9a,
    0x4a75, 0x5a54, 0x6a37, 0x7a16, 0x0af1, 0x1ad0, 0x2ab3, 0x3a92,
    0xfd2e, 0xed0f, 0xdd6c, 0xcd4d, 0xbdaa, 0xad8b, 0x9de8, 0x8dc9,
    0x7c26, 0x6c07, 0x5c64, 0x4c45, 0x3ca2, 0x2c83, 0x1ce0, 0x0cc1,
    0xef1f, 0xff3e, 0xcf5d, 0xdf7c, 0xaf9b, 0xbfba, 0x8fd9, 0x9ff8,
    0x6e17, 0x7e36, 0x4e55, 0x5e74, 0x2e93, 0x3eb2, 0x0ed1, 0x1ef0};

int _inbyte(unsigned int timeout)
{
    int i;
    while (timeout--)
    {
        i = asm {
        LDA     $1F85
        ANDA    #$08
        BEQ     ?inbyt01
        LDA     #$00
        LDB     $1F84
        JMP     ?inbyt02
?inbyt01 NOP
        LDA     #$FF
        LDB     #$F1
?inbyt02 NOP
        };
        if (i >= 0)
        {
            return (unsigned char)i;
        }
    }
    return -1;
}


unsigned int crc16_ccitt(const unsigned char *buf, unsigned int len)
{
    unsigned int counter;
    unsigned int crc1;
    unsigned int index;
    crc1 = 0;
    for (counter = 0; counter < len; counter++)
    {
        index = ((crc1 >> 8) ^ *(char *)buf++);
        index = index & 0x00FF;
        crc1 = (crc1 << 8) ^ crc16tab[index];
    }
    return crc1;
}
static unsigned int check(int crc2, const unsigned char *buf, int sz)
{
    unsigned int crc3;
    unsigned int tcrc;
    unsigned int i;
    unsigned char cks;
    if (crc2)
    {
        tcrc = (buf[sz] << 8) + buf[sz + 1];
        crc3 = crc16_ccitt(buf, sz);
        if (crc3 == tcrc)
            return 1;
    }
    else
    {
        cks = 0;
        for (i = 0; i < sz; ++i)
        {
            cks += buf[i];
        }
        if (cks == buf[sz])
            return 1;
    }
    return 0;
}

static void flushinput(void)
{
    while (_inbyte(DLY_1S) > 0)
        continue;
}

void xmemset(unsigned char *dst, unsigned char ch, int count)
{
    while (count--)
        *dst++ = ch;
}

int xmodemTransmit()
{
    unsigned int ccrc;
    unsigned char ccks;
    int bufsz, crc;
    unsigned char packetno;
    int i, c, len, eof;
    int retry;
    crc = -1;
    packetno = 1;
    len = 0;
    eof = 0;

    for (;;)
    {
        for (retry = 0; retry < 16; ++retry)
        {
            if ((c = _inbyte((DLY_1S) << 1)) >= 0)
            {
                switch (c)
                {
                case 'C':
                    crc = 1;
                    goto start_trans;
                case NAK:
                    crc = 0;
                    goto start_trans;
                case CAN:
                    if ((c = _inbyte(DLY_1S)) == CAN)
                    {
                        putchr(ACK);
                        flushinput();
                        return -1; /* canceled by remote */
                    }
                    break;
                default:
                    break;
                }
            }
        }
        putchr(CAN);
        putchr(CAN);
        putchr(CAN);
        flushinput();
        return -2; /* no sync */

        for (;;)
        {
        start_trans:
            bufsz = 128;

            xbuff[0] = SOH;
            xbuff[1] = packetno;
            xbuff[2] = ~packetno;

            // read record
            eof = fgetb(&xbuff[3], 128, reader);
            if (eof != 0)
            {
                if (crc)
                {
                    ccrc = crc16_ccitt(&xbuff[3], bufsz);
                    xbuff[bufsz + 3] = (ccrc >> 8) & 0xFF;
                    xbuff[bufsz + 4] = ccrc & 0xFF;
                }
                else
                {
                    ccks = 0;
                    for (i = 3; i < bufsz + 3; ++i)
                    {
                        ccks += xbuff[i];
                    }
                    xbuff[bufsz + 3] = ccks;
                }

                for (retry = 0; retry < MAXRETRANS; ++retry)
                {
                    for (i = 0; i < bufsz + 4 + (crc ? 1 : 0); ++i)
                    {
                        putchr(xbuff[i]);
                    }

                    if ((c = _inbyte(DLY_1S)) >= 0)
                    {
                        switch (c)
                        {
                        case ACK:
                            ++packetno;
                            len += bufsz;
                            goto start_trans;
                        case CAN:
                            if ((c = _inbyte(DLY_1S)) == CAN)
                            {
                                putchr(ACK);
                                flushinput();
                                return -1; /* canceled by remote */
                            }
                            break;
                        case NAK:
                        default:
                            break;
                        }
                    }
                }
                putchr(CAN);
                putchr(CAN);
                putchr(CAN);
                flushinput();
                return -4; /* xmit error */
            }
            else
            {
                for (retry = 0; retry < 10; ++retry)
                {
                    putchr(EOT);
                    if ((c = _inbyte((DLY_1S) << 1)) == ACK)
                        break;
                }
                flushinput();
                return (c == ACK) ? len : -5;
            }
        }
    }
}

main(ac,av)
   int ac;
   int *av[];
{
    int st;

    if(ac<2)
    {
        printf("Use: XMS <FILENAME>\n\r");
        return 0;
    }

    reader = fopenr(av[1]);
    if (reader == 0)
    {
        printf("FILE OPEN ERROR\n\r");
        return 0;
    }
    printf("\n\rSending file: %s\n\r", av[1]);
    printf("\n\rPrepare your terminal emulator to receive data now...\n\r");
    st = xmodemTransmit();
    fclose(reader);
    if (st < 0)
    {
        printf("\n\rXmodem transmit error: status: %d\n\r", st);
    }
    else
    {
        printf("\n\rXmodem successfully transmitted %d bytes\n\r", st);
    }

    return 0;
}
