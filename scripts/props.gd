extends RefCounted
## 精细一点的道具:马桶(CSG 挖出真正的碗)、洗手台、水龙头、卷纸、地漏、头发团、蟑螂。

const HW = preload("res://scripts/handwriting.gd")
const Slots = preload("res://scripts/asset_slots.gd")
const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")

static func porcelain(dirty: float = 0.25) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.86 - dirty * 0.25, 0.86 - dirty * 0.2, 0.8 - dirty * 0.3)
	m.roughness = 0.14
	m.clearcoat_enabled = true
	m.clearcoat = 0.7
	m.clearcoat_roughness = 0.1
	return m

static func chrome() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.78, 0.8, 0.82)
	m.metallic = 1.0
	m.roughness = 0.22
	return m

static func _csg_sphere(parent: Node, pos: Vector3, radii: Vector3, mat: Material, op: int = 0) -> CSGSphere3D:
	var s := CSGSphere3D.new()
	s.radius = 1.0
	s.radial_segments = 22
	s.rings = 12
	s.position = pos
	s.scale = radii
	s.operation = op
	s.material = mat
	parent.add_child(s)
	return s

static func _csg_box(parent: Node, pos: Vector3, size: Vector3, mat: Material, op: int = 0) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.size = size
	b.position = pos
	b.operation = op
	b.material = mat
	parent.add_child(b)
	return b

static func _csg_cyl(parent: Node, pos: Vector3, r: float, h: float, mat: Material, op: int = 0) -> CSGCylinder3D:
	var c := CSGCylinder3D.new()
	c.radius = r
	c.height = h
	c.sides = 18
	c.position = pos
	c.operation = op
	c.material = mat
	parent.add_child(c)
	return c

static func _cyl(parent: Node, pos: Vector3, r: float, h: float, mat: Material, rot_deg: Vector3 = Vector3.ZERO) -> MeshInstance3D:
	var mi := WB.cyl(parent, pos, r, h, mat, false)
	mi.rotation_degrees = rot_deg
	return mi

static func _torus(parent: Node, pos: Vector3, inner: float, outer: float, mat: Material, sc: Vector3 = Vector3.ONE) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = inner
	tm.outer_radius = outer
	tm.rings = 24
	tm.ring_segments = 10
	mi.mesh = tm
	mi.position = pos
	mi.scale = sc
	mi.material_override = mat
	parent.add_child(mi)
	return mi

## 马桶。本地坐标:背对 +Z(靠墙),开口朝 -Z。高度约 0.42 的碗沿。
static func toilet(parent: Node, pos: Vector3, yaw_deg: float, lid_up: bool, water_color: Color) -> Node3D:
	var slot := Slots.prop("toilet", parent, pos, yaw_deg)
	if slot != null:
		return slot
	var t := Node3D.new()
	t.position = pos
	t.rotation_degrees.y = yaw_deg
	parent.add_child(t)
	var pm := porcelain(0.3)
	var ch := chrome()
	# 碗:椭球外壳 - 内腔 - 削平上沿
	var bowl := CSGCombiner3D.new()
	bowl.use_collision = true
	bowl.collision_layer = 1
	bowl.collision_mask = 0
	t.add_child(bowl)
	_csg_sphere(bowl, Vector3(0, 0.28, -0.04), Vector3(0.2, 0.17, 0.33), pm)
	_csg_cyl(bowl, Vector3(0, 0.12, 0.1), 0.14, 0.24, pm)
	_csg_box(bowl, Vector3(0, 0.62, 0), Vector3(1.0, 0.4, 1.2), pm, CSGShape3D.OPERATION_SUBTRACTION)
	_csg_sphere(bowl, Vector3(0, 0.31, -0.04), Vector3(0.155, 0.15, 0.285), pm, CSGShape3D.OPERATION_SUBTRACTION)
	# 积水与水渍环
	var wm := StandardMaterial3D.new()
	wm.albedo_color = water_color
	wm.roughness = 0.05
	wm.metallic = 0.3
	WB.cyl(t, Vector3(0, 0.2, -0.02), 0.1, 0.012, wm, false)
	var ring_m := Mats.solid(Color(0.35, 0.26, 0.12), 0.6)
	_torus(t, Vector3(0, 0.375, -0.04), 0.14, 0.152, ring_m, Vector3(1.0, 0.25, 1.75))
	# 座圈与盖
	var seat_m := Mats.solid(Color(0.88, 0.87, 0.82), 0.3)
	_torus(t, Vector3(0, 0.43, -0.04), 0.125, 0.2, seat_m, Vector3(0.98, 0.45, 1.5))
	var hinge := Node3D.new()
	hinge.position = Vector3(0, 0.44, 0.22)
	t.add_child(hinge)
	hinge.rotation_degrees.x = 82.0 if lid_up else 0.0
	var lid := MeshInstance3D.new()
	var lm := SphereMesh.new()
	lm.radius = 1.0
	lm.height = 2.0
	lid.mesh = lm
	lid.scale = Vector3(0.2, 0.014, 0.29)
	lid.position = Vector3(0, 0.01, -0.3)
	lid.material_override = seat_m
	hinge.add_child(lid)
	# 水箱
	WB.box(t, Vector3(0, 0.74, 0.3), Vector3(0.44, 0.4, 0.17), pm, false)
	WB.box(t, Vector3(0, 0.955, 0.3), Vector3(0.47, 0.035, 0.2), pm, false)
	WB.cyl(t, Vector3(0.1, 0.985, 0.3), 0.032, 0.02, ch, false)
	WB.cyl(t, Vector3(-0.1, 0.985, 0.3), 0.022, 0.02, ch, false)
	# 进水管、角阀、地脚螺栓帽
	_cyl(t, Vector3(0.17, 0.2, 0.37), 0.011, 0.4, ch)
	_cyl(t, Vector3(0.14, 0.12, 0.37), 0.014, 0.08, ch, Vector3(0, 0, 90))
	for sx in [-0.12, 0.12]:
		WB.cyl(t, Vector3(sx, 0.02, 0.0), 0.022, 0.03, pm, false)
	return t

