extends Node2D
## Demo: makes four placeholder animations (the look's scale/colour) and the state machine in code. In a real game
## the animations come from your sprite sheet or model and the state machine can be drawn in the editor instead.

@onready var player: AnimationPlayer = $Body/AnimationPlayer
@onready var tree: AnimationTree = $Body/AnimationTree


func _ready() -> void:
	var lib := AnimationLibrary.new()
	lib.add_animation(AnimStates.IDLE, _anim(Vector2(1, 1), Vector2(1, 0.94), Color(0.45, 0.75, 1)))
	lib.add_animation(AnimStates.RUN, _anim(Vector2(1.1, 0.9), Vector2(0.9, 1.1), Color(0.4, 0.9, 0.5)))
	lib.add_animation(AnimStates.JUMP, _anim(Vector2(0.8, 1.25), Vector2(0.8, 1.25), Color(1, 0.85, 0.3)))
	lib.add_animation(AnimStates.FALL, _anim(Vector2(1.2, 0.85), Vector2(1.2, 0.85), Color(0.95, 0.45, 0.35)))
	player.add_animation_library(&"", lib)
	tree.tree_root = AnimStates.build_machine([AnimStates.IDLE, AnimStates.RUN, AnimStates.JUMP, AnimStates.FALL])
	tree.anim_player = tree.get_path_to(player)
	tree.active = true


func _anim(a: Vector2, b: Vector2, colour: Color) -> Animation:
	var anim := Animation.new()
	anim.length = 0.4
	anim.loop_mode = Animation.LOOP_LINEAR
	var s := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(s, "Look:scale")
	anim.track_insert_key(s, 0.0, a)
	anim.track_insert_key(s, 0.2, b)
	anim.track_insert_key(s, 0.4, a)
	var c := anim.add_track(Animation.TYPE_VALUE)
	anim.track_set_path(c, "Look:modulate")
	anim.track_insert_key(c, 0.0, colour)
	return anim
