extends RefCounted
## 程序化人形模型(胶囊 + 椭球),用于镜中人影、Boss、鬼魂。朝向 -Z,脚底在原点。

const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")

static func _cap(parent: Node, pos: Vector3, r: float, h: float, mat: Material, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0)
	cm.radial_segments = 14
	cm.rings = 5
	mi.mesh = cm
	mi.position = pos
	mi.scale = sc
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _ell(parent: Node, pos: Vector3, radii: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 16
	sm.rings = 9
	mi.mesh = sm
	mi.position = pos
	mi.scale = radii
	mi.material_override = mat
	parent.add_child(mi)
	return mi

static func _ring(parent: Node, pos: Vector3, inner: float, outer: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 20
	tm.ring_segments = 8
	mi.mesh = tm
	mi.position = pos
	mi.rotation_degrees.x = 90.0
	mi.material_override = mat
	parent.add_child(mi)
	return mi

## o: skin, coat, pants, hair(Color 或 null=秃头), long_hair(bool), long_coat(bool), glasses(bool), hollow_eyes(bool), ghost(bool), hunch(弧度,负=前倾)
static func build(o: Dictionary) -> Dictionary:
	var ghost: bool = o.get("ghost", false)
	var wild: bool = o.get("wild", false)
	var skin_c: Color = o.get("skin", Color(0.8, 0.66, 0.58))
	var coat_c: Color = o.get("coat", Color(0.85, 0.85, 0.8))
	var pants_c: Color = o.get("pants", Color(0.15, 0.15, 0.2))
	var skin: Material = Mats.ghostly(skin_c, 0.55) if ghost else Mats.solid(skin_c, 0.65)
	var coat: Material = Mats.ghostly(coat_c, 0.5) if ghost else Mats.solid(coat_c, 0.85)
	var pants: Material = Mats.ghostly(pants_c, 0.5) if ghost else Mats.solid(pants_c, 0.9)
	var shoe: Material = Mats.ghostly(Color(0.3, 0.3, 0.4), 0.5) if ghost else Mats.solid(Color(0.06, 0.05, 0.05), 0.5)
	var dark: Material = Mats.solid(Color(0.02, 0.02, 0.02), 0.5)
	var white: Material = Mats.solid(Color(0.92, 0.92, 0.88), 0.4)
	var root := Node3D.new()
	# 腿与鞋
	for s in [-1.0, 1.0]:
		_cap(root, Vector3(s * 0.1, 0.5, 0), 0.085, 0.95, pants)
		WB.box(root, Vector3(s * 0.1, 0.04, -0.05), Vector3(0.13, 0.08, 0.3), shoe, false)
	# 上身(以髋部为轴,可前倾)
	var body := Node3D.new()
	body.position = Vector3(0, 0.95, 0)
	body.rotation.x = o.get("hunch", 0.0)
	root.add_child(body)
	_cap(body, Vector3(0, 0.3, 0), 0.17, 0.62, coat, Vector3(1.3, 1.0, 0.82))
	if o.get("long_coat", false):
		var sk := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		cm.top_radius = 0.21
		cm.bottom_radius = 0.27
		cm.height = 0.62
		cm.radial_segments = 16
		sk.mesh = cm
		sk.position = Vector3(0, -0.12, 0)
		sk.scale = Vector3(1.0, 1.0, 0.75)
		sk.material_override = coat
		body.add_child(sk)
		# 翻领
		WB.box(body, Vector3(-0.07, 0.52, -0.13), Vector3(0.08, 0.14, 0.02), coat, false).rotation.z = 0.5
		WB.box(body, Vector3(0.07, 0.52, -0.13), Vector3(0.08, 0.14, 0.02), coat, false).rotation.z = -0.5
	if wild:
		var st1 := Mats.solid(Color(0.3, 0.5, 0.22), 0.9)
		var st2 := Mats.solid(Color(0.45, 0.08, 0.06), 0.9)
		for k in 6:
			_ell(body, Vector3(-0.16 + k * 0.06, 0.12 + (k * 37 % 5) * 0.07, -0.143), Vector3(0.03 + (k % 3) * 0.012, 0.04, 0.004), st1 if k % 2 == 0 else st2)
		WB.box(body, Vector3(-0.12, 0.3, -0.147), Vector3(0.1, 0.1, 0.012), coat, false)          # 口袋
		for k in 3:
			var pen := WB.cyl(body, Vector3(-0.145 + k * 0.025, 0.37, -0.15), 0.006, 0.06, Mats.solid([Color(0.8, 0.1, 0.1), Color(0.1, 0.2, 0.8), Color(0.1, 0.1, 0.1)][k]), false)
		WB.box(body, Vector3(0.1, 0.4, -0.148), Vector3(0.065, 0.045, 0.008), Mats.solid(Color(0.9, 0.9, 0.85)), false)   # 胸牌
		WB.box(body, Vector3(0.1, 0.405, -0.153), Vector3(0.05, 0.006, 0.002), dark, false)
	_cap(body, Vector3(0, 0.68, 0), 0.05, 0.14, skin)   # 脖子
	# 头
	var head := Node3D.new()
	head.position = Vector3(0, 0.84, 0)
	body.add_child(head)
	_ell(head, Vector3.ZERO, Vector3(0.105, 0.13, 0.115), skin)
	_ell(head, Vector3(-0.105, 0, 0.0), Vector3(0.015, 0.03, 0.02), skin)  # 耳
	_ell(head, Vector3(0.105, 0, 0.0), Vector3(0.015, 0.03, 0.02), skin)
	_ell(head, Vector3(0, -0.015, -0.115), Vector3(0.016, 0.028, 0.02), skin)   # 鼻
	var hollow: bool = o.get("hollow_eyes", false)
	var veins := Mats.solid(Color(0.7, 0.05, 0.05), 0.5)
	for s in [-1.0, 1.0]:
		if hollow:
			_ell(head, Vector3(s * 0.04, 0.03, -0.1), Vector3(0.028, 0.03, 0.02), dark)
		elif wild:
			_ell(head, Vector3(s * 0.04, 0.03, -0.1), Vector3(0.024, 0.019, 0.013), Mats.solid(Color(0.92, 0.78, 0.74), 0.4))   # 充血的眼白
			_ell(head, Vector3(s * 0.04, 0.03, -0.108), Vector3(0.006, 0.006, 0.004), dark)                                  # 针尖般的瞳孔
			for k in 3:
				WB.box(head, Vector3(s * (0.03 + k * 0.007), 0.03 + (k - 1) * 0.007, -0.1125), Vector3(0.012, 0.0014, 0.001), veins, false).rotation.z = (k - 1) * 0.5
			_ell(head, Vector3(s * 0.04, 0.003, -0.097), Vector3(0.027, 0.011, 0.012), Mats.solid(Color(0.32, 0.2, 0.3), 0.8))   # 眼袋
			_ell(head, Vector3(s * 0.068, -0.04, -0.085), Vector3(0.028, 0.042, 0.03), Mats.solid(Color(0.58, 0.46, 0.4), 0.9))  # 凹陷的脸颊
		else:
			_ell(head, Vector3(s * 0.04, 0.03, -0.1), Vector3(0.018, 0.012, 0.01), white)
			_ell(head, Vector3(s * 0.04, 0.03, -0.108), Vector3(0.008, 0.008, 0.005), dark)
		var brow := WB.box(head, Vector3(s * 0.045, 0.062, -0.105), Vector3(0.045, 0.01, 0.012), dark, false)
		brow.rotation.z = -s * (0.45 if wild and s > 0 else 0.15)
	if wild:
		# 胡茬、咧开的嘴和牙
		_ell(head, Vector3(0, -0.06, -0.012), Vector3(0.108, 0.07, 0.108), Mats.solid(Color(0.5, 0.45, 0.42), 1.0))
		_ell(head, Vector3(0, -0.062, -0.104), Vector3(0.034, 0.016, 0.01), Mats.solid(Color(0.1, 0.02, 0.02), 0.5))
		for k in 7:
			WB.box(head, Vector3(-0.027 + k * 0.009, -0.052, -0.11), Vector3(0.007, 0.01, 0.006), Mats.solid(Color(0.85, 0.8, 0.6), 0.4), false)
		for k in 6:
			WB.box(head, Vector3(-0.022 + k * 0.009, -0.07, -0.11), Vector3(0.007, 0.009, 0.006), Mats.solid(Color(0.8, 0.75, 0.55), 0.4), false)
	else:
		WB.box(head, Vector3(0, -0.055, -0.105), Vector3(0.05, 0.008, 0.01), Mats.solid(Color(0.35, 0.12, 0.12)), false)
	if o.get("glasses", false):
		for s in [-1.0, 1.0]:
			_ring(head, Vector3(s * 0.04, 0.03, -0.118), 0.026, 0.03, dark)
		WB.box(head, Vector3(0, 0.032, -0.118), Vector3(0.02, 0.005, 0.005), dark, false)
	if wild:
		var grey := Mats.solid(Color(0.6, 0.6, 0.58), 0.9)
		for sx in [-1.0, 1.0]:
			for k in 4:
				_ell(head, Vector3(sx * (0.1 - k * 0.003), 0.07 - k * 0.025, 0.03 + k * 0.004), Vector3(0.02, 0.02, 0.02), grey)
			for k in 3:
				var strand := _cap(head, Vector3(sx * 0.11, 0.09 + k * 0.02, 0.03), 0.003, 0.12, grey)
				strand.rotation = Vector3(0.3 * k, 0, sx * (0.9 + k * 0.4))
	var hair_c = o.get("hair", null)
	if hair_c != null:
		var hm: Material = Mats.solid(hair_c, 0.9)
		_ell(head, Vector3(0, 0.05, 0.02), Vector3(0.115, 0.1, 0.12), hm)
		if o.get("long_hair", false):
			_cap(head, Vector3(0, -0.12, 0.075), 0.085, 0.4, hm, Vector3(1.0, 1.0, 0.7))
	# 手臂:肩 → 肘 → 手
	var arms := {}
	for side in ["l", "r"]:
		var sx: float = -1.0 if side == "l" else 1.0
		var sh := Node3D.new()
		sh.position = Vector3(sx * 0.25, 0.52, 0)
		body.add_child(sh)
		_cap(sh, Vector3(0, -0.15, 0), 0.05, 0.32, coat)
		var el := Node3D.new()
		el.position = Vector3(0, -0.3, 0)
		sh.add_child(el)
		_cap(el, Vector3(0, -0.14, 0), 0.043, 0.3, coat)
		_ell(el, Vector3(0, -0.3, 0), Vector3(0.04, 0.055, 0.025), Mats.solid(Color(0.35, 0.65, 0.5), 0.3) if wild else skin)
		arms["arm_" + side] = sh
		arms["elbow_" + side] = el
	var out := {"root": root, "body": body, "head": head}
	out.merge(arms)
	return out

## 递归设置可见层(用于只在镜子里显示的模型)
static func set_layers(n: Node, layers: int) -> void:
	if n is VisualInstance3D:
		n.layers = layers
	for c in n.get_children():
		set_layers(c, layers)
