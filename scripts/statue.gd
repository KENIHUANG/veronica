extends CharacterBody3D
## 修女雕像:拿走镊子后先张嘴尖叫,然后抽搐着追击;被镜子碎片刺中后崩坏,头顶有机关。

const Slots = preload("res://scripts/asset_slots.gd")
const Mats = preload("res://scripts/mats.gd")
const WB = preload("res://scripts/wb.gd")
const Nav = preload("res://scripts/nav.gd")
const H = preload("res://scripts/humanoid.gd")
const Props = preload("res://scripts/props.gd")
const ML = preload("res://scripts/meshlib.gd")
const Person = preload("res://scripts/person.gd")
const Draw = preload("res://scripts/draw.gd")

enum S { IDLE, SCREAM, CHASE, GRAPPLE, DEFEATED, LURK }
const SCREAM_DUR := 2.6
const LURK_PT := Vector3(2.6, 0, 4.0)     # 大厅里、厕所门口:玩家躲起来后,她就在这里来回踱步

var state: int = S.IDLE
var player: Node3D = null
var m = null
var pause_t := 0.0
var path_t := 0.0
var next_pt := Vector3.ZERO
var stuck_t := 0.0
var force_graph_t := 0.0
var scream_t := 0.0
var growl_t := 6.0
var lamp_t := 0.0
var t := 0.0
var lurk_t := 0.0
var body_root: Node3D
var head: Node3D
var jaw: Node3D
var arm_r: Node3D
var eyes: Array = []
var heart: MeshInstance3D
var button_mi: MeshInstance3D
var tweezers: Node3D
var tweezers_inter: Area3D
var stab_inter: Area3D
var button_inter: Area3D

