# 67 — Climbing and ledges (a markup-free ledge probe, hang, climb, shimmy, side jump, mantle, vault, parkour down)

**Problem:** climbing is the genre's signature and its most common complaint (genre doc §1):
- sticky climbing that grabs walls the player only ran into;
- holds nobody can see, so players "find the spot and press the button";
- no way down from a roof but a fall;
- climbing that cuts through corners or leaves the body hanging inside the wall;
- hand-placed markers on every ledge, which break whenever a level changes.

**Solution:** a probe that reads holds from the geometry, and a climber that moves the body between them.
- **`LedgeProbe.find(space, origin, facing, y_min, y_max)`:**
  - forward rays through the height window find the wall's face (the farthest wall hit, because lips stick out of
    the face). The wall must be steep, and faced within `max_facing_deg`;
  - two columns look down for a flat top:
    - just behind the face: the wall's own top, as on a roof's edge, a crate or a fence. It is skipped when the
      wall goes on above the window;
    - just in front of the face: a lip, such as a cornice, a sill or a beam.

    Holds above the window are passed through, so a sill under a cornice is still found.
  - It returns `{kind (&"top" / &"lip"), top_y, edge, normal, hang, stand, height, can_hang, can_stand}`:
    - `hang` puts the feet `hang_below` under the top and `hang_gap` out from the face;
    - `stand` is `stand_in` behind the edge;
    - `can_hang` and `can_stand` are capsule checks, and nobody stands on a lip.
  - `capsule_free(space, feet)` is the same check, for other uses.
- **`Climber`** (a child `Node` of a `StealthMover`, recipe 66). It runs before the mover each physics frame.
  - **On the ground:** jump at a wall, or sprint into it, to grab the hold in front. A top up to `mantle_max` is
    stepped onto (a mantle); a thin one is vaulted, because its stand point lies past it. A knee-high lip that can
    be neither stood on nor hung from is skipped for the hold above it (on a roof under a taller wall, for example).
    Running into a wall without sprint or jump never climbs.
  - **At a roof's edge** (the mover stopped there, recipe 66), the drop intent hangs from the edge: the genre's
    "parkour down".
  - **In the air**, with jump pressed or sprint held, it catches a hold at hand height.
  - **Hanging:**
    - up/down climb hold by hold;
    - up at a top climbs over it;
    - left/right shimmy, stopping `shimmy_margin` before a hold's end;
    - jump plus left/right jumps to the next hold sideways;
    - drop lets go;
    - jump alone pushes off backwards.
  - Moves are timed (`climb_speed`), turn the body to the wall, and make noise (`climb_noise`), because climbing is
    high profile.
  - A climb onto a top goes up first, then over, instead of cutting the corner.
  - `hang_at(hands, facing)` snaps into a hang, for tests, spawns and cutscenes.
  - Signals: `grabbed(ledge)`, `climbed_up`, `let_go`.

**Level rules:**
- Holds must be at least `hang_below` above the ground to hang from (a lip at 1.5 m can't hold a hanging body);
  the first one on a facade at about 2.2 m is a jump-grab.
- Keep holds 1.2–1.6 m apart vertically (`reach_up`).
- Give all holds one look, e.g. lighter stone or wood, and put them on a climbable physics layer
  (`probe.mask`) (genre doc §12).

**Tuning:**
- `climb_speed` 2.2 m/s (a move takes 0.25–0.8 s);
- `grab_max` 2.3 m, `mantle_max` 1.4 m, `reach_up` / `reach_down` 1.6 m;
- `shimmy_step` 0.4 m with a `shimmy_margin` of 0.25 m;
- `side_jumps` 1.0–2.2 m;
- the probe's `reach` 1.0 m, `max_facing_deg` 40, `hang_below` 1.95 and `hang_gap` 0.5 (for a 1.8 m body with a
  0.35 m radius; lips up to 0.12 m deep).

No shipped game publishes these numbers (genre doc, "Not established"), so they are starting values.

**Pitfalls:**
- **The first down ray hitting the hold above the one wanted:** stacked holds hid each other until the probe passed
  through holds above its window. A side jump under a cornice found nothing.
- **A down ray starting inside the wall:** a building's inside would count as its top. The probe checks that the
  start point is free, but only for the wall's own top. A lip column often starts inside the hold being hung from
  (climbing down from 4.6 starts at 4.45), and that check stopped every climb down after the first.
- **A top that isn't this wall's:** a crate behind a thin 4 m wall has a top in the window, and the body would climb
  through the wall. A wall's top counts only when the edge is open above it (a point just behind the face, 0.2 m
  over the top). The check that the column's start is free is only an early exit.
- **Taking the nearest wall hit as the face:** a lip is nearer than the wall, so the columns land inside it. Use the
  farthest.
- **Comparing heights from ray hits with `==`:** a hold at 3.4 comes back as 3.3999… Compare in whole centimetres or
  decimetres.
- **The mover processing before the climber:** the mover walks off the edge in the same frame the drop was meant to
  hang. `process_physics_priority = -1` runs the climber first.
- **Climbing on any contact:** the inFAMOUS complaint (genre doc §1). Grab only on jump or sprint.

**Test:** `tests/unit/test_r67_ledges.gd` runs the probe on real boxes:
- the first lip from the street (also when a forward ray hits the lip's front), the next hold up and down from a
  hang, the roof's edge with room to stand;
- no hold through a thin wall with a crate behind it;
- facing and reach limits, and a window between holds;
- a hold under a cornice, and nothing in a gap;
- a crate top, the same crate under a low shelf, and a lip too low to hang from.

`tests/scenarios/r67_climbing.gd` (scene `climb_demo.tscn`):
- running into the wall doesn't climb;
- jump and hold up climbs 2.2 → 3.4 → 4.6 → the edge → over it, in five moves;
- drop at the roof's edge hangs, and hold down climbs down to 2.2; drop lets go;
- a shimmy stops before a hold's end, and jump plus right crosses a 1.2 m gap;
- a sprint steps onto a crate and vaults a fence.
