# Case C — adopting an existing Godot project

A running game that was built without this workflow. **Adopt, never rewrite**: the methodology is
added around the game; not one scene, script or asset of the game changes during adoption.

## Procedure
1. **Baseline the game as it is** — before touching anything:
   `node <plugin>/tools/gb/gb.js verify --path <project>` and save the output. Existing errors are
   the game's current state, not something adoption fixes; they go to `.ai/incidents/` or the backlog.
2. **Read the project**: `project.godot` (engine version, main scene, autoloads, input map, renderer),
   the folder layout, existing README/docs/AGENTS.md (another workflow's AGENTS.md is kept as-is and
   referenced), test addons, export presets. Note the real conventions (naming, where scripts live).
   If git tracks `.godot/` (the engine's cache), report it and propose `git rm -r --cached .godot` as a
   separate commit the human approves — do not fold cache churn into the adoption commit.
3. **Scaffold additively**: `node <plugin>/tools/gb/gb.js scaffold --dir <project> --adopt --name "<title>"`.
   Adopt mode never generates game files (no placeholder scene) and never overwrites anything — every
   existing file is KEPT. Input actions are added only when missing, never changed.
4. **Existing AGENTS.md** (e.g. from another workflow) is KEPT; add a short section at its top with the
   `> Game-Builder-Version: x.y.z` stamp and the spine line, or — if the human prefers — merge the
   generated template into it by hand. The stamp is what activates the game-builder session router.
5. **Existing `.claude/settings.json`** is KEPT: merge the game-builder entries (permissions allow
   `node tools/gb/gb.js:*`, the two hooks, `enabledPlugins` Sailes off) by hand and show the diff.
6. **Document the real setup** in `ADR-001` (generated as a starting point — correct it to the facts
   read in step 2) and write `.ai/brief.md` from the light discovery: what the game is today, what
   the human wants next.
7. **Prove nothing broke**: `gb verify` again — the result must be the same as the baseline (same
   passes; pre-existing failures unchanged and recorded). Then `gb doctor`. A project without
   `export_presets.cfg` stays one MISS: adoption never creates presets, because the target platforms
   (and, for the web, the Compatibility renderer) are the human's decision — ask with a card, or record
   it in the backlog and say so in the completion message. Any other MISS is adoption's job to clear.
8. Commit only with the human's go-ahead: `chore: adopt game-builder <version> (no gameplay changes)`.
   If git has no author identity, ask the human for one — never borrow it from another repository.

## Never during adoption
Rename/move files · reformat scripts · "fix" warnings · upgrade the engine version · change the input
map · delete old docs. Each of those is a separate, spec'd change the human asks for.
