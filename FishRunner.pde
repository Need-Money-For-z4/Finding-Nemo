int gameState = 1;          // 0 = ready, 1 = playing, 2 = game over
float floorY;               // y of the ocean floor
float speed;                // scroll speed
int   score, highScore = 0;
float spawnTimer;

Fish fish;
ArrayList<Obstacle> obstacles;
ArrayList<Bubble>   bubbles;

void setup() {
  size(820, 360);
  floorY = height - 55;
  textFont(createFont("Arial", 18, true));
  bubbles = new ArrayList<Bubble>();
  for (int i = 0; i < 25; i++) bubbles.add(new Bubble());
  resetGame();
}

void resetGame() {
  fish = new Fish();
  obstacles = new ArrayList<Obstacle>();
  speed = 6.0;
  score = 0;
  spawnTimer = 60;
}

void startGame() {
  resetGame();
  gameState = 1;
}

void draw() {
  drawOcean();

  // background bubbles always drift up
  for (Bubble b : bubbles) { b.update(); b.display(); }

  drawFloor();

  if (gameState == 1) {
    // ---- advance the world ----
    score++;
    if (score % 120 == 0 && speed < 13) speed += 0.4;   // ramp difficulty

    spawnTimer -= 1;
    if (spawnTimer <= 0) {
      obstacles.add(new Obstacle());
      spawnTimer = random(70, 120);
    }

    fish.update();

    for (int i = obstacles.size() - 1; i >= 0; i--) {
      Obstacle o = obstacles.get(i);
      o.update();
      if (o.hits(fish)) {
        gameState = 2;
        highScore = max(highScore, score);
      }
      if (o.offscreen()) obstacles.remove(i);
    }
  }

  for (Obstacle o : obstacles) o.display();
  fish.display();

  drawHUD();
}

// -------------------------------------------------------------------
//  INPUT
// -------------------------------------------------------------------
void keyPressed() {
  if (key == ' ' || (key == CODED && keyCode == UP)) {
    if (gameState == 1) fish.jump();
    else startGame();
  }
  if (key == CODED && keyCode == DOWN && gameState == 1) {
    fish.ducking = true;
  }
}

void keyReleased() {
  if (key == CODED && keyCode == DOWN) fish.ducking = false;
}

// ===================================================================
//  FISH
// ===================================================================
class Fish {
  float x = 110, y, vy = 0;
  boolean ducking = false, onFloor = true;

  Fish() { y = floorY - 15; }

  float halfH() { return ducking ? 10 : 15; }
  float halfW() { return ducking ? 24 : 21; }

  void jump() {
    if (onFloor && !ducking) { vy = -15; onFloor = false; }
  }

  void update() {
    y += vy;
    vy += 0.9;                       // gravity
    if (y + halfH() >= floorY) {     // land on the ocean floor
      y = floorY - halfH();
      vy = 0;
      onFloor = true;
    } else {
      onFloor = false;
    }
  }

  void display() {
    pushMatrix();
    translate(x, y);
    float sy = ducking ? 0.72 : 1.0;
    float sx = ducking ? 1.15 : 1.0;
    scale(sx, sy);

    float wig = sin(frameCount * 0.4) * 4;   // tail wiggle

    // tail
    fill(255, 110, 40);
    triangle(-20, 0, -36, -13 + wig, -36, 13 + wig);
    // body
    fill(255, 140, 60);
    ellipse(0, 0, 48, 30);
    // white clownfish stripes
    fill(255);
    arc(-4, 0, 34, 30, -HALF_PI, HALF_PI);
    fill(255, 140, 60);
    ellipse(-4, 0, 6, 30);
    // top fin
    fill(255, 110, 40);
    triangle(2, -14, 14, -22, 16, -12);
    // pectoral fin
    triangle(6, 6, 2, 18, 16, 12);
    // eye
    fill(255); ellipse(15, -5, 9, 9);
    fill(0);   ellipse(16, -5, 4, 4);
    popMatrix();
  }
}

// ===================================================================
//  OBSTACLES  (type 0 = coral -> jump ; type 1 = jellyfish -> duck)
// ===================================================================
class Obstacle {
  float x, w, h, topY;
  int type;

