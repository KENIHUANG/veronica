extends SceneTree
func _initialize() -> void:
	var gs = root.get_node("GS")
	var ui = root.get_node("UI")
	var touch = root.get_node("Touch")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	ui.hide_title(); gs.reset()
	main._build_world(); main._begin_play(false)
	await physics_frame
	touch.enabled = true
	touch._layout()
	print("viewport size: ", touch._size(), " active=", touch.active())
	var ev := InputEventScreenTouch.new()
	ev.index = 0; ev.position = Vector2(200, 500); ev.pressed = true
	Input.parse_input_event(ev)
	Input.flush_buffered_events()
	await process_frame
	print("fingers after press: ", touch.fingers)
	var dv := InputEventScreenDrag.new()
	dv.index = 0; dv.position = Vector2(200, 430); dv.relative = Vector2(0, -70)
	Input.parse_input_event(dv)
	Input.flush_buffered_events()
	await process_frame
	print("move after drag: ", touch.move, " center=", touch.stick_center)
	quit()
