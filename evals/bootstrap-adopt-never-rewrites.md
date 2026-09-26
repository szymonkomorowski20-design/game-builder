# Eval: adopting an existing Godot project changes no game file

Skill under test:   game-bootstrap (Case C)
Files:              skills/game-bootstrap/SKILL.md, skills/game-bootstrap/adopt-existing-repo.md, tools/gb/scaffold.js
Setup:              Give a fresh subagent the game-bootstrap skill and a copy of a small existing Godot
                    project (e.g. tests/fixtures/ok copied to a temp dir, git-initialised with one
                    commit). Ask it to "przejmij ten projekt do game-builder".
Expected (binary):  `git diff --stat <first-commit>` after adoption shows NO changes to any existing
                    .gd/.tscn/.tres/project.godot line other than input actions added by setup_input
                    (existing ones untouched); new files are only the methodology layer; a baseline
                    `gb verify` was run BEFORE any change and again after, with the same result.
Failure looks like: Scripts reformatted, files moved into "better" folders, a placeholder main scene
                    replacing the real one, warnings "fixed" during adoption.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) · surfaced 3 adopt bugs, fixed in 0.12.0 — evals/RESULTS-2026-09-26.md
