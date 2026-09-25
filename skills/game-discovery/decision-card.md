# Decision card — how a fork is put to the human

## Two kinds of question

- **Fact-finding** (their world): "Na czym chcesz grać?", "Ile godzin tygodniowo?", "Czy rysujesz?" → plain options; you are learning their reality.
- **Decision** (a fork you would otherwise pick): 2D/3D, camera, real-time/turn-based, level generation, art source, platform priority, engine, renderer, test framework → **never** a bare "A or B?", never decided silently. Use the card.

## The card

```
Decyzja: <co rozstrzygamy, jedna linia>
Dlaczego to ważne: <na co wpływa — czas pracy, koszt grafiki, odwracalność, platforma, wydajność>
Opcje:
  A) <opcja> — ✅ <konkretna zaleta dla TEJ gry>  ⚠️ <konkretny koszt>
  B) <opcja> — ✅ …  ⚠️ …
  C) <opcja> — ✅ …  ⚠️ …
Rekomendacja: <A/B/C> — bo <powód oparty na JEGO odpowiedziach>
Twój wybór? (możesz wybrać inaczej niż rekomenduję)
```

In `AskUserQuestion`: put the recommended option first with "(Rekomendowane)", each option's
description = its ✅ and ⚠️.

## Quality bar

- Each option has **one concrete upside and one concrete cost for this game** — not "flexible", "simple", "modern" without saying what it simplifies.
- Costs name the real trade-off: weeks of work, art/animation cost, platform exclusion, performance, licence risk, reversibility.
- The recommendation cites the user's answers ("bo gra ma być w przeglądarce i robisz ją sam po godzinach").
- An option that only makes sense later (online multiplayer in a first prototype) is marked "later" and goes to the backlog, not offered as a current choice.
- Can't state a real pro and con for an option? Ask a fact-finding question first.

## When you cannot ground the recommendation

"Nie mam podstaw, żeby wskazać — <czego nie wiem>" is a legitimate recommendation line. When the
fork is expensive or hard to reverse, offer a fourth move: **settle it by a spike** — a toy
prototype of both options (e.g. 30 minutes of grey-box movement in 2D and in 3D), with the
criterion agreed *before* building ("wybieramy tę, w którą chcesz grać dłużej"). The human still
owns the choice, including just deciding.

## Game forks that always get a card

| Fork | Typical options | The cost people forget |
|---|---|---|
| Dimension & camera | 2D side / 2D top-down / 2.5D / 3D third-person / 3D first-person | 3D multiplies art, animation, camera and collision work |
| Pace | real-time / turn-based / hybrid | real-time needs feel tuning; turn-based needs UI clarity and AI |
| Levels | hand-made / procedural / hybrid | procedural is hard to make *good*; hand-made costs content time |
| Art source | CC0 placeholders / own art / bought packs / AI-generated | licences, style consistency, time; AI art has its own licence and store-policy questions |
| Platform priority | PC / web / mobile / Deck | web → Compatibility renderer + small builds; mobile → touch UI + performance |
| Save model | none / checkpoints / anywhere / cloud | save migration once players have saves |
| Multiplayer | none / local / online | online multiplies everything (scope-guard.md) |
