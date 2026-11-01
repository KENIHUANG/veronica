extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	main._build_world(); main._begin_play(false)
	await process_frame
	var p = main.player
	var st = main.statue
	print("tweezers world pos: ", st.tweezers_inter.global_position)
	p.global_position = Vector3(-2.8, 0, -2.4)
	p.face_point(st.tweezers_inter.global_position)
	for i in 4: await physics_frame
	print("prompt: [", ui.prompt_label.text, "]")
	p.target_inter.interact()
	print("statue state=", st.state, " pos=", st.global_position)
	quit()
