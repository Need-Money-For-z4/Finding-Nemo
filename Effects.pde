// =====================================================================
//  Effects - all the short-lived visual feedback.
//
//  One class owns every particle in the game so nothing else has to
//  manage a list. Callers just say what happened -- splash, burst,
//  popup -- and this decides what it looks like.
//
//  OWNER: [effects and feedback]
// =====================================================================

// ---- a single particle -------------------------------------------------
class Particle {
  float x, y, vx, vy, size, life, maxLife, grav;
  color col;
  boolean isBubble;

  Particle(float x, float y, float vx, float vy, float size,
           float life, color col, float grav, boolean isBubble) {
    this.x = x;  this.y = y;
    this.vx = vx;  this.vy = vy;
    this.size = size;
    this.life = life;  this.maxLife = life;
    this.col = col;
    this.grav = grav;
    this.isBubble = isBubble;
  }

  void update() {
    // Particles obey dt like everything else, so slow-mo slows the spray
    // as well as the freight and the whole scene stays coherent.
    vy += grav * dt;
    vx *= pow(0.99, dt);
    x  += vx * dt;
    y  += vy * dt;
    life -= dt;

    // Airborne splash droplets die when they fall back into the sea. The
    // threshold picks out droplets specifically: bursts and sand puffs use
    // near-zero gravity and should live out their full lifespan underwater.
    if (!isBubble && grav > 0.2 && y > SURFACE_Y && vy > 0) life -= 3 * dt;
  }

  boolean done() {
    return life <= 0;
  }

  void display() {
    float a = map(life, 0, maxLife, 0, 255);
    noStroke();
    if (isBubble) {
      fill(215, 245, 255, a * 0.55);
      ellipse(x, y, size, size);
      fill(255, 255, 255, a * 0.7);
      ellipse(x - size * 0.22, y - size * 0.22, size * 0.35, size * 0.35);
    } else {
      fill(red(col), green(col), blue(col), a);
      ellipse(x, y, size, size);
    }
  }
}

// ---- an expanding ring on the water surface ----------------------------
class Ripple {
  float x, y, r, maxR, life, maxLife;

  Ripple(float x, float y, float force) {
    this.x = x;  this.y = y;
    r = 6;
    maxR = 60 * force;
    maxLife = 46;
    life = maxLife;
  }

  void update() {
    r += (maxR - r) * 0.07 * dt;
    life -= dt;
  }

  boolean done() { return life <= 0; }

  void display() {
    float a = map(life, 0, maxLife, 0, 150);
    noFill();
    stroke(235, 252, 255, a);
    strokeWeight(2);
    ellipse(x, y, r * 2, r * 0.55);
    ellipse(x, y, r * 1.35, r * 0.38);
    noStroke();
    strokeWeight(1);
  }
}

// ---- rising score / pickup text ----------------------------------------
class FloatingText {
  float x, y, life, maxLife;
  String msg;
  color col;

  FloatingText(float x, float y, String msg, color col) {
    this.x = x;  this.y = y;
    this.msg = msg;  this.col = col;
    maxLife = 62;
    life = maxLife;
  }

  void update() {
    y -= 0.85 * dt;
    life -= dt;
  }

  boolean done() { return life <= 0; }

  void display() {
    float a = map(life, 0, maxLife * 0.6, 0, 255);
    a = min(a, 255);
    textFont(fontUI);
    textSize(17);
    textAlign(CENTER, CENTER);
    fill(0, 0, 0, a * 0.45);
    text(msg, x + 1.5, y + 1.5);
    fill(red(col), green(col), blue(col), a);
    text(msg, x, y);
  }
}

// ---- the manager --------------------------------------------------------
class Effects {

  ArrayList<Particle>     particles;
  ArrayList<Ripple>       ripples;
  ArrayList<FloatingText> texts;

  Effects() {
    particles = new ArrayList<Particle>();
    ripples   = new ArrayList<Ripple>();
    texts     = new ArrayList<FloatingText>();
  }

  void clear() {
    particles.clear();
    ripples.clear();
    texts.clear();
  }

  // ---- spawners --------------------------------------------------------

  // Cargo hitting the water: a crown of droplets thrown upward plus a
  // cloud of bubbles dragged down under the surface.
  void splash(float x, float y, float force) {
    int n = int(14 * force);
    for (int i = 0; i < n; i++) {
      float ang = random(-PI * 0.85, -PI * 0.15);
      float spd = random(2.2, 7.5) * force;
      particles.add(new Particle(
        x + random(-8, 8), y,
        cos(ang) * spd, sin(ang) * spd,
        random(3, 8), random(24, 44),
        color(226, 248, 255), 0.34, false));
    }
    for (int i = 0; i < n * 0.7; i++) {
      particles.add(new Particle(
        x + random(-18, 18), y + random(4, 26),
        random(-1.1, 1.1), random(-0.9, -0.2),
        random(3, 8), random(40, 80),
        color(255), -0.012, true));
    }
  }

  void ripple(float x, float y, float force) {
    ripples.add(new Ripple(x, y, force));
  }

  // A single bubble, used for cargo trails and power-up shimmer.
  void bubble(float x, float y) {
    particles.add(new Particle(
      x, y, random(-0.25, 0.25), random(-0.9, -0.35),
      random(2.5, 6), random(45, 95),
      color(255), -0.006, true));
  }

  // Radial pop, used on damage and on power-up pickup.
  void burst(float x, float y, color col, int n) {
    for (int i = 0; i < n; i++) {
      float ang = random(TWO_PI);
      float spd = random(1.2, 5.4);
      particles.add(new Particle(
        x, y, cos(ang) * spd, sin(ang) * spd,
        random(4, 10), random(24, 50),
        col, 0.01, false));
    }
  }

  void sandPuff(float x, float y) {
    for (int i = 0; i < 12; i++) {
      particles.add(new Particle(
        x + random(-14, 14), y,
        random(-1.4, 1.4), random(-1.5, -0.2),
        random(6, 15), random(28, 52),
        color(148, 158, 150, 180), 0.018, false));
    }
  }

  void popup(float x, float y, String msg, color col) {
    texts.add(new FloatingText(x, y, msg, col));
  }

  // ---- loop -------------------------------------------------------------

  void update() {
    for (int i = particles.size() - 1; i >= 0; i--) {
      Particle p = particles.get(i);
      p.update();
      if (p.done()) particles.remove(i);
    }
    for (int i = ripples.size() - 1; i >= 0; i--) {
      Ripple rp = ripples.get(i);
      rp.update();
      if (rp.done()) ripples.remove(i);
    }
    for (int i = texts.size() - 1; i >= 0; i--) {
      FloatingText t = texts.get(i);
      t.update();
      if (t.done()) texts.remove(i);
    }
  }

  void display() {
    for (int i = 0; i < ripples.size(); i++)   ripples.get(i).display();
    for (int i = 0; i < particles.size(); i++) particles.get(i).display();
    for (int i = 0; i < texts.size(); i++)     texts.get(i).display();
  }
}
