# 47 — Melee combo (windup / active / recovery, input buffer, dash-cancel)

**Problem:** melee that feels mushy or unfair:
- presses get eaten because they came a frame early;
- the hitbox is on for the whole animation, so it hits things behind you;
- one swing hits a target five times (once per physics frame);
- the player is either locked in long animations or can mash through everything.

**Solution:**
- **`ComboAttack`** is pure logic with no 2D/3D in it. Each `AttackStep` runs **windup → active → recovery**. Only
  *active* can hit.
  - **Chaining:** a press during recovery chains the next step immediately. A press up to `buffer_time` before
    recovery is remembered (the **input buffer**), and earlier presses are dropped.
  - **Looping:** a press during the last step's recovery restarts the combo when that recovery ends.
  - **Dash-cancel:** `try_dash_cancel()` works only in recovery. Windup and active are the commitment.
  - Every active window gets a new `hit_id`.
- **`ComboMelee3D`** hosts it in 3D.
  - It reads the attack action and sizes an `Area3D` hitbox forward (-Z) to the step's `reach`.
  - While the swing is active, it calls `take_hit(damage, push)` on each overlapping body **once per `hit_id`**.
  - `move_scale()` slows the owner while swinging.
  - `damage_multiplier` scales every swing (feed it the owner's attack power from recipe 48).
  - `default_combo()` is a three-swing starting point: two quick cuts, then a slower finisher with more reach and
    push.

**Tuning:** per step `windup`, `active`, `recovery`, `damage`, `knockback`, `reach`, `lunge`; the combo's
`buffer_time` (0.1–0.2 s); `move_scale_attacking`. A finisher reads as heavy when it has a longer windup and more
push. Quick first swings keep the combo responsive.

**Hooking up enemies:** give them `take_hit(damage, push)` and route it into `Health` (recipe 05). Use
**`invulnerability_time = 0`** on enemies, because the recipe's default 0.5 s would swallow the second and third
swing. Feel comes from recipes 32 (hit-stop) and 33 (hit flash) on `hit_landed`. The dash is recipe 43: call
`try_dash_cancel()` before starting it.

**Pitfalls:**
- Using `area_entered` instead of polling overlaps. A target already inside when the swing starts never "enters".
- Forgetting the per-swing id, so you get a hit every frame. The scenario catches it: 4× damage per swing.
- A shared `BoxShape3D` between instances (`resource_local_to_scene`).
- **The default 3D physics (GodotPhysics) doesn't report `StaticBody3D` to an `Area3D`**, measured here: a static
  dummy took 0 hits and a `CharacterBody3D` dummy took all of them. Jolt does report them. Make enemies bodies that
  move (`CharacterBody3D`), and mask the hitbox to the enemy layer only.

**Test:** `tests/unit/test_r47_combo.gd` (frame-exact timings, chaining, buffer, dropped early press, loop,
dash-cancel only in recovery, a new hit id per swing), `tests/scenarios/r47_melee_combo.gd` (the bot hits a dummy:
1 press = 1 hit; 3 presses = the 3 swings once each; a pause resets). Scene: `combo_demo.tscn`.
