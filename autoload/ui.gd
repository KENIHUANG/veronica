extends CanvasLayer
## 所有界面:HUD、对白、提示、背包、阅读器、保险箱、拼图、调配、终端、标题、结局。

const Draw = preload("res://scripts/draw.gd")

signal title_new
signal title_continue
signal retry_requested
signal quit_to_title
signal modal_closed
signal dialogue_finished

var reduce_flash := false
var hud_on := false

var hud_root: Control
var prompt_label: Label
var toast_label: Label
var obj_label: Label
var hp_label: Label
var hp_pips: Array = []
var hideables: Array = []
var bar_top: ColorRect
var bar_bottom: ColorRect
var crosshair: Label
var overlay: ColorRect
var dlg_panel: PanelContainer
var dlg_name: Label
var dlg_text: RichTextLabel
var qte_panel: PanelContainer
var qte_bar: ProgressBar
var qte_label: Label

var modal: Control = null
var modal_on_close := Callable()
const GAME_VERSION := "v11.1"
var letters_label: Label = null
var title_ui: Control = null
var screen_ui: Control = null
var screen_kind := ""
var intro_ui: Control = null
var intro_label: RichTextLabel = null

var dlg_active := false
var dlg_queue: Array = []
var dlg_cb := Callable()
var _typing := false
var _chars := 0.0
var _toast_t := 0.0

var _qte_active := false
var _qte_count := 0
var _qte_need := 0
var _qte_left := 0.0
var _qte_time := 1.0
var _qte_ok := Callable()
var _qte_fail := Callable()

var _intro_paras: Array = []
var _intro_idx := 0
var _intro_typing := false
var _intro_chars := 0.0
var _intro_cb := Callable()

func _ready() -> void:
	layer = 10
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_hud()
	GS.hp_changed.connect(_refresh_hp)
	L.changed.connect(_on_lang_changed)
	Touch.changed.connect(_on_lang_changed)
	reduce_flash = L.reduce_flash
	GS.flag_changed.connect(func(_f): refresh_objective())
	GS.inventory_changed.connect(refresh_objective)
	_refresh_hp()

