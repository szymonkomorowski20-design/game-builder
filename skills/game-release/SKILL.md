---
name: game-release
description: Use to prepare a game build for players — version, credits and licences, desktop and web exports that are smoke-tested as built, save compatibility, release notes, and a publishing step the human performs. Triggers — "wydaj grę", "zrób build", "release", "eksport", "wrzuć na itch", "opublikuj", "wersja demo", "zbuduj exe". Never publishes by itself.
---

# Game Release — a build players can run, legally, that we actually ran

**Core principle:** a release is a *built artifact that was run*, with every asset's licence cleared.
The editor run proves nothing about the export: filters drop files, templates differ, the browser plays audio
differently. And publishing is always the human's act.

## Preconditions (stop if any fails)
- Specs in the release are `implemented` with playtest verdicts; `.ai/STATE.md` has no open failures.
- `node tools/gb/gb.js verify` green on the release commit (paste it).
- Export templates installed (`gb doctor`); missing → the human installs them once (*Editor → Manage Export Templates*).

## Steps
1. **Version:** `application/config/version` in `project.godot` (semver), changelog entry (player-facing words), git tag after the human approves.
2. **Credits and licences:** `node tools/gb/gb.js credits` → writes `CREDITS.md`; **FAIL blocks the release** (non-commercial, no-derivatives, unknown or proprietary licences, registered files that don't exist). `gb lint` must show no unregistered assets. Show the credits in the game (menu → Credits) when any licence needs attribution (CC-BY) — the file alone is not enough for CC-BY.
3. **Desktop build:** `node tools/gb/gb.js export --preset "Windows Desktop" --smoke` — exports and runs the built `.exe` headless for 180 frames, failing on any error in its log (catches resources dropped by `exclude_filter`, missing autoloads). Linux/macOS presets the same way when targeted.
4. **Web build:** `gb export --preset "Web"`. The scaffold preset is single-threaded (no SharedArrayBuffer headers needed — works on itch.io, Poki, CrazyGames). Check the spec's audio needs: the web build plays audio in *Sample* mode (no bus effects/reverb/generators) unless *Default Playback Type.web* = Stream. The web build cannot be smoke-run by `gb` — the human opens it (a local server: `python -m http.server` in `build/web`, or the itch.io draft page) and plays: first click starts audio, fullscreen, input, save/load across reloads.
5. **Saves:** if the game has saves, load a save made by the previous release (keep one per release in `tests/fixtures/saves/`) — the migration test must pass; a deliberate break is announced in the notes.
6. **Human play of the built artifact:** the exported game (not the editor) played start to end on the target. Record the verdict in `STATUS.md`.
7. **Release notes + checklist:** fill `.ai/checklists/release.md` with evidence per line.

## Publishing (the human does it)
- itch.io: the human creates the page and logs in to `butler` themselves; you may prepare the command, e.g. `butler push build/web <user>/<game>:html5 --userversion <version>` and `butler push build/windows <user>/<game>:windows --userversion <version>`. **Never** enter or store credentials, API keys or tokens; never run the push without an explicit "push now" for this build.
- Stores (Steam etc.): out of scope unless the human sets them up; same rule.

After the release: [postmortem-template.md](postmortem-template.md) → `.ai/postmortems/{version}.md`; lessons go where the template says.

## Red Flags — STOP
- Exported without `--smoke`, or smoke FAIL ignored.
- `gb credits` FAIL "just this once"; a CC-BY asset without in-game credit.
- "It works in the editor" offered as evidence for the build.
- Web build not played by a human in a browser.
- You were about to run `butler push` / upload anything without the human's go for this exact build.
