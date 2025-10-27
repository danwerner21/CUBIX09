/*
 * SUPER STAR TREK - C Version
 * Originally Converted from BASIC version dated MAY 16, 1978
 *
 * Original BASIC program by Mike Mayfield, modified by Dave Ahl
 * Further modifications by Bob Leedom
 * Converted to Microsoft 8K BASIC by John Gorders
 */

// todo: opening screen (w/music)
//       Sound effects
//       Speech?
//       3d (ok, 2d arcade playing)
//       glyphs and graphics (three views, facing, 45 deg, rear and then mirror)
//       operations pop ups

// current bugs/working
//        Navigation

#include "../gcclib/stdio.h"
#include "../gcclib/graphics.h"

/* Game constants */
#define GALAXY_SIZE 7 // Galaxy size is this value +1
#define SECTOR_SIZE 7 // Sector size is this value +1
#define MAX_KLINGONS 3
#define MAX_DEVICES 8
#define MAX_COMMANDS 9

/* Device indices */
#define WARP_ENGINES 0
#define SHORT_SENSORS 1
#define LONG_SENSORS 2
#define PHASER_CONTROL 3
#define PHOTON_TUBES 4
#define DAMAGE_CONTROL 5
#define SHIELD_CONTROL 6
#define LIBRARY_COMPUTER 7

static char *star_names1[] = {"ANTARES", "RIGEL", "PROCYON", "VEGA",
                              "CANOPUS", "ALTAIR", "SAGITTARIUS", "POLLUX"};
static char *star_names2[] = {"SIRIUS", "DENEB", "CAPELLA", "BETELGEUSE",
                              "ALDEBARAN", "REGULUS", "ARCTURUS", "SPICA"};
static char *roman_numerals[] = {" I", " II", " III", " IV"};
static char *device_names[] = {
    "WARP ENGINES", "SHORT RANGE SENSORS", "LONG RANGE SENSORS",
    "PHASER CONTROL", "PHOTON TUBES", "DAMAGE CONTROL",
    "SHIELD CONTROL", "LIBRARY-COMPUTER"};
static int Dir[3][8] = {{1, 1, 0, -1, -1, -1, 0, 1}, /* Navigation Directions*/
                        {0, -1, -1, -1, 0, 1, 1, 1},
                        {1, 2, 0, 2, 1, 2, 0, 2}};

static char enterpriseGlyph1[36] = {0, 3, 128, 127, 135, 192, 127, 143, 224, 28, 31, 240, 14, 31, 240,
                                    7, 255, 240, 7, 255, 240, 14, 31, 240, 28, 31, 240, 127, 143, 224,
                                    127, 135, 192, 0, 3, 128};

static char enterpriseGlyph2[57] = {0, 0, 240, 0, 3, 248, 0, 7, 252, 0, 15, 254, 0, 15, 254, 0, 15, 254, 0, 15, 254,
                                    0, 135, 252, 1, 199, 248, 3, 142, 240, 7, 252, 0, 14, 120, 0, 4, 57, 0, 0, 27, 128,
                                    0, 31, 0, 0, 30, 0, 0, 60, 0, 0, 120, 0, 0, 48, 0};

static char enterpriseGlyph3[38] = {31, 128, 63, 192, 127, 224, 255, 240, 255, 240, 255, 240, 127, 224,
                                    63, 192, 31, 128, 6, 0, 6, 0, 102, 96, 102, 96, 111, 96, 127, 224,
                                    121, 224, 112, 224, 96, 96, 96, 96};

static char enterpriseGlyph4[57] = {15, 0, 0, 31, 192, 0, 63, 224, 0, 127, 240, 0, 127, 240, 0, 127, 240, 0,
                                    127, 240, 0, 63, 225, 0, 31, 227, 128, 15, 113, 192, 0, 63, 224, 0, 30, 112,
                                    0, 156, 32, 1, 216, 0, 0, 248, 0, 0, 120, 0, 0, 60, 0, 0, 30, 0, 0, 12, 0};

static char enterpriseGlyph5[36] = {1, 192, 0, 3, 225, 254, 7, 241, 254, 15, 248, 56, 15, 248, 112, 15, 255, 224,
                                    15, 255, 224, 15, 248, 112, 15, 248, 56, 7, 241, 254, 3, 225, 254, 1, 192, 0};

static char enterpriseGlyph6[57] = {0, 12, 0, 0, 30, 0, 0, 60, 0, 0, 120, 0, 0, 248, 0, 1, 216, 0, 0, 156, 32,
                                    0, 30, 112, 0, 63, 224, 15, 113, 192, 31, 227, 128, 63, 225, 0, 127, 240, 0,
                                    127, 240, 0, 127, 240, 0, 127, 240, 0, 63, 224, 0, 31, 192, 0, 15, 0, 0};

static char enterpriseGlyph7[38] = {96, 96, 96, 96, 112, 224, 121, 224, 127, 224, 111, 96, 102, 96, 102, 96,
                                    6, 0, 6, 0, 31, 128, 63, 192, 127, 224, 255, 240, 255, 240, 255, 240,
                                    127, 224, 63, 192, 31, 128};

static char enterpriseGlyph8[57] = {0, 48, 0, 0, 120, 0, 0, 60, 0, 0, 30, 0, 0, 31, 0, 0, 27, 128, 4, 57, 0, 14, 120, 0,
                                    7, 252, 0, 3, 142, 240, 1, 199, 248, 0, 135, 252, 0, 15, 254, 0, 15, 254, 0, 15, 254,
                                    0, 15, 254, 0, 7, 252, 0, 3, 248, 0, 0, 240};

static char *enterpriseGlyph[8] = {enterpriseGlyph1, enterpriseGlyph2, enterpriseGlyph3, enterpriseGlyph4, enterpriseGlyph5, enterpriseGlyph6, enterpriseGlyph7, enterpriseGlyph8};

static char enterpriseGlyphOffsetX[3] = {224, 220, 220};
static char enterpriseGlyphOffsetY[3] = {10, 14, 10};
static char enterpriseGlyphSize[3] = {38, 36, 57};
static char enterpriseGlyphSizeX[3] = {16, 24, 24};
static char enterpriseGlyphSizeY[3] = {19, 12, 19};
static char enterpriseDirection = 0;

static char starGlyph[9] = {16, 146, 84, 56, 254, 56, 84, 146, 16};
static char baseGlyph[60] = {0, 224, 0, 1, 240, 0, 1, 240, 0, 0, 224, 0, 0, 64, 0, 0, 64, 0,
                             1, 240, 0, 103, 252, 192, 247, 253, 224, 255, 255, 224, 247, 253, 224,
                             103, 252, 192, 3, 248, 0, 1, 240, 0, 0, 64, 0, 0, 64, 0, 0, 224, 0, 1, 240, 0,
                             1, 240, 0, 0, 224, 0};

