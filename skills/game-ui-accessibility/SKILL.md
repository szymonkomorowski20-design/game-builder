---
name: game-ui-accessibility
description: Use for menus, HUD, settings, text and accessibility — layouts that survive resolutions, controller and keyboard navigation, readable text, key rebinding, volume and motion options, colour-blind safety, subtitles and localization-ready text. Triggers — "menu", "HUD", "interfejs", "UI", "ustawienia", "czcionka za mała", "dostępność", "accessibility", "sterowanie padem w menu", "zmiana klawiszy", "napisy", "daltonizm", "tłumaczenie".
---

# Game UI & Accessibility — every player can read, reach and control it

**Core principle:** UI shows state, it does not own it (gameplay emits signals, the UI listens — recipe 23), and
every screen is usable with **keyboard, gamepad and mouse**, at **every supported resolution**, in **every
shipped language** — checked with screenshots, not assumed.

## 1. Build
- Containers + anchors, not absolute offsets; HUD in a `CanvasLayer`; a `Theme` resource for fonts/colours/sizes
  (one place to scale text).
- Focus navigation: set initial focus on every menu (`grab_focus()`), neighbours where the automatic order is
  wrong; the `ui_*` actions drive it — never rebind `ui_*` for gameplay.
- Pause menu `PROCESS_MODE_ALWAYS` (recipe 15); transitions (recipe 16).
- Settings (recipe 17): volume per bus, fullscreen, rebinding of keyboard keys with `physical_keycode`,
  conflict prompt; persisted in `user://settings.cfg`.
- Text via translation keys (recipe 22); fonts with glyphs for every language (Polish ąęłńóśźż).

## 2. Accessibility baseline (spec decides which apply)
Text size option (Theme font scale); subtitles/captions for voice and important sounds; toggles for screen
shake and flashes (feel layers must be switchable — `game-feel`); hold-to-press alternatives; colour never the only
signal (add icons/shapes; recipe 38 — a GUT test of the game's colour pairs under deuteranopia/protanopia/
tritanopia + a screen overlay for `gb shot --movie`); rebindable controls; pause anywhere in
single-player. Screen readers: Godot ships an AccessKit driver (*Project Settings → Accessibility → General*:
`accessibility_driver`, `accessibility_support`) — enable it and give controls accessible names when the spec
targets it.

## 3. Check
- `gb shot --movie --scene res://ui/<menu>.tscn` at each target resolution (change `window/size` override for the
  run) and in the longest language — clipping, overflow, overlap are defects.
- A scenario that navigates the menu with `tap("ui_down")`/`tap("ui_accept")` and asserts the resulting screen —
  proves controller/keyboard reachability.
- Settings round trip test (recipe 17).

## Red Flags — STOP
- A menu with no initial focus (dead on gamepad).
- Text in the scene file instead of a key; fixed pixel sizes for text.
- Screen shake/flash with no off switch.
- "Looks fine" without a screenshot at the smallest resolution.
