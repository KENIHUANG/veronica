extends SceneTree
## 镇民来信:每封信都能从正常站位瞄准并拾取;柜子里的信在惊吓前拿不到;接待台原有互动不被挡住。
## 通过时最后一行输出 "letters fails: 0"。
var main
var p
var ui
var fails := 0

func aim(pos: Vector3, target: Vector3) -> String:
	p.global_position = pos
	p.face_point(target)
	for i in 4: await physics_frame
	return ui.prompt_label.text

func check(name: String, stands: Array, target: Vector3, want: String) -> void:
	for st in stands:
		var t: String = await aim(st, target)
		var ok := want in t
		if not ok: fails += 1
		print(name, " from ", st, " -> [", t, "] ", "OK" if ok else "FAIL")

func pick(stand: Vector3, target: Vector3, idx: int) -> void:
	await aim(stand, target)
	if p.target_inter != null:
		p.target_inter.interact()
	for i in 3: await process_frame
	var ok: bool = root.get_node("GS").has_flag("letter_%d" % idx)
	if not ok: fails += 1
	print("pick letter ", idx, " -> ", ok, " reader open: ", ui.blocked())
	ui.hide_screen() if ui.has_method("hide_screen") else null
	if ui.has_method("close_modal"): ui.close_modal()
	for i in 3: await process_frame

func _initialize() -> void:
	var gs = root.get_node("GS")
	ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	p = main.player
	main.boss.visible = false
	main.boss.process_mode = Node.PROCESS_MODE_DISABLED
	var L0 := Vector3(3.73, 1.64, 8.6)
	await check("letter0 (cubby)", [Vector3(1.9, 0, 8.6), Vector3(2.0, 0, 8.2), Vector3(2.0, 0, 9.1)], L0, "信件")
	await check("reception still works", [Vector3(1.6, 0, 8.0)], Vector3(2.9, 1.1, 8.0), "接待台")
	var L1 := Vector3(5.0, 0.66, 7.25)
	await check("letter1 (trash)", [Vector3(5.0, 0, 6.2), Vector3(5.9, 0, 7.0)], L1, "信件")
	var L2 := Vector3(-4.9, 0.02, -0.7)
	await check("letter2 (desk)", [Vector3(-6.2, 0, -0.5), Vector3(-5.9, 0, 0.3)], L2, "信件")
	await check("photo frame still works", [Vector3(-8.7, 0, 1.2)], Vector3(-8.7, 1.0, 0.25), "相框")
	var L3 := Vector3(-6.48, 1.5, -3.95)
	await check("letter3 (cork)", [Vector3(-6.48, 0, -2.6), Vector3(-6.0, 0, -2.5)], L3, "信件")
	await check("radio still works", [Vector3(-6.2, 0, -2.5)], Vector3(-6.2, 0.85, -3.55), "收音机")
	var L4 := Vector3(3.75, 0.06, -25.7)
	var before: String = await aim(Vector3(3.7, 0, -24.0), L4)
	var hidden_ok := not ("信件" in before)
	if not hidden_ok: fails += 1
	print("letter4 before scare -> [", before, "] ", "OK" if hidden_ok else "FAIL")
	# 触发柜子惊吓
	if p.target_inter != null:
		p.target_inter.interact()
	for i in 90: await physics_frame
	await check("letter4 (cabinet, after scare)", [Vector3(3.7, 0, -24.4), Vector3(3.4, 0, -24.5)], L4, "信件")
	# 依次拾取
	await pick(Vector3(1.9, 0, 8.6), L0, 0)
	await pick(Vector3(5.0, 0, 6.2), L1, 1)
	await pick(Vector3(-6.2, 0, -0.5), L2, 2)
	await pick(Vector3(-6.48, 0, -2.6), L3, 3)
	await pick(Vector3(3.7, 0, -24.4), L4, 4)
	var Letters = load("res://scripts/letters.gd")
	print("collected: ", Letters.collected(), " all: ", Letters.all_collected(), " has item: ", gs.has_item("town_letters"), " pages: ", Letters.pages().size())
	if not Letters.all_collected(): fails += 1
	print("letters fails: ", fails)
	quit()
