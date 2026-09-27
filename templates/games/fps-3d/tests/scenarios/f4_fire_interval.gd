extends GbScenario
## F4 — holding shoot fires once per fire_interval, not every frame.


func run() -> void:
	var player := node("Player") as FpsPlayer
	await wait(0.2)
	player.look(0.0, -0.6)   # at the floor, nothing to destroy
	var before := player.weapon.shots_fired
	await press("shoot", 1.0)
	var fired := player.weapon.shots_fired - before
	var expected := int(ceil(1.0 / player.tuning.fire_interval))
	expect(absi(fired - expected) <= 1, "F4 %d shots in 1 s (expected about %d)" % [fired, expected])