# ======================= helpers =======================
func _style(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(2)
	s.set_content_margin_all(14)
	s.set_corner_radius_all(2)
	return s

func _label(text: String, size: int = 18, color: Color = Color(0.85, 0.85, 0.8)) -> Label:
	var l := Label.new()
	l.text = L.t(text)
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", color)
	return l

func _full(c: Control) -> void:
	c.set_anchors_preset(Control.PRESET_FULL_RECT)

func _button(text: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = L.t(text)
	b.custom_minimum_size = Vector2(190, 42)
	b.pressed.connect(cb)
	return b

# ======================= HUD =======================
func _build_hud() -> void:
	var vig := ColorRect.new()
	vig.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(vig)
	var sh := Shader.new()
	sh.code = """
shader_type canvas_item;
uniform float vignette = 0.6;
uniform float grain = 0.03;
float rnd(vec2 p) { return fract(sin(dot(p, vec2(12.9898, 78.233))) * 43758.5453); }
void fragment() {
	float d = distance(UV, vec2(0.5));
	float v = smoothstep(0.32, 0.9, d) * vignette;
	float g = (rnd(UV * 900.0 + vec2(TIME * 31.0, TIME * 17.0)) - 0.5) * grain;
	float ag = abs(g);
	float a = ag + v * (1.0 - ag);
	COLOR = vec4(vec3(step(0.0, g)) * ag / max(a, 0.0001), a);
}
"""
	var mat := ShaderMaterial.new()
	mat.shader = sh
	vig.material = mat
	add_child(vig)

	hud_root = Control.new()
	hud_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(hud_root)
	add_child(hud_root)

	crosshair = _label("·", 26, Color(0.9, 0.9, 0.9, 0.55))
	crosshair.set_anchors_preset(Control.PRESET_CENTER)
	crosshair.position = Vector2(-4, -20)
	hud_root.add_child(crosshair)

	prompt_label = _label("", 20, Color(1.0, 0.92, 0.75))
	prompt_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_anchor_bottom(prompt_label, 700, 36, 150)
	hud_root.add_child(prompt_label)

	toast_label = _label("", 20, Color(0.95, 0.85, 0.6))
	toast_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	toast_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	toast_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	toast_label.add_theme_constant_override("outline_size", 6)
	_anchor_bottom(toast_label, 900, 90, 190)
	hud_root.add_child(toast_label)

	obj_label = _label("", 16, Color(0.6, 0.85, 0.6))
	obj_label.position = Vector2(20, 16)
	obj_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	obj_label.add_theme_constant_override("outline_size", 5)
	letters_label = _label("", 15, Color(0.95, 0.85, 0.55))
	letters_label.position = Vector2(20, 40)
	letters_label.add_theme_color_override("font_outline_color", Color(0, 0, 0))
	letters_label.add_theme_constant_override("outline_size", 5)
	hud_root.add_child(letters_label)
	hud_root.add_child(obj_label)

	var hp_box := HBoxContainer.new()
	hp_box.add_theme_constant_override("separation", 4)
	hp_box.anchor_top = 1.0
	hp_box.anchor_bottom = 1.0
	hp_box.offset_left = 22
	hp_box.offset_top = -52
	hp_box.offset_bottom = -22
	hud_root.add_child(hp_box)
	hp_label = _label("良好", 18, Color(0.4, 0.9, 0.4))
	hp_box.add_child(hp_label)
	for i in GS.MAX_HP:
		var r := ColorRect.new()
		r.custom_minimum_size = Vector2(22, 12)
		hp_box.add_child(r)
		hp_pips.append(r)

	# 对白框
	dlg_panel = PanelContainer.new()
	dlg_panel.anchor_left = 0.1
	dlg_panel.anchor_right = 0.9
	dlg_panel.anchor_top = 1.0
	dlg_panel.anchor_bottom = 1.0
	dlg_panel.offset_top = -210
	dlg_panel.offset_bottom = -40
	dlg_panel.add_theme_stylebox_override("panel", _style(Color(0.03, 0.03, 0.04, 0.92), Color(0.55, 0.1, 0.1)))
	dlg_panel.visible = false
	hud_root.add_child(dlg_panel)
	var vb := VBoxContainer.new()
	dlg_panel.add_child(vb)
	dlg_name = _label("", 18, Color(1.0, 0.65, 0.3))
	vb.add_child(dlg_name)
	dlg_text = RichTextLabel.new()
	dlg_text.bbcode_enabled = true
	dlg_text.scroll_active = false
	dlg_text.custom_minimum_size = Vector2(0, 90)
	dlg_text.size_flags_vertical = Control.SIZE_EXPAND_FILL
	dlg_text.add_theme_font_size_override("normal_font_size", 20)
	vb.add_child(dlg_text)
	var hint := _label("[E] 继续", 13, Color(0.5, 0.5, 0.5))
	hint.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	vb.add_child(hint)

	# QTE
	qte_panel = PanelContainer.new()
	qte_panel.set_anchors_preset(Control.PRESET_CENTER)
	qte_panel.offset_left = -200
	qte_panel.offset_right = 200
	qte_panel.offset_top = 60
	qte_panel.offset_bottom = 170
	qte_panel.add_theme_stylebox_override("panel", _style(Color(0.1, 0.0, 0.0, 0.9), Color(0.9, 0.2, 0.2)))
	qte_panel.visible = false
	hud_root.add_child(qte_panel)
	var qv := VBoxContainer.new()
	qte_panel.add_child(qv)
	qte_label = _label("", 22, Color(1, 0.8, 0.8))
	qte_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	qv.add_child(qte_label)
	qte_bar = ProgressBar.new()
	qte_bar.max_value = 1.0
	qte_bar.show_percentage = false
	qte_bar.custom_minimum_size = Vector2(0, 22)
	qv.add_child(qte_bar)

	bar_top = ColorRect.new()
	bar_top.color = Color.BLACK
	bar_top.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_top.anchor_right = 1.0
	bar_top.offset_bottom = 0.0
	add_child(bar_top)
	bar_bottom = ColorRect.new()
	bar_bottom.color = Color.BLACK
	bar_bottom.mouse_filter = Control.MOUSE_FILTER_IGNORE
	bar_bottom.anchor_top = 1.0
	bar_bottom.anchor_right = 1.0
	bar_bottom.anchor_bottom = 1.0
	bar_bottom.offset_top = 0.0
	add_child(bar_bottom)
	hideables = [crosshair, prompt_label, obj_label, hp_box]
	overlay = ColorRect.new()
	overlay.color = Color(0, 0, 0, 0)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_full(overlay)
	add_child(overlay)

func _anchor_bottom(c: Control, w: float, h: float, margin: float) -> void:
	c.anchor_left = 0.5
	c.anchor_right = 0.5
	c.anchor_top = 1.0
	c.anchor_bottom = 1.0
	c.offset_left = -w / 2.0
	c.offset_right = w / 2.0
	c.offset_top = -(margin + h)
	c.offset_bottom = -margin

func _on_lang_changed() -> void:
	refresh_objective()
	_refresh_hp()
	if screen_kind == "pause":
		show_pause()
	elif title_ui != null:
		show_title(GS.has_save())

## 键位提示前缀:键鼠显示 [E],触屏显示 ●
func key_hint() -> String:
	return "● " if Touch.enabled else "[E]  "

func capture_mouse() -> void:
	if Touch.enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func set_hud_visible(v: bool) -> void:
	hud_on = v
	hud_root.visible = v
	refresh_objective()
	_refresh_hp()

func set_prompt(t: String) -> void:
	if prompt_label.text != t:
		prompt_label.text = t

func refresh_objective() -> void:
	if obj_label:
		obj_label.text = L.t("目标:") + L.t(GS.objective())
	if letters_label:
		var n := 0
		for i in 5:
			if GS.has_flag("letter_%d" % i):
				n += 1
		letters_label.text = "✉ " + L.f("镇民来信 {n}/{t}", {"n": n, "t": 5})

func _refresh_hp() -> void:
	if hp_pips.is_empty():
		return
	var col := Color(0.35, 0.9, 0.35)
	var txt := "良好"
	if GS.hp <= 1:
		col = Color(0.95, 0.15, 0.15)
		txt = "危险"
	elif GS.hp <= 3:
		col = Color(0.95, 0.75, 0.2)
		txt = "注意"
	hp_label.text = L.t(txt)
	hp_label.add_theme_color_override("font_color", col)
	for i in hp_pips.size():
		hp_pips[i].color = col if i < GS.hp else Color(0.15, 0.15, 0.15)
	SFX.loop("heart", hud_on and GS.hp <= 2 and GS.hp > 0, -8.0)

func toast(text: String, dur: float = 3.0) -> void:
	toast_label.text = L.t(text)
	toast_label.modulate.a = 1.0
	_toast_t = dur

func flash(color: Color, dur: float = 0.5) -> void:
	if reduce_flash:
		color.a *= 0.2
	overlay.color = color
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", 0.0, dur)

func fade_to(alpha: float, dur: float = 1.0) -> void:
	overlay.color = Color(0, 0, 0, overlay.color.a)
	var tw := create_tween()
	tw.tween_property(overlay, "color:a", alpha, dur)
	await tw.finished

## 演出模式:上下黑边滑入,隐藏准星/目标/血量
func set_cinematic(on: bool, dur: float = 0.8) -> void:
	for h in hideables:
		if h != null:
			h.visible = not on
	var tw := create_tween().set_parallel(true)
	tw.tween_property(bar_top, "offset_bottom", 86.0 if on else 0.0, dur)
	tw.tween_property(bar_bottom, "offset_top", -86.0 if on else 0.0, dur)

func blocked() -> bool:
	return modal != null or dlg_active or _qte_active or title_ui != null or screen_ui != null or intro_ui != null

# ======================= 对白 =======================
## lines 中每条可写成 "说话人|内容" 或纯文本旁白
func say(lines: Array, cb: Callable = Callable()) -> void:
	for l in lines:
		dlg_queue.append(l)
	if cb.is_valid():
		dlg_cb = cb
	if not dlg_active:
		dlg_active = true
		dlg_panel.visible = true
		_next_line()

func _next_line() -> void:
	if dlg_queue.is_empty():
		dlg_active = false
		dlg_panel.visible = false
		var cb := dlg_cb
		dlg_cb = Callable()
		dialogue_finished.emit()
		if cb.is_valid():
			cb.call()
		return
	var s: String = L.t(dlg_queue.pop_front())
	var who := ""
	var txt := s
	if "|" in s:
		var parts := s.split("|", true, 1)
		who = parts[0]
		txt = parts[1]
	else:
		txt = "[i]" + s + "[/i]"
	dlg_name.text = who
	dlg_text.text = txt
	dlg_text.visible_characters = 0
	_chars = 0.0
	_typing = true

func _advance_dialogue() -> void:
	if _typing:
		_typing = false
		dlg_text.visible_characters = -1
	else:
		_next_line()

# ======================= QTE =======================
var _qte_verb := "刺入"

## verb:屏幕上显示的动作("刺入" / "拧紧"),对应翻译键 "连按 [E] <verb>!  {a}/{b}"
func qte(need: int, time_limit: float, on_ok: Callable, on_fail: Callable, verb: String = "刺入") -> void:
	_qte_verb = verb
	_qte_active = true
	_qte_count = 0
	_qte_need = need
	_qte_time = time_limit
	_qte_left = time_limit
	_qte_ok = on_ok
	_qte_fail = on_fail
	qte_panel.visible = true
	qte_label.text = _qte_text(0)
	qte_bar.value = 1.0

func _qte_text(n: int) -> String:
	if _qte_verb == "拧紧":
		return L.f("连按 ● 拧紧!  {a}/{b}" if Touch.enabled else "连按 [E] 拧紧!  {a}/{b}", {"a": n, "b": _qte_need})
	return L.f("连按 ● 刺入!  {a}/{b}" if Touch.enabled else "连按 [E] 刺入!  {a}/{b}", {"a": n, "b": _qte_need})

func _qte_press() -> void:
	_qte_count += 1
	SFX.play("click")
	qte_label.text = _qte_text(_qte_count)
	if _qte_count >= _qte_need:
		_qte_active = false
		qte_panel.visible = false
		_qte_ok.call()

func _process(delta: float) -> void:
	if _typing:
		_chars += delta * 48.0
		dlg_text.visible_characters = int(_chars)
		if int(_chars) >= dlg_text.get_total_character_count():
			_typing = false
			dlg_text.visible_characters = -1
	if _toast_t > 0.0:
		_toast_t -= delta
		if _toast_t < 0.6:
			toast_label.modulate.a = maxf(0.0, _toast_t / 0.6)
		if _toast_t <= 0.0:
			toast_label.text = ""
	if _qte_active:
		_qte_left -= delta
		qte_bar.value = maxf(0.0, _qte_left / _qte_time)
		if _qte_left <= 0.0:
			_qte_active = false
			qte_panel.visible = false
			_qte_fail.call()
	if _intro_typing and intro_label != null:
		_intro_chars += delta * 30.0
		intro_label.visible_characters = int(_intro_chars)
		if int(_intro_chars) >= intro_label.get_total_character_count():
			_intro_typing = false
			intro_label.visible_characters = -1

# ======================= 输入 =======================
func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		var k: int = event.keycode
		if k == KEY_ESCAPE:
			if modal != null:
				close_modal()
				get_viewport().set_input_as_handled()
				return
			if screen_kind == "pause":
				hide_screen()
				get_viewport().set_input_as_handled()
				return
		if _qte_active and (k == KEY_E or k == KEY_SPACE):
			_qte_press()
			get_viewport().set_input_as_handled()
			return
		if dlg_active and (k == KEY_E or k == KEY_ENTER or k == KEY_SPACE):
			_advance_dialogue()
			get_viewport().set_input_as_handled()
			return
		if intro_ui != null and (k == KEY_E or k == KEY_ENTER or k == KEY_SPACE):
			_advance_intro()
			get_viewport().set_input_as_handled()
			return
		if screen_kind == "gameover" and k == KEY_R:
			hide_screen()
			retry_requested.emit()
			get_viewport().set_input_as_handled()
			return
		if screen_kind == "end" and k == KEY_R:
			hide_screen()
			quit_to_title.emit()
			get_viewport().set_input_as_handled()
			return
	elif event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if dlg_active:
			_advance_dialogue()
			get_viewport().set_input_as_handled()
		elif intro_ui != null:
			_advance_intro()
			get_viewport().set_input_as_handled()

# ======================= 模态窗口 =======================
func _open_modal(title: String, min_size: Vector2 = Vector2(760, 470)) -> VBoxContainer:
	close_modal()
	modal = Control.new()
	_full(modal)
	modal.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(modal)
	var dim := ColorRect.new()
	dim.color = Color(0, 0, 0, 0.8)
	_full(dim)
	modal.add_child(dim)
	var cc := CenterContainer.new()
	_full(cc)
	modal.add_child(cc)
	var pc := PanelContainer.new()
	pc.custom_minimum_size = min_size
	pc.add_theme_stylebox_override("panel", _style(Color(0.06, 0.06, 0.07, 0.97), Color(0.5, 0.12, 0.12)))
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	vb.add_child(_label(title, 22, Color(0.9, 0.75, 0.5)))
	vb.add_child(HSeparator.new())
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return vb

func close_modal() -> void:
	if modal == null:
		return
	modal.queue_free()
	modal = null
	var cb := modal_on_close
	modal_on_close = Callable()
	if hud_on and title_ui == null and screen_ui == null:
		capture_mouse()
	modal_closed.emit()
	if cb.is_valid():
		cb.call()

func _add_close(vb: VBoxContainer, text: String = "关闭 (Esc)") -> void:
	vb.add_child(_button(text, close_modal))

# ---- 背包 ----
func open_inventory(on_use: Callable) -> void:
	var vb := _open_modal("物品   (Esc 关闭)")
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	vb.add_child(hb)
	var list := ItemList.new()
	list.custom_minimum_size = Vector2(260, 300)
	hb.add_child(list)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	var name_l := _label("", 22, Color(1, 0.85, 0.5))
	right.add_child(name_l)
	var desc := RichTextLabel.new()
	desc.custom_minimum_size = Vector2(0, 220)
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_font_size_override("normal_font_size", 18)
	right.add_child(desc)
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(160, 38)
	btn.visible = false
	right.add_child(btn)
	var ids: Array = GS.items.duplicate()
	var sel := {"i": -1}
	if ids.is_empty():
		desc.text = L.t("(什么也没有)")
	for id in ids:
		list.add_item(L.t(GS.ITEMS[id]["name"]))
	list.item_selected.connect(func(i: int):
		sel["i"] = i
		var d: Dictionary = GS.ITEMS[ids[i]]
		name_l.text = L.t(d["name"])
		desc.text = L.t(d["desc"])
		btn.visible = d.has("verb")
		btn.text = L.t(d.get("verb", ""))
	)
	btn.pressed.connect(func():
		if sel["i"] >= 0:
			var id: String = ids[sel["i"]]
			close_modal()
			on_use.call(id)
	)
	if not ids.is_empty():
		list.select(0)
		list.item_selected.emit(0)
	_add_close(vb)

# ---- 阅读器(日记/笔记) ----
func open_reader(title: String, pages: Array, on_close: Callable = Callable()) -> void:
	var vb := _open_modal(title)
	modal_on_close = on_close
	var txt := RichTextLabel.new()
	txt.bbcode_enabled = true
	txt.custom_minimum_size = Vector2(0, 300)
	txt.size_flags_vertical = Control.SIZE_EXPAND_FILL
	txt.add_theme_font_size_override("normal_font_size", 20)
	vb.add_child(txt)
	var nav := HBoxContainer.new()
	nav.alignment = BoxContainer.ALIGNMENT_CENTER
	vb.add_child(nav)
	var prev := Button.new()
	prev.text = "◀ 上一页"
	var nxt := Button.new()
	nxt.text = "下一页 ▶"
	var pg := _label("", 16)
	nav.add_child(prev)
	nav.add_child(pg)
	nav.add_child(nxt)
	var st := {"i": 0}
	var refresh := func():
		txt.text = L.t(pages[st["i"]])
		pg.text = "   %d / %d   " % [st["i"] + 1, pages.size()]
		prev.disabled = st["i"] == 0
		nxt.disabled = st["i"] >= pages.size() - 1
	prev.pressed.connect(func():
		st["i"] = maxi(0, st["i"] - 1)
		refresh.call())
	nxt.pressed.connect(func():
		st["i"] = mini(pages.size() - 1, st["i"] + 1)
		refresh.call())
	refresh.call()
	_add_close(vb)

# ---- 保险箱 ----
func open_safe(on_success: Callable) -> void:
	var vb := _open_modal("保险箱", Vector2(460, 270))
	vb.add_child(_label("请输入日期密码:", 18))
	var le := LineEdit.new()
	le.max_length = 12
	le.placeholder_text = L.t("例如 2000.1.1")
	le.custom_minimum_size = Vector2(0, 40)
	vb.add_child(le)
	var fb := _label("", 16, Color(0.9, 0.4, 0.4))
	vb.add_child(fb)
	var submit := func(_t: String = ""):
		var digits := ""
		for ch in le.text:
			if ch >= "0" and ch <= "9":
				digits += ch
		if digits == "20210203" or digits == "202123":
			close_modal()
			on_success.call()
		else:
			SFX.play("buzz")
			fb.text = L.t("嘀——错误。")
			le.text = ""
	le.text_submitted.connect(submit)
	vb.add_child(_button("确认", func(): submit.call()))
	_add_close(vb)
	le.grab_focus.call_deferred()

# ---- 拼合照片 ----
func open_photo_puzzle(on_done: Callable) -> void:
	var vb := _open_modal("拼合照片   (依次点击两块来交换位置)", Vector2(560, 560))
	var full: Image = Draw.photo_image()
	var tiles: Array = []
	for r in 2:
		for c in 3:
			tiles.append(ImageTexture.create_from_image(full.get_region(Rect2i(c * 120, r * 120, 120, 120))))
	var order: Array = [0, 1, 2, 3, 4, 5]
	order = [3, 5, 0, 4, 1, 2]
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	var cc := CenterContainer.new()
	cc.add_child(grid)
	vb.add_child(cc)
	var btns: Array = []
	var sel := {"i": -1}
	var result := VBoxContainer.new()
	result.visible = false
	vb.add_child(result)
	var photo := TextureRect.new()
	photo.texture = ImageTexture.create_from_image(full)
	photo.custom_minimum_size = Vector2(360, 240)
	photo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	photo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	result.add_child(photo)
	var back := _label("", 22, Color(0.9, 0.85, 0.6))
	back.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	result.add_child(back)
	var flip := {"back": false}
	var flipb := _button("翻到背面", func(): pass)
	flipb.pressed.connect(func():
		flip["back"] = not flip["back"]
		photo.visible = not flip["back"]
		back.text = L.t("背面写着:\nSarah 生日快乐 · 2021.2.3") if flip["back"] else ""
		flipb.text = L.t("翻回正面") if flip["back"] else L.t("翻到背面"))
	result.add_child(flipb)
	result.add_child(_button("收好照片", func():
		close_modal()
		on_done.call()))
	var refresh := func():
		for i in 6:
			(btns[i] as TextureButton).texture_normal = tiles[order[i]]
			(btns[i] as TextureButton).modulate = Color(1, 1, 0.5) if sel["i"] == i else Color.WHITE
	var check := func():
		var ok := true
		for i in 6:
			if order[i] != i:
				ok = false
		if ok:
			SFX.play("ding")
			grid.get_parent().visible = false
			result.visible = true
	for i in 6:
		var b := TextureButton.new()
		b.ignore_texture_size = true
		b.stretch_mode = TextureButton.STRETCH_SCALE
		b.custom_minimum_size = Vector2(130, 130)
		var idx := i
		b.pressed.connect(func():
			SFX.play("click")
			if sel["i"] == -1:
				sel["i"] = idx
			elif sel["i"] == idx:
				sel["i"] = -1
			else:
				var tmp = order[idx]
				order[idx] = order[sel["i"]]
				order[sel["i"]] = tmp
				sel["i"] = -1
			refresh.call()
			check.call())
		grid.add_child(b)
		btns.append(b)
	refresh.call()
	_add_close(vb)

# ---- 调配生发剂 ----
func open_mixer(names: Array, checker: Callable, on_success: Callable) -> void:
	var vb := _open_modal("调配台   (每种成分 0~50 份)", Vector2(720, 520))
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 20)
	vb.add_child(hb)
	var left := VBoxContainer.new()
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(left)
	var beaker := ColorRect.new()
	beaker.custom_minimum_size = Vector2(90, 220)
	hb.add_child(beaker)
	var sliders: Array = []
	var sum_l := _label("", 20, Color(1, 0.9, 0.5))
	var msg := _label("", 18, Color(0.9, 0.6, 0.5))
	msg.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var vals := func() -> Array:
		var a: Array = []
		for s in sliders:
			a.append(int(s.value))
		return a
	var refresh := func():
		var v: Array = vals.call()
		var tot := 0
		for x in v:
			tot += x
		sum_l.text = L.f("合计 {n} / 100", {"n": tot})
		beaker.color = Color(0.25 + v[4] / 60.0, 0.45 + v[2] / 120.0, 0.7 - v[0] / 40.0, 1.0)
	for i in names.size():
		var row := HBoxContainer.new()
		row.add_child(_label(names[i], 18))
		row.get_child(0).custom_minimum_size = Vector2(230, 0)
		var s := HSlider.new()
		s.min_value = 0
		s.max_value = 50
		s.step = 1
		s.value = 10
		s.custom_minimum_size = Vector2(240, 28)
		s.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var vl := _label("10", 18)
		vl.custom_minimum_size = Vector2(36, 0)
		s.value_changed.connect(func(v: float):
			vl.text = str(int(v))
			refresh.call())
		row.add_child(s)
		row.add_child(vl)
		left.add_child(row)
		sliders.append(s)
	left.add_child(sum_l)
	left.add_child(msg)
	var mixb := _button("调配!", func(): pass)
	mixb.pressed.connect(func():
		var r: Dictionary = checker.call(vals.call())
		msg.text = L.t(r["msg"])
		if r["ok"]:
			SFX.play("ding")
			beaker.color = Color(1.0, 0.82, 0.2)
			mixb.disabled = true
			await get_tree().create_timer(1.6).timeout
			if modal != null:
				close_modal()
				on_success.call()
		else:
			SFX.play("buzz"))
	left.add_child(mixb)
	refresh.call()
	_add_close(vb)

# ---- 终端 ----
func open_terminal(password: String, log_text: String, on_read: Callable) -> void:
	var vb := _open_modal("实验室终端", Vector2(720, 420))
	var info := RichTextLabel.new()
	info.custom_minimum_size = Vector2(0, 200)
	info.size_flags_vertical = Control.SIZE_EXPAND_FILL
	info.add_theme_color_override("default_color", Color(0.4, 1.0, 0.5))
	info.add_theme_font_size_override("normal_font_size", 18)
	info.text = L.t("> CLICHÉ LAB 内部系统\n> 请输入密码:")
	vb.add_child(info)
	var le := LineEdit.new()
	le.placeholder_text = L.t("密码")
	le.custom_minimum_size = Vector2(0, 36)
	vb.add_child(le)
	var submit := func(_t: String = ""):
		if le.text.strip_edges().to_upper() == password:
			SFX.play("ding")
			le.visible = false
			info.text = L.t(log_text)
			on_read.call()
		else:
			SFX.play("buzz")
			info.text = L.t("> CLICHÉ LAB 内部系统\n> 密码错误。\n> 请输入密码:")
			le.text = ""
	le.text_submitted.connect(submit)
	_add_close(vb)
	le.grab_focus.call_deferred()

# ======================= 全屏界面 =======================
func _screen_base() -> Control:
	hide_screen(false)
	screen_ui = Control.new()
	_full(screen_ui)
	screen_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(screen_ui)
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	return screen_ui

func hide_screen(restore: bool = true) -> void:
	if screen_ui != null:
		screen_ui.queue_free()
		screen_ui = null
	var was := screen_kind
	screen_kind = ""
	if was == "pause":
		get_tree().paused = false
	if restore and hud_on and modal == null and title_ui == null:
		capture_mouse()

func show_title(has_save: bool) -> void:
	overlay.color = Color(0, 0, 0, 0)
	set_hud_visible(false)
	hide_title()
	title_ui = Control.new()
	_full(title_ui)
	add_child(title_ui)
	var bg := ColorRect.new()
	bg.color = Color(0.02, 0.02, 0.025)
	_full(bg)
	title_ui.add_child(bg)
	var ver := Label.new()                 # 版本号:用来确认打开的是不是最新的项目
	ver.text = GAME_VERSION
	ver.add_theme_font_size_override("font_size", 16)
	ver.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))
	ver.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
	ver.position = Vector2(-140, -36)
	title_ui.add_child(ver)
	var cc := CenterContainer.new()
	_full(cc)
	title_ui.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 14)
	cc.add_child(vb)
	var t := _label("VERONICA", 72, Color(0.75, 0.1, 0.1))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var t2 := _label("生发剂实验室", 34, Color(0.85, 0.8, 0.7))
	t2.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t2)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(0, 30)
	vb.add_child(sp)
	var nb := _button("新游戏", func(): title_new.emit())
	vb.add_child(nb)
	var cb := _button("继续(上次检查点)", func(): title_continue.emit())
	cb.disabled = not has_save
	vb.add_child(cb)
	vb.add_child(_button("语言 / Language: " + ("中文" if L.lang == "zh" else "English"), func(): L.toggle_lang()))
	vb.add_child(_button("手机触控:开" if Touch.enabled else "手机触控:关", func(): Touch.toggle()))
	vb.add_child(_button("操作说明", func(): open_reader("操作说明", [CONTROLS])))
	vb.add_child(_button("退出", func(): get_tree().quit()))
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

