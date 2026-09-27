# Agents Guidelines — game-builder (the plugin itself)

This repo is the **framework**, not a game. It ships skills, hooks, templates and the `gb` verification
tool that game repos use. Modelled on the Sailes app-builder; the same discipline applies to changing it.

## Layout
| Path | What |
|---|---|
| `skills/<name>/SKILL.md` (+ reference files) | the pipeline: game-start, game-discovery, game-bootstrap (more per ROADMAP.md) |
| `hooks/` | SessionStart: `session-router.js` (routes from repo state), `version-check.js`; shared `lib/game-repo.js` |
| `tools/gb/` | `gb.js` verification CLI (copied into every game repo), `check_all.gd`, `setup_input.gd`, `scaffold.js` (plugin-only) |
| `templates/` | what `gb scaffold` writes into a game repo (AGENTS.md template, `.ai/`, `.claude/`) |
| `tests/` | `node --test` suite; integration tests run the real Godot (skipped without it) |
| `evals/` | behaviour scenarios for the skills (see evals/README.md) |
| `ROADMAP.md` | stages 1–8 and the complete checklist; the source of truth for what exists |

## Rules for changing the framework
- **Test first.** A change to `gb`, hooks or scaffold comes with a test that fails before it. `npm test` must be green (paste the summary).
- **Measure Godot, do not assume it.** Engine behaviour claims in skills/docs are checked against the installed Godot or the docs in the knowledge base, with the date.
- **One source for repeated literals.** The spine line lives in `hooks/session-router.js` and `templates/repo/AGENTS.md.tmpl`; a test keeps them identical.
- **Versioning.** Behaviour change → bump `VERSION`, `.claude-plugin/plugin.json`, `.claude-plugin/marketplace.json`, `package.json` together (a test checks) and add a `CHANGELOG.md` entry `## x.y.z — YYYY-MM-DD · title` (the version-check hook reads these headings).
- **Skills stay thin at the entry point.** Methods and tables go into sibling reference files the SKILL.md points to.
- **Evals.** Editing a skill → re-run the evals that name it; record `Last run:` honestly (stand-in vs real run).
- Skill bodies are English (model-facing); user-facing prompts and generated READMEs are Polish.

## Commands
- `npm test` — whole suite (≈ 1 min with Godot installed)
- `node tools/gb/gb.js scaffold --dir <tmp> --name Demo --dim 2d --pixel-art` — generate a demo game repo
- `node tools/gb/gb.js verify --path <project>` — verify any Godot project
