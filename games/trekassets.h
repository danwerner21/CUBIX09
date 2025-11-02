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
