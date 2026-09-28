# 64 — RTS skirmish AI (a priority list, attack waves, retreat, honest difficulty)

**Problem:** an RTS needs an opponent. The usual failures:
- a planner that is too clever to finish, or too slow to run;
- an AI that supply-blocks itself;
- an AI that buys cheap units forever and never techs;
- an AI that trickles units one by one into the player's army;
- an AI that fights to the last man;
- "hard" that secretly sees the whole map.

**Solution:** `RtsAiBrain`, built the way commercial skirmish AIs are: a priority list, waves, and difficulty as reaction
and income. Every `think_interval` seconds it:
1. **Supply:** builds a farm when free supply drops below `supply_margin` and none is on its way. It saves for the
   farm before anything else.
2. **Workers:** keeps making them up to `worker_target`.
3. **The build order**, a list of `{kind, count}`: the first entry it has fewer of is the goal.
   - It is bought when affordable. Otherwise the AI saves up for it; cheaper things don't jump the queue, or it never
     techs.
   - An entry locked by the tech tree waits while what unlocks it is being built (`unlocking`, optional in the
     world). Otherwise it is skipped, so list prerequisites first. (Found in the RTS template: skipping while the
     first barracks was going up made the AI start a second one and starve.)
4. **Waves:** once the army has `wave_size` units it attack-moves to the enemy base as one group. Each wave is
   `wave_growth` bigger, up to `max_wave_size` (found in the RTS template: waves outgrew the largest army the supply
   allows, and the AI never attacked again).
5. **Push or retreat:** while a wave is out, idle units of it are sent on at the enemy base (it moves as buildings
   fall). When the wave's power falls below `retreat_ratio` × the enemy's power there, it goes home, and the next
   wave waits for its size.

At the supply ceiling (`supply_maxed()`, optional in the world) it stops building farms. Between waves, when enemies
come near its buildings (`threat()`, optional), the idle army goes at them.

The game gives it a `world` object (see the class header for the methods: counts, costs, tech, supply, orders, army
power, attack and retreat). The recipe's test uses a fake world, so the decisions are tested apart from the game.

**Difficulty** (`preset(level)`), honestly:
- the reaction time (`think_interval`: 2 s / 1 s / 0.5 s);
- the wave sizes;
- an **income multiplier** (0.8 / 1.0 / 1.3) the game applies to the AI workers' deliveries.

Commercial RTS AIs raise difficulty with resource bonuses more than with smarter decisions. It works, but say so on the
difficulty screen ("Hard: the enemy gathers 30% faster"), and give the AI its team's fog of war (recipe 62) instead of a
full map.

**Tuning:**
- the build order (it *is* the AI's personality: rush, boom, tech);
- `worker_target` (12–20);
- `supply_margin` (a farm's supply ÷ 2);
- `wave_size` and `wave_growth` (the pressure curve);
- `retreat_ratio` (0.5–0.8);
- the presets.

**Host (the game):**
- an AI node per computer team owns an `RtsAiBrain` and calls `tick(delta)`;
- its world object answers from the team's stockpile (recipe 59), productions and tech tree (recipe 60), and its unit
  lists;
- `order(kind)` either queues a unit at the least busy building that makes it, or picks a building site next to its
  base with a free footprint (recipe 60's grid) and sends a worker;
- `attack` gives the army an ATTACK_MOVE with formation targets (recipes 58, 61);
- `power` sums what the units cost; `enemy_power_near` counts the *visible* enemies around the army.

**Pitfalls:**
- skipping to cheaper items when poor (the AI never techs);
- no farm rule (it blocks itself at the first supply cap);
- trickling units into the enemy one by one (waves fix it);
- fighting to the death (retreat, and the player gets to counter-attack);
- thinking every frame (costly, and it reacts like a machine; 0.5–2 s is human);
- a secret map hack.

**Test:** `tests/unit/test_r64_ai.gd`:
- a farm when supply runs low, and saving for it;
- workers up to the target;
- the build order saving for its goal and skipping a tech-locked step;
- waves that grow, and the retreat when the odds turn;
- the think interval as reaction time;
- the presets.
