extends SceneTree
## 实验室门:只有门禁卡打不开,还要日期密码(日记 2024.1.3)。通过时输出 "labdoor fails: 0"
var fails := 0
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "statue_defeated"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	gs.add_item("lab_keycard"); gs.set_flag("got_lab_keycard")
	p.global_position = Vector3(0, 0, -10.6)
	p.face_point(Vector3(0, 1.2, -12.0))
	for i in 4: await physics_frame
	print("prompt: [", ui.prompt_label.text, "]")
	p.target_inter.interact()
	for i in 3: await process_frame
	var lock_open: bool = ui.blocked() and ui.lock_edit != null
	if not lock_open: fails += 1
	print("date lock shown: ", lock_open, " | objective: ", gs.objective())
	ui.lock_edit.text = "2021.2.3"            # 保险箱的密码,不对
	ui.lock_edit.text_submitted.emit(ui.lock_edit.text)
	await process_frame
	var still_locked: bool = not gs.has_flag("lab_unlocked")
	if not still_locked: fails += 1
	print("wrong code keeps it locked: ", still_locked)
	ui.lock_edit.text = "2024.1.3"
	ui.lock_edit.text_submitted.emit(ui.lock_edit.text)
	for i in 3: await process_frame
	var opened: bool = gs.has_flag("lab_unlocked")
	if not opened: fails += 1
	print("correct code opens lab: ", opened)
	var Main = load("res://scripts/main.gd")
	var clue: bool = "门锁密码" in str(Main.DIARY)
	if not clue: fails += 1
	print("diary has the clue: ", clue)
	print("labdoor fails: ", fails)
	quit()
