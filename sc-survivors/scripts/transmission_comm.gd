class_name TransmissionComm
extends Control

## Componente táctico de comunicación de radio StarCraft
## Muestra una pantalla de cámara con chasis metálico (tframe) a la izquierda
## y el panel de órdenes/objetivos invertido con el brazo mecánico a la derecha.

signal transmission_started(speaker: String, text: String)
signal transmission_finished

@onready var text_frame: TextureRect = $TextFrame
@onready var header_label: Label = $TextFrame/TextContent/VBox/HeaderLabel
@onready var body_label: Label = $TextFrame/TextContent/VBox/BodyLabel
@onready var portrait_monitor: Control = $PortraitMonitor
@onready var portrait_control: SCPortrait = $PortraitMonitor/PortraitControl
@onready var chassis_rect: TextureRect = $PortraitMonitor/Chassis

var current_tween: Tween = null
var queue: Array[Dictionary] = []
var on_finished_callback: Callable = Callable()
var current_on_finish: Callable = Callable()
var is_active: bool = false

func get_pos_offscreen_x() -> float:
	return get_viewport_rect().size.x + 20.0

func get_pos_onscreen_x() -> float:
	return get_viewport_rect().size.x - 272.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	position.x = get_pos_offscreen_x()
	mouse_filter = Control.MOUSE_FILTER_STOP
	gui_input.connect(_on_gui_input)

func show_transmission(speaker: String, portrait_tex: Texture2D, message: String, duration: float = 4.5, on_finish: Callable = Callable(), voice_id: String = "") -> void:
	if has_node("/root/AudioManager"):
		AudioManager.stop_voice()
	
	is_active = true
	current_on_finish = on_finish
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if header_label:
		header_label.text = speaker
	if body_label:
		body_label.text = message
	
	# Reproducir voz si existe
	var voice_dur = 0.0
	if voice_id != "" and has_node("/root/AudioManager"):
		voice_dur = AudioManager.play_voice(voice_id)
		if voice_dur > 0.0:
			duration = max(duration, voice_dur + 0.8)
	
	# Si no se proporciona textura de retrato, usar el Capitán Hollis Voss por defecto
	var final_tex = portrait_tex
	if not final_tex:
		final_tex = load("res://assets/skins/sd/portrait/civilian_portrait.png")
	
	if portrait_control and final_tex:
		portrait_control.set_portrait(final_tex)
		portrait_control.trigger_talk(voice_dur if voice_dur > 0.0 else duration)
	
	# Sonido auténtico de radio/transmisión de StarCraft
	if has_node("/root/AudioManager"):
		AudioManager.play_sfx("transmission")
	
	visible = true
	
	var pos_off = get_pos_offscreen_x()
	var pos_on = get_pos_onscreen_x()
	var already_onscreen = (position.x <= pos_on + 20.0 and position.x >= pos_on - 20.0)
	
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	
	current_tween = create_tween().set_parallel(false).set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	if not already_onscreen:
		position.x = pos_off
		current_tween.tween_property(self, "position:x", pos_on, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	else:
		position.x = pos_on
		
	current_tween.tween_interval(duration)
	current_tween.tween_property(self, "position:x", pos_off, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	current_tween.tween_callback(func():
		if has_node("/root/AudioManager"):
			AudioManager.stop_voice()
		visible = false
		is_active = false
		emit_signal("transmission_finished")
		var cb = current_on_finish
		current_on_finish = Callable()
		if cb.is_valid():
			cb.call()
	)
	
	emit_signal("transmission_started", speaker, message)

func play_sequence(lines: Array, on_finished: Callable = Callable()) -> void:
	if current_tween and current_tween.is_valid():
		current_tween.kill()
		current_tween = null
	queue = lines.duplicate()
	on_finished_callback = on_finished
	_play_next_in_queue()

func _play_next_in_queue() -> void:
	if queue.is_empty():
		var cb = on_finished_callback
		on_finished_callback = Callable()
		if cb.is_valid():
			cb.call()
		return
	
	var item = queue.pop_front()
	var spk: String = item.get("speaker", "")
	var tex: Texture2D = item.get("portrait", null)
	if spk == "":
		if item.get("is_voss", false):
			spk = "CAPITÁN HOLLIS VOSS"
			if tex == null:
				tex = load("res://assets/skins/sd/portrait/civilian_portrait.png")
		else:
			spk = "??????"
			if tex == null:
				var wf_hero = "wire_medic" if GameManager.selected_hero == "medic" else "wire_marine"
				tex = SkinManager.get_sprite(wf_hero) if (has_node("/root/GameManager") and GameManager.has_suit_equipped) else SkinManager.get_sprite("wire_civilian")
	
	var msg = item.get("message", item.get("text", ""))
	var dur = item.get("duration", 5.0)
	var v_id = item.get("voice_id", "")
	show_transmission(spk, tex, msg, dur, Callable(self, "_play_next_in_queue"), v_id)

func skip_transmission() -> void:
	if has_node("/root/AudioManager"):
		AudioManager.stop_voice()
	
	if is_active:
		if current_tween and current_tween.is_valid():
			current_tween.kill()
			current_tween = null
		is_active = false
		var cb = current_on_finish
		current_on_finish = Callable()
		if not queue.is_empty():
			_play_next_in_queue()
		elif cb.is_valid():
			cb.call()
		else:
			visible = false
			var old_cb = on_finished_callback
			on_finished_callback = Callable()
			if old_cb.is_valid():
				old_cb.call()

func _on_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		skip_transmission()
		accept_event()

func _unhandled_input(event: InputEvent) -> void:
	if not is_active or not visible:
		return
	if event is InputEventKey and event.pressed and not event.echo:
		# Excluir KEY_SPACE para permitir uso libre de Stimpack en combate sin cortar voces
		if event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER:
			skip_transmission()
			get_viewport().set_input_as_handled()
