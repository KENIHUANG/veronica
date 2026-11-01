extends SceneTree
## 修女追逐 + 厕所藏身:躲进清洁工具柜 → 她跟丢、退到门外徘徊 → 玩家能在厕所里自由探索
## → 拿到镜子碎片后她闯进来。通过时输出 "hide fails: 0"
var fails := 0
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var st = main.statue
	# 柜子能瞄准
	for pos in [Vector3(6.65, 0, 5.8), Vector3(6.0, 0, 6.0), Vector3(7.3, 0, 6.0)]:
		p.global_position = pos
		p.face_point(Vector3(6.65, 1.1, 7.15))
		for i in 4: await physics_frame
		var ok: bool = "清洁工具柜" in ui.prompt_label.text
		if not ok: fails += 1
		print("closet from ", pos, " -> [", ui.prompt_label.text, "] ", "OK" if ok else "FAIL")
	# 拿镊子 → 尖叫 → 追
	p.global_position = Vector3(-2.5, 0, -3.6)
	p.face_point(st.head.global_position)
	st.tweezers_inter.interact()
	for i in 200: await physics_frame
	print("statue state after scream: ", st.state, " (2=CHASE)")
	# 玩家进厕所、躲进柜子
	p.global_position = Vector3(6.65, 0, 6.0)
	p.face_point(Vector3(6.65, 1.1, 7.15))
	for i in 4: await physics_frame
	p.target_inter.interact()
	var hp0: int = gs.hp
	for i in 60 * 12: await physics_frame
	var lurk: bool = st.state == 5
	var near_door: bool = Vector2(st.global_position.x - 2.6, st.global_position.z - 4.0).length() < 2.0
	if not (lurk and near_door): fails += 1
	print("hidden -> statue LURK: ", lurk, " near door: ", near_door, " pos ", st.global_position.snapped(Vector3(0.1, 0.1, 0.1)), " hp ", hp0, "->", gs.hp)
	print("objective: ", gs.objective())
	# 出来,在厕所里逛 12 秒(去镜子前、隔间旁)
	p.leave_hide()
	for spot in [Vector3(8.25, 0, 2.2), Vector3(10.0, 0, 4.0), Vector3(7.0, 0, 5.0)]:
		p.global_position = spot
		for i in 60 * 4: await physics_frame
	var safe_explore: bool = gs.hp == hp0 and st.state == 5
	if not safe_explore: fails += 1
	print("explored restroom safely: ", safe_explore, " (state ", st.state, " hp ", gs.hp, ")")
	# 拿到碎片 → 她闯进来
	gs.set_flag("mirror_event_done")
	gs.add_item("mirror_shard"); gs.set_flag("got_mirror_shard")
	for i in 10: await physics_frame
	var back: bool = st.state == 2
	if not back: fails += 1
	print("after shard -> statue CHASE: ", back)
	print("hide fails: ", fails)
	quit()
