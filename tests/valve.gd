extends SceneTree
## 排污阀:能瞄准;QTE 失败会把走开的弟子1号叫回来;成功后 valve_closed,滴水停止,交药才可用。
## 另外检查保险箱:弹出获得物品 → 关掉后自动打开日记 → 再关掉触发收音机。
## 通过时输出 "valve fails: 0"
var fails := 0
func _initialize() -> void:
	var gs = root.get_node("GS"); var ui = root.get_node("UI")
	var main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	root.get_node("L").lang = "zh"
	ui.hide_title(); gs.reset()
	for f in ["restroom_open", "office_unlocked", "lab_unlocked", "statue_defeated", "boss_intro_done"]:
		gs.set_flag(f)
	main._build_world(); main._begin_play(false)
	await physics_frame
	var p = main.player
	var b = main.boss
	var VP := Vector3(5.72, 1.1, -21.2)
	for st in [Vector3(4.6, 0, -21.2), Vector3(4.8, 0, -20.6), Vector3(4.8, 0, -21.9)]:
		p.global_position = st
		p.face_point(VP)
		for i in 4: await physics_frame
		var ok: bool = "排污阀" in ui.prompt_label.text
		if not ok: fails += 1
		print("valve from ", st, " -> [", ui.prompt_label.text, "] ", "OK" if ok else "FAIL")
	# 让弟子1号处于"走开"状态,然后故意让 QTE 失败
	b.state = b.S.AWAY
	b.timer = 25.0
	b.visible = false
	p.global_position = Vector3(4.6, 0, -21.2)
	p.face_point(VP)
	for i in 4: await physics_frame
	p.target_inter.interact()
	for i in 240: await physics_frame       # 超时 → 失败
	var called_back: bool = b.timer <= 1.6 or b.state != b.S.AWAY
	if not called_back: fails += 1
	print("qte fail called boss back: ", called_back, " (state ", b.state, " timer ", snappedf(b.timer, 0.1), ")")
	var hand_prompt_before: String = b.handover_inter.current_prompt()
	# 再来一次,这次连按成功
	p.target_inter.interact()
	for i in 14:
		ui._qte_press()
		await process_frame
	var closed: bool = gs.has_flag("valve_closed")
	if not closed: fails += 1
	print("valve closed: ", closed)
	gs.add_item("perfect_hair_tonic")
	b.state = b.S.PATROL
	var hp: String = b.handover_inter.current_prompt()
	var hand_ok: bool = hp != ""
	if not hand_ok: fails += 1
	print("handover prompt after valve: [", hp, "] (before, without tonic: [", hand_prompt_before, "])")
	gs.remove_item("perfect_hair_tonic")
	# 保险箱流程
	var Office = load("res://scripts/rooms/office.gd")
	Office._safe_open(main)
	await process_frame
	var first_open: bool = ui.blocked()
	ui.close_modal()
	await process_frame
	var diary_open: bool = ui.blocked()
	ui.close_modal()
	for i in 3: await process_frame
	var radio: bool = main.radio_active or gs.has_flag("radio_event_done")
	var safe_ok: bool = first_open and diary_open and radio and gs.has_item("doctor_diary")
	if not safe_ok: fails += 1
	print("safe: obtained-modal=", first_open, " diary-opened=", diary_open, " radio=", radio)
	print("valve fails: ", fails)
	quit()
