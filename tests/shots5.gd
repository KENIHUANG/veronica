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
	main._build_world(); main._begin_play(false)
	await physics_frame
	await snap("h_north", Vector3(0, 0, 10.5), Vector3(0, 1.4, -8))
	await snap("h_desk", Vector3(0.0, 0, 5.0), Vector3(2.6, 0.9, 8.0))
	await snap("h_south", Vector3(0, 0, -2.0), Vector3(0, 1.4, 11))
	await snap("h_west", Vector3(3.0, 0, 3.0), Vector3(-4.0, 1.3, 3.5))
	quit()
