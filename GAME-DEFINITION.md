# Game Definition Document

**Project name:** *OVERBOARD*
**Team:** [TEAM NAME]
**Team members:** [NAME 1], [NAME 2], [NAME 3], [NAME 4], [NAME 5]
**Platform:** Processing (Java mode)
**Date:** [DATE]
**Version:** 1.0 — For stakeholder review

---

## 1. Assigned Words

| Category | Word | How it is realised |
|---|---|---|
| Subject | **Fish** | The player character, swimming freely in a fixed ocean arena |
| Action | **Dodge** | The entire game: weaving between falling freight |
| Object | **Plane** | A cargo plane crosses the sky above and sheds its load into the water |

---

## 2. Elevator Pitch

*OVERBOARD* is an aquatic survival dodger. A cargo plane crosses the sky above the ocean, shedding crates, barrels, pallets and shipping containers into the water. You are the fish below. Swim freely in two dimensions, dodge everything that comes down, and survive as long as you can.

The longer you last, the faster the drops come and the more points you earn. Power-ups drift through the water offering an extra life, half-speed slow motion, or double points. When you finally get hit one time too many, you put your initials on a persistent leaderboard and hand the keyboard to whoever thinks they can beat it.

---

## 3. Stakeholders

| Stakeholder | Motive | Conflict |
|---|---|---|
| **Players** | Immediately understandable, responsive, and fair — a loss should feel earned | Want variety and content; the team must keep scope small enough to finish and document |
| **Competitive players** | A reason to replay — a score to beat and a name on the board | Leaderboard chasing rewards cautious play; the near-miss bonus exists to push against that |
| **Teaching staff** | Evidence the three words are represented and that the process was engineered properly | Assessment rewards documentation over polish, so effort must be split |
| **Development team** | A build that divides into independent, attributable features across five people | Individual reports need distinct user stories and code blocks, so features must be modular rather than co-written |
| **New players** | To understand the game without a tutorial | Depth for repeat players competes with clarity for first-timers |

---

## 4. Core Gameplay Loop

1. The player starts a run from the title screen with three lives.
2. A cargo plane crosses the sky, turns around off-screen, and comes back the other way.
3. Freight is released from the plane's rear ramp, arcs forward, and splashes into the water.
4. On entry each piece loses most of its speed and then sinks at a rate set by its weight.
5. The player swims freely in the water, dodging everything.
6. Points accrue with time survived; squeezing past a piece of cargo pays a near-miss bonus.
7. Power-ups drift through the water and can be collected for an extra life, slow motion, or double points.
8. Every collision costs a life and grants a brief window of invulnerability.
9. At zero lives the run ends. If the score qualifies, the player enters three initials for the leaderboard.
10. Instant restart.

---

## 5. Game World

- **Setting:** A side-on cross-section of the ocean. Sky above the waterline, water below, seabed at the bottom.
- **Fixed arena:** The camera does not scroll. The fish moves; the world stays put. All action is contained on one screen.
- **Scenery:** Gradient sky with a sun, animated waterline with caustic flecks, drifting light shafts, rising bubbles, swaying kelp, coral and distant rock silhouettes on the seabed.
- **Day/night cycle:** The palette drifts slowly between bright day and dusk over the course of a run, marking progress without ever changing the rules.

---

## 6. Controls

| Input | Action |
|---|---|
| `ARROW KEYS` / `WASD` | Swim in any direction (diagonals normalised) |
| `SPACE` | Start / restart |
| `P` | Pause; `Q` from pause returns to the title |
| `L` | View the leaderboard |
| `A–Z`, `0–9` | Enter initials after a qualifying run |

Movement uses acceleration and drag rather than fixed stepping, so the fish carries momentum and feels like it is swimming through water.

---

## 7. Hazards

Every hazard is a piece of freight released from the plane's ramp. Nothing spawns from empty sky.

| Freight | Size | Sink rate | Character |
|---|---|---|---|
| **Suitcase** | Small | Slowest | Light, drifts, easy to slip past |
| **Crate** | Medium | Medium | The bread and butter hazard |
| **Barrel** | Medium-tall | Fast | Heavy, gives little warning |
| **Pallet** | Wide, flat | Medium | Hard to get around sideways |
| **Shipping container** | Huge | Fastest | Rare, screen-filling, unlocks only after the opening |

**Two-phase physics.** Freight accelerates under gravity through the air, splashes at the waterline, loses most of its momentum, then eases toward a terminal velocity set by its weight. The fast, readable air phase gives warning; the long underwater descent is where the dodging happens.

Cargo inherits the plane's forward momentum, so it arcs rather than dropping straight down — the player has to lead the plane rather than sit under it.

---

## 8. Power-Ups

Collectable bubbles drift through the water, spawning away from the fish so that reaching one is a decision with risk attached. Each lasts twelve seconds before it pops.

