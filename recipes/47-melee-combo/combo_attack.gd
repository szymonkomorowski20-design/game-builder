class_name ComboAttack
extends RefCounted
## Melee combo logic with no 2D/3D in it. Each AttackStep runs windup → active → recovery. Pressing attack during
## recovery chains the next step at once; a press up to `buffer_time` before recovery is remembered and chains when
## recovery begins; earlier presses are dropped. A press during the LAST step's recovery restarts the combo when that
## recovery ends (mashing loops it). A dash can cancel recovery, never the committed windup/active.
## Drive it with tick(delta) from _physics_process; the host opens its hitbox while is_hitting().

signal step_started(index: int)
signal hit_window_opened(index: int, hit_id: int)
signal hit_window_closed(index: int)
signal finished

enum Phase { IDLE, WINDUP, ACTIVE, RECOVERY }

const EPS := 1e-4   # float time accumulated from 1/60 steps lands a hair short of 0.1 etc.

var steps: Array[AttackStep] = []
var buffer_time := 0.15

var phase := Phase.IDLE
var step_index := -1
var hit_id := 0                 ## grows with every active window: hit each target once per id

var _t := 0.0                   # time spent in the current phase
var _press_age := -1.0          # seconds since a pending press; < 0 = none
var _restart_queued := false    # pressed during the last step's recovery


func press() -> void:
	match phase:
		Phase.IDLE:
			_start(0)
		Phase.RECOVERY:
			if step_index < steps.size() - 1:
				_start(step_index + 1)
			else:
				_restart_queued = true
		_:
			_press_age = 0.0     # windup/active: remember it; chains only if still fresh when recovery begins


func try_dash_cancel() -> bool:
	if phase != Phase.RECOVERY:
		return false
	_to_idle()
	return true


func is_hitting() -> bool:
	return phase == Phase.ACTIVE


func current_step() -> AttackStep:
	return steps[step_index] if step_index >= 0 else null


func tick(delta: float) -> void:
	if phase == Phase.IDLE:
		return
	_t += delta
	if _press_age >= 0.0:
		_press_age += delta
	# A long delta may cross several phase boundaries; the leftover time carries into the next phase.
	while phase != Phase.IDLE:
		var s := steps[step_index]
		var length: float = s.windup if phase == Phase.WINDUP else (s.active if phase == Phase.ACTIVE else s.recovery)
		if _t + EPS < length:
			return
		_t = maxf(_t - length, 0.0)
		match phase:
			Phase.WINDUP:
				phase = Phase.ACTIVE
				hit_id += 1
				hit_window_opened.emit(step_index, hit_id)
			Phase.ACTIVE:
				phase = Phase.RECOVERY
				hit_window_closed.emit(step_index)
				var fresh := _press_age >= 0.0 and _press_age <= buffer_time + EPS
				_press_age = -1.0
				if fresh:
					if step_index < steps.size() - 1:
						_start(step_index + 1)
					else:
						_restart_queued = true
			Phase.RECOVERY:
				if _restart_queued:
					_start(0)
				else:
					_to_idle()
					finished.emit()


func _start(index: int) -> void:
	step_index = index
	phase = Phase.WINDUP
	_t = 0.0
	_press_age = -1.0
	_restart_queued = false
	step_started.emit(index)


func _to_idle() -> void:
	phase = Phase.IDLE
	step_index = -1
	_t = 0.0
	_press_age = -1.0
	_restart_queued = false
