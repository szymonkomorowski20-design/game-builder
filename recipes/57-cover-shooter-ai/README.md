# 57 — Cover-shooter AI: cover, peek, suppression, flank, barks

**Problem:** shooter enemies are either target dummies standing in the open or aimbots that kill from across the map.
Good campaign AI:
- hides;
- peeks to shoot in bursts;
- misses its first shots at a player who just appeared;
- stays down when shot at;
- flanks a player who camps;
- **says what it is doing**, so the player can read the fight.

**Solution:** two parts without scenes.
- **`ShooterBrain`** (decisions): MOVE → COVER → PEEK → COVER …, with RELOAD in cover and FLANK when the player hasn't
  moved for `flank_after`.
  - The body feeds `tick(delta, arrived, sees_player, player_moved)`, calls `fire_round()` per shot while peeking,
    and `suppress()` when hit or when bullets land close.
  - `accuracy(difficulty)` ramps from `accuracy_min` to `accuracy_max` over `aim_time` of exposure. Roll it per
    shot: a hit deals damage, a miss sends the tracer past the player.
  - `bark(kind)` gives the host a voice line or subtitle: `reloading`, `flanking`, `suppressed`.
  - Optional **`AttackTokens`** (recipe 49): at most N soldiers peek and fire at once.
- **`CoverFinder`** (where to hide): cover points are Marker3Ds (group "cover") behind waist-high geometry.
  - A point is *useful* when the player's eyes can't see it at crouch height (0.9 m) but can at standing height
    (1.6 m): hidden, and still able to peek.
  - `best(space, points, soldier, player_eye, occupied, flank_from)` scores the useful, free points. It prefers a
    distance to the player inside [`near`, `far`] and a short walk, and for a flank a new angle on the player.

**Tuning:**
- `peek_wait` and `peek_time` (the rhythm);
- `aim_time`, `accuracy_min` and `accuracy_max` (difficulty lives here: lower accuracy on easy, not shorter
  telegraphs);
- `suppressed_extra`;
- `flank_after` (5–10 s);
- `reload_time` and `magazine`;
- the token `limit` (2–3 shooters for a room of 6);
- the CoverFinder band `near` / `far` per weapon (shotgunners close, riflemen far).

**Host (the body):**
- A CharacterBody3D with a NavigationAgent3D, walking to `brain.cover_target`.
- While PEEK, stand and fire bursts at the player.
- While COVER or RELOAD, crouch (a shorter collision shape, or just the pose).
- On `state_changed` to MOVE or FLANK, pick a point with `CoverFinder.best` and call `move_to(point)`. Tell other
  soldiers which points are taken.
- Rays for `sees_player` come from the head at standing height.

**Pitfalls:**
- a cover point on the wrong side of the wall (check usefulness against the *current* player position, each time
  the soldier picks);
- everyone picking the same point (pass `occupied`);
- accuracy that doesn't ramp, so the first shot kills from 40 m;
- suppression with no visible reaction (play a flinch);
- flanks nobody sees coming (the bark is the warning);
- more than 2–3 shooters firing at once.

**Test:** `tests/unit/test_r57_cover_ai.gd`:
- the move/cover/peek cycle, the accuracy ramp and its difficulty scale;
- reloading in cover with a bark, suppression and its longer wait, flanking a camper;
- tokens limiting who peeks;
- cover finding: hidden but can peek, open ground, a tall wall, occupied points;
- the flank score.
