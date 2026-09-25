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

## Etap 4 — Wiedza, fala 05
- [ ] Dokumentacja Godota w wersji przypiętej (gałąź 4.7, nie rozwojowa)
- [ ] Biblioteka przepisów mechanik (~45): problem, scena, kod GDScript 4, test, pułapki, źródło
- [ ] Pułapki Godota (`_process` vs `_physics_process`, współdzielone Resources, zmiany 3→4, warstwy kolizji…)
- [ ] Teoria projektowania (MDA, pętle, flow, krzywe trudności, game feel, level design, playtesty)
- [ ] Dokumentacja GUT/gdUnit4, platform (itch/butler, web, Android), pipeline assetów (Blender→glTF, Aseprite, LDtk/Tiled)
- [ ] Gry referencyjne open source w Godocie (MIT, z testami) zindeksowane
- [ ] Paczki startowe CC0 per gatunek z fal 1–4

## Etap 5 — Szablony startowe gier
- [x] Platformówka 2D (0.4.0): ruch ze strojeniem, coyote time, bufor skoku, zmienny skok, poziom z monetami i metą, 3 testy + 8 scenariuszy
- [ ] Top-down 2D, puzzle na siatce, 3D TPS/FPS, karty — każdy z testami i licencjami

## Etap 6 — Role i pozostałe skille
- [ ] Role: lead/producent, explorer, researcher, game-designer, art-director, gameplay-dev, ui-dev, tech-artist, level-designer, audio-integrator, tester, checker, playtester-qa, docs-author, balancer
- [ ] Skille: gry-assety, audio, animacja, feel, balans, level-design, ai-npc, narracja, zapis, wydajność, dostępność-lokalizacja, playtest, shadery-vfx, prawo/licencje, art-direction, ui, diagnose, release, docs, port, wayfinder
- [ ] Katalog modułów opcjonalnych (multiplayer, Steamworks, osiągnięcia, zapis w chmurze, mody, proceduralne…)
- [ ] Szablony: art bible, dokument audio, budżet wydajności, arkusz balansu, plan/raport playtestu, postmortem

## Etap 7 — Evale
- [ ] ~20 scenariuszy (zakres, licencje, API Godota 3, `_physics_process`, dane zamiast magicznych liczb, tester przed kodem, qa uruchamia grę, migracja zapisów…) + fixtures, sędzia sprawdzony na celowo zepsutej grze

## Etap 8 — Dogfooding
- [ ] Platformówka i top-down zbudowane pluginem; wnioski wpisane do skilli; adopcja NEMORAX
