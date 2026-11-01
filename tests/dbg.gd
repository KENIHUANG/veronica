extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	gs.reset(); ui.hide_title()
	gs.set_flag("lab_unlocked"); gs.set_flag("boss_intro_done"); gs.set_flag("statue_defeated")
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var b = main.boss
	p.global_position = Vector3(0, 0, 5)
	b.global_position = Vector3(0, 0, -14.5)
	b.begin_patrol()
	b.patrol_time = 100.0
	for i in 1500:
		await physics_frame
		if i % 100 == 0:
			print(i, " state=", b.state, " pos=", b.global_position, " next=", b.next_pt)
		if b.state == 5:
			print("AWAY at ", i); break
	# statue chase test
	gs.reset(); gs.set_flag("restroom_open"); main._build_world(); main._begin_play(false)
	await physics_frame
	p = main.player; var st = main.statue
	p.global_position = Vector3(-2.5, 0, -2.0)
	st.tweezers_inter.interact()
	p.global_position = Vector3(8.0, 0, 2.2)
	for i in 1500:
		await physics_frame
		if i % 150 == 0:
			print("statue ", i, " pos=", st.global_position, " hp=", gs.hp)
		if gs.hp < 5:
			print("statue hit at ", i); break
	quit()
