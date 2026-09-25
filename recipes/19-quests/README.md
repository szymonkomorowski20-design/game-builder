# 19 — Quests

**Problem:** quest logic spread over enemies, pickups and NPCs (`if quest_active: counter += 1` in the slime script).

**Solution:** gameplay only reports events (`quests.report("killed:slime")` — wire it once from the `Events` bus);
`QuestLog` holds quest definitions (counted objectives), status (LOCKED / ACTIVE / COMPLETED), progress capped at the
target, and emits `quest_started` / `objective_progress` / `quest_completed` for the HUD. Dialogue (18) starts quests
through flags; saves (13) store `to_dict()`; loading ignores quests that no longer exist.

**Pitfalls:** progress counted before the quest started (usually wrong — decide in the spec); completion firing
twice (rewards twice); saving quest *definitions* instead of progress; renaming quest ids without a save migration.

**Test:** `tests/unit/test_r19_quests.gd`.
