class_name EncounterZone
extends Area3D
## One combat arena of the mission. Its children:
##   CollisionShape3D — the trigger: standing in it starts the fight when the mission expects this zone
##                      (`MilMission.can_start`), unless `trigger_on_enter` is off;
##   Cover/  — Marker3Ds behind low cover; soldiers of this zone pick among them (CoverFinder, recipe 57);
##   Spawns/ — Marker3Ds where soldiers appear, hidden from the way the player comes in (SpawnPicker);
##   Checkpoint — Marker3D: where the player comes back after dying in this zone (set when the zone starts).
## Waves come one after another: the next one `wave_delay` s after the previous is completely dead (recipe 49's
## rule). `cleared` fires once. Dying resets an unfinished zone: its soldiers vanish and the trigger re-arms.
## The zone's `ahead` is its −Z: the way the player pushes through it (spawns behind that are unfair).

signal started(zone: EncounterZone)
signal wave_started(zone: EncounterZone, index: int)
signal cleared(zone: EncounterZone)

@export var order := 1                       ## checkpoint order (recipe 41: furthest wins)
@export var title := "Strefa"
@export var waves: Array[int] = [3]          ## soldiers per wave
@export var wave_delay := 1.5                ## s after a wave is dead before the next
@export var trigger_on_enter := true
## The first N waves start dug in: crouched at cover points hidden from the player (they were there before the
## player arrived). Later waves run in from the Spawns, as reinforcements.
@export var dug_in_waves := 1

var active := false
var done := false
var wave := -1
var alive: Array[MilSoldier] = []
var mission: MilMission

var _next_in := -1.0
var _waits := 0
var _arm_in := 0.0            # after a reset: the physics server still has a respawned player at the old spot

const ARM_TIME := 0.3

const WAIT_STEP := 0.5         ## s between asks for a fair spawn
const MAX_WAITS := 10          ## then it spawns anyway (and the mission counts an unfair spawn)


func ahead() -> Vector3:
	return -global_transform.basis.z


func cover_points() -> Array[Vector3]:
	return _markers(^"Cover")


func spawn_points() -> Array[Vector3]:
	return _markers(^"Spawns")


func checkpoint_position() -> Vector3:
	var m := get_node_or_null(^"Checkpoint") as Node3D
	return m.global_position if m != null else global_position


func soldiers_total() -> int:
	var n := 0
	for w in waves:
		n += w
	return n


func _markers(path: NodePath) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var root := get_node_or_null(path)
	if root != null:
		for c in root.get_children():
			out.append((c as Node3D).global_position)
	return out


func start() -> void:
	if active or done or (mission != null and not mission.can_start(self)):
		return
	active = true
	wave = -1
	started.emit(self)
	_next_wave()


func _next_wave() -> void:
	wave += 1
	if wave >= waves.size():
		active = false
		done = true
		cleared.emit(self)
		return
	alive = mission.spawn_wave(self, waves[wave], _waits >= MAX_WAITS)
	if alive.is_empty() and waves[wave] > 0:
		_waits += 1
		wave -= 1
		_next_in = WAIT_STEP
		return
	_waits = 0
	for s in alive:
		s.died.connect(_on_soldier_died)
	wave_started.emit(self, wave)


func _on_soldier_died(s: MilSoldier) -> void:
	alive.erase(s)
	if alive.is_empty() and active:
		_next_in = wave_delay


func _physics_process(delta: float) -> void:
	# Checked every frame, not on entering: a player already standing here when the zone's turn comes starts it.
	_arm_in = maxf(_arm_in - delta, 0.0)
	var here := _arm_in <= 0.0 and mission != null and mission.player.alive and overlaps_body(mission.player)
	if trigger_on_enter and not active and not done and here and mission.can_start(self):
		start()
	if _next_in < 0.0:
		return
	_next_in -= delta
	if _next_in <= 0.0:
		_next_in = -1.0
		if active:
			_next_wave()


## The player died here: the fight starts over when they walk back in (or when the mission restarts it).
func reset() -> void:
	for s in alive:
		if is_instance_valid(s):
			s.queue_free()
	alive.clear()
	active = false
	wave = -1
	_next_in = -1.0
	_waits = 0
	_arm_in = ARM_TIME
