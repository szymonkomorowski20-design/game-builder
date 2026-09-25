# 10 — Crafting

**Problem:** combine items into new ones without duplicating or losing items when something goes wrong.

**Solution:** recipes as data (`{inputs: {id: n}, output, amount}` — later a Resource or JSON file); `Crafting.can_craft`
for the UI (grey out), `Crafting.craft` atomic: consume inputs, add output, **roll back** if the output does not fit.

**Tuning:** the recipe table (keep it in `data/` so designers edit numbers, not code).

**Pitfalls:** checking room before consuming (consuming may free a slot — or not); crafting from UI state instead of
the inventory; forgetting rollback (item loss bugs are the most reported crafting bugs).

**Test:** `tests/unit/test_r10_crafting.gd`. Builds on recipe 09.
