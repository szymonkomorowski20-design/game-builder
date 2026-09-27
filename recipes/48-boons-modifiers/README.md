# 48 — Stat modifiers and boons (rarity, synergies, seeded offers)

**Problem:** run-based games live on build variety, and it breaks in predictable ways:
- upgrades that stack in a different order give different numbers;
- an item can't be removed cleanly;
- the same boon is offered twice;
- a "duo" synergy shows up before the player has either half;
- rarity is a coin flip nobody can tune;
- offers can't be reproduced, so a bug report can't be replayed.

**Solution:**
- **`StatSheet`**: base stats plus `StatModifier`s. The value is **(base + Σ flat) × (1 + Σ increased) × Π more**,
  the same in any order. `remove_source(id)` removes a boon or item whole, and `changed(stat)` tells the UI and
  caches.
- **`Boon`** (Resource): `id`, `tags` (a school/element/god), and `requires_tags`, which make it a **synergy**. Its
  modifiers are written for COMMON. `apply(sheet, rarity)` scales them by `RARITY_SCALE` (×1 / 1.5 / 2 / 2.5); a
  MORE multiplier scales only its bonus part.
- **`BoonPool.offer(seed, owned, 3)`** returns distinct boons the player doesn't own. Synergies are included only
  when the player owns boons of **every** required tag. Rarity is rolled from `rarity_weights`, and `luck` raises
  rarer tiers (weight × (1 + luck × tier)). The same seed gives the same offer.

**Tuning:**
- `rarity_weights` (default 70/24/5/1);
- `RARITY_SCALE`;
- `luck` (from a meta upgrade or a "heat" reward);
- per-boon modifier values;
- offer size (3 is the genre standard; 2 raises pressure, 4 lowers it).

Put boons in `.tres` files so designers edit data, not code.

**Wiring:**
- Read stats at the moment of use:
  - `sheet.value(&"damage")` × the step damage of recipe 47 on hit;
  - `value(&"speed")` each physics frame;
  - `max_health` into recipe 05 when `changed` fires.
- Give each run its own seed stream (seed = run seed + room index) so a run replays exactly (recipes 13 and 36).

**Balance:** "no dominant boon" is a contract. Simulate each boon's DPS or survival gain with recipe 36 and keep
every one inside a band. A boon that wins everywhere gets redesigned, not just trimmed. Synergies should reward
*combining* schools, not just add more numbers.

**Pitfalls:**
- Multiplying "increased" percentages together, so +20% and +30% gives +56% instead of +50%. The formula test
  catches it.
- Caching a stat once and missing later boons.
- Rolling rarity with the global RNG, which makes offers unreproducible and harness-dependent.
- Offering synergies whose parts the player can't have yet.
- One RNG draw shared between the card choice and its rarity in a way that correlates the cards. The test checks
  that all three cards follow the weights and that "all the same rarity" happens at chance rate (~36%).

**Test:** `tests/unit/test_r48_boons.gd` (formula and order independence, removal, the change signal, distinct and
unowned offers over 100 seeds, synergy gating, the small pool, rarity distribution for all cards, luck, rarity
scaling), `tests/scenarios/r48_boons.gd` (the bot takes a card with the real keys; the stat rises, the next offer
doesn't repeat it). Scene: `boon_demo.tscn`.