func build(main_node) -> void:
	m = main_node
	add_to_group("statue")
	collision_layer = 8
	collision_mask = 1 | 16
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.42
	cap.height = 2.1
	cs.shape = cap
	cs.position.y = 1.05
	add_child(cs)
	body_root = Node3D.new()
	add_child(body_root)

	var stone: StandardMaterial3D = Mats.get_mat("stone").duplicate()
	stone.albedo_color = Color(0.8, 0.8, 0.78)
	var robe: StandardMaterial3D = Mats.get_mat("stone").duplicate()
	robe.albedo_color = Color(0.2, 0.2, 0.23)
	var robe_hi: StandardMaterial3D = Mats.get_mat("stone").duplicate()
	robe_hi.albedo_color = Color(0.3, 0.3, 0.33)
	var dark := Mats.solid(Color(0.005, 0.005, 0.005), 0.8)
	var moss := Mats.solid(Color(0.12, 0.2, 0.08), 1.0)
	var cream := Mats.solid(Color(0.8, 0.77, 0.65), 0.6)

	# ---- 长袍:带深褶皱的旋转体 + 胸前披肩 + 腰绳 ----
	var prof := [Vector2(0.62, 0.0), Vector2(0.57, 0.35), Vector2(0.47, 0.8), Vector2(0.35, 1.2), Vector2(0.28, 1.5), Vector2(0.25, 1.64)]
	var rm := MeshInstance3D.new()
	rm.mesh = ML.revolve(prof, 64, 0.09, 9, false)
	rm.material_override = robe
	body_root.add_child(rm)
	H._ell(body_root, Vector3(0, 1.58, 0), Vector3(0.31, 0.15, 0.2), robe)                       # 肩
	var scap := []
	var scr := []
	for i in 7:
		var y := 1.55 - i * 0.24
		var rad := lerpf(0.62, 0.25, clampf(y / 1.64, 0.0, 1.0)) * 1.0
		rad = 0.25 + (0.62 - 0.25) * pow(1.0 - clampf(y / 1.64, 0.0, 1.0), 1.0) * 0.9
		scap.append(Vector3(0, y, -rad - 0.015))
		scr.append(Vector2(0.11 + (1.55 - y) * 0.03, 0.014))
	var sc_mesh := MeshInstance3D.new()
	sc_mesh.mesh = ML.loft(scap, scr, 10, {"caps": false})
	sc_mesh.material_override = robe_hi
	body_root.add_child(sc_mesh)
	Props._torus(body_root, Vector3(0, 1.2, 0), 0.30, 0.325, dark, Vector3(1, 0.7, 1))        # 腰绳
	var gorget := MeshInstance3D.new()
	gorget.mesh = ML.revolve([Vector2(0.15, 1.8), Vector2(0.19, 1.68), Vector2(0.245, 1.6), Vector2(0.27, 1.5), Vector2(0.25, 1.44)], 40, 0.03, 7, false)
	gorget.material_override = stone
	body_root.add_child(gorget)
	var neck := MeshInstance3D.new()
	neck.mesh = ML.loft([Vector3(0, 1.6, 0), Vector3(0, 1.78, -0.005), Vector3(0, 1.88, -0.01)], [Vector2(0.075, 0.075), Vector2(0.058, 0.058), Vector2(0.055, 0.055)], 14)
	neck.material_override = stone
	body_root.add_child(neck)
	Props._torus(body_root, Vector3(0, 0.04, 0), 0.56, 0.66, robe_hi, Vector3(1, 0.4, 1))

	# ---- 头部:雕刻的脸(骷髅感)+ 可张合的下颌 + 兜帽 + 披纱 ----
	head = Node3D.new()
	head.position = Vector3(0, 1.97, 0)
	head.rotation.z = 0.12
	head.scale = Vector3.ONE * 1.12
	body_root.add_child(head)
	var hd := ML.head({"gaunt": 0.7, "socket": 1.0, "brow": 1.25, "chin": 1.15, "skull": 0.8, "split": true})
	var ftex := Draw.face_texture({"skin": Color(0.74, 0.74, 0.71), "eyes": "hollow", "socket": 1.2, "black_tears": true, "age": 1.0, "dead": true, "bags": 0.9, "blush": 0.0, "lips": Color(0.45, 0.45, 0.43), "brow": Color(0.3, 0.3, 0.3)})
	var fmat := StandardMaterial3D.new()
	fmat.albedo_texture = ftex
	fmat.roughness = 0.9
	fmat.albedo_color = Color(0.72, 0.72, 0.7)     # 头顶有聚光灯,压暗避免脸被照成一片白
	fmat.texture_repeat = false
	var up := MeshInstance3D.new()
	up.mesh = hd["upper"]
	up.material_override = fmat
	head.add_child(up)
	jaw = Node3D.new()
	jaw.position = hd["pivot"]
	head.add_child(jaw)
	var jm := MeshInstance3D.new()
	jm.mesh = hd["jaw"]
	jm.material_override = fmat
	jaw.add_child(jm)
	H._ell(head, Vector3(0, -0.06, -0.045), Vector3(0.042, 0.022, 0.034), dark)                   # 口腔
	for i in 8:
		var tx := -0.0305 + i * 0.0087
		WB.box(head, Vector3(tx, -0.056, -0.088 + absf(tx) * 0.9), Vector3(0.0075, 0.012, 0.006), cream, false)
		WB.box(jaw, Vector3(tx, 0.002, -0.088 + absf(tx) * 0.9 + 0.004), Vector3(0.0075, 0.011, 0.006), cream, false)
	Person._hair_cap(head, robe, 34.0, 1.3)                                                       # 兜帽(内层)
	# 兜帽外层:一圈垂到肩上的布,略微靠后,让脸从开口里"探出来"
	var cowl := MeshInstance3D.new()
	cowl.mesh = ML.loft(
		[Vector3(0, 0.17, 0.05), Vector3(0, 0.1, 0.045), Vector3(0, 0.02, 0.045), Vector3(0, -0.07, 0.05), Vector3(0, -0.15, 0.06), Vector3(0, -0.25, 0.08)],
		[Vector2(0.06, 0.055), Vector2(0.106, 0.104), Vector2(0.114, 0.11), Vector2(0.11, 0.108), Vector2(0.125, 0.12), Vector2(0.21, 0.17)],
		24, {"ripple": 0.05, "ripple_n": 7})
	cowl.material_override = robe
	head.add_child(cowl)
	Props._torus(head, Vector3(0, 0.06, -0.008), 0.073, 0.092, stone, Vector3(1.0, 0.9, 1.12))   # 额带
	var veil := MeshInstance3D.new()
	veil.mesh = ML.loft([Vector3(0, 0.08, 0.09), Vector3(0, -0.2, 0.15), Vector3(0, -0.6, 0.2), Vector3(0, -0.95, 0.24)], [Vector2(0.15, 0.022), Vector2(0.2, 0.03), Vector2(0.26, 0.034), Vector2(0.3, 0.036)], 18, {"ripple": 0.1, "ripple_n": 5, "caps": false})
	veil.material_override = robe
	head.add_child(veil)
	for sx in [-1.0, 1.0]:
		var glow := H._ell(head, Vector3(sx * 0.037, 0.027, -0.084), Vector3(0.011, 0.009, 0.007), Mats.emissive(Color(1.0, 0.12, 0.05), 9.0))
		glow.visible = false
		eyes.append(glow)
	var eye_light := OmniLight3D.new()
	eye_light.light_color = Color(1.0, 0.15, 0.1)
	eye_light.light_energy = 0.9
	eye_light.omni_range = 1.6
	eye_light.position = Vector3(0, 0.03, -0.22)
	eye_light.visible = false
	head.add_child(eye_light)
	eyes.append(eye_light)
	button_mi = WB.cyl(head, Vector3(0, 0.215, 0.05), 0.03, 0.02, Mats.emissive(Color(1.0, 0.05, 0.05), 3.0), false)
	button_mi.visible = false

	# ---- 裂纹与苔藓 ----
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for i in 14:
		var a := rng.randf() * TAU
		var y := rng.randf_range(0.3, 1.4)
		var r := lerpf(0.62, 0.27, y / 1.5) + 0.008
		var c := WB.box(body_root, Vector3(sin(a) * r, y, cos(a) * r), Vector3(0.006, rng.randf_range(0.08, 0.3), 0.004), dark, false)
		c.rotation.y = a
		c.rotation_degrees.z = rng.randf_range(-35, 35)
	for i in 6:
		var a := rng.randf() * TAU
		var mo := H._ell(body_root, Vector3(sin(a) * 0.58, 0.07, cos(a) * 0.58), Vector3(0.12, 0.025, 0.09), moss)
		mo.rotation.y = a

	# ---- 向前伸出的右臂:宽袖 + 石手,指尖夹着镊子 ----
	arm_r = Node3D.new()
	arm_r.position = Vector3(0.33, 1.56, 0)
	arm_r.rotation_degrees.x = 82.0
	body_root.add_child(arm_r)
	var sleeve := MeshInstance3D.new()
	sleeve.mesh = ML.loft([Vector3(0, 0, 0), Vector3(0, -0.25, 0), Vector3(0, -0.5, 0)], [Vector2(0.075, 0.075), Vector2(0.1, 0.1), Vector2(0.135, 0.135)], 18, {"ripple": 0.07, "ripple_n": 5, "caps": false})
	sleeve.material_override = robe
	arm_r.add_child(sleeve)
	var wrist := MeshInstance3D.new()
	wrist.mesh = ML.loft([Vector3(0, -0.42, 0), Vector3(0, -0.56, 0)], [Vector2(0.045, 0.04), Vector2(0.036, 0.032)], 12)
	wrist.material_override = stone
	arm_r.add_child(wrist)
	var hand_r := Person.make_hand(stone, 1.2, 0.42)
	hand_r.position = Vector3(0, -0.56, 0)
	arm_r.add_child(hand_r)
	tweezers = Node3D.new()
	tweezers.position = Vector3(0, -0.72, 0)
	arm_r.add_child(tweezers)
	var steel := Props.chrome()
	for sx in [-1.0, 1.0]:
		var blade := WB.box(tweezers, Vector3(sx * 0.006, -0.09, 0), Vector3(0.005, 0.26, 0.012), steel, false)
		blade.rotation_degrees.z = -sx * 1.2
	# ---- 垂着的左臂 + 念珠 ----
	var arm_l := Node3D.new()
	arm_l.position = Vector3(-0.33, 1.56, 0)
	arm_l.rotation_degrees.z = -7.0
	body_root.add_child(arm_l)
	var sleeve_l := MeshInstance3D.new()
	sleeve_l.mesh = sleeve.mesh
	sleeve_l.material_override = robe
	arm_l.add_child(sleeve_l)
	var wrist_l := MeshInstance3D.new()
	wrist_l.mesh = wrist.mesh
	wrist_l.material_override = stone
	arm_l.add_child(wrist_l)
	var hand_l := Person.make_hand(stone, 1.2, 0.7)
	hand_l.position = Vector3(0, -0.56, 0)
	arm_l.add_child(hand_l)
	var bead := Mats.solid(Color(0.05, 0.03, 0.02), 0.3, 0.2)
	for i in 20:
		H._ell(arm_l, Vector3(sin(i * 0.4) * 0.012, -0.64 - i * 0.045, -0.035), Vector3(0.016, 0.016, 0.016), bead)
	WB.box(arm_l, Vector3(0, -1.58, -0.035), Vector3(0.018, 0.08, 0.01), cream, false)
	WB.box(arm_l, Vector3(0, -1.56, -0.035), Vector3(0.05, 0.018, 0.01), cream, false)

	heart = WB.ball(body_root, Vector3(0, 1.33, -0.31), 0.08, Mats.emissive(Color(0.95, 0.05, 0.05), 3.5))
	heart.visible = false

	# 素材替换槽:assets/models/statue_nun.glb 存在时隐藏程序化石像,只保留眼睛、心脏、头顶按钮、镊子这些功能件
	var sm := Slots.model("statue_nun")
	if sm != null:
		var keep: Array = [heart, button_mi, tweezers]
		keep.append_array(eyes)
		_hide_meshes(body_root, keep)
		body_root.add_child(sm)

	# 互动区
	stab_inter = WB.inter(self, Vector3(0, 1.1, 0), Vector3(1.4, 2.3, 1.4), "")
	stab_inter.prompt_fn = func():
		if state == S.CHASE and GS.has_item("mirror_shard"):
			return "用镜子碎片刺进她的胸口!"
		return ""
	stab_inter.action = _begin_stab
	stab_inter.collision_layer = 0
	button_inter = WB.inter(head, Vector3(0, 0.22, 0.04), Vector3(0.6, 0.5, 0.6), "")
	button_inter.prompt_fn = func():
		if state == S.DEFEATED and not GS.has_flag("got_lab_keycard"):
			return "按下头顶的红色按钮"
		return ""
	button_inter.action = _press_button

