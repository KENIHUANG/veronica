extends RefCounted
## 手写字体:拉丁字母用 Permanent Marker(马克笔),中文回退到 Long Cang(手写体)。
## 两个字体都可免费商用:Apache 2.0 / SIL OFL,许可见 assets/fonts/LICENSES。

static var _font: Font = null

static func font() -> Font:
	if _font == null:
		var latin: FontFile = load("res://assets/fonts/PermanentMarker-Regular.ttf")
		var cjk: FontFile = load("res://assets/fonts/LongCang-Regular.ttf")
		latin.fallbacks = [cjk]
		_font = latin
	return _font

## 墙上/白板上的手写字(Label3D,受灯光影响)
static func label(parent: Node, pos: Vector3, text: String, color: Color, pixel: float, yaw_deg: float = 0.0, tilt_deg: float = 0.0) -> Label3D:
	var l := Label3D.new()
	l.font = font()
	l.text = L.t(text)
	l.set_meta("zh", text)
	l.add_to_group("loc3d")
	l.modulate = color
	l.pixel_size = pixel
	l.font_size = 64
	# 同色描边 = 加粗,让细手写体像马克笔
	l.outline_size = 10
	l.outline_modulate = color
	l.shaded = true
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	l.position = pos
	l.rotation_degrees = Vector3(0, yaw_deg, tilt_deg)
	parent.add_child(l)
	return l
