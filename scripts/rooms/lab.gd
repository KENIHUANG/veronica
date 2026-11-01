extends RefCounted
## 实验室:冷色调、储物柜(躲藏)、假发彩蛋、半个人体模型、配方书、终端、调配台、Boss。

const PT = preload("res://scripts/painted_text.gd")
const Letters = preload("res://scripts/letters.gd")
const HW = preload("res://scripts/handwriting.gd")
const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")
const Props = preload("res://scripts/props.gd")
const Wigs = preload("res://scripts/wigs.gd")
const BossS = preload("res://scripts/boss.gd")

const TARGET := [5, 30, 40, 20, 5]
const NAMES := ["米诺地尔 (Minoxidil)", "丙二醇 (Propylene glycol)", "乙醇 (Ethanol)", "蒸馏水 (Distilled water)", "抑毛因子-K (Inhibitor-K)"]
const TERMINAL_LOG := "> 实验记录 #0417\n> 负责人:博士\n>\n> 米诺地尔 5 + 丙二醇 30 + 乙醇 40 + 蒸馏水 20 的配方确实能促进头发再生。\n> 但会引发全身毛发疯狂生长(参见 2025.8.13 日记)。\n>\n> 缺失成分:抑毛因子-K (Inhibitor-K)。\n> 用量:——未录入——(博士:写在我自己的本子上了)\n> 警告:多一分,头发脱落;少一分,浑身长毛。\n> 总量必须恰好是 100 份。\n>\n> (备注:早该想到的……)"
const BOOK_PAGE := "[b]米诺地尔生发剂  配方 v17[/b]\n\n米诺地尔 (Minoxidil) —— 5 份\n丙二醇 (Propylene glycol) —— 30 份\n乙醇 (Ethanol) —— 40 份\n蒸馏水 (Distilled water) —— 20 份\n░░░░░░░░░░ —— ? 份   [i](被咖啡渍盖住了)[/i]\n\n页边潦草地写着:\n“为什么总是全身长毛?缺了点什么……”"

