# Reference games — open-source Godot 4 projects worth reading

Real, working Godot 4 code to study when a spec needs a structure you haven't built yet: a state machine at game
scale, a save service, a multiplayer stack, a card data model. Read them for **patterns**. Our own recipes
(`recipes/`, tested) stay the first stop.

**Checked 2026-09-27:**
- **Licence:** read from each repo's LICENSE file (and its README where the licence is split). Spot-checked twice
  by hand.
- **Godot version and renderer:** from each repo's `project.godot`.
- **Tests:** looked for in the repo tree.
- **Activity:** GitHub API `pushed_at`.

Repositories change, so re-check the licence before copying anything.

**Finding:** none of the 17 has an automated test suite (GUT or gdUnit4). `godot-open-rts` has hand-run test scenes.
So these are references for structure, never for testing practice. That is what our harness, recipes and templates
are for.

## Using code from them
- MIT/Apache/CC0 code may be copied. For MIT and Apache, keep the licence notice, in the file header plus a
  `THIRD_PARTY.md` (or the credits). Name the source in the commit message.
- **Assets are a separate licence.** Check the column below and `game-assets`. CC-BY needs in-game credit. NC or
  "not stated" means don't ship it.
- Their Godot versions range from 4.1 to 4.7. Check APIs against `game-implement/godot-4.4-4.7-changes.md` before
  copying anything older than 4.4.

## The five to read first
1. **[godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects).** Official, MIT, tracks
   the current Godot (the checked demo is 4.7). One concept per demo, e.g. three multiplayer transports side by side
   in `networking/` (compare with recipes 39 and 46).
2. **[gdquest-demos/godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg).** MIT, 4.6 Compatibility. It
   has a clean autoload architecture (`Gameboard`, `Gamepiece`, `CombatEvents`, `FieldEvents`) and a real Dialogic
   integration.
3. **KenneyNL Starter Kits (listed below).** Code MIT, assets CC0 (per their READMEs), 4.6. They're minimal and share
   one shape (`scripts/`, `objects/`, `scenes/main.tscn`, an audio autoload), which is "a small complete Godot
   project".
