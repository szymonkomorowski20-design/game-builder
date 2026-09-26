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
- [ ] Evale uruchomione na świeżych subagentach (wymaga zgody na uruchamianie subagentów)

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
- [ ] Werdykt gracza z bramek fazy 2 i 3 Ponga + nagranie meczu (czeka na człowieka)

## Etap 4 — Wiedza, fala 05 (0.5.0 — w toku)
- [x] Dokumentacja Godota w wersji przypiętej (gałąź 4.7) — w BAZA-AI (fala 05) + referencja zmian 4.4–4.7 z oficjalnych przewodników migracji
- [x] Biblioteka przepisów mechanik: 35 z 98 testami GUT i 11 scenariuszami; `gb recipe list/add` kopiuje je z testami do gry (dowód e2e)
- [ ] Kolejne przepisy do ~45: AnimationTree, multiplayer, checkpointy, ruchome platformy, dash/knockback, minimapa, dostępność
- [x] Pułapki Godota — `skills/game-implement/godot-pitfalls.md` (zmierzone, z poprawkami)
- [x] Audio: skill `game-audio`, przepisy 34–35, `gb shot --movie` z pomiarem dźwięku; fala 05 biblioteki (paczki CC0/MIT/CC-BY, licencje)
- [x] Z Claude Code Game Studios (MIT): dowód wizualny „Run result” w game-implement, zrzuty przez Movie Maker
- [ ] Teoria projektowania (MDA, pętle, flow, krzywe trudności, game feel, level design, playtesty)
- [ ] Dokumentacja GUT/gdUnit4, platform (itch/butler, web, Android), pipeline assetów (Blender→glTF, Aseprite, LDtk/Tiled)
- [ ] Gry referencyjne open source w Godocie (MIT, z testami) zindeksowane
- [ ] Paczki startowe CC0 per gatunek z fal 1–4

## Etap 5 — Szablony startowe gier
- [x] Platformówka 2D (0.4.0): ruch ze strojeniem, coyote time, bufor skoku, zmienny skok, poziom z monetami i metą, 3 testy + 8 scenariuszy
- [x] Top-down 2D (0.9.0): arena, strzelanie, fale, wrogowie z obrażeniami kontaktowymi, 3 testy + 8 scenariuszy T1–T8, dowody wykrycia
- [ ] Puzzle na siatce, karty, 3D TPS/FPS — każdy z testami i licencjami

## Etap 6 — Role i pozostałe skille (0.6.0 — w toku)
- [x] Role (celowo mało — pomiar CCGS: cięższy proces dał gorszą grę): `game-checker` (recenzja diffu względem specu, tylko odczyt), `game-tester` (testy ze specu przed kodem), `game-playtester` (uruchamia grę, zrzuty i dźwięk, Run result, pytania do człowieka), `game-researcher` (fakty ze źródłami); wpięte w game-implement/test/spec/pre-implement
- [x] Skille: game-audio, game-assets, game-playtest, game-diagnose, game-release
- [x] `gb export --smoke` (gotowy build uruchomiony bez okna, dowód wykrycia zasobu zgubionego przez filtr eksportu), `gb credits` (CREDITS.md z rejestru, blokada NC/ND/nieznanych licencji)
- [x] Skille (0.7.0): game-feel, game-balance, game-level-design, game-npc-ai, game-narrative, game-save, game-performance, game-ui-accessibility, game-vfx, game-upgrade
- [x] Przepisy wspierające skille: 36 kontrakty balansu (symulacja), 37 walidacja poziomów (softlocki), 38 test palety pod daltonizm — z dowodami wykrycia
- [x] Katalog modułów opcjonalnych — `docs/modules.md` (status, sposób, pułapki); wpięty w karty modułów game-bootstrap
- [x] Szablony: art bible, dokument audio, arkusz balansu, plan/raport playtestu, postmortem (budżet wydajności już w scaffoldzie: `.ai/perf-budget.json`)
- [x] Przepis 39 multiplayer (serwer autorytatywny, test w jednym procesie) — dalej: spawner/synchronizer

## Etap 7 — Evale
- [ ] ~20 scenariuszy (zakres, licencje, API Godota 3, `_physics_process`, dane zamiast magicznych liczb, tester przed kodem, qa uruchamia grę, migracja zapisów…) + fixtures, sędzia sprawdzony na celowo zepsutej grze

## Etap 8 — Dogfooding
- [ ] Platformówka i top-down zbudowane pluginem; wnioski wpisane do skilli; adopcja NEMORAX
