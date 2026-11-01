extends Node3D
## 游戏流程:标题 → 序幕 → 游玩(检查点/重试)→ 结局。

const WB = preload("res://scripts/wb.gd")
const Humanoid = preload("res://scripts/humanoid.gd")
const Person = preload("res://scripts/person.gd")
const Mats = preload("res://scripts/mats.gd")
const PlayerS = preload("res://scripts/player.gd")
const Hall = preload("res://scripts/rooms/hall.gd")
const Restroom = preload("res://scripts/rooms/restroom.gd")
const Office = preload("res://scripts/rooms/office.gd")
const Lab = preload("res://scripts/rooms/lab.gd")
const Letters = preload("res://scripts/letters.gd")

const INTRO := [
	"【调查委托 #0417】\n\n委托人:柳湾镇镇长(本人已秃)。\n\n现象:三个月内,全镇八成居民开始掉头发。\n镇上唯一的理发店,已经改行卖帽子了。",
	"水样检测:河水里有大量米诺地尔——一种本来让人“长”头发的药。\n\n镇长在电话里的原话:\n“那为什么我们全秃了?!”",
	"排放源:上游,河边一座废弃的实验室——Cliché Lab。",
	"附注:镇上还有个七岁的小女孩,长出了一撇小胡子。\n\n镇上传得很玄乎:说她刚出生时,爸妈分不清她是男是女,干脆抛了枚硬币,决定怎么养她。\n(该说法未经证实。)",
	"你是 Veronica,环境调查员。\n你的任务:找到排放源,让它停下来。",
]

const BOSS_LINES := [
	"弟子1号|我的老师……他有什么错?",
	"弟子1号|错的是这个世界。这个世界,糟糕透了。",
	"弟子1号|2000 年。我还是个学生。压力大到,头发一把一把地掉。",
	"弟子1号|我向喜欢的女孩表白。她说——她接受不了爷孙恋。",
	"弟子1号|……我有那么显老吗?!",
	"弟子1号|我躲起来研究生发剂。好不容易遇到了老师……可这个世界,连他也带走了。",
	"弟子1号|所以,我要让所有人都变得和我们一样。这才公平。",
	"弟子1号|(他慢慢转过头,盯着你)……你的头发,很多啊。",
]

const EPILOGUE := [
	"上游不再排放。河水一天天清了。\n全镇的头发,又掉了最后一次——然后,真的长回来了。",
	"弟子1号带着完美生发剂,挨家挨户地送。\n这一次,一滴都没有排进河里。",
	"清晨的河边,偶尔有人看见一个中年男人的影子,\n认真地摆正了一块牌子:\n“洗完澡,请清理水槽。”",
	"理发店把“帽子店”的招牌摘了下来。\n那个长胡子的小女孩,还是每天在河边抛她的硬币。",
	"镇子,恢复了往日的平静。",
]

## 收齐 5 封镇民来信时,尾声里多出的一页
const LETTERS_EPILOGUE := "你把那封一直没人拆的信,还给了小女孩的妈妈。\n她看了很久,然后说:\n“那你能不能帮我跟镇上的人说一声——我们真的没抛过硬币。”"

## 开局自动弹出的水样检测报告(科普:为什么米诺地尔会同时导致长毛和脱发)
const WATER_REPORT := [
	"[b]水样检测报告 · 附录 B[/b]\n委托 #0417 · 柳湾镇\n\n检出物:米诺地尔(Minoxidil),超标约 2000 倍。\n\n米诺地尔原本是一种口服降压药。医生发现,吃药的病人汗毛越长越多,于是把它改成了外用生发水。\n\n已知特性:\n① 刚开始用,会先把旧头发顶掉;\n② 一旦停用,靠它长出来的头发,几个月内全部掉回去;\n③ 不挑地方。头发、眉毛、胡子,一视同仁;\n④ 小孩对它特别敏感。",
	"[b]结论[/b]\n\n柳湾镇的人掉头发,不是因为水里“有”米诺地尔,而是因为它“时有时无”。\n\n排放记录:上游大约每 40 天排一次。排的时候,全镇头发疯长;一停,就整片整片地掉。一次比一次严重。\n\n那个七岁的女孩,家离排污口最近,个子最小,喝的井水最多——所以她身上,“长”赢过了“掉”。\n至于抛硬币的传言:和米诺地尔无关。大概。\n\n[i]另:镇长说,这几个月镇上很多人给实验室写过信,一封回音都没有。[/i]",
]

