extends SceneTree

func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	await process_frame
	print("TITLE OK")
	gs.reset()
	ui.hide_title()
	main._build_world()
	main._begin_play()
	for i in 20:
		await physics_frame
	print("WORLD BUILT; children=", main.world.get_child_count(), " player_y=", main.player.global_position.y)
	quit()
