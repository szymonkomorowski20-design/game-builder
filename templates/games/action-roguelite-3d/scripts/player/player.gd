class_name RoguePlayer
extends CharacterBody3D
## The hero. Moves on the ground plane (screen up = -Z), attacks with a recipe-47 combo (`attack`), dashes with a
## recipe-43 dash (`dash`) that is invulnerable and cancels an attack's recovery — never its committed windup/active.
## All numbers come from `tuning` and the run's StatSheet (recipe 48): speed, max_health, attack_power, burn_power.

signal died
signal health_changed(current: int, max_health: int)
signal dashed

@export var tuning: PlayerTuning

var sheet: StatSheet
var dash := Dash.new()
var facing := Vector3.FORWARD
var input_enabled := true
var burn := preload("res://data/burn_status.tres") as StatusDef

var _knock := Vector3.ZERO
var _flash := 0.0

@onready var melee := $Melee as ComboMelee3D
@onready var health := $Health as Health
@onready var _look := $Look as MeshInstance3D


func _ready() -> void:
	dash.speed = tuning.dash_speed
	dash.duration = tuning.dash_duration
	dash.cooldown = tuning.dash_cooldown
	dash.iframes_after = tuning.dash_iframes_after
	health.invulnerability_time = tuning.hurt_iframes
	health.died.connect(func() -> void: died.emit())
	health.damaged.connect(func(_a: int, _r: int) -> void: health_changed.emit(health.current, health.max_health))
	health.healed.connect(func(_a: int, _r: int) -> void: health_changed.emit(health.current, health.max_health))
	melee.hit_landed.connect(_on_hit_landed)
	if sheet == null:
		use_sheet(StatSheet.new(tuning.base_stats()))


## A new run (or the hub) hands the player its stat sheet; health starts full.
func use_sheet(new_sheet: StatSheet) -> void:
	if sheet != null and sheet.changed.is_connected(_on_stat_changed):
		sheet.changed.disconnect(_on_stat_changed)
	sheet = new_sheet
	sheet.changed.connect(_on_stat_changed)
	melee.damage_multiplier = sheet.value(&"attack_power")
	health.max_health = roundi(sheet.value(&"max_health"))
	health.current = health.max_health
	health_changed.emit(health.current, health.max_health)


func set_input_enabled(on: bool) -> void:
	input_enabled = on
	melee.process_mode = Node.PROCESS_MODE_INHERIT if on else Node.PROCESS_MODE_DISABLED
	if not on:
		velocity = Vector3.ZERO


func heal_fraction(fraction: float) -> int:
	return health.heal(roundi(health.max_health * fraction))


func is_invulnerable() -> bool:
	return dash.is_invulnerable() or health.is_invulnerable()


## Enemies and the boss call this. Ignored while dashing (i-frames) and during the hurt window.
func take_hit(damage: int, push: Vector3) -> void:
	if dash.is_invulnerable() or health.is_dead():
		return
	if health.take_damage(damage) > 0:
		_knock = push
		_flash = 0.15


func _physics_process(delta: float) -> void:
	dash.tick(delta)
	var input := Vector2.ZERO
	if input_enabled:
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
		if Input.is_action_just_pressed(&"dash"):
			_try_dash(input)
	var move := Vector3(input.x, 0.0, input.y)
	if dash.is_dashing():
		var v := dash.velocity()
		velocity = Vector3(v.x, 0.0, v.y)
	else:
		velocity = move * sheet.value(&"speed") * melee.move_scale() + _knock
	_knock = _knock.move_toward(Vector3.ZERO, tuning.knockback_decay * delta)
	if move.length() > 0.1 and melee.combo.phase == ComboAttack.Phase.IDLE:
		facing = move.normalized()
		look_at(global_position + facing, Vector3.UP)
	move_and_slide()


func _process(delta: float) -> void:
	_flash = maxf(_flash - delta, 0.0)
	_look.transparency = 0.5 if dash.is_invulnerable() else 0.0
	_look.scale = Vector3.ONE * (1.12 if _flash > 0.0 else 1.0)


func _try_dash(input: Vector2) -> void:
	var phase := melee.combo.phase
	if phase == ComboAttack.Phase.WINDUP or phase == ComboAttack.Phase.ACTIVE:
		return   # the swing is committed
	if phase == ComboAttack.Phase.RECOVERY:
		melee.combo.try_dash_cancel()
	var dir := input if input.length() > 0.1 else Vector2(facing.x, facing.z)
	if dash.try_start(dir.normalized()):
		dashed.emit()


func _on_stat_changed(stat: StringName) -> void:
	match stat:
		&"attack_power":
			melee.damage_multiplier = sheet.value(&"attack_power")
		&"max_health":
			var new_max := roundi(sheet.value(&"max_health"))
			var grown := new_max - health.max_health
			health.max_health = new_max
			if grown > 0:
				health.heal(grown)          # more max health also heals by the difference
			health.current = mini(health.current, new_max)
			health_changed.emit(health.current, health.max_health)


func _on_hit_landed(target: Node3D, _damage: int) -> void:
	if sheet.value(&"burn_power") > 0.0 and target.has_method(&"apply_status"):
		target.apply_status(burn)
