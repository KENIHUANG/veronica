extends RefCounted
## 素材替换槽:不改代码就能把程序化模型/贴图换成专业素材。
##
## 模型:res://assets/models/<名字>.glb(或 .gltf / .fbx)存在时优先使用。尺寸、朝向、原点会按 NORMALIZE 自动摆正。
##   约定:1 单位 = 1 米,人物/物体朝向 -Z,脚底(底面)在原点。
##   人物槽:veronica, mirror_ghost, boss, doctor_ghost, girl
##   其他:statue_nun, toilet, sink, mannequin, wig_comb, wig_afro, wig_twin
## 贴图:res://assets/textures/<材质名>/color.(jpg|png),可选 normal.* 和 roughness.*
##   材质名见 mats.gd 的 SPECS:wallpaper, wood, deskwood, concrete, plaster, tile, tile_floor,
##   rust, steel, labtile, labwall, carpet, stone
##
## 人物模型如果没有 body/head/arm_l/arm_r/elbow_l/elbow_r/hand_l/hand_r 节点:
##   1) 若有 Skeleton3D,按骨骼名(Mixamo / Blender / UE 常见命名)挂 BoneAttachment3D,道具会跟着骨骼动;
##   2) 否则在大致位置补空 Node3D,保证 boss.gd / main.gd 里的姿势赋值不报错(但不会驱动模型)。
##   模型自带 AnimationPlayer 时,自动循环播放名字含 idle 的动画(没有就播第一个)。

const MODEL_DIR := "res://assets/models/"
const TEX_DIR := "res://assets/textures/"

## 节点名 → 默认位置(相对父节点)与父节点
const RIG := {
	"body": [Vector3(0, 0.93, 0), ""],
	"head": [Vector3(0, 1.65, 0), ""],
	"arm_l": [Vector3(-0.18, 1.43, 0), ""],
	"arm_r": [Vector3(0.18, 1.43, 0), ""],
	"elbow_l": [Vector3(0, -0.3, 0), "arm_l"],
	"elbow_r": [Vector3(0, -0.3, 0), "arm_r"],
	"hand_l": [Vector3(0, -0.27, 0), "elbow_l"],
	"hand_r": [Vector3(0, -0.27, 0), "elbow_r"],
}
## 常见骨骼命名(小写、去掉 mixamorig 前缀后比较)
const BONES := {
	"body": ["spine", "spine1", "spine_01", "chest"],
	"head": ["head"],
	"arm_l": ["leftarm", "upperarm_l", "upperarm.l", "upper_arm.l", "l_upperarm"],
	"arm_r": ["rightarm", "upperarm_r", "upperarm.r", "upper_arm.r", "r_upperarm"],
	"elbow_l": ["leftforearm", "lowerarm_l", "forearm.l", "lowerarm.l", "l_forearm"],
	"elbow_r": ["rightforearm", "lowerarm_r", "forearm.r", "lowerarm.r", "r_forearm"],
	"hand_l": ["lefthand", "hand_l", "hand.l", "l_hand"],
	"hand_r": ["righthand", "hand_r", "hand.r", "r_hand"],
	"jaw": ["jaw"],
}

## 每个槽的默认摆放规则(素材本身的尺寸/朝向/原点各不相同,这里统一):
##   height  = 缩放到的目标高度(米);0 表示不缩放
##   yaw     = 额外旋转(度);素材朝 +Z 时填 180
##   ground  = 底面放到 y=0
##   center  = X/Z 居中;back = 背面(最小 Z)贴到 z=0(靠墙的物体)
## assets/models/slots.json 里同名键可以覆盖这些值,例如 {"boss": {"height": 1.85, "yaw": 0}}
const NORMALIZE := {
	"veronica": {"height": 1.68, "yaw": 180.0, "ground": true, "center": true},
	"mirror_ghost": {"height": 1.8, "yaw": 180.0, "ground": true, "center": true},
	"boss": {"height": 1.8, "yaw": 180.0, "ground": true, "center": true},
	"doctor_ghost": {"height": 1.78, "yaw": 180.0, "ground": true, "center": true},
	"girl": {"height": 1.75, "yaw": 180.0, "ground": true, "center": true},
	"statue_nun": {"height": 2.3, "yaw": 180.0, "ground": true, "center": true},
	"mannequin": {"height": 1.75, "yaw": 180.0, "ground": true, "center": true},
	"toilet": {"height": 0.78, "yaw": 180.0, "ground": true, "center": true},
	"sink": {"height": 0.92, "yaw": 180.0, "ground": true, "center": false, "center_x": true, "back": true},
}

static var _cfg_cache = null

static func _cfg(n: String) -> Dictionary:
	if _cfg_cache == null:
		_cfg_cache = {}
		var path := MODEL_DIR + "slots.json"
		if FileAccess.file_exists(path):
			var d = JSON.parse_string(FileAccess.get_file_as_string(path))
			if typeof(d) == TYPE_DICTIONARY:
				_cfg_cache = d
	var out: Dictionary = NORMALIZE.get(n, {}).duplicate()
	var over = _cfg_cache.get(n, {})
	if typeof(over) == TYPE_DICTIONARY:
		out.merge(over, true)
	return out

