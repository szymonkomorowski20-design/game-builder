extends GbScenario
## R06 — a hitbox overlapping a hurtbox damages its Health once per entry; no overlap, no damage.


func run() -> void:
	await load_scene("res://06-hitbox-hurtbox/arena.tscn")
	var hp := node("Dummy/Health") as Health
	var sword := node("Sword") as Area2D
	await wait_frames(3)
	expect_eq(hp.current, 3, "R06 no overlap, no damage")
	sword.position = Vector2(300, 180)
	await wait_frames(3)
	expect_eq(hp.current, 1, "R06 entering the hurtbox deals the hitbox damage (2)")
	await wait(0.5)
	expect_eq(hp.current, 1, "R06 staying inside does not re-hit (area_entered fires once)")
	sword.position = Vector2(100, 180)
	await wait_frames(3)
	sword.position = Vector2(300, 180)
	await wait_frames(3)
	expect_eq(hp.current, 0, "R06 re-entering after i-frames hits again")
