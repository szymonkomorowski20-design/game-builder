extends GbScenario
## A1 — in the hub, holding right moves the hero at the tuned speed (m/s); a dash covers about speed × duration in a
## blink and makes the hero invulnerable while it lasts.


func run() -> void:
	await load_scene("res://scenes/run/run.tscn")
	var game := node(".") as RogueRun
	await wait_frames(5)
	var p := game.player
	var x0 := p.global_position.x
	await press("move_right", 0.5)
	await wait_frames(2)
	var walked := p.global_position.x - x0
	expect_near(walked, p.tuning.move_speed * 0.5, 0.35, "A1 0.5 s of walking ≈ move_speed × 0.5 (%.2f m)" % walked)
	var x1 := p.global_position.x
	hold("move_right")
	await tap("dash")
	expect(p.is_invulnerable(), "A1 invulnerable during the dash")
	var hp := p.health.current
	p.take_hit(10, Vector3.ZERO)
	expect_eq(p.health.current, hp, "A1 a hit landing mid-dash does nothing (i-frames)")
	await wait(p.tuning.dash_duration)
	release("move_right")
	var dashed := p.global_position.x - x1
	expect_gt(dashed, p.tuning.dash_speed * p.tuning.dash_duration * 0.8, "A1 the dash covers its distance (%.2f m)" % dashed)
