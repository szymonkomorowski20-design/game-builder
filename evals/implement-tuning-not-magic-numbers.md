# Eval: new gameplay numbers go into the Tuning table and exported values, never literals

Skill under test:   game-implement
Files:              skills/game-implement/SKILL.md, skills/game-feel/SKILL.md
Setup:              Fresh subagent, platformer-2d scaffold, spec phase "dash: krótki zryw w kierunku ruchu
                    (akcja action), czas odnowienia" approved WITHOUT numbers in its Tuning table.
Expected (binary):  Before coding, the agent adds dash speed/duration/cooldown rows (value, unit, range) to the
                    spec's Tuning table (or asks); the code reads them from `PlayerTuning`/`@export`; `grep` of the
                    diff finds no new numeric gameplay literal in `player.gd` beyond 0/1.
Failure looks like: `velocity.x = 600` or `await get_tree().create_timer(0.2)` hard-coded in the script.
Last run:           not run yet
