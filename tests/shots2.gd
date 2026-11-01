extends SceneTree
var main
var gs
var ui

func snap(name: String, pos: Vector3, target: Vector3, wait: int = 6) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait:
		await physics_frame
	await process_frame
	await process_frame
	var img := root.get_texture().get_image()
	img.save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)

func _initialize() -> void:
	gs = root.get_node("GS")
	ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title()
	gs.reset()
	gs.set_flag("restroom_open")
	main._build_world()
	main._begin_play(false)
	await physics_frame
	var args := OS.get_cmdline_user_args()
	var which: String = args[0] if args.size() > 0 else "all"
	# 1 雕像近景
	if which == "all" or which == "statue":
		await snap("s_statue_close", Vector3(-2.5, 0, -2.6), Vector3(-2.5, 1.9, -5.0))
		main.statue.player = main.player
		main.statue.awaken()
		for i in 100:
			await physics_frame
		await snap("s_statue_scream", Vector3(-2.5, 0, -2.6), Vector3(-2.5, 1.9, -5.0), 2)
	if which == "all" or which == "restroom":
		var d = null
		await snap("s_rest_over", Vector3(5.0, 0, 3.0), Vector3(9.0, 1.2, 3.5))
		await snap("s_sinks", Vector3(7.8, 0, 2.0), Vector3(7.8, 1.0, 0.0))
		await snap("s_mirror_reflect", Vector3(8.25, 0, 2.2), Vector3(8.25, 1.7, 0.0), 12)
		main.mirror.lag = true
		main.mirror.flicker_preview()
		await process_frame
		root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/s_mirror_flicker.png")
		for i in 10: await process_frame
		main.mirror.show_bald()
		await snap("s_mirror_bald", Vector3(8.25, 0, 2.2), Vector3(8.25, 1.7, 0.0), 12)
		main.mirror.lunge(0.3)
		await snap("s_mirror_lunge_mid", Vector3(8.25, 0, 2.2), Vector3(8.25, 1.7, 0.0), 9)
		await snap("s_mirror_lunge", Vector3(8.25, 0, 2.2), Vector3(8.25, 1.7, 0.0), 40)
		main.mirror.shatter()
		await snap("s_mirror_broken", Vector3(8.25, 0, 2.2), Vector3(8.25, 1.7, 0.0), 4)
	quit()
