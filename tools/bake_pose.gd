extends SceneTree
## 把带骨骼的人物套上动画库里某一帧的姿势,烘焙成静态网格并导出 GLB(用于人体模型等道具)。
## 用法:godot --headless --path . -s tools/bake_pose.gd -- <人物.gltf> <动画库.glb> <动画名> <时间秒> <输出.glb> [r,g,b]
##   动画名写 ARMS_DOWN 时不读动画库,把上臂向下转 <时间> 度(人体模型用),例如:
##   ... -- res://x/Superhero_Female_FullBody.gltf - ARMS_DOWN 72 res://assets/models/mannequin.glb 0.86,0.84,0.8
## 两边骨骼名相同即可(Quaternius Universal Base Characters + Universal Animation Library)。

func _skinned_arrays(mi: MeshInstance3D, sk: Skeleton3D) -> Array:
	var out := []
	var skin: Skin = mi.skin
	for s in mi.mesh.get_surface_count():
		var a: Array = mi.mesh.surface_get_arrays(s)
		var verts: PackedVector3Array = a[Mesh.ARRAY_VERTEX]
		var norms: PackedVector3Array = a[Mesh.ARRAY_NORMAL]
		var bones: PackedInt32Array = a[Mesh.ARRAY_BONES]
		var weights: PackedFloat32Array = a[Mesh.ARRAY_WEIGHTS]
		var per := bones.size() / maxi(verts.size(), 1)
		# 每个 skin bind 的最终变换
		var mats := []
		for b in skin.get_bind_count():
			var bi := skin.get_bind_bone(b)
			if bi < 0:
				bi = sk.find_bone(skin.get_bind_name(b))
			mats.append(sk.get_bone_global_pose(bi) * skin.get_bind_pose(b))
		var nv := PackedVector3Array(); nv.resize(verts.size())
		var nn := PackedVector3Array(); nn.resize(norms.size())
		for i in verts.size():
			var p := Vector3.ZERO
			var n := Vector3.ZERO
			for k in per:
				var w: float = weights[i * per + k]
				if w <= 0.0: continue
				var t: Transform3D = mats[bones[i * per + k]]
				p += (t * verts[i]) * w
				if i < norms.size(): n += (t.basis * norms[i]) * w
			nv[i] = p
			if i < norms.size(): nn[i] = n.normalized()
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = nv
		arr[Mesh.ARRAY_NORMAL] = nn
		arr[Mesh.ARRAY_TEX_UV] = a[Mesh.ARRAY_TEX_UV]
		arr[Mesh.ARRAY_INDEX] = a[Mesh.ARRAY_INDEX]
		out.append(arr)
	return out

func _initialize() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() < 5:
		print("usage: <body.gltf> <anims.glb> <anim> <time> <out.glb> [r,g,b]"); quit(1); return
	var col := Color(0.86, 0.84, 0.8)
	if args.size() > 5:
		var c := args[5].split(",")
		col = Color(float(c[0]), float(c[1]), float(c[2]))
	var body: Node3D = (load(args[0]) as PackedScene).instantiate()
	root.add_child(body)
	var sk: Skeleton3D = body.find_children("*", "Skeleton3D", true, false)[0]
	if args[2].begins_with("ARMS_DOWN"):
		# 不用动画库:直接把上臂向下转(人体模型那种僵硬站姿)。时间参数 = 角度(度)
		_arms_down(sk, deg_to_rad(float(args[3])))
		_export(body, sk, col, args[4])
		return
	var lib: Node = (load(args[1]) as PackedScene).instantiate()
	var ap := lib.find_child("AnimationPlayer", true, false) as AnimationPlayer
	var anim := ap.get_animation(args[2])
	var t := float(args[3])
	var hit := 0
	var miss := {}
	for tr in anim.get_track_count():
		var path := anim.track_get_path(tr)
		var bone := String(path.get_concatenated_subnames())
		var bi := sk.find_bone(bone)
		if bi < 0:
			miss[bone] = true; continue
		match anim.track_get_type(tr):
			Animation.TYPE_ROTATION_3D:
				sk.set_bone_pose_rotation(bi, anim.rotation_track_interpolate(tr, t)); hit += 1
			Animation.TYPE_POSITION_3D:
				if bone != "root":
					sk.set_bone_pose_position(bi, anim.position_track_interpolate(tr, t))
	print("posed tracks: ", hit, " missing bones: ", miss.keys().slice(0, 8))
	_export(body, sk, col, args[4])

func _arms_down(sk: Skeleton3D, ang: float) -> void:
	for side in ["l", "r"]:
		var ua := sk.find_bone("upperarm_" + side)
		var hd := sk.find_bone("hand_" + side)
		if ua < 0 or hd < 0:
			print("no arm bones for ", side); continue
		sk.force_update_all_bone_transforms()
		var dir := sk.get_bone_global_pose(hd).origin - sk.get_bone_global_pose(ua).origin
		var q := Quaternion(Vector3(0, 0, 1), -signf(dir.x) * ang)
		var g := Basis(q) * sk.get_bone_global_pose(ua).basis
		var par := sk.get_bone_parent(ua)
		var local := sk.get_bone_global_pose(par).basis.inverse() * g
		sk.set_bone_pose_rotation(ua, local.get_rotation_quaternion())
		# 小臂微弯
		var la := sk.find_bone("lowerarm_" + side)
		if la >= 0:
			sk.force_update_all_bone_transforms()
			var g2 := Basis(Quaternion(Vector3(1, 0, 0), -0.12)) * sk.get_bone_global_pose(la).basis
			var l2 := sk.get_bone_global_pose(ua).basis.inverse() * g2
			sk.set_bone_pose_rotation(la, l2.get_rotation_quaternion())
	sk.force_update_all_bone_transforms()
	print("arms down ok")

func _export(body: Node3D, sk: Skeleton3D, col: Color, out_path: String) -> void:
	sk.force_update_all_bone_transforms()
	var out_root := Node3D.new()
	out_root.name = "Mannequin"
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.roughness = 0.35
	for mi in body.find_children("*", "MeshInstance3D", true, false):
		var m := mi as MeshInstance3D
		if m.skin == null: continue
		var am := ArrayMesh.new()
		for arr in _skinned_arrays(m, sk):
			am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
			am.surface_set_material(am.get_surface_count() - 1, mat)
		var nm := MeshInstance3D.new()
		nm.name = m.name
		nm.mesh = am
		nm.transform = sk.global_transform    # 网格已在骨架空间
		out_root.add_child(nm)
		nm.owner = out_root
	var doc := GLTFDocument.new()
	var st := GLTFState.new()
	doc.append_from_scene(out_root, st)
	print("export ", out_path, " -> ", doc.write_to_filesystem(st, ProjectSettings.globalize_path(out_path)))
	quit()
