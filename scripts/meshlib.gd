extends RefCounted
## 程序化有机建模工具:放样(loft)、旋转体(revolve,可带褶皱)、雕刻头部、手。
## 所有网格都用 SurfaceTool 生成平滑法线。单位:米。

static func _gauss(x: float, y: float, cx: float, cy: float, sx: float, sy: float) -> float:
	var dx := (x - cx) / sx
	var dy := (y - cy) / sy
	return exp(-(dx * dx + dy * dy))

static func _smooth(a: float, b: float, x: float) -> float:
	var t := clampf((x - a) / (b - a), 0.0, 1.0)
	return t * t * (3.0 - 2.0 * t)

## 沿路径放样。path: Array[Vector3];radii: Array[Vector2](rx, rz);
## opts: ref(Vector3,截面"前方"参考轴), ripple(褶皱幅度), ripple_n(褶皱数), caps(bool), uv_u/uv_v(UV 缩放), flip(bool)
static func loft(path: Array, radii: Array, seg: int = 20, opts: Dictionary = {}) -> ArrayMesh:
	var ref: Vector3 = opts.get("ref", Vector3(0, 0, -1))
	var ripple: float = opts.get("ripple", 0.0)
	var ripple_n: int = opts.get("ripple_n", 6)
	var caps: bool = opts.get("caps", true)
	var uu: float = opts.get("uv_u", 1.0)
	var vv: float = opts.get("uv_v", 1.0)
	var flip: bool = opts.get("flip", false)
	var n := path.size()
	var rings: Array = []
	for i in n:
		var t: Vector3
		if i == 0:
			t = path[1] - path[0]
		elif i == n - 1:
			t = path[i] - path[i - 1]
		else:
			t = path[i + 1] - path[i - 1]
		t = t.normalized()
		var r0 := ref
		if absf(t.dot(r0)) > 0.95:
			r0 = Vector3(1, 0, 0)
		var fwd := (r0 - t * t.dot(r0)).normalized()
		var right := fwd.cross(t).normalized()
		var rr: Vector2 = radii[i]
		var ring: Array = []
		for k in seg:
			var a := TAU * k / seg
			var rip := 1.0
			if ripple != 0.0:
				rip += ripple * sin(a * ripple_n + float(i) * 0.9)
			ring.append(path[i] + right * cos(a) * rr.x * rip + fwd * sin(a) * rr.y * rip)
		rings.append(ring)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		for k in seg:
			var k2 := (k + 1) % seg
			var a: Vector3 = rings[i][k]
			var b: Vector3 = rings[i][k2]
			var c: Vector3 = rings[i + 1][k2]
			var d: Vector3 = rings[i + 1][k]
			var ua := float(k) / seg * uu
			var ub := float(k + 1) / seg * uu
			var va := float(i) / (n - 1) * vv
			var vb := float(i + 1) / (n - 1) * vv
			var quad := [[a, Vector2(ua, va)], [b, Vector2(ub, va)], [c, Vector2(ub, vb)], [d, Vector2(ua, vb)]]
			var order := [0, 2, 1, 0, 3, 2] if not flip else [0, 1, 2, 0, 2, 3]
			for idx in order:
				st.set_smooth_group(0)
				st.set_uv(quad[idx][1])
				st.add_vertex(quad[idx][0])
	if caps:
		for end in [0, n - 1]:
			var center: Vector3 = path[end]
			for k in seg:
				var k2 := (k + 1) % seg
				var p1: Vector3 = rings[end][k]
				var p2: Vector3 = rings[end][k2]
				var tri := [center, p2, p1] if (end == 0) != flip else [center, p1, p2]
				for p in tri:
					st.set_smooth_group(0)
					st.set_uv(Vector2(0.5, 0.5))
					st.add_vertex(p)
	st.generate_normals()
	return st.commit()

