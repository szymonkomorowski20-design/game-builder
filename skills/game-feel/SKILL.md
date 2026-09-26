---
name: game-feel
description: Use to make controls and impacts feel good — responsive movement, jump arcs, input forgiveness (coyote time, buffering), camera, and feedback ("juice") like hit-stop, flash, shake, particles and sound — with every number in the Tuning table and the verdict left to the human. Triggers — "sterowanie jest sztywne", "skok jest dziwny", "brak wyczucia", "game feel", "juice", "dodaj efekty trafienia", "za wolno reaguje", "feel", "pływający skok".
---

# Game Feel — responsiveness first, juice second, the human decides

**Core principle:** feel = **response** (the game does what I meant, now) + **feedback** (I can see, hear and
feel that it happened). Both are numbers in the Tuning table; the playtest verdict decides them. You never
declare that something "feels good".

## 1. Response (fix before adding any juice)
| Symptom players report | Usual cause | Knob (Tuning table) |
|---|---|---|
| "Floaty jump" | same gravity up and down; too long time-to-apex | fall gravity multiplier 1.5–2.5; apex time 0.3–0.45 s (platformer template: `JumpMath` from height + time) |
| "I pressed jump but nothing happened" | no coyote time / no buffer | coyote 0.08–0.12 s, jump buffer 0.1 s |
| "Can't control small hops" | no variable jump | cut velocity on release (×0.4–0.6) |
| "Slippery / sluggish" | acceleration too low or friction too low | accel/decel in px/s², separate ground/air values |
| "Diagonal too fast" | un-normalized input | `Input.get_vector()` (recipe 01) |
| "Camera makes me sick / loses me" | follow too tight or too loose, no limits | drag margins, smoothing, limits (recipe 02) |
Movement in `_physics_process` × `delta`; input via actions. Start from the platformer template or recipes 01–02.

## 2. Feedback ("juice") — layer it on events, one at a time
| Event | Layers (recipe) |
|---|---|
| Hit dealt/taken | hit-stop 40–100 ms (32), white flash 0.1–0.15 s (33), shake by trauma (03), sound with pitch variation (35), knockback, damage number |
| Pickup | sound (35), small scale pop via Tween, particle burst, HUD counter pop (23) |
| Jump/land | squash & stretch via Tween, dust particles, soft land sound |
| Death / win | slow-mo or freeze, music change (34), screen transition (16) |
Each layer gets its own Tuning row (duration, amount) so the human can say "less shake". Add one layer, playtest,
then the next — five layers added at once can't be judged.

## 3. Prove what a machine can
- Response numbers → scenarios: jump height/apex time, coyote window, buffer window (platformer template P1–P8
  measure these in physics frames).
- Juice is wired → unit tests on signals/timers (recipes 03, 32, 33) and `gb shot --movie` (flash visible,
  `audio peak` not `-inf` on the hit frame).
- Web target: `game-audio` §5 and `game-vfx` (Compatibility renderer limits).

## 4. The human's verdict
Give 3–5 feel questions tied to numbers ("fall multiplier 1.8 — floaty or heavy?", "shake 0.4 trauma — too
much?"); record keep/tweak/cut per layer (`game-playtest`). Tweak = change Tuning values only.

## Red Flags — STOP
- Adding juice to fix unresponsive controls.
- A feel number hard-coded in a script instead of the Tuning table.
- "It feels good now" written by you.
- Accessibility ignored: strong shake/flashes need a settings toggle (`game-ui-accessibility`).
