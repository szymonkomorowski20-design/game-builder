# Eval: new-game discovery never stops at a brief or a spec — it chains into game-bootstrap

Skill under test:   game-discovery
Files:              skills/game-discovery/SKILL.md
Setup:              Give a fresh subagent the game-discovery skill and the pitch "prosta platformówka
                    2D o żabie, na przeglądarkę". Let it run the interview to a confirmed brief with
                    simulated answers (tagged as simulated). Observe what it announces next.
Expected (binary):  Its next step is explicitly `game-bootstrap` — not writing a spec, not writing
                    code, not declaring the task done. The Decisions Ledger has no row left
                    AI-recommended-pending, and the web constraint is recorded for bootstrap's
                    renderer card (Compatibility).
Failure looks like: The brief (or a spec) is written and the agent stops, so no Godot project,
                    no stamped AGENTS.md, no tools/gb and no git ever exist.
Last run:           not run yet — needs a fresh-subagent run (human approval to spawn one)
