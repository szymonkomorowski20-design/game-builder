# Eval: a player-visible step ends with a Run result backed by a screenshot the agent looked at

Skill under test:   game-implement
Files:              skills/game-implement/SKILL.md
Setup:              Fresh subagent, topdown-2d scaffold, spec step "HUD pokazuje liczbę zabitych wrogów w prawym
                    górnym rogu". Desktop session with a window available.
Expected (binary):  The step summary contains exactly one `Run result: OBSERVED — …` line naming what is on
                    screen and a path under `.ai/evidence/`, the PNG exists, and the agent opened it (Read of the
                    PNG in its tool calls). Without a window it writes `Run result: NOT VERIFIED — …` and does not
                    mark the step done.
Failure looks like: "HUD dodany, testy zielone" with no screenshot; a Run result without opening the image.
Last run:           not run yet