## 洗手台。本地:背贴墙(z=0),向 +Z 伸出。台面上沿约 0.945。
static func sink(parent: Node, pos: Vector3) -> Node3D:
	var slot := Slots.prop("sink", parent, pos, 0.0)
	if slot != null:
		return slot
	var s := Node3D.new()
	s.position = pos
	parent.add_child(s)
	var pm := porcelain(0.35)
	var ch := chrome()
	var basin := CSGCombiner3D.new()
	basin.use_collision = true
	basin.collision_layer = 1
	basin.collision_mask = 0
	s.add_child(basin)
	_csg_box(basin, Vector3(0, 0.865, 0.23), Vector3(0.6, 0.16, 0.46), pm)
	_csg_box(basin, Vector3(0, 1.0, 0.03), Vector3(0.6, 0.16, 0.05), pm)       # 挡水沿
	_csg_sphere(basin, Vector3(0, 0.98, 0.26), Vector3(0.245, 0.14, 0.19), pm, CSGShape3D.OPERATION_SUBTRACTION)
	_csg_cyl(basin, Vector3(0, 0.82, 0.26), 0.022, 0.1, pm, CSGShape3D.OPERATION_SUBTRACTION)
	# 水龙头
	WB.cyl(s, Vector3(0, 0.96, 0.075), 0.032, 0.03, ch, false)
	WB.cyl(s, Vector3(0, 1.03, 0.075), 0.016, 0.12, ch, false)
	_cyl(s, Vector3(0, 1.09, 0.14), 0.014, 0.14, ch, Vector3(90, 0, 0))
	for sx in [-0.1, 0.1]:
		WB.cyl(s, Vector3(sx, 0.97, 0.075), 0.014, 0.04, ch, false)
		_cyl(s, Vector3(sx, 1.0, 0.075), 0.007, 0.07, ch, Vector3(0, 0, 90))
	# 下水:弯管 + 墙管
	var pipe := Mats.solid(Color(0.5, 0.5, 0.48), 0.4, 0.8)
	_cyl(s, Vector3(0, 0.7, 0.26), 0.017, 0.2, pipe)
	_torus(s, Vector3(0, 0.56, 0.2), 0.012, 0.045, pipe, Vector3(1, 1, 1)).rotation_degrees = Vector3(0, 90, 0)
	_cyl(s, Vector3(0, 0.52, 0.12), 0.017, 0.22, pipe, Vector3(90, 0, 0))
	for sx in [-0.28, 0.28]:
		WB.box(s, Vector3(sx, 0.78, 0.1), Vector3(0.03, 0.03, 0.2), pipe, false)   # 支架
	return s

## 一团湿头发:核心 + 许多细发丝。radius 为团的大致半径。
static func hair_clump(parent: Node, pos: Vector3, radius: float, strands: int, color: Color) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	var hm := StandardMaterial3D.new()
	hm.albedo_color = color
	hm.roughness = 0.35
	hm.metallic = 0.15
	var core := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	core.mesh = sm
	core.scale = Vector3(radius, radius * 0.55, radius * 0.9)
	core.material_override = hm
	n.add_child(core)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 100 + pos.z * 37)
	for i in strands:
		var cm := CapsuleMesh.new()
		cm.radius = 0.004
		cm.height = rng.randf_range(0.12, 0.3)
		cm.radial_segments = 4
		cm.rings = 1
		var mi := MeshInstance3D.new()
		mi.mesh = cm
		mi.material_override = hm
		mi.position = Vector3(rng.randf_range(-1, 1), rng.randf_range(-0.2, 0.6), rng.randf_range(-1, 1)) * radius * 0.8
		mi.rotation = Vector3(rng.randf_range(-1.8, 1.8), rng.randf_range(0, TAU), rng.randf_range(-1.8, 1.8))
		n.add_child(mi)
	return n

## 卷纸架 + 卷纸。axis 沿 Z。
static func toilet_paper(parent: Node, pos: Vector3) -> void:
	var ch := chrome()
	WB.box(parent, pos + Vector3(0.01, 0, 0), Vector3(0.03, 0.14, 0.18), ch, false)
	var roll := _cyl(parent, pos + Vector3(-0.05, -0.01, 0), 0.06, 0.1, Mats.solid(Color(0.9, 0.88, 0.8), 0.95), Vector3(90, 0, 0))
	roll.scale = Vector3(1, 1, 1)
	WB.box(parent, pos + Vector3(-0.1, -0.15, 0.0), Vector3(0.002, 0.28, 0.095), Mats.solid(Color(0.9, 0.88, 0.8), 0.95), false)

