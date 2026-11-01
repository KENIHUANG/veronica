extends CanvasLayer
## PS1 复古画面:把 3D 画面降到约 240 线、色彩量化 + 4x4 有序抖动、轻微暗角。
## 位于 UI(layer 10)之下,所以文字、按钮仍然清晰。开关存在 L.retro。
## 粗糙的程序化模型在这种画风下反而成为风格;导入的模型也会被统一到同一画风里。

const SHADER := """
shader_type canvas_item;
uniform sampler2D screen_tex : hint_screen_texture, filter_nearest, repeat_disable;
uniform vec2 target_res = vec2(426.0, 240.0);
uniform float levels = 28.0;       // 每通道色阶数
uniform float dither_amt = 1.0;
uniform float vignette = 0.35;
void fragment() {
	vec2 px = floor(SCREEN_UV * target_res);
	vec2 uv = (px + 0.5) / target_res;
	vec3 c = textureLod(screen_tex, uv, 0.0).rgb;   // 用 Lod 0:floor 后的 UV 导数不连续,普通采样会选到模糊的 mip
	float b[16] = float[16](0.0, 8.0, 2.0, 10.0, 12.0, 4.0, 14.0, 6.0, 3.0, 11.0, 1.0, 9.0, 15.0, 7.0, 13.0, 5.0);
	int bi = int(mod(px.x, 4.0)) + int(mod(px.y, 4.0)) * 4;
	float d = (b[bi] / 16.0 - 0.5) / levels * dither_amt;
	c = floor((c + d) * levels + 0.5) / levels;
	vec2 q = SCREEN_UV - 0.5;
	c *= 1.0 - vignette * dot(q, q) * 2.0;
	COLOR = vec4(c, 1.0);
}
"""

const LINES := 240.0

var rect: ColorRect
var mat: ShaderMaterial

func _ready() -> void:
	layer = 9
	process_mode = Node.PROCESS_MODE_ALWAYS
	rect = ColorRect.new()
	rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	rect.set_anchors_preset(Control.PRESET_FULL_RECT)
	var sh := Shader.new()
	sh.code = SHADER
	mat = ShaderMaterial.new()
	mat.shader = sh
	rect.material = mat
	add_child(rect)
	apply()
	L.changed.connect(apply)

func apply() -> void:
	visible = L.retro
	_update_res()

func _update_res() -> void:
	var s := get_viewport().get_visible_rect().size
	if s.y <= 0.0:
		return
	var h := minf(LINES, s.y)
	mat.set_shader_parameter("target_res", Vector2(round(s.x * h / s.y), h))

func _process(_delta: float) -> void:
	if visible:
		_update_res()