static char klingonGlyph1[20] = {255, 0, 255, 0, 12, 14, 12, 31, 15, 255, 15, 255, 12, 31, 12, 14, 255, 0, 255, 0};

static char klingonGlyph2[51] = {0, 0, 14, 0, 0, 31, 0, 0, 31, 0, 0, 31, 0, 8, 62, 0, 28, 112, 0, 56, 224, 0, 125, 192,
                                 0, 231, 128, 1, 195, 16, 0, 129, 184, 0, 0, 240, 0, 0, 224, 0, 1, 192, 0, 3, 128, 0, 7, 0, 0, 2, 0};

static char klingonGlyph3[32] = {15, 0, 31, 128, 31, 128, 31, 128, 15, 0, 6, 0, 6, 0,
                                 6, 0, 102, 96, 102, 96, 127, 224, 127, 224, 96, 96,
                                 96, 96, 96, 96, 96, 96};

static char klingonGlyph4[51] = {112, 0, 0, 248, 0, 0, 248, 0, 0, 248, 0, 0, 124, 16, 0, 14, 56, 0, 7, 28, 0, 3, 190, 0,
                                 1, 231, 0, 8, 195, 128, 29, 129, 0, 15, 0, 0, 7, 0, 0, 3, 128, 0, 1, 192, 0, 0, 224, 0, 0, 64, 0};

static char klingonGlyph5[20] = {0, 255, 0, 255, 112, 48, 248, 48, 255, 240, 255, 240, 248, 48, 112, 48, 0, 255, 0, 255};

static char klingonGlyph6[51] = {0, 64, 0, 0, 224, 0, 1, 192, 0, 3, 128, 0, 7, 0, 0, 15, 0, 0, 29, 129, 0,
                                 8, 195, 128, 1, 231, 0, 3, 190, 0, 7, 28, 0, 14, 56, 0, 124, 16, 0, 248, 0, 0,
                                 248, 0, 0, 248, 0, 0, 112, 0, 0};

static char klingonGlyph7[32] = {96, 96, 96, 96, 96, 96, 96, 96, 127, 224, 127, 224, 102, 96, 102, 96, 6, 0, 6, 0,
                                 6, 0, 15, 0, 31, 128, 31, 128, 31, 128, 15, 0};

static char klingonGlyph8[51] = {0, 2, 0, 0, 7, 0, 0, 3, 128, 0, 1, 192, 0, 0, 224, 0, 0, 240, 0, 129, 184, 1, 195, 16, 0, 231, 128,
                                 0, 125, 192, 0, 56, 224, 0, 28, 112, 0, 8, 62, 0, 0, 31, 0, 0, 31, 0, 0, 31, 0, 0, 14};

static char *klingonGlyph[8] = {klingonGlyph1, klingonGlyph2, klingonGlyph3, klingonGlyph4, klingonGlyph5, klingonGlyph6, klingonGlyph7, klingonGlyph8};

static char klingonGlyphOffsetX[3] = {220, 220, 220};
static char klingonGlyphOffsetY[3] = {10, 10, 10};
static char klingonGlyphSize[3] = {32, 20, 51};
static char klingonGlyphSizeX[3] = {16, 16, 24};
static char klingonGlyphSizeY[3] = {16, 10, 17};

/* Global game state */
int G[GALAXY_SIZE + 1][GALAXY_SIZE + 1]; /* Galaxy map */
int K[MAX_KLINGONS][3];                  /* Klingon positions and energy */
int Z[GALAXY_SIZE + 1][GALAXY_SIZE + 1]; /* Cumulative galactic record */
int D[MAX_DEVICES];                      /* Damage array */
int N[3];                                /* Temporary array */

/* Game variables */
int T, T0, T9;      /* Time variables */
int E, E0;          /* Energy */
int P, P0;          /* Photon torpedoes */
int S, S9;          /* Shield energy */
int B9, K9, K7;     /* Starbases, Klingons */
int Q1, Q2, S1, S2; /* Quadrant and sector positions */
int K3, B3, S3;     /* Quadrant contents */
int B4, B5;         /* Starbase position */
int D0, D4;         /* Docked flag, damage repair time */
char Q[193];        /* Quadrant string */
char Qu[65];        /* Quadrant string */
char A1[28];        /* Command string */
char G2[20];        /* Region name */
char C_STR[10];     /* Condition string */
char C_STR_COLOR;   /* Condition string COLOR*/

/* Game restart flag (replaces recursive main() call) */
int restart_game = 0;

/* Function prototypes */
void paint_intro_screen();
void initialize_game(void);
void print_instructions(void);
void enter_quadrant(void);
void short_range_scan(void);
void long_range_scan(void);
void phaser_control(void);
void photon_torpedoes(void);
void shield_control(void);
void damage_report(void);
void library_computer(void);
void navigation(void);
void end_game(void);
void klingon_attack(void);
void place_enterprise(void);
void place_objects(void);
void get_quadrant_name(int z4, int z5);
int get_random(int max);
int find_empty_sector(void);
void update_quadrant_string(int z1, int z2, char *symbol, char t);
char *get_quadrant_symbol(int z1, int z2);
void repair_damage(void);
int calculate_distance(int x1, int y1, int x2, int y2);
int calculate_direction(int x1, int y1, int x2, int y2);
int abs_value(int x);

/* Simple replacements for standard library functions */
int simple_strlen(char *str);
void simple_strcpy(char *dest, char *src);
void simple_strcat(char *dest, char *src);
int simple_strcmp(char *str1, char *str2);
int simple_strncmp(char *str1, char *str2, int n);
int simple_scanf_int(void);
void simple_gets(char *buffer, int max_len);
char simple_getchar(void);

/* Random number seed */
static unsigned lfsr = 0xACE1u;
static unsigned bit;

static unsigned int random_seed = 1;

/* Simple absolute value function */
int abs_value(int x)
{
    return (x < 0) ? -x : x;
}

/* Simple random number generator (using smaller constants for 16-bit) */
int get_random(int max)
{
    lfsr = lfsr + randseed();
    bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1;
    lfsr = (lfsr >> 1) | (bit << 15);

    return (lfsr % max);
}

/* Simple string functions to replace standard library */
int simple_strlen(char *str)
{
    int len;
    len = 0;
    while (str[len] != '\0')
        len++;
    return len;
}

