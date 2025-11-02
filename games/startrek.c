/*
 * STAR TREK - C Version
 * Originally Converted from BASIC version dated MAY 16, 1978
 *
 * Original BASIC program by Mike Mayfield, modified by Dave Ahl
 * Further modifications by Bob Leedom
 * Converted to Microsoft 8K BASIC by John Gorders
 *
 * Arcade conversion by Dan Werner
 *
 */

// todo:
//       Message Window
//       Remove Printfs
//       3d (ok, 2d arcade playing)
//             visualizations
//             arcade-ish play style?
//       Improved Graphics
//             3d view models
//             explosions
//             smoother motion and animation
//             remove flickering
//       Sound effects
//       opening screen (w/music)
//       Speech?

//       glyphs and graphics (three views, facing, 45 deg, rear and then mirror)


#include "../gcclib/stdio.h"
#include "../gcclib/graphics.h"

#include "trekconstants.h"
#include "trekassets.h"
#include "startrek.h"



int get_random(int max)
{
    lfsr = lfsr + randseed();
    bit = ((lfsr >> 0) ^ (lfsr >> 2) ^ (lfsr >> 3) ^ (lfsr >> 5)) & 1;
    lfsr = (lfsr >> 1) | (bit << 15);

    return (lfsr % max);
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
    int i;

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

    OutString(10, 420, 6, 0, 7, "DEVICE");
    OutString(10, 520, 6, 0, 7, "HEALTH");
    for (i = 0; i < MAX_DEVICES; i++)
        OutString(420, 25 + (15 * i), 6, 0, 7, device_names[i]);

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
    DrawFilledRectangle(210, 5, 410, 170);
    DrawFilledRectangle(3, 203, 400, 470);

    if (D[SHORT_SENSORS] < 0)
    {
        printf("\n\r*** SHORT RANGE SENSORS ARE OUT ***\n\r\n\r");
    }
    else
    {
        SetPenColor(5);
        sprintf(buf, "%d", T);
        OutString(135, 10, 8, 0, 25, buf);
        sprintf(buf, "%d,%d", Q1, Q2);
        OutString(135, 40, 8, 0, 25, buf);
        sprintf(buf, "%d,%d", S1, S2);
        OutString(135, 55, 8, 0, 25, buf);
        sprintf(buf, "%d", P);
        OutString(135, 70, 8, 0, 25, buf);
        sprintf(buf, "%d", E);
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
                    // add shield graphic if shields are up. (make it fit better)
                    SetPenColor(2);
                    if (S > 0)
                        DrawEllipse((j * 20) + 229, (i * 20) + 19, 30, 20);
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
    }
    // Draw Viewer
    // 100% view
    j = S2 + Dir[0][enterpriseDirection];
    i = S1 + Dir[1][enterpriseDirection];

    if (Qu[j + (i * 8)] == '*')
    {
        SetPenColor(3);
        SetGlyphOptions(0, 1, 1, 0, 0, 0, 0);
        DrawGlyph(300, 270, 8, 9, 0, 9, starGlyph);
        SetGlyphOptions(0, 0, 0, 0, 0, 0, 0);
    }
    if (Qu[j + (i * 8)] == 'K')
    {
        SetPenColor(9);
        SetGlyphOptions(0, 1, 1, 0, 0, 0, 0);
        DrawGlyph(300, 270, klingonGlyphSizeX[Dir[2][5]], klingonGlyphSizeY[Dir[2][5]], 0, klingonGlyphSize[Dir[2][5]], klingonGlyph[5]);
        SetGlyphOptions(0, 0, 0, 0, 0, 0, 0);
    }
    if (Qu[j + (i * 8)] == 'X')
    {
        SetPenColor(12);
        SetGlyphOptions(0, 1, 1, 0, 0, 0, 0);
        DrawGlyph(300, 270, 24, 20, 0, 60, baseGlyph);
        SetGlyphOptions(0, 0, 0, 0, 0, 0, 0);
    }

    damage_report();
}

