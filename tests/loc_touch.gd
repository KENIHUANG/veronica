extends SceneTree
func _touch(idx: int, pos: Vector2, pressed: bool) -> void:
	var ev := InputEventScreenTouch.new()
	ev.index = idx
	ev.position = root.get_final_transform() * pos
	ev.pressed = pressed
	Input.parse_input_event(ev)
func _drag(idx: int, pos: Vector2, rel: Vector2) -> void:
	var ev := InputEventScreenDrag.new()
	ev.index = idx
	ev.position = root.get_final_transform() * pos
	ev.relative = root.get_final_transform().basis_xform(rel)
	Input.parse_input_event(ev)
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var L = root.get_node("L")
	var touch = root.get_node("Touch")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	# ---------- 语言 ----------
	L.set_lang("en")
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	print("EN objective: ", ui.obj_label.text)
	var p = main.player
	var st = main.statue
	p.global_position = Vector3(-2.5, 0, -2.4)
	p.face_point(st.tweezers_inter.global_position)
	for i in 3: await physics_frame
	print("EN prompt: ", ui.prompt_label.text)
	ui.toast("你已经调好了完美的生发剂。快交给弟子1号!", 1.0)
	print("EN toast: ", ui.toast_label.text)
	L.set_lang("zh")
	await physics_frame
	print("ZH prompt: ", ui.prompt_label.text, " | ZH objective: ", ui.obj_label.text)
	L.set_lang("en")
	# ---------- 触控 ----------
	touch.enabled = true
	touch.canvas.visible = true
	touch._layout()
	await process_frame
	var yaw0 = p.yaw
	var pos0 = p.global_position
	# 左半屏按下并推摇杆向上(前进)
	_touch(0, Vector2(200, 500), true)
	await process_frame
	_drag(0, Vector2(200, 430), Vector2(0, -70))
	await process_frame
	print("stick move vector: ", touch.move)
	for i in 30: await physics_frame
	print("moved by touch: ", p.global_position.distance_to(pos0) > 0.5)
	_touch(0, Vector2(200, 430), false)
	await process_frame
	# 右半屏拖动 -> 转视角
	_touch(1, Vector2(900, 300), true)
	await process_frame
	_drag(1, Vector2(1000, 300), Vector2(100, 0))
	await process_frame
	await physics_frame
	print("looked by touch: ", absf(p.yaw - yaw0) > 0.1)
	_touch(1, Vector2(1000, 300), false)
	# 互动大按钮:对着厕所门点一下
	p.global_position = Vector3(2.0, 0, 4.0)
	p.face_point(Vector3(4.1, 1.2, 4.0))
	for i in 3: await physics_frame
	var ib = touch.btns[0]
	print("interact btn pos: ", ib["pos"], " prompt: ", ui.prompt_label.text)
	_touch(2, ib["pos"], true)
	await process_frame
	_touch(2, ib["pos"], false)
	for i in 5: await physics_frame
	print("restroom door opened by touch: ", gs.has_flag("restroom_open"))
	quit()
