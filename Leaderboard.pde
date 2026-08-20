// =====================================================================
//  Leaderboard - persistent top ten, plus the rank titles.
//
//  Scores are written to a plain CSV next to the sketch, so the board
//  survives closing Processing. Anyone who runs the sketch on the same
//  machine plays against the same board -- that is the "challenge your
//  friends" loop.
//
//  OWNER: [persistence and progression]
// =====================================================================

// One row of the board.
class ScoreEntry {
  String name;
  int    points;
  String rank;

  ScoreEntry(String name, int points, String rank) {
    this.name   = name;
    this.points = points;
    this.rank   = rank;
  }
}

class Leaderboard {

  ArrayList<ScoreEntry> entries;

  final int    BOARD_SIZE = 10;
  final String FILENAME   = "leaderboard.csv";

  String  pendingName  = "";     // initials being typed right now
  int     pendingScore = 0;
  int     highlightRow = -1;     // row to flash after a new entry lands
  boolean saveFailed   = false;  // true if the folder is read-only

  Leaderboard() {
    entries = new ArrayList<ScoreEntry>();
  }

  // ------------------------------------------------------------ ranks

  // Rank is derived purely from score, so it is consistent everywhere it
  // is shown: the HUD, the game-over screen and the board itself.
  String rankTitle(int s) {
    if (s >= 22000) return "LEVIATHAN";
    if (s >= 15000) return "MARLIN";
    if (s >= 10000) return "BARRACUDA";
    if (s >=  6500) return "REEF RUNNER";
    if (s >=  3500) return "SNAPPER";
    if (s >=  1500) return "GUPPY";
    return "MINNOW";
  }

  int nextRankAt(int s) {
    int[] gates = { 1500, 3500, 6500, 10000, 15000, 22000 };
    for (int g : gates) if (s < g) return g;
    return -1;                   // already at the top rank
  }

  // ------------------------------------------------- load / save / seed

  void load() {
    entries.clear();

    String path = sketchPath(FILENAME);
    File   f    = new File(path);

    if (f.exists()) {
      String[] lines = loadStrings(path);
      if (lines != null) {
        for (String line : lines) {
          if (line == null || line.trim().length() == 0) continue;
          String[] parts = split(line.trim(), ',');
          // Skip any malformed row rather than letting one bad line take
          // the whole board down.
          if (parts.length < 2) continue;
          try {
            String nm = parts[0].trim();
            int    sc = int(parts[1].trim());
            entries.add(new ScoreEntry(nm, sc, rankTitle(sc)));
          } catch (Exception e) {
            println("Skipped bad leaderboard row: " + line);
          }
        }
      }
    }

    if (entries.size() == 0) seed();
    sortAndTrim();
  }

  // A few starting targets, so a first-time player has something to beat
  // instead of an empty table.
  void seed() {
    entries.add(new ScoreEntry("ACE", 9200, rankTitle(9200)));
    entries.add(new ScoreEntry("FIN", 6800, rankTitle(6800)));
    entries.add(new ScoreEntry("GIL", 4400, rankTitle(4400)));
    entries.add(new ScoreEntry("RAY", 2600, rankTitle(2600)));
    entries.add(new ScoreEntry("JET", 1200, rankTitle(1200)));
  }

  void save() {
    String[] out = new String[entries.size()];
    for (int i = 0; i < entries.size(); i++) {
      ScoreEntry e = entries.get(i);
      out[i] = e.name + "," + e.points;
    }
    try {
      saveStrings(sketchPath(FILENAME), out);
      saveFailed = false;
    } catch (Exception e) {
      // A read-only sketch folder should not crash the game; the board
      // just becomes session-only and the UI says so.
      saveFailed = true;
      println("Could not write leaderboard: " + e.getMessage());
    }
  }

  void sortAndTrim() {
    // Simple insertion sort. The list is at most ten long, so anything
    // cleverer would be harder to read for no measurable gain.
    for (int i = 1; i < entries.size(); i++) {
      ScoreEntry key = entries.get(i);
      int j = i - 1;
      while (j >= 0 && entries.get(j).points < key.points) {
        entries.set(j + 1, entries.get(j));
        j--;
      }
      entries.set(j + 1, key);
    }
    while (entries.size() > BOARD_SIZE) entries.remove(entries.size() - 1);
  }

