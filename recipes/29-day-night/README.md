# 29 — Day/night cycle

**Problem:** lighting, NPC schedules and spawns each keep their own idea of what time it is.

**Solution:** one `DayCycle` (autoload or world node) owns `time` 0..1 and `day`; it emits `phase_changed`
(dawn/day/dusk/night — once per transition) and `new_day`; systems listen instead of polling. 2D: a `Gradient` sampled
into a `CanvasModulate`; lights (`PointLight2D` torches) fade in on `dusk`. 3D: rotate a `DirectionalLight3D` and
lerp `WorldEnvironment` sky/ambient. Save `time` + `day` (13).

**Tuning:** `day_length` (Stardew ≈ 14 real minutes per day), gradient colours, phase boundaries.

**Pitfalls:** comparing `time == 0.5` (it never lands exactly — use phase changes); `CanvasModulate` also darkens the
HUD unless the HUD is on its own `CanvasLayer`; pausing — the cycle is a normal (pausable) node on purpose.

**Test:** `tests/unit/test_r29_day_night.gd`.
