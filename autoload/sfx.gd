extends Node
## 程序化生成的音效(不需要任何音频文件)。以后可以替换成真正的音频。

const RATE := 22050
var streams: Dictionary = {}
var loops: Dictionary = {}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	seed(1234)
	streams["pickup"] = _wav(_cat([_tone(660.0, 0.07, 6.0, 0.4), _tone(990.0, 0.12, 6.0, 0.4)]))
	streams["ding"] = _wav(_mix([_tone(880.0, 1.0, 3.0, 0.4), _tone(1320.0, 1.0, 3.5, 0.3)]))
	streams["buzz"] = _wav(_square(110.0, 0.4, 0.25))
	streams["click"] = _wav(_noise(0.07, 0.9, 70.0, 0.9))
	streams["step"] = _wav(_noise(0.11, 0.18, 26.0, 0.55))
	streams["hurt"] = _wav(_mix([_tone(70.0, 0.4, 7.0, 0.9), _noise(0.4, 0.3, 9.0, 0.6)]))
	streams["glass"] = _wav(_mix([_noise(1.1, 0.95, 3.5, 0.7), _noise(0.15, 1.0, 40.0, 0.9)]))
	streams["sting"] = _wav(_mix([_tone(185.0, 1.6, 2.0, 0.35), _tone(196.6, 1.6, 2.0, 0.35), _tone(370.0, 1.6, 2.6, 0.2), _noise(0.5, 0.5, 6.0, 0.6)]))
	streams["shriek"] = _wav(_sweep(380.0, 1100.0, 0.9, 0.45))
	streams["door"] = _wav(_creak(0.9))
	streams["water"] = _wav(_noise(0.9, 0.35, 1.2, 0.35))
	streams["glitch"] = _wav(_mix([_noise(0.3, 0.8, 8.0, 0.5), _square(300.0, 0.2, 0.15)]))
	streams["scream"] = _wav(_scream(2.6))
	streams["growl"] = _wav(_scream(1.1, 0.5))
	streams["thump"] = _wav(_tone(55.0, 0.5, 6.0, 0.9))
	streams["static"] = _wav(_noise_flat(1.0, 0.65, 0.22), true)
	streams["heart"] = _wav(_heart(), true)
	streams["drone"] = _wav(_drone(), true)

func play(sfx_name: String, vol_db: float = 0.0) -> void:
	if not streams.has(sfx_name):
		return
	var p := AudioStreamPlayer.new()
	p.stream = streams[sfx_name]
	p.volume_db = vol_db
	add_child(p)
	p.finished.connect(p.queue_free)
	p.play()

func loop(sfx_name: String, on: bool, vol_db: float = -6.0) -> void:
	if on:
		if loops.has(sfx_name) or not streams.has(sfx_name):
			return
		var p := AudioStreamPlayer.new()
		p.stream = streams[sfx_name]
		p.volume_db = vol_db
		add_child(p)
		p.play()
		loops[sfx_name] = p
	else:
		if loops.has(sfx_name):
			loops[sfx_name].queue_free()
			loops.erase(sfx_name)

# ---------- generators ----------
func _wav(samples: PackedFloat32Array, looped: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	data.resize(samples.size() * 2)
	for i in samples.size():
		data.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 30000.0))
	var s := AudioStreamWAV.new()
	s.format = AudioStreamWAV.FORMAT_16_BITS
	s.mix_rate = RATE
	s.stereo = false
	s.data = data
	if looped:
		s.loop_mode = AudioStreamWAV.LOOP_FORWARD
		s.loop_begin = 0
		s.loop_end = samples.size()
	return s

func _tone(freq: float, dur: float, decay: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		a[i] = sin(TAU * freq * t) * exp(-t * decay) * vol
	return a

func _square(freq: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		a[i] = (1.0 if sin(TAU * freq * t) > 0.0 else -1.0) * vol * (1.0 - float(i) / n)
	return a

func _noise(dur: float, lp: float, decay: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var prev := 0.0
	for i in n:
		var t := float(i) / RATE
		prev += (randf() * 2.0 - 1.0 - prev) * lp
		a[i] = prev * exp(-t * decay) * vol
	return a

func _noise_flat(dur: float, lp: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var prev := 0.0
	for i in n:
		prev += (randf() * 2.0 - 1.0 - prev) * lp
		a[i] = prev * vol
	return a

func _sweep(f0: float, f1: float, dur: float, vol: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / n
		ph += TAU * lerpf(f0, f1, t) / RATE
		a[i] = (sin(ph) * 0.7 + (randf() - 0.5) * 0.5) * vol * (1.0 - t)
	return a

func _creak(dur: float) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var ph := 0.0
	for i in n:
		var t := float(i) / RATE
		var f := 140.0 + 60.0 * sin(t * 7.0) + 40.0 * sin(t * 23.0)
		ph += TAU * f / RATE
		var saw := fmod(ph / TAU, 1.0) * 2.0 - 1.0
		a[i] = (saw * 0.25 + (randf() - 0.5) * 0.12) * (1.0 - t / dur) * minf(1.0, t * 12.0)
	return a

func _heart() -> PackedFloat32Array:
	var a := PackedFloat32Array()
	a.resize(RATE)
	for i in RATE:
		var t := float(i) / RATE
		var v := sin(TAU * 52.0 * t) * exp(-t * 14.0) * 0.9
		if t > 0.28:
			v += sin(TAU * 46.0 * (t - 0.28)) * exp(-(t - 0.28) * 16.0) * 0.7
		a[i] = v
	return a

func _drone() -> PackedFloat32Array:
	var dur := 4.0
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	for i in n:
		var t := float(i) / RATE
		a[i] = (sin(TAU * 55.0 * t) * 0.5 + sin(TAU * 55.25 * t) * 0.5 + sin(TAU * 82.5 * t) * 0.25) * 0.18
	return a

func _cat(parts: Array) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	for p in parts:
		out.append_array(p)
	return out

func _mix(parts: Array) -> PackedFloat32Array:
	var n := 0
	for p in parts:
		n = max(n, p.size())
	var out := PackedFloat32Array()
	out.resize(n)
	for p in parts:
		for i in p.size():
			out[i] += p[i]
	return out

func _scream(dur: float, pitch: float = 1.0) -> PackedFloat32Array:
	var n := int(dur * RATE)
	var a := PackedFloat32Array()
	a.resize(n)
	var ph := 0.0
	var jit := 0.0
	for i in n:
		var t := float(i) / RATE
		var u := t / dur
		jit += (randf() - 0.5) * 0.02
		jit *= 0.98
		var f := (520.0 + 260.0 * sin(PI * u) + 60.0 * sin(u * 9.0)) * pitch
		f *= 1.0 + 0.05 * sin(TAU * 7.0 * t) + jit
		ph += TAU * f / RATE
		var v := sin(ph) + 0.55 * sin(2.0 * ph + 0.6) + 0.35 * sin(3.0 * ph) + 0.2 * sin(5.0 * ph)
		v = tanh(v * 1.8)
		v += (randf() - 0.5) * 0.35 * sin(PI * u)
		var env := minf(1.0, t * 25.0) * (1.0 - pow(u, 3.0))
		a[i] = v * env * 0.5
	return a
