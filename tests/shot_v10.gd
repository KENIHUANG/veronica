extends SceneTree
## v10 新内容截图:排污阀、假发、序幕、开局自动弹出的检测报告、结局小女孩。输出 SHOT_DIR/v10_*.png
var main
func save(name: String) -> void:
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 12, fov: float = 75.0) -> void:
	var p = main.player
	p.cam.fov = fov
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame; await process_frame
	save(name)
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	# 序幕第 4 页(小女孩谣言)+ 开局报告
	main.new_game()
	for k in 3:
		for i in 140: await process_frame
		ui._advance_intro(); ui._advance_intro()
	for i in 160: await process_frame
	save("v10_intro")
	for k in 6:
		if ui.intro_ui == null: break
		ui._advance_intro(); ui._advance_intro()
		for i in 20: await process_frame
	for i in 30: await process_frame
	save("v10_report")
	ui.close_modal()
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	main.boss.visible = false
	main.boss.process_mode = Node.PROCESS_MODE_DISABLED
	await snap("v10_valve", Vector3(4.0, 0, -20.4), Vector3(5.8, 1.3, -21.2), 20)
	await snap("v10_wigs", Vector3(-3.6, 0, -24.6), Vector3(-3.9, 1.62, -25.74), 12, 30.0)
	await snap("v10_wigs_side", Vector3(-2.9, 0, -25.2), Vector3(-3.9, 1.62, -25.74), 12, 30.0)
	main._ending_outdoor()
	for i in 200: await process_frame
	for k in 4:
		ui._advance_dialogue()
		for i in 70: await process_frame
	save("v10_girl")
	quit()
