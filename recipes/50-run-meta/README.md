# 50 — Run structure and meta progression (doors with rewards, death banks, permanent upgrades)

**Problem:** a roguelite's pacing is its structure, and it breaks in familiar ways:
- blind doors, so routing is luck;
- two shops in a row;
- no rest before the boss;
- elites in the second room;
- dying erases the run, so bad luck costs half an hour;
- permanent upgrades that are free or explode in price;
- progress that can't be saved.

**Solution:**
- **`RunMap.doors(depth, seed, previous)`**: the exits after each room, each a `RoomDoor` with a room **type**
  (combat, elite, shop, rest, boss) and the **reward shown on the door** (boon, currency, heal, upgrade). The rules:
  - room 0 is a single combat door with a boon (onboarding);
  - the last room is the boss, alone;
  - the room before it always offers a rest;
  - other rooms offer 2–3 distinct doors;
  - never a shop right after a shop;
  - elites only from `elite_from`.

  It is deterministic from the run seed.
- **`RunState`** tracks one attempt: its seed, depth, path and the currency collected. `end(won)` returns **all** of
  the collected currency, even on death, so every run moves the player on.
- **`MetaProgress`** holds the banked currency and permanent upgrades. Level n → n+1 costs `base_cost × (n + 1)`, up
  to `max_level`. `apply_to(sheet)` adds them to a recipe-48 `StatSheet` (source `meta:<id>`, re-applied cleanly).
  `to_dict`/`from_dict` connect it to the save recipe (13).

**Tuning:**
- `rooms` per area (8–12; a first clear should take tens of minutes, not hours);
- `elite_from`, `shop_chance`, `elite_chance`;
- rewards per room;
- upgrade costs and caps.

Lean meta upgrades toward **new options** (a weapon, a starting boon choice, a reroll) rather than only raw power.
Pure power makes early runs too hard and late runs trivial. Harder "mastery" modifiers for players who beat the game
belong in data, not code.

**Wiring:**
- `EncounterDirector` (recipe 49) runs combat and elite rooms with `depth` = room index (elites get a higher
  budget);
- the reward is given on `cleared`: a boon offer (48), currency (`run.collect`), a heal, or an upgrade;
- save `meta.to_dict()` after every banking (13).

**Pitfalls:**
- Losing currency on death. The test catches it.
- Seeding doors from the global RNG, which makes runs unreproducible.
- Door rules checked only on the path the developer happened to take. The tests sweep 100 seeds and every depth.
- An economy where the first upgrade isn't reachable in a short run. The scenario caught this in the demo: 3 rooms
  paid 9 and the upgrade cost 10.
- Applying meta upgrades twice (`apply_to` removes the old source first).

**Test:** `tests/unit/test_r50_run_meta.gd` (first and last rooms, rest before the boss, 2–3 distinct doors, no shop
after a shop, elites only from `elite_from`, determinism, death banks currency, rising costs and caps, upgrades
raise stats and survive to_dict/from_dict, a fresh run), `tests/scenarios/r50_run_meta.gd` (the bot enters 3
rooms, dies, buys an upgrade in the hub and starts a stronger run). Scene: `run_demo.tscn`.
