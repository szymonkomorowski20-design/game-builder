# Template — real-time strategy skirmish (Warcraft / StarCraft-like, original)
Status: implemented. Evidence: game-builder template tests green under `gb verify` at scaffold time.
- **Tests:** 7 unit contracts plus the recipes' own tests (68 GUT tests in a scaffolded game); scenarios R1–R9 plus
  the camera recipe's scenario and smoke (11), stable over `--repeat 2` (R5 and R6 over `--repeat 3` and more).
- **Performance:** `tests/fixtures/perf_battle.tscn` (40 against 40 plus workers, fog on, everything in view, vsync
  off) under `gb perf --seconds 120`: frame p95 1.5 ms, process p95 2.5 ms, physics (the worst frame of each second)
  p95 8.9 ms, 727 nodes, 846 draw calls. The physics budget is 10 ms (see `.ai/perf-budget.json`).
- **Recipes that land:** 58–65.
- **Detection proven** (15 deliberate breaks, each run against its check; 13 caught):
  - units that never pick a target → R5;
  - hits that do no damage → R5;
  - buildings that cannot die → R5;
  - arrows weak against heavy armour (pierce × 1.2) → the counter contract;
  - the rider's bonus against ranged units at 0 → the bonus contract;
  - the fog showing every enemy → R7;
  - building in unexplored ground → R7;
  - no tech check when placing a building → R3;
  - a new building not carved from the navigation mesh → R3;
  - the computer never attacking → R8;
  - the selection box taking enemy units → R1;
  - workers walking to a mine's centre instead of its near side → R2;
  - a group order sending everyone to one point → R6.

  Two breaks were **not** caught, and need no test:
  - skipping the tech check when training: only a finished building of the right kind trains, and in this tree that
    building is the unit's only requirement, so the check cannot fail;
  - switching off the units' avoidance: R6's formation slots already keep them apart; avoidance only smooths
    crossings.
- **Screenshots looked at:** the build ghost (green on free ground), a group standing in formation at its goal with
  selection rings and health bars, a scout at the enemy's town hall with the fog clear around it, dim where explored
  and dark beyond; the minimap with fog, dots and the camera frame.
- **Found while building (by the bot):**
  - the fog overlay and the HUD read the game before it had set itself up (children are ready before their parent);
  - new buildings were not cut out of the navigation mesh (a NavigationRegion3D parses only its own children);
  - reach was measured to a building's centre, so a worker at a corner never arrived; units standing where a
    building went up were walled in by it;
  - the mines ran dry by six minutes;
  - buildings were nearly invulnerable, and idle units ignored them;
  - workers walked to the far side of a mine; they queued at one tree instead of moving on;
  - a lambda or a typed variable holding a unit that had died stopped the script;
  - archers lost to footmen at equal cost, and the rider's bonus never applied (bonuses match tags, and "light" was an
    armour type), so archers now hit harder against heavy armour and riders run down anything tagged "ranged";
  - the computer's waves outgrew its maximum army, it built farms at the supply ceiling, its waves stood idle once a
    fight was over, and it built a second barracks too early;
  - in a big battle, every unit without a target scanned every frame (n² a frame), and the fog cost 3 ms an update;
  - a unit jammed at a rock's corner for 4 s gave up there, 15 m from its place in the formation.

  All were fixed, and they are now tests.

Ladder rung: first playable (one skirmish, start to a winner, against a computer opponent at three difficulties).

## Goal
A tested starting point for an original real-time strategy game in the style of the genre (see `gb doc genre-rts`):
- an economy of workers, two resources and supply;
- a base built on a grid that says why it refuses;
- three combat units in a counter triangle;
- the genre's controls (selection, smart right-click, attack-move, queues, control groups, formations, the RTS
  camera, a minimap);
- the fog of war;
- a computer opponent that plays by the same rules, and a bot that can beat it.

The art is placeholder (primitives: units told apart by silhouette and size, team colour on the body).

