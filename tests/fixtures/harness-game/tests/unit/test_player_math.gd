extends GutTest


func test_speed_constant() -> void:
	assert_eq(preload("res://player.gd").SPEED, 120.0)


func test_deliberately_failing() -> void:
	assert_eq(1, 2, "fixture: one failing test on purpose")
