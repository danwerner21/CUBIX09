
#include"graphics.h"
#include "esp.h"


void OutString(int x,int y,int xa,int ya,char font,char *string)
{
    char ch;
    for(;;)
    {
        ch=*string++;
        if(ch==0) return;
        DrawChar(x,y,ch,font);
        x+=xa;
        y+=ya;
    }
}

void SetCursor(char status)
{
    esp0_outbyte(5);    // send opcode '5'
    esp0_outbyte(status);

}

void SetResolution(char resolution)
{
    esp0_outbyte(15);    // send opcode '15'
    esp0_outbyte(resolution);

}

void LoadFont(char font)
{
    esp0_outbyte(16);    // send opcode '16'
    esp0_outbyte(font);  //LSB
}

void ClearDisplay()
{
    esp0_outbyte(17);    // send opcode '17'
}

void CopyRectangle(int sX,int sY,int dX, int dY,int width, int height)
{
    esp0_outbyte(18);    // send opcode '18'
    esp0_outint(sX);
    esp0_outint(sY);
    esp0_outint(dX);
    esp0_outint(dY);
    esp0_outint(width);
    esp0_outint(height);
}

void DrawBitmap(int x,int y,int width, int height,char format,int size, char *data)
{
    esp0_outbyte(19);    // send opcode '19'
    esp0_outint(x);
    esp0_outint(y);
    esp0_outint(width);
    esp0_outint(height);
    esp0_outbyte(format);
    esp0_outint(size);
    esp0_outstruct(data,size);
}

void DrawChar(int x,int y,char ch,char font)
{
    esp0_outbyte(20);    // send opcode '20'
    esp0_outint(x);
    esp0_outint(y);
    esp0_outbyte(ch);
    esp0_outbyte(font);
}

void DrawEllipse(int x,int y,int width, int height)
{
    esp0_outbyte(21);    // send opcode '21'
    esp0_outint(x);
    esp0_outint(y);
    esp0_outint(width);
    esp0_outint(height);
}

void DrawGlyph(int x,int y,int width, int height,int index,int size, char *data)
{
    esp0_outbyte(22);    // send opcode '22'
    esp0_outint(x);
    esp0_outint(y);
    esp0_outint(width);
    esp0_outint(height);
    esp0_outint(index);
    esp0_outint(size);
    esp0_outstruct(data,size);
}

void DrawLine(int sX,int sY,int dX, int dY)
{
    esp0_outbyte(23);    // send opcode '23'
    esp0_outint(sX);
    esp0_outint(sY);
    esp0_outint(dX);
    esp0_outint(dY);
}

void DrawRectangle(int sX,int sY,int dX, int dY)
{
    esp0_outbyte(24);    // send opcode '24'
    esp0_outint(sX);
    esp0_outint(sY);
    esp0_outint(dX);
    esp0_outint(dY);
}

void DrawFilledEllipse(int x,int y,int width, int height)
{
    esp0_outbyte(25);    // send opcode '25'
    esp0_outint(x);
    esp0_outint(y);
    esp0_outint(width);
    esp0_outint(height);
}

void DrawFilledRectangle(int sX,int sY,int dX, int dY)
{
    esp0_outbyte(26);    // send opcode '26'
    esp0_outint(sX);
    esp0_outint(sY);
    esp0_outint(dX);
    esp0_outint(dY);
}

rgb GetPixelValue(int x,int y)
{
    rgb result;

    esp0_outbyte(27);    // send opcode '27'
    esp0_outint(x);
    esp0_outint(y);
    result.b = esp0_inbytewait();
    result.g = esp0_inbytewait();
    result.r = esp0_inbytewait();
}

void InvertRectangle(int sX,int sY,int dX, int dY)
{
    esp0_outbyte(28);    // send opcode '28'
    esp0_outint(sX);
    esp0_outint(sY);
    esp0_outint(dX);
    esp0_outint(dY);
}

void DrawLineTo(int x, int y)
{
    esp0_outbyte(29);    // send opcode '29'
    esp0_outint(x);
    esp0_outint(y);
}

void MoveCursorTo(int x, int y)
{
    esp0_outbyte(30);    // send opcode '30'
    esp0_outint(x);
    esp0_outint(y);
}

void ScrollDisplay(int x, int y)
{
    esp0_outbyte(31);    // send opcode '31'
    esp0_outint(x);
    esp0_outint(y);
}

void SetBrushColor(char c)
{
    esp0_outbyte(32);  // send opcode '32'
    esp0_outbyte(c);
}

void SetLineEnds(char type)
{
    esp0_outbyte(33);    // send opcode '33'
    esp0_outbyte(type);
}

void SetPenColor(char c)
{
    esp0_outbyte(34);    // send opcode '34'
    esp0_outbyte(c);
}

void SetPenWidth(char w)
{
    esp0_outbyte(35);    // send opcode '35'
    esp0_outbyte(w);
}

void SetPixel(int x, int y)
{
    esp0_outbyte(36);    // send opcode '36'
    esp0_outint(x);
    esp0_outint(y);
}

void SetGlyphOptions(char blank,char bold,char doubleWidth, char fillBackground,char invert,char italic,char underline)
{
    esp0_outbyte(37);    // send opcode '37'
    esp0_outbyte(blank);
    esp0_outbyte(bold);
    esp0_outbyte(doubleWidth);
    esp0_outbyte(fillBackground);
    esp0_outbyte(invert);
    esp0_outbyte(italic);
    esp0_outbyte(underline);
}

void SetPallette(char index,char blue,char green, char red)
{
    esp0_outbyte(38);    // send opcode '38'
    esp0_outbyte(index);
    esp0_outbyte(blue);
    esp0_outbyte(green);
    esp0_outbyte(red);
}

void SetMouseCursor(char type)
{
    esp0_outbyte(39);    // send opcode '39'
    esp0_outbyte(type);
}

void SetMouseCursorPosition(int x, int y)
{
    esp0_outbyte(40);    // send opcode '40'
    esp0_outint(x);
    esp0_outint(y);
}

void ClearSprites()
{
    esp0_outbyte(41);    // send opcode '41'
}

void SetSpriteMap(char index,int width,int height,char format,int size,char *data)
{
    esp0_outbyte(42);    // send opcode '42'
    esp0_outbyte(index);
    esp0_outint(width);
    esp0_outint(height);
    esp0_outbyte(format);
    esp0_outint(size);
    esp0_outstruct(data,size);
}

void SetSpriteLocation(int x, int y,char index)
{
    esp0_outbyte(43);    // send opcode '43'
    esp0_outint(x);
    esp0_outint(y);
    esp0_outbyte(index);
}

void SetSpriteVisibility(char index,char visible)
{
    esp0_outbyte(44);    // send opcode '44'
    esp0_outbyte(index);
    esp0_outbyte(visible);
}
