class_name RogueRun
extends Node3D
## The whole loop: hub → run (rooms → reward → doors → … → boss) → back to the hub, win or lose.
## Built on recipes: RunMap/RunState/MetaProgress (50), BoonPool/StatSheet (48), EncounterDirector (49, in rooms),
## BossBrain (51, in the boss), SaveSystem (13) for the meta progress. Death banks everything collected in the run.
## `start_depth` starts a run at a later room — for playtesting one room, and for the boss scenario.

signal state_changed(state: State)

enum State { HUB, ROOM, REWARD, DOORS, SHRINE, OVER }

const HUB := preload("res://scenes/hub/hub.tscn")
const ROOM := preload("res://scenes/room/room.tscn")
const CURRENCY_REWARD := 15
const KILL_EMBERS := 1
const HEAL_REWARD := 0.3
const REST_HEAL := 0.4

@export var rooms_per_run := 5
@export var start_depth := 0
@export var save_path := "user://meta.json"
@export var camera_offset := Vector3(0, 11, 8)

var state := State.HUB
var meta := MetaProgress.new()
var run := RunState.new()
var map := RunMap.new()
var pool := BoonCatalog.pool()
var owned: Array[StringName] = []
var current_door: RoomDoor
var room: RogueRoom
var hub: RogueHub
var offer: Array[BoonOffer] = []
var selected := 0
var runs_started := 0
var _save_blocked := false

@onready var player := $Player as RoguePlayer
@onready var camera := $Camera as Camera3D
@onready var _world := $World
@onready var ui := $UI/Root as RogueUI


func _ready() -> void:
	map.rooms = rooms_per_run
	map.elite_from = 999      # the template has no elites yet
	map.shop_chance = 0.0     # nor a shop
	meta.upgrades = {
		&"vitality": {"stat": &"max_health", "per_level": 10.0, "base_cost": 10, "max_level": 5},
		&"might": {"stat": &"attack_power", "per_level": 0.1, "base_cost": 15, "max_level": 5},
	}
	if GbHarness.active:
		save_path = "user://meta_harness.json"     # test runs never touch the player's progress
		DirAccess.remove_absolute(ProjectSettings.globalize_path(save_path))
	var loaded := SaveSystem.load_save(save_path)
	if loaded.result == SaveSystem.Result.CORRUPT or loaded.result == SaveSystem.Result.TOO_NEW:
		_save_blocked = true   # never overwrite a save we could not read (recipe 13)
	meta.from_dict((loaded.data as Dictionary).get("meta", {}))
	player.died.connect(_on_player_died)
	player.health_changed.connect(func(c: int, m: int) -> void: ui.set_health(c, m))
	ui.boon_chosen.connect(_on_boon_chosen)
	ui.upgrade_bought.connect(_buy_upgrade)
	ui.shrine_closed.connect(func() -> void:
		player.set_input_enabled(true)
		_set_state(State.HUB))
	go_hub()


func _physics_process(delta: float) -> void:
	var want := player.global_position + camera_offset
	camera.global_position = camera.global_position.lerp(want, clampf(8.0 * delta, 0.0, 1.0))


# ---------- hub ----------

func go_hub() -> void:
	_clear_world()
	hub = HUB.instantiate() as RogueHub
	_world.add_child(hub)
	hub.start_run_requested.connect(func() -> void: call_deferred(&"start_run", 1000 + runs_started))
	hub.shrine_opened.connect(_open_shrine)
	var sheet := StatSheet.new(player.tuning.base_stats())
	meta.apply_to(sheet)
	player.use_sheet(sheet)
	_place_player(hub.start_point)
	_set_state(State.HUB)
	ui.show_hub(meta)


func _open_shrine() -> void:
	if state != State.HUB:
		return
	_set_state(State.SHRINE)
	player.set_input_enabled(false)
	ui.show_shrine(meta)


func _buy_upgrade(id: StringName) -> void:
	if meta.buy(id):
		_save()
		var sheet := StatSheet.new(player.tuning.base_stats())
		meta.apply_to(sheet)
		player.use_sheet(sheet)
	ui.show_shrine(meta)


# ---------- run ----------

