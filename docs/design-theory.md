# Design theory — the few ideas that change decisions

A working reference for the agent. It is not a textbook: each idea is here because it changes a question in
discovery, a line in a spec or a question in a playtest. The skills own the procedures (`game-discovery`,
`game-spec`, `game-balance`, `game-level-design`, `game-feel`, `game-playtest`); this page gives them the *why* and
the vocabulary. The human still decides. Theory helps you ask better questions, but it doesn't settle the answer.

More sources: `node tools/gb/gb.js kb "<topic>"` (the gry-wiedza library, e.g. `kb "MDA"`, `kb "game feel"`).

## 1. MDA — design backwards from the experience

**Idea:** a game's rules and parts are its **Mechanics**. **Dynamics** are how those mechanics behave at run
time with a player acting on them. **Aesthetics** are the emotional responses of the player. The designer builds
M → D → A. The player meets A first, then D, then M. The paper names eight aesthetics:
- sensation;
- fantasy;
- narrative;
- challenge;
- fellowship;
- discovery;
- expression;
- submission (pastime).

*Source:* Hunicke, LeBlanc, Zubek — *MDA: A Formal Approach to Game Design and Game Research* (AAAI workshop, 2004).

**Use it:**
- **Brief:** record the 1–2 target aesthetics ("challenge + discovery"), in the player's words.
- **Spec:** every mechanic traces to a dynamic that serves a target aesthetic. A mechanic with no trace is scope
  creep, so move it to the backlog.
- **Playtest:** ask about the aesthetic ("did it feel tense when…?"), not the mechanic ("did you like the dash?").

**Trap:** "fun" isn't an aesthetic, so pick which kind of fun you mean. Another trap is adding a mechanic because
the genre usually has it.

## 2. Loops — what repeats, and what feeds itself

**Idea:** a game is loops at nested time scales:
- every ~10 s: act (move, aim, place);
- every ~1 min: a goal (clear a room, finish a round);
- every ~10 min+: progress (level, run, unlock).

Each loop needs a reward that restarts it. Economies are loops too.

Feedback loops come in two kinds:
- **positive:** the leader gets stronger, so the game snowballs and ends fast;
- **negative:** the trailer gets help, so it catches up and matches stay close.

*Sources:* Marc LeBlanc, *Feedback Systems and the Dramatic Structure of Competition* (GDC 1999). Adams & Dormans,
*Game Mechanics: Advanced Game Design* (2012; Machinations diagrams).

**Use it:**
- The core-loop sentence in discovery: *the player ___, in order to ___, which lets them ___*
  (`game-discovery/checklists.md`).
- In `game-balance`, write every positive loop as a contract with a cap, e.g. "after 10 rounds the leader's
  advantage stays within X". Simulate it with recipe 36.

**Trap:**
- an uncapped positive loop decides matches in the first minute;
- a negative loop that punishes skill ("why play well?");
- a 10-minute loop with no 10-second loop that is fun on its own.

## 3. Interesting decisions

**Idea:** a choice is meaningful when:
- the options have real trade-offs;
- the player has enough information to reason;
- the result is visible and matters later.

A dominant option is not a decision. Salen & Zimmerman's "meaningful play" says the same: the outcome of an action
must be *discernable* (the player sees it) and *integrated* (it affects what comes next).

*Sources:* Sid Meier, *Interesting Decisions* (GDC 2012). Salen & Zimmerman, *Rules of Play* (2003).

**Use it:**
- For every choice in the spec (weapon, card, upgrade, path), name the trade-off.
- In `game-balance`, test "no dominant option": simulate each option across the contexts that matter. An option
  that wins everywhere means redesign, not a smaller number.
- Show the consequence with feedback (see §6).

**Trap:**
- choices whose results the player can't see;
- "choices" between a strictly better and a strictly worse item;
- hidden information that makes the choice a coin flip.

## 4. Fun as learning

**Idea:** people enjoy recognising and mastering patterns. A game gets boring when the pattern is mastered and
nothing new arrives, and when there is no learnable pattern at all (noise).

*Source:* Raph Koster, *A Theory of Fun for Game Design* (2004; 2nd ed. 2013).

**Use it:**
- The spec's content plan says what is **new** in each level or wave: a mechanic, a combination, a twist
  (`game-level-design`).
- N levels in a row with nothing new is a pacing flag you raise with the human.
- Randomness should vary a learnable pattern, not replace it (`game-balance` §4).

**Trap:**
- content volume mistaken for novelty (ten levels of the same thing);
- randomness so wide that skill doesn't show.

## 5. Flow and the difficulty curve

**Idea:** people are absorbed when challenge matches skill:
- too hard → anxiety;
- too easy → boredom.

Skill grows, so challenge must grow too, with rests. A common shape is a sawtooth: ramp up, peak at a test (a boss
or a hard level), then drop when a new mechanic arrives. Jenova Chen argues for letting players choose their own
challenge rather than adjusting it behind their back.

