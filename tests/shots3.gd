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
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	for c in main.world.get_children():
		if c.has_method("set_open") and abs(c.position.x - 10.0) < 0.01:
			c.set_open(true, false)
	await snap("t_toilet1", Vector3(8.8, 0, 2.0), Vector3(11.4, 0.45, 2.0))
	await snap("t_toilet2", Vector3(8.8, 0, 3.6), Vector3(11.4, 0.5, 3.6))
	await snap("t_roach", Vector3(10.6, 0, 3.4), Vector3(11.3, 0.0, 3.6))
	await snap("t_broken", Vector3(8.25, 0, 2.2), Vector3(8.25, 1.7, 0.0))
	quit()
