---
name: game-upgrade
description: Use to move a game to a newer Godot version or to update the game-builder tooling inside a game repo — reading the official migration notes, upgrading project files, and proving with gb verify, replays and screenshots that nothing changed that should not. Triggers — "zaktualizuj Godota", "nowa wersja Godota", "upgrade", "przejście na 4.8", "migracja silnika", "aktualizacja narzędzi", "tools update".
---

# Game Upgrade — change the engine, prove the game did not change

**Core principle:** an engine upgrade is a change like any other: branch, baseline, upgrade, and the **same**
evidence before and after — tests, scenarios, replays (state signature), screenshots. A difference is either an
intended fix or a regression; the human decides which.

## 1. Before
- Branch `chore/godot-<version>`; `gb verify` green on the old version (paste); `gb shot --accept` baselines for
  key scenes if none exist; replays recorded for core mechanics (`gb record`).
- Read the official migration notes for every version jumped (`tutorials/migrating/upgrading_to_godot_<v>.rst`);
  for 4.4–4.7 the plugin has them digested: `<plugin>/skills/game-implement/godot-4.4-4.7-changes.md`. List every
  item that touches this game (grep the API names).

## 2. Upgrade
- Install the new Godot next to the old one; point `GODOT_BIN` at it; update `config/features` version in
  `project.godot` (the scaffold pins it).
- Open the project once in the new editor or run `gb import`; run *Project → Tools → Upgrade Project Files…*
  (4.6+ writes new scene fields — commit that diff separately, it is mechanical).
- Fix the listed breaking changes; `gb check` + `gb lint` clean.
- Export templates for the new version (`gb doctor` reports missing ones).

## 3. Prove
`gb verify` (tests, scenarios, replays with state match), `gb shot --compare` for baselines, `gb export --smoke`
for each desktop target, human playtest of the core loop. Physics engine changes (Jolt defaults, 4.7 Jolt sign
flips) show up as replay mismatches — investigate, don't re-record without the human.

## Tooling update (game-builder)
`gb doctor` warns when `tools/gb` differs from the plugin → `node <plugin>/tools/gb/gb.js tools update --path .`,
then `gb verify`, commit alone. Harness/GUT updates: `harness install` / `tests install gut` from the plugin copy.

## Red Flags — STOP
- Upgrading on the main branch or without a green baseline.
- Re-recording replays or re-accepting screenshots to make the upgrade "pass".
- Mixing the mechanical project-file diff with real fixes in one commit.
