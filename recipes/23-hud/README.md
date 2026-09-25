# 23 — HUD bound by signals

**Problem:** the player script does `get_node("/root/Game/UI/HpBar").value = hp` — every UI change breaks gameplay,
and gameplay tests need the UI.

**Solution:** the HUD *listens*: it gets a `Health` via an exported NodePath (or the `Events` bus) and connects to
`damaged` / `healed`; the wallet binds with `bind_wallet(w)` and `balance_changed`. Text goes through `tr()` keys (22).
Gameplay can run and be tested with no HUD in the scene.

**Layout tips:** HUD in a `CanvasLayer` (not moved by the camera); anchors/containers instead of absolute offsets for
different aspect ratios; test at 16:9 and 16:10 and on the smallest target resolution; keep critical info away from
edges (TV/Steam Deck safe area ≈ 5 %).

**Pitfalls:** polling in `_process` every frame instead of signals; HUD holding references to freed players after
respawn (reconnect on spawn via the bus); lambdas connected in `_ready` are disconnected automatically only when the
HUD is freed.

**Test:** `tests/scenarios/r23_hud.gd`.
