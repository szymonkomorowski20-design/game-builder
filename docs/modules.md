# Optional modules — what game-builder supports and how

A module is something a game may need but most don't. Each row says what exists in the plugin today (tested
recipe / skill / tool), what is external, and the traps. Decide modules in the spec (a decision card when the
choice has consequences: licence, platform, backend).

Legend: **recipe** = tested code in `recipes/` (`gb recipe add <NN>`), **skill** = procedure, **external** =
third-party (check its licence at the source before adding), **not yet** = no support in the plugin.

| Module | Status | How | Traps (verified against Godot 4.7 docs where noted) |
|---|---|---|---|
| Save / load, slots, migrations | recipe 13 + skill `game-save` | JSON, atomic write, versioned migrations, fixtures per release | Web: `user://` persists only if the browser allows IndexedDB; private mode and blocked third-party cookies in an iframe lose saves — check `OS.is_userfs_persistent()` and tell the player (4.7 docs, *Exporting for the Web*) |
| Settings + key rebinding | recipe 17 | `ConfigFile`, per-bus volume, physical keycodes | 4.7: keyboard/mouse device IDs are constants, not 0 |
| Achievements | recipe 12 | stat-driven, saved ids | Platform achievements (Steam) = an adapter listening to `unlocked`, never called from gameplay |
| Localization | recipe 22 + skill `game-narrative` | CSV → translations, keys in code | register translations or the UI shows keys; fonts must cover every language |
| Adaptive music, SFX variants | recipes 34, 35 + skill `game-audio` | `AudioStreamInteractive`, `AudioStreamRandomizer`/`Polyphonic` | web Sample mode: no bus effects/generators |
| Procedural levels | recipes 27, 28, 37 + skill `game-level-design` | seeded generator + completability check over many seeds | global RNG shared with gameplay changes levels — own RNG per generator |
| Enemy AI, navigation | recipes 14, 24, 25, 26 + skill `game-npc-ai` | FSM / BT / NavigationAgent2D | navigation map syncs asynchronously (4.5+) |
| Dialogue, quests | recipes 18, 19 + skill `game-narrative` | data-driven runner, event-driven quests | validate every branch reachable |
| Balance contracts | recipe 36 + skill `game-balance` | Monte-Carlo with bands in GUT | read the game's own data files |
| Accessibility | recipe 38 + skill `game-ui-accessibility` | colour-pair test, overlay, toggles, AccessKit driver | colour never the only signal |
| Controller support | built in (scaffold writes gamepad bindings) | input actions with joypad events; `Input.start_joy_vibration` for rumble | menus need initial focus |
| Multiplayer (local / online) | recipe 39 (basics); spawner/synchronizer not yet | Godot high-level multiplayer: `MultiplayerSpawner`, `MultiplayerSynchronizer`, RPCs; ENet on desktop | **Web:** no low-level networking — only HTTP, WebSocket (client) and WebRTC (4.7 docs); determinism and the harness assume single-player — needs its own test strategy |
| Steamworks (achievements, cloud, leaderboards) | external | GodotSteam (GDExtension) — the human sets up the Steamworks account and app id | never commit app secrets; keep Steam calls behind an adapter so tests run without Steam |
| Mods / user content | **not yet** | `ProjectSettings.load_resource_pack(path)` loads a `.pck` at runtime | a pack can replace any file and run code — only for trusted content, document it |
| Analytics / telemetry | **not yet** | HTTP to your own endpoint | personal data → consent, privacy policy; off by default |
| Online leaderboards / accounts | **not yet** | backend service (external) | credentials never in the repo; web CORS |
| 3D (TPS/FPS templates) | **not yet** (stage 5) | Jolt physics default since 4.6 | 4.7 Jolt sign/soft-body changes (`godot-4.4-4.7-changes.md`) |

When a module marked **not yet** is needed, run `game-researcher` for it, write a recipe with a test first
(the recipe becomes plugin knowledge for the next game), then use it.
