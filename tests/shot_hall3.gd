extends SceneTree
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 10) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png("/home/claude/" + name + ".png")
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	# 正对着看:正常
	await snap("f_calm", Vector3(-1.6, 0, -9.5), Vector3(-3.96, 1.75, -9.5), 12)
	# 转过身再回头(背对 0.6 秒后,摄像机转回之前的瞬间画面):手动把所有 frame 设为恐怖态来截图
	for n in main.world.get_children():
		if n.has_method("_process") and n.get("creepy") != null:
			n.mat.albedo_texture = n.creepy
	await snap("f_creepy_nun", Vector3(-1.6, 0, -9.5), Vector3(-3.96, 1.75, -9.5), 3)
	await snap("f_creepy_family", Vector3(1.5, 0, -3.0), Vector3(3.96, 1.75, -3.0), 3)
	await snap("f_creepy_portrait", Vector3(-1.6, 0, 9.5), Vector3(-3.96, 1.75, 9.5), 3)
	quit()
