extends GutTest
## R21 — voices are reused (no new players), the oldest voice is stolen when all are busy,
## pitch variation stays within bounds and is reproducible with a seed.


func _silence(seconds: float) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_8_BITS
	s.mix_rate = 8000
	var data := PackedByteArray()
	data.resize(int(8000 * seconds))
	s.data = data
	return s


func _sfx(voices: int) -> SfxPlayer:
	var s := SfxPlayer.new()
	s.voices = voices
	add_child_autofree(s)
	s.rng.seed = 7
	return s


func test_r21_fixed_number_of_players() -> void:
	var s := _sfx(3)
	var snd := _silence(1.0)
	for i in 20:
		s.play(snd)
	assert_eq(s.get_child_count(), 3)


func test_r21_steals_oldest_when_all_busy() -> void:
	var s := _sfx(2)
	var snd := _silence(2.0)
	var first := s.play(snd)
	var second := s.play(snd)
	assert_ne(first, second, "second sound uses the free voice")
	assert_eq(s.play(snd), first, "all busy → the oldest voice is reused")
	assert_eq(s.play(snd), second)


func test_r21_pitch_within_variation() -> void:
	var s := _sfx(4)
	var snd := _silence(0.1)
	for i in 30:
		var p := s.player(s.play(snd))
		assert_between(p.pitch_scale, 1.0 - s.pitch_variation, 1.0 + s.pitch_variation)
