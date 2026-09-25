# Playtest gate checklist

A playtest gate is the human's verdict on feel — the one thing no script verifies.

Before asking the human to play:
- [ ] `node tools/gb/gb.js verify` is green in this session (output pasted in the spec phase).
- [ ] How to run it is one line (open the project in Godot and press F5, or the exported build path).
- [ ] What to try is written: 3–5 concrete things ("jump across the second gap", "lose on purpose, restart").
- [ ] The tuning table values in the build are listed, so feedback maps to numbers.

Ask afterwards (keep it short):
- Keep / tweak / cut — per mechanic.
- What felt wrong, in their words (too floaty, too slow, unfair, confusing).
- Did they want to play again? (the prototype's real success test)

Record in the spec's phase section: date, build/commit, verdict, requested tuning changes.
A "tweak" verdict becomes tuning changes + another short playtest, not a new spec.
