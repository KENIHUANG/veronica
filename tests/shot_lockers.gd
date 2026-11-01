extends SceneTree
## 储物柜/清洁工具柜:外观 + 躲进去后的视角。输出 SHOT_DIR/lk_*.png
var main
func save(name: String) -> void:
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 10) -> void:
	var p = main.player
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
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	main.boss.visible = false
	main.boss.process_mode = Node.PROCESS_MODE_DISABLED
	var zs: Array = OS.get_environment("LOCKER_Z").split(",")
	var z := float(zs[0])
	await snap("lk_lab_out", Vector3(-3.2, 0, z + 1.2), Vector3(-5.5, 1.0, z))
	await snap("lk_lab_side", Vector3(-4.4, 0, z + 1.6), Vector3(-5.5, 1.2, z))
	await snap("lk_lab_near", Vector3(-4.6, 0, z), Vector3(-5.5, 1.3, z))
	main.player.global_position = Vector3(-4.6, 0, z)
	main.player.face_point(Vector3(-5.5, 1.0, z))
	for i in 4: await physics_frame
	if main.player.target_inter: main.player.target_inter.interact()
	for i in 10: await physics_frame
	save("lk_lab_inside")
	main.player.leave_hide()
	await snap("lk_closet_out", Vector3(6.65, 0, 5.4), Vector3(6.65, 1.0, 7.5))
	await snap("lk_closet_side", Vector3(8.0, 0, 6.2), Vector3(6.65, 1.0, 7.5))
	main.player.global_position = Vector3(6.65, 0, 6.3)
	main.player.face_point(Vector3(6.65, 1.0, 7.3))
	for i in 4: await physics_frame
	if main.player.target_inter: main.player.target_inter.interact()
	for i in 10: await physics_frame
	save("lk_closet_inside")
	quit()
