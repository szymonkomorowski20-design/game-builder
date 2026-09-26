# 24 — Enemy AI: patrol, sight, chase, attack, give up

**Problem:** enemies that see through walls, chase forever, or forget the player the instant they turn a corner.

**Solution:** `EnemyAI` with four modes. `can_see()` = within `sight_range` **and** a ray (`PhysicsRayQueryParameters2D`,
mask = wall layers, excluding itself) reaches the target. `decide(dist, sees, delta)` is a pure function (unit-tested
decision table); `_physics_process` moves: patrol points → last seen position → stop and attack on cooldown → walk home.
For levels with obstacles combine CHASE with a `NavigationAgent2D` (recipe 26) instead of a straight line.

**Tuning:** `sight_range`, `attack_range`, `chase_speed` vs player speed (chaser slightly slower = escapable),
`lose_time` (0.8–2 s), `attack_cooldown`. Add a short "alert" pause before chasing to telegraph.

**Pitfalls:** the ray hitting the enemy's own collider (exclude its RID); raycasting every frame for 200 enemies (stagger
checks, e.g. every 5th frame); sight through one-way platforms; `motion_mode` must be FLOATING for top-down bodies.

**Tests:** `tests/unit/test_r24_enemy_decide.gd` (decision table) + `tests/scenarios/r24_enemy_ai.gd` (real physics,
wall blocks sight).
