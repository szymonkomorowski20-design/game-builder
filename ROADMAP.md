# Roadmap — game-builder („Sailes dla gier”)

Źródło prawdy o tym, co istnieje, a co jest zaplanowane. `[x]` = zrobione i sprawdzone (testem lub
uruchomieniem), `[ ]` = do zrobienia. Każdy etap kończy się czymś, co da się uruchomić i sprawdzić.

Decyzje (potwierdzone 2026-09-25): Godot 4 (przypięty 4.7.x) · GDScript · 2D na start, potem 3D ·
PC + web · Claude Code · nazwa `game-builder` · baza wiedzy: gry-wiedza/BAZA-AI.

## Etap 1 — Fundament ✅ (0.1.0)
- [x] Manifest pluginu, marketplace, `enable-plugin` (Windows/macOS/Linux), VERSION, CHANGELOG
- [x] Hooki SessionStart: router pracy (stan repo gry → właściwy skill), kontrola wersji frameworka
- [x] Konflikt z Sailes rozwiązany: repo gry wyłącza Sailes w `.claude/settings.json`, router game-builder ma pierwszeństwo
- [x] `gb`: godot / import / check / run / test / verify / doctor / kb / assets / scaffold (+ `--adopt`)
- [x] Weryfikacja czyta log (błędy runtime przy kodzie wyjścia 0), sprawdzanie wszystkich skryptów w jednym uruchomieniu
- [x] Mapa sterowania zapisywana przez sam Godot (`setup_input.gd`)
- [x] Skille: `game-start`, `game-discovery` (+ checklisty, karty decyzji, drabina zakresu, szablony briefu), `game-bootstrap` (+ silnik decyzyjny, baseline Godota, adopcja, baza wiedzy, definicja gotowości)
- [x] Szablony repo gry: AGENTS.md ze stemplem, `.ai/` (spec-writing, checklisty, rejestr assetów, ADR-001), `.claude/` (pamięć sesji, strażnik ścieżek)
- [x] Testy: 43 (gb jednostkowe + integracyjne na prawdziwym Godocie, hooki, strażnik, scaffold, e2e bootstrap, higiena wydania)
- [x] `claude plugin validate` przechodzi (manifest, marketplace, frontmatter skilli)
- [x] Evale: 5 scenariuszy napisanych
- [x] Evale uruchomione na świeżych subagentach — zrobione w etapie 7 (evals/RESULTS-2026-09-26.md)

## Etap 2 — Warstwa weryfikacji ✅ (0.2.0)
- [x] GUT 9.7.1 dołączony do pluginu i instalowany przez `gb` (scaffold / `tests install`), `gb test` z podsumowaniem i JUnit; gdUnit4 tylko wykrywany (instalacja ręczna)
- [x] Determinizm: stały krok fizyki, ziarno RNG w trybie testu
- [x] Nagrywanie i odtwarzanie wejścia (replay) + bot-gracz (skrypty scenariuszy: „idź w prawo 2 s, skocz”) z asercjami stanu
- [x] Zrzuty ekranu z viewportu (okno, `--fixed-fps`) + porównanie z baseline (`imgdiff.gd`) + instrukcja: agent ogląda PNG przed akceptacją
- [x] Pomiar wydajności (monitory Performance → JSON) i budżety
- [x] Walidatory: zepsute `res://`, assety spoza rejestru licencji, nieużywane assety, rozmiary tekstur, API Godota 3
- [x] Eksport (`gb export`): Windows sprawdzony (109 MB .exe); Web gotowy, ale na tym komputerze brak szablonów web — `gb` i `doctor` to wykrywają
- [x] Hook po edycji `.gd/.tscn/.tres`: `gb check` + `gb lint`, błąd wraca do agenta od razu (gdtoolkit i hook Stop — świadomie pominięte: wymagałyby Pythona/pakietów i wydłużały każdą turę)
- [x] CI (GitHub Actions): Godot Linux (adres sprawdzony) → `gb verify`, raport jako artefakt; eksport w CI — nie (szablony ~1 GB); workflow jeszcze nie uruchomiony na GitHubie (sprawdzi go dogfooding w etapie 8)
- [x] Ocena gotowych serwerów MCP dla Godota

## Etap 3 — Spec → implement → test ✅ (0.3.0)
- [x] `game-spec`, `game-pre-implement`, `game-implement`, `game-test` (+ szablony, techniki)
- [x] Bramka „człowiek zagrał” w implementacji, run log, STATUS.md na bramkach, pamięć STATE.md
- [x] Dowód: Pong zbudowany pluginem w 3 fazach (docs/dogfood/pong.md) — metoda złapała regres i usterkę wizualną
- [x] Pong zamknięty jako zakończony test metody (decyzja właściciela 2026-09-26) — bramki zamknięte bez werdyktu gracza; bramka człowieka zostanie sprawdzona na grze z etapu 8

