---
name: game-level-design
description: Use to design, build and validate levels — layout, teaching through level design, pacing, secrets, tilemaps and procedural generation — with automatic checks that every level is completable and a bot or a human that actually plays it. Triggers — "zaprojektuj poziom", "mapa", "level", "plansza", "labirynt", "loch", "tileset poziomu", "generowanie poziomów", "za długi poziom", "gracz się gubi".
---

# Game Level Design — teach, test, validate every level

**Core principle:** a level is a lesson with a test. Each one introduces or combines mechanics on purpose, and
**every** level (hand-made or generated) is proven completable by a machine before a human plays it.

## 1. Design on paper (spec)
Per level: goal, mechanic(s) it teaches or combines, beats (introduce safely → practise → combine/twist →
rest), intended length (path length or seconds), secrets, fail points and checkpoints. A level list table in
the spec keeps the curve visible (`game-balance` §3).

Principles: show before asking (the first gap can't kill you); one new idea at a time; landmarks and lighting
lead the eye; critical path readable, secrets optional; checkpoint before anything that takes > 30 s to redo.

## 2. Build
- Tiles: one `TileMapLayer` per layer; collision and custom data (hazard, cost) on the TileSet (recipe 27).
- Text/ASCII or data-authored levels are easy to diff and to test; external editors (LDtk, Tiled) via importers
  — decide in the spec.
- Generated levels: seeded generator (recipe 28), show the seed in the pause menu for bug reports.

## 3. Validate (machine)
- **Top-down / grid:** `LevelCheck.analyze()` (recipe 37) over **all** levels and many seeds: exit and every
  pickup reachable, no key/door soft-lock, path length within the design band, dead-end count.
- **Side-view / physics:** a bot scenario that plays the level with input actions (`GbScenario`: `press`,
  `tap`, `expect`) to the goal — the platformer template's scenarios are the model. A replay of the human's
  run (`gb record`) guards against later regressions.
- **Look:** `gb shot --movie --scene res://levels/<n>.tscn` — nothing cut off, readable.

## 4. Validate (human)
Playtest with tasks ("find the exit", "find the secret"); note where players hesitate or die repeatedly —
that is the level telling you something (`game-playtest`).

## Red Flags — STOP
- A new level without a completability check.
- Validating only the level you edited instead of all levels/seeds.
- The first appearance of a hazard can kill the player with no warning.
- Generator output shipped without a seed shown to players.