## 旋转体(裙摆、长袍、帽子)。profile: Array[Vector2](半径, 高度),自下而上或自上而下均可。
## drape: 褶皱幅度, drape_n: 褶皱数;褶皱随高度渐强(越靠近下摆越大)
static func revolve(profile: Array, seg: int = 40, drape: float = 0.0, drape_n: int = 9, flip: bool = false, uv_u: float = 1.0, uv_v: float = 1.0) -> ArrayMesh:
	var n := profile.size()
	var ymin := 1e9
	var ymax := -1e9
	for p in profile:
		ymin = minf(ymin, p.y)
		ymax = maxf(ymax, p.y)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n - 1:
		for k in seg:
			var k2 := (k + 1) % seg
			var pts: Array = []
			for pair in [[i, k], [i, k2], [i + 1, k2], [i + 1, k]]:
				var pi_: int = pair[0]
				var pk: int = pair[1]
				var pr: Vector2 = profile[pi_]
				var a: float = TAU * pk / seg
				var h := (pr.y - ymin) / maxf(ymax - ymin, 0.001)
				var rad := pr.x * (1.0 + drape * (1.0 - h) * (sin(a * drape_n) + 0.5 * sin(a * (drape_n * 2 + 1) + 1.3)))
				pts.append(Vector3(sin(a) * rad, pr.y, cos(a) * rad))
			var uvs := [Vector2(float(k) / seg * uv_u, float(i) / (n - 1) * uv_v), Vector2(float(k + 1) / seg * uv_u, float(i) / (n - 1) * uv_v), Vector2(float(k + 1) / seg * uv_u, float(i + 1) / (n - 1) * uv_v), Vector2(float(k) / seg * uv_u, float(i + 1) / (n - 1) * uv_v)]
			var order := [0, 2, 1, 0, 3, 2] if not flip else [0, 1, 2, 0, 2, 3]
			for idx in order:
				st.set_smooth_group(0)
				st.set_uv(uvs[idx])
				st.add_vertex(pts[idx])
	st.generate_normals()
	return st.commit()

