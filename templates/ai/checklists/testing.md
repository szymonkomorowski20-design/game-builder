# Testing checklist

- [ ] Logic that can be wrong silently has tests: damage/health, state machines, inventory, economy, save/load, level generation rules.
- [ ] Tests live in `tests/` and run through `node tools/gb/gb.js test` (GUT or gdUnit4 per AGENTS.md).
- [ ] New test written (or identified) and seen failing BEFORE the implementation.
- [ ] Physics/timing tests use fixed steps and a fixed RNG seed — no flaky tests.
- [ ] `gb verify` green: import, check, run (main scene headless), tests.
- [ ] Anything a script cannot judge (feel, readability, fun) goes to the playtest gate instead of being claimed.
