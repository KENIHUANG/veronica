extends Node3D
## 收集品的微光:材质自发光缓慢呼吸,外加一盏很小的暖光照亮周围。
var mat: StandardMaterial3D
var light: OmniLight3D
var t := randf() * 6.0

func _process(delta: float) -> void:
	t += delta
	var k := 0.5 + 0.5 * sin(t * 2.6)
	if mat != null:
		mat.emission_energy_multiplier = 0.35 + 0.9 * k
	if light != null:
		light.light_energy = 0.25 + 0.35 * k
