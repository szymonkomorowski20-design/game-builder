class_name AttackTokens
extends RefCounted
## Fairness: at most `limit` melee enemies may be winding up or striking at the same time. Overlapping tells with no
## priority are what make a fight unreadable (genre doc §1), so an enemy takes a token before its telegraph and gives
## it back when its strike is over (or it is staggered or dies). Without a token it keeps chasing and tries again.

var limit := 2
var _holders := {}


func take(who: Object) -> bool:
	var id := who.get_instance_id()
	if _holders.has(id):
		return true
	if _holders.size() >= limit:
		return false
	_holders[id] = true
	return true


func give_back(who: Object) -> void:
	_holders.erase(who.get_instance_id())


func held() -> int:
	return _holders.size()
