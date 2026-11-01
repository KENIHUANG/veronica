extends CanvasLayer
## 手机触控:浮动摇杆(左)、拖动转视角(右)、互动/奔跑/手电/背包/喷雾/空枪/暂停按钮。
## 按钮通过合成键盘事件(E/F/Tab/H/Q/Esc)驱动已有逻辑,所以键鼠和触屏走同一套代码。

signal changed

const LOOK_GAIN := 0.0042
var enabled := false
var move := Vector2.ZERO
var run := false
var look := Vector2.ZERO
var fingers: Dictionary = {}
var stick_center := Vector2.ZERO
var stick_radius := 90.0
var canvas: Control
var btns: Array = []

func _ready() -> void:
	layer = 11
	process_mode = Node.PROCESS_MODE_ALWAYS
	canvas = Control.new()
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.draw.connect(_draw_ui)
	add_child(canvas)
	match L.touch_mode:
		"on":
			enabled = true
		"off":
			enabled = false
		_:
			enabled = OS.has_feature("mobile") or OS.has_feature("web_android") or OS.has_feature("web_ios")
	canvas.visible = enabled

func toggle() -> void:
	enabled = not enabled
	L.touch_mode = "on" if enabled else "off"
	L.save()
	canvas.visible = enabled
	fingers.clear()
	move = Vector2.ZERO
	run = false
	if enabled:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	changed.emit()

## 是否正在显示并接受触控(游戏进行中,没有弹窗/标题/暂停)
func active() -> bool:
	return enabled and UI.hud_on and UI.modal == null and UI.title_ui == null and UI.screen_ui == null and UI.intro_ui == null

func move_vector() -> Vector2:
	return move if active() else Vector2.ZERO

func run_held() -> bool:
	return run and active()

func take_look() -> Vector2:
	var v := look
	look = Vector2.ZERO
	return v

func _size() -> Vector2:
	return get_viewport().get_visible_rect().size

func _layout() -> void:
	var s := _size()
	btns = [
		{"name": "interact", "label": "互动", "pos": Vector2(s.x - 150, s.y - 170), "r": 82.0, "key": KEY_E},
		{"name": "run", "label": "奔跑", "pos": Vector2(s.x - 310, s.y - 100), "r": 52.0, "key": 0},
		{"name": "pause", "label": "暂停", "pos": Vector2(s.x - 56, 54), "r": 36.0, "key": KEY_ESCAPE},
		{"name": "inv", "label": "物品", "pos": Vector2(s.x - 136, 54), "r": 36.0, "key": KEY_TAB},
		{"name": "flash", "label": "手电", "pos": Vector2(s.x - 216, 54), "r": 36.0, "key": KEY_F},
		{"name": "heal", "label": "喷雾", "pos": Vector2(s.x - 296, 54), "r": 36.0, "key": KEY_H},
		{"name": "gun", "label": "空枪", "pos": Vector2(s.x - 376, 54), "r": 36.0, "key": KEY_Q},
	]

func _hit_button(p: Vector2) -> Dictionary:
	for b in btns:
		if p.distance_to(b["pos"]) <= b["r"] * 1.15:
			return b
	return {}

func _send_key(k: int, pressed: bool) -> void:
	if k == 0:
		return
	var ev := InputEventKey.new()
	ev.keycode = k
	ev.physical_keycode = k
	ev.pressed = pressed
	Input.parse_input_event(ev)

func _input(event: InputEvent) -> void:
	if not active():
		if event is InputEventScreenTouch and not event.pressed:
			fingers.erase(event.index)
			move = Vector2.ZERO
			run = false
		return
	if btns.is_empty():
		_layout()
	if event is InputEventScreenTouch:
		var p: Vector2 = event.position
		if event.pressed:
			var b := _hit_button(p)
			if not b.is_empty():
				fingers[event.index] = {"role": "btn", "btn": b}
				if b["name"] == "run":
					run = true
				else:
					# 对白/序幕里点击已经会被"鼠标模拟"算作一次推进,这时不再补发 E,避免跳行
					if not (b["name"] == "interact" and (UI.dlg_active or UI.intro_ui != null)):
						_send_key(b["key"], true)
				return
			var s := _size()
			if p.x < s.x * 0.42 and p.y > s.y * 0.25 and not fingers.has("stick_owner"):
				fingers[event.index] = {"role": "stick"}
				fingers["stick_owner"] = event.index
				stick_center = p
				move = Vector2.ZERO
			else:
				fingers[event.index] = {"role": "look", "last": p}
		else:
			if fingers.has(event.index):
				var f: Dictionary = fingers[event.index]
				if f["role"] == "btn":
					var b: Dictionary = f["btn"]
					if b["name"] == "run":
						run = false
					else:
						_send_key(b["key"], false)
				elif f["role"] == "stick":
					move = Vector2.ZERO
					fingers.erase("stick_owner")
				fingers.erase(event.index)
	elif event is InputEventScreenDrag:
		if not fingers.has(event.index):
			return
		var f: Dictionary = fingers[event.index]
		if f["role"] == "stick":
			var d: Vector2 = event.position - stick_center
			if d.length() > stick_radius:
				stick_center += d.normalized() * (d.length() - stick_radius)   # 摇杆底座跟着手指走
				d = event.position - stick_center
			move = d / stick_radius
		elif f["role"] == "look":
			look += event.relative * LOOK_GAIN

func _process(_delta: float) -> void:
	if enabled and canvas != null:
		if btns.is_empty():
			_layout()
		canvas.visible = active() or UI.dlg_active
		canvas.queue_redraw()

func _draw_ui() -> void:
	if not enabled:
		return
	var font := canvas.get_theme_default_font()
	var s := _size()
	# 摇杆
	var has_stick := fingers.has("stick_owner")
	var c := stick_center if has_stick else Vector2(170, s.y - 150)
	var a := 0.4 if has_stick else 0.16
	canvas.draw_circle(c, stick_radius, Color(1, 1, 1, a * 0.5))
	canvas.draw_arc(c, stick_radius, 0, TAU, 40, Color(1, 1, 1, a + 0.15), 3.0)
	var knob := c + (move * stick_radius if has_stick else Vector2.ZERO)
	canvas.draw_circle(knob, 40.0, Color(1, 1, 1, a + 0.25))
	# 按钮
	for b in btns:
		var down := false
		for k in fingers:
			if typeof(k) == TYPE_INT and fingers[k].get("role", "") == "btn" and fingers[k]["btn"]["name"] == b["name"]:
				down = true
		var col := Color(0.9, 0.25, 0.2, 0.55) if b["name"] == "interact" else Color(1, 1, 1, 0.22)
		if down:
			col.a += 0.3
		canvas.draw_circle(b["pos"], b["r"], col)
		canvas.draw_arc(b["pos"], b["r"], 0, TAU, 32, Color(1, 1, 1, 0.6), 2.5)
		var label: String = L.t(b["label"])
		var fs := 26 if b["r"] > 60 else 17
		var w := font.get_string_size(label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		canvas.draw_string(font, b["pos"] + Vector2(-w * 0.5, fs * 0.35), label, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(1, 1, 1, 0.95))
