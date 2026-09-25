# 16 — Scene transitions & background loading

**Problem:** `change_scene_to_file` hitches on big scenes, the cut is abrupt, and double-clicking "Play" starts two loads.

**Solution:** `SceneRouter` (make it an autoload): fade to black → `ResourceLoader.load_threaded_request` and poll
`load_threaded_get_status` each frame (a progress bar can read the `progress` array) → `change_scene_to_packed` → fade in.
A `busy` flag refuses overlapping requests; the overlay swallows clicks during the fade.

**Tuning:** `fade_time` (0.2–0.4 s).

**Pitfalls:** passing data to the next scene through the scene itself (use an autoload/state object);
`change_scene_*` is deferred — the new scene exists one frame later; the router must be `PROCESS_MODE_ALWAYS`
if you transition out of a paused game (then unpause); holding a reference to nodes of the old scene.

**Test:** `tests/scenarios/r16_scene_transition.gd`.
