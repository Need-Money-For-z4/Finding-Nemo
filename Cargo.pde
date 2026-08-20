// =====================================================================
//  Cargo - a single piece of freight falling out of the plane.
//
//  Two-phase physics. In AIR it accelerates under gravity. The moment it
//  crosses the waterline it splashes, loses most of its speed, and then
//  sinks toward a terminal velocity set by how heavy it is. That gives
//  every piece a fast, readable entry and a long, dodgeable descent.
//
//  OWNER: [hazards]
// =====================================================================

class Cargo {

  int   kind;
  float x, y;
  float vx, vy;
  float w, h;
  float rot, spin;
  float terminal;                // sink speed once fully submerged
  float maxTilt;                 // rotation clamp; wide pieces stay flat so
                                 // the collision box stays honest
  boolean submerged = false;
  boolean scored    = false;     // near-miss bonus is awarded only once
  boolean finished  = false;     // ready to be removed from the list

  Cargo(int kind, float x, float y, float vx) {
    this.kind = kind;
    this.x    = x;
    this.y    = y;
    this.vx   = vx;
    this.vy   = 0.6;

    if (kind == C_SUITCASE) {          // small, light, drifts on the way down
      w = 40;  h = 28;  terminal = 1.5;  spin = random(-0.055, 0.055); maxTilt = PI;
    } else if (kind == C_CRATE) {      // the bread and butter hazard
      w = 48;  h = 48;  terminal = 2.3;  spin = random(-0.035, 0.035); maxTilt = PI;
    } else if (kind == C_BARREL) {     // heavy, sinks quickly, little warning
      w = 40;  h = 56;  terminal = 3.0;  spin = random(-0.028, 0.028); maxTilt = PI;
    } else if (kind == C_PALLET) {     // wide, hard to slip past sideways
      w = 78;  h = 22;  terminal = 1.9;  spin = random(-0.012, 0.012); maxTilt = 0.30;
    } else {                           // C_CONTAINER: rare, huge, screen-filling
      w = 118; h = 54;  terminal = 3.2;  spin = random(-0.008, 0.008); maxTilt = 0.22;
    }
    rot = random(-0.3, 0.3);
  }

  void update() {
    if (!submerged) {
      // ---- falling through air ----
      vy += GRAVITY_AIR * dt;
      rot += spin * dt;

      if (y + h * 0.35 >= SURFACE_Y) enterWater();

    } else {
      // ---- sinking through water ----
      // Ease toward terminal velocity rather than snapping to it, so the
      // deceleration on entry is visible.
      vy += (terminal * gameSpeed - vy) * 0.045 * dt;
      vx *= pow(0.975, dt);
      rot += spin * 0.45 * dt;

      // Wide flat pieces settle level as they sink.
      if (maxTilt < 1) rot = constrain(rot * pow(0.985, dt), -maxTilt, maxTilt);

      // A slow sideways sway, so the descent is not a dead straight line.
      x += sin((frameCount + y) * 0.018) * 0.35 * dt;

      // Trail of bubbles off the heavier pieces.
      if (frameCount % 7 == 0 && terminal > 2.0 && random(1) < 0.6) {
        fx.bubble(x + random(-w * 0.3, w * 0.3), y - h * 0.4);
      }
    }

    x += vx * dt;
    y += vy * dt;

    // Hit the seabed: puff of sand and gone.
    if (y - h * 0.4 > SEABED_Y) {
      fx.sandPuff(x, SEABED_Y);
      finished = true;
    }
    // Drifted off the side.
    if (x < -160 || x > width + 160) finished = true;
  }

  // Crossing the waterline: splash, ripple, and a hard loss of momentum.
  void enterWater() {
    submerged = true;
    y  = SURFACE_Y - h * 0.35 + 1;
    vy *= 0.28;
    vx *= 0.45;

    float force = constrain(map(w * h, 900, 6400, 0.6, 2.0), 0.5, 2.2);
    fx.splash(x, SURFACE_Y, force);
    fx.ripple(x, SURFACE_Y, force);
    shakeAmount = max(shakeAmount, force * 2.2);
  }

