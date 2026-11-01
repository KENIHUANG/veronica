extends SceneTree
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 8) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait:
		await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/home/claude/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated"]:
		gs.set_flag(f)
	gs.add_item("lab_keycard")
	main._build_world(); main._begin_play(false)
	await physics_frame
	await snap("u_office", Vector3(-5.0, 0, 0.5), Vector3(-10.0, 1.0, -0.5))
	await snap("u_lab", Vector3(0, 0, -13.5), Vector3(0, 1.2, -21.0))
	await snap("u_comp", Vector3(3.2, 0, -15.5), Vector3(5.1, 1.1, -15.5))
	await snap("u_wigs", Vector3(-2.0, 0, -22.5), Vector3(-2.2, 1.4, -25.8))
	main.boss.spawn_at(Vector3(0, 0, -17))
	main.boss.begin_patrol()
	await snap("u_boss", Vector3(0, 0, -13.5), Vector3(0, 1.4, -16.5), 4)
	quit()
