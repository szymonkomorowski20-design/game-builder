# Template — stealth and parkour in a city district (Assassin's Creed-like, original)
Status: implemented. Evidence: game-builder template tests green under `gb verify` at scaffold time.
- **Tests:** 8 unit contracts plus the recipes' own tests (61 GUT tests in a scaffolded game); scenarios S1–S11 plus
  the recipes' scenarios (16), stable over `--repeat 3` (every run the same: the bot hides at 15.8 s, the tower's
  climb takes 7.7 s and 13 moves).
- **Performance:** `tests/fixtures/perf_alarm.tscn` (every guard hunting the player in the square, the crowd
  panicking, vsync off) under `gb perf --seconds 120`:
  - frame p95 4.2 ms, process p95 5.5 ms;
  - physics (the worst frame of each second) p95 0.65 ms, at most 8.9;
  - 458 nodes, 369 draw calls;
  - the five guards' scripts cost about 0.14 ms a frame.

  Budget: `.ai/perf-budget.json`.
- **Recipes that land:** 40 (the orbit camera) and 66–73.
- **Detection proven** (20 deliberate breaks, each run against its check; 20 caught):
  - hiding that does nothing → S1; hiding not blending the player for the guards → S1;
  - falls that cost nothing → the fall contract;
  - a target that ignores its routine → S9; no assassination → S9; a contract that never completes → S9;
  - being hunted not alerting the target → S4;
  - counters that don't hurt guards → S7; guards' strikes that never land → S7;
  - the crowd never hiding the player → S6;
  - noise never reaching the guards → S5;
  - a last seen place off the navigation mesh never reached → S8; hiding not counting for the chase → S8;
  - guards that ignore bodies → S10;
  - witnesses that never report → S11; posters that do nothing → S11; notoriety not speeding up noticing → S11;
  - a sync that reveals nothing → S3; hay that isn't soft → S3; a tower without holds → S3.
- **Screenshots looked at:**
  - the start (the HUD's goal, the market's crowd, the houses' lighter holds);
  - the view from the tower after the sync (the palazzo, its door guard, the target in gold, the sync message);
  - a guard with a red "!" hunting the player, with the chase and the target's flight on the HUD;
  - the target's body by the hay after the strike, with "escape" on the HUD.
- **Found while building (by the bot):**
  - Godot stops a `CharacterBody3D` that pushes within 15° of a wall's normal instead of sliding along it
    (`wall_min_slide_angle`, in grounded 3D motion too). The bot stuck at a hay pile's corner; it now rounds corners;
  - hiding needed a reach: the hay is solid, so the player stands next to it. The action works within 1 m of the pile;
  - a poster 39.99 m from the viewpoint was revealed by its 40 m sync; the poster moved;
  - the guards' path points lie 0.5 m above the ground, so a 0.5 m reach was never met, and a guard stood still in the
    street. The agent now has a `path_height_offset` of 0.5;
  - a guard recorded the player's position after a teleport as seen, because the senses' flag is up to 0.1 s old. The
    brain now gets the position of the senses' last look (recipe 68's `meter.last_seen`);
  - a player seen on a stall left a last seen place off the navigation mesh, which the guard never reached, and it
    never searched. A guard now "arrives" when its path ends as close as the mesh allows;
  - a counter ended a guard's strike inside the loop over its hits, and the loop read the cleared strike (a script
    error);
  - a knee-high lip under a real hold stopped the grab from a roof (fixed in recipe 67);
  - a 60 s performance run measured the scene's start (process p95 89 ms); 120 s measure the play (5.5 ms).

  All were fixed, and they are now tests.

Ladder rung: first playable (one district, one contract from the briefing to done or failed).

## Goal
A tested starting point for an original third-person stealth and parkour game in the style of the genre (see
`gb doc genre-stealth-parkour`):
- a district to climb: lipped facades, roofs with alleys to leap, a viewpoint tower over a hay pile;
- guards who see, hear, check, hunt, call for support, search and give up, and find bodies;
- a crowd to blend into, with a bench and hay to hide in;
- a counter-based fight when found;
- notoriety that witnesses raise and posters lower, and a chase that ends when the player escapes;
- a viewpoint that reveals the district, and one assassination contract (a target with a routine, the strike, the
  escape), where detection changes the contract instead of failing it.

The art is placeholder (primitives): the player in white with a red sash, guards in red with helmets and spears, the
target in gold with a purple hat, townspeople in muted colours; holds and hay share lighter colours.

