extends Node

signal skin_changed(new_skin: String)

static var current_skin: String = "sd"

func _ready() -> void:
	current_skin = "sd"

static func set_skin(_skin_id: String) -> void:
	current_skin = "sd"

static func get_skin_path(category: String, filename: String, skin: String = "") -> String:
	var s = skin if skin != "" else current_skin
	return "res://assets/skins/%s/%s/%s" % [s, category, filename]

static func get_sprite(name: String) -> Texture2D:
	var path = get_skin_path("sprites", name + ".png")
	if ResourceLoader.exists(path):
		return load(path)
	var fallback = get_skin_path("sprites", name + ".png", "sd")
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

static func get_building(name: String) -> Texture2D:
	var path = get_skin_path("buildings", name + ".png")
	if ResourceLoader.exists(path):
		return load(path)
	var fallback = get_skin_path("buildings", name + ".png", "sd")
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

static func get_ui(name: String) -> Texture2D:
	var path = get_skin_path("ui", name + ".png")
	if ResourceLoader.exists(path):
		return load(path)
	var fallback = get_skin_path("ui", name + ".png", "sd")
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

static func get_tile(name: String) -> Texture2D:
	var path = get_skin_path("tiles", name + ".png")
	if ResourceLoader.exists(path):
		return load(path)
	var fallback = get_skin_path("tiles", name + ".png", "sd")
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

static func get_portrait(unit_name: String) -> Texture2D:
	var path = get_skin_path("portrait", unit_name + "_portrait.png")
	if ResourceLoader.exists(path):
		return load(path)
	var fallback = get_skin_path("portrait", unit_name + "_portrait.png", "sd")
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

static func get_sfx(name: String) -> AudioStream:
	var path = get_skin_path("sfx", name + ".wav")
	if ResourceLoader.exists(path):
		return load(path)
	var fallback = get_skin_path("sfx", name + ".wav", "sd")
	if ResourceLoader.exists(fallback):
		return load(fallback)
	return null

static func get_music(name: String) -> AudioStream:
	var path_ogg = get_skin_path("music", name + ".ogg")
	if ResourceLoader.exists(path_ogg):
		var res = load(path_ogg)
		if res:
			return res
	if FileAccess.file_exists(path_ogg):
		var stream = AudioStreamOggVorbis.load_from_file(path_ogg)
		if stream:
			return stream
	var path_wav = get_skin_path("music", name + ".wav")
	if ResourceLoader.exists(path_wav):
		return load(path_wav)
	var fallback_ogg = get_skin_path("music", name + ".ogg", "sd")
	if ResourceLoader.exists(fallback_ogg):
		var res = load(fallback_ogg)
		if res:
			return res
	if FileAccess.file_exists(fallback_ogg):
		var stream = AudioStreamOggVorbis.load_from_file(fallback_ogg)
		if stream:
			return stream
	var fallback_wav = get_skin_path("music", name + ".wav", "sd")
	if ResourceLoader.exists(fallback_wav):
		return load(fallback_wav)
	return null