## Etap 4 — Wiedza, fala 05 (0.5.0–0.8.0; zostały dodatki)
- [x] Dokumentacja Godota w wersji przypiętej (gałąź 4.7) — w BAZA-AI (fala 05) + referencja zmian 4.4–4.7 z oficjalnych przewodników migracji
- [x] Biblioteka przepisów mechanik: 35 z 98 testami GUT i 11 scenariuszami; `gb recipe list/add` kopiuje je z testami do gry (dowód e2e)
- [x] Przepisy 40–43 (0.14.0): kamera orbitująca 3D, punkty kontrolne, ruchoma platforma, zryw i odrzut — z dowodami wykrycia
- [x] Przepisy 44–46 (0.16.0): AnimationTree, minimapa, multiplayer spawner/synchronizer — z dowodami wykrycia
- [ ] Kolejne przepisy: zapis w chmurze, mody, przewidywanie/interpolacja po stronie klienta
- [x] Pułapki Godota — `skills/game-implement/godot-pitfalls.md` (zmierzone, z poprawkami)
- [x] Audio: skill `game-audio`, przepisy 34–35, `gb shot --movie` z pomiarem dźwięku; fala 05 biblioteki (paczki CC0/MIT/CC-BY, licencje)
- [x] Z Claude Code Game Studios (MIT): dowód wizualny „Run result” w game-implement, zrzuty przez Movie Maker
- [x] Teoria projektowania (0.17.0): `gry-wiedza/wiedza/design-theory.md` (`gb doc design-theory`) — MDA, pętle, decyzje, nauka, flow i krzywa trudności, game feel, level design, odbiorca, playtesty; każda idea ze źródłem i miejscem w bramkach (brief: docelowe doświadczenie, przegląd specu, raport playtestu, postmortem)
- [x] Platformy (0.17.0): `gry-wiedza/wiedza/platforms.md` (`gb doc platforms`) — web, itch.io + butler, Android wg dokumentacji gałęzi 4.7 (kopia master w BAZA-AI różni się dla Androida)
- [x] Pipeline assetów (0.17.0): `gry-wiedza/wiedza/asset-pipeline.md` (`gb doc asset-pipeline`) — obrazy/pixel art, audio, Blender→glTF, przyrostki nazw, edycje odporne na reimport, TileMapLayer, Aseprite Wizard / YATI / LDtk
- [ ] gdUnit4: ścieżka `gb test` dla gdUnit4 nigdy nie uruchomiona (dodatek niezainstalowany) — sprawdzić, gdy ktoś go wybierze; GUT pokryty (game-test + gb)
- [x] Gry referencyjne (0.17.0): `gry-wiedza/wiedza/reference-games.md` (`gb doc reference-games`) — 17 gier Godot 4 z licencjami kodu i assetów sprawdzonymi w repo; żadna nie ma testów automatycznych (ustalenie)
- [x] Paczki startowe (0.17.0): `gry-wiedza/wiedza/starter-packs.md` (`gb doc starter-packs`) — paczki z biblioteki per szablon, strony autorów do rejestru; luki: kafelki platformówki 2D z boku, czcionki bez polskich znaków (zmierzone)

- [x] Rozdział repozytoriów (0.18.0): wiedza w gry-wiedza (`wiedza/`, czytana przez `gb doc`), narzędzie i instrukcja w game-builder; licencje: `LICENSE` (zastrzeżona), `THIRD_PARTY_NOTICES.md`; hooki sesji przepisane od zera (wcześniej adaptacja Sailes)

## Etap 5 — Szablony startowe gier
- [x] Platformówka 2D (0.4.0): ruch ze strojeniem, coyote time, bufor skoku, zmienny skok, poziom z monetami i metą, 3 testy + 8 scenariuszy
- [x] Top-down 2D (0.9.0): arena, strzelanie, fale, wrogowie z obrażeniami kontaktowymi, 3 testy + 8 scenariuszy T1–T8, dowody wykrycia
- [x] Puzzle na siatce (0.10.0): model + undo + solver BFS dowodzący rozwiązywalności poziomów, 6 testów + 4 scenariusze
- [x] Karty (0.11.0): walka karciana, energia, zamiary przeciwnika, dane kart, 11 testów (z kontraktem balansu) + 4 scenariusze
- [x] 3D: szablon `platformer-3d` (0.13.0) — ruch i skok w 3D, kamera na sprężynie przed ścianami, monety → meta; 7 scenariuszy D1–D7 + testy jednostkowe, Forward+ i Jolt
- [x] 3D: kamera orbitująca myszą/gałką — przepis 40 (0.14.0)
- [x] 3D: szablon strzelanki `fps-3d` (0.15.0) — widok z pierwszej osoby, strzał natychmiastowy, cele; szablony mogą dodawać własne akcje (strzał pod myszą)
- [ ] 3D: strzelanka z trzeciej osoby — do złożenia z platformer-3d + przepis 40 + broń z fps-3d, gdy gra tego potrzebuje

