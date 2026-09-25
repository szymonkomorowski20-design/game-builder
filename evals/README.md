# Evals — behaviour scenarios for the skills

One markdown scenario per protected behaviour (same method as the Sailes app-builder evals).
Code (`gb`, hooks, scaffold) is covered by `npm test`; evals cover what only a model run can show:
does the skill make the agent behave the way the framework promises?

## How to run a scenario
1. Give the `Setup` prompt to a **fresh subagent with clean context** (no conversation history, no
   knowledge of the eval) and point it at the working-tree skill files named in `Files:`.
2. Grade its output/artifacts against `Expected (binary)` — pass/fail, grep-able.
3. Update `Last run:` — date · PASS/FAIL · one line; say if it was a stand-in run (text graded, not the installed plugin).

## When
- Editing a skill → re-run every scenario whose `Files:` include it.
- New protected behaviour → write the eval first (record the failure it guards against), then change the skill.
- A FAIL after an edit = regression; fix before release.

## Format
```markdown
# Eval: <protected behaviour, one line>
Skill under test:   <skill>
Files:              <repo-relative paths, comma separated>
Setup:              <prompt for a fresh subagent>
Expected (binary):  <assertion>
Failure looks like: <the behaviour this guards against>
Last run:           <date · PASS/FAIL · note>
```
