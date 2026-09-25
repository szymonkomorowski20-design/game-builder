# 01 — Top-down 8-direction movement

**Problem:** move a character in 8 directions with a snappy but not instant feel; diagonals must not be faster.

**Solution:** `Input.get_vector()` (length ≤ 1) × speed as the target velocity; approach it with `move_toward`
at `acceleration` (input held) or `friction` (no input). `CharacterBody2D.motion_mode = FLOATING` (no floor/gravity).

**Tuning:** `speed` (px/s), `acceleration`, `friction` (px/s²) — exported on the node.

**Pitfalls:** building the direction from two `get_axis` calls without normalising (diagonal √2 faster);
moving in `_process` instead of `_physics_process`; forgetting `delta`.

**Test:** `tests/scenarios/r01_topdown_diagonal.gd` — diagonal speed equals `speed`; friction stops.
Files: `top_down_mover.gd`, `topdown.tscn`. Source: Godot docs "2D movement overview" (knowledge base: `gb kb "2D movement overview get_vector"`).