const DIARY := [
	"[b]2023.11.20[/b]\n\nSarah 又发火了。\n她说我洗完澡从来不清理水槽,下水道这个月第三次被我的头发堵死了。\n她拎着一团湿漉漉的头发站在浴室门口:“你掉的头发,比你在这个家待的时间还多。”\n\n我说我会注意的。\n我没有。",
	"[b]2024.1.3[/b]\n\nSarah 走了。冰箱上留了张字条:\n“下水道又堵了。我受够了。farewell。我要去和一个光头结婚。”\n\n十五年。原来十五年的婚姻,输给了一团头发。\n\n我把实验室的门锁密码,改成了今天。\n这样我每天进门,都得想一遍她是哪天走的。",
	"[b]2024.8.3[/b]\n\n我查遍了文献,找到了它:米诺地尔。\n本来是降压药,病人吃了会长毛。多么优雅的副作用。\n\n只要改改配方、申请专利,我的头发和我的财富,就会一起蓬勃生长。\nSarah 会回来的。",
	"[b]2025.3.14[/b]\n\n值得铭记的一天。第一版配方完成。诺贝尔奖,我来了。\nScrew you, Sarah.\n\n我在一个只要交钱就能发论文的网站上,认识了一个年轻人。他也秃,也焦虑,也被这个世界嫌弃。\n我叫他弟子1号。我们会一起证明:秃头,不是我们的错。",
	"[b]2025.8.13[/b]\n\n不对劲。\n头发在长,可别的地方也在长。手背、后颈、耳朵里。今天早上,我的眉毛和鬓角连成了一片。\n弟子1号说这是“副作用”。不,这是嘲笑。\n\n停用一段时间吧。",
	"[b]2025.12.1[/b]\n\n停用三个月。头发比用药前还少。\n枕头上、下水道里、水槽里,到处都是。\n\n这一批废液,和以前一样,从后门旁边的排污阀放进了河里。\n每次拧开它,我都跟自己说:最后一次。",
	"[b]2026.3.15[/b]\n\n积蓄见底了。\n配方改到第 17 版,我终于知道缺的是什么:抑毛因子-K。有了它,头发只会长在该长的地方。\n可我已经没力气再试了。前四样加起来是 95 份,总量必须是 100——剩下的,就是它。\n\n今天在街上遇见了 Sarah,用着我的赡养费。她身边那个男人,光头,亮得能反光,胳膊比我的腿还粗。\n她看了我一眼。就一眼。然后笑了。\n\n我恨她。我更恨镜子里的我。\n\n留给这个世界最后一句话:\n[b]“Remember to clean the sink after you shower.”[/b]",
]

var world: Node3D = null
var player = null
var statue = null
var boss = null
var mirror = null
var env: Environment = null
var playing := false
var radio_active := false
var radio_t := 0.0
var ending_started := false

func _ready() -> void:
	_setup_env()
	add_child(preload("res://scripts/retro.gd").new())
	UI.title_new.connect(new_game)
	UI.title_continue.connect(continue_game)
	UI.retry_requested.connect(retry)
	UI.quit_to_title.connect(to_title)
	to_title()

func _setup_env() -> void:
	var we := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.01, 0.01, 0.015)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.22, 0.24, 0.28)
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.fog_enabled = true
	e.fog_light_color = Color(0.04, 0.05, 0.05)
	e.fog_density = 0.035
	e.glow_enabled = not OS.has_feature("web")     # 网页版(WebGL)上 Godot 4.3 的辉光会把画面整个搞坏,关掉
	e.glow_intensity = 0.6
	e.glow_bloom = 0.1
	e.adjustment_enabled = true
	e.adjustment_saturation = 0.82
	e.adjustment_contrast = 1.1
	e.ssao_enabled = not OS.has_feature("web")
	we.environment = e
	env = e
	add_child(we)

