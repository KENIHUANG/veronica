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
	main._build_world(); main._begin_play(false)
	await physics_frame
	await snap("r_over", Vector3(5.6, 0, 3.8), Vector3(9.5, 1.3, 1.5))
	await snap("r_corner", Vector3(6.2, 0, 2.4), Vector3(4.6, 1.0, 0.3))
	await snap("r_south", Vector3(7.0, 0, 4.0), Vector3(6.5, 1.4, 8.0))
	await snap("o_north", Vector3(-5.5, 0, 0.5), Vector3(-7.4, 1.5, -4.0))
	await snap("o_south", Vector3(-8.0, 0, -1.5), Vector3(-8.5, 1.6, 4.0))
	await snap("o_west", Vector3(-6.0, 0, 1.0), Vector3(-11.8, 1.6, 0.0))
	quit()
