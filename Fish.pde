// =====================================================================
//  Fish - the player.
//
//  Free 2D movement inside the water column. Acceleration plus drag
//  rather than fixed-speed stepping, so the fish carries momentum and
//  feels like it is swimming through something rather than sliding on
//  a grid.
//
//  OWNER: [player character and movement]
// =====================================================================

class  Fish {

  float x, y;
  float vx = 0, vy = 0;
  float r  = 15;                 // collision radius -- deliberately smaller
                                 // than the drawn body, so near misses read
                                 // as near misses instead of cheap deaths

  float facing   = 1;            // +1 right, -1 left
  float tailPhase = 0;
  float squash    = 0;           // brief stretch when accelerating hard

  boolean dead = false;
  float deathRoll = 0;

  int invulnFrames = 0;          // grace period after taking a hit

  final float ACCEL     = 0.62;
  final float MAX_SPEED = 6.1;
  final float DRAG      = 0.905;

  Fish() {
    reset();
  }

  void reset() {
    x = width * 0.30;
    y = (SURFACE_Y + SEABED_Y) * 0.5;
    vx = 0;
    vy = 0;
    dead = false;
    deathRoll = 0;
    invulnFrames = 0;
  }

  void startInvulnerable() {
    invulnFrames = 110;          // just under two seconds of safety
  }

  boolean invulnerable() {
    return invulnFrames > 0;
  }

  void die() {
    dead = true;
    deathRoll = 0;
  }

