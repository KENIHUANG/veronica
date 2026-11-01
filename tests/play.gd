extends SceneTree

var gs
var ui
var main

func frames(n: int) -> void:
	for i in n:
		await physics_frame

func _initialize() -> void:
	gs = root.get_node("GS")
	ui = root.get_node("UI")
	main = load("res://scenes/main.tscn").instantiate()
	root.add_child(main)
	await process_frame
	gs.reset()
	ui.hide_title()
	main._build_world()
	main._begin_play()
	await frames(5)
	var p = main.player
	var st = main.statue
	# ---- 1. 拿镊子 -> 追击 ----
	p.global_position = Vector3(-2.5, 0, -3.0)
	st.tweezers_inter.interact()
	print("tweezers: has=", gs.has_item("tweezers"), " statue_state=", st.state, " awakened=", gs.has_flag("statue_awakened"))
	# 玩家跑进厕所镜子前
	p.global_position = Vector3(8.0, 0, 2.2)
	p.hidden = false
	var t0 := 0
	var reached := false
	for i in 1800:
		await physics_frame
		if st.global_position.distance_to(p.global_position) < 2.6:
			reached = true
			t0 = i
			break
	print("statue reached restroom player: ", reached, " after frames=", t0, " statue_pos=", st.global_position)
	# ---- 2. 镜子事件 + 碎片 ----
	gs.set_flag("mirror_event_done")
	main.give_item("mirror_shard")
	st._begin_stab()
	for i in 6:
		ui._qte_press()
	print("statue defeated state=", st.state, " flag=", gs.has_flag("statue_defeated"))
	st.button_inter.interact()
	print("keycard=", gs.has_item("lab_keycard"), " ckpt_has_pos=", gs.checkpoint.has("pos"))
	# ---- 3. 门禁:重建世界后实验室门应保持开启状态 ----
	gs.set_flag("lab_unlocked")
	gs.set_flag("office_unlocked")
	gs.set_flag("safe_opened")
	main._build_world()
	p = main.player
	await frames(3)
	# ---- 4. Boss 序幕 ----
	p.global_position = Vector3(0, 0, -13.5)
	main.on_lab_enter()
	await create_timer(1.6).timeout
	print("boss visible after intro start: ", main.boss.visible, " dlg_active=", ui.dlg_active)
	for i in 12:
		ui._advance_dialogue()
		ui._advance_dialogue()
	await frames(3)
	print("boss state after dialogue (CHASE=3): ", main.boss.state, " player.locked=", p.locked)
	# 追击:玩家站在原地,boss 应冲过来并攻击
	p.global_position = Vector3(0, 0, -14.0)
	var hp0: int = gs.hp
	for i in 900:
		await physics_frame
		if gs.hp < hp0:
			print("boss hit player after frames ", i, " hp=", gs.hp)
			break
	print("hp now=", gs.hp, " boss_state=", main.boss.state)
	# 躲藏:进储物柜
	gs.hp = 5
	p.dead = false
	p.global_position = Vector3(-4.6, 0, -15.7)
	p.enter_hide(Vector3(-5.55, 0, -15.7), -PI / 2.0, Vector3(-4.6, 0, -15.7), func(): pass, func(): pass)
	await frames(400)
	print("after hiding boss_state (SEARCH=2/PATROL=1): ", main.boss.state)
	p.leave_hide()
	# ---- 5. 离开/返回循环 ----
	p.global_position = Vector3(0, 0, 5)  # 玩家远离实验室
	main.boss.begin_patrol()
	main.boss.global_position = Vector3(0, 0, -14.5)
	main.boss.patrol_time = 100.0
	var went_away := false
	for i in 3000:
		await physics_frame
		if main.boss.state == 5:
			went_away = true
			main.boss.timer = 0.5
			break
	print("boss went away: ", went_away)
	for i in 1200:
		await physics_frame
		if main.boss.state == 1:
			break
	print("boss back to patrol (state 1): ", main.boss.state, " visible=", main.boss.visible)
	# ---- 6. 调配 ----
	var Lab = load("res://scripts/rooms/lab.gd")
	print("mix ok: ", Lab._check_mix([5, 30, 40, 20, 5])["ok"], " | wrong: ", Lab._check_mix([5, 30, 40, 20, 4])["msg"], " | ", Lab._check_mix([6, 30, 40, 20, 5])["msg"], " | ", Lab._check_mix([0, 30, 40, 20, 6])["msg"])
	Lab._mix_ok(main)
	print("tonic=", gs.has_item("perfect_hair_tonic"))
	# ---- 7. 结局 ----
	p.dead = false
	gs.set_flag("photo_assembled")
	gs.set_flag("valve_closed")
	if OS.get_environment("ALL_LETTERS") == "1":
		for k in 5: gs.set_flag("letter_%d" % k)
	main.handover()
	var stage_log := []
	var seen := {}
	for i in 400:
		await create_timer(0.25).timeout
		if ui.dlg_active:
			seen[str(ui.dlg_text.text)] = true
		ui._advance_dialogue()
		if ui.intro_ui != null:
			ui._advance_intro()
		if gs.has_flag("game_completed") and not "completed" in stage_log:
			stage_log.append("completed")
		if ui.screen_kind == "end":
			break
	var mother := false
	for k in seen.keys():
		if "封都没看" in k or "never read a single one" in k: mother = true
	print("mother scene shown: ", mother)
	print("ending flag=", gs.has_flag("game_completed"), " end-screen=", ui.screen_kind)
	quit()
