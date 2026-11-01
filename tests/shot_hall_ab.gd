extends SceneTree
## 大厅三个固定机位,用于画面风格前后对比。输出 SHOT_DIR/<PREFIX>hall_<n>.png
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 10) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame; await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + OS.get_environment("PREFIX") + name + ".png")
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
	await snap("hall_1", Vector3(0, 0, 9.0), Vector3(-2.5, 1.6, -5.0), 20)
	await snap("hall_2", Vector3(-1.0, 0, -1.8), Vector3(-2.5, 2.0, -5.0))
	await snap("hall_3", Vector3(1.5, 0, -3.0), Vector3(3.96, 1.75, -3.0))
	quit()