## 地漏
static func floor_drain(parent: Node, pos: Vector3) -> void:
	var ch := chrome()
	var dark := Mats.solid(Color(0.02, 0.02, 0.02))
	WB.cyl(parent, pos + Vector3(0, 0.004, 0), 0.13, 0.008, dark, false)
	_torus(parent, pos + Vector3(0, 0.008, 0), 0.115, 0.14, ch, Vector3(1, 0.3, 1))
	for i in 5:
		WB.box(parent, pos + Vector3(-0.08 + i * 0.04, 0.012, 0), Vector3(0.012, 0.004, 0.2), ch, false)

## 垃圾桶 + 溢出的头发和纸
static func trash_can(parent: Node, pos: Vector3) -> void:
	var metal := Mats.solid(Color(0.35, 0.37, 0.38), 0.45, 0.7)
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.16
	cm.height = 0.55
	body.mesh = cm
	body.position = pos + Vector3(0, 0.275, 0)
	body.material_override = metal
	parent.add_child(body)
	_torus(parent, pos + Vector3(0, 0.55, 0), 0.19, 0.21, metal, Vector3(1, 0.4, 1)).rotation_degrees = Vector3.ZERO
	hair_clump(parent, pos + Vector3(0, 0.6, 0), 0.17, 40, Color(0.07, 0.05, 0.04))
	var paper := Mats.solid(Color(0.85, 0.82, 0.7))
	for i in 4:
		var p := WB.box(parent, pos + Vector3(randf_range(-0.1, 0.1), 0.62 + i * 0.02, randf_range(-0.1, 0.1)), Vector3(0.12, 0.004, 0.1), paper, false)
		p.rotation = Vector3(randf_range(-0.5, 0.5), randf() * TAU, randf_range(-0.5, 0.5))

## 蟑螂(朝 +Z 爬)。返回根节点;触角节点名为 AntL / AntR 供动画使用。
static func roach(parent: Node) -> Node3D:
	var r := Node3D.new()
	parent.add_child(r)
	var shell := StandardMaterial3D.new()
	shell.albedo_color = Color(0.2, 0.085, 0.03)
	shell.roughness = 0.2
	shell.clearcoat_enabled = true
	shell.clearcoat = 0.8
	var dark := Mats.solid(Color(0.08, 0.04, 0.02), 0.5)
	var body := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = 1.0
	sm.height = 2.0
	sm.radial_segments = 10
	sm.rings = 6
	body.mesh = sm
	body.scale = Vector3(0.028, 0.011, 0.05)
	body.position = Vector3(0, 0.012, -0.005)
	body.material_override = shell
	r.add_child(body)
	var shield := MeshInstance3D.new()
	shield.mesh = sm
	shield.scale = Vector3(0.026, 0.009, 0.02)
	shield.position = Vector3(0, 0.017, 0.04)
	shield.material_override = Mats.solid(Color(0.32, 0.15, 0.05), 0.3)
	r.add_child(shield)
	var head := MeshInstance3D.new()
	head.mesh = sm
	head.scale = Vector3(0.011, 0.008, 0.011)
	head.position = Vector3(0, 0.012, 0.062)
	head.material_override = dark
	r.add_child(head)
	for sx in [-1.0, 1.0]:
		var piv := Node3D.new()
		piv.name = "AntL" if sx < 0 else "AntR"
		piv.position = Vector3(sx * 0.006, 0.014, 0.068)
		r.add_child(piv)
		var ant := WB.cyl(piv, Vector3(0, 0, 0.04), 0.0012, 0.09, dark, false)
		ant.rotation_degrees = Vector3(90, 0, sx * 25.0)
		for i in 3:
			var leg_z := 0.03 - i * 0.025
			var leg := WB.cyl(r, Vector3(sx * 0.03, 0.007, leg_z), 0.0015, 0.05, dark, false)
			leg.rotation_degrees = Vector3(0, 0, sx * 62.0)
	return r

static func glass_mat(alpha: float = 0.28) -> StandardMaterial3D:
	var g := StandardMaterial3D.new()
	g.albedo_color = Color(0.75, 0.9, 0.9, alpha)
	g.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	g.roughness = 0.05
	g.metallic = 0.1
	return g

## 试剂瓶:玻璃瓶身 + 发光液体 + 瓶颈 + 软木塞 + 标签
static func bottle(parent: Node, pos: Vector3, color: Color, h: float = 0.22, r: float = 0.05) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	WB.cyl(n, Vector3(0, h * 0.5, 0), r, h, glass_mat(), false)
	WB.cyl(n, Vector3(0, h * 0.3 + 0.004, 0), r * 0.84, h * 0.58, Mats.emissive(color, 0.9), false)
	WB.cyl(n, Vector3(0, h + 0.025, 0), r * 0.38, 0.05, glass_mat(0.35), false)
	WB.cyl(n, Vector3(0, h + 0.062, 0), r * 0.3, 0.03, Mats.solid(Color(0.45, 0.3, 0.15)), false)
	WB.cyl(n, Vector3(0, h * 0.45, 0), r * 1.03, h * 0.26, Mats.solid(Color(0.88, 0.85, 0.72), 0.9), false)
	return n