4. **[P1X-in/Tanks-of-Freedom-3-D](https://github.com/P1X-in/Tanks-of-Freedom-3-D).** A shipped game, MIT code
   (4.4). `scripts/services/` holds `multiplayer.gd`, `online.gd`, `relay.gd`, `autodiscovery.gd` and
   `saves_manager.gd` side by side.
5. **[bearlikelion/BoomerShooter](https://github.com/bearlikelion/BoomerShooter).** Small, MIT, 4.7 Forward+. One
   generic FSM (`Scripts/state.gd`, `state_machine.gd`) drives both the player (`Player/States/*`: 7 states) and
   enemies (`Scripts/Enemies/States/`). Compare with recipe 14.

## Index
| Repo | Genre | Godot · renderer | Code | Assets | Last push | Study |
|---|---|---|---|---|---|---|
| [godotengine/godot-demo-projects](https://github.com/godotengine/godot-demo-projects) | many demos, 2D+3D | 4.7 (checked `2d/platformer`) | MIT | per demo — check | 2026-09 | `networking/*`, `2d/platformer`, `3d/platformer` |
| [KenneyNL/Starter-Kit-3D-Platformer](https://github.com/KenneyNL/Starter-Kit-3D-Platformer) | 3D platformer | 4.6 · Forward+, Jolt | MIT | CC0 (README) | 2026-03 | `scripts/player.gd`, `scripts/view.gd`, `objects/` — compare with our `platformer-3d` |
| [KenneyNL/Starter-Kit-FPS](https://github.com/KenneyNL/Starter-Kit-FPS) | FPS | 4.6 · Forward+ | MIT | CC0 (README pattern of the kits — confirm) | 2026-08 | `scripts/weapon.gd`, `weapons/*.tres` (weapons as data) — compare with our `fps-3d` |
| [KenneyNL/Starter-Kit-Racing](https://github.com/KenneyNL/Starter-Kit-Racing) | arcade racing, 3D | 4.6 · Forward+, Jolt | MIT | CC0 (confirm) | 2026-08 | `scripts/vehicle.gd`, `vehicle-motorcycle.gd`, `view.gd` |
| [KenneyNL/Starter-Kit-City-Builder](https://github.com/KenneyNL/Starter-Kit-City-Builder) | city builder, 3D | 4.6 · Forward+ | MIT | CC0 (confirm) | 2026-03 | `scripts/builder.gd`, `data_map.gd`, `structure.gd` (grid placement + a data-driven catalogue) |
| [KenneyNL/Starter-Kit-Match-3](https://github.com/KenneyNL/Starter-Kit-Match-3) | match-3, 2D | 4.6 | MIT | CC0 (confirm) | 2026-08 | `scripts/tile.gd`, `scripts/main.gd` (match detection) |
| [gdquest-demos/godot-open-rpg](https://github.com/gdquest-demos/godot-open-rpg) | turn-based RPG, 2D | 4.6 · Compatibility | MIT | check per folder | 2026-05 | autoloads, `addons/dialogic/` integration |
| [P1X-in/Tanks-of-Freedom-3-D](https://github.com/P1X-in/Tanks-of-Freedom-3-D) | turn-based strategy, voxel 3D | 4.4 | MIT (code + graphics) | fonts OFL/Apache; music CC-BY(-SA); icons CC0 | 2025-10 | `scripts/services/*` (LAN, online relay, saves) |
| [lampe-games/godot-open-rts](https://github.com/lampe-games/godot-open-rts) | RTS, 3D | 4.3 · Forward+ | MIT | not split — check | 2025-01 | `source/match/`, `source/data-model/`, `tests/manual/` (hand-run test scenes) |
| [quiver-dev/tower-defense-godot4](https://github.com/quiver-dev/tower-defense-godot4) | tower defense, 2D | 4.7 | MIT | **CC-BY 4.0** (`LICENSE_ASSETS.txt`) | 2026-08 | `entities/enemies/enemy_fsm.gd`, `interfaces/` (tower placement) |
| [godotengine/tps-demo](https://github.com/godotengine/tps-demo) | third-person shooter | 4.7 | MIT | **CC-BY 3.0** (models, music) | 2026-08 | `enemies/red_robot/` (AI, hit parts), `door/`, `effects_shared/` |
| [bearlikelion/BoomerShooter](https://github.com/bearlikelion/BoomerShooter) | retro FPS | 4.7 · Forward+ | MIT | not split — check | 2026-07 | `Scripts/state_machine.gd`, `Player/States/*`, `Resources/player_save.gd` |
| [TheDahoom/FPS-Multiplayer-Template](https://github.com/TheDahoom/FPS-Multiplayer-Template) | FPS multiplayer template | 4.3 · Forward+ | MIT | not split — check | 2026-04 | `scripts/world.gd` (authority), `scripts/Global.gd` |
| [manuu1311/RaccoonRacing](https://github.com/manuu1311/RaccoonRacing) | racing, online + local | 4.6 · Compatibility | MIT | not split — check | 2026-09 (brand new, 0 stars) | `scripts/Network/`, `scripts/Server/`, `webrtc_native/` |
| [rametta/Pali](https://github.com/rametta/Pali) | trading-card game, 3D | 4.1 · Compatibility | Apache-2.0 | not split — check | 2024-04 (stale) | `Cards/CardResource.gd` (card data), `Scenes/World/Deck.gd` |
| [max99x/wutw-public](https://github.com/max99x/wutw-public) | roguelite deckbuilder, 2D (a commercial game released as public domain) | 4.7 · Forward+ | **CC0** | CC0 | 2026-09 | `wutw/cards/` (tiers 0–6 = power curve as data), `quests/`, `relics/`, `shops/` — compare with our `cards-2d` |
| [TinyTakinTeller/GodotProjectZero](https://github.com/TinyTakinTeller/GodotProjectZero) | incremental/idle, 2D | 4.4 · Compatibility | MIT (scripts) | **mixed, several NC** — don't reuse assets | 2026-05 | `.github/workflows/gdlint.yml` (lint in CI), `addons/BulletUpHell/` |

"Confirm" means the kit's README wasn't read individually. The 3D-Platformer kit's README states "Assets …
are CC0 licensed"; the others follow the same template but haven't been checked one by one.

## Excluded (checked)
| Repo | Why |
|---|---|
| Quaint-Studios/Reia | AGPL-3.0 code |
| StampedeStudios/sum-zero | GPL-3.0 code |
| Poobslag/turbofat | a Godot 3 project (GLES2, no `config/features`), despite list descriptions |
| lyuai/opencards | not a Godot project (Python/TypeScript) |
