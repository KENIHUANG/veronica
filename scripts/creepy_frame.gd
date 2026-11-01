extends Node3D
## 会变化的挂画:你盯着它看的时候是正常的;你转过身、或余光扫过时,它就变成恐怖的样子,并往下滴血。

var mat: StandardMaterial3D
var calm: Texture2D
var creepy: Texture2D
var drip: CPUParticles3D = null
var player: Node3D = null
var state := false
var hold := 0.0
var flash_t := 0.0

## 把当前 state 套到材质上。恐怖态用更暗、更哑光的材质,避免灯光把脸照成一片白。
func apply_state() -> void:
	if mat == null:
		return
	mat.albedo_texture = creepy if state else calm
	mat.albedo_color = Color(0.7, 0.66, 0.66) if state else Color(0.66, 0.66, 0.66)
	mat.roughness = 0.95 if state else 0.8
	mat.metallic_specular = 0.15 if state else 0.35
	if drip != null:
		drip.emitting = state

func _process(delta: float) -> void:
	if player == null:
		player = get_tree().get_first_node_in_group("player")
		return
	if hold > 0.0:
		hold -= delta
		return
	var cam: Camera3D = player.cam
	var to := global_position - cam.global_position
	var dist := to.length()
	var fwd := -cam.global_transform.basis.z
	var dot := fwd.dot(to.normalized())
	var want := dot < 0.1 and dist < 10.0
	if dot > 0.72 and dist < 8.0:
		want = false
		# 盯着看久了,偶尔闪一下
		flash_t += delta
		if flash_t > 4.0 and randf() < 0.01:
			flash_t = 0.0
			want = true
	if want != state:
		state = want
		apply_state()
		hold = 0.18 if (state and dot > 0.72) else 0.5
