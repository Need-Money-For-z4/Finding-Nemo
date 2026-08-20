// =====================================================================
//  Screens - every full-screen overlay.
//
//  Kept out of the main file so the game loop stays readable and so one
//  person can work on presentation without touching gameplay code.
//
//  OWNER: [interface]
// =====================================================================

// A dark wash behind overlay text, so UI stays legible over the ocean.
void dimBackdrop(float alpha) {
  noStroke();
  fill(4, 12, 28, alpha);
  rect(0, 0, width, height);
}

// A soft rounded panel to sit UI on.
void panel(float cx, float cy, float w, float h) {
  noStroke();
  fill(8, 22, 44, 205);
  rect(cx - w / 2, cy - h / 2, w, h, 18);
  fill(255, 255, 255, 18);
  rect(cx - w / 2, cy - h / 2, w, 3, 18);
}

// ------------------------------------------------------------- title

void drawTitleScreen() {
  dimBackdrop(120);

  float cx = width / 2;

  textAlign(CENTER, CENTER);
  textFont(fontBig);
  textSize(78);
  fill(0, 20, 40, 160);
  text("OVERBOARD", cx + 3, 165 + 3);
  fill(255, 236, 210);
  text("OVERBOARD", cx, 165);

  textFont(fontUI);
  textSize(17);
  fill(170, 216, 240, 225);
  text("The cargo is coming down. You are the fish.", cx, 224);

  // ---- controls panel ----
  panel(cx, 350, 470, 168);

  textSize(13);
  fill(150, 196, 220, 200);
  text("C O N T R O L S", cx, 292);

  textAlign(LEFT, CENTER);
  textFont(fontNum);
  textSize(16);
  fill(232, 244, 252);
  text("ARROWS / WASD", cx - 190, 326);
  text("SPACE", cx - 190, 356);
  text("P", cx - 190, 386);
  text("L", cx - 190, 414);

  textFont(fontUI);
  textSize(14);
  fill(178, 212, 232, 210);
  text("swim",              cx + 20, 326);
  text("start",             cx + 20, 356);
  text("pause",             cx + 20, 386);
  text("leaderboard",       cx + 20, 414);

  // ---- power-up legend ----
  textAlign(CENTER, CENTER);
  textSize(13);
  fill(150, 196, 220, 200);
  text("P O W E R - U P S", cx, 470);

  drawLegendOrb(cx - 170, 508, color(255, 96, 116), "EXTRA LIFE");
  drawLegendOrb(cx,       508, color(120, 210, 255), "SLOW-MO 0.5x");
  drawLegendOrb(cx + 170, 508, color(255, 206, 84),  "2x POINTS");

  // ---- prompt ----
  textSize(19);
  float pulse = 170 + sin(frameCount * 0.09) * 85;
  fill(255, 236, 210, pulse);
  text("PRESS SPACE TO DIVE IN", cx, 580);
}

void drawLegendOrb(float x, float y, color c, String label) {
  noStroke();
  for (int i = 3; i >= 1; i--) {
    fill(red(c), green(c), blue(c), 14 * i);
    ellipse(x, y - 12, 30 + i * 7, 30 + i * 7);
  }
  fill(c);
  ellipse(x, y - 12, 26, 26);
  fill(255, 255, 255, 90);
  ellipse(x - 4, y - 16, 9, 7);

  textAlign(CENTER, CENTER);
  textFont(fontUI);
  textSize(11);
  fill(200, 226, 242, 210);
  text(label, x, y + 14);
}

// ------------------------------------------------------------- pause

void drawPauseScreen() {
  dimBackdrop(155);
  float cx = width / 2;

  textAlign(CENTER, CENTER);
  textFont(fontBig);
  textSize(52);
  fill(255, 236, 210);
  text("PAUSED", cx, height / 2 - 30);

  textFont(fontUI);
  textSize(16);
  fill(180, 216, 238, 220);
  text("P or SPACE to resume        Q to quit to title", cx, height / 2 + 26);
}

