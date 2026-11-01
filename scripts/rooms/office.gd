extends RefCounted
## 博士办公室:半张相框、保险箱(2021.2.3)、日记、空枪、收音机。

const Letters = preload("res://scripts/letters.gd")
const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")
const Draw = preload("res://scripts/draw.gd")
const Props = preload("res://scripts/props.gd")

static func build(m, root: Node3D) -> void:
	var wall := Mats.get_mat("plaster")
	var floor_m := Mats.get_mat("wood")
	var ceil_m := Mats.get_mat("concrete")
	var desk := Mats.get_mat("deskwood")
	var metal := Mats.solid(Color(0.3, 0.32, 0.33), 0.5, 0.6)

	WB.slab(root, Vector3(-12.2, -0.2, -4.2), Vector3(-4.0, 0, 4.2), floor_m)
	WB.slab(root, Vector3(-12.2, 3.0, -4.2), Vector3(-4.0, 3.2, 4.2), ceil_m)
	WB.slab(root, Vector3(-12.2, 0, -4.2), Vector3(-4.0, 3, -4.0), wall)
	WB.slab(root, Vector3(-12.2, 0, 4.0), Vector3(-4.0, 3, 4.2), wall)
	WB.slab(root, Vector3(-12.2, 0, -4.2), Vector3(-12.0, 3, 4.2), wall)

	# 东墙(与大厅共用)的办公室一侧贴灰泥,门洞处留空
	WB.slab(root, Vector3(-4.25, 0, -4.0), Vector3(-4.2, 3, -1.0), wall, false)
	WB.slab(root, Vector3(-4.25, 0, 1.0), Vector3(-4.2, 3, 4.0), wall, false)
	WB.slab(root, Vector3(-4.25, 2.4, -1.0), Vector3(-4.2, 3, 1.0), wall, false)

	# 灯光:温暖的台灯 + 将熄的顶灯
	var desk_lamp := OmniLight3D.new()
	desk_lamp.position = Vector3(-9.0, 1.4, -0.3)
	desk_lamp.light_color = Color(1.0, 0.7, 0.38)
	desk_lamp.light_energy = 1.3
	desk_lamp.omni_range = 7.0
	root.add_child(desk_lamp)
	WB.lamp(root, Vector3(-7.5, 2.95, 0.0), Color(1.0, 0.8, 0.5), 0.6, 0.3, 0.3)

	# 办公桌
	WB.slab(root, Vector3(-10.8, 0.75, -0.6), Vector3(-8.2, 0.82, 0.6), desk)
	WB.slab(root, Vector3(-10.8, 0, -0.6), Vector3(-10.6, 0.75, 0.6), desk)
	WB.slab(root, Vector3(-8.4, 0, -0.6), Vector3(-8.2, 0.75, 0.6), desk)
	# 桌面杂物
	var paper := Mats.solid(Color(0.85, 0.82, 0.7))
	for i in 7:
		var p := WB.box(root, Vector3(-10.3 + randf() * 1.8, 0.83 + i * 0.006, -0.4 + randf() * 0.8), Vector3(0.3, 0.005, 0.22), paper, false)
		p.rotation.y = randf() * TAU
	var bcols := [Color(0.3, 0.9, 0.4), Color(0.9, 0.5, 0.2), Color(0.4, 0.6, 1.0)]
	for i in 3:
		Props.bottle(root, Vector3(-10.5 + i * 0.18, 0.82, 0.35), bcols[i], 0.2, 0.04)
	# 老 CRT
	Props.monitor(root, Vector3(-10.1, 0.82, -0.2), -90.0, Color(0.2, 0.75, 0.35), "USER: DR.\nPASS: ****\n> Sarah_")
	WB.box(root, Vector3(-9.45, 0.83, -0.2), Vector3(0.14, 0.025, 0.4), Mats.solid(Color(0.7, 0.68, 0.6)), false)
	# 半张相框
	var frame_tex := _half_photo()
	var fm := StandardMaterial3D.new()
	fm.albedo_texture = frame_tex
	var fq := MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.22, 0.3)
	fq.mesh = qm
	fq.material_override = fm
	fq.position = Vector3(-8.65, 0.99, 0.25)
	fq.rotation_degrees.y = 90.0
	root.add_child(fq)
	WB.box(root, Vector3(-8.67, 0.99, 0.25), Vector3(0.02, 0.34, 0.26), Mats.solid(Color(0.15, 0.1, 0.06)), false)
	WB.inter(root, Vector3(-8.7, 1.0, 0.25), Vector3(0.5, 0.5, 0.6), "查看相框", func():
		if GS.has_flag("photo_assembled"):
			UI.toast("相框里只有博士的那半张。\n和厕所里拼好的照片严丝合缝——另一半,是 Sarah。", 5.0)
		else:
			UI.toast("相框里只有半张照片:一个笑得有点腼腆的男人。\n另一半被撕掉了。", 4.5))
	# 倒下的椅子
	Props.office_chair(root, Vector3(-7.6, 0.28, 1.2), Vector3(88, 30, 0))
	Props.office_chair(root, Vector3(-9.6, 0.0, 1.5), Vector3(0, 200, 0))

	# 试剂架
	var shelf_mat := Mats.get_mat("rust")
	for y in [0.5, 1.1, 1.7, 2.3]:
		WB.slab(root, Vector3(-11.95, y, -3.8), Vector3(-11.55, y + 0.04, -1.0), shelf_mat)
	var pal := [Color(0.3, 0.9, 0.4), Color(0.95, 0.75, 0.2), Color(0.4, 0.6, 1.0), Color(0.9, 0.3, 0.3), Color(0.8, 0.8, 0.8)]
	for yi in 4:
		for i in 6:
			var c: Color = pal[(yi + i) % pal.size()]
			Props.bottle(root, Vector3(-11.75, 0.54 + yi * 0.6, -3.6 + i * 0.45), c, 0.22, 0.05)
	# 文件柜
	for i in 3:
		WB.slab(root, Vector3(-11.2 + i * 1.0, 0, -4.0), Vector3(-10.7 + i * 1.0, 1.4, -3.3), metal)
	# 另一瓶喷雾
	if not GS.has_flag("spray_office"):
		WB.cyl(root, Vector3(-11.75, 1.26, -0.4), 0.04, 0.2, Mats.emissive(Color(0.3, 0.8, 0.35), 0.8), false)
	WB.slab(root, Vector3(-11.95, 1.1, -1.0), Vector3(-11.55, 1.14, 0.0), shelf_mat)
	var spi := WB.inter(root, Vector3(-11.75, 1.3, -0.4), Vector3(0.5, 0.5, 0.5), "拿走架子上的喷雾瓶", Callable())
	spi.action = func():
		if GS.has_flag("spray_office"):
			return
		GS.set_flag("spray_office")
		spi.enabled = false
		m.give_item("hair_tonic_spray", "", "spray_office")
	if GS.has_flag("spray_office"):
		spi.enabled = false

	# 保险箱
	WB.slab(root, Vector3(-11.95, 0, 2.4), Vector3(-11.15, 0.85, 3.2), Mats.solid(Color(0.2, 0.22, 0.24), 0.4, 0.7))
	var dial := WB.cyl(root, Vector3(-11.12, 0.5, 2.8), 0.09, 0.04, Mats.solid(Color(0.8, 0.75, 0.5), 0.3, 0.8), false)
	dial.rotation_degrees.z = 90.0
	var safei := WB.inter(root, Vector3(-11.0, 0.5, 2.8), Vector3(0.6, 0.9, 1.0), "", Callable())
	safei.prompt_fn = func():
		return "保险箱(已打开)" if GS.has_flag("safe_opened") else "输入保险箱密码"
	safei.action = func():
		if GS.has_flag("safe_opened"):
			UI.toast("保险箱里空了。", 2.0)
			return
		UI.open_safe(func(): _safe_open(m))

	# 收音机
	WB.slab(root, Vector3(-6.6, 0, -3.95), Vector3(-5.8, 0.7, -3.3), desk)
	WB.box(root, Vector3(-6.2, 0.82, -3.62), Vector3(0.36, 0.2, 0.26), Mats.solid(Color(0.35, 0.22, 0.12)), false)
	WB.box(root, Vector3(-6.3, 0.82, -3.49), Vector3(0.08, 0.08, 0.02), Mats.emissive(Color(1.0, 0.65, 0.2), 1.0), false)
	WB.inter(root, Vector3(-6.2, 0.85, -3.55), Vector3(0.7, 0.5, 0.6), "查看收音机", func():
		if m.radio_active:
			UI.toast("收音机里,同一句话在反复……", 2.5)
		else:
			UI.toast("老收音机,调在一个不存在的频道上。旋钮上积满了灰。", 3.0))

	_decorate(root)

	# 脚下散落的文件
	for i in 6:
		var p := WB.box(root, Vector3(-9.0 + randf() * 3.5, 0.01, -3.0 + randf() * 5.5), Vector3(0.3, 0.004, 0.22), paper, false)
		p.rotation.y = randf() * TAU

