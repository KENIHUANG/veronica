extends Node3D
## 墙上的字(不再是悬浮发光的 Label3D):
##   style = "stencil" 模板喷漆在墙上,颜料剥落
##   style = "plate"   挂在墙上的旧搪瓷/铁皮标牌,有边框、锈迹
## 面朝本地 +Z。text 是中文键,切换语言时重新绘制。

const TR = preload("res://scripts/tex_render.gd")

var text := ""
var style := "stencil"
var color := Color(0.75, 0.1, 0.08)
var plate_color := Color(0.82, 0.8, 0.72)
var width := 1.5
var px := 110
var font_kind := "stencil"
var seed_v := 3
var aspect := 0.28        # 高/宽
var _mi: MeshInstance3D = null

func _ready() -> void:
	L.changed.connect(_redraw)
	_redraw()

func _key() -> String:
	return "pt_%s_%s" % [("%s|%s|%s|%s|%d|%.3f|%d" % [text, style, color.to_html(), font_kind, px, aspect, seed_v]).md5_text().substr(0, 10), L.lang]

func _redraw() -> void:
	var bt := TR.baked(_key())
	if bt != null:
		if _mi != null:
			_mi.queue_free()
		_mi = TR.quad_tex(self, bt, width, style != "plate", 0.85)
		return
	var w := 1024
	var h := int(w * aspect)
	var root := Control.new()
	root.size = Vector2(w, h)
	if style == "plate":
		var bg := ColorRect.new()
		bg.color = plate_color
		bg.size = Vector2(w, h)
		root.add_child(bg)
		var border := ReferenceRect.new()
		border.border_color = color
		border.border_width = 10.0
		border.editor_only = false
		border.position = Vector2(18, 18)
		border.size = Vector2(w - 36, h - 36)
		root.add_child(border)
	root.add_child(TR.label(L.t(text), font_kind, px, color, Rect2(30, 10, w - 60, h - 20)))
	var img: Image = await TR.capture(self, root, Vector2i(w, h))
	if img == null:
		return
	if style == "plate":
		TR.weather(img, seed_v, 0.0, 0.35)
		_rust(img)
	else:
		TR.weather(img, seed_v, 0.33, 0.3)
	TR.save_baked(_key(), img)
	if _mi != null:
		_mi.queue_free()
	_mi = TR.quad(self, img, width, style != "plate", 0.85)

func _rust(img: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var w := img.get_width()
	var h := img.get_height()
	for i in 26:
		var cx := rng.randf() * w
		var cy := rng.randf() * h
		var r := rng.randf_range(6, 26)
		for y in range(int(cy - r), int(cy + r)):
			for x in range(int(cx - r), int(cx + r)):
				if x < 0 or y < 0 or x >= w or y >= h:
					continue
				var d := Vector2(x - cx, y - cy).length() / r
				if d < 1.0:
					var c := img.get_pixel(x, y)
					img.set_pixel(x, y, c.lerp(Color(0.35, 0.18, 0.08, c.a), (1.0 - d) * 0.75))
	# 底部的锈水流痕
	for i in 14:
		var x0 := int(rng.randf() * w)
		var len := rng.randi_range(20, h)
		for y in range(h - len, h):
			for dx in 3:
				var xx := x0 + dx
				if xx < w:
					var c := img.get_pixel(xx, y)
					img.set_pixel(xx, y, c.lerp(Color(0.3, 0.16, 0.07, c.a), 0.35))

static func make(parent: Node, pos: Vector3, yaw_deg: float, text_zh: String, style_name: String, w: float, col: Color, font: String = "stencil", font_px: int = 110, asp: float = 0.28) -> Node3D:
	var n := Node3D.new()
	n.set_script(load("res://scripts/painted_text.gd"))
	n.set("text", text_zh)
	n.set("style", style_name)
	n.set("width", w)
	n.set("color", col)
	n.set("font_kind", font)
	n.set("px", font_px)
	n.set("aspect", asp)
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	return n