# ===================== 流程 =====================
func to_title() -> void:
	get_viewport().disable_3d = false
	playing = false
	get_tree().paused = false
	SFX.loop("drone", false)
	SFX.loop("static", false)
	SFX.loop("heart", false)
	radio_active = false
	_free_world()
	UI.show_title(GS.has_save())

func _free_world() -> void:
	if world != null:
		world.free()
		world = null
	player = null
	statue = null
	boss = null
	mirror = null

func _apply_dark_env() -> void:
	env.background_mode = Environment.BG_COLOR
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.22, 0.24, 0.28)
	env.ambient_light_energy = 0.35
	env.fog_light_color = Color(0.04, 0.05, 0.05)
	env.fog_density = 0.035

func _apply_dawn_env() -> void:
	var sky := Sky.new()
	var pm := ProceduralSkyMaterial.new()
	pm.sky_top_color = Color(0.32, 0.48, 0.78)
	pm.sky_horizon_color = Color(1.0, 0.72, 0.5)
	pm.ground_horizon_color = Color(0.9, 0.62, 0.45)
	pm.ground_bottom_color = Color(0.25, 0.22, 0.18)
	pm.sun_angle_max = 25.0
	sky.sky_material = pm
	env.sky = sky
	env.background_mode = Environment.BG_SKY
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.55
	env.fog_light_color = Color(1.0, 0.78, 0.6)
	env.fog_density = 0.0025

func _build_world() -> void:
	_apply_dark_env()
	_free_world()
	ending_started = false
	world = Node3D.new()
	add_child(world)
	player = PlayerS.new()
	world.add_child(player)
	player.position = Vector3(0, 0, 11)
	player.inventory_requested.connect(open_inventory)
	player.heal_requested.connect(heal)
	player.gun_clicked.connect(_on_gun)
	player.died.connect(_on_died)
	Hall.build(self, world)
	Restroom.build(self, world)
	Office.build(self, world)
	Lab.build(self, world)
	statue.player = player
	boss.player = player
	if GS.has_flag("boss_intro_done") and not GS.has_flag("game_completed"):
		boss.spawn_at(Vector3(0, 0, -14.5))
		boss.begin_patrol()
	if OS.has_feature("web") or OS.get_environment("WEB_CULL") == "1":
		var wc := preload("res://scripts/web_cull.gd").new()
		world.add_child(wc)
		wc.setup(world, player)

func new_game() -> void:
	GS.reset()
	UI.hide_title()
	_build_world()
	player.locked = true
	SFX.loop("drone", true, -14.0)
	get_viewport().disable_3d = true          # 序幕是全黑的文字画面:这时不渲染 3D 场景,打字不卡
	UI.show_intro(INTRO, func():
		get_viewport().disable_3d = false
		GS.add_item("water_report")
		_begin_play()
		UI.open_reader("水样检测报告", WATER_REPORT))

func continue_game() -> void:
	if not GS.load_disk():
		return
	UI.hide_title()
	_build_world()
	player.global_position = GS.checkpoint["pos"]
	player.set_yaw(GS.checkpoint["yaw"])
	SFX.loop("drone", true, -14.0)
	_begin_play(false)

func retry() -> void:
	if not GS.restore_checkpoint():
		GS.reset()
	_build_world()
	if GS.checkpoint.has("pos"):
		player.global_position = GS.checkpoint["pos"]
		player.set_yaw(GS.checkpoint["yaw"])
	_begin_play(false)

func _begin_play(fresh: bool = true) -> void:
	player.locked = false
	player.dead = false
	UI.set_hud_visible(true)
	UI.capture_mouse()
	playing = true
	if fresh:
		checkpoint()
		UI.toast("左边拖动摇杆移动 · 右边拖动转视角 · 红色大按钮互动" if Touch.enabled else "WASD 移动 · Shift 奔跑 · E 互动 · F 手电 · Tab 背包", 5.0)
	UI.fade_to(0.0, 0.01)

func checkpoint() -> void:
	if player != null:
		GS.save_checkpoint(player.global_position, player.yaw)

func _on_died() -> void:
	playing = false
	UI.show_gameover()

var _dbg_room := 0

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if playing and not UI.blocked():
				UI.show_pause()
		elif OS.is_debug_build() and playing and player != null:
			_debug_key(event.keycode)

