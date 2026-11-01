extends Node3D
## 铰链门:带碰撞,打开时碰撞关闭。门板沿本地 +X 延伸 width,以铰链为原点。

const Inter = preload("res://scripts/interactable.gd")

var closed_yaw: float = 0.0
var open_yaw: float = 90.0
var is_open: bool = false
var body: StaticBody3D
var tw: Tween

func setup(width: float, height: float, mat: Material) -> void:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, height, 0.1)
	mi.mesh = bm
	mi.position = Vector3(width * 0.5, height * 0.5, 0)
	mi.material_override = mat
	add_child(mi)
	# 门把手
	var hd := MeshInstance3D.new()
	var hm := BoxMesh.new()
	hm.size = Vector3(0.12, 0.05, 0.16)
	hd.mesh = hm
	hd.position = Vector3(width - 0.2, height * 0.45, 0)
	var hmat := StandardMaterial3D.new()
	hmat.albedo_color = Color(0.7, 0.62, 0.35)
	hmat.metallic = 0.8
	hmat.roughness = 0.4
	hd.material_override = hmat
	add_child(hd)
	body = StaticBody3D.new()
	body.collision_layer = 16
	body.collision_mask = 0
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(width, height, 0.14)
	cs.shape = sh
	cs.position = Vector3(width * 0.5, height * 0.5, 0)
	body.add_child(cs)
	add_child(body)

func add_inter(width: float, height: float, prompt: String, action: Callable) -> Area3D:
	var a = Inter.new()
	a.collision_layer = 2
	a.collision_mask = 0
	a.monitoring = false
	a.prompt = prompt
	a.action = action
	a.position = Vector3(width * 0.5, height * 0.5, 0)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(width, height, 0.7)
	cs.shape = sh
	a.add_child(cs)
	add_child(a)
	return a

func set_open(v: bool, animate: bool = true) -> void:
	is_open = v
	var target: float = open_yaw if v else closed_yaw
	for c in body.get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", v)
	if animate and is_inside_tree():
		if tw != null and tw.is_valid():
			tw.kill()
		tw = create_tween()
		tw.tween_property(self, "rotation_degrees:y", target, 0.55).set_trans(Tween.TRANS_SINE)
	else:
		rotation_degrees.y = target
