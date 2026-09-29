class_name EnemyStrike
extends RefCounted
## One enemy attack as a timeline (recipe 71, genre doc §11): a tell (the pose), a flash `flash_lead` before the hit,
## the hit(s), then recovery.
## - NORMAL: counter it, block it or dodge it;
## - UNBLOCKABLE (the red flash): dodge it; a block or a counter only breaks the guard;
## - COMBO (the blue flash): several hits; block, parry or dodge each.
## The first hit comes later than a human can react (about 0.3 s; `windup` 0.7 s here), the combo's next hits faster,
## because the player anticipates them (Ghost of Tsushima).

enum Kind { NORMAL, UNBLOCKABLE, COMBO }

var kind := Kind.NORMAL
var windup := 0.7
var flash_lead := 0.35
var recover := 0.8
var hits := 1
var combo_gap := 0.35


static func make(p_kind: int, p_hits: int = 1) -> EnemyStrike:
	var s := EnemyStrike.new()
	s.kind = p_kind
	s.hits = maxi(p_hits, 1)
	return s


## When each hit lands, for a strike started at `start`.
func hit_times(start: float) -> Array[float]:
	var out: Array[float] = []
	for i in hits:
		out.append(start + windup + combo_gap * i)
	return out


func flash_time(start: float) -> float:
	return start + windup - flash_lead


func duration() -> float:
	return windup + combo_gap * (hits - 1) + recover
