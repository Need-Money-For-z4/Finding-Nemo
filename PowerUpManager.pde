// =====================================================================
//  PowerUpManager - spawns collectables and runs the active timers.
//
//  This class owns the two timed effects. Nothing else in the game
//  touches timeScale or the point multiplier directly; they ask here.
//  One owner for each piece of state keeps the effects from fighting
//  each other when both are running at once.
//
//  OWNER: [power-ups]
// =====================================================================

class PowerUpManager {

  ArrayList<PowerUp> list;
  float spawnTimer;

  float slowTimer   = 0;         // frames of slow-mo remaining
  float doubleTimer = 0;         // frames of 2x points remaining

  final float SLOW_DURATION   = 420;    // 7 seconds
  final float DOUBLE_DURATION = 600;    // 10 seconds

  PowerUpManager() {
    list = new ArrayList<PowerUp>();
    reset();
  }

  void reset() {
    list.clear();
    spawnTimer  = 480;           // first one arrives around 8 seconds in
    slowTimer   = 0;
    doubleTimer = 0;
    timeScale   = 1.0;
  }

  void update() {
    // ---- tick the active effects -------------------------------------
    // Timers count down in real frames, not scaled time, otherwise slow-mo
    // would extend its own duration and never end.
    if (slowTimer   > 0) slowTimer--;
    if (doubleTimer > 0) doubleTimer--;
    timeScale = (slowTimer > 0) ? 0.5 : 1.0;

    // ---- move the orbs ------------------------------------------------
    for (int i = list.size() - 1; i >= 0; i--) {
      PowerUp p = list.get(i);
      p.update();
      if (p.collected) list.remove(i);
    }

    // ---- spawn ---------------------------------------------------------
    spawnTimer -= dt;
    if (spawnTimer <= 0) {
      spawn();
      spawnTimer = random(560, 900);
    }
  }

  void spawn() {
    // Never let more than two sit on screen; the arena gets crowded enough
    // with freight falling through it.
    if (list.size() >= 2) return;

    int kind = pickKind();

    // Spawn away from the fish, so an orb is something you have to swim
    // for rather than something that lands in your lap.
    float px, py;
    int guard = 0;
    do {
      px = random(70, width - 70);
      py = random(SURFACE_Y + 70, SEABED_Y - 60);
      guard++;
    } while (dist(px, py, fish.x, fish.y) < 220 && guard < 24);

    list.add(new PowerUp(kind, px, py));
  }

  // Extra lives get rarer the more you are carrying, so a full stack of
  // hearts does not keep hogging the spawn slots.
  int pickKind() {
    float lifeWeight = (lives >= MAX_LIVES) ? 0 : map(lives, 1, MAX_LIVES, 0.42, 0.12);
    float roll = random(1);
    if (roll < lifeWeight)        return PU_LIFE;
    if (roll < lifeWeight + 0.42) return PU_DOUBLE;
    return PU_SLOW;
  }

  void checkPickups() {
    if (fish.dead) return;

    for (int i = list.size() - 1; i >= 0; i--) {
      PowerUp p = list.get(i);
      if (p.touches(fish)) {
        apply(p);
        list.remove(i);
      }
    }
  }

  void apply(PowerUp p) {
    fx.burst(p.x, p.y, p.tint(), 20);
    fx.popup(p.x, p.y - 30, p.label(), p.tint());

    if (p.kind == PU_LIFE) {
      // At the cap, convert the pickup into points instead of wasting it.
      if (lives < MAX_LIVES) {
        lives++;
      } else {
        score += 500;
        fx.popup(p.x, p.y - 54, "+500", color(255, 220, 140));
      }

    } else if (p.kind == PU_SLOW) {
      // Re-collecting refreshes the timer rather than stacking it, so the
      // player cannot bank an unbroken minute of slow motion.
      slowTimer = SLOW_DURATION;

    } else {
      doubleTimer = DOUBLE_DURATION;
    }
  }

  // ---- queried by the scoring code and the HUD -------------------------

  float pointMultiplier() {
    return (doubleTimer > 0) ? 2.0 : 1.0;
  }

  boolean slowActive()   { return slowTimer   > 0; }
  boolean doubleActive() { return doubleTimer > 0; }

  float slowFraction()   { return slowTimer   / SLOW_DURATION;   }
  float doubleFraction() { return doubleTimer / DOUBLE_DURATION; }

  void display() {
    for (int i = 0; i < list.size(); i++) list.get(i).display();
  }
}
