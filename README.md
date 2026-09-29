# game-builder

Plugin do Claude Code, który prowadzi tworzenie gier w **Godot 4** metodą znaną z Sailes app-buildera:
najpierw rozmowa o koncepcji, potem konfiguracja projektu, spec i budowa faza po fazie. Każda faza
kończy się grywalną wersją, którą **sprawdza silnik** (`gb verify`), a **oceniasz Ty**, grając.

> Kręgosłup: **SPEC → HUMAN → VERIFIED → PLAYABLE → GATED**
> Żadnego kodu bez zatwierdzonego speca · kluczowe decyzje podejmujesz Ty · „gotowe” = zielony `gb verify` ·
> każda faza da się uruchomić i zagrać · bramek między fazami nie przeskakujemy.

**Instrukcja obsługi po polsku:** [docs/INSTRUKCJA.md](docs/INSTRUKCJA.md).
Opisuje instalację, pierwszą grę krok po kroku, co mówić na bramkach, szablony, przepisy, `gb`, licencje i
wydanie.

## Co jest w środku (0.30.0)

| Element | Do czego służy |
|---|---|
| Proces: `game-start` → `game-discovery` → `game-bootstrap` → `game-spec` → `game-pre-implement` → `game-implement` → `game-test` → `game-playtest` → `game-release` | od pomysłu (wywiad z drabiną zakresu) przez karty decyzji i spec z tabelą strojenia do budowy faza po fazie i wydania; na każdej bramce grasz Ty |
| Skille tematyczne | audio, assety, balans, level design, game feel, AI postaci, narracja, zapis gry, wydajność, UI i dostępność, efekty, aktualizacja silnika, diagnoza błędów |
| Role (agenci) | `game-checker` (niezależna recenzja zmian), `game-tester` (testy ze speca przed kodem), `game-playtester` (uruchamia grę, ogląda zrzuty, słucha dźwięku), `game-researcher` (fakty ze źródłami) |
| 9 szablonów gier | `platformer-2d`, `topdown-2d`, `grid-puzzle-2d`, `cards-2d`, `platformer-3d`, `fps-3d`, `action-roguelite-3d` (jak Hades), `military-fps-3d` (misja jak Call of Duty), `rts-3d` (potyczka jak Warcraft), każdy z testami i botem-graczem |
| 65 przepisów | przetestowane mechaniki (ruch, walka, ekwipunek, zapis, dialogi, AI, nawigacja, audio, multiplayer, kamera 3D, animacje, minimapa, broń FPS z odrzutem i celowaniem, AI z osłonami, zaznaczanie i rozkazy RTS, ekonomia, mgła wojny…), `gb recipe add` |
| Narzędzie `gb` | weryfikacja gry bez okna, bot-gracz, nagrania Twojej gry jako testy, zrzuty z wzorcami, wydajność, eksport z próbnym uruchomieniem, licencje/napisy, wyszukiwanie w gry-wiedza |
| Hooki sesji | na starcie każdej sesji w repo gry: etap procesu, wynik ostatniej weryfikacji, tryb pracy (standardowy / lekki / autonomiczny), twarde zasady |
| `docs/` | instrukcja obsługi, tryby pracy (standardowy / lekki / autonomiczny: bot buduje, Ty grasz w gotową grę), moduły opcjonalne, raporty z budowy gier |
| Wiedza (w repo [gry-wiedza](https://github.com/szymonkomorowski20-design/gry-wiedza), `gb doc <nazwa>`) | teoria projektowania, platformy (web, itch.io, Android), import assetów, paczki startowe, gry referencyjne, dokumenty gatunków (action roguelite jak Hades, militarny FPS jak Call of Duty, RTS jak Warcraft) z pomiarami z gier-dowodów |

Dowody działania:
- gra *Lodowy Loch*, zbudowana pluginem w 5 fazach i przejdziona przez człowieka ([raport](docs/dogfood/lodowy-loch.md));
- gra *Ucieczka z Krypty* (jak Hades), zbudowana w trybie autonomicznym od jednozdaniowego pomysłu do buildu na
  Windows, z darmowymi assetami ([raport](docs/dogfood/ucieczka-z-krypty.md));
- gra *Operacja Pył* (FPS jak Call of Duty): 3 misje na Księżycu, bot przechodzi całą kampanię przez menu
  ([raport](docs/dogfood/operacja-pyl.md));
- gra *Kamienna Marchia* (RTS jak Warcraft): 3 misje i potyczka z komputerem na 3 poziomach, bot przechodzi kampanię
  przez menu, poziomy trudności zmierzone na kilku ziarnach ([raport](docs/dogfood/kamienna-marchia.md)).

 Plan i stan: [ROADMAP.md](ROADMAP.md), zmiany: [CHANGELOG.md](CHANGELOG.md).

## Instalacja

Wymagania: [Claude Code](https://claude.com/claude-code), Node.js ≥ 22, Godot 4.x (na Windows najlepiej wersja `_console.exe`), opcjonalnie baza wiedzy [gry-wiedza](https://github.com/szymonkomorowski20-design/gry-wiedza) (folder `BAZA-AI`).

**A. Z GitHuba (zalecane):**
```powershell
powershell -ExecutionPolicy Bypass -File .\enable-plugin.ps1
```
albo w Claude Code:
```
/plugin marketplace add szymonkomorowski20-design/game-builder
/plugin install game-builder@game-builder
```

**B. Lokalnie (rozwój pluginu):** `/plugin marketplace add C:\ścieżka\do\game-builder`, potem `/plugin install game-builder@game-builder`.

Zmienne środowiskowe (opcjonalne): `GODOT_BIN` — ścieżka do Godota, jeśli `gb` go nie znajdzie (szuka w PATH, na Pulpicie, w Pobranych, w typowych folderach) · `GAME_BUILDER_KB` — folder `BAZA-AI`, jeśli nie jest w `~/Desktop/gry-wiedza/BAZA-AI` · `GAME_BUILDER_WIEDZA` — kopia repo gry-wiedza (dla `gb doc`), jeśli nie jest w `~/Desktop/gry-wiedza`.

**Licencja:** kod pluginu jest zastrzeżony ([LICENSE](LICENSE)); składniki innych autorów mają własne licencje ([THIRD_PARTY_NOTICES.md](THIRD_PARTY_NOTICES.md)).

## Jak zacząć grę

W nowym, pustym folderze w Claude Code napisz np. *„zróbmy grę — platformówka 2D o żabie”*. Plugin:
1. pokaże mapę procesu i zapyta o ścieżkę,
2. przeprowadzi wywiad i zapisze **Game Brief** z tabelą Twoich decyzji,
3. wygeneruje projekt Godota z całą strukturą i udowodni, że działa,
4. przejdzie do speca pierwszej grywalnej wersji.

## Narzędzie `gb`

```
node tools/gb/gb.js verify        # import → skrypty → lint → uruchomienie → testy GUT → scenariusze bota → nagrania
node tools/gb/gb.js doctor        # czy repo gry ma wszystko, czego wymaga metoda
node tools/gb/gb.js scenario      # bot-gracz: tests/scenarios/*.gd (press/tap/wait + oczekiwania)
node tools/gb/gb.js record skok   # TY grasz, gb nagrywa → tests/replays/skok.json
node tools/gb/gb.js replay        # odtwarza nagrania bez okna; stan końcowy musi się zgadzać
node tools/gb/gb.js shot --name menu --compare   # zrzut ekranu vs zaakceptowany wzorzec
node tools/gb/gb.js perf --seconds 10            # czas klatki, węzły, draw calls vs budżet
node tools/gb/gb.js snapshot                     # migawka fazy bez commita (git write-tree); snapshot checkout <drzewo> <folder> = czysta kopia
node tools/gb/gb.js export --preset "Windows Desktop"
node tools/gb/gb.js kb "coyote time CharacterBody2D"
node tools/gb/gb.js assets "wybuch" --typ audio
```

Harness (`addons/gb_harness`) jest w grze nieaktywny — działa tylko, gdy `gb` uruchamia grę z flagami `--gb-*`.
Dlaczego własne `gb`, a nie serwer MCP: [docs/mcp-evaluation.md](docs/mcp-evaluation.md).

## Rozwój pluginu

`npm test` — pełny zestaw testów (z Godotem ok. 1 min; bez Godota testy integracyjne są pomijane z komunikatem). Zasady zmian: [AGENTS.md](AGENTS.md).
