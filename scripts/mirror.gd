extends Node3D
## 真正的平面镜:SubViewport 里放一台镜像摄像机,画面贴在镜面上。
## 镜中人影(Veronica / 秃头大叔)只在"镜像图层"里存在 —— 主摄像机永远看不到它们,只有照镜子时才出现。

const Draw = preload("res://scripts/draw.gd")
const Humanoid = preload("res://scripts/humanoid.gd")
const Person = preload("res://scripts/person.gd")
const WB = preload("res://scripts/wb.gd")

const LAYER_REFLECT_ONLY := 2     # 只给镜像摄像机看(第 2 层)
const LAYER_MAIN_ONLY := 4        # 只给主摄像机看(第 3 层):墙、镜子本身

const SHADER := """
shader_type spatial;
render_mode unshaded, cull_disabled;
uniform sampler2D refl : source_color, filter_linear, repeat_disable;
uniform sampler2D grime : source_color, filter_linear, repeat_enable;
uniform sampler2D crack_tex : source_color, filter_linear;
uniform float cracked = 0.0;
uniform float bright = 1.0;
uniform float glitch = 0.0;   // 0..1 横向错位 + 色散
uniform float red = 0.0;      // 0..1 红色闪
float h1(float x) { return fract(sin(x * 91.7) * 43758.5453); }
void fragment() {
	vec2 uv = vec2(1.0 - SCREEN_UV.x, SCREEN_UV.y);
	float tk = floor(TIME * 24.0);
	float band = floor(UV.y * 26.0);
	float on = step(0.55, h1(band * 1.7 + tk * 0.31));
	uv.x += (h1(band + tk) - 0.5) * 0.07 * glitch * on;
	float ca = 0.007 * glitch;
	vec3 c = vec3(texture(refl, uv + vec2(ca, 0.0)).r, texture(refl, uv).g, texture(refl, uv - vec2(ca, 0.0)).b);
	c *= 1.0 - 0.35 * glitch * step(0.92, h1(band * 3.1 + tk));
	float g = texture(grime, UV * vec2(5.0, 1.6)).r;
	vec3 mirror_col = c * vec3(0.78, 0.9, 0.86) * (0.5 + 0.5 * g) * bright;
	float lum = dot(mirror_col, vec3(0.3, 0.59, 0.11));
	mirror_col = mix(mirror_col, vec3(lum * 1.7, lum * 0.18, lum * 0.15) + vec3(0.08, 0.0, 0.0), red);
	vec3 cr = texture(crack_tex, UV).rgb;
	vec3 broken_col = vec3(0.02, 0.03, 0.035) + cr * 0.5;
	ALBEDO = mix(mirror_col, broken_col, cracked);
}
"""

var player: Node3D = null
var plane_z := 0.03
var center := Vector3(8.25, 1.75, 0.03)
var vp: SubViewport
var cam: Camera3D
var quad: MeshInstance3D
var mat: ShaderMaterial
var avatar_v: Dictionary
var avatar_b: Dictionary
var follow_pos := Vector3.ZERO
var follow_yaw := 0.0
var lag := false
var broken := false
var bald_visible := false
var active := false
var face_light: OmniLight3D
var res_scale := 0.5          # 镜面视口分辨率(相对屏幕);事件期间临时提高,让脸看得清
var event_res_scale := 0.75
var _jit_t := 0.0
var _glitch := 0.0            # 当前故障强度(会自然衰减)