const CONTROLS := "[b]移动[/b]  W A S D\n[b]奔跑[/b]  按住 Shift(会发出声音)\n[b]视角[/b]  鼠标\n[b]互动[/b]  E\n[b]手电筒[/b]  F\n[b]背包[/b]  Tab\n[b]使用喷雾恢复[/b]  H\n[b]扣动空枪制造声响[/b]  Q\n[b]暂停[/b]  Esc\n\n[b]躲藏[/b]:靠近储物柜按 E 躲进去,再按 E 出来。\n怪物看不见躲起来的你,但听得到你奔跑的声音。\n\n[b]触屏[/b]:左半屏拖动 = 摇杆移动;右半屏拖动 = 转视角;右下角红色大按钮 = 互动;上方小按钮 = 暂停 / 物品 / 手电 / 喷雾 / 空枪。"

func hide_title() -> void:
	if title_ui != null:
		title_ui.queue_free()
		title_ui = null

func show_pause() -> void:
	var s := _screen_base()
	screen_kind = "pause"
	get_tree().paused = true
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0, 0.7)
	_full(bg)
	s.add_child(bg)
	var cc := CenterContainer.new()
	_full(cc)
	s.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 12)
	cc.add_child(vb)
	vb.add_child(_label("暂停", 40, Color(0.9, 0.8, 0.6)))
	vb.add_child(_button("继续", func(): hide_screen()))
	var chk := CheckBox.new()
	chk.text = L.t("关闭惊吓闪屏")
	chk.button_pressed = reduce_flash
	chk.toggled.connect(func(v: bool):
		reduce_flash = v
		L.reduce_flash = v
		L.save())
	vb.add_child(chk)
	var rchk := CheckBox.new()
	rchk.text = L.t("复古画面(PS1 风格)")
	rchk.button_pressed = L.retro
	rchk.toggled.connect(func(v: bool):
		L.retro = v
		L.save()
		L.changed.emit())
	vb.add_child(rchk)
	vb.add_child(_button("语言 / Language: " + ("中文" if L.lang == "zh" else "English"), func(): L.toggle_lang()))
	vb.add_child(_button("手机触控:开" if Touch.enabled else "手机触控:关", func(): Touch.toggle()))
	vb.add_child(_button("操作说明", func(): open_reader("操作说明", [CONTROLS])))
	vb.add_child(_button("回到标题", func():
		hide_screen(false)
		quit_to_title.emit()))

