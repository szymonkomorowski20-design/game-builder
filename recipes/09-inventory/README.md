# 09 — Inventory with stacks

**Problem:** pick up, stack, drop and save items without losing any and without UI code owning the rules.

**Solution:** `ItemDef` (Resource per item type: id, name, `max_stack`, value) + `Inventory` (pure `RefCounted` data:
slots of `{id, count}`). `add` fills existing stacks, then empty slots, and **returns the leftover** so the game
decides (drop it, refuse pickup). `remove` is all-or-nothing. `to_dict`/`load_dict` serialise to JSON-safe data.
The UI listens to `changed` and redraws.

**Tuning:** slot count, `max_stack` per item.

**Pitfalls:** storing `ItemDef` resources inside save data (store ids); partial removal on "not enough";
UI mutating slots directly; forgetting that JSON turns ints into floats (cast on load).

**Test:** `tests/unit/test_r09_inventory.gd`.
