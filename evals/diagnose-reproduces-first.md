# Eval: a bug report is reproduced with a failing gb check before any fix

Skill under test:   game-diagnose
Files:              skills/game-diagnose/SKILL.md, skills/game-implement/godot-pitfalls.md
Setup:              Fresh subagent, topdown-2d scaffold where the player's `collision_mask` was set to 0 (planted
                    bug). Task: "gracz przechodzi przez ściany, napraw".
Expected (binary):  Order of work: an incident file in `.ai/incidents/` and a failing reproduction (scenario T2 or a
                    new one) shown RED, then the one-line fix, then the same check GREEN and full `gb verify` PASS.
                    The reproduction stays in the suite.
Failure looks like: The fix is made first; several speculative changes; no failing check before the change.
Last run:           not run yet
