---
name: game-save
description: Use for anything that stores player progress or settings — save and load, save slots, autosave, versioned save formats with migrations, corrupt-file handling and compatibility between releases. Treated as tier A because a bug here destroys players' progress. Triggers — "zapis gry", "wczytywanie", "save", "load", "sloty zapisu", "autosave", "postęp gracza", "zapis się zepsuł", "nowa wersja psuje zapisy".
---

# Game Save — tier A: never lose a player's progress

**Core principle:** a save written by any released version must load in every later version — or the game
says clearly why not. Proven by tests with **old-format fixtures** and a **detection proof**, not by trying it once.

## 1. Design (in the spec)
- What is saved (progress, inventory, quests, flags, settings?) — settings live in their own file
  (`user://settings.cfg`, recipe 17), not in the save.
- Format: JSON (readable, diffable) via composed `to_dict()` of each system (inventory 09, achievements 12,
  quests 19). **Never** `var_to_str`/Resources from user-writable files (object deserialization can run code).
- `version` field from day one; slots; autosave points; what happens on corrupt/too-new files (message, backup).

## 2. Implement (recipe 13 is the baseline)
Atomic write (`.tmp` then rename); `load` returns an explicit result (OK/MISSING/CORRUPT/TOO_NEW), never silent
defaults; migrations `vN → vN+1` in order; numbers cast back from JSON floats; keep the previous save as
`.bak` on overwrite if the design wants recovery.

## 3. Test (tier A)
- Round trip of every saved system.
- **Fixtures:** each release adds a save made by that release to `tests/fixtures/saves/<version>.json`; a test
  loads all of them with the current code.
- Corrupt, missing, too-new, and interrupted write (temp file left behind) cases.
- **Detection proof:** break a migration → the fixture test goes RED → revert → GREEN; paste the outputs
  (recipe 13 did this: a broken gold→coins migration failed two tests).

## 4. On every change of save shape
`game-pre-implement` flags it → bump version → migration → fixture test → release notes. A deliberate
incompatible break is a decision in the Decisions Ledger, announced to players.

## Red Flags — STOP
- Changing a saved field name without a migration.
- `load` that returns defaults on a parse error.
- No fixture from the previous release.
- Saving by overwriting the only file in place.
