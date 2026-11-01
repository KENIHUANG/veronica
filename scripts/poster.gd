extends Node3D
## 大厅海报:一张褪色的米诺地尔药品广告,被人涂鸦过。
## 广告上笑着的男人,被黑色记号笔画满了头发、眼睛被划掉;
## 旁边用红笔歪歪扭扭写着"停药之后,它会全部掉回去"。
## 面朝本地 +Z,宽 0.9 米。

const TR = preload("res://scripts/tex_render.gd")
const Draw = preload("res://scripts/draw.gd")

var width := 0.9
var _mi: MeshInstance3D = null

func _ready() -> void:
	L.changed.connect(_redraw)
	_redraw()

func _redraw() -> void:
	var W := 640
	var H := 900
	var root := Control.new()
	root.size = Vector2(W, H)
	var bg := ColorRect.new()
	bg.color = Color(0.86, 0.82, 0.7)
	bg.size = Vector2(W, H)
	root.add_child(bg)
	var band := ColorRect.new()
	band.color = Color(0.12, 0.36, 0.38)
	band.size = Vector2(W, 190)
	root.add_child(band)
	root.add_child(TR.label("MINOXIDIL", "typewriter", 92, Color(0.95, 0.92, 0.8), Rect2(0, 18, W, 110)))
	root.add_child(TR.label(L.t("米诺地尔 · 让头发回来"), "bold", 38, Color(0.95, 0.92, 0.8), Rect2(0, 118, W, 60)))
	var photo := ColorRect.new()            # 照片底色,让脸从纸上"跳"出来
	photo.color = Color(0.28, 0.33, 0.36)
	photo.position = Vector2(110, 205)
	photo.size = Vector2(420, 430)
	root.add_child(photo)
	var shoulders := ColorRect.new()         # 西装肩膀
	shoulders.color = Color(0.1, 0.1, 0.12)
	shoulders.position = Vector2(150, 560)
	shoulders.size = Vector2(340, 75)
	root.add_child(shoulders)
	var face := TextureRect.new()
	face.texture = _oval_face()
	face.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	face.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	face.position = Vector2(190, 250)
	face.size = Vector2(260, 330)
	root.add_child(face)
	root.add_child(TR.label(L.t("原本是降血压的药。\n服用者意外长出了浓密的头发。"), "typewriter", 30, Color(0.15, 0.12, 0.1), Rect2(30, 650, W - 60, 110)))
	root.add_child(TR.label(L.t("Cliché 实验室 · 荣誉出品"), "typewriter", 24, Color(0.3, 0.25, 0.2), Rect2(30, 780, W - 60, 50)))
	var scrawl := TR.label(L.t("停药之后,\n它会全部掉回去。"), "hand", 62, Color(0.55, 0.03, 0.03), Rect2(200, 470, 440, 170))
	scrawl.rotation = -0.18
	scrawl.add_theme_constant_override("outline_size", 8)
	scrawl.add_theme_color_override("font_outline_color", Color(0.5, 0.02, 0.02))
	root.add_child(scrawl)
	var img: Image = await TR.capture(self, root, Vector2i(W, H))
	if img == null:
		return
	_vandalize(img)
	_age(img)
	if _mi != null:
		_mi.queue_free()
	_mi = TR.quad(self, img, width, false, 0.95)
	(_mi.material_override as StandardMaterial3D).albedo_color = Color(0.7, 0.68, 0.64)   # 正上方有聚光灯,压暗

## 把整块的脸部贴图裁成椭圆的脸(外面透明)
func _oval_face() -> ImageTexture:
	var src: Image = Draw.face_texture({"skin": Color(0.82, 0.66, 0.55), "eyes": "normal", "grin": 0.0, "age": 0.4, "bags": 0.2, "blush": 0.3, "brow": Color(0.12, 0.08, 0.05)}).get_image()
	src.convert(Image.FORMAT_RGBA8)
	var w := src.get_width()
	var h := src.get_height()
	var crop := src.get_region(Rect2i(int(w * 0.12), int(h * 0.06), int(w * 0.76), int(h * 0.9)))
	var cw := crop.get_width()
	var ch := crop.get_height()
	for y in ch:
		for x in cw:
			var dx := (x - cw * 0.5) / (cw * 0.5)
			var dy := (y - ch * 0.5) / (ch * 0.5)
			if dx * dx + dy * dy > 1.0:
				crop.set_pixel(x, y, Color(0, 0, 0, 0))
	return ImageTexture.create_from_image(crop)

## 记号笔在脸上画满头发、划掉眼睛
func _vandalize(img: Image) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var ink := Color(0.04, 0.04, 0.05)
	var cx := 320.0
	for i in 90:
		var a := rng.randf_range(-PI * 0.95, -PI * 0.05)
		var r0 := rng.randf_range(120, 150)
		var x0 := cx + cos(a) * r0
		var y0 := 400.0 + sin(a) * r0 * 1.2
		var x1 := x0 + rng.randf_range(-60, 60)
		var y1 := y0 - rng.randf_range(20, 90)
		Draw.line(img, x0, y0, x1, y1, ink, 2)
	# 两条长长的"鬓角"一直拖到下巴
	for s: float in [-1.0, 1.0]:
		for k in 8:
			Draw.line(img, cx + s * (135 + k * 3), 380 + k * 6, cx + s * (120 + k * 2), 600 + k * 5, ink, 2)
	# 划掉眼睛
	for s: float in [-1.0, 1.0]:
		var ex := cx + s * 80.0
		var ey := 395.0
		for k in 3:
			Draw.line(img, ex - 34, ey - 20 + k * 4, ex + 34, ey + 20 + k * 4, ink, 4)
			Draw.line(img, ex - 34, ey + 20 + k * 4, ex + 34, ey - 20 + k * 4, ink, 4)

## 褪色、发黄、水渍、折痕
func _age(img: Image) -> void:
	var n := FastNoiseLite.new()
	n.seed = 17
	n.frequency = 0.01
	var w := img.get_width()
	var h := img.get_height()
	for y in h:
		for x in w:
			var c := img.get_pixel(x, y)
			var v := n.get_noise_2d(x, y) * 0.5 + 0.5
			var yel := Color(0.62, 0.52, 0.3)
			c = c.lerp(yel, 0.18 + 0.25 * v)
			if absf(x - w * 0.5) < 2 or absf(y - h * 0.48) < 2:
				c = c.darkened(0.25)          # 折痕
			var dx := (x - w * 0.5) / (w * 0.5)
			var dy := (y - h * 0.5) / (h * 0.5)
			c = c.darkened(clampf((dx * dx + dy * dy) * 0.35 - 0.05, 0.0, 0.4))
			img.set_pixel(x, y, Color(c.r, c.g, c.b, 1.0))
	# 右下角被撕掉一块
	for y in range(h - 160, h):
		for x in range(w - 140, w):
			if (x - (w - 140)) + (y - (h - 160)) * 0.9 > 120:
				img.set_pixel(x, y, Color(0.18, 0.15, 0.1, 1.0))
