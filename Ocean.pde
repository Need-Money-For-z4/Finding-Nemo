// =====================================================================
//  Ocean - everything that is scenery.
//
//  The expensive parts (sky gradient, water gradient, seabed, coral,
//  vignette) are drawn once into off-screen buffers at startup and then
//  blitted every frame. Only the things that actually move -- waves,
//  light shafts, kelp, bubbles -- are redrawn live. That keeps the
//  frame rate flat, which matters for a reaction game.
//
//  OWNER: [scenery and rendering]
// =====================================================================

class Ocean {

  PGraphics bgDay, bgDusk, vignette;

  float wavePhase = 0;
  float causticPhase = 0;

  float[] shaftX, shaftW, shaftSpeed;
  final int SHAFT_COUNT = 7;

  float[] bubX, bubY, bubR, bubSpeed;
  final int BUB_COUNT = 34;

  float[] kelpX, kelpH, kelpPhase;
  final int KELP_COUNT = 11;

  Ocean() {
    bgDay  = buildBackground(false);
    bgDusk = buildBackground(true);
    vignette = buildVignette();

    shaftX = new float[SHAFT_COUNT];
    shaftW = new float[SHAFT_COUNT];
    shaftSpeed = new float[SHAFT_COUNT];
    for (int i = 0; i < SHAFT_COUNT; i++) {
      shaftX[i] = random(width);
      shaftW[i] = random(34, 96);
      shaftSpeed[i] = random(0.10, 0.32);
    }

    bubX = new float[BUB_COUNT];
    bubY = new float[BUB_COUNT];
    bubR = new float[BUB_COUNT];
    bubSpeed = new float[BUB_COUNT];
    for (int i = 0; i < BUB_COUNT; i++) resetBubble(i, true);

    kelpX = new float[KELP_COUNT];
    kelpH = new float[KELP_COUNT];
    kelpPhase = new float[KELP_COUNT];
    for (int i = 0; i < KELP_COUNT; i++) {
      kelpX[i] = random(width);
      kelpH[i] = random(70, 165);
      kelpPhase[i] = random(TWO_PI);
    }
  }

  void resetBubble(int i, boolean anywhere) {
    bubX[i] = random(width);
    bubY[i] = anywhere ? random(SURFACE_Y, SEABED_Y) : random(SEABED_Y - 40, SEABED_Y);
    bubR[i] = random(2.5, 7);
    bubSpeed[i] = random(0.30, 0.95);
  }

  // ------------------------------------------------- off-screen buffers

  PGraphics buildBackground(boolean dusk) {
    PGraphics g = createGraphics(width, height);
    g.beginDraw();
    g.noStroke();

    // ---- sky, vertical gradient ----
    color skyTop = dusk ? color(38, 40, 78)  : color(126, 190, 232);
    color skyBot = dusk ? color(158, 96, 92) : color(212, 236, 246);
    for (int y = 0; y < SURFACE_Y; y++) {
      g.stroke(lerpColor(skyTop, skyBot, y / SURFACE_Y));
      g.line(0, y, width, y);
    }

    // ---- sun / moon ----
    g.noStroke();
    color orb = dusk ? color(255, 214, 180, 200) : color(255, 248, 214, 220);
    g.fill(orb);
    g.ellipse(width * 0.78, SURFACE_Y * 0.42, 62, 62);
    g.fill(red(orb), green(orb), blue(orb), 40);
    g.ellipse(width * 0.78, SURFACE_Y * 0.42, 132, 132);

    // ---- water, vertical gradient from bright shallows to a dark floor ----
    color wTop = dusk ? color(22, 66, 104) : color(52, 150, 190);
    color wMid = dusk ? color(13, 40, 74)  : color(24, 96, 148);
    color wBot = dusk ? color(5, 15, 38)   : color(8, 38, 72);
    for (float y = SURFACE_Y; y < height; y++) {
      float t = (y - SURFACE_Y) / (height - SURFACE_Y);
      color c = (t < 0.5) ? lerpColor(wTop, wMid, t * 2)
                          : lerpColor(wMid, wBot, (t - 0.5) * 2);
      g.stroke(c);
      g.line(0, y, width, y);
    }

    // ---- distant rock silhouettes ----
    g.noStroke();
    g.fill(dusk ? color(4, 12, 30) : color(10, 42, 72));
    for (int i = 0; i < 6; i++) {
      float rx = i * (width / 5.0) + random(-40, 40);
      float rw = random(140, 260);
      float rh = random(60, 130);
      g.ellipse(rx, SEABED_Y + 6, rw, rh);
    }

    // ---- seabed ----
    g.fill(dusk ? color(28, 30, 48) : color(78, 92, 96));
    g.rect(0, SEABED_Y, width, height - SEABED_Y);
    g.fill(dusk ? color(38, 40, 58) : color(102, 116, 116));
    for (float sx = -20; sx < width + 40; sx += 58) {
      g.ellipse(sx, SEABED_Y + 4, 96, 26);                // sand mounds
    }

    // ---- coral clusters ----
    for (int i = 0; i < 9; i++) {
      float cx = random(width);
      color coral = dusk ? color(46, 34, 62) : color(148, 78, 96);
      g.fill(coral);
      for (int b = 0; b < 4; b++) {
        float bx = cx + random(-18, 18);
        float by = SEABED_Y - random(4, 30);
        g.ellipse(bx, by, random(12, 26), random(16, 34));
      }
    }

    g.endDraw();
    return g;
  }

