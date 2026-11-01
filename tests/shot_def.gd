extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset(); gs.set_flag("statue_defeated")
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var st = main.statue
	p.global_position = Vector3(-2.5, 0, -2.2)
	p.face_point(st.head.global_position + Vector3(0, 0.3, 0))
	for i in 10: await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/home/claude/d_statue_defeated.png")
	quit()
