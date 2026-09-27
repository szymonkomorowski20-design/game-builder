# Asset pipeline — getting art and sound into Godot 4.7 without losing it

A checked reference behind `game-assets` §3 and `game-audio`.

**Sources:**
- Godot docs **4.7 branch** (the gry-wiedza copy `BAZA-AI/fala-05/zrodla/godotengine--godot-docs-4.7`). Paths below
  are relative to it.
- The Blender 4.2 manual (glTF exporter).
- The importers' own repositories, read 2026-09-27.

Licences and the register are `game-assets`' job; starter packs per template are in `docs/starter-packs.md`.

## Import basics (every asset type)
- Put source files inside the project; Godot imports them and caches the result in `.godot/imported/`.
- **Commit** the `<file>.import` next to each asset (it holds the import settings). Also commit the `.uid` files
  Godot 4.4+ writes next to scripts and shaders. That is our AGENTS.md rule; the import docs don't cover `.uid`.
- **Never commit** `.godot/`. The scaffold's `.gitignore` already does this.

Source: `tutorials/assets_pipeline/import_process.rst`.
- Load imported assets with `load()`/`ResourceLoader`. `FileAccess` on an imported `.png` works in the editor and
  **breaks in the exported game**.
- To change settings: select the file → Import dock → **Reimport**. Selecting another file first discards the
  edit silently. Several files can be reimported together (only ticked options change). Project-wide defaults
  per type: *Project Settings → Import Defaults*.
- `Keep File (exported as is)` ships the raw file untouched. `Skip File (not exported)` leaves it out of the build.

## Images

### 2D pixel art (the scaffold's `--pixel-art` sets the project side)
- **Project settings:**
  - `rendering/textures/canvas_textures/default_texture_filter` = Nearest;
  - `rendering/2d/snap/snap_2d_transforms_to_pixel` = true (read at start-up; don't combine with
    `snap_2d_vertices_to_pixel`);
  - viewport stretch with integer scale.

  Source: `classes/class_projectsettings.rst`.
- **Texture import:** `Compress > Mode` = **Lossless** (the 2D default), mipmaps off.
- **Detect 3D:** if a 2D texture is ever used on a 3D material, Godot switches it to VRAM Compressed with mipmaps
  and reimports, printing a note in Output. For pixel art on 3D (billboards, retro 3D), set `Detect 3D > Compress
  To` or `Compress > Mode` back to Lossless. Source: `tutorials/assets_pipeline/importing_images.rst` "Detect 3D",
  "Compress mode".
- Blurry pixel art is almost always one of four things:
  - the filter (Linear);
  - a non-integer scale;
  - the sprite sitting between pixels (snap);
  - VRAM compression.

  `gb shot`, then look at the PNG (`game-assets` §5).

### 2D HD and 3D textures
- 3D: **VRAM Compressed** (4–6× less video memory) with mipmaps. Normal maps: `Compress > Normal Map` = Detect.
  For DirectX-style maps also set `Process > Normal Map Invert Y`.
- Large 2D art: Lossless or Lossy. VRAM compression shows artifacts in 2D.
- `Process > Size Limit` caps the long side on import. Mobile and web GPUs may reject textures over about 4096 px,
  and `gb lint` warns above 4096.
- `Process > Fix Alpha Border` (on by default) prevents dark halos on filtered sprites; keep it on.
- SVG is rasterised at import (`SVG > Scale`). Convert text in the SVG to paths first.

## Audio (`tutorials/assets_pipeline/importing_audio_samples.rst`)
| Use | Format | Import |
|---|---|---|
| Short, frequent SFX | **WAV** (cheap to decode) | `Force > Mono` for most SFX; `Force > Max Rate` well under 48 kHz where it doesn't hurt (e.g. 22050 for voice); the default compression is Quite OK Audio |
| Music, ambience, long voice | **Ogg Vorbis** | `Loop` + `Loop Offset` (seconds) for music; `BPM`/`Beat Count`/`Bar Beats` for interactive music (recipe 34) |
| Many simultaneous long sounds on web/mobile | MP3 | less CPU than Ogg, bigger |

