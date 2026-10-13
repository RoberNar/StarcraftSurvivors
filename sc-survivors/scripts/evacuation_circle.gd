class_name EvacuationCircle
extends Area2D

var player_inside: bool = false
@onready var modal: Panel = $CanvasLayer/EvacModal
@onready var title_label: Label = $CanvasLayer/EvacModal/VBox/TitleLabel
@onready var mission_status_label: Label = $CanvasLayer/EvacModal/VBox/MissionStatusLabel
@onready var resources_label: Label = $CanvasLayer/EvacModal/VBox/ResourcesLabel
@onready var prompt_label: Label = $CanvasLayer/EvacModal/VBox/PromptLabel
@onready var confirm_btn: Button = $CanvasLayer/EvacModal/VBox/ButtonsHBox/ConfirmBtn
@onready var cancel_btn: Button = $CanvasLayer/EvacModal/VBox/ButtonsHBox/CancelBtn
@onready var beacon_light: Sprite2D = $BeaconLight
@onready var evac_hint_bubble: Panel = $EvacHintBubble

var pulse_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("evacuation_zone")
	modal.visible = false
	if evac_hint_bubble:
		evac_hint_bubble.visible = false
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)
	confirm_btn.pressed.connect(_on_confirm_pressed)
	cancel_btn.pressed.connect(_on_cancel_pressed)

func _process(delta: float) -> void:
	pulse_timer += delta * 3.0
	if beacon_light:
		beacon_light.modulate.a = 0.6 + sin(pulse_timer) * 0.35

func _unhandled_input(event: InputEvent) -> void:
	if modal.visible:
		if event is InputEventKey and event.pressed and not event.echo:
			if event.keycode == KEY_ESCAPE:
				_on_cancel_pressed()
				get_viewport().set_input_as_handled()
			elif event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.is_action_pressed("ui_accept"):
				_on_confirm_pressed()
				get_viewport().set_input_as_handled()
		return
	
	if player_inside and not get_tree().paused:
		if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_E:
			_show_evac_dialog()
			get_viewport().set_input_as_handled()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = true
		if evac_hint_bubble:
			evac_hint_bubble.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		player_inside = false
		if evac_hint_bubble:
			evac_hint_bubble.visible = false

func _show_evac_dialog() -> void:
	get_tree().paused = true
	var m = GameManager.get_current_mission()
	var state_text = "¡OBJETIVO COMPLETADO! (Listo para cobrar recompensas)" if GameManager.is_mission_completed else "En progreso (%s)" % GameManager.get_mission_progress_str()
	
	mission_status_label.text = "🎯 Misión: %s\nEstado: %s" % [m.get("title", ""), state_text]
	resources_label.text = "Minerales en posesión: %d\nGas Vespeno recolectado: %d" % [GameManager.get_total_minerals(), GameManager.get_total_gas()]
	if prompt_label:
		prompt_label.text = "¿Estás seguro de que deseas salir de la misión y regresar a la base militar?\n(Tus recursos recolectados serán guardados)."
	
	modal.visible = true
	AudioManager.play_sfx("button")

func _on_confirm_pressed() -> void:
	AudioManager.play_sfx("dropship_depart")
	modal.visible = false
	get_tree().paused = false
	GameManager.evacuate_to_base()

func _on_cancel_pressed() -> void:
	AudioManager.play_sfx("button")
	modal.visible = false
	get_tree().paused = false
