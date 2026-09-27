extends GbScenario
## R43 — with the keys: a dash covers more ground than walking for the same time; a second press during the cooldown
## does nothing; a hit during the dash is ignored (i-frames), a hit afterwards knocks the mover away from the source.


func run() -> void:
	await load_scene("res://43-dash-knockback/dash_demo.tscn")
	var m := node("Mover") as DashMover
	var span := m.dash.duration
	var x0 := m.global_position.x
	hold("move_right")
	await wait(span)
	var walked := m.global_position.x - x0
	await wait(0.3)   # full walking speed
	var x1 := m.global_position.x
	await tap("action")
	await wait(span - 3.0 / 60.0)   # tap() itself took 3 frames
	var dashed := m.global_position.x - x1
	release("move_right")
	expect_gt(dashed, walked * 2.0, "R43 a dash covers more ground than walking (%.0f px vs %.0f px)" % [dashed, walked])
	expect_eq(m.dashes, 1, "R43 one dash")
	await tap("action")
	expect_eq(m.dashes, 1, "R43 a press during the cooldown does nothing")

	await wait(m.dash.cooldown)
	await tap("action")
	expect(not m.take_hit(m.global_position + Vector2(-20, 0), 300.0), "R43 a hit during the dash is ignored (i-frames)")
	await wait(0.3)
	var x2 := m.global_position.x
	expect(m.take_hit(m.global_position + Vector2(20, 0), 300.0), "R43 a hit after the dash lands")
	await wait(0.1)
	expect_lt(m.global_position.x, x2 - 10.0, "R43 knocked back away from the source (to the left)")
