extends SceneTree
const ML = preload("res://scripts/meshlib.gd")
const Draw = preload("res://scripts/draw.gd")
func _initialize() -> void:
	var w := Node3D.new()
	root.add_child(w)
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.08, 0.08, 0.1)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.5, 0.5, 0.55)
	e.ambient_light_energy = 0.6
	env.environment = e
	w.add_child(env)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-30, 200, 0)
	sun.light_energy = 1.4
	w.add_child(sun)
	var specs := [
		{"x": -0.5, "head": {"gaunt": 0.0}, "face": {"skin": Color(0.82, 0.66, 0.56), "female": true, "blush": 0.3, "lips": Color(0.7, 0.3, 0.32), "iris": Color(0.25, 0.35, 0.3)}},
		{"x": -0.25, "head": {"gaunt": 0.9, "socket": 1.0, "chin": 1.2, "brow": 1.3}, "face": {"skin": Color(0.78, 0.74, 0.66), "eyes": "hollow", "bags": 0.9, "age": 0.9, "grin": 0.7, "stubble": 0.3}},
		{"x": 0.0, "head": {"gaunt": 0.5, "socket": 0.8}, "face": {"skin": Color(0.82, 0.68, 0.6), "eyes": "wild", "bags": 0.8, "age": 0.7, "grin": 0.4, "stubble": 0.6, "brow_tilt": 0.01}},
		{"x": 0.25, "head": {"jaw_w": 1.0, "width": 1.0}, "face": {"skin": Color(0.86, 0.72, 0.62), "mustache": true, "eyes": "normal", "blush": 0.5}},
		{"x": 0.5, "head": {"gaunt": 1.0, "skull": 1.0, "socket": 1.0, "split": true}, "face": {"skin": Color(0.6, 0.62, 0.58), "eyes": "glow", "dead": true, "grin": 1.0}},
	]
	for s in specs:
		var h := ML.head(s["head"])
		var mi := MeshInstance3D.new()
		mi.mesh = h["upper"]
		var m := StandardMaterial3D.new()
		m.albedo_texture = Draw.face_texture(s["face"])
		m.roughness = 0.6
		m.texture_repeat = false
		mi.material_override = m
		mi.position = Vector3(s["x"], 0, 0)
		w.add_child(mi)
		if h["jaw"] != null:
			var jm := MeshInstance3D.new()
			jm.mesh = h["jaw"]
			jm.material_override = m
			jm.position = Vector3(s["x"], 0, 0) + h["pivot"]
			w.add_child(jm)
	var cam := Camera3D.new()
	cam.position = Vector3(0, 0.0, -1.15)
	cam.rotation_degrees = Vector3(0, 180, 0)
	cam.fov = 40
	w.add_child(cam)
	cam.current = true
	for i in 6: await process_frame
	root.get_texture().get_image().save_png("/home/claude/head_test.png")
	print("saved")
	quit()
