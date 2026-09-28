# 61 — RTS group movement (the magic box, formation slots, crossing-free assignment, arrival)

**Problem:** twenty units ordered to one point fight over it. They bump and circle, and the last ones shove the first
ones forever.
- A formation that walks a few metres collapses into a ball.
- Units swap sides on the way and cross each other's paths.
- A group arrives strung out, fast units first.

**Solution:** `RtsGroupMove`, pure functions the game calls when it gives a MOVE or ATTACK_MOVE to a selection.
Avoidance while walking stays with the engine (`NavigationAgent3D` with avoidance on).
- **`targets(positions, target, spacing, max_spread)`:** one call that does the rest.
  - **The magic box** (a StarCraft II behaviour players rely on): a compact group (no wider than `max_spread`)
    ordered outside its bounding box keeps each unit's offset from the centre. The formation moves as it is.
  - A target inside the box, or a scattered group, gathers into **slots** around the target.
- **`slots(centre, count, spacing, facing)`:** a grid, `spacing` apart, with the first row facing the way the group
  walks; centred even when the last row is short.
- **`assign(positions, slots)`:** each unit gets a slot, globally closest pairs first. Every slot is used once, the
  total walk is near the optimum, and a line moved sideways does not cross.
- **`arrived(at, slot, radius, arrived_neighbours, crowd)`:** at the slot, or within `crowd` × radius of it while
  touching a neighbour that has stopped. The last ones don't push the first ones forever.
- **`group_speed(speeds)`:** the slowest member's speed, for a group that should arrive together (optional; many games
  let fast units run ahead).

**Tuning:**
- `spacing` (1.2–1.5 × the unit's diameter);
- `max_spread` (about a screen's width in metres; wider groups gather);
- the arrival `crowd` factor (2–4).

**Host (the game):**
- on a right-click, `var t := RtsGroupMove.targets(unit_positions, point, spacing)`, then each unit gets its
  `t[i]` as its MOVE point (recipe 58);
- each unit's `NavigationAgent3D`: `avoidance_enabled = true`, `radius` = the unit's radius, `max_speed` = its speed
  (or `group_speed`); feed `velocity_computed` into the body's velocity;
- each physics frame, stop a unit when `arrived(...)` says so, passing the positions of its group's stopped units
  nearby.

**Pitfalls:**
- every unit sent to the same point (the classic ball);
- slots assigned by selection order (paths cross; units swap places);
- "arrived" only at the exact slot (the crowd never settles);
- avoidance with a radius smaller than the model (units overlap), or without the agent's `velocity_computed` (avoidance
  does nothing);
- a `%` in a test message that is itself formatted with `%` (write `%%`).

**Test:** `tests/unit/test_r61_group_move.gd`:
- slots: the count, the spacing, the front row, centred for uneven counts;
- assignment: every slot once, within 15% of brute force, no crossing on a sideways move;
- the magic box: a shape kept, gathering for a target inside, a scattered group, one unit;
- arrival and the crowd rule;
- the group speed.
