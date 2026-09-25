extends GbScenario
## R07 — a fired projectile flies, damages the target's Health on contact and disappears; a projectile
## fired away from targets disappears after its lifetime.


func run() -> void:
	await load_scene("res://07-projectile/range.tscn")
	var weapon := node("Weapon") as Weapon
	var hp := node("Target/Health") as Health
	var shots: Array = []
	weapon.fired.connect(func(p: Node2D) -> void: shots.append(p))

	expect(weapon.try_fire(Vector2.RIGHT), "R07 first shot fires")
	var hit := await wait_until(func() -> bool: return hp.current < 3, 2.0)
	expect(hit, "R07 projectile damaged the target")
	await wait_frames(2)
	expect(not is_instance_valid(shots[0]), "R07 projectile removed after the hit")

	await wait(0.3)
	expect(weapon.try_fire(Vector2.LEFT), "R07 shot away from the target")
	var p: Node2D = shots[1]
	var life: float = p.get("lifetime")
	await wait(life + 0.1)
	expect(not is_instance_valid(p), "R07 projectile removed after its lifetime")
	expect_eq(hp.current, 2, "R07 the miss did no damage")
