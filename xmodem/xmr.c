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
*/
/*
    Converted for use with Cubix09 by Dan Werner
    10/20/2023
    Modified to use checksum-only xmodem protocol
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
FILE *writer;

/* Buffer for xmodem packets: 128 bytes data + 3 header bytes + 1 checksum */
unsigned char xbuff[132];

unsigned char _inbyte(unsigned int timeout)
{
    int i;
    while (timeout--)
    {
        i = chkchr();
        if (i > 0)
        {
            return (unsigned char)(i & 0xFF);
        }
    }
    return 0;
}

void xmemcpy(unsigned char *dst, unsigned char *src, unsigned int count)
{
    while (count--)
        *dst++ = *src++;
}

/* Simple checksum calculation for xmodem */
static unsigned int check_checksum(const unsigned char *buf, int sz)
{
    unsigned int i;
    unsigned char cks;

    cks = 0;
    for (i = 0; i < sz; ++i)
    {
        cks += (unsigned char)buf[i];
    }

    return (cks == (unsigned char)buf[sz]) ? 1 : 0;
}

static void flushinput(void)
{
    while (_inbyte(DLY_1S) > 0)
        continue;
}

int xmodemReceive()
{
    unsigned char *p;
    unsigned char packetno;
    unsigned int i, len;
    unsigned char c;
    unsigned int retry, retrans;

    packetno = 1;
    len = 0;
    retrans = MAXRETRANS;

    /* Initial connection setup */
    for (retry = 0; retry < 30; ++retry)
    { /* approx 30 seconds allowed to make connection */
        putchr(NAK);  /* Request checksum mode */
        c = _inbyte(DLY_1S);
        if (c > 0)
        {
            switch (c)
            {
            case SOH:
                goto start_recv;
            case EOT:
                flushinput();
                putchr(ACK);
                return len; /* normal end */
            case CAN:
                c = _inbyte(DLY_1S);
                if (c == CAN)
                {
                    flushinput();
                    putchr(ACK);
                    return -1; /* canceled by remote */
                }
                break;
            default:
                break;
            }
        }
    }

    /* Connection timeout */
    flushinput();
    putchr(CAN);
    putchr(CAN);
    putchr(CAN);
    return -2; /* sync error */

start_recv:
    p = xbuff;
    *p++ = c;  /* SOH already received */

    /* Read packet number, complement, data (128 bytes), and checksum */
    for (i = 0; i < 131; ++i)  /* 1 + 1 + 128 + 1 = 131 more bytes */
    {
        c = _inbyte(DLY_1S);
        if (c == 0)  /* timeout */
            goto reject;
        *p++ = c;
    }

    /* Verify packet structure and checksum */
    if (xbuff[1] == (unsigned char)(~xbuff[2]) &&
        (xbuff[1] == packetno || xbuff[1] == (unsigned char)packetno - 1) &&
        check_checksum(&xbuff[3], 128))
    {
        if (xbuff[1] == packetno)
        {
            /* Write 128-byte record */
            fputb(xbuff + 3, 128, writer);
            len += 128;
            ++packetno;
            retrans = MAXRETRANS + 1;
        }
        /* If duplicate packet (packetno-1), just ACK it */
        if (--retrans <= 0)
        {
            flushinput();
            putchr(CAN);
            putchr(CAN);
            putchr(CAN);
            return -3; /* too many retry error */
        }
        putchr(ACK);

        /* Wait for next packet */
        for (;;)
        {
            c = _inbyte(DLY_1S);
            if (c > 0)
            {
                switch (c)
                {
                case SOH:
                    goto start_recv;
                case EOT:
                    flushinput();
                    putchr(ACK);
                    return len; /* normal end */
                case CAN:
                    c = _inbyte(DLY_1S);
                    if (c == CAN)
                    {
                        flushinput();
                        putchr(ACK);
                        return -1; /* canceled by remote */
                    }
                    break;
                default:
                    break;
                }
            }
            else
            {
                /* Timeout waiting for next packet */
                goto reject;
            }
        }
    }

reject:
    flushinput();
    putchr(NAK);

    /* Wait for retransmission */
    for (;;)
    {
        c = _inbyte(DLY_1S);
        if (c > 0)
        {
            switch (c)
            {
            case SOH:
                goto start_recv;
            case EOT:
                flushinput();
                putchr(ACK);
                return len; /* normal end */
            case CAN:
                c = _inbyte(DLY_1S);
                if (c == CAN)
                {
                    flushinput();
                    putchr(ACK);
                    return -1; /* canceled by remote */
                }
                break;
            default:
                break;
            }
        }
        else
        {
            /* Timeout - send NAK again */
            putchr(NAK);
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
        printf("Use: XMR <FILENAME>\n\r");
        return 0;
    }

    writer = fopenw(av[1]);
    printf("\n\rReceiving file: %s\n\r",av[1]);
    printf("\n\rSend data using the xmodem protocol (checksum mode) from your terminal emulator now...\n\r");
    st = xmodemReceive();
    fclose(writer);
    if (st < 0)
    {
        printf("\n\rXmodem receive error: status: %d\n\r", st);
    }
    else
    {
        printf("\n\rXmodem successfully received %d bytes\n\r", st);
    }
    return 0;
}