## 调试键(仅在编辑器里运行时有效):F2 传送到下一个房间;F3 获得关键道具并开门;F4 解锁配方知识;F5 恢复满血
func _debug_key(k: int) -> void:
	match k:
		KEY_F2:
			var spots := [Vector3(0, 0, 10), Vector3(8, 0, 3), Vector3(-6, 0, 0), Vector3(0, 0, -11.5)]
			_dbg_room = (_dbg_room + 1) % spots.size()
			player.global_position = spots[_dbg_room]
		KEY_F3:
			for id in ["tweezers", "lab_keycard", "office_key", "doctor_diary", "hollow_revolver"]:
				GS.add_item(id)
			for f in ["got_tweezers", "statue_awakened", "statue_defeated", "got_lab_keycard", "restroom_open"]:
				GS.set_flag(f)
			UI.toast("[调试] 已获得关键道具。重新开始/读档后门会保持开启。", 3.0)
		KEY_F4:
			GS.set_flag("formula_known")
			UI.toast("[调试] 已知配方。", 2.0)
		KEY_F5:
			GS.heal(5)

# ===================== 物品 =====================
func give_item(id: String, msg: String = "", flag: String = "") -> void:
	GS.add_item(id)
	GS.set_flag(flag if flag != "" else "got_" + id)
	SFX.play("pickup")
	var t: String = L.t("获得:") + L.t(GS.ITEMS[id]["name"])
	if msg != "":
		t = L.t(msg) + "\n" + t
	UI.toast(t, 4.0)

func open_inventory() -> void:
	UI.open_inventory(use_item)

func use_item(id: String) -> void:
	match id:
		"doctor_diary":
			UI.open_reader("博士的日记", DIARY)
		"water_report":
			UI.open_reader("水样检测报告", WATER_REPORT)
		"town_letters":
			UI.open_reader(L.f("镇民来信 {n}/{t}", {"n": Letters.collected(), "t": Letters.COUNT}), Letters.pages())
		"photo_pieces":
			UI.open_photo_puzzle(func():
				GS.remove_item("photo_pieces")
				GS.add_item("photo_whole")
				GS.set_flag("photo_assembled")
				UI.toast("合照拼好了。背面写着:Sarah 生日快乐 · 2021.2.3", 5.0))
		"photo_whole":
			UI.open_reader("合照", ["[center]照片上,一个笑得有点腼腆的男人,搂着一位笑得很甜的女人。\n\n[b]背面[/b]\nSarah 生日快乐 · 2021.2.3[/center]"])
		"hair_tonic_spray":
			heal()

func heal() -> void:
	if not GS.has_item("hair_tonic_spray"):
		return
	if GS.hp >= GS.MAX_HP:
		UI.toast("状态良好,现在不需要。", 2.0)
		return
	GS.remove_item("hair_tonic_spray")
	GS.heal(2)
	SFX.play("pickup")
	UI.toast("你喷了一下。头皮一阵发痒,但精神好多了。", 3.0)

func _on_gun(pos: Vector3) -> void:
	if boss != null:
		boss.hear(pos)

# ===================== 收音机事件 =====================
func radio_event() -> void:
	if GS.has_flag("radio_event_done") or radio_active:
		return
	radio_active = true
	radio_t = 1.5
	SFX.loop("static", true, -10.0)
	get_tree().call_group("lamps", "pulse_off", 0.8)
	UI.toast("办公室里的灯开始闪烁。角落里的收音机,自己打开了。", 4.0)

func _process(delta: float) -> void:
	if radio_active and player != null:
		radio_t -= delta
		if radio_t <= 0.0:
			radio_t = 6.0
			UI.toast("收音机(断断续续):\n“Remember to clean the sink after you shower.”", 4.5)
			SFX.play("glitch")
			get_tree().call_group("lamps", "pulse_off", 0.3)
		if player.global_position.x > -4.0:
			radio_active = false
			SFX.loop("static", false)
			GS.set_flag("radio_event_done")
			checkpoint()

# ===================== Boss =====================
func on_lab_enter() -> void:
	if not GS.has_flag("lab_unlocked") or GS.has_flag("boss_intro_done"):
		return
	checkpoint()
	start_boss_intro()