func start_run(seed: int) -> void:
	runs_started += 1
	run.begin(seed)
	owned.clear()
	var sheet := StatSheet.new(player.tuning.base_stats())
	meta.apply_to(sheet)
	player.use_sheet(sheet)
	current_door = RoomDoor.new(RoomDoor.Type.COMBAT, RoomDoor.Reward.BOON)
	run.depth = start_depth
	_enter_room(map.doors(run.depth, run.seed, RoomDoor.Type.COMBAT)[0] if start_depth > 0 else current_door)


func _enter_room(door: RoomDoor) -> void:
	current_door = door
	_clear_world()
	room = ROOM.instantiate() as RogueRoom
	_world.add_child(room)
	_place_player(room.start_point)
	room.enemy_killed.connect(func() -> void:
		run.collect(KILL_EMBERS)
		ui.set_run(run, rooms_per_run, owned))
	room.cleared.connect(_on_room_cleared)
	room.door_chosen.connect(_on_door_chosen)
	_set_state(State.ROOM)
	ui.set_run(run, rooms_per_run, owned)
	if door.type == RoomDoor.Type.REST:
		player.heal_fraction(REST_HEAL)
		ui.banner("Rest: +%d%% health" % roundi(REST_HEAL * 100))
		room.is_cleared = true
		_show_doors()
		return
	var boss_room := door.type == RoomDoor.Type.BOSS
	room.begin(player, run.depth, hash([run.seed, run.depth]), boss_room)
	if boss_room:
		room.boss.health_changed.connect(func(c: int, m: int) -> void: ui.set_boss(c, m))
		ui.set_boss(room.boss.brain.health, room.boss.brain.max_health)


func _on_room_cleared() -> void:
	ui.hide_boss()
	match current_door.reward:
		RoomDoor.Reward.BOON:
			_set_state(State.REWARD)
			offer = pool.offer(hash([run.seed, run.depth, &"boon"]), owned, 3)
			if offer.is_empty():
				_show_doors()
			else:
				player.set_input_enabled(false)
				ui.show_boons(offer)
		RoomDoor.Reward.CURRENCY:
			run.collect(CURRENCY_REWARD)
			ui.banner("+%d embers" % CURRENCY_REWARD)
			_show_doors()
		RoomDoor.Reward.HEAL:
			player.heal_fraction(HEAL_REWARD)
			ui.banner("+%d%% health" % roundi(HEAL_REWARD * 100))
			_show_doors()
		RoomDoor.Reward.UPGRADE:
			var m := StatModifier.new()
			m.stat = &"attack_power"
			m.op = StatModifier.Op.FLAT
			m.value = 0.1
			m.source = StringName("sharpen_%d" % run.depth)
			player.sheet.add(m)
			ui.banner("Sharpened: +0.1 damage")
			_show_doors()
		RoomDoor.Reward.NONE:
			_finish(true)
	ui.set_run(run, rooms_per_run, owned)


func _on_boon_chosen(index: int) -> void:
	var o := offer[index]
	o.boon.apply(player.sheet, o.rarity)
	owned.append(o.boon.id)
	player.set_input_enabled(true)
	ui.banner("%s (%s)" % [o.boon.title, Boon.Rarity.keys()[o.rarity].capitalize()])
	_show_doors()


func _show_doors() -> void:
	_set_state(State.DOORS)
	room.show_doors(map.doors(run.depth + 1, run.seed, current_door.type))


func _on_door_chosen(door: RoomDoor) -> void:
	run.enter(door)
	call_deferred(&"_enter_room", door)


func _on_player_died() -> void:
	if state == State.OVER or state == State.HUB:
		return
	_finish(false)


func _finish(won: bool) -> void:
	_set_state(State.OVER)
	var banked := run.end(won)
	meta.bank(banked)
	_save()
	player.set_input_enabled(false)
	ui.banner(("Victory! " if won else "Defeated. ") + "%d embers banked" % banked)
	await get_tree().create_timer(1.5, false).timeout
	player.set_input_enabled(true)
	go_hub()


# ---------- helpers ----------

func _set_state(s: State) -> void:
	state = s
	state_changed.emit(s)


func _place_player(at: Marker3D) -> void:
	player.global_position = at.global_position
	player.velocity = Vector3.ZERO
	camera.global_position = player.global_position + camera_offset


func _clear_world() -> void:
	for c in _world.get_children():
		_world.remove_child(c)
		c.queue_free()
	room = null
	hub = null


func _save() -> void:
	if _save_blocked:
		ui.banner("Save file unreadable — progress is not being saved")
		return
	SaveSystem.save(save_path, {"meta": meta.to_dict()})
