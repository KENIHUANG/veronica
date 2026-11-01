extends SceneTree
## 游戏内截图:每幅"会变脸"的挂画,calm 与 creepy 两个状态。输出 SHOT_DIR/frame_<i>_<calm|creepy>.png
const CF = preload("res://scripts/creepy_frame.gd")
var main
func _find(n: Node, out: Array) -> void:
	if n.get_script() == CF:
		out.append(n)
	for c in n.get_children():
		_find(c, out)
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
	var frames: Array = []
	_find(main.world, frames)
	print("creepy frames: ", frames.size())
	var d := OS.get_environment("SHOT_DIR")
	for i in frames.size():
		var f: Node3D = frames[i]
		var fp: Vector3 = f.global_position
		var nrm: Vector3 = f.global_transform.basis.z.normalized()
		var stand := fp + nrm * 1.7
		stand.y = 0.0
		for st in ["calm", "creepy"]:
			p.global_position = stand
			p.face_point(fp)
			f.hold = 99.0
			f.state = st == "creepy"
			f.apply_state()
			for k in 8: await physics_frame
			await process_frame
			await process_frame
			root.get_texture().get_image().save_png(d + "/frame_%d_%s.png" % [i, st])
		f.hold = 0.0
		print("frame ", i, " at ", fp)
	quit()
