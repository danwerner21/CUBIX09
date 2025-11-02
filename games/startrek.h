#include "trekconstants.h"

/* Function prototypes */
void paint_intro_screen();
void initialize_game(void);
void enter_quadrant(void);
void long_range_scan(void);
void phaser_control(void);
void photon_torpedoes(void);
void damage_report(void);
void library_computer(void);
void warpSpeed(int WarpFactor);
void end_game(void);
void klingon_attack(void);
void place_enterprise(void);
void place_objects(void);
void get_quadrant_name(int z4, int z5);
void CheckDocked(void);
int get_random(int max);
int find_empty_sector(void);
void repair_damage(void);
int calculate_distance(int x1, int y1, int x2, int y2);
int calculate_direction(int x1, int y1, int x2, int y2);
void impulsePower(void);


/* Global game state */
int G[GALAXY_SIZE + 1][GALAXY_SIZE + 1]; /* Galaxy map */
int K[MAX_KLINGONS][3];                  /* Klingon positions and energy */
int Z[GALAXY_SIZE + 1][GALAXY_SIZE + 1]; /* Cumulative galactic record */
int D[MAX_DEVICES];                      /* Damage array */

/* Game variables */
static int T, T0, T9;      /* Time variables */
static int E;              /* Energy */
static int P;              /* Photon torpedoes */
static int S;              /* Shield energy */
static int B9, K9, K7;     /* Starbases, Klingons */
static int Q1, Q2, S1, S2; /* Quadrant and sector positions */
static int K3, B3, S3;     /* Quadrant contents */
static int B4, B5;         /* Starbase position */
static int D0, D4;         /* Docked flag, damage repair time */
static char Qu[65];        /* Quadrant string */
static char G2[20];        /* Region name */
static char C_STR[10];     /* Condition string */
static char C_STR_COLOR;   /* Condition string COLOR*/

/* Game restart flag (replaces recursive main() call) */
static int restart_game = 0;


/* Random number seed */
static unsigned lfsr = 0xACE1u;
static unsigned bit;

static unsigned int random_seed = 1;
