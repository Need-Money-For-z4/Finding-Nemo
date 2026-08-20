// =====================================================================
//  HUD - the in-game overlay.
//
//  Kept to the top strip and one corner, because the middle of the
//  screen is where the player is trying to read falling cargo. Anything
//  drawn there would be actively harmful.
//
//  OWNER: [interface]
// =====================================================================

class HUD {

  void display() {
    drawScore();
    drawLives();
    drawPowerBars();
    if (powerups.slowActive()) drawSlowVignette();
  }

  // ---- score and rank, top right ---------------------------------------
  void drawScore() {
    textAlign(RIGHT, TOP);

    textFont(fontNum);
    textSize(38);
    // Shadow first, so the number stays readable over bright caustics.
    fill(0, 20, 40, 130);
    text(nf(int(score), 6), width - 22, 20);
    fill(powerups.doubleActive() ? color(255, 206, 84) : color(255));
    text(nf(int(score), 6), width - 24, 18);

    textFont(fontUI);
    textSize(14);
    fill(190, 226, 244, 220);
    text(board.rankTitle(int(score)), width - 24, 62);

    // Session best, so there is always a target on screen.
    if (board.topScore() > 0) {
      textSize(13);
      fill(160, 200, 224, 180);
      text("BEST " + nf(board.topScore(), 6), width - 24, 84);
    }
  }

  // ---- lives, top left --------------------------------------------------
  void drawLives() {
    float x = 26, y = 30;
    for (int i = 0; i < MAX_LIVES; i++) {
      boolean filled = i < lives;
      pushMatrix();
      translate(x + i * 30, y);
      scale(0.85);
      noStroke();
      if (filled) {
        fill(0, 20, 40, 110);
        drawHeart(1.5, 2.5);
        fill(255, 96, 116);
        drawHeart(0, 0);
      } else {
        fill(255, 255, 255, 42);
        drawHeart(0, 0);
      }
      popMatrix();
    }

    textAlign(LEFT, TOP);
    textFont(fontUI);
    textSize(12);
    fill(190, 226, 244, 170);
    text("TIME  " + nf(int(runTime), 3) + "s", 22, 52);
  }

  void drawHeart(float ox, float oy) {
    ellipse(ox - 5, oy - 3, 12, 12);
    ellipse(ox + 5, oy - 3, 12, 12);
    triangle(ox - 10.5, oy + 0.5, ox + 10.5, oy + 0.5, ox, oy + 13);
  }

  // ---- active power-up timers, bottom left -------------------------------
  void drawPowerBars() {
    float y = height - 46;
    if (powerups.slowActive()) {
      drawBar(24, y, powerups.slowFraction(), color(120, 210, 255), "SLOW-MO");
      y -= 30;
    }
    if (powerups.doubleActive()) {
      drawBar(24, y, powerups.doubleFraction(), color(255, 206, 84), "2x POINTS");
    }
  }

  void drawBar(float x, float y, float frac, color c, String label) {
    float w = 168, h = 9;

    noStroke();
    fill(0, 20, 40, 120);
    rect(x - 2, y - 2, w + 4, h + 4, 6);
    fill(255, 255, 255, 34);
    rect(x, y, w, h, 5);

    // The bar drains, and pulses once it is nearly out as a warning.
    float a = (frac < 0.25 && (frameCount / 6) % 2 == 0) ? 120 : 255;
    fill(red(c), green(c), blue(c), a);
    rect(x, y, w * constrain(frac, 0, 1), h, 5);

    textAlign(LEFT, BOTTOM);
    textFont(fontUI);
    textSize(12);
    fill(red(c), green(c), blue(c), 235);
    text(label, x, y - 4);
  }

  // A cool blue tint around the edges while time is slowed, so the effect
  // is felt even when the player is not looking at the timer bar.
  void drawSlowVignette() {
    noStroke();
    for (int i = 0; i < 4; i++) {
      fill(120, 210, 255, 12);
      rect(i * 5, i * 5, width - i * 10, height - i * 10, 18);
    }
  }
}
