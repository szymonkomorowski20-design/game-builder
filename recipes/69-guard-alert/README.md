# 69 — Guard alert and search (states, a shared board, one investigator, search points, calling for support)

**Problem:** guards that break stealth (genre doc §5):
- the whole level converges on a single noise;
- guards who know where the player is without seeing him;
- searches that last minutes, or end the moment the player breaks line of sight;
- alarms that spread across the whole map;
- no way to stop a guard before he raises the alarm;
- a group that can't be pulled apart.

**Solution:** a pure brain per guard, and a board the guards of one area share.
- **`GuardBrain`** states:
  - `PATROL`: the host follows the patrol route;
  - `SUSPICIOUS`: something seen (the meter over `suspicious_at`) or heard (`notice(kind, key, pos, now)`). The guard
    stops and stares at it for `turn_time`;
  - `INVESTIGATE`: the guard that claims the stimulus on the board walks there, looks around for
    `look_around_time`, and goes back. This is a cautious search, and only one guard makes it;
  - `ALERT`: detected. The guard runs at the player.
    - After `call_delay` the call for support reaches the board. Silence the guard first and nobody hears it.
    - A lost player is still known for `memory` seconds, and the guard runs to where the player really is (the
      trick from Halo and Crysis). After that only the last seen place counts;
  - `SEARCH`: at the last seen place. It takes the board's search points one at a time and runs; it ends when the
    points run out or after `search_time`;
  - `RETURN`: back to the post, with raised caution for `caution_time`. `guard_state()` gives the senses
    (recipe 68) `&"caution"`, and `wants_reset` tells the host to reset the awareness meter.

  A guard seen again by the player while searching goes straight back to the chase. Stimulus priorities follow
  Mark of the Ninja's table (`PRIORITY`): a higher one replaces a lower, and the newest wins on a tie. A body found
  on investigation raises an alarm and starts a search.
- **`AlertBoard`:**
  - `report_seen` stores the last known place (written only by a guard who sees the player);
  - `raise_alarm`: guards on patrol within `alarm_radius` answer it by running to it. They don't learn where the
    player is now;
  - `claim_investigation(key)`: one investigator per stimulus;
  - `join_search`: at most `max_searchers`;
  - `plan_search(estimate, candidates, radius, hidden_from)`: points hidden from the estimate first (where someone
    who just broke line of sight would be), then by distance;
  - `next_point` gives each searcher its own point, and `tick_off` marks it checked.

**Host (the game):**
- Each frame, call `tick(now, {level, seen, seen_at, true_pos}, position)` from recipe 68's `GuardSenses`.
  - Pass `seen_at = senses.meter.last_seen`: the position at the senses' last look. The `seen` flag is up to
    `think_every` old, and a live position read with it records where the player went after the look (the stealth
    template's guard once "saw" a player who had already left).
  - When the goal lies off the navigation mesh (a spot on a stall, a roof edge), pass `goal` as the position once
    the path is done as close as the mesh allows. Otherwise the guard never "arrives" and never searches.
- In `PATROL`, walk the route. Otherwise go to `goal`, run when `running`, and face `look_at` when standing.
- Set `senses.guard_state = brain.guard_state(now)`. When `wants_reset` is set, reset the meter and clear the flag.
- Give each guard a slightly different `search_time` (±25%), so the guards go back gradually, not all at once
  (genre doc §5).
- Fill `search_candidates` with hiding places and corners (markers in the level), and `hidden_from` with a ray
  test.

**Tuning:**
- `turn_time` 1 s, `look_around_time` 2 s;
- `memory` 2.5 s, `call_delay` 1.5 s;
- `search_time` 30 s, `search_radius` 15 m, `caution_time` 60 s;
- the board's `max_searchers` 3 and `alarm_radius` 25 m.

The genre doc's sources give the ranges: 2–3 s of memory, 1–3 searchers, and a search cycle cut from 2 minutes to
30 s. No game publishes its alarm or search durations.

**Pitfalls:**
- **Every guard that hears a distraction goes:** nothing is left to split, and one noise empties the area. Claim
  it on the board.
- **Guards reading the player's true position after losing sight:** use it only within `memory`.
- **A latched detection** (recipe 68) re-triggering the chase every tick while searching: re-alert only when the
  player is seen again.
- **The call for support checked after the state changed:** a guard that reached the last seen place before
  `call_delay` never called. Check the call first.
- **An alarm answered by guards across the whole map:** limit it with `alarm_radius`. Thief limited how far
  knowledge spreads for the same reason (genre doc §5).

**Test:** `tests/unit/test_r69_guard_alert.gd`:
- a noise stared at, checked and dropped;
- one investigator per stimulus;
- priorities;
- the call for support only after the delay, answered within the radius only;
- memory, then the last seen place, then the search's hidden-first points, calming down with caution;
- the search's time limit and the searcher cap, with no shared points;
- a body raises an alarm and a search;
- a player seen again during a search is chased at once.
