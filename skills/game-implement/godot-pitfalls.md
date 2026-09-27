# Godot pitfalls — measured, not remembered

Every entry below was hit while building game-builder (harness, Pong dogfood, platformer template,
33 recipes) on Godot 4.7.2 and is covered by a test or a recipe. Symptom → cause → fix.

## Running and testing

| Symptom | Cause | Fix |
|---|---|---|
| Game "passes" with exit code 0 but logged `SCRIPT ERROR` | runtime script errors don't change Godot's exit code | read the log — `gb run/verify` does this for you; never trust the exit code alone |
| `Identifier "Events" not declared` only under `gb check` / `--script` | autoload names are not compiled as identifiers outside a running game | in code that may be checked standalone use `get_node("/root/Events")` |
| A scenario presses an action but `_unhandled_input` never fires | `Input.action_press()` sets state but emits no event | the harness uses `Input.parse_input_event()` too; in your own tools do the same |
| Two runs of the same replay diverge | global RNG unseeded, or a system shares it | harness seeds the global RNG; give generators/decks their **own** `RandomNumberGenerator` with a seed |
| GUT test fails with "Unexpected Errors" on an expected bad input | `JSON.parse_string()` (and `push_error`) print engine errors, GUT treats them as failures | for input that may legitimately be invalid use `var j := JSON.new(); if j.parse(text) != OK: …` |
| Test comparing `lost_for >= 1.0` after 10 × `0.1` fails | float accumulation: 0.1 × 10 = 0.99999… | tests use exactly representable steps (0.125, 0.25) or `>= target - epsilon` |
| `test_…` "at line -1: Nonexistent 'float' constructor" | `get_shader_parameter()` returns `null` until the uniform is set | set every uniform once in `_ready`, guard reads with `null` |
| `gb lint` reports a broken `res://` in a comment or a test for a missing file | lint scans all text | build the path dynamically (`"res://x/" + "missing.tscn"`) for intentional misses; don't write example paths in comments |
| Viewport capture is black/empty headless | headless has no renderer | `gb shot` / `--write-movie` need a window (`--window`) |

## Scenes, nodes, time

| Symptom | Cause | Fix |
|---|---|---|
| New scene "not there" right after `change_scene_to_*` | scene change is deferred | await one `process_frame` (the harness `load_scene` awaits two) |
| Pause menu freezes with the game | menu inherits pause | `process_mode = PROCESS_MODE_ALWAYS` on the menu; world stays `INHERIT` |
| Hit-stop never ends | the timer is slowed by `Engine.time_scale` too | `get_tree().create_timer(t, true, false, true)` (ignore time scale); restore `time_scale = 1` in `_exit_tree` |
| `Parallax2D` layer position never changes in a test | `Parallax2D` drives its own offset | measure on screen: `get_global_transform_with_canvas().origin` |
| Every enemy flashes when one is hit | one `ShaderMaterial` resource shared by all instances | a new material per instance (or `resource_local_to_scene`) |
| `var log` / `var name` warnings or odd behaviour | shadows a global function / Node property | pick another name (`trace`, `label`) |
| Node names compare unequal | `Node.name` is a `StringName` | compare with `&"Idle"` or `String(node.name)` |
| A hand-written 3D rotation in a `.tscn` points the wrong way (camera looks into the ground, light shines upward) | `Transform3D(…)` in a scene file lists the basis **row by row** (x.x, y.x, z.x, x.y, …), not as the column vectors | write rows, or set `rotation_degrees` in the scene instead; a scenario that measures the result (e.g. spring arm length in the open) catches it |
| 3D chase camera ends up inside the player's head next to a wall | `SpringArm3D` shortens exactly as designed | fade/hide the player mesh under ~1.5 m of arm, or raise the camera — a design decision for the spec |
| Mouse-look sensitivity changes with the window size | `InputEventMouseMotion.relative` is scaled by the viewport stretch (×10 measured in a headless run) | use `screen_relative` (4.3+) for camera look; `relative` stays right for dragging things in the viewport |
| `Area3D` pickup fires for the floor/walls under Jolt (4.5+) | Jolt reports overlaps with static bodies | give the pickup a mask with only the player's layer |

## Physics and navigation

| Symptom | Cause | Fix |
|---|---|---|
| Projectile passes through a hurtbox | Area on layer 0 / masks don't overlap | give hitboxes and hurtboxes dedicated layers (recipes 06–07: hitbox layer 3, hurtbox mask 3) |
| Contact damage applies once while standing inside | `area_entered` fires on entry only | intended; re-hit needs leave+enter or a timer with i-frames |
| `NavigationAgent2D` path empty at start; a navigation scenario fails 1 run in ~60 | the map's first iteration (id 1) exists at frame 0 but is **empty**; region polygons arrive ~3 frames later, later under load (async since 4.5) — a fixed "wait 2 frames" is a race (measured 4.7.2) | wait until `NavigationServer2D.map_get_path(map, from, to, true)` is non-empty (recipe 26 `map_ready()`), never a fixed frame count |
| Agent "arrived" but `is_navigation_finished()` is false | finish uses `target_desired_distance`, not your threshold | wait for `is_navigation_finished()` |
| Enemy "sees" through walls or hits itself with the sight ray | ray not masked/excluded | `PhysicsRayQueryParameters2D.create(from, to, wall_mask, [get_rid()])` |
| Top-down body slides/floors oddly | `motion_mode` GROUNDED for a top-down game | `motion_mode = MOTION_MODE_FLOATING` |
| Jump height 3 px higher than the tuning table | full gravity applied on the impulse frame | trapezoid integration: half gravity before and after the position update (platformer template) |

## Data, saves, localization, audio

| Symptom | Cause | Fix |
|---|---|---|
| Loaded ints compare unequal | JSON numbers are floats | cast with `int()` on load |
| Save format change breaks old saves | no version field / migration | versioned save + migration + test with an old-format fixture (recipe 13, tier A) |
| Deep copy of tuning Resource still shares sub-resources | 4.5 semantics of `duplicate(true)` | `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` |
| UI shows `HUD_COINS` instead of text | translations not registered in *Project Settings → Localization* | register the imported `*.translation` files; don't commit them (generated) |
| Rebinding a key removed the gamepad binding | erased all events of the action | erase only `InputEventKey`s; use `physical_keycode` |
| Silence in the browser build | autoplay policy | start audio after the first click/keypress |
| Reverb/generated audio missing on web | web **Sample** playback mode | *Default Playback Type.web* = Stream, test the web export |
| Engine error `stream_playbacks.is_empty()` | `get_stream_playback()` on an `AudioStreamPlayer` that is not playing | check `player.playing` first; for `AudioStreamPolyphonic` call `play()` once before `play_stream()`; for `AudioStreamInteractive` set `initial_clip` before playing |
| Audio tests fail headless | — | they don't: the dummy driver plays streams (`playing == true`) — test logic, leave sound quality to the playtest |

## Project files

- Commit `*.uid` and `*.import`; ignore `.godot/` and `*.translation`.
- Export presets need `include_filter` and `exclude_filter` keys or export fails; web export needs the Compatibility renderer.
- The first windowed run on a machine can take ~75 s (shader cache) — not a hang.
