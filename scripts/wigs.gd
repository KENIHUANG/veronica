extends RefCounted
## 假发与人体模型:光滑的塑料头 + 一缕缕放样的发丝,不再是球和方块。

const Slots = preload("res://scripts/asset_slots.gd")
const ML = preload("res://scripts/meshlib.gd")
const Person = preload("res://scripts/person.gd")
const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")

static func _hair_mat(color: Color, rough: float = 0.35, metal: float = 0.1) -> StandardMaterial3D:
	return Person._mat({}, color, rough, null, metal)

static func _plastic() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.86, 0.83, 0.76)
	m.roughness = 0.45
	m.clearcoat_enabled = true
	m.clearcoat = 0.3
	return m

## 空白的塑料人头(有鼻梁和嘴唇的起伏,没有五官),脸朝 -Z
static func blank_head(parent: Node, pos: Vector3, yaw_deg: float = 0.0, tilt_deg: float = 0.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees = Vector3(tilt_deg, yaw_deg, 0)
	parent.add_child(n)
	var hd := ML.head({"width": 0.98, "gaunt": 0.1, "socket": 0.2, "brow": 0.6, "nose": 0.8})
	var mi := MeshInstance3D.new()
	mi.mesh = hd["upper"]
	mi.material_override = _plastic()
	n.add_child(mi)
	var neck := MeshInstance3D.new()
	neck.mesh = ML.loft([Vector3(0, -0.09, 0.01), Vector3(0, -0.2, 0.01)], [Vector2(0.045, 0.045), Vector2(0.05, 0.05)], 12)
	neck.material_override = _plastic()
	n.add_child(neck)
	return n

static func _strand(parent: Node, path: Array, w0: float, w1: float, mat: Material) -> void:
	Person._strand(parent, path, w0, w1, mat)

## kind: "comb" 橙色大背头 / "afro" 爆炸头 / "twin" 青绿双马尾。head 是 blank_head 的节点。
static func wig(head: Node3D, kind: String) -> void:
	if Slots.prop("wig_" + kind, head, Vector3.ZERO, 0.0, false) != null:
		return
	match kind:
		"comb":
			# 金黄色、蓬松得不科学的侧分大背头:左侧分线,一大片头发从左往右、从前往后梳过头顶,
			# 额前高高隆起一道"浪",两侧和后脑压得很平,发梢往后翘。
			var m := _hair_mat(Color(0.82, 0.6, 0.26), 0.45, 0.05)
			var m_dark := _hair_mat(Color(0.7, 0.5, 0.2), 0.5, 0.03)
			Person._hair_cap(head, m_dark, 10.0, 1.16)
			# 额前的大浪:一根粗的放样管,沿额头从左到右,中间最高
			var wave := []
			var wr := []
			for i in 9:
				var t := float(i) / 8.0
				var x := lerpf(-0.07, 0.095, t)
				wave.append(Vector3(x, 0.1 + 0.04 * sin(t * PI) + 0.012 * t, -0.07 + 0.015 * t))
				wr.append(Vector2(0.036 + 0.012 * sin(t * PI), 0.045 + 0.012 * sin(t * PI)))
			var wm := MeshInstance3D.new()
			wm.mesh = ML.loft(wave, wr, 14)
			wm.material_override = m
			head.add_child(wm)
			# 顶上一层层从左前梳向右后的发片
			var rng := RandomNumberGenerator.new()
			rng.seed = 4
			for i in 60:
				var t := float(i) / 59.0
				var z0 := lerpf(-0.08, 0.07, t)
				var lift := 0.05 * (1.0 - t)
				var path := [
					Vector3(-0.08, 0.07 + rng.randf() * 0.01, z0 - 0.01),
					Vector3(-0.035, 0.13 + lift + rng.randf() * 0.008, z0),
					Vector3(0.025, 0.14 + lift * 0.8, z0 + 0.02),
					Vector3(0.08, 0.11 + lift * 0.4, z0 + 0.04),
					Vector3(0.1, 0.05, z0 + 0.07),
				]
				_strand(head, path, 0.022, 0.012, m)
			# 两侧压平往后梳,发梢上翘
			for sx in [-1.0, 1.0]:
				for k in 7:
					var b := Vector3(sx * 0.086, 0.06 - k * 0.012, -0.02 + k * 0.014)
					_strand(head, [b, b + Vector3(sx * 0.006, -0.01, 0.05), b + Vector3(sx * 0.004, 0.0, 0.1)], 0.008, 0.003, m_dark)
			for k in 10:
				var bx := lerpf(-0.06, 0.06, float(k) / 9.0)
				_strand(head, [Vector3(bx, 0.07, 0.085), Vector3(bx * 1.1, 0.02, 0.1), Vector3(bx * 1.2, 0.0, 0.125)], 0.01, 0.004, m_dark)
		"afro":
			var m2 := _hair_mat(Color(0.05, 0.04, 0.04), 0.9, 0.0)
			var prof := []
			for i in 16:
				var a := PI * i / 15.0
				prof.append(Vector2(sin(a) * 0.19, 0.075 + cos(a) * 0.2))
			var cap := MeshInstance3D.new()
			cap.mesh = ML.revolve(prof, 40, 0.1, 11, true)
			cap.material_override = m2
			cap.position = Vector3(0, 0.02, 0.025)
			head.add_child(cap)
			var rng2 := RandomNumberGenerator.new()
			rng2.seed = 8
			for i in 110:
				var a1 := rng2.randf() * PI * 0.92
				var a2 := rng2.randf() * TAU
				var rr := 0.2 + rng2.randf() * 0.01
				var p := Vector3(sin(a1) * cos(a2) * rr, 0.095 + cos(a1) * rr * 0.98, sin(a1) * sin(a2) * rr * 0.9 + 0.025)
				if p.y < 0.05 and p.z < 0.0:
					continue
				Person._ball(head, p, Vector3(1, 1, 1) * rng2.randf_range(0.03, 0.05), m2)
		"twin":
			var m3 := _hair_mat(Color(0.1, 0.78, 0.82), 0.3, 0.2)
			Person._hair_cap(head, m3, 26.0, 1.12)
			var rng3 := RandomNumberGenerator.new()
			rng3.seed = 15
			for i in 14:      # 刘海
				var x := lerpf(-0.07, 0.07, float(i) / 13.0)
				_strand(head, [Vector3(x, 0.115, -0.02), Vector3(x * 1.05, 0.1, -0.07), Vector3(x * 1.08, 0.075 - rng3.randf() * 0.015, -0.1)], 0.007, 0.0025, m3)
			for sx in [-1.0, 1.0]:
				_ball_tie(head, Vector3(sx * 0.1, 0.07, 0.02), m3)
				var path := []
				var radii := []
				for k in 12:
					var t := float(k) / 11.0
					path.append(Vector3(sx * (0.12 + sin(t * 3.0) * 0.03 + t * 0.03), 0.07 - t * 0.9, 0.02 + sin(t * 5.0) * 0.02))
					radii.append(Vector2(0.032 * (1.0 - t * 0.78), 0.03 * (1.0 - t * 0.78)))
				head.add_child(_mi(ML.loft(path, radii, 12, {"ripple": 0.12, "ripple_n": 4}), m3))
				for k in 5:
					var b := Vector3(sx * 0.1, 0.06, 0.02)
					var pth := []
					for q in 6:
						var tt := float(q) / 5.0
						pth.append(b + Vector3(sx * (0.03 + tt * 0.08 + k * 0.006), -tt * (0.5 + k * 0.03), sin(tt * 4.0 + k) * 0.02))
					_strand(head, pth, 0.006, 0.002, m3)

static func _mi(mesh: Mesh, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.material_override = mat
	return mi

static func _ball_tie(parent: Node, pos: Vector3, mat: Material) -> void:
	Person._ball(parent, pos, Vector3(0.035, 0.035, 0.035), mat)
	Person._ball(parent, pos + Vector3(0, 0.0, 0.0), Vector3(0.012, 0.045, 0.012), Mats.solid(Color(0.9, 0.1, 0.3), 0.4))

## 无臂的塑料人体模型(放样躯干),可选头与底座。返回根节点。
static func mannequin(parent: Node, pos: Vector3, yaw_deg: float, with_stand: bool = true, tilt_head: float = 0.0, arm_up: bool = false) -> Node3D:
	if with_stand:     # 柜子惊吓里的"半个人体模型"保持程序化(需要断口和特定姿势)
		var slot := Slots.prop("mannequin", parent, pos, yaw_deg)
		if slot != null:
			return slot
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	var pm := _plastic()
	var ty := [0.0, 0.14, 0.28, 0.4, 0.5, 0.55, 0.6, 0.66]
	var tr := [Vector2(0.15, 0.1), Vector2(0.13, 0.09), Vector2(0.115, 0.085), Vector2(0.13, 0.095), Vector2(0.15, 0.095), Vector2(0.14, 0.08), Vector2(0.09, 0.066), Vector2(0.05, 0.05)]
	var path := []
	for y in ty:
		path.append(Vector3(0, y + 0.88, 0))
	n.add_child(_mi(ML.loft(path, tr, 22), pm))
	if with_stand:
		WB.cyl(n, Vector3(0, 0.44, 0), 0.025, 0.88, Mats.solid(Color(0.15, 0.15, 0.16), 0.4, 0.7), false)
		WB.cyl(n, Vector3(0, 0.01, 0), 0.22, 0.02, Mats.solid(Color(0.12, 0.12, 0.13), 0.4, 0.7), false)
	var h := blank_head(n, Vector3(0, 1.66, 0), 0.0, tilt_head)
	h.scale = Vector3.ONE * 0.96
	# 肩部断臂接口
	for sx in [-1.0, 1.0]:
		var arm := MeshInstance3D.new()
		arm.mesh = ML.loft([Vector3(sx * 0.17, 1.4, 0), Vector3(sx * 0.2, 1.2, -0.02), Vector3(sx * 0.205, 1.0, -0.04)], [Vector2(0.045, 0.045), Vector2(0.04, 0.04), Vector2(0.034, 0.034)], 12)
		arm.material_override = pm
		if arm_up and sx > 0:
			arm.rotation_degrees.x = 140.0
			arm.position = Vector3(0, 2.0, 0.4)
		n.add_child(arm)
	return n
