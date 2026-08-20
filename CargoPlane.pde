// =====================================================================
//  CargoPlane - the source of every hazard in the game.
//
//  Crosses the sky, turns around off-screen, comes back the other way.
//  Its rear ramp is the exact point cargo is released from, so the
//  player can watch the plane and know where the next wave will land.
//
//  OWNER: [the plane]
// =====================================================================

class CargoPlane {

  float x, y;
  float vx;
  float baseY;
  float bob      = 0;
  float propPhase = 0;
  float rampKick  = 0;           // recoil when a piece is released
  float turnDelay = 0;           // pause off-screen between passes
  int   dir       = 1;           // +1 flying right, -1 flying left

  final float BODY_W = 190;
  final float BODY_H = 34;

  CargoPlane() {
    reset();
  }

  void reset() {
    dir   = 1;
    baseY = 74;
    x     = -BODY_W;
    y     = baseY;
    vx    = 1.9;
    turnDelay = 0;
    rampKick  = 0;
  }

  void update() {
    propPhase += 0.55 * dt;
    bob       += 0.02 * dt;
    rampKick  *= pow(0.86, dt);

    if (turnDelay > 0) {
      turnDelay -= dt;
      return;
    }

    // Speed tracks the difficulty ramp, so late in a run the plane is
    // sweeping across fast and the drop pattern gets much wider.
    vx = 1.9 * gameSpeed * dir;
    x += vx * dt;
    y  = baseY + sin(bob) * 5;

    // Off the far edge: turn around, pick a new altitude, come back.
    float margin = BODY_W * 0.9;
    if ((dir > 0 && x > width + margin) || (dir < 0 && x < -margin)) {
      dir   = -dir;
      baseY = random(56, 116);
      turnDelay = 34 / gameSpeed;
      x = (dir > 0) ? -margin : width + margin;
    }
  }

  // Cargo is only released while the ramp is genuinely above open water.
  boolean overWater() {
    return turnDelay <= 0 && rampX() > 20 && rampX() < width - 20;
  }

  // The tail ramp sits at the back of the plane, which flips with heading.
  float rampX() {
    return x - dir * BODY_W * 0.44;
  }

  float rampY() {
    return y + BODY_H * 0.42 + rampKick;
  }

  void kick() {
    rampKick = 4;
  }

  void display() {
    pushMatrix();
    translate(x, y);
    scale(dir, 1);
    noStroke();

    // ---- contrails ----
    fill(255, 255, 255, 55);
    for (int i = 0; i < 3; i++) {
      float t = i * 46;
      rect(-BODY_W * 0.5 - 30 - t, -6 + sin((frameCount * 0.05) + i) * 2, 26 - i * 5, 4, 2);
    }

    // ---- tail fin ----
    fill(206, 210, 218);
    quad(-BODY_W * 0.46, 0,
         -BODY_W * 0.30, 0,
         -BODY_W * 0.30, -34,
         -BODY_W * 0.44, -34);
    fill(178, 62, 58);
    rect(-BODY_W * 0.44, -34, BODY_W * 0.14, 9);          // livery stripe

    // ---- far wing, drawn behind the fuselage ----
    fill(176, 182, 192);
    quad(-10, -2, 44, -2, 26, -40, -2, -40);

    // ---- fuselage ----
    fill(232, 236, 242);
    rect(-BODY_W * 0.5, -BODY_H * 0.5, BODY_W, BODY_H, 12);
    fill(206, 212, 220);
    rect(-BODY_W * 0.5, 0, BODY_W, BODY_H * 0.5, 12);      // shaded underside
    fill(178, 62, 58);
    rect(-BODY_W * 0.5, -4, BODY_W, 5);                    // cheat line

    // ---- nose and flight deck ----
    fill(232, 236, 242);
    arc(BODY_W * 0.46, 0, 42, BODY_H, -HALF_PI, HALF_PI);
    fill(74, 96, 122);
    rect(BODY_W * 0.34, -BODY_H * 0.30, 22, 10, 3);        // cockpit glass

    // ---- open rear ramp: the release point ----
    fill(196, 202, 212);
    pushMatrix();
    translate(-BODY_W * 0.44, BODY_H * 0.30 + rampKick);
    rotate(0.55);
    rect(0, 0, 40, 7, 2);
    popMatrix();
    fill(38, 44, 54);
    rect(-BODY_W * 0.48, -BODY_H * 0.24, 26, BODY_H * 0.60, 3);   // dark cargo bay

    // ---- near wing ----
    fill(214, 220, 230);
    quad(-16, 2, 42, 2, 30, 40, -4, 40);

    // ---- engines with turning props ----
    drawEngine(4, 22);
    drawEngine(-30, 30);

    popMatrix();
  }

  void drawEngine(float ex, float ey) {
    fill(150, 156, 168);
    rect(ex - 13, ey - 7, 30, 14, 5);                     // nacelle
    fill(120, 126, 138);
    rect(ex - 13, ey - 7, 30, 5, 4);

    // Blur disc plus two blades: reads as spinning without the strobing
    // you get from drawing sharp blades at 60fps.
    fill(210, 214, 222, 70);
    ellipse(ex + 19, ey, 8, 40);
    stroke(196, 200, 210, 160);
    strokeWeight(2);
    float a = propPhase;
    line(ex + 19, ey, ex + 19, ey + cos(a) * 19);
    line(ex + 19, ey, ex + 19, ey - cos(a) * 19);
    noStroke();
    fill(120, 126, 138);
    ellipse(ex + 19, ey, 7, 7);                           // spinner
  }
}