func start_boss_intro() -> void:
	GS.set_flag("boss_intro_done")
	player.locked = true
	get_tree().call_group("lamps", "set_blackout", true)
	SFX.play("sting")
	await get_tree().create_timer(1.3).timeout
	get_tree().call_group("lamps", "set_blackout", false)
	boss.spawn_at(Vector3(0, 0, -22.5))
	boss.rotation.y = PI
	player.face_point(Vector3(0, 1.6, -22.5))
	SFX.play("shriek", -4.0)
	UI.flash(Color(0.8, 0.0, 0.0, 0.35), 0.5)
	UI.say(BOSS_LINES)
	await UI.dialogue_finished
	player.locked = false
	boss.begin_chase()

func _say_wait(lines: Array) -> void:
	UI.say(lines)
	await UI.dialogue_finished

func _set_ghost_alpha(n: Node, a: float) -> void:
	if n is MeshInstance3D and n.material_override is StandardMaterial3D:
		var m: StandardMaterial3D = n.material_override
		if m.transparency == BaseMaterial3D.TRANSPARENCY_ALPHA:
			m.albedo_color.a = a * 0.6
	for c in n.get_children():
		_set_ghost_alpha(c, a)

func _ghostify(n: Node) -> void:
	if n is MeshInstance3D and n.material_override is StandardMaterial3D:
		var m: StandardMaterial3D = n.material_override
		if m.transparency != BaseMaterial3D.TRANSPARENCY_ALPHA:
			n.material_override = Mats.ghostly(m.albedo_color.lerp(Color(0.6, 0.8, 1.0), 0.5), 0.6)
	for c in n.get_children():
		_ghostify(c)

func _yaw_toward(from: Vector3, to: Vector3) -> float:
	var d := to - from
	return atan2(-d.x, -d.z)

## ===== 结局:交付 → 头发长出 → 鬼魂显形 → 告别 → 黎明的河边 =====
func handover() -> void:
	if ending_started:
		return
	ending_started = true
	player.locked = true
	boss.set_done()
	UI.set_cinematic(true)
	var cam: Camera3D = player.cam
	player.face_point(boss.global_position + Vector3(0, 1.55, 0))
	await _say_wait([
		"你把那瓶金色的液体,递到弟子1号面前。他的手在发抖。",
		"弟子1号|……(凑近闻了闻)这个气味……是对的。",
		"弟子1号|多一分不行,少一分也不行……原来,缺的是这个。我们试了整整一年……",
		"他往掌心倒了一点,颤抖着,按在自己光亮的头顶上。",
	])
	# --- 头发长出来 ---
	boss.kneel()
	boss.grow_hair_animated()
	SFX.play("ding")
	get_tree().call_group("lamps", "calm_down")
	UI.flash(Color(1.0, 0.85, 0.4, 0.35), 1.2)
	var fov_tw := cam.create_tween()
	fov_tw.tween_property(cam, "fov", 52.0, 3.2).set_trans(Tween.TRANS_SINE)
	player.face_point(boss.global_position + Vector3(0, 1.35, 0))
	await get_tree().create_timer(3.6).timeout
	await _say_wait([
		"一层细密、柔软的新发,在他的头皮上一簇一簇地冒了出来。",
		"弟子1号|……(用手摸了摸)……是真的。是真的头发。",
		"弟子1号|……我不用再让所有人变秃了。",
		"弟子1号|老师!老师您看见了吗!……",
	])
	# --- 鬼魂显形 ---
	var fov_back := cam.create_tween()
	fov_back.tween_property(cam, "fov", 75.0, 1.5)
	var right: Vector3 = player.global_transform.basis.x
	var ghost := _make_ghost()
	var gpos: Vector3 = boss.global_position + right * 1.7
	ghost.global_position = Vector3(gpos.x, 0.0, gpos.z)
	ghost.rotation.y = _yaw_toward(ghost.global_position, boss.global_position)
	_set_ghost_alpha(ghost, 0.0)
	var ga := create_tween()
	ga.tween_method(func(v: float): _set_ghost_alpha(ghost, v), 0.0, 1.0, 3.0)
	SFX.play("sting", -10.0)
	player.face_point(ghost.global_position + Vector3(0, 1.4, 0))
	await get_tree().create_timer(3.2).timeout
	var lines: Array = [
		"博士的鬼魂|……是你,把它配出来的?",
		"博士的鬼魂|多一分不行,少一分也不行。十五年的婚姻我都没算明白……这个比例,倒让你算出来了。",
		"博士的鬼魂|(看着弟子头上的新发)……长得真好。比我当年还好。",
		"弟子1号|老师……",
		"博士的鬼魂|别哭了,孩子。是这个世界不够温柔,不是你们的头发有错。",
	]
	if GS.has_flag("photo_assembled"):
		lines.append("博士的鬼魂|(目光落在你手里的合照上)Sarah……她笑起来的时候,我是真的很爱她。")
		lines.append("博士的鬼魂|……不过,她说得对。下水道确实该通了。")
	lines.append("博士的鬼魂|谢谢你。替全世界的秃头,谢谢你。")
	lines.append("博士的鬼魂|最后一件事——洗完澡,记得清理水槽。")
	await _say_wait(lines)
	# --- 鬼魂消散 ---
	player.face_point(ghost.global_position + Vector3(0, 1.4, 0))
	var up := create_tween().set_parallel(true)
	up.tween_property(ghost, "global_position:y", 1.2, 3.0)
	up.tween_method(func(v: float): _set_ghost_alpha(ghost, v), 1.0, 0.0, 3.0)
	SFX.play("ding", -4.0)
	UI.flash(Color(0.6, 0.85, 1.0, 0.3), 1.5)
	await get_tree().create_timer(3.2).timeout
	ghost.queue_free()
	await _say_wait([
		"弟子1号|……老师,走好。",
		"弟子1号|我去给全镇的人送货。放心——这次,不排进河里了。",
	])
	# --- 他走出后门,门外是破晓的光 ---
	boss.stand_up()
	var dawn := OmniLight3D.new()
	dawn.position = Vector3(8.5, 1.6, -24.0)
	dawn.light_color = Color(1.0, 0.7, 0.4)
	dawn.light_energy = 0.0
	dawn.omni_range = 12.0
	world.add_child(dawn)
	dawn.create_tween().tween_property(dawn, "light_energy", 3.0, 2.5)
	player.face_point(boss.global_position + Vector3(0, 1.5, 0))
	boss.walk_out(boss.exit_door)
	await get_tree().create_timer(4.5).timeout
	await UI.fade_to(1.0, 1.4)
	_finish_ending()

