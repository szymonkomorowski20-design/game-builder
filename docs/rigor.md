# Process weight — standard, light or autonomous

A game repo runs one of two process weights, set in its `AGENTS.md` (`- Process: standard` or `- Process:
light`). The session router reads it at every session start and after every context reset, and prints the matching
pipeline. **The human chooses it** at bootstrap (a decision card in `game-bootstrap/decision-engine.md`) and may
change it later. Record the change in the Decisions Ledger. Standard is the default and matches the behaviour of
every earlier release.

**Why a light mode exists:** Claude Code Game Studios (MIT, in the gry-wiedza library, fala 05) measured its heavier
process tier as several times more expensive to reach working code, without a better result. It then made its
lightest tier the default (`.claude/docs/config-resolution.md`, "Defaults"). Our standard mode is already lean on
roles. Even so, every phase spawns a checker and a playtester, and every non-trivial spec gets a readiness report.
For a jam game, a toy or a learning project that is overhead. **Our own cost comparison hasn't been measured yet**:
an eval run of the same briefs in both modes is on the roadmap.

## Never relaxed (all modes)
The spine: **SPEC → HUMAN → VERIFIED → PLAYABLE → GATED**.
- A spec on disk, approved by the human, before gameplay code (light allows the short form below).
- The human owns every key decision: the decision cards stay.
- `gb verify` green, with the output shown. `Run result` lines carry evidence paths, and shots are looked at, not
  just taken.
- Every phase ends in a build the human can run.
- The human plays at the gates. Feel is theirs to judge.
- Commits only on the human's word. Licences registered in the same commit. Paid generators ask first. All safety
  rules stay.

## What light changes
| Step | Standard | Light |
|---|---|---|
| Brief (`game-discovery`) | full Game Brief | the same for a new game (it is written before this choice is made at bootstrap); later features: a short Feature Brief |
| Spec (`game-spec`) | full template, as many small phases as needed | **short spec**: goal, non-goals, Tuning table, Done-when list (commands + expected results), tests per Done-when; at most 2 phases |
| Readiness (`game-pre-implement`) | every non-trivial spec | only when the spec touches saved data, autoloads, input action names or scenes other specs use |
| Tests (`game-test`) | the `game-tester` agent writes them from the spec before seeing code; the plan is frozen with the human | the implementer writes them from the spec **first** and shows them red. The plan goes to the human in one message, not a separate freeze step |
| Review (`game-checker`) | at every phase gate | **once per spec**, before the human's last gate (still a fresh agent that sees only the diff, the spec and the test plan) |
| Machine playtest (`game-playtester`) | an agent at every phase | the implementer's own `Run result`: `gb shot`/`--movie`, open and look at the images, one line per Done-when |
| Human gate | every phase the spec marks | at least at the end of the spec, plus any phase the human asks for |
| Replays (`gb record`) | after feel gates | optional |
| Paper trail | run log + STATUS.md per phase, STATE.md | one STATUS.md line per phase; STATE.md at session end |

## What autonomous changes
The human chose to **play only the finished game**. Use it for proof games, jams the human wants to see only at
the end, or when the human says "zrób sam". It is the most relaxed mode, so the machine gates carry more weight.

| Step | Autonomous |
|---|---|
| Discovery | The human gives the pitch (and genre). You answer the rest yourself: each decision card's **recommended** option, informed by `gb doc genre-*` when the genre has one. Every decision goes into the Decisions Ledger with **By: bot**, the reason and the alternatives. |
| Bootstrap | The same cards and the same recording. Prefer a genre template when one exists (e.g. `action-roguelite-3d`). |
| Spec | The full spec, **approved by an independent `game-checker` review against the brief** (a fresh agent, the spec and the brief only). CHANGES-REQUIRED means fix it and review again. |
| Implement | Every phase ends playable. The gates are machine gates: `gb verify` green; `game-checker` on the phase diff; `game-playtester` runs it and **looks** at shots/audio; plus a **completability scenario**, where a simple bot finishes the game or the level (template A8, recipe 37). Feel parameters stay in the Tuning table for the human's pass. |
| Commits | Only on the human's word (their standing rule). Keep a snapshot per phase with `git write-tree` and list the ids in STATUS.md, then commit at the end when the human says so. |
| Paid assets | Never without the human's yes for that batch. Use free packs (`gb doc starter-packs`), or placeholders marked as such. |
| The end | STATUS.md gets a human-gate checklist: how to run the game, 3–5 things to try, the Tuning values, and the Decisions Ledger to review. **The human plays the finished game**; every bot decision can be overturned. |

## When to recommend which
- **Light:**
  - a jam or a deadline under a week;
  - a toy or prototype to test one idea;
  - a learning project;
  - a single-mechanic experiment that may be thrown away.
- **Standard:**
  - a game meant for players or a release;
  - anything with saves, multiplayer or several people working on it;
  - an adopted existing game;
  - a project that will live for months.
- **Autonomous:** only when the human asks for it ("zrób sam", "prawie bez bramek"), e.g. a proof game or a
  first draft to react to. Never pick it for them.
- **Suggest switching light → standard** when:
  - the game gets saves;
  - a release gets planned;
  - a second person joins;
  - the end-of-spec checker returns CHANGES-REQUIRED twice in a row (the review came too late to be cheap).

  Switching is the human's call; you raise it once, with the reason.

## How skills read it
Each pipeline skill checks `AGENTS.md` (`- Process:`). A missing line means standard (repos from before 0.17.0). An
unknown value also means standard, and the router says so. The router's PROCESS line is the reminder after a
context reset.
