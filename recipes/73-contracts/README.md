# 73 — Contracts and viewpoints (sync to reveal, a target's routine, phases where detection changes, not fails)

**Problem:** the open-world structure of the genre goes wrong in known ways (genre doc §9, §13):
- a map full of icons from the start, or towers as the only way to learn about a place;
- targets whose routine is long, random or unreadable, so the player waits or guesses;
- missions that fail the moment the player is seen (the tailing missions);
- optional objectives that dictate one way to play;
- the same procedure repeated before every target.

**Solution:** three small parts.
- **`ViewpointNetwork`:**
  - `add_viewpoint(id, pos, radius)`, `add_marker(id, pos, kind)`;
  - `sync(id)` reveals every marker within the radius at once (a clear goal and an instant, large reward), shows the
    unsynced viewpoints within twice the radius (`seen_unsynced()`, for the map), and makes it a fast-travel point
    (`fast_travel_points()`). A second sync reveals nothing new;
  - `discover_near(pos, distance)`: walking up to a place reveals it as well, so a viewpoint is a shortcut, not a
    toll.
- **`TargetRoutine`:**
  - `add_stop(pos, wait)` builds a loop of stops at `speed`;
  - `position_at(t)` is deterministic, so the player can learn it from a roof and a test can check it;
  - `waiting_at(t)` gives the stop the target stands at, the strike's window; `loop_time()` the whole round.

  Keep the loop short: Hitman's testers got bored waiting for a target's long loop through a town, and the loops were
  cut to one building.
- **`Contract`**, in phases:
  1. `APPROACH`: `start()`;
  2. `ESCAPE`: `on_kill(true)`, the target is down;
  3. `DONE`: `on_escaped()`, the chase is lost (recipe 72) or the exit reached.

  Events:
  - `on_detected()` fails nothing. It alerts the target (`target_alerted`: the host sends it to its safe place), so
    detection changes the situation instead of ending the mission (genre doc §9);
  - the contract fails only on `on_target_safe()` (the target reached safety) or `on_player_died()`;
  - `bonuses()` reports `unseen` and `only_the_target` at the end, and they never fail anything.

**Host (the game):**
- Put viewpoints on the district's landmarks. From each one the next should be visible (the first game showed the
  next viewpoints from every one).
- Place the target's stops where the level offers several approaches: a roof, a crowd, a side door. Design from the
  area, not a line: Hitman starts from the targets and the spaces they occupy.
- Let the player learn the routine without a HUD: overheard talk, a clue board, the viewpoint's view.
- Vary what comes before each target (investigate, eavesdrop, steal a key), because the same procedure nine times
  drew complaints.
- Keep bonuses optional and small.

**Tuning:**
- a viewpoint's radius (40–60 m in a district a few hundred metres across);
- the routine's stops and waits (a loop of a minute or two);
- the target's `speed` (1.3 m/s walking) and its safe place's distance, which is how long a chase can last.

**Pitfalls:**
- **Every marker visible from the start:** a hundred icons overwhelm; ten groups of ten are digestible.
- **Viewpoints as the only way to reveal places:** the rhythm becomes "climb a tower, clear its icons". Reveal by
  discovery too.
- **A random or unrepeatable routine:** the player can't plan. Deterministic by time.
- **Failing on detection:** the player reloads instead of playing the chase. Fail only on a lost target or death.
- **A bonus that fails the contract:** "undetected" as a requirement dictates one way to play.

**Test:** `tests/unit/test_r73_contracts.gd`:
- a sync reveals its radius once, becomes a fast-travel point and shows the next viewpoint; discovery by walking;
- a routine's positions, waits and walks, and the loop repeating;
- a contract where detection alerts but fails nothing, other kills are allowed, and escaping finishes it;
- the two ways to fail; bonuses for a clean run; nothing after the end changes it.