func _hide_meshes(n: Node, keep: Array) -> void:
	if n in keep:
		return
	if n is GeometryInstance3D:
		(n as GeometryInstance3D).visible = false
		return
	for c in n.get_children():
		_hide_meshes(c, keep)

func setup_tweezers(taken: bool, on_take: Callable) -> void:
	if taken:
		tweezers.visible = false
		return
	tweezers_inter = WB.inter(arm_r, Vector3(0, -0.72, 0), Vector3(0.5, 0.6, 0.5), "拿走镊子", on_take)

func remove_tweezers() -> void:
	tweezers.visible = false
	if tweezers_inter != null:
		tweezers_inter.queue_free()
		tweezers_inter = null

## 先尖叫,再追击
func awaken() -> void:
	if state != S.IDLE:
		return
	state = S.SCREAM
	scream_t = SCREAM_DUR
	for e in eyes:
		e.visible = true
	SFX.play("scream")
	SFX.play("sting", -6.0)
	if player != null:
		player.locked = true
		player.face_point(head.global_position)
		player.shake(SCREAM_DUR, 0.012)
	UI.toast("……石像的嘴,缓缓张开了。", 2.4)

## 刺入框只在追击时存在,否则它会挡住头顶按钮和镊子的射线
func _set_stab_active(on: bool) -> void:
	stab_inter.set_deferred("collision_layer", 2 if on else 0)