## 把导入的模型包一层,按规则缩放/旋转/落地/居中
static func _normalize(inst: Node3D, n: String) -> Node3D:
	var c := _cfg(n)
	if c.is_empty():
		return inst
	var holder := Node3D.new()
	holder.name = "norm_" + n
	holder.add_child(inst)
	inst.rotation_degrees.y += float(c.get("yaw", 0.0))
	var box := _aabb(inst, Transform3D.IDENTITY)
	var h: float = c.get("height", 0.0)
	if h > 0.0 and box.size.y > 0.0001:
		inst.scale *= h / box.size.y
	box = _aabb(inst, Transform3D.IDENTITY)
	var off := Vector3.ZERO
	if c.get("ground", false):
		off.y = -box.position.y
	if c.get("center", false) or c.get("center_x", false):
		off.x = -box.get_center().x
	if c.get("center", false):
		off.z = -box.get_center().z
	if c.get("back", false):
		off.z = -box.position.z
	inst.position += off
	return holder

static func model_path(n: String) -> String:
	for ext in [".glb", ".gltf", ".fbx"]:
		var p: String = MODEL_DIR + n + ext
		if ResourceLoader.exists(p):
			return p
	return ""

static func has_model(n: String) -> bool:
	return model_path(n) != ""

static func model(n: String) -> Node3D:
	var p := model_path(n)
	if p == "":
		return null
	var r = load(p)
	if r is PackedScene:
		var inst = (r as PackedScene).instantiate()
		if inst is Node3D:
			_autoplay(inst)
			return _normalize(inst, n)
	push_warning("素材槽 %s 不是可实例化的 3D 场景" % p)
	return null

static func _autoplay(n: Node) -> void:
	var ap := n.find_child("AnimationPlayer", true, false) as AnimationPlayer
	if ap == null:
		return
	var list := ap.get_animation_list()
	if list.is_empty():
		return
	var pick: String = list[0]
	for a in list:
		if "idle" in String(a).to_lower():
			pick = a
			break
	var anim := ap.get_animation(pick)
	if anim != null:
		anim.loop_mode = Animation.LOOP_LINEAR
	ap.play(pick)

## 物体槽:返回放好位置的节点(带一个按包围盒生成的碰撞体,层 1);没有素材就返回 null。
static func prop(n: String, parent: Node, pos: Vector3, yaw_deg: float = 0.0, collide: bool = true) -> Node3D:
	var m := model(n)
	if m == null:
		return null
	var holder := Node3D.new()
	holder.name = "slot_" + n
	holder.position = pos
	holder.rotation_degrees.y = yaw_deg
	parent.add_child(holder)
	holder.add_child(m)
	if collide:
		var box := _aabb(m, Transform3D.IDENTITY)
		if box.size.length() > 0.01:
			var sb := StaticBody3D.new()
			sb.collision_layer = 1
			sb.collision_mask = 0
			var cs := CollisionShape3D.new()
			var bs := BoxShape3D.new()
			bs.size = box.size
			cs.shape = bs
			cs.position = box.get_center()
			sb.add_child(cs)
			holder.add_child(sb)
	return holder

static func _aabb(n: Node, xf: Transform3D) -> AABB:
	var out := AABB()
	var first := true
	var t := xf
	if n is Node3D:
		t = xf * (n as Node3D).transform
	if n is MeshInstance3D and (n as MeshInstance3D).mesh != null:
		var b: AABB = t * (n as MeshInstance3D).mesh.get_aabb()
		out = b
		first = false
	for c in n.get_children():
		var cb := _aabb(c, t)
		if cb.size == Vector3.ZERO:
			continue
		out = cb if first else out.merge(cb)
		first = false
	return out

## 人物槽:返回与 Person.build 相同结构的字典;没有素材返回 {}。
static func character(n: String) -> Dictionary:
	var m := model(n)
	if m == null:
		return {}
	var root := Node3D.new()
	root.name = "slot_" + n
	root.add_child(m)
	var out := {"root": root, "imported": true}
	var skel: Skeleton3D = null
	for c in m.find_children("*", "Skeleton3D", true, false):
		skel = c
		break
	for key in ["body", "head", "arm_l", "arm_r", "elbow_l", "elbow_r", "hand_l", "hand_r", "jaw"]:
		var node: Node3D = m.find_child(key, true, false) as Node3D
		if node == null and skel != null:
			var bi := _find_bone(skel, BONES[key])
			if bi >= 0:
				var ba := BoneAttachment3D.new()
				ba.name = key
				skel.add_child(ba)
				ba.bone_idx = bi
				node = ba
		if node == null and key != "jaw":
			var spec: Array = RIG[key]
			node = Node3D.new()
			node.name = key
			node.position = spec[0]
			var par: Node = root if spec[1] == "" else out.get(spec[1], root)
			par.add_child(node)
		if node != null:
			out[key] = node
	return out

static func _find_bone(skel: Skeleton3D, names: Array) -> int:
	for i in skel.get_bone_count():
		var bn := skel.get_bone_name(i).to_lower().replace("mixamorig:", "").replace("mixamorig_", "")
		if bn in names:
			return i
	return -1

## 贴图槽:找到就返回 {color, normal, roughness}(后两个可能为 null);没有返回 {}。
static func textures(mat_name: String) -> Dictionary:
	var out := {}
	for kind in ["color", "normal", "roughness"]:
		for ext in [".jpg", ".png", ".webp"]:
			var p: String = TEX_DIR + mat_name + "/" + kind + ext
			if ResourceLoader.exists(p):
				out[kind] = load(p)
				break
	if not out.has("color"):
		return {}
	return out