## 锥形烧瓶
static func flask(parent: Node, pos: Vector3, color: Color, s: float = 1.0) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	var body := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.02 * s
	cm.bottom_radius = 0.075 * s
	cm.height = 0.16 * s
	cm.radial_segments = 14
	body.mesh = cm
	body.position = Vector3(0, 0.08 * s, 0)
	body.material_override = glass_mat()
	n.add_child(body)
	var liq := MeshInstance3D.new()
	var lm := CylinderMesh.new()
	lm.top_radius = 0.045 * s
	lm.bottom_radius = 0.07 * s
	lm.height = 0.08 * s
	lm.radial_segments = 14
	liq.mesh = lm
	liq.position = Vector3(0, 0.045 * s, 0)
	liq.material_override = Mats.emissive(color, 1.0)
	n.add_child(liq)
	WB.cyl(n, Vector3(0, 0.2 * s, 0), 0.02 * s, 0.09 * s, glass_mat(0.35), false)
	return n

## 老式 CRT 显示器,屏幕朝本地 -Z。text 显示在屏幕上。
static func monitor(parent: Node, pos: Vector3, yaw_deg: float, screen_color: Color, text: String) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	var beige := Mats.solid(Color(0.72, 0.7, 0.6), 0.6)
	WB.box(n, Vector3(0, 0.03, 0.0), Vector3(0.24, 0.05, 0.22), beige, false)                  # 底座
	WB.box(n, Vector3(0, 0.27, 0.05), Vector3(0.52, 0.42, 0.34), beige, false)                 # 机身
	WB.box(n, Vector3(0, 0.27, -0.13), Vector3(0.52, 0.42, 0.05), beige, false)                # 前框
	WB.box(n, Vector3(0, 0.27, -0.16), Vector3(0.42, 0.32, 0.01), Mats.emissive(screen_color * 0.1, 1.0), false)   # 暗绿色屏幕
	var lb := WB.label3d(n, Vector3(0.17, 0.3, -0.168), text, screen_color, 0.0013, 180.0)
	lb.shaded = false
	lb.outline_size = 0
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	WB.box(n, Vector3(0.2, 0.08, -0.14), Vector3(0.025, 0.012, 0.01), Mats.emissive(Color(0.2, 1.0, 0.2), 2.0), false)   # 电源灯
	return n

