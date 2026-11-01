extends SceneTree
## 5 封来信的位置 + 阅读界面。输出 SHOT_DIR/lt_*.png
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 10) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame; await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done", "cabinet_scare"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	main.boss.visible = false
	main.boss.process_mode = Node.PROCESS_MODE_DISABLED
	await snap("lt_0", Vector3(2.0, 0, 8.6), Vector3(3.73, 1.6, 8.6), 20)
	await snap("lt_1", Vector3(5.0, 0, 5.8), Vector3(5.0, 0.66, 7.25))
	await snap("lt_2", Vector3(-6.4, 0, -0.4), Vector3(-4.9, 0.02, -0.7))
	await snap("lt_3", Vector3(-6.48, 0, -2.7), Vector3(-6.48, 1.5, -3.95))
	await snap("lt_4", Vector3(3.7, 0, -24.4), Vector3(3.75, 0.06, -25.7))
	main.player.target_inter.interact()
	for i in 20: await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/lt_read.png")
	quit()
