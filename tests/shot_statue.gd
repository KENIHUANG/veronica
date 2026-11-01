extends SceneTree
## 修女石像:静止 / 尖叫(下颌张开、红眼)/ 塌陷(头顶按钮)。输出 SHOT_DIR/st_*.png
var main
func snap(name: String, pos: Vector3, target: Vector3, wait: int = 6) -> void:
	var p = main.player
	p.global_position = pos
	p.face_point(target)
	for i in wait: await physics_frame
	await process_frame
	await process_frame
	root.get_texture().get_image().save_png(OS.get_environment("SHOT_DIR") + "/" + name + ".png")
	print("saved ", name)
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	main._build_world(); main._begin_play(false)
	await physics_frame
	var st = main.statue
	var hp: Vector3 = st.head.global_position
	await snap("st_idle_far", Vector3(-2.5, 0, -1.2), hp, 6)
	main.player.cam.fov = 22.0
	await snap("st_idle_zoom", Vector3(-2.5, 0, -1.6), hp, 6)
	main.player.cam.fov = 75.0
	await snap("st_idle", Vector3(-2.5, 0, -3.6), hp, 6)
	await snap("st_idle_side", Vector3(-1.3, 0, -4.2), hp, 6)
	st.player = main.player
	st.awaken()
	for i in 70: await physics_frame
	main.player.face_point(st.head.global_position)
	await snap("st_scream", main.player.global_position, st.head.global_position, 2)
	main.player.cam.fov = 22.0
	await snap("st_scream_zoom", Vector3(-2.5, 0, -1.6), st.head.global_position, 2)
	main.player.cam.fov = 75.0
	print("jaw x=", st.jaw.rotation.x, " eyes visible=", st.eyes[0].visible)
	st.set_defeated_instant()
	for i in 4: await physics_frame
	await snap("st_collapsed", st.global_position + Vector3(0, 0, 1.6), st.button_mi.global_position, 6)
	main.player.cam.fov = 30.0
	await snap("st_collapsed_zoom", st.global_position + Vector3(0, 0, 2.4), st.button_mi.global_position, 6)
	main.player.cam.fov = 75.0
	await snap("st_collapsed_top", st.global_position + Vector3(0.3, 0, 0.9), st.button_mi.global_position, 6)
	quit()
