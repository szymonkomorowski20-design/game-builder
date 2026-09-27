# Third-party notices

game-builder is proprietary (see `LICENSE`). This file lists everything in the repository, or copied by it into
game projects, that other people wrote, under what terms, and what we changed. The last full audit was on
2026-09-27.

## Included software

### GUT — Godot Unit Test (9.7.1)
- Where: `vendor/gut/addons/gut/`. `gb tests install` copies the whole folder, including its `LICENSE.md`, into
  a game's `addons/gut/`.
- Licence: MIT. Copyright (c) 2018 Tom "Butch" Wesley. Full text: `vendor/gut/addons/gut/LICENSE.md`.
- Source: https://github.com/bitwes/Gut. Unmodified.

## Adapted text

### Claude Code Game Studios
- What:
  - the visual-evidence ("Run result") rule in `skills/game-implement/SKILL.md`, adapted and marked there;
  - the reasoning behind a lightest-tier default, summarised in `docs/rigor.md`;
  - the idea of a playtester and screenshot evidence.
- Source: https://github.com/Donchitos/Claude-Code-Game-Studios (a copy is in the gry-wiedza library, wave 05).
- Licence: MIT:

```
MIT License

Copyright (c) 2026 Donchitos

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

### Godot Engine documentation
- What: facts summarised, in our own words and with file references, from the official docs (4.7 branch). They
  are in:
  - `skills/game-implement/godot-4.4-4.7-changes.md` (the migration guides);
  - `skills/game-implement/godot-pitfalls.md` (where a row cites the docs).
- Licence of the source: CC BY 3.0, https://creativecommons.org/licenses/by/3.0/. Godot Engine documentation ©
  Juan Linietsky, Ariel Manzur and the Godot community. **Changes:** condensed, paraphrased, and combined with our
  own measurements on Godot 4.7.2. No endorsement by the Godot project is implied.
- Godot Engine itself is not included. It is installed separately under its own MIT licence.

## Inspiration only (nothing included)
- **Sailes app-builder** (Sailes Tech): the idea of a stage-gated workflow (discovery → bootstrap → spec →
  implement, with a human deciding at each gate) comes from it. No Sailes code or text is included. The session
  hooks were rewritten from scratch on 2026-09-27. A line-by-line comparison against sailes-app-builder 1.28.2
  finds no shared line of 60+ characters except one standard PowerShell invocation line
  (`powershell -ExecutionPolicy Bypass -File .\enable-plugin.ps1`).
- **Game-design literature** in the gry-wiedza library's guides (MDA, flow, game feel, …): cited by author and
  title, with no quotations beyond short phrases.

## Not included, only referenced
- **Assets.** The plugin ships no third-party art, audio, fonts or models. Templates draw with code and
  placeholders. The asset packs a game uses come from the gry-wiedza library or elsewhere and are registered per
  game in `.ai/assets/REGISTER.md`. `gb credits` turns the register into the game's credits.
- **Knowledge documents** (design theory, platforms, asset pipeline, starter packs, reference games) live in the
  gry-wiedza repository, with their own attributions; `gb doc <name>` reads them from there.
