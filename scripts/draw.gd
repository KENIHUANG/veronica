extends RefCounted
## 极简像素绘图工具:用来程序化生成镜子倒影、合照等贴图。

static func rect(img: Image, x0: int, y0: int, x1: int, y1: int, c: Color) -> void:
	for y in range(maxi(y0, 0), mini(y1, img.get_height())):
		for x in range(maxi(x0, 0), mini(x1, img.get_width())):
			img.set_pixel(x, y, c)

static func ellipse(img: Image, cx: float, cy: float, rx: float, ry: float, c: Color) -> void:
	for y in range(maxi(int(cy - ry), 0), mini(int(cy + ry) + 1, img.get_height())):
		for x in range(maxi(int(cx - rx), 0), mini(int(cx + rx) + 1, img.get_width())):
			var dx := (x - cx) / rx
			var dy := (y - cy) / ry
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(x, y, c)

static func circle(img: Image, cx: float, cy: float, r: float, c: Color) -> void:
	ellipse(img, cx, cy, r, r, c)

static func ring(img: Image, cx: float, cy: float, r: float, thick: float, c: Color) -> void:
	for y in range(maxi(int(cy - r - thick), 0), mini(int(cy + r + thick) + 1, img.get_height())):
		for x in range(maxi(int(cx - r - thick), 0), mini(int(cx + r + thick) + 1, img.get_width())):
			var d := Vector2(x - cx, y - cy).length()
			if absf(d - r) <= thick:
				img.set_pixel(x, y, c)

static func line(img: Image, x0: float, y0: float, x1: float, y1: float, c: Color, thick: int = 1) -> void:
	var steps := int(maxf(absf(x1 - x0), absf(y1 - y0))) + 1
	for i in steps + 1:
		var t := float(i) / steps
		var x := int(lerpf(x0, x1, t))
		var y := int(lerpf(y0, y1, t))
		for ox in range(-(thick / 2), thick / 2 + 1):
			for oy in range(-(thick / 2), thick / 2 + 1):
				var px := x + ox
				var py := y + oy
				if px >= 0 and py >= 0 and px < img.get_width() and py < img.get_height():
					img.set_pixel(px, py, c)

static func _bg(w: int, h: int, top: Color, bottom: Color) -> Image:
	var img := Image.create(w, h, false, Image.FORMAT_RGB8)
	for y in h:
		var c := top.lerp(bottom, float(y) / h)
		for x in w:
			img.set_pixel(x, y, c)
	return img

