extends RefCounted
## 入口大厅:修女雕像、三扇门、接待台。

const PT = preload("res://scripts/painted_text.gd")
const Letters = preload("res://scripts/letters.gd")
const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")
const StatueS = preload("res://scripts/statue.gd")
const Props = preload("res://scripts/props.gd")
const DrawS = preload("res://scripts/draw.gd")

static func build(m, root: Node3D) -> void:
	var wall := Mats.get_mat("wallpaper")
	var floor_m := Mats.get_mat("wood")
	var ceil_m := Mats.get_mat("concrete")
	var trim := Mats.solid(Color(0.1, 0.07, 0.05))
	var wood := Mats.get_mat("deskwood")

	# 地板 / 天花板
	WB.slab(root, Vector3(-4.2, -0.2, -12.2), Vector3(4.2, 0, 12.2), floor_m)
	WB.slab(root, Vector3(-4.2, 3.0, -12.2), Vector3(4.2, 3.2, 12.2), ceil_m)
	# 南墙(入口)
	WB.slab(root, Vector3(-4.2, 0, 12.0), Vector3(4.2, 3, 12.2), wall)
	# 西墙(办公室门洞 z -1..1)
	WB.slab(root, Vector3(-4.2, 0, -12.2), Vector3(-4.0, 3, -1.0), wall)
	WB.slab(root, Vector3(-4.2, 0, 1.0), Vector3(-4.0, 3, 12.2), wall)
	WB.slab(root, Vector3(-4.2, 2.4, -1.0), Vector3(-4.0, 3, 1.0), wall)
	# 东墙(厕所门洞 z 3..5)
	WB.slab(root, Vector3(4.0, 0, -12.2), Vector3(4.2, 3, 3.0), wall)
	WB.slab(root, Vector3(4.0, 0, 5.0), Vector3(4.2, 3, 12.2), wall)
	WB.slab(root, Vector3(4.0, 2.4, 3.0), Vector3(4.2, 3, 5.0), wall)
	# 北墙(实验室门洞 x -1..1)
	WB.slab(root, Vector3(-4.2, 0, -12.2), Vector3(-1.0, 3, -12.0), wall)
	WB.slab(root, Vector3(1.0, 0, -12.2), Vector3(4.2, 3, -12.0), wall)
	WB.slab(root, Vector3(-1.0, 2.4, -12.2), Vector3(1.0, 3, -12.0), wall)

	# 踢脚线与地毯
	WB.slab(root, Vector3(-4.0, 0, -12.0), Vector3(-3.9, 0.16, 12.0), trim, false)
	WB.slab(root, Vector3(3.9, 0, -12.0), Vector3(4.0, 0.16, 12.0), trim, false)
	WB.slab(root, Vector3(-0.8, 0.0, -11.5), Vector3(0.8, 0.02, 11.5), Mats.get_mat("carpet"), false)

	# 灯(发黄、会闪)
	var warm := Color(1.0, 0.86, 0.5)
	WB.lamp(root, Vector3(0, 2.95, 8.0), warm, 1.5, 0.2, 0.15)
	WB.lamp(root, Vector3(0, 2.95, 2.0), warm, 1.2, 0.25, 0.25)
	WB.lamp(root, Vector3(0, 2.95, -5.0), warm, 1.0, 0.3, 0.3)
	WB.lamp(root, Vector3(0, 2.95, -10.0), Color(0.8, 0.9, 0.7), 0.9, 0.3, 0.35)

	# 裸露的电线
	var cable := Mats.solid(Color(0.02, 0.02, 0.02))
	for p in [Vector3(1.6, 2.4, 6.0), Vector3(-1.8, 2.3, -3.0), Vector3(2.2, 2.5, -8.0)]:
		WB.cyl(root, p, 0.015, 1.2, cable, false)
	var long_cable := WB.cyl(root, Vector3(0, 2.92, 0), 0.02, 24.0, cable, false)
	long_cable.rotation.x = deg_to_rad(90.0)

	# 墙上的绿色化学污渍
	var stain := StandardMaterial3D.new()
	stain.albedo_color = Color(0.25, 0.65, 0.25, 0.35)
	stain.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	WB.slab(root, Vector3(-4.0, 0.2, -4.0), Vector3(-3.97, 2.0, -2.2), stain, false)
	WB.slab(root, Vector3(3.97, 0.0, 6.0), Vector3(4.0, 1.4, 7.4), stain, false)
	WB.slab(root, Vector3(-3.0, 0.0, -11.97), Vector3(-1.6, 1.3, -11.95), stain, false)

	# 实验区牌子
	PT.make(root, Vector3(0, 2.72, -11.94), 0.0, "实验区\n仅限授权人员", "plate", 1.1, Color(0.6, 0.08, 0.06), "bold", 150, 0.42)

	# 接待台(正面朝西,台后是信格墙和时钟)
	var desk_node := Props.reception(root, Vector3(2.55, 0.0, 8.0))
	desk_node.rotation_degrees.y = 90.0
	desk_node.position = Vector3(2.9, 0.0, 8.0)
	# 来信 1:插在信格里(第 3 排,玩家站在台前能看到)
	Letters.spawn(m, root, 0, desk_node.transform * Vector3(-0.6, 1.64, 0.83), 0.0, "slot", Vector3(0.18, 0.22, 0.3))
	WB.inter(root, Vector3(2.9, 1.15, 8.0), Vector3(1.2, 0.7, 2.9), "查看接待台", func():
		UI.toast("发霉的访客登记表。最后一页只写着:“米诺地尔,第 417 批”。\n登记表下压着一份《柳湾周报》,头条是:《帽子脱销!全镇八成居民出门必戴帽,理发店老板:我也想买一顶》。", 4.5))

	# 海报
	var poster := Node3D.new()
	poster.set_script(preload("res://scripts/poster.gd"))
	poster.position = Vector3(3.945, 1.72, 10.3)
	poster.rotation_degrees.y = -90.0
	root.add_child(poster)
	WB.inter(root, Vector3(3.8, 1.72, 10.3), Vector3(0.5, 1.2, 0.9), "查看海报", func():
		UI.toast("一张褪色的药品广告。米诺地尔——原本是降血压的药,吃了的人却意外长出了头发。\n广告上那个男人的脸,被人用记号笔画满了头发,眼睛被划掉了。\n旁边有人用红笔写着:“停药之后,它会全部掉回去。”", 6.0))

	# 长椅(铁腿木板,靠背朝东)
	Props.bench(root, Vector3(-3.55, 0.0, 5.7), 90.0, 3.4)
	WB.inter(root, Vector3(-3.5, 0.6, 5.7), Vector3(0.8, 0.8, 3.6), "查看长椅", func():
		UI.toast("扶手上贴着小牌:“候诊区。请勿在此脱发。”\n牌子下面,积了一层头发。", 3.0))

	# 入口大门:门框、微微敞开的双扇门、漏进来的蓝色月光
	var frame_m := Mats.solid(Color(0.1, 0.07, 0.05), 0.6)
	WB.slab(root, Vector3(-1.12, 0, 11.88), Vector3(-1.0, 2.5, 12.0), frame_m, false)
	WB.slab(root, Vector3(1.0, 0, 11.88), Vector3(1.12, 2.5, 12.0), frame_m, false)
	WB.slab(root, Vector3(-1.12, 2.4, 11.88), Vector3(1.12, 2.5, 12.0), frame_m, false)
	WB.slab(root, Vector3(-1.0, 0, 12.0), Vector3(1.0, 2.4, 12.2), Mats.emissive(Color(0.12, 0.17, 0.3), 0.5), false)
	var dl := WB.door(root, Vector3(-1.0, 0, 11.85), 0.0, 0.0, 1.0, 2.4, Mats.get_mat("wood"))
	dl.rotation_degrees.y = 18.0
	var dr := WB.door(root, Vector3(1.0, 0, 11.85), 180.0, 180.0, 1.0, 2.4, Mats.get_mat("wood"))
	dr.rotation_degrees.y = 180.0 + 20.0
	var moon := OmniLight3D.new()
	moon.position = Vector3(0, 1.4, 12.6)
	moon.light_color = Color(0.45, 0.58, 1.0)
	moon.light_energy = 0.9
	moon.omni_range = 7.0
	root.add_child(moon)
	WB.label3d(root, Vector3(0, 2.62, 11.9), "EXIT", Color(0.2, 1.0, 0.4), 0.007, 180.0, true)
	WB.box(root, Vector3(0, 2.62, 11.93), Vector3(0.6, 0.2, 0.04), Mats.emissive(Color(0.05, 0.4, 0.15), 1.2), false)
	WB.inter(root, Vector3(0, 1.2, 11.5), Vector3(2.2, 2.4, 0.9), "大门", func():
		UI.toast("身后的大门不知何时关上了,纹丝不动。", 3.0))

	_decorate(m, root)

	# ---- 三扇门 ----
	var door_mat := Mats.get_mat("wood")
	# 厕所
	var rd := WB.door(root, Vector3(4.1, 0, 5.0), 90.0, 0.0, 2.0, 2.4, door_mat)
	var ri = rd.add_inter(2.0, 2.4, "推开厕所门", Callable())
	ri.action = func():
		rd.set_open(true)
		SFX.play("door")
		ri.enabled = false
		GS.set_flag("restroom_open")
	if GS.has_flag("restroom_open"):
		rd.set_open(true, false)
		ri.enabled = false
	# 办公室
	var od := WB.door(root, Vector3(-4.1, 0, 1.0), 90.0, 180.0, 2.0, 2.4, door_mat)
	var oi = od.add_inter(2.0, 2.4, "", Callable())
	oi.prompt_fn = func():
		return "用钥匙打开办公室的门" if GS.has_item("office_key") else "尝试打开办公室的门"
	oi.action = func():
		if GS.has_item("office_key"):
			od.set_open(true)
			SFX.play("door")
			oi.enabled = false
			GS.set_flag("office_unlocked")
			UI.toast("钥匙转动了。门吱呀一声开了。", 3.0)
			m.checkpoint()
		else:
			SFX.play("click")
			UI.toast("锁住了。门缝里飘出更浓的生发剂气味。", 3.0)
	if GS.has_flag("office_unlocked"):
		od.set_open(true, false)
		oi.enabled = false
	# 实验室
	var ld := WB.door(root, Vector3(-1.0, 0, -12.1), 0.0, 90.0, 2.0, 2.4, Mats.get_mat("steel"))
	var li = ld.add_inter(2.0, 2.4, "", Callable())
	li.prompt_fn = func():
		return "刷门禁卡" if GS.has_item("lab_keycard") else "读卡器(需要门禁卡)"
	li.action = func():
		if GS.has_item("lab_keycard"):
			ld.set_open(true)
			SFX.play("door")
			li.enabled = false
			GS.set_flag("lab_unlocked")
			UI.toast("嘀。读卡器变绿了。一股冷气扑面而来。", 3.5)
		else:
			SFX.play("buzz")
			UI.toast("读卡器闪着红灯。需要门禁卡。", 3.0)
	if GS.has_flag("lab_unlocked"):
		ld.set_open(true, false)
		li.enabled = false

	# ---- 雕像 ----
	WB.slab(root, Vector3(-3.05, 0, -5.55), Vector3(-1.95, 0.6, -4.45), Mats.get_mat("stone"))
	var st = StatueS.new()
	st.position = Vector3(-2.5, 0.6, -5.0)
	st.rotation.y = PI
	root.add_child(st)
	st.build(m)
	m.statue = st
	if GS.has_flag("statue_defeated"):
		st.global_position = Vector3(-2.5, 0.0, -3.6)   # 读档/重试时,倒在基座前面
		st.set_defeated_instant()
	else:
		st.setup_tweezers(GS.has_flag("got_tweezers"), func(): _take_tweezers(m, st))
		if GS.has_flag("got_tweezers"):
			st.state = StatueS.S.CHASE
			st._set_stab_active(true)
			st.global_position = Vector3(-2.5, 0.0, -3.7)
			st.pause_t = 3.0

