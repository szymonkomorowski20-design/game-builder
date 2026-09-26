# 38 — Colour-blind check (palette test + screen overlay)

**Problem:** red vs green teams, health bars, "good/bad" pickups — ~8 % of men can't tell some of these apart,
and nobody on the team notices because they see them fine.

**Solution:** `Colorblind.simulate(color, mode)` applies the Machado et al. (2009) matrices (deuteranopia,
protanopia, tritanopia, severity 1.0, linear RGB). `Colorblind.problems(pairs, min_distance)` returns every pair of
colours that must be told apart but collapses under some mode — put **the game's own palette pairs** in a GUT test
so a new colour can't silently break it. `colorblind_overlay.gdshader` does the same per pixel for a full-screen
preview: `preview.tscn` shows it; in a game put the `ColorRect` + material in a debug `CanvasLayer` and take
`gb shot --movie` with `mode` 1/2/3.

**Fix when flagged:** don't rely on hue alone — add shape/icon/pattern/label, or pick pairs that differ in
lightness and blue–yellow (blue vs orange passes all three modes).

**Tuning:** `min_distance` (0.25 default for UI-sized elements; stricter for tiny icons).

**Pitfalls:** checking only deuteranopia; testing colours from a mock-up instead of the ones the game loads;
treating a "colour-blind mode" filter as a fix (it shifts colours for everyone else too — better to design the
palette right and offer symbols).

**Test:** `tests/unit/test_r38_colorblind.gd` (simulation sanity, red/green flagged, blue/orange passes). Visual:
`gb shot --movie --scene res://38-colorblind-check/preview.tscn` — red and green render as two similar olive tones,
blue and orange stay distinct (checked 2026-09-26, Godot 4.7.2).
