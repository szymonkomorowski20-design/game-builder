extends GutTest
## R44 — state rules (floor/air, rising/falling, run threshold) and the built state machine (all states, every
## pair connected, a start transition).


func test_r44_ground_states() -> void:
	assert_eq(AnimStates.state_for(true, Vector2.ZERO), AnimStates.IDLE)
	assert_eq(AnimStates.state_for(true, Vector2(5, 0)), AnimStates.IDLE, "below the threshold is still idle")
	assert_eq(AnimStates.state_for(true, Vector2(-120, 0)), AnimStates.RUN)


func test_r44_air_states() -> void:
	assert_eq(AnimStates.state_for(false, Vector2(0, -200)), AnimStates.JUMP, "rising")
	assert_eq(AnimStates.state_for(false, Vector2(150, 10)), AnimStates.FALL, "falling, even while moving sideways")
	assert_eq(AnimStates.state_for(false, Vector2(0, 0)), AnimStates.FALL, "apex counts as falling")


func test_r44_machine_connects_every_pair() -> void:
	var names: Array[StringName] = [AnimStates.IDLE, AnimStates.RUN, AnimStates.JUMP, AnimStates.FALL]
	var sm := AnimStates.build_machine(names)
	for n in names:
		assert_true(sm.has_node(n), "state %s exists" % n)
	for from in names:
		for to in names:
			if from != to:
				assert_true(sm.has_transition(from, to), "%s → %s" % [from, to])
	assert_true(sm.has_transition(&"Start", AnimStates.IDLE), "starts in the first state")
