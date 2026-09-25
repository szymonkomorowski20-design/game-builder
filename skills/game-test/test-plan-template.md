# Test plan template

File: `.ai/test-plans/{spec-file-name}.md`

```markdown
# Test plan: {spec title}
Status: DRAFT | FROZEN (by: user, date)
Spec: .ai/specs/{…}.md · Phase(s): …

## Questions for the human (what the spec does not decide)
1. {question} — options: A) … B) … — recommendation: …

## Behaviours
| ID | Behaviour (from the spec) | Tier | Instrument | Failure path covered |
|---|---|---|---|---|
| B1 | … | B | scenario `tests/scenarios/….gd` | … |
| B2 | … | A | unit `test_b2_…` | … |

## State transitions (incl. illegal)
| From \ Input | … |
|---|---|

## Not covered by scripts (human playtest)
- feel of …, readability of …

## Detection proof (filled after writing)
- B1: broke … → red → reverted → green
```
