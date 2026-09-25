# 18 — Branching dialogue

**Problem:** dialogue hardcoded in scripts — writers can't edit it, branches are untestable.

**Solution:** dialogue as data (`guard.json`): nodes with `speaker`, `text`, `next` or `choices` (with `if` flag
conditions, `!flag` negation) and `set` (flags written on entering). `DialogueRunner` walks it and emits `line_shown` /
`ended`; the UI only displays and forwards `advance()` / `choose(i)`. Flags are a shared Dictionary — the same one quests
(19) and the save file (13) use.

**Scaling up:** for large scripts use Dialogic 2 or Nathan Hoad's Dialogue Manager (both MIT, Godot 4) — the same
separation (data ↔ runner ↔ UI) still applies. Text goes through `tr()` keys when localizing (22).

**Pitfalls:** choice indices from the unfiltered list (the UI must use `choices()`); typewriter effects that skip the
last characters when advancing; conditions as arbitrary code strings (`Expression`) from modded files.

**Test:** `tests/unit/test_r18_dialogue.gd` (also proves the JSON file parses).
