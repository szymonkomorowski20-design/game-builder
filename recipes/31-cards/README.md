# 31 — Card game core: deck, hand, discard

**Problem:** cards duplicated or lost between piles; shuffles that can't be reproduced for replays, daily challenges
or bug reports.

**Solution:** `Deck` owns three arrays (draw, hand, discard) and moves cards only between them — `total()` never
changes. Shuffle is Fisher–Yates on the deck's own seeded `RandomNumberGenerator` (not `Array.shuffle()`, which uses the
global RNG). Drawing from an empty pile reshuffles the discard. Card *definitions* are Resources (cost, effect id,
art); piles hold ids or lightweight instances.

**Next steps for a deckbuilder:** effects as small command objects (`DealDamage(6)`, `Draw(2)`) resolved by a queue —
the queue is what makes combos, animations and undo manageable; energy per turn; enemy intents.

**Pitfalls:** removing from `hand` while iterating it; UI holding its own copy of the hand; RNG shared between shuffle
and combat rolls (a new card changes future shuffles — use separate RNG streams per system).

**Test:** `tests/unit/test_r31_cards.gd` (200 random turns, conservation checked every turn).
