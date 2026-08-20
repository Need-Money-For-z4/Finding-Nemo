// =====================================================================
//  CargoManager - owns every falling hazard.
//
//  Cargo is never spawned at a random screen position. It is always
//  released from the plane's open ramp, so the player can read the
//  plane's path and predict where the next wave will land. That link
//  between cause and hazard is what makes the game feel fair.
//
//  OWNER: [spawning, collision, scoring bonuses]
// =====================================================================

class CargoManager {

  ArrayList<Cargo> list;
  float dropTimer;               // counts down to the next release
  int   burstLeft = 0;           // pieces still to drop in a rapid burst

  CargoManager() {
    list = new ArrayList<Cargo>();
    reset();
  }

  void reset() {
    list.clear();
    dropTimer = 90;              // a calm run-up before the first drop
    burstLeft = 0;
  }

  void update() {
    // ---- move and retire ----
    for (int i = list.size() - 1; i >= 0; i--) {
      Cargo c = list.get(i);
      c.update();
      if (c.finished) list.remove(i);
    }

    // ---- release new cargo ----
    // Only while the plane is actually over the water, so freight never
    // appears out of empty sky.
    if (plane.overWater()) {
      dropTimer -= dt;
      if (dropTimer <= 0) {
        release();
        dropTimer = nextInterval();
      }
    }
  }

  // The interval shrinks as the game speeds up, which is the main lever
  // on difficulty. The random spread stops the drops falling into a
  // rhythm the player can memorise.
  float nextInterval() {
    if (burstLeft > 0) {
      burstLeft--;
      return 11 + random(4);     // rapid-fire carpet drop
    }
    float base = 76 / gameSpeed;
    // Once things are moving, occasionally commit to a carpet drop.
    if (gameSpeed > 1.35 && random(1) < 0.13) {
      burstLeft = int(random(2, 5));
    }
    return base + random(-14, 26);
  }

  void release() {
    float px = plane.rampX();
    float py = plane.rampY();

    int kind = pickKind();
    // Cargo inherits the plane's forward momentum, so it arcs rather than
    // dropping straight down. Physically right, and it means the player
    // must lead the plane rather than sit under it.
    Cargo c = new Cargo(kind, px, py, plane.vx * 0.55);
    list.add(c);

    plane.kick();                // visual recoil on the ramp
  }

  // Weighted pick. Big pieces stay rare, and the container only shows up
  // once the player has had time to learn the basics.
  int pickKind() {
    float roll = random(1);
    if (gameSpeed < 1.15) {
      return (roll < 0.45) ? C_SUITCASE : C_CRATE;
    }
    if (roll < 0.26) return C_SUITCASE;
    if (roll < 0.58) return C_CRATE;
    if (roll < 0.79) return C_BARREL;
    if (roll < 0.93) return C_PALLET;
    return C_CONTAINER;
  }

  // -------------------------------------------------------- collisions

  void checkCollisions() {
    if (fish.dead) return;

    for (int i = list.size() - 1; i >= 0; i--) {
      Cargo c = list.get(i);

      if (!fish.invulnerable() && c.hits(fish)) {
        list.remove(i);
        damageFish();
        return;                  // one hit per frame, never a double death
      }

      // ---- near-miss bonus ----
      // Squeezing past a piece is worth points. It rewards the risky line
      // over hiding in a corner, which is what stops the game going stale.
      if (!c.scored && c.submerged && c.y > fish.y + 12) {
        float gap = c.clearance(fish);
        if (gap < 26 && abs(c.x - fish.x) < c.w * 0.9) {
          c.scored = true;
          int bonus = int(50 * powerups.pointMultiplier());
          score += bonus;
          fx.popup(fish.x, fish.y - 34, "CLOSE! +" + bonus, color(140, 240, 255));
        } else if (gap > 90) {
          c.scored = true;       // clearly missed; stop testing it
        }
      }
    }
  }

  void display() {
    for (int i = 0; i < list.size(); i++) list.get(i).display();
  }

  int count() {
    return list.size();
  }
}
