# Starter packs — licensed assets per template, already in the library

A free, legal default for a template's art and sound. It's one option on the art decision, next to placeholder
shapes, generated art (paid tools, human go first) and the human's own art. **The human picks.**

Every pack below:
- is in the gry-wiedza library with its licence file and a provenance note (checked 2026-09-27);
- is CC0 unless marked.

## Where the files are
- **Local:** `<BAZA-AI>/assety/<wave>/<pack>/`. BAZA-AI is found the same way `gb kb` finds it (`GAME_BUILDER_KB`, or
  `Desktop/gry-wiedza/BAZA-AI`).
- **Public:** the same packs are zipped in the gry-wiedza repo:
  - wave 1 packs in `paczki/`;
  - later waves in `fala-0N/paczki/` (e.g. `fala-03/paczki/kaykit-prototype-bits-1.0.zip`).
- **Register:** always cite the **author's page** (column "Author page") as the source. Never cite the library,
  a mirror or an aggregator (`game-assets` red flag).

Search more: `node tools/gb/gb.js assets "<what>" --typ sprite_2d|model_3d|animation|audio|ui_skin`.

## How to use a pack (agent)
1. Offer it on the art decision (brief / bootstrap) with what it looks like: open `Preview.png` or `Sample.png`
   from the pack and show it.
2. Copy **only the files the game uses** into `assets/<kind>/<pack>/`, plus the pack's `License.txt`.
3. Add one register row per pack folder in the same commit. This is the pattern from the Lodowy Loch game, and it
   names the used files:
   `| assets/sprites/tiny-dungeon/ | https://kenney.nl/assets/tiny-dungeon — Tiny Dungeon 1.0 via gry-wiedza BAZA-AI assety/fala-01/tiny-dungeon; hero = tile_0085, wall = tile_0040; License.txt copied alongside | Kenney (www.kenney.nl) | CC0-1.0 | no | <date> |`
4. Import right (`game-assets` §3, `docs/asset-pipeline.md`), then run `gb lint`, then take `gb shot` and look at
   it.
5. Keep one style family per game. Kenney's "Tiny" packs mix with each other; KayKit packs mix with each other.
   Kenney and KayKit side by side is a decision for the art bible, not a default.

## Per template

### `platformer-2d` (side view) — **gap in the library**
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Prototype characters/props | gdquest-prototype-sprites | `assety/fala-03/gdquest-prototype-sprites` | https://github.com/GDQuest/game-sprites | SVG, deliberately "prototype" look |
| Hit / jump / coin SFX | impact-sounds; 8bit-sfx-komplet (**MIT**, keep notice) | `assety/fala-01/impact-sounds`; `assety/fala-05/8bit-sfx-wav` | https://kenney.nl/assets/impact-sounds; https://github.com/cportka/8bit-sfx | 8bit-sfx has a manifest with categories (jump, coin…) |
| Effects | particle-pack | `assety/fala-02/kenney-particle-pack` | https://kenney.nl/assets/particle-pack | |

**Missing:** side-view pixel tiles and an animated player. Kenney's *Pixel Platformer* and *Platformer Pack Redux*
(both CC0 on kenney.nl) are the candidates for the next library wave. Adding them takes a download and needs the
human's go. Until then, use code-drawn shapes or the prototype sprites, marked as placeholders.

### `topdown-2d`
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Characters, walls, floors, items | tiny-dungeon | `assety/fala-01/tiny-dungeon` | https://kenney.nl/assets/tiny-dungeon | 16×16. `Tilemap/tilemap_packed.png` has no spacing; `tilemap.png` has 1 px spacing (see `Tilesheet.txt`). Used in Lodowy Loch |
| Outdoor / town | tiny-town | `assety/fala-01/tiny-town` | https://kenney.nl/assets/tiny-town | same style and size as tiny-dungeon |
| Alternative style | roguelike-rpg-pack | `assety/fala-01/roguelike-rpg-pack` | https://kenney.nl/assets/roguelike-rpg-pack | 16×16 sheet; don't mix with the Tiny packs |
| Hits, footsteps | impact-sounds, rpg-audio | `assety/fala-01/impact-sounds`, `assety/fala-02/kenney-rpg-audio` | https://kenney.nl/assets/impact-sounds, https://kenney.nl/assets/rpg-audio | |
| Shots, pickups | sci-fi-sounds or 8bit-sfx-komplet (**MIT**) | `assety/fala-02/kenney-sci-fi-sounds`, `assety/fala-05/8bit-sfx-wav` | https://kenney.nl/assets/sci-fi-sounds | |

### `grid-puzzle-2d`
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Tiles + hero | tiny-dungeon | as above | https://kenney.nl/assets/tiny-dungeon | proven in Lodowy Loch (ice/rock/exit from the same sheet) |
| Move / bump / win | casino-audio (slide), impact-sounds, interface-sounds | `assety/fala-02/kenney-casino-audio`, `assety/fala-01/impact-sounds`, `assety/fala-01/interface-sounds` | https://kenney.nl/assets/casino-audio, …/impact-sounds, …/interface-sounds | |
| Win jingle | Kenney music-jingles | `<BAZA-AI>/fala-05/zrodla/kapishdima--soundcn/assets/kenney_music-jingles` | https://kenney.nl/assets/music-jingles | a copy inside a larger repo; cite Kenney's page |

