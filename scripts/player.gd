extends CharacterBody3D
## 第一人称玩家:移动、视角、手电、射线互动、躲藏、受击。

const WALK := 3.4
const RUN := 5.8
const SENS := 0.0024

signal died
signal inventory_requested
signal heal_requested
signal gun_clicked(pos: Vector3)

var cam: Camera3D
var flash: SpotLight3D
var ray: RayCast3D
var yaw := 0.0
var pitch := 0.0
var hidden := false
var locked := false
var dead := false
var running := false
var moving := false
var target_inter: Node = null
var knock := Vector3.ZERO
var bob_t := 0.0
var step_t := 0.0
var shake_t := 0.0
var shake_amp := 0.0
var revolver_cd := 0.0
var hide_info: Dictionary = {}

func _ready() -> void:
	add_to_group("player")
	collision_layer = 4
	collision_mask = 1 | 16
	var cs := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.32
	cap.height = 1.8
	cs.shape = cap
	cs.position.y = 0.9
	add_child(cs)
	cam = Camera3D.new()
	cam.position = Vector3(0, 1.6, 0)
	cam.fov = 75.0
	cam.near = 0.05
	cam.current = true
	cam.cull_mask = 0xFFFFF & ~2   # 第 2 层只在镜子里可见
	add_child(cam)
	flash = SpotLight3D.new()
	flash.light_energy = 4.0
	flash.spot_range = 20.0
	flash.spot_angle = 30.0
	flash.spot_attenuation = 0.8
	flash.light_color = Color(1.0, 0.95, 0.82)
	flash.shadow_enabled = true
	flash.position = Vector3(0.15, -0.12, -0.1)
	cam.add_child(flash)
	ray = RayCast3D.new()
	ray.target_position = Vector3(0, 0, -2.6)
	ray.collide_with_areas = true
	ray.collide_with_bodies = true
	ray.collision_mask = 1 | 2 | 16
	ray.hit_from_inside = true
	cam.add_child(ray)

func set_yaw(y: float) -> void:
	yaw = y
	rotation.y = yaw

func face_point(p: Vector3) -> void:
	var d := p - global_position
	yaw = atan2(-d.x, -d.z)
	rotation.y = yaw
	var h := Vector2(d.x, d.z).length()
	pitch = clampf(atan2(p.y - cam.global_position.y, maxf(h, 0.01)), -1.2, 1.2)
	cam.rotation.x = pitch

func shake(t: float, amp: float) -> void:
	shake_t = t
	shake_amp = amp

func _physics_process(delta: float) -> void:
	revolver_cd = maxf(0.0, revolver_cd - delta)
	var blocked := locked or hidden or dead or UI.blocked()
	var lk: Vector2 = Touch.take_look()
	if lk != Vector2.ZERO and not locked and not dead and not UI.blocked():
		yaw -= lk.x
		pitch = clampf(pitch - lk.y, -1.3, 1.3)
		rotation.y = yaw
		cam.rotation.x = pitch
	var dir := Vector3.ZERO
	running = false
	if not blocked:
		var v := Vector2.ZERO
		if Input.is_physical_key_pressed(KEY_W) or Input.is_physical_key_pressed(KEY_UP):
			v.y -= 1.0
		if Input.is_physical_key_pressed(KEY_S) or Input.is_physical_key_pressed(KEY_DOWN):
			v.y += 1.0
		if Input.is_physical_key_pressed(KEY_A) or Input.is_physical_key_pressed(KEY_LEFT):
			v.x -= 1.0
		if Input.is_physical_key_pressed(KEY_D) or Input.is_physical_key_pressed(KEY_RIGHT):
			v.x += 1.0
		v = v.normalized()
		var tv: Vector2 = Touch.move_vector()
		if tv.length() > 0.05:
			v = tv
		dir = global_transform.basis * Vector3(v.x, 0, v.y)
		running = (Input.is_physical_key_pressed(KEY_SHIFT) or Touch.run_held()) and v != Vector2.ZERO
	moving = dir.length() > 0.1
	var sp := RUN if running else WALK
	velocity.x = dir.x * sp + knock.x
	velocity.z = dir.z * sp + knock.z
	knock = knock.move_toward(Vector3.ZERO, 16.0 * delta)
	if not is_on_floor():
		velocity.y -= 20.0 * delta
	else:
		velocity.y = -0.1
	if not hidden:
		move_and_slide()
	# 摇晃与脚步
	if moving:
		bob_t += delta * (11.0 if running else 7.5)
		step_t -= delta
		if step_t <= 0.0:
			step_t = 0.28 if running else 0.5
			SFX.play("step", -10.0 if not running else -5.0)
	cam.position.y = 1.6 + (sin(bob_t) * 0.025 if moving else 0.0)
	if shake_t > 0.0:
		shake_t -= delta
		cam.position += Vector3(randf_range(-1, 1), randf_range(-1, 1), 0) * shake_amp
	# 互动目标
	target_inter = null
	if hidden:
		UI.set_prompt(UI.key_hint() + L.t("离开藏身处"))
		return
	if not blocked and ray.is_colliding():
		var c = ray.get_collider()
		if c != null and c.has_method("current_prompt"):
			var p: String = c.current_prompt()
			if p != "":
				target_inter = c
				UI.set_prompt(UI.key_hint() + L.t(p))
				return
	UI.set_prompt("")

