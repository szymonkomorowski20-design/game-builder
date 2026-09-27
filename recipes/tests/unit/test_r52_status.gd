extends GutTest
## R52 — status effects. A burn ticks damage at its interval for its duration (exact tick count); re-applying a
## REFRESH status resets its time but not its strength; a STACK status adds stacks up to max_stacks, damage scales
## with stacks and each application refreshes the time; a slow changes a stat through the StatSheet only while it
## lasts; cleanse removes everything and restores stats; `expired` fires once per ending.

const DT := 1.0 / 60.0

var fx: StatusEffects
var sheet: StatSheet
var damage := []


func _def(id: StringName, duration: float, interval: float, per_tick: int, stacking: StatusDef.Stacking, max_stacks: int = 1) -> StatusDef:
	var d := StatusDef.new()
	d.id = id
	d.duration = duration
	d.tick_interval = interval
	d.damage_per_tick = per_tick
	d.stacking = stacking
	d.max_stacks = max_stacks
	return d


func before_each() -> void:
	sheet = StatSheet.new({&"speed": 6.0})
	fx = StatusEffects.new(sheet)
	damage = []
	fx.damaged.connect(func(amount: int, id: StringName): damage.append([id, amount]))


func _run(seconds: float) -> void:
	for i in roundi(seconds / DT):
		fx.tick(DT)


func test_r52_burn_ticks_exactly() -> void:
	fx.apply(_def(&"burn", 2.0, 0.5, 3, StatusDef.Stacking.REFRESH))
	_run(0.49)
	assert_eq(damage.size(), 0, "no tick before the first interval")
	_run(0.02)
	assert_eq(damage.size(), 1, "first tick at 0.5 s")
	_run(2.0)
	assert_eq(damage, [[&"burn", 3], [&"burn", 3], [&"burn", 3], [&"burn", 3]], "4 ticks in 2 s, then it ends")
	assert_false(fx.has(&"burn"))


func test_r52_refresh_resets_time_not_strength() -> void:
	var burn := _def(&"burn", 1.0, 0.5, 3, StatusDef.Stacking.REFRESH)
	fx.apply(burn)
	_run(0.9)
	fx.apply(burn)
	assert_eq(fx.stacks(&"burn"), 1)
	_run(0.9)
	assert_true(fx.has(&"burn"), "refreshed: still burning 1.8 s after the first application")
	for d in damage:
		assert_eq(d[1], 3, "strength unchanged")


func test_r52_stacks_scale_damage_up_to_max() -> void:
	var poison := _def(&"poison", 2.0, 1.0, 2, StatusDef.Stacking.STACK, 3)
	for i in 5:
		fx.apply(poison)
	assert_eq(fx.stacks(&"poison"), 3, "capped at max_stacks")
	_run(1.01)
	assert_eq(damage, [[&"poison", 6]], "2 per stack × 3")


func test_r52_slow_changes_the_stat_only_while_active() -> void:
	var slow := _def(&"slow", 1.0, 0.0, 0, StatusDef.Stacking.REFRESH)
	var m := StatModifier.new()
	m.stat = &"speed"
	m.op = StatModifier.Op.MORE
	m.value = 0.5
	slow.modifiers = [m]
	fx.apply(slow)
	assert_almost_eq(sheet.value(&"speed"), 3.0, 1e-6, "halved while slowed")
	fx.apply(slow)
	assert_almost_eq(sheet.value(&"speed"), 3.0, 1e-6, "re-applying doesn't slow twice")
	_run(1.1)
	assert_almost_eq(sheet.value(&"speed"), 6.0, 1e-6, "restored when it ends")


func test_r52_cleanse_and_expired_once() -> void:
	var ended := []
	fx.expired.connect(func(id: StringName): ended.append(id))
	var slow := _def(&"slow", 5.0, 0.0, 0, StatusDef.Stacking.REFRESH)
	var m := StatModifier.new()
	m.stat = &"speed"
	m.op = StatModifier.Op.FLAT
	m.value = -2.0
	slow.modifiers = [m]
	fx.apply(slow)
	fx.apply(_def(&"burn", 5.0, 0.5, 1, StatusDef.Stacking.REFRESH))
	fx.cleanse()
	assert_false(fx.has(&"slow"))
	assert_false(fx.has(&"burn"))
	assert_almost_eq(sheet.value(&"speed"), 6.0, 1e-6)
	_run(6.0)
	ended.sort()
	assert_eq(ended, [&"burn", &"slow"], "each ended once (by cleanse), not again later")
