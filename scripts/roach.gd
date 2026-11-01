extends Node3D
## 蟑螂:在地面乱爬,玩家靠近就四散逃开。

var player: Node3D = null
var speed: float = 0.0
var dir: Vector3 = Vector3.ZERO
var timer: float = 0.0
var min_x: float = 4.6
var max_x: float = 11.8
var min_z: float = 0.4
var max_z: float = 7.7
var ant_l: Node3D = null
var ant_r: Node3D = null
var tt: float = randf() * 10.0

func _ready() -> void:
	add_to_group("roaches")

func _process(delta: float) -> void:
	tt += delta
	if ant_l == null:
		ant_l = find_child("AntL", true, false)
		ant_r = find_child("AntR", true, false)
	if ant_l != null:
		ant_l.rotation.y = sin(tt * (14.0 if speed > 0.05 else 4.0)) * 0.4
		ant_r.rotation.y = -sin(tt * (13.0 if speed > 0.05 else 3.5) + 1.0) * 0.4
	if player == null:
		player = get_tree().get_first_node_in_group("player")
	timer -= delta
	if player != null and global_position.distance_to(player.global_position) < 2.2:
		var away := global_position - player.global_position
		away.y = 0
		if away.length() > 0.01:
			dir = away.normalized()
			speed = 1.9
	elif timer <= 0.0:
		timer = randf_range(0.4, 2.0)
		if randf() < 0.55:
			speed = 0.0
		else:
			speed = randf_range(0.3, 0.9)
			var a := randf() * TAU
			dir = Vector3(sin(a), 0, cos(a))
	var np := position + dir * speed * delta
	np.x = clampf(np.x, min_x, max_x)
	np.z = clampf(np.z, min_z, max_z)
	position = np
	if speed > 0.05:
		rotation.y = atan2(dir.x, dir.z)
