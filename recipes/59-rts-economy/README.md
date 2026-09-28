# 59 — RTS economy (stockpile, supply, resource nodes with saturation, the workers' gathering loop)

**Problem:** the economy is the other half of an RTS. The usual breakages:
- a purchase that takes the gold and then fails on the wood;
- two barracks both starting the last footman that fits the supply;
- ten workers on one mine earning ten times as much, so expanding never pays;
- workers walking back to the old town hall past a new one;
- a spent mine leaving its workers standing idle;
- income nobody can predict, so build orders and balance are guesswork.

**Solution:** logic classes without scenes; the game's nodes wrap them.
- **`RtsStockpile`** (one per team):
  - resources of any kinds; `spend(cost)` is all-or-nothing; `refund(cost, fraction)`;
  - supply: `provide(n)` (a farm finished: +n; destroyed: −n), `reserve(n)` when an item *starts* (false if it does
    not fit), `release(n)` when a unit dies or an item is cancelled; `max_supply` caps it whatever the farms.
- **`RtsResourceNode`:** `amount`, and at most `max_gatherers` gather at once (the others wait). `take(n)`;
  `depleted` fires when it runs out.
  - `income_per_minute(workers, distance, speed, gather_time, carry, slots)`: the expected income, capped by the slots.
    Put it in the spec's balance sheet and in a contract test.
- **`RtsGatherer`** (one per worker): TO_NODE → WAIT → GATHERING → TO_DROP → deposit → back.
  - The body walks to `target()` and calls `tick(delta, arrived)`.
  - `find_node(kind, from, busy)` finds the next node when one is spent, or when the worker has waited `max_wait`
    for a slot (the game should prefer nodes with free slots and skip `busy`); `find_drop` finds the nearest
    drop-off, asked when the load is ready.
  - `stop()` (another order) gives up the slot and keeps the load.

**Tuning:**
- per resource: the load (`carry`), `gather_time`, `max_gatherers` (2–3 per patch or mine slot), and the node's `amount`;
- per team: the start amounts, `max_supply` (100–200), the supply per farm or house (8–10);
- the distance from a base to its resources (a trip that is too long makes a new drop-off pay).

Balance with `income_per_minute`, not by feel: one worker on an 8 m trip at 4 m/s, gathering 1 s for 10 gold, earns
120 a minute. The node's slots cap it at `slots × carry / gather_time`.

**Host (the game):**
- a worker node (`CharacterBody3D` + `NavigationAgent3D`) that owns an `RtsGatherer`:
  - sets `position` every physics frame;
  - walks to `target()`, and `arrived` = within its radius;
  - plays gather and carry animations by `state`;
- a mine node wrapping an `RtsResourceNode` (its `position` is where workers stand);
- `find_drop`: the nearest own finished town hall or lumber mill;
- the HUD reads the stockpile's `changed`.

**Pitfalls:**
- charging a cost piece by piece;
- checking supply when an item is *queued* but reserving it only when it *finishes* (two queues overfill the cap);
- no slot limit (income grows without bound);
- a drop-off chosen when the trip starts instead of when the load is ready;
- a spent node's workers stuck in WAIT;
- workers queuing at the nearest node while another stands free (found in the RTS template; `max_wait` fixes it);
- a worker ordered away losing its load (players notice).

**Test:** `tests/unit/test_r59_economy.gd`:
- all-or-nothing spending, refunds, reserved and capped supply;
- slots and depletion;
- the full loop with a walking host (5 s a trip, as computed);
- the income formula against the simulation, and saturation;
- waiting for a slot;
- the next node, and the nearest drop-off;
- stop() keeps the load.
