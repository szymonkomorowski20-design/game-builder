# 52 — Status effects (damage over time, stacks, stat changes)

**Problem:** statuses are where bugs hide:
- a burn ticks one time too many;
- re-applying a slow slows twice and never comes back;
- poison stacks to 50;
- a cleanse leaves the stat changed;
- every system checks "am I slowed?" with its own special case.

**Solution:**
- **`StatusDef`** (Resource): `duration`, damage over time (`tick_interval`, `damage_per_tick` per stack), stat
  `modifiers` while active, and **stacking**. REFRESH means the same strength with the timer restarted. STACK adds
  a stack up to `max_stacks` and restarts the timer; damage and FLAT/INCREASED modifiers scale with stacks.
- **`StatusEffects`**, one per character:
  - `apply(def)`;
  - `tick(delta)` sends damage through `damaged(amount, id)`, so route it to Health (recipe 05) and damage numbers;
  - the end of a status fires `expired(id)` once;
  - `cleanse()`.
- Stat changes go through the character's **`StatSheet` (recipe 48)** under source `status:<id>` and are replaced,
  never doubled, on re-application. So movement just reads `sheet.value(&"speed")`.

**Tuning:** per status: duration, interval, damage, stacking, max stacks, modifiers. Keep damage over time readable,
about one tick per 0.5–1 s. Give each status one colour, icon and sound (recipe 33 flash tinted by status) so the
player can read it on a busy screen.

**Wiring:**
- Boons (recipe 48) and attacks (recipe 47) apply statuses on hit.
- An elite affix (recipe 49) can be a status aura.
- Enemies need `invulnerability_time = 0` on Health, or damage-over-time ticks are swallowed.
- Show stacks on a small icon row above the health bar.

**Pitfalls:**
- Re-adding modifiers on re-application, so the effect doubles. The test catches it.
- Forgetting to remove modifiers on expiry or cleanse, so the slow is permanent.
- Counting ticks with floating time and no epsilon (one tick more or less).
- Uncapped stacks.
- A status that kills during a boss's invulnerable transition. Route damage over time through the same
  `take_damage` gate (recipe 51) as hits.

**Test:** `tests/unit/test_r52_status.gd` (exact tick count, REFRESH, STACK with its cap and scaling, the slow
applied only while active and never doubled, cleanse, `expired` once). Four detection proofs: the doubled slow, no
stack cap, the stat not restored, damage ignoring stacks.
