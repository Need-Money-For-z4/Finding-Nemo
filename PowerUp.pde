// =====================================================================
//  PowerUp - a collectable bubble drifting in the water column.
//
//  Three kinds:
//    PU_LIFE    +1 life, up to the cap
//    PU_SLOW    the whole world runs at half speed for a while
//    PU_DOUBLE  every point is worth two for a while
//
//  Each one has a limited lifespan and fades out near the end, so the
//  player has to decide whether the detour is worth the risk.
//
//  OWNER: [power-ups]
// =====================================================================

class PowerUp {

  int   kind;
  float x, y;
  float vx, vy;
  float r = 21;
  float life;                    // frames remaining before it pops
  float phase;                   // bob / pulse offset, so they don't sync
  boolean collected = false;

  PowerUp(int kind, float x, float y) {
    this.kind = kind;
    this.x    = x;
    this.y    = y;
    vx    = random(-0.5, 0.5);
    vy    = random(-0.30, -0.12);   // buoyant, drifts gently upward
    life  = 720;                    // twelve seconds at 60fps
    phase = random(TWO_PI);
  }

  void update() {
    x += vx * dt;
    y += (vy + sin(frameCount * 0.03 + phase) * 0.28) * dt;

    // Bounce off the edges of the water so it stays reachable.
    if (x < r || x > width - r) vx *= -1;
    y = constrain(y, SURFACE_Y + 30, SEABED_Y - 26);

    life -= dt;
    if (life <= 0) {
      collected = true;                       // treated as gone
      fx.burst(x, y, tint(), 10);
    }

    if (frameCount % 12 == 0) fx.bubble(x + random(-8, 8), y - 6);
  }

  boolean touches(Fish f) {
    return dist(x, y, f.x, f.y) < r + f.r;
  }

  // Each type gets its own colour, used by the orb, the pickup burst and
  // the HUD timer bar, so the player learns one colour per ability.
  color tint() {
    if (kind == PU_LIFE) return color(255, 96, 116);
    if (kind == PU_SLOW) return color(120, 210, 255);
    return color(255, 206, 84);
  }

  String label() {
    if (kind == PU_LIFE) return "EXTRA LIFE";
    if (kind == PU_SLOW) return "SLOW-MO";
    return "DOUBLE POINTS";
  }

  void display() {
    // Blink out over the final second and a half.
    float a = (life < 90) ? map(life, 0, 90, 0, 255) : 255;
    if (life < 90 && (frameCount / 5) % 2 == 0) a *= 0.35;

    float pulse = 1 + sin(frameCount * 0.09 + phase) * 0.07;
    color c = tint();

    pushMatrix();
    translate(x, y);
    scale(pulse);
    noStroke();

    // Soft outer glow, built from a few stacked translucent discs.
    for (int i = 3; i >= 1; i--) {
      fill(red(c), green(c), blue(c), a * 0.10 * i);
      ellipse(0, 0, r * (2.5 + i * 0.45), r * (2.5 + i * 0.45));
    }

    // Bubble shell.
    fill(red(c), green(c), blue(c), a * 0.88);
    ellipse(0, 0, r * 2, r * 2);
    fill(255, 255, 255, a * 0.30);
    ellipse(0, 0, r * 1.55, r * 1.55);
    fill(255, 255, 255, a * 0.55);
    ellipse(-r * 0.32, -r * 0.34, r * 0.42, r * 0.32);   // specular highlight

    drawIcon(a);
    popMatrix();
  }

  void drawIcon(float a) {
    fill(255, 255, 255, a);
    noStroke();

    if (kind == PU_LIFE) {
      // Heart, drawn from two discs and a triangle.
      ellipse(-4.6, -3, 11, 11);
      ellipse( 4.6, -3, 11, 11);
      triangle(-9.6, 0.4, 9.6, 0.4, 0, 12);

    } else if (kind == PU_SLOW) {
      // Hourglass.
      triangle(-9, -10, 9, -10, 0, 0);
      triangle(-9,  10, 9,  10, 0, 0);
      rect(-10, -13, 20, 3.5, 1);
      rect(-10,  9.5, 20, 3.5, 1);

    } else {
      // A literal "x2".
      textAlign(CENTER, CENTER);
      textFont(fontUI);
      textSize(20);
      fill(255, 255, 255, a);
      text("x2", 0, -1);
    }
  }
}
