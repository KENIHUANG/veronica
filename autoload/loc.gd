extends Node
## 本地化与设置:中文 / English。文案以中文原文作键,英文在 scripts/en_strings.gd。
## L.t("中文") → 当前语言的文本;L.f("... {n} ...", {"n": 3}) → 带占位符。

signal changed

const EN := preload("res://scripts/en_strings.gd")
const SETTINGS_PATH := "user://settings.json"

var lang := "zh"
var touch_mode := "auto"      # auto / on / off
var reduce_flash := false
var retro := true            # PS1 复古画面

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var loc := OS.get_locale_language()
	lang = "zh" if loc.begins_with("zh") else "en"
	_load()

func t(s: String) -> String:
	if lang == "zh" or s == "":
		return s
	return EN.MAP.get(s, s)

func f(key: String, vals: Dictionary) -> String:
	var r := t(key)
	for k in vals:
		r = r.replace("{%s}" % k, str(vals[k]))
	return r

func set_lang(l: String) -> void:
	lang = l
	save()
	for n in get_tree().get_nodes_in_group("loc3d"):
		if n.has_meta("zh"):
			n.text = t(n.get_meta("zh"))
	changed.emit()

func toggle_lang() -> void:
	set_lang("en" if lang == "zh" else "zh")

func save() -> void:
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"lang": lang, "touch": touch_mode, "reduce_flash": reduce_flash, "retro": retro}))

func _load() -> void:
	if not FileAccess.file_exists(SETTINGS_PATH):
		return
	var f := FileAccess.open(SETTINGS_PATH, FileAccess.READ)
	if f == null:
		return
	var d = JSON.parse_string(f.get_as_text())
	if typeof(d) != TYPE_DICTIONARY:
		return
	lang = d.get("lang", lang)
	touch_mode = d.get("touch", "auto")
	reduce_flash = d.get("reduce_flash", false)
	retro = d.get("retro", true)