// -------------------------------------------------------- name entry

void drawNameEntryScreen() {
  dimBackdrop(190);
  float cx = width / 2;

  textAlign(CENTER, CENTER);
  textFont(fontUI);
  textSize(15);
  fill(150, 196, 220, 210);
  text("Y O U   M A D E   T H E   B O A R D", cx, 168);

  textFont(fontBig);
  textSize(70);
  fill(255, 206, 84);
  text(nf(board.pendingScore, 6), cx, 236);

  textFont(fontUI);
  textSize(20);
  fill(200, 230, 246);
  text(board.rankTitle(board.pendingScore), cx, 292);

  textSize(14);
  fill(150, 196, 220, 200);
  text("ENTER YOUR INITIALS", cx, 350);

  // Three character slots.
  for (int i = 0; i < 3; i++) {
    float bx = cx - 92 + i * 92;
    boolean active = (i == board.pendingName.length());

    noStroke();
    fill(255, 255, 255, active ? 34 : 16);
    rect(bx - 34, 372, 68, 78, 10);

    if (active) {
      // Underscore cursor blinking in the next empty slot.
      fill(255, 206, 84, 120 + sin(frameCount * 0.2) * 100);
      rect(bx - 20, 434, 40, 4, 2);
    }

    if (i < board.pendingName.length()) {
      textFont(fontNum);
      textSize(46);
      fill(255, 236, 210);
      text(str(board.pendingName.charAt(i)), bx, 410);
    }
  }

  textFont(fontUI);
  textSize(14);
  fill(170, 210, 234, 200);
  text("type A-Z or 0-9        BACKSPACE to delete        ENTER to confirm",
       cx, 486);
}

// --------------------------------------------------------- game over

void drawGameOverScreen() {
  dimBackdrop(185);
  float cx = width / 2;

  textAlign(CENTER, CENTER);
  textFont(fontBig);
  textSize(58);
  fill(0, 20, 40, 160);
  text("GAME OVER", cx + 3, 76 + 3);
  fill(255, 236, 210);
  text("GAME OVER", cx, 76);

  // ---- run summary ----
  textFont(fontUI);
  textSize(13);
  fill(150, 196, 220, 200);
  text("SCORE", cx - 150, 136);
  text("SURVIVED", cx + 150, 136);

  textFont(fontNum);
  textSize(34);
  fill(255, 206, 84);
  text(nf(int(score), 6), cx - 150, 166);
  fill(200, 230, 246);
  text(nf(int(runTime), 3) + "s", cx + 150, 166);

  textFont(fontUI);
  textSize(19);
  fill(232, 244, 252);
  text("RANK: " + board.rankTitle(int(score)), cx, 208);

  // Distance to the next rank, so there is a concrete reason to try again.
  int gate = board.nextRankAt(int(score));
  if (gate > 0) {
    textSize(13);
    fill(160, 200, 224, 190);
    text((gate - int(score)) + " more for " + board.rankTitle(gate), cx, 234);
  }

  board.drawTable(cx, 296, 30);

  textSize(17);
  float pulse = 170 + sin(frameCount * 0.09) * 85;
  fill(255, 236, 210, pulse);
  text("SPACE to swim again        L for the full board", cx, height - 34);
}

// -------------------------------------------------------- leaderboard

void drawBoardScreen() {
  dimBackdrop(200);
  float cx = width / 2;

  textAlign(CENTER, CENTER);
  textFont(fontBig);
  textSize(48);
  fill(255, 236, 210);
  text("LEADERBOARD", cx, 92);

  textFont(fontUI);
  textSize(14);
  fill(150, 196, 220, 200);
  text("saved to leaderboard.csv beside the sketch", cx, 138);

  board.drawTable(cx, 208, 36);

  textSize(17);
  float pulse = 170 + sin(frameCount * 0.09) * 85;
  fill(255, 236, 210, pulse);
  text("SPACE to go back", cx, height - 40);
}
