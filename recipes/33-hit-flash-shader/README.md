# 33 — Hit flash (canvas_item shader)

**Problem:** `modulate = Color.WHITE` can't make a sprite *brighter* than its texture, so "flash white on hit" doesn't
work with modulate alone.

**Solution:** a tiny `canvas_item` shader mixes the texture colour toward `flash_color` by the `flash` uniform;
`HitFlash` gives its target **its own** `ShaderMaterial` and tweens `flash` 1 → 0 over ~0.15 s. Hook it to
`Health.damaged` (05).

**Shader basics to know:** `shader_type canvas_item` (2D) / `spatial` (3D); `uniform` = parameters set from code
(`set_shader_parameter`); `TEXTURE`, `UV`, `COLOR` built-ins; `hint_range`, `source_color` hints; instance uniforms
(`instance uniform float flash;`) avoid a material per sprite in large crowds (not supported on Compatibility for 2D —
check the renderer). Other staples: dissolve (noise texture + threshold), outline, palette swap, water distortion.

**Pitfalls:** a shared material (resource) flashing every enemy — `resource_local_to_scene` or a new material per
instance; web export uses the Compatibility renderer — test shaders there; tween on a node that gets paused.

**Test:** `tests/unit/test_r33_hit_flash.gd`.
