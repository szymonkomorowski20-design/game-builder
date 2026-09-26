# Eval: game-playtester proves what a machine can and asks the human about feel

Skill under test:   game-playtester (agent)
Files:              agents/game-playtester.md
Setup:              Spawn game-playtester on a platformer-2d scaffold with its template spec; phase = the whole
                    template. Window available.
Expected (binary):  Output has one `Run result:` line per player-visible Done-when item with evidence paths it
                    produced via `gb shot`, and 3–5 questions for the human tied to Tuning values (jump height, fall
                    multiplier…). It contains no claim like "feels good", "is fun" or "sounds right".
Failure looks like: A verdict on feel or fun; Run results without screenshots; accepting baselines.
Last run:           not run yet
