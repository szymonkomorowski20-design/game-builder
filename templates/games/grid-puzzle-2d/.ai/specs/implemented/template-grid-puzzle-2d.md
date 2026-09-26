# Template — grid push-box puzzle starter
Status: implemented — evidence: game-builder template tests (tests/unit/test_puzzle_rules.gd, tests/scenarios/g*.gd) green under `gb verify` at scaffold time; detection proven (held key moving every frame → G1 red); the solvability test caught an unsolvable level during development
Ladder rung: toy + first-playable loop (3 levels → win)

## Goal
A tested starting point for turn-based grid puzzles (Sokoban-likes, block pushers, tile puzzles): rules as a pure
model with undo, levels as data, a solver that proves every level solvable and gives its par, and input that moves
exactly one cell per press.

## Design
- `GridPuzzle` (`scripts/puzzle/grid_puzzle.gd`): parse text rows (`#` wall, `@` player, `$` box, `.` goal, `*`
  box on goal, `+` player on goal), `move(dir)` (push, blocked moves change nothing), `undo()`, `is_solved()`,
  `solve(rows)` — BFS over (player, boxes), shortest solution or `[]`.
- `LevelSet` (`data/levels.tres`): levels as strings inside a Resource so they ship with the export (plain `.txt`
  files would be dropped by the export filter).
- Board (`scenes/board.tscn`, `scripts/puzzle/board.gd`): single step per `move_*` press, `action` undo, `jump`
  restart, next level after `next_level_delay`, win after the last level (`jump` starts over); draws the grid with
  `_draw()`. Observable: `level_index`, `puzzle`, `levels_solved`, `won`, `score`.

## Tuning table
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| tile | 32 | px | board.gd `@export` | 16–48 |
| next_level_delay | 0.5 | s | board.gd `@export` | 0.2–1.5 |
| levels | 3 | levels | data/levels.tres | — |
| par (per level) | 3 / 7 / 9 | moves | computed by the solver; pinned in `test_puzzle_rules.gd` | — |

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| G1 | One press = one cell; holding does not repeat; walls block and aren't counted | `g1_single_step.gd` |
| G2 | Undo restores the last move incl. a push; restart resets the level | `g2_undo_restart.gd` |
| G3 | Solving a level (solver's solution as real key taps) loads the next one | `g3_level_advance.gd` |
| G4 | Solving every level wins (screenshot at the end) | `g4_win.gd` |
| — | Rules, undo, every level solvable within its par, unsolvable detection | `tests/unit/test_puzzle_rules.gd` |

## Adding levels
Add a string to `data/levels.tres`, run `gb test` — the solvability test fails until the new level is solvable, and
tells you its par; add the par to `PAR`. Keep levels small (the BFS solver explores every state).

## Next steps
Key repeat with a delay (hold to walk after 0.3 s), move animation (tween between cells, input queued while
animating), level select + best moves saved (recipe 13), sounds (recipe 35).
