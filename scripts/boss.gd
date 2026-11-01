extends CharacterBody3D
## 弟子1号:巡逻 / 视野 / 听觉 / 追击 / 定期走出后门(玩家的安全窗口)。不会被杀死,通关靠交付生发剂。

const Mats = preload("res://scripts/mats.gd")
const WB = preload("res://scripts/wb.gd")
const Nav = preload("res://scripts/nav.gd")
const Humanoid = preload("res://scripts/humanoid.gd")
const Person = preload("res://scripts/person.gd")

enum S { DORMANT, PATROL, SEARCH, CHASE, LEAVING, AWAY, RETURNING, STUNNED, DONE }

const PATROL_PTS := [Vector3(0, 0, -14.5), Vector3(3, 0, -17.5), Vector3(0, 0, -19.5), Vector3(-2, 0, -23), Vector3(-4.4, 0, -20.5), Vector3(-4.4, 0, -15.5)]
const EXIT_PT := Vector3(5.3, 0, -24)
const OUT_PT := Vector3(7.8, 0, -24)
const PATROL_SPEED := 1.8
const CHASE_SPEED := 3.5
const AWAY_TIME := 28.0
const PATROL_BEFORE_LEAVE := 24.0

var state: int = S.DORMANT
var player: Node3D = null
var m = null
var exit_door: Node3D = null
var pi := 0
var timer := 0.0
var patrol_time := 0.0
var last_known := Vector3.ZERO
var lost_t := 0.0
var attack_cd := 0.0
var path_t := 0.0
var next_pt := Vector3.ZERO
var stuck_t := 0.0
var force_graph_t := 0.0
var wait_t := 0.0
var t := 0.0
var body_root: Node3D
var injector: Node3D
var handover_inter: Area3D
var head_node: Node3D

func build(main_node) -> void:
	m = main_node
	add_to_group("boss")
	collision_layer = 8
	collision_mask = 1 | 16
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.34
	cap.height = 1.85
	cs.shape = cap
	cs.position.y = 0.92
	add_child(cs)
	var hd := Person.build({
		"slot": "boss", "skin": Color(0.76, 0.63, 0.56), "cloth": "labcoat", "coat": Color(0.66, 0.65, 0.6), "stains": true, "pants": Color(0.12, 0.12, 0.15),
		"hunch": -0.22, "wisps": true, "glove": Color(0.35, 0.65, 0.5), "curl": 0.55,
		"head": {"gaunt": 0.5, "socket": 0.8, "chin": 1.1},
		"face": {"eyes": "wild", "bags": 0.85, "age": 0.75, "grin": 0.45, "stubble": 0.6, "brow_tilt": 0.01},
	})
	body_root = hd["root"]
	add_child(body_root)
	head_node = hd["head"]
	# 右臂向前伸,手里是发光的强效针;左臂像爪子一样抬起
	hd["arm_r"].rotation.x = 1.45
	hd["elbow_r"].rotation.x = 0.15
	hd["arm_l"].rotation.x = 0.5
	hd["arm_l"].rotation.z = -0.25
	injector = Node3D.new()
	injector.position = Vector3(0, -0.36, 0)
	hd["elbow_r"].add_child(injector)
	var glass := Mats.emissive(Color(0.2, 1.0, 0.35), 2.5)
	WB.cyl(injector, Vector3(0, -0.1, 0), 0.034, 0.26, glass, false)
	WB.cyl(injector, Vector3(0, 0.05, 0), 0.05, 0.015, Mats.solid(Color(0.8, 0.8, 0.85), 0.3, 0.8), false)
	WB.cyl(injector, Vector3(0, 0.1, 0), 0.01, 0.1, Mats.solid(Color(0.8, 0.8, 0.85), 0.3, 0.8), false)
	WB.cyl(injector, Vector3(0, -0.34, 0), 0.005, 0.2, Mats.solid(Color(0.85, 0.85, 0.9), 0.2, 0.9), false)
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.2, 1.0, 0.35)
	glow.light_energy = 0.5
	glow.omni_range = 3.5
	injector.add_child(glow)
	# 交付药剂的互动区
	handover_inter = WB.inter(self, Vector3(0, 1.0, 0), Vector3(1.3, 2.2, 1.3), "")
	handover_inter.prompt_fn = func():
		if GS.has_item("perfect_hair_tonic") and GS.has_flag("valve_closed") and state in [S.PATROL, S.SEARCH, S.CHASE, S.STUNNED]:
			return "把完美生发剂交给弟子1号"
		return ""
	handover_inter.action = func(): m.handover()
	visible = false
	_set_collision(false)

func _set_collision(on: bool) -> void:
	for c in get_children():
		if c is CollisionShape3D:
			c.set_deferred("disabled", not on)

func spawn_at(pos: Vector3) -> void:
	global_position = pos
	visible = true
	_set_collision(true)

