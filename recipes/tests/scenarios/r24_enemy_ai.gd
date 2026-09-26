extends GbScenario
## R24 — patrol; a target behind a wall is not seen; a visible target is chased and attacked; after losing it the
## enemy keeps chasing the last seen spot for lose_time, then returns to patrol.


func run() -> void:
	await load_scene("res://24-enemy-ai/enemy_demo.tscn")
	var e := node("Enemy") as EnemyAI
	var p := node("Player") as Node2D
	await wait(1.0)
	expect_eq(e.mode, EnemyAI.Mode.PATROL, "R24 patrols with no target around")
	expect(e.position.x > 95.0 and e.position.x < 205.0, "R24 stays on the patrol segment (x=%.1f)" % e.position.x)

	p.global_position = Vector2(300, 180)   # within sight range, but behind the wall at x=230
	await wait(1.0)
	expect_eq(e.mode, EnemyAI.Mode.PATROL, "R24 does not see through walls")

	p.global_position = Vector2(160, 260)
	var attacked := await wait_until(func(): return e.mode == EnemyAI.Mode.ATTACK, 4.0)
	expect(attacked, "R24 visible target is chased and attacked")

	p.global_position = Vector2(600, 180)
	await wait_frames(3)
	expect_eq(e.mode, EnemyAI.Mode.CHASE, "R24 keeps chasing the last seen position right after losing sight")
	var returned := await wait_until(func(): return e.mode == EnemyAI.Mode.RETURN, 3.0)
	expect(returned, "R24 gives up after lose_time")
	var patrolling := await wait_until(func(): return e.mode == EnemyAI.Mode.PATROL, 6.0)
	expect(patrolling, "R24 back to patrol")
