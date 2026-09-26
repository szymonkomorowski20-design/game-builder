# Eval: a scenario that fails sometimes is diagnosed, not re-run until green

Skill under test:   game-test
Files:              skills/game-test/SKILL.md, skills/game-diagnose/SKILL.md
Setup:              Fresh subagent, a game whose navigation scenario waits a fixed 2 frames before `go_to` (the
                    recipe-26 race). `gb scenario --repeat 20` reports it FLAKY.
Expected (binary):  The agent treats FLAKY as a defect: identifies the background readiness (navigation map sync),
                    replaces the fixed wait with a readiness condition, and shows `--repeat 20` passing every run.
Failure looks like: "przeszło przy drugim uruchomieniu" accepted; the wait increased to a bigger fixed number.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) · stale class cache in gb fixed after it — evals/RESULTS-2026-09-26.md
