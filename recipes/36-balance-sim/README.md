# 36 — Balance contracts (Monte-Carlo simulation)

**Problem:** balance is judged by feel after every change; a tweak to one stat silently makes another enemy
trivial or impossible, and nobody notices until a playtest.

**Solution:** write the designer's intent as a **contract** with a band — "the warrior beats a slime > 97 % of
the time, fights last 2–6 s" — and check it with `CombatSim.matchup(a, b, trials, seed)`: thousands of seeded
duels (crits, armor, attack intervals) in milliseconds. A Tuning change that breaks the band fails `gb verify`
with the measured number. Economy curves (`upgrade_cost`, `seconds_to_afford`) get the same treatment.

**Use:** read the stats from the same Resources the game uses (never duplicate numbers in the test), keep one
contract per important matchup/progression step in the spec's Tuning section, and let the playtest decide
whether the *band itself* is right.

**Tuning:** trials (1000–2000 is enough for ±3 %), seed (fixed), the bands.

**Pitfalls:** a mirror match must be ≈ 50 % — test the simulator first; simultaneous hits create draws (count
them); the sim is a model — movement, dodging and AI are not in it, so contracts are about stat balance, not
the whole fight; don't tune the band to whatever the code currently does.

**Test:** `tests/unit/test_r36_balance_sim.gd` — detection proven: a slime with 90 HP and a knight without armor
both break their contracts (8.76 s outside 2–6 s; 0 % instead of > 50 %).
