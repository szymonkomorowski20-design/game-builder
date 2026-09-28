class_name MilHud
extends CanvasLayer
## The mission HUD, built in code (placeholder look; swap the fonts and colours for art). It reads the mission and
## the player every frame. Genre doc §1, §3, §6:
##   - a crosshair whose gap is the gun's real spread (the same number that draws the shot); hidden while aiming
##     down sights or sprinting;
##   - hit markers graded body / head / kill;
##   - arcs showing where damage came from, and red screen edges growing as health drops (no health number);
##   - ammo, the gun, the objective and the enemies left; subtitles for the soldiers' barks, so the player hears
##     and reads their intent.
## Observable: subtitle, hit_marker, crosshair_gap, crosshair_visible, danger, banner.

const BARKS := {
	&"contact": "Kontakt! Tam jest!",
	&"reloading": "Przeładowuję!",
	&"flanking": "Obchodzę go!",
	&"suppressed": "Przygwożdżony!",
	&"man_down": "Straciliśmy jednego!",
}
const HIT_MARK_TIME := 0.2
const SUBTITLE_TIME := 2.2
const CONTROLS := "WASD ruch · mysz celowanie · LPM strzał · PPM przyłożenie broni · R przeładowanie\nShift bieg · C kucnięcie · Spacja skok · Q zmiana broni · E akcja · Esc kursor"
const VIGNETTE := "shader_type canvas_item;\nuniform float strength = 0.0;\nvoid fragment() {\n\tfloat r = length(UV - vec2(0.5)) * 1.41421;\n\tCOLOR = vec4(0.55, 0.0, 0.0, smoothstep(0.5, 1.0, r) * strength);\n}\n"

var mission: MilMission
var player: MilPlayer
var subtitle := ""
var hit_marker: StringName = &""
var crosshair_gap := 0.0
var crosshair_visible := true
var danger := 0.0
var banner := ""

var _sub_left := 0.0
var _hit_left := 0.0
var _banner_left := 0.0
var _overlay: Control
var _vignette: ColorRect
var _objective: Label
var _enemies: Label
var _ammo: Label
var _weapon: Label
var _subtitle: Label
var _banner: Label
var _prompt: Label
var _progress: ProgressBar
var _hint: Label
var _death: Label
var _complete: Label


func _ready() -> void:
	mission = get_parent() as MilMission
	_vignette = ColorRect.new()
	_vignette.set_anchors_preset(Control.PRESET_FULL_RECT)
	_vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sh := Shader.new()
	sh.code = VIGNETTE
	var sm := ShaderMaterial.new()
	sm.shader = sh
	_vignette.material = sm
	add_child(_vignette)
	_overlay = Control.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.draw.connect(_draw_overlay)
	add_child(_overlay)
	_objective = _label(Vector2(24, 18), 22, HORIZONTAL_ALIGNMENT_LEFT)
	_enemies = _label(Vector2(24, 50), 18, HORIZONTAL_ALIGNMENT_LEFT)
	_ammo = _label(Vector2(-24, -64), 30, HORIZONTAL_ALIGNMENT_RIGHT, Control.PRESET_BOTTOM_RIGHT)
	_weapon = _label(Vector2(-24, -100), 18, HORIZONTAL_ALIGNMENT_RIGHT, Control.PRESET_BOTTOM_RIGHT)
	_subtitle = _label(Vector2(0, -120), 22, HORIZONTAL_ALIGNMENT_CENTER, Control.PRESET_CENTER_BOTTOM)
	_banner = _label(Vector2(0, 140), 30, HORIZONTAL_ALIGNMENT_CENTER, Control.PRESET_CENTER_TOP)
	_prompt = _label(Vector2(0, 70), 20, HORIZONTAL_ALIGNMENT_CENTER, Control.PRESET_CENTER)
	_hint = _label(Vector2(0, -64), 16, HORIZONTAL_ALIGNMENT_CENTER, Control.PRESET_CENTER_BOTTOM)
	_hint.text = CONTROLS
	_death = _label(Vector2(0, -40), 40, HORIZONTAL_ALIGNMENT_CENTER, Control.PRESET_CENTER)
	_death.text = "Poległeś\nPowrót do punktu kontrolnego…"
	_death.visible = false
	_complete = _label(Vector2(0, -150), 26, HORIZONTAL_ALIGNMENT_CENTER, Control.PRESET_CENTER)
	_complete.visible = false
	_progress = ProgressBar.new()
	_progress.set_anchors_preset(Control.PRESET_CENTER)
	_progress.size = Vector2(260, 16)
	_progress.position = Vector2(-130, 110)
	_progress.show_percentage = false
	_progress.max_value = 1.0
	_progress.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_progress.visible = false
	_overlay.add_child(_progress)


func _label(offset: Vector2, font_size: int, align: HorizontalAlignment, preset := Control.PRESET_TOP_LEFT) -> Label:
	var l := Label.new()
	l.add_theme_font_size_override(&"font_size", font_size)
	l.add_theme_color_override(&"font_outline_color", Color(0, 0, 0, 0.85))
	l.add_theme_constant_override(&"outline_size", 6)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_overlay.add_child(l)
	l.set_anchors_preset(preset)
	var w := 900.0 if align == HORIZONTAL_ALIGNMENT_CENTER else 520.0
	l.size = Vector2(w, font_size * 4.0)
	match preset:
		Control.PRESET_TOP_LEFT:
			l.position = offset
		Control.PRESET_BOTTOM_RIGHT:
			l.grow_horizontal = Control.GROW_DIRECTION_BEGIN
			l.grow_vertical = Control.GROW_DIRECTION_BEGIN
			l.offset_left = offset.x - w
			l.offset_right = offset.x
			l.offset_top = offset.y - font_size * 1.5
			l.offset_bottom = offset.y + font_size * 1.5
		_:
			l.offset_left = -w * 0.5 + offset.x
			l.offset_right = w * 0.5 + offset.x
			l.offset_top = offset.y
			l.offset_bottom = offset.y + font_size * 4.0
	return l