## Design (built on recipes 40 and 66–73 — added by scaffold with their tests)
- **Game** (`scenes/district/district.tscn`, `scripts/core/stealth_game.gd`, main scene):
  - builds the district (`DistrictMap`) under the navigation region and bakes the mesh on load (synchronously, so a
    scenario plays the same every run);
  - spawns the guards, the crowd and the target;
  - owns the shared systems: the guards' `AlertBoard` (69), `Notoriety` and `WantedSearch` (72), `ViewpointNetwork`
    and the `Contract` (73), the `MeleeStage` (71), the crowd's `CrowdLanes` and the bench's `SmartSlots` (70);
  - each physics frame: the crowd by distance bands (70), the target, the player's blending, notoriety, the action key,
    the chase and the contract;
  - **the action key:** synchronise at the tower's top; tear a wanted poster within 2 m; hide in hay within 1 m of a
    pile, or on the bench's middle seat when the two outer ones are taken; press it again, or move, to come out;
  - **the strike:** a victim within 1.6 m in front (height within 1.2 m, so from a hay pile too) dies at once when it
    is the target or a guard that isn't hunting (an assassination); otherwise it hits the fighter the stick points at
    (71's target picking);
  - **after a kill:** any guard that sees the player at that moment within 25 m makes it a guard-witnessed act and
    starts hunting; the first townsperson within 14 m makes a report (6 s); the crowd within 10 m panics, within 18 m
    is scared;
  - **the contract:** a hunting guard seeing the player alerts the target (it runs for the palazzo's door; there it is
    safe, and the contract fails); the target's death starts the escape; 20 m from the body with nobody chasing, the
    contract is done; the player's death fails it;
  - notoriety's `notice` multiplier goes to every guard's senses (`notice_scale`).
  - Observable: `contract`, `notoriety`, `wanted`, `viewpoints`, `board`, `guards`, `civilians`, `target`, `clock`,
    `actions`, `noises`; for tests: `crowd_frozen`.
- **District** (`scripts/world/district_map.gd`, data plus a builder):
  - 70 × 70 m inside a wall; a north–south and an east–west street (8 m) crossing at the centre;
  - north-west: four 6 m houses with 2 m alleys (sprint leaps);
  - north-east: the target's 9 m palazzo, its door and courtyard, and a 6 m house against it (its roof leads up the
    palazzo's lips);
  - south-west: the 15 m viewpoint tower (holds on all four faces) over a 7 × 6 m hay pile;
  - south-east: the market square with stalls, a well, a three-seat bench and 14 townspeople (two seated);
  - houses have lips (0.15 m, 0.12 m out) on the faces toward the streets, every 1.2 m from 2.2 m;
  - three hay piles (soft landings and hiding places), two wanted posters;
  - five guards: two patrols, the palazzo's door (heavy), the palazzo's roof, the market;
  - the target's routine: the courtyard (12 s), the market (14 s), a quiet corner by the tower's hay (10 s), a loop of
    about 90 s;
  - 15 search points (alley mouths, corners, the backs of stalls).
- **Player** (`scenes/player/player.tscn`, `scripts/player/assassin.gd`, extends recipe 66's `StealthMover` with 67's
  `Climber` as a child):
  - health in hits (5), falls routed through the `FallRule` (a hurting fall costs its share of full health);
  - hiding in hay (the body hidden) or on the bench;
  - the defence of 71: a tap of `counter` counters, holding it blocks, `drop` dodges (the genre's "parkour down" and
    dodge share a button);
  - its cues say blended when hidden or with the crowd.
- **Guards** (`scenes/npc/guard.tscn`, `scripts/npc/guard_agent.gd`):
  - 68's `GuardSenses` at eye height (the guard turns its whole body), 69's `GuardBrain` on the shared board;
  - walking on the navigation mesh (a patrol ping-pongs its route; a post faces its direction), running when hunting;
  - the brain gets the position of the senses' last look, and "arrives" at a goal off the mesh when the path is done
    as close as it gets;
  - they hear the player's noise along the navigation mesh (68's `Hearing`), and see bodies within 14 m in their zones;
  - fighting: engaged within 3.5 m, a strike (71's `EnemyStrike`) when the stage allows; the door guard is heavy (8 on
    the stage, one more hit, every second strike unblockable); countered, a guard loses a hit and staggers;
  - three hits kill a guard (a strike or a counter each, a perfect counter two); dead, it leaves a body;
  - over the head: a meter while it notices, "?" while suspicious or checking, "!" while hunting.
- **Crowd** (`scripts/npc/civilian.gd`): 70's lanes (seeded per townsperson), `CrowdMind`, steering by speed; two sit
  on the bench and get up when frightened.
- **Target** (`scripts/npc/target_npc.gd`): 73's `TargetRoutine` by the game's clock; alerted, it runs for the door.
- **HUD** (`scripts/ui/hud.gd`, Polish): the contract's goal, health, notoriety pips, the chase (seen / searched for,
  and how far out of the circle / escaped / hidden / in the crowd), messages.
- **Camera:** recipe 40's orbit camera (mouse or right stick), a 5 m spring arm.

