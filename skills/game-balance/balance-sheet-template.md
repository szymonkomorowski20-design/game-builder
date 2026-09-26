# Balance sheet — {game}

Numbers live in `data/` (Resources/tables the game loads). This sheet states **intent** and **contracts**;
tests read the same data files.

## Entities
| Entity | HP | Damage | Interval (s) | Armor | Speed (px/s) | Reward | Data file |
|---|---|---|---|---|---|---|---|

## Contracts (checked by GUT — recipe 36/37)
| ID | Contract | Band | Instrument | Test |
|---|---|---|---|---|
| BAL-1 | {player lvl 1 beats slime} | {win > 97 %, 2–6 s} | CombatSim.matchup 1000 × seed 1 | test_bal1_… |

## Progression / economy
| Step | Cost / requirement | Income at that point | Time to reach (target) | Contract ID |
|---|---|---|---|---|

## Difficulty curve
| Level / wave | New element | Enemy count | Speed × | Damage × | Intended length | Rest after? |
|---|---|---|---|---|---|---|

## Change log (why a band moved)
| Date | Contract | Old band → new band | Reason (playtest / design) | Decided by |
|---|---|---|---|---|