func _end_scream() -> void:
	_set_stab_active(true)
	body_root.position = Vector3.ZERO
	head.rotation.x = 0.1
	jaw.rotation.x = -0.4
	state = S.CHASE
	pause_t = 1.8     # 给玩家一点反应时间:先尖叫,再追
	if player != null:
		var d := player.global_position - global_position
		d.y = 0
		global_position = global_position + d.normalized() * 1.45
		global_position.y = 0.0
		player.locked = false
	UI.toast("跑。右边——厕所!", 3.5)

func set_defeated_instant() -> void:
	state = S.DEFEATED
	global_position.y = 0.0
	_collapse()

func _collapse() -> void:
	_set_stab_active(false)
	body_root.scale.y = 0.55
	body_root.rotation.x = deg_to_rad(-14.0)
	head.rotation.z = 0.5
	jaw.rotation.x = -0.7
	heart.visible = true
	button_mi.visible = true
	for e in eyes:
		e.visible = false

func _begin_stab() -> void:
	if state != S.CHASE or player == null:
		return
	state = S.GRAPPLE
	_set_stab_active(false)
	UI.qte(6, 2.4, _stab_ok, _stab_fail)

func _stab_ok() -> void:
	state = S.DEFEATED
	_collapse()
	SFX.play("glass")
	SFX.play("thump")
	UI.flash(Color(1, 1, 1, 0.5), 0.5)
	player.shake(0.4, 0.04)
	GS.set_flag("statue_defeated")
	UI.toast("碎片没入石像的胸口。她跪了下去。\n头顶,有个红色的按钮在闪。", 5.0)

