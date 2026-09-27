---
name: game-assets
description: Use when a game needs art or other assets — sprites, tilesets, fonts, UI skins, 3D models, animations, textures — finding legal sources in the gry-wiedza library or elsewhere, importing them with correct Godot settings, registering the licence, and keeping placeholders honest. Triggers — "grafika", "sprite", "tileset", "model 3D", "tekstury", "czcionka", "animacje postaci", "assety", "placeholder", "pixel art". For sound and music use game-audio.
---

# Game Assets — legal, registered, imported right

**Core principle:** every file in `assets/` has a known author and a licence that allows this release,
recorded in `.ai/assets/REGISTER.md` **in the same commit** — `gb lint` checks it, `gb credits` turns it into
the credits and blocks licences that cannot ship.

## 1. Plan in the spec
Spec *Assets* section: each asset (or pack) with purpose, style constraint (resolution, palette, perspective),
source, licence. Placeholders are allowed and **marked** as placeholders (`assets/placeholder/`), with the
phase that replaces them.

## 2. Find
- Library: `node tools/gb/gb.js assets "<what>" --typ sprite_2d|model_3d|animation|animation_clip|ui_skin` — each
  record shows the pack, licence and path in BAZA-AI; packs with confirmed licences are listed in gry-wiedza
  `fala-0N/paczki/README.md` (Kenney, KayKit, Polygonal Mind, Mesh2Motion rigs and animations, UI skins…).
- Starter packs per template (checked licences, author pages for the register, known gaps such as side-view
  platformer tiles, and fonts without Polish letters): `gb doc starter-packs` (gry-wiedza).
- Consistency beats quantity: one style family (one author/pack series) per game where possible.
- Allowed for release: CC0, CC-BY (credit in game), MIT/BSD/zlib (keep notice), OFL for fonts. **Not:**
  "free for personal use", NC/ND, no licence, ripped/fan art of existing games, Ready Player Me animations with
  other characters, AI output whose model/service terms forbid it.

## 3. Import (Godot 4.7)
Full, sourced details (Detect 3D, name suffixes like `-colonly` that delete meshes, edits that survive reimport,
Blender export settings, importers for Aseprite, Tiled and LDtk): `gb doc asset-pipeline` (gry-wiedza).
- **Pixel art:** *Project Settings → Rendering → Textures → Default Texture Filter = Nearest*, integer scaling
  (`window/stretch` = viewport, scale mode integer), snap 2D transforms to pixel; the scaffold's `--pixel-art` sets these.
- **Sprites/atlases:** keep sprite sheets whole, `AnimatedSprite2D`/`SpriteFrames` or `AtlasTexture`; `gb lint`
  warns about textures > 4096 px.
- **Tilesets:** one `TileMapLayer` per layer (not `TileMap`); physics and custom data on the TileSet (recipe 27).
- **3D:** glTF/GLB preferred (Blender → glTF 2.0); set import scale and root type in the Import dock; Jolt is the
  default 3D physics in new 4.6+ projects. Mesh2Motion / Mixamo-style retargeting → gry-wiedza fala 04 guides.
- **Fonts:** keep the font's licence file next to it; check glyph coverage for every language you ship (Polish ąęłńóśźż).
- Commit the `.import` and `.uid` files; never commit `.godot/`.

## 4. Register (same commit)
`| assets/sprites/player.png | https://kenney.nl/assets/… | Kenney | CC0-1.0 | no | 2026-09-26 |`
Licence file copied next to the asset (or the pack's folder). Then `gb lint` (no unregistered assets) and,
before a release, `gb credits`.

## 5. Look
After importing, `gb shot --movie --scene <scene using it>` and open the PNG: scale, filtering (blurry pixel
art = wrong filter), transparency, z-order. Record the `Run result`.

Template: [art-bible-template.md](art-bible-template.md) — copy to `.ai/art-bible.md` before the first real art goes in.

## Red Flags — STOP
- An asset added without a REGISTER row, or with "free"/"unknown" as the licence.
- A licence taken from a mirror, a catalogue or an aggregator instead of the author.
- Mixed art styles "for now" with no placeholder marking.
- Referencing files outside the project folder.
