# game-builder — instrukcja obsługi

**game-builder** to plugin do Claude Code, który prowadzi tworzenie gier w **Godot 4**. Bot przeprowadza z Tobą
rozmowę o pomyśle i zakłada projekt. Potem pisze plan (spec), a Ty go zatwierdzasz. Następnie buduje grę
fazami. Po każdej fazie gra działa: sprawdza ją silnik, a oceniasz Ty, grając.

- Plugin: https://github.com/szymonkomorowski20-design/game-builder (wersja 0.17.0, 27 września 2026)
- Biblioteka wiedzy i assetów, z której korzysta: [gry-wiedza](https://github.com/szymonkomorowski20-design/gry-wiedza)
  (dokumenty w `wiedza/`, paczki assetów, katalogi) i lokalny folder `BAZA-AI`
- Przykładowa gra zrobiona pluginem: **Lodowy Loch**, łamigłówka o ślizganiu po lodzie w 10 piętrach
  (repozytorium prywatne)

## Zasada, na której wszystko stoi
**SPEC → HUMAN → VERIFIED → PLAYABLE → GATED**
- **SPEC:** żadnego kodu gry bez zatwierdzonego planu.
- **HUMAN:** kluczowe decyzje (gatunek, zakres, wygląd, wyczucie sterowania) podejmujesz Ty. Bot doradza, podaje
  plusy i minusy, a potem czeka na Twój wybór.
- **VERIFIED:** „gotowe” znaczy, że silnik to potwierdził (`gb verify` na zielono), a nie że bot tak uważa.
- **PLAYABLE:** każda faza kończy się wersją, w którą da się zagrać.
- **GATED:** bot nie przeskakuje bramek między fazami. O tym, czy gra „dobrze się czuje”, decydujesz Ty po zagraniu.

Do tego trzy stałe reguły:
- bot robi **commit tylko na Twoje słowo**;
- nigdy sam nie publikuje gry (itch.io, sklepy);
- przed użyciem płatnych generatorów (PixelLab, ElevenLabs, Meshy) mówi co, ile i czym, i czeka na „tak”.

## 1. Czego potrzebujesz
| Co | Po co | Uwagi |
|---|---|---|
| [Claude Code](https://claude.com/claude-code) | tu pracuje bot | aplikacja desktopowa albo terminal |
| Node.js 22 lub nowszy | narzędzie `gb` (weryfikacja gry) | `node --version` |
| Godot **4.7.2** | silnik | na Windows najlepiej `Godot_v4.7.2-stable_win64_console.exe` (np. na Pulpicie; `gb` sam go znajdzie) |
| Szablony eksportu Godota 4.7.2 | budowanie `.exe` i wersji przeglądarkowej | Godot → Editor → Manage Export Templates → Download and Install |
| (opcjonalnie) kopia repo [gry-wiedza](https://github.com/szymonkomorowski20-design/gry-wiedza) | dokumenty wiedzy (`gb doc <nazwa>`: teoria projektowania, platformy, import assetów, paczki startowe, gry referencyjne) | domyślnie `Pulpit/gry-wiedza`; inna ścieżka przez zmienną `GAME_BUILDER_WIEDZA`. Bez kopii `gb doc` podaje adres na GitHubie |
| (opcjonalnie) `BAZA-AI` z gry-wiedza | wyszukiwanie wiedzy i darmowych assetów (`gb kb`, `gb assets`) | domyślnie `Pulpit/gry-wiedza/BAZA-AI`; inna ścieżka przez zmienną `GAME_BUILDER_KB` |

## 2. Instalacja (raz na komputer)
**Najprościej** jest pobrać repozytorium pluginu i w jego folderze uruchomić:
```powershell
powershell -ExecutionPolicy Bypass -File .\enable-plugin.ps1
```
Skrypt dopisuje plugin do `~/.claude/settings.json` z automatyczną aktualizacją. Potem uruchom Claude Code
ponownie.

**Albo w Claude Code:**
```
/plugin marketplace add szymonkomorowski20-design/game-builder
/plugin install game-builder@game-builder
```

**Jak sprawdzić, że działa:** otwórz Claude Code w folderze gry zrobionej pluginem. Na starcie sesji bot dostaje
komunikat `[game-builder] This repo runs the game-builder workflow…` i wie, na jakim etapie jest gra.

## 3. Pierwsza gra krok po kroku
Załóż pusty folder (np. `Pulpit/gry/moja-gra`), otwórz w nim Claude Code i napisz po prostu, co chcesz:
*„zróbmy grę — platformówka 2D o żabie”*.

| Krok | Co robi bot | Co robisz Ty |
|---|---|---|
| **0. Mapa** | pokazuje cały proces i pyta o ścieżkę: nowa gra / nowa mechanika w istniejącej grze / przejęcie gotowego projektu w Godocie | wybierasz |
| **1. Wywiad** (`game-discovery`) | zadaje pytania w rundach po 3–4 (klikasz odpowiedzi): o czym gra, co gracz robi co 10 sekund, co minutę i co 10 minut, jakie ma odczucia, platforma, sterowanie, grafika, zakres | odpowiadasz. Za duży pomysł („MMO jak WoW”) bot tnie **drabiną zakresu** do pierwszej grywalnej wersji, a reszta trafia do backlogu |
| **2. Brief** | zapisuje *Game Brief* z tabelą Twoich decyzji | potwierdzasz |
| **3. Założenie projektu** (`game-bootstrap`) | karty decyzji, a potem generuje projekt Godota z testami i narzędziami i udowadnia, że działa (`gb doctor`, `gb verify`). Karty: szablon, renderer, rozdzielczość, testy, LFS, tryb pracy | wybierasz na kartach |
| **4. Spec** (`game-spec`) | plan pierwszej grywalnej wersji: fazy, tabela strojenia (np. prędkość, siła skoku), kryteria „gotowe, gdy…”, bramki gry | czytasz i zatwierdzasz albo prosisz o zmiany |
| **5. Sprawdzenie przed kodem** (`game-pre-implement`) | szuka ryzyk: zapisy gry, wydajność, licencje, web | — |
| **6. Budowa** (`game-implement`) | faza po fazie. Najpierw test, który na razie nie przechodzi, potem kod, a po każdym kroku `gb verify`. Robi i ogląda zrzuty ekranu. Niezależny recenzent (`game-checker`) sprawdza zmiany | na **bramce gry** grasz i mówisz: **zostaje / popraw / wyrzuć** dla każdej mechaniki |
| **7. Strojenie** | po „popraw” zmienia tylko liczby z tabeli strojenia, sprawdza i daje Ci zagrać ponownie | grasz jeszcze raz |
| **8. Commit** | przygotowuje zmiany i mówi, że są gotowe | mówisz „commit” (albo nie) |
| **9. Wydanie** (`game-release`) | buduje `.exe` i wersję web, uruchamia zbudowaną grę, sprawdza licencje, robi napisy (`gb credits`), przygotowuje komendę wysyłki | grasz w zbudowaną wersję i **sam** publikujesz (np. `butler push`) |

**Co mówić na bramkach:**
- *„zagrałem, zostaje”*
- *„skok za niski”*
- *„ślizg za szybki”*
- *„wyrzuć podwójny skok”*
- *„commit”*
- *„nie commituj jeszcze”*

## 4. Szablony gier (start od działającej gry)
| Szablon | Co jest w środku |
|---|---|
| `platformer-2d` | bieg i skok (coyote time, bufor skoku, zmienny skok), monety i meta |
| `topdown-2d` | ruch w 8 kierunkach, strzelanie, fale wrogów, życie |
| `grid-puzzle-2d` | łamigłówka na siatce z cofaniem i solverem, który dowodzi, że każdy poziom da się przejść (z tego szablonu powstał Lodowy Loch) |
| `cards-2d` | walka karciana: energia, zamiary przeciwnika, karty jako dane, test balansu |
| `platformer-3d` | bieg i skok w 3D, kamera na sprężynie, która nie wchodzi w ściany, monety i meta |
| `fps-3d` | widok z pierwszej osoby, strzał, cele, osłony |
| `action-roguelite-3d` | gra w stylu Hadesa: hub z manekinem i kapliczką ulepszeń, runy z 5 pokoi, dary do wyboru, drzwi z nagrodami, 2 typy wrogów z czytelnymi zapowiedziami, boss z fazami, śmierć zachowuje walutę; bot przechodzi cały run |
| `military-fps-3d` | misja w stylu Call of Duty: karabin i pistolet z odrzutem, celowaniem i przeładowaniem, bieg i kucanie, zdrowie z regeneracją; żołnierze chowają się za osłonami, wychylają się seriami, obchodzą i krzyczą, co robią; dziedziniec, magazyn, radiostacja, posiłki, ewakuacja; punkty kontrolne; bot przechodzi całą misję |
| `rts-3d` | potyczka w stylu Warcrafta z komputerem: robotnicy zbierają złoto i drewno, budowa farm, koszar i stajni na siatce, która mówi, czemu nie można budować; piechurzy, łucznicy i jeźdźcy, z których każdy wygrywa z jednym i przegrywa z drugim; zaznaczanie ramką, grupy pod cyframi, rozkazy prawym przyciskiem, atak w marszu, szyki; kamera RTS i minimapa; mgła wojny; komputer na trzech poziomach trudności; bot wygrywa potyczkę |
| `stealth-parkour-3d` | skradanie i parkour w dzielnicy miasta w stylu Assassin's Creed: wspinaczka po występach fasad, przeskoki nad alejkami, zwis z krawędzi dachu i schodzenie, wieża widokowa, która odsłania dzielnicę, i skok w siano; strażnicy, którzy widzą i słyszą, sprawdzają hałas, polują, wzywają wsparcie, przeszukują, rezygnują i znajdują ciała; tłum, w którym można się wtopić, siano i ławka do ukrycia; walka z kontrami; rozgłos ze świadkami i listami gończymi, pościg do zgubienia; jeden kontrakt na zabójstwo, w którym wykrycie płoszy cel zamiast kończyć misję; bot wykonuje kontrakt niezauważony |

Każdy szablon ma już testy i scenariusze bota, który gra za Ciebie.

## 5. Przepisy (gotowe, przetestowane mechaniki)
Plugin ma **65 przepisów**, na przykład:
- ruch, kamera, trzęsienie ekranu;
- zdrowie, trafienia, pociski, broń;
- ekwipunek, sklep, zapis gry, dialogi, zadania;
- AI wrogów, nawigacja, mapa kafelkowa, generowany loch;
- muzyka adaptacyjna, lokalizacja, dostępność dla daltonistów;
- multiplayer, kamera 3D, punkty kontrolne, ruchome platformy, zryw, animacje postaci, minimapa;
- walka jak w Hadesie: kombinacje ciosów, dary, fale wrogów, bossowie z fazami, efekty statusów;
- strzelanka jak Call of Duty: broń z odrzutem, rozrzutem, celowaniem i przeładowaniem, strefy trafień, zdrowie z regeneracją, wspomaganie celowania na padzie, żołnierze chowający się za osłonami;
- strategia jak Warcraft: zaznaczanie i rozkazy, ekonomia z robotnikami, budowa na siatce i produkcja, ruch grupy w szyku, mgła wojny, walka z typami pancerza, komputerowy przeciwnik, kamera RTS.

Bot kopiuje przepis razem z jego testami:
```
node <folder-pluginu>/tools/gb/gb.js recipe list
node <folder-pluginu>/tools/gb/gb.js recipe add 13
```
Zwykle nie musisz tego robić sam: bot sięga po przepis, gdy spec go potrzebuje.

## 6. Narzędzie `gb` (to, co bot uruchamia; możesz też sam)
W folderze gry: `node tools/gb/gb.js <komenda>`
| Komenda | Co robi |
|---|---|
| `verify` | pełne sprawdzenie: import, skrypty, lint, uruchomienie bez okna, testy, scenariusze bota, nagrania. **Zielone = działa** |
| `scenario --window` | bot gra w oknie; widzisz, co testuje |
| `record skok` | **Ty grasz**, `gb` nagrywa. Nagranie staje się testem regresji |
| `shot --name menu` | zrzut ekranu (z `--compare` porównuje z zaakceptowanym wzorcem) |
| `perf` | czas klatki i wydajność względem budżetu |
| `export --preset "Windows Desktop" --smoke` | buduje `.exe` i uruchamia go na próbę; gdy Windows (Smart App Control) zablokuje nowy exe, sprawdza sam plik `.pck` edytorowym Godotem i mówi to wprost |
| `export --preset "Web"` | wersja przeglądarkowa |
| `credits` | napisy z licencjami; blokuje assety, których nie wolno wydać |
| `kb "coyote time"` / `assets "wybuch" --typ audio` | wyszukiwanie w bazie wiedzy i darmowych assetach |
| `doctor` | czy projekt ma wszystko, czego wymaga metoda |

**SKIP to nie PASS.** Jeśli coś zostało pominięte, bot mówi „niesprawdzone”, a nie „działa”.

## 7. Tryb pracy: standardowy, lekki albo autonomiczny
Wybierasz go przy zakładaniu projektu. Później zmieniasz go linijką `- Process:` w pliku `AGENTS.md` gry.
- **Standardowy** (domyślny): recenzent i agent-tester gry przy każdej fazie, pełna dokumentacja. Dla gier
  „na serio”, z zapisami gry, do wydania.
- **Lekki**: krótszy spec, jedna recenzja na cały spec, zrzuty sprawdza sam bot, a Ty grasz co najmniej na końcu
  specu. Dla game jamów, prototypów i nauki.
- **Autonomiczny** („zrób sam”, „prawie bez bramek”):
  - Ty podajesz pomysł, a bot odpowiada na karty decyzji polecanymi opcjami. Każdą decyzję zapisuje z uzasadnieniem,
    żebyś mógł ją odwrócić.
  - Spec zatwierdza niezależny recenzent.
  - Każdą fazę pilnują maszyny: testy, recenzja, playtest na zrzutach i bot, który przechodzi grę.
  - Ty grasz w gotową grę według listy w `STATUS.md`.
  - Zamiast commitów bot robi migawki (`gb snapshot`). Commit robi dopiero na Twoje słowo.

  Przykład: [Ucieczka z Krypty](dogfood/ucieczka-z-krypty.md).

**We wszystkich trybach bez zmian:**
- zielone `gb verify` i grywalna wersja po każdej fazie;
- płatne generatory tylko po Twoim „tak”;
- commit na Twoje słowo.

W standardowym i lekkim decyzje podejmujesz Ty. W autonomicznym bot decyduje, a Ty każdą decyzję możesz odwrócić po
zagraniu.

## 8. Grafika, dźwięk i licencje
- Każdy plik w `assets/` ma wpis w `.ai/assets/REGISTER.md` (źródło, autor, licencja). Bez wpisu nie trafia do
  wydania.
- **Wolno:** CC0, CC-BY (z napisami w grze), MIT, OFL (czcionki). **Nie wolno:** „free for personal use”,
  licencje NC/ND, brak licencji, grafika wycięta z innych gier.
- Darmowe paczki pasujące do każdego szablonu są w bazie gry-wiedza. Lista: `gb doc starter-packs`.
- Czcionki Kenney nie mają polskich liter (poza „ó”), a domyślna czcionka Godota ma wszystkie.
- Płatne generatory zawsze wymagają Twojej zgody: jedna zgoda to jedna partia, najpierw próbka.

## 9. Gdy coś się psuje
Napisz, co się dzieje, np. *„gra się wysypuje po drugim poziomie”*. Bot najpierw **odtwarza błąd** narzędziem
`gb`, potem szuka przyczyny (`game-diagnose`), a dopiero na końcu naprawia. Nie traktuje błędu jak nowej funkcji
i nie zgaduje.

## 10. Przejęcie istniejącej gry w Godocie
Otwórz Claude Code w folderze gry i napisz *„przejmij mój projekt”*. Bot dokłada metodę: testy, `gb`, `AGENTS.md`
i dokumentację. **Nie przepisuje Twojego kodu** i odczytuje ustawienia z Twojego `project.godot`.

## 11. Wydanie gry
1. Bot: `gb export --smoke`. Zbudowana gra jest uruchamiana na próbę, a błędy w jej logu blokują wydanie.
2. Bot: `gb credits`. Napisy muszą być w grze, jeśli są assety CC-BY.
3. Wersja web: grasz w przeglądarce. Sprawdzasz, czy dźwięk rusza po pierwszym kliknięciu i czy zapisy przetrwają
   odświeżenie strony. Szczegóły: `gb doc platforms`.
4. **Publikujesz Ty.** Bot przygotowuje komendę `butler push …`, ale nigdy nie loguje się za Ciebie i nie wysyła
   bez Twojego „wyślij”.

## 12. Gdzie co jest w folderze gry
| Plik / folder | Co to |
|---|---|
| `AGENTS.md` | zasady dla bota w tej grze (i tryb pracy) |
| `STATUS.md` | na jakim etapie jest gra |
| `.ai/brief.md` | koncepcja i Twoje decyzje |
| `.ai/specs/` | plany: w toku, a w `implemented/` zakończone |
| `.ai/STATE.md`, `.ai/lessons.md` | pamięć bota między sesjami i wnioski z błędów |
| `.ai/assets/REGISTER.md` | rejestr licencji |
| `tests/` | testy, scenariusze bota, nagrania Twojej gry, wzorce zrzutów |
| `tools/gb/` | narzędzie weryfikacji |

## 13. Najczęstsze pytania
- **Pierwsze uruchomienie z oknem trwa ~75 s.** Godot buduje wtedy cache shaderów, a gra się nie zawiesiła.
- **Bot nie zrobił commita.** Tak ma być: czeka na Twoje słowo.
- **„Dlaczego bot pyta, a nie robi?”** Pyta, bo decyzja należy do Ciebie. Doradza i podaje, co poleca, ale wybór
  jest Twój.
- **Gra ma działać w przeglądarce.** Powiedz to na starcie. Web wymusza renderer Compatibility, nie ma tam
  sieciowego ENet, a zapisy żyją w przeglądarce.
- **Aktualizacja pluginu:** instalacja przez `enable-plugin.ps1` włącza automatyczną aktualizację przy starcie
  Claude Code. Istniejące gry dostają nowe narzędzia komendą
  `node <folder-pluginu>/tools/gb/gb.js tools update --path <folder-gry>` (bot ją zaproponuje).

## Więcej
W repozytorium pluginu:
- `ROADMAP.md`: co zrobione, a co zostało;
- `CHANGELOG.md`: zmiany w każdej wersji;
- `docs/`: tryb pracy (`rigor.md`), moduły opcjonalne, raporty z budowy gier;
- `LICENSE` i `THIRD_PARTY_NOTICES.md`: licencja pluginu (zastrzeżona) i składniki innych autorów;

W repozytorium [gry-wiedza](https://github.com/szymonkomorowski20-design/gry-wiedza) (`gb doc <nazwa>`):
- `wiedza/`: teoria projektowania, platformy, import assetów, paczki startowe, gry referencyjne;
- `recipes/README.md`: wszystkie przepisy.

Raport z budowy Lodowego Lochu, pierwszej gry zrobionej pluginem, jest w `docs/dogfood/lodowy-loch.md`.
