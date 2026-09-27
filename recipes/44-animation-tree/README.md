# 44 — AnimationTree state machine driven by movement

**Problem:** animation code scattered through the player script (`play("run")` in five places), animations that
flicker between states, a fall animation that never plays because "jump" is set on the way down too — and no test
can tell, because nobody watches the animation.

**Solution:** one rule, one driver. `AnimStates.state_for(on_floor, velocity)` is the pure rule: idle / run on the
floor (with a speed threshold), jump while rising, fall otherwise. `CharacterAnimator` asks it every physics frame and
calls `travel()` on the AnimationTree's state machine only when the state changes. `AnimStates.build_machine(names)`
builds the machine in code (every state connected to every other with a short cross-fade) when you don't want to
draw the graph in the editor. The demo makes placeholder animations; yours come from sprites or models. The same rule
works for 3D (use the body's horizontal speed).

**Tuning:** `run_threshold` (px/s), `xfade` (s) per transition. Add states (attack, hurt, land) to the rule first, then
to the machine.

**Pitfalls:** calling `travel()` every frame (restarts cross-fades; call it on change); `travel()` to a state with no
path from the current one does nothing silently — connect them (or use `build_machine`); forgetting
`AnimationTree.active = true`; setting `anim_player` before the AnimationPlayer has its library; animating the same
property from AnimationPlayer and code at once. In 4.7 BlendSpace nodes gained `sync_mode` — check it when blends
drift out of step.

**Test:** `tests/unit/test_r44_anim_states.gd`, `tests/scenarios/r44_animation_tree.gd` (checks the state machine's
current node, not the animator's variable). Scene: `anim_demo.tscn`.