## Design (built on recipes 58–65 — added by scaffold with their tests)
- **Game** (`scenes/skirmish/skirmish.tscn`, `scripts/core/rts_game.gd`, main scene):
  - owns what the teams share: the placement grid (60), the combat rules (63), the navigation mesh (rebuilt when
    buildings change), a stockpile, a tech tree and a fog per team;
  - spawns units and buildings (buildings under the navigation region, so their footprint is cut out; units standing
    where one goes up step out of its way), trains, builds, and says to the player why an order was refused (Polish);
  - the fog updates `fog_rate` times a second, one team at a time; the player sees enemy units only in sight, enemy
    buildings once seen, and mines, trees and rocks once explored;
  - a building's reach is to its walls (`closest_point`), and workers walk to the near side of a mine;
  - a team with no buildings left loses; the end screen shows who won and the time;
  - **fog honesty:** every team remembers the enemy buildings it has seen (`seen_by`, which the computer uses too); a
    hit shows the attacker to the victim's team for `reveal_on_hit` s (an archer stops at its reach, at or past a
    footman's sight); a team with buildings but no finished town hall for 60 s has them shown to the enemy
    (`reveal_hall_less`, Warcraft III's rule — a last farm nobody saw made a bot game endless);
  - **determinism for tests:** while the harness runs the navigation mesh is baked on the same frame, and a removed
    building is baked out two physics frames later (it leaves the tree at the end of its frame); the project keeps the
    navigation server's async iterations and threaded avoidance off, except threaded avoidance in exported builds
    (`template.json` "settings": a `.template` feature override) — single-threaded it can strain a big battle's physics
    budget on a loaded machine, threaded it makes bot games differ run to run;
  - exports: `ai_enabled`, `ai_level` (0 easy · 1 normal · 2 hard), `reveal_map`, `bot_team` (tests),
    `reveal_on_hit`, `reveal_hall_less`.
  - Observable: `winner`, `elapsed`, `units`, `buildings`, `mines`, `stockpile(t)`, `fog(t)`, `count(t, kind)`.
- **Rules** (`scripts/core/rts_rules.gd`, `data/rules.tres`): every number of the skirmish in one place — units and
  buildings as data (cost, supply, time, hit points, armour and its type, tags, attack with bonuses, range, cooldown,
  speed, sight), the type table, the start bank, resources. The tech tree comes from what buildings need and train.
- **Map** (`scripts/world/rts_map.gd`, built in code): 72 × 72 m, two mirrored bases in opposite corners, each with
  two gold mines (5000 gold, 2 workers at a time) and a tree line (450 wood a tree, 2 at a time); rocks in the middle
  split the way into lanes.
- **Units** (`scripts/units/rts_unit.gd`): worker, footman, archer, rider. They carry out their order queue (58):
  MOVE, ATTACK, ATTACK_MOVE, HOLD, STOP, GATHER (59), BUILD, PATROL.
  - They look for targets every 0.25 s (staggered; at once when their target dies): whoever attacks them first, units
    before buildings, only what their team sees (63). Idle, they chase within a leash and come back.
  - A unit with no unit to fight — idle, on attack-move or on patrol, or hitting a building — answers a seen attacker
    that hit it in the last 5 s, even beyond its acquire range (an explicit attack order is kept). Patrols fight what
    they meet.
  - The navigation agent's avoidance keeps them apart; gatherers switch it off on their loop. A unit making no
    progress steps aside, then asks for a fresh path; it stops short only when close to its goal among others who
    arrived, or after three fresh paths.
  - Archers shoot a visible arrow.
- **Buildings** (`scripts/buildings/rts_building.gd`): town hall, farm, barracks, stable. A site until workers finish
  it (hit points grow with the work), then supply, tech and training (60), with a rally point. Destroyed: its cells
  free, its supply and tech go, the navigation mesh is rebuilt.
- **Computer player** (`scripts/ai/rts_ai_player.gd`, recipe 64's brain): workers gathering (about 60% gold, 40%
  wood), a build order, farms before supply runs out, growing attack waves at the enemy base, retreat when a wave
  loses, defence when its base is attacked. It sees through its own fog only: the enemy base is a building it has seen,
  else the enemy's start. Measured in the proof game Kamienna Marchia and kept here:
  - no wave before 4 minutes, and the first wave is at most its difficulty's wave size (the rest defend at home);
  - a threat is a visible enemy **on its half** near its buildings (both sides build toward each other; an army idling
    at its own rally set off the other side's whole army);
  - farms ahead of the army (the free-food margin grows 3 per barracks; up to 3 farms at once when the wood is there)
    and production that never idles (an idle barracks trains while the order waits, keeping 300 gold);
  - difficulty is honest and bites: think speed, wave size, income, **and** the production buildings it runs (2 / 3 /
    4) and its army's food ceiling (70 / 85 / 100) — with income alone it only grew its bank.
  - `player_bot` (tests) plays the player's side: after its opening it reads the enemy's army (only what its team
    sees) and trains the counter (out of wood with gold in the bank: footmen); it defends at home until its first wave
    is ready.
- **Player's hands** (`scripts/ui/rts_player_input.gd`): recipes 58, 60, 61, 65 — see Input below. Observable:
  `selection`, `mode`, `placing`, `ghost_why`, `drag_rect()`.
- **HUD** (`scripts/ui/rts_hud.gd`, built in code): resources and food at the top; messages ("Za mało surowców",
  "Jesteśmy atakowani!", "Wymaga: Koszary"); the drag box; selection rings and health bars; the selection panel; the
  command card with keys, costs and what is missing; a building's queue with its progress; the minimap with fog, dots
  and the camera's frame (click to jump); the end screen.
- **Fog overlay** (`scripts/world/rts_fog_overlay.gd`): a plane over the map whose shader darkens it by the player's
  fog texture, smoothed.
- **Look** (`scripts/core/rts_look.gd`): the placeholder bodies. Swap for models by keeping the node names and sizes.
- **Input** (template actions):

  | Action | Keyboard / mouse |
  |---|---|
  | select | left click (shift toggles, double-click takes the type on screen), drag a box (units over buildings) |
  | smart order | right click: attack, gather, help build, move (formation targets); shift queues; a building's rally point |
  | `attack_move` | A, then left click |
  | `stop` | S |
  | `build_menu` | B, then Q farm · W barracks · E stable · R town hall; left click places, right click or Esc cancels |
  | `cmd_1`–`cmd_4` | Q W E R: with a building selected, train what it makes |
  | control groups | Ctrl+1–9 assigns, 1–9 recalls, twice quickly jumps the camera there |
  | `cam_*` | arrows; also the screen edges, a middle-mouse drag, the wheel to zoom, a minimap click |

  Plus the defaults (`pause` = Esc).
- Forward+, Jolt, 1280×720. Layers: 1 world, 2 units.

## Tuning table
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| start bank / workers | 400 gold, 150 wood / 4 | — | rts_rules.gd `start`, `start_workers` | — |
| supply: hall / farm / ceiling | 10 / 6 / 100 | food | rules `buildings`, `max_supply` | — |
| worker | 50 g · 1 food · 8 s · 40 hp · carries 10 · gathers 1.5 s · 3.6 m/s | — | rules `units` | — |
| footman | 90 g · 2 food · 14 s · 110 hp · armour 2 heavy · 10 blade (+8 vs mounted) · 1.2 s · 3.0 m/s | — | rules | — |
| archer | 70 g + 30 w · 2 food · 14 s · 70 hp · light, ranged · 11 pierce · range 7.5 · 1.25 s · 3.2 m/s | — | rules | range 6–8 |
| rider | 120 g + 20 w · 3 food · 18 s · 150 hp · armour 1 medium, mounted · 12 blade (+6 vs ranged) · 1.2 s · 5.0 m/s | — | rules | — |
| town hall / farm / barracks / stable | 400 g 200 w, 1500 hp / 60 w, 300 hp / 160 g 60 w, 700 hp / 150 g 100 w, 600 hp | — | rules `buildings` | — |
| type table | blade: light 1.25, medium 1.0, heavy 0.8, fortified 0.7 · pierce: light 1.0, medium 0.8, heavy 2.0, fortified 0.4 | × | rules `type_table` | keep the counter contract green |
| gold mine / tree | 5000 / 450, 2 workers each | — | rules `resources` | 300 ran out by minute 9 |
| target scan | 0.25 | s | rts_unit.gd `SCAN_EVERY` | 0.2–0.5 |
| leash | 12 | m | rts_unit.gd `LEASH` | 8–16 |
| a unit answers its attacker for | 5 | s after the hit | rts_unit.gd `ANSWER_WINDOW` | 3–10 |
| a hit reveals the attacker for | 2 | s | rts_game.gd `reveal_on_hit` | 1–4 |
| a team without a town hall is revealed after | 60 | s | rts_game.gd `REVEAL_WITHOUT_HALL` | 30–120 |
| fog | 2 m cells, 10 updates a second (5 per team) | — | rts_game.gd | — |
| AI easy / normal / hard | think 2.0 / 1.0 / 0.5 s · first wave 5 / 6 / 8 · growth 1 / 2 / 3 · income × 0.8 / 1.0 / 1.3 · barracks 2 / 3 / 4 · army food 70 / 85 / 100 | — | recipe 64 `preset` | — |
| AI first wave not before | 240 | s | rts_ai_player.gd `first_wave_not_before` | 180–360 |
| AI workers / free-food margin / farms at once / idle-production reserve | 14 / 4 + 3 per barracks / up to 3 / 300 gold | — | rts_ai_player.gd | — |
| AI wave cap | 20 (and never above what the supply allows) | units | recipe 64 `max_wave_size` | 12–30 |
| camera | pitch 58°, distance 16–48 (32) | — | skirmish.tscn CameraRig | — |

## Contracts (tests)
- **Complete data** (`test_rts_rules.gd`): every unit has its numbers and an attack type in the table, and exactly one
  building trains it; every building's needs exist; every attack type has a multiplier for every armour type.
- **Tech tree:** farm and town hall need nothing; a town hall opens workers and the barracks; a barracks opens
  footmen, archers and the stable; only a stable opens riders.
- **Counter triangle at equal cost** (a balance sheet: everyone focuses the first enemy alive, the longer-ranged side
  fires alone while the other closes the gap): archers beat footmen, riders beat archers, footmen beat riders, at
  420, 720 and 1260 gold, each keeping more than 25% of its budget and wiping the other side out. The same in the
  engine (R5), with attack-move in the open.
- **Bonuses along the triangle:** footmen have a bonus against a tag riders carry, riders against a tag archers carry,
  each worth at least a third of the hit.
- **Economy:** a worker 6 m from its mine earns back its gold in under 30 s; the start bank pays a farm and a barracks;
  the start workers fit the town hall's food; the ceiling is reachable (at most 20 farms).
- **Sieges:** ten footmen raze a town hall within a minute and five a farm within 20 s; a lone worker needs more than
  five minutes for a town hall.
- **Winnable:** R9's bot beats the normal computer within 20 minutes.
- **Fog honesty** (`test_fog_honesty.gd`): the computer's `enemy_base()`, `threat()` and `enemy_power_near()` ignore
  what its team hasn't seen; a hit reveals the attacker for `reveal_on_hit` s; a team without a town hall is revealed
  both ways after 60 s (off with `reveal_hall_less`); an idle unit answers its attacker only within the window.
- **The computer's habits** (`test_ai_habits.gd`), one at a time: a threat is an enemy on its half; idle production
  trains keeping its reserve; the food margin per barracks; the production cap and the food ceiling per difficulty.

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| R1 | A drag box around the workers and the hall takes the workers only; a click takes the hall; Ctrl+1 stores and 1 recalls; a double-click takes every worker on screen; the HUD shows the selection | `r1_selection.gd` |
| R2 | Workers right-clicked onto a gold mine gather and bring gold home; a minute's gold is near the formula's prediction for the trip; a worker ordered away keeps its load; wood works the same | `r2_gather.gd` |
| R3 | B, Q picks the farm; the ghost is green on free ground; a click places the site, takes the wood, and the worker builds it; food +6; over a mine the ghost is red and a click costs nothing, with the reason; a stable without a barracks is refused with "Wymaga: Koszary"; a path past the new farm bends around it | `r3_build.gd` |
| R4 | The hall's rally point by right click; Q three times queues three workers and pays at once; they come out after their time and walk to the rally point; a queue past the food cap waits at the cap | `r4_train.gd` |
| R5 | Equal-cost groups meet with attack-move: archers beat footmen, riders beat archers, footmen beat riders; five footmen raze a farm within a minute | `r5_counters.gd` |
| R6 | Twelve footmen, box-selected and right-clicked across the map, are each sent to their own slot (the group's shape kept), walk around the rocks, all arrive near the goal, nobody on anybody, most on their slot | `r6_group_move.gd` |
| R7 | The enemy base starts hidden and can't be built on; a scout reveals it and its workers; after it leaves, the buildings stay drawn, the units hide, the ground is explored | `r7_fog.gd` |
| R8 | The computer alone keeps its workers busy, builds a barracks and farms by three minutes, sends no wave before four, and its wave reaches the player's base by seven | `r8_ai.gd` |
| R9 | A bot on the player's side beats the normal computer within 20 minutes; a log every minute shows both economies | `r9_bot_wins.gd` |

## Next steps when a game starts from this
Replace the placeholders with art: `gb doc starter-packs` (KayKit's medieval hexagon pack for buildings and props,
its adventurers and skeletons for units, with idle / walk / attack / die clips → recipe 44), sounds (acknowledgements
per unit, the attack alert, construction, a victory sting). Then extend, in this order:
- a second faction with its own units over the same rules (the counter triangle stays the contract);
- upgrades at a new building (a research queue: recipe 60's production with a tech item);
- more maps (keep the bases mirrored; a map's layout is data);
- a campaign mission with a scripted objective (recipe 41's checkpoints, a trigger that starts the enemy);
- settings (camera speed, edge pan on / off, difficulty);
- a feel pass (`game-feel`: impact flashes, death animations, a ring pulse on orders).

Keep R9 green, and rerun the counter contract after every tuning change.
