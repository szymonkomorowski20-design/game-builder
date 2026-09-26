# 34 — Adaptive music (AudioStreamInteractive)

**Problem:** music should change with the game (explore → combat → boss) without abrupt cuts, and gameplay code
should not deal with fades and timing.

**Solution:** `MusicDirector` builds an `AudioStreamInteractive` from named clips and one transition rule
(any → any, on the next bar, start of the new clip, cross-fade over `fade_beats`). Gameplay calls
`set_mood(&"combat")`; unknown names return `false`. Before playback starts, `set_mood` sets the initial clip
instead of touching the (not yet existing) playback. Make it an autoload with `PROCESS_MODE_ALWAYS`.

**For real music:** import each loop with **Loop**, **BPM**, **Beat Count** and **Bar Beats** set in the Import
dock — `TRANSITION_FROM_TIME_NEXT_BAR/NEXT_BEAT` only land on musical boundaries when the clip knows its tempo.
Layers of the same piece (drums, bass, melody) → `AudioStreamSynchronized` as one clip, fade layers with
`set_sync_stream_volume`. Legal music for testing: gry-wiedza fala 05 (`gmc-muzyka-ogg` CC0, DST CC-BY).

**Tuning:** `fade_beats`, which moods exist, transition timing per pair (add more `add_transition` rules for
special cases, e.g. boss → victory at clip end).

**Pitfalls:** `get_stream_playback()` on a stopped player → engine error (handled here); web export uses the
**Sample** playback mode by default, which drops bus effects — behaviour of interactive streams there is not
verified by this recipe, test the web build (or set the player's Playback Type to Stream); pausing the tree stops music unless
the director is `ALWAYS`; clips without BPM switch immediately.

**Test:** `tests/unit/test_r34_adaptive_music.gd` — sine tones stand in for music (dummy audio driver headless).