/* Initialize game */
void initialize_game(void)
{
    int i, j, k3, b3, s3;

    /* Set up time and energy */
    T = (get_random(20) + 20) * 100;
    T0 = T;
    T9 = get_random(30) + 155;
    E = 3000;
    P = 10;
    S = 0;
    B9 = 0;
    K9 = 0;
    D0 = 0;
    enterpriseDirection = 0;
    /* Initialize damage array */
    for (i = 0; i < MAX_DEVICES; i++)
    {
        D[i] = 100;
    }

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

    /* Initialize quadrant */
    for (i = 0; i < 65; i++)
    {
        Qu[i] = ' ';
    }
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
    Qu[S2 + (S1 * 8)] = 'E';
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
        K[i][2] = 200 * (get_random(50) + 50) / 100;
        Qu[r2 + (r1 * 8)] = 'K';
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
        Qu[r2 + (r1 * 8)] = 'X';
    }

    /* Place stars */
    for (i = 0; i < S3; i++)
    {
        do
        {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (Qu[r2 + (r1 * 8)] != ' ');

        Qu[r2 + (r1 * 8)] = '*';
    }
}

/* Get quadrant name (using global arrays) */
void get_quadrant_name(int z4, int z5)
{
    if (z5 < 4)
    {
        strcpy(G2, star_names1[z4]);
    }
    else
    {
        strcpy(G2, star_names2[z4]);
    }
    strcat(G2, roman_numerals[z5 % 4]);
}

/* Main game loop */
void main_game_loop(void)
{
    char keypress;

    while (1)
    {
        paint_player_updates();
        while (1)
        {
            keypress = getc();
            if (keypress == 'a')
            {
                enterpriseDirection++;
                if (enterpriseDirection > 7)
                    enterpriseDirection = 0;
                paint_player_updates();
            }
            if (keypress == 'd')
            {
                if (enterpriseDirection > 0)
                {
                    enterpriseDirection--;
                }
                else
                {
                    enterpriseDirection = 7;
                }
                paint_player_updates();
            }
            if (keypress == 's')
            {
                if (E > 0)
                {
                    impulsePower();
                    paint_player_updates();
                }
            }
            if (keypress == 'w')
            {
                if ((E > 8) && (D[WARP_ENGINES] >= 0))
                {
                    warpSpeed(1);
                    paint_player_updates();
                }
            }
            if (keypress == 't')
            {
                photon_torpedoes();
                paint_player_updates();
            }
            if (keypress == '>')
            {
                if (D[SHIELD_CONTROL] > 0)
                {
                    if (E > 100)
                    {
                        S += 100;
                        E -= 100;
                    }
                    paint_player_updates();
                }
            }
            if (keypress == '<')
            {
                if (D[SHIELD_CONTROL] > 0)
                {
                    if (S > 100)
                    {
                        S -= 100;
                        E += 100;
                    }
                    paint_player_updates();
                }
            }
            if (keypress == 'l')
            {
                long_range_scan();
                paint_player_updates();
            }

            if (keypress == 'x')
            {
                end_game();
                return;
            }

            if (keypress == ' ')
            {
                phaser_control();
                paint_player_updates();
            }
            if (keypress == 'c')
            {
                library_computer();
                paint_player_updates();
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
        }
    }
}

void CheckDocked(void)
{
    /* Check for docking */
    D0 = 0;
    if (B3 > 0)
    {
        if (abs_value(S1 - B4) <= 1 && abs_value(S2 - B5) <= 1)
        {
            D0 = 1;
            strcpy(C_STR, "DOCKED\0");
            C_STR_COLOR = 12;
            E = 3000;
            P = 10;
            printf("SHIELDS DROPPED FOR DOCKING PURPOSES\n\r");
            S = 0;
        }
    }

    /* Set condition */
    if (!D0)
    {
        if (K3 > 0)
        {
            strcpy(C_STR, "*RED*\0");
            C_STR_COLOR = 9;
        }
        else if (E < 300)
        {
            strcpy(C_STR, "YELLOW\0");
            C_STR_COLOR = 11;
        }
        else
        {
            strcpy(C_STR, "GREEN\0");
            C_STR_COLOR = 10;
        }
    }
}

void impulsePower(void)
{
    int tx, ty;
    int i, d;

    tx = S1 + Dir[1][enterpriseDirection];
    ty = S2 + Dir[0][enterpriseDirection];

    if ((tx < 0) || (tx > SECTOR_SIZE) || (ty < 0) || (ty > SECTOR_SIZE) ||
        (Qu[ty + (tx * 8)] != ' '))
    {
        /* Exceeded sector limits or collision-- abort*/
        printf("IMPULSE ENGINES SHUT DOWN AT SECTOR %d,%d DUE TO BAD NAVIGATION\n\r", tx, ty);
    }
    else
    {
        // remove current location
        Qu[S2 + (S1 * 8)] = ' ';
        S1 = tx;
        S2 = ty;
        Qu[S2 + (S1 * 8)] = 'E';
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
                            Qu[K[i][1] + (K[i][0] * 8)] = ' ';
                            K[i][0] = tx;
                            K[i][1] = ty;
                            Qu[K[i][1] + (K[i][0] * 8)] = 'K';
                        }
                    }
                }
            }
        }

        /* Klingon attack */
        CheckDocked();
        /* Klingon attack */
        klingon_attack();
        /* Repair damage */
        repair_damage();
        /* Update time */
        T++;
    }
}