### `cards-2d`
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Card faces and backs, chips, dice | Boardgame Pack (Kenney) | `assety/fala-03/codingame-board-game/packs/board game/` | https://kenney.nl/assets/boardgame-pack | a standard 52-card deck (`cardClubs2…A`, …) + 3 back colours; the library copy comes from CodinGame's SDK assets (CC0 notice included) |
| Card sounds | casino-audio | `assety/fala-02/kenney-casino-audio` | https://kenney.nl/assets/casino-audio | slides, shuffles, chips |
| Panels | ui-pack, ui-pack-rpg-expansion | `assety/fala-01/ui-pack`, `assety/fala-02/kenney-ui-pack-rpg-expansion` | https://kenney.nl/assets/ui-pack, …/ui-pack-rpg-expansion | |

### `platformer-3d`
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Blocks, platforms, props | kaykit-prototype-bits | `assety/fala-03/kaykit-prototype-bits-1.0` | https://github.com/KayKit-Game-Assets/KayKit-Prototype-Bits-1.0 | glTF |
| Animated hero | kaykit-character-pack-adventures | `assety/fala-03/kaykit-character-pack-adventures-1.0` | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Adventures-1.0 | 5 rigged `.glb` with 76 animations each (measured), including `Idle`, `Running_A`, `Jump_Start`, `Jump_Idle`, `Jump_Land` — they map onto recipe 44's idle/run/jump/fall |
| Enemies | kaykit-character-pack-skeletons | `assety/fala-03/kaykit-character-pack-skeletons-1.0` | https://github.com/KayKit-Game-Assets/KayKit-Character-Pack-Skeletons-1.0 | 4 rigged `.glb`, 95 animations each (measured) |
| Nature | nature-kit | `assety/fala-01/nature-kit/Models/GLTF format` | https://kenney.nl/assets/nature-kit | Kenney style — decide against KayKit |
| Grid textures | prototype-textures | `assety/fala-02/kenney-prototype-textures` | https://kenney.nl/assets/prototype-textures | for greybox levels |

### `fps-3d`
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Greybox | prototype-textures | as above | https://kenney.nl/assets/prototype-textures | |
| Surfaces | ambientCG Bricks001, Concrete001, Metal001, Ground001, Rock001, WoodFloor001 | `assety/fala-02/ambientcg-<Name>` | https://ambientcg.com/view?id=<Name> | 1K PBR sets with a ready `.tres` material |
| Level kits | kaykit-dungeon-remastered, kaykit-space-base-bits | `assety/fala-03/…-1.0` | https://github.com/KayKit-Game-Assets/KayKit-Dungeon-Remastered-1.0, …/KayKit-Space-Base-Bits-1.0 | glTF |
| Shots, impacts | sci-fi-sounds, impact-sounds; mrbid sound effects (**Unlicense**) | `assety/fala-02/kenney-sci-fi-sounds`, `assety/fala-01/impact-sounds`, `<BAZA-AI>/fala-04/zrodla/mrbid--Sound-Effects` | https://kenney.nl/assets/sci-fi-sounds, …/impact-sounds, https://github.com/mrbid/Sound-Effects | |

## For every game
| Need | Pack | Local | Author page | Notes |
|---|---|---|---|---|
| Buttons, panels | ui-pack | `assety/fala-01/ui-pack` | https://kenney.nl/assets/ui-pack | |
| Key / gamepad glyphs | input-prompts | `assety/fala-01/input-prompts` | https://kenney.nl/assets/input-prompts | for rebinding screens and tutorials |
| UI sounds | interface-sounds | `assety/fala-01/interface-sounds` | https://kenney.nl/assets/interface-sounds | |
| Music | game-music-composer tracks (140 OGG) | `<BAZA-AI>/fala-05/zrodla/gvastethecreator--game-music-composer` (zip: `fala-05/paczki/gmc-muzyka-ogg.zip`) | https://github.com/gvastethecreator/game-music-composer | CC0; styles: exploration, combat, town, menu, credits |
| Jingles | Kenney music-jingles | see grid-puzzle-2d | https://kenney.nl/assets/music-jingles | win, lose, level up |
| Font | Godot's default (Open Sans SemiBold) | built in | — | **Kenney Future / Future Narrow (in ui-pack) have no Polish letters except ó** — measured. Use them only for Latin-only titles or numbers |

## Not for release (in the library for learning only)
Anything whose library record says "brak licencji", "tylko lokalnie", NC, GPL (for assets), the Ready Player Me
animation library, or Mixamo content. `gb credits` blocks the unknown ones, but don't copy them in the first place.
