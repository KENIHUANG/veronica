extends RefCounted
## 镇民来信(收集品):镇上的人这几个月寄给实验室的信,没人拆、没人回,被随手塞得到处都是。
## 每封信的拾取点由各房间脚本调用 spawn() 放置;flag 为 letter_<i>。
## 背包里显示为一件物品"镇民来信",可以重读已收集的信。5 封全收齐 → 结局多一段。

const WB = preload("res://scripts/wb.gd")
const Mats = preload("res://scripts/mats.gd")

const COUNT := 5

## 顺序 = 编号 0..4
const TEXTS := [
	# 0 大厅接待台信格:理发店老板
	"[b]致 Cliché 实验室负责人[/b]\n\n您好。\n本人是柳湾镇“老周理发”的店主,经营三十一年。\n自今年春天起,本店客人减少了 94%。剩下的 6%,是来问能不能退卡的。\n恳请贵司核查排放情况。\n\n此致\n敬礼\n\n附:本店已改为“老周帽子店”。欢迎贵司员工惠顾,凭工牌九折。",
	# 1 厕所垃圾桶:小学生
	"[i](铅笔写的,字歪歪扭扭。纸被揉成过一团。)[/i]\n\n实验室的叔叔:\n我叫小磊,三年级。\n我在学校被叫“小卤蛋”。\n请把我的头发还给我。\n\n附:一根我的头发。(最后一根)\n\n[i](信封里,真的夹着一根头发。)[/i]",
	# 2 办公桌:女孩的母亲(没拆封)
	"[i](信封没有拆过。你小心地撕开了它。)[/i]\n\n您好,冒昧打扰。\n我是河边那户人家的妈妈。我女儿今年七岁,这两个月,嘴唇上长出了一撇小胡子。\n现在镇上都在传,说她刚出生时我们分不清男女,是抛硬币决定怎么养的。\n\n我想澄清一下:我们没有抛过硬币。\n(是她自己抛的。她很喜欢那枚硬币。)\n\n医生说,可能是接触了什么药。镇上的人都说,是从上游来的。\n如果是你们排的,能不能请你们停下来。\n\n谢谢。\n—— 一个很想澄清的妈妈",
	# 3 软木板:假发店的感谢信
	"[b]感谢信[/b]\n\n尊敬的 Cliché 实验室:\n自贵司开业以来,本店营业额增长 [b]400%[/b]。\n为表谢意,随信附赠本店新品“春风”系列假发一顶。\n期待长期合作。\n\n—— 柳湾假发城\n\n[i](“400%”被红笔圈了三圈。旁边写着:“我们到底在帮谁?”)[/i]",
	# 4 实验室柜子:2000 年的回信
	"[i](一张泛黄的信纸,折痕很深,被小心地夹在塑料袋里。)[/i]\n\n对不起。\n你是个好人。\n但我真的接受不了爷孙恋。\n\n—— 2000.11.4\n\n[i](背面是另一种笔迹,新一些:)[/i]\n“等我有了头发……”",
]

static func flag(i: int) -> String:
	return "letter_%d" % i

static func collected() -> int:
	var n := 0
	for i in COUNT:
		if GS.has_flag(flag(i)):
			n += 1
	return n

static func pages() -> Array:
	var out := []
	for i in COUNT:
		if GS.has_flag(flag(i)):
			out.append(TEXTS[i])
	return out

static func all_collected() -> bool:
	return collected() >= COUNT

## 放一封信。style: "flat"(平放的信封)/ "pinned"(钉在墙上,本地 +Z 朝外)/ "ball"(揉成一团)/ "slot"(插在信格里)
## 返回互动区(Area3D);已收集的信不生成,返回 null。
static func spawn(m, parent: Node3D, i: int, pos: Vector3, yaw_deg: float, style: String, area_size: Vector3 = Vector3(0.3, 0.25, 0.3)) -> Area3D:
	if GS.has_flag(flag(i)):
		return null
	var n := Node3D.new()
	n.set_script(preload("res://scripts/glint.gd"))
	n.position = pos
	n.rotation_degrees.y = yaw_deg
	parent.add_child(n)
	var paper := Mats.solid(Color(0.86, 0.82, 0.7), 0.9)
	paper.emission_enabled = true                       # 一点点自发光:暗处也能被注意到
	paper.emission = Color(0.9, 0.85, 0.7)
	paper.emission_energy_multiplier = 0.6
	n.set("mat", paper)
	var gl := OmniLight3D.new()                       # 小暖光:照亮信封周围,远处也能看到一点光
	gl.light_color = Color(1.0, 0.85, 0.55)
	gl.omni_range = 0.9
	gl.light_energy = 0.4
	gl.position = Vector3(0, 0.15, 0.12) if style == "pinned" else Vector3(0, 0.2, 0)
	n.add_child(gl)
	n.set("light", gl)
	var stamp := Mats.solid(Color(0.6, 0.12, 0.1), 0.8)
	match style:
		"pinned":
			var p := WB.box(n, Vector3(0, 0, 0.004), Vector3(0.26, 0.18, 0.004), paper, false)
			p.rotation.z = 0.06
			WB.box(n, Vector3(0.0, 0.11, 0.01), Vector3(0.018, 0.018, 0.012), stamp, false)    # 图钉
		"ball":
			var sm := SphereMesh.new()
			sm.radius = 0.05
			sm.height = 0.085
			var b := MeshInstance3D.new()
			b.mesh = sm
			b.material_override = paper
			b.rotation = Vector3(0.4, 0.7, 0.2)
			n.add_child(b)
		"slot":
			var e := WB.box(n, Vector3(0, 0, 0), Vector3(0.012, 0.16, 0.24), paper, false)
			e.rotation.x = 0.08
			WB.box(n, Vector3(0.008, 0.03, 0.06), Vector3(0.004, 0.03, 0.03), stamp, false)
		_:
			var f := WB.box(n, Vector3(0, 0.004, 0), Vector3(0.26, 0.006, 0.17), paper, false)
			f.rotation.y = 0.2
			WB.box(n, Vector3(0.09, 0.009, -0.045), Vector3(0.04, 0.002, 0.04), stamp, false).rotation.y = 0.2
	var area: Area3D = WB.inter(parent, pos, area_size, "捡起信件", Callable())
	area.action = func():
		if GS.has_flag(flag(i)):
			return
		GS.set_flag(flag(i))
		if not GS.has_item("town_letters"):
			GS.add_item("town_letters")
		n.queue_free()
		area.enabled = false
		area.set_deferred("collision_layer", 0)
		SFX.play("pickup")
		UI.open_reader(L.f("镇民来信 {n}/{t}", {"n": collected(), "t": COUNT}), [TEXTS[i]])
		if collected() == 1:
			UI.toast("镇上的人寄给实验室的信。\n应该不止这一封。", 4.0)
	return area
