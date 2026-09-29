# 71 — Counter-based melee (a weighted stage manager, strike timelines, counter / block / dodge, target picking)

**Problem:** the genre's fights fail two ways (genre doc §11):
- **Too easy.** Everyone attacks one at a time and a one-button counter wins every fight, so fighting becomes the
  path of least resistance and stealth loses its point.
- **Unreadable.** Five tells overlap, attacks start together, and presses get eaten or mashed.

Other ways it goes wrong:
- a counter that can't cancel the player's own swing, so the player is hit without knowing why;
- attacks that pull the player across the room at an enemy standing to the side.

**Solution:** four small parts. The host plays the animations and applies the results.
- **`MeleeStage`**, after Kingdoms of Amalur's stage manager:
  - `engage(fighter, weight)` gives a slot around the player within `grid_capacity`; the rest wait outside.
    `slot_position(i, centre, radius)` places them;
  - `may_attack(fighter, weight, now)` takes the strike's weight from `attack_capacity`, respecting a cooldown per
    fighter and a short global one;
  - `attack_done(fighter)` gives it back the moment the strike lands, is blocked or is countered, so attackers take
    turns;
  - difficulty raises only the two capacities.

  Recipe 49's `AttackTokens` is the one-number version.
- **`EnemyStrike`:** a strike's timeline (tell, flash, hit(s), recovery).
  - Kinds:
    - `NORMAL`: counter, block or dodge;
    - `UNBLOCKABLE` (red): dodge it; a block or a counter only breaks the guard;
    - `COMBO` (blue): several hits, answered one by one.
  - The first hit comes 0.7 s after the tell, well over human reaction (about 0.3 s). The combo's next hits come
    0.35 s apart, because the player anticipates them (Ghost of Tsushima).
- **`CounterDefense`** (the player):
  - `press_counter(now)` and `press_dodge(now)`; `blocking` is held;
  - `resolve(kind, hit_time)` gives `HIT / BLOCKED / COUNTERED / PERFECT / DODGED / GUARD_BROKEN`;
  - a counter within `window` (0.35 s) before the hit counters it, and within `perfect` (0.1 s) stuns;
  - each earlier press within `spam_window` halves the window (as in Sekiro), so mashing fails;
  - a press answers one hit.
- **`MeleeTarget.pick(from, direction, enemies)`**, after God of War (2018):
  - any sensible target is better than the air;
  - the stick's direction carries the intent; with no input, pass the camera's direction;
  - the reach (3 m) shrinks with the angle, down to 30% at the side.

**Host (the game):**
- On a counter press, cancel the player's own swing (recipe 47's combo) before resolving.
- Resolve every hit at its time with `resolve(strike.kind, hit_time)`, and call `stage.attack_done` right after.
- Show the flash at `flash_time` with a sound (the tell has three parts, genre doc §11), in red for UNBLOCKABLE and
  blue for COMBO.
- Give enemies health in hits, not points: a hard hits-to-kill cap per type, the same on every difficulty. Change
  difficulty with speed, aggression, windows and enemy damage. Inflated health feels like "a foam bat" (Ghost of
  Tsushima).
- Break the counter pattern with one or two special types per fight, at most: a heavy you must dodge, an agile one
  that survives one counter.
- Make a hit look different from a block (sparks against blood).
- Keep hit-stop short in groups (recipe 32): two frozen fighters give a third a free moment.

**Tuning:**
- `grid_capacity` 12, `attack_capacity` 4, weights about 4 for a soldier and 8 for a brute;
- `fighter_cooldown` 1.5 s, `global_cooldown` 0.35 s;
- `windup` 0.7 s, `flash_lead` 0.35 s, `combo_gap` 0.35 s, `recover` 0.8 s;
- `window` 0.35 s, `perfect` 0.1 s, `dodge_window` 0.4 s, `spam_window` 0.5 s with `spam_shrink` 0.5;
- `reach` 3 m, `side_reach` 0.3.

No game in the genre publishes its counter windows. For Honor's 166–200 ms parries are a PvP reference, and an
Arkham critic estimated about a second.

**Pitfalls:**
- **A strike's capacity released at the end of its recovery** instead of on the hit: attackers stand in line, and
  the fight slows to one at a time again.
- **One press countering every simultaneous hit:** with two attackers, mashing once wins. A press answers one hit;
  allow more only on purpose, as Arkham City did.
- **Comparing strike times with `==`:** 2.0 + 0.7 is not 2.7 in floating point. Compare within a tolerance.
- **A counter window that grows with the press count:** it must shrink, or the pad's fastest masher wins.

**Test:** `tests/unit/test_r71_counter_melee.gd`:
- the weighted grid and its slots;
- attackers taking turns, the cooldowns;
- the strike timeline;
- counter, perfect, too early, too late, block and dodge;
- mashing that fails where one press works;
- unblockable strikes;
- one press per hit, and forgotten presses;
- target picking with the reach shrinking by angle.