## 雕刻头部。头中心为原点,朝向 -Z。返回 {"upper": ArrayMesh, "jaw": ArrayMesh(可为 null), "pivot": Vector3}
## opts: gaunt(0..1 脸颊凹陷), socket(0..1 眼窝深度), brow(0..1.5), nose(0..1.5), chin(0..1.5), jaw_w(下颌宽度系数),
##       width(整体宽度系数), height(整体高度系数), split(bool 是否把下颌分离成可张合的网格), skull(0..1 颅骨感)
static func head(opts: Dictionary = {}) -> Dictionary:
	var gaunt: float = opts.get("gaunt", 0.0)
	var socket: float = opts.get("socket", 0.5)
	var brow: float = opts.get("brow", 1.0)
	var nose: float = opts.get("nose", 1.0)
	var chin: float = opts.get("chin", 1.0)
	var jaw_w: float = opts.get("jaw_w", 1.0)
	var wid: float = opts.get("width", 1.0)
	var hei: float = opts.get("height", 1.0)
	var skull: float = opts.get("skull", 0.0)
	var split: bool = opts.get("split", false)
	var rows := 44
	var cols := 60
	var rx := 0.078 * wid
	var ry := 0.115 * hei
	var rzf := 0.088
	var rzb := 0.108
	var grid: Array = []
	for i in rows + 1:
		var th := PI * i / rows
		var row: Array = []
		for j in cols:
			var ph := TAU * j / cols
			var dx := sin(th) * sin(ph)
			var dy := cos(th)
			var dz := -sin(th) * cos(ph)
			var rz := rzf if dz < 0.0 else rzb
			var p := Vector3(dx * rx, dy * ry, dz * rz)
			# 下颌收窄
			var jawk := _smooth(-0.01, -0.115, p.y)
			p.x *= 1.0 - 0.30 * jawk * (1.0 / jaw_w if jaw_w > 0.0 else 1.0) * 0.9
			p.z *= 1.0 - 0.12 * jawk
			var fr := _smooth(0.0, 0.55, -dz)       # 越朝前越受五官影响
			var x := p.x
			var y := p.y
			var out := 0.0
			for s: float in [-1.0, 1.0]:
				out += _gauss(x, y, s * 0.058 * wid, -0.004, 0.02, 0.017) * 0.0075                  # 颧骨
				out -= _gauss(x, y, s * 0.036 * wid, 0.028, 0.0185, 0.0115) * (0.007 + 0.011 * socket)   # 眼窝
				out += _gauss(x, y, s * 0.014, -0.034, 0.007, 0.0065) * 0.006 * nose                # 鼻翼
				out -= _gauss(x, y, s * 0.046 * wid, -0.042, 0.022, 0.028) * gaunt * 0.0125         # 脸颊凹陷
				out -= _gauss(x, y, s * 0.071 * wid, 0.045, 0.014, 0.026) * (0.004 + gaunt * 0.004)   # 太阳穴
			out += _gauss(x, y, 0.0, 0.047, 0.065 * wid, 0.011) * 0.008 * brow                       # 眉弓
			out += _gauss(x, y, 0.0, 0.002, 0.0075, 0.042) * 0.011 * nose                           # 鼻梁
			out += _gauss(x, y, 0.0, -0.030, 0.0105, 0.0095) * 0.0155 * nose                        # 鼻头
			out -= _gauss(x, y, 0.0, -0.0475, 0.0042, 0.006) * 0.003                                # 人中
			out += _gauss(x, y, 0.0, -0.0585, 0.0205, 0.0058) * 0.0065                              # 上唇
			out += _gauss(x, y, 0.0, -0.0735, 0.019, 0.0068) * 0.0075                               # 下唇
			out -= _gauss(x, y, 0.0, -0.0652, 0.0225, 0.0016) * 0.0045                              # 嘴缝
			out += _gauss(x, y, 0.0, -0.099, 0.023, 0.014) * 0.0105 * chin                          # 下巴
			out += _gauss(x, y, 0.0, 0.078, 0.05, 0.03) * 0.004                                     # 前额
			out -= _gauss(x, y, 0.0, -0.088, 0.018, 0.006) * 0.0035                                 # 下唇下凹
			if skull > 0.0:
				out -= _gauss(x, y, 0.0, -0.025, 0.014, 0.012) * 0.011 * skull                       # 鼻腔空洞感
				out -= _gauss(x, y, 0.0, -0.1, 0.05, 0.02) * 0.0 * skull
			p.z -= out * fr * (-1.0 if dz > 0.0 else 1.0) * (1.0 if dz < 0.0 else 0.0)
			p.z += 0.0
			row.append(p)
		grid.append(row)
	# 分离下颌的分界行(嘴缝所在的纬线)
	var split_row := -1
	if split:
		for i in rows + 1:
			if grid[i][0].y <= -0.0652:
				split_row = i
				break
	var pivot := Vector3(0, -0.012, 0.045)
	var result := {"upper": null, "jaw": null, "pivot": pivot}
	var ranges: Array = [[0, rows]]
	if split and split_row > 0:
		ranges = [[0, split_row], [split_row, rows]]
	for ri in ranges.size():
		var st := SurfaceTool.new()
		st.begin(Mesh.PRIMITIVE_TRIANGLES)
		var off := Vector3.ZERO if ri == 0 else pivot
		for i in range(ranges[ri][0], ranges[ri][1]):
			for j in cols:
				var j2 := (j + 1) % cols
				var pts := [grid[i][j], grid[i][j2], grid[i + 1][j2], grid[i + 1][j]]
				var order := [0, 2, 1, 0, 3, 2]
				for idx in order:
					var p: Vector3 = pts[idx]
					st.set_smooth_group(0)
					st.set_uv(Vector2(0.5 + p.x / 0.17, 0.5 - p.y / 0.25))
					st.add_vertex(p - off)
		st.generate_normals()
		var m := st.commit()
		if ri == 0:
			result["upper"] = m
		else:
			result["jaw"] = m
	return result
