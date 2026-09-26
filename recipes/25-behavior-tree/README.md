# 25 — Behavior tree

**Problem:** the enemy FSM (24) grows to 12 states with transitions between all of them (flee when hurt, heal, call
friends, search…).

**Solution:** a behavior tree re-evaluates priorities every tick: **Selector** = try options in priority order,
**Sequence** = do steps in order until one fails, **Condition** / **Action** = leaves reading/writing a blackboard
Dictionary, **Inverter** = negate. Actions return `RUNNING` for multi-frame work (walking somewhere); a Sequence resumes
at the running child. `bt.gd` is ~100 lines to understand the model and for small AIs.

**When to use what:** ≤ 5 states → FSM (14/24). Many priority-driven behaviours → BT. Big projects → **LimboAI**
(C++ GDExtension, BT + HSM, visual debugger) or **Beehave** (GDScript, MIT).

**Pitfalls:** reactive selectors abandoning a RUNNING action without cleanup (add an abort hook when needed); logic in
the tree that belongs in the blackboard updater (perception once per tick, then decide); ticking 60× per second for
slow decisions (tick at 5–10 Hz).

**Test:** `tests/unit/test_r25_behavior_tree.gd`.
