# Godot pitfalls — measured, not remembered

Every entry below was hit while building game-builder (harness, Pong dogfood, platformer template,
33 recipes) on Godot 4.7.2 and is covered by a test or a recipe. Symptom → cause → fix.

## Running and testing

| Symptom | Cause | Fix |
|---|---|---|
| The first import after adding assets fails (`p_position > length` in `file_access_memory`), the second passes | a WAV whose data chunk runs past the end of the file: Godot refuses it on the first import only, and the warm cache hides it afterwards — every fresh clone, CI run and export fails | `gb lint` reports it (`wav-header`); pad the file with zero bytes to its declared length or re-export it; reproduce any failed import on a clean copy (`gb snapshot checkout`) before dismissing it |
| Game "passes" with exit code 0 but logged `SCRIPT ERROR` | runtime script errors don't change Godot's exit code | read the log — `gb run/verify` does this for you; never trust the exit code alone |
| `Identifier "Events" not declared` only under `gb check` / `--script` | autoload names are not compiled as identifiers outside a running game | in code that may be checked standalone use `get_node("/root/Events")` |
| A scenario presses an action but `_unhandled_input` never fires | `Input.action_press()` sets state but emits no event | the harness uses `Input.parse_input_event()` too; in your own tools do the same |
| Two runs of the same replay diverge | global RNG unseeded, or a system shares it | harness seeds the global RNG; give generators/decks their **own** `RandomNumberGenerator` with a seed |
| GUT test fails with "Unexpected Errors" on an expected bad input | `JSON.parse_string()` (and `push_error`) print engine errors, GUT treats them as failures | for input that may legitimately be invalid use `var j := JSON.new(); if j.parse(text) != OK: …` |
| Test comparing `lost_for >= 1.0` after 10 × `0.1` fails | float accumulation: 0.1 × 10 = 0.99999… | tests use exactly representable steps (0.125, 0.25) or `>= target - epsilon` |
| `test_…` "at line -1: Nonexistent 'float' constructor" | `get_shader_parameter()` returns `null` until the uniform is set | set every uniform once in `_ready`, guard reads with `null` |
| `gb lint` reports a broken `res://` in a comment or a test for a missing file | lint scans all text | build the path dynamically (`"res://x/" + "missing.tscn"`) for intentional misses; don't write example paths in comments |
| Viewport capture is black/empty headless | headless has no renderer | `gb shot` / `--write-movie` need a window (`--window`) |
| A test that sorts `StringName`s passes, then fails after unrelated code is added | `StringName` sorts by its interned address, not alphabetically, so the order depends on what was loaded first (recipe 52's test failed in the proof game) | compare as `String`s: `names.map(func(x): return String(x))` then `sort()`, or compare sets |
| A lambda "finds" a value but the variable is still `null` after `wait_until(func(): …)` | GDScript lambdas capture locals **by value**; assigning to an outer local inside the lambda changes only its copy | write through a container: `var found: Array[Node] = []` … `found.append(n)` inside the lambda |
| `print()` from a scenario is nowhere in the `gb scenario` report | gb shows only its own markers from the Godot log | use `note("…")` in the scenario — gb prints each line under the scenario and keeps them in `--json` |
| A scripted click in a headless scenario lands far from where it was aimed (×20 measured) | `Input.parse_input_event` takes window coordinates, and the headless window is tiny while the viewport is 1280×720, so the position is scaled | push mouse events into the viewport instead: `get_viewport().push_input(ev, true)` (viewport coordinates); keys can still go through `Input.parse_input_event` (the rts-3d template's `RtsHands`) |
| The camera drifts away in every headless scenario | edge pan reads the mouse at (0, 0), a corner, when there is no real pointer | pan with the screen edges only while the mouse is inside a focused window (recipe 65's `mouse_in_window()`) |
| `Lambda capture at index 0 was freed. Passed "null" instead.` from a `wait_until` | the lambda captured a node that was freed while it waited (a building destroyed, a unit killed) | capture a container instead: `var held := [node]` … `func(): return not is_instance_valid(held[0])` |

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
| A melee hitbox (`Area3D`) never hits a `StaticBody3D` target in a project on the default 3D physics | GodotPhysics doesn't report static bodies to areas (measured, recipe 47: 0 hits → all hits after switching the dummy to `CharacterBody3D`); Jolt does | make hittable things moving bodies (`CharacterBody3D`/`RigidBody3D`); don't rely on either engine's static-body behaviour |
| A client's copy of a synced node stays wrong (tampered, or missed an update) | `MultiplayerSynchronizer` in `ON_CHANGE` mode sends only changes | `ALWAYS` for moving state (the next packet corrects it); `ON_CHANGE` for rare state such as HP or a name — recipe 46 |
| One client's NaN input freezes or teleports an avatar for everyone | `Vector2(NAN, 0).limit_length(1)` is still NaN | reject `not dir.is_finite()` on the server before clamping — recipe 46 |
| Cleanup in a parent's `_exit_tree` errors on its children (`multiplayer`, `get_path()`) | children leave the tree before their parent | let each node clean up in its own `_exit_tree`, or keep references (a peer, a path) taken while in the tree |
| `Trying to assign invalid previously freed instance` when a unit dies | a typed variable, parameter, loop variable (`for u: Unit in list`) or typed lambda parameter received an Object that was already freed: the typed assignment checks it and stops the script | hold what can die in an untyped (`Variant`) variable and test `is_instance_valid(x)` before use; loop with `for x: Variant in list` (recipes 58, 59, 63 and the rts-3d template) |
| A child's `_ready` finds its parent not set up (an overlay or HUD reading the game's state) | children are ready before their parent | `if not parent.is_node_ready(): await parent.ready` |

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
| A respawned or teleported player instantly triggers the area it just left (a door, a fight's trigger) | after `global_position = …` the physics server still reports the body at its old place for a frame, so `overlaps_body()` and area signals see it there | arm the area a short time after a teleport or reset (0.3 s: the roguelite template's doors, the FPS template's encounter zones) |
| A 3D hit on the head counts as the body | the head's collision shape sits inside the body capsule (e.g. the capsule grows back after crouching), and the ray meets the capsule first | keep the head sphere above the capsule in every stance; test a headshot after a crouch and stand (FPS template M4) |
| A hitscan's first shot lands high | the shot was cast after its own recoil kick moved the view | cast along the view as it was when the trigger released the shot; the kick moves the next shot (FPS template M3) |
| Buildings placed during the game don't change the paths; units walk into them | a `NavigationRegion3D` bakes the geometry of its own children only (the default source), so a building added elsewhere is not cut out | add obstacles under the navigation region and rebake after placing or removing one (`bake_navigation_mesh(true)`, one bake at a time) |
| A unit sent to a building or a mine never arrives, or walks around to its far side | reach measured to the obstacle's centre, and a navigation target inside an obstacle ends the path at the nearest navigable point, often behind it | measure reach to the near edge (a `closest_point` of the footprint) and walk to a point on the near side |

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
| A physics spike every second in a busy fight, average frame fine | an effect makes a new mesh / material per shot (tracers) | share one mesh and one material per colour; stretch with `scale` after `look_at` |
| The exported exe won't start on Windows 11 ("application control policy blocked this file") | Smart App Control blocks a new unsigned exe; with the pack embedded every build is a new exe | `binary_format/embed_pck=false`: the exe is the stock template, the game is the `.pck` beside it; never switch the protection off |
| … and it still won't start with `embed_pck=false`, though an identical exe in another game's folder runs | the verdict is kept per file: a newly written copy of the stock template can be blocked (Kamienna Marchia, the same MD5 as Operacja Pył's exe) | `gb export --smoke` then runs the pack under the editor binary (`--main-pack`) and says the exe didn't run; tell the owner to play from the editor (F5); never switch the protection off or trick it |
| A bot scenario passes on the harness's seed and the same claim fails in another run | one seed is one game: a bot that won there lost the same mission on half of the others | check a bot claim on several seeds (an env var per scenario, e.g. `M3_SEED`); seed each game inside the scenario (a chain of games must not depend on how long the one before took) |
| Bot games differ from run to run; a failing scenario won't reproduce | the navigation server's async map/region iterations and threaded avoidance depend on thread timing | in the tests: `navigation/world/map_use_async_iterations=false`, `region_use_async_iterations=false`, `avoidance/thread_model/avoidance_use_multiple_threads=false`, and a synchronous `bake_navigation_mesh(false)` while the harness runs |
| … and then a big battle can strain the physics budget (80 units: once 17.9 ms p95 for the worst frame of each second, other runs within 10 ms) | single-threaded avoidance, sensitive to the machine's load | a feature override keeps both: `avoidance_use_multiple_threads=false` plus `avoidance_use_multiple_threads.template=true` (export templates only); measure the budget with both values, more than once |
| A script error at a `bool(...)` conversion, and a smart order that never fires on some targets (right-clicking an enemy did nothing) | `bool(target.get(&"prop"))` where the target has no such property: `get()` returns null and `bool(null)` is an error | compare `target.get(&"prop") == true` |
| "The function signature doesn't match the parent" on a helper named `_set` / `_get` / `_input` | `Object._set(StringName, Variant)`, `_get` and `Node._input(InputEvent)` are engine virtuals | name helpers differently (`_replace`, `_read`, `_stick`) |
| "String formatting error: unsupported format character" from a test message | a literal `%` (e.g. "15%") inside a string that is then formatted with `%` | write `%%` |
| "Invalid argument for "_enter()": argument 1 should be "State" but is "GuardBrain.State"" | an enum-typed parameter (`s: State`) inside the same `class_name` script (the 4.7.2 parser) | type the parameter, and the variable holding the state, as `int` |
| "Cannot infer the type of "x" variable because the value doesn't have a set type" | `var x := d.get("k", false) == true`, or `a and callable.call()`: a Variant on one side | write the type: `var x: bool = …` |
| A test fails with "[0.0] expected to equal [0.0]", or a hold at 3.4 m doesn't equal 3.4 | floating point: 2.0 + 0.7 is not 2.7, a ray hit comes back as 3.3999…, cos(π/2)² is 1e-33 | compare within a tolerance (`assert_almost_eq`, `expect_near`) or in whole units (`roundi(x * 10.0)`) |
| Sorted StringNames come out in an odd order | `StringName` `<` compares pointers, not letters | sort `String`s, or compare as sets (`size()` and `has()`) |
| A node that drives another acts a frame late: the body walked off the roof in the frame the climber should have caught it | children run `_physics_process` after their parent (tree order) | `process_physics_priority = -1` on the node that must go first |
| A `CharacterBody3D` pushed diagonally into a wall stops dead instead of sliding along it (a bot stuck at a crate's corner) | `wall_min_slide_angle` (15°): motion within that angle of the wall's normal stops, in grounded 3D motion too, not only floating | route bots round corners; lower the angle only if the game wants sliding at steep angles |
| An NPC stands still in an open street with a path to follow; `get_next_path_position()` is its own position | the navigation mesh's path points lie about 0.5 m above the ground (cell height rounding), and the agent's reach check is 3D, so a 0.5 m `path_desired_distance` is never met | set `path_height_offset` to that height (0.5), or raise the desired distances |
| An NPC "saw" the player where the player went after the sighting | a sighting flag updated every `think_every` s read together with the live position | take the position recorded at the look (recipe 68's `meter.last_seen`) |
| `gb perf` over budget in a short run, within it in a long one | the monitors are the worst frame of each second; with 60 samples a few start-up spikes (new materials, glyphs) set the p95 | measure 120 s or more before judging a budget |
| `Parameter "material" is null` (`material_get_instance_shader_parameters`) in a headless run, the scene otherwise fine | one mesh resource shared by the player (tracked by the harness) and other nodes with different `surface_material_override` (the dummy renderer; recipe 68's demo) | give the tracked node's mesh its own resource |
| Audio tests fail headless | — | they don't: the dummy driver plays streams (`playing == true`) — test logic, leave sound quality to the playtest |

## Project files

- Commit `*.uid` and `*.import`; ignore `.godot/` and `*.translation`.
- Export presets need `include_filter` and `exclude_filter` keys or export fails; web export needs the Compatibility renderer.
- The first windowed run on a machine can take ~75 s (shader cache) — not a hang.
