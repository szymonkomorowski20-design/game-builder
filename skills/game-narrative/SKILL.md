---
name: game-narrative
description: Use for story, dialogue, quests and in-game text — branching conversations as data, quest logic driven by events, shared flags, localization-ready text keys, and checks that every dialogue branch and quest can actually be reached and finished. Triggers — "dialogi", "fabuła", "questy", "zadania", "NPC mówi", "rozmowa", "historia", "teksty w grze", "narracja", "story", "quest", "dialogue".
---

# Game Narrative — story as data, logic as events, every branch reachable

**Core principle:** writers edit **data** (dialogue files, quest definitions, string tables), gameplay reports
**events**, and a test walks every branch — a dialogue node nobody can reach or a quest that can't complete is a
bug like any other.

## 1. Structure
- Dialogue: data file per conversation (JSON/Resource) → runner → UI (recipe 18: `next`, `choices` with `if`
  flags, `set` flags). Big projects: Dialogic 2 or Dialogue Manager (MIT) — same separation.
- Quests: definitions with counted objectives; gameplay emits events (`"killed:slime"`), the quest log
  advances, completes once, saves progress (recipe 19).
- Flags: one shared dictionary (dialogue + quests + save) — names in a documented list, no ad-hoc strings.
- Text: keys, not sentences, in code and data (`tr("NPC_GUARD_HALT")`), placeholders filled after translation
  (recipe 22). Register the translations in Project Settings (otherwise the UI shows keys).

## 2. Validate (GUT)
- Every dialogue file parses; every `next`/choice target exists; every node is reachable from the start with some
  set of flags; every path ends (no loops without exit unless intended).
- Every quest objective's event is emitted somewhere in the code (grep in the test or a registry of events).
- Quest save round trip; renamed quest ids need a save migration (`game-save`).
- Localization: every key used in scenes/scripts exists in the CSV for every shipped language; long languages fit
  (`gb shot --movie` with the locale set).

## 3. Writing for games
Short lines (2 lines per box), the player's goal clear after every conversation, important info repeated in the
quest log, names consistent (a glossary in `.ai/`), no walls of text before the first input.

## Red Flags — STOP
- Dialogue text hard-coded in scripts.
- A choice shown whose `if` flag can never become true.
- Quest progress counted from UI code instead of gameplay events.
- Concatenated translated fragments ("You have " + n + " coins").
