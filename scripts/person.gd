extends RefCounted
## 写实向人物:放样躯干/四肢、雕刻头部 + 彩绘脸、带手指的手、衣服、头发。朝向 -Z,脚底在原点。
## 返回 {root, body, head, arm_l, arm_r, elbow_l, elbow_r, jaw(可空)},与旧 humanoid 接口兼容。

const ML = preload("res://scripts/meshlib.gd")
const Draw = preload("res://scripts/draw.gd")
const Slots = preload("res://scripts/asset_slots.gd")

static var _fabric_cache: Dictionary = {}

# ---------------- 材质 ----------------
static func _mat(o: Dictionary, color: Color, rough: float = 0.7, tex: Texture2D = null, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color.WHITE if tex != null else color
	m.albedo_texture = tex
	m.roughness = rough
	m.metallic = metal
	m.texture_repeat = tex != null and not o.get("_face", false)
	if o.get("ghost", false):
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		var c := m.albedo_color
		m.albedo_color = Color(c.r, c.g, c.b, 0.58)
		m.emission_enabled = true
		m.emission = Color(0.35, 0.55, 0.85)
		m.emission_energy_multiplier = 0.35
	return m

static func _noise_tex(base: Color, seed_v: int, contrast: float = 0.22, weave: int = 0, dirt: float = 0.0, stains: bool = false) -> ImageTexture:
	var key := "%s_%d_%d_%d_%s" % [str(base), seed_v, weave, int(dirt * 10), str(stains)]
	if _fabric_cache.has(key):
		return _fabric_cache[key]
	var S := 128
	var n := FastNoiseLite.new()
	n.frequency = 0.05
	n.seed = seed_v
	var g: Image = n.get_seamless_image(S, S)
	var f := FastNoiseLite.new()
	f.frequency = 0.4
	f.seed = seed_v + 9
	var h: Image = f.get_seamless_image(S, S)
	var img := Image.create(S, S, false, Image.FORMAT_RGB8)
	for y in S:
		for x in S:
			var a: float = g.get_pixel(x, y).r
			var b: float = h.get_pixel(x, y).r
			var k := 1.0 - contrast * 0.5 + contrast * a + (b - 0.5) * 0.08
			if weave > 0 and ((x / weave + y / weave) % 2 == 0):
				k *= 0.93
			var c := base * k
			if dirt > 0.0:
				c = c.lerp(Color(0.18, 0.14, 0.1), clampf((1.0 - a) * dirt - 0.2, 0.0, 0.7))
			img.set_pixel(x, y, Color(clampf(c.r, 0, 1), clampf(c.g, 0, 1), clampf(c.b, 0, 1)))
	if stains:
		var rng := RandomNumberGenerator.new()
		rng.seed = seed_v
		for i in 10:
			var col := Color(0.32, 0.5, 0.2) if i % 2 == 0 else Color(0.42, 0.08, 0.06)
			var cx := rng.randf() * S
			var cy := rng.randf() * S
			var r := rng.randf_range(3.0, 9.0)
			for y in range(int(cy - r), int(cy + r)):
				for x in range(int(cx - r), int(cx + r)):
					var d := Vector2(x - cx, y - cy).length() / r
					if d < 1.0 and x >= 0 and y >= 0 and x < S and y < S:
						img.set_pixel(x, y, img.get_pixel(x, y).lerp(col, (1.0 - d) * 0.8))
	img.generate_mipmaps()
	var t := ImageTexture.create_from_image(img)
	_fabric_cache[key] = t
	return t

static func _add(parent: Node, mesh: Mesh, mat: Material, pos: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi

static func _ball(parent: Node, pos: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 20
	sm.rings = 12
	var mi := _add(parent, sm, mat, pos)
	mi.scale = radii
	return mi

# ---------------- 手 ----------------
## 手掌 + 四指(三节) + 拇指。curl 0 张开 .. 1 握拳。局部:手腕在原点,手指朝 -Y。
static func make_hand(skin: Material, scale: float = 1.0, curl: float = 0.28) -> Node3D:
	var h := Node3D.new()
	h.scale = Vector3.ONE * scale
	var palm := ML.loft([Vector3(0, 0, 0), Vector3(0, -0.045, 0), Vector3(0, -0.09, 0)], [Vector2(0.030, 0.014), Vector2(0.040, 0.016), Vector2(0.041, 0.014)], 12)
	_add(h, palm, skin)
	var lens := [0.040, 0.048, 0.044, 0.034]
	for i in 4:
		var x := -0.0285 + i * 0.019
		var L: float = lens[i]
		var path := []
		var p := Vector3(x, -0.088, 0.0)
		path.append(p)
		var ang := 0.0
		var dir := Vector3(0, -1, 0)
		var seg_len := [L * 0.45, L * 0.32, L * 0.23]
		for sgm in 3:
			ang += curl * (0.55 + 0.25 * sgm)
			dir = Vector3(0, -cos(ang), -sin(ang) * 1.0)
			p += dir * seg_len[sgm]
			path.append(p)
		_add(h, ML.loft(path, [Vector2(0.0078, 0.0075), Vector2(0.0072, 0.007), Vector2(0.0065, 0.0062), Vector2(0.005, 0.005)], 8), skin)
	var tp := [Vector3(0.036, -0.022, -0.004), Vector3(0.052, -0.05, -0.012 - curl * 0.01), Vector3(0.056, -0.078 + curl * 0.01, -0.02 - curl * 0.015)]
	_add(h, ML.loft(tp, [Vector2(0.011, 0.01), Vector2(0.0095, 0.009), Vector2(0.0075, 0.007)], 8), skin)
	return h

# ---------------- 头发 ----------------
static func _strand(parent: Node, path: Array, w0: float, w1: float, mat: Material) -> void:
	var radii := []
	for i in path.size():
		var t := float(i) / (path.size() - 1)
		var r := lerpf(w0, w1, t)
		radii.append(Vector2(r, r))
	_add(parent, ML.loft(path, radii, 6, {"caps": false}), mat)

static func _hair_cap(head: Node3D, mat: Material, tilt_deg: float = 30.0, scale: float = 1.07) -> void:
	var prof := []
	for i in 14:
		var t := float(i) / 13.0
		var ang := t * PI * 0.5
		prof.append(Vector2(sin(ang) * 0.088 * scale, 0.125 * scale * cos(ang) + 0.015))
	prof.append(Vector2(0.088 * scale, 0.0))
	prof.append(Vector2(0.084 * scale, -0.02))
	var cap := ML.revolve(prof, 30, 0.0, 8, true)
	var mi := _add(head, cap, mat, Vector3(0, 0.0, 0.01))
	mi.rotation_degrees.x = tilt_deg

# ---------------- 主构建 ----------------
static func build(o: Dictionary = {}) -> Dictionary:
	# 素材替换槽:assets/models/<slot>.glb 存在时用导入的模型
	var slot: String = o.get("slot", "")
	if slot != "":
		var d := Slots.character(slot)
		if not d.is_empty():
			if o.get("ghost", false):
				_ghost_imported(d["root"], _mat(o, o.get("skin", Color(0.62, 0.8, 1.0)), 0.5))
			return d
	var female: bool = o.get("female", false)
	var ghost: bool = o.get("ghost", false)
	var skin_c: Color = o.get("skin", Color(0.8, 0.64, 0.55))
	var skin_tex := _noise_tex(skin_c, 4, 0.14)
	var skin := _mat(o, skin_c, 0.58, skin_tex)
	var arm_len: float = o.get("arm_len", 1.0)
	var neck_len: float = o.get("neck_len", 0.0)
	var cloth: String = o.get("cloth", "")
	var coat_c: Color = o.get("coat", Color(0.8, 0.8, 0.75))
	var pants_c: Color = o.get("pants", Color(0.15, 0.15, 0.2))
	var root := Node3D.new()
	var body := Node3D.new()
	body.position = Vector3(0, 0.93, 0)
	body.rotation.x = o.get("hunch", 0.0)
	root.add_child(body)

	# ----- 躯干(含脖子) -----
	var ty := [-0.04, 0.10, 0.22, 0.36, 0.46, 0.51, 0.545, 0.58, 0.64, 0.70 + neck_len]
	var tr: Array
	if female:
		tr = [Vector2(0.165, 0.105), Vector2(0.142, 0.092), Vector2(0.122, 0.085), Vector2(0.135, 0.098), Vector2(0.15, 0.098), Vector2(0.158, 0.082), Vector2(0.118, 0.07), Vector2(0.072, 0.058), Vector2(0.05, 0.05), Vector2(0.048, 0.05)]
	else:
		tr = [Vector2(0.16, 0.10), Vector2(0.146, 0.095), Vector2(0.14, 0.092), Vector2(0.158, 0.105), Vector2(0.17, 0.108), Vector2(0.17, 0.09), Vector2(0.135, 0.078), Vector2(0.088, 0.064), Vector2(0.054, 0.054), Vector2(0.052, 0.054)]
	var tpath := []
	for y in ty:
		tpath.append(Vector3(0, y, 0))
	_add(body, ML.loft(tpath, tr, 28, {"uv_u": 2, "uv_v": 2}), skin)

	# ----- 腿 -----
	var pants_tex := _noise_tex(pants_c, 7, 0.2, 3)
	var pants := _mat(o, pants_c, 0.85, pants_tex)
	var shoe := _mat(o, Color(0.07, 0.06, 0.06), 0.75)
	var legs_bare: bool = o.get("legs_bare", false)
	for sx in [-1.0, 1.0]:
		var x: float = sx * 0.092
		var thigh := ML.loft([Vector3(x, 0.93, 0), Vector3(x * 0.98, 0.72, -0.005), Vector3(x * 0.96, 0.50, 0.0)], [Vector2(0.088, 0.09), Vector2(0.075, 0.078), Vector2(0.058, 0.062)], 18, {"uv_u": 2, "uv_v": 2})
		var shin := ML.loft([Vector3(x * 0.96, 0.50, 0.0), Vector3(x * 0.94, 0.30, 0.012), Vector3(x * 0.92, 0.085, 0.0)], [Vector2(0.056, 0.058), Vector2(0.05, 0.056), Vector2(0.036, 0.04)], 16, {"uv_u": 2, "uv_v": 2})
		var lm: Material = skin if legs_bare else pants
		var grow := 0.0 if legs_bare else 0.011
		var thigh_c := ML.loft([Vector3(x, 0.93, 0), Vector3(x * 0.98, 0.72, -0.005), Vector3(x * 0.96, 0.50, 0.0)], [Vector2(0.088 + grow, 0.09 + grow), Vector2(0.075 + grow, 0.078 + grow), Vector2(0.058 + grow, 0.062 + grow)], 18, {"ripple": 0.03 if not legs_bare else 0.0, "ripple_n": 5, "uv_u": 2, "uv_v": 2})
		var shin_c := ML.loft([Vector3(x * 0.96, 0.50, 0.0), Vector3(x * 0.94, 0.30, 0.012), Vector3(x * 0.92, 0.085, 0.0)], [Vector2(0.056 + grow, 0.058 + grow), Vector2(0.05 + grow, 0.056 + grow), Vector2(0.038 + grow, 0.042 + grow)], 16, {"ripple": 0.035 if not legs_bare else 0.0, "ripple_n": 5, "uv_u": 2, "uv_v": 2})
		_add(root, thigh_c, lm)
		_add(root, shin_c, lm)
		_ball(root, Vector3(x * 0.96, 0.5, 0.0), Vector3(0.062, 0.06, 0.064), lm)
		var foot := ML.loft([Vector3(x * 0.92, 0.07, 0.075), Vector3(x * 0.92, 0.05, -0.04), Vector3(x * 0.92, 0.04, -0.15), Vector3(x * 0.92, 0.035, -0.235)], [Vector2(0.046, 0.05), Vector2(0.05, 0.052), Vector2(0.052, 0.042), Vector2(0.04, 0.028)], 14, {"ref": Vector3(0, 1, 0)})
		_add(root, foot, shoe)
		WB_box(root, Vector3(x * 0.92, 0.012, -0.07), Vector3(0.1, 0.024, 0.34), _mat(o, Color(0.04, 0.04, 0.04), 0.7))

	# ----- 衣服(躯干) -----
	var coat_tex: Texture2D = null
	var coat_m: Material
	match cloth:
		"labcoat":
			coat_tex = _noise_tex(coat_c, 21, 0.12, 4, 0.25, o.get("stains", false))
			coat_m = _mat(o, coat_c, 0.9, coat_tex)
		"jacket":
			coat_tex = _noise_tex(coat_c, 33, 0.28, 3, 0.35)
			coat_m = _mat(o, coat_c, 0.88, coat_tex)
		"dress":
			coat_tex = _noise_tex(coat_c, 41, 0.12, 2)
			coat_m = _mat(o, coat_c, 0.85, coat_tex)
		_:
			coat_m = null
	var sleeve_len := 1.0 if cloth in ["labcoat", "jacket", "dress", "robe"] else 0.0
	if coat_m != null:
		var off := 0.02 if cloth != "dress" else 0.008
		var cr: Array = []
		for r in tr:
			cr.append(Vector2(r.x + off, r.y + off))
		_add(body, ML.loft(tpath.slice(0, 8), cr.slice(0, 8), 28, {"ripple": 0.03 if cloth != "dress" else 0.01, "ripple_n": 7, "uv_u": 2, "uv_v": 2}), coat_m)
		if cloth == "labcoat" or cloth == "robe":
			var prof := [Vector2(0.172, 0.14), Vector2(0.186, 0.02), Vector2(0.205, -0.15), Vector2(0.225, -0.36), Vector2(0.24, -0.58), Vector2(0.245, -0.68)]
			_add(body, ML.revolve(prof, 40, 0.06, 7, false, 3.0, 2.0), coat_m)
			# 翻领与前襟开口
			for sx in [-1.0, 1.0]:
				var lp := ML.loft([Vector3(sx * 0.03, 0.56, -0.085), Vector3(sx * 0.09, 0.44, -0.125), Vector3(sx * 0.06, 0.2, -0.14)], [Vector2(0.05, 0.006), Vector2(0.045, 0.007), Vector2(0.03, 0.006)], 8, {"ref": Vector3(1, 0, 0)})
				_add(body, lp, coat_m)
		elif cloth == "dress":
			var prof2 := [Vector2(0.15, 0.14), Vector2(0.19, 0.0), Vector2(0.25, -0.2), Vector2(0.3, -0.38)]
			_add(body, ML.revolve(prof2, 40, 0.05, 11, false, 3.0, 2.0), coat_m)
		elif cloth == "jacket":
			# 立领 + 腰带 + 腰包
			_add(body, ML.loft([Vector3(0, 0.56, 0), Vector3(0, 0.66, 0)], [Vector2(0.088, 0.078), Vector2(0.09, 0.08)], 20, {"caps": false}), coat_m)
			var belt := _mat(o, Color(0.1, 0.08, 0.06), 0.6)
			_add(body, ML.loft([Vector3(0, 0.08, 0), Vector3(0, 0.12, 0)], [Vector2(0.168, 0.118), Vector2(0.168, 0.118)], 28, {"caps": false}), belt)
			for px in [-0.1, 0.1]:
				WB_box(body, Vector3(px, 0.08, -0.115), Vector3(0.07, 0.085, 0.045), belt)

	# ----- 头 -----
	var head := Node3D.new()
	head.position = Vector3(0, 0.72 + neck_len, 0)
	head.scale = Vector3.ONE * o.get("head_scale", 1.06)
	body.add_child(head)
	var hopts: Dictionary = o.get("head", {})
	if female and not hopts.has("jaw_w"):
		hopts["jaw_w"] = 1.0
	var hd := ML.head(hopts)
	var fopts: Dictionary = o.get("face", {})
	fopts["skin"] = skin_c
	fopts["female"] = female
	var face_tex := Draw.face_texture(fopts)
	var fo := o.duplicate()
	fo["_face"] = true
	var face_mat := _mat(fo, skin_c, 0.55, face_tex)
	face_mat.texture_repeat = false
	if ghost:
		face_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.9)
		face_mat.emission_energy_multiplier = 0.5
	_add(head, hd["upper"], face_mat)
	var jaw_node: Node3D = null
	if hd["jaw"] != null:
		jaw_node = Node3D.new()
		jaw_node.position = hd["pivot"]
		head.add_child(jaw_node)
		_add(jaw_node, hd["jaw"], face_mat)
		_ball(head, Vector3(0, -0.062, -0.045), Vector3(0.04, 0.02, 0.03), _mat(o, Color(0.04, 0.01, 0.01), 0.9))
	# 耳朵
	for sx in [-1.0, 1.0]:
		var ear := _ball(head, Vector3(sx * 0.0765, -0.004, 0.012), Vector3(0.0085, 0.028, 0.019), skin)
		ear.rotation_degrees.y = sx * 12.0
	# 头发
	var hair_c = o.get("hair", null)
	var hmat: Material = null
	if hair_c != null:
		hmat = _mat(o, hair_c, 0.4, null, 0.1)
		_hair_cap(head, hmat)
		var style: String = o.get("hair_style", "long" if o.get("long_hair", false) else "short")
		if style == "long":
			var rng := RandomNumberGenerator.new()
			rng.seed = 12
			for i in 22:
				var a := deg_to_rad(lerpf(-105.0, 105.0, float(i) / 21.0))
				var base := Vector3(sin(a) * 0.082, -0.01 + rng.randf() * 0.03, cos(a) * 0.085 + 0.012)
				var pth := []
				var len := rng.randf_range(0.28, 0.42)
				for k in 6:
					var t := float(k) / 5.0
					pth.append(Vector3(base.x * (1.0 + 0.05 * t) + sin(t * 4.0 + i) * 0.012, base.y - t * len, base.z + 0.02 + t * 0.045 + (0.0 if absf(sin(a)) < 0.6 else -0.03 * t)))
				_strand(head, pth, 0.0085, 0.0035, hmat)
		elif style == "braids":
			for sx in [-1.0, 1.0]:
				var path := []
				var radii := []
				for k in 9:
					var t := float(k) / 8.0
					path.append(Vector3(sx * (0.083 + 0.01 * t), -0.02 - t * 0.28, 0.03 + sin(t * 3.0) * 0.004))
					radii.append(Vector2(0.015 - t * 0.006 + (0.004 if k % 2 == 0 else 0.0), 0.014 - t * 0.006))
				_add(head, ML.loft(path, radii, 10), hmat)
				_ball(head, Vector3(sx * 0.093, -0.3, 0.03), Vector3(0.012, 0.012, 0.012), _mat(o, Color(0.8, 0.1, 0.2), 0.5))
	if o.get("wisps", false):
		var gm := _mat(o, Color(0.66, 0.65, 0.62), 0.6)
		var rng2 := RandomNumberGenerator.new()
		rng2.seed = 9
		for i in 34:
			var side := -1.0 if i % 2 == 0 else 1.0
			var h0 := rng2.randf()
			var b := Vector3(side * (0.072 + 0.006 * h0), 0.015 + h0 * 0.06, 0.02 + rng2.randf() * 0.05)
			var pth2 := [b, b + Vector3(side * 0.012, 0.002, 0.018), b + Vector3(side * 0.018, -0.018 - rng2.randf() * 0.02, 0.036 + rng2.randf() * 0.02), b + Vector3(side * 0.012, -0.05 - rng2.randf() * 0.04, 0.05 + rng2.randf() * 0.03)]
			_strand(head, pth2, 0.0017, 0.0005, gm)
		# 后脑勺一圈灰白细发
		for i in 14:
			var aa := deg_to_rad(lerpf(-70.0, 70.0, float(i) / 13.0))
			var bb := Vector3(sin(aa) * 0.075, 0.0 + rng2.randf() * 0.03, 0.06 + cos(aa) * 0.035)
			_strand(head, [bb, bb + Vector3(sin(aa) * 0.01, -0.03, 0.012), bb + Vector3(sin(aa) * 0.012, -0.065, 0.02)], 0.0017, 0.0005, gm)
	if o.get("glasses", false):
		var gl := _mat(o, Color(0.05, 0.05, 0.06), 0.3, null, 0.5)
		for sx in [-1.0, 1.0]:
			var ring := TorusMesh.new()
			ring.inner_radius = 0.0165
			ring.outer_radius = 0.0185
			var rm := _add(head, ring, gl, Vector3(sx * 0.036, 0.028, -0.084))
			rm.rotation_degrees.x = 90.0
			rm.scale = Vector3(1.1, 1.0, 0.85)
		WB_box(head, Vector3(0, 0.032, -0.092), Vector3(0.02, 0.003, 0.003), gl)

	# ----- 手臂 -----
	var out := {"root": root, "body": body, "head": head}
	if jaw_node != null:
		out["jaw"] = jaw_node
	var sleeve_m: Material = coat_m if (coat_m != null and sleeve_len > 0.0) else skin
	var hand_skin: Material = skin
	if o.has("glove"):
		hand_skin = _mat(o, o["glove"], 0.3)
	var short_sleeve: bool = o.get("short_sleeve", false)
	for side in ["l", "r"]:
		var sx: float = -1.0 if side == "l" else 1.0
		var sh := Node3D.new()
		sh.position = Vector3(sx * 0.178, 0.5, 0)
		body.add_child(sh)
		var up_len := 0.30 * arm_len
		var fo_len := 0.27 * arm_len
		var sr := 0.012 if coat_m != null and sleeve_len > 0.0 else 0.0
		_ball(sh, Vector3(0, -0.012, 0), Vector3(0.047 + sr, 0.05 + sr, 0.047 + sr), sleeve_m)
		_add(sh, ML.loft([Vector3(0, 0.0, 0), Vector3(0, -up_len * 0.5, 0.004), Vector3(0, -up_len, 0)], [Vector2(0.047 + sr, 0.047 + sr), Vector2(0.043 + sr, 0.043 + sr), Vector2(0.036 + sr, 0.036 + sr)], 16, {"ripple": 0.03 if sr > 0 else 0.0, "ripple_n": 4, "uv_u": 2, "uv_v": 1}), sleeve_m)
		var el := Node3D.new()
		el.position = Vector3(0, -up_len, 0)
		sh.add_child(el)
		_ball(el, Vector3.ZERO, Vector3(0.037 + sr, 0.036 + sr, 0.037 + sr), sleeve_m)
		_add(el, ML.loft([Vector3(0, 0, 0), Vector3(0, -fo_len * 0.5, -0.004), Vector3(0, -fo_len, 0)], [Vector2(0.039 + sr, 0.039 + sr), Vector2(0.036 + sr, 0.035 + sr), Vector2(0.027 + sr * 0.5, 0.026 + sr * 0.5)], 14, {"ripple": 0.03 if sr > 0 else 0.0, "ripple_n": 4, "uv_u": 2, "uv_v": 1}), sleeve_m)
		var hand := make_hand(hand_skin, 1.0, o.get("curl", 0.28))
		hand.position = Vector3(0, -fo_len, 0)
		hand.rotation_degrees.y = sx * -10.0
		el.add_child(hand)
		out["arm_" + side] = sh
		out["elbow_" + side] = el
		out["hand_" + side] = hand
	# 背包带与证件(Veronica 风格)
	if o.get("strap", false):
		var strap := _mat(o, Color(0.12, 0.1, 0.08), 0.7)
		_add(body, ML.loft([Vector3(-0.17, 0.5, -0.07), Vector3(0.0, 0.3, -0.125), Vector3(0.14, 0.08, -0.125)], [Vector2(0.025, 0.006), Vector2(0.025, 0.006), Vector2(0.025, 0.006)], 6, {"ref": Vector3(0, 0, -1)}), strap)
	return out

static func _ghost_imported(n: Node, m: Material) -> void:
	if n is MeshInstance3D:
		(n as MeshInstance3D).material_override = m
	for c in n.get_children():
		_ghost_imported(c, m)

static func WB_box(parent: Node, pos: Vector3, size: Vector3, mat: Material) -> MeshInstance3D:
	var bm := BoxMesh.new()
	bm.size = size
	return _add(parent, bm, mat, pos)

static func set_layers(n: Node, layers: int) -> void:
	if n is VisualInstance3D:
		n.layers = layers
	for c in n.get_children():
		set_layers(c, layers)
