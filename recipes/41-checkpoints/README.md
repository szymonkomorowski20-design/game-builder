# 41 — Checkpoints (furthest one wins, never backwards)

**Problem:** after dying the player should restart at the last checkpoint — but "last touched" is wrong: walking
back over an earlier flag must not move the respawn point back, and a death before any checkpoint must use the start.

**Solution:** `CheckpointTracker` (pure `RefCounted`, 2D or 3D positions): `reach(order, position)` accepts only a
higher `order`, `respawn_position` is where to put the player, `reset()` starts over, `activated(order)` fires once
per new checkpoint. `Checkpoint` (Area2D) reports bodies of group `player` and lights its flag; the level owns one
tracker and moves the player on death (`checkpoint_level.gd`, using recipe 01's mover). For 3D use an Area3D with
the same two lines.

**Tuning:** the `order` of each checkpoint (place them in order along the level); flag colours.

**Pitfalls:** "last touched wins" (players lose progress by backtracking); the checkpoint detecting enemies or
projectiles (filter by group or collision mask); respawning with the old velocity (zero it); storing node references
instead of positions (freed when the level reloads). To keep checkpoints across quitting, save `active_order` with
recipe 13.

**Test:** `tests/unit/test_r41_checkpoints.gd`, `tests/scenarios/r41_checkpoints.gd`. Scene: `checkpoint_demo.tscn`.
