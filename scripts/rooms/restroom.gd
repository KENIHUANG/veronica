extends RefCounted
## 厕所:真正的平面镜(照的时候才有人影)、CSG 马桶、洗手台、四个隔间、蟑螂。

const PT = preload("res://scripts/painted_text.gd")
const Letters = preload("res://scripts/letters.gd")
const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")
const Draw = preload("res://scripts/draw.gd")
const Props = preload("res://scripts/props.gd")
const MirrorS = preload("res://scripts/mirror.gd")
const RoachS = preload("res://scripts/roach.gd")

const MIRROR_CENTER := Vector3(8.25, 1.75, 0.03)

static func build(m, root: Node3D) -> void:
	var tile := Mats.get_mat("tile")
	var tfloor := Mats.get_mat("tile_floor")
	var conc := Mats.get_mat("concrete")
	var paint := Mats.solid(Color(0.17, 0.27, 0.21), 0.5)
	var rust := Mats.get_mat("rust")
	var ch := Props.chrome()
	var dark_hair := Color(0.05, 0.035, 0.025)

	WB.slab(root, Vector3(4.0, -0.2, -0.2), Vector3(12.2, 0, 8.2), tfloor)
	WB.slab(root, Vector3(4.0, 3.0, -0.2), Vector3(12.2, 3.2, 8.2), conc)
	var north := WB.slab(root, Vector3(4.0, 0, -0.2), Vector3(12.2, 3, 0.0), tile)
	north.layers = MirrorS.LAYER_MAIN_ONLY      # 镜像摄像机要透过这面墙"看"进房间
	WB.slab(root, Vector3(4.0, 0, 8.0), Vector3(12.2, 3, 8.2), tile)
	WB.slab(root, Vector3(12.0, 0, -0.2), Vector3(12.2, 3, 8.2), tile)

	# 西墙(与大厅共用)的厕所一侧也贴上瓷砖,门洞处留空
	WB.slab(root, Vector3(4.2, 0, 0.0), Vector3(4.25, 3, 3.0), tile, false)
	WB.slab(root, Vector3(4.2, 0, 5.0), Vector3(4.25, 3, 8.0), tile, false)
	WB.slab(root, Vector3(4.2, 2.4, 3.0), Vector3(4.25, 3, 5.0), tile, false)

	# 日光灯(狂闪)
	var cold := Color(0.75, 0.98, 0.85)
	WB.lamp(root, Vector3(6.5, 2.95, 2.5), cold, 1.6, 0.35, 0.6, Vector3(1.2, 0.06, 0.2))
	WB.lamp(root, Vector3(9.5, 2.95, 5.5), cold, 1.4, 0.35, 0.5, Vector3(1.2, 0.06, 0.2))

	# 管道
	var p1 := WB.cyl(root, Vector3(8.2, 2.75, 0.3), 0.06, 7.8, rust, false)
	p1.rotation.z = deg_to_rad(90.0)
	WB.cyl(root, Vector3(4.5, 1.5, 0.3), 0.05, 3.0, rust, false)
	WB.cyl(root, Vector3(11.7, 1.5, 7.7), 0.05, 3.0, rust, false)

	# 积水、地漏、垃圾桶
	var water := StandardMaterial3D.new()
	water.albedo_color = Color(0.1, 0.14, 0.15, 0.7)
	water.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	water.roughness = 0.05
	water.metallic = 0.5
	WB.slab(root, Vector3(6.0, 0.0, 4.2), Vector3(8.4, 0.01, 6.0), water, false)
	Props.floor_drain(root, Vector3(7.2, 0, 5.1))
	Props.trash_can(root, Vector3(5.0, 0, 7.3))
	_build_closet(m, root)
	Letters.spawn(m, root, 1, Vector3(5.0, 0.66, 7.25), 0.0, "flat", Vector3(0.45, 0.3, 0.45))     # 来信 2:被扔在垃圾桶顶上

	# ---- 洗手台 ×3 ----
	var sink_x := [6.4, 8.25, 10.1]
	for x in sink_x:
		Props.sink(root, Vector3(x, 0, 0.0))
		var ti := WB.inter(root, Vector3(x, 1.15, 0.17), Vector3(0.5, 0.35, 0.4), "拧开水龙头", func(): _tap(m))
		ti.prompt_fn = func():
			return "冲洗钥匙" if GS.has_item("hair_key_dirty") else "拧开水龙头"

	# ---- 镜子 ----
	var mirror = MirrorS.new()
	root.add_child(mirror)
	mirror.setup(m.player, MIRROR_CENTER, Vector2(5.0, 1.25))
	m.mirror = mirror
	var frame := Mats.solid(Color(0.1, 0.08, 0.06), 0.6)
	for fr in [
		[Vector3(5.72, 1.08, 0.0), Vector3(10.78, 1.14, 0.07)],
		[Vector3(5.72, 2.36, 0.0), Vector3(10.78, 2.42, 0.07)],
		[Vector3(5.72, 1.08, 0.0), Vector3(5.78, 2.42, 0.07)],
		[Vector3(10.72, 1.08, 0.0), Vector3(10.78, 2.42, 0.07)],
	]:
		var fm := WB.slab(root, fr[0], fr[1], frame, false)
		fm.layers = MirrorS.LAYER_MAIN_ONLY
	var mi = WB.inter(root, Vector3(8.25, 1.95, 0.2), Vector3(5.0, 0.95, 0.3), "查看镜子", Callable())
	mi.action = func():
		if GS.has_flag("mirror_event_done"):
			UI.toast("镜子已经碎了。镜框里只剩锯齿状的玻璃。\n(打碎它的,大概是一位有容貌焦虑的科学家鬼魂。很合理。)", 3.0)
			return
		if not GS.has_flag("statue_awakened"):
			UI.toast("镜面蒙着厚厚的灰,什么也照不出来。\n(先看看大厅里有什么。)", 3.5)
			return
		_mirror_event(m, root, mirror, mi)
	if GS.has_flag("mirror_event_done"):
		mirror.set_broken_instant()
		if not GS.has_flag("got_mirror_shard"):
			_spawn_shard_pickup(m, root)

	# 洗手池 1 号里堵着的头发
	var hair_nodes: Array = []
	if not GS.has_flag("sink_hair_removed"):
		hair_nodes.append(Props.hair_clump(root, Vector3(6.4, 0.84, 0.27), 0.1, 45, dark_hair))
	var hi = WB.inter(root, Vector3(6.4, 0.9, 0.26), Vector3(0.5, 0.1, 0.4), "", Callable())
	hi.prompt_fn = func():
		if GS.has_flag("sink_hair_removed"):
			return ""
		return "用镊子夹出头发" if GS.has_item("tweezers") else "查看堵塞的排水口"
	hi.action = func():
		if GS.has_flag("sink_hair_removed"):
			return
		if not GS.has_item("tweezers"):
			UI.toast("排水口被一团湿漉漉的头发堵住了。\n徒手?算了。需要个工具把它夹出来。", 4.0)
			return
		for h in hair_nodes:
			h.queue_free()
		GS.set_flag("sink_hair_removed")
		m.give_item("hair_key_dirty", "你用镊子从头发里夹出一把裹满污垢的钥匙。\n得找水龙头冲一冲。")

	# ---- 隔间 ----
	var zs := [1.2, 2.8, 4.4, 6.0, 7.6]
	for z in zs:
		WB.slab(root, Vector3(10.0, 0.25, z - 0.04), Vector3(12.0, 2.2, z + 0.04), paint)
	var water_cols := [Color(0.16, 0.1, 0.04), Color(0.12, 0.16, 0.18), Color(0.12, 0.16, 0.18), Color(0.12, 0.16, 0.18)]
	for i in 4:
		var zc: float = (zs[i] + zs[i + 1]) * 0.5
		Props.toilet(root, Vector3(11.6, 0, zc), 90.0, i == 1 or i == 3, water_cols[i])
		if i < 3:
			Props.toilet_paper(root, Vector3(11.93, 0.85, zc - 0.55))
		var d := WB.door(root, Vector3(10.0, 0.25, zs[i + 1] - 0.05), 90.0, 180.0, 1.5, 1.95, paint)
		WB.box(d, Vector3(1.36, 1.0, 0.075), Vector3(0.12, 0.05, 0.03), ch, false)                       # 插销
		WB.box(d, Vector3(1.36, 1.0, 0.093), Vector3(0.04, 0.03, 0.01), Mats.emissive(Color(0.9, 0.1, 0.05), 1.2), false)
		var di = d.add_inter(1.5, 1.95, "", Callable())
		var idx := i + 1
		di.prompt_fn = func():
			return L.f("关上 {n} 号隔间门" if d.is_open else "推开 {n} 号隔间门", {"n": idx})
		di.action = func():
			d.set_open(not d.is_open)
			SFX.play("door", -4.0)

	# 1 号:堵死的马桶,头发漫过碗沿
	Props.hair_clump(root, Vector3(11.4, 0.4, 2.0), 0.13, 80, dark_hair)
	for i in 10:
		var rim := Props.hair_clump(root, Vector3(11.3 + randf_range(-0.12, 0.1), 0.3 + randf() * 0.1, 2.0 + randf_range(-0.2, 0.2)), 0.03, 4, dark_hair)
		rim.rotation.z = randf_range(-1.0, 1.0)
	WB.inter(root, Vector3(11.4, 0.5, 2.0), Vector3(0.9, 0.7, 0.8), "查看马桶", func():
		UI.toast("马桶被一大团头发堵死了。\n每 40 天,这里就会堵一次。", 4.0))

	# 2 号:蟑螂窝 + 喷雾
	if not GS.has_flag("spray_stall"):
		WB.cyl(root, Vector3(11.85, 1.08, 3.6), 0.04, 0.2, Mats.emissive(Color(0.3, 0.8, 0.35), 0.8), false)
	var si = WB.inter(root, Vector3(11.85, 1.08, 3.6), Vector3(0.5, 0.5, 0.5), "拿走水箱上的喷雾瓶", Callable())
	si.action = func():
		if GS.has_flag("spray_stall"):
			return
		GS.set_flag("spray_stall")
		si.enabled = false
		m.give_item("hair_tonic_spray", "", "spray_stall")
	if GS.has_flag("spray_stall"):
		si.enabled = false

	# 3 号:涂鸦
	var blood := Node3D.new()
	blood.set_script(preload("res://scripts/blood_text.gd"))
	blood.position = Vector3(11.935, 1.28, 5.2)
	blood.rotation_degrees.y = -90.0
	blood.set("width", 1.15)
	root.add_child(blood)
	WB.inter(root, Vector3(11.7, 1.4, 5.2), Vector3(0.5, 0.9, 1.2), "查看墙上的字", func():
		UI.toast("墙上用血写着:“HE IS STILL IN HERE.”\n……字迹还没干透。", 3.5))

	# 4 号:撕碎的合照
	var paper := Mats.solid(Color(0.85, 0.8, 0.65))
	var pieces: Array = []
	if not GS.has_flag("got_photo_pieces"):
		for i in 6:
			var pc := WB.box(root, Vector3(10.9 + (i % 3) * 0.25, 0.02, 6.5 + int(i / 3) * 0.3), Vector3(0.18, 0.01, 0.16), paper, false)
			pc.rotation.y = randf() * TAU
			pieces.append(pc)
	var pi = WB.inter(root, Vector3(11.15, 0.15, 6.7), Vector3(1.0, 0.3, 0.9), "捡起撕碎的照片", Callable())
	pi.action = func():
		if GS.has_flag("got_photo_pieces"):
			return
		for p in pieces:
			p.queue_free()
		pi.enabled = false
		m.give_item("photo_pieces", "地上散落着撕碎的合照。")
	if GS.has_flag("got_photo_pieces"):
		pi.enabled = false

	_decorate(root)

	# ---- 蟑螂 ----
	for i in 14:
		var holder = RoachS.new()
		if i < 5:
			holder.position = Vector3(randf_range(10.9, 11.7), 0.0, randf_range(3.2, 4.0))
		else:
			holder.position = Vector3(randf_range(5.0, 11.5), 0.0, randf_range(0.9, 7.5))
		root.add_child(holder)
		Props.roach(holder)