func show_bark(_who: MilSoldier, kind: StringName) -> void:
	subtitle = "Żołnierz: " + String(BARKS.get(kind, String(kind)))
	_sub_left = SUBTITLE_TIME


func show_banner(text: String) -> void:
	banner = text
	_banner_left = 3.0


func show_death() -> void:
	_death.visible = true


func hide_death() -> void:
	_death.visible = false


func show_complete() -> void:
	var p := mission.player
	var acc := 0.0 if p.shots_fired == 0 else 100.0 * p.hits / p.shots_fired
	_complete.text = "MISJA WYKONANA\nCzas: %d:%02d\nCelność: %d%% (trafienia %d / strzały %d)\nStrzały w głowę: %d\nZabici: %d · Śmierci: %d\n\nE / Enter — jeszcze raz" % [
		floori(mission.elapsed / 60.0), int(mission.elapsed) % 60, roundi(acc), p.hits, p.shots_fired, p.headshots, p.kills, mission.deaths]
	_complete.visible = true


func _process(delta: float) -> void:
	if mission == null or mission.player == null:
		return
	player = mission.player
	if not player.hit_confirmed.is_connected(_on_hit):
		player.hit_confirmed.connect(_on_hit)
	_sub_left = maxf(_sub_left - delta, 0.0)
	_hit_left = maxf(_hit_left - delta, 0.0)
	_banner_left = maxf(_banner_left - delta, 0.0)
	if _sub_left <= 0.0:
		subtitle = ""
	if _hit_left <= 0.0:
		hit_marker = &""
	if _banner_left <= 0.0:
		banner = ""
	var g := player.gun()
	var complete := mission.stage == MilMission.Stage.COMPLETE
	_objective.text = "" if complete else "CEL: " + mission.objective_text()
	var left := mission.enemies_left()
	_enemies.text = "Wrogowie: %d" % left if left > 0 else ""
	_weapon.text = g.stats.resource_name if g.stats.resource_name != "" else ("Karabin" if player.gun_index == 0 else "Pistolet")
	if g.is_reloading():
		_ammo.text = "PRZEŁADOWANIE  %d / %d" % [g.ammo, g.reserve]
	elif g.ammo == 0 and g.reserve == 0:
		_ammo.text = "BRAK AMUNICJI"
	else:
		_ammo.text = "%d / %d" % [g.ammo, g.reserve]
	_subtitle.text = subtitle
	_banner.text = banner
	_hint.visible = mission.stage == MilMission.Stage.GATE
	var objective := mission.radio
	_progress.visible = objective.enabled and objective.player_inside() and not objective.done
	_progress.value = objective.progress
	_prompt.text = objective.prompt if _progress.visible else ""
	danger = player.health.danger()
	(_vignette.material as ShaderMaterial).set_shader_parameter(&"strength", danger)
	crosshair_visible = player.alive and not player.sprinting and g.ads < 0.6 and not complete
	var half_h := _overlay.size.y * 0.5
	crosshair_gap = 4.0 + tan(deg_to_rad(g.current_spread())) / tan(deg_to_rad(player.camera.fov * 0.5)) * half_h
	_overlay.queue_redraw()


func _on_hit(kind: StringName) -> void:
	hit_marker = kind
	_hit_left = HIT_MARK_TIME


func _draw_overlay() -> void:
	if player == null:
		return
	var c := _overlay.size * 0.5
	if crosshair_visible:
		var col := Color(1, 1, 1, 0.9)
		var gap := crosshair_gap
		for d: Vector2 in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
			_overlay.draw_line(c + d * gap, c + d * (gap + 10.0), col, 2.0)
	elif player.alive and player.gun().ads >= 0.6:
		_overlay.draw_circle(c, 3.5, Color(0, 0, 0, 0.6))
		_overlay.draw_circle(c, 2.0, Color(1, 1, 1, 0.95))
	if hit_marker != &"":
		var kill := hit_marker == &"kill"
		var col := Color(1, 0.2, 0.15) if kill else (Color(1, 0.8, 0.2) if hit_marker == &"head" else Color(1, 1, 1))
		var r0 := 7.0 if not kill else 9.0
		var r1 := 15.0 if not kill else 20.0
		for d: Vector2 in [Vector2(1, 1), Vector2(-1, 1), Vector2(1, -1), Vector2(-1, -1)]:
			var n := d.normalized()
			_overlay.draw_line(c + n * r0, c + n * r1, col, 3.0 if kill else 2.0)
	for ind in player.indicators.indicators:
		var a := deg_to_rad(float(ind.angle)) - PI * 0.5
		var col := Color(1, 0.15, 0.1, player.indicators.alpha(ind) * 0.9)
		_overlay.draw_arc(c, 120.0, a - 0.32, a + 0.32, 18, col, 7.0)
