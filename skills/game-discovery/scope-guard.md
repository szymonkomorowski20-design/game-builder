# Scope guard — the scope ladder and the red-flag list

Most games are never finished, and the cause is almost never bad code: it is scope. This file is
how discovery turns a pitch into a **first playable** that can actually be built, played and judged.
It is not a way to refuse ideas — the big version goes to `.ai/backlog.md` as the destination. It
decides the *order* in which the game gets built, and the human still decides.

## The scope ladder

Walk it top to bottom with the user; each rung is a buildable, playable milestone. The first
rung that is not yet proven is where the first spec starts.

1. **Toy** — movement + the one core interaction, grey boxes, no goal. Proves: is the verb fun to do?
   (A platformer: run + jump feel right. A tower defence: placing a tower and seeing it shoot.)
2. **First playable (prototype)** — the core loop closed once: a goal, a fail state, a restart.
   One arena/level, one enemy/obstacle type, placeholder art, no menus beyond "restart".
   Proves: does the loop hold for 3 minutes?
3. **Vertical slice** — one level at intended quality: final-ish art for that level, sound, juice,
   UI, save if the game needs it. Proves: the game can look and feel like the vision.
4. **Content** — more levels/enemies/items using systems that already exist. No new systems.
5. **Polish & release** — menus, settings, accessibility, performance, export, store page.

Rules:
- A new game's first spec is rung 1 or 2. Never 3+.
- Every rung ends in a build the human plays. The human's verdict ("fun / not yet / pivot") is the gate.
- A system that is not in the core loop does not enter until rung 3 (inventory, crafting, dialogue trees, skill trees, economy).

## Red flags — cost these out loud before the user commits

| Pitch contains | Why it is dangerous | Offer instead |
|---|---|---|
| Online multiplayer (first project) | Netcode, sync, servers, cheating, testing with 2+ machines — multiplies every system | Local multiplayer or single-player first; online as a later milestone |
| MMO / persistent world | Server infrastructure and content volume of a studio | A single-player or small-session version of the core loop |
| Open world | Streaming, content volume, navigation, quests | One hand-made area that shows the loop |
| Procedural generation "for replayability" | Hard to tune; bad generation feels worse than hand-made | 3 hand-made levels first; generation once the loop is proven |
| "Like <AAA game>" | Hundreds of person-years of content | Name the ONE mechanic taken from it |
| 20+ hours of content | Content production dominates everything | 15 minutes that are great |
| Many systems at once (crafting + inventory + skill tree + economy) | Each is weeks; they interact | One system that serves the loop; the rest to backlog |
| Realistic 3D characters with custom animation | Art/animation cost | Stylised/low-poly CC0 characters + Mesh2Motion animations |
| Story-heavy with branching dialogue | Writing + tooling + testing combinatorics | Linear story or environmental storytelling first |
| VR / console / mobile + PC at once | Each platform = its own input, UI and performance work | One platform first |

## First-playable definition (write it into the brief)

```
First playable = <core verb(s)> in <one level/arena>, against <one obstacle/enemy type>,
with <win condition> and <fail condition>, restart in < 3 s, placeholder art from <source>.
Done when: <the human plays N runs and says ___>.
```

## When the user insists on the big version

Their call. Write the risks into the Decisions Ledger (chosen by the user, with the cost stated),
and still build it in ladder order — the first spec covers the toy/prototype of the big version.
Never refuse, never silently shrink it either.
