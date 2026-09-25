# Assets & licences checklist

For every asset entering `assets/` (art, models, animations, audio, fonts, shaders from others):
- [ ] Source URL / local path in the gry-wiedza library, author, licence, date → a row in `.ai/assets/REGISTER.md`, same commit.
- [ ] Licence allows the intended release (commercial? redistribution in a build?):
  - CC0 / public domain — fine, attribution optional (record it anyway).
  - CC BY — fine with attribution in the credits screen/file.
  - MIT / Unlicense (code or assets) — keep the licence text in the repo.
  - CC BY-NC / "non-commercial" / PolyForm NC — only for non-commercial releases.
  - "Free", "royalty-free as far as I know", no licence file — prototype only; replace before release.
  - Ready Player Me animations — only with Ready Player Me avatars, no redistribution.
  - Anything from a commercial game (ripped sprites/sounds) — never.
- [ ] Fonts: separate licence (OFL is fine; include the licence text).
- [ ] AI-generated assets: record the tool and its terms; check the target store's policy.
- [ ] Imported with the right settings (pixel art: nearest filter; audio loops flagged; 3D scale checked).
