extends Node

## Runtime-generated SFX — layered synth for distinct combat feedback

const POOL_SIZE := 6
const LASER_POOL := 2

var _players: Array[AudioStreamPlayer] = []
var _laser_players: Array[AudioStreamPlayer] = []
var _streams: Dictionary = {}
var _pool_i: int = 0
var _laser_i: int = 0


func _ready() -> void:
	_streams["hit"] = _make_noise_blip(0.07, 0.22, 1400.0, 0.35)
	_streams["splash"] = _make_chord_hit([420.0, 630.0, 840.0], 0.12, 0.24)
	_streams["build"] = _make_tone(520.0, 0.09, 0.26)
	_streams["upgrade"] = _make_chord_hit([660.0, 880.0, 1320.0], 0.16, 0.22)
	_streams["kill"] = _make_noise_blip(0.11, 0.28, 180.0, 0.55)
	_streams["boss_kill"] = _make_boss_kill()
	_streams["wave"] = _make_chord_hit([330.0, 440.0, 550.0], 0.22, 0.18)
	_streams["ui"] = _make_tone(740.0, 0.04, 0.14)
	_streams["laser"] = _make_gaster_laser()

	var sfx_bus := "SFX" if AudioServer.get_bus_index("SFX") != -1 else "Master"
	for i in POOL_SIZE:
		var p := AudioStreamPlayer.new()
		p.bus = sfx_bus
		p.volume_db = -10.0
		add_child(p)
		_players.append(p)

	for i in LASER_POOL:
		var lp := AudioStreamPlayer.new()
		lp.bus = sfx_bus
		lp.volume_db = -14.0
		add_child(lp)
		_laser_players.append(lp)

	GameState.attack_fired.connect(_on_attack_fired)
	GameState.unit_built.connect(_on_unit_built)
	GameState.monster_killed.connect(_on_monster_killed)
	GameState.phase_changed.connect(_on_phase_changed)
	GameState.boss_spawned.connect(_on_boss_spawned)


func play(kind: String) -> void:
	if not _streams.has(kind):
		return
	if kind == "laser":
		var lp: AudioStreamPlayer = _laser_players[_laser_i]
		_laser_i = (_laser_i + 1) % LASER_POOL
		lp.stream = _streams["laser"]
		lp.play()
		return
	var p: AudioStreamPlayer = _players[_pool_i]
	_pool_i = (_pool_i + 1) % POOL_SIZE
	p.stream = _streams[kind]
	p.play()


func _on_attack_fired(mode: String, _faction: String) -> void:
	if mode == "single":
		play("laser")
	else:
		play("splash")


func _on_unit_built(_type_key: String) -> void:
	play("build")


func _on_monster_killed(is_boss: bool) -> void:
	play("boss_kill" if is_boss else "kill")


func _on_phase_changed(phase_type: String, _wave: int) -> void:
	if phase_type == "COMBAT":
		play("wave")


func _on_boss_spawned(_type_key: String, _is_final: bool) -> void:
	play("wave")


func _make_tone(freq: float, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := 1.0 - (t / duration)
		env = clampf(env, 0.0, 1.0)
		if t < 0.005:
			env *= t / 0.005
		var sample := int(sin(t * freq * TAU) * volume * env * 32767.0)
		data.encode_s16(i * 2, clampi(sample, -32768, 32767))
	return _wav_from_data(data, sample_rate)


func _make_chord_hit(freqs: Array, duration: float, volume: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		if t < 0.008:
			env *= t / 0.008
		var sample_f := 0.0
		for f in freqs:
			sample_f += sin(t * float(f) * TAU) * (volume / float(freqs.size()))
		sample_f *= env
		data.encode_s16(i * 2, clampi(int(sample_f * 32767.0), -32768, 32767))
	return _wav_from_data(data, sample_rate)


func _make_noise_blip(duration: float, volume: float, tone: float, noise_amt: float) -> AudioStreamWAV:
	var sample_rate := 22050
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = int(tone * 17.0)
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var env := clampf(1.0 - t / duration, 0.0, 1.0)
		env *= env
		var sample_f := sin(t * tone * TAU) * (1.0 - noise_amt) + rng.randf_range(-1.0, 1.0) * noise_amt
		sample_f *= volume * env
		data.encode_s16(i * 2, clampi(int(sample_f * 32767.0), -32768, 32767))
	return _wav_from_data(data, sample_rate)


func _make_boss_kill() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.45
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 909
	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var u := t / duration
		var env := clampf(1.0 - u, 0.0, 1.0)
		if t < 0.02:
			env *= t / 0.02
		var freq := lerpf(140.0, 40.0, u)
		var sample_f := sin(t * freq * TAU) * 0.45
		sample_f += sin(t * freq * 2.0 * TAU) * 0.2
		sample_f += rng.randf_range(-1.0, 1.0) * 0.22 * (1.0 - u)
		sample_f *= env * 0.55
		data.encode_s16(i * 2, clampi(int(sample_f * 32767.0), -32768, 32767))
	return _wav_from_data(data, sample_rate)


## Charge whine → long heavy sustained beam (energy-blaster vibe, original synth)
func _make_gaster_laser() -> AudioStreamWAV:
	var sample_rate := 22050
	var duration := 0.85
	var sample_count := int(sample_rate * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1337

	for i in sample_count:
		var t := float(i) / float(sample_rate)
		var sample_f := 0.0

		if t < 0.14:
			var ct := t / 0.14
			var freq := lerpf(180.0, 900.0, ct * ct)
			var env := ct * 0.28
			sample_f += sin(t * freq * TAU) * env
			sample_f += sin(t * freq * 2.01 * TAU) * env * 0.2
			sample_f += sin(t * 55.0 * TAU) * env * 0.35
		else:
			var bt := t - 0.14
			var beam_len := duration - 0.14
			var u := bt / beam_len
			var open := 1.0
			if bt < 0.04:
				open = bt / 0.04
			var sustain := 1.0
			if u > 0.62:
				sustain = 1.0 - ((u - 0.62) / 0.38)
			sustain = clampf(sustain, 0.0, 1.0)
			var env := open * sustain
			var low := 48.0 + sin(bt * 9.0) * 3.0
			var phase := fmod(bt * low, 1.0)
			var saw := phase * 2.0 - 1.0
			sample_f += saw * 0.48 * env
			sample_f += sin(bt * 52.0 * TAU) * 0.42 * env
			sample_f += sin(bt * 78.0 * TAU) * 0.28 * env
			sample_f += sin(bt * 110.0 * TAU) * 0.2 * env
			sample_f += sin(bt * 128.0 * TAU) * 0.14 * env
			var scream_f := 980.0 + sin(bt * 22.0) * 60.0
			sample_f += sin(bt * scream_f * TAU) * 0.08 * env
			var noise := rng.randf_range(-1.0, 1.0)
			sample_f += noise * 0.18 * env
			sample_f += noise * 0.12 * env * (1.0 - u * 0.5)
			if bt < 0.025:
				sample_f += rng.randf_range(-1.0, 1.0) * (1.0 - bt / 0.025) * 0.35

		sample_f = clampf(sample_f * 0.38, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample_f * 32767.0))

	return _wav_from_data(data, sample_rate)


func _wav_from_data(data: PackedByteArray, sample_rate: int) -> AudioStreamWAV:
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = sample_rate
	stream.stereo = false
	stream.data = data
	return stream
