# 21 — Audio: SFX voices, buses, music

**Problem:** every enemy owns an AudioStreamPlayer; 40 hits in one frame = 40 overlapping, clipping copies of the same
sound; sound stops when the node that played it is freed.

**Solution:** `SfxPlayer` autoload with a fixed number of voices on the `SFX` bus: `play(stream)` uses a free voice or
steals the oldest, adds ±8 % pitch variation. Positional sounds (`AudioStreamPlayer2D`) stay on the emitting node but
use the same bus. Music: one `AudioStreamPlayer` on a `Music` bus in an autoload with `PROCESS_MODE_ALWAYS`,
crossfade with two players and a Tween. Volumes per bus come from settings (17).

**Bus layout (Project → Audio → Buses):** `Master` ← `Music`, `SFX`, `UI` (+ optional `Voice`). Effects (reverb in caves,
low-pass under water) go on buses, not on players.

**Pitfalls:** `.wav` for long music (use `.ogg`), `.ogg` for very short SFX that repeat (use `.wav`, no decode cost);
loop flags set in the import dock, not in code; sounds played from a node that is `queue_free`d the same frame;
web export: audio starts only after the first user click (browser autoplay policy).

**Test:** `tests/unit/test_r21_audio.gd` (runs headless on the dummy audio driver).
