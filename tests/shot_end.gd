extends SceneTree
var main
func snap(name: String, wait: int = 8) -> void:
	for i in wait:
		await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var b = main.boss
	b.spawn_at(Vector3(0, 0, -17.0))
	b.set_done()
	b.rotation.y = PI
	b.kneel()
	b.grow_hair_animated()
	get_nodes_in_group("lamps")
	ui.set_cinematic(true, 0.01)
	p.global_position = Vector3(0, 0, -14.2)
	p.face_point(b.global_position + Vector3(0, 1.35, 0))
	p.cam.fov = 52.0
	await snap("e_hair", 20)
	# 鬼魂
	var g = main._make_ghost()
	g.global_position = b.global_position + Vector3(1.7, 0, 0)
	g.rotation.y = main._yaw_toward(g.global_position, b.global_position)
	main._set_ghost_alpha(g, 1.0)
	p.cam.fov = 70.0
	p.global_position = Vector3(0.9, 0, -13.8)
	p.face_point(Vector3(1.1, 1.4, -17.0))
	await snap("e_ghost", 10)
	# 河边
	main._ending_outdoor()
	await snap("e_outdoor", 200)
	p.cam.fov = 18.0
	await snap("e_girl_zoom", 4)
	quit()
