# OVERBOARD

**Fish** • **Dodge** • **Plane** — a survival dodger in Processing.

A cargo plane crosses the sky above the ocean, shedding its load. You are the fish below. Survive as long as you can while the drops get faster, grab power-ups, and put your initials on the leaderboard.

---

## Running it

1. Install [Processing](https://processing.org/download) (Java mode, 4.x).
2. Keep all `.pde` files in a folder named exactly **`Overboard`**.
3. Open `Overboard.pde` — the other files appear automatically as tabs.
4. Press Run.

No external libraries, no image or font assets. Everything is drawn in code, so the sketch runs identically on every machine in the team.

---

## Controls

| Key | Action |
|---|---|
| `ARROWS` / `WASD` | Swim |
| `SPACE` | Start / restart |
| `P` | Pause (`Q` from pause returns to the title) |
| `L` | Leaderboard |
| `A–Z`, `0–9`, `BACKSPACE`, `ENTER` | Enter your initials after a qualifying run |

---

## How it works

**Cargo comes from the plane, not from nowhere.** Every hazard is released from the plane's open rear ramp and inherits its forward momentum, so freight arcs rather than dropping straight down. Watch the plane and you can read where the next wave will land — that link between cause and hazard is what keeps the game feeling fair.

**Two-phase physics.** Cargo accelerates under gravity through the air, then splashes at the waterline, loses most of its speed, and sinks toward a terminal velocity set by its weight. A suitcase drifts down slowly; a shipping container drops like a stone. The water is the arena, and the long descent is where the real dodging happens.

**Difficulty ramps for 90 seconds, then holds.** `gameSpeed` climbs from 1.0 to 2.4 and stops. The drop interval shrinks with it, and occasional carpet drops release a rapid burst. It gets hard; it never becomes impossible.

**Near misses pay.** Squeezing past a piece of cargo is worth 50 points and a popup. This is the counterweight to camping in a corner — the risky line scores better than the safe one.

**Power-ups are a trade-off, not a gift.**

| | Effect | Cost |
|---|---|---|
| ❤️ Extra Life | +1 life, capped at 5 | At the cap it converts to 1000 points instead |
| ⏳ Slow-Mo | The entire world runs at 0.5× for 10s | Scoring slows too — you buy safety with points |
| ✕2 Double Points | Every point counts twice for 10s | You have to swim to it through the freight |

Re-collecting refreshes a timer rather than stacking it, so you can't bank a minute of slow motion.

**The leaderboard persists.** Scores are written to `leaderboard.csv` beside the sketch, so it survives closing Processing and everyone on the same machine plays the same board. Ranks are derived from score alone: Minnow → Guppy → Snapper → Reef Runner → Barracuda → Marlin → Leviathan.

---

## File ownership

One feature per file, so nobody edits the same file at the same time and merges stay clean. **Fill in the owner column before anyone starts committing** — it decides who can answer which question in the individual report.

| File | Feature | Owner |
|---|---|---|
| `Overboard.pde` | Core loop, state machine, difficulty ramp, input | |
| `Fish.pde` | Player character, swimming physics, animation | |
| `Cargo.pde` | Hazard entity, air/water physics, five freight types | |
| `CargoManager.pde` | Spawning, collision detection, near-miss bonus | |
| `CargoPlane.pde` | The plane, its flight path and drop ramp | |
| `PowerUp.pde` | Collectable entity and icons | |
| `PowerUpManager.pde` | Spawning, pickup, active-effect timers | |
| `Ocean.pde` | Scenery, pre-rendered gradients, parallax | |
| `Effects.pde` | Particles, splashes, ripples, floating text | |
| `HUD.pde` | In-game overlay | |
| `Leaderboard.pde` | Persistence, ranks, initials entry | |
| `Screens.pde` | Title, pause, entry, game over, board screens | |

Twelve files across five people is roughly two or three each. Suggested grouping:

- **A** — `Overboard.pde` (core loop, states, difficulty)
- **B** — `Fish.pde` + `Effects.pde`
- **C** — `Cargo.pde` + `CargoManager.pde`
- **D** — `CargoPlane.pde` + `PowerUp.pde` + `PowerUpManager.pde`
- **E** — `Ocean.pde` + `HUD.pde` + `Leaderboard.pde` + `Screens.pde`

---

## Performance notes

The sky gradient, water gradient, seabed, coral and vignette are drawn once into off-screen `PGraphics` buffers at startup and blitted each frame. Only genuinely moving things — waves, light shafts, kelp, bubbles, particles — are redrawn live. This matters: a reaction game with a wandering frame rate is unfair, and "maintains a smooth frame rate" is a testable non-functional requirement.

The vignette is built with a per-pixel loop, which is expensive but runs exactly once. Expect a brief pause on startup.

---

## Tuning

Most of the feel lives in a handful of constants:

| Constant | File | What it controls |
|---|---|---|
| `ACCEL`, `MAX_SPEED`, `DRAG` | `Fish.pde` | How heavy the fish feels |
| `GRAVITY_AIR` | `Overboard.pde` | How much warning you get before a splash |
| `terminal` per type | `Cargo.pde` | How fast each freight type sinks |
| `nextInterval()` | `CargoManager.pde` | Drop frequency, the main difficulty lever |
| `runTime / 85.0` | `Overboard.pde` | How quickly the game ramps up |
| `SLOW_DURATION`, `DOUBLE_DURATION` | `PowerUpManager.pde` | Power-up lengths |

If you change `MAX_SPEED`, re-check that the fish can still cross the arena fast enough to reach a power-up before it expires (12 seconds).

---

## Not built yet (stretch goals)

Sound effects and music, a global online leaderboard, a boss pass where the plane drops a solid wall with one gap, a shield power-up distinct from extra life, and mobile/web export.

These are deliberately sized so each team member has real work to claim and commit under their own account.