static func _take_tweezers(m, st) -> void:
	st.remove_tweezers()
	m.give_item("tweezers")
	GS.set_flag("statue_awakened")
	UI.flash(Color(0, 0, 0, 0.9), 0.9)
	m.get_tree().call_group("lamps", "pulse_off", 1.0)
	st.awaken()


## 墙裙、门框、顶线、挂画、吊灯罩、盆栽、灭火器、蜘蛛网、灰尘、杂物
static func _decorate(m, root: Node3D) -> void:
	var wood := Mats.get_mat("deskwood")
	var rail := Mats.solid(Color(0.09, 0.06, 0.04), 0.5)
	# 墙裙 + 压条(避开门洞)
	for seg in [[-12.0, -1.0], [1.0, 12.0]]:
		WB.slab(root, Vector3(-4.0, 0, seg[0]), Vector3(-3.94, 1.0, seg[1]), wood, false)
		WB.slab(root, Vector3(-4.0, 1.0, seg[0]), Vector3(-3.9, 1.05, seg[1]), rail, false)
	for seg in [[-12.0, 3.0], [5.0, 12.0]]:
		WB.slab(root, Vector3(3.94, 0, seg[0]), Vector3(4.0, 1.0, seg[1]), wood, false)
		WB.slab(root, Vector3(3.9, 1.0, seg[0]), Vector3(4.0, 1.05, seg[1]), rail, false)
	for seg in [[-4.0, -1.0], [1.0, 4.0]]:
		WB.slab(root, Vector3(seg[0], 0, -12.0), Vector3(seg[1], 1.0, -11.94), wood, false)
		WB.slab(root, Vector3(seg[0], 1.0, -12.0), Vector3(seg[1], 1.05, -11.9), rail, false)
	# 顶线
	WB.slab(root, Vector3(-4.0, 2.9, -12.0), Vector3(-3.88, 3.0, 12.0), rail, false)
	WB.slab(root, Vector3(3.88, 2.9, -12.0), Vector3(4.0, 3.0, 12.0), rail, false)
	WB.slab(root, Vector3(-4.0, 2.9, -12.0), Vector3(4.0, 3.0, -11.88), rail, false)
	WB.slab(root, Vector3(-4.0, 2.9, 11.88), Vector3(4.0, 3.0, 12.0), rail, false)
	# 门框:办公室 / 厕所 / 实验室
	for z in [-1.0, 1.0]:
		WB.slab(root, Vector3(-4.0, 0, z - 0.06), Vector3(-3.9, 2.46, z + 0.06), rail, false)
	WB.slab(root, Vector3(-4.0, 2.4, -1.06), Vector3(-3.9, 2.46, 1.06), rail, false)
	for z in [3.0, 5.0]:
		WB.slab(root, Vector3(3.9, 0, z - 0.06), Vector3(4.0, 2.46, z + 0.06), rail, false)
	WB.slab(root, Vector3(3.9, 2.4, 2.94), Vector3(4.0, 2.46, 5.06), rail, false)
	for x in [-1.0, 1.0]:
		WB.slab(root, Vector3(x - 0.06, 0, -12.0), Vector3(x + 0.06, 2.46, -11.9), rail, false)
	WB.slab(root, Vector3(-1.06, 2.4, -12.0), Vector3(1.06, 2.46, -11.9), rail, false)
	# 门牌
	PT.make(root, Vector3(3.94, 2.2, 4.0), -90.0, "WC", "plate", 0.42, Color(0.12, 0.2, 0.35), "bold", 300, 0.55)
	PT.make(root, Vector3(-3.94, 2.2, 0.0), 90.0, "办公室", "plate", 0.55, Color(0.15, 0.12, 0.1), "bold", 240, 0.42)
	# 挂画(有的歪了)
	var tw := [
		[Vector3(-3.96, 1.75, -9.5), 90.0, Vector2(0.6, 0.75), "nun", 4.0],
		[Vector3(-3.96, 1.75, -7.0), 90.0, Vector2(0.9, 0.6), "landscape", -3.0],
		[Vector3(-3.96, 1.7, 3.0), 90.0, Vector2(0.55, 0.7), "certificate", 9.0],
		[Vector3(-3.96, 1.75, 9.5), 90.0, Vector2(0.6, 0.75), "portrait", -2.0],
		[Vector3(3.96, 1.75, -9.0), -90.0, Vector2(0.6, 0.75), "ad", 2.0],
		[Vector3(3.96, 1.75, -3.0), -90.0, Vector2(0.62, 0.78), "family", 6.0],
		[Vector3(3.96, 1.75, 1.0), -90.0, Vector2(0.55, 0.7), "portrait", -4.0],
	]
	for f in tw:
		Props.picture_frame(root, f[0], f[1], f[2], f[3], f[4], true)
	# 灯罩
	for z in [8.0, 2.0, -5.0, -10.0]:
		Props.lamp_shade(root, Vector3(0, 2.62, z))
	# 壁灯(不亮,只是摆设)
	for z in [6.5, -3.0, -8.0]:
		WB.box(root, Vector3(-3.9, 1.9, z), Vector3(0.1, 0.22, 0.14), Mats.solid(Color(0.14, 0.12, 0.08), 0.4, 0.6), false)
		WB.ball(root, Vector3(-3.84, 1.95, z), 0.07, Mats.solid(Color(0.7, 0.68, 0.55), 0.3))
	# 枯萎盆栽、灭火器、箱子、杂物
	Props.dead_plant(root, Vector3(3.2, 0.0, 10.8))
	Props.dead_plant(root, Vector3(-3.3, 0.0, -11.2))
	var red := Mats.solid(Color(0.7, 0.05, 0.05), 0.4)
	WB.cyl(root, Vector3(3.82, 0.95, -6.5), 0.08, 0.4, red, false)
	WB.cyl(root, Vector3(3.82, 1.2, -6.5), 0.03, 0.1, Mats.solid(Color(0.1, 0.1, 0.1)), false)
	WB.box(root, Vector3(3.9, 1.35, -6.5), Vector3(0.02, 0.28, 0.3), Mats.solid(Color(0.8, 0.1, 0.1)), false)
	Props.crate(root, Vector3(-3.3, 0.0, -9.2), 12.0)
	Props.crate(root, Vector3(-3.4, 0.6, -9.1), 40.0)
	Props.crate(root, Vector3(3.3, 0.0, -10.6), -20.0)
	var paper := Mats.solid(Color(0.85, 0.82, 0.68))
	var rng := RandomNumberGenerator.new()
	rng.seed = 11
	for i in 14:
		var pp := WB.box(root, Vector3(rng.randf_range(-3.4, 3.4), 0.012, rng.randf_range(-10.5, 10.5)), Vector3(0.3, 0.004, 0.22), paper, false)
		pp.rotation.y = rng.randf() * TAU
	# 蜘蛛网
	var web_mat := StandardMaterial3D.new()
	web_mat.albedo_texture = DrawS.web_image()
	web_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	web_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	web_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	for c in [[Vector3(3.9, 2.9, 11.9), 225.0], [Vector3(-3.9, 2.9, 11.9), 135.0], [Vector3(3.9, 2.9, -11.9), 315.0], [Vector3(-3.9, 2.9, -11.9), 45.0]]:
		var wq := MeshInstance3D.new()
		var qm := QuadMesh.new()
		qm.size = Vector2(0.9, 0.9)
		wq.mesh = qm
		wq.material_override = web_mat
		wq.position = c[0] + Vector3(0, -0.4, 0)
		wq.rotation_degrees = Vector3(0, c[1], 0)
		root.add_child(wq)
	# 漂浮的灰尘
	var dust := CPUParticles3D.new()
	dust.position = Vector3(0, 1.5, 0)
	dust.amount = 90
	dust.lifetime = 9.0
	dust.preprocess = 9.0
	dust.emission_shape = CPUParticles3D.EMISSION_SHAPE_BOX
	dust.emission_box_extents = Vector3(3.8, 1.4, 11.0)
	dust.gravity = Vector3(0, -0.01, 0)
	dust.initial_velocity_min = 0.02
	dust.initial_velocity_max = 0.08
	dust.direction = Vector3(0, 1, 0)
	dust.spread = 180.0
	var dq := QuadMesh.new()
	dq.size = Vector2(0.014, 0.014)
	dust.mesh = dq
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(1.0, 0.95, 0.8, 0.55)
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	dm.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	dust.material_override = dm
	root.add_child(dust)
