class_name SCPortrait
extends Control

@export var portrait_texture: Texture2D = null
@export var auto_scale_to_fill: bool = false
@export var enable_click_to_talk: bool = true
@export var voice_list: Array[String] = []

var texture_sheet: Texture2D = null
var current_frame: int = 0
var anim_timer: float = 0.0
var is_talking: bool = false
var talk_timer: float = 0.0

const FRAME_W: int = 60
const FRAME_H: int = 56
const COLS: int = 10
const ROWS: int = 3

@export var fallback_marine: bool = false

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	if portrait_texture:
		texture_sheet = portrait_texture
	elif fallback_marine:
		texture_sheet = load("res://assets/skins/sd/portrait/marine_portrait.png")

func _process(delta: float) -> void:
	if talk_timer > 0.0:
		talk_timer -= delta
		is_talking = true
	else:
		is_talking = false
	
	var fps = 12.0 if is_talking else 8.0
	anim_timer += delta * fps
	
	if is_talking:
		# Cuadros de hablar: 10 a 29 (20 cuadros)
		current_frame = 10 + (int(anim_timer) % 20)
	else:
		# Cuadros de respirar/idle: 0 a 9 (10 cuadros)
		current_frame = int(anim_timer) % 10
	
	queue_redraw()

func trigger_talk(duration: float = 1.4) -> void:
	talk_timer = max(talk_timer, duration)

func set_portrait(tex: Texture2D) -> void:
	texture_sheet = tex
	if tex != null:
		var path_str = tex.resource_path.to_lower()
		if "medic" in path_str:
			voice_list = [
				"medic_what0", "medic_what1", "medic_what2", "medic_what3",
				"medic_yes0", "medic_yes1", "medic_yes2", "medic_yes3"
			]
		elif "marine" in path_str:
			voice_list = ["marine_what0", "marine_what1", "marine_yes0", "marine_yes1"]
	queue_redraw()

func _gui_input(event: InputEvent) -> void:
	if not enable_click_to_talk or texture_sheet == null:
		return
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		trigger_talk(1.5)
		if voice_list.size() > 0:
			AudioManager.play_sfx(voice_list[randi() % voice_list.size()])
		else:
			var is_medic = false
			if GameManager and "selected_hero" in GameManager and GameManager.selected_hero == "medic":
				is_medic = true
			if texture_sheet and "medic" in texture_sheet.resource_path.to_lower():
				is_medic = true
			
			if is_medic:
				var m_voices = [
					"medic_what0", "medic_what1", "medic_what2", "medic_what3",
					"medic_yes0", "medic_yes1", "medic_yes2", "medic_yes3"
				]
				AudioManager.play_sfx(m_voices[randi() % m_voices.size()])
			else:
				var voices = ["marine_what0", "marine_what1", "marine_yes0", "marine_yes1"]
				AudioManager.play_sfx(voices[randi() % voices.size()])

func _draw() -> void:
	var w = size.x
	var h = size.y
	
	# Fondo azul marino oscuro
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.08, 1.0), true)
	
	if texture_sheet:
		if texture_sheet.get_width() <= FRAME_W * 2:
			# Textura estática (como el wireframe o civil)
			var dest_rect: Rect2
			if auto_scale_to_fill:
				var tex_sz = texture_sheet.get_size()
				var scale_factor = min(w / tex_sz.x, h / tex_sz.y)
				var draw_sz = tex_sz * scale_factor
				var dest_pos = Vector2((w - draw_sz.x) * 0.5, (h - draw_sz.y) * 0.5)
				dest_rect = Rect2(dest_pos, draw_sz)
			else:
				var dest_pos = Vector2((w - FRAME_W) * 0.5, (h - FRAME_H) * 0.5)
				dest_rect = Rect2(dest_pos, Vector2(FRAME_W, FRAME_H))
			draw_texture_rect(texture_sheet, dest_rect, false)
		else:
			var col = current_frame % COLS
			var row = current_frame / COLS
			var src_rect = Rect2(col * FRAME_W, row * FRAME_H, FRAME_W, FRAME_H)
			
			var dest_rect: Rect2
			if auto_scale_to_fill:
				dest_rect = Rect2(Vector2.ZERO, size)
			else:
				var dest_pos = Vector2((w - FRAME_W) * 0.5, (h - FRAME_H) * 0.5)
				dest_rect = Rect2(dest_pos, Vector2(FRAME_W, FRAME_H))
			
			draw_texture_rect_region(texture_sheet, dest_rect, src_rect)
	
	# Scanlines CRT retro
	for y in range(0, int(h), 3):
		draw_line(Vector2(0, y), Vector2(w, y), Color(0.0, 0.0, 0.0, 0.35), 1.0)
	
	# Borde sutil del monitor
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.08, 0.12, 0.5), false, 1.0)