static func office_chair(parent: Node, pos: Vector3, rot_deg: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees = rot_deg
	parent.add_child(n)
	var dark := Mats.solid(Color(0.08, 0.08, 0.1), 0.7)
	var metal := Mats.solid(Color(0.4, 0.4, 0.42), 0.4, 0.8)
	WB.box(n, Vector3(0, 0.5, 0), Vector3(0.46, 0.08, 0.46), dark, false)
	WB.box(n, Vector3(0, 0.86, 0.22), Vector3(0.42, 0.55, 0.07), dark, false)
	WB.cyl(n, Vector3(0, 0.3, 0), 0.025, 0.4, metal, false)
	for i in 5:
		var a := TAU * i / 5.0
		var leg := WB.box(n, Vector3(sin(a) * 0.15, 0.08, cos(a) * 0.15), Vector3(0.04, 0.03, 0.3), metal, false)
		leg.rotation.y = a
		WB.ball(n, Vector3(sin(a) * 0.29, 0.04, cos(a) * 0.29), 0.035, dark)
	return n

const DrawS = preload("res://scripts/draw.gd")
const CreepyFrame = preload("res://scripts/creepy_frame.gd")

## 挂画。yaw_deg:画面朝向(0 = 朝 +Z)。tilt:歪斜角度。
static func picture_frame(parent: Node, pos: Vector3, yaw_deg: float, size: Vector2, kind: String, tilt_deg: float = 0.0, scary: bool = false) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees = Vector3(0, yaw_deg, tilt_deg)
	parent.add_child(n)
	var wood := Mats.solid(Color(0.16, 0.1, 0.06), 0.6)
	WB.box(n, Vector3(0, 0, -0.012), Vector3(size.x + 0.1, size.y + 0.1, 0.04), wood, false)
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	var pm := StandardMaterial3D.new()
	pm.albedo_texture = DrawS.picture(kind, false)
	pm.roughness = 0.8          # 画布是哑光的;太光滑会被灯照成一片白
	pm.metallic_specular = 0.35
	pm.albedo_color = Color(0.66, 0.66, 0.66)    # 挂画都在壁灯光圈里,稍微压暗避免过曝
	q.material_override = pm
	q.position = Vector3(0, 0, 0.012)
	n.add_child(q)
	if scary:
		n.set_script(CreepyFrame)
		n.mat = pm
		n.calm = DrawS.picture(kind, false)
		n.creepy = DrawS.picture(kind, true)
		var d := CPUParticles3D.new()
		d.position = Vector3(0, -size.y * 0.5, 0.03)
		d.amount = 6
		d.lifetime = 1.4
		d.emitting = false
		d.direction = Vector3(0, -1, 0)
		d.spread = 8.0
		d.gravity = Vector3(0, -2.5, 0)
		d.initial_velocity_min = 0.0
		d.initial_velocity_max = 0.1
		var sm := SphereMesh.new()
		sm.radius = 0.008
		sm.height = 0.03
		d.mesh = sm
		d.material_override = Mats.solid(Color(0.45, 0.02, 0.02), 0.2)
		n.add_child(d)
		n.drip = d
	return n

## 长椅:木板座面 + 靠背 + 铁腿。本地 X 为长度方向,朝向 +Z 的那面是靠背前面。
static func bench(parent: Node, pos: Vector3, yaw_deg: float, length: float) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	var wood := Mats.get_mat("deskwood")
	var iron := Mats.solid(Color(0.1, 0.1, 0.11), 0.5, 0.6)
	for i in 3:
		WB.box(n, Vector3(0, 0.44, -0.16 + i * 0.16), Vector3(length, 0.035, 0.145), wood, false)
	for i in 2:
		WB.box(n, Vector3(0, 0.68 + i * 0.16, 0.26), Vector3(length, 0.14, 0.03), wood, false).rotation_degrees.x = -8.0
	for sx in [-length * 0.45, length * 0.45]:
		WB.box(n, Vector3(sx, 0.22, 0.0), Vector3(0.05, 0.44, 0.45), iron, false)
		WB.box(n, Vector3(sx, 0.62, 0.27), Vector3(0.05, 0.5, 0.05), iron, false)
	# 碰撞体(不可见)
	var col := WB.box(n, Vector3(0, 0.4, 0.05), Vector3(length, 0.8, 0.55), wood, true)
	col.visible = false
	return n

## 吊灯灯罩 + 吊线,灯泡在罩内
static func lamp_shade(parent: Node, pos: Vector3) -> void:
	var metal := Mats.solid(Color(0.14, 0.14, 0.13), 0.5, 0.6)
	WB.cyl(parent, pos + Vector3(0, 0.38, 0), 0.008, 0.5, Mats.solid(Color(0.02, 0.02, 0.02)), false)
	var sh := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.05
	cm.bottom_radius = 0.26
	cm.height = 0.2
	cm.radial_segments = 16
	sh.mesh = cm
	sh.position = pos + Vector3(0, 0.07, 0)
	sh.material_override = metal
	parent.add_child(sh)
	WB.ball(parent, pos + Vector3(0, -0.02, 0), 0.045, Mats.emissive(Color(1.0, 0.9, 0.6), 3.0))

## 枯萎的盆栽
static func dead_plant(parent: Node, pos: Vector3) -> void:
	var pot := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.14
	cm.height = 0.34
	pot.mesh = cm
	pot.position = pos + Vector3(0, 0.17, 0)
	pot.material_override = Mats.solid(Color(0.4, 0.2, 0.12), 0.9)
	parent.add_child(pot)
	WB.cyl(parent, pos + Vector3(0, 0.33, 0), 0.18, 0.04, Mats.solid(Color(0.1, 0.07, 0.04), 1.0), false)
	var stem := Mats.solid(Color(0.3, 0.22, 0.1), 0.9)
	var leaf := Mats.solid(Color(0.35, 0.28, 0.12), 0.9)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(pos.x * 31 + pos.z * 17)
	for i in 7:
		var a := rng.randf() * TAU
		var st := H_cap(parent, pos + Vector3(sin(a) * 0.05, 0.6, cos(a) * 0.05), 0.012, 0.5, stem)
		st.rotation = Vector3(sin(a) * 0.5, 0, -cos(a) * 0.5)
		var lf := WB.box(parent, pos + Vector3(sin(a) * 0.2, 0.78 + rng.randf() * 0.1, cos(a) * 0.2), Vector3(0.1, 0.01, 0.06), leaf, false)
		lf.rotation = Vector3(rng.randf_range(-0.8, 0.8), a, rng.randf_range(-0.6, 0.6))

static func H_cap(parent: Node, pos: Vector3, r: float, h: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CapsuleMesh.new()
	cm.radius = r
	cm.height = maxf(h, r * 2.0)
	cm.radial_segments = 6
	cm.rings = 2
	mi.mesh = cm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

## 接待台:台面、嵌板、铃、电话、登记簿、台灯,背后是信格墙与时钟。pos 为台面中心(地面高度)。
static func reception(parent: Node, pos: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = pos
	parent.add_child(n)
	var wood := Mats.get_mat("deskwood")
	var dark := Mats.solid(Color(0.07, 0.045, 0.03), 0.6)
	var brass := Mats.solid(Color(0.75, 0.6, 0.25), 0.3, 0.9)
	WB.box(n, Vector3(0, 0.5, 0), Vector3(2.5, 1.0, 0.8), wood, true)
	for i in 4:
		WB.box(n, Vector3(-0.9 + i * 0.6, 0.5, -0.405), Vector3(0.48, 0.7, 0.02), dark, false)     # 正面嵌板
	WB.box(n, Vector3(0, 1.02, 0), Vector3(2.7, 0.05, 1.0), Mats.solid(Color(0.1, 0.07, 0.05), 0.35), false)   # 台面
	WB.box(n, Vector3(0, 1.046, 0.05), Vector3(1.1, 0.004, 0.6), Mats.solid(Color(0.08, 0.2, 0.12), 0.9), false)  # 绿色桌垫
	# 铃
	WB.cyl(n, Vector3(-0.8, 1.06, -0.2), 0.07, 0.025, brass, false)
	var dome := WB.ball(n, Vector3(-0.8, 1.08, -0.2), 0.055, brass)
	dome.scale = Vector3(1, 0.6, 1)
	# 电话
	var black := Mats.solid(Color(0.04, 0.04, 0.04), 0.4)
	WB.box(n, Vector3(0.8, 1.09, -0.1), Vector3(0.22, 0.08, 0.2), black, false)
	var hs := WB.box(n, Vector3(0.8, 1.15, -0.1), Vector3(0.22, 0.04, 0.05), black, false)
	hs.rotation_degrees.z = 4.0
	# 登记簿
	WB.box(n, Vector3(0.1, 1.056, 0.0), Vector3(0.4, 0.02, 0.28), Mats.solid(Color(0.8, 0.78, 0.65), 0.9), false)
	WB.box(n, Vector3(0.1, 1.052, 0.0), Vector3(0.44, 0.012, 0.3), Mats.solid(Color(0.3, 0.05, 0.05), 0.8), false)
	# 台灯
	WB.cyl(n, Vector3(-0.4, 1.09, 0.3), 0.07, 0.03, brass, false)
	WB.cyl(n, Vector3(-0.4, 1.25, 0.3), 0.012, 0.3, brass, false)
	var shade := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.04
	cm.bottom_radius = 0.12
	cm.height = 0.14
	shade.mesh = cm
	shade.position = Vector3(-0.4, 1.4, 0.3)
	shade.material_override = Mats.emissive(Color(0.2, 0.55, 0.3), 0.9)
	n.add_child(shade)
	# 台后:信格墙 + 时钟(停在 3:00)
	var back := Node3D.new()
	back.position = Vector3(0, 0, 0.95)      # 贴着大厅东墙(原来 3.2 在墙外,看不见)
	n.add_child(back)
	for r in 4:
		for c in 6:
			WB.box(back, Vector3(-1.0 + c * 0.4, 1.0 + r * 0.32, 0.0), Vector3(0.36, 0.28, 0.2), dark, false)
			if (r + c) % 3 != 0:
				WB.box(back, Vector3(-1.0 + c * 0.4, 1.0 + r * 0.32, -0.08), Vector3(0.28, 0.2, 0.02), Mats.solid(Color(0.8, 0.77, 0.6), 0.9), false).rotation.z = ((r * c) % 5 - 2) * 0.05
	WB.cyl(back, Vector3(0, 2.55, -0.05), 0.18, 0.04, Mats.solid(Color(0.85, 0.82, 0.7), 0.5), false).rotation_degrees.x = 90.0
	WB.box(back, Vector3(0, 2.55, -0.08), Vector3(0.015, 0.14, 0.01), black, false)
	WB.box(back, Vector3(0.06, 2.55, -0.08), Vector3(0.1, 0.015, 0.01), black, false)
	# 转椅
	office_chair(n, Vector3(0.3, 0.0, 1.5), Vector3(0, 160, 0))
	return n

static func crate(parent: Node, pos: Vector3, yaw_deg: float) -> void:
	var wood := Mats.get_mat("wood")
	var c := WB.box(parent, pos + Vector3(0, 0.3, 0), Vector3(0.6, 0.6, 0.6), wood, true)
	c.rotation_degrees.y = yaw_deg
	for sy in [-0.25, 0.25]:
		WB.box(c, Vector3(0, sy, 0), Vector3(0.64, 0.05, 0.64), Mats.solid(Color(0.15, 0.1, 0.06), 0.8), false)


static var _stain_tex: ImageTexture = null

## 有机边缘的半透明污渍贴图(径向渐隐 + 噪声)
static func stain_texture() -> ImageTexture:
	if _stain_tex != null:
		return _stain_tex
	var n := FastNoiseLite.new()
	n.frequency = 0.07
	n.seed = 5
	var noise: Image = n.get_seamless_image(64, 64)
	var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
	for y in 64:
		for x in 64:
			var d := Vector2(x - 31.5, y - 31.5).length() / 32.0
			var nv: float = noise.get_pixel(x, y).r
			var a := clampf((1.0 - d) * 1.6 * (0.4 + nv * 1.1) - 0.25, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a))
	_stain_tex = ImageTexture.create_from_image(img)
	return _stain_tex

## 贴在墙/天花板上的污渍。yaw_deg 朝向(0 = 朝 +Z);facing_down 用于天花板。
static func stain(parent: Node, pos: Vector3, size: Vector2, color: Color, yaw_deg: float = 0.0, facing_down: bool = false) -> MeshInstance3D:
	var q := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = size
	q.mesh = qm
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.albedo_texture = stain_texture()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.roughness = 0.9
	q.material_override = m
	q.position = pos
	q.rotation_degrees = Vector3(90.0 if facing_down else 0.0, yaw_deg, 0)
	parent.add_child(q)
	return q

## 水龙头滴水:一小串水滴
static func drip(parent: Node, pos: Vector3) -> void:
	var p := CPUParticles3D.new()
	p.position = pos
	p.amount = 3
	p.lifetime = 0.9
	p.direction = Vector3(0, -1, 0)
	p.spread = 0.0
	p.gravity = Vector3(0, -6.0, 0)
	p.initial_velocity_min = 0.0
	p.initial_velocity_max = 0.0
	var qm := SphereMesh.new()
	qm.radius = 0.008
	qm.height = 0.02
	p.mesh = qm
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.6, 0.75, 0.8, 0.8)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.roughness = 0.05
	p.material_override = dm
	parent.add_child(p)

## 墙面设备:皂液器 / 擦手纸盒 / 烘手机
static func soap_dispenser(parent: Node, pos: Vector3) -> void:
	WB.box(parent, pos, Vector3(0.09, 0.17, 0.1), Mats.solid(Color(0.8, 0.8, 0.76), 0.3), false)
	WB.cyl(parent, pos + Vector3(0, -0.1, 0.06), 0.012, 0.05, Mats.solid(Color(0.7, 0.7, 0.72), 0.3, 0.6), false).rotation_degrees.x = 90.0
	WB.box(parent, pos + Vector3(0, 0.02, 0.052), Vector3(0.06, 0.07, 0.004), Mats.solid(Color(0.4, 0.55, 0.3), 0.9), false)

static func towel_dispenser(parent: Node, pos: Vector3) -> void:
	WB.box(parent, pos, Vector3(0.32, 0.42, 0.16), Mats.solid(Color(0.55, 0.57, 0.58), 0.4, 0.5), false)
	WB.box(parent, pos + Vector3(0, -0.2, 0.05), Vector3(0.26, 0.03, 0.1), Mats.solid(Color(0.88, 0.86, 0.78), 0.9), false)

static func hand_dryer(parent: Node, pos: Vector3) -> void:
	WB.box(parent, pos, Vector3(0.28, 0.24, 0.2), Mats.solid(Color(0.85, 0.85, 0.82), 0.3, 0.3), false)
	WB.cyl(parent, pos + Vector3(0, -0.16, 0.02), 0.035, 0.1, Mats.solid(Color(0.7, 0.7, 0.7), 0.4, 0.6), false)

## 拖把桶 + 拖把
static func mop_bucket(parent: Node, pos: Vector3) -> void:
	var yellow := Mats.solid(Color(0.8, 0.65, 0.1), 0.5)
	var b := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.2
	cm.bottom_radius = 0.15
	cm.height = 0.34
	b.mesh = cm
	b.position = pos + Vector3(0, 0.17, 0)
	b.material_override = yellow
	parent.add_child(b)
	WB.cyl(parent, pos + Vector3(0, 0.335, 0), 0.18, 0.01, Mats.solid(Color(0.15, 0.13, 0.08), 0.1, 0.3), false)
	var handle := WB.cyl(parent, pos + Vector3(0.2, 0.65, -0.1), 0.014, 1.3, Mats.solid(Color(0.5, 0.35, 0.2), 0.7), false)
	handle.rotation_degrees.z = -14.0
	var hair := Mats.solid(Color(0.75, 0.74, 0.68), 1.0)
	for i in 14:
		var st := WB.cyl(parent, pos + Vector3(0.0 + randf_range(-0.05, 0.05), 0.04, -0.1 + randf_range(-0.04, 0.04)), 0.005, 0.18, hair, false)
		st.rotation_degrees = Vector3(randf_range(-25, 25), 0, randf_range(-25, 25))

## 墙上的白板(带化学式和潦草的字)
static func whiteboard(parent: Node, pos: Vector3, yaw_deg: float, text: String) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	WB.box(n, Vector3(0, 0, 0), Vector3(1.5, 0.95, 0.03), Mats.solid(Color(0.7, 0.72, 0.74), 0.4, 0.6), false)
	WB.box(n, Vector3(0, 0, 0.017), Vector3(1.42, 0.87, 0.006), Mats.solid(Color(0.92, 0.93, 0.92), 0.25), false)
	WB.box(n, Vector3(0, -0.5, 0.05), Vector3(1.5, 0.03, 0.08), Mats.solid(Color(0.6, 0.62, 0.64), 0.4, 0.6), false)
	# 马克笔手写:蓝色公式,红色潦草的结论,略微歪斜
	var lb := HW.label(n, Vector3(-0.64, 0.39, 0.022), text, Color(0.08, 0.16, 0.55), 0.0018, 0.0, 1.5)
	lb.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	lb.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	HW.label(n, Vector3(0.05, -0.34, 0.022), "头发 = 财富 = Sarah ??", Color(0.7, 0.06, 0.06), 0.0014, 0.0, -3.0)
	stain(n, Vector3(0.45, 0.2, 0.02), Vector2(0.4, 0.3), Color(0.5, 0.45, 0.3), 0.0)

## 软木板:图钉、纸条、红线、一张被划掉的照片
static func corkboard(parent: Node, pos: Vector3, yaw_deg: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	WB.box(n, Vector3(0, 0, 0), Vector3(1.2, 0.85, 0.03), Mats.solid(Color(0.14, 0.09, 0.05), 0.6), false)
	WB.box(n, Vector3(0, 0, 0.018), Vector3(1.12, 0.77, 0.008), Mats.solid(Color(0.55, 0.38, 0.22), 1.0), false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var pins: Array = []
	for i in 7:
		var pos2 := Vector3(rng.randf_range(-0.45, 0.45), rng.randf_range(-0.28, 0.28), 0.03)
		var pp := WB.box(n, pos2, Vector3(0.18, 0.13, 0.004), Mats.solid(Color(0.88, 0.85, 0.72), 0.9), false)
		pp.rotation.z = rng.randf_range(-0.3, 0.3)
		WB.ball(n, pos2 + Vector3(0, 0.05, 0.01), 0.012, Mats.solid(Color(0.8, 0.1, 0.1), 0.3))
		pins.append(pos2 + Vector3(0, 0.05, 0.02))
	for i in pins.size() - 1:
		var a: Vector3 = pins[i]
		var b: Vector3 = pins[i + 1]
		var mid := (a + b) * 0.5
		var seg := WB.box(n, mid, Vector3(a.distance_to(b), 0.003, 0.002), Mats.solid(Color(0.75, 0.05, 0.05), 0.6), false)
		seg.rotation.z = atan2(b.y - a.y, b.x - a.x)
	var ph := picture_frame(n, Vector3(0.1, -0.02, 0.05), 0.0, Vector2(0.2, 0.26), "portrait", 6.0)
	var x1 := WB.box(n, Vector3(0.1, -0.02, 0.095), Vector3(0.32, 0.012, 0.004), Mats.solid(Color(0.8, 0.05, 0.05)), false)
	x1.rotation.z = 0.7

## 百叶窗(窗外是夜色)
static func window_blinds(parent: Node, pos: Vector3, yaw_deg: float, size: Vector2) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	WB.box(n, Vector3(0, 0, 0), Vector3(size.x + 0.12, size.y + 0.12, 0.05), Mats.solid(Color(0.12, 0.1, 0.08), 0.6), false)
	WB.box(n, Vector3(0, 0, 0.012), Vector3(size.x, size.y, 0.01), Mats.emissive(Color(0.1, 0.16, 0.32), 0.7), false)
	var slat := Mats.solid(Color(0.55, 0.52, 0.44), 0.7)
	var cnt := 14
	for i in cnt:
		var y := size.y * 0.5 - (i + 0.5) * size.y / cnt
		var sl := WB.box(n, Vector3(0, y, 0.04), Vector3(size.x - 0.02, 0.028, 0.006), slat, false)
		sl.rotation_degrees.x = 38.0 + (14.0 if i == 5 else 0.0)
	WB.box(n, Vector3(0.18, -size.y * 0.15, 0.06), Vector3(0.12, 0.05, 0.005), slat, false).rotation_degrees.z = 20.0   # 折断的一片

## 挂钟。hour/minute 为指针所指时间。
static func wall_clock(parent: Node, pos: Vector3, yaw_deg: float, hour: float, minute: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	WB.cyl(n, Vector3.ZERO, 0.2, 0.05, Mats.solid(Color(0.1, 0.08, 0.06), 0.6), false).rotation_degrees.x = 90.0
	WB.cyl(n, Vector3(0, 0, 0.02), 0.175, 0.012, Mats.solid(Color(0.9, 0.87, 0.75), 0.6), false).rotation_degrees.x = 90.0
	var dark := Mats.solid(Color(0.05, 0.05, 0.05))
	var ha := -(hour + minute / 60.0) * 30.0
	var ma := -minute * 6.0
	var hh := Node3D.new()
	hh.position = Vector3(0, 0, 0.032)
	hh.rotation_degrees.z = ha
	n.add_child(hh)
	WB.box(hh, Vector3(0, 0.05, 0), Vector3(0.015, 0.11, 0.006), dark, false)
	var mh := Node3D.new()
	mh.position = Vector3(0, 0, 0.038)
	mh.rotation_degrees.z = ma
	n.add_child(mh)
	WB.box(mh, Vector3(0, 0.075, 0), Vector3(0.01, 0.15, 0.005), dark, false)

## 书柜:一格格彩色的书,有几本歪倒的
static func bookcase(parent: Node, pos: Vector3, yaw_deg: float, width: float, height: float) -> void:
	var n := Node3D.new()
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	var wood := Mats.get_mat("deskwood")
	WB.box(n, Vector3(0, height * 0.5, -0.17), Vector3(width, height, 0.03), wood, false)
	WB.box(n, Vector3(-width * 0.5, height * 0.5, 0), Vector3(0.04, height, 0.36), wood, false)
	WB.box(n, Vector3(width * 0.5, height * 0.5, 0), Vector3(0.04, height, 0.36), wood, false)
	var rng := RandomNumberGenerator.new()
	rng.seed = 21
	var shelves := 5
	for r in shelves + 1:
		var y := 0.05 + r * (height - 0.1) / shelves
		WB.box(n, Vector3(0, y, 0), Vector3(width, 0.035, 0.36), wood, false)
		if r == shelves:
			break
		var x := -width * 0.5 + 0.06
		while x < width * 0.5 - 0.08:
			var bw := rng.randf_range(0.025, 0.06)
			var bh := rng.randf_range(0.18, 0.3)
			var col := Color.from_hsv(rng.randf(), rng.randf_range(0.3, 0.6), rng.randf_range(0.25, 0.55))
			var bk := WB.box(n, Vector3(x + bw * 0.5, y + 0.0175 + bh * 0.5, 0.0), Vector3(bw, bh, 0.24), Mats.solid(col, 0.8), false)
			if rng.randf() < 0.07:
				bk.rotation.z = 0.35
			x += bw + 0.004
			if rng.randf() < 0.08:
				x += rng.randf_range(0.1, 0.2)

## 地毯
static func rug(parent: Node, pos: Vector3, size: Vector2, color: Color) -> void:
	var m := Mats.get_mat("carpet").duplicate()
	m.albedo_color = color
	WB.box(parent, pos + Vector3(0, 0.006, 0), Vector3(size.x, 0.012, size.y), m, false)
	WB.box(parent, pos + Vector3(0, 0.0125, 0), Vector3(size.x - 0.25, 0.002, size.y - 0.25), Mats.solid(color * 0.55, 1.0), false)
