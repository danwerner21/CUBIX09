
typedef struct rgb rgb;

struct rgb {
  char b;
  char g;
  char r;
};

extern void SetCursor(char status);
extern void OutString(int x,int y,int xa,int ya,char font,char *string);
extern void SetResolution(char resolution);
extern void LoadFont(char font);
extern void ClearDisplay();
extern void CopyRectangle(int sX,int sY,int dX, int dY,int width, int height);
extern void DrawBitmap(int x,int y,int width, int height,char format,int size, char *data);
extern void DrawChar(int x,int y,char ch,char font);
extern void DrawEllipse(int x,int y,int width, int height);
extern void DrawGlyph(int x,int y,int width, int height,int index,int size, char *data);
extern void DrawLine(int sX,int sY,int dX, int dY);
extern void DrawRectangle(int sX,int sY,int dX, int dY);
extern void DrawFilledEllipse(int x,int y,int width, int height);
extern void DrawFilledRectangle(int sX,int sY,int dX, int dY);
extern rgb GetPixelValue(int x,int y);
extern void InvertRectangle(int sX,int sY,int dX, int dY);
extern void DrawLineTo(int x, int y);
extern void MoveCursorTo(int x, int y);
extern void ScrollDisplay(int x, int y);
extern void SetBrushColor(char c);
extern void SetLineEnds(char type);
extern void SetPenColor(char c);
extern void SetPenWidth(char w);
extern void SetPixel(int x, int y);
extern void SetGlyphOptions(char blank,char bold,char doubleWidth, char fillBackground,char invert,char italic,char underline);
extern void SetPallette(char index,char blue,char green, char red);
extern void SetMouseCursor(char type);
extern void SetMouseCursorPosition(int x, int y);
extern void ClearSprites();
extern void SetSpriteMap(char index,int width,int height,char format,int size,char *data);
extern void SetSpriteLocation(int x, int y,char index);
extern void SetSpriteVisibility(char index,char visible);
