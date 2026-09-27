# 42 — Moving platform that carries the player

**Problem:** a platform moving along waypoints must carry whoever stands on it — sideways and upward — without the
rider sliding off, jittering, or being left hanging in the air.

**Solution:** `MovingPlatform` is an `AnimatableBody2D` with `sync_to_physics` on, moved in `_physics_process` to
`origin + PlatformPath.position_at(time)`. `CharacterBody2D.move_and_slide()` then picks up the platform's velocity,
so the rider (any character with gravity — `PlatformRider` in the demo) travels with it. `PlatformPath` is pure: a
ping-pong route along waypoints at constant speed, testable without physics.

**Tuning:** waypoints (relative to the platform's start), `speed` (px/s). A pause at the ends is a small extension:
hold `time` for N seconds when `position_at` reaches an end.

**Pitfalls (verified):** a `StaticBody2D` moved by setting `position` does not carry the rider — in this recipe's
scenario the rider stayed behind and fell to y ≈ 1500. Moving the platform in `_process` instead of `_physics_process`
makes riders jitter. `CharacterBody2D.platform_on_leave` (default: add the platform's velocity) decides what a jump off
a moving platform feels like — tune it on purpose. One-way platforms: set the collision shape's `one_way_collision`.

**Test:** `tests/unit/test_r42_platform_path.gd`, `tests/scenarios/r42_moving_platform.gd`. Scene: `platform_demo.tscn`.
