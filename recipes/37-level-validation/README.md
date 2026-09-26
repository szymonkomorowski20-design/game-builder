# 37 — Level validation (completable, no soft-locks)

**Problem:** a level edit or a generator seed makes the exit unreachable, hides a coin behind a wall, or puts a
key behind the door it opens — found by a player, weeks later.

**Solution:** `LevelCheck.analyze(rows)` flood-fills from the start (`S`) over floor, treating walls (`#`) and
hazards (`~`) as blocked and doors (`D`) as closed until a reachable key (`k`) opens one — repeated to a
fixpoint. It reports `exit_reachable`, `unreachable_pickups`, `softlocked_doors`, the shortest `path_length`
(pacing) and `dead_ends`. `rows_from_layer(layer, start, exit)` converts a `TileMapLayer` (collision = wall).
Run it in a GUT test over **every** level file and over many generator seeds (recipe 28).

**Platformers:** 4-direction reachability ignores jump arcs — for side-view levels use a bot scenario that
actually plays the level (platformer template, scenarios P1–P8), and keep `LevelCheck` for top-down/grid levels
and for key/door logic.

**Pitfalls:** checking only the hand-made level you edited (loop over all); counting a door as passable because
*a* key exists somewhere (it must be reachable before the door); forgetting one-way passages (model them as
extra tile types if your game has them).

**Test:** `tests/unit/test_r37_level_validation.gd` — detection proven: opening doors without a key hides the
soft-lock and the test fails.
