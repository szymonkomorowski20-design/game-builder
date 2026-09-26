class_name MusicDirector
extends Node
## Adaptive music with Godot's AudioStreamInteractive: named clips (explore, combat, boss…) and a transition
## table. Gameplay only says what is happening — `set_mood(&"combat")` — the stream picks the musical moment
## (next beat/bar) and the fade. Make it an autoload with PROCESS_MODE_ALWAYS so music survives scene changes.

signal mood_changed(mood: StringName)

@export var bus := &"Music"
@export var fade_beats := 2.0

var player: AudioStreamPlayer
var mood: StringName = &""
var _stream: AudioStreamInteractive
var _index: Dictionary = {}   ## mood -> clip index


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	player = AudioStreamPlayer.new()
	player.bus = bus if AudioServer.get_bus_index(bus) != -1 else &"Master"
	add_child(player)


## clips: { &"explore": AudioStream, &"combat": AudioStream, … }. The first clip is the initial one.
## Every clip can go to every other one on the next bar with a cross-fade (one CLIP_ANY rule).
func setup(clips: Dictionary) -> void:
	_stream = AudioStreamInteractive.new()
	_stream.clip_count = clips.size()
	var i := 0
	for name in clips:
		_stream.set_clip_name(i, name)
		_stream.set_clip_stream(i, clips[name])
		_index[StringName(name)] = i
		i += 1
	_stream.add_transition(AudioStreamInteractive.CLIP_ANY, AudioStreamInteractive.CLIP_ANY,
		AudioStreamInteractive.TRANSITION_FROM_TIME_NEXT_BAR, AudioStreamInteractive.TRANSITION_TO_TIME_START,
		AudioStreamInteractive.FADE_CROSS, fade_beats)
	player.stream = _stream
	mood = StringName(clips.keys()[0])


func play() -> void:
	player.play()


## Returns false for an unknown mood (typo in gameplay code) instead of silently doing nothing.
func set_mood(new_mood: StringName) -> bool:
	if not _index.has(new_mood):
		return false
	if new_mood == mood:
		return true
	mood = new_mood
	if player.playing:
		(player.get_stream_playback() as AudioStreamPlaybackInteractive).switch_to_clip_by_name(new_mood)
	else:
		# get_stream_playback() on a stopped player is an engine error — start on this clip instead.
		_stream.initial_clip = _index[new_mood]
	mood_changed.emit(new_mood)
	return true


func current_clip_name() -> StringName:
	if not player.playing:
		return &""
	var pb := player.get_stream_playback() as AudioStreamPlaybackInteractive
	return _stream.get_clip_name(pb.get_current_clip_index())


## Test/prototype helper: a looping sine tone as a stand-in for real music files.
static func tone(hz: float, seconds: float = 2.0) -> AudioStreamWAV:
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = 22050
	var n := int(22050 * seconds)
	var data := PackedByteArray()
	data.resize(n * 2)
	for i in n:
		data.encode_s16(i * 2, int(sin(i * TAU * hz / 22050.0) * 8000.0))
	s.data = data
	s.loop_mode = AudioStreamWAV.LOOP_FORWARD
	s.loop_end = n
	return s
