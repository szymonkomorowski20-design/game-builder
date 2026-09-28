# Proof game: "Kamienna Marchia" (ROADMAP 9.3, autonomous mode)

A real-time strategy game in the Warcraft mould — the march's knights against the risen dead, three missions and a
skirmish — built by game-builder from the owner's pitch. It uses the **autonomous** process: the bot decided with each
decision card's recommended option, a fresh `game-checker` approved the spec (three rounds), the machine gates ran at
every phase, and the owner plays only the finished game. It was built on 2026-09-28 on game-builder 0.28.0, from the
`rts-3d` template.

Game repo: `Desktop/gry testowe/kamienna-marchia`. It has no commits by the owner's rule; phases are `git write-tree`
snapshots listed in its STATUS.md.

## What was built
- **Two factions, one set of numbers:** the march (KayKit adventurers: robotnik, piechur, kusznik, szarżownik) and
  the dead (KayKit skeletons: sługa, wojownik, strzelec, upiór); the same costs, stats and sight, so the counter
  triangle (crossbows beat foot, chargers beat shooters, foot beats chargers) is the only asymmetry a player reads.
- **Missions** (a step runner: gather, build, train, survive raids, destroy targets, destroy a base):
  1. **Bród:** a tutorial base build with a hint per step, then three raids through the ford.
  2. **Wypad:** no economy — a fixed army against three camps whose guards each counter one part of it, a camp alarm
     and leash, a patrol, reinforcements per fallen totem.
  3. **Kurhan:** both sides from a mid-game start with a garrison that never joins a wave; the full game against the
     dead at the chosen difficulty.
  - **Potyczka:** the template's skirmish on the same runner.
- **The computer:** recipe 64's brain with a first-wave floor (4 minutes) and cap, honest fog knowledge, farms ahead of
  its army, production that never idles, and difficulty as income, production and an army ceiling.
- **Menus:** a title over the living map, mission select with padlocks and best times, briefings, skirmish setup,
  results with stats, pause (Esc cancels a placement or a target first), settings (camera speed, edge pan, volumes,
  fullscreen, difficulty), a versioned save that never overwrites an unreadable file, credits.
- **Look and sound:** KayKit characters and the Medieval Hexagon pack, Kenney sounds, 6 Game Music Composer tracks with
  adaptive quiet/fight music. All free, from the gry-wiedza library; 0 paid generations.

## Numbers
| | |
|---|---|
| Unit tests (GUT) | 154, including the recipes' own |
| Bot scenarios | 29: the template's R1–R9, the phases' P1–P5 — the whole campaign and the skirmish through the menus, mission 3 on more seeds, the difficulty order |
| Detection proofs (mutations) | phase 3b fixes: 4 of 4 caught; phases 3c–5: 11 caught, 1 equivalent (explained in the spec's Evidence) |
| Phase reviews | spec: 3 rounds → NITS; P1 CHANGES-REQUIRED; P1 fixes + P2 CHANGES-REQUIRED; 3a CHANGES-REQUIRED; 3b CHANGES-REQUIRED; 3b fixes + 3c–5: see STATUS.md |
| The bot, Normalny | mission 1: 376–430 s; mission 2: 124–137 s, every camp taken; mission 3: 14 of 15 games won (417–670 s); the skirmish (R9): 6 of 6 seeds (414–569 s); the campaign through the menus: 1022 s of play |
| The difficulty order (army value at 6 min, four seeds) | Łatwy 2560–2580 · Normalny 3280–3320 · Trudny 3920–3940; first waves 5 / 6 / 8 at 240–245 s |
| Performance (40 against 40, the shipped avoidance setting) | frame p95 5.56 ms, process p95 5.84 ms, draw calls max 952, nodes max 3184 |
| Build | `KamiennaMarchia.exe` + `KamiennaMarchia.pck` (126.6 MB); the exe blocked by Smart App Control on this machine, the pack verified under the editor binary |

## What the machine gates caught (and a human would have found later)
| Found by | Problem | Fix |
|---|---|---|
| the bot (phase 1) | the template's bot and the computer used the same brain: the bot won 1 of 5 seeds, so R9 proved nothing | a bot that reads the enemy's army and trains the counter (8 of 8 seeds) |
| the bot (phase 1) | a last farm the winner never saw made a game endless | a team without a town hall is revealed after 60 s (Warcraft III's rule) |
| the phase 1 review | bot games differed run to run | synchronous navigation baking under the harness, the navigation server's async iterations and threaded avoidance off, the sounds' own RNG |
| GUT (phase 1) | navigation-mesh bake warnings counted as errors | agent radius and climb in exact multiples of the cell size |
| `p2_feedback` (phase 2) | a right click on an enemy never attacked: recipe 58 read `bool(target.get("is_resource"))` | `== true` (plugin fix) |
| the phase 2 review | the template's first wave reached the player by 3 minutes | a 4-minute floor and a first wave capped at `wave_size` |
| the phase 3b review | the patrol walked one way; guards bounced at the camp leash, so archers past it cleared a camp without losses | two queued patrol legs; a leashed guard is deaf to alarms and forgets its attacker; no alarm from past the leash |
| the camps in the engine (phase 3b) | melee units attack-moving into a camp beat its totem while archers behind it shot them | units on attack-move, on patrol or hitting a building answer a seen attacker |
| the bot (phase 3b) | the spec's camp order passed a third camp and lost the whole army | the order chosen by routes on the navigation mesh, tested |
| the difficulty test (phase 5) | Łatwy and Normalny fielded the same army at 6 minutes; the hard one banked 5000 gold | farms ahead of the army, idle barracks train, difficulty caps production and the army's food |
| the difficulty test (phase 5) | one difficulty fielded 22–40 soldiers depending on the seed | the same fixes; each level of the test starts from the same seed, checked on four seeds |

## What the plugin learned (0.29.0)
- **Recipe 64:** the first-wave floor and cap, the stall rule, the retreat measured where the wave is, and two more
  difficulty knobs (production buildings, the army's food ceiling); its README names the host's habits.
- **Recipe 58:** the smart right-click on enemies (`bool(get())` on a missing property). **Recipe 35:** an own RNG.
- **Template `rts-3d`:** the computer's habits, the reading bot, answering attackers, fighting patrols, fog honesty,
  determinism for tests with threaded avoidance in exports, navigation in cell multiples, 450 wood a tree, and unit
  tests for each habit.
- **`gb scaffold`:** templates set their own project settings. **`gb export --smoke`:** the pack runs under the editor
  binary when Windows refuses the exe.
- **Pitfalls:** the per-file application-control verdict, one seed is not a proof, determinism against a battle's
  budget, `bool(get())`.

## What the owner decides (STATUS.md, "Twoja kolej")
Play the three missions and a skirmish and judge what no bot can: whether the counters read on screen, whether
mission 2's camps are fair, whether the computer's waves feel like pressure or a wall, which difficulty is right. Then
"commituj" for the game repo's first commit.

## Honest limits
- The bots play by the numbers (a perfect counter read, no misclicks); their wins are fairness floors.
- There are no horses in the library: the "chargers" are barbarians on foot, the "stable" is a smithy.
- Three missions and a skirmish on 72 × 72 m maps is the brief's rung 3, not a full campaign.
