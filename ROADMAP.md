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

## Etap 2 — Warstwa weryfikacji
- [ ] Instalacja GUT / gdUnit4 do `addons/` (przypięta wersja zgodna z 4.7) przez `gb`, runner w `gb test`, raport JUnit/JSON
- [ ] Determinizm: stały krok fizyki, ziarno RNG w trybie testu
- [ ] Nagrywanie i odtwarzanie wejścia (replay) + bot-gracz (skrypty scenariuszy: „idź w prawo 2 s, skocz”) z asercjami stanu
- [ ] Zrzuty ekranu w trybie Movie Maker (`--write-movie`, `--fixed-fps`) + porównanie z baseline + ocena wizualna modelem
- [ ] Pomiar wydajności (monitory Performance → JSON) i budżety
- [ ] Walidatory: zepsute `res://`, assety spoza rejestru licencji, nieużywane assety, rozmiary tekstur, API Godota 3
- [ ] Test eksportu (`--export-release`) na Windows i web
- [ ] Hooki w repo gry: lint/format (gdtoolkit) po edycji, szybkie testy przy zakończeniu
- [ ] CI (GitHub Actions) z Godotem: verify + eksport
- [ ] Ocena gotowych serwerów MCP dla Godota

## Etap 3 — Spec → implement → test
- [ ] `game-spec` (globalny odpowiednik lokalnego spec-writing), `game-pre-implement`, `game-implement`, `game-test`
- [ ] Bramka „człowiek zagrał” w implementacji, run log, STATUS.md na bramkach
- [ ] Dowód: klon Ponga zbudowany wyłącznie pluginem

## Etap 4 — Wiedza, fala 05
- [ ] Dokumentacja Godota w wersji przypiętej (gałąź 4.7, nie rozwojowa)
- [ ] Biblioteka przepisów mechanik (~45): problem, scena, kod GDScript 4, test, pułapki, źródło
- [ ] Pułapki Godota (`_process` vs `_physics_process`, współdzielone Resources, zmiany 3→4, warstwy kolizji…)
- [ ] Teoria projektowania (MDA, pętle, flow, krzywe trudności, game feel, level design, playtesty)
- [ ] Dokumentacja GUT/gdUnit4, platform (itch/butler, web, Android), pipeline assetów (Blender→glTF, Aseprite, LDtk/Tiled)
- [ ] Gry referencyjne open source w Godocie (MIT, z testami) zindeksowane
- [ ] Paczki startowe CC0 per gatunek z fal 1–4

## Etap 5 — Szablony startowe gier
- [ ] Platformówka 2D, top-down 2D, puzzle na siatce, 3D TPS/FPS, karty — każdy z testami i licencjami

## Etap 6 — Role i pozostałe skille
- [ ] Role: lead/producent, explorer, researcher, game-designer, art-director, gameplay-dev, ui-dev, tech-artist, level-designer, audio-integrator, tester, checker, playtester-qa, docs-author, balancer
- [ ] Skille: gry-assety, audio, animacja, feel, balans, level-design, ai-npc, narracja, zapis, wydajność, dostępność-lokalizacja, playtest, shadery-vfx, prawo/licencje, art-direction, ui, diagnose, release, docs, port, wayfinder
- [ ] Katalog modułów opcjonalnych (multiplayer, Steamworks, osiągnięcia, zapis w chmurze, mody, proceduralne…)
- [ ] Szablony: art bible, dokument audio, budżet wydajności, arkusz balansu, plan/raport playtestu, postmortem

## Etap 7 — Evale
- [ ] ~20 scenariuszy (zakres, licencje, API Godota 3, `_physics_process`, dane zamiast magicznych liczb, tester przed kodem, qa uruchamia grę, migracja zapisów…) + fixtures, sędzia sprawdzony na celowo zepsutej grze

## Etap 8 — Dogfooding
- [ ] Platformówka i top-down zbudowane pluginem; wnioski wpisane do skilli; adopcja NEMORAX