void warpSpeed(int WarpFactor)
{
    int tx, ty, i, collision, d;

    tx = S1;
    ty = S2;
    collision = 0;
    for (i = 0; i < 8; i++)
    {
        Qu[ty + (tx * 8)] = ' ';
        tx += Dir[1][enterpriseDirection];
        ty += Dir[0][enterpriseDirection];
        if ((tx < 0) || (tx > SECTOR_SIZE) || (ty < 0) || (ty > SECTOR_SIZE))
            break;
        if (Qu[ty + (tx * 8)] != ' ')
        {
            tx -= Dir[1][enterpriseDirection];
            ty -= Dir[0][enterpriseDirection];
            S1 = tx;
            S2 = ty;
            /*  collision-- abort*/
            printf("WARP ENGINES SHUT DOWN AT SECTOR %d,%d DUE TO BAD NAVIGATION\n\r", tx, ty);
            collision = 1;
            Qu[ty + (tx * 8)] = 'E';
            paint_player_updates();
            break;
        }
        Qu[ty + (tx * 8)] = 'E';
        paint_player_updates();
    }

    if (collision == 0)
    {
        Q1 += Dir[1][enterpriseDirection] * WarpFactor;
        Q2 += Dir[0][enterpriseDirection] * WarpFactor;
        E -= (WarpFactor * 80);
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
        T += WarpFactor;
    }
}

