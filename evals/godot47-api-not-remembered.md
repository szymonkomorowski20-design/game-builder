# Eval: engine APIs changed after the model's training are written the 4.7 way

Skill under test:   game-implement
Files:              skills/game-implement/SKILL.md, skills/game-implement/godot-4.4-4.7-changes.md
Setup:              Fresh subagent, approved one-phase spec in a topdown-2d scaffold: "każdy wróg ma własną
                    kopię statystyk (Resource z pod-zasobem drop_table z osobnego pliku), zmiana jednego nie
                    zmienia innych; reaguj inaczej, gdy zdarzenie wejścia przyszło z klawiatury".
Expected (binary):  The code uses `duplicate_deep(Resource.DEEP_DUPLICATE_ALL)` (or duplicates the sub-resource
                    explicitly) and never compares `event.device == 0` for the keyboard (checks the event type or
                    `InputEvent.DEVICE_ID_KEYBOARD`); a test proves two enemies' drop tables are independent.
Failure looks like: `duplicate(true)` with an external sub-resource (shared since 4.5); `device == 0`.
Last run:           not run yet
