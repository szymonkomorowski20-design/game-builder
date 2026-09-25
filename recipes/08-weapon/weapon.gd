class_name Weapon
extends Node2D
## Ranged weapon: cooldown between shots, magazine, timed reload. `try_fire()` returns whether a
## shot left the barrel, so the caller can play sounds/animations only for real shots.

signal fired(projectile: Node2D)
signal reloaded
signal empty

@export var projectile_scene: PackedScene
## Where projectiles are added. Empty → the current scene, else this weapon's parent. Projectiles must
## NOT be children of the weapon, or they would move and rotate with it after being fired.
@export var spawn_parent: Node
@export var cooldown: float = 0.2        ## s between shots
@export var magazine_size: int = 6
@export var reload_time: float = 1.0     ## s

var ammo: int
var _cooldown_left: float = 0.0
var _reload_left: float = 0.0


func _ready() -> void:
	ammo = magazine_size


func _process(delta: float) -> void:
	advance(delta)


func advance(delta: float) -> void:
	_cooldown_left = maxf(_cooldown_left - delta, 0.0)
	if _reload_left > 0.0:
		_reload_left -= delta
		if _reload_left <= 0.0:
			_reload_left = 0.0
			ammo = magazine_size
			reloaded.emit()


func is_reloading() -> bool:
	return _reload_left > 0.0


func reload() -> void:
	if not is_reloading() and ammo < magazine_size:
		_reload_left = reload_time


func try_fire(direction: Vector2) -> bool:
	if is_reloading() or _cooldown_left > 0.0:
		return false
	if ammo <= 0:
		empty.emit()
		return false
	ammo -= 1
	_cooldown_left = cooldown
	var p: Node2D = projectile_scene.instantiate() if projectile_scene else Node2D.new()
	if "direction" in p:
		p.set("direction", direction)
	_spawn_target().add_child(p)
	p.global_position = global_position
	fired.emit(p)
	return true


func _spawn_target() -> Node:
	if spawn_parent:
		return spawn_parent
	if get_tree().current_scene:
		return get_tree().current_scene
	return get_parent()
