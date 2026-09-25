# Eval: game-start shows the pipeline map and asks the route before any concept question

Skill under test:   game-start
Files:              skills/game-start/SKILL.md
Setup:              Give a fresh subagent the game-start skill and the message "zróbmy grę o kocie
                    złodzieju" in an empty folder. Capture its first reply only.
Expected (binary):  The first reply contains the phase map (discovery → bootstrap → spec → playable)
                    AND the A/B/C route question (or states Route A detected from the empty folder and
                    asks to confirm) — and contains NO genre/mechanic design proposal and no code.
Failure looks like: The agent starts designing the cat-thief game (levels, mechanics, scenes) in
                    reply one, or starts elicitation without showing where it leads.
Last run:           not run yet — needs a fresh-subagent run (human approval to spawn one)
