class_name SfxBank
extends Node
## Built-in alternative to a hand-written voice pool (recipe 21): one AudioStreamPlayer whose stream is an
## AudioStreamPolyphonic plays many sounds at once; each named sound is an AudioStreamRandomizer holding its
## variants (5 footsteps, 3 hits) with random pitch/volume — no GDScript randomness, no player per sound.

@export var polyphony := 16
@export var pitch_variation := 1.06        ## random_pitch: 1.06 = between 1/1.06 and 1.06
@export var volume_variation_db := 1.5

var player: AudioStreamPlayer
var _sounds: Dictionary = {}               ## StringName -> AudioStreamRandomizer


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


func has_sound(name: StringName) -> bool:
	return _sounds.has(name)


## Plays a registered sound; returns the polyphonic stream id (INVALID_ID for unknown names or full polyphony).
func play(name: StringName, volume_db: float = 0.0) -> int:
	if not _sounds.has(name):
		return AudioStreamPlaybackPolyphonic.INVALID_ID
	var pb := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	if pb == null:
		return AudioStreamPlaybackPolyphonic.INVALID_ID
	return pb.play_stream(_sounds[name], 0.0, volume_db)


func is_playing(id: int) -> bool:
	var pb := player.get_stream_playback() as AudioStreamPlaybackPolyphonic
	return pb != null and id != AudioStreamPlaybackPolyphonic.INVALID_ID and pb.is_stream_playing(id)