- 24-bit and >48 kHz gain nothing in a game. Voice can be mono at about 22 kHz.
- Keep reverb out of the files and put it on buses (but web plays in Sample mode without bus effects; see
  `docs/platforms.md`).
- WAV `Edit > Loop Mode` (Forward/Ping-Pong/Backward with begin and end). A looping stream never emits `finished`.

## 3D from Blender (or any DCC)

### Format
- **glTF 2.0** is the recommended format:
  - `.glb` is one file, with textures embedded;
  - `.gltf` + `.bin` + textures diff better and keep textures separate.
- **`.blend` directly:** needs Blender 3.0+ (3.5+ recommended) installed and found through the editor setting
  `filesystem/import/blender/blender_path`. It doesn't work in CI or on machines without Blender, so **for gb and CI
  export `.glb` and commit that**. Source: `importing_3d_scenes/available_formats.rst`.
- FBX is imported with ufbx (the default since 4.3). OBJ has no skeletons, pivots or animation. DAE is only for simple,
  static scenes.

### Before export (in Blender)
- **Orientation:** Godot is Y-up and right-handed. A character's **front faces +Z**; in Blender its front is −Y.
  Source: `importing_3d_scenes/model_export_considerations.rst`.
- **Apply transforms**, triangulate (a Triangulate modifier plus the exporter's *Apply Modifiers*), and put
  skeletons in rest pose. Author lighting in Godot, not in Blender.
- **Animations:** in the exporter's default *Actions* mode, only the active action and actions stashed on **their
  own NLA track** are exported. Unstashed actions vanish silently. Name clips with `loop`/`cycle` (prefix or
  suffix, no hyphen needed) so they import looping. Source: Blender manual 4.2, glTF 2.0 add-on, "Animation" (the same text is in
  KhronosGroup/glTF-Blender-IO `docs/blender_docs/scene_gltf2.rst`);
  `node_type_customization.rst`.
- **Blend shapes:** enable *Export Deformation Bones Only*, or shading breaks. Source: `available_formats.rst`.
- Materials are double-sided unless *Backface Culling* is on in Blender. Double-sided costs performance.

### Name suffixes (automatic, case-insensitive, with `-`, `$` or `_`)
Source: `importing_3d_scenes/node_type_customization.rst`.

| Suffix | Result |
|---|---|
| `-col` / `-convcol` | keeps the mesh and adds static trimesh or convex collision |
| `-colonly` / `-convcolonly` | **removes the mesh** and leaves only a `StaticBody3D` collision |
| `-navmesh` | **the mesh becomes a navigation mesh** (the visual is gone) |
| `-occ` / `-occonly` | adds an occluder / replaces the mesh with an occluder |
| `-rigid` | the mesh node itself is imported **as** a `RigidBody3D` |
| `-vehicle`, `-wheel` | the mesh becomes a child of a new `VehicleBody3D` / `VehicleWheel3D` |
| `-noimp` | not imported at all |
| `-alpha`, `-vcol` (materials) | alpha transparency; albedo from vertex colours |

A model called "floor_col" gets collision, and one called "wall_colonly" loses its look. That's intended when
planned and a bug when not. Opt out with the import options `nodes/use_node_type_suffixes` = false (or
`nodes/use_name_suffixes` = false; `-noimp` and glTF `-loop` still apply).

### After import — keep your edits
- The imported scene is regenerated on every reimport. **Durable edits:**
  - *Advanced Import Settings → Actions → Extract Materials* (writes `.tres` files that survive reimport, but if
    the material is renamed in Blender, the link must be re-set);
  - per animation, *Save to file* (then custom tracks survive).

  A mesh's *Save to File* writes the `Mesh` resource out for nodes that need it directly (`MultiMeshInstance3D`,
  particles). The docs don't promise that edits to it survive reimport. Source:
  `importing_3d_scenes/advanced_import_settings.rst`.
- For gameplay (scripts, extra nodes), **instance** the model in your own scene (e.g. `Player.tscn` → the `.glb`
  instance as a child), or use *New Inherited Scene*. You can add nodes, but you can't remove base nodes or edit
  subresources in place. Source: `importing_3d_scenes/import_configuration.rst` "Scene inheritance".
