extends GutTest
## R36 — balance contracts as tests: the simulator is fair (mirror ≈ 50 %), deterministic per seed, and the
## designed matchups stay inside their bands. When a Tuning change breaks a band, this fails and says by how much.

const WARRIOR := {"hp": 40, "damage": 7, "interval": 0.8, "crit_chance": 0.1, "crit_mult": 2.0, "armor": 1}
const SLIME := {"hp": 24, "damage": 4, "interval": 1.0, "armor": 0}
const KNIGHT := {"hp": 60, "damage": 5, "interval": 1.0, "armor": 3}


func test_r36_mirror_match_is_fair() -> void:
	var r := CombatSim.matchup(WARRIOR, WARRIOR, 2000, 7)
	# first strike is simultaneous, so a mirror is a coin flip (draws excluded)
	var decided: int = 2000 - int(r.draws)
	var rate: float = float(r.win_rate) * 2000.0 / decided
	assert_between(rate, 0.46, 0.54, "mirror win rate %.3f" % rate)


func test_r36_same_seed_same_result() -> void:
	assert_eq(CombatSim.matchup(WARRIOR, SLIME, 300, 42), CombatSim.matchup(WARRIOR, SLIME, 300, 42))


func test_r36_contract_warrior_vs_slime() -> void:
	# Design contract (spec Tuning section): the warrior always beats a slime, in 2–6 s.
	var r := CombatSim.matchup(WARRIOR, SLIME, 1000, 3)
	assert_gt(r.win_rate, 0.97, "warrior should almost always beat a slime (got %.2f)" % r.win_rate)
	assert_between(r.avg_time, 2.0, 6.0, "fight length %.2f s" % r.avg_time)


func test_r36_contract_armor_matters() -> void:
	# Armor 3 against 7 damage: the knight must win the long fight more often than it loses.
	var r := CombatSim.matchup(KNIGHT, WARRIOR, 1000, 5)
	assert_gt(r.win_rate, 0.5, "knight vs warrior %.2f" % r.win_rate)
	assert_gt(r.p90_time, r.p10_time)


func test_r36_economy_curve() -> void:
	assert_eq(CombatSim.upgrade_cost(10.0, 1.15, 0), 10)
	assert_eq(CombatSim.upgrade_cost(10.0, 1.15, 10), 40)
	# contract: upgrade 10 costs at most a minute of income at 1 coin/s
	assert_lt(CombatSim.seconds_to_afford(CombatSim.upgrade_cost(10.0, 1.15, 10), 1.0), 60.0)
	assert_eq(CombatSim.seconds_to_afford(10, 0.0), INF)