func setup(p: Node3D, mirror_center: Vector3, mirror_size: Vector2) -> void:
	player = p
	center = mirror_center
	plane_z = mirror_center.z
	vp = SubViewport.new()
	vp.size = Vector2i(640, 360)
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	add_child(vp)
	cam = Camera3D.new()
	cam.cull_mask = LAYER_REFLECT_ONLY | 1
	cam.fov = 75.0
	cam.far = 40.0
	vp.add_child(cam)
	cam.current = true
	# 镜面
	var sh := Shader.new()
	sh.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	mat.set_shader_parameter("refl", vp.get_texture())
	mat.set_shader_parameter("grime", _grime_tex())
	mat.set_shader_parameter("crack_tex", Draw.mirror_image("cracked"))
	mat.set_shader_parameter("cracked", 0.0)
	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = mirror_size
	quad.mesh = qm
	quad.material_override = mat
	quad.position = mirror_center
	quad.layers = LAYER_MAIN_ONLY
	add_child(quad)
	# 镜中人影:Veronica 的倒影 / 秃头大叔(瘦长、空洞的眼窝、咧开的嘴、过长的手臂)
	avatar_v = Person.build({
		"slot": "veronica", "female": true, "skin": Color(0.82, 0.66, 0.56), "cloth": "jacket", "coat": Color(0.3, 0.34, 0.22), "pants": Color(0.13, 0.15, 0.22),
		"hair": Color(0.22, 0.12, 0.07), "long_hair": true, "strap": true,
		"face": {"blush": 0.3, "lips": Color(0.68, 0.32, 0.32), "iris": Color(0.2, 0.4, 0.3), "brow": Color(0.15, 0.09, 0.06)},
	})
	avatar_b = Person.build({
		"slot": "mirror_ghost", "skin": Color(0.6, 0.6, 0.54), "cloth": "labcoat", "coat": Color(0.46, 0.47, 0.43), "pants": Color(0.2, 0.2, 0.22),
		"glasses": true, "hunch": -0.16, "arm_len": 1.28, "neck_len": 0.05, "wisps": true, "curl": 0.7, "stains": true,
		"head": {"gaunt": 0.95, "socket": 1.0, "chin": 1.3, "brow": 1.3, "skull": 0.5, "split": true},
		"face": {"eyes": "hollow", "socket": 1.3, "bags": 1.0, "age": 1.0, "grin": 0.95, "stubble": 0.25, "dead": true, "black_tears": true},
	})
	for a in [avatar_v, avatar_b]:
		Person.set_layers(a["root"], LAYER_REFLECT_ONLY)
		add_child(a["root"])
	avatar_b["root"].visible = false
	# 只照亮镜中人影(第 2 层)的冷光,让秃头大叔的脸看得见
	face_light = OmniLight3D.new()
	face_light.light_cull_mask = LAYER_REFLECT_ONLY
	face_light.light_color = Color(0.7, 0.9, 0.85)
	face_light.light_energy = 0.75
	face_light.omni_range = 3.2
	face_light.position = Vector3(mirror_center.x, 1.2, plane_z - 0.35)   # 从下往上打光,脸更阴森
	face_light.visible = false
	add_child(face_light)
	if player != null:
		follow_pos = player.global_position
		follow_yaw = player.rotation.y

func _grime_tex() -> ImageTexture:
	var n := FastNoiseLite.new()
	n.frequency = 0.04
	n.seed = 91
	var img: Image = n.get_seamless_image(128, 128)
	return ImageTexture.create_from_image(img)

func _process(delta: float) -> void:
	if player == null or vp == null:
		return
	var flat := Vector2(player.global_position.x - center.x, player.global_position.z - center.z).length()
	active = flat < 9.0 and not broken
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS if active else SubViewport.UPDATE_DISABLED
	if not active:
		return
	var s := get_viewport().get_visible_rect().size
	var rs := event_res_scale if (bald_visible or _glitch > 0.0) else res_scale
	if L.retro:
		rs = minf(rs, 0.4)     # 复古画面本来就会降到 240 线,镜面不用那么高分辨率(手机更省)
	var want := Vector2i(maxi(int(s.x * rs), 64), maxi(int(s.y * rs), 64))
	if vp.size != want:
		vp.size = want
	var main_cam: Camera3D = player.cam
	cam.fov = main_cam.fov
	var t := main_cam.global_transform
	var o := t.origin
	var f := -t.basis.z
	var u := t.basis.y
	var o2 := Vector3(o.x, o.y, 2.0 * plane_z - o.z)
	var f2 := Vector3(f.x, f.y, -f.z)
	var u2 := Vector3(u.x, u.y, -u.z)
	cam.global_transform = Transform3D(Basis.looking_at(f2, u2), o2)
	# 人影:跟随玩家,事件开始后会慢半拍
	var k := 1.0 - exp(-delta * (1.6 if lag else 40.0))
	follow_pos = follow_pos.lerp(player.global_position, k)
	follow_yaw = lerp_angle(follow_yaw, player.rotation.y, k)
	for a in [avatar_v, avatar_b]:
		if a == avatar_v:
			a["root"].global_position = follow_pos
			a["root"].rotation.y = follow_yaw
	# 故障感:秃头大叔出现后,头部轻微抽动;故障强度逐渐衰减
	if bald_visible:
		_jit_t -= delta
		if _jit_t <= 0.0:
			_jit_t = randf_range(0.05, 0.35)
			avatar_b["head"].rotation.y = randf_range(-0.12, 0.12)
			avatar_b["head"].rotation.x = randf_range(-0.06, 0.08)
			if randf() < 0.35:
				_glitch = maxf(_glitch, randf_range(0.25, 0.6))
	_glitch = maxf(_glitch - delta * 2.5, 0.0)
	mat.set_shader_parameter("glitch", _glitch)

