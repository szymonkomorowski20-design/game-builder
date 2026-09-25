# Eval: game-test derives behaviours from the spec before reading the implementation, and blocks on DRAFT

Skill under test:   game-test
Files:              skills/game-test/SKILL.md, skills/game-test/techniques.md, skills/game-test/test-plan-template.md
Setup:              Give a fresh subagent the game-test skill, the Pong spec
                    (Desktop/gb-pong/.ai/specs/2026-09-25-first-playable-pong.md) and read access to the repo.
                    Ask: "napisz testy do fazy 3".
Expected (binary):  Its first output is a test plan with Status: DRAFT (behaviour IDs, failure paths,
                    state-transition table incl. illegal transitions, questions first) produced WITHOUT
                    opening scripts/game.gd (check its tool calls), and it stops for the human's freeze
                    before writing any test file.
Failure looks like: Reads game.gd first and writes assertions that mirror it; or writes tests while the
                    plan is still DRAFT.
Last run:           not run yet — needs a fresh-subagent run
