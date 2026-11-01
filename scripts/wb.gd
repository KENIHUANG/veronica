extends RefCounted
## 世界搭建小工具:方块、圆柱、灯、门、互动区。

const Mats = preload("res://scripts/mats.gd")
const Inter = preload("res://scripts/interactable.gd")
const DoorS = preload("res://scripts/door.gd")
const LampS = preload("res://scripts/flicker_light.gd")

static func box(parent: Node, pos: Vector3, size: Vector3, mat: Material, solid: bool = true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = size
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi

## 用两个对角点定义的盒子
static func slab(parent: Node, a: Vector3, b: Vector3, mat: Material, solid: bool = true) -> MeshInstance3D:
	var lo := Vector3(minf(a.x, b.x), minf(a.y, b.y), minf(a.z, b.z))
	var hi := Vector3(maxf(a.x, b.x), maxf(a.y, b.y), maxf(a.z, b.z))
	return box(parent, (lo + hi) * 0.5, hi - lo, mat, solid)

static func cyl(parent: Node, pos: Vector3, radius: float, height: float, mat: Material, solid: bool = false) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = radius
	cm.bottom_radius = radius
	cm.height = height
	cm.radial_segments = 12
	mi.mesh = cm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	if solid:
		var sb := StaticBody3D.new()
		sb.collision_layer = 1
		sb.collision_mask = 0
		var cs := CollisionShape3D.new()
		var sh := CylinderShape3D.new()
		sh.radius = radius
		sh.height = height
		cs.shape = sh
		sb.add_child(cs)
		mi.add_child(sb)
	return mi

static func ball(parent: Node, pos: Vector3, radius: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = radius
	sm.height = radius * 2.0
	sm.radial_segments = 14
	sm.rings = 8
	mi.mesh = sm
	mi.position = pos
	mi.material_override = mat
	parent.add_child(mi)
	return mi

## 印刷体文字(标牌、海报)。默认受灯光影响,不再"悬浮发光";glow=true 用于灯箱(EXIT)。
static func label3d(parent: Node, pos: Vector3, text: String, color: Color, size: float = 0.012, yaw_deg: float = 0.0, glow: bool = false) -> Label3D:
	var l := Label3D.new()
	l.text = L.t(text)
	l.set_meta("zh", text)
	l.add_to_group("loc3d")
	l.modulate = color
	l.pixel_size = size
	l.font_size = 48
	l.outline_size = 4 if glow else 0
	l.position = pos
	l.rotation_degrees.y = yaw_deg
	l.shaded = not glow
	l.double_sided = false
	l.alpha_cut = Label3D.ALPHA_CUT_DISCARD
	parent.add_child(l)
	return l

## 天花板灯:有可见的灯具(自发光)和会闪的 OmniLight
static func lamp(parent: Node, pos: Vector3, color: Color, energy: float, flicker: float = 0.12, cutout: float = 0.0, fixture_size: Vector3 = Vector3(0.9, 0.06, 0.22)) -> OmniLight3D:
	var em := Mats.emissive(color, 2.2)
	box(parent, pos + Vector3(0, 0.1, 0), fixture_size, em, false)
	var l = LampS.new()
	l.position = pos - Vector3(0, 0.15, 0)
	l.light_color = color
	l.base_energy = energy
	l.light_energy = energy
	l.omni_range = 9.0
	l.omni_attenuation = 1.1
	l.flicker = flicker
	l.cutout_chance = cutout
	l.emissive_mat = em
	l.emissive_base = 2.2
	parent.add_child(l)
	return l

static func inter(parent: Node, pos: Vector3, size: Vector3, prompt: String, action: Callable = Callable()) -> Area3D:
	var a = Inter.new()
	a.collision_layer = 2
	a.collision_mask = 0
	a.monitoring = false
	a.position = pos
	a.prompt = prompt
	a.action = action
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	a.add_child(cs)
	parent.add_child(a)
	return a

static func door(parent: Node, hinge: Vector3, closed_yaw: float, open_yaw: float, width: float, height: float, mat: Material) -> Node3D:
	var d = DoorS.new()
	d.position = hinge
	d.closed_yaw = closed_yaw
	d.open_yaw = open_yaw
	d.rotation_degrees.y = closed_yaw
	parent.add_child(d)
	d.setup(width, height, mat)
	return d

static func trigger(parent: Node, pos: Vector3, size: Vector3, on_enter: Callable) -> Area3D:
	var a := Area3D.new()
	a.collision_layer = 0
	a.collision_mask = 4
	a.position = pos
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = size
	cs.shape = sh
	a.add_child(cs)
	parent.add_child(a)
	a.body_entered.connect(func(b): on_enter.call(b))
	return a
