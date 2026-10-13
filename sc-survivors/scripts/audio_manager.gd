extends Node

var music_player: AudioStreamPlayer
var sfx_pool: Array[AudioStreamPlayer] = []
var max_sfx_voices: int = 16

var music_volume: float = 0.20
var sfx_volume: float = 0.20

var current_music_name: String = ""
var current_music_loop: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	music_player = AudioStreamPlayer.new()
	music_player.bus = "Master"
	music_player.volume_db = _vol_to_db(music_volume)
	music_player.finished.connect(_on_music_finished)
	add_child(music_player)
	
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

func set_music_volume(val: float) -> void:
	music_volume = clamp(val, 0.0, 1.0)
	if music_player:
		music_player.volume_db = _vol_to_db(music_volume)

func set_sfx_volume(val: float) -> void:
	sfx_volume = clamp(val, 0.0, 1.0)
	var db = _vol_to_db(sfx_volume)
	for p in sfx_pool:
		p.volume_db = db

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

