extends GutTest
## Fog honesty (spec: Contracts): the computer's enemy_base(), threat() and enemy_power_near() ignore enemy units and
## buildings its team hasn't seen; with nothing seen, enemy_base() is the enemy's start. A revealed attacker (a hit
## shows it to the victim's team for reveal_on_hit s) counts as seen. A team without a town hall is revealed after
## REVEAL_WITHOUT_HALL s, both ways, unless the map switches it off.

var g: RtsGame
var ai: RtsAiPlayer


func before_each() -> void:
	g = (load("res://tests/fixtures/sandbox.tscn") as PackedScene).instantiate() as RtsGame
	add_child_autofree(g)
	await wait_physics_frames(5)
	ai = RtsAiPlayer.new()
	ai.team = 1
	g.add_child(ai)
	await wait_physics_frames(2)


func _fog_tick() -> void:
	g._update_fog(1)
	g._update_fog(0)


func test_nothing_seen_means_the_start_position() -> void:
	var farm := g.place_building(0, &"farm", g.grid.footprint_at(Vector3(0, 0, 30), Vector2i(2, 2)), true)
	g.buildings.erase(g.buildings.filter(func(b: RtsBuilding) -> bool: return b.team == 0 and b.kind == &"town_hall")[0])
	_fog_tick()
	assert_false(farm.seen_by.has(1), "the dead haven't seen the farm")
	assert_eq(ai.enemy_base(), g.bases[0], "unseen buildings don't count: the enemy's start")


func test_a_seen_building_is_the_base() -> void:
	var farm := g.place_building(0, &"farm", g.grid.footprint_at(Vector3(20, 0, -10), Vector2i(2, 2)), true)
	g.buildings.erase(g.buildings.filter(func(b: RtsBuilding) -> bool: return b.team == 0 and b.kind == &"town_hall")[0])
	var scout := g.spawn_unit(1, &"worker", Vector3(20, 0, -14))
	_fog_tick()
	assert_true(farm.seen_by.has(1), "the dead's worker saw the farm")
	assert_eq(ai.enemy_base(), farm.global_position, "a seen building is where the enemy is")
	scout.take_damage(1e6, null)


func test_threat_and_power_ignore_unseen_units() -> void:
	var raider := g.spawn_unit(0, &"footman", g.bases[1] + Vector3(-2, 0, 8))
	for u in g.units.filter(func(x: RtsUnit) -> bool: return x.team == 1):
		u.global_position = g.bases[1] + Vector3(0, 0, -20)            # the dead's own units look the other way
	for b in g.buildings.filter(func(x: RtsBuilding) -> bool: return x.team == 1):
		b.def = b.def.duplicate()
		b.def.sight = 0.5                                              # and their hall sees nothing
	_fog_tick()
	assert_false(g.visible_to(1, raider), "the raider is in the dead's fog")
	assert_eq(ai.enemy_power_near(raider.global_position), 0.0, "unseen: no power counted")
	assert_eq(ai.threat(), Vector3.INF, "unseen: no threat")


func test_a_hit_reveals_the_attacker() -> void:
	var archer := g.spawn_unit(0, &"archer", Vector3(0, 0, 20))
	var victim := g.spawn_unit(1, &"footman", Vector3(0, 0, 11))
	for b in g.buildings.filter(func(x: RtsBuilding) -> bool: return x.team == 1):
		b.def = b.def.duplicate()
		b.def.sight = 0.5
	victim.def = victim.def.duplicate()
	victim.def.sight = 2.0                                             # the victim can't see 9 m away on its own
	_fog_tick()
	assert_false(g.visible_to(1, archer), "the archer is hidden from the dead")
	victim.take_damage(1.0, archer)
	_fog_tick()
	assert_true(g.visible_to(1, archer), "hit: the archer is seen by the victim's team")
	assert_eq(ai.enemy_power_near(archer.global_position), g.rules.value(&"archer"), "… and counts for the computer")
	g.elapsed += g.reveal_on_hit + 0.1
	_fog_tick()
	assert_false(g.visible_to(1, archer), "after reveal_on_hit s it is hidden again")


func test_a_team_without_a_town_hall_is_revealed_both_ways() -> void:
	var said: Array[String] = []
	g.message.connect(func(t: String) -> void: said.append(t))
	var dead_farm := g.place_building(1, &"farm", g.grid.footprint_at(Vector3(24, 0, -6), Vector2i(2, 2)), true)
	var march_farm := g.place_building(0, &"farm", g.grid.footprint_at(Vector3(-24, 0, 6), Vector2i(2, 2)), true)
	_fog_tick()
	assert_false(dead_farm.seen_by.has(0), "the dead's farm is unseen")
	for b in g.buildings.filter(func(x: RtsBuilding) -> bool: return x.kind == &"town_hall"):
		b.take_damage(1e6, null)
	await wait_physics_frames(2)
	g._check_hall_less(g.REVEAL_WITHOUT_HALL - 1.0)
	assert_false(dead_farm.seen_by.has(0), "not before REVEAL_WITHOUT_HALL s")
	g._check_hall_less(2.0)
	assert_true(dead_farm.seen_by.has(0) and dead_farm.visible, "the computer without a town hall: its farm is shown to the player")
	assert_true(march_farm.seen_by.has(1), "the player without a hall: the dead see the player's farm")
	assert_true(said.has("Wróg nie ma ratusza: jego budynki są widoczne") and said.has("Nie masz ratusza: wróg widzi twoje budynki"), "the player is told, both ways")
	assert_eq(ai.enemy_base(), march_farm.global_position, "and the computer goes for what it now sees")


func test_the_hall_less_reveal_can_be_off() -> void:
	g.reveal_hall_less = false
	var dead_farm := g.place_building(1, &"farm", g.grid.footprint_at(Vector3(24, 0, -6), Vector2i(2, 2)), true)
	for b in g.buildings.filter(func(x: RtsBuilding) -> bool: return x.kind == &"town_hall" and x.team == 1):
		b.take_damage(1e6, null)
	await wait_physics_frames(2)
	g._check_hall_less(g.REVEAL_WITHOUT_HALL + 1.0)
	assert_false(dead_farm.seen_by.has(0), "off (a map without halls): nothing is revealed")


func test_an_idle_unit_answers_its_attacker_only_for_a_while() -> void:
	var footman := g.spawn_unit(1, &"footman", Vector3(0, 0, 14))
	var archer := g.spawn_unit(0, &"archer", Vector3(9, 0, 14))
	g.spawn_unit(1, &"worker", Vector3(8, 0, 12))                    # a friend of the footman's sees the archer all the time
	await wait_physics_frames(2)
	_fog_tick()
	assert_true(g.visible_to(1, archer), "the archer is in the dead's sight")
	footman.take_damage(1.0, archer)
	g.elapsed += RtsUnit.ANSWER_WINDOW + 1.0
	await wait_physics_frames(15)
	assert_ne(footman.target, archer, "hit more than ANSWER_WINDOW s ago: it no longer chases")
	footman.take_damage(1.0, archer)
	await wait_physics_frames(15)
	assert_eq(footman.target, archer, "hit just now: it answers")
