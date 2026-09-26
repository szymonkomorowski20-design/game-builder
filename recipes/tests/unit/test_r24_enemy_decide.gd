extends GutTest
## R24 — decision table of EnemyAI.decide() without physics.


func _e() -> EnemyAI:
	var e: EnemyAI = autofree(EnemyAI.new())
	e.sight_range = 160.0
	e.attack_range = 28.0
	e.lose_time = 1.0
	return e


func test_r24_not_seen_stays_patrol() -> void:
	var e := _e()
	assert_eq(e.decide(50.0, false, 0.1), EnemyAI.Mode.PATROL)


func test_r24_seen_in_range_chases_then_attacks() -> void:
	var e := _e()
	assert_eq(e.decide(100.0, true, 0.1), EnemyAI.Mode.CHASE)
	assert_eq(e.decide(20.0, true, 0.1), EnemyAI.Mode.ATTACK)
	assert_eq(e.decide(40.0, true, 0.1), EnemyAI.Mode.CHASE, "target stepped back out of reach")


func test_r24_seen_but_too_far_is_ignored() -> void:
	var e := _e()
	assert_eq(e.decide(200.0, true, 0.1), EnemyAI.Mode.PATROL)


func test_r24_lost_target_chases_until_lose_time() -> void:
	var e := _e()
	e.decide(100.0, true, 0.1)
	for i in 7:   # 0.125 is exact in binary floating point; 0.1 × 10 is 0.9999…
		assert_eq(e.decide(300.0, false, 0.125), EnemyAI.Mode.CHASE)
	assert_eq(e.decide(300.0, false, 0.125), EnemyAI.Mode.RETURN, "1.0 s without sight")


func test_r24_seeing_again_resets_lose_timer() -> void:
	var e := _e()
	e.decide(100.0, true, 0.1)
	e.decide(300.0, false, 0.9)
	e.decide(100.0, true, 0.1)
	assert_eq(e.decide(300.0, false, 0.9), EnemyAI.Mode.CHASE)