  // A soft dark frame around the edges. Built pixel by pixel once, which
  // is far cheaper than faking it with stacked shapes every frame.
  PGraphics buildVignette() {
    PGraphics g = createGraphics(width, height);
    g.beginDraw();
    g.loadPixels();
    float cx = width * 0.5, cy = height * 0.5;
    float maxD = dist(0, 0, cx, cy);
    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        float d = dist(x, y, cx, cy) / maxD;
        float a = constrain(map(d, 0.62, 1.15, 0, 165), 0, 165);
        g.pixels[y * width + x] = color(0, 6, 18, a);
      }
    }
    g.updatePixels();
    g.endDraw();
    return g;
  }

  // ------------------------------------------------------------ updates

  void update() {
    float t = dt;                // zero while paused, 0.5 under slow-mo

    wavePhase    += 0.035 * t;
    causticPhase += 0.021 * t;

    for (int i = 0; i < SHAFT_COUNT; i++) {
      shaftX[i] += shaftSpeed[i] * t;
      if (shaftX[i] > width + 120) shaftX[i] = -120;
    }

    for (int i = 0; i < BUB_COUNT; i++) {
      bubY[i] -= bubSpeed[i] * t;
      bubX[i] += sin((frameCount * 0.02) + i) * 0.25 * t;
      if (bubY[i] < SURFACE_Y - 6) resetBubble(i, false);
    }
  }

  // ------------------------------------------------------------ drawing

  void display() {
    image(bgDay, 0, 0);

    // Crossfade toward the dusk palette as the run goes on, then back
    // again -- a slow day/night cycle that marks progress without ever
    // changing the rules.
    float k = (sin(runTime * 0.055 - HALF_PI) + 1) * 0.5;
    if (k > 0.01) {
      tint(255, k * 255);
      image(bgDusk, 0, 0);
      noTint();
    }

    drawLightShafts();
    drawSurface();
    drawKelp();
    drawBubbles();
  }

  // Drawn after the entities so it sits in front of everything.
  void displayForeground() {
    image(vignette, 0, 0);
  }

  void drawLightShafts() {
    noStroke();
    for (int i = 0; i < SHAFT_COUNT; i++) {
      float sway = sin(causticPhase + i) * 22;
      float w1 = shaftW[i];
      fill(190, 235, 255, 15);
      quad(shaftX[i], SURFACE_Y,
           shaftX[i] + w1, SURFACE_Y,
           shaftX[i] + w1 * 2.1 + sway, SEABED_Y,
           shaftX[i] - w1 * 0.5 + sway, SEABED_Y);
    }
  }

  void drawSurface() {
    noStroke();

    // The waterline itself, as a run of small quads following a sine.
    fill(180, 226, 244, 210);
    float step = 12;
    for (float x = 0; x <= width; x += step) {
      float y1 = SURFACE_Y + sin(wavePhase + x * 0.017) * 5;
      float y2 = SURFACE_Y + sin(wavePhase + (x + step) * 0.017) * 5;
      quad(x, y1, x + step, y2, x + step, y2 + 7, x, y1 + 7);
    }

    // Bright caustic flecks just under the surface.
    fill(235, 252, 255, 90);
    for (float x = 0; x < width; x += 34) {
      float o = sin(causticPhase * 2.2 + x * 0.05) * 9;
      float wdt = 12 + sin(causticPhase * 1.5 + x * 0.03) * 7;
      rect(x + o, SURFACE_Y + 12 + sin(causticPhase + x * 0.04) * 4, wdt, 3, 2);
    }
  }

  void drawKelp() {
    noFill();
    strokeWeight(6);
    for (int i = 0; i < KELP_COUNT; i++) {
      stroke(26, 92, 76, 165);
      float segs = 7;
      float px = kelpX[i], py = SEABED_Y;
      beginShape();
      curveVertex(px, py);
      for (int s = 0; s <= segs; s++) {
        float f = s / segs;
        float sx = kelpX[i] + sin(causticPhase * 1.6 + kelpPhase[i] + f * 2.4) * (16 * f);
        float sy = SEABED_Y - kelpH[i] * f;
        curveVertex(sx, sy);
      }
      endShape();
    }
    strokeWeight(1);
    noStroke();
  }

  void drawBubbles() {
    noStroke();
    for (int i = 0; i < BUB_COUNT; i++) {
      fill(210, 240, 255, 60);
      ellipse(bubX[i], bubY[i], bubR[i] * 2, bubR[i] * 2);
      fill(255, 255, 255, 90);
      ellipse(bubX[i] - bubR[i] * 0.3, bubY[i] - bubR[i] * 0.3, bubR[i] * 0.7, bubR[i] * 0.7);
    }
  }
}