void simple_strcpy(char *dest, char *src)
{
    int i;
    i = 0;
    while (src[i] != '\0')
    {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0';
}

void simple_strcat(char *dest, char *src)
{
    int dest_len;
    int i;

    dest_len = simple_strlen(dest);
    i = 0;

    while (src[i] != '\0')
    {
        dest[dest_len + i] = src[i];
        i++;
    }
    dest[dest_len + i] = '\0';
}

int simple_strcmp(char *str1, char *str2)
{
    int i;
    i = 0;
    while (str1[i] != '\0' && str2[i] != '\0')
    {
        if (str1[i] != str2[i])
        {
            return str1[i] - str2[i];
        }
        i++;
    }
    return str1[i] - str2[i];
}

int simple_strncmp(char *str1, char *str2, int n)
{
    int i;
    for (i = 0; i < n && str1[i] != '\0' && str2[i] != '\0'; i++)
    {
        if (str1[i] != str2[i])
        {
            return str1[i] - str2[i];
        }
    }
    if (i == n)
        return 0;
    return str1[i] - str2[i];
}

/* Simple input functions */
char simple_getchar(void)
{
    char ch = getch();
    ch = toupper(ch);
    outbyte(ch);
    return ch; /* Assuming minimal getchar() is available */
}

int simple_scanf_int(void)
{
    char buffer[10];
    int i;
    int result;
    int negative;
    char c;

    i = 0;
    result = 0;
    negative = 0;

    /* Skip whitespace */
    do
    {
        c = simple_getchar();
    } while (c == ' ' || c == '\t' || c == '\n' || c == '\r');

    /* Check for negative */
    if (c == '-')
    {
        negative = 1;
        c = simple_getchar();
    }

    /* Read digits */
    while (c >= '0' && c <= '9' && i < 9)
    {
        buffer[i++] = c;
        c = simple_getchar();
    }
    buffer[i] = '\0';

    /* Convert to integer */
    for (i = 0; buffer[i] != '\0'; i++)
    {
        result = result * 10 + (buffer[i] - '0');
    }

    return negative ? -result : result;
}

void simple_gets(char *buffer, int max_len)
{
    int i;
    char c;

    i = 0;

    while (i < max_len - 1)
    {
        c = simple_getchar();
        if (c == '\n' || c == '\r')
            break;
        buffer[i++] = c;
    }
    buffer[i] = '\0';
}

void paint_intro_screen()
{
    ClearDisplay();
    SetCursor(0);
    SetPenColor(4);
    OutString(100, 100, 9, 0, 23, "STAR TREK");
    getch();
}

void paint_player_screen()
{
    ClearDisplay();
    SetCursor(0);
    SetPenColor(12);
    DrawRectangle(0, 0, 639, 479);
    SetPenColor(3);
    DrawLine(1, 200, 638, 200);
    DrawLine(1, 135, 200, 135);

    DrawLine(200, 1, 200, 200);
    DrawLine(411, 1, 411, 200);
    SetPenColor(6);
    OutString(10, 10, 6, 0, 7, "STARDATE");
    OutString(10, 25, 6, 0, 7, "CONDITION");
    OutString(10, 40, 6, 0, 7, "QUADRANT");
    OutString(10, 55, 6, 0, 7, "SECTOR");
    OutString(10, 70, 6, 0, 7, "PHOTON TORPEDOES");
    OutString(10, 85, 6, 0, 7, "ENERGY");
    OutString(10, 100, 6, 0, 7, "SHIELDS");
    OutString(10, 115, 6, 0, 7, "KLINGONS");
    C_STR_COLOR = 0;
    C_STR[0] = 0;
    C_STR[1] = 0;
}

void paint_player_updates()
{
    char buf[30];
    int i, j, d;

    SetPenColor(0);
    SetBrushColor(0);
    DrawFilledRectangle(125, 10, 198, 130);
    DrawFilledRectangle(220, 10, 410, 170);
    DrawFilledRectangle(10,210, 400, 470);

    SetPenColor(5);
    sprintf(buf, "%d", T);
    OutString(135, 10, 8, 0, 25, buf);
    sprintf(buf, "%d,%d", Q1, Q2);
    OutString(135, 40, 8, 0, 25, buf);
    sprintf(buf, "%d,%d", S1, S2);
    OutString(135, 55, 8, 0, 25, buf);
    sprintf(buf, "%d", P);
    OutString(135, 70, 8, 0, 25, buf);
    sprintf(buf, "%d", E + S);
    OutString(135, 85, 8, 0, 25, buf);
    sprintf(buf, "%d", S);
    OutString(135, 100, 8, 0, 25, buf);
    sprintf(buf, "%d", K9);
    OutString(135, 115, 8, 0, 25, buf);

    SetPenColor(C_STR_COLOR);
    OutString(135, 25, 8, 0, 25, C_STR);

    SetPenColor(7);
    // Draw Tactical
    for (i = 0; i <= SECTOR_SIZE; i++)
    {
        for (j = 0; j <= SECTOR_SIZE; j++)
        {
            if (Qu[j + (i * 8)] == '*')
            {
                SetPenColor(3);
                DrawGlyph((j * 20) + 226, (i * 20) + 15, 8, 9, 0, 9, starGlyph);
            }

            if (Qu[j + (i * 8)] == 'E')
            {
                SetPenColor(10);
                DrawGlyph((j * 20) + enterpriseGlyphOffsetX[Dir[2][enterpriseDirection]], (i * 20) + enterpriseGlyphOffsetY[Dir[2][enterpriseDirection]], enterpriseGlyphSizeX[Dir[2][enterpriseDirection]], enterpriseGlyphSizeY[Dir[2][enterpriseDirection]], 0, enterpriseGlyphSize[Dir[2][enterpriseDirection]], enterpriseGlyph[enterpriseDirection]);
            }

            if (Qu[j + (i * 8)] == 'X')
            {
                SetPenColor(12);
                DrawGlyph((j * 20) + 220, (i * 20) + 10, 24, 20, 0, 60, baseGlyph);
            }

            if (Qu[j + (i * 8)] == 'K')
            {
                d = 0;
                if (S2 > j)
                {
                    if (S1 > i)
                        d = 7;
                    if (S1 == i)
                        d = 0;
                    if (S1 < i)
                        d = 1;
                }
                if (S2 < j)
                {
                    if (S1 > i)
                        d = 5;
                    if (S1 == i)
                        d = 4;
                    if (S1 < i)
                        d = 3;
                }
                if (S2 == j)
                {
                    if (S1 > i)
                        d = 6;
                    if (S1 < i)
                        d = 2;
                }
                SetPenColor(9);
                DrawGlyph((j * 20) + klingonGlyphOffsetX[Dir[2][d]], (i * 20) + klingonGlyphOffsetY[Dir[2][d]], klingonGlyphSizeX[Dir[2][d]], klingonGlyphSizeY[Dir[2][d]], 0, klingonGlyphSize[Dir[2][d]], klingonGlyph[d]);
            }
        }
    }

    // Draw Viewer
    // 100% view
    j=S2+Dir[0][enterpriseDirection];
    i=S1+Dir[1][enterpriseDirection];

    if(Qu[j + (i * 8)]=='*')
    {
        SetPenColor(3);
        SetGlyphOptions(0,1,1,0,0,0,0);
        DrawGlyph(300,270, 8, 9, 0, 9, starGlyph);
        SetGlyphOptions(0,0,0,0,0,0,0);
    }
    if(Qu[j + (i * 8)]=='K')
    {
        SetPenColor(9);
        SetGlyphOptions(0,1,1,0,0,0,0);
        DrawGlyph(300,270, klingonGlyphSizeX[Dir[2][5]], klingonGlyphSizeY[Dir[2][5]], 0, klingonGlyphSize[Dir[2][5]], klingonGlyph[5]);
        SetGlyphOptions(0,0,0,0,0,0,0);
    }
    if(Qu[j + (i * 8)]=='X')
    {
        SetPenColor(12);
        SetGlyphOptions(0,1,1,0,0,0,0);
        DrawGlyph(300,270, 24, 20, 0, 60, baseGlyph);
        SetGlyphOptions(0,0,0,0,0,0,0);
    }

}

/* Initialize game */
void initialize_game(void)
{
    int i, j, k3, b3, s3;

    /* Set up time and energy */
    T = (get_random(20) + 20) * 100;
    T0 = T;
    T9 = get_random(10) + 25;
    E = 3000;
    E0 = E;
    P = 10;
    P0 = P;
    S9 = 200;
    S = 0;
    B9 = 0;
    K9 = 0;
    D0 = 0;
    enterpriseDirection = 0;
    /* Initialize damage array */
    for (i = 0; i < MAX_DEVICES; i++)
    {
        D[i] = 0;
    }

    /* Set up command string */
    simple_strcpy(A1, "NAVSRSLRSPHATORSHEDAMCOMXXX");

    /* Set up galaxy */
    for (i = 0; i <= GALAXY_SIZE; i++)
    {
        for (j = 0; j <= GALAXY_SIZE; j++)
        {
            k3 = 0;
            b3 = 0;
            s3 = get_random(8) + 1;

            /* Place Klingons */
            if (get_random(100) > 98)
            {
                k3 = 3;
                K9 += 3;
            }
            else if (get_random(100) > 95)
            {
                k3 = 2;
                K9 += 2;
            }
            else if (get_random(100) > 80)
            {
                k3 = 1;
                K9 += 1;
            }

            /* Place starbases */
            if (get_random(100) > 96)
            {
                b3 = 1;
                B9 += 1;
            }

            G[i][j] = k3 * 100 + b3 * 10 + s3;
            Z[i][j] = 0;
        }
    }

    /* Ensure at least one starbase */
    if (B9 == 0)
    {
        i = get_random(GALAXY_SIZE);
        j = get_random(GALAXY_SIZE);
        if (G[i][j] < 200)
        {
            G[i][j] += 120;
            K9++;
        }
        B9 = 1;
        G[i][j] += 10;
    }

    /* Set starting position */
    Q1 = get_random(GALAXY_SIZE);
    Q2 = get_random(GALAXY_SIZE);
    S1 = get_random(SECTOR_SIZE);
    S2 = get_random(SECTOR_SIZE);

    /* Set mission parameters */
    K7 = K9;
    if (K9 > T9)
        T9 = K9 + 1;

    /* Initialize quadrant string */
    for (i = 0; i < 192; i++)
    {
        Q[i] = ' ';
    }
    for (i = 0; i < 65; i++)
    {
        Qu[i] = ' ';
    }

    Q[192] = '\0';
}

/* Print game instructions */
void print_instructions(void)
{
    printf("\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r\n\r");
    printf("                ,------*------,\n\r");
    printf(",-------------   '---  ------'\n\r");
    printf(" '-------- --'      / /\n\r");
    printf("    ,---' '-------/ /--,\n\r");
    printf("    '----------------'\n\r\n\r");
    printf("  THE USS ENTERPRISE --- NCC-1701\n\r");
    printf("\n\r\n\r\n\r\n\r\n\r");

    printf("YOUR ORDERS ARE AS FOLLOWS:\n\r");
    printf("     DESTROY THE %d KLINGON WARSHIPS WHICH HAVE INVADED\n\r", K9);
    printf("   THE GALAXY BEFORE THEY CAN ATTACK FEDERATION HEADQUARTERS\n\r");
    printf("   ON STARDATE %d. THIS GIVES YOU %d DAYS. THERE", T0 + T9, T9);
    if (B9 == 1)
    {
        printf(" IS\n\r  1 STARBASE IN THE GALAXY FOR RESUPPLYING YOUR SHIP\n\r");
    }
    else
    {
        printf(" ARE\n\r  %d STARBASES IN THE GALAXY FOR RESUPPLYING YOUR SHIP\n\r", B9);
    }
    printf("\n\r");
}

/* Enter new quadrant */
void enter_quadrant(void)
{
    int i;

    /* Get quadrant info */
    K3 = G[Q1][Q2] / 100;
    B3 = (G[Q1][Q2] % 100) / 10;
    S3 = G[Q1][Q2] % 10;

    /* Clear quadrant */
    for (i = 0; i < 192; i++)
    {
        Q[i] = ' ';
    }
    for (i = 0; i < 65; i++)
    {
        Qu[i] = ' ';
    }

    /* Clear Klingon array */
    for (i = 0; i < MAX_KLINGONS; i++)
    {
        K[i][0] = 0;
        K[i][1] = 0;
        K[i][2] = 0;
    }

    /* Get quadrant name and print entry message */
    get_quadrant_name(Q1, Q2);
    if (T0 == T)
    {
        printf("YOUR MISSION BEGINS WITH YOUR STARSHIP LOCATED\n\r");
        printf("IN THE GALACTIC QUADRANT, '%s'.\n\r", G2);
    }
    else
    {
        printf("NOW ENTERING %s QUADRANT . . .\n\r", G2);
    }

    /* Check for combat */
    if (K3 > 0)
    {
        printf("COMBAT AREA      CONDITION RED\n\r");
        if (S <= 200)
        {
            printf("   SHIELDS DANGEROUSLY LOW\n\r");
        }
    }

    /* Place objects */
    place_objects();

    /* Place Enterprise */
    place_enterprise();

    /* Update cumulative record */
    Z[Q1][Q2] = G[Q1][Q2];
}

/* Place Enterprise in quadrant */
void place_enterprise(void)
{
    int conflicts = 1, retry = 0;
    while (conflicts)
    {
        if (Qu[S2 + (S1 * 8)] != ' ')
        {
            S2++;
            retry++;
            if (S2 > SECTOR_SIZE)
                S2 = 0;
            if (retry == 8)
            {
                S1++;
                retry = 0;
                if (S1 > SECTOR_SIZE)
                    S1 = 0;
            }
        }
        else
            conflicts = 0;
    }
    update_quadrant_string(S1, S2, "<*>", 'E');
}

/* Place Klingons, starbases, and stars */
void place_objects(void)
{
    int i, r1, r2;

    /* Place Klingons */
    for (i = 0; i < K3; i++)
    {
        do
        {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (Qu[r2 + (r1 * 8)] != ' ');

        K[i][0] = r1;
        K[i][1] = r2;
        K[i][2] = S9 * (get_random(50) + 50) / 100;
        update_quadrant_string(r1, r2, "+K+", 'K');
    }

    /* Place starbase */
    if (B3 > 0)
    {
        do
        {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (Qu[r2 + (r1 * 8)] != ' ');

        B4 = r1;
        B5 = r2;
        update_quadrant_string(r1, r2, ">!<", 'X');
    }

    /* Place stars */
    for (i = 0; i < S3; i++)
    {
        do
        {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (Qu[r2 + (r1 * 8)] != ' ');

        update_quadrant_string(r1, r2, " * ", '*');
    }
}

/* Update quadrant string */
void update_quadrant_string(int z1, int z2, char *symbol, char t)
{
    int pos;
    pos = z2 * 3 + z1 * 24;
    if (pos >= 0 && pos < 189)
    {
        Q[pos] = symbol[0];
        Q[pos + 1] = symbol[1];
        Q[pos + 2] = symbol[2];
    }
    Qu[z2 + (z1 * 8)] = t;
}

/* Get quadrant name (using global arrays) */
void get_quadrant_name(int z4, int z5)
{
    if (z5 < 4)
    {
        simple_strcpy(G2, star_names1[z4]);
    }
    else
    {
        simple_strcpy(G2, star_names2[z4]);
    }
    simple_strcat(G2, roman_numerals[z5 % 4]);
}

/* Main game loop */
void main_game_loop(void)
{
    char input[10];
    int i, cmd_found;

    while (1)
    {
        /* Check for docking */
        D0 = 0;
        if (B3 > 0)
        {
            if (abs_value(S1 - B4) <= 1 && abs_value(S2 - B5) <= 1)
            {
                D0 = 1;
                simple_strcpy(C_STR, "DOCKED\0");
                C_STR_COLOR = 12;
                E = E0;
                P = P0;
                printf("SHIELDS DROPPED FOR DOCKING PURPOSES\n\r");
                S = 0;
            }
        }

        /* Set condition */
        if (!D0)
        {
            if (K3 > 0)
            {
                simple_strcpy(C_STR, "*RED*\0");
                C_STR_COLOR = 9;
            }
            else if (E < E0 / 10)
            {
                simple_strcpy(C_STR, "YELLOW\0");
                C_STR_COLOR = 11;
            }
            else
            {
                simple_strcpy(C_STR, "GREEN\0");
                C_STR_COLOR = 10;
            }
        }

        /* Check for insufficient energy */
        if (S + E <= 10 && (E <= 10 || D[SHIELD_CONTROL] < 0))
        {
            printf("\n\r** FATAL ERROR **   YOU'VE JUST STRANDED YOUR SHIP IN SPACE\n\r");
            printf("YOU HAVE INSUFFICIENT MANEUVERING ENERGY, AND SHIELD CONTROL\n\r");
            printf("IS PRESENTLY INCAPABLE OF CROSS-CIRCUITING TO ENGINE ROOM!!\n\r");
            end_game();
            return;
        }

        /* Get command */
        printf("COMMAND? ");
        simple_gets(input, 10);

        /* Parse command */
        cmd_found = 0;
        for (i = 0; i < MAX_COMMANDS; i++)
        {
            if (simple_strncmp(input, &A1[i * 3], 3) == 0)
            {
                cmd_found = 1;
                switch (i)
                {
                case 0:
                    navigation();
                    break;
                case 1:
                    short_range_scan();
                    break;
                case 2:
                    long_range_scan();
                    break;
                case 3:
                    phaser_control();
                    break;
                case 4:
                    photon_torpedoes();
                    break;
                case 5:
                    shield_control();
                    break;
                case 6:
                    damage_report();
                    break;
                case 7:
                    library_computer();
                    break;
                case 8:
                    end_game();
                    return;
                }
                break;
            }
        }

        if (!cmd_found)
        {
            printf("ENTER ONE OF THE FOLLOWING:\n\r");
            printf("  NAV  (TO SET COURSE)\n\r");
            printf("  SRS  (FOR SHORT RANGE SENSOR SCAN)\n\r");
            printf("  LRS  (FOR LONG RANGE SENSOR SCAN)\n\r");
            printf("  PHA  (TO FIRE PHASERS)\n\r");
            printf("  TOR  (TO FIRE PHOTON TORPEDOES)\n\r");
            printf("  SHE  (TO RAISE OR LOWER SHIELDS)\n\r");
            printf("  DAM  (FOR DAMAGE CONTROL REPORTS)\n\r");
            printf("  COM  (TO CALL ON LIBRARY-COMPUTER)\n\r");
            printf("  XXX  (TO RESIGN YOUR COMMAND)\n\r\n\r");
        }

        /* Check for end conditions */
        if (K9 <= 0)
        {
            printf("CONGRATULATIONS, CAPTAIN! THE LAST KLINGON BATTLE CRUISER\n\r");
            printf("MENACING THE FEDERATION HAS BEEN DESTROYED.\n\r\n\r");
            printf("YOUR EFFICIENCY RATING IS %d\n\r", 1000 * K7 * K7 / ((T - T0) * (T - T0)));
            end_game();
            return;
        }

        if (T > T0 + T9)
        {
            printf("IT IS STARDATE %d\n\r", T);
            end_game();
            return;
        }
        paint_player_updates();
    }
}

/* Navigation */
void navigation(void)
{
    int c1, w1, n, i, tx, ty, collision, d;

    // get direction of travel

    printf("  4  3  2\n\r");
    printf("   \\ | /\n\r");
    printf("  5--*--1\n\r");
    printf("   / | \\ \n\r");
    printf("  6  7  8\n\r");
    printf("COURSE (1-8)? ");
    c1 = simple_scanf_int();
    printf("\n\r");
    if (c1 < 1 || c1 > 8)
    {
        printf("   LT. SULU REPORTS, 'INCORRECT COURSE DATA, SIR!'\n\r");
        return;
    }
    enterpriseDirection = c1 - 1;
    // get distance
    printf("WARP FACTOR (0-%s)? ", (D[WARP_ENGINES] < 0) ? "0" : "8");
    w1 = simple_scanf_int();
    printf("\n\r");
    if (w1 > 8)
    {
        printf("   CHIEF ENGINEER SCOTT REPORTS 'THE ENGINES WON'T TAKE WARP %d!'\n\r", w1);
        return;
    }
    // adjust for damage (limit speed)
    if (D[WARP_ENGINES] < 0 && w1 > 0)
    {
        printf("WARP ENGINES ARE DAMAGED. IMPULSE POWER ONLY\n\r");
        return;
    }

    // if insuffient available energy do not permit travel
    n = w1 * 80;
    if (n == 0)
        n = 1;
    if (E - n < 0)
    {
        printf("ENGINEERING REPORTS   'INSUFFICIENT ENERGY AVAILABLE\n\r");
        printf("                       FOR MANEUVERING AT WARP %d!'\n\r", w1);
        if (S < n - E || D[SHIELD_CONTROL] < 0)
            return;
        printf("DEFLECTOR CONTROL ROOM ACKNOWLEDGES %d UNITS OF ENERGY\n\r", S);
        printf("                         PRESENTLY DEPLOYED TO SHIELDS.\n\r");
        return;
    }

    // Move Enterprise

    if (w1 == 0)
    {
        // if at impulse
        tx = S1 + Dir[1][c1 - 1];
        ty = S2 + Dir[0][c1 - 1];

        if ((tx < 0) || (tx > SECTOR_SIZE) || (ty < 0) || (ty > SECTOR_SIZE) ||
            (Qu[ty + (tx * 8)] != ' '))
        {
            /* Exceeded sector limits or collision-- abort*/
            printf("IMPULSE ENGINES SHUT DOWN AT SECTOR %d,%d DUE TO BAD NAVIGATION\n\r", tx, ty);
        }
        else
        {
            // remove current location
            update_quadrant_string(S1, S2, "   ", ' ');
            S1 = tx;
            S2 = ty;
            update_quadrant_string(S1, S2, "<*>", 'E');
            E--;
            // good chance all of this should be in a main loop, and not only happen during navigation

            /* Move Klingons */
            for (i = 0; i < K3; i++)
            {
                d = get_random(9);
                if (d < 8)
                {
                    if (K[i][2] > 0)
                    {
                        tx = K[i][0] + Dir[d][1];
                        ty = K[i][1] + Dir[d][0];
                        if ((tx >= 0) && (ty >= 0) && (tx <= SECTOR_SIZE) && (ty <= SECTOR_SIZE))
                        {
                            if (Qu[ty + (tx * 8)] == ' ')
                            {
                                update_quadrant_string(K[i][0], K[i][1], "   ", ' ');
                                K[i][0] = tx;
                                K[i][1] = ty;
                                update_quadrant_string(K[i][0], K[i][1], "+K+", 'K');
                            }
                        }
                    }
                }
            }

            /* Klingon attack */
            klingon_attack();
            /* Repair damage */
            repair_damage();
            /* Update time */
            T += (w1 < 1) ? 1 : w1;
        }
    }
    else
    {
        // warp movement
        tx = S1;
        ty = S2;
        collision = 0;
        for (i = 0; i < 8; i++)
        {
            tx += Dir[1][c1 - 1];
            ty += Dir[0][c1 - 1];
            if ((tx < 0) || (tx > SECTOR_SIZE) || (ty < 0) || (ty > SECTOR_SIZE))
                break;
            if (Qu[ty + (tx * 8)] != ' ')
            {
                S1 = tx;
                S2 = ty;
                /*  collision-- abort*/
                printf("WARP ENGINES SHUT DOWN AT SECTOR %d,%d DUE TO BAD NAVIGATION\n\r", tx, ty);
                collision = 1;
            }
        }
        if (collision == 0)
        {
            Q1 += Dir[1][c1 - 1] * w1;
            Q2 += Dir[0][c1 - 1] * w1;
            E -= n;
            if ((Q1 < 0) || (Q1 > GALAXY_SIZE) || (Q2 < 0) || (Q2 > GALAXY_SIZE))
            {
                printf("LT. UHURA REPORTS MESSAGE FROM STARFLEET COMMAND:\n\r");
                printf("  'PERMISSION TO ATTEMPT CROSSING OF GALACTIC PERIMETER\n\r");
                printf("  IS HEREBY *DENIED*.  SHUT DOWN YOUR ENGINES.'\n\r");
                printf("CHIEF ENGINEER SCOTT REPORTS  'WARP ENGINES SHUT DOWN\n\r");
                if (Q1 < 0)
                    Q1 = 0;
                if (Q2 < 0)
                    Q2 = 0;
                if (Q1 >= GALAXY_SIZE)
                    Q1 = GALAXY_SIZE;
                if (Q2 >= GALAXY_SIZE)
                    Q2 = GALAXY_SIZE;
                printf("  AT SECTOR %d,%d OF QUADRANT %d,%d.' \n\r", S1, S2, Q1, Q2);
            }

            enter_quadrant();
            printf(" WELCOME TO QUADRANT %d,%d.' \n\r", Q1, Q2);
            /* Repair damage */
            repair_damage();
            /* Update time */
            T += (w1 < 1) ? 1 : w1;
        }
    }
}

/* Short range sensor scan */
void short_range_scan(void)
{
    int i, j;

    if (D[SHORT_SENSORS] < 0)
    {
        printf("\n\r*** SHORT RANGE SENSORS ARE OUT ***\n\r\n\r");
        return;
    }

    printf("---------------------------------\n\r");
    for (i = 0; i <= SECTOR_SIZE; i++)
    {
        for (j = 0; j <= SECTOR_SIZE; j++)
        {
            printf(" %s", get_quadrant_symbol(i, j));
        }

        /* Print status information */
        switch (i)
        {
        case 0:
            printf("        STARDATE          %d\n\r", T);
            break;
        case 1:
            printf("        CONDITION         %s\n\r", C_STR);
            break;
        case 2:
            printf("        QUADRANT          %d,%d\n\r", Q1, Q2);
            break;
        case 3:
            printf("        SECTOR            %d,%d\n\r", S1, S2);
            break;
        case 4:
            printf("        PHOTON TORPEDOES  %d\n\r", P);
            break;
        case 5:
            printf("        TOTAL ENERGY      %d\n\r", E + S);
            break;
        case 6:
            printf("        SHIELDS           %d\n\r", S);
            break;
        case 7:
            printf("        KLINGONS REMAINING %d\n\r", K9);
            break;
        }
    }
    printf("---------------------------------\n\r");
}

/* Get quadrant symbol */
char *get_quadrant_symbol(int z1, int z2)
{
    int pos;
    static char symbol[4];
    pos = z2 * 3 + z1 * 24;
    if (pos >= 0 && pos < 189)
    {
        symbol[0] = Q[pos];
        symbol[1] = Q[pos + 1];
        symbol[2] = Q[pos + 2];
        symbol[3] = '\0';
    }
    else
    {
        simple_strcpy(symbol, "   ");
    }
    return symbol;
}

/* Long range sensor scan */
void long_range_scan(void)
{
    int i, j;

    if (D[LONG_SENSORS] < 0)
    {
        printf("LONG RANGE SENSORS ARE INOPERABLE\n\r");
        return;
    }

    printf("LONG RANGE SCAN FOR QUADRANT %d,%d\n\r", Q1, Q2);
    printf("-------------------\n\r");

    for (i = Q1 - 1; i <= Q1 + 1; i++)
    {
        printf(": ");
        for (j = Q2 - 1; j <= Q2 + 1; j++)
        {
            if (i >= 0 && i <= GALAXY_SIZE && j >= 0 && j <= GALAXY_SIZE)
            {
                printf("%03d ", G[i][j]);
                Z[i][j] = G[i][j];
            }
            else
            {
                printf("*** ");
            }
        }
        printf(":\n\r");
    }
    printf("-------------------\n\r");
}

/* Phaser control */
void phaser_control(void)
{
    int x, h, i;
    int hit;
    if (D[PHASER_CONTROL] < 0)
    {
        printf("PHASERS INOPERATIVE\n\r");
        return;
    }

    if (K3 <= 0)
    {
        printf("SCIENCE OFFICER SPOCK REPORTS  'SENSORS SHOW NO ENEMY SHIPS\n\r");
        printf("                                IN THIS QUADRANT'\n\r");
        return;
    }

    if (D[LIBRARY_COMPUTER] < 0)
    {
        printf("COMPUTER FAILURE HAMPERS ACCURACY\n\r");
    }

    printf("PHASERS LOCKED ON TARGET;  ENERGY AVAILABLE = %d UNITS\n\r", E);
    printf("NUMBER OF UNITS TO FIRE? ");
    x = simple_scanf_int();

    if (x <= 0)
        return;
    if (E - x < 0)
    {
        printf("INSUFFICIENT ENERGY\n\r");
        return;
    }

    E -= x;
    if (D[SHIELD_CONTROL] < 0)
    {
        x = x * get_random(100) / 100;
    }

    h = x / K3;
    for (i = 0; i < K3; i++)
    {
        if (K[i][2] > 0)
        {
            hit = h / (calculate_distance(S1, S2, K[i][0], K[i][1]) + 1) * (get_random(3) + 2);
            if (hit > K[i][2] * 15 / 100)
            {
                K[i][2] -= hit;
                printf("%d UNIT HIT ON KLINGON AT SECTOR %d,%d\n\r", hit, K[i][0], K[i][1]);
                if (K[i][2] <= 0)
                {
                    printf("*** KLINGON DESTROYED ***\n\r");
                    K3--;
                    K9--;
                    update_quadrant_string(K[i][0], K[i][1], "   ", ' ');
                    K[i][2] = 0;
                    G[Q1][Q2] -= 100;
                    Z[Q1][Q2] = G[Q1][Q2];
                }
                else
                {
                    printf("   (SENSORS SHOW %d UNITS REMAINING)\n\r", K[i][2]);
                }
            }
            else
            {
                printf("SENSORS SHOW NO DAMAGE TO ENEMY AT %d,%d\n\r", K[i][0], K[i][1]);
            }
        }
    }

    klingon_attack();
}

/* Photon torpedoes */
void photon_torpedoes(void)
{
    int c1;
    int x1, x2, x, y;
    int x3, y3, i;
    char *symbol;

    if (P <= 0)
    {
        printf("ALL PHOTON TORPEDOES EXPENDED\n\r");
        return;
    }

    if (D[PHOTON_TUBES] < 0)
    {
        printf("PHOTON TUBES ARE NOT OPERATIONAL\n\r");
        return;
    }

    printf("PHOTON TORPEDO COURSE (1-9)? ");
    c1 = simple_scanf_int();
    if (c1 == 9)
        c1 = 1;

    if (c1 < 1 || c1 >= 9)
    {
        printf("ENSIGN CHEKOV REPORTS,  'INCORRECT COURSE DATA, SIR!'\n\r");
        return;
    }

    /* Simplified torpedo trajectory calculation */
    ///////  x1 = C[c1 - 1][0];
    /////////  x2 = C[c1 - 1][1];
    x = S1;
    y = S2;
    E -= 2;
    P--;

    printf("TORPEDO TRACK:\n\r");

    while (1)
    {
        x += x1;
        y += x2;
        x3 = x;
        y3 = y;

        if (x3 < 0 || x3 > SECTOR_SIZE || y3 < 0 || y3 > SECTOR_SIZE)
        {
            printf("TORPEDO MISSED\n\r");
            break;
        }

        printf("               %d,%d\n\r", x3, y3);

        /* Check for hit */
        if (get_quadrant_symbol(x3, y3)[1] != ' ')
        {
            symbol = get_quadrant_symbol(x3, y3);

            if (symbol[0] == '+')
            {
                /* Hit Klingon */
                printf("*** KLINGON DESTROYED ***\n\r");
                K3--;
                K9--;
                for (i = 0; i < MAX_KLINGONS; i++)
                {
                    if (K[i][0] == x3 && K[i][1] == y3)
                    {
                        K[i][2] = 0;
                        break;
                    }
                }
                update_quadrant_string(x3, y3, "   ", ' ');
                G[Q1][Q2] -= 100;
                Z[Q1][Q2] = G[Q1][Q2];
                break;
            }
            else if (symbol[0] == '*')
            {
                /* Hit star */
                printf("STAR AT %d,%d ABSORBED TORPEDO ENERGY.\n\r", x3, y3);
                break;
            }
            else if (symbol[0] == '>')
            {
                /* Hit starbase */
                printf("*** STARBASE DESTROYED ***\n\r");
                B3--;
                B9--;
                update_quadrant_string(x3, y3, "   ", ' ');
                G[Q1][Q2] -= 10;
                Z[Q1][Q2] = G[Q1][Q2];
                if (B9 <= 0 && K9 > T - T0 - T9)
                {
                    printf("THAT DOES IT, CAPTAIN!! YOU ARE HEREBY RELIEVED OF COMMAND\n\r");
                    printf("AND SENTENCED TO 99 STARDATES AT HARD LABOR ON CYGNUS 12!!\n\r");
                    end_game();
                    return;
                }
                printf("STARFLEET COMMAND REVIEWING YOUR RECORD TO CONSIDER COURT MARTIAL!\n\r");
                break;
            }
        }
    }

    klingon_attack();
}

/* Shield control */
void shield_control(void)
{
    int x;

    if (D[SHIELD_CONTROL] < 0)
    {
        printf("SHIELD CONTROL INOPERABLE\n\r");
        return;
    }

    printf("ENERGY AVAILABLE = %d  NUMBER OF UNITS TO SHIELDS? ", E + S);
    x = simple_scanf_int();

    if (x < 0 || S == x)
    {
        printf("<SHIELDS UNCHANGED>\n\r");
        return;
    }

    if (x > E + S)
    {
        printf("SHIELD CONTROL REPORTS  'THIS IS NOT THE FEDERATION TREASURY.'\n\r");
        printf("<SHIELDS UNCHANGED>\n\r");
        return;
    }

    E = E + S - x;
    S = x;
    printf("DEFLECTOR CONTROL ROOM REPORT:\n\r");
    printf("  'SHIELDS NOW AT %d UNITS PER YOUR COMMAND.'\n\r", S);
}

/* Damage report (using global device_names array) */
void damage_report(void)
{
    int i;

    printf("\n\rDEVICE             STATE OF REPAIR\n\r");
    for (i = 0; i < MAX_DEVICES; i++)
    {
        printf("%s %d\n\r", device_names[i], D[i]);
    }
    printf("\n\r");
}

/* Library computer */
void library_computer(void)
{
    int a, i, j;

    if (D[LIBRARY_COMPUTER] < 0)
    {
        printf("COMPUTER DISABLED\n\r");
        return;
    }

    printf("COMPUTER ACTIVE AND AWAITING COMMAND? ");
    a = simple_scanf_int();

    if (a < 0)
        return;

    switch (a)
    {
    case 0:
        /* Cumulative galactic record */
        printf("        COMPUTER RECORD OF GALAXY FOR QUADRANT %d,%d\n\r", Q1, Q2);
        printf("       1     2     3     4     5     6     7     8\n\r");
        printf("     ----- ----- ----- ----- ----- ----- ----- -----\n\r");
        for (i = 0; i <= GALAXY_SIZE; i++)
        {
            printf("%d", i + 1);
            for (j = 0; j <= GALAXY_SIZE; j++)
            {
                if (Z[i][j] == 0)
                {
                    printf("   ***");
                }
                else
                {
                    printf("   %03d", Z[i][j]);
                }
            }
            printf("\n\r");
        }
        break;
    case 1:
        /* Status report */
        printf("   STATUS REPORT:\n\r");
        printf("KLINGONS LEFT: %d\n\r", K9);
        printf("MISSION MUST BE COMPLETED IN %d STARDATES\n\r", T0 + T9 - T);
        if (B9 > 0)
        {
            printf("THE FEDERATION IS MAINTAINING %d STARBASE", B9);
            if (B9 > 1)
                printf("S");
            printf(" IN THE GALAXY\n\r");
        }
        else
        {
            printf("YOUR STUPIDITY HAS LEFT YOU ON YOUR OWN IN\n\r");
            printf("  THE GALAXY -- YOU HAVE NO STARBASES LEFT!\n\r");
        }
        damage_report();
        break;
    default:
        printf("FUNCTIONS AVAILABLE FROM LIBRARY-COMPUTER:\n\r");
        printf("   0 = CUMULATIVE GALACTIC RECORD\n\r");
        printf("   1 = STATUS REPORT\n\r");
        break;
    }
}

/* Klingon attack */
void klingon_attack(void)
{
    int i, h;
    int r1;

    if (K3 <= 0)
        return;
    if (D0 != 0)
    {
        printf("STARBASE SHIELDS PROTECT THE ENTERPRISE\n\r");
        return;
    }

    for (i = 0; i < K3; i++)
    {
        if (K[i][2] > 0)
        {
            h = (K[i][2] / calculate_distance(S1, S2, K[i][0], K[i][1])) * (get_random(3) + 2);
            S -= h;
            K[i][2] = K[i][2] / (3 + get_random(3));
            printf("%d UNIT HIT ON ENTERPRISE FROM SECTOR %d,%d\n\r", h, K[i][0], K[i][1]);
            if (S <= 0)
            {
                printf("\n\rTHE ENTERPRISE HAS BEEN DESTROYED. THE FEDERATION WILL BE CONQUERED\n\r");
                end_game();
                return;
            }
            printf("      <SHIELDS DOWN TO %d UNITS>\n\r", S);
            if (h >= 20 && (get_random(10) > 6 || h * 100 / S > 2))
            {
                r1 = get_random(MAX_DEVICES);
                D[r1] = D[r1] - h / S - get_random(5);
                printf("DAMAGE CONTROL REPORTS '%s DAMAGED BY THE HIT'\n\r", device_names[r1]);
            }
        }
    }
}

/* Calculate distance (simplified as distance squared) */
int calculate_distance(int x1, int y1, int x2, int y2)
{
    int dx;
    int dy;

    dx = x2 - x1;
    dy = y2 - y1;

    return dx * dx + dy * dy; /* Distance squared for comparison */
}

/* Repair damage */
void repair_damage(void)
{
    int i, d1;
    d1 = 0;
    for (i = 0; i < MAX_DEVICES; i++)
    {
        if (D[i] < 0)
        {
            D[i] += 1;
            if (D[i] > -1 && D[i] < 0)
            {
                D[i] = -1;
            }
            else if (D[i] >= 0)
            {
                if (d1 == 0)
                {
                    d1 = 1;
                    printf("DAMAGE CONTROL REPORT:  ");
                }
                printf("%s REPAIR COMPLETED.\n\r", device_names[i]);
            }
        }
    }
}

/* End game (fixed to use restart flag instead of recursive main() call) */
void end_game(void)
{
    char response[10]; /* Variable declared at top for Micro-C compatibility */

    printf("THERE WERE %d KLINGON BATTLE CRUISERS LEFT AT\n\r", K9);
    printf("THE END OF YOUR MISSION.\n\r\n\r");

    if (B9 > 0)
    {
        printf("THE FEDERATION IS IN NEED OF A NEW STARSHIP COMMANDER\n\r");
        printf("FOR A SIMILAR MISSION -- IF THERE IS A VOLUNTEER,\n\r");
        printf("LET HIM STEP FORWARD AND ENTER 'AYE': ");
        simple_gets(response, 10);
        if (simple_strcmp(response, "AYE") == 0)
        {
            restart_game = 1; /* Set restart flag instead of calling main() */
            return;
        }
    }
    printf("\n\r\r");
    _exit();
}

/* Main function with game restart loop */
int main(void)
{
    do
    {
        paint_intro_screen();
        paint_player_screen();
        /* Initialize game */
        initialize_game();
        paint_player_updates();
        /* Print instructions */
        print_instructions();

        /* Enter starting quadrant */
        enter_quadrant();

        /* Start game loop */
        main_game_loop();

    } while (restart_game);

    _exit();
    _start();
}