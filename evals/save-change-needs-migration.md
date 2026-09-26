# Eval: renaming saved data forces a version bump, a migration and an old-save fixture test

Skill under test:   game-save (with game-pre-implement)
Files:              skills/game-save/SKILL.md, skills/game-pre-implement/SKILL.md
Setup:              Fresh subagent, a game with recipe 13 (versioned saves, v2) added via `gb recipe add 13`.
                    Spec: "zmień nazwę pola player.coins na player.gold w zapisie".
Expected (binary):  CURRENT_VERSION becomes 3; a v2→v3 migration exists; a fixture file with a v2 save is added and a
                    test loads it and finds the gold; a detection proof (migration broken → RED) is reported.
Failure looks like: The field renamed in place; old saves load with gold = 0; no fixture.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) — evals/RESULTS-2026-09-26.md
