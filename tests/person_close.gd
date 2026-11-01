extends SceneTree
const P = preload("res://scripts/person.gd")
func _initialize() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.1, 0.1, 0.12)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.55)
	e.ambient_light_energy = 0.5
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-35, 160, 0)
	sun.light_energy = 1.5
	w.add_child(sun)
	var people := [
		# Veronica
		{"x": -2.4, "o": {"female": true, "skin": Color(0.82, 0.66, 0.56), "cloth": "jacket", "coat": Color(0.3, 0.34, 0.22), "pants": Color(0.13, 0.15, 0.22), "hair": Color(0.22, 0.12, 0.07), "long_hair": true, "strap": true,
			"face": {"blush": 0.3, "lips": Color(0.68, 0.32, 0.32), "iris": Color(0.2, 0.4, 0.3), "brow": Color(0.15, 0.09, 0.06)}}},
		# 秃头大叔(镜中鬼)
		{"x": -1.2, "o": {"skin": Color(0.76, 0.72, 0.64), "cloth": "labcoat", "coat": Color(0.85, 0.85, 0.82), "pants": Color(0.2, 0.2, 0.22), "glasses": true, "hunch": -0.14, "arm_len": 1.2, "neck_len": 0.03, "wisps": true,
			"head": {"gaunt": 0.9, "socket": 1.0, "chin": 1.2, "brow": 1.3}, "face": {"eyes": "hollow", "bags": 0.9, "age": 0.9, "grin": 0.8, "stubble": 0.3}, "curl": 0.6}},
		# Boss
		{"x": 0.0, "o": {"skin": Color(0.82, 0.68, 0.6), "cloth": "labcoat", "coat": Color(0.78, 0.77, 0.72), "stains": true, "hunch": -0.22, "wisps": true, "glove": Color(0.35, 0.65, 0.5),
			"head": {"gaunt": 0.5, "socket": 0.8}, "face": {"eyes": "wild", "bags": 0.8, "age": 0.7, "grin": 0.4, "stubble": 0.6, "brow_tilt": 0.01}, "curl": 0.5}},
		# 医生鬼魂
		{"x": 1.2, "o": {"ghost": true, "skin": Color(0.6, 0.78, 1.0), "cloth": "labcoat", "coat": Color(0.6, 0.8, 1.0), "glasses": true, "hunch": -0.1, "wisps": true,
			"head": {"gaunt": 0.7}, "face": {"tears": true, "eyes": "normal", "age": 0.8, "bags": 0.6, "brow_tilt": -0.012}}},
		# 小女孩
		{"x": 2.2, "s": 0.62, "o": {"female": true, "skin": Color(0.86, 0.7, 0.6), "cloth": "dress", "coat": Color(0.75, 0.3, 0.4), "pants": Color(0.75, 0.3, 0.4), "hair": Color(0.18, 0.1, 0.05), "hair_style": "braids", "legs_bare": false,
			"head": {"width": 1.05, "height": 0.98}, "face": {"mustache": true, "blush": 0.4, "age": 0.0, "brow": Color(0.1, 0.06, 0.04)}}},
	]
	for pp in people:
		var h := P.build(pp["o"])
		h["root"].position = Vector3(pp["x"], 0, 0)
		h["root"].scale = Vector3.ONE * pp.get("s", 1.0)
		h["root"].rotation_degrees.y = 180.0
		w.add_child(h["root"])
	var cam := Camera3D.new()
	cam.position = Vector3(0, 1.55, 3.0)
	cam.fov = 28
	w.add_child(cam)
	cam.current = true
	cam.look_at(Vector3(0, 1.45, 0))
	for i in 8: await process_frame
	root.get_texture().get_image().save_png("/home/claude/person_close.png")
	print("saved")
	quit()
