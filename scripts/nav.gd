extends RefCounted
## 手工路点图 + A*。雕像和 Boss 都用它在房间/走廊之间找路(直线可见时直接走过去)。

const PTS := [
	Vector3(0, 0, 10), Vector3(0, 0, 4), Vector3(0, 0, 0), Vector3(0, 0, -5), Vector3(0, 0, -10),   # 0-4 大厅
	Vector3(4.1, 0, 4), Vector3(6.5, 0, 4), Vector3(8, 0, 2.5), Vector3(8, 0, 5.5),                   # 5-8 厕所
	Vector3(-4.1, 0, 0), Vector3(-6.5, 0, 0),                                                          # 9-10 办公室
	Vector3(0, 0, -12.1), Vector3(0, 0, -14.5),                                                        # 11-12 实验室门
	Vector3(3, 0, -17.5), Vector3(0, 0, -19.5), Vector3(-2, 0, -23), Vector3(-4.4, 0, -20.5), Vector3(-4.4, 0, -15.5),  # 13-17
	Vector3(4.5, 0, -23.5),                                                                            # 18 后门
]
const EDGES := [
	[0, 1], [1, 2], [2, 3], [3, 4], [1, 5], [5, 6], [6, 7], [6, 8], [7, 8], [2, 9], [9, 10],
	[4, 11], [11, 12], [12, 13], [13, 14], [14, 15], [15, 16], [16, 17], [17, 12], [12, 14], [15, 18],
]

static var astar: AStar3D = null

static func _ensure() -> void:
	if astar != null:
		return
	astar = AStar3D.new()
	for i in PTS.size():
		astar.add_point(i, PTS[i])
	for e in EDGES:
		astar.connect_points(e[0], e[1])

static func los(space: PhysicsDirectSpaceState3D, a: Vector3, b: Vector3, width: float = 0.0) -> bool:
	var d := Vector3(b.x - a.x, 0, b.z - a.z)
	var n := Vector3(d.z, 0, -d.x)
	n = n.normalized() * width if n.length() > 0.001 else Vector3.ZERO
	var offs: Array = [0.0] if width <= 0.0 else [-1.0, 0.0, 1.0]
	for o in offs:
		var q := PhysicsRayQueryParameters3D.create(a + n * o + Vector3(0, 0.5, 0), b + n * o + Vector3(0, 0.5, 0), 1)
		if not space.intersect_ray(q).is_empty():
			return false
	return true

static func _flat(a: Vector3, b: Vector3) -> float:
	return Vector2(a.x - b.x, a.z - b.z).length()

## 返回下一步该走向的点。use_los=false 时强制按路点图逐点走(用于卡住后脱困)
static func next_point(space: PhysicsDirectSpaceState3D, from: Vector3, to: Vector3, use_los: bool = true) -> Vector3:
	if use_los and los(space, from, to, 0.4):
		return to
	_ensure()
	var a := _closest_visible(space, from)
	var b := _closest_visible(space, to)
	var path: PackedVector3Array = astar.get_point_path(a, b)
	if path.size() == 0:
		return to
	if use_los:
		for i in range(path.size() - 1, -1, -1):
			var p: Vector3 = path[i]
			if _flat(from, p) > 0.7 and los(space, from, p, 0.4):
				return p
	for p in path:
		if _flat(from, p) > 0.9:
			return p
	return to

static func _closest_visible(space: PhysicsDirectSpaceState3D, p: Vector3) -> int:
	var best := -1
	var bd := 1e9
	for i in PTS.size():
		var d: float = p.distance_to(PTS[i])
		if d < bd and los(space, p, PTS[i]):
			bd = d
			best = i
	if best == -1:
		best = astar.get_closest_point(p)
	return best

static func closest_index(p: Vector3) -> int:
	_ensure()
	return astar.get_closest_point(p)
