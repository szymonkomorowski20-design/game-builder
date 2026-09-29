class_name Assassin
extends StealthMover
## The player (template stealth-parkour-3d): recipe 66's StealthMover, with recipe 67's Climber as a child, plus what
## the district needs:
## - health counted in hits (`max_health`), `take_hit(n)`, `died`;
## - hiding in hay or on the bench: `hide_in(kind, at)`, left by moving or pressing the action again;
## - the defence of recipe 71 (`CounterDefense`): a tap of `counter` counters, holding it blocks, `drop` dodges;
## - the strike: `strike` kills an unaware victim in reach at once (an assassination), or hits a fighter.
## The game (StealthGame) decides who can be struck and applies the results.

signal died
signal struck
signal hid(kind: StringName)

@export var max_health := 5
var health := 5
var hidden_in: StringName = &""
var defense := CounterDefense.new()
var alive := true
var clock := 0.0

@onready var climber: Climber = $Climber


func _ready() -> void:
	super._ready()
	health = max_health
	landed.connect(_on_landed)


func _physics_process(delta: float) -> void:
	clock += delta
	if not alive:
		return
	defense.blocking = _held(&"counter")
	if _just(&"counter"):
		defense.press_counter(clock)
	if _just(&"drop") and not is_hidden():
		defense.press_dodge(clock)
	if _just(&"strike") and not is_hidden():
		struck.emit()
	if is_hidden():
		velocity = Vector3.ZERO
		if _input_vector().length() > 0.5 or _just(&"jump"):
			hide_in(&"", global_position)
		return
	super._physics_process(delta)
	defense.forget_before(clock - 2.0)


func is_hidden() -> bool:
	return hidden_in != &""


## Hide (`kind` &"hay" / &"bench") with the feet at `at`, or come out (`kind` &"").
func hide_in(kind: StringName, at: Vector3) -> void:
	hidden_in = kind
	if kind != &"":
		teleport(at)
	var body := get_node_or_null("Body") as Node3D
	if body != null:
		body.visible = kind != &"hay"
	hid.emit(kind)


func take_hit(n: int) -> void:
	if not alive:
		return
	health = maxi(health - n, 0)
	if health == 0:
		alive = false
		died.emit()


## A fall's cost (recipe 66's FallRule) in hits: death from the deadly height, else a share of full health.
func _on_landed(_height: float, outcome: Dictionary) -> void:
	match int(outcome.kind):
		FallRule.Kind.DEAD:
			take_hit(health)
		FallRule.Kind.HURT:
			take_hit(maxi(1, roundi(float(outcome.damage) * max_health)))


func stealth_cues() -> Dictionary:
	var cues := super.stealth_cues()
	if is_hidden():
		cues.blended = true
	return cues
