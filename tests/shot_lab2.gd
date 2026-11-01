extends SceneTree
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 8) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	await snap("w_wigs", Vector3(-2.2, 0, -23.0), Vector3(-2.2, 1.55, -25.7))
	await snap("w_manq", Vector3(-3.2, 0, -21.5), Vector3(-5.0, 1.2, -24.5))
	quit()