*Sources:* Mihaly Csikszentmihalyi, *Flow* (1990). Jenova Chen, *Flow in Games* (MFA thesis, USC, 2006).

**Use it:**
- A difficulty table per level/wave in the spec (`game-balance` §3).
- Where the ramp should rise, check that it does.
- Hidden dynamic difficulty only as a human decision with a bounded, tested rule. Otherwise use player-chosen
  difficulty or an assist option.
- In playtests, measure retries and time per level, and where people quit (`game-playtest`).

**Trap:**
- **the developer is the best player**, so their curve feels flat and everyone else's is a wall;
- **the bot is a perfect player:** a passing scenario or solver proves the level can be completed (recipe 37),
  never that it is fair or fun. Only human play measures the curve.

## 6. Game feel — response first, juice second

**Idea:** feel is three things:
- real-time control (the character does what I meant, now);
- a simulated space that reacts;
- polish.

"Juice" is extra feedback on events: particles, shake, sound, squash, hit-stop. It amplifies good control but
can't fix bad control.

*Sources:* Steve Swink, *Game Feel* (2008). Martin Jonasson & Petri Purho, *Juice it or lose it* (talk, 2012).
Jan Willem Nijman, *The Art of Screenshake* (talk, 2013).

**Use it:** `game-feel`:
1. Response: input latency, coyote time, input buffer, acceleration curves.
2. Then feedback, one event at a time, from recipes 03 (camera shake), 32 (hit-stop), 33 (hit flash) and 35 (SFX
   variants).
3. Every feel number goes in the Tuning table so playtest notes map to values.

**Trap:**
- juice on top of unresponsive controls;
- so much shake and flash that the game stops being readable (also an accessibility issue, see
  `game-ui-accessibility`).

## 7. Level design — introduce, develop, twist, conclude

**Idea:** Nintendo's structure, taken from four-panel comics (kishōtenketsu):
1. introduce a mechanic safely;
2. develop it with a harder use;
3. twist it (combine it or subvert it);
4. conclude, and move on before it's stale.

Teach through the space: the first encounter is safe and readable, landmarks and sightlines show the goal, and text
tutorials are the exception.

*Source:* Koichi Hayashida on *Super Mario 3D Land* (Gamasutra/Game Developer interview, 2012).

**Use it:** `game-level-design` has one row per level: what it teaches, tests or twists. Validate that every level
can be completed (recipe 37), then put a human in front of it.

**Trap:**
- the twist before the introduction;
- a lesson given in a text box instead of a level;
- a level that tests two new things at once.

## 8. Who it is for

**Idea:** players are motivated differently: mastery, exploration, social play, competition, story, calm. Bartle's
four types came from MUDs and are often over-applied. Survey-based models such as Quantic Foundry's are closer to
evidence.

*Sources:* Richard Bartle, *Hearts, Clubs, Diamonds, Spades: Players Who Suit MUDs* (1996). Quantic Foundry's
gamer motivation model (Nick Yee).

**Use it:** in discovery, "who is it for" picks the target aesthetics (§1). It also sets what to cut: a calm puzzle
game doesn't need a combo meter.

**Trap:** "for everyone" means for no one in particular, so the spec can't be checked against it.

## 9. Playtesting — observe, don't lead

**Idea:**
- test early, with ugly prototypes;
- watch what players do rather than asking what they think;
- let them think aloud;
- don't explain or help.

Players are reliable about *what* went wrong for them and unreliable about *how* to fix it.

*Sources:* Tracy Fullerton, *Game Design Workshop* (playcentric design; 4th ed. 2018). Jesse Schell, *The Art of
Game Design: A Book of Lenses* (2008; 3rd ed. 2019).

**Use it:** `game-playtest`:
- 3–5 concrete tasks and one question the session must answer;
- a verdict per mechanic;
- suggestions are logged as symptoms, then traced to a Tuning value or a contract (`game-balance` §5).

The human owns the verdict. A machine playtest (`game-playtester`) proves the game runs and looks right, never that
it is fun.

**Trap:**
- leading questions ("wasn't the jump nice?");
- testing only with the developer;
- changing three things between sessions, so nobody knows which one helped.

## The theory at our gates

| Gate | Questions this page adds |
|---|---|
| Discovery (brief) | Which 1–2 aesthetics (§1)? The core-loop sentence at 10 s / 1 min / 10 min (§2)? Who it's for (§8)? |
| Spec review | Does every mechanic trace to a target aesthetic (§1)? Is every positive loop capped (§2)? Does every choice have a trade-off, with no dominant option (§3)? Is something new per level (§4, §7)? Is there a difficulty table with rests (§5)? Are feel numbers in Tuning (§6)? |
| Playtest | Questions phrased by aesthetic (§1). Retries and time per level (§5). Where players stopped. Observations separate from suggestions (§9). |
| After release | The postmortem asks which aesthetic landed and which loop carried the game (`game-release/postmortem-template.md`). |