func _stab_fail() -> void:
	_set_stab_active(true)
	state = S.CHASE
	pause_t = 1.8
	player.take_hit(1, global_position)

func _start_lurk() -> void:
	state = S.LURK
	_set_stab_active(false)
	path_t = 0.0
	lurk_t = 0.0
	velocity = Vector3.ZERO
	if not GS.has_flag("hid_from_statue"):
		GS.set_flag("hid_from_statue")
		UI.toast("脚步声停在了门口。\n……她在找你。", 4.0)

## 门外徘徊:走到厕所门口,来回踱步,时不时朝门里看。
## 玩家没躲、又离她太近 → 继续追;玩家拿到镜子碎片 → 她闯进来(给玩家刺她的机会)。
func _lurk(delta: float) -> void:
	if player == null or player.dead or UI.blocked():
		velocity = Vector3.ZERO
		return
	lurk_t += delta
	var to_p := player.global_position - global_position
	to_p.y = 0
	if not player.hidden and not player.locked:
		if GS.has_flag("got_mirror_shard"):
			state = S.CHASE
			pause_t = 1.2
			_set_stab_active(true)
			SFX.play("growl", -3.0)
			UI.toast("门被推开了。她进来了。", 3.0)
			return
		if to_p.length() < 2.6:
			state = S.CHASE
			pause_t = 0.6
			_set_stab_active(true)
			return
	var goal := LURK_PT + Vector3(0, 0, 0.9 * sin(lurk_t * 0.35))
	path_t -= delta
	if path_t <= 0.0:
		path_t = 0.5
		next_pt = Nav.next_point(get_world_3d().direct_space_state, global_position, goal)
	var step := next_pt - global_position
	step.y = 0
	if step.length() > 0.15 and _flat(goal) > 0.3:
		var phase := fmod(t * 1.4, 1.0)
		var far := _flat(LURK_PT) > 1.5                      # 先快步走到门口,到了再慢慢踱步
		velocity = step.normalized() * ((3.0 if far else 0.9) if phase < 0.45 else (0.4 if far else 0.1))
		rotation.y = lerp_angle(rotation.y, atan2(-step.x, -step.z), 5.0 * delta)
	else:
		velocity = Vector3.ZERO
		rotation.y = lerp_angle(rotation.y, atan2(-1.0, 0.0), 2.0 * delta)   # 面朝厕所门(+X)
	velocity.y = -2.0
	move_and_slide()
	head.rotation.z = 0.12 + 0.05 * sin(t * 0.9)
	jaw.rotation.x = -0.25 + 0.05 * sin(t * 6.0)

