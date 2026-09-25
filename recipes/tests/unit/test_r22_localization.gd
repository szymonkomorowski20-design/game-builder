extends GutTest
## R22 — switching locale changes tr() results, placeholders are filled after translation,
## a missing translation falls back to English, unknown keys come back unchanged (visible in QA).

var _added: Array[Translation] = []
var _locale := ""


func before_each() -> void:
	_locale = TranslationServer.get_locale()
	_added = LocaleLoader.load_csv("res://22-localization/strings.csv")
	for t in _added:
		TranslationServer.add_translation(t)
	ProjectSettings.set_setting("internationalization/locale/fallback", "en")


func after_each() -> void:
	for t in _added:
		TranslationServer.remove_translation(t)
	TranslationServer.set_locale(_locale)


func test_r22_switch_locale() -> void:
	TranslationServer.set_locale("en")
	assert_eq(tr("MENU_PLAY"), "Play")
	TranslationServer.set_locale("pl")
	assert_eq(tr("MENU_PLAY"), "Graj")


func test_r22_placeholders_after_translation() -> void:
	TranslationServer.set_locale("pl")
	assert_eq(tr("HUD_COINS").format({"n": 12}), "Monety: 12")
	assert_eq(tr("GREETING").format({"name": "Ala"}), "Cześć, Ala!", "quoted CSV cell with a comma")


func test_r22_fallback_and_unknown_key() -> void:
	TranslationServer.set_locale("pl")
	assert_eq(tr("ONLY_EN"), "Only in English", "empty pl cell → English")
	assert_eq(tr("NOT_A_KEY"), "NOT_A_KEY", "missing keys stay visible as keys")