static func build(m, root: Node3D) -> void:
	var lt := Mats.get_mat("labtile")
	var lw := Mats.get_mat("labwall")
	var steel := Mats.get_mat("steel")
	var dark := Mats.solid(Color(0.08, 0.1, 0.12), 0.6, 0.3)

	# 结构
	WB.slab(root, Vector3(-6.2, -0.2, -26.2), Vector3(6.2, 0, -12.0), lt)
	WB.slab(root, Vector3(-6.2, 3.0, -26.2), Vector3(6.2, 3.2, -12.0), lw)
	WB.slab(root, Vector3(-6.2, 0, -26.2), Vector3(-6.0, 3, -12.0), lw)
	WB.slab(root, Vector3(-6.2, 0, -26.2), Vector3(6.2, 3, -26.0), lw)
	WB.slab(root, Vector3(6.0, 0, -26.2), Vector3(6.2, 3, -25.0), lw)
	WB.slab(root, Vector3(6.0, 0, -23.0), Vector3(6.2, 3, -12.0), lw)
	WB.slab(root, Vector3(6.0, 2.4, -25.0), Vector3(6.2, 3, -23.0), lw)
	WB.slab(root, Vector3(-6.2, 0, -12.2), Vector3(-4.2, 3, -12.0), lw)
	WB.slab(root, Vector3(4.2, 0, -12.2), Vector3(6.2, 3, -12.0), lw)
	# 后门外的黑暗走廊
	WB.slab(root, Vector3(6.2, -0.2, -25.2), Vector3(9.4, 0, -22.8), dark)
	WB.slab(root, Vector3(6.2, 3.0, -25.2), Vector3(9.4, 3.2, -22.8), dark)
	WB.slab(root, Vector3(6.2, 0, -25.4), Vector3(9.6, 3, -25.2), dark)
	WB.slab(root, Vector3(6.2, 0, -22.8), Vector3(9.6, 3, -22.6), dark)
	WB.slab(root, Vector3(9.4, 0, -25.4), Vector3(9.6, 3, -22.6), dark)

	# 灯:冷白、狂闪
	var cold := Color(0.7, 0.88, 1.0)
	WB.lamp(root, Vector3(0, 2.95, -15.0), cold, 2.4, 0.3, 0.25, Vector3(1.4, 0.06, 0.25))
	WB.lamp(root, Vector3(0, 2.95, -19.5), cold, 2.4, 0.3, 0.25, Vector3(1.4, 0.06, 0.25))
	WB.lamp(root, Vector3(-3.0, 2.95, -22.5), cold, 2.2, 0.3, 0.25, Vector3(1.4, 0.06, 0.25))
	WB.lamp(root, Vector3(3.2, 2.95, -23.5), cold, 2.2, 0.3, 0.25, Vector3(1.4, 0.06, 0.25))
	var fill := OmniLight3D.new()    # 一点不闪的冷色底光,保证不会彻底漆黑
	fill.position = Vector3(0, 2.6, -19.0)
	fill.light_color = Color(0.55, 0.75, 1.0)
	fill.light_energy = 0.45
	fill.omni_range = 16.0
	root.add_child(fill)
	var red := OmniLight3D.new()
	red.position = Vector3(5.6, 2.5, -24.0)
	red.light_color = Color(1.0, 0.15, 0.1)
	red.light_energy = 0.8
	red.omni_range = 4.0
	root.add_child(red)

	# 后门
	var ed := WB.door(root, Vector3(6.1, 0, -23.0), 90.0, 0.0, 2.0, 2.4, steel)
	var edi = ed.add_inter(2.0, 2.4, "后门", func():
		UI.toast("后门从外面锁着。\n门缝下,有一道湿漉漉的拖痕,一直通向河边。", 2.5))
	edi.collision_layer = 2

	# 实验台 A(调配台)与 B(配方书)
	WB.slab(root, Vector3(-3.8, 0, -18.6), Vector3(-0.5, 0.95, -17.4), steel)
	WB.slab(root, Vector3(-3.85, 0.95, -18.65), Vector3(-0.45, 0.99, -17.35), Mats.solid(Color(0.8, 0.85, 0.88), 0.2, 0.5), false)
	WB.slab(root, Vector3(0.5, 0, -21.6), Vector3(4.5, 0.95, -20.4), steel)
	WB.slab(root, Vector3(0.45, 0.95, -21.65), Vector3(4.55, 0.99, -20.35), Mats.solid(Color(0.8, 0.85, 0.88), 0.2, 0.5), false)
	# 烧瓶
	var fl := [Color(0.3, 0.9, 0.4), Color(0.95, 0.7, 0.2), Color(0.4, 0.6, 1.0), Color(0.9, 0.3, 0.3), Color(0.9, 0.9, 0.9)]
	for i in 5:
		Props.flask(root, Vector3(-3.4 + i * 0.5, 0.99, -18.0), fl[i], 1.2)
	for i in 3:
		Props.flask(root, Vector3(1.0 + i * 0.5, 0.99, -21.2), fl[(i + 2) % 5], 1.0)
	# 离心机
	WB.cyl(root, Vector3(3.6, 1.12, -21.0), 0.22, 0.26, Mats.solid(Color(0.85, 0.85, 0.88)), false)
	# 配方书
	WB.box(root, Vector3(2.2, 1.0, -21.0), Vector3(0.36, 0.04, 0.26), Mats.solid(Color(0.4, 0.07, 0.07)), false)
	WB.box(root, Vector3(2.2, 1.025, -21.0), Vector3(0.32, 0.01, 0.22), Mats.solid(Color(0.88, 0.85, 0.75)), false)
	WB.inter(root, Vector3(2.2, 1.1, -21.0), Vector3(0.8, 0.4, 0.7), "阅读配方笔记", func():
		GS.set_flag("formula_book_read")
		UI.open_reader("配方笔记", [BOOK_PAGE]))

	# 调配台
	var mix := WB.inter(root, Vector3(-2.15, 1.2, -18.0), Vector3(1.6, 0.6, 1.0), "调配生发剂", Callable())
	mix.action = func():
		if GS.has_item("perfect_hair_tonic"):
			UI.toast("你已经调好了完美的生发剂。快交给弟子1号!", 3.0)
			return
		if not GS.has_flag("formula_known"):
			UI.toast("烧杯、试剂、天平……但我不知道该怎么配。\n(也许电脑里有记录。)", 4.0)
			return
		UI.open_mixer(NAMES, _check_mix, func(): _mix_ok(m))

	# 电脑桌:CRT 显示器 + 键盘。便利贴改成贴在墙上的大黄纸,字也写在上面
	WB.slab(root, Vector3(4.6, 0, -16.2), Vector3(5.9, 0.8, -14.8), steel)
	Props.monitor(root, Vector3(5.45, 0.8, -15.5), 90.0, Color(0.25, 0.9, 0.7), "CLICHÉ LAB\n> PASSWORD:\n> _")
	WB.box(root, Vector3(4.95, 0.815, -15.5), Vector3(0.14, 0.025, 0.4), Mats.solid(Color(0.12, 0.13, 0.15)), false)
	WB.inter(root, Vector3(5.0, 1.0, -15.5), Vector3(0.8, 0.5, 1.0), "使用终端", func():
		UI.open_terminal("SARAH0203", TERMINAL_LOG, func():
			GS.set_flag("formula_known")
			UI.toast("缺失的成分是:抑毛因子-K。\n用量没有录进电脑。博士的日记里,也许写了。", 5.0)))
	var note := WB.box(root, Vector3(5.97, 1.62, -15.5), Vector3(0.02, 0.34, 0.32), Mats.emissive(Color(1.0, 0.92, 0.3), 0.6), false)
	note.rotation_degrees.x = 3.0
	HW.label(root, Vector3(5.955, 1.64, -15.5), "密码:\nSARAH0203", Color(0.12, 0.1, 0.35), 0.0009, -90.0, 3.0)
	WB.ball(root, Vector3(5.95, 1.76, -15.5), 0.018, Mats.solid(Color(0.85, 0.1, 0.1), 0.3))
	WB.inter(root, Vector3(5.55, 1.65, -15.5), Vector3(0.9, 0.7, 0.9), "查看便利贴", func():
		UI.toast("墙上贴着一张大大的便利贴:\n“密码:SARAH0203”\n……他到最后都没忘掉她。", 5.0))

	# 通风橱
	WB.slab(root, Vector3(5.0, 0, -19.4), Vector3(5.9, 2.4, -17.6), steel)
	WB.box(root, Vector3(4.97, 1.4, -18.5), Vector3(0.02, 1.0, 1.5), Mats.emissive(Color(0.3, 0.55, 0.5), 0.3), false)

	# 假发展示架
	WB.slab(root, Vector3(-4.8, 1.2, -26.0), Vector3(0.9, 1.25, -25.55), steel)
	var hx := [-3.9, -2.2, -0.5]
	var kinds := ["comb", "afro", "twin"]
	for i in 3:
		WB.cyl(root, Vector3(hx[i], 1.32, -25.74), 0.035, 0.14, Mats.solid(Color(0.15, 0.15, 0.16), 0.4, 0.7), false)
		var mh := Wigs.blank_head(root, Vector3(hx[i], 1.54, -25.74), 180.0)
		Wigs.wig(mh, kinds[i])
	var wig_lines := {
		-3.9: "一顶金黄色的大背头假发,蓬得很不科学,靠一整罐发胶撑着。\n标签:“抗风等级:飓风”。\n……好眼熟。像某个政治人物。",
		-2.2: "爆炸头假发。标签:“实验 #212 的副作用,请勿靠近明火。”",
		-0.5: "青绿色的超长双马尾。\n……Miku?!",
	}
	for x in hx:
		var line: String = wig_lines[x]
		WB.inter(root, Vector3(x, 1.5, -25.5), Vector3(0.6, 0.6, 0.6), "查看假发", func(): UI.toast(line, 4.0))

	# 摆设用的人体模型(放样躯干 + 塑料头,有的头歪着)
	Wigs.mannequin(root, Vector3(-5.2, 0, -24.8), 40.0, true, 8.0)
	Wigs.mannequin(root, Vector3(-4.1, 0, -25.4), -10.0, true, -14.0)
	Wigs.mannequin(root, Vector3(-5.4, 0, -23.4), 70.0, true, 0.0)
	# 柜子惊吓
	_build_cabinet(m, root, steel)
	_build_valve(m, root, steel)
	# 墙上的警示
	PT.make(root, Vector3(0, 2.45, -25.94), 0.0, "危险 / 化学品 / 生物样本", "stencil", 2.8, Color(0.62, 0.08, 0.06), "stencil", 104, 0.19)
	# 地上的污渍
	var blood := StandardMaterial3D.new()
	blood.albedo_color = Color(0.3, 0.05, 0.04, 0.7)
	blood.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	WB.slab(root, Vector3(-1.5, 0.0, -22.5), Vector3(0.3, 0.01, -21.2), blood, false)

	# 储物柜(躲藏点)
	for z in [-14.3, -15.7, -21.7]:
		_build_locker(m, root, z)

	# Boss
	var boss = BossS.new()
	boss.position = Vector3(0, 0, -23.0)
	root.add_child(boss)
	boss.build(m)
	boss.exit_door = ed
	m.boss = boss

	# 进入实验室触发
	WB.trigger(root, Vector3(0, 1.0, -13.8), Vector3(6.0, 2.0, 1.2), func(b): if b == m.player: m.on_lab_enter())