  // Menu-screen behaviour: the fish keeps breathing so the title screen
  // is not a still image, but no input is read and no physics runs.
  void idle() {
    tailPhase += 0.14 * dt;
    if (invulnFrames > 0) invulnFrames -= dt;

    if (dead) {
      deathRoll = min(PI, deathRoll + 0.09 * dt);
      y = max(SURFACE_Y + 16, y - 1.4 * dt);
      return;
    }
    y += sin(frameCount * 0.04) * 0.42 * dt;
    squash = lerp(squash, 0, 0.1);
  }
void update() { 

  // ---- read input ------------------------------------------------ 

  float ax = 0, ay = 0;              // acceleration requested this frame 

  // held() checks the key table, so both layouts drive the same code 

  if (held(LEFT,  'A')) ax -= ACCEL;   // push left 

  if (held(RIGHT, 'D')) ax += ACCEL;   // push right 

  if (held(UP,    'W')) ay -= ACCEL;   // push up (y grows downward) 

  if (held(DOWN,  'S')) ay += ACCEL;   // push down 

  

  // Normalise diagonals. Without this, holding two keys gives 1.41x 

  // the speed of one, making corner-running the dominant strategy. 

  if (ax != 0 && ay != 0) { 

    ax *= 0.7071;                    // cos(45 degrees) 

    ay *= 0.7071; 

  } 

  

  vx += ax * dt;                     // acceleration feeds velocity, 

  vy += ay * dt;                     // so the fish carries momentum 

  

  // ---- drag and speed cap ---------------------------------------- 

  vx *= pow(DRAG, dt);               // bleed speed off each frame, so 

  vy *= pow(DRAG, dt);               // releasing a key glides to a stop 

  

  float sp = mag(vx, vy);            // current speed, both axes combined 

  if (sp > MAX_SPEED) {              // clamp to the agreed maximum 

    vx = vx / sp * MAX_SPEED;        // scale both components equally so 

    vy = vy / sp * MAX_SPEED;        // the direction of travel is kept 

  } 

  

  x += vx * dt;                      // apply the frame’s movement 

  y += vy * dt; 

  

  // ---- keep the fish inside the water ---------------------------- 

  float top    = SURFACE_Y + 18;     // just under the waterline 

  float bottom = SEABED_Y  - 14;     // just above the sand 

  // Killing the velocity into a wall stops the player grinding an edge 

  if (x < r)         { x = r;         vx = 0; } 

  if (x > width - r) { x = width - r; vx = 0; } 

  if (y < top)       { y = top;       vy *= -0.25; }  // soft bounce 

  if (y > bottom)    { y = bottom;    vy *= -0.25; } 

} 
    // ---- presentation ------------------------------------------------
    if (abs(vx) > 0.35) facing = (vx > 0) ? 1 : -1;
    squash = lerp(squash, constrain(sp / MAX_SPEED, 0, 1), 0.18);
  }

  void display() {
    // Flash on and off during the post-hit grace period so the player can
    // see they are temporarily safe.
    if (invulnerable() && (frameCount / 4) % 2 == 0 && !dead) return;

    pushMatrix();
    translate(x, y);
    if (dead) rotate(deathRoll);
    scale(facing, 1);

    // Nose tilts toward the direction of travel.
    float tilt = constrain(vy * 0.05 * facing, -0.45, 0.45);
    rotate(tilt);

    float bodyW = 46 * (1 + squash * 0.10);
    float bodyH = 27 * (1 - squash * 0.09);

    noStroke();

    // ---- tail: sweeps behind, faster the harder you swim -------------
    float sweep = sin(tailPhase) * (0.30 + squash * 0.45);
    pushMatrix();
    translate(-bodyW * 0.44, 0);
    rotate(sweep);
    fill(214, 96, 44);
    triangle(0, 0, -20, -15, -20, 15);
    fill(238, 128, 62);
    triangle(0, 0, -16, -9, -16, 9);
    popMatrix();

    // ---- dorsal and pelvic fins --------------------------------------
    fill(214, 96, 44);
    triangle(-bodyW * 0.10, -bodyH * 0.42,
              bodyW * 0.16, -bodyH * 0.42,
             -bodyW * 0.02, -bodyH * 0.42 - 13 - squash * 4);
    triangle(-bodyW * 0.08,  bodyH * 0.38,
              bodyW * 0.10,  bodyH * 0.38,
             -bodyW * 0.02,  bodyH * 0.38 + 9);

    // ---- body --------------------------------------------------------
    fill(246, 140, 62);
    ellipse(0, 0, bodyW, bodyH);
    fill(255, 178, 104);                                  // lit upper flank
    arc(0, 0, bodyW * 0.94, bodyH * 0.86, PI, TWO_PI);
    fill(255, 232, 198);                                  // pale belly
    arc(0, bodyH * 0.06, bodyW * 0.80, bodyH * 0.62, 0, PI);

    // ---- pectoral fin, beating out of phase with the tail -------------
    fill(230, 112, 52);
    pushMatrix();
    translate(bodyW * 0.02, bodyH * 0.18);
    rotate(sin(tailPhase * 1.7) * 0.4 + 0.3);
    ellipse(0, 0, 17, 9);
    popMatrix();

    // ---- gill line ----------------------------------------------------
    noFill();
    stroke(206, 92, 44, 190);
    strokeWeight(2);
    arc(bodyW * 0.10, 0, 14, bodyH * 0.62, -HALF_PI * 1.15, HALF_PI * 1.15);
    noStroke();

    // ---- eye -----------------------------------------------------------
    fill(255);
    ellipse(bodyW * 0.30, -bodyH * 0.14, 11, 11);
    fill(30, 34, 44);
    if (dead) {
      // Classic dead-fish cross.
      stroke(30, 34, 44);
      strokeWeight(2.4);
      line(bodyW * 0.30 - 4, -bodyH * 0.14 - 4, bodyW * 0.30 + 4, -bodyH * 0.14 + 4);
      line(bodyW * 0.30 + 4, -bodyH * 0.14 - 4, bodyW * 0.30 - 4, -bodyH * 0.14 + 4);
      noStroke();
    } else {
      // Pupil drifts toward wherever the fish is heading.
      ellipse(bodyW * 0.30 + constrain(vx * 0.32, -2, 2),
              -bodyH * 0.14 + constrain(vy * 0.32, -2, 2), 6, 6);
      fill(255, 255, 255, 200);
      ellipse(bodyW * 0.30 + 1.6, -bodyH * 0.14 - 2, 3, 3);
    }

    popMatrix();

    // ---- shield ring during the grace period ---------------------------
    if (invulnerable() && !dead) {
      noFill();
      stroke(150, 230, 255, 130 + sin(frameCount * 0.35) * 60);
      strokeWeight(2.5);
      ellipse(x, y, 66 + sin(frameCount * 0.2) * 4, 56 + sin(frameCount * 0.2) * 4);
      noStroke();
    }
  }
}
