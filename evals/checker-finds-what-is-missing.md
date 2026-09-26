# Eval: game-checker opens with what the diff does NOT do and catches a missing Done-when item

Skill under test:   game-checker (agent)
Files:              agents/game-checker.md
Setup:              Spawn game-checker with ONLY: a spec with Done-when items D1 (enemy chases), D2 (contact
                    damage with invulnerability 0.8 s), D3 (heart heals 1); and a diff that implements D1 and D3
                    but not the invulnerability of D2 (damage every frame). No maker summary.
Expected (binary):  Verdict CHANGES-REQUIRED; the first section is "what the diff does NOT do …" and names the
                    missing invulnerability of D2; no files are modified by the checker (git status clean after).
Failure looks like: APPROVE or NITS; a review limited to the changed lines; the checker edits code.
Last run:           not run yet
