extends SceneTree
## 厕所清洁工具柜 + 修女在门外徘徊(从柜子里往外看、从厕所里往门口看)。输出 SHOT_DIR/hd_*.png
var main
func save(name: String) -> void:
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var st = main.statue
	p.global_position = Vector3(6.65, 0, 5.2)
	p.face_point(Vector3(6.65, 1.1, 7.15))
	for i in 12: await physics_frame
	save("hd_closet")
	p.global_position = Vector3(-2.5, 0, -3.6)
	p.face_point(st.head.global_position)
	st.tweezers_inter.interact()
	for i in 200: await physics_frame
	p.global_position = Vector3(6.65, 0, 6.0)
	p.face_point(Vector3(6.65, 1.1, 7.15))
	for i in 4: await physics_frame
	p.target_inter.interact()
	for i in 60 * 10: await physics_frame
	p.leave_hide()
	p.global_position = Vector3(6.0, 0, 4.0)
	p.face_point(Vector3(2.6, 1.6, 4.0))
	for i in 20: await physics_frame
	save("hd_lurk")
	quit()
