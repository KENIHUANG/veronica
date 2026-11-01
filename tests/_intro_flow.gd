extends SceneTree
func _initialize() -> void:
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	main.new_game()
	for k in 12:
		for i in 20: await process_frame
		if ui.intro_ui == null: break
		ui._advance_intro(); ui._advance_intro()
	for i in 30: await process_frame
	ui.close_modal()
	for i in 30: await process_frame
	print("disable_3d=", root.get_viewport().disable_3d, " cam current=", main.player.cam.current)
	root.get_texture().get_image().save_png("/home/claude/shots/native_after_intro.png")
	quit()
