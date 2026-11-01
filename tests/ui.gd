extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.show_title(true)
	await process_frame
	ui.hide_title()
	gs.reset()
	main._build_world(); main._begin_play(false)
	await process_frame
	for id in ["tweezers", "photo_pieces", "doctor_diary", "hair_tonic_spray"]:
		gs.add_item(id)
	ui.open_inventory(main.use_item); await process_frame; ui.close_modal()
	ui.open_reader("t", ["a", "b"]); await process_frame; ui.close_modal()
	ui.open_safe(func(): pass); await process_frame; ui.close_modal()
	ui.open_photo_puzzle(func(): pass); await process_frame
	# 解开拼图
	print("photo modal ok: ", ui.modal != null)
	ui.close_modal()
	var Lab = load("res://scripts/rooms/lab.gd")
	ui.open_mixer(Lab.NAMES, Lab._check_mix, func(): pass); await process_frame; ui.close_modal()
	ui.open_terminal("SARAH0203", "log", func(): pass); await process_frame; ui.close_modal()
	ui.show_pause(); await process_frame; ui.hide_screen()
	ui.show_gameover(); await process_frame; ui.hide_screen()
	ui.show_the_end(); await process_frame; ui.hide_screen()
	ui.show_intro(["a", "b"], func(): print("intro done")); await process_frame
	ui._advance_intro(); ui._advance_intro(); ui._advance_intro(); ui._advance_intro()
	ui.say(["x|hello", "narration"], func(): print("say done")); await process_frame
	for i in 6: ui._advance_dialogue()
	# 射线提示测试
	var p = main.player
	p.global_position = Vector3(0, 0, 11)
	p.face_point(Vector3(4.1, 1.2, 4.0))
	p.global_position = Vector3(2.0, 0, 4.0)
	p.face_point(Vector3(4.1, 1.2, 4.0))
	for i in 4: await physics_frame
	print("prompt at restroom door: [", ui.prompt_label.text, "]")
	p.global_position = Vector3(8.2, 0, 2.2)
	p.face_point(Vector3(8.25, 1.85, 0.2))
	for i in 4: await physics_frame
	print("prompt at mirror: [", ui.prompt_label.text, "]")
	p.global_position = Vector3(-2.5, 0, -2.8)
	p.face_point(Vector3(-2.2, 1.5, -4.1))
	for i in 4: await physics_frame
	print("prompt at statue tweezers: [", ui.prompt_label.text, "]")
	p.global_position = Vector3(0, 0, -10.5)
	p.face_point(Vector3(0, 1.2, -12.1))
	for i in 4: await physics_frame
	print("prompt at lab door: [", ui.prompt_label.text, "]")
	quit()
