extends SceneTree
func snap(name: String, wait: int = 4) -> void:
	for i in wait:
		await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/home/claude/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var L = root.get_node("L")
	var touch = root.get_node("Touch")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	L.set_lang("en")
	await snap("ui_title_en", 6)
	var args := OS.get_cmdline_user_args()
	var tag: String = args[0] if args.size() > 0 else "gl"
	touch.enabled = true
	touch.canvas.visible = true
	ui.hide_title(); gs.reset(); gs.set_flag("restroom_open")
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	p.global_position = Vector3(8.25, 0, 2.2)
	p.face_point(Vector3(8.25, 1.7, 0.0))
	touch._layout()
	await snap("ui_touch_" + tag, 14)
	quit()
