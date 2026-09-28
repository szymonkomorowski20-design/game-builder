class_name JumpMath
extends RefCounted
## Jump physics from designer-friendly numbers: a jump is described by its HEIGHT and the TIME to
## reach the apex; gravity and launch speed follow (constant-acceleration kinematics).
##   g = 2h / t²      v = 2h / t      apex = v² / 2g  (= h)


static func gravity(height: float, time_to_apex: float) -> float:
	return 2.0 * height / (time_to_apex * time_to_apex)


static func jump_velocity(height: float, time_to_apex: float) -> float:
	return 2.0 * height / time_to_apex


static func apex_height(launch_velocity: float, g: float) -> float:
	return launch_velocity * launch_velocity / (2.0 * g)
