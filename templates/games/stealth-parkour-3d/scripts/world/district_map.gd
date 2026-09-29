class_name DistrictMap
extends RefCounted
## The district, as data (x to the east, z to the south; −Z is north). A 70 m square with two streets crossing at the
## centre: a block of four houses with 2 m alleys to leap (north-west), the target's palazzo and its courtyard
## (north-east), the viewpoint tower over a hay pile (south-west), the market square with the crowd (south-east).
## Houses carry lips (holds) on the faces toward the streets, every 1.2 m from 2.2 m; everything climbable shares one
## lighter colour (genre doc §12). `build()` makes the blocks under a node (a NavigationRegion3D, so they are baked).

const HALF := 35.0
const STONE := Color(0.6, 0.55, 0.48)
const DARK_STONE := Color(0.45, 0.42, 0.4)
const HOLD := Color(0.88, 0.82, 0.68)
const HAY := Color(0.86, 0.72, 0.3)
const WOOD := Color(0.5, 0.36, 0.24)
const GROUND := Color(0.36, 0.37, 0.33)
const SQUARE := Color(0.42, 0.4, 0.36)

## Houses: [x0, x1, z0, z1, height, faces with lips ("n", "s", "e", "w"), lips from (m, optional)].
const HOUSES := [
	[-22.0, -12.0, -22.0, -12.0, 6.0, "es"],
	[-10.0, -5.0, -22.0, -12.0, 6.0, "es"],
	[-22.0, -12.0, -10.0, -5.0, 6.0, "es"],
	[-10.0, -5.0, -10.0, -5.0, 6.0, "es"],
	[5.0, 10.0, -22.0, -12.0, 6.0, "ws"],
	[-26.0, -18.0, 18.0, 28.0, 6.0, "ne"],
	[26.0, 33.0, 5.0, 20.0, 6.0, "w"],
]
const PALAZZO := [10.0, 24.0, -22.0, -12.0, 9.0]
const TOWER := [-16.0, -12.0, 10.0, 14.0, 15.0]
## Hay: [centre, size]. The tower's is wide: a leap from its top lands in it with or without a run-up.
const HAYS := [[Vector3(-8.3, 0.5, 12), Vector3(7, 1, 6)], [Vector3(8, 0.5, 24), Vector3(4, 1, 4)],
		[Vector3(-2.5, 0.5, -24), Vector3(3, 1, 4)]]
const STALLS := [Vector3(12, 0.6, 12), Vector3(18, 0.6, 12), Vector3(12, 0.6, 18)]
const WELL := Vector3(20, 0.5, 20)
const BENCH := Vector3(10.5, 0.25, 21)
const POSTERS := {&"poster_1": Vector3(-17.94, 1.4, 23.0), &"poster_2": Vector3(25.94, 1.4, 6.0)}

const PLAYER_START := Vector3(0, 0.05, 31)
const VIEWPOINT := Vector3(-14, 15, 12)
const VIEWPOINT_RADIUS := 40.0
const DOOR := Vector3(17, 0, -11.2)
const TARGET_STOPS := [[Vector3(17, 0, -8), 12.0], [Vector3(15, 0, 9.5), 14.0], [Vector3(-8, 0, 8), 10.0]]

## Guards: name, post, facing (the direction it looks), patrol route (empty: stands at the post).
const GUARDS := [
	[&"patrol_ns", Vector3(0, 0, -26), Vector3(0, 0, 1), [Vector3(0, 0, -26), Vector3(0, 0, 26)]],
	[&"patrol_ew", Vector3(-26, 0, 0), Vector3(1, 0, 0), [Vector3(-26, 0, 0), Vector3(26, 0, 0)]],
	[&"door", Vector3(15.5, 0, -10.5), Vector3(0, 0, 1), []],
	[&"roof", Vector3(17, 9, -17), Vector3(0, 0, 1), []],
	[&"market", Vector3(9, 0, 9), Vector3(1, 0, 1), []],
]

## The crowd's lanes: a loop around the market, two cross lanes, and one along the east-west street.
const LANES := [
	[Vector3(6, 0, 6), Vector3(24, 0, 6), Vector3(24, 0, 24), Vector3(6, 0, 24), Vector3(6, 0, 6)],
	[Vector3(15, 0, 6), Vector3(15, 0, 15), Vector3(15, 0, 24)],
	[Vector3(6, 0, 15), Vector3(15, 0, 15), Vector3(24, 0, 15)],
	[Vector3(6, 0, 6), Vector3(6, 0, 1.5), Vector3(-20, 0, 1.5)],
]
const CROWD := 12

## Where searches look: alley mouths, corners, the backs of stalls.
const SEARCH_POINTS := [
	Vector3(-11, 0, -3), Vector3(-4.5, 0, -11), Vector3(4.5, 0, -11), Vector3(9, 0, -4.5), Vector3(-4.5, 0, 6),
	Vector3(-9, 0, 16), Vector3(4.5, 0, 12), Vector3(13, 0, 13.5), Vector3(19, 0, 13.5), Vector3(24.5, 0, 22),
	Vector3(-20, 0, -3), Vector3(20, 0, -3), Vector3(0, 0, -14), Vector3(0, 0, 14), Vector3(-2, 0, 22),
]


