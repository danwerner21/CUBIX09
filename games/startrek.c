/*
 * SUPER STAR TREK - C Version (Micro-C Compatible)
 * Converted from BASIC version dated MAY 16, 1978
 *
 * Original BASIC program by Mike Mayfield, modified by Dave Ahl
 * Further modifications by Bob Leedom
 * Converted to Microsoft 8K BASIC by John Gorders
 * Converted to Micro-C by AI Assistant
 * Fixed for Micro-C compatibility
 */

/* Minimal includes - only what's available in Micro-C */

/* Game constants */
#define GALAXY_SIZE 8
#define SECTOR_SIZE 8
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

/* Global string arrays (moved from local functions for Micro-C compatibility) */
static char *star_names1[] = {"ANTARES", "RIGEL", "PROCYON", "VEGA",
                              "CANOPUS", "ALTAIR", "SAGITTARIUS", "POLLUX"};
static char *star_names2[] = {"SIRIUS", "DENEB", "CAPELLA", "BETELGEUSE",
                              "ALDEBARAN", "REGULUS", "ARCTURUS", "SPICA"};
static char *roman_numerals[] = {" I", " II", " III", " IV"};
static char *device_names[] = {
    "WARP ENGINES", "SHORT RANGE SENSORS", "LONG RANGE SENSORS",
    "PHASER CONTROL", "PHOTON TUBES", "DAMAGE CONTROL",
    "SHIELD CONTROL", "LIBRARY-COMPUTER"
};

/* Global game state */
int G[GALAXY_SIZE][GALAXY_SIZE];    /* Galaxy map */
int K[MAX_KLINGONS][3];             /* Klingon positions and energy */
int C[9][2];                        /* Direction vectors */
int Z[GALAXY_SIZE][GALAXY_SIZE];    /* Cumulative galactic record */
int D[MAX_DEVICES];                 /* Damage array */
int N[3];                           /* Temporary array */

/* Game variables */
int T, T0, T9;                      /* Time variables */
int E, E0;                          /* Energy */
int P, P0;                          /* Photon torpedoes */
int S, S9;                          /* Shield energy */
int B9, K9, K7;                     /* Starbases, Klingons */
int Q1, Q2, S1, S2;                 /* Quadrant and sector positions */
int K3, B3, S3;                     /* Quadrant contents */
int B4, B5;                         /* Starbase position */
int D0, D4;                         /* Docked flag, damage repair time */
char Q[193];                        /* Quadrant string */
char A1[28];                        /* Command string */
char G2[20];                        /* Region name */
char C_STR[10];                     /* Condition string */

/* Game restart flag (replaces recursive main() call) */
int restart_game = 0;

/* Function prototypes */
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
void update_quadrant_string(int z1, int z2, char *symbol);
char *get_quadrant_symbol(int z1, int z2);
void repair_damage(void);
void maneuver_energy(int energy_used);
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
void simple_putchar(char c);
char simple_getchar(void);

/* Random number seed */
static unsigned int random_seed = 1;

/* Simple absolute value function */
int abs_value(int x) {
    return (x < 0) ? -x : x;
}

/* Simple random number generator (using smaller constants for 16-bit) */
int get_random(int max) {
    random_seed = (random_seed * 1103 + 12345) & 0x7fff;
    return (random_seed % max);
}

/* Simple string functions to replace standard library */
int simple_strlen(char *str) {
    int len = 0;
    while (str[len] != '\0') len++;
    return len;
}

void simple_strcpy(char *dest, char *src) {
    int i = 0;
    while (src[i] != '\0') {
        dest[i] = src[i];
        i++;
    }
    dest[i] = '\0';
}

void simple_strcat(char *dest, char *src) {
    int dest_len = simple_strlen(dest);
    int i = 0;
    while (src[i] != '\0') {
        dest[dest_len + i] = src[i];
        i++;
    }
    dest[dest_len + i] = '\0';
}

int simple_strcmp(char *str1, char *str2) {
    int i = 0;
    while (str1[i] != '\0' && str2[i] != '\0') {
        if (str1[i] != str2[i]) {
            return str1[i] - str2[i];
        }
        i++;
    }
    return str1[i] - str2[i];
}

