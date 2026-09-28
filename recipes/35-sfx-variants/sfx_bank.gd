class_name SfxBank
extends Node
## Built-in alternative to a hand-written voice pool (recipe 21): one AudioStreamPlayer whose stream is an
## AudioStreamPolyphonic plays many sounds at once; each named sound is an AudioStreamRandomizer holding its
## variants (5 footsteps, 3 hits) with random pitch/volume — no GDScript randomness, no player per sound.

@export var polyphony := 16
@export var pitch_variation := 1.06        ## random_pitch: 1.06 = between 1/1.06 and 1.06
@export var volume_variation_db := 1.5

var player: AudioStreamPlayer
var rng: RandomNumberGenerator = null     ## set: variants, pitch and volume come from it (deterministic, main thread)
var _sounds: Dictionary = {}               ## StringName -> AudioStreamRandomizer
var _variants: Dictionary = {}             ## StringName -> Array of AudioStream (for `rng`)
var _last: Dictionary = {}                 ## StringName -> the last variant's index (no repeats, as the randomizer)


func _ready() -> void:
	player = AudioStreamPlayer.new()
	var poly := AudioStreamPolyphonic.new()
	poly.polyphony = polyphony
	player.stream = poly
	player.bus = &"SFX" if AudioServer.get_bus_index(&"SFX") != -1 else &"Master"
	add_child(player)
	player.play()   # the polyphonic playback must be running before play_stream()


## Registers a sound made of one or more variants.
func add_sound(name: StringName, variants: Array) -> void:
	var r := AudioStreamRandomizer.new()
	for v: AudioStream in variants:
		r.add_stream(-1, v)
	r.random_pitch = pitch_variation
	r.random_volume_offset_db = volume_variation_db
	r.playback_mode = AudioStreamRandomizer.PLAYBACK_RANDOM_NO_REPEATS
	_sounds[name] = r
	_variants[name] = variants.duplicate()


func has_sound(name: StringName) -> bool:
	return _sounds.has(name)


## Plays a registered sound; returns the polyphonic stream id (INVALID_ID for unknown names or full polyphony).
func play(name: StringName, volume_db: float = 0.0) -> int:
	if not _sounds.has(name):
		return AudioStreamPlaybackPolyphonic.INVALID_ID
	var pb := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if pb == null:
		return AudioStreamPlaybackPolyphonic.INVALID_ID
	if rng != null:
		# The randomizer draws from the global RNG, and its pitch and volume on the audio thread: with `rng`, pick
		# here instead, so gameplay randomness never depends on sounds.
		var list: Array = _variants[name]
		var i := rng.randi() % list.size()
		if list.size() > 1 and i == int(_last.get(name, -1)):
			i = (i + 1 + rng.randi() % (list.size() - 1)) % list.size()
		_last[name] = i
		var s: AudioStream = list[i]
		var pitch := rng.randf_range(1.0 / pitch_variation, pitch_variation)
		var vol := rng.randf_range(-volume_variation_db, volume_variation_db)
		return pb.play_stream(s, 0.0, volume_db + vol, pitch)
	return pb.play_stream(_sounds[name], 0.0, volume_db)


func is_playing(id: int) -> bool:
	var pb := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	return pb != null and id != AudioStreamPlaybackPolyphonic.INVALID_ID and pb.is_stream_playing(id)