## Builds the static district under `parent`. Returns {soft (hay bodies), bench, posters (name -> node)}.
static func build(parent: Node3D) -> Dictionary:
	parent.add_child(GreyboxBlock.make(Vector3(0, -0.5, 0), Vector3(HALF * 2, 1, HALF * 2), GROUND))
	parent.add_child(GreyboxBlock.make(Vector3(15, 0.01, 15), Vector3(22, 0.02, 22), SQUARE))
	for side: Array in [[Vector3(0, 2, -HALF), Vector3(HALF * 2, 4, 1)], [Vector3(0, 2, HALF), Vector3(HALF * 2, 4, 1)],
			[Vector3(-HALF, 2, 0), Vector3(1, 4, HALF * 2)], [Vector3(HALF, 2, 0), Vector3(1, 4, HALF * 2)]]:
		parent.add_child(GreyboxBlock.make(side[0], side[1], DARK_STONE))
	for h: Array in HOUSES:
		_house(parent, h[0], h[1], h[2], h[3], h[4], h[5], 2.2)
	_house(parent, PALAZZO[0], PALAZZO[1], PALAZZO[2], PALAZZO[3], PALAZZO[4], "s", 2.2)
	_lips(parent, "w", PALAZZO[0], PALAZZO[1], PALAZZO[2], PALAZZO[3], PALAZZO[4], 7.0)
	parent.add_child(GreyboxBlock.make(DOOR + Vector3(0, 1.25, -0.75), Vector3(2, 2.5, 0.2), WOOD))
	_house(parent, TOWER[0], TOWER[1], TOWER[2], TOWER[3], TOWER[4], "nsew", 2.2)
	var soft: Array[Node3D] = []
	for h: Array in HAYS:
		var groups: Array[StringName] = [&"soft_landing", &"hiding_spot"]
		var hay := GreyboxBlock.make(h[0], h[1], HAY, 1, groups)
		parent.add_child(hay)
		soft.append(hay)
	for p: Vector3 in STALLS:
		parent.add_child(GreyboxBlock.make(p, Vector3(2, 1.2, 1), WOOD))
	parent.add_child(GreyboxBlock.make(WELL, Vector3(1.6, 1.0, 1.6), DARK_STONE))
	var bench := GreyboxBlock.make(BENCH, Vector3(2.4, 0.5, 0.6), WOOD)
	parent.add_child(bench)
	var posters := {}
	for name: StringName in POSTERS:
		var poster := GreyboxBlock.make(POSTERS[name], Vector3(0.1, 1.0, 0.7), Color(0.85, 0.2, 0.15))
		poster.name = String(name)
		parent.add_child(poster)
		posters[name] = poster
	return {soft = soft, bench = bench, posters = posters}


## The bench's three seats: civilians take the outer two, the middle one hides the player.
static func bench_seats() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for dx: float in [-0.8, 0.8, 0.0]:
		out.append(BENCH + Vector3(dx, 0.25, 0))
	return out


static func lanes() -> CrowdLanes:
	var paths: Array[PackedVector3Array] = []
	for l: Array in LANES:
		paths.append(PackedVector3Array(l))
	return CrowdLanes.from_paths(paths)


static func search_points() -> Array[Vector3]:
	var out: Array[Vector3] = []
	for p: Vector3 in SEARCH_POINTS:
		out.append(p)
	return out


static func routine() -> TargetRoutine:
	var r := TargetRoutine.new()
	for s: Array in TARGET_STOPS:
		r.add_stop(s[0], s[1])
	return r


static func _house(parent: Node3D, x0: float, x1: float, z0: float, z1: float, h: float, faces: String,
		lips_from: float) -> void:
	parent.add_child(GreyboxBlock.make(Vector3((x0 + x1) * 0.5, h * 0.5, (z0 + z1) * 0.5), Vector3(x1 - x0, h, z1 - z0),
			STONE))
	for f in faces:
		_lips(parent, f, x0, x1, z0, z1, h, lips_from)


## Lips on one face, 0.15 m thick and 0.12 m out, every 1.2 m from `from` up to 0.8 m under the top.
static func _lips(parent: Node3D, face: String, x0: float, x1: float, z0: float, z1: float, h: float,
		from: float) -> void:
	var top := from
	while top <= h - 0.8 + 1e-4:
		var y := top - 0.075
		match face:
			"n":
				parent.add_child(GreyboxBlock.make(Vector3((x0 + x1) * 0.5, y, z0 - 0.06), Vector3(x1 - x0, 0.15, 0.12), HOLD))
			"s":
				parent.add_child(GreyboxBlock.make(Vector3((x0 + x1) * 0.5, y, z1 + 0.06), Vector3(x1 - x0, 0.15, 0.12), HOLD))
			"w":
				parent.add_child(GreyboxBlock.make(Vector3(x0 - 0.06, y, (z0 + z1) * 0.5), Vector3(0.12, 0.15, z1 - z0), HOLD))
			"e":
				parent.add_child(GreyboxBlock.make(Vector3(x1 + 0.06, y, (z0 + z1) * 0.5), Vector3(0.12, 0.15, z1 - z0), HOLD))
		top += 1.2