func begin_chase() -> void:
	state = S.CHASE
	lost_t = 0.0
	if player != null:
		last_known = player.global_position

func begin_patrol() -> void:
	state = S.PATROL
	patrol_time = 0.0
	pi = Nav.closest_index(global_position) % PATROL_PTS.size()
	pi = _nearest_patrol()

func _nearest_patrol() -> int:
	var best := 0
	var bd := 1e9
	for i in PATROL_PTS.size():
		var d := global_position.distance_to(PATROL_PTS[i])
		if d < bd:
			bd = d
			best = i
	return best

func set_done() -> void:
	state = S.DONE
	velocity = Vector3.ZERO

func kneel() -> void:
	body_root.position.y = -0.4
	injector.visible = false

## 很大的声响(比如拧排污阀):人在外面也会被叫回来
func loud_noise(pos: Vector3) -> void:
	if state == S.AWAY:
		timer = minf(timer, 1.5)
		last_known = pos
	else:
		hear(pos)

func hear(pos: Vector3) -> void:
	if state == S.PATROL or state == S.SEARCH:
		last_known = pos
		state = S.SEARCH
		wait_t = 0.0

func _can_see_player() -> bool:
	if player == null or player.hidden or player.dead:
		return false
	var to: Vector3 = player.global_position - global_position
	to.y = 0
	var d := to.length()
	if d > 11.0:
		return false
	if not player.flash.visible and d > 6.0:
		return false
	var fwd := -global_transform.basis.z
	fwd.y = 0
	if d > 2.2 and fwd.normalized().dot(to.normalized()) < 0.55:
		return false
	var q := PhysicsRayQueryParameters3D.create(global_position + Vector3(0, 1.6, 0), player.global_position + Vector3(0, 1.3, 0), 1)
	return get_world_3d().direct_space_state.intersect_ray(q).is_empty()

func _move_to(target: Vector3, speed: float, delta: float, use_los: bool = true) -> void:
	path_t -= delta
	force_graph_t -= delta
	if path_t <= 0.0:
		path_t = 0.3
		next_pt = Nav.next_point(get_world_3d().direct_space_state, global_position, target, use_los and force_graph_t <= 0.0)
	var step := next_pt - global_position
	step.y = 0
	if step.length() > 0.1:
		velocity = step.normalized() * speed
		rotation.y = lerp_angle(rotation.y, atan2(-step.x, -step.z), 8.0 * delta)
	else:
		velocity = Vector3.ZERO
	velocity.y = -2.0
	move_and_slide()
	if speed > 1.0 and get_real_velocity().length() < 0.3:
		stuck_t += delta
		if stuck_t > 0.9:
			force_graph_t = 2.5
			stuck_t = 0.0
	else:
		stuck_t = 0.0

func _flat_dist(p: Vector3) -> float:
	return Vector2(global_position.x - p.x, global_position.z - p.z).length()

func _physics_process(delta: float) -> void:
	t += delta
	attack_cd = maxf(0.0, attack_cd - delta)
	if player == null or state == S.DORMANT or state == S.DONE or player.dead:
		return
	if player.locked or UI.blocked():
		velocity = Vector3.ZERO
		return
	injector.rotation.z = sin(t * 3.0) * 0.05
	var agitation := 1.0 if state == S.CHASE else 0.35
	head_node.rotation.z = sin(t * 9.0) * 0.05 * agitation
	head_node.rotation.x = sin(t * 5.3 + 1.0) * 0.04 * agitation
	body_root.scale.y = 1.0 + sin(t * 2.4) * 0.008
	match state:
		S.PATROL:
			patrol_time += delta
			var tgt: Vector3 = PATROL_PTS[pi]
			_move_to(tgt, PATROL_SPEED, delta)
			if _flat_dist(tgt) < 0.7:
				pi = (pi + 1) % PATROL_PTS.size()
			if _can_see_player():
				_alert()
			elif _heard():
				hear(player.global_position)
			elif patrol_time > PATROL_BEFORE_LEAVE:
				state = S.LEAVING
		S.SEARCH:
			if _can_see_player():
				_alert()
			elif _flat_dist(last_known) > 0.9:
				_move_to(last_known, PATROL_SPEED * 1.3, delta)
			else:
				wait_t += delta
				rotation.y += delta * 1.2
				if wait_t > 3.5:
					begin_patrol()
			if state == S.SEARCH and _heard():
				last_known = player.global_position
		S.CHASE:
			if _can_see_player():
				lost_t = 0.0
				last_known = player.global_position
			else:
				lost_t += delta
			if player.hidden or lost_t > 4.0:
				state = S.SEARCH
				wait_t = 0.0
				return
			_move_to(player.global_position, CHASE_SPEED, delta)
			if _flat_dist(player.global_position) < 1.4 and attack_cd <= 0.0:
				attack_cd = 1.8
				player.take_hit(2, global_position)
				state = S.STUNNED
				timer = 0.9
				velocity = Vector3.ZERO
		S.STUNNED:
			timer -= delta
			injector.rotation.z = -0.6
			if timer <= 0.0:
				state = S.CHASE
		S.LEAVING:
			_move_to(EXIT_PT, PATROL_SPEED * 1.2, delta)
			if _can_see_player():
				_alert()
			elif _flat_dist(EXIT_PT) < 0.8:
				_open_exit(true)
				state = S.AWAY
				timer = AWAY_TIME
				_set_collision(false)
				visible = false
				UI.toast("弟子1号走到了外面的走廊。趁现在!", 4.0)
		S.AWAY:
			timer -= delta
			if timer <= 0.0:
				global_position = OUT_PT
				visible = true
				_set_collision(true)
				_open_exit(true)
				state = S.RETURNING
		S.RETURNING:
			_move_to(Vector3(4.5, 0, -23.5), PATROL_SPEED * 1.2, delta, false)
			if _can_see_player():
				_alert()
			elif _flat_dist(Vector3(4.5, 0, -23.5)) < 0.9:
				_open_exit(false)
				begin_patrol()

