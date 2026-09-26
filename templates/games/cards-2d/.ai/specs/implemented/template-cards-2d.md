# Template — card combat starter (deckbuilder-style)
Status: implemented — evidence: game-builder template tests (tests/unit/test_combat.gd, tests/scenarios/c*.gd) green under `gb verify` at scaffold time; detection proven (block not absorbing → unit red; energy not spent → unit + C1 + C3 red); screenshot looked at (selection marked by a symbol, not only colour)
Ladder rung: toy + first-playable loop (one fight: win or lose, restart)

## Goal
A tested starting point for card games: a seeded deck, a hand, energy per turn, cards as data, an enemy with a
visible intent, block, and a win/lose loop — rules as a pure model (`Combat`) so balance and new cards are
testable without the UI.

## Design
- `Deck` (`scripts/cards/deck.gd`, recipe 31): draw/hand/discard, reshuffle when empty, seeded Fisher–Yates, cards
  conserved.
- `CardSet` (`data/cards.tres`): card id → name, cost, damage, block; the starting deck (5 Cios, 4 Obrona, 1 Grzmot).
- `CombatTuning` (`data/combat_tuning.tres`): player HP, energy per turn, hand size, enemy HP, enemy intents
  (cycling), deck seed.
- `Combat` (`scripts/cards/combat.gd`): `play(i)` (cost ≤ energy, damage, block; win at enemy 0 HP), `end_turn()`
  (enemy hits for its intent minus block, discard, new turn: energy refilled, block reset, draw), `ended(won)`.
- View (`scenes/combat.tscn`, `scripts/cards/combat_view.gd`): labels, the hand as buttons (disabled when
  unaffordable, selected card marked with ▶), `move_left/right` select, `action` plays, `jump` ends the turn,
  mouse click plays / button ends the turn, `pause` restarts after the fight. Observable: `combat`, `selected`, `score`.

## Tuning table (data/combat_tuning.tres, data/cards.tres)
| Parameter | Value | Unit | Where | Range to try |
|---|---|---|---|---|
| player_hp | 40 | HP | CombatTuning | 30–80 |
| energy_per_turn | 3 | energy | CombatTuning | 2–4 |
| hand_size | 5 | cards | CombatTuning | 4–7 |
| enemy_hp | 30 | HP | CombatTuning | — |
| enemy_intents | 6, 8, 12 | damage/turn | CombatTuning | — |
| seed_value | 7 | — | CombatTuning | — |
| Cios | cost 1, 6 dmg | — | cards.tres | — |
| Obrona | cost 1, 5 block | — | cards.tres | — |
| Grzmot | cost 2, 10 dmg | — | cards.tres | — |
| Balance contract | greedy play wins within 5 turns | — | `test_greedy_play_wins_the_default_fight` | move the band only with a playtest |

## Behaviours (test IDs)
| ID | Behaviour | Test |
|---|---|---|
| C1 | move_right selects the next card; action plays it; energy/enemy HP change by the card's data | `c1_select_and_play.gd` |
| C2 | jump ends the turn: enemy attack minus block, new hand, full energy, next intent shown | `c2_end_turn.gd` |
| C3 | Without energy, playing shows "Za mało energii" and changes nothing | `c3_no_energy.gd` |
| C4 | The whole fight played through input only is won; win message (screenshot) | `c4_win.gd` |
| — | Energy, cost, block, intents cycle, card conservation, lose, determinism, greedy-win contract | `tests/unit/test_combat.gd` |

## Next steps
More cards as data (draw, energy gain, poison) — each effect a small command resolved by the model and a unit
test; several enemies and target selection; rewards between fights (pick 1 of 3 cards, seeded); a map; saves
(recipe 13); card art through the asset register; sounds (recipe 35).