int simple_strncmp(char *str1, char *str2, int n) {
    int i;
    for (i = 0; i < n && str1[i] != '\0' && str2[i] != '\0'; i++) {
        if (str1[i] != str2[i]) {
            return str1[i] - str2[i];
        }
    }
    if (i == n) return 0;
    return str1[i] - str2[i];
}

/* Simple input functions */
char simple_getchar(void) {
    /* This would need to be implemented based on the target system */
    /* For now, assuming basic character input is available */
    return getchar();  /* Assuming minimal getchar() is available */
}

void simple_putchar(char c) {
    /* This would need to be implemented based on the target system */
    putchar(c);  /* Assuming minimal putchar() is available */
}

int simple_scanf_int(void) {
    char buffer[10];
    int i = 0;
    int result = 0;
    int negative = 0;
    char c;

    /* Skip whitespace */
    do {
        c = simple_getchar();
    } while (c == ' ' || c == '\t' || c == '\n');

    /* Check for negative */
    if (c == '-') {
        negative = 1;
        c = simple_getchar();
    }

    /* Read digits */
    while (c >= '0' && c <= '9' && i < 9) {
        buffer[i++] = c;
        c = simple_getchar();
    }
    buffer[i] = '\0';

    /* Convert to integer */
    for (i = 0; buffer[i] != '\0'; i++) {
        result = result * 10 + (buffer[i] - '0');
    }

    return negative ? -result : result;
}

void simple_gets(char *buffer, int max_len) {
    int i = 0;
    char c;

    while (i < max_len - 1) {
        c = simple_getchar();
        if (c == '\n' || c == '\r') break;
        buffer[i++] = c;
    }
    buffer[i] = '\0';
}

