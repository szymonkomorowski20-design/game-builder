---
name: game-vfx
description: Use for visual effects — particles, shaders, hit flashes, dissolves, outlines, post-processing, lighting in 2D — within the limits of the chosen renderer (web and low-end targets use Compatibility), with each effect tunable and checked on screen. Triggers — "efekty", "cząsteczki", "particles", "shader", "VFX", "świecenie", "glow", "wybuch", "błysk", "rozpuszczanie", "outline", "oświetlenie 2D".
---

# Game VFX — effects that serve the gameplay and run on the target

**Core principle:** an effect communicates something (hit, pickup, danger, power) and must **run on the target
renderer**. Web and weak machines mean the **Compatibility** renderer — check the effect is supported before
building it.

## 1. Renderer limits (Godot 4.7 docs, *Rendering → Renderers*)
Compatibility (web, default for 2D in game-builder) does **not** support: particle trails, particle SDF collision,
decals, compute shaders, CompositorEffects post-processing, screen-space reflections/SSIL, volumetric fog, depth of
field, variable rate shading, debanding; colour is RGBA8 (low dynamic range). It **does** support glow,
adjustments, fullscreen-quad custom post-processing, and ordinary `canvas_item`/`spatial` shaders. Forward+/Mobile
support more — but not in the browser. Decide the renderer in the spec (`game-bootstrap` decision card).

## 2. Building blocks
| Need | Use | Recipe |
|---|---|---|
| Flash on hit | `canvas_item` shader uniform, per-instance material | 33 |
| Screen shake | trauma-based camera offset | 03 |
| Freeze frame | `Engine.time_scale` + real-time timer | 32 |
| Bursts (hit sparks, dust, coins) | `GPUParticles2D` (one-shot, `emitting = true`), or `CPUParticles2D` when many small emitters or for predictable behaviour | — |
| Dissolve / outline / palette swap | `canvas_item` shader with a noise texture / neighbour sampling | — |
| 2D lighting | `PointLight2D` + `LightOccluder2D`, `CanvasModulate` for ambient (29 day/night) | — |
| Glow in 2D | `WorldEnvironment` glow, either *Rendering → Viewport → HDR 2D* on + overbright `modulate` on what should glow (linear colour — use `source_color` hints), or HDR 2D off + background mode **Canvas** + low *Glow HDR Threshold*; keep UI in a `CanvasLayer` so it doesn't glow (4.7 docs, *Environment and post-processing*). Check the look on the target renderer | — |
Every effect has Tuning rows (duration, intensity, colour) and an accessibility toggle when it flashes or shakes.

## 3. Check
- Unit tests for effect logic (recipe 33: flash decays to 0, materials independent).
- `gb shot --movie --scene …` on the frame the effect peaks — **look** at it; on Compatibility if the game targets web.
- `gb perf` with the worst case (many particles on screen).

## Red Flags — STOP
- An effect built on a feature the target renderer lacks (trails/decals on web).
- A shared material flashing every enemy.
- Particles left emitting forever / never freed.
- An effect that hides gameplay information (bullets behind the explosion, HUD covered).