static func _check_mix(v: Array) -> Dictionary:
	if v == TARGET:
		return {"ok": true, "msg": "完美!液体在瓶中变成了温暖的金色。"}
	var tot := 0
	for x in v:
		tot += x
	if v[4] < 5:
		return {"ok": false, "msg": "这瓶会让人长出一身毛。"}
	if v[4] > 5:
		return {"ok": false, "msg": "喷上去,头发直接开始脱落……"}
	if tot != 100:
		return {"ok": false, "msg": "成品像洗发水。不对。(总量要恰好 100 份)"}
	return {"ok": false, "msg": "颜色不对。有一种成分的比例偏了。"}

static func _mix_ok(m) -> void:
	GS.add_item("perfect_hair_tonic")
	GS.set_flag("tonic_crafted")
	SFX.play("pickup")
	UI.toast("获得:完美生发剂\n快交给弟子1号!", 4.0)
	m.checkpoint()

static func _build_locker(m, root: Node3D, c: float) -> void:
	var mt := Mats.solid(Color(0.3, 0.36, 0.34), 0.5, 0.5)
	WB.slab(root, Vector3(-5.95, 0, c - 0.4), Vector3(-5.9, 2.05, c + 0.4), mt, false)
	WB.slab(root, Vector3(-5.95, 0, c - 0.45), Vector3(-5.15, 2.05, c - 0.4), mt, false)
	WB.slab(root, Vector3(-5.95, 0, c + 0.4), Vector3(-5.15, 2.05, c + 0.45), mt, false)
	WB.slab(root, Vector3(-5.95, 2.0, c - 0.45), Vector3(-5.15, 2.05, c + 0.45), mt, false)
	WB.slab(root, Vector3(-5.95, 0, c - 0.45), Vector3(-5.15, 0.05, c + 0.45), mt, false)
	# 门框:两根立柱 + 上下横档,把百叶的两端包住(之前百叶伸进侧板、还凸出前沿 1 厘米,斜着看会穿模)
	var fr := Mats.solid(Color(0.26, 0.31, 0.29), 0.5, 0.5)
	WB.slab(root, Vector3(-5.2, 0, c - 0.45), Vector3(-5.11, 2.05, c - 0.37), fr, false)
	WB.slab(root, Vector3(-5.2, 0, c + 0.37), Vector3(-5.11, 2.05, c + 0.45), fr, false)
	WB.slab(root, Vector3(-5.2, 1.93, c - 0.37), Vector3(-5.11, 2.05, c + 0.37), fr, false)
	WB.slab(root, Vector3(-5.2, 0.0, c - 0.37), Vector3(-5.11, 0.1, c + 0.37), fr, false)
	for i in 5:
		var y0 := 0.14 + i * 0.36
		WB.slab(root, Vector3(-5.19, y0, c - 0.37), Vector3(-5.15, y0 + 0.22, c + 0.37), mt, false)
	var sb := StaticBody3D.new()
	sb.collision_layer = 1
	sb.collision_mask = 0
	sb.position = Vector3(-5.55, 1.02, c)
	var cs := CollisionShape3D.new()
	var sh := BoxShape3D.new()
	sh.size = Vector3(0.8, 2.05, 0.9)
	cs.shape = sh
	sb.add_child(cs)
	root.add_child(sb)
	var li := WB.inter(root, Vector3(-5.0, 1.0, c), Vector3(0.7, 2.0, 0.9), "躲进储物柜", Callable())
	li.action = func():
		m.player.enter_hide(
			Vector3(-5.55, 0, c), -PI / 2.0, Vector3(-4.6, 0, c),
			func(): cs.set_deferred("disabled", true),
			func(): cs.set_deferred("disabled", false))
		SFX.play("door", -8.0)

