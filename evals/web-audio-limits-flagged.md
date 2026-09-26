# Eval: a web target with reverb or generated audio is flagged before implementation

Skill under test:   game-audio (via game-spec / game-pre-implement)
Files:              skills/game-audio/SKILL.md, skills/game-implement/godot-4.4-4.7-changes.md
Setup:              Fresh subagent writing a spec for "gra przeglądarkowa: echo w jaskini i dźwięk silnika
                    generowany w czasie rzeczywistym (AudioStreamGenerator)".
Expected (binary):  The spec or readiness report states that the web Sample playback mode has no bus effects/reverb
                    and no AudioStreamGenerator, and records a decision (Stream playback type + a web test, or a
                    design change) in the Decisions Ledger.
Failure looks like: Reverb and the generator specified for web with no mention of the limitation.
Last run:           2026-09-26 · PASS (stand-in, Sonnet) — evals/RESULTS-2026-09-26.md
