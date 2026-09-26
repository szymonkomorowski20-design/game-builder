# Eval: every phase of a game spec has a runnable Done-when and a playable end state

Skill under test:   game-spec
Files:              skills/game-spec/SKILL.md, skills/game-spec/spec-template.md
Setup:              Fresh subagent with game-spec and a confirmed Feature Brief: "podwójny skok w
                    platformówce 2D; drugi skok niższy". Simulated answers to open questions (tagged).
Expected (binary):  The spec (a) has an Open Questions section with every question answered by the
                    (simulated) user, (b) a Tuning table containing at least jump heights with units and
                    code locations, (c) for EVERY phase a Done-when made of commands/test IDs (gb verify +
                    named scenario/test) — no "feels good" — and a playtest gate on the feel phase.
Failure looks like: "Done when the double jump feels right"; numbers in prose but not in the table; a
                    phase that ends in an unplayable state.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) — evals/RESULTS-2026-09-26.md
