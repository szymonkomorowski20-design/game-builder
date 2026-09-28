# 60 — RTS building and production (placement grid, production queue, tech tree)

**Problem:** building is where an RTS's rules show.
- Placement:
  - buildings overlap, or stand half off the map;
  - a building goes up on a cliff or on a mine;
  - a building goes up in the fog, where the player has never been;
  - the ghost says nothing about *why* it is red.
- Production:
  - a queue that takes the money only when the unit is done (so the player overspends);
  - two queues overfilling the supply;
  - a cancel that loses the money;
  - a "not enough food" message every frame.
- Tech:
  - a knight button that works without its blacksmith;
  - a tech that stays unlocked after the blacksmith burned down.

**Solution:** three logic classes; the game's nodes wrap them.
- **`RtsBuildGrid`:**
  - square cells; `footprint_at(world, size)` gives the footprint nearest to the cursor, and `centre(cell, size)` the
    world point where the building node goes (a 2×2 lands on a cell corner, a 3×3 on a cell middle);
  - `why_not(cell, size)` gives `outside`, `occupied`, `blocked` or `unexplored` (via `explored`, the fog of war,
    recipe 62), or "" when the building fits;
  - `place` / `remove` take and free the cells; `block_around` keeps a no-build ring, e.g. around a mine.
- **`RtsProduction`** (one per building):
  - `enqueue(item)` pays at once (all or nothing, recipe 59), up to `max_queue`;
  - the front item **reserves its supply when it starts**. If it doesn't fit, the building waits and `blocked` fires
    once;
  - `produced(id)` fires after the item's `time`; `cancel(index)` refunds in full, and releases supply that had started;
  - `fraction()` is the button's fill; `rally_point` is where new units go.
- **`RtsTechTree`:** `requires` (item → what must be owned); `owned` counts buildings and research, so losing the last
  blacksmith locks knights again; `missing(item)` is the tooltip.

**Tuning:**
- cell size (1–2 m, to match the unit sizes);
- footprints (2×2 to 4×4);
- `max_queue` (5);
- item costs, supply and times (the balance sheet);
- the no-build ring around resources (2–3 cells).

**Host (the game):**
- while placing, move a ghost to `centre(footprint_at(mouse, size), size)` and tint it by `why_not`;
- on a click: `place`, spend the cost, spawn a construction site that a worker builds (recipe 58's BUILD order);
- a building node owns an `RtsProduction` and calls `tick(delta)` in `_process`; on `produced`, spawn the unit and give
  it a MOVE (or ATTACK_MOVE) to `rally_point`;
- the command card (the buttons) greys out items that `RtsTechTree.available` refuses, with `missing()` as the tooltip.

**Pitfalls:**
- charging at the end of production;
- reserving supply at queue time for the whole queue (a full queue then blocks other buildings for nothing);
- a supply-blocked message every frame;
- footprints that are centred differently for even and odd sizes;
- placement checks against the physics world only (too slow for a ghost that moves every frame; the grid is exact);
- a tech tree that stores "unlocked" once and never locks again.

**Test:** `tests/unit/test_r60_build_produce.gd`:
- snapping for 2×2 and 3×3;
- every refusal reason, an overlap taking nothing, removal, the ring;
- paying when queued and the limit;
- order and timing; supply blocking once and then starting;
- cancel refunds and releases;
- the tech tree with counts and a lost building.
