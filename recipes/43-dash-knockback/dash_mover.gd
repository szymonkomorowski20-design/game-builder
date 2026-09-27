class_name DashMover
extends CharacterBody2D
## Demo: 8-direction movement (like recipe 01) + a dash on `action` toward the held direction (or the last one)
## + knockback from hits. While dashing or being knocked back, steering input is ignored.

@export var walk_speed := 160.0     ## px/s
@export var acceleration := 1200.0  ## px/s²

var dash := Dash.new()
var knockback := Knockback.new()
var dashes := 0
var _facing := Vector2.RIGHT


func _physics_process(delta: float) -> void:
	dash.tick(delta)
	knockback.tick(delta)
	var input := Input.get_vector("move_left", "move_right", "move_up", "move_down")
	if input != Vector2.ZERO:
		_facing = input.normalized()
	if Input.is_action_just_pressed("action") and dash.try_start(_facing):
		dashes += 1
	if dash.is_dashing():
		velocity = dash.velocity()
	elif knockback.active():
		velocity = knockback.velocity()
	else:
		velocity = velocity.move_toward(input * walk_speed, acceleration * delta)
	move_and_slide()


## Called by whatever hits the player (enemy contact, explosion). Ignored while invulnerable.
func take_hit(source: Vector2, strength: float) -> bool:
	if dash.is_invulnerable():
		return false
	knockback.hit(source, global_position, strength)
	return true
