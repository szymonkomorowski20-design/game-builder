extends GutTest
## The template's rules and contracts, without the scene tree:
## - EnemyBrain: chase → windup → strike → recover with exact timings; a hit staggers only while chasing or recovering
##   (a started telegraph always finishes — the player can trust it).
## - Boons: every catalog boon changes its stat; synergies only appear once both schools are owned.
## - Readability: every boss move passes BossBrain.validate() (telegraph ≥ 0.4 s, a window ≥ 0.5 s to punish).
## - Balance at base stats: time to kill a rusher / a brute / the boss stays inside the bands the spec sets, and no
##   single hit takes more than 20% (basic enemy) or 30% (boss) of the hero's base health.

const DT := 1.0 / 60.0


func _brain() -> EnemyBrain:
	var b := EnemyBrain.new()
	b.configure(load("res://data/rusher.tres"))
	return b


func test_enemy_brain_cycle() -> void:
	var b := _brain()
	b.tick(DT, 5.0)
	assert_eq(b.state, EnemyBrain.State.CHASE, "far away: chase")
	b.tick(DT, 1.0)
	assert_eq(b.state, EnemyBrain.State.WINDUP, "in range: windup starts")
	var strikes := [0]
	b.strike_started.connect(func() -> void: strikes[0] += 1)
	for i in roundi(0.45 / DT):
		b.tick(DT, 1.0)
	assert_eq(b.state, EnemyBrain.State.STRIKE, "strike after the 0.45 s telegraph")
	assert_eq(strikes[0], 1)
	for i in ceili(0.12 / DT):
		b.tick(DT, 1.0)
	assert_eq(b.state, EnemyBrain.State.RECOVER)


func test_enemy_hits_never_cancel_a_telegraph() -> void:
	var b := _brain()
	b.tick(DT, 1.0)
	b.hit()
	assert_eq(b.state, EnemyBrain.State.WINDUP, "windup is not interrupted by a hit")
	var c := _brain()
	c.tick(DT, 5.0)
	c.hit()
	assert_eq(c.state, EnemyBrain.State.STAGGER, "a chasing enemy is staggered")


func test_every_boon_changes_its_stat_and_synergies_are_gated() -> void:
	for boon in BoonCatalog.all():
		var sheet := StatSheet.new({&"speed": 6.0, &"max_health": 60.0, &"attack_power": 1.0})
		var stat: StringName = boon.modifiers[0].stat
		var before := sheet.value(stat)
		boon.apply(sheet)
		assert_ne(sheet.value(stat), before, "%s changes %s" % [boon.id, stat])
	var pool := BoonCatalog.pool()
	var early := pool.eligible([] as Array[StringName]).map(func(b: Boon): return b.id)
	assert_false(early.has(&"momentum"), "no synergy before its schools")
	var later := pool.eligible([&"swift_feet", &"heavy_blows"] as Array[StringName]).map(func(b: Boon): return b.id)
	assert_true(later.has(&"momentum"), "speed + power → Momentum offered")


func test_boss_moves_are_readable() -> void:
	var brain := BossBrain.new()
	brain.attacks = RogueBoss.moves()
	brain.min_telegraph = 0.4
	brain.min_window = 0.5
	assert_eq(brain.validate(), [], "every boss move can be read and punished")


## Seconds of perfect play to deal `hp` with the default combo at `power` (loop the combo, no misses).
func _time_to_kill(hp: int, power: float) -> float:
	var steps := ComboMelee3D.default_combo()
	var t := 0.0
	var dealt := 0
	var i := 0
	while dealt < hp:
		var s := steps[i % steps.size()]
		t += s.windup
		dealt += roundi(s.damage * power)
		if dealt >= hp:
			break
		t += s.active + (s.recovery if i % steps.size() == steps.size() - 1 else 0.0)
		i += 1
	return t


func test_balance_time_to_kill_at_base_stats() -> void:
	var rusher: EnemyTuning = load("res://data/rusher.tres")
	var brute: EnemyTuning = load("res://data/brute.tres")
	var ttk_rusher := _time_to_kill(rusher.max_health, 1.0)
	var ttk_brute := _time_to_kill(brute.max_health, 1.0)
	assert_between(ttk_rusher, 0.3, 1.2, "a rusher falls to about one combo (%.2f s)" % ttk_rusher)
	assert_between(ttk_brute, 1.0, 3.5, "a brute takes a few combos (%.2f s)" % ttk_brute)
	var boss := RogueBoss.new()
	var ttk_boss := _time_to_kill(boss.max_health, 1.0) + 2 * 1.2
	boss.free()
	assert_between(ttk_boss, 8.0, 40.0, "the boss is a fight, not a formality or a slog (%.1f s of perfect play)" % ttk_boss)


func test_balance_no_hit_takes_too_much() -> void:
	var base_hp: int = (load("res://data/player_tuning.tres") as PlayerTuning).max_health
	for path in ["res://data/rusher.tres", "res://data/brute.tres"]:
		var e: EnemyTuning = load(path)
		assert_lte(e.damage, base_hp * 0.2, "%s hits for ≤ 20%% of base health" % path.get_file())
	for m in RogueBoss.moves():
		assert_lte(m.damage, base_hp * 0.3, "boss %s hits for ≤ 30%% of base health" % m.id)