  Obstacle() {
    x = width + 20;
    type = (random(1) < 0.65) ? 0 : 1;      // coral more common
    if (type == 0) {                        // coral on the floor
      w = random(22, 34);
      h = random(34, 58);
      topY = floorY - h;
    } else {                                // jellyfish floats high
      w = 34;
      h = 26;
      topY = floorY - 24 - h;               // forces a duck
    }
  }

  void update() { x -= speed; }
  boolean offscreen() { return x + w < -10; }

  boolean hits(Fish f) {
    float fl = f.x - f.halfW(), fr = f.x + f.halfW();
    float ft = f.y - f.halfH(), fb = f.y + f.halfH();
    return fr > x && fl < x + w && fb > topY && ft < topY + h;
  }

  void display() {
    if (type == 0) drawCoral();
    else drawJelly();
  }

  void drawCoral() {
    noStroke();
    fill(90, 180, 120);                     // seaweed green
    pushMatrix();
    translate(x + w / 2, floorY);
    float sway = sin(frameCount * 0.05 + x) * 4;
    beginShape();
    vertex(-w / 2, 0);
    bezierVertex(-w / 2 + sway, -h * 0.5, -w / 4 + sway, -h, 0, -h);
    bezierVertex(w / 4 + sway, -h, w / 2 + sway, -h * 0.5, w / 2, 0);
    endShape(CLOSE);
    fill(70, 150, 100);
    ellipse(0, -h, w * 0.6, 10);
    popMatrix();
  }

  void drawJelly() {
    pushMatrix();
    translate(x + w / 2, topY + h / 2);
    // dome
    noStroke();
    fill(230, 130, 220, 210);
    arc(0, 0, w, h * 1.6, PI, TWO_PI);
    fill(230, 130, 220, 210);
    rect(-w / 2, -1, w, 4);
    // tentacles
    stroke(230, 130, 220, 210);
    strokeWeight(3);
    for (int i = -2; i <= 2; i++) {
      float tx = i * (w / 5);
      float wig = sin(frameCount * 0.2 + i) * 3;
      line(tx, 2, tx + wig, 16);
    }
    noStroke();
    popMatrix();
  }
}

// ===================================================================
//  BACKGROUND BUBBLES
// ===================================================================
class Bubble {
  float x, y, r, sp;
  Bubble() { reset(); y = random(height); }
  void reset() {
    x = random(width); y = height + 10;
    r = random(3, 9); sp = random(0.5, 1.6);
  }
  void update() {
    y -= sp;
    x += sin(frameCount * 0.03 + y) * 0.4;
    if (y < -10) reset();
  }
  void display() {
    noFill();
    stroke(255, 255, 255, 90);
    strokeWeight(1.5);
    ellipse(x, y, r, r);
    noStroke();
  }
}

// ===================================================================
//  SCENERY + HUD
// ===================================================================
void drawOcean() {
  for (int y = 0; y < height; y++) {          // vertical gradient
    float t = map(y, 0, height, 0, 1);
    int c = lerpColor(color(40, 130, 200), color(10, 50, 110), t);
    stroke(c);
    line(0, y, width, y);
  }
  noStroke();
}

void drawFloor() {
  noStroke();
  fill(238, 214, 160);                        // sand
  rect(0, floorY, width, height - floorY);
  fill(222, 196, 140);                        // little sand mounds
  for (int i = 0; i < width; i += 60) {
    float off = (i - (frameCount * (gameState == 1 ? speed : 0)) % 60);
    ellipse(off, floorY + 8, 34, 14);
  }
}

void drawHUD() {
  fill(255);
  textAlign(RIGHT, TOP);
  textSize(18);
  text("SCORE " + nf(score, 5) + "    HI " + nf(highScore, 5), width - 15, 12);

  textAlign(CENTER, CENTER);
  if (gameState == 0) {
    text("FISH RUNNER", width / 2, height / 2 - 24);
    textSize(15);
    text("SPACE / UP = jump    DOWN = duck", width / 2, height / 2 + 6);
    text("press SPACE to start", width / 2, height / 2 + 30);
  } else if (gameState == 2) {
    textSize(26);
    text("GAME OVER", width / 2, height / 2 - 12);
    textSize(15);
    text("press SPACE to swim again", width / 2, height / 2 + 18);
  }
}
