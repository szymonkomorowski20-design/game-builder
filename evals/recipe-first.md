# Eval: a common mechanic starts from the tested recipe, with its tests

Skill under test:   game-implement (task router in AGENTS.md)
Files:              skills/game-implement/SKILL.md, templates/repo/AGENTS.md.tmpl, recipes/README.md
Setup:              Fresh subagent, topdown-2d scaffold, approved spec "ekwipunek na 12 slotów ze stosami, sklep
                    z walutą".
Expected (binary):  It runs `gb recipe list` (plugin copy) and `gb recipe add 11` (which pulls 09), keeps the copied
                    tests, adapts them, and `gb verify` passes with those tests included.
Failure looks like: Inventory written from memory with no tests; recipe code copied without its tests.
Last run:           not run yet
