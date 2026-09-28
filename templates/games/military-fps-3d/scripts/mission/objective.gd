class_name MilObjective
extends Area3D
## A "hold the action button" objective (plant a charge, hack a terminal): once `enabled`, a player standing inside
## holds `action` for `hold_time` seconds. Letting go resets the progress, so it is a decision to commit under fire.
## While the player is inside, `action` belongs to this objective (the player ignores `reload`, which shares the pad
## button). Observable: enabled, progress (0…1), done.

signal completed

@export var hold_time := 2.0
@export var prompt := "Przytrzymaj E — podłóż ładunek"

var enabled := false
var progress := 0.0
var done := false

var _player: MilPlayer


func _ready() -> void:
	body_entered.connect(func(b: Node3D) -> void:
		if b is MilPlayer:
			_player = b as MilPlayer)
	body_exited.connect(func(b: Node3D) -> void:
		if b == _player:
			if _player.interact_target == self:
				_player.interact_target = null
			_player = null
			progress = 0.0)


func player_inside() -> bool:
	return _player != null


func _physics_process(delta: float) -> void:
	if _player == null or done or not enabled or not _player.alive:
		progress = 0.0
		return
	_player.interact_target = self
	if Input.is_action_pressed("action"):
		progress = minf(progress + delta / hold_time, 1.0)
		if progress >= 1.0:
			done = true
			_player.interact_target = null
			completed.emit()
	else:
		progress = 0.0
