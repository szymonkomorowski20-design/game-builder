class_name BossBrain
extends RefCounted
## A boss fight as data plus rules. Health thresholds (fractions of max) start new phases; a hit that would cross a
## threshold stops on it, so a burst build can't skip a phase, and the boss is invulnerable for `transition_time`
## while it changes (roar, arena change, adds). It loops attacks: telegraph → strike → recovery, picking the next one
## by weight among the unlocked moves, never the same move twice in a row when there's a choice, from a seeded RNG.
## validate() checks the readability contract: telegraphs ≥ min_telegraph, recovery windows ≥ min_window.

signal phase_changed(phase: int)
signal attack_started(attack: BossAttack)
signal strike_started(attack: BossAttack)
signal died

enum State { ATTACK_TELEGRAPH, ATTACK_STRIKE, ATTACK_RECOVERY, TRANSITION, DEAD }

const EPS := 1e-4

var max_health := 300
var thresholds: Array[float] = [0.66, 0.33]
var transition_time := 1.0
var attacks: Array[BossAttack] = []
var min_telegraph := 0.4
var min_window := 0.5

var health := 0
var phase := 0
var state := State.ATTACK_TELEGRAPH

var _rng := RandomNumberGenerator.new()
var _attack: BossAttack
var _t := 0.0


func start(seed: int) -> void:
	_rng.seed = seed
	health = max_health
	phase = 0
	_attack = null
	_begin_attack()


func current_attack() -> BossAttack:
	return _attack if state in [State.ATTACK_TELEGRAPH, State.ATTACK_STRIKE, State.ATTACK_RECOVERY] else null


func is_telegraphing() -> bool:
	return state == State.ATTACK_TELEGRAPH


func is_striking() -> bool:
	return state == State.ATTACK_STRIKE


func is_recovering() -> bool:
	return state == State.ATTACK_RECOVERY


## Seconds spent in the current state — lets a host sync visuals (a filling telegraph) and lets tests act on time.
func state_elapsed() -> float:
	return _t


func is_invulnerable() -> bool:
	return state == State.TRANSITION or state == State.DEAD


func take_damage(amount: int) -> int:
	if is_invulnerable() or amount <= 0:
		return 0
	var floor_hp := 0
	if phase < thresholds.size():
		floor_hp = roundi(max_health * thresholds[phase])
	var before := health
	health = maxi(health - amount, floor_hp)
	if health == 0:
		state = State.DEAD
		died.emit()
	elif phase < thresholds.size() and health <= floor_hp:
		phase += 1
		state = State.TRANSITION
		_t = 0.0
		phase_changed.emit(phase)
	return before - health


func tick(delta: float) -> void:
	if state == State.DEAD:
		return
	_t += delta
	match state:
		State.TRANSITION:
			if _t + EPS >= transition_time:
				_begin_attack()
		State.ATTACK_TELEGRAPH:
			if _t + EPS >= _attack.telegraph:
				_t -= _attack.telegraph
				state = State.ATTACK_STRIKE
				strike_started.emit(_attack)
		State.ATTACK_STRIKE:
			if _t + EPS >= _attack.strike:
				_t -= _attack.strike
				state = State.ATTACK_RECOVERY
		State.ATTACK_RECOVERY:
			if _t + EPS >= _attack.recovery:
				_begin_attack()


## Readability contract: every problem as text (empty = fine). Run it in a test over the real boss data.
func validate() -> Array[String]:
	var problems: Array[String] = []
	for a in attacks:
		if a.telegraph + EPS < min_telegraph:
			problems.append("%s: telegraph %.2f s < %.2f s — too short to read" % [a.id, a.telegraph, min_telegraph])
		elif a.recovery + EPS < min_window:
			problems.append("%s: recovery %.2f s < %.2f s — no window to punish" % [a.id, a.recovery, min_window])
	return problems


func _begin_attack() -> void:
	var last_id: StringName = _attack.id if _attack != null else &""
	var open := attacks.filter(func(a: BossAttack) -> bool: return a.min_phase <= phase)
	var fresh := open.filter(func(a: BossAttack) -> bool: return a.id != last_id)
	var pool: Array = fresh if not fresh.is_empty() else open
	_attack = _weighted(pool)
	state = State.ATTACK_TELEGRAPH
	_t = 0.0
	attack_started.emit(_attack)


func _weighted(pool: Array) -> BossAttack:
	var total := 0.0
	for a: BossAttack in pool:
		total += a.weight
	var roll := _rng.randf() * total
	for a: BossAttack in pool:
		roll -= a.weight
		if roll < 0.0:
			return a
	return pool.back()
