extends SceneTree
## 墙面文字与海报。输出 SHOT_DIR/sg_*.png
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 12) -> void:
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
	root.get_node("L").lang = "zh" if OS.get_environment("LANG_ZH") != "0" else "en"
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	main.boss.visible = false
	main.boss.process_mode = Node.PROCESS_MODE_DISABLED
	await snap("sg_poster", Vector3(2.4, 0, 10.3), Vector3(3.94, 1.72, 10.3), 25)
	await snap("sg_lab_sign", Vector3(0, 0, -7.0), Vector3(0, 2.6, -11.94))
	await snap("sg_doors", Vector3(0, 0, 2.0), Vector3(3.94, 2.0, 4.0))
	await snap("sg_office", Vector3(0, 0, 0.0), Vector3(-3.94, 2.1, 0.0))
	await snap("sg_danger", Vector3(0, 0, -21.5), Vector3(0, 2.2, -25.94))
	quit()
