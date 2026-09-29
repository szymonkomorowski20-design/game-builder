extends GbScenario
## S1 — the streets: a sprint up the main street at sprint speed; the action key in the hay hides the player (the guards'
## cues say blended, the HUD says hidden) and moving comes out; a sneak is silent, a sprint is heard by the guards.

var _noises := 0


func run() -> void:
	await load_scene("res://scenes/district/district.tscn")
	var game := get_tree().current_scene as StealthGame
	var bot := StealthBot.new(self, game)
	var p := game.player
	p.noise_made.connect(func(_at: Vector3, _r: float) -> void: _noises += 1)
	await wait_frames(5)

	Input.action_press(&"sprint")
	bot.stick(Vector3(0, 0, -1))
	await wait(1.2)
	expect_near(Vector2(p.velocity.x, p.velocity.z).length(), p.profiles.speed(MoveProfiles.SPRINT), 0.3,
			"a sprint up the main street")
	bot.let_go()
	await wait(0.5)

	# Round the hay's corner, then walk straight at it: a body pushing within 15° of a wall's normal stops dead
	# (CharacterBody3D.wall_min_slide_angle) instead of sliding along it.
	await bot.walk_to(Vector3(8, 0, 19.5), false, 0.5)
	expect(await bot.walk_to(Vector3(8, 0, 21.5), false, 0.5), "walked to the hay in the square")
	await tap("action")
	expect_eq(p.hidden_in, &"hay", "the action key next to the hay hides the player in it")
	expect(p.stealth_cues().get("blended", false) == true, "hidden: the guards' cues say blended")
	await wait(0.5)
	expect(p.is_hidden(), "still hidden while standing still")
	shot("s1_hidden_in_hay")
	await bot.push(Vector3(0, 0, -1), 0.4)
	expect(not p.is_hidden(), "moving comes out of the hay")

	p.teleport(Vector3(0, 0.05, 28))
	await wait(0.3)
	_noises = 0
	await bot.push(Vector3(0, 0, -1), 1.5, &"sneak")
	expect_eq(_noises, 0, "sneaking up the street makes no noise")
	await bot.push(Vector3(0, 0, -1), 1.5, &"sprint")
	expect_gt(_noises, 3, "sprinting does")
