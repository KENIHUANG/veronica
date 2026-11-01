extends RefCounted
## 把一组 Control 渲染成一张图(只渲染一次),用于墙上的喷漆字、标牌、海报。
## 无头模式(自动测试)下返回 null。

static var _fonts: Dictionary = {}

const BAKED_DIR := "res://assets/baked/"

## 预渲染缓存:墙上的字、海报、血字都很费时(逐像素处理),
## 所以提前渲染成 PNG 放在 assets/baked/,运行时直接读,开局不卡。
## 重新生成:BAKE_TEX=1 godot --path . -s tools/bake_textures.gd
static func baked(key: String) -> Texture2D:
	if OS.get_environment("BAKE_TEX") == "1":
		return null
	var p := BAKED_DIR + key + ".png"
	if ResourceLoader.exists(p):
		return load(p)
	return null

static func save_baked(key: String, img: Image) -> void:
	if OS.get_environment("BAKE_TEX") != "1":
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(BAKED_DIR))
	img.save_png(ProjectSettings.globalize_path(BAKED_DIR + key + ".png"))

static func quad_tex(parent: Node3D, tex: Texture2D, width: float, alpha: bool = true, rough: float = 0.9) -> MeshInstance3D:
	var m := StandardMaterial3D.new()
	m.albedo_texture = tex
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.3
	m.roughness = rough
	m.metallic_specular = 0.2
	var qm := QuadMesh.new()
	qm.size = Vector2(width, width * tex.get_height() / tex.get_width())
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = m
	parent.add_child(mi)
	return mi

## kind: "stencil" 模板喷漆 / "typewriter" 打字机 / "hand" 手写 / "bold" 粗黑体
static func font(kind: String) -> Font:
	if _fonts.has(kind):
		return _fonts[kind]
	var cjk := SystemFont.new()
	cjk.font_names = PackedStringArray(["Microsoft YaHei", "PingFang SC", "Noto Sans CJK SC", "Source Han Sans SC", "WenQuanYi Micro Hei", "Heiti SC", "sans-serif"])
	cjk.font_weight = 800
	var noto: FontFile = load("res://assets/fonts/NotoSansSC-Game.ttf")    # 网页版没有系统字体,靠它兜底
	var f: Font
	match kind:
		"stencil":
			# 拉丁字母:Allerta Stencil 模板字;中文:站酷庆科黄油体(粗壮的招牌字,和模板字气质接近)
			var ff: FontFile = load("res://assets/fonts/AllertaStencil-Regular.ttf").duplicate()
			var qk: FontFile = load("res://assets/fonts/ZCOOLQingKeHuangYou-Regular.ttf")
			ff.fallbacks = [qk, cjk, noto]
			f = ff
		"typewriter":
			var ff2: FontFile = load("res://assets/fonts/SpecialElite-Regular.ttf").duplicate()
			ff2.fallbacks = [cjk, noto]
			f = ff2
		"hand":
			f = preload("res://scripts/handwriting.gd").font()
		_:
			f = cjk
	_fonts[kind] = f
	return f

static func capture(host: Node, root_ctrl: Control, size: Vector2i) -> Image:
	if DisplayServer.get_name() == "headless":
		root_ctrl.queue_free()
		return null
	var vp := SubViewport.new()
	vp.size = size
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	vp.add_child(root_ctrl)
	host.add_child(vp)
	await host.get_tree().process_frame
	await host.get_tree().process_frame
	var img: Image = null
	if vp.get_texture() != null:
		img = vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		return null
	img.convert(Image.FORMAT_RGBA8)
	return img

static func label(text: String, kind: String, px: int, color: Color, rect: Rect2, align: int = HORIZONTAL_ALIGNMENT_CENTER) -> Label:
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_override("font", font(kind))
	lb.add_theme_font_size_override("font_size", px)
	lb.add_theme_color_override("font_color", color)
	lb.horizontal_alignment = align
	lb.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lb.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	lb.position = rect.position
	lb.size = rect.size
	return lb

## 旧化:颜料剥落(按噪声把一部分像素变透明)、颜色深浅不匀
static func weather(img: Image, seed_v: int, chip: float = 0.35, fade: float = 0.25) -> void:
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = 0.02
	var f := FastNoiseLite.new()
	f.seed = seed_v + 3
	f.frequency = 0.18
	for y in img.get_height():
		for x in img.get_width():
			var c := img.get_pixel(x, y)
			if c.a <= 0.01:
				continue
			var big := n.get_noise_2d(x, y) * 0.5 + 0.5
			var small := f.get_noise_2d(x, y) * 0.5 + 0.5
			if small * 0.6 + big * 0.4 < chip:
				c.a = 0.0
			else:
				var k := 1.0 - fade * big
				c = Color(c.r * k, c.g * k, c.b * k, c.a)
			img.set_pixel(x, y, c)

## 把图贴到一个面朝本地 +Z 的四边形上(受灯光影响)
static func quad(parent: Node3D, img: Image, width: float, alpha: bool = true, rough: float = 0.9) -> MeshInstance3D:
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	if alpha:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.3
	m.roughness = rough
	m.metallic_specular = 0.2
	var qm := QuadMesh.new()
	qm.size = Vector2(width, width * img.get_height() / img.get_width())
	var mi := MeshInstance3D.new()
	mi.mesh = qm
	mi.material_override = m
	parent.add_child(mi)
	return mi