## Etap 6 — Role i pozostałe skille ✅ (0.6.0–0.8.0)
- [x] Role (celowo mało — pomiar CCGS: cięższy proces dał gorszą grę): `game-checker` (recenzja diffu względem specu, tylko odczyt), `game-tester` (testy ze specu przed kodem), `game-playtester` (uruchamia grę, zrzuty i dźwięk, Run result, pytania do człowieka), `game-researcher` (fakty ze źródłami); wpięte w game-implement/test/spec/pre-implement
- [x] Skille: game-audio, game-assets, game-playtest, game-diagnose, game-release
- [x] `gb export --smoke` (gotowy build uruchomiony bez okna, dowód wykrycia zasobu zgubionego przez filtr eksportu), `gb credits` (CREDITS.md z rejestru, blokada NC/ND/nieznanych licencji)
- [x] Skille (0.7.0): game-feel, game-balance, game-level-design, game-npc-ai, game-narrative, game-save, game-performance, game-ui-accessibility, game-vfx, game-upgrade
- [x] Przepisy wspierające skille: 36 kontrakty balansu (symulacja), 37 walidacja poziomów (softlocki), 38 test palety pod daltonizm — z dowodami wykrycia
- [x] Katalog modułów opcjonalnych — `docs/modules.md` (status, sposób, pułapki); wpięty w karty modułów game-bootstrap
- [x] Szablony: art bible, dokument audio, arkusz balansu, plan/raport playtestu, postmortem (budżet wydajności już w scaffoldzie: `.ai/perf-budget.json`)
- [x] Przepis 39 multiplayer (serwer autorytatywny, test w jednym procesie) — dalej: spawner/synchronizer

## Etap 7 — Evale ✅ (0.11.0–0.12.0)
- [x] 20 scenariuszy napisanych (evals/), test higieny formatu
- [x] Uruchomienie na świeżych subagentach (Sonnet, przebieg zastępczy) i ocena na artefaktach z dysku — `evals/RESULTS-2026-09-26.md`: końcowo 20/20 PASS; za pierwszym razem 3 FAIL (08, 09, 14) → poprawione skille/narzędzia → ponowne przebiegi PASS; 11 dodatkowych usterek pluginu znalezionych przy zaliczonych evalach, poprawionych w 0.12.0
- [x] Tryb procesu lekki/standard (0.17.0): `docs/rigor.md`, `gb scaffold --rigor`, karta decyzji w bootstrapie, router pokazuje pipeline trybu; kręgosłup bez zmian
- [ ] Później: ten sam zestaw na zainstalowanym pluginie (automatyczne wyzwalanie skilli, router sesji), na innym modelu, kilka powtórzeń; porównanie kosztu trybu lekkiego i standardowego

## Etap 8 — Dogfooding
- [x] Nowa mała gra od zera pluginem: **Lodowy Loch** (łamigłówka, 5 faz, 10 pięter, zapis, dźwięk). Człowiek przeszedł
      całość: „wszystko działa”. Wnioski wpisane do narzędzi i skilli w 0.12.1–0.12.2, raport w `docs/dogfood/lodowy-loch.md`.
- [ ] Pierwszy prawdziwy przebieg CI na GitHubie (repo gry jest lokalne — wysłanie decyduje właściciel)
- [ ] Pętla strojenia po werdykcie „tweak” i odpowiedzi na szczegółowe pytania z bramek (nie zostały sprawdzone)
- [ ] Adopcja NEMORAX — odłożona decyzją właściciela (wybrał nową grę)

## Etap 9 — Paczki gatunkowe (cel właściciela, 2026-09-27)
Cel: game-builder samodzielnie buduje **dobrą grę w gatunku** typu Hades, Call of Duty, Warcraft, Assassin's Creed —
w skali indie (dopracowana gra na 20–60 min), nie AAA. Mechaniki gatunku tak; postaci, nazwy i grafiki cudzych gier nie.
Każda paczka: **szablon** (mini-gra z testami) + **przepisy systemów gatunku** (kod + testy + dowody wykrycia) +
**dokument gatunku** w gry-wiedza/wiedza (`gb doc`) + **gra-dowód** zbudowana pluginem od zera.
Decyzje właściciela: kolejność Hades → FPS → RTS → akcja 3. osoby; gry-dowody „prawie bez bramek” (bot buduje
całość, człowiek gra w gotową wersję); assety najpierw darmowe (CC0 z biblioteki), płatne generatory tylko po „tak”
dla konkretnej partii.

