class_name AimAssist
extends RefCounted
## Gamepad aim assist (recipe 56), as plain math the camera code applies:
##   slowdown — while the crosshair is near a target, look sensitivity drops (friction), so small corrections land;
##   pull     — while the player is moving the stick, the aim is turned a little toward the nearest target
##              (rotational assist). Never while the stick is idle: the gun must not aim itself.
## Targets are aim points the host already knows are visible (line of sight is its job). Mouse and keyboard get none.

var cone := 6.0            ## degrees around the crosshair where assist acts
var min_scale := 0.45      ## sensitivity at the centre of a target (1 = no slowdown)
var pull_speed := 10.0     ## degrees per second of turning toward the target, at full stick
var max_range := 60.0      ## m


static func angle_to(eye: Vector3, aim_dir: Vector3, point: Vector3) -> float:
	var to := point - eye
	if to.length() < 1e-4:
		return 0.0
	return rad_to_deg(aim_dir.normalized().angle_to(to.normalized()))


## The closest target inside the cone and range, or null.
func best_target(eye: Vector3, aim_dir: Vector3, targets: Array[Vector3]) -> Variant:
	var best: Variant = null
	var best_angle := cone
	for t in targets:
		if eye.distance_to(t) > max_range:
			continue
		var a := angle_to(eye, aim_dir, t)
		if a <= best_angle:
			best_angle = a
			best = t
	return best


## Sensitivity multiplier: min_scale on the target, rising linearly to 1 at the edge of the cone.
func slowdown(eye: Vector3, aim_dir: Vector3, targets: Array[Vector3]) -> float:
	var t: Variant = best_target(eye, aim_dir, targets)
	if t == null:
		return 1.0
	return lerpf(min_scale, 1.0, angle_to(eye, aim_dir, t) / cone)


## Degrees (x = yaw right, y = pitch up) to turn the aim this frame toward the target, only while the stick moves.
func pull(eye: Vector3, aim_dir: Vector3, view: Basis, targets: Array[Vector3], stick: Vector2, delta: float) -> Vector2:
	if stick.length() < 0.2:
		return Vector2.ZERO
	var t: Variant = best_target(eye, aim_dir, targets)
	if t == null:
		return Vector2.ZERO
	var to := ((t as Vector3) - eye).normalized()
	var yaw := rad_to_deg(atan2(to.dot(view.x.normalized()), to.dot(-view.z.normalized())))
	var pitch := rad_to_deg(asin(clampf(to.dot(view.y.normalized()), -1.0, 1.0)))
	var want := Vector2(yaw, pitch)
	var step := pull_speed * minf(stick.length(), 1.0) * delta
	return want.limit_length(step)