static func _tap(m) -> void:
	SFX.play("water")
	if GS.has_item("hair_key_dirty"):
		GS.remove_item("hair_key_dirty")
		m.give_item("office_key", "你用水冲掉了钥匙上的污垢。\n柄上刻着“博士办公室”。")
	else:
		UI.toast("水龙头流出一股发黄的水。生发剂味。\n……你的手背,好像有点痒。", 2.5)

static func _spawn_shard_pickup(m, root: Node3D) -> void:
	var glass := Mats.solid(Color(0.7, 0.88, 0.95), 0.05, 0.9)
	var sh := WB.box(root, Vector3(8.25, 0.0 + 0.96, 0.4), Vector3(0.12, 0.02, 0.2), glass, false)
	sh.rotation.y = 0.6
	var si = WB.inter(root, Vector3(8.25, 0.98, 0.4), Vector3(0.5, 0.3, 0.5), "捡起镜子碎片", Callable())
	si.action = func():
		if GS.has_flag("got_mirror_shard"):
			return
		sh.queue_free()
		si.enabled = false
		m.give_item("mirror_shard", "锋利的碎片。也许能派上用场。")

## 清洁工具柜:靠南墙,门朝北。被修女追进来时可以躲进去。
static func _build_closet(m, root: Node3D) -> void:
	var mt := Mats.solid(Color(0.32, 0.36, 0.3), 0.55, 0.45)
	var x0 := 6.2
	var x1 := 7.1
	WB.slab(root, Vector3(x0, 0, 7.95), Vector3(x1, 2.1, 8.0), mt, false)           # 背板
	WB.slab(root, Vector3(x0 - 0.05, 0, 7.15), Vector3(x0, 2.1, 8.0), mt, false)    # 左侧板
	WB.slab(root, Vector3(x1, 0, 7.15), Vector3(x1 + 0.05, 2.1, 8.0), mt, false)    # 右侧板
	WB.slab(root, Vector3(x0 - 0.05, 2.05, 7.15), Vector3(x1 + 0.05, 2.1, 8.0), mt, false)
	# 门框(包住百叶两端,避免穿模)+ 百叶门:能从缝里往外看
	var fr := Mats.solid(Color(0.27, 0.31, 0.26), 0.55, 0.45)
	WB.slab(root, Vector3(x0 - 0.05, 0, 7.11), Vector3(x0 + 0.05, 2.1, 7.2), fr, false)
	WB.slab(root, Vector3(x1 - 0.05, 0, 7.11), Vector3(x1 + 0.05, 2.1, 7.2), fr, false)
	WB.slab(root, Vector3(x0 + 0.05, 1.98, 7.11), Vector3(x1 - 0.05, 2.1, 7.2), fr, false)
	WB.slab(root, Vector3(x0 + 0.05, 0, 7.11), Vector3(x1 - 0.05, 0.1, 7.2), fr, false)
	for i in 5:
		var y0 := 0.14 + i * 0.37
		WB.slab(root, Vector3(x0 + 0.05, y0, 7.14), Vector3(x1 - 0.05, y0 + 0.24, 7.18), mt, false)
	WB.slab(root, Vector3(6.92, 0.95, 7.07), Vector3(6.97, 1.1, 7.11), Props.chrome(), false)   # 把手
	PT.make(root, Vector3(6.65, 2.04, 7.105), 180.0, "清洁工具", "stencil", 0.5, Color(0.85, 0.82, 0.7), "stencil", 120, 0.25)
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.position = Vector3(6.65, 1.05, 7.58)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.95, 2.1, 0.85)
	cs.shape = sh
	sb.add_child(cs)
	root.add_child(sb)
	var ci := WB.inter(root, Vector3(6.65, 1.0, 6.95), Vector3(0.9, 2.0, 0.4), "躲进清洁工具柜", Callable())
	ci.action = func():
		m.player.enter_hide(
			Vector3(6.65, 0, 7.6), 0.0, Vector3(6.65, 0, 6.6),
			func(): cs.set_deferred("disabled", true),
			func(): cs.set_deferred("disabled", false))
		SFX.play("door", -8.0)

