extends Node

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var max_sfx_voices: int = 16

var music_volume: float = 0.50
var sfx_volume: float = 0.80
var voice_volume: float = 0.90

var voice_player: AudioStreamPlayer = null
var voice_cache: Dictionary = {}

var current_music_name: String = ""
var current_music_loop: bool = true
const AUDIO_SETTINGS_PATH = "user://audio_settings.json"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_audio_settings()
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = _vol_to_db(music_volume)
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	
	voice_player = AudioStreamPlayer.new()
	voice_player.bus = "Master"
	voice_player.volume_db = _vol_to_db(voice_volume)
	add_child(voice_player)
	
	for i in range(max_sfx_voices):
		var p = AudioStreamPlayer.new()
		p.bus = "Master"
		p.volume_db = _vol_to_db(sfx_volume)
		add_child(p)
		sfx_pool.append(p)

func _on_music_finished() -> void:
	if current_music_loop and music_player.stream:
		music_player.play()

func _vol_to_db(val: float) -> float:
	if val <= 0.001:
		return -80.0
	return linear_to_db(val)

func set_music_volume(val: float, save: bool = true) -> void:
	music_volume = clamp(val, 0.0, 1.0)
	if music_player:
		music_player.volume_db = _vol_to_db(music_volume)
	if save:
		save_audio_settings()

func set_sfx_volume(val: float, save: bool = true) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	var db = _vol_to_db(sfx_volume)
	for p in sfx_pool:
		p.volume_db = db
	if save:
		save_audio_settings()

func set_voice_volume(val: float, save: bool = true) -> void:
	voice_volume = clamp(val, 0.0, 1.0)
	if voice_player:
		voice_player.volume_db = _vol_to_db(voice_volume)
	if save:
		save_audio_settings()

func load_audio_settings() -> void:
	if not FileAccess.file_exists(AUDIO_SETTINGS_PATH):
		return
	var file = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			if parsed.has("music_volume"):
				music_volume = clamp(float(parsed.get("music_volume", 0.5)), 0.0, 1.0)
			if parsed.has("sfx_volume"):
				sfx_volume = clamp(float(parsed.get("sfx_volume", 0.8)), 0.0, 1.0)
			if parsed.has("voice_volume"):
				voice_volume = clamp(float(parsed.get("voice_volume", 0.9)), 0.0, 1.0)

func save_audio_settings() -> void:
	var file = FileAccess.open(AUDIO_SETTINGS_PATH, FileAccess.WRITE)
	if file:
		var data = {
			"music_volume": music_volume,
			"sfx_volume": sfx_volume,
			"voice_volume": voice_volume
		}
		file.store_string(JSON.stringify(data, "\t"))

func get_voice_stream(voice_id: String) -> AudioStream:
	var id_clean = voice_id.strip_edges().to_upper()
	if voice_cache.has(id_clean):
		return voice_cache[id_clean]
	
	var subfolder = "VOSS"
	if id_clean.begins_with("PROTAG"):
		subfolder = "PROTAG"
	elif id_clean.begins_with("ADJ") or id_clean.begins_with("ADVISOR") or id_clean.begins_with("OPERA"):
		subfolder = "ADVISOR"
	
	var formatted_id = id_clean
	var parts = id_clean.split("_")
	if parts.size() == 2 and parts[1].is_valid_int():
		formatted_id = "%s_%02d" % [parts[0], int(parts[1])]
	
	var candidate_paths = [
		"res://assets/voices/%s/%s.ogg" % [subfolder, formatted_id],
		"res://assets/voices/%s/%s.ogg" % [subfolder, id_clean],
		"res://assets/voices/%s/%s.mp3" % [subfolder, formatted_id],
		"res://assets/voices/%s/%s.mp3" % [subfolder, id_clean],
		"res://assets/voices/%s/%s.wav" % [subfolder, formatted_id],
		"res://assets/voices/%s/%s.wav" % [subfolder, id_clean],
		"res://assets/voices/ADVISOR/%s.ogg" % formatted_id,
		"res://assets/voices/ADVISOR/%s.mp3" % formatted_id,
		"res://assets/voices/VOSS/%s.ogg" % formatted_id,
		"res://assets/voices/PROTAG/%s.ogg" % formatted_id
	]
	
	for path in candidate_paths:
		if ResourceLoader.exists(path):
			var res = load(path)
			if res is AudioStream:
				voice_cache[id_clean] = res
				return res
		if FileAccess.file_exists(path):
			if path.ends_with(".ogg"):
				var stream = AudioStreamOggVorbis.load_from_file(path)
				if stream:
					stream.loop = false
					voice_cache[id_clean] = stream
					return stream
				var file_bytes = FileAccess.get_file_as_bytes(path)
				if file_bytes.size() > 0:
					var stream_buf = AudioStreamOggVorbis.load_from_buffer(file_bytes)
					if stream_buf:
						stream_buf.loop = false
						voice_cache[id_clean] = stream_buf
						return stream_buf
			elif path.ends_with(".mp3"):
				var file_bytes = FileAccess.get_file_as_bytes(path)
				if file_bytes.size() > 0:
					var stream = AudioStreamMP3.new()
					stream.data = file_bytes
					stream.loop = false
					voice_cache[id_clean] = stream
					return stream
	return null

func play_voice(voice_id: String) -> float:
	if voice_id.is_empty():
		return 0.0
	var stream = get_voice_stream(voice_id)
	if stream == null:
		return 0.0
	if voice_player:
		voice_player.stop()
		voice_player.stream = stream
		voice_player.volume_db = _vol_to_db(voice_volume)
		voice_player.play()
		return stream.get_length()
	return 0.0

func stop_voice() -> void:
	if voice_player and voice_player.playing:
		voice_player.stop()

func is_voice_playing() -> bool:
	return voice_player != null and voice_player.playing

func play_music(music_name: String, loop: bool = true, force_restart: bool = false) -> void:
	if not force_restart and current_music_name == music_name and music_player.playing:
		return
	current_music_name = music_name
	current_music_loop = loop
	var stream = SkinManager.get_music(music_name)
	if stream:
		if stream is AudioStreamOggVorbis:
			stream.loop = loop
		elif "loop" in stream:
			stream.loop = loop
		elif stream is AudioStreamWAV:
			if loop:
				stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
			else:
				stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
		
		music_player.stream = stream
		music_player.volume_db = _vol_to_db(music_volume)
		music_player.play()

func stop_music() -> void:
	current_music_name = ""
	if music_player:
		music_player.stop()

func play_sfx(sfx_name: String, pitch_range: float = 0.05, volume_offset_db: float = 0.0) -> void:
	var stream = SkinManager.get_sfx(sfx_name)
	if stream == null:
		return
	
	var base_db = _vol_to_db(sfx_volume)
	var target_db = -80.0 if sfx_volume <= 0.001 else (base_db + volume_offset_db)
	
	if sfx_pool.is_empty():
		return
	
	# Buscar reproductor libre en el pool
	for p in sfx_pool:
		if not p.playing:
			p.stream = stream
			p.volume_db = target_db
			if pitch_range > 0.0:
				p.pitch_scale = randf_range(1.0 - pitch_range, 1.0 + pitch_range)
			else:
				p.pitch_scale = 1.0
			p.play()
			return
	
	# Si todos estan ocupados, usar el primero
	var p = sfx_pool[0]
	p.stream = stream
	p.volume_db = target_db
	p.pitch_scale = 1.0
	p.play()

func play_voss_greeting() -> void:
	var idx = randi() % 5
	play_sfx("voss_greet%d" % idx)

