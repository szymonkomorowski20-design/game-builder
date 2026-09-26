class_name CombatSim
extends RefCounted
## Monte-Carlo duel simulator for balance contracts: "a level-3 warrior beats a slime 85–95 % of the time in
## 4–8 s". Stats are plain dictionaries (or read them from your stat Resources); the RNG is seeded, so a balance
## test is deterministic and a change in numbers shows up as a failing band, not as a vague feeling.
##   unit = {"hp": 30, "damage": 6, "interval": 0.8, "crit_chance": 0.1, "crit_mult": 2.0, "armor": 1}

const DT := 0.05   ## simulation step (s)


## One duel. Returns {"winner": 0|1|-1 (timeout), "time": seconds}.
static func duel(a: Dictionary, b: Dictionary, rng: RandomNumberGenerator, max_time: float = 120.0) -> Dictionary:
	var hp := [float(a.hp), float(b.hp)]
	var cd := [float(a.get("first_delay", 0.0)), float(b.get("first_delay", 0.0))]
	var units := [a, b]
	var t := 0.0
	while t < max_time:
		t += DT
		for i in 2:
			cd[i] -= DT
			if cd[i] <= 0.0:
				cd[i] += float(units[i].interval)
				var other := 1 - i
				var dmg := float(units[i].damage)
				if rng.randf() < float(units[i].get("crit_chance", 0.0)):
					dmg *= float(units[i].get("crit_mult", 2.0))
				hp[other] -= maxf(1.0, dmg - float(units[other].get("armor", 0.0)))
		# simultaneous deaths are resolved in favour of nobody (counted as a draw)
		if hp[0] <= 0.0 and hp[1] <= 0.0:
			return {"winner": -1, "time": t}
		if hp[1] <= 0.0:
			return {"winner": 0, "time": t}
		if hp[0] <= 0.0:
			return {"winner": 1, "time": t}
	return {"winner": -1, "time": max_time}


## Many duels → {"win_rate": a's wins / trials, "draws": n, "avg_time": s, "p10_time": s, "p90_time": s}
static func matchup(a: Dictionary, b: Dictionary, trials: int = 1000, seed_value: int = 1) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	var wins := 0
	var draws := 0
	var times: Array[float] = []
	for i in trials:
		var r := duel(a, b, rng)
		if r.winner == 0:
			wins += 1
		elif r.winner == -1:
			draws += 1
		times.append(r.time)
	times.sort()
	var total := 0.0
	for x in times:
		total += x
	return {
		"win_rate": float(wins) / trials, "draws": draws, "avg_time": total / trials,
		"p10_time": times[int(trials * 0.1)], "p90_time": times[int(trials * 0.9)],
	}


## Economy helper: price of the n-th upgrade with geometric growth, and seconds of income needed for it.
static func upgrade_cost(base: float, growth: float, n: int) -> int:
	return int(round(base * pow(growth, n)))


static func seconds_to_afford(cost: int, income_per_s: float) -> float:
	return INF if income_per_s <= 0.0 else cost / income_per_s
