extends GutTest
## R34 — clips are named, the director starts on the first clip, switching mood changes the playing clip,
## unknown moods are rejected, the signal fires once per real change.


func _director() -> MusicDirector:
	var m := MusicDirector.new()
	add_child_autofree(m)
	m.setup({&"explore": MusicDirector.tone(220.0), &"combat": MusicDirector.tone(330.0)})
	return m


func test_r34_starts_on_first_clip() -> void:
	var m := _director()
	m.play()
	await wait_frames(3)
	assert_true(m.player.playing)
	assert_eq(m.current_clip_name(), &"explore")


func test_r34_switch_changes_clip() -> void:
	var m := _director()
	m.play()
	await wait_frames(3)
	assert_true(m.set_mood(&"combat"))
	# NEXT_BAR with no BPM set on the clips transitions right away; give the mixer a few frames.
	await wait_seconds(0.3)
	assert_eq(m.current_clip_name(), &"combat")


func test_r34_mood_set_before_play_starts_there() -> void:
	var m := _director()
	m.set_mood(&"combat")
	m.play()
	await wait_frames(3)
	assert_eq(m.current_clip_name(), &"combat")


func test_r34_unknown_mood_rejected_and_signal_once() -> void:
	var m := _director()
	watch_signals(m)
	assert_false(m.set_mood(&"bosss"))
	m.set_mood(&"combat")
	m.set_mood(&"combat")
	assert_signal_emit_count(m, "mood_changed", 1)
	assert_eq(m.mood, &"combat")
