extends Node3D
## 用血写在墙上的字:先用手写字体把文字渲染成图,再"画"成血:
## 颜色深浅不匀、笔画边缘干涸破碎、底部往下淌血,周围有几滴溅点。
## 平面朝向本地 +Z(和 QuadMesh 一样),width 为世界宽度(米)。

const HW = preload("res://scripts/handwriting.gd")

@export var text := "HE IS STILL\nIN HERE."
@export var width := 1.6
@export var seed_v := 7

var quad: MeshInstance3D

func _ready() -> void:
	quad = MeshInstance3D.new()
	add_child(quad)
	_render()

func _render() -> void:
	if DisplayServer.get_name() == "headless":
		return      # 无头模式(自动测试)没有真实渲染器
	var vp := SubViewport.new()
	vp.size = Vector2i(1024, 480)
	vp.transparent_bg = true
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	var lb := Label.new()
	lb.text = text
	lb.add_theme_font_override("font", HW.font())
	lb.add_theme_font_size_override("font_size", 130)
	lb.add_theme_constant_override("line_spacing", -18)
	lb.add_theme_color_override("font_color", Color.WHITE)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lb.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	lb.position = Vector2(0, 20)
	lb.size = Vector2(1024, 340)
	vp.add_child(lb)
	add_child(vp)
	await get_tree().process_frame
	await get_tree().process_frame
	var img: Image = null
	if vp.get_texture() != null:
		img = vp.get_texture().get_image()
	vp.queue_free()
	if img == null or img.is_empty():
		return      # 无头模式(测试)下没有真实渲染,跳过
	img.convert(Image.FORMAT_RGBA8)
	_bloodify(img)
	img.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(img)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.25
	m.roughness = 0.95
	m.metallic_specular = 0.0
	m.albedo_color = Color(0.75, 0.7, 0.7)     # 隔间顶上有灯,压暗免得血被照成粉色
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var qm := QuadMesh.new()
	qm.size = Vector2(width, width * img.get_height() / img.get_width())
	quad.mesh = qm
	quad.material_override = m

func _bloodify(img: Image) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_v
	var n := FastNoiseLite.new()
	n.seed = seed_v
	n.frequency = 0.03
	var fine := FastNoiseLite.new()
	fine.seed = seed_v + 5
	fine.frequency = 0.25
	var mask := PackedFloat32Array()
	mask.resize(w * h)
	for y in h:
		for x in w:
			mask[y * w + x] = img.get_pixel(x, y).a
	# 淌血:从每一列笔画的最低处,随机往下流
	var drips := PackedFloat32Array()
	drips.resize(w * h)
	var x := 0
	while x < w:
		var low := -1
		for y in range(h - 1, -1, -1):
			if mask[y * w + x] > 0.6:
				low = y
				break
		if low > 0 and rng.randf() < 0.22:
			var length := rng.randi_range(15, 110)
			var thick := rng.randf_range(1.5, 3.5)
			for k in length:
				var yy := low + k
				if yy >= h - 6:
					break
				var t := float(k) / length
				var rad := thick * (1.0 - 0.6 * t)
				for dx in range(-3, 4):
					var xx := x + dx
					if xx >= 0 and xx < w and absf(dx) <= rad:
						drips[yy * w + xx] = 1.0
			# 末端的血珠
			var by := mini(low + length, h - 6)
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var xx := x + dx
					var yy := by + dy
					if xx >= 0 and xx < w and yy >= 0 and yy < h and dx * dx + dy * dy <= thick * thick * 2.2:
						drips[yy * w + xx] = 1.0
			x += rng.randi_range(6, 14)
		else:
			x += 3
	# 溅点
	for i in 40:
		var cx := rng.randf_range(20, w - 20)
		var cy := rng.randf_range(10, h - 40)
		var r := rng.randf_range(1.0, 4.5)
		for dy in range(-5, 6):
			for dx in range(-5, 6):
				if dx * dx + dy * dy <= r * r:
					var xx := int(cx) + dx
					var yy := int(cy) + dy
					if xx >= 0 and xx < w and yy >= 0 and yy < h:
						drips[yy * w + xx] = 1.0
	for y in h:
		for x2 in w:
			var a: float = maxf(mask[y * w + x2], drips[y * w + x2])
			if a <= 0.02:
				img.set_pixel(x2, y, Color(0, 0, 0, 0))
				continue
			var v := n.get_noise_2d(x2, y) * 0.5 + 0.5
			var f := fine.get_noise_2d(x2, y) * 0.5 + 0.5
			# 笔画边缘干涸、破碎
			if mask[y * w + x2] > 0.0 and mask[y * w + x2] < 0.6 and f < 0.3:
				a *= 0.3
			var dark := lerpf(0.55, 1.0, v)
			var col := Color(0.34 * dark, 0.015 * dark, 0.015 * dark, a)
			if f > 0.8:
				col = col.darkened(0.35)      # 干掉的部分更暗
			img.set_pixel(x2, y, col)
