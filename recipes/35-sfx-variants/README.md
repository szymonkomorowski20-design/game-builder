# 35 — SFX variants with built-in streams (Randomizer + Polyphonic)

**Problem:** the same footstep 40 times sounds mechanical; one `AudioStreamPlayer` per sound per enemy wastes
nodes; hand-written voice pools (recipe 21) are code you have to maintain.

**Solution:** `SfxBank` — one `AudioStreamPlayer` with an `AudioStreamPolyphonic` stream (`polyphony` voices);
each named sound is an `AudioStreamRandomizer` with its variants, random pitch (`random_pitch` 1.06 = ±6 %) and
volume, `PLAYBACK_RANDOM_NO_REPEATS` so the same variant never plays twice in a row. `play(&"step")` returns
a stream id (or `INVALID_ID` for an unknown name or when all voices are busy).

**When recipe 21 instead:** you need per-voice control (stop the oldest, different buses per sound) or Godot
older than 4.2. For positional sounds use `AudioStreamPlayer2D/3D` with an `AudioStreamRandomizer` stream.

**Sources of variants:** record 3–5 takes, or generate them — the `8bit-sfx-komplet` pack (gry-wiedza fala 05,
MIT) has ~200 variants per category with text descriptions.

**Pitfalls:** `play_stream()` before the player is playing → engine error (`_ready` starts it); `max_polyphony`
on the player is a different mechanism (same stream overlapping) — don't combine; randomizer weights default to 1.

**Deterministic games:** `AudioStreamRandomizer` draws its variant from the global RNG and its pitch and volume on the
audio thread, so a game whose tests replay a seeded match plays differently whenever a sound is heard. Give the bank
its own `rng` (a `RandomNumberGenerator`): it then picks the variant (never the same one twice in a row), the pitch
and the volume itself, on the main thread (found by the proof game Kamienna Marchia).

**Test:** `tests/unit/test_r35_sfx_variants.gd`.
