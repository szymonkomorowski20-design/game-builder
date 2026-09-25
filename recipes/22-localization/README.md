# 22 — Localization

**Problem:** English strings hardcoded in scenes and scripts; translating later means hunting through every file;
"Coins: " + str(n) breaks in languages with different word order.

**Solution:** every player-visible string is a **key** (`MENU_PLAY`) in `strings.csv` (`keys,en,pl,…`). Godot imports
the CSV into `*.translation` files — register them in *Project Settings → Localization → Translations*. `Label.text =
"MENU_PLAY"` is translated automatically (auto-translate is on by default); in code use `tr("HUD_COINS").format({"n": n})`
— placeholders **after** translation so each language places them. Switch with `TranslationServer.set_locale("pl")` and
store the choice in settings (17). `LocaleLoader` builds the same Translation objects in code (tests, mods).

**Pitfalls:** concatenating translated fragments; fonts without Polish/Cyrillic/CJK glyphs (test with the longest
language — German/Polish run ~30 % longer than English, give Labels room or autowrap); `*.translation` files are generated
— don't commit them (the game-builder `.gitignore` already ignores them); plurals (`tr_n`) need gettext `.po`, not CSV.

**Test:** `tests/unit/test_r22_localization.gd`.
