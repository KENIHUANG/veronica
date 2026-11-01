extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"     # 断言用中文提示,不受系统语言/已存设置影响(不写入设置)
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var fails := 0
	# 便利贴:从多个位置、大致朝向它(不用瞄准得很准)
	for pos in [Vector3(3.2, 0, -15.5), Vector3(3.8, 0, -14.9), Vector3(4.0, 0, -16.2), Vector3(2.6, 0, -15.5), Vector3(4.2, 0, -15.5)]:
		for dz in [-0.35, 0.0, 0.35]:
			p.global_position = pos
			p.face_point(Vector3(5.95, 1.6 + 0.0, -15.5 + dz))
			for i in 3: await physics_frame
			var t: String = ui.prompt_label.text
			var ok := "便利贴" in t
			if not ok: fails += 1
			print("note from ", pos, " aim dz=", dz, " -> [", t, "] ", "OK" if ok else "FAIL")
	# 终端
	p.global_position = Vector3(3.6, 0, -15.5)
	p.face_point(Vector3(5.2, 1.0, -15.5))
	for i in 3: await physics_frame
	print("terminal -> [", ui.prompt_label.text, "]")
	print("note fails: ", fails)
	quit()
