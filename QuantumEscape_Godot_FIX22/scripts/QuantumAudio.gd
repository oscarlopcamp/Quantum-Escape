extends Node

# Original music stems keep the same playhead while the scene changes their mix.
const AMBIENT_PATH: String = "res://audio/quantum_ambient.wav"
const PULSE_PATH: String = "res://audio/quantum_pulse.wav"
const AMBIENT_STREAM: AudioStreamWAV = preload("res://audio/quantum_ambient.wav")
const PULSE_STREAM: AudioStreamWAV = preload("res://audio/quantum_pulse.wav")
const CUE_SAMPLE_RATE: int = 22050
const SILENT_DB: float = -80.0
const SCENE_MIX: Dictionary = {
	"menu": Vector2(-12.0, -30.0),
	"classic": Vector2(-16.0, -14.0),
	"quantum": Vector2(-16.0, -12.0),
	"entanglement": Vector2(-16.0, -10.0),
	"modal": Vector2(-18.0, -25.0),
}

var muted: bool = false
var _ambient: AudioStreamPlayer
var _pulse: AudioStreamPlayer
var _cue_players: Array[AudioStreamPlayer] = []
var _cues: Dictionary = {}
var _scene_mode: String = "menu"
var _mix_tween: Tween
var _next_cue_player: int = 0


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_ambient = _create_player("Ambient", SILENT_DB)
	_pulse = _create_player("Pulse", SILENT_DB)
	_ambient.stream = _load_music_loop(AMBIENT_PATH)
	_pulse.stream = _load_music_loop(PULSE_PATH)
	for index in range(4):
		_cue_players.append(_create_player("Cue%d" % (index + 1), -15.0))
	_build_cues()
	# Both starts are submitted in the same frame, so the stems remain in sync.
	if _ambient.stream != null:
		_ambient.play()
	if _pulse.stream != null:
		_pulse.play()
	_fade_mix(1.0)


func set_scene(mode: String) -> void:
	if not SCENE_MIX.has(mode):
		mode = "menu"
	if _scene_mode == mode:
		return
	_scene_mode = mode
	if is_instance_valid(_ambient):
		_fade_mix(0.75)


func set_muted(value: bool) -> void:
	if muted == value:
		return
	muted = value
	if muted:
		for player in _cue_players:
			player.stop()
	if is_instance_valid(_ambient):
		_fade_mix(0.18 if muted else 0.5)


func play_cue(cue_name: String) -> void:
	if muted or not _cues.has(cue_name) or _cue_players.is_empty():
		return
	var player: AudioStreamPlayer = _cue_players[_next_cue_player]
	for offset in range(_cue_players.size()):
		var candidate: int = (_next_cue_player + offset) % _cue_players.size()
		if not _cue_players[candidate].playing:
			player = _cue_players[candidate]
			_next_cue_player = candidate
			break
	_next_cue_player = (_next_cue_player + 1) % _cue_players.size()
	player.stop()
	player.stream = _cues[cue_name]
	player.volume_db = -12.0 if cue_name in ["caught", "victory"] else -15.0
	player.play()


func _create_player(player_name: String, level_db: float) -> AudioStreamPlayer:
	var player := AudioStreamPlayer.new()
	player.name = player_name
	player.volume_db = level_db
	add_child(player)
	return player


func _load_music_loop(path: String) -> AudioStreamWAV:
	var stream: AudioStreamWAV
	# Explicit resource dependencies keep both music assets in exported builds.
	if path == AMBIENT_PATH:
		stream = AMBIENT_STREAM.duplicate() as AudioStreamWAV
	elif path == PULSE_PATH:
		stream = PULSE_STREAM.duplicate() as AudioStreamWAV
	elif FileAccess.file_exists(path):
		# Runtime loading also works before the editor has imported the new assets.
		stream = AudioStreamWAV.load_from_file(path, {
			"force/8_bit": false,
			"compress/mode": 0,
		})
	elif ResourceLoader.exists(path, "AudioStreamWAV"):
		# Exported projects can contain an imported resource instead of a raw WAV.
		stream = ResourceLoader.load(path, "AudioStreamWAV") as AudioStreamWAV
	if stream == null:
		push_warning("Quantum Audio: no se pudo cargar %s" % path)
		return null
	var channels: int = 2 if stream.stereo else 1
	var sample_bytes: int = 2 if stream.format == AudioStreamWAV.FORMAT_16_BITS else 1
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	if stream.format in [AudioStreamWAV.FORMAT_8_BITS, AudioStreamWAV.FORMAT_16_BITS]:
		stream.loop_end = stream.data.size() / (channels * sample_bytes)
	else:
		stream.loop_end = roundi(stream.get_length() * stream.mix_rate)
	return stream


