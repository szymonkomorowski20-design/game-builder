---
name: game-audio
description: Use when a game needs sound effects, music or voice — choosing legal sources, importing, buses and volume settings, sound variants, adaptive music, and proving that the game actually makes sound. Triggers — "dodaj dźwięki", "muzyka", "SFX", "efekty dźwiękowe", "głośność", "muzyka w walce", "audio", "sound", "music", or a spec phase that mentions sound. The agent cannot hear, so it picks sounds by text descriptions and licences and leaves the listening to the human at the playtest gate.
---

# Game Audio — legal sounds, wired right, proven to play

**Core principle:** you cannot hear. So every sound you add is chosen by **text** (a description, a category,
a licence), wired through **tested patterns**, proven to **play** (`gb shot --movie` reports the audio peak),
and **judged by the human** at the playtest gate.

## 1. Decide in the spec (not while coding)
Add an *Audio* section to the spec: list of sounds per event (jump, hit, pickup, UI click, win/lose), music
moods (explore/combat/menu), buses (`Master` ← `Music`, `SFX`, `UI`), web target yes/no, and the source of each
sound (pack + licence). Tuning table gets the volumes (linear 0–1) and pitch variation.

## 2. Sources — licence first
- Search the library: `node tools/gb/gb.js assets "<description>" --typ audio` — records show licence and path.
  Descriptive queries work for the 8888 generated 8-bit effects (`"laser falling zap"`, `"coin bright"`).
- Guides (quoted data): `gb kb "licencja dźwięków"`, `gb kb "AudioStreamInteractive"`; the library's
  *fala-05/wiedza* covers legal sources, Godot audio, chiptune, FMOD/Wwise and AI audio.
- Allowed for release: CC0, CC-BY (with attribution), MIT/Unlicense packs whose **sound files** are covered.
- **Never:** sounds ripped from other games, films or meme sites — even when the repository's code licence is MIT
  (two such repositories were found and purged in the library); "royalty free" without a named licence; a
  licence claimed by a mirror instead of the author; CC-BY-NC in a paid or ad-supported game.
- AI-generated sound: record the model and its **weights'/service** licence; code licence is not enough.
- Every file → a row in `.ai/assets/REGISTER.md` (source URL, author, licence, attribution text). `gb lint`
  flags assets missing from the register. CC-BY attribution goes into the game's credits screen.
- Copy files into `assets/audio/<sfx|music|voice>/` with the licence file next to them.

## 3. Import
WAV for short repeated SFX, Ogg Vorbis for music/voice, MP3 for many simultaneous long sounds on web/mobile.
Music loops: *Import dock → Loop*; for adaptive music also *BPM, Beat Count, Bar Beats*. No 8-bit WAV compression.

## 4. Wire it — start from a tested recipe
| Need | Recipe (plugin `recipes/`) |
|---|---|
| Volume sliders per bus, saved; mute at 0 | 17-settings |
| Many SFX at once, variants, random pitch | 35-sfx-variants (built-in `AudioStreamRandomizer` + `AudioStreamPolyphonic`) — or 21-audio (own voice pool) |
| Music that follows the game state | 34-adaptive-music (`AudioStreamInteractive`) |
| Pause menu still makes UI sounds | 15-pause (`PROCESS_MODE_ALWAYS` on the audio node) |
| Hit feedback | 32-hit-stop, 33-hit-flash + a sound from the bank |

Gameplay code emits events (`Events.item_picked`, `Health.damaged`); an audio node listens and plays — gameplay
never owns `AudioStreamPlayer`s for one-shot effects.

## 5. Web export
The browser build uses the **Sample** playback mode by default: no bus effects, no reverb/Doppler, no
`AudioStreamGenerator`. If the spec needs them → *Project Settings → Audio → General → Default Playback
Type.web = Stream* (more latency) and test the web export. First sound only after a click/key (autoplay policy).

## 6. Prove it plays (Run result)
- Logic (which sound, which voice, which mood): GUT tests — they run headless on the dummy audio driver.
- That sound actually comes out: `gb shot --movie --name <step> --scene res://…` → the report includes
  `audio peak <x> dBFS`; `-inf` means silence. Put it in the step's `Run result:` line.
- Loudness balance, feel, sync with animation: **the human** at the playtest gate — ask specific questions
  ("is the jump sound too loud against the music?", "does the hit feel heavy?").

Template: [audio-doc-template.md](audio-doc-template.md) — copy to `.ai/audio.md` when the game has more than a handful of sounds.

## Red Flags — STOP
- A sound file without a REGISTER row, or with "unknown/royalty free" as licence.
- A sound from another game/film/meme site "just for the prototype" — it ends up shipped.
- Volume set on individual players instead of buses; `-80 dB` instead of mute.
- A visual/audio step closed with `audio peak -inf` where sound was expected.
- Claiming something "sounds good" — you cannot know; ask the human.
