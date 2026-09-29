# 70 — Crowd (lanes, moods that only worsen, four-phase reactions, steering by speed, distance bands, blending, slots)

**Problem:** a city's crowd fails in familiar ways (genre doc §6–§7):
- agents wandering freely look chaotic;
- a crowd that swings between calm and panic, or ignores a killing;
- people who turn on the spot like robots;
- a crowd that costs as much as the guards;
- hiding in a crowd the player can't trust;
- benches and stalls nobody uses, or two people sitting in the same seat.

**Solution:** small pure parts. The host moves the bodies.
- **`CrowdLanes`:** a network of lane points.
  - `from_paths(polylines)` merges points closer than 0.5 m, so lanes cross.
  - `next_from(current, previous, rng)` picks a random link, never straight back except at a dead end.
  - A seeded RNG makes every run the same.
- **`CrowdMind`** (one civilian):
  - moods `AMBIENT < ALERT < SCARED < PANIC`. `stimulate(mood, at, now)` takes only a worse mood (Hitman's rule).
    After calming down, a mere ALERT is ignored for `cooldown`, so nobody swings between extremes (Watch Dogs 2);
  - four phases (Watch Dogs 2):
    1. `REACT`: a short look;
    2. `REPOSITION`: away from the source to `watch_distance` when alerted, or `flee_distance` when scared or
       panicking;
    3. `MAIN`: watch, or keep fleeing;
    4. `CALM`: slow down, then back to the lanes.
  - `goal(pos)` is where to go now, or null for the lanes; `speed_scale()` is 0 while looking or watching.
- **`CrowdRules`:**
  - `steer(heading, desired, speed, turn_rate, delta)`: turn at a limited rate and scale the speed by cos² of the
    angle still to turn. People slow down rather than turn, and a U-turn stops first (Hitman);
  - `lod_interval(distance)` updates every frame under 12 m, every 3rd frame under 40 m and every 10th beyond (the
    bands of Assassin's Creed Unity). `lod_due(frame, id, distance)` spreads agents over those frames, and
    `lod_animate` stops animation beyond 30 m;
  - `blended(player, speed, calm_civilians)`: at walking speed within 1.8 m of at least two calm civilians (a group
    of two, as in Assassin's Creed III). Feed the result to recipe 66's `StealthMover.blended`, which recipe 68's
    senses read.
- **`SmartSlots`** (a bench, a stall):
  - `reserve(who, from)` takes the nearest free slot; a reserved one is never given away;
  - `occupy`, `release`;
  - `full()`: a bench with two sitting is a hiding place for a third (genre doc §6).

**Host (the game):**
- A civilian is a light body walking the lanes. When `goal()` is not null, walk to it instead, at
  `speed_scale() × walk speed`, steered by `steer`.
- Stimulate everyone within a radius of an event:
  - ALERT: a climb in view, a shove;
  - SCARED: a fight;
  - PANIC: a killing.
- A panicking crowd should leave by the exits and never block the player (Hitman).
- Update by `lod_due` and animate by `lod_animate`.
- Never delete fleeing people in view: Cyberpunk 2077's launch shows what that costs (genre doc §7).
- Tens of agents are the scale for GDScript. Thousands need the engine-level tricks the genre doc lists.

**Tuning:**
- `react_time` 0.6 s; `main_time` 4 / 6 / 10 s by mood; `calm_time` 3 s; `cooldown` 8 s;
- `watch_distance` 6 m, `flee_distance` 18 m;
- speeds ×1.0 / 0.9 / 1.8 / 2.6;
- the bands 12 / 40 m and 30 m for animation;
- blending within 1.8 m of 2 civilians, at up to 2.4 m/s.

**Pitfalls:**
- **A stimulus that resets a worse mood to a milder one:** a panicking civilian calms down at a shout. Only worsen.
- **Reactions with no calm phase and no cooldown:** a crowd that flickers between walking and panic.
- **Free wandering:** use lanes and slots.
- **A reserved seat taken by someone else:** two civilians sit in one seat.
- **Blending while sprinting:** a crowd isn't cover for someone running through it.
- **One level of detail for every agent:** the cost grows with every civilian added. Updates by distance keep it
  flat.

**Test:** `tests/unit/test_r70_crowd.gd`:
- lanes that merge at crossings and never double back; the same seed walks the same way;
- moods that only worsen, the four phases and the cooldown;
- steering that slows, stops and completes the turn;
- the distance bands, spread over frames;
- blending: two versus one, sprinting, too far;
- slots: reserved, occupied, full, released.
