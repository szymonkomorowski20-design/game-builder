# 15 — Pause

**Problem:** pausing stops everything — including the pause menu itself — or leaves some systems running.

**Solution:** `get_tree().paused = true` freezes every node in the default `INHERIT` process mode. The pause menu sets
`PROCESS_MODE_ALWAYS` so it still receives input. Toggle on the `pause` input action in `_unhandled_input`, and also pause
on `NOTIFICATION_APPLICATION_FOCUS_OUT`.

**Process modes cheat sheet:** `INHERIT` (default, freezes), `PAUSABLE` (freezes even if parent is ALWAYS),
`WHEN_PAUSED` (only runs while paused — menu animations), `ALWAYS` (music manager, pause menu), `DISABLED`.

**Pitfalls:** `Tween`s and `Timer`s follow their node's mode (a Tween created by `create_tween()` on a paused node stops);
`SceneTree.create_timer()` ignores pause unless `process_always=false`; audio keeps playing unless its player is pausable;
forgetting to unpause when leaving to the main menu (the next scene starts frozen).

**Test:** `tests/scenarios/r15_pause.gd` (real input action through the harness).
