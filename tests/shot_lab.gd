extends SceneTree
## 实验室:柜子惊吓的半个人体模型(扑出顶点 + 落地后)。输出 SHOT_DIR/lab_*.png
var main
func _find_tor(n: Node) -> Node3D:
	if n is Node3D and (n as Node3D).position.distance_to(Vector3(3.7, 0.2, -25.55)) < 0.01:
		return n
	for c in n.get_children():
		var r := _find_tor(c)
		if r != null: return r
	return null
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 8) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame; await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	main.boss.visible = false
	var tor := _find_tor(main.world)
	print("tor found: ", tor != null)
	# 打开柜门,摆成扑出的顶点
	for n in main.world.get_children(): pass
	tor.position = Vector3(3.7, 1.1, -23.9)
	tor.rotation_degrees = Vector3(-30, 0, 0)
	await snap("lab_cab_lunge", Vector3(3.7, 0, -22.3), Vector3(3.7, 1.2, -24.2))
	tor.position = Vector3(3.7, 0.2, -23.6)
	tor.rotation_degrees = Vector3(-90, 40, 0)
	await snap("lab_cab_floor", Vector3(3.2, 0, -22.2), Vector3(3.7, 0.3, -23.6))
	quit()