static func _half_photo() -> ImageTexture:
	var full: Image = Draw.photo_image()
	var half := full.get_region(Rect2i(0, 0, 180, 240))
	return ImageTexture.create_from_image(half)

static func _safe_open(m) -> void:
	GS.set_flag("safe_opened")
	SFX.play("door")
	GS.add_item("doctor_diary")
	GS.add_item("hollow_revolver")
	GS.set_flag("got_doctor_diary")
	GS.set_flag("got_hollow_revolver")
	SFX.play("pickup")
	m.checkpoint()
	UI.open_reader("保险箱开了", ["[b]获得:[/b]\n\n· [b]博士的日记[/b]\n  字迹越往后越潦草。[i]关掉这个窗口后会自动打开。[/i]\n\n· [b]空枪[/b]\n  没有子弹。按 Q 扣一下扳机,咔哒声能把人引开。\n\n[i]两样东西之后都可以按 Tab 在背包里查看。[/i]"], func():
		UI.open_reader("博士的日记", m.DIARY, func(): m.radio_event()))


## 墙上的白板、软木板、百叶窗、书柜、挂钟、证书、地毯
static func _decorate(root: Node3D) -> void:
	# 白板:北墙(面朝 +Z)
	Props.whiteboard(root, Vector3(-7.7, 1.75, -3.97), 0.0, "C13H20N4O\n米诺地尔 → 头发 ↑\n副作用 = 毛 ↑↑↑\n缺: ???")
	# 软木板:放在收音机上方
	Props.corkboard(root, Vector3(-6.2, 1.7, -3.97), 0.0)
	Letters.spawn(null, root, 2, Vector3(-4.9, 0.0, -0.7), 0.0, "flat", Vector3(0.45, 0.25, 0.4))   # 来信 3:从门缝塞进来,落在门口地上,没拆封
	Letters.spawn(null, root, 3, Vector3(-6.48, 1.5, -3.95), 0.0, "pinned", Vector3(0.28, 0.32, 0.12)) # 来信 4:钉在软木板上
	# 南墙(面朝 -Z):百叶窗、书柜、证书
	Props.window_blinds(root, Vector3(-9.9, 1.8, 3.97), 180.0, Vector2(1.3, 1.0))
	Props.bookcase(root, Vector3(-7.6, 0.0, 3.8), 180.0, 1.5, 2.1)
	Props.picture_frame(root, Vector3(-5.4, 1.8, 3.96), 180.0, Vector2(0.5, 0.65), "certificate", 3.0)
	Props.picture_frame(root, Vector3(-4.75, 1.75, 3.96), 180.0, Vector2(0.45, 0.6), "portrait", -6.0)
	# 西墙(面朝 +X):挂钟停在 2:03
	Props.wall_clock(root, Vector3(-11.95, 2.35, 1.2), 90.0, 2.0, 3.0)
	# 地毯、墙角灰尘、咖啡杯
	Props.rug(root, Vector3(-9.5, 0.0, 0.4), Vector2(3.6, 3.0), Color(0.34, 0.12, 0.1))
	WB.cyl(root, Vector3(-8.5, 0.86, 0.35), 0.04, 0.09, Mats.solid(Color(0.85, 0.85, 0.8), 0.4), false)
	WB.cyl(root, Vector3(-8.5, 0.905, 0.35), 0.033, 0.004, Mats.solid(Color(0.12, 0.07, 0.03), 0.2), false)
	# 墙面渗水
	Props.stain(root, Vector3(-7.5, 2.5, 3.98), Vector2(1.6, 1.0), Color(0.15, 0.1, 0.05, 0.6), 180.0)
	Props.stain(root, Vector3(-11.97, 0.9, -2.0), Vector2(1.2, 1.4), Color(0.12, 0.2, 0.08, 0.5), 90.0)
	Props.stain(root, Vector3(-8.0, 2.99, -1.5), Vector2(2.4, 2.0), Color(0.15, 0.1, 0.05, 0.5), 0.0, true)