/* Initialize game */
void initialize_game(void) {
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

    /* Initialize direction vectors */
    C[0][0] = 0; C[0][1] = 1;    /* N */
    C[1][0] = -1; C[1][1] = 1;   /* NE */
    C[2][0] = -1; C[2][1] = 0;   /* E */
    C[3][0] = -1; C[3][1] = -1;  /* SE */
    C[4][0] = 0; C[4][1] = -1;   /* S */
    C[5][0] = 1; C[5][1] = -1;   /* SW */
    C[6][0] = 1; C[6][1] = 0;    /* W */
    C[7][0] = 1; C[7][1] = 1;    /* NW */
    C[8][0] = 0; C[8][1] = 1;    /* N (wrap) */

    /* Initialize damage array */
    for (i = 0; i < MAX_DEVICES; i++) {
        D[i] = 0;
    }

    /* Set up command string */
    simple_strcpy(A1, "NAVSRSLRSPHATORSHEDAMCOMXXX");

    /* Set up galaxy */
    for (i = 0; i < GALAXY_SIZE; i++) {
        for (j = 0; j < GALAXY_SIZE; j++) {
            k3 = 0;
            b3 = 0;
            s3 = get_random(8) + 1;

            /* Place Klingons */
            if (get_random(100) > 98) {
                k3 = 3;
                K9 += 3;
            } else if (get_random(100) > 95) {
                k3 = 2;
                K9 += 2;
            } else if (get_random(100) > 80) {
                k3 = 1;
                K9 += 1;
            }

            /* Place starbases */
            if (get_random(100) > 96) {
                b3 = 1;
                B9 += 1;
            }

            G[i][j] = k3 * 100 + b3 * 10 + s3;
            Z[i][j] = 0;
        }
    }

    /* Ensure at least one starbase */
    if (B9 == 0) {
        i = get_random(GALAXY_SIZE);
        j = get_random(GALAXY_SIZE);
        if (G[i][j] < 200) {
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
    if (K9 > T9) T9 = K9 + 1;

    /* Initialize quadrant string */
    for (i = 0; i < 192; i++) {
        Q[i] = ' ';
    }
    Q[192] = '\0';
}

/* Print game instructions */
void print_instructions(void) {
    printf("\n\n\n\n\n\n\n\n\n\n\n");
    printf("                                    ,------*------,\n");
    printf("                    ,-------------   '---  ------'\n");
    printf("                     '-------- --'      / /\n");
    printf("                         ,---' '-------/ /--,\n");
    printf("                          '----------------'\n\n");
    printf("                    THE USS ENTERPRISE --- NCC-1701\n");
    printf("\n\n\n\n\n");

    printf("YOUR ORDERS ARE AS FOLLOWS:\n");
    printf("     DESTROY THE %d KLINGON WARSHIPS WHICH HAVE INVADED\n", K9);
    printf("   THE GALAXY BEFORE THEY CAN ATTACK FEDERATION HEADQUARTERS\n");
    printf("   ON STARDATE %d. THIS GIVES YOU %d DAYS. THERE", T0 + T9, T9);
    if (B9 == 1) {
        printf(" IS\n  1 STARBASE IN THE GALAXY FOR RESUPPLYING YOUR SHIP\n");
    } else {
        printf(" ARE\n  %d STARBASES IN THE GALAXY FOR RESUPPLYING YOUR SHIP\n", B9);
    }
    printf("\n");
}

/* Enter new quadrant */
void enter_quadrant(void) {
    int i;

    /* Check quadrant bounds */
    if (Q1 < 0 || Q1 >= GALAXY_SIZE || Q2 < 0 || Q2 >= GALAXY_SIZE) {
        return;
    }

    /* Get quadrant info */
    K3 = G[Q1][Q2] / 100;
    B3 = (G[Q1][Q2] % 100) / 10;
    S3 = G[Q1][Q2] % 10;

    /* Clear quadrant */
    for (i = 0; i < 192; i++) {
        Q[i] = ' ';
    }

    /* Clear Klingon array */
    for (i = 0; i < MAX_KLINGONS; i++) {
        K[i][0] = 0;
        K[i][1] = 0;
        K[i][2] = 0;
    }

    /* Get quadrant name and print entry message */
    get_quadrant_name(Q1, Q2);
    if (T0 == T) {
        printf("YOUR MISSION BEGINS WITH YOUR STARSHIP LOCATED\n");
        printf("IN THE GALACTIC QUADRANT, '%s'.\n", G2);
    } else {
        printf("NOW ENTERING %s QUADRANT . . .\n", G2);
    }

    /* Check for combat */
    if (K3 > 0) {
        printf("COMBAT AREA      CONDITION RED\n");
        if (S <= 200) {
            printf("   SHIELDS DANGEROUSLY LOW\n");
        }
    }

    /* Place Enterprise */
    place_enterprise();

    /* Place objects */
    place_objects();

    /* Update cumulative record */
    Z[Q1][Q2] = G[Q1][Q2];
}

/* Place Enterprise in quadrant */
void place_enterprise(void) {
    update_quadrant_string(S1, S2, "<*>");
}

/* Place Klingons, starbases, and stars */
void place_objects(void) {
    int i, r1, r2;

    /* Place Klingons */
    for (i = 0; i < K3; i++) {
        do {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (r1 == S1 && r2 == S2);

        K[i][0] = r1;
        K[i][1] = r2;
        K[i][2] = S9 * (get_random(50) + 50) / 100;
        update_quadrant_string(r1, r2, "+K+");
    }

    /* Place starbase */
    if (B3 > 0) {
        do {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (r1 == S1 && r2 == S2);

        B4 = r1;
        B5 = r2;
        update_quadrant_string(r1, r2, ">!<");
    }

    /* Place stars */
    for (i = 0; i < S3; i++) {
        do {
            r1 = get_random(SECTOR_SIZE);
            r2 = get_random(SECTOR_SIZE);
        } while (r1 == S1 && r2 == S2);

        update_quadrant_string(r1, r2, " * ");
    }
}

/* Update quadrant string */
void update_quadrant_string(int z1, int z2, char *symbol) {
    int pos = z2 * 3 + z1 * 24;
    if (pos >= 0 && pos < 189) {
        Q[pos] = symbol[0];
        Q[pos + 1] = symbol[1];
        Q[pos + 2] = symbol[2];
    }
}

/* Get quadrant name (using global arrays) */
void get_quadrant_name(int z4, int z5) {
    if (z5 < 4) {
        simple_strcpy(G2, star_names1[z4]);
    } else {
        simple_strcpy(G2, star_names2[z4]);
    }
    simple_strcat(G2, roman_numerals[z5 % 4]);
}

/* Main game loop */
void main_game_loop(void) {
    char input[10];
    int i, cmd_found;

    while (1) {
        /* Check for docking */
        D0 = 0;
        if (B3 > 0) {
            if (abs_value(S1 - B4) <= 1 && abs_value(S2 - B5) <= 1) {
                D0 = 1;
                simple_strcpy(C_STR, "DOCKED");
                E = E0;
                P = P0;
                printf("SHIELDS DROPPED FOR DOCKING PURPOSES\n");
                S = 0;
            }
        }

        /* Set condition */
        if (!D0) {
            if (K3 > 0) {
                simple_strcpy(C_STR, "*RED*");
            } else if (E < E0 / 10) {
                simple_strcpy(C_STR, "YELLOW");
            } else {
                simple_strcpy(C_STR, "GREEN");
            }
        }

        /* Check for insufficient energy */
        if (S + E <= 10 && (E <= 10 || D[SHIELD_CONTROL] < 0)) {
            printf("\n** FATAL ERROR **   YOU'VE JUST STRANDED YOUR SHIP IN SPACE\n");
            printf("YOU HAVE INSUFFICIENT MANEUVERING ENERGY, AND SHIELD CONTROL\n");
            printf("IS PRESENTLY INCAPABLE OF CROSS-CIRCUITING TO ENGINE ROOM!!\n");
            end_game();
            return;
        }

        /* Get command */
        printf("COMMAND? ");
        simple_gets(input, 10);

        /* Parse command */
        cmd_found = 0;
        for (i = 0; i < MAX_COMMANDS; i++) {
            if (simple_strncmp(input, &A1[i * 3], 3) == 0) {
                cmd_found = 1;
                switch (i) {
                    case 0: navigation(); break;
                    case 1: short_range_scan(); break;
                    case 2: long_range_scan(); break;
                    case 3: phaser_control(); break;
                    case 4: photon_torpedoes(); break;
                    case 5: shield_control(); break;
                    case 6: damage_report(); break;
                    case 7: library_computer(); break;
                    case 8: end_game(); return;
                }
                break;
            }
        }

        if (!cmd_found) {
            printf("ENTER ONE OF THE FOLLOWING:\n");
            printf("  NAV  (TO SET COURSE)\n");
            printf("  SRS  (FOR SHORT RANGE SENSOR SCAN)\n");
            printf("  LRS  (FOR LONG RANGE SENSOR SCAN)\n");
            printf("  PHA  (TO FIRE PHASERS)\n");
            printf("  TOR  (TO FIRE PHOTON TORPEDOES)\n");
            printf("  SHE  (TO RAISE OR LOWER SHIELDS)\n");
            printf("  DAM  (FOR DAMAGE CONTROL REPORTS)\n");
            printf("  COM  (TO CALL ON LIBRARY-COMPUTER)\n");
            printf("  XXX  (TO RESIGN YOUR COMMAND)\n\n");
        }

        /* Check for end conditions */
        if (K9 <= 0) {
            printf("CONGRATULATIONS, CAPTAIN! THE LAST KLINGON BATTLE CRUISER\n");
            printf("MENACING THE FEDERATION HAS BEEN DESTROYED.\n\n");
            printf("YOUR EFFICIENCY RATING IS %d\n", 1000 * K7 * K7 / ((T - T0) * (T - T0)));
            end_game();
            return;
        }

        if (T > T0 + T9) {
            printf("IT IS STARDATE %d\n", T);
            end_game();
            return;
        }
    }
}

/* Navigation */
void navigation(void) {
    int c1, w1, n, i;
    int x1, x2, x, y;

    printf("COURSE (0-9)? ");
    c1 = simple_scanf_int();
    if (c1 == 9) c1 = 1;

    if (c1 < 1 || c1 >= 9) {
        printf("   LT. SULU REPORTS, 'INCORRECT COURSE DATA, SIR!'\n");
        return;
    }

    printf("WARP FACTOR (0-%s)? ", (D[WARP_ENGINES] < 0) ? "0.2" : "8");
    w1 = simple_scanf_int();

    if (D[WARP_ENGINES] < 0 && w1 > 0) {
        printf("WARP ENGINES ARE DAMAGED. MAXIMUM SPEED = WARP 0.2\n");
        return;
    }

    if (w1 <= 0) return;
    if (w1 > 8) {
        printf("   CHIEF ENGINEER SCOTT REPORTS 'THE ENGINES WON'T TAKE WARP %d!'\n", w1);
        return;
    }

    n = w1 * 8;
    if (E - n < 0) {
        printf("ENGINEERING REPORTS   'INSUFFICIENT ENERGY AVAILABLE\n");
        printf("                       FOR MANEUVERING AT WARP %d!'\n", w1);
        if (S < n - E || D[SHIELD_CONTROL] < 0) return;
        printf("DEFLECTOR CONTROL ROOM ACKNOWLEDGES %d UNITS OF ENERGY\n", S);
        printf("                         PRESENTLY DEPLOYED TO SHIELDS.\n");
        return;
    }

    /* Move Klingons */
    for (i = 0; i < K3; i++) {
        if (K[i][2] > 0) {
            update_quadrant_string(K[i][0], K[i][1], "   ");
            K[i][0] = get_random(SECTOR_SIZE);
            K[i][1] = get_random(SECTOR_SIZE);
            update_quadrant_string(K[i][0], K[i][1], "+K+");
        }
    }

    /* Klingon attack */
    klingon_attack();

    /* Repair damage */
    repair_damage();

    /* Move Enterprise */
    update_quadrant_string(S1, S2, "   ");

    /* Simplified course calculation - use integer approximation */
    x1 = C[c1 - 1][0];
    x2 = C[c1 - 1][1];
    x = S1;
    y = S2;

    for (i = 0; i < n; i++) {
        S1 += x1;
        S2 += x2;
        if (S1 < 0 || S1 >= SECTOR_SIZE || S2 < 0 || S2 >= SECTOR_SIZE) {
            /* Exceeded sector limits */
            break;
        }
        /* Check for collision */
        if (get_quadrant_symbol(S1, S2)[0] != ' ') {
            S1 = S1 - x1;
            S2 = S2 - x2;
            printf("WARP ENGINES SHUT DOWN AT SECTOR %d,%d DUE TO BAD NAVIGATION\n", S1, S2);
            break;
        }
    }

    S1 = S1;
    S2 = S2;
    update_quadrant_string(S1, S2, "<*>");

    /* Use energy */
    maneuver_energy(n);

    /* Update time */
    T += (w1 < 1) ? 1 : w1;
}

/* Short range sensor scan */
void short_range_scan(void) {
    int i, j;

    if (D[SHORT_SENSORS] < 0) {
        printf("\n*** SHORT RANGE SENSORS ARE OUT ***\n\n");
        return;
    }

    printf("---------------------------------\n");
    for (i = 0; i < SECTOR_SIZE; i++) {
        for (j = 0; j < SECTOR_SIZE; j++) {
            printf(" %s", get_quadrant_symbol(i, j));
        }

        /* Print status information */
        switch (i) {
            case 0: printf("        STARDATE          %d\n", T); break;
            case 1: printf("        CONDITION         %s\n", C_STR); break;
            case 2: printf("        QUADRANT          %d,%d\n", Q1, Q2); break;
            case 3: printf("        SECTOR            %d,%d\n", S1, S2); break;
            case 4: printf("        PHOTON TORPEDOES  %d\n", P); break;
            case 5: printf("        TOTAL ENERGY      %d\n", E + S); break;
            case 6: printf("        SHIELDS           %d\n", S); break;
            case 7: printf("        KLINGONS REMAINING %d\n", K9); break;
        }
    }
    printf("---------------------------------\n");
}

/* Get quadrant symbol */
char *get_quadrant_symbol(int z1, int z2) {
    int pos = z2 * 3 + z1 * 24;
    static char symbol[4];

    if (pos >= 0 && pos < 189) {
        symbol[0] = Q[pos];
        symbol[1] = Q[pos + 1];
        symbol[2] = Q[pos + 2];
        symbol[3] = '\0';
    } else {
        simple_strcpy(symbol, "   ");
    }
    return symbol;
}

/* Long range sensor scan */
void long_range_scan(void) {
    int i, j;

    if (D[LONG_SENSORS] < 0) {
        printf("LONG RANGE SENSORS ARE INOPERABLE\n");
        return;
    }

    printf("LONG RANGE SCAN FOR QUADRANT %d,%d\n", Q1, Q2);
    printf("-------------------\n");

    for (i = Q1 - 1; i <= Q1 + 1; i++) {
        printf(": ");
        for (j = Q2 - 1; j <= Q2 + 1; j++) {
            if (i >= 0 && i < GALAXY_SIZE && j >= 0 && j < GALAXY_SIZE) {
                printf("%03d ", G[i][j]);
                Z[i][j] = G[i][j];
            } else {
                printf("*** ");
            }
        }
        printf(":\n");
    }
    printf("-------------------\n");
}

/* Phaser control */
void phaser_control(void) {
    int x, h, i;

    if (D[PHASER_CONTROL] < 0) {
        printf("PHASERS INOPERATIVE\n");
        return;
    }

    if (K3 <= 0) {
        printf("SCIENCE OFFICER SPOCK REPORTS  'SENSORS SHOW NO ENEMY SHIPS\n");
        printf("                                IN THIS QUADRANT'\n");
        return;
    }

    if (D[LIBRARY_COMPUTER] < 0) {
        printf("COMPUTER FAILURE HAMPERS ACCURACY\n");
    }

    printf("PHASERS LOCKED ON TARGET;  ENERGY AVAILABLE = %d UNITS\n", E);
    printf("NUMBER OF UNITS TO FIRE? ");
    x = simple_scanf_int();

    if (x <= 0) return;
    if (E - x < 0) {
        printf("INSUFFICIENT ENERGY\n");
        return;
    }

    E -= x;
    if (D[SHIELD_CONTROL] < 0) {
        x = x * get_random(100) / 100;
    }

    h = x / K3;
    for (i = 0; i < K3; i++) {
        if (K[i][2] > 0) {
            int hit = h / (calculate_distance(S1, S2, K[i][0], K[i][1]) + 1) * (get_random(3) + 2);
            if (hit > K[i][2] * 15 / 100) {
                K[i][2] -= hit;
                printf("%d UNIT HIT ON KLINGON AT SECTOR %d,%d\n", hit, K[i][0], K[i][1]);
                if (K[i][2] <= 0) {
                    printf("*** KLINGON DESTROYED ***\n");
                    K3--;
                    K9--;
                    update_quadrant_string(K[i][0], K[i][1], "   ");
                    K[i][2] = 0;
                    G[Q1][Q2] -= 100;
                    Z[Q1][Q2] = G[Q1][Q2];
                } else {
                    printf("   (SENSORS SHOW %d UNITS REMAINING)\n", K[i][2]);
                }
            } else {
                printf("SENSORS SHOW NO DAMAGE TO ENEMY AT %d,%d\n", K[i][0], K[i][1]);
            }
        }
    }

    klingon_attack();
}

/* Photon torpedoes */
void photon_torpedoes(void) {
    int c1, hit;
    int x1, x2, x, y;
    int x3, y3, i;
    char *symbol;

    if (P <= 0) {
        printf("ALL PHOTON TORPEDOES EXPENDED\n");
        return;
    }

    if (D[PHOTON_TUBES] < 0) {
        printf("PHOTON TUBES ARE NOT OPERATIONAL\n");
        return;
    }

    printf("PHOTON TORPEDO COURSE (1-9)? ");
    c1 = simple_scanf_int();
    if (c1 == 9) c1 = 1;

    if (c1 < 1 || c1 >= 9) {
        printf("ENSIGN CHEKOV REPORTS,  'INCORRECT COURSE DATA, SIR!'\n");
        return;
    }

    /* Simplified torpedo trajectory calculation */
    x1 = C[c1 - 1][0];
    x2 = C[c1 - 1][1];
    x = S1;
    y = S2;
    E -= 2;
    P--;

    printf("TORPEDO TRACK:\n");

    while (1) {
        x += x1;
        y += x2;
        x3 = x;
        y3 = y;

        if (x3 < 0 || x3 >= SECTOR_SIZE || y3 < 0 || y3 >= SECTOR_SIZE) {
            printf("TORPEDO MISSED\n");
            break;
        }

        printf("               %d,%d\n", x3, y3);

        /* Check for hit */
        if (get_quadrant_symbol(x3, y3)[0] != ' ') {
            symbol = get_quadrant_symbol(x3, y3);

            if (symbol[0] == '+') {
                /* Hit Klingon */
                printf("*** KLINGON DESTROYED ***\n");
                K3--;
                K9--;
                for (i = 0; i < MAX_KLINGONS; i++) {
                    if (K[i][0] == x3 && K[i][1] == y3) {
                        K[i][2] = 0;
                        break;
                    }
                }
                update_quadrant_string(x3, y3, "   ");
                G[Q1][Q2] -= 100;
                Z[Q1][Q2] = G[Q1][Q2];
                break;
            } else if (symbol[0] == '*') {
                /* Hit star */
                printf("STAR AT %d,%d ABSORBED TORPEDO ENERGY.\n", x3, y3);
                break;
            } else if (symbol[0] == '>') {
                /* Hit starbase */
                printf("*** STARBASE DESTROYED ***\n");
                B3--;
                B9--;
                update_quadrant_string(x3, y3, "   ");
                G[Q1][Q2] -= 10;
                Z[Q1][Q2] = G[Q1][Q2];
                if (B9 <= 0 && K9 > T - T0 - T9) {
                    printf("THAT DOES IT, CAPTAIN!! YOU ARE HEREBY RELIEVED OF COMMAND\n");
                    printf("AND SENTENCED TO 99 STARDATES AT HARD LABOR ON CYGNUS 12!!\n");
                    end_game();
                    return;
                }
                printf("STARFLEET COMMAND REVIEWING YOUR RECORD TO CONSIDER COURT MARTIAL!\n");
                break;
            }
        }
    }

    klingon_attack();
}

/* Shield control */
void shield_control(void) {
    int x;

    if (D[SHIELD_CONTROL] < 0) {
        printf("SHIELD CONTROL INOPERABLE\n");
        return;
    }

    printf("ENERGY AVAILABLE = %d  NUMBER OF UNITS TO SHIELDS? ", E + S);
    x = simple_scanf_int();

    if (x < 0 || S == x) {
        printf("<SHIELDS UNCHANGED>\n");
        return;
    }

    if (x > E + S) {
        printf("SHIELD CONTROL REPORTS  'THIS IS NOT THE FEDERATION TREASURY.'\n");
        printf("<SHIELDS UNCHANGED>\n");
        return;
    }

    E = E + S - x;
    S = x;
    printf("DEFLECTOR CONTROL ROOM REPORT:\n");
    printf("  'SHIELDS NOW AT %d UNITS PER YOUR COMMAND.'\n", S);
}

/* Damage report (using global device_names array) */
void damage_report(void) {
    int i;

    printf("\nDEVICE             STATE OF REPAIR\n");
    for (i = 0; i < MAX_DEVICES; i++) {
        printf("%s %d\n", device_names[i], D[i]);
    }
    printf("\n");
}

/* Library computer */
void library_computer(void) {
    int a, i, j;

    if (D[LIBRARY_COMPUTER] < 0) {
        printf("COMPUTER DISABLED\n");
        return;
    }

    printf("COMPUTER ACTIVE AND AWAITING COMMAND? ");
    a = simple_scanf_int();

    if (a < 0) return;

    switch (a) {
        case 0:
            /* Cumulative galactic record */
            printf("        COMPUTER RECORD OF GALAXY FOR QUADRANT %d,%d\n", Q1, Q2);
            printf("       1     2     3     4     5     6     7     8\n");
            printf("     ----- ----- ----- ----- ----- ----- ----- -----\n");
            for (i = 0; i < GALAXY_SIZE; i++) {
                printf("%d", i + 1);
                for (j = 0; j < GALAXY_SIZE; j++) {
                    if (Z[i][j] == 0) {
                        printf("   ***");
                    } else {
                        printf("   %03d", Z[i][j]);
                    }
                }
                printf("\n");
            }
            break;
        case 1:
            /* Status report */
            printf("   STATUS REPORT:\n");
            printf("KLINGONS LEFT: %d\n", K9);
            printf("MISSION MUST BE COMPLETED IN %d STARDATES\n", T0 + T9 - T);
            if (B9 > 0) {
                printf("THE FEDERATION IS MAINTAINING %d STARBASE", B9);
                if (B9 > 1) printf("S");
                printf(" IN THE GALAXY\n");
            } else {
                printf("YOUR STUPIDITY HAS LEFT YOU ON YOUR OWN IN\n");
                printf("  THE GALAXY -- YOU HAVE NO STARBASES LEFT!\n");
            }
            damage_report();
            break;
        default:
            printf("FUNCTIONS AVAILABLE FROM LIBRARY-COMPUTER:\n");
            printf("   0 = CUMULATIVE GALACTIC RECORD\n");
            printf("   1 = STATUS REPORT\n");
            break;
    }
}

/* Klingon attack */
void klingon_attack(void) {
    int i, h;

    if (K3 <= 0) return;
    if (D0 != 0) {
        printf("STARBASE SHIELDS PROTECT THE ENTERPRISE\n");
        return;
    }

    for (i = 0; i < K3; i++) {
        if (K[i][2] > 0) {
            h = (K[i][2] / calculate_distance(S1, S2, K[i][0], K[i][1])) * (get_random(3) + 2);
            S -= h;
            K[i][2] = K[i][2] / (3 + get_random(3));
            printf("%d UNIT HIT ON ENTERPRISE FROM SECTOR %d,%d\n", h, K[i][0], K[i][1]);
            if (S <= 0) {
                printf("\nTHE ENTERPRISE HAS BEEN DESTROYED. THE FEDERATION WILL BE CONQUERED\n");
                end_game();
                return;
            }
            printf("      <SHIELDS DOWN TO %d UNITS>\n", S);
            if (h >= 20 && (get_random(10) > 6 || h * 100 / S > 2)) {
                int r1 = get_random(MAX_DEVICES);
                D[r1] = D[r1] - h / S - get_random(5);
                printf("DAMAGE CONTROL REPORTS '%s DAMAGED BY THE HIT'\n", device_names[r1]);
            }
        }
    }
}

/* Calculate distance (simplified as distance squared) */
int calculate_distance(int x1, int y1, int x2, int y2) {
    int dx = x2 - x1;
    int dy = y2 - y1;
    return dx * dx + dy * dy;  /* Distance squared for comparison */
}

/* Repair damage */
void repair_damage(void) {
    int i, d1 = 0;

    for (i = 0; i < MAX_DEVICES; i++) {
        if (D[i] < 0) {
            D[i] += 1;
            if (D[i] > -1 && D[i] < 0) {
                D[i] = -1;
            } else if (D[i] >= 0) {
                if (d1 == 0) {
                    d1 = 1;
                    printf("DAMAGE CONTROL REPORT:  ");
                }
                printf("%s REPAIR COMPLETED.\n", device_names[i]);
            }
        }
    }
}

/* Maneuver energy */
void maneuver_energy(int energy_used) {
    E = E - energy_used - 10;
    if (E < 0) {
        printf("SHIELD CONTROL SUPPLIES ENERGY TO COMPLETE THE MANEUVER.\n");
        S = S + E;
        E = 0;
        if (S < 0) S = 0;
    }
}

/* End game (fixed to use restart flag instead of recursive main() call) */
void end_game(void) {
    char response[10];  /* Variable declared at top for Micro-C compatibility */

    printf("THERE WERE %d KLINGON BATTLE CRUISERS LEFT AT\n", K9);
    printf("THE END OF YOUR MISSION.\n\n");

    if (B9 > 0) {
        printf("THE FEDERATION IS IN NEED OF A NEW STARSHIP COMMANDER\n");
        printf("FOR A SIMILAR MISSION -- IF THERE IS A VOLUNTEER,\n");
        printf("LET HIM STEP FORWARD AND ENTER 'AYE': ");
        simple_gets(response, 10);
        if (simple_strcmp(response, "AYE") == 0) {
            restart_game = 1;  /* Set restart flag instead of calling main() */
            return;
        }
    }

    /* No exit() call - just return to main which will terminate */
}

/* Main function with game restart loop */
int main(void) {
    printf("SUPER STAR TREK - C VERSION (MICRO-C COMPATIBLE)\n");
    printf("CONVERTED FROM BASIC\n\n");

    do {
        /* Seed random number generator */
        random_seed = 12345;

        /* Initialize game */
        initialize_game();

        /* Print instructions */
        print_instructions();

        /* Enter starting quadrant */
        enter_quadrant();

        /* Start game loop */
        main_game_loop();

    } while (restart_game);

    return 0;
}