func show_gameover() -> void:
	var s := _screen_base()
	screen_kind = "gameover"
	SFX.loop("heart", false)
	var bg := ColorRect.new()
	bg.color = Color(0.12, 0, 0, 0.88)
	_full(bg)
	s.add_child(bg)
	var cc := CenterContainer.new()
	_full(cc)
	s.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 16)
	cc.add_child(vb)
	var t := _label("你倒下了", 64, Color(0.8, 0.1, 0.1))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var h := _label("(据说,下一次头发会更多一些。)", 18, Color(0.7, 0.6, 0.6))
	h.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(h)
	vb.add_child(_button("从检查点重试 (R)", func():
		hide_screen()
		retry_requested.emit()))
	vb.add_child(_button("回到标题", func():
		hide_screen(false)
		quit_to_title.emit()))

# ---- 文字序幕 / 尾声 ----
func show_intro(paras: Array, cb: Callable) -> void:
	set_hud_visible(false)
	if intro_ui != null:
		intro_ui.queue_free()
	intro_ui = Control.new()
	_full(intro_ui)
	intro_ui.mouse_filter = Control.MOUSE_FILTER_STOP
	add_child(intro_ui)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	_full(bg)
	intro_ui.add_child(bg)
	var cc := CenterContainer.new()
	_full(cc)
	intro_ui.add_child(cc)
	intro_label = RichTextLabel.new()
	intro_label.bbcode_enabled = true
	intro_label.custom_minimum_size = Vector2(820, 300)
	intro_label.scroll_active = false
	intro_label.add_theme_font_size_override("normal_font_size", 26)
	intro_label.add_theme_color_override("default_color", Color(0.88, 0.85, 0.75))
	cc.add_child(intro_label)
	var hint := _label("[E] / 点击 继续", 14, Color(0.4, 0.4, 0.4))
	hint.set_anchors_preset(Control.PRESET_CENTER_BOTTOM)
	hint.position = Vector2(-60, -50)
	intro_ui.add_child(hint)
	_intro_paras = paras
	_intro_idx = -1
	_intro_cb = cb
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	_intro_next()

