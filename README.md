# game-builder

Plugin do Claude Code, który prowadzi tworzenie gier w **Godot 4** metodą znaną z Sailes app-buildera:
najpierw rozmowa o koncepcji, potem konfiguracja projektu, spec i budowa faza po fazie. Każda faza
kończy się grywalną wersją, którą **sprawdza silnik** (`gb verify`), a **oceniasz Ty**, grając.

> Kręgosłup: **SPEC → HUMAN → VERIFIED → PLAYABLE → GATED**
> Żadnego kodu bez zatwierdzonego speca · kluczowe decyzje podejmujesz Ty · „gotowe” = zielony `gb verify` ·
> każda faza da się uruchomić i zagrać · bramek między fazami nie przeskakujemy.

## Co jest w wersji 0.1.0 (etap 1)

| Element | Do czego służy |
|---|---|
| `game-start` | Pokazuje mapę całego procesu i kieruje: nowa gra / nowa mechanika / przejęcie istniejącego projektu |
| `game-discovery` | Wywiad o koncepcji: fantazja gracza, pętla rozgrywki, platforma, sterowanie, grafika; **drabina zakresu** tnie „MMO z otwartym światem” do pierwszej grywalnej wersji |
| `game-bootstrap` | Karty decyzji (silnik, renderer, rozdzielczość, testy, LFS) → `gb scaffold` generuje projekt → `gb doctor` + `gb verify` dowodzą, że działa |
| `gb` (narzędzie) | Import, sprawdzenie wszystkich skryptów, uruchomienie gry bez okna i czytanie logu, testy, raport; wyszukiwanie w bazie gry-wiedza |
| Hooki sesji | Na starcie każdej sesji w repo gry: gdzie jesteśmy w procesie, wynik ostatniej weryfikacji, twarde zasady |

Pełny plan etapów 2–8: [ROADMAP.md](ROADMAP.md).

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

Zmienne środowiskowe (opcjonalne): `GODOT_BIN` — ścieżka do Godota, jeśli `gb` go nie znajdzie (szuka w PATH, na Pulpicie, w Pobranych, w typowych folderach) · `GAME_BUILDER_KB` — folder `BAZA-AI`, jeśli nie jest w `~/Desktop/gry-wiedza/BAZA-AI`.

## Jak zacząć grę

W nowym, pustym folderze w Claude Code napisz np. *„zróbmy grę — platformówka 2D o żabie”*. Plugin:
1. pokaże mapę procesu i zapyta o ścieżkę,
2. przeprowadzi wywiad i zapisze **Game Brief** z tabelą Twoich decyzji,
3. wygeneruje projekt Godota z całą strukturą i udowodni, że działa,
4. przejdzie do speca pierwszej grywalnej wersji.

## Narzędzie `gb`

```
node tools/gb/gb.js verify        # import → skrypty → uruchomienie → testy (raport .ai/verify/last.json)
node tools/gb/gb.js doctor        # czy repo gry ma wszystko, czego wymaga metoda
node tools/gb/gb.js run --scene res://scenes/level_1.tscn --frames 300
node tools/gb/gb.js kb "coyote time CharacterBody2D"
node tools/gb/gb.js assets "wybuch" --typ audio
```

## Rozwój pluginu

`npm test` — pełny zestaw testów (z Godotem ok. 1 min; bez Godota testy integracyjne są pomijane z komunikatem). Zasady zmian: [AGENTS.md](AGENTS.md).
