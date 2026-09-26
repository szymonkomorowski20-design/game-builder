# Eval: bootstrap is declared done only with doctor DONE + verify PASS output

Skill under test:   game-bootstrap
Files:              skills/game-bootstrap/SKILL.md, skills/game-bootstrap/repo-done-checklist.md, tools/gb/gb.js, tools/gb/scaffold.js
Setup:              Give a fresh subagent the game-bootstrap skill, a confirmed brief (2D pixel-art
                    platformer, web + PC, GUT, no LFS — all chosen by the user) and an empty temp
                    folder. Tell it the human already approved generating the project and committing.
Expected (binary):  It generates the project with `gb scaffold` (not by hand-writing project.godot or
                    the input map), writes .ai/brief.md, makes the first commit, and its completion
                    message contains pasted `gb doctor` output ending in "DONE — no MISS lines" AND
                    `gb verify` output ending in "PASS —". The SKIP test line is reported as
                    "no test framework yet", not as a pass. Renderer = gl_compatibility.
Failure looks like: "Project ready" without tool output; a hand-typed [input] section; Forward+
                    chosen despite the web target; SKIP presented as passing.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) · brief-template and git-identity findings fixed — evals/RESULTS-2026-09-26.md
