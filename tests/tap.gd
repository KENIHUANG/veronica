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
	var fails := 0
	for x in [6.4, 8.25, 9.3]:
		for z in [0.8, 1.0, 1.2, 1.6, 2.0]:
			p.global_position = Vector3(x, 0, z)
			p.face_point(Vector3(x, 1.1, 0.14))
			for i in 3: await physics_frame
			var t: String = ui.prompt_label.text
			var ok := "水龙头" in t or "冲洗" in t
			if not ok:
				fails += 1
			print("sink x=", x, " z=", z, " -> [", t, "] ", "OK" if ok else "FAIL")
	for z in [0.8, 1.2, 1.6, 2.0]:
		p.global_position = Vector3(9.5, 0, z)
		p.face_point(Vector3(10.1, 1.1, 0.14))
		for i in 3: await physics_frame
		var t3: String = ui.prompt_label.text
		print("sink3 from (9.5,", z, ") -> [", t3, "]")
	# 镜子与洗手池里的头发仍然要能点到
	p.global_position = Vector3(8.25, 0, 2.0)
	p.face_point(Vector3(8.25, 1.8, 0.2))
	for i in 3: await physics_frame
	print("mirror -> [", ui.prompt_label.text, "]")
	p.global_position = Vector3(6.4, 0, 1.4)
	p.face_point(Vector3(6.4, 0.88, 0.27))
	for i in 3: await physics_frame
	print("sink hair -> [", ui.prompt_label.text, "]")
	print("tap fails: ", fails)
	quit()
