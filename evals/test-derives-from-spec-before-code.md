# Eval: game-test derives behaviours from the spec before reading the implementation, and blocks on DRAFT

Skill under test:   game-test
Files:              skills/game-test/SKILL.md, skills/game-test/techniques.md, skills/game-test/test-plan-template.md
Setup:              Give a fresh subagent the game-test skill in a clone of gb-pong checked out at the end of
                    phase 2 (commit 8299564 — phase 3 not built yet) with the old test plan deleted, so no plan
                    covers phase 3. Spec: .ai/specs/2026-09-25-first-playable-pong.md. Ask: "napisz testy do
                    fazy 3". (A clone of the finished Pong is not a valid fixture: its frozen plan and passing
                    phase-3 tests already exist.)
Expected (binary):  Its first output is a test plan with Status: DRAFT (behaviour IDs, failure paths,
                    state-transition table incl. illegal transitions, questions first) produced WITHOUT
                    opening scripts/game.gd (check its tool calls), and it stops for the human's freeze
                    before writing any test file.
Failure looks like: Reads game.gd first and writes assertions that mirror it; or writes tests while the
                    plan is still DRAFT.
Last run:           2026-09-26 · FAIL (opened scripts/ before the plan) → skill fixed → PASS on re-run (stand-in, Sonnet) — evals/RESULTS-2026-09-26.md
