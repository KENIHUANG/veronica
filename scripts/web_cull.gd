extends Node
## 网页版专用:WebGL 下场景里同时存在的模型超过约 1100 个时,Godot 4.3 会整帧画不出 3D(全黑)。
## 这里按距离把离玩家远的模型暂时隐藏(visible=false 会把它移出渲染场景),近处的照常显示。
## 只恢复自己隐藏的模型,不干扰剧情脚本自己做的显示/隐藏。

const RADIUS := 15.0
const MAX_SHOWN := 900

var world: Node3D
var player: Node3D
var _items: Array = []      # [MeshInstance3D, 中心点, 半径]
var _t := 0.0

func setup(w: Node3D, p: Node3D) -> void:
	world = w
	player = p
	_items.clear()
	for n in w.find_children("*", "MeshInstance3D", true, false):
		var mi := n as MeshInstance3D
		if mi.mesh == null:
			continue
		var ab: AABB = mi.global_transform * mi.get_aabb()
		_items.append([mi, ab.get_center(), ab.size.length() * 0.5])
	refresh()

func _process(delta: float) -> void:
	_t -= delta
	if _t <= 0.0:
		_t = 0.25
		refresh()

func refresh() -> void:
	if world == null or not is_instance_valid(player):
		return
	var pp := player.global_position
	var shown := 0
	for it in _items:
		var mi: MeshInstance3D = it[0]
		if not is_instance_valid(mi):
			continue
		var near: bool = pp.distance_to(it[1]) - float(it[2]) < RADIUS
		if near and shown < MAX_SHOWN:
			if mi.has_meta("wc_hid"):
				mi.remove_meta("wc_hid")
				mi.visible = true
			if mi.visible:
				shown += 1
		elif mi.visible:
			mi.visible = false
			mi.set_meta("wc_hid", true)