static func _mirror_event(m, root: Node3D, mirror, mi: Area3D) -> void:
	GS.set_flag("mirror_event_done")
	mi.enabled = false
	var player = m.player
	player.locked = true
	player.face_point(MIRROR_CENTER)
	mirror.lag = true
	UI.toast("镜子里的你,慢了半拍。", 2.4)
	await m.get_tree().create_timer(1.3).timeout
	mirror.flicker_preview()          # 1~2 帧的闪现
	await m.get_tree().create_timer(0.9).timeout
	mirror.show_bald()
	SFX.play("sting")
	UI.flash(Color(1, 1, 1, 0.3), 0.3)
	player.shake(0.5, 0.03)
	await m.get_tree().create_timer(1.3).timeout
	mirror.lunge(0.3)
	SFX.play("thump")
	await m.get_tree().create_timer(0.32).timeout
	mirror.shatter()
	SFX.play("glass")
	UI.flash(Color(1, 1, 1, 0.6), 0.4)
	player.shake(0.5, 0.05)
	var glass := Mats.solid(Color(0.7, 0.88, 0.95), 0.05, 0.9)
	for i in 14:
		var rb := RigidBody3D.new()
		rb.collision_layer = 0
		rb.collision_mask = 1
		var cs := CollisionShape3D.new()
		var sh := BoxShape3D.new()
		sh.size = Vector3(0.1, 0.02, 0.1)
		cs.shape = sh
		rb.add_child(cs)
		WB.box(rb, Vector3.ZERO, Vector3(0.1, 0.02, 0.1), glass, false)
		rb.position = Vector3(8.25 + randf_range(-2.2, 2.2), 1.3 + randf() * 0.8, 0.4)
		rb.linear_velocity = Vector3(randf_range(-1, 1), 0.5, randf_range(0.5, 2.0))
		root.add_child(rb)
		m.get_tree().create_timer(5.0).timeout.connect(rb.queue_free)
	_spawn_shard_pickup(m, root)
	UI.say([
		"镜子里的人,不是你。",
		"是一个秃头的男人。",
		"他在笑。",
	], func(): player.locked = false)