func _unhandled_input(event: InputEvent) -> void:
	if dead:
		return
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED and not locked and not UI.blocked():
		yaw -= event.relative.x * SENS
		pitch = clampf(pitch - event.relative.y * SENS, -1.3, 1.3)
		rotation.y = yaw
		cam.rotation.x = pitch
	elif event is InputEventMouseButton and event.pressed:
		if UI.hud_on and not UI.blocked() and Input.mouse_mode != Input.MOUSE_MODE_CAPTURED and not Touch.enabled:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	elif event is InputEventKey and event.pressed and not event.echo:
		if UI.blocked() or locked:
			return
		match event.keycode:
			KEY_E:
				if hidden:
					leave_hide()
				elif target_inter != null:
					target_inter.interact()
			KEY_F:
				if not hidden:
					flash.visible = not flash.visible
					SFX.play("click", -6.0)
			KEY_TAB:
				if not hidden:
					inventory_requested.emit()
			KEY_H:
				heal_requested.emit()
			KEY_Q:
				if GS.has_item("hollow_revolver") and revolver_cd <= 0.0 and not hidden:
					revolver_cd = 5.0
					SFX.play("click")
					UI.toast("咔哒——空枪的声音在远处回荡。", 2.0)
					var fwd := -global_transform.basis.z
					fwd.y = 0
					gun_clicked.emit(global_position + fwd.normalized() * 8.0)

func take_hit(n: int, from: Vector3) -> void:
	if dead:
		return
	GS.damage(n)
	SFX.play("hurt")
	UI.flash(Color(0.7, 0.0, 0.0, 0.5), 0.5)
	shake(0.35, 0.05)
	var d := global_position - from
	d.y = 0
	if d.length() < 0.01:
		d = Vector3(0, 0, 1)
	knock = d.normalized() * 8.0
	if GS.hp <= 0:
		dead = true
		died.emit()

## 躲藏:传入藏身位置、面向、离开时的位置、进入/离开回调
func enter_hide(pos: Vector3, face_yaw: float, leave_pos: Vector3, on_enter: Callable, on_leave: Callable) -> void:
	hide_info = {"leave": leave_pos, "on_leave": on_leave}
	on_enter.call()
	hidden = true
	velocity = Vector3.ZERO
	global_position = pos
	set_yaw(face_yaw)
	pitch = 0.0
	cam.rotation.x = 0.0

func leave_hide() -> void:
	if not hidden:
		return
	hidden = false
	global_position = hide_info["leave"]
	var cb: Callable = hide_info["on_leave"]
	hide_info = {}
	cb.call()
