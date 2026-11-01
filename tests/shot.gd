extends SceneTree
# 用法: godot --path . -s tests/shot.gd -- scene_id
func _snap(path: String) -> void:
	await process_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(path)
	print("saved ", path, " ", img.get_size())

func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title()
	gs.reset()
	main._build_world()
	main._begin_play(false)
	ui.toast("", 0.1)
	for i in 10: await physics_frame
	var p = main.player
	p.global_position = Vector3(0, 0, 9)
	p.face_point(Vector3(-2.5, 1.5, -5))
	for i in 5: await physics_frame
	await _snap("/home/claude/shot_hall.png")
	quit()
