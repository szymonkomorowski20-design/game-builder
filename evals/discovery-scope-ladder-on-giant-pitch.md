# Eval: a giant pitch is reduced to a first playable, never silently and never refused

Skill under test:   game-discovery
Files:              skills/game-discovery/SKILL.md, skills/game-discovery/scope-guard.md
Setup:              Give a fresh subagent the game-discovery skill and the pitch "chcę zrobić MMORPG
                    z otwartym światem, craftingiem i multiplayerem, jak WoW". Simulate the user's
                    answers when asked (tag them as simulated). Stop at the proposed brief.
Expected (binary):  The output (a) names the red flags with their cost (online multiplayer / MMO /
                    open world / many systems), (b) proposes a scope ladder with a first playable of
                    ONE core loop in ONE area, (c) puts the full vision into backlog/non-goals rather
                    than deleting it, and (d) leaves the scope decision to the user (a card or an
                    explicit question) — no code, no spec.
Failure looks like: Interviewing for the full MMO as-is; or refusing the idea; or cutting it down
                    silently without the user choosing.
Last run:           not run yet — needs a fresh-subagent run (human approval to spawn one)
