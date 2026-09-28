# 63 — RTS combat (damage with bonuses, type table and armour; target priority; leash)

**Problem:** RTS fights are many units fighting on their own. Their rules decide whether the army the player built
does what they meant.
- Damage rules that make every unit equal, so there are no counters and the biggest blob wins.
- Armour that makes a unit immune (0 damage), so fights never end.
- Units that attack the wall next to them while archers shoot them.
- Units that twitch between two targets, or chase one runner across the map.

**Solution:** `RtsCombat`, data and pure functions.
- **`damage(attack, target)`:**
  - the base damage, plus `bonus` against the target's `tags` (e.g. +8 vs `mounted`), **before** armour;
  - times `table[attack.type][target.armour_type]` (the counter table: blades beat light, arrows beat heavy, siege beats
    fortified — the game's own numbers);
  - minus the target's flat `armour`, never below `min_damage` (0.5). This is StarCraft II's order: bonus, then armour,
    with a floor; Warcraft III uses a type table.
- **`hits_to_kill(attack, target, hp)`:** for the balance sheet. Write the counter triangle as a contract test, so a
  tuning change can't quietly flatten it.
- **`pick_target(from, acquire, candidates, current)`:**
  - only visible candidates (fog, recipe 62) inside `acquire` range;
  - whoever is attacking me first, then the nearest unit, buildings last;
  - the current target is kept while it is valid and in range (no twitching).
- **`should_give_up(chase_start, at, leash)`:** a unit chasing on its own returns beyond `leash`.

**Tuning:**
- the type table (1.5 / 0.75 / 0.5 are readable steps; keep every multiplier above 0.25);
- per unit: damage, attack type, bonus tags, armour, armour type, hit points, cooldown, range, `acquire` (range + 2–4 m);
- `leash` (10–15 m);
- `min_damage` (0.5–1).

**Host (the game):**
- a unit's combat node calls `pick_target` a few times a second while idle, on ATTACK_MOVE or HOLD. A MOVE order ignores
  enemies (the genre's rule: move means move).
- Mark a target `attacking_me` from the damage the unit takes.
- Fire when the cooldown allows and the target is in range. Deal `damage(...)` through the health component (recipe 05)
  and set the target's `attacking_me` for its own picker.
- Stop the chase when `should_give_up`, and go back to the order or the spot.

**Pitfalls:**
- armour as a percentage with no floor on the other side (0 damage);
- bonus added after armour (bonuses vanish against armour);
- target picking by nearest only (towers soak the army's fire while archers kill it);
- re-picking every frame (twitching);
- attacking into the fog;
- a MOVE order that fights anyway, so the player can't retreat.

**Test:** `tests/unit/test_r63_combat.gd`:
- the order of bonus, table and armour, and the floor;
- the counter triangle as a contract;
- target priority: attacker first, units before buildings, range, fog, sticking with the current target;
- the leash.
