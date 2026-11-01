extends SceneTree
## 预渲染墙上的字、海报、血字到 assets/baked/(中英文各一套)。改了这些文字或样式后重新运行:
##   BAKE_TEX=1 godot --path . -s tools/bake_textures.gd -- zh
##   BAKE_TEX=1 godot --path . -s tools/bake_textures.gd -- en
## 需要真实渲染器(不能 --headless);没有显卡的机器可以用 xvfb-run + --rendering-driver opengl3。
func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	var lang: String = args[0] if args.size() > 0 else "zh"
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = lang
	ui.hide_title(); gs.reset()
	main._build_world(); main._begin_play(false)
	for i in 240: await process_frame
	var d := DirAccess.open("res://assets/baked")
	var n := 0
	if d != null:
		for f in d.get_files():
			if f.ends_with(".png"): n += 1
	print("baked textures now: ", n, " (lang ", lang, ")")
	quit()