## 出现前的闪现:秃头大叔只出现 1~2 帧,画面错位一下,又恢复成 Veronica 的倒影。
func flicker_preview() -> void:
	if broken:
		return
	var bz := maxf(plane_z + 0.9, follow_pos.z - 1.0)
	avatar_b["root"].global_position = Vector3(follow_pos.x + 0.35, 0, bz)
	avatar_b["root"].rotation.y = 0.0
	face_light.visible = true
	avatar_v["root"].visible = false
	avatar_b["root"].visible = true
	_glitch = 1.0
	for i in 2:
		await get_tree().process_frame
	if bald_visible or broken:
		return
	avatar_b["root"].visible = false
	avatar_v["root"].visible = true
	face_light.visible = false

func show_bald() -> void:
	bald_visible = true
	face_light.visible = true
	avatar_v["root"].visible = false
	avatar_b["root"].visible = true
	var bz := maxf(plane_z + 0.75, follow_pos.z - 1.3)
	avatar_b["root"].global_position = Vector3(follow_pos.x, 0, bz)
	avatar_b["root"].rotation.y = 0.0
	_glitch = 0.8

## 秃头大叔猛地扑向玻璃
func lunge(duration: float = 0.35) -> void:
	var tw = avatar_b["root"].create_tween()
	var target := Vector3(follow_pos.x, 0, plane_z + 0.2)
	tw.tween_property(avatar_b["root"], "global_position", target, duration).set_trans(Tween.TRANS_EXPO).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(avatar_b["root"], "scale", Vector3.ONE * 1.08, duration)
	# 双手猛地拍向玻璃
	for side in ["l", "r"]:
		tw.parallel().tween_property(avatar_b["arm_" + side], "rotation:x", 1.5, duration)
		tw.parallel().tween_property(avatar_b["elbow_" + side], "rotation:x", 0.1, duration)
	tw.parallel().tween_property(avatar_b["head"], "rotation:z", 0.35, duration)
	# 扑向玻璃时一闪而过的红色 + 剧烈故障
	_glitch = 1.0
	var tr := create_tween()
	tr.tween_method(func(v: float): mat.set_shader_parameter("red", v), 0.0, 1.0, duration * 0.5)
	tr.tween_method(func(v: float): mat.set_shader_parameter("red", v), 1.0, 0.0, duration * 1.2)
	face_light.light_color = Color(1.0, 0.45, 0.4)
	face_light.position.y = 1.55

func shatter() -> void:
	broken = true
	face_light.visible = false
	_glitch = 0.0
	mat.set_shader_parameter("glitch", 0.0)
	mat.set_shader_parameter("red", 0.0)
	mat.set_shader_parameter("cracked", 1.0)
	vp.render_target_update_mode = SubViewport.UPDATE_DISABLED
	avatar_v["root"].visible = false
	avatar_b["root"].visible = false

func set_broken_instant() -> void:
	broken = true
	mat.set_shader_parameter("cracked", 1.0)
	avatar_v["root"].visible = false
	avatar_b["root"].visible = false