func _intro_next() -> void:
	_intro_idx += 1
	if _intro_idx >= _intro_paras.size():
		intro_ui.queue_free()
		intro_ui = null
		intro_label = null
		_intro_typing = false
		var cb := _intro_cb
		_intro_cb = Callable()
		if cb.is_valid():
			cb.call()
		return
	intro_label.text = L.t(_intro_paras[_intro_idx])
	intro_label.visible_characters = 0
	_intro_chars = 0.0
	_intro_typing = true

func _advance_intro() -> void:
	if _intro_typing:
		_intro_typing = false
		intro_label.visible_characters = -1
	else:
		_intro_next()

func show_the_end() -> void:
	var s := _screen_base()
	screen_kind = "end"
	set_hud_visible(false)
	var bg := ColorRect.new()
	bg.color = Color.BLACK
	_full(bg)
	s.add_child(bg)
	var cc := CenterContainer.new()
	_full(cc)
	s.add_child(cc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 18)
	cc.add_child(vb)
	var t := _label("THE END", 72, Color(0.8, 0.75, 0.6))
	t.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(t)
	var c := _label("Veronica: 生发剂实验室\n\n谨以此献给所有正在掉发的人。\n(别忘了,洗完澡要把水槽清理干净。)", 22, Color(0.7, 0.7, 0.65))
	c.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vb.add_child(c)
	vb.add_child(_button("回到标题 (R)", func():
		hide_screen(false)
		quit_to_title.emit()))
