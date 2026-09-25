class_name SfxPlayer
extends Node
## Fixed set of voices for sound effects on the "SFX" bus (falls back to Master). play() picks a free voice,
## or steals the one that started longest ago — a burst of 50 hits never creates 50 players.
## Small random pitch variation stops repeated sounds from feeling mechanical.
## In a game: autoload "Sfx", then Sfx.play(hit_stream) with a preloaded AudioStream.

@export var voices := 8
@export var pitch_variation := 0.08   ## ±8 %

var rng := RandomNumberGenerator.new()
var _players: Array[AudioStreamPlayer] = []
var _order: Array[int] = []   ## voice indices, oldest start first


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS   # UI clicks still sound in the pause menu
	var bus := "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	for i in voices:
		var p := AudioStreamPlayer.new()
		p.bus = bus
		add_child(p)
		_players.append(p)


## Returns the voice index used.
func play(stream: AudioStream, volume_db: float = 0.0) -> int:
	var idx := _pick_voice()
	var p := _players[idx]
	p.stream = stream
	p.volume_db = volume_db
	p.pitch_scale = 1.0 + rng.randf_range(-pitch_variation, pitch_variation)
	p.play()
	_order.erase(idx)
	_order.append(idx)
	return idx


func _pick_voice() -> int:
	for i in _players.size():
		if not _players[i].playing:
			return i
	return _order[0]


func player(idx: int) -> AudioStreamPlayer:
	return _players[idx]