func _heard() -> bool:
	var d := _flat_dist(player.global_position)
	return (player.running and d < 7.5) or (player.moving and d < 2.0)

func _alert() -> void:
	if state != S.CHASE:
		SFX.play("sting", -8.0)
		UI.toast("弟子1号:“头发……你的头发……”", 2.5)
	begin_chase()

func _open_exit(v: bool) -> void:
	if exit_door != null:
		exit_door.set_open(v)
		SFX.play("door", -6.0)

func grow_hair() -> void:
	var hair := Mats.solid(Color(0.16, 0.1, 0.07))
	for i in 22:
		var a := randf() * TAU
		var r := randf() * 0.16
		WB.ball(head_node, Vector3(cos(a) * r, 0.1 + randf() * 0.04, sin(a) * r), 0.03, hair)

## 头发一簇一簇冒出来,伴随金色光点与光晕
func grow_hair_animated() -> void:
	var hair := Mats.solid(Color(0.16, 0.1, 0.07), 0.8)
	for i in 70:
		var a := randf() * TAU
		var r := sqrt(randf()) * 0.066
		var topy := 0.115 * sqrt(maxf(0.0, 1.0 - pow(r / 0.078, 2.0))) + 0.012
		var tuft := WB.ball(head_node, Vector3(cos(a) * r, topy, sin(a) * r * 1.1 + 0.005), randf_range(0.014, 0.022), hair)
		tuft.scale = Vector3.ZERO
		var tw := tuft.create_tween()
		tw.tween_interval(i * 0.035)
		tw.tween_property(tuft, "scale", Vector3.ONE, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var sparks := CPUParticles3D.new()
	sparks.position = Vector3(0, 0.12, 0)
	sparks.amount = 60
	sparks.lifetime = 1.8
	sparks.emission_shape = CPUParticles3D.EMISSION_SHAPE_SPHERE
	sparks.emission_sphere_radius = 0.2
	sparks.gravity = Vector3(0, 0.35, 0)
	sparks.initial_velocity_min = 0.05
	sparks.initial_velocity_max = 0.25
	sparks.direction = Vector3(0, 1, 0)
	sparks.spread = 120.0
	var sm := SphereMesh.new()
	sm.radius = 0.012
	sm.height = 0.024
	sparks.mesh = sm
	sparks.material_override = Mats.emissive(Color(1.0, 0.85, 0.3), 4.0)
	head_node.add_child(sparks)
	var glow := OmniLight3D.new()
	glow.light_color = Color(1.0, 0.82, 0.4)
	glow.light_energy = 0.0
	glow.omni_range = 5.0
	glow.position = Vector3(0, 0.3, -0.2)
	head_node.add_child(glow)
	var lt := glow.create_tween()
	lt.tween_property(glow, "light_energy", 2.5, 1.8)
	# 注射器变成金色
	for c in injector.get_children():
		if c is MeshInstance3D:
			c.material_override = Mats.emissive(Color(1.0, 0.8, 0.3), 2.5)

func stand_up() -> void:
	var tw := create_tween()
	tw.tween_property(body_root, "position:y", 0.0, 0.8).set_trans(Tween.TRANS_SINE)
	body_root.rotation.x = 0.0

## 走出后门,消失
func walk_out(door: Node3D) -> void:
	if door != null:
		door.set_open(true)
		SFX.play("door", -4.0)
	var tw := create_tween()
	var start := global_position
	rotation.y = atan2(-(OUT_PT.x - start.x), -(OUT_PT.z - start.z))
	tw.tween_property(self, "global_position", Vector3(EXIT_PT.x, 0, EXIT_PT.z), 2.2)
	tw.tween_property(self, "global_position", OUT_PT, 1.6)
	tw.tween_callback(func(): visible = false)
