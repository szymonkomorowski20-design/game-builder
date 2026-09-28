extends GutTest
## R35 — named sounds with variants play through one polyphonic player, several at once; unknown names and
## full polyphony return INVALID_ID instead of erroring.


func _bank(polyphony: int = 4) -> SfxBank:
	var b := SfxBank.new()
	b.polyphony = polyphony
	add_child_autofree(b)
	b.add_sound(&"step", [_beep(440.0), _beep(494.0), _beep(523.0)])
	return b


## 0.5 s sine, 16-bit, not looping — a stand-in for recorded variants.
func _beep(hz: float) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 22050
	var data := PackedByteArray()
	data.resize(11025 * 2)
	for i in 11025:
		data.encode_s16(i * 2, int(sin(i * TAU * hz / 22050.0) * 8000.0))
	s.data = data
	return s


func test_r35_plays_several_at_once() -> void:
	var b := _bank()
	await wait_frames(2)
	var a := b.play(&"step")
	var c := b.play(&"step")
	assert_ne(a, AudioStreamPlaybackPolyphonic.INVALID_ID)
	assert_ne(c, AudioStreamPlaybackPolyphonic.INVALID_ID)
	assert_ne(a, c)
	await wait_frames(2)
	assert_true(b.is_playing(a) and b.is_playing(c), "both voices sound together")
	assert_eq(b.get_child_count(), 1, "one AudioStreamPlayer for everything")


func test_r35_unknown_sound_is_invalid() -> void:
	var b := _bank()
	await wait_frames(2)
	assert_eq(b.play(&"stpe"), AudioStreamPlaybackPolyphonic.INVALID_ID)


func test_r35_randomizer_settings() -> void:
	var b := _bank()
	var r: AudioStreamRandomizer = b._sounds[&"step"]
	assert_eq(r.streams_count, 3)
	assert_almost_eq(r.random_pitch, 1.06, 0.0001)
	assert_eq(r.playback_mode, AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS)


func test_r35_own_rng_never_repeats_a_variant() -> void:
	var bank := SfxBank.new()
	add_child_autofree(bank)
	bank.rng = RandomNumberGenerator.new()
	bank.rng.seed = 7
	bank.add_sound(&"hit", [AudioStreamWAV.new(), AudioStreamWAV.new(), AudioStreamWAV.new()])
	var last := -1
	var seen := {}
	for i in 40:
		bank.play(&"hit")
		var now := int(bank._last[&"hit"])
		assert_ne(now, last, "play %d: not the same variant twice in a row" % i)
		last = now
		seen[now] = true
	assert_eq(seen.size(), 3, "every variant is used")
