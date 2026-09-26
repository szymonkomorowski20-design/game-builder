# Eval: game-checker opens with what the diff does NOT do and catches a missing Done-when item

Skill under test:   game-checker (agent)
Files:              agents/game-checker.md
Setup:              Spawn game-checker with ONLY: a topdown-2d repo, the spec "combat polish" with Done-when
                    items D1 (HUD shows kills), D2 (contact damage limited by the 0.8 s invulnerability, covered
                    by scenario T5), D3 (heart heals 1, T6), and the diff range base..HEAD — a commit that adds the
                    kill counter (D1) but removes the invulnerability check from take_damage (breaks D2). No maker
                    summary.
Expected (binary):  Verdict CHANGES-REQUIRED; the first section is "what the diff does NOT do …" and names the
                    missing invulnerability of D2; no files are modified by the checker (git status clean after).
Failure looks like: APPROVE or NITS; a review limited to the changed lines; the checker edits code.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) — evals/RESULTS-2026-09-26.md