  // ---- collision: circle (fish) against this piece's axis-aligned box --
  // Rotation on the wide pieces is clamped above, so an AABB stays a fair
  // approximation of what the player can actually see.
  boolean hits(Fish f) {
    float halfW = w * 0.42;
    float halfH = h * 0.42;
    float nearX = constrain(f.x, x - halfW, x + halfW);
    float nearY = constrain(f.y, y - halfH, y + halfH);
    return dist(f.x, f.y, nearX, nearY) < f.r;
  }

  // How close the fish came without being hit -- drives the near-miss bonus.
  float clearance(Fish f) {
    float halfW = w * 0.42;
    float halfH = h * 0.42;
    float nearX = constrain(f.x, x - halfW, x + halfW);
    float nearY = constrain(f.y, y - halfH, y + halfH);
    return dist(f.x, f.y, nearX, nearY) - f.r;
  }

  // ------------------------------------------------------------ drawing

  void display() {
    pushMatrix();
    translate(x, y);
    rotate(rot);
    noStroke();

    if      (kind == C_SUITCASE) drawSuitcase();
    else if (kind == C_CRATE)    drawCrate();
    else if (kind == C_BARREL)   drawBarrel();
    else if (kind == C_PALLET)   drawPallet();
    else                         drawContainer();

    popMatrix();
  }

  void drawSuitcase() {
    fill(96, 62, 48);
    rect(-w / 2, -h / 2, w, h, 4);
    fill(122, 80, 60);
    rect(-w / 2 + 3, -h / 2 + 3, w - 6, h - 6, 3);
    fill(70, 46, 36);
    rect(-w / 2 + 3, -3, w - 6, 6);              // strap
    fill(198, 176, 120);
    rect(-6, -h / 2 - 5, 12, 6, 2);              // handle
    rect(w / 2 - 12, -2, 7, 4);                  // latch
  }

  void drawCrate() {
    fill(150, 106, 58);
    rect(-w / 2, -h / 2, w, h, 3);
    fill(178, 130, 74);
    rect(-w / 2 + 4, -h / 2 + 4, w - 8, h - 8, 2);
    fill(128, 88, 46);
    rect(-w / 2, -4, w, 8);                      // banding
    rect(-4, -h / 2, 8, h);
    fill(94, 64, 34);                            // corner brackets
    rect(-w / 2, -h / 2, 8, 8);
    rect(w / 2 - 8, -h / 2, 8, 8);
    rect(-w / 2, h / 2 - 8, 8, 8);
    rect(w / 2 - 8, h / 2 - 8, 8, 8);
  }

  void drawBarrel() {
    fill(74, 108, 74);
    rect(-w / 2, -h / 2, w, h, 7);
    fill(96, 138, 92);
    rect(-w / 2 + 4, -h / 2 + 2, w * 0.30, h - 4, 5);   // lit side
    fill(52, 78, 54);
    rect(-w / 2, -h * 0.30, w, 6);                      // hoops
    rect(-w / 2, h * 0.16, w, 6);
    fill(206, 198, 150);
    ellipse(0, 0, 15, 15);                              // hazard placard
    fill(74, 108, 74);
    ellipse(0, 0, 8, 8);
  }

  void drawPallet() {
    fill(158, 120, 70);
    rect(-w / 2, -h / 2, w, h * 0.44, 2);               // deck boards
    rect(-w / 2, h * 0.10, w, h * 0.30, 2);
    fill(120, 88, 50);
    for (int i = -1; i <= 1; i++) {                     // stringers
      rect(i * w * 0.32 - 6, -h / 2, 12, h);
    }
    fill(178, 140, 84);
    rect(-w / 2, -h / 2, w, 4);                         // highlight
  }

  void drawContainer() {
    fill(160, 58, 52);
    rect(-w / 2, -h / 2, w, h, 3);
    fill(184, 74, 66);
    rect(-w / 2, -h / 2, w, h * 0.30, 3);               // lit top face
    fill(132, 44, 40);
    for (float i = -w / 2 + 8; i < w / 2 - 4; i += 11) { // corrugation
      rect(i, -h / 2 + 5, 4, h - 10);
    }
    fill(96, 30, 28);                                   // corner castings
    rect(-w / 2, -h / 2, 11, 11);
    rect(w / 2 - 11, -h / 2, 11, 11);
    rect(-w / 2, h / 2 - 11, 11, 11);
    rect(w / 2 - 11, h / 2 - 11, 11, 11);
    fill(220, 210, 196);                                // stencilled marking
    rect(-w * 0.20, -3, w * 0.40, 6);
  }
}
