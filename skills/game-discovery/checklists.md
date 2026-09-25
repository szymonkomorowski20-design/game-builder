# Concept checklists — new game and feature

Step 1 walks the one the variant selected. Skip an item only if the user explicitly defers it.

## New game (Game Brief)

- **Why this game, why you** — what excites the user about it? Personal project, learning, portfolio, jam, commercial release? Deadline (a jam weekend vs "someday")? This decides how hard the scope ladder cuts.
- **Player fantasy** — in one sentence, what does the player *feel like* (a nimble thief, a desperate survivor, a clever puzzle-solver)? Everything else serves this.
- **Core loop (the heart — never skip)** — what does the player do every ~10 seconds (move/aim/jump/place/match), every ~1 minute (clear a room, finish a round, craft), every ~10 minutes (level, run, day)? What is the reward that makes them do it again? Write it as: *the player ___, in order to ___, which lets them ___.*
- **References** — 2–3 games it should feel like, and for each: *what exactly* to take (the movement? the camera? the progression?) and what NOT to take.
- **Perspective & dimension** — 2D (side, top-down, isometric) or 3D (first-person, third-person, top-down)? Camera behaviour? (Decision card — it changes art cost and tech.)
- **Platform & input** — PC / web browser / Android / Steam Deck? Keyboard+mouse, gamepad, touch? Web forces the Compatibility renderer and small downloads; touch forces a different UI. (Constraints for bootstrap.)
- **Session & structure** — how long is one session (3 min run, 30 min level, hours)? Levels hand-made or generated? Linear, hub, open? Is there a fail state and what does it cost the player?
- **Progression & systems** — what persists between sessions (unlocks, upgrades, story, nothing)? Which systems are truly needed: combat, inventory, dialogue, economy, crafting, save/load? Each one is weeks of work — list them, then rank.
- **Feel targets** — responsive and snappy, or heavy and deliberate? Any concrete numbers they already know (jump height in tiles, run speed)? These become the spec's tuning table.
- **Art & audio source** — placeholders first (CC0 from the gry-wiedza library), own art, bought packs, AI-generated? Pixel art resolution / low-poly / hand-drawn? Who makes the music/SFX? Every non-CC0 source is a licence question. (Decision card.)
- **Narrative** — none, environmental, dialogue-heavy? Language(s) of the game text?
- **Multiplayer** — none / local / online? Online multiplayer as a first project is a red flag (scope-guard) — cost it out loud.
- **Monetisation & distribution** — free on itch.io, paid on Steam, jam submission, nothing? (Affects licences, age rating, store requirements later.)
- **Maker constraints** — hours per week, skills (code / art / audio / design), what they want to *learn* from this project, machine it must run on.
- **Success** — what makes the first playable a success ("my friends play 3 runs in a row")? What would make you stop or pivot?
- **Non-goals** — what the game explicitly is NOT (controls scope creep). Deferred ideas go to `.ai/backlog.md`, not into the brief.

## Feature (Feature Brief)

- **Already exists?** — recon result (scene/script paths). Resolve before anything else.
- **Who & why** — which player need does it serve; which part of the core loop does it strengthen?
- **Exact behaviour** — inputs, states, what the player sees and hears (feedback: sound, particle, screen shake, UI change).
- **Feel parameters** — the numbers that will be tuned (speed, cooldown, damage, timings) with starting values and who decides the final ones (the human, after playing).
- **Acceptance criteria** — testable and observable ("pressing jump within 0.1 s after leaving a ledge still jumps"; "the save survives quitting mid-level").
- **Content volume** — how many enemies/items/levels this feature must support now vs later.
- **Save & compatibility** — does it change saved data? Old saves must still load (migration) or be explicitly invalidated.
- **Performance budget** — worst case on screen (how many enemies/particles) on the weakest target device.
- **Assets needed** — which art/audio, from where, under which licence.
- **Non-goals** — what this feature does NOT do yet (to backlog).
- **Handoff** — which spec phases, which playtest gate.
