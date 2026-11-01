extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	var b = main.boss
	b.spawn_at(Vector3(0, 0, -16.0))
	b.rotation.y = PI
	var p = main.player
	p.global_position = Vector3(0, 0, -13.6)
	p.face_point(b.global_position + Vector3(0, 1.62, 0))
	for i in 6: await physics_frame
	await process_frame; await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/b_face.png")
	p.global_position = Vector3(0, 0, -11.6)
	p.face_point(b.global_position + Vector3(0, 1.3, 0))
	for i in 4: await physics_frame
	await process_frame; await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/b_full.png")
	quit()
