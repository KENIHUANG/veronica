extends SceneTree
## 墙上的字:厕所血字、办公室白板、实验室便利贴、大厅标牌。输出 SHOT_DIR/wr_*.png
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 10, fov: float = 75.0) -> void:
	var p = main.player
	p.cam.fov = fov
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
	if OS.get_environment("LANG_ZH") == "1":
		root.get_node("L").lang = "zh"
	if OS.get_environment("RETRO") == "0":
		root.get_node("L").retro = false
		root.get_node("L").changed.emit()
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	main.boss.visible = false
	for n in main.world.find_children("*", "", true, false):
		if n.has_method("set_open"): n.set_open(true, false)
	await snap("wr_blood", Vector3(10.3, 0, 5.2), Vector3(11.93, 1.3, 5.2), 20)
	await snap("wr_board", Vector3(-7.7, 0, -2.2), Vector3(-7.7, 1.7, -3.97), 10)
	await snap("wr_note", Vector3(4.9, 0, -15.5), Vector3(5.95, 1.62, -15.5), 10, 40.0)
	await snap("wr_hall", Vector3(0, 0, -6.5), Vector3(0, 2.6, -11.95), 10)
	quit()