## Tuning table
| What | Value | Where |
|---|---|---|
| Speeds sneak / walk / run / sprint | 1.6 / 2.2 / 4.2 / 6.5 m/s | recipe 66 (`MoveProfiles`) |
| Noise sneak / walk / run / sprint | 0 / 2 / 5 / 9 m | recipe 66 |
| Jump | 1.2 m, 0.38 s to the apex (a sprint clears about 4 m) | `StealthMover` |
| Falls | safe 4.5 m, deadly 14 m, hay up to 40 m | `FallRule` |
| Climbing | 2.2 m/s; grab up to 2.3 m; next hold 1.6 m | `Climber` |
| Noticing | near 0.4 s; main 1–4 s over 2.5–20 m; peripheral 4 s | `VisionCone` |
| Guards | turn 1 s, look around 2 s, memory 2.5 s, call 1.5 s, search 30 s, caution 60 s | `GuardBrain` |
| Board | 3 searchers, alarm radius 30 m | `stealth_game.gd` |
| Guards' health | 3 hits (door 4); the player 5 | `guard_agent.gd`, `assassin.gd` |
| Strikes | windup 0.7 s, flash 0.35 s before, recovery 0.8 s | `EnemyStrike` |
| Counter | window 0.35 s, perfect 0.1 s, dodge 0.4 s | `CounterDefense` |
| Notoriety | levels at 25 / 55 / 85; a kill 30; report 6 s; poster −25 | `Notoriety` |
| Chase | lost after 0.5 s; circle 15–40 m; out 4 s or hidden 3 s | `WantedSearch` |
| Kill reach | 1.6 m in front, height within 1.2 m | `stealth_game.gd` |
| Witnesses | guards 25 m, townspeople 14 m; panic 10 m, fright 18 m | `stealth_game.gd` |
| Escape | 20 m from the body, nobody chasing | `stealth_game.gd` |
| Viewpoint | radius 40 m | `DistrictMap` |
| Target | 1.3 m/s; waits 12 / 14 / 10 s; runs 4 m/s | `DistrictMap`, `target_npc.gd` |

## Contracts (tests)
`tests/unit/test_district.gd`:
- every house's holds are within the climber's reach, the first a standing grab;
- roofs of one height are leapable (≤ 2.5 m apart) or clearly not (≥ 6 m);
- posts, patrols, search points, the target's stops and the start lie outside the buildings;
- the target's loop is under 2 minutes with at least 8 s at each stop;
- the viewpoint's radius reaches the target's house;
- the tower's hay catches a leap from a standstill and a running one;
- falls cost health (none, a share, death);
- hits to kill.

## Behaviours (test IDs)
- **S1:** a sprint up the street; hiding in hay (the guards' cues blended), coming out by moving; sneaking silent,
  sprinting heard.
- **S2:** a house climbed onto its roof; sprint leaps over three alleys; at the edge over the street the drop intent
  hangs, holding down climbs down, a drop lands unhurt.
- **S3:** the tower climbed; the sync reveals the target's house and one poster (not the far one), and makes a
  fast-travel point; a leap into the hay, unhurt.
- **S4:** noticed after 1 / rate seconds in a guard's main zone; the guard hunts; the chase; the target flees.
- **S5:** a sprint behind a guard is heard; stare, check, look around, back to the post.
- **S6:** between two calm townspeople the guard doesn't notice; alone, 3 m away, it does.
- **S7:** an unanswered strike lands; three counters kill the guard; no more damage.
- **S8:** seen on a stall; hidden far away the chase is lost and escaped; the guard searches (reaching the off-mesh
  place), gives up, and goes back with caution.
- **S9:** the bot completes the contract unseen: tower, sync, leap, hide, wait for the quiet stop and far patrols,
  strike, walk away.
- **S10:** a patrol sees a body in the street, checks, raises the alarm, searches.
- **S11:** a kill in front of the crowd: panic, a report raises notoriety after its delay, the guards notice faster; a
  torn poster brings it back.

## Next steps when a game starts from this
- Art: the Mesh2Motion CC0 humans and their clips (including climbing, ledge hangs, sneaking and sword fights) on one
  shared skeleton; props from the library (see `gb doc starter-packs`). Keep holds in one readable colour.
- Contracts: several targets, each with its own routine, and different lead-ins (eavesdrop, steal a key, tail),
  because the same procedure nine times drew complaints (genre doc §9).
- The genre doc's answers to a player on the roofs: guards on the roofs at notoriety 2, a hunter at 3.
- Guard variety: a heavy to dodge, an agile one that survives a counter; at most one or two special types in a fight.
- A minimap or compass with the search circle (recipe 45); guidance by light and sound rather than icons.
- Menus, settings, saves (recipes 13, 17), a pause (15); sound: steps by profile, climbing, alarms, the crowd.
- Difficulty through the cone times and blind spots, never through inflated health (genre doc §11).