/* Long range sensor scan */
void long_range_scan(void)
{
    int i, j;
    int x = 0, y = 0;
    char buffer[10];

    if (D[LONG_SENSORS] < 0)
    {
        printf("LONG RANGE SENSORS ARE INOPERABLE\n\r");
        return;
    }

    SetPenColor(15);
    OutString(35, 210, 6, 0, 7, "LONG RANGE SCAN FOR QUADRANT");

    for (i = Q1 - 1; i <= Q1 + 1; i++)
    {
        DrawLine(65, (y * 15) + 233, 170, (y * 15) + 233);
        for (j = Q2 - 1; j <= Q2 + 1; j++)
        {
            if (i >= 0 && i <= GALAXY_SIZE && j >= 0 && j <= GALAXY_SIZE)
            {
                sprintf(buffer, "%03d", G[i][j]);
                if ((x == 1) && (y == 1))
                    SetPenColor(11);
                OutString(70 + (x * 40), 235 + (y * 15), 6, 0, 7, buffer);
                SetPenColor(15);
                Z[i][j] = G[i][j];
            }
            else
            {
                OutString(70 + (x * 40), 235 + (y * 15), 6, 0, 7, "***");
            }
            x++;
        }
        y++;
        x = 0;
    }
    DrawLine(65, 233, 65, 278);
    DrawLine(100, 233, 100, 278);
    DrawLine(135, 233, 135, 278);
    DrawLine(170, 233, 170, 278);
    DrawLine(65, 278, 170, 278);
    getch();
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
    x = 100;

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
                    Qu[K[i][1] + (K[i][0] * 8)] = ' ';
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
    ////////// this needs to animate the torpedo launch on both screens (tactical and viewer)
    int x1, x2, x, y;
    int x3, y3, i;
    char symbol;

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

    x1 = Dir[1][enterpriseDirection];
    x2 = Dir[0][enterpriseDirection];
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
        if (Qu[y3 + (x3 * 8)] != ' ')
        {
            symbol = Qu[y3 + (x3 * 8)];

            if (symbol == 'K')
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
                Qu[y3 + (x3 * 8)] = ' ';
                G[Q1][Q2] -= 100;
                Z[Q1][Q2] = G[Q1][Q2];
                break;
            }
            else if (symbol == '*')
            {
                /* Hit star */
                printf("STAR AT %d,%d ABSORBED TORPEDO ENERGY.\n\r", x3, y3);
                break;
            }
            else if (symbol == 'X')
            {
                /* Hit starbase */
                printf("*** STARBASE DESTROYED ***\n\r");
                B3--;
                B9--;
                Qu[y3 + (x3 * 8)] = ' ';
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

/* Damage report (using global device_names array) */
void damage_report(void)
{
    int i;
    char out[10];
    SetPenColor(0);
    DrawFilledRectangle(560, 10, 630, 150);

    if (D[DAMAGE_CONTROL] < 0)
        return;

    SetPenColor(6);
    for (i = 0; i < MAX_DEVICES; i++)
    {
        sprintf(out, "%d%%", D[i]);
        if (D[i] > 60)
            SetPenColor(10);
        else if (D[i] > 25)
            SetPenColor(11);
        else
            SetPenColor(9);
        OutString(560, 25 + (15 * i), 6, 0, 7, out);
    }
}

/* Library computer */
void library_computer(void)
{
    int i, j;
    char buffer[20];

    if (D[LIBRARY_COMPUTER] < 0)
    {
        printf("COMPUTER DISABLED\n\r");
        return;
    }

    /* Cumulative galactic record */
    SetPenColor(15);
    OutString(70, 210, 6, 0, 7, "COMPUTER RECORD OF GALAXY");

    for (i = -1; i <= GALAXY_SIZE; i++)
    {

        if (i != -1)
        {
            sprintf(buffer, "%d", i + 1);
            OutString(15, 240 + (i * 15), 6, 0, 7, buffer);
        }

        for (j = 0; j <= GALAXY_SIZE; j++)
        {
            if (i == -1)
            {
                sprintf(buffer, "%d", j + 1);
                OutString(36 + (30 * j), 225, 6, 0, 7, buffer);
            }
            else
            {
                if (Z[i][j] == 0)
                {
                    OutString(30 + (30 * j), 240 + (i * 15), 6, 0, 7, "***");
                }
                else
                {
                    sprintf(buffer, "%03d", Z[i][j]);
                    OutString(30 + (30 * j), 240 + (i * 15), 6, 0, 7, buffer);
                }
            }
        }
    }
    getch();
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
                D[r1] = D[r1] - h / S - get_random(15);
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
    // todo: this should be time based, not based  on moves
    int i, d1;
    d1 = 0;
    char buffer[60];
    if (K3 == 0)
    {
        for (i = 0; i < MAX_DEVICES; i++)
        {
            if (D[i] < 100)
            {
                D[i] += 1;
                if (D[i] > 100)
                {
                    D[i] = 100;
                }
                if (D[i] == 100)
                {
                    SetPenColor(0);
                    DrawRectangle(420, 180, 639, 199);
                    SetPenColor(11);
                    sprintf(buffer, "%s REPAIR COMPLETE", device_names[i]);
                    OutString(420, 185, 6, 0, 7, buffer);
                }
            }
        }
    }
}

/* End game (fixed to use restart flag instead of recursive main() call) */
void end_game(void)
{
    // need an explosion

    printf("THERE WERE %d KLINGON BATTLE CRUISERS LEFT AT\n\r", K9);
    printf("THE END OF YOUR MISSION.\n\r\n\r");

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

        /* Enter starting quadrant */
        enter_quadrant();

        /* Start game loop */
        main_game_loop();

    } while (restart_game);

    _exit();
    _start();
}