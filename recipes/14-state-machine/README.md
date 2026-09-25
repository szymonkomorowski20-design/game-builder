# 14 — Finite state machine (node-based)

**Problem:** a player/enemy script full of `if is_jumping and not is_attacking and ...` flags that contradict each other.

**Solution:** `StateMachine` node with `State` children (Idle, Run, Jump…). Only the active state receives
`update` / `physics_update` / `handle_input`. States switch via `machine.transition_to(&"Jump", {msg})`; `exit()` of the
old state always runs before `enter()` of the new one. States reach the character through `owner`.

**When not to use:** 2–3 states → an `enum` + `match` is simpler (the Pong dogfood does this). For enemy AI with
priorities, see behavior trees (recipe 25); for animation states use AnimationTree's own state machine and drive it from here.

**Pitfalls:** transitioning inside `enter()` of another transition (re-entrancy — defer it); states holding references
to each other (go through the machine); forgetting that `_unhandled_input` needs real input events (the harness sends them).

**Test:** `tests/unit/test_r14_state_machine.gd`.