| Power-up | Effect | Design intent |
|---|---|---|
| **Extra Life** | +1 life, capped at five. At the cap it converts to 500 points instead | Never a wasted pickup. Spawn weight falls as the player's stack grows |
| **Slow-Mo** | The entire world runs at 0.5× for seven seconds | Scoring slows with it, so safety is bought with points — a real trade-off, not a free win |
| **Double Points** | Every point counts twice for ten seconds | Rewards surviving the crowded late game rather than the quiet opening |

Re-collecting refreshes a timer rather than stacking it, so an unbroken minute of slow motion cannot be banked.

---

## 9. Scoring, Ranks and the Leaderboard

- Score accrues with time survived, scaled by the current difficulty multiplier.
- **Near-miss bonus:** passing within a few pixels of a piece of cargo pays 50 points and a popup. This is the counterweight to hiding in a corner.
- **Ranks** derived from score alone: Minnow → Guppy → Snapper → Reef Runner → Barracuda → Marlin → Leviathan. The game-over screen shows how far the next rank is, so there is always a concrete reason to try again.
- **Persistent leaderboard:** the top ten are written to `leaderboard.csv` beside the sketch and survive closing Processing. Qualifying runs prompt for three initials; the new row is highlighted when the board appears.

---

## 10. Difficulty

A single multiplier, `gameSpeed`, rises from 1.0 to 2.4 over the first ninety seconds and then holds. It drives the plane's speed, the sink rate of freight, and the interval between drops. Occasional carpet drops release a rapid burst of freight.

The cap matters: the game becomes genuinely hard but never mathematically impossible, so a loss is always attributable to the player.

---

## 11. Game States

| State | Contents | Exit |
|---|---|---|
| **Title** | Logo, controls, power-up legend, live ocean behind | SPACE |
| **Playing** | Full game with HUD | Lives reach zero |
| **Paused** | Frozen world, dimmed | P / SPACE to resume, Q to quit |
| **Name entry** | Score, rank, three initial slots | ENTER |
| **Game over** | Run summary, rank, distance to next rank, leaderboard | SPACE / L |
| **Leaderboard** | Full top ten | SPACE |

---

## 12. Feature List (basis for functional requirements)

1. Fish with free 2D movement, momentum, and arena bounds
2. Cargo plane with a looping flight path and a drop ramp
3. Cargo spawning from the ramp with inherited momentum
4. Two-phase cargo physics with water-entry transition
5. Five distinct freight types with different weights and silhouettes
6. Collision detection, life loss, and post-hit invulnerability
7. Score accrual, near-miss bonus, and rank derivation
8. Three power-up types with spawning, pickup and timed effects
9. Progressive difficulty scaling with a cap
10. Persistent leaderboard with initials entry and file storage
11. Full state management across six screens
12. Particle effects: splashes, ripples, bubbles, bursts, floating text

---

## 13. Non-Functional Considerations

- **Performance:** a consistent frame rate on a standard lab machine. A reaction game with a wandering frame rate is unfair. Achieved by pre-rendering static scenery into off-screen buffers.
- **Input latency:** input registers within a frame or two, so a failed dodge is the player's timing and not the engine's.
- **Learnability:** a new player should survive their first thirty seconds using only the title-screen legend.
- **Fairness:** difficulty caps, spawn intervals scale with speed, and power-ups never spawn on top of the player.
- **Robustness:** a missing or corrupt leaderboard file must not crash the game — bad rows are skipped and a read-only folder degrades to a session-only board.
- **Maintainability:** one feature per file, so five people can work in parallel and merge cleanly.
- **Portability:** runs unmodified in Processing on Windows and macOS with no external assets or libraries.

---

## 14. Scope

**In scope (MVP):** all twelve features above, plus the six screens.

**Stretch goals:** sound effects and music, a global online leaderboard, a boss pass where the plane drops a wall with one gap, a shield power-up distinct from extra life.

**Out of scope:** multiple levels, multiplayer, save profiles, mobile or web export.

---

## 15. Constraints and Assumptions

- Built in Processing, as the unit requires.
- No budget — every asset is drawn programmatically. No image, font or sound files ship with the project.
- Developed across the term alongside other assessments, asynchronously via GitHub.
- Mixed prior programming experience in the team, so the design favours many small, well-separated features over a few complex ones.
- Assessment is on documented process rather than the finished game, so scope stays tight enough to leave time for the reports.

---

## 16. Definition of Success

1. A fish visibly dodges objects falling from a plane, satisfying the three assigned words.
2. A new player survives their first run without instruction beyond the title screen.
3. All MVP features implemented, merged, and running without errors at a stable frame rate.
4. Every feature traceable to a user story with tested acceptance criteria.
5. Every team member has independently attributable commits, an assigned board task, and a distinct code contribution.

---

## 17. Next Steps

1. Agree on this definition, or raise changes now rather than after coding starts.
2. Derive the functional and non-functional requirements from sections 12 and 13.
3. Write user stories as *"As a ___ I want ___ so that ___"* with acceptance criteria as *"Given ___ when ___ then ___"*.
4. Each member claims one distinct user story for their individual report, and the file ownership table in `README.md` is filled in before anyone commits.
