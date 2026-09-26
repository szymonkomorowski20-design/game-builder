# Godot 4.4 → 4.7 — what changed since most model training data

Source: the official migration guides in the pinned 4.7 docs
(`BAZA-AI/fala-05/zrodla/godotengine--godot-docs-4.7/tutorials/migrating/upgrading_to_godot_4.{4,5,6,7}.rst`),
extracted 2026-09-26. Model knowledge is densest around Godot 4.2–4.3; treat anything below as
**overriding** what you remember. When unsure about a signature, read
`classes/class_<name>.rst` in that folder (version-exact) — `gb kb` may return the dev-branch copy.

## Breaking for GDScript (will not parse or behaves differently)

| Version | Change | Do this |
|---|---|---|
| 4.4 | `@export_file` stores `uid://…` instead of `res://…` when set in the Inspector | don't string-compare exported paths with `res://`; in 4.5+ use `@export_file_path` when you need raw paths |
| 4.4 | `Curve` enforces its `min_value`/`max_value` range (default 0–1) | widen the range before adding points outside it |
| 4.4 | `FileAccess.store_*` return `bool` | you may check the result (was `void`) |
| 4.5 | `Resource.duplicate(true)` copies only resources **internal** to the file; external ones stay shared | use `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` for the old full copy — matters for per-instance stats/tuning Resources |
| 4.5 | `Node.get_rpc_config()` → `get_node_rpc_config()`; `JSONRPC.set_scope()` → `set_method()` | rename |
| 4.5 | `TileMapLayer` physics chunking on by default — `get_coords_for_body_rid()` is imprecise | set `physics_quadrant_size = 1` when you need exact cells from a collision |
| 4.5 | Navigation regions update asynchronously (threads) | wait at least one physics frame after changing a navmesh before querying paths |
| 4.5 | Jolt: `Area3D` always reports overlaps with static bodies | filter with collision layers/masks |
| 4.6 | **Jolt is the default 3D physics engine** for new projects | 3D physics tuning/tutorials from ≤4.5 may assume GodotPhysics3D |
| 4.6 | `.tscn` no longer writes `load_steps`; saves unique node IDs | big diffs when re-saving old scenes — run *Project → Tools → Upgrade Project Files* once and commit |
| 4.6 | Glow default blend = Screen (brighter); volumetric fog brighter | re-tune `Environment` after upgrading |
| 4.6 | `AStar2D/3D.get_point_path`, `AStarGrid2D.get_id_path/get_point_path` return **empty** when the start point is disabled/solid | check for empty path; start from a walkable cell |
| 4.7 | Overriding a method with a typed return inherits the return type → **needs an explicit `return`** | add `return null` / a value at the end of overrides |
| 4.7 | Setting an element of a packed-array property no longer calls the property's setter | call the setter yourself (reassign the array) if you relied on it |
| 4.7 | Keyboard/mouse `InputEvent.device` is `DEVICE_ID_KEYBOARD` / `DEVICE_ID_MOUSE`, not `0` | check event type, or compare with the constants — never `device == 0` |
| 4.7 | `AudioStreamPlayer.area_mask` default `1` → `0` | if you use `Area2D/3D` audio bus overrides, set the mask back to layer 1 |
| 4.7 | `AnimationNodeBlendSpace1D/2D`: boolean `sync` → `sync_mode` enum | set `sync_mode` explicitly in blend spaces |
| 4.7 | `RichTextLabel.ImageUpdateMask.UPDATE_WIDTH_IN_PERCENT` → `UPDATE_WIDTH_UNIT`; `AudioEffectSpectrumAnalyzer.tap_back_pos` removed | rename / remove |
| 4.7 | Jolt `WorldBoundaryShape3D.plane.d` sign flipped vs 4.6; `SoftBody3D` mass defaults to 1 kg total | flip `d`; re-tune soft bodies |
| 4.7 | `CanvasItem` line drawing no longer adds the antialias feather | draw thicker lines if they now look thin |

## New language/API features worth using

- **Variadic functions** (4.5): `func log_all(prefix, ...args):` — one rest parameter, last, no default; not typed as `Array[T]`.
- **Abstract classes/methods** (4.5): `@abstract class Shape:` / `@abstract func draw()` — use for State/Command bases instead of empty methods that silently do nothing.
- `@export_file_path` (4.5): export a raw `res://` path.
- `Resource.duplicate_deep(mode)` (4.5): explicit deep-copy control.
- Audio (4.3+, all present in 4.7): `AudioStreamInteractive` (adaptive music with a transition table), `AudioStreamSynchronized` (layered stems), `AudioStreamPlaylist`, `AudioStreamRandomizer` (`random_pitch_semitones` added), `AudioStreamPolyphonic`. See the `game-audio` skill.
- Web export (4.3+): audio defaults to **Sample** playback — no `AudioEffect`s, no reverb/Doppler, no `AudioStreamGenerator`. Switch *Audio → General → Default Playback Type.web* to **Stream** (or per player) if the game needs them.

## Not changed but frequently misremembered

- `TileMap` is deprecated since 4.3 — use one `TileMapLayer` node per layer.
- Godot 3 names (`KinematicBody2D`, `move_and_slide(velocity)`, `yield`, `onready var`, `export var`, `instance()`) — `gb lint` flags them.
