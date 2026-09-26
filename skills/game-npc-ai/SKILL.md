---
name: game-npc-ai
description: Use to build enemy and NPC behaviour — patrol, perception, chase, attack, flee, pathfinding, group behaviour — choosing between a state machine and a behavior tree, keeping decisions testable and readable to the player. Triggers — "przeciwnik", "wróg", "AI", "NPC", "patrol", "ściganie", "sztuczna inteligencja", "pathfinding", "omijanie przeszkód", "behavior tree", "state machine".
---

# Game NPC AI — readable to the player, testable to us

**Core principle:** good game AI is **readable** (the player understands what it is doing and why) and
**fair** (telegraphs before hitting), not smart. Split **decision** (pure, unit-testable) from **movement**
(physics, scenario-testable).

## 1. Choose the structure (decision card if unsure)
| Behaviour | Structure | Recipe |
|---|---|---|
| ≤ 5 clear states (patrol/chase/attack/return) | FSM — `enum` + `match`, or node states | 24 (enemy), 14 (node FSM) |
| Many priorities (flee when hurt, heal, call help, search) | Behavior tree (Selector/Sequence/RUNNING) | 25; big projects: LimboAI or Beehave |
| Moving around obstacles | `NavigationRegion2D` + `NavigationAgent2D` | 26 |
| Grid/tactics | `AStarGrid2D` (4.6+: empty path from a solid start point) | — |
| Animation states | AnimationTree state machine driven by the AI state (4.7: set blend space `sync_mode`) | — |

## 2. Perception
Sight = range **and** a ray not blocked by walls (exclude own RID, mask = walls — recipe 24). Hearing = events
(`Events.noise(pos, radius)`). Memory: last seen position + give-up timer. Stagger expensive checks (every Nth
frame) with many agents.

## 3. Fairness and readability
Telegraph attacks (wind-up animation/sound/flash 0.3–0.6 s) — a Tuning row each. Alert state before chase.
Enemies slightly slower than the player unless the design says otherwise. Don't attack from off-screen.

## 4. Tests
- Decision table as GUT (`decide(dist, sees, delta)` → mode) — recipe 24 shows it; exact float steps (0.125) for timers.
- Scenario with real physics: patrol stays on its segment, a wall blocks sight, a visible target is chased and
  attacked, lose-time → return (recipe 24 scenario). Navigation: reaches the target around an obstacle (26).
- Many agents → `gb perf` with the worst-case count on screen.

## Red Flags — STOP
- Decision logic tangled with movement code (untestable).
- Enemies that see through walls or react to the player instantly with no telegraph.
- Pathfinding queried on the first frame (map not synced) or re-pathed every frame for every agent.