static func _scratches(img: Image, n: int, c: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77
	for i in n:
		var x := rng.randf() * img.get_width()
		var y := rng.randf() * img.get_height()
		line(img, x, y, x + rng.randf_range(-30, 30), y + rng.randf_range(-12, 12), c, 1)

## 镜子:kind = "reflect"(Veronica 的倒影) / "bald"(秃头大叔) / "cracked"(碎裂)
static func mirror_image(kind: String) -> ImageTexture:
	var img := _bg(512, 128, Color(0.13, 0.17, 0.18), Color(0.05, 0.07, 0.08))
	var cx := 256.0
	match kind:
		"reflect":
			ellipse(img, cx, 44, 30, 32, Color(0.25, 0.14, 0.08))            # 头发
			circle(img, cx, 54, 24, Color(0.7, 0.55, 0.47))                   # 脸
			rect(img, int(cx) - 55, 84, int(cx) + 55, 128, Color(0.28, 0.33, 0.22))  # 外套
			rect(img, int(cx) - 8, 80, int(cx) + 8, 90, Color(0.7, 0.55, 0.47))
			circle(img, cx - 9, 52, 2.5, Color(0.1, 0.08, 0.08))
			circle(img, cx + 9, 52, 2.5, Color(0.1, 0.08, 0.08))
			line(img, cx - 6, 66, cx + 6, 66, Color(0.4, 0.2, 0.2), 1)
		"bald":
			circle(img, cx, 52, 28, Color(0.78, 0.72, 0.62))                  # 秃头
			ellipse(img, cx - 29, 60, 5, 10, Color(0.55, 0.55, 0.55))         # 两侧残余灰发
			ellipse(img, cx + 29, 60, 5, 10, Color(0.55, 0.55, 0.55))
			rect(img, int(cx) - 58, 86, int(cx) + 58, 128, Color(0.82, 0.82, 0.8))   # 白大褂
			rect(img, int(cx) - 8, 80, int(cx) + 8, 90, Color(0.78, 0.72, 0.62))
			circle(img, cx - 11, 54, 6, Color(0.02, 0.02, 0.02))              # 空洞的眼眶
			circle(img, cx + 11, 54, 6, Color(0.02, 0.02, 0.02))
			ring(img, cx - 11, 54, 9, 1.2, Color(0.15, 0.15, 0.15))           # 眼镜
			ring(img, cx + 11, 54, 9, 1.2, Color(0.15, 0.15, 0.15))
			line(img, cx - 9, 72, cx + 9, 74, Color(0.25, 0.08, 0.08), 2)
		"cracked":
			for i in 14:
				var a := TAU * i / 14.0 + 0.2
				var l := 40.0 + (i % 4) * 45.0
				line(img, cx, 64, cx + cos(a) * l * 1.6, 64 + sin(a) * l * 0.6, Color(0.85, 0.9, 0.95), 1)
			for i in 6:
				var a := TAU * i / 6.0
				line(img, cx + cos(a) * 30, 64 + sin(a) * 12, cx + cos(a + 0.5) * 55, 64 + sin(a + 0.5) * 22, Color(0.7, 0.75, 0.8), 1)
	_scratches(img, 18, Color(0.3, 0.34, 0.35))
	return ImageTexture.create_from_image(img)

## 博士与 Sarah 的合照(360x240,可切成 3x2 的 120x120 方块)
static func photo_image() -> Image:
	var img := _bg(360, 240, Color(0.93, 0.82, 0.6), Color(0.78, 0.6, 0.42))
	# 背景装饰:小花
	for i in 9:
		circle(img, 20 + i * 42, 215, 7, Color(0.9, 0.5, 0.55))
		circle(img, 20 + i * 42, 215, 2.5, Color(0.95, 0.85, 0.3))
	# 博士(左):头发稀疏,灰西装
	rect(img, 45, 128, 125, 240, Color(0.3, 0.33, 0.4))
	rect(img, 78, 126, 92, 150, Color(0.95, 0.95, 0.95))
	circle(img, 85, 95, 30, Color(0.88, 0.7, 0.58))
	for i in 5:
		line(img, 66 + i * 8, 70, 68 + i * 8, 62, Color(0.3, 0.2, 0.15), 1)
	circle(img, 75, 92, 3, Color(0.12, 0.1, 0.1))
	circle(img, 95, 92, 3, Color(0.12, 0.1, 0.1))
	for dx in range(-9, 10):
		img.set_pixel(85 + dx, 108 + int(dx * dx * 0.045), Color(0.5, 0.2, 0.2))
	# Sarah(右):长发,红裙
	ellipse(img, 215, 105, 38, 52, Color(0.35, 0.2, 0.12))
	rect(img, 175, 135, 255, 240, Color(0.75, 0.15, 0.2))
	circle(img, 215, 95, 27, Color(0.92, 0.76, 0.64))
	circle(img, 205, 92, 3, Color(0.12, 0.1, 0.1))
	circle(img, 225, 92, 3, Color(0.12, 0.1, 0.1))
	for dx in range(-10, 11):
		img.set_pixel(215 + dx, 107 + int(dx * dx * 0.05), Color(0.7, 0.15, 0.2))
	# 两人手牵手 + 爱心
	rect(img, 118, 160, 182, 172, Color(0.88, 0.7, 0.58))
	circle(img, 295, 60, 14, Color(0.95, 0.4, 0.5))
	circle(img, 320, 60, 14, Color(0.95, 0.4, 0.5))
	for y in range(60, 95):
		var hw := int(lerpf(27.0, 0.0, (y - 60) / 35.0))
		for x in range(307 - hw, 307 + hw):
			img.set_pixel(x, y, Color(0.95, 0.4, 0.5))
	# 白边
	for i in 6:
		line(img, 0, i, 359, i, Color(0.97, 0.95, 0.9), 1)
		line(img, 0, 239 - i, 359, 239 - i, Color(0.97, 0.95, 0.9), 1)
		line(img, i, 0, i, 239, Color(0.97, 0.95, 0.9), 1)
		line(img, 359 - i, 0, 359 - i, 239, Color(0.97, 0.95, 0.9), 1)
	return img

static var _pic_cache: Dictionary = {}

static func _bust(img: Image, face_opts: Dictionary, hood: bool, dirty: bool = false) -> void:
	var band := Color(0.42, 0.41, 0.38) if dirty else Color(0.86, 0.86, 0.84)
	var tex := face_texture(face_opts)
	var fimg: Image = tex.get_image()
	var crop := fimg.get_region(Rect2i(30, 20, 196, 216))
	crop.resize(60, 78)
	if hood:
		ellipse(img, 64, 100, 50, 60, Color(0.03, 0.03, 0.04))
		ellipse(img, 64, 74, 38, 46, band)
	else:
		ellipse(img, 64, 160, 56, 46, Color(0.07, 0.06, 0.06))
		rect(img, 50, 112, 78, 130, Color(0.75, 0.72, 0.66))
	for y in range(0, 78):
		for x in range(0, 60):
			var dx := (x - 30.0) / 30.0
			var dy := (y - 39.0) / 39.0
			if dx * dx + dy * dy <= 1.0:
				img.set_pixel(34 + x, 34 + y, crop.get_pixel(x, y))
	if hood:
		rect(img, 28, 22, 100, 36, Color(0.03, 0.03, 0.04))
		rect(img, 32, 36, 96, 40, band.lightened(0.05))

static func _blood_drips(img: Image, n: int, seed_v: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var x := rng.randi_range(8, 120)
		var y0 := rng.randi_range(0, 80)
		line(img, x, y0, x + rng.randi_range(-2, 2), y0 + rng.randi_range(30, 90), Color(0.5, 0.02, 0.02), rng.randi_range(1, 3))

static func _scribble(img: Image, n: int, seed_v: int, col: Color) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for i in n:
		var x := rng.randf_range(10, 118)
		var y := rng.randf_range(10, 150)
		line(img, x, y, x + rng.randf_range(-40, 40), y + rng.randf_range(-40, 40), col, 2)

## 恐怖版后期:压暗、去饱和偏冷绿、强暗角、颗粒。让画面"暗而清楚",而不是一片白。
static func _creepify(img: Image, seed_v: int, dark: float = 0.62) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var l := c.r * 0.3 + c.g * 0.59 + c.b * 0.11
			var r := lerpf(c.r, l, 0.35)
			var g := lerpf(c.g, l, 0.35)
			var b := lerpf(c.b, l, 0.35)
			# 红色(血)保留饱和度
			if c.r > 0.35 and c.g < 0.12 and c.b < 0.12:
				r = c.r; g = c.g; b = c.b
			var dx := (x - w * 0.5) / (w * 0.5)
			var dy := (y - h * 0.45) / (h * 0.55)
			var v := clampf(1.0 - pow(dx * dx + dy * dy, 1.2) * 0.75, 0.12, 1.0)
			var k := dark * v * (1.0 + (rng.randf() - 0.5) * 0.12)
			img.set_pixel(x, y, Color(clampf(r * k * 0.95, 0, 1), clampf(g * k, 0, 1), clampf(b * k * 0.98, 0, 1)))

## 挂画。kind:portrait / nun / ad / landscape / certificate / family。creepy=true 是"趁你不看时"的样子。尺寸 128x160。
static func picture(kind: String, creepy: bool = false) -> ImageTexture:
	var key := kind + ("_c" if creepy else "")
	if _pic_cache.has(key):
		return _pic_cache[key]
	var img: Image
	match kind:
		"portrait":
			img = _bg(128, 160, Color(0.38, 0.3, 0.18), Color(0.18, 0.13, 0.08))
			var fo := {"skin": Color(0.74, 0.58, 0.46), "eyes": "normal", "age": 0.7, "bags": 0.4, "brow": Color(0.35, 0.3, 0.25)}
			if creepy:
				fo = {"skin": Color(0.62, 0.58, 0.5), "eyes": "hollow", "socket": 1.45, "age": 1.0, "bags": 1.0, "dead": true, "black_tears": true, "lips": Color(0.3, 0.22, 0.22), "brow_tilt": -0.006}
			_bust(img, fo, false)
			if creepy:
				line(img, 50, 97, 78, 97, Color(0.04, 0.02, 0.02), 2)       # 被缝上的嘴(在嘴的位置上)
				for k in 7:
					line(img, 51 + k * 4.4, 93, 52 + k * 4.4, 101, Color(0.05, 0.02, 0.02), 1)
				_blood_drips(img, 3, 3)
		"nun":
			img = _bg(128, 160, Color(0.12, 0.12, 0.14), Color(0.04, 0.04, 0.05))
			var fo2 := {"skin": Color(0.84, 0.8, 0.74), "eyes": "closed", "age": 0.3, "bags": 0.2, "lips": Color(0.6, 0.4, 0.4)}
			if creepy:
				fo2 = {"skin": Color(0.66, 0.68, 0.66), "eyes": "hollow", "socket": 1.5, "pin": Color(0.9, 0.1, 0.05), "age": 0.9, "bags": 1.0, "grin": 1.0, "dead": true, "black_tears": true}
			_bust(img, fo2, true, creepy)
			if creepy:
				for k in 6:
					line(img, 30 + k * 3, 60, 14 + k * 6, 158, Color(0.02, 0.02, 0.02), 1)    # 面纱下伸出的黑手指
		"ad":
			img = _bg(128, 160, Color(0.2, 0.45, 0.35), Color(0.1, 0.25, 0.2))
			var fo3 := {"skin": Color(0.84, 0.7, 0.58), "eyes": "normal", "age": 0.2, "bags": 0.1, "grin": 0.5, "blush": 0.4}
			if creepy:
				fo3 = {"skin": Color(0.72, 0.62, 0.55), "eyes": "wild", "age": 1.0, "bags": 1.0, "grin": 1.0, "stubble": 0.7}
			_bust(img, fo3, false)
			rect(img, 8, 6, 120, 22, Color(0.95, 0.9, 0.5))
			rect(img, 20, 26, 108, 32, Color(0.95, 0.9, 0.5))
			if creepy:
				var rng := RandomNumberGenerator.new()
				rng.seed = 21
				for i in 60:    # 疯长的黑发,盖住整张画
					var x := rng.randf_range(34, 94)
					line(img, x, 36, x + rng.randf_range(-30, 30), rng.randf_range(100, 158), Color(0.03, 0.02, 0.02), 1)
				for ex: float in [48.0, 80.0]:   # 发帘后面亮着两只眼睛
					circle(img, ex, 63, 4.0, Color(0.02, 0.0, 0.0))
					circle(img, ex, 63, 2.2, Color(0.95, 0.12, 0.05))
					circle(img, ex, 63, 0.9, Color(1.0, 0.85, 0.7))
		"family":
			img = _bg(128, 160, Color(0.75, 0.6, 0.42), Color(0.45, 0.32, 0.2))
			var ph := photo_image()
			ph.resize(112, 75)
			img.blit_rect(ph, Rect2i(0, 0, 112, 75), Vector2i(8, 40))
			if creepy:
				for k in 40:
					line(img, 66 + (k % 9) * 2, 56 + k, 94 - (k % 7), 50 + k * 1.5, Color(0.6, 0.02, 0.02), 2)   # 划烂的 Sarah
				_scribble(img, 10, 5, Color(0.05, 0.02, 0.02))
		"landscape":
			img = _bg(128, 160, Color(0.55, 0.62, 0.55), Color(0.3, 0.38, 0.28))
			if creepy:
				img = _bg(128, 160, Color(0.45, 0.04, 0.04), Color(0.12, 0.02, 0.02))
			circle(img, 90, 40, 14, Color(0.9, 0.85, 0.55) if not creepy else Color(0.95, 0.9, 0.85))
			ellipse(img, 30, 130, 80, 40, Color(0.18, 0.28, 0.18) if not creepy else Color(0.05, 0.05, 0.05))
			ellipse(img, 100, 140, 70, 34, Color(0.14, 0.22, 0.15) if not creepy else Color(0.03, 0.03, 0.03))
			rect(img, 0, 150, 128, 160, Color(0.2, 0.18, 0.12))
			if creepy:
				circle(img, 90, 40, 6, Color(0.05, 0.0, 0.0))                       # 太阳变成一只眼睛
				for k in 14:                                                        # 田野里站着很多人影,全都面朝你
					var px := 8 + k * 8
					var py := 122 + (k % 3) * 8
					ellipse(img, px, py, 2, 8, Color(0.0, 0.0, 0.0))
					circle(img, px, py - 10, 2.4, Color(0.0, 0.0, 0.0))
					img.set_pixel(px - 1, py - 10, Color(0.95, 0.9, 0.85))    # 每个人影都有两点白眼睛,全都盯着你
					img.set_pixel(px + 1, py - 10, Color(0.95, 0.9, 0.85))
		"certificate":
			img = _bg(128, 160, Color(0.88, 0.84, 0.7), Color(0.8, 0.76, 0.6))
			for i in 8:
				line(img, 20, 40 + i * 10, 108, 40 + i * 10, Color(0.35, 0.3, 0.25), 1)
			circle(img, 64, 135, 10, Color(0.65, 0.12, 0.1))
			ring(img, 64, 135, 14, 1.2, Color(0.5, 0.4, 0.15))
			rect(img, 20, 14, 108, 24, Color(0.4, 0.3, 0.2))
			if creepy:
				_scribble(img, 26, 9, Color(0.5, 0.02, 0.02))
				ellipse(img, 70, 98, 20, 24, Color(0.45, 0.02, 0.02))               # 血手印
				for k in 5:
					ellipse(img, 54 + k * 8, 70 - (k % 3) * 3, 3.2, 14, Color(0.45, 0.02, 0.02))
				_blood_drips(img, 8, 4)
		_:
			img = _bg(128, 160, Color(0.3, 0.3, 0.3), Color(0.1, 0.1, 0.1))
	if not creepy:
		_scratches(img, 12, Color(0.55, 0.48, 0.35))
	else:
		_creepify(img, kind.length() * 7, {"certificate": 0.75, "landscape": 1.0, "family": 0.75}.get(kind, 0.62))
	var t := ImageTexture.create_from_image(img)
	_pic_cache[key] = t
	return t

## 蜘蛛网(带透明通道)
static func web_image() -> ImageTexture:
	var img := Image.create(128, 128, false, Image.FORMAT_RGBA8)
	img.fill(Color(1, 1, 1, 0))
	var c := Color(0.92, 0.94, 0.96, 0.75)
	for i in 7:
		var a := PI * 0.5 * i / 6.0
		line(img, 0, 0, cos(a) * 124, sin(a) * 124, c, 1)
	for r in [22, 42, 64, 88, 112]:
		var prev := Vector2(r, 0)
		for k in range(1, 7):
			var a := PI * 0.5 * k / 6.0
			var cur: Vector2 = Vector2(cos(a), sin(a)) * float(r - 3 * (k % 2))
			line(img, prev.x, prev.y, cur.x, cur.y, Color(c.r, c.g, c.b, 0.5), 1)
			prev = cur
	return ImageTexture.create_from_image(img)


# ============ 脸部贴图绘制(米制坐标 → 贴图像素) ============
const FACE_W := 0.17
const FACE_H := 0.25
const FS := 256

static func _px(X: float) -> float:
	return (0.5 + X / FACE_W) * FS

static func _py(Y: float) -> float:
	return (0.5 - Y / FACE_H) * FS

static func _blend(img: Image, x: int, y: int, c: Color, a: float) -> void:
	if x < 0 or y < 0 or x >= img.get_width() or y >= img.get_height() or a <= 0.0:
		return
	var o := img.get_pixel(x, y)
	img.set_pixel(x, y, o.lerp(Color(c.r, c.g, c.b, 1.0), clampf(a * c.a, 0.0, 1.0)))

## 柔边椭圆;rx/ry 为米,strength 0..1
static func soft(img: Image, X: float, Y: float, rx: float, ry: float, c: Color, strength: float = 1.0, hard: float = 0.35) -> void:
	var cx := _px(X)
	var cy := _py(Y)
	var rpx := rx / FACE_W * FS
	var rpy := ry / FACE_H * FS
	for y in range(int(cy - rpy) - 1, int(cy + rpy) + 2):
		for x in range(int(cx - rpx) - 1, int(cx + rpx) + 2):
			var dx := (x - cx) / maxf(rpx, 0.5)
			var dy := (y - cy) / maxf(rpy, 0.5)
			var d := sqrt(dx * dx + dy * dy)
			if d <= 1.0:
				var a := (1.0 - smoothstep(hard, 1.0, d)) * strength
				_blend(img, x, y, c, a)

## 沿折线描线(米坐标点)
static func stroke(img: Image, pts: Array, c: Color, thick_m: float = 0.002, strength: float = 1.0) -> void:
	for i in pts.size() - 1:
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[i + 1]
		var steps := int(maxf(a.distance_to(b) / 0.0008, 2.0))
		for k in steps + 1:
			var t := float(k) / steps
			var p := a.lerp(b, t)
			soft(img, p.x, p.y, thick_m, thick_m * 0.7, c, strength, 0.2)

## opts: skin, eyes("normal"/"hollow"/"wild"/"glow"/"closed"), iris, brow, brow_w, lips, bags, stubble, grin, blush, age, female, tears, dead, mustache
static func face_texture(o: Dictionary = {}) -> ImageTexture:
	var skin: Color = o.get("skin", Color(0.8, 0.64, 0.55))
	var img := Image.create(FS, FS, false, Image.FORMAT_RGB8)
	var n := FastNoiseLite.new()
	n.frequency = 0.09
	n.seed = int(skin.r * 1000) + 3
	var nm: Image = n.get_image(FS, FS)
	var n2 := FastNoiseLite.new()
	n2.frequency = 0.5
	n2.seed = 11
	var nf: Image = n2.get_image(FS, FS)
	for y in FS:
		for x in FS:
			var a: float = nm.get_pixel(x, y).r
			var b: float = nf.get_pixel(x, y).r
			var k := 0.9 + 0.2 * a + (b - 0.5) * 0.06
			img.set_pixel(x, y, Color(clampf(skin.r * k, 0, 1), clampf(skin.g * k, 0, 1), clampf(skin.b * k, 0, 1)))
	var female: bool = o.get("female", false)
	var age: float = o.get("age", 0.3)
	var shade := skin * 0.55
	shade.a = 1.0
	# 脸颊红润 / 苍白
	var blush: float = o.get("blush", 0.15)
	for s: float in [-1.0, 1.0]:
		soft(img, s * 0.05, -0.022, 0.026, 0.02, Color(0.85, 0.35, 0.3), blush)
	# 眼袋 / 黑眼圈
	var bags: float = o.get("bags", 0.2)
	var bag_col := Color(0.32, 0.2, 0.3)
	for s: float in [-1.0, 1.0]:
		soft(img, s * 0.034, 0.014, 0.022, 0.0085, bag_col, bags)
		soft(img, s * 0.034, 0.04, 0.022, 0.007, shade, 0.25 + bags * 0.2)      # 上眼睑阴影
	# 眼睛
	var eyes: String = o.get("eyes", "normal")
	var iris: Color = o.get("iris", Color(0.3, 0.22, 0.14))
	for s: float in [-1.0, 1.0]:
		var ex: float = s * 0.034
		var ey: float = 0.028
		match eyes:
			"hollow":
				var sk: float = o.get("socket", 1.0)
				soft(img, ex, ey - 0.002, 0.026 * sk, 0.02 * sk, Color(0.12, 0.06, 0.08), 0.75, 0.15)   # 眼眶周围的淤青
				soft(img, ex, ey, 0.0185 * sk, 0.0125 * sk, Color(0.01, 0.01, 0.015), 1.0, 0.5)
				var pin: Color = o.get("pin", Color(0.9, 0.95, 1.0))
				soft(img, ex + 0.002, ey - 0.001, 0.0016 * sk, 0.0016 * sk, pin, 0.9, 0.3)
			"glow":
				soft(img, ex, ey, 0.017, 0.011, Color(0.0, 0.0, 0.0), 1.0, 0.5)
				soft(img, ex, ey, 0.007, 0.006, Color(1.0, 0.15, 0.08), 1.0, 0.1)
			"closed":
				stroke(img, [Vector2(ex - 0.012, ey), Vector2(ex, ey - 0.003), Vector2(ex + 0.012, ey)], Color(0.1, 0.06, 0.05), 0.0018)
			_:
				var white := Color(0.93, 0.9, 0.86)
				if eyes == "wild":
					white = Color(0.92, 0.72, 0.68)
				soft(img, ex, ey, 0.0128, 0.0072, white, 1.0, 0.7)
				soft(img, ex, ey, 0.0062 if eyes != "wild" else 0.0045, 0.0062 if eyes != "wild" else 0.0045, iris, 1.0, 0.75)
				soft(img, ex, ey, 0.0028 if eyes != "wild" else 0.0014, 0.0028 if eyes != "wild" else 0.0014, Color(0.02, 0.02, 0.03), 1.0, 0.5)
				soft(img, ex + 0.0022, ey + 0.002, 0.0011, 0.0011, Color(1, 1, 1), 0.9, 0.3)
				if eyes == "wild":
					for k in 4:
						var ang := k * 1.57 + (0.4 if s > 0 else 0.0)
						stroke(img, [Vector2(ex + cos(ang) * 0.012, ey + sin(ang) * 0.006), Vector2(ex + cos(ang) * 0.0055, ey + sin(ang) * 0.003)], Color(0.7, 0.05, 0.05), 0.0004, 0.85)
				# 上眼线 / 睫毛
				var lash := 0.0034 if female else 0.0018
				stroke(img, [Vector2(ex - 0.0135, ey - 0.0005), Vector2(ex - 0.007, ey + 0.0058), Vector2(ex + 0.002, ey + 0.0072), Vector2(ex + 0.0115, ey + 0.0042), Vector2(ex + 0.0135, ey - 0.001)], Color(0.07, 0.04, 0.04), lash)
				stroke(img, [Vector2(ex - 0.0115, ey - 0.0035), Vector2(ex, ey - 0.0072), Vector2(ex + 0.0115, ey - 0.0036)], shade, 0.0012, 0.5)
	# 眉毛
	var brow_c: Color = o.get("brow", Color(0.2, 0.13, 0.09))
	var bw: float = o.get("brow_w", 0.0028)
	var tilt: float = o.get("brow_tilt", 0.0)     # 正值:外端上扬(凶),负值:外端下垂(悲)
	for s: float in [-1.0, 1.0]:
		var t_adj := tilt * (1.0 if s > 0 else -0.4)
		stroke(img, [Vector2(s * 0.014, 0.052), Vector2(s * 0.03, 0.0585 + t_adj * 0.4), Vector2(s * 0.047, 0.0595 + t_adj), Vector2(s * 0.062, 0.0535 + t_adj * 1.2)], brow_c, bw, 0.85)
	# 鼻孔与鼻翼阴影
	for s: float in [-1.0, 1.0]:
		soft(img, s * 0.0085, -0.0365, 0.0042, 0.0028, Color(0.1, 0.04, 0.04), 0.9)
		soft(img, s * 0.019, -0.03, 0.006, 0.01, shade, 0.2)
	# 法令纹 / 皱纹
	var wr := Color(0.35, 0.22, 0.2)
	for s: float in [-1.0, 1.0]:
		stroke(img, [Vector2(s * 0.022, -0.032), Vector2(s * 0.03, -0.052), Vector2(s * 0.031, -0.07)], wr, 0.0015, 0.2 + age * 0.55)
		for k in 3:
			stroke(img, [Vector2(s * 0.012, 0.074 + k * 0.007), Vector2(0.0, 0.0775 + k * 0.007), Vector2(s * -0.012, 0.074 + k * 0.007)], wr, 0.0009, age * 0.45)
	# 嘴唇
	var lips: Color = o.get("lips", Color(0.62, 0.35, 0.33))
	var grin: float = o.get("grin", 0.0)
	if grin > 0.0:
		soft(img, 0.0, -0.0655, 0.027, 0.004 + 0.012 * grin, Color(0.08, 0.01, 0.01), 1.0, 0.6)
		for k in 10:
			soft(img, -0.0175 + k * 0.0039, -0.0655 + 0.003 + 0.004 * grin, 0.0019, 0.0034 * (0.5 + grin), Color(0.88, 0.83, 0.66), 1.0, 0.6)
			soft(img, -0.0175 + k * 0.0039, -0.0655 - 0.002 - 0.008 * grin, 0.0019, 0.0030 * grin, Color(0.82, 0.78, 0.6), grin, 0.6)
		stroke(img, [Vector2(-0.027, -0.0645), Vector2(0, -0.0655 - 0.002), Vector2(0.027, -0.0645)], lips * 0.5, 0.0016)
	else:
		soft(img, 0.0, -0.0585, 0.0185, 0.0048, lips * (1.05 if female else 0.9), 0.95, 0.55)
		soft(img, 0.0, -0.0735, 0.0175, 0.0062, lips * (1.12 if female else 0.95), 0.95, 0.55)
		stroke(img, [Vector2(-0.0215, -0.0655), Vector2(-0.01, -0.0646), Vector2(0.0, -0.0652), Vector2(0.01, -0.0646), Vector2(0.0215, -0.0655)], Color(0.2, 0.08, 0.08), 0.0013)
	# 胡茬与小胡子
	var stub: float = o.get("stubble", 0.0)
	if stub > 0.0:
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		for i in int(900 * stub):
			var X := rng.randf_range(-0.058, 0.058)
			var Y := rng.randf_range(-0.108, -0.035)
			var inside := (X * X) / (0.058 * 0.058) + pow((Y + 0.07) / 0.05, 2.0)
			if inside < 1.0 and not (absf(X) < 0.02 and Y > -0.075 and Y < -0.052):
				_blend(img, int(_px(X)), int(_py(Y)), Color(0.15, 0.12, 0.1), 0.55)
	if o.get("mustache", false):
		var mc: Color = o.get("brow", Color(0.1, 0.06, 0.04))
		# 粗一点、深一点:远景和逆光下也要一眼看出"有胡子"
		for s: float in [-1.0, 1.0]:
			soft(img, s * 0.016, -0.0505, 0.019, 0.0062, mc, 1.0, 0.55)
			stroke(img, [Vector2(s * 0.03, -0.052), Vector2(s * 0.038, -0.056), Vector2(s * 0.042, -0.052)], mc, 0.0026, 1.0)   # 两端微微上翘
		soft(img, 0.0, -0.0495, 0.006, 0.004, mc * 0.8, 0.6, 0.5)
	# 眼泪 / 死气
	if o.get("tears", false):
		for s: float in [-1.0, 1.0]:
			stroke(img, [Vector2(s * 0.036, 0.018), Vector2(s * 0.04, -0.01), Vector2(s * 0.042, -0.04)], Color(0.7, 0.8, 0.95), 0.0016, 0.6)
	if o.get("black_tears", false):
		var sk2: float = o.get("socket", 1.0)
		for s: float in [-1.0, 1.0]:
			var x0 := s * 0.034
			var y0 := 0.028 - 0.011 * sk2
			for j in 3:
				var dx := (j - 1) * 0.006
				var len := 0.05 + 0.025 * ((j + int(s > 0)) % 3)
				stroke(img, [Vector2(x0 + dx, y0), Vector2(x0 + dx * 1.2 + s * 0.002, y0 - len * 0.5), Vector2(x0 + dx * 1.3 + s * 0.003, y0 - len)], Color(0.02, 0.01, 0.01), 0.0026 - j * 0.0004, 0.95)
				soft(img, x0 + dx * 1.3 + s * 0.003, y0 - len, 0.0034, 0.0042, Color(0.02, 0.01, 0.01), 0.95, 0.4)
	if o.get("dead", false):
		for k in 9:
			var a0 := k * 0.7
			stroke(img, [Vector2(cos(a0) * 0.02, 0.02 + sin(a0) * 0.02), Vector2(cos(a0 + 0.8) * 0.05, 0.0 + sin(a0 + 0.8) * 0.06)], Color(0.25, 0.3, 0.45), 0.0011, 0.5)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
