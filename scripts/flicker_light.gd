extends OmniLight3D
## 会闪烁的灯。可同步自发光材质。支持全局熄灯(blackout)与短暂熄灭(pulse_off)。

var base_energy: float = 1.0
var flicker: float = 0.12
var cutout_chance: float = 0.0
var emissive_mat: StandardMaterial3D = null
var emissive_base: float = 2.0
var t: float = 0.0
var clock: float = 0.0
var off_until: float = 0.0
var blackout: bool = false

func _ready() -> void:
	add_to_group("lamps")
	t = randf() * 100.0

func _process(delta: float) -> void:
	clock += delta
	t += delta
	var k := 1.0
	if blackout or clock < off_until:
		k = 0.0
	else:
		k = 1.0 - flicker * (0.5 + 0.5 * sin(t * 37.0) * sin(t * 11.0))
		if cutout_chance > 0.0 and randf() < cutout_chance * delta:
			off_until = clock + randf_range(0.04, 0.22)
	light_energy = base_energy * k
	if emissive_mat != null:
		emissive_mat.emission_energy_multiplier = emissive_base * k

func pulse_off(d: float) -> void:
	off_until = clock + d

func set_blackout(v: bool) -> void:
	blackout = v

## 演出高潮:灯不再闪,变成温暖的白光
func calm_down() -> void:
	flicker = 0.02
	cutout_chance = 0.0
	off_until = 0.0
	blackout = false
	var tw := create_tween()
	tw.tween_property(self, "light_color", Color(1.0, 0.93, 0.78), 1.5)
	tw.parallel().tween_property(self, "base_energy", base_energy * 1.25, 1.5)