func _flat(p: Vector3) -> float:
	return Vector2(p.x - global_position.x, p.z - global_position.z).length()

func _press_button() -> void:
	SFX.play("click")
	SFX.play("door")
	button_mi.visible = false
	m.give_item("lab_keycard", "头顶的暗格弹开了,掉出一张门禁卡。")
	m.checkpoint()

func _physics_process(delta: float) -> void:
	t += delta
	if state == S.IDLE:
		head.rotation.z = 0.12 + 0.02 * sin(t * 0.8)
		return
	if state == S.SCREAM:
		scream_t -= delta
		jaw.rotation.x = lerpf(jaw.rotation.x, -1.0, 9.0 * delta)
		head.rotation.x = lerpf(head.rotation.x, 0.32, 6.0 * delta)
		head.rotation.z = lerpf(head.rotation.z, 0.0, 6.0 * delta)
		body_root.position = Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)) * 0.012
		if player != null:
			var d := player.global_position - global_position
			rotation.y = lerp_angle(rotation.y, atan2(-d.x, -d.z), 3.0 * delta)
		lamp_t -= delta
		if lamp_t <= 0.0:
			lamp_t = 0.3
			get_tree().call_group("lamps", "pulse_off", 0.12)
		if scream_t <= 0.0:
			_end_scream()
		return
	if state == S.DEFEATED:
		button_mi.scale = Vector3.ONE * (1.0 + 0.25 * sin(t * 6.0))
	if state == S.LURK:
		_lurk(delta)
		return
	if state != S.CHASE or player == null or player.dead or player.locked or UI.blocked():
		velocity = Vector3.ZERO
		return
	# 玩家躲起来了:跟丢,退到门外
	if player.hidden:
		_start_lurk()
		return
	if pause_t > 0.0:
		pause_t -= delta
		return
	growl_t -= delta
	if growl_t <= 0.0:
		growl_t = randf_range(5.0, 9.0)
		SFX.play("growl", -5.0)
	var to := player.global_position - global_position
	to.y = 0
	if to.length() < 1.15 and not player.hidden:
		player.take_hit(2, global_position)
		pause_t = 2.2
		return
	path_t -= delta
	force_graph_t -= delta
	if path_t <= 0.0:
		path_t = 0.35
		next_pt = Nav.next_point(get_world_3d().direct_space_state, global_position, player.global_position, force_graph_t <= 0.0)
	# 抽搐式前进
	var phase := fmod(t * 1.4, 1.0)
	var spd := 1.6 * (2.2 if phase < 0.45 else 0.2)
	var step := next_pt - global_position
	step.y = 0
	if step.length() > 0.1:
		velocity = step.normalized() * spd
		rotation.y = lerp_angle(rotation.y, atan2(-step.x, -step.z), 7.0 * delta)
	else:
		velocity = Vector3.ZERO
	velocity.y = -2.0
	move_and_slide()
	head.rotation.z = 0.12 + (0.15 if phase < 0.45 else -0.05)
	jaw.rotation.x = -0.4 + 0.12 * sin(t * 16.0)
	if spd > 1.0 and get_real_velocity().length() < 0.25:
		stuck_t += delta
		if stuck_t > 0.9:
			force_graph_t = 2.5
			stuck_t = 0.0
	else:
		stuck_t = 0.0