func _fade_mix(duration: float) -> void:
	if _mix_tween != null and _mix_tween.is_valid():
		_mix_tween.kill()
	var levels: Vector2 = SCENE_MIX[_scene_mode]
	if muted:
		levels = Vector2(SILENT_DB, SILENT_DB)
	_mix_tween = create_tween().set_parallel(true)
	_mix_tween.set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	_mix_tween.tween_property(_ambient, "volume_db", levels.x, duration)
	_mix_tween.tween_property(_pulse, "volume_db", levels.y, duration)


func _build_cues() -> void:
	# Frequencies share the soundtrack's E minor / suspended palette. Each note is
	# (frequency, start, duration, gain); short fades keep all cue edges click-free.
	_cues["confirm"] = _synthesize([
		Vector4(659.26, 0.0, 0.14, 0.65), Vector4(987.77, 0.07, 0.18, 0.5),
	], 0.26)
	_cues["superposition_on"] = _synthesize([
		Vector4(329.63, 0.0, 0.45, 0.4), Vector4(493.88, 0.06, 0.43, 0.4),
		Vector4(739.99, 0.12, 0.42, 0.35),
	], 0.55, true)
	_cues["superposition_off"] = _synthesize([
		Vector4(493.88, 0.0, 0.17, 0.55), Vector4(329.63, 0.09, 0.24, 0.6),
	], 0.34)
	_cues["switch"] = _synthesize([
		Vector4(987.77, 0.0, 0.11, 0.55), Vector4(739.99, 0.065, 0.14, 0.5),
	], 0.22)
	_cues["collapse"] = _synthesize([
		Vector4(659.26, 0.0, 0.16, 0.55), Vector4(493.88, 0.055, 0.18, 0.5),
		Vector4(329.63, 0.12, 0.27, 0.55),
	], 0.4)
	_cues["caught"] = _synthesize([
		Vector4(164.81, 0.0, 0.22, 0.65), Vector4(123.47, 0.12, 0.22, 0.6),
		Vector4(82.41, 0.25, 0.3, 0.65),
	], 0.56)
	_cues["entangled"] = _synthesize([
		Vector4(329.63, 0.0, 0.52, 0.35), Vector4(493.88, 0.04, 0.5, 0.35),
		Vector4(739.99, 0.08, 0.47, 0.35),
	], 0.56, true)
	_cues["delivery"] = _synthesize([
		Vector4(493.88, 0.0, 0.22, 0.6), Vector4(739.99, 0.08, 0.24, 0.55),
		Vector4(987.77, 0.17, 0.3, 0.45),
	], 0.48)
	_cues["victory"] = _synthesize([
		Vector4(329.63, 0.0, 0.32, 0.45), Vector4(493.88, 0.1, 0.32, 0.4),
		Vector4(587.33, 0.2, 0.36, 0.4), Vector4(739.99, 0.3, 0.4, 0.4),
		Vector4(987.77, 0.4, 0.36, 0.4),
	], 0.77, true)


func _synthesize(notes: Array, duration: float, shimmer: bool = false) -> AudioStreamWAV:
	var sample_count: int = ceili(duration * CUE_SAMPLE_RATE)
	var pcm := PackedByteArray()
	pcm.resize(sample_count * 2)
	for sample_index in range(sample_count):
		var time: float = float(sample_index) / CUE_SAMPLE_RATE
		var sample: float = 0.0
		for note: Vector4 in notes:
			var local_time: float = time - note.y
			if local_time < 0.0 or local_time >= note.z:
				continue
			var attack: float = minf(local_time / 0.008, 1.0)
			var release: float = minf((note.z - local_time) / 0.035, 1.0)
			var envelope: float = attack * release * exp(-4.0 * local_time / note.z)
			var phase: float = TAU * note.x * local_time
			var tone: float = sin(phase) * 0.78 + sin(phase * 2.0) * 0.14
			if shimmer:
				tone += sin(phase * 3.0) * 0.08
			sample += tone * envelope * note.w * 0.48
		var encoded: int = roundi(clampf(sample, -0.95, 0.95) * 32767.0)
		pcm.encode_s16(sample_index * 2, encoded)
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = CUE_SAMPLE_RATE
	stream.stereo = false
	stream.data = pcm
	return stream