## 结局收尾:不再有河边的过场,直接进尾声字幕
func _finish_ending() -> void:
	GS.set_flag("game_completed")
	playing = false
	SFX.loop("drone", false)
	UI.set_cinematic(false, 0.01)
	var pages: Array = EPILOGUE.duplicate()
	if Letters.all_collected():
		# 收齐 5 封镇民来信:多一页
		pages.insert(pages.size() - 1, LETTERS_EPILOGUE)
	get_viewport().disable_3d = true
	UI.show_intro(pages, func():
		get_viewport().disable_3d = false
		UI.show_the_end())

func _make_ghost() -> Node3D:
	var hd := Person.build({
		"slot": "doctor_ghost", "ghost": true, "skin": Color(0.62, 0.8, 1.0), "cloth": "labcoat", "coat": Color(0.62, 0.8, 1.0), "pants": Color(0.4, 0.55, 0.9),
		"glasses": true, "hunch": -0.1, "wisps": true,
		"head": {"gaunt": 0.7}, "face": {"tears": true, "eyes": "normal", "age": 0.8, "bags": 0.6, "brow_tilt": -0.012},
	})
	var g: Node3D = hd["root"]
	world.add_child(g)
	# 一只手抬到脸边抹眼泪
	hd["arm_r"].rotation.x = -0.9
	var tw = (hd["elbow_r"] as Node3D).create_tween().set_loops()
	hd["elbow_r"].rotation.x = -2.0
	tw.tween_property(hd["elbow_r"], "rotation:x", -2.3, 0.6)
	tw.tween_property(hd["elbow_r"], "rotation:x", -1.7, 0.6)
	var l := OmniLight3D.new()
	l.light_color = Color(0.5, 0.8, 1.0)
	l.light_energy = 1.2
	l.omni_range = 5.0
	l.position = Vector3(0, 1.2, 0)
	g.add_child(l)
	return g