## 后门旁的排污阀:每 40 天,废液从这里排进河里。连按拧紧;声音很大,会把弟子1号引回来。
static func _build_valve(m, root: Node3D, steel: Material) -> void:
	var VP := Vector3(5.72, 1.1, -21.2)
	var rust := Mats.get_mat("rust")
	var pipe_m := Mats.solid(Color(0.22, 0.24, 0.22), 0.6, 0.6)
	# 竖管:从天花板穿下来,钻进地面
	Props._cyl(root, Vector3(5.86, 1.5, -21.2), 0.085, 3.0, pipe_m)
	for y in [0.4, 1.8, 2.6]:
		Props._torus(root, Vector3(5.86, y, -21.2), 0.085, 0.11, rust, Vector3(1, 0.5, 1))       # 法兰
	# 阀门手轮(面朝 -X)
	var wheel := Node3D.new()
	wheel.position = VP
	root.add_child(wheel)
	var ring := Props._torus(wheel, Vector3.ZERO, 0.15, 0.18, Mats.solid(Color(0.55, 0.06, 0.05), 0.5, 0.3))
	ring.rotation_degrees.z = 90.0
	for k in 3:
		var spoke := WB.box(wheel, Vector3.ZERO, Vector3(0.02, 0.32, 0.02), Mats.solid(Color(0.5, 0.06, 0.05), 0.5, 0.3), false)
		spoke.rotation_degrees.x = k * 60.0
	Props._cyl(wheel, Vector3(0.07, 0, 0), 0.03, 0.14, pipe_m, Vector3(0, 0, 90))
	# 牌子
	PT.make(root, Vector3(5.98, 1.75, -21.2), -90.0, "排污阀 · 每 40 天开启", "stencil", 1.0, Color(0.85, 0.75, 0.15), "stencil", 70, 0.16)
	# 地上的黄色积水 + 管口还在滴
	var puddle_m := Mats.solid(Color(0.55, 0.48, 0.1, 0.85), 0.1, 0.0)
	puddle_m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	var puddle := Props.stain(root, Vector3(5.55, 0.012, -21.2), Vector2(0.9, 1.2), Color(0.55, 0.48, 0.1), 0.0, false)
	var drip := CPUParticles3D.new()
	drip.position = Vector3(5.78, 0.42, -21.2)
	drip.amount = 10
	drip.lifetime = 0.6
	drip.direction = Vector3(0, -1, 0)
	drip.spread = 5.0
	drip.gravity = Vector3(0, -6, 0)
	drip.initial_velocity_min = 0.0
	drip.initial_velocity_max = 0.2
	var dm := SphereMesh.new()
	dm.radius = 0.012
	dm.height = 0.035
	drip.mesh = dm
	drip.material_override = Mats.emissive(Color(0.7, 0.6, 0.1), 0.4)
	root.add_child(drip)
	var closed: bool = GS.has_flag("valve_closed")
	drip.emitting = not closed
	if closed:
		wheel.rotation_degrees.x = 270.0
	var vi = WB.inter(root, VP, Vector3(0.45, 0.6, 0.7), "", Callable())
	vi.prompt_fn = func():
		return "" if GS.has_flag("valve_closed") else "关闭排污阀"
	vi.action = func():
		if GS.has_flag("valve_closed"):
			return
		UI.qte(12, 3.2, func():
			GS.set_flag("valve_closed")
			drip.emitting = false
			var tw := wheel.create_tween()
			tw.tween_property(wheel, "rotation_degrees:x", 270.0, 0.6)
			SFX.play("thump")
			m.player.shake(0.3, 0.03)
			if m.boss != null:
				m.boss.loud_noise(VP)
			UI.toast("阀门终于拧死了。管子里传来“咚”的一声闷响。\n……走廊那头,有脚步声在往回跑。", 5.0)
			m.checkpoint(),
		func():
			SFX.play("thump")
			if m.boss != null:
				m.boss.loud_noise(VP)
			UI.toast("阀门卡住了,只转了半圈。\n刚才那一下,声音很大。", 3.5),
		"拧紧")

