extends SceneTree
## 厕所:洗手台与马桶(检查替换槽摆放)。输出 SHOT_DIR/rp_*.png
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 8) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame; await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").retro = false
	root.get_node("L").changed.emit()
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	await snap("rp_sinks", Vector3(7.0, 0, 2.6), Vector3(7.6, 0.8, 0.0))
	await snap("rp_sinks_side", Vector3(5.4, 0, 1.0), Vector3(8.0, 0.8, 0.3))
	# 隔间门全部打开后看马桶
	for n in main.world.find_children("*", "", true, false):
		if n.has_method("set_open"): n.set_open(true, false)
	for i in 3: await physics_frame
	await snap("rp_toilet", Vector3(10.0, 0, -1.0), Vector3(11.6, 0.4, -1.0))
	await snap("rp_toilets", Vector3(9.4, 0, 2.6), Vector3(11.6, 0.4, -2.0))
	quit()
