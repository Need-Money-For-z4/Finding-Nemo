// =====================================================================
//  O V E R B O A R D
//  Subject: FISH   |   Action: DODGE   |   Object: PLANE
//
//  A cargo plane crosses the sky above the ocean, shedding its load.
//  You are the fish below. Survive. The longer you last the faster it
//  comes, the more you score, and the higher you climb the leaderboard.
//
//  OWNER: [core loop, state machine, difficulty, input]
// =====================================================================

// ---------------------------------------------------------- game states
final int STATE_TITLE   = 0;
final int STATE_PLAYING = 1;
final int STATE_PAUSED  = 2;
final int STATE_ENTRY   = 3;   // typing your initials into the leaderboard
final int STATE_OVER    = 4;
final int STATE_BOARD   = 5;   // leaderboard viewed from the title screen

// ---------------------------------------------------------- cargo kinds
// Declared at sketch level so every class can see them.
final int C_SUITCASE  = 0;
final int C_CRATE     = 1;
final int C_BARREL    = 2;
final int C_PALLET    = 3;
final int C_CONTAINER = 4;

// ------------------------------------------------------- power-up kinds
final int PU_LIFE   = 0;   // +1 life
final int PU_SLOW   = 1;   // time runs at 0.5x
final int PU_DOUBLE = 2;   // 2x points

// ------------------------------------------------------ world constants
final float SURFACE_Y = 190;   // the waterline
final float SEABED_Y  = 616;   // where the sand starts

final float GRAVITY_AIR = 0.30;   // gentle, so falling cargo is readable
final int   START_LIVES = 3;
final int   MAX_LIVES   = 5;

// ------------------------------------------------------ mutable globals
int   gameState = STATE_TITLE;
float score     = 0;
int   lives     = START_LIVES;
float gameSpeed = 1.0;    // difficulty multiplier, ramps 1.0 -> 2.4
float runTime   = 0;      // seconds survived this run
float timeScale = 1.0;    // 0.5 while the slow-mo power-up is active
float dt        = 1.0;    // per-frame time step; everything moves by * dt

// ------------------------------------------------------------- entities
Fish            fish;
CargoPlane      plane;
CargoManager    cargo;
PowerUpManager  powerups;
Ocean           ocean;
Effects         fx;
HUD             hud;
Leaderboard     board;

// --------------------------------------------------------- screen juice
float shakeAmount = 0;    // screen shake, decays each frame
float flashAmount = 0;    // red damage flash, decays each frame

// ----------------------------------------------------------------- misc
boolean[] keysHeld = new boolean[512];   // held-key table, so diagonals work
PFont fontUI, fontNum, fontBig;

void setup() {
  size(960, 640);
  frameRate(60);

  // Logical font names, always present on every JVM, so the sketch runs
  // identically on every machine in the team without shipping font files.
  fontUI  = createFont("SansSerif", 24, true);
  fontNum = createFont("Monospaced", 28, true);
  fontBig = createFont("SansSerif", 80, true);
  textFont(fontUI);

  ocean    = new Ocean();
  fx       = new Effects();
  fish     = new Fish();
  plane    = new CargoPlane();
  cargo    = new CargoManager();
  powerups = new PowerUpManager();
  hud      = new HUD();
  board    = new Leaderboard();

  board.load();
  gameState = STATE_TITLE;
}

void draw() {
  boolean paused  = (gameState == STATE_PAUSED);
  boolean playing = (gameState == STATE_PLAYING);

  // dt is the single knob the slow-mo power-up turns. Every moving thing
  // multiplies by it, so one variable slows the entire world. Menus still
  // run at 1.0 so the background stays alive behind them; pause freezes
  // everything by setting it to zero.
  if (paused)       dt = 0;
  else if (playing) dt = timeScale;
  else              dt = 1.0;

  pushMatrix();
  applyShake();

  ocean.update();
  ocean.display();

  if (playing) {
    updatePlaying();
  } else if (!paused) {
    // Ambient life behind the menus: the plane keeps flying, the fish
    // keeps breathing, leftover particles finish their arcs.
    plane.update();
    fish.idle();
    fx.update();
  }

  // Draw order is back to front: plane in the sky, then cargo and
  // power-ups in the water, then the fish, then particles on top.
  plane.display();
  cargo.display();
  powerups.display();
  fish.display();
  fx.display();

  popMatrix();

  // Vignette and overlays sit outside the shake, so the screen edges
  // never tear away from the frame when the player takes a hit.
  ocean.displayForeground();
  drawFlash();

  if (playing || paused) hud.display();

  if      (gameState == STATE_TITLE)  drawTitleScreen();
  else if (gameState == STATE_PAUSED) drawPauseScreen();
  else if (gameState == STATE_ENTRY)  drawNameEntryScreen();
  else if (gameState == STATE_OVER)   drawGameOverScreen();
  else if (gameState == STATE_BOARD)  drawBoardScreen();

  decayJuice();
}

