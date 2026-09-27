# 51 — Boss phases and telegraphed attacks

**Problem:** bosses that are a pile of HP:
- a burst build skips the whole second phase in one hit;
- the boss changes phase in the middle of a strike;
- attacks come without warning or with no gap to punish;
- the same move three times in a row;
- the late-fight moves show up in the first seconds.

**Solution:** **`BossBrain`**:
- **Phases** start at health `thresholds` (fractions of max). A hit that would cross one **stops on it**, and the
  boss is **invulnerable for `transition_time`**: the moment for a roar, an arena change or adds, and a pause for
  the player.
- **Attacks** (`BossAttack`) run **telegraph → strike → recovery**. The recovery is the window of opportunity.
- `min_phase` holds moves back until the fight escalates.
- The next move is weighted among the unlocked ones, **never the same twice in a row** when there's a choice, from a
  seeded RNG.
- **`state_elapsed()`** says how far into the current telegraph/strike/recovery it is. Use it to sync visuals and to time a test bot's reaction.
- **`validate()`** is the readability contract. It returns every move whose telegraph is shorter than
  `min_telegraph` (0.4 s by default) or whose recovery is shorter than `min_window`. Run it in a test over your real
  boss data.

**Tuning:**
- thresholds (2–3 phases);
- `transition_time` (0.8–1.5 s);
- per move: telegraph, strike, recovery, weight, `min_phase`, damage;
- `min_telegraph` and `min_window` (tighten them for harder difficulty modes instead of making the tells shorter
  than the contract).

Raise late-phase difficulty by adding moves, shortening recoveries (above the minimum) or combining moves, never by
hiding the tell. Design research (gry-wiedza `gb doc genre-action-roguelite`) says keep a move's visual language
constant as difficulty rises.

**Host:**
- On `attack_started`, play the telegraph with **at least two cues**: animation plus a sound or ground marker.
- On `strike_started`, enable the move's hitbox for `strike` seconds.
- On `phase_changed`, play the transition (arena change, adds from recipe 49).
- Route player hits into `take_damage()`, and route the return value to a damage number.

**Pitfalls:**
- Letting overflow damage cross thresholds.
- Taking damage during the transition.
- Telegraphs shorter than a human reaction (~0.25–0.4 s plus reading time). The scenario measures the on-screen
  telegraph time before every strike.
- Two simultaneous telegraphs with no priority, which makes the fight unreadable.
- Global RNG, which makes fights unreproducible.
- Scenario tests whose expectations assume a long fight. A fast player sees few strikes, because transitions
  interrupt them. Assert the rule, not a count.

**Test:** `tests/unit/test_r51_boss.gd` (a threshold stops the hit, the phase changes once, invulnerable
transition, exact attack timings, no repeats, determinism, phase locks, the validate contract, death once),
`tests/scenarios/r51_boss.gd` (the bot fights with the real key: the threshold stops the hit, a blocked hit in the
transition, hits land again, every strike telegraphed ≥ 0.4 s on screen, the boss dies; shots of the transition and
a telegraph). Scene: `boss_demo.tscn`.
