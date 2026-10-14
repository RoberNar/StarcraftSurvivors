class_name FaceToFaceDialog
extends Control

## Diálogo Presencial (Hablar de Frente) - Estilo Briefing de StarCraft 1
## Muestra una pantalla táctica Terran en la parte inferior de la base:
## Monitor CRT con chasis metálico (tframe1/tframeh1) para retrato animado a la izquierda,
## y pantalla de texto con marco metálico, ribete de neón naranja (dialog_briefing_frame) a la derecha.

signal dialogue_started(speaker: String, text: String)
signal dialogue_finished

@onready var monitor_control: Control = $HBox/PortraitMonitor
@onready var portrait_control: SCPortrait = $HBox/PortraitMonitor/PortraitControl
@onready var chassis_rect: TextureRect = $HBox/PortraitMonitor/Chassis
@onready var text_frame: TextureRect = $HBox/TextFrame
@onready var header_label: Label = $HBox/TextFrame/ContentVBox/HeaderLabel
@onready var body_label: Label = $HBox/TextFrame/ContentVBox/BodyLabel
@onready var objective_label: Label = $HBox/TextFrame/ContentVBox/ObjectiveLabel
@onready var prompt_label: Label = $HBox/TextFrame/ContentVBox/PromptLabel

var tex_normal: Texture2D = null
var tex_highlight: Texture2D = null

var is_active: bool = false
var queue: Array[Dictionary] = []
var queue_index: int = 0
var current_on_finish: Callable = Callable()
var current_tween: Tween = null

var line_timer: float = 0.0
var auto_advance_duration: float = 0.0
var input_cooldown: float = 0.0

const COLOR_VOSS: Color = Color(1.0, 0.85, 0.25, 1.0)
const COLOR_PLAYER: Color = Color(0.35, 0.9, 1.0, 1.0)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)
	
	tex_normal = load("res://assets/skins/sd/ui/tframe1.png")
	tex_highlight = load("res://assets/skins/sd/ui/tframeh1.png")

func _process(delta: float) -> void:
	if input_cooldown > 0.0:
		input_cooldown -= delta
	
	if is_active and visible and auto_advance_duration > 0.0:
		line_timer += delta
		if line_timer >= auto_advance_duration:
			line_timer = 0.0
			advance_or_close()

func show_dialogue(speaker: String, portrait_tex: Texture2D, message: String, objective: String = "", on_finish: Callable = Callable()) -> void:
	is_active = true
	current_on_finish = on_finish
	queue.clear()
	queue_index = 0
	line_timer = 0.0
	# Para diálogo estático de misión (hablar con Voss), no autoskipear para permitir lectura tranquila
	auto_advance_duration = 0.0
	input_cooldown = 0.35
	
	_render_dialogue_line(speaker, portrait_tex, message, objective)
	_open_window()

func play_dialogue_queue(lines: Array[Dictionary], on_finish: Callable = Callable()) -> void:
	if lines.is_empty():
		if on_finish.is_valid():
			on_finish.call()
		return
	
	is_active = true
	current_on_finish = on_finish
	queue = lines.duplicate()
	queue_index = 0
	line_timer = 0.0
	input_cooldown = 0.35
	
	_advance_queue_line()
	_open_window()

func _advance_queue_line() -> void:
	if queue_index >= queue.size():
		close_dialogue()
		return
	
	var item = queue[queue_index]
	var is_voss = item.get("is_voss", true)
	var speaker = item.get("speaker", "CAPITÁN HOLLIS VOSS" if is_voss else "??????")
	var text = item.get("text", "")
	var obj = item.get("objective", "")
	
	# Tiempo generoso de auto-avance (8 a 12 segundos según longitud) para evitar cualquier autoskip apresurado
	auto_advance_duration = max(8.0, float(text.length()) * 0.08 + 3.0)
	line_timer = 0.0
	input_cooldown = 0.35
	
	var portrait_tex: Texture2D = null
	if is_voss:
		portrait_tex = load("res://assets/skins/sd/portrait/civilian_portrait.png")
	else:
		if GameManager.has_suit_equipped:
			portrait_tex = SkinManager.get_sprite("wire_marine")
		else:
			portrait_tex = SkinManager.get_sprite("wire_civilian")
	
	_render_dialogue_line(speaker, portrait_tex, text, obj)
	queue_index += 1

func _render_dialogue_line(speaker: String, portrait_tex: Texture2D, message: String, objective: String = "") -> void:
	if header_label:
		header_label.text = speaker
		var is_voss = (speaker.find("VOSS") != -1 or speaker.find("HOLLIS") != -1 or speaker.find("COMANDANTE") != -1)
		header_label.add_theme_color_override("font_color", COLOR_VOSS if is_voss else COLOR_PLAYER)
	
	if body_label:
		body_label.text = message
	
	if objective_label:
		if objective != "":
			objective_label.visible = true
			objective_label.text = objective if objective.begins_with("🎯") else ("🎯 " + objective)
		else:
			objective_label.visible = false
	
	# Retrato y animación de habla
	var final_tex = portrait_tex
	if not final_tex:
		final_tex = load("res://assets/skins/sd/portrait/civilian_portrait.png")
	
	if portrait_control and final_tex:
		portrait_control.set_portrait(final_tex)
		portrait_control.trigger_talk(2.2)
	
	# Efecto de resaltado en el marco del monitor
	if chassis_rect:
		chassis_rect.texture = tex_highlight if tex_highlight else tex_normal
		var t = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		t.tween_interval(0.2)
		t.tween_callback(func():
			if chassis_rect and tex_normal:
				chassis_rect.texture = tex_normal
		)
	
	# Sonido sutil de avance de diálogo presencial
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("button", 0.04, -3.0)
	
	emit_signal("dialogue_started", speaker, message)

func _open_window() -> void:
	visible = true
	modulate.a = 0.0
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.tween_property(self, "modulate:a", 1.0, 0.16).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func advance_or_close() -> void:
	if not is_active or not visible:
		return
	if input_cooldown > 0.0:
		return
	
	line_timer = 0.0
	input_cooldown = 0.3
	
	if not queue.is_empty() and queue_index < queue.size():
		_advance_queue_line()
	else:
		close_dialogue()

func close_dialogue() -> void:
	if not is_active and not visible:
		return
	
	is_active = false
	if current_tween and current_tween.is_valid():
		current_tween.kill()
	
	current_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	current_tween.tween_property(self, "modulate:a", 0.0, 0.12).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	current_tween.tween_callback(func():
		visible = false
		emit_signal("dialogue_finished")
		var cb = current_on_finish
		current_on_finish = Callable()
		queue.clear()
		queue_index = 0
		line_timer = 0.0
		input_cooldown = 0.0
		if cb.is_valid():
			cb.call()
	)

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		advance_or_close()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
	if input_cooldown > 0.0:
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_SPACE or event.keycode == KEY_ENTER or event.keycode == KEY_E:
			advance_or_close()
			get_viewport().set_input_as_handled()
	elif event is InputEventMouseButton and event.pressed:
		advance_or_close()
		get_viewport().set_input_as_handled()
