extends GutTest
## R38 — the simulation matches known behaviour (red/green collapse for deuteranopia, grey is unchanged), a
## red-vs-green team palette is flagged, a blue-vs-orange palette passes, and the overlay shader compiles.


func test_r38_grey_is_unchanged() -> void:
	for mode in [Colorblind.Mode.DEUTERANOPIA, Colorblind.Mode.PROTANOPIA, Colorblind.Mode.TRITANOPIA]:
		var g := Colorblind.simulate(Color(0.5, 0.5, 0.5), mode)
		assert_almost_eq(g.r, 0.5, 0.02)
		assert_almost_eq(g.g, 0.5, 0.02)
		assert_almost_eq(g.b, 0.5, 0.02)


func test_r38_red_and_green_move_closer_for_deuteranopia() -> void:
	var red := Color(0.85, 0.2, 0.2)
	var green := Color(0.2, 0.75, 0.2)
	var before := Colorblind.distance(red, green)
	var after := Colorblind.distance(Colorblind.simulate(red, Colorblind.Mode.DEUTERANOPIA), Colorblind.simulate(green, Colorblind.Mode.DEUTERANOPIA))
	assert_lt(after, before * 0.5, "before %.2f after %.2f" % [before, after])


func test_r38_palette_check() -> void:
	var red_green := [[Color(0.85, 0.2, 0.2), Color(0.2, 0.75, 0.2)]]
	var blue_orange := [[Color(0.1, 0.45, 0.9), Color(0.95, 0.55, 0.1)]]
	var bad := Colorblind.problems(red_green)
	assert_false(bad.is_empty(), "red vs green team colours must be flagged")
	assert_true(bad.any(func(p): return p.mode == Colorblind.Mode.DEUTERANOPIA))
	assert_eq(Colorblind.problems(blue_orange), [], "blue vs orange stays distinguishable")


func test_r38_overlay_shader_compiles() -> void:
	var sh: Shader = load("res://38-colorblind-check/colorblind_overlay.gdshader")
	assert_not_null(sh)
	var mat := ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("mode", 1)
	assert_eq(mat.get_shader_parameter("mode"), 1)