- Collision without naming tricks: Advanced Import Settings → node → `Generate > Physics`:
  - body: Static/Dynamic/Area;
  - shape: Trimesh (only for static level geometry) or convex/decomposed for moving bodies.
- **Animation Library import mode** (change the import type, then restart the editor) turns a glTF of clips into an
  `AnimationLibrary` that many characters can share.
- **Retargeting** (Mixamo, Mesh2Motion, KayKit): Skeleton3D → `bone_map` with `SkeletonProfileHumanoid`. Keep
  *Overwrite Axis* on for shared animations, and *Fix Silhouette* for A-pose models. Red or magenta bones are
  warnings and don't block the import. Source: `retargeting_3d_skeletons.rst`. The gry-wiedza wave 04 guides
  cover Mesh2Motion.
- Measured on the library's KayKit characters: one `.glb` carries the rig plus 76–95 clips (`Idle`, `Running_A`,
  `Jump_Start`, `Jump_Idle`, `Jump_Land`…). They map onto recipe 44's AnimationTree states.

## 2D animation (`tutorials/2d/2d_sprite_animation.rst`)
- **`AnimatedSprite2D` + `SpriteFrames`** for frame animation only. Frames come from separate images or *Add
  frames from a Sprite Sheet*.
- **`Sprite2D` (`hframes`/`vframes`) + `AnimationPlayer` keying `frame`** when the same clip also moves hitboxes,
  plays sounds or changes other properties. It combines with an AnimationTree (recipe 44).
- `play()` takes effect on the next processing step. If you flip or swap something in the same frame, call
  `advance(0)` after `play()` to avoid a one-frame glitch.

## Tile maps
- **`TileMapLayer`**, one node per layer. `TileMap` is deprecated; its bottom panel can extract layers into
  `TileMapLayer` nodes. Save the `TileSet` as a `.tres` shared by all layers. Source: `classes/class_tilemap.rst`,
  `tutorials/2d/using_tilemaps.rst`.
- TileSet: set the exact `Tile Size` **before** dragging in the sheet, then accept auto-creation. For sheets with
  gaps (Tiny Dungeon's `tilemap.png` has 1 px spacing, per its `Tilesheet.txt`), set the separation, or use the `_packed` sheet. Put physics,
  custom data and terrains (autotiling: create a terrain set first, then terrains) on the TileSet. Recipe 27 has a
  tested setup. Source: `tutorials/2d/using_tilesets.rst`.

## Third-party importers (addons are dependency decisions — the human approves adding one)
| Tool | For | Licence | Godot | State (2026-09-27) | Produces |
|---|---|---|---|---|---|
| [Aseprite Wizard](https://github.com/viniciusgerevini/godot-aseprite-wizard) (`godot_4` branch) | `.aseprite`/`.ase` | MIT | 4.x | active (v9.8.0) | `SpriteFrames`, AnimationPlayer tracks, a static texture, a tileset `AtlasTexture`; tags become clips |
| [YATI](https://github.com/Kiamo2/YATI) | Tiled `.tmx`/`.tmj` | MIT | 4.3+ (v2.2.7) | active | one `TileMapLayer` per Tiled layer, objects, collisions. **Turn off the editor's multi-threaded import** or importing several maps can freeze or crash the editor (its README's known issue) |
| [godot-ldtk-importer](https://github.com/heygleeson/godot-ldtk-importer) | LDtk `.ldtk` | MIT | 4.1+ | **quiet** (latest release v2.0.1, 2024-09; last push 2025-02 per the GitHub API) | a scene with level/world/entity nodes; TileSet edits survive reimport. Tile layers: the main-branch code (`src/layer.gd`) creates `TileMapLayer`, but the README still says "TileMaps". Check what the version you install actually emits; `TileMap` is deprecated |

Without Aseprite: export a sprite sheet plus JSON from any editor and slice it in `SpriteFrames`. Without Tiled or
LDtk: paint in Godot's own TileMapLayer editor, which is the simplest option for small games.

## Checks after any import
1. `gb lint`: register rows, texture sizes.
2. `gb verify`: import errors fail the import step (and gb retries once when a new asset is preloaded).
3. `gb shot --movie --scene <scene>`, then look at it: scale, filtering, orientation (3D models facing +Z), animation
   playing.
4. Record the `Run result`.
