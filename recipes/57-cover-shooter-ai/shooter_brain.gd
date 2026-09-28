class_name ShooterBrain
extends RefCounted
## A cover-shooter soldier's decisions without any 3D (recipe 57). The body (ShooterBody / your enemy) feeds it facts
## each tick and does what `state` says:
##   MOVE      — go to `cover_target` (a CoverFinder pick); arriving → COVER
##   COVER     — hidden; after `peek_wait` (longer while suppressed) → PEEK, if a shoot token is free
##   PEEK      — exposed, firing bursts at the player with `accuracy()` ramping up over `aim_time`; after
##               `peek_time` or when the magazine runs dry → COVER (RELOAD if empty)
##   RELOAD    — in cover for `reload_time`, then COVER
##   FLANK     — the player has not moved for `flank_after` s: pick a new cover point at an angle (MOVE again)
## Getting hit or shot at nearby (`suppress()`) sends a peeking soldier back to cover and lengthens its next wait.
## `bark` tells the host what to say out loud ("Przeładowuję!", "Obchodzę go!") — the player hears intent.

signal bark(kind: StringName)
signal state_changed(state: Mode)

enum Mode { MOVE, COVER, PEEK, RELOAD, FLANK }

var peek_wait := 1.2         ## s hidden between peeks
var peek_time := 1.6         ## s exposed per peek
var suppressed_extra := 1.5  ## s added to the next wait after being suppressed
var reload_time := 2.2
var magazine := 20
var aim_time := 1.2          ## s of exposure until full accuracy
var accuracy_min := 0.15     ## chance a shot hits at the start of a peek
var accuracy_max := 0.55     ## chance at full aim (before difficulty)
var flank_after := 7.0       ## s of the player staying in one spot before someone flanks
var tokens: AttackTokens      ## optional: at most N soldiers peek and fire at once

var state := Mode.MOVE
var rounds := 20
var cover_target := Vector3.ZERO
var _t := 0.0
var _exposed := 0.0
var _suppressed := 0.0
var _player_still := 0.0
var _needs_target := false     # FLANK chosen: wait for the body to pick the new cover (move_to)


func _init() -> void:
	rounds = magazine


## One tick. `arrived`: the body reached cover_target. `sees_player`: from its peek position. `player_moved`: the
## player's position changed noticeably this tick.
func tick(delta: float, arrived: bool, sees_player: bool, player_moved: bool) -> void:
	_t += delta
	_suppressed = maxf(_suppressed - delta, 0.0)
	_player_still = 0.0 if player_moved else _player_still + delta
	match state:
		Mode.MOVE, Mode.FLANK:
			if arrived and not _needs_target:
				_go(Mode.COVER)
		Mode.COVER:
			if _player_still >= flank_after and sees_player:
				_player_still = 0.0
				bark.emit(&"flanking")
				_go(Mode.FLANK)
			elif _t >= peek_wait + (suppressed_extra if _suppressed > 0.0 else 0.0) and _take_token():
				_exposed = 0.0
				_go(Mode.PEEK)
		Mode.PEEK:
			_exposed += delta
			if _t >= peek_time or not sees_player:
				_leave_peek(Mode.COVER)
		Mode.RELOAD:
			if _t >= reload_time:
				rounds = magazine
				_go(Mode.COVER)


## Chance this shot hits: ramps from accuracy_min to accuracy_max over aim_time of continuous exposure (the first
## shots at a player who just appeared miss on purpose), × the difficulty scale.
func accuracy(difficulty_scale: float = 1.0) -> float:
	return clampf(lerpf(accuracy_min, accuracy_max, clampf(_exposed / aim_time, 0.0, 1.0)) * difficulty_scale, 0.0, 1.0)


## The body fired one round while peeking. Returns false when it may not fire (not peeking, or empty).
func fire_round() -> bool:
	if state != Mode.PEEK or rounds <= 0:
		return false
	rounds -= 1
	if rounds <= 0:
		bark.emit(&"reloading")
		_leave_peek(Mode.RELOAD)
	return true


## Hit, or bullets landing close: back into cover now, and wait longer before the next peek.
func suppress() -> void:
	_suppressed = suppressed_extra
	if state == Mode.PEEK:
		bark.emit(&"suppressed")
		_leave_peek(Mode.COVER)


func is_exposed() -> bool:
	return state == Mode.PEEK or state == Mode.MOVE or state == Mode.FLANK


func is_suppressed() -> bool:
	return _suppressed > 0.0


func move_to(point: Vector3) -> void:
	cover_target = point
	_needs_target = false
	if state != Mode.FLANK:
		_go(Mode.MOVE)


func _leave_peek(next: Mode) -> void:
	if tokens != null:
		tokens.give_back(self)
	_go(next)


func _take_token() -> bool:
	return tokens == null or tokens.take(self)


func _go(s: Mode) -> void:
	state = s
	if s == Mode.FLANK:
		_needs_target = true
	_t = 0.0
	state_changed.emit(s)
