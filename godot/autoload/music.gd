extends Node

## Runtime-generated ambient cyber BGM loop + audio buses (BGM / SFX)

const SAMPLE_RATE := 22050
const CHORD_LEN := 3.2 # seconds per chord
# A-minor flavored progression: Am, F, C, G (root/fifth/octave-ish voicings)
const CHORDS := [
	[110.0, 164.81, 220.0, 329.63],
	[87.31, 130.81, 174.61, 261.63],
	[130.81, 196.0, 261.63, 392.0],
	[98.0, 146.83, 196.0, 293.66],
]
const ARP_NOTES := [220.0, 261.63, 329.63, 392.0, 440.0, 523.25]

var _player: AudioStreamPlayer


func _ready() -> void:
	_ensure_bus("BGM")
	_ensure_bus("SFX")

	_player = AudioStreamPlayer.new()
	_player.bus = "BGM"
	_player.volume_db = -16.0
	add_child(_player)
	_player.stream = _make_bgm_loop()

	GameState.game_started.connect(_on_game_started)
	GameState.game_over_changed.connect(_on_game_over)


func _on_game_started() -> void:
	_player.volume_db = -16.0
	if not _player.playing:
		_player.play()


func _on_game_over(_result: String) -> void:
	fade_to(-28.0, 1.4)


func stop_bgm() -> void:
	if _player == null:
		return
	var tw := create_tween()
	tw.tween_property(_player, "volume_db", -48.0, 0.45)
	tw.tween_callback(func() -> void:
		_player.stop()
		_player.volume_db = -16.0
	)


func fade_to(db: float, duration: float = 1.0) -> void:
	if _player == null or not _player.playing:
		return
	var tw := create_tween()
	tw.tween_property(_player, "volume_db", db, duration)


func set_bgm_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("BGM"), linear_to_db(clampf(linear, 0.0001, 1.0)))


func set_sfx_volume(linear: float) -> void:
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("SFX"), linear_to_db(clampf(linear, 0.0001, 1.0)))


func get_bgm_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("BGM")))


func get_sfx_volume() -> float:
	return db_to_linear(AudioServer.get_bus_volume_db(AudioServer.get_bus_index("SFX")))


func _ensure_bus(bus_name: String) -> void:
	if AudioServer.get_bus_index(bus_name) != -1:
		return
	AudioServer.add_bus()
	var idx := AudioServer.bus_count - 1
	AudioServer.set_bus_name(idx, bus_name)
	AudioServer.set_bus_send(idx, "Master")


func _make_bgm_loop() -> AudioStreamWAV:
	var duration := CHORD_LEN * CHORDS.size()
	var sample_count := int(SAMPLE_RATE * duration)
	var data := PackedByteArray()
	data.resize(sample_count * 2)
	var rng := RandomNumberGenerator.new()
	rng.seed = 9

	for i in sample_count:
		var t := float(i) / float(SAMPLE_RATE)
		var chord_i := int(t / CHORD_LEN) % CHORDS.size()
		var chord: Array = CHORDS[chord_i]
		var ct := fmod(t, CHORD_LEN)
		var sample_f := 0.0

		# Crossfade between chords near boundaries to keep the loop seamless
		var fade := 1.0
		if ct < 0.25:
			fade = ct / 0.25
		elif ct > CHORD_LEN - 0.25:
			fade = (CHORD_LEN - ct) / 0.25

		# Pad: detuned sines, slow tremolo
		var tremolo := 0.85 + 0.15 * sin(t * 0.8 * TAU)
		for f in chord:
			var freq := float(f)
			sample_f += sin(t * freq * TAU) * 0.09 * fade * tremolo
			sample_f += sin(t * freq * 1.003 * TAU) * 0.05 * fade * tremolo

		# Sub bass pulse on the root, every 0.8s
		var beat := fmod(t, 0.8)
		var bass_env := maxf(0.0, 1.0 - beat / 0.5)
		sample_f += sin(t * float(chord[0]) * 0.5 * TAU) * 0.22 * bass_env * fade

		# Sparse soft arp pluck every 0.4s
		var step := int(t / 0.4)
		var arp_t := fmod(t, 0.4)
		if step % 3 != 2: # rests keep it airy
			var note: float = ARP_NOTES[(step * 7 + chord_i * 3) % ARP_NOTES.size()]
			var pluck_env := maxf(0.0, 1.0 - arp_t / 0.3) * 0.07
			sample_f += sin(t * note * TAU) * pluck_env * fade

		# Gentle air noise
		sample_f += rng.randf_range(-1.0, 1.0) * 0.012

		sample_f = clampf(sample_f, -1.0, 1.0)
		data.encode_s16(i * 2, int(sample_f * 32767.0))

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	stream.loop_end = sample_count
	return stream
