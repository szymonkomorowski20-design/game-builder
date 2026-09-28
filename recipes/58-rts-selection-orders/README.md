# 58 — RTS selection and orders (click, box, groups, smart right-click, shift queue)

**Problem:** the player's hands are the RTS's first system. If selection and orders feel wrong, nothing else matters:
- a drag box grabs the town hall with the army;
- a click on an enemy mixes it into the selection;
- control groups keep dead units;
- right-click on a gold mine sends the knights to stand on it;
- shift-queued orders are lost when a target dies.

**Solution:** two classes without scenes. The game hands them its objects and a `to_screen` Callable, so the same code
serves 2D and 3D games and the tests.

- **`RtsSelection`:**
  - `click` takes the nearest object within `click_radius` px; shift toggles it;
  - an enemy or a neutral is selected **alone**, for its information, and takes no orders (`units()` is empty);
  - `box` takes own objects only, and **units over buildings** (a box with any unit drops the buildings); shift adds;
  - `select_same_kind` (a double-click) takes every own object of that `kind` on screen;
  - control groups: `assign_group(n)` (Ctrl+n), `add_to_group(n)` (Shift+n), `recall_group(n)` (n);
  - `prune()` drops the dead from the selection and the groups;
  - `limit` (0 = none; older games used 12) keeps the first caught.
- **`RtsOrders`** (one per unit): a queue of `{kind, at, target}`:
  - the kinds are MOVE, ATTACK, ATTACK_MOVE, STOP, HOLD, GATHER, BUILD and PATROL;
  - `give(order, shift)` replaces the queue, or with shift appends to it (STOP and HOLD always replace);
  - `current()` / `done()`: the body carries out the current order and says when it is finished;
  - PATROL goes back to the end of the queue;
  - an ATTACK on a dead target, a GATHER on a spent resource and a BUILD on a finished building end by themselves;
  - `RtsOrders.smart(team, can_gather, can_build, target, ground)` is the right-click: attack an enemy, gather a
    resource, help build an own unfinished building, else move.

**The objects** need `team: int` (−1 for neutrals and resources), `kind: StringName` and `is_building: bool`, and
optionally `alive: bool`, `is_resource: bool` and `finished: bool`.

**Host (the game):**
- `to_screen`:
  - 3D: `func(o): return Vector2.INF if camera.is_position_behind(o.global_position) else camera.unproject_position(o.global_position)`;
  - 2D: the canvas transform times the position.
- Draw the drag box yourself (a `Control` with `draw_rect`).
- Show selection circles and health bars for `selected`.
- On a right-click, give each unit in `units()` `RtsOrders.smart(...)`. For MOVE and ATTACK_MOVE, spread the targets
  with recipe 61's formation slots, so the group does not fight over one point.
- A unit plays a short "yes, sir" bark when it takes an order (readability, genre doc).

**Tuning:**
- `click_radius` (20–30 px);
- `limit` (0 or 12);
- `MAX_QUEUE` (16).

**Pitfalls:**
- selecting from the physics ray only: small units are hard to click, so use a radius in screen space;
- a box in world space under a tilted camera selects a trapezoid, not what the player sees;
- enemies mixing into an own selection, and then receiving orders;
- groups that keep freed nodes (always `is_instance_valid`);
- a freed target read into a typed variable or parameter (`var t: Object = order.target`): Godot refuses a freed
  instance there with a script error, and the order never ends. Read it as a Variant, then `is_instance_valid`;
- a method named `_set` (it overrides `Object._set` and fails to parse).
- reading an optional property with `bool(target.get(&"is_resource"))`: a unit or a building has no such property, `get()`
  returns null and `bool(null)` is a script error — the right click on an enemy never gave an attack order (found by
  the proof game Kamienna Marchia). Compare with `== true`.

**Test:** `tests/unit/test_r58_selection_orders.gd`:
- the click radius, shift-toggle, an enemy selected alone;
- the box: own units over buildings, a negative drag rect, shift adds, the limit;
- the double-click by kind on screen;
- control groups with dead members;
- the smart right-click table;
- the shift queue, STOP, PATROL, and a dead target ending its order.
