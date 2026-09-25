# 13 — Save / load with versions and migrations

**Problem:** saves outlive code. A renamed field or a crash during writing destroys players' progress — the worst bug a game can ship.

**Solution:** JSON saves in `user://` with a `version` field; `load_save` runs migrations up to `CURRENT_VERSION`;
writes go to `.tmp` and are renamed into place (atomic); corrupt / missing / too-new files return an explicit `Result`
so the game can tell the player instead of silently resetting. Each system contributes its own `to_dict()`
(inventory 09, achievements 12) — the save file is their composition.

**Tuning:** none — but every change of save shape = bump `CURRENT_VERSION` + a migration + a test with an old-format fixture.

**Pitfalls:** saving Resources/Objects directly (`var_to_str` of objects executes code on load — never load untrusted
`var_to_str`/`ResourceLoader` data from user files); no version field; overwriting the only save in place;
treating JSON numbers as ints without casting; defaults hiding a corrupt file.

**Test (tier A):** `tests/unit/test_r13_save_load.gd` — round trip, migration, corrupt/missing/too-new, overwrite.
