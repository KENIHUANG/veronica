extends SceneTree
## 序幕第一页 + 背包检测报告截图
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	root.get_node("L").lang = "zh"
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	main.new_game()
	for i in 90: await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/intro_1.png")
	ui.hide_title(); gs.reset()
	main._build_world(); main._begin_play(false)
	gs.add_item("water_report")
	main.use_item("water_report")
	for i in 30: await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/report_1.png")
	print("ok")
	quit()