// ------------------------------------------------------------- the loop

void updatePlaying() {
  runTime += dt / 60.0;

  // Difficulty ramp. Rises for the first minute and a half, then holds at
  // 2.4x so the game stays hard but never becomes literally impossible.
  gameSpeed = 1.0 + min(1.4, runTime / 85.0);

  // Points accrue with time survived, scaled by difficulty, doubled while
  // the 2x power-up runs. Slow-mo also slows scoring through dt, so it
  // costs you points -- that trade-off is what makes it a real choice.
  score += 0.62 * gameSpeed * dt * powerups.pointMultiplier();

  plane.update();
  cargo.update();
  powerups.update();
  fish.update();
  fx.update();

  // Collisions are resolved after everything has moved, so nothing is
  // ever tested against a stale position from the previous frame.
  cargo.checkCollisions();
  powerups.checkPickups();
}

// ------------------------------------------------------ run start / end

void startRun() {
  score     = 0;
  lives     = START_LIVES;
  runTime   = 0;
  gameSpeed = 1.0;
  timeScale = 1.0;

  fish.reset();
  plane.reset();
  cargo.reset();
  powerups.reset();
  fx.clear();
  board.highlightRow = -1;

  gameState = STATE_PLAYING;
}

// Called by CargoManager when a piece of cargo connects.
void damageFish() {
  lives--;
  shakeAmount = 14;
  flashAmount = 150;
  fx.burst(fish.x, fish.y, color(255, 90, 70), 22);

  if (lives <= 0) endRun();
  else            fish.startInvulnerable();
}

void endRun() {
  lives     = 0;
  timeScale = 1.0;
  fx.burst(fish.x, fish.y, color(255, 210, 120), 30);
  fish.die();

  // Only ask for initials if the score actually lands on the board --
  // nobody wants to type their name in just to be told they lost.
  if (board.qualifies(int(score))) {
    board.beginEntry(int(score));
    gameState = STATE_ENTRY;
  } else {
    gameState = STATE_OVER;
  }
}

void quitToTitle() {
  fish.reset();
  cargo.reset();
  powerups.reset();
  fx.clear();
  gameState = STATE_TITLE;
}

// -------------------------------------------------------- screen juice

void applyShake() {
  if (shakeAmount > 0.2) {
    translate(random(-shakeAmount, shakeAmount), random(-shakeAmount, shakeAmount));
  }
}

void drawFlash() {
  if (flashAmount > 1) {
    noStroke();
    fill(255, 60, 50, flashAmount * 0.55);
    rect(0, 0, width, height);
  }
}

void decayJuice() {
  shakeAmount *= 0.86;
  flashAmount *= 0.88;
}

// ----------------------------------------------------------------- input

void keyPressed() {
  if (keyCode >= 0 && keyCode < 512) keysHeld[keyCode] = true;
  if (key == ESC) key = 0;              // stop ESC from killing the sketch

  boolean confirm = (key == ' ' || key == ENTER || key == RETURN);
  boolean isL     = (key == 'l' || key == 'L');
  boolean isP     = (key == 'p' || key == 'P');
  boolean isQ     = (key == 'q' || key == 'Q');

  if (gameState == STATE_TITLE) {
    if (confirm) startRun();
    if (isL)     gameState = STATE_BOARD;

  } else if (gameState == STATE_PLAYING) {
    if (isP) gameState = STATE_PAUSED;

  } else if (gameState == STATE_PAUSED) {
    if (isP || confirm) gameState = STATE_PLAYING;
    if (isQ)            quitToTitle();

  } else if (gameState == STATE_ENTRY) {
    board.handleEntryKey(key);

  } else if (gameState == STATE_OVER) {
    if (confirm) startRun();
    if (isL)     gameState = STATE_BOARD;

  } else if (gameState == STATE_BOARD) {
    if (confirm || isL) gameState = STATE_TITLE;
  }
}

void keyReleased() {
  if (keyCode >= 0 && keyCode < 512) keysHeld[keyCode] = false;
}

// Helper the Fish uses so movement code does not care which key layout
// the player prefers.
boolean held(int a, int b) {
  return keysHeld[a] || keysHeld[b];
}

void mousePressed() {
  if (gameState == STATE_TITLE || gameState == STATE_OVER) startRun();
}
