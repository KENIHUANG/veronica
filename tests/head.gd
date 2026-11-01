extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var st = main.statue
	# 走完整流程:拿镊子 -> 尖叫 -> 追击 -> 刺入 -> 头顶按钮
	p.global_position = Vector3(-2.5, 0, -2.4)
	p.face_point(st.tweezers_inter.global_position)
	for i in 3: await physics_frame
	p.target_inter.interact()
	for i in 220: await physics_frame
	gs.add_item("mirror_shard")
	p.global_position = st.global_position + Vector3(0, 0, 1.8)
	p.face_point(st.global_position + Vector3(0, 1.1, 0))
	for i in 4: await physics_frame
	print("chase prompt: [", ui.prompt_label.text, "]")
	p.target_inter.interact()
	for i in 6: ui._qte_press()
	print("defeated state=", st.state)
	# 在几个不同距离/角度下找头顶按钮
	var hb = st.head.global_position + Vector3(0, 0.3, 0)
	print("head button world pos: ", hb)
	for d in [1.0, 1.5, 2.0, 2.4]:
		p.global_position = st.global_position + Vector3(0, 0, d)
		p.face_point(hb)
		for i in 4: await physics_frame
		print("dist ", d, " prompt: [", ui.prompt_label.text, "]")
	p.face_point(hb)
	p.target_inter.interact()
	print("keycard: ", gs.has_item("lab_keycard"))
	quit()
