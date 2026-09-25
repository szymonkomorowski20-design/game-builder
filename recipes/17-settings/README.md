# 17 — Settings & key rebinding

**Problem:** volume sliders that don't persist, settings files that break after an update, rebinding that wipes the
gamepad bindings.

**Solution:** `GameSettings` over `ConfigFile` in `user://settings.cfg`: every read has a default (old/missing files
just work), volumes are linear 0–1 converted with `linear_to_db` (0 → mute, not −inf), fullscreen only touched when
not headless, `rebind` replaces only `InputEventKey`s of an action (physical keycodes = layout-independent WASD).
`action_using_key` powers the "already bound — swap?" prompt. Call `load_settings(); apply()` once at startup (autoload).

**Pitfalls:** storing settings inside the save game (settings are per machine, saves are per player); `keycode` instead of
`physical_keycode` (AZERTY players); rebinding `ui_*` actions by accident; audio buses referenced by index (use names).

**Test:** `tests/unit/test_r17_settings.gd`.
