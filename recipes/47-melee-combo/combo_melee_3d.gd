class_name ComboMelee3D
extends Node3D
## Hosts a ComboAttack in 3D. It reads the attack action, sizes the hitbox (an Area3D child reaching forward, -Z)
## to the current step, and while the swing is active hits every overlapping body that has
## `take_hit(damage: int, push: Vector3)` — each body once per swing (per hit id), however many frames it overlaps.

signal hit_landed(target: Node3D, damage: int)

@export var steps: Array[AttackStep] = []
@export var buffer_time := 0.15
@export var attack_action: StringName = &"action"
@export var move_scale_attacking := 0.25   ## the owner multiplies its speed by move_scale()
@export var hitbox: Area3D                  ## mask it to the enemies' layer only
@export var damage_multiplier := 1.0        ## the owner's power (boons, upgrades — recipe 48); damage = round(step × this)

var combo := ComboAttack.new()
var _last_hit_id := {}   # target instance id → the swing's hit id that already hit it


## A three-swing combo to start from: two quick cuts, then a slower, longer finisher with more reach and push.
static func default_combo() -> Array[AttackStep]:
	var out: Array[AttackStep] = []
	for spec: Array in [[0.08, 0.06, 0.22, 10, 4.0, 1.6], [0.08, 0.06, 0.22, 12, 4.0, 1.6], [0.14, 0.08, 0.40, 25, 8.0, 2.0]]:
		var s := AttackStep.new()
		s.windup = spec[0]
		s.active = spec[1]
		s.recovery = spec[2]
		s.damage = spec[3]
		s.knockback = spec[4]
		s.reach = spec[5]
		out.append(s)
	return out


func _ready() -> void:
	if steps.is_empty():
		steps = default_combo()
	combo.steps = steps
	combo.buffer_time = buffer_time
	combo.step_started.connect(_fit_hitbox)


func _physics_process(delta: float) -> void:
	if Input.is_action_just_pressed(attack_action):
		combo.press()
	combo.tick(delta)
	if combo.is_hitting():
		_hit_overlapping()


## 1 while free, `move_scale_attacking` during a swing: attacks root you a little, dashes cancel the recovery.
func move_scale() -> float:
	return 1.0 if combo.phase == ComboAttack.Phase.IDLE else move_scale_attacking


func _fit_hitbox(index: int) -> void:
	var col := hitbox.get_child(0) as CollisionShape3D
	var box := col.shape as BoxShape3D
	box.size.z = steps[index].reach
	col.position.z = -steps[index].reach / 2.0


func _hit_overlapping() -> void:
	var step := combo.current_step()
	var push := -global_transform.basis.z * step.knockback
	for body in hitbox.get_overlapping_bodies():
		if not body.has_method(&"take_hit"):
			continue
		var id := body.get_instance_id()
		if _last_hit_id.get(id, -1) == combo.hit_id:
			continue
		_last_hit_id[id] = combo.hit_id
		var dealt := roundi(step.damage * damage_multiplier)
		body.take_hit(dealt, push)
		hit_landed.emit(body, dealt)
