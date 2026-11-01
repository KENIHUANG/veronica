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
	p.global_position = Vector3(-2.5, 0, -2.4)
	p.face_point(st.tweezers_inter.global_position)
	for i in 3: await physics_frame
	p.target_inter.interact()
	print("after take: state=", st.state, " (1=SCREAM) locked=", p.locked, " pos=", st.global_position)
	for i in 120: await physics_frame
	print("1s later: state=", st.state, " locked=", p.locked, " jaw=", snapped(st.jaw.rotation.x, 0.01))
	for i in 100: await physics_frame
	print("2.7s later: state=", st.state, " (2=CHASE) locked=", p.locked, " pos=", st.global_position)
	p.global_position = Vector3(8.0, 0, 2.2)
	var hit := -1
	for i in 1500:
		await physics_frame
		if gs.hp < 5:
			hit = i
			break
	print("chased to restroom and hit after frames: ", hit, " hp=", gs.hp)
	quit()
