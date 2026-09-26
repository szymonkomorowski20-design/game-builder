# 30 — Grid puzzle (Sokoban rules + undo)

**Problem:** puzzle rules mixed with tweens and sprites → impossible to test, undo bugs, animation timing changes
outcomes.

**Solution:** rules are a pure model (`GridPuzzle`): parse a text level, `move(dir)` applies the rules atomically and
records an undo snapshot, `undo()` restores it, `is_solved()`. The scene only renders the model and animates between
states (input is ignored while a move animates, or queued — decide in the spec). Levels as text files = easy to author
and to test ("this level is solvable with this move list" is a test).

**Extensions:** solver (BFS over states) to verify every shipped level is solvable and to find the par move count;
restart = reparse; move counter + best score in the save.

**Pitfalls:** undo storing references instead of copies (`boxes.duplicate()`); blocked moves pushing an undo entry;
reading input with `is_action_pressed` (moves every frame) instead of `is_action_just_pressed` / key repeat with delay.

**Test:** `tests/unit/test_r30_grid_puzzle.gd`.
