extends GutTest
## The computer's habits measured in the proof game Kamienna Marchia (recipe 64's README: the host's habits), each on
## its own — the bot games only show them in sum, and one seed can win without any of them:
## - a threat is a visible enemy on our half near our buildings, not one idling on its own half next to our farthest farm;
## - an idle production building trains while the build order waits, keeping FILLER_RESERVE gold;
## - the margin of free food grows with the barracks, and with wood in the bank farms go up together;
## - the difficulty presets cap the computer's production and its army's food, and a game applies the ceiling.
## The map is the template's: bases at (−22, 22) and (22, −22), so the halves meet on the line x = z.

var g: RtsGame


func before_each() -> void:
	g = (load("res://tests/fixtures/sandbox.tscn") as PackedScene).instantiate() as RtsGame
	add_child_autofree(g)
	await wait_physics_frames(5)


func _ai(team: int, bot: bool) -> RtsAiPlayer:
	var ai := RtsAiPlayer.new()
	ai.team = team
	ai.player_bot = bot
	g.add_child(ai)
	ai.set_physics_process(false)            # the tests call its habits one at a time; it doesn't think on its own here
	return ai


func _gold(t: int, n: int) -> void:
	var s := g.stockpile(t)
	s.spend({&"gold": s.amount(&"gold")})
	s.add(&"gold", n)


func test_a_threat_is_an_enemy_on_our_half() -> void:
	var ai := _ai(1, false)
	await wait_physics_frames(2)
	var farm := g.place_building(1, &"farm", g.grid.footprint_at(Vector3(-15, 0, -21), Vector2i(2, 2)), true)
	assert_not_null(farm, "(the dead's farthest farm, on their half: x > z)")
	g.spawn_unit(1, &"worker", Vector3(-16, 0, -19))                   # its eyes
	var enemy := g.spawn_unit(0, &"footman", Vector3(-21, 0, -15))     # on the march's half (x < z), 6.5 m from the farm
	g._update_fog(1)
	assert_true(g.visible_to(1, enemy), "(the dead see it)")
	assert_eq(ai.threat(), Vector3.INF, "an enemy idling on its own half is no threat, even next to our farthest farm")
	enemy.global_position = Vector3(-15, 0, -17)                       # a step onto the dead's half
	g._update_fog(1)
	assert_eq(ai.threat(), enemy.global_position, "on our half near our buildings: a threat")


func test_idle_production_trains_keeping_a_reserve() -> void:
	var ai := _ai(1, false)
	await wait_physics_frames(2)
	var barracks := g.place_building(1, &"barracks", g.grid.footprint_at(Vector3(14, 0, -24), Vector2i(3, 3)), true)
	assert_not_null(barracks, "(a finished barracks)")
	var cost := int(g.rules.unit(&"footman").cost.get(&"gold", 0))
	_gold(1, cost + RtsAiPlayer.FILLER_RESERVE - 1)
	ai._spend_the_bank()                    # its once-a-second habits, the idle-production one among them
	assert_true(barracks.production.queue.is_empty(), "short of the reserve: nothing is trained")
	_gold(1, cost + RtsAiPlayer.FILLER_RESERVE)
	ai._spend_the_bank()                    # its once-a-second habits, the idle-production one among them
	assert_eq(barracks.production.queue.size(), 1, "with the reserve kept: the idle barracks trains")


func test_the_food_margin_grows_with_the_barracks() -> void:
	var ai := _ai(1, false)
	await wait_physics_frames(2)
	ai._spend_the_bank()
	assert_eq(ai.brain.supply_margin, RtsAiPlayer.SUPPLY_MARGIN, "no barracks: the base margin")
	assert_not_null(g.place_building(1, &"barracks", g.grid.footprint_at(Vector3(14, 0, -24), Vector2i(3, 3)), true), "(barracks 1)")
	assert_not_null(g.place_building(1, &"barracks", g.grid.footprint_at(Vector3(6, 0, -16), Vector2i(3, 3)), true), "(barracks 2)")
	assert_eq(g.count(1, &"barracks"), 2, "(two barracks)")
	ai._spend_the_bank()
	assert_eq(ai.brain.supply_margin, RtsAiPlayer.SUPPLY_MARGIN + 2 * RtsAiPlayer.SUPPLY_PER_BARRACKS, "two barracks: two steps more")


func test_the_difficulty_caps_production_and_the_army_s_food() -> void:
	var production := []
	var food := []
	for level in 3:
		production.append(int(RtsAiBrain.preset(level).production))
		food.append(int(RtsAiBrain.preset(level).max_supply))
	assert_eq(production, [2, 3, 4], "production buildings: Łatwy 2, Normalny 3, Trudny 4")
	assert_eq(food, [70, 85, 100], "the army's food: 70, 85, 100")
	var easy := (load("res://scenes/skirmish/skirmish.tscn") as PackedScene).instantiate() as RtsGame
	easy.ai_level = 0
	add_child_autofree(easy)
	await wait_physics_frames(3)
	assert_eq(easy.stockpile(1).max_supply, 70, "a game at Łatwy: the computer's ceiling is 70")
	assert_eq(easy.stockpile(0).max_supply, easy.rules.max_supply, "… the player's is the rules' own")
	assert_eq((easy.get_node("AI") as RtsAiPlayer).max_barracks, 2, "… and the computer runs at most 2 barracks")

func test_farms_go_up_together_when_the_wood_is_there() -> void:
	var ai := _ai(1, false)
	await wait_physics_frames(2)
	var s := g.stockpile(1)
	s.supply_used = s.supply_cap - 1                                   # food short of the margin
	var first := g.place_building(1, &"farm", g.grid.footprint_at(Vector3(14, 0, -24), Vector2i(2, 2)), false)
	assert_not_null(first, "(one farm on its way: the brain's own)")
	var farm_wood := int(g.rules.building(&"farm").cost.get(&"wood", 0))
	var each := RtsAiPlayer.FARM_WOOD_EACH * farm_wood
	s.spend({&"wood": s.amount(&"wood")})
	s.add(&"wood", each - 1)
	for i in 3:
		ai._spend_the_bank()
	assert_eq(g.pending(1, &"farm"), 1, "less than %d wood (%d farms' worth): one farm at a time" % [each, RtsAiPlayer.FARM_WOOD_EACH])
	s.add(&"wood", 5 * each)
	for i in 5:
		ai._spend_the_bank()
	assert_eq(g.pending(1, &"farm"), RtsAiPlayer.MAX_FARMS_AT_ONCE, "plenty of wood: more farms at once, up to MAX_FARMS_AT_ONCE")
