# Test design techniques for games

## Where cases come from
- **Equivalence partitions**: e.g. hit positions on a paddle — top third / middle / bottom third / edge; health — full / partial / 1 / 0 / negative (invalid).
- **Boundary values**: score limit−1 / limit / limit+1; speed caps; timers at exactly 0; array of enemies empty / one / max.
- **State-transition tables** (highest yield in games): player idle/run/jump/fall/dead, round serve/play/scored/game over. Draw every state × every input; the bugs live in the cells nobody drew (jump while dead, pause during a goal, two goals in one frame).
- **Decision tables** where outcome depends on combinations (armor × damage type × crit).
- **Failure paths**: falling out of the world, leaving the screen, input spam, zero-length frames, loading a corrupt save.

## Scenario patterns
```gdscript
extends GbScenario   # B2 — paddle stops at the top wall

func run() -> void:
	await load_scene("res://scenes/main.tscn")
	var paddle := node("LeftPaddle") as Node2D
	await press("move_up", 3.0)                       # far longer than needed to reach the wall
	expect_near(paddle.position.y, 60.0, 1.0, "B2 paddle clamped at top (half height 60)")
```
- Assert on state (positions, score, flags), not on log text.
- Name nodes in the spec's node plan so scenarios can find them (`node("LeftPaddle")`).
- Use `wait_until(cond, timeout)` for events (ball reaches goal) instead of guessing frame counts.

## Test setup hooks (learned building Pong, 2026-09-25)
Scenarios often set state directly (`game.call("place_ball", pos, velocity)`). Such a hook must
establish **the full state it implies** — a ball given a velocity is in play (state PLAY). When a
later phase adds a state (SERVE holding the ball for 1 s), an older scenario that relied on the
implicit state fails: that is the suite doing its job. Fix the hook/code, never loosen the scenario.

## Visual scenarios
Every new screen or state (end of match, pause, level complete) gets a scenario that drives the game
there and calls `shot("name")`. `gb verify` runs it headless (state only); `gb scenario <file> --window`
saves the PNG — look at it, then `--accept` to make it a baseline and `--compare` on later runs.
In the Pong dogfood all logic tests passed while the ball covered the end-of-match message; only the
screenshot showed it.

## Unit test patterns (GUT)
```gdscript
extends GutTest   # B5 — bounce angle depends on hit offset

func test_b5_center_hit_is_straight() -> void:
	assert_almost_eq(Ball.bounce_angle(0.0), 0.0, 0.001)

func test_b5_edge_hit_is_steep_but_capped() -> void:
	assert_almost_eq(Ball.bounce_angle(1.0), deg_to_rad(60.0), 0.001)
```
Make logic testable by putting it in static functions or plain classes, not buried in `_physics_process`.

## Detection proof (tier A/B)
For each behaviour ID: change exactly the behaviour (flip a sign, change a constant, remove a clamp) →
run its test → it must go RED → revert → suite GREEN again. Record in the plan:
`B2: removed clamp in paddle.gd:18 → test_b2 red (expected 60 got -340) → reverted → green`.
A test that stays green when its behaviour is broken is deleted-or-fixed, never kept for the count.

## Replays
Recorded by the human after a "keep" feel verdict (`gb record <name>`). Add the nodes that matter to
group `gb_track` first (player, ball, score holder) — then the replay compares their final position and
`health/hp/score/state`. A replay mismatch after an intended change is shown to the human, never
silently re-recorded.

## Save data (tier A)
Round-trip test: build state → save → load into a fresh object → equal. Plus: load a save file from the
previous format version (keep a fixture in `tests/fixtures/saves/`) → migrated or rejected with a clear message.
