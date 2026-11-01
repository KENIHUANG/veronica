extends RefCounted
## 程序化贴图 + 材质库。
## 贴图替换槽:res://assets/textures/<材质名>/color.jpg(可选 normal.jpg、roughness.jpg)存在时优先使用,见 asset_slots.gd。

const Slots = preload("res://scripts/asset_slots.gd")

static var cache: Dictionary = {}

const SPECS := {
	"wallpaper": {"k": "wallpaper", "c": Color(0.62, 0.56, 0.34), "r": 0.95},
	"wood": {"k": "wood", "c": Color(0.36, 0.25, 0.16), "r": 0.75},
	"deskwood": {"k": "wood", "c": Color(0.3, 0.19, 0.1), "r": 0.7},
	"concrete": {"k": "concrete", "c": Color(0.42, 0.42, 0.4), "r": 0.95},
	"plaster": {"k": "concrete", "c": Color(0.55, 0.46, 0.35), "r": 0.95},
	"tile": {"k": "tile", "c": Color(0.5, 0.62, 0.54), "r": 0.3},
	"tile_floor": {"k": "tile", "c": Color(0.3, 0.33, 0.3), "r": 0.25},
	"rust": {"k": "rust", "c": Color(0.5, 0.28, 0.14), "r": 0.7, "m": 0.35},
	"steel": {"k": "steel", "c": Color(0.68, 0.72, 0.76), "r": 0.35, "m": 0.7},
	"labtile": {"k": "tile", "c": Color(0.66, 0.74, 0.8), "r": 0.22},
	"labwall": {"k": "concrete", "c": Color(0.5, 0.58, 0.66), "r": 0.8},
	"carpet": {"k": "carpet", "c": Color(0.42, 0.06, 0.06), "r": 1.0},
	"stone": {"k": "concrete", "c": Color(0.68, 0.68, 0.64), "r": 0.9},
}

static func get_mat(mat_name: String) -> StandardMaterial3D:
	if cache.has(mat_name):
		return cache[mat_name]
	var spec: Dictionary = SPECS.get(mat_name, SPECS["concrete"])
	var m := StandardMaterial3D.new()
	var tex := Slots.textures(mat_name)
	if tex.is_empty():
		m.albedo_texture = _gen(spec["k"], spec["c"])
	else:
		m.albedo_texture = tex["color"]
		if tex.has("normal"):
			m.normal_enabled = true
			m.normal_texture = tex["normal"]
		if tex.has("roughness"):
			m.roughness_texture = tex["roughness"]
	m.albedo_color = Color.WHITE
	m.roughness = spec.get("r", 0.9)
	m.metallic = spec.get("m", 0.0)
	m.uv1_triplanar = true
	m.uv1_world_triplanar = true
	m.uv1_scale = Vector3(0.45, 0.45, 0.45)
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST_WITH_MIPMAPS
	cache[mat_name] = m
	return m

static func solid(color: Color, rough: float = 0.85, metal: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.roughness = rough
	m.metallic = metal
	return m

static func emissive(color: Color, energy: float = 2.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = color
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = energy
	return m

static func ghostly(color: Color, alpha: float = 0.45) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(color.r, color.g, color.b, alpha)
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.emission_enabled = true
	m.emission = color
	m.emission_energy_multiplier = 1.4
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

static func _gen(kind: String, base: Color) -> ImageTexture:
	var S := 128
	var h: int = kind.hash()
	var n1 := FastNoiseLite.new()
	n1.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	n1.frequency = 0.03
	n1.seed = h & 0xffff
	var n2 := FastNoiseLite.new()
	n2.frequency = 0.16
	n2.seed = (h >> 3) & 0xffff
	var g: Image = n1.get_seamless_image(S, S)
	var f: Image = n2.get_seamless_image(S, S)
	var img := Image.create(S, S, false, Image.FORMAT_RGB8)
	for y in S:
		for x in S:
			var gv: float = g.get_pixel(x, y).r
			var fv: float = f.get_pixel(x, y).r
			var c := base
			var dirt := 0.55 + 0.6 * gv
			var tex := 0.9 + 0.2 * fv
			match kind:
				"tile":
					if x % 32 < 2 or y % 32 < 2:
						c = base * 0.35
					dirt = 0.5 + 0.7 * gv
				"wallpaper":
					if (x / 16) % 2 == 0:
						c = base * 1.08
					else:
						c = base * 0.94
					if gv < 0.3:
						c = base * 0.42
				"wood":
					if y % 32 < 2:
						c = base * 0.4
					elif ((y / 32) % 2 == 0 and x % 64 < 2) or ((y / 32) % 2 == 1 and (x + 32) % 64 < 2):
						c = base * 0.45
					tex = 0.8 + 0.4 * fv
				"carpet":
					tex = 0.75 + 0.5 * fv
				"rust":
					c = base.lerp(Color(0.18, 0.1, 0.07), fv)
				"steel":
					tex = 0.82 + 0.28 * (0.5 + 0.5 * sin(float(y) * 1.7 + fv * 3.0))
			c = c * dirt * tex
			img.set_pixel(x, y, Color(clampf(c.r, 0.0, 1.0), clampf(c.g, 0.0, 1.0), clampf(c.b, 0.0, 1.0)))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)
