class_name BossDemo
extends Node2D
## A boss run by BossBrain, drawn in 2D: a telegraph ring that fills up before each strike, a flash while it strikes,
## a health bar with the phase thresholds marked. `action` hits it for 40 (a stand-in for the player's combat).
## Records how long every telegraph was actually on screen before its strike.

var brain := BossBrain.new()
var telegraph_seconds: Array[float] = []   ## measured, one per strike
var hits_blocked := 0
var _telegraph_t := 0.0

@onready var _label := $Info as Label


func _ready() -> void:
	brain.max_health = 300
	brain.thresholds = [0.66, 0.33]
	brain.transition_time = 1.0
	brain.attacks = [_attack(&"slam", 0.6, 0.2, 0.8, 0), _attack(&"sweep", 0.5, 0.3, 0.7, 0), _attack(&"storm", 0.8, 0.5, 1.0, 1)]
	brain.attack_started.connect(func(_a: BossAttack): _telegraph_t = 0.0)
	brain.strike_started.connect(func(_a: BossAttack): telegraph_seconds.append(_telegraph_t))
	brain.start(5)


func _physics_process(delta: float) -> void:
	if brain.is_telegraphing():
		_telegraph_t += delta
	brain.tick(delta)
	var a := brain.current_attack()
	_label.text = "HP %d/%d · phase %d · %s%s" % [brain.health, brain.max_health, brain.phase,
		("TRANSITION (invulnerable)" if brain.state == BossBrain.State.TRANSITION else (String(a.id) if a != null else "DEAD")),
		(" — telegraph" if brain.is_telegraphing() else (" — STRIKE" if brain.is_striking() else ""))]
	queue_redraw()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(&"action"):
		if brain.take_damage(40) == 0 and brain.health > 0:
			hits_blocked += 1


func _draw() -> void:
	var center := Vector2(320, 190)
	var body := Color(0.8, 0.3, 0.35) if brain.health > 0 else Color(0.3, 0.3, 0.3)
	if brain.state == BossBrain.State.TRANSITION:
		body = Color(1, 1, 1)
	draw_rect(Rect2(center - Vector2(30, 30), Vector2(60, 60)), body)
	var a := brain.current_attack()
	if a != null and brain.is_telegraphing():
		var k := clampf(_telegraph_t / a.telegraph, 0.0, 1.0)
		draw_arc(center, 110.0, 0.0, TAU, 64, Color(1, 0.8, 0.2, 0.9), 3.0)
		draw_circle(center, 110.0 * k, Color(1, 0.8, 0.2, 0.25))
	elif a != null and brain.is_striking():
		draw_circle(center, 110.0, Color(1, 0.3, 0.2, 0.55))
	var bar := Rect2(170, 330, 300, 12)
	draw_rect(bar, Color(0.2, 0.2, 0.2))
	draw_rect(Rect2(bar.position, Vector2(bar.size.x * brain.health / float(brain.max_health), bar.size.y)), Color(0.9, 0.25, 0.3))
	for t in brain.thresholds:
		draw_line(bar.position + Vector2(bar.size.x * t, -3), bar.position + Vector2(bar.size.x * t, bar.size.y + 3), Color.WHITE, 2.0)


static func _attack(id: StringName, telegraph: float, strike: float, recovery: float, min_phase: int) -> BossAttack:
	var a := BossAttack.new()
	a.id = id
	a.telegraph = telegraph
	a.strike = strike
	a.recovery = recovery
	a.min_phase = min_phase
	return a
