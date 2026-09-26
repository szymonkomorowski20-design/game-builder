---
name: game-performance
description: Use when the game stutters, drops frames, loads slowly or must hit a budget on a weak target (web, laptop, mobile) — measuring with gb perf against a budget, finding the real cost, and fixing it without guesswork. Triggers — "laguje", "spadki FPS", "tnie się", "wolno działa", "wydajność", "optymalizacja", "performance", "stutter", "długie ładowanie", "za dużo przeciwników".
---

# Game Performance — measure, find, fix, measure again

**Core principle:** no optimisation without a **measurement against a budget** on the **target**. The first
guess about what is slow is usually wrong.

## 1. Budget (spec)
`.ai/perf-budget.json` (created by scaffold): frame time (16.6 ms for 60 FPS), physics/process time, node count,
draw calls — for the worst case on screen on the weakest target. The spec's performance section names that
worst case ("40 enemies + 200 bullets").

## 2. Measure
- `node tools/gb/gb.js perf --seconds 10 --scene res://<worst-case scene>` (window; `--headless` for CPU-only
  logic) → frame/process/physics time, nodes, draw calls vs the budget. Build a worst-case scene or a scenario
  that spawns it — measuring the title screen proves nothing.
- Godot editor profiler / visual profiler for where the time goes (human runs it or you read exported data).
- Web: measure the exported build in the browser (single-threaded export, Compatibility renderer).

## 3. Usual causes (confirm by measurement)
| Symptom | Cause | Fix |
|---|---|---|
| Spikes when shooting/spawning | instantiate + free churn | pool (recipe 20) — after measuring |
| Physics time high | too many bodies/areas, complex shapes | simpler shapes, layers/masks, fewer active bodies, sleep |
| Process time high | per-frame work in many nodes | stagger (every N frames), signals instead of polling, disable off-screen (`VisibleOnScreenEnabler2D`) |
| Draw calls high | many unique materials/textures | atlases, shared materials, `MultiMesh` for crowds |
| Hitch on first effect | shader compilation | pre-warm effects at load; the export option `shader_baker/enabled` pre-compiles shaders into the build |
| Long load | loading big scenes on the main thread | threaded loading (recipe 16), smaller scenes |
| AI heavy | raycasts/pathing every frame per agent | stagger perception, re-path on change (npc skill) |

## 4. Fix and prove
One change at a time; `gb perf` before/after pasted; `gb verify` still green (optimisations break behaviour).
A budget test in CI is optional — timings on shared runners are noisy; prefer node/draw-call counts there.

## Red Flags — STOP
- "Optimised" code with no before/after numbers.
- Measuring on a scene that is not the worst case, or only on the dev machine for a web target.
- Micro-optimising GDScript before checking physics and draw calls.