## 墙面老化、水渍、设备、滴水、地面裂缝
static func _decorate(root: Node3D) -> void:
	var mold := Color(0.08, 0.16, 0.06, 0.75)
	var rustc := Color(0.35, 0.16, 0.06, 0.7)
	var damp := Color(0.12, 0.09, 0.04, 0.55)
	# 霉斑
	Props.stain(root, Vector3(6.0, 0.7, 7.97), Vector2(1.6, 1.2), mold, 180.0)
	Props.stain(root, Vector3(9.0, 2.3, 7.97), Vector2(1.2, 0.9), mold, 180.0)
	Props.stain(root, Vector3(4.23, 0.5, 6.4), Vector2(1.4, 1.0), mold, 90.0)
	Props.stain(root, Vector3(11.98, 2.5, 3.0), Vector2(1.0, 0.8), mold, -90.0)
	# 管道下的锈水痕(竖长)
	Props.stain(root, Vector3(4.5, 0.9, 0.35), Vector2(0.3, 1.6), rustc, 0.0)
	Props.stain(root, Vector3(11.3, 1.9, 0.31), Vector2(0.4, 1.2), rustc, 0.0)
	Props.stain(root, Vector3(11.6, 0.8, 7.7), Vector2(0.3, 1.8), rustc, 180.0)
	# 天花板渗水
	for c in [Vector3(5.5, 2.99, 1.5), Vector3(9.5, 2.99, 3.0), Vector3(7.0, 2.99, 6.5), Vector3(11.0, 2.99, 6.5)]:
		Props.stain(root, c, Vector2(2.2, 1.8), damp, 0.0, true)
	# 掉了瓷砖的墙面(露出黑色水泥)
	var bare := Mats.solid(Color(0.05, 0.05, 0.05), 1.0)
	for pos in [Vector3(4.2, 1.1, 2.2), Vector3(4.2, 1.5, 6.8), Vector3(12.0, 1.0, 6.2)]:
		var sx := 1.0 if pos.x < 5.0 else -1.0
		WB.box(root, pos + Vector3(sx * 0.005, 0, 0), Vector3(0.012, 0.36, 0.34), bare, false)
	for pos in [Vector3(6.0, 1.3, 7.99), Vector3(10.5, 0.9, 7.99)]:
		WB.box(root, pos, Vector3(0.34, 0.3, 0.012), bare, false)
	# 墙面设备
	Props.soap_dispenser(root, Vector3(7.3, 1.2, 0.07))
	Props.soap_dispenser(root, Vector3(9.15, 1.2, 0.07))
	Props.towel_dispenser(root, Vector3(5.1, 1.35, 0.1))
	Props.hand_dryer(root, Vector3(11.3, 1.3, 0.12))
	# 拖把桶(墙角)
	Props.mop_bucket(root, Vector3(4.65, 0.0, 0.7))
	# 滴水:第三个水龙头、天花板管道
	Props.drip(root, Vector3(10.1, 1.07, 0.2))
	Props.drip(root, Vector3(8.2, 2.7, 0.55))
	# 通风格栅
	var gm := Mats.solid(Color(0.1, 0.1, 0.1), 0.5, 0.5)
	WB.box(root, Vector3(6.5, 2.97, 6.5), Vector3(0.6, 0.03, 0.4), gm, false)
	for i in 6:
		WB.box(root, Vector3(6.5, 2.95, 6.35 + i * 0.06), Vector3(0.56, 0.01, 0.015), Mats.solid(Color(0.35, 0.35, 0.35), 0.4, 0.7), false)
	# 地面:裂缝、散落的头发和卷纸
	var crack := Mats.solid(Color(0.02, 0.02, 0.02), 1.0)
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	for i in 6:
		var c := WB.box(root, Vector3(rng.randf_range(5.0, 9.5), 0.003, rng.randf_range(1.5, 7.0)), Vector3(rng.randf_range(0.6, 1.4), 0.002, 0.012), crack, false)
		c.rotation.y = rng.randf_range(0, PI)
	for i in 5:
		Props.hair_clump(root, Vector3(rng.randf_range(5.0, 10.0), 0.02, rng.randf_range(1.0, 7.5)), 0.05, 10, Color(0.05, 0.035, 0.025))
	var tp := Mats.solid(Color(0.9, 0.88, 0.8), 0.95)
	for i in 5:
		var s := WB.box(root, Vector3(rng.randf_range(5.0, 9.5), 0.006, rng.randf_range(1.0, 7.5)), Vector3(0.22, 0.004, 0.12), tp, false)
		s.rotation.y = rng.randf() * TAU