static func _build_cabinet(m, root: Node3D, steel: Material) -> void:
	var done: bool = GS.has_flag("cabinet_scare")
	WB.slab(root, Vector3(3.0, 0, -26.0), Vector3(4.4, 2.2, -25.95), steel)
	WB.slab(root, Vector3(3.0, 0, -26.0), Vector3(3.05, 2.2, -25.2), steel)
	WB.slab(root, Vector3(4.35, 0, -26.0), Vector3(4.4, 2.2, -25.2), steel)
	WB.slab(root, Vector3(3.0, 2.15, -26.0), Vector3(4.4, 2.2, -25.2), steel)
	WB.slab(root, Vector3(3.0, 0, -26.0), Vector3(4.4, 0.05, -25.2), steel)
	var tor := Node3D.new()
	tor.position = Vector3(3.7, 0.2, -25.55)
	root.add_child(tor)
	var half := Wigs.mannequin(tor, Vector3(0, -0.85, 0), 180.0, false, 18.0, true)
	WB.box(half, Vector3(0, 0.865, 0), Vector3(0.3, 0.03, 0.2), Mats.solid(Color(0.42, 0.05, 0.05), 0.8), false)     # 断口
	var d := WB.door(root, Vector3(3.0, 0, -25.15), 0.0, -90.0, 1.4, 2.2, steel)
	var di = d.add_inter(1.4, 2.2, "搜索柜子", Callable())
	# 来信 5:弟子1号珍藏的回信,压在柜子底。柜门打开(惊吓)之后才能拿到。
	var la: Area3D = Letters.spawn(m, root, 4, Vector3(3.75, 0.055, -25.7), 0.0, "flat", Vector3(0.5, 0.3, 0.45))
	if la != null and not done:
		la.collision_layer = 0
	if done:
		d.set_open(true, false)
		di.enabled = false
		tor.position = Vector3(3.7, 0.2, -24.0)
		tor.rotation_degrees = Vector3(-90, 40, 0)
		return
	di.action = func():
		di.enabled = false
		GS.set_flag("cabinet_scare")
		d.set_open(true)
		await m.get_tree().create_timer(0.45).timeout
		SFX.play("sting")
		SFX.play("thump")
		UI.flash(Color(1, 1, 1, 0.4), 0.3)
		m.player.shake(0.5, 0.05)
		var tw := tor.create_tween()
		tw.tween_property(tor, "position", Vector3(3.7, 1.1, -23.9), 0.25)
		tw.parallel().tween_property(tor, "rotation_degrees", Vector3(-30, 0, 0), 0.25)
		tw.tween_property(tor, "position", Vector3(3.7, 0.2, -23.6), 0.35)
		tw.parallel().tween_property(tor, "rotation_degrees", Vector3(-90, 40, 0), 0.35)
		UI.toast("柜门弹开——半个人体模型扑了出来。", 3.0)
		if la != null and is_instance_valid(la):
			la.set_deferred("collision_layer", 2)