### 9.1 Jak Hades — akcja z góry, roguelite (w toku)
- [x] Dokument gatunku `gry-wiedza/wiedza/genre-action-roguelite.md` (`gb doc genre-action-roguelite`): badanie 124 faktów z 84 źródeł (7 gier), zasady → przepisy (0.19.0)
- [x] Przepisy 47–52 (0.19.0): kombinacje ataków wręcz (okna, bufor, anulowanie), modyfikatory statystyk i „dary” (boony) z
      rzadkością i synergiami, reżyser spotkań (fale, budżet, drzwi), struktura runu (pokoje, nagrody, śmierć → hub,
      waluta między runami), bossowie z fazami i zapowiadanymi atakami, efekty statusów
- [x] Szablon `action-roguelite-3d` (0.20.0) (kamera izometryczna, ruch, zryw, kombinacje, 2 typy wrogów, pokoje z falami,
      wybór daru, boss, śmierć i nowy run, waluta) z bot-scenariuszami
- [x] Tryb pracy „autonomiczny” (0.21.0): bot decyduje polecanymi opcjami (zapisane do przeglądu), spec zatwierdza checker, bramki maszynowe + scenariusz „bot przechodzi grę”, człowiek gra w gotową grę; bez zmian: bezpieczeństwo, licencje, płatne assety za zgodą, commit na słowo
- [x] Gra-dowód zbudowana pluginem od zera + raport (0.23.0): **Ucieczka z Krypty**, zbudowana autonomicznie w jednej sesji, z darmowymi assetami. Ma 10 komnat, 4 typy wrogów + elitę, 18 darów, Strażnika z 3 fazami, menu i build Windows. Liczby: 126 testów, 31 scenariuszy, 31 mutacji, bot przechodzi grę na 3 ziarnach. Raport w `docs/dogfood/ucieczka-z-krypty.md`. Czeka na werdykt właściciela po zagraniu.
- [ ] `gb perf`: monitory TIME_PROCESS/TIME_PHYSICS_PROCESS w oknie nie są czasem CPU klatki (18/16 ms w pustej scenie przy klatce 4,17 ms) — zbadać i poprawić budżet
- [ ] `gb recipe add`: zależności używane tylko przez demo przepisu (np. demo przepisu 41 chodzi ruchem 2D z przepisu 01, więc gra FPS dostaje przepis 01) — oznaczać je jako demo-only albo usamodzielnić dema
### 9.2 Jak Call of Duty — FPS: broń (odrzut, rozrzut, celowanie, przeładowanie), AI z osłonami, poziomy (w toku)
- [x] Przepisy 53–57 (0.24.0):
  - obsługa broni: szybkostrzelność, magazynek, przeładowanie taktyczne i z pustego, rozrzut z rozgrzewaniem, celowanie
    (ADS), wzór odrzutu, spadek obrażeń z odległością;
  - hitscan ze strefami trafień (głowa / tułów / kończyny);
  - zdrowie z regeneracją i wskaźniki kierunku obrażeń;
  - wspomaganie celowania na padzie;
  - AI żołnierza z osłonami: wybór osłony, wychylanie, przygwożdżenie, obchodzenie, okrzyki, rosnąca celność.
  - `AttackTokens` przeniesione do przepisu 49 (wspólne dla walki wręcz i strzelców).
- [x] Dokument gatunku `gry-wiedza/wiedza/genre-military-fps.md` (`gb doc genre-military-fps`): 87 faktów z 47 źródeł (0.24.0)
- [x] Szablon `military-fps-3d` (0.25.0): misja od placu startowego przez dziedziniec, magazyn i radiostację do ewakuacji;
  broń z przepisów 53–56, żołnierze z przepisu 57 (okopani na starcie, posiłki z ukrycia), uczciwe spawny, punkty
  kontrolne; 10 scenariuszy (bot przechodzi misję), kontrakty TTK, śmiertelności i czytelności, 15 dowodów wykrywania
- [ ] Gra-dowód FPS zbudowana autonomicznie + raport
### 9.3 Jak Warcraft — RTS: zaznaczanie, rozkazy, surowce, budowanie, produkcja, mgła wojny, AI, wydajność
### 9.4 Jak Assassin's Creed — 3. osoba: wspinaczka/parkour, skradanie, walka z kontrami, tłum, duży świat