  // --------------------------------------------------------- queries

  boolean qualifies(int s) {
    if (s <= 0) return false;
    if (entries.size() < BOARD_SIZE) return true;
    return s > entries.get(entries.size() - 1).points;
  }

  int topScore() {
    return (entries.size() > 0) ? entries.get(0).points : 0;
  }

  // ---------------------------------------------------- initials entry

  void beginEntry(int s) {
    pendingScore = s;
    pendingName  = "";
    highlightRow = -1;
  }

  void handleEntryKey(char k) {
    if (k == BACKSPACE || k == DELETE) {
      if (pendingName.length() > 0) {
        pendingName = pendingName.substring(0, pendingName.length() - 1);
      }
      return;
    }

    if (k == ENTER || k == RETURN) {
      commitEntry();
      return;
    }

    // Letters and digits only, three characters maximum.
    if (pendingName.length() < 3) {
      char u = Character.toUpperCase(k);
      if ((u >= 'A' && u <= 'Z') || (u >= '0' && u <= '9')) {
        pendingName += u;
      }
    }
  }

  void commitEntry() {
    String nm = pendingName.trim();
    if (nm.length() == 0) nm = "???";

    entries.add(new ScoreEntry(nm, pendingScore, rankTitle(pendingScore)));
    sortAndTrim();

    // Find where it landed, so the board can flash that row.
    highlightRow = -1;
    for (int i = 0; i < entries.size(); i++) {
      ScoreEntry e = entries.get(i);
      if (e.points == pendingScore && e.name.equals(nm)) {
        highlightRow = i;
        break;
      }
    }

    save();
    gameState = STATE_OVER;
  }

  // ------------------------------------------------------------ drawing

  // Shared by the game-over screen and the standalone board screen.
  void drawTable(float cx, float top, float rowH) {
    textFont(fontUI);

    // Header
    textSize(12);
    fill(150, 196, 220, 190);
    textAlign(LEFT, CENTER);
    text("#",     cx - 250, top - 20);
    text("NAME",  cx - 208, top - 20);
    text("RANK",  cx - 120, top - 20);
    textAlign(RIGHT, CENTER);
    text("SCORE", cx + 250, top - 20);

    for (int i = 0; i < entries.size(); i++) {
      ScoreEntry e = entries.get(i);
      float y = top + i * rowH;

      boolean isNew = (i == highlightRow);
      float pulse = isNew ? (140 + sin(frameCount * 0.2) * 90) : 0;

      // Row background: alternating stripes, with the new entry glowing.
      noStroke();
      if (isNew) fill(255, 206, 84, pulse * 0.35);
      else       fill(255, 255, 255, (i % 2 == 0) ? 14 : 6);
      rect(cx - 268, y - rowH * 0.42, 536, rowH * 0.84, 6);

      color rowCol = isNew ? color(255, 226, 150) : color(228, 240, 248);

      textAlign(LEFT, CENTER);
      textSize(15);
      fill(150, 196, 220, 200);
      text(nf(i + 1, 2), cx - 250, y);

      textFont(fontNum);
      textSize(18);
      fill(rowCol);
      text(e.name, cx - 208, y);

      textFont(fontUI);
      textSize(13);
      fill(red(rowCol), green(rowCol), blue(rowCol), 175);
      text(e.rank, cx - 120, y);

      textFont(fontNum);
      textSize(19);
      textAlign(RIGHT, CENTER);
      fill(rowCol);
      text(nf(e.points, 6), cx + 250, y);
    }

    if (saveFailed) {
      textFont(fontUI);
      textSize(12);
      textAlign(CENTER, CENTER);
      fill(255, 170, 120, 200);
      text("Scores could not be saved to disk - this session only.",
           cx, top + entries.size() * rowH + 14);
    }
  }
}
