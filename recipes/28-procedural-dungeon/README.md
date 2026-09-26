# 28 — Procedural dungeon (seeded)

**Problem:** procedural levels that are sometimes unwinnable (unreachable rooms), and bugs nobody can reproduce because
the level was random.

**Solution:** every generator takes a **seed** and its own `RandomNumberGenerator` (never the global RNG — anything
else calling `randf()` would change the level). Rooms-and-corridors: place random rooms that don't overlap (with a
1-tile margin), connect each to the previous one with an L-shaped corridor → connected by construction. Output is a
grid → `to_rows()` → `AsciiLevel.build()` (27). Show the seed in the pause menu / bug report.

**Test generators as properties over many seeds:** same seed → same output; every floor reachable (flood fill);
rooms never overlap; border closed. 50 seeds run in milliseconds and catch the 1-in-30 broken level.

**Other algorithms:** BSP (evenly spread rooms), cellular automata (caves — needs a connectivity pass that removes or
connects isolated pockets), drunkard's walk, Wave Function Collapse (tile rules), prefab room stitching (Spelunky/Isaac
style, best for hand-crafted feel).

**Pitfalls:** `Array.shuffle()` / `randi()` use the global RNG; placing the player/exit in the same room; generation on
the main thread for big maps (use a thread or spread over frames).

**Test:** `tests/unit/test_r28_dungeon.gd`.
