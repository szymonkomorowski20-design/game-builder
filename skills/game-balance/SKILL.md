---
name: game-balance
description: Use to set and protect the numbers of a game — damage, health, prices, rewards, spawn rates, difficulty curves — by writing the designer's intent as testable contracts with bands, simulating them, and letting playtests move the bands. Triggers — "balans", "za trudne", "za łatwe", "ekonomia", "ceny", "nagrody", "krzywa trudności", "przeciwnik za mocny", "difficulty", "balance", "economy".
---

# Game Balance — intent as contracts, numbers in one place

**Core principle:** balance is **intent** ("a slime is a warm-up", "the first upgrade costs a minute of
play") turned into **contracts with bands** that `gb verify` checks, plus **numbers kept in one place**
(stat Resources / Tuning table). Playtests change the bands; code changes never silently change the balance.

## 1. Numbers live in data
- One source: stat Resources (`data/enemies/slime.tres`) or a table the game loads. Tests and the game read the
  **same** files — never copy numbers into a test.
- Every number has a Tuning-table row: value, unit, range to try, why.

## 2. Write contracts
In the spec's Tuning section, per important relation:
| Contract | Band | Instrument |
|---|---|---|
| Warrior beats slime | win > 97 %, 2–6 s | `CombatSim.matchup` (recipe 36), 1000 seeded trials |
| Boss is beatable at level 5 | win 40–70 % | same |
| Upgrade 10 affordable | ≤ 60 s of income | `upgrade_cost` / `seconds_to_afford` (recipe 36) |
| Level 3 not longer than level 4 | path length ratio | `LevelCheck` path length (recipe 37) |
| No softlock in the shop | can always afford the cheapest healing | GUT on the economy model |
Write the contract test **before** tuning (it may be red — that is the point), then tune numbers until green.

## 3. Difficulty curve
Rising challenge with rests: introduce → practise → combine → rest. Express per level/wave as numbers (enemy
count, speed, damage) in a table; plot or at least check monotonicity where intended. Dynamic difficulty only
with a spec decision and a test that it is bounded.

## 4. Randomness
Seeded RNG per system (recipes 28, 31); state the variance the design tolerates (p10/p90 fight length from
recipe 36). Pity timers/bad-luck protection for important drops — as a tested rule, not a hope.

## 5. Playtest moves the bands
Players say "too hard" → find which contract they hit (time to kill? damage taken?), move the band in the
spec with the human, re-tune, re-verify. Record the change and why in the Decisions Ledger.

Template: [balance-sheet-template.md](balance-sheet-template.md) — copy to `.ai/balance.md`; contracts there, numbers in `data/`.

## Red Flags — STOP
- A number changed in code with no Tuning row.
- A band widened to make a test pass.
- Balance tests that recompute the game's own formula (mirroring) instead of simulating outcomes.
- "Feels balanced" without a contract or a playtest.
