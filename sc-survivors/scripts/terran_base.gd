class_name TerranBase
extends Node2D

@onready var player_spawn: Marker2D = $PlayerSpawn
@onready var top_bar_minerals: Label = $CanvasLayer/TopBar/HBox/MineralHBox/MineralsLabel
@onready var top_bar_gas: Label = $CanvasLayer/TopBar/HBox/GasHBox/GasLabel

# HUD inferior y consola de StarCraft
@onready var console_rect: TextureRect = $CanvasLayer/ConsoleRect
@onready var bottom_portrait: SCPortrait = $CanvasLayer/ConsoleRect/PortraitControl
@onready var bottom_name_label: Label = $CanvasLayer/ConsoleRect/UnitInfo/UnitNameLabel
@onready var bottom_rank_label: Label = $CanvasLayer/ConsoleRect/UnitInfo/RankLabel
@onready var bottom_weapon_label: Label = $CanvasLayer/ConsoleRect/UnitInfo/WeaponLabel
@onready var bottom_armor_label: Label = $CanvasLayer/ConsoleRect/UnitInfo/ArmorLabel
@onready var bottom_hp_bar: Control = $CanvasLayer/ConsoleRect/SCHealthBar
@onready var bottom_hp_label: Label = $CanvasLayer/ConsoleRect/HpLabel
@onready var bottom_wireframe: TextureRect = $CanvasLayer/ConsoleRect/WireframeRect

# Soporte de Armadura Marine CMC-300
@onready var armor_stand: Node2D = $ArmorStand
@onready var armor_stand_sprite: Sprite2D = $ArmorStand/Sprite2D
@onready var armor_stand_shadow: Sprite2D = $ArmorStand/Shadow
@onready var armor_stand_hint: Label = $ArmorStand/HintLabel
@onready var armor_stand_area: Area2D = $ArmorStand/Area2D

# Comunicador Táctico de Radio Terran (Briefing Transmission Comm - Transmisiones de Radio)
@onready var transmission_comm: TransmissionComm = $CanvasLayer/TransmissionComm
# Diálogo Presencial Terran (Briefing Face-to-Face - Para hablar de frente en la base)
@onready var face_to_face_dialog: FaceToFaceDialog = $CanvasLayer/FaceToFaceDialog

# Menú de Pausa / Configuración
@onready var pause_panel: Panel = $CanvasLayer/PausePanel
@onready var pause_music_slider: HSlider = $CanvasLayer/PausePanel/VBox/MusicSlider
@onready var pause_music_lbl: Label = $CanvasLayer/PausePanel/VBox/MusicLabel
@onready var pause_sfx_slider: HSlider = $CanvasLayer/PausePanel/VBox/SfxSlider
@onready var pause_sfx_lbl: Label = $CanvasLayer/PausePanel/VBox/SfxLabel
@onready var pause_voice_slider: HSlider = $CanvasLayer/PausePanel/VBox/VoiceSlider
@onready var pause_voice_lbl: Label = $CanvasLayer/PausePanel/VBox/VoiceLabel
@onready var pause_fullscreen_check: CheckButton = $CanvasLayer/PausePanel/VBox/FullscreenCheck
@onready var pause_resume_btn: Button = $CanvasLayer/PausePanel/VBox/ResumeBtn
@onready var pause_quit_btn: Button = $CanvasLayer/PausePanel/VBox/QuitBtn

var story_dialogue_queue: Array[Dictionary] = []
var story_dialogue_index: int = 0
var story_dialogue_timer: float = 0.0
var is_playing_story_dialogue: bool = false
var story_dialogue_finished_callback: Callable

const ARRIVAL_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Soy el Capitán Hollis Voss, oficial al mando de este puesto de avanzada.",
		"is_voss": true,
		"voice_id": "VOSS_00"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Bienvenido a la base. Bueno, a lo que queda de ella.",
		"is_voss": true,
		"voice_id": "VOSS_03"
	},
	{
		"speaker": "??????",
		"text": "...Gracias. Me salvaste la vida Ahí abajo.",
		"is_voss": false,
		"voice_id": "PROTAG_06"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Así es. Y costó caro: consumí casi todo el combustible que me quedaba para llegar a tiempo. A esa nave le quedan pocos viajes de transporte.",
		"is_voss": true,
		"voice_id": "VOSS_04"
	},
	{
		"speaker": "??????",
		"text": "¿Dónde estamos exactamente? ¿Qué es este lugar?",
		"is_voss": false,
		"voice_id": "PROTAG_07"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Un puesto de avanzada en ruinas. No es un sitio seguro para civiles.",
		"is_voss": true,
		"voice_id": "VOSS_05"
	},
	{
		"speaker": "??????",
		"text": "¿Y esos zerg? ¿De dónde llegaron?",
		"is_voss": false,
		"voice_id": "PROTAG_08"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "De todas direcciones. Si queremos seguir con vida, necesitaremos suministros urgentes. Minerales, para comenzar.",
		"is_voss": true,
		"voice_id": "VOSS_06"
	},
	{
		"speaker": "??????",
		"text": "Comprendo... ¿cuál es el plan?",
		"is_voss": false,
		"voice_id": "PROTAG_09"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "El plan es sencillo: tengo una armadura de combate CMC en el soporte. Te la equipas, desciendes en la nave y extraes minerales.",
		"is_voss": true,
		"voice_id": "VOSS_07"
	},
	{
		"speaker": "??????",
		"text": "¿Por qué no vas tú mismo?",
		"is_voss": false,
		"voice_id": "PROTAG_10"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Porque alguien debe coordinar las defensas de la base. Y además, así saldas tu deuda conmigo.",
		"is_voss": true,
		"voice_id": "VOSS_08"
	},
	{
		"speaker": "??????",
		"text": "...De acuerdo, es razonable. Aunque no poseo entrenamiento militar ni sé maniobrar con esa tecnología.",
		"is_voss": false,
		"voice_id": "PROTAG_11"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Descuida. La computadora de tiro de la armadura se encargará del cálculo balístico. Una vez en el terreno lo entenderás. Reúne 20 minerales en el exterior. La nave está lista para el despegue.",
		"is_voss": true,
		"voice_id": "VOSS_09"
	},
	{
		"speaker": "??????",
		"text": "Espero que tengas razón.",
		"is_voss": false,
		"voice_id": "PROTAG_12"
	}
]

# Condición 1: Mueres sin completar los 20 minerales
const FIRST_DEATH_NO_MINERALS_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "??????",
		"text": "Espera... ¿no estaba muerto? Juraría que sentí cómo esas bestias me destrozaban en el páramo...",
		"is_voss": false,
		"voice_id": "PROTAG_15"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Tranquilo, muchacho. Estás entero y de una sola pieza aquí en la base. La cápsula médica de emergencia te sacó de ahí antes de que fuera tarde... Pero todavía no tenemos los recursos necesarios. Ahora ponte de pie, vuelve allá afuera y recupera esos minerales. Necesitamos 20 para reconstruir la base.",
		"is_voss": true,
		"voice_id": "VOSS_19"
	},
	{
		"speaker": "??????",
		"text": "Entendido, VOSS. Volveré al páramo por ellos.",
		"is_voss": false,
		"voice_id": "PROTAG_17"
	}
]

# Condición 2: Mueres con los 20 minerales
const FIRST_DEATH_WITH_MINERALS_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "??????",
		"text": "Espera... ¿no estaba muerto? Juraría que sentí cómo esas bestias me destrozaban en el páramo...",
		"is_voss": false,
		"voice_id": "PROTAG_15"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Tranquilo, muchacho. Estás entero y de una sola pieza aquí en la base. La cápsula médica de emergencia te sacó de ahí antes de que fuera tarde... y afortunadamente tu armadura retuvo los minerales. Conseguiste los 20 minerales requeridos. Ahora acércate al Centro de Mando y levanta el Cuartel y la Bahía de Ingeniería.",
		"is_voss": true,
		"voice_id": "VOSS_18"
	},
	{
		"speaker": "??????",
		"text": "Entendido, VOSS . Comenzaré la construcción.",
		"is_voss": false,
		"voice_id": "PROTAG_20"
	}
]

# Condición 3: Te vas sin morir (completas la misión con vida)
const MISSION_1_COMPLETED_ALIVE_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "??????",
		"text": "Objetivo cumplido, VOSS. Traje los 20 minerales que me pediste.",
		"is_voss": false,
		"voice_id": "PROTAG_19"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "¡Excelente trabajo! Trajiste los recursos que te pedí. Ahora acércate al Centro de Mando y levanta el Cuartel y la Bahía de Ingeniería.",
		"is_voss": true,
		"voice_id": "VOSS_17"
	},
	{
		"speaker": "??????",
		"text": "Entendido, VOSS . Comenzaré la construcción.",
		"is_voss": false,
		"voice_id": "PROTAG_20"
	}
]

# Diálogo de primera muerte si ocurre más adelante (Misión 2+)
const FIRST_DEATH_LATER_DIALOGUE: Array[Dictionary] = [
	{
		"speaker": "??????",
		"text": "Espera... ¿no estaba muerto? Juraría que sentí cómo esas bestias me destrozaban en el páramo...",
		"is_voss": false,
		"voice_id": "PROTAG_15"
	},
	{
		"speaker": "CAPITÁN HOLLIS VOSS",
		"text": "Tranquilo, muchacho. Estás entero y de una sola pieza aquí en la base. La cápsula médica de emergencia te sacó de ahí antes de que fuera tarde... Los enemigos ahí abajo son implacables. Reabastécete en el Cuartel y la Bahía de Ingeniería antes de tu próximo despliegue.",
		"is_voss": true,
		"voice_id": "VOSS_20"
	},
	{
		"speaker": "??????",
		"text": "Entendido, VOSS. Tendré mucho más cuidado allá afuera.",
		"is_voss": false,
		"voice_id": "PROTAG_18"
	}
]

# Centro de Mando Terran (Terminal de Construcción)
@onready var cmd_center: StaticBody2D = $CommandCenter
@onready var cmd_center_area: Area2D = $CommandCenter/Area2D
@onready var cmd_center_hint: Label = $CommandCenter/HintLabel
@onready var cmd_center_panel: Panel = $CanvasLayer/CommandCenterPanel
@onready var cmd_center_close_btn: Button = $CanvasLayer/CommandCenterPanel/VBox/CloseBtn
@onready var cmd_center_container: VBoxContainer = $CanvasLayer/CommandCenterPanel/VBox/Scroll/BuildingsContainer

# Modales de interacción
@onready var academy_modal: Panel = $CanvasLayer/AcademyPanel
@onready var academy_list: GridContainer = $CanvasLayer/AcademyPanel/VBox/Scroll/UpgradesContainer
@onready var academy_close_btn: Button = $CanvasLayer/AcademyPanel/VBox/CloseBtn
@onready var academy_sprite: Sprite2D = $Academy/Sprite2D
@onready var academy_hint: Label = $Academy/HintLabel

@onready var mission_modal: Panel = $NPC/MissionBubble
@onready var mission_title_lbl: Label = $NPC/MissionBubble/VBox/TitleLabel
@onready var mission_dialog_lbl: Label = $NPC/MissionBubble/VBox/DialogLabel
@onready var mission_req_lbl: Label = $NPC/MissionBubble/VBox/ReqLabel
@onready var mission_reward_lbl: Label = $NPC/MissionBubble/VBox/RewardLabel
@onready var mission_action_btn: Button = $NPC/MissionBubble/VBox/Buttons/ActionBtn
@onready var mission_close_btn: Button = $NPC/MissionBubble/VBox/Buttons/CloseBtn

@onready var deploy_modal: Panel = $Starport/DeployBubble
@onready var deploy_mission_lbl: Label = $Starport/DeployBubble/VBox/MissionLabel
@onready var deploy_confirm_btn: Button = $Starport/DeployBubble/VBox/Buttons/DeployBtn
@onready var deploy_cancel_btn: Button = $Starport/DeployBubble/VBox/Buttons/CancelBtn

# Indicadores de proximidad
@onready var barracks_hint: Label = $Barracks/HintLabel
@onready var starport_hint: Label = $Starport/HintLabel
@onready var npc_hint: Label = $NPC/HintLabel
@onready var npc_badge: Label = $NPC/BadgeLabel

var active_zone: String = ""
var pulse_time: float = 0.0
var player_node: CharacterBody2D = null

func _ready() -> void:
	# Cursor del juego
	var cursor_tex = SkinManager.get_ui("cursor")
	if cursor_tex:
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2.ZERO)
	
	# Asegurar que no quede ningún enemigo residual
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy):
			enemy.queue_free()
	
	# Colisiones exactas de muros (generadas desde la caminabilidad real de StarCraft)
	_build_wall_collisions()
	
	# Huellas isométricas (rombo) de los edificios en Layer 1
	_set_footprint($Barracks, 124, 62, 14)
	_set_footprint($Academy, 110, 56, 12)
	_set_footprint($Starport, 104, 52, 14)
	_set_footprint($Depot1, 88, 44, 8)
	_set_footprint($Depot2, 88, 44, 8)
	_set_footprint($Geyser, 108, 48, 6)
	
	# Música militar de la base Terran
	AudioManager.play_music("terran1", true, true)
	
	# Instanciar jugador en la base como CIVIL
	var p_scene = load("res://scenes/civilian_player.tscn")
	if p_scene:
		player_node = p_scene.instantiate()
		player_node.move_speed = 185.0
		player_node.global_position = player_spawn.global_position
		add_child(player_node)
		
		# Cámara del civil con límites del mapa completo (1920x1152)
		var cam = player_node.get_node_or_null("Camera2D")
		if cam:
			cam.limit_left = 0
			cam.limit_top = 0
			cam.limit_right = 1920
			cam.limit_bottom = 1152
	
	# Ocultar paneles y pistas iniciales
	academy_modal.visible = false
	cmd_center_panel.visible = false
	pause_panel.visible = false
	mission_modal.visible = false
	deploy_modal.visible = false
	barracks_hint.visible = false
	academy_hint.visible = false
	starport_hint.visible = false
	npc_hint.visible = false
	cmd_center_hint.visible = false
	if transmission_comm:
		transmission_comm.visible = false
	
	_connect_signals()
	if has_node("/root/GameManager"):
		GameManager.sync_barracks_upgrades()
	_update_top_bar()
	_refresh_base_buildings()
	_populate_academy_upgrades()
	_update_armor_stand_state()
	
	# Si ya tiene la armadura equipada, asegurar que no vuelva a reproducir el diálogo inicial
	if GameManager.has_suit_equipped and SaveManager.get_story_stage() == "base_initial":
		SaveManager.set_story_stage("mission_1")

	# Prioridad 1: Muerte por primera vez (SaveManager.first_death_dialogue_pending)
	if SaveManager.first_death_dialogue_pending:
		SaveManager.first_death_dialogue_pending = false
		SaveManager.has_experienced_first_death = true
		SaveManager.has_seen_first_death_cinematic = true
		SaveManager.save_data()
		
		var stage = SaveManager.get_story_stage()
		var has_20_min = (GameManager.session_minerals >= 20 or GameManager.is_mission_completed)
		
		# Si la muerte ocurrió en Misión 1 (o antes de tener Cuartel y Bahía de Ingeniería)
		if stage == StoryManager.STAGE_MISSION_1 or stage == StoryManager.STAGE_BASE_INITIAL:
			if has_20_min:
				# Condición 2: Mueres con los 20 minerales -> se sorprende y te manda a construir
				_start_story_dialogue(FIRST_DEATH_WITH_MINERALS_DIALOGUE, func():
					GameManager.claim_mission_reward()
					SaveManager.set_story_stage(StoryManager.STAGE_BASE_BUILDING)
					_refresh_base_buildings()
					_update_top_bar()
				)
			else:
				# Condición 1: Mueres sin completar los 20 minerales -> se sorprende y te manda a recuperarlos
				_start_story_dialogue(FIRST_DEATH_NO_MINERALS_DIALOGUE, func():
					GameManager.is_mission_completed = false
					_update_top_bar()
				)
		else:
			# Condición 3 (muerte posterior): Primera muerte ocurrida en Misión 2 o más adelante
			_start_story_dialogue(FIRST_DEATH_LATER_DIALOGUE, func():
				_update_top_bar()
			)

	# Prioridad 2: Regreso vivo sin morir (Condición 3)
	elif GameManager.is_mission_completed or (SaveManager.get_story_stage() == StoryManager.STAGE_MISSION_1 and GameManager.session_minerals >= 20):
		var stage = SaveManager.get_story_stage()
		if stage == StoryManager.STAGE_MISSION_1 or stage == StoryManager.STAGE_BASE_INITIAL:
			# Condición 3: Regreso vivo con 20 minerales -> diálogo de misión cumplida, te manda a construir
			_start_story_dialogue(MISSION_1_COMPLETED_ALIVE_DIALOGUE, func():
				GameManager.claim_mission_reward()
				SaveManager.set_story_stage(StoryManager.STAGE_BASE_BUILDING)
				_refresh_base_buildings()
				_update_top_bar()
			)
		else:
			# Misión 2 o posterior completada viva
			var cur_m = GameManager.get_current_mission()
			var compl_text = cur_m.get("complete_dialog", "¡Excelente barrido táctico! El perímetro exterior está asegurado.")
			var compl_queue: Array[Dictionary] = [
				{
					"speaker": "CAPITÁN HOLLIS VOSS",
					"text": compl_text,
					"is_voss": true,
					"voice_id": "VOSS_21"
				},
				{
					"speaker": "??????",
					"text": "Objetivo cumplido, VOSS. Traje los recursos del terreno a la base.",
					"is_voss": false,
					"voice_id": "PROTAG_21"
				},
				{
					"speaker": "CAPITÁN HOLLIS VOSS",
					"text": "Bien hecho. Usa los recursos que recolectaste para prepararte. Te asignaré el siguiente vector de despliegue.",
					"is_voss": true,
					"voice_id": "VOSS_27"
				}
			]
			_start_story_dialogue(compl_queue, func():
				GameManager.claim_mission_reward()
				_update_top_bar()
			)

	# Prioridad 3: Diálogo inicial al llegar a la base
	elif SaveManager.get_story_stage() == StoryManager.STAGE_BASE_INITIAL:
		_start_story_dialogue(ARRIVAL_DIALOGUE, func():
			SaveManager.set_story_stage(StoryManager.STAGE_MISSION_1)
		)

	else:
		console_rect.visible = true

func _start_story_dialogue(queue: Array[Dictionary], on_finished: Callable = Callable()) -> void:
	_close_all_modals()
	story_dialogue_finished_callback = on_finished
	is_playing_story_dialogue = true
	console_rect.visible = true
	if player_node:
		player_node.can_move = false
	
	if face_to_face_dialog:
		face_to_face_dialog.play_dialogue_queue(queue, func():
			_finish_story_dialogue()
		)
	else:
		_finish_story_dialogue()

func _advance_story_dialogue() -> void:
	if face_to_face_dialog and face_to_face_dialog.is_active:
		face_to_face_dialog.advance_or_close()

func _finish_story_dialogue() -> void:
	is_playing_story_dialogue = false
	if face_to_face_dialog and face_to_face_dialog.is_active:
		face_to_face_dialog.close_dialogue()
	if player_node:
		player_node.can_move = true
	console_rect.visible = true
	AudioManager.play_sfx("button")
	if story_dialogue_finished_callback.is_valid():
		story_dialogue_finished_callback.call()

func _build_wall_collisions() -> void:
	var f = FileAccess.open("res://assets/skins/sd/tiles/terran_base_collision.json", FileAccess.READ)
	if f == null:
		push_warning("No se encontró terran_base_collision.json")
		return
	var parsed = JSON.parse_string(f.get_as_text())
	if typeof(parsed) != TYPE_DICTIONARY:
		return
	var walls := StaticBody2D.new()
	walls.name = "Walls"
	walls.collision_layer = 1
	walls.collision_mask = 0
	add_child(walls)
	for r in parsed.get("rects", []):
		var shape := RectangleShape2D.new()
		shape.size = Vector2(r[2], r[3])
		var cs := CollisionShape2D.new()
		cs.shape = shape
		cs.position = Vector2(r[0] + r[2] * 0.5, r[1] + r[3] * 0.5)
		walls.add_child(cs)

func _set_footprint(body: Node2D, w: float, h: float, offset_y: float) -> void:
	if body == null:
		return
	if body is CollisionObject2D:
		body.collision_layer = 1
		body.collision_mask = 0
	for c in body.get_children():
		if c is CollisionShape2D or c is CollisionPolygon2D:
			c.queue_free()
	var poly := CollisionPolygon2D.new()
	poly.polygon = PackedVector2Array([
		Vector2(0, offset_y - h * 0.5),
		Vector2(w * 0.5, offset_y),
		Vector2(0, offset_y + h * 0.5),
		Vector2(-w * 0.5, offset_y),
	])
	body.add_child(poly)

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	if npc_badge:
		npc_badge.modulate.a = 0.7 + sin(pulse_time) * 0.3

func _unhandled_input(event: InputEvent) -> void:
	if is_playing_story_dialogue or (face_to_face_dialog != null and face_to_face_dialog.is_active):
		return
	
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			if _is_any_modal_open():
				_close_all_modals()
			elif pause_panel and pause_panel.visible:
				_close_pause_menu()
			else:
				_open_pause_menu()
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_E or event.keycode == KEY_SPACE) and not _is_any_modal_open() and not (pause_panel and pause_panel.visible):
			_trigger_active_zone()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N or event.keycode == KEY_M or event.keycode == KEY_F9:
			# Debug rápido M / N / F9 para saltar directo a la batalla del jefe
			get_tree().change_scene_to_file("res://scenes/boss_cave_arena.tscn")
			get_viewport().set_input_as_handled()
		elif (event.keycode == KEY_ENTER or event.keycode == KEY_SPACE or event.is_action_pressed("ui_accept")) and _is_any_modal_open():
			if deploy_modal.visible:
				deploy_confirm_btn.emit_signal("pressed")
			elif mission_modal.visible:
				mission_action_btn.emit_signal("pressed")

func _is_any_modal_open() -> bool:
	return academy_modal.visible or cmd_center_panel.visible or mission_modal.visible or deploy_modal.visible or is_playing_story_dialogue or (face_to_face_dialog != null and face_to_face_dialog.is_active)

func _close_all_modals() -> void:
	if face_to_face_dialog and face_to_face_dialog.is_active:
		face_to_face_dialog.close_dialogue()
	academy_modal.visible = false
	cmd_center_panel.visible = false
	mission_modal.visible = false
	deploy_modal.visible = false
	AudioManager.play_sfx("button")

func _open_pause_menu() -> void:
	AudioManager.play_sfx("button")
	pause_panel.visible = true
	pause_music_slider.value = AudioManager.music_volume
	pause_sfx_slider.value = AudioManager.sfx_volume
	pause_music_lbl.text = "Volumen Música: %d%%" % int(AudioManager.music_volume * 100)
	pause_sfx_lbl.text = "Volumen Efectos: %d%%" % int(AudioManager.sfx_volume * 100)
	if pause_voice_slider:
		pause_voice_slider.value = AudioManager.voice_volume
	if pause_voice_lbl:
		pause_voice_lbl.text = "Volumen Voces: %d%%" % int(AudioManager.voice_volume * 100)
	pause_fullscreen_check.button_pressed = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)

func _close_pause_menu() -> void:
	AudioManager.play_sfx("button")
	pause_panel.visible = false

func _refresh_base_buildings() -> void:
	var barracks_built = StoryManager.is_barracks_built()
	var barracks_node = $Barracks
	var barracks_sprite = $Barracks/Sprite2D
	if barracks_sprite:
		if barracks_built:
			barracks_sprite.visible = true
			barracks_sprite.modulate = Color(1, 1, 1, 1)
			barracks_sprite.position = Vector2.ZERO
			barracks_hint.text = "[E] CUARTEL: RECLUTAMIENTO"
			barracks_node.collision_layer = 1
			$Barracks/Area2D.monitoring = true
		else:
			barracks_sprite.visible = false
			barracks_hint.text = ""
			barracks_hint.visible = false
			barracks_node.collision_layer = 0
			$Barracks/Area2D.monitoring = false
	
	var ebay_built = StoryManager.is_engineering_bay_built()
	var ebay_node = $Academy
	if academy_sprite:
		if ebay_built:
			academy_sprite.visible = true
			academy_sprite.modulate = Color(1, 1, 1, 1)
			academy_sprite.position = Vector2.ZERO
			academy_sprite.frame = 0
			academy_hint.text = "[E] BAHÍA DE INGENIERÍA: MEJORAS"
			ebay_node.collision_layer = 1
			$Academy/Area2D.monitoring = true
		else:
			academy_sprite.visible = false
			academy_hint.text = ""
			academy_hint.visible = false
			ebay_node.collision_layer = 0
			$Academy/Area2D.monitoring = false

func _play_building_landing_cinematic(building_node: Node2D, bldg_name: String, on_done: Callable) -> void:
	_close_all_modals()
	if player_node:
		player_node.can_move = false
		player_node.velocity = Vector2.ZERO
	
	var cam: Camera2D = null
	if player_node:
		cam = player_node.get_node_or_null("Camera2D")
	
	var sprite: Sprite2D = building_node.get_node_or_null("Sprite2D")
	if not sprite:
		if on_done.is_valid(): on_done.call()
		return
	
	sprite.visible = true
	sprite.modulate = Color(1, 1, 1, 1)
	if building_node.name == "Academy":
		sprite.frame = 1
	sprite.position = Vector2(0, -180)
	
	if cam:
		var target_offset = building_node.global_position - player_node.global_position
		var tw_cam = create_tween().set_parallel(true)
		tw_cam.tween_property(cam, "position", target_offset, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		tw_cam.tween_property(cam, "zoom", Vector2(0.72, 0.72), 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	var tw_land = create_tween()
	tw_land.tween_interval(0.8)
	tw_land.tween_property(sprite, "position", Vector2(0, 0), 1.8).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw_land.tween_callback(func():
		AudioManager.play_sfx("building_land", 0.0, 4.0)
		if building_node.name == "Academy":
			sprite.frame = 0
		
		if cam:
			var shake_tw = create_tween()
			for s in [Vector2(5, -4), Vector2(-5, 4), Vector2(3, -2), Vector2(-2, 2), Vector2.ZERO]:
				shake_tw.tween_property(cam, "offset", s, 0.05)
		
		if player_node and player_node.has_method("show_bubble"):
			player_node.show_bubble("¡%s aterrizado y colocado con éxito!" % bldg_name, 2.5)
	)
	
	tw_land.tween_interval(1.4)
	
	tw_land.tween_callback(func():
		var return_tw = create_tween().set_parallel(true)
		if cam:
			return_tw.tween_property(cam, "position", Vector2.ZERO, 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
			return_tw.tween_property(cam, "zoom", Vector2(1.0, 1.0), 1.0).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
		return_tw.chain().tween_callback(func():
			if player_node:
				player_node.can_move = true
			if on_done.is_valid():
				on_done.call()
		)
	)

func _check_both_buildings_dialogue() -> void:
	if StoryManager.is_barracks_built() and StoryManager.is_engineering_bay_built():
		var post_build_dialogue: Array[Dictionary] = [
			{
				"speaker": "CAPITÁN HOLLIS VOSS",
				"text": "¡Excelente trabajo! El Cuartel y la Bahía de Ingeniería están anclados y listos.",
				"is_voss": true
			},
			{
				"speaker": "CAPITÁN HOLLIS VOSS",
				"text": "Ahora escucha con atención: tienes que ir a matar a un objetivo grande para limpiar los páramos. Los sismógrafos detectan actividad zerg colosal bajo tierra.",
				"is_voss": true
			},
			{
				"speaker": "??????",
				"text": "¿Un objetivo grande? ¿Qué tipo de criatura es?",
				"is_voss": false
			},
			{
				"speaker": "CAPITÁN HOLLIS VOSS",
				"text": "Lo sabrás cuando lo veas. Resiste 30 minutos ahí fuera limpiando la superficie... y te deseo mucha suerte, soldado.",
				"is_voss": true
			}
		]
		_start_story_dialogue(post_build_dialogue, func():
			console_rect.visible = true
		)

func _trigger_active_zone() -> void:
	if is_playing_story_dialogue:
		return
	match active_zone:
		"cmd_center":
			_open_cmd_center()
		"armor":
			_toggle_armor_suit()
		"barracks":
			if StoryManager.is_barracks_built():
				_open_barracks_select()
		"academy":
			if StoryManager.is_engineering_bay_built():
				_open_academy()
		"starport":
			_open_deploy()
		"npc":
			_open_mission()

func _open_cmd_center() -> void:
	AudioManager.play_sfx("button")
	_populate_cmd_center_buildings()
	cmd_center_panel.visible = true

func _populate_cmd_center_buildings() -> void:
	for child in cmd_center_container.get_children():
		child.queue_free()
	
	# 1. Bahía de Ingeniería Terran (10 minerales)
	var ebay_built = StoryManager.is_engineering_bay_built()
	var ebay_card = _create_building_card(
		"BAHÍA DE INGENIERÍA",
		"Instalación de tecnología balística y militar. Permite investigar mejoras permanentes con Gas Vespeno.",
		0,
		ebay_built,
		true,
		func():
			if StoryManager.build_engineering_bay():
				cmd_center_panel.visible = false
				_play_building_landing_cinematic($Academy, "Bahía de Ingeniería", func():
					_refresh_base_buildings()
					_update_top_bar()
					_check_both_buildings_dialogue()
				)
	)
	cmd_center_container.add_child(ebay_card)
	
	# 2. Cuartel Terran
	var b_built = StoryManager.is_barracks_built()
	var b_card = _create_building_card(
		"CUARTEL TERRAN",
		"Instalación de reclutamiento táctico. Habilita la selección de unidades de combate militar.",
		0,
		b_built,
		true,
		func():
			if StoryManager.build_barracks():
				cmd_center_panel.visible = false
				_play_building_landing_cinematic($Barracks, "Cuartel", func():
					_refresh_base_buildings()
					_update_top_bar()
					_check_both_buildings_dialogue()
				)
	)
	cmd_center_container.add_child(b_card)


func _create_building_card(b_name: String, b_desc: String, cost: int, is_built: bool, is_unlocked: bool, on_buy: Callable) -> PanelContainer:
	var panel = PanelContainer.new()
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.06, 0.10, 0.16, 0.92)
	sb.border_color = Color(0.2, 0.45, 0.75, 0.8)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", sb)
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 10)
	
	var vbox = VBoxContainer.new()
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.add_theme_constant_override("separation", 2)
	
	var title_lbl = Label.new()
	title_lbl.text = ("%s [AUTORIZADO]" % b_name) if cost == 0 else ("%s [%d GAS]" % [b_name, cost])
	title_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0) if not is_built else Color(0.3, 1.0, 0.4, 1.0))
	title_lbl.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title_lbl)
	
	var desc_lbl = Label.new()
	desc_lbl.text = b_desc
	desc_lbl.add_theme_color_override("font_color", Color(0.8, 0.85, 0.9, 0.9))
	desc_lbl.add_theme_font_size_override("font_size", 9)
	desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_lbl)
	
	hbox.add_child(vbox)
	
	var btn = Button.new()
	btn.custom_minimum_size = Vector2(120, 28)
	btn.add_theme_font_size_override("font_size", 10)
	
	if is_built:
		btn.text = "OPERATIVO"
		btn.disabled = true
	elif not is_unlocked:
		btn.text = "BLOQUEADO"
		btn.disabled = true
	else:
		var can_afford = (cost == 0 or SaveManager.total_gas >= cost)
		btn.text = "AUTORIZAR" if cost == 0 else ("CONSTRUIR" if can_afford else "FALTAN %d GAS" % (cost - SaveManager.total_gas))
		btn.disabled = not can_afford
		if can_afford:
			btn.add_theme_color_override("font_color", Color(0.25, 1.0, 0.35, 1.0))
			btn.pressed.connect(on_buy)
	
	hbox.add_child(btn)
	panel.add_child(hbox)
	return panel

func _open_barracks_select() -> void:
	AudioManager.play_sfx("button")
	ScreenFade.fade_out_in(0.35, 0.1, 0.35, func():
		get_tree().change_scene_to_file("res://scenes/character_select.tscn")
	)

func _open_academy() -> void:
	AudioManager.play_sfx("button")
	if has_node("/root/GameManager"):
		GameManager.sync_barracks_upgrades()
	_populate_academy_upgrades()
	academy_modal.visible = true

func _try_build_academy() -> void:
	if StoryManager.build_academy():
		AudioManager.play_sfx("upgrade")
		_refresh_base_buildings()
		_update_top_bar()
		if player_node and player_node.has_method("show_bubble"):
			player_node.show_bubble("¡Academia construida! Mejoras permanentes desbloqueadas.", 3.5)

func _toggle_armor_suit() -> void:
	if GameManager.has_suit_equipped:
		return # Solo se puede equipar una vez al inicio
	if ScreenFade.current_tween and ScreenFade.current_tween.is_valid():
		return
	ScreenFade.fade_out_in(0.35, 0.1, 0.35, Callable(self, "_on_armor_equip_midpoint"))

func _on_armor_equip_midpoint() -> void:
	GameManager.has_suit_equipped = true
	SaveManager.set_story_stage("mission_1")
	_update_armor_stand_state()
	AudioManager.play_sfx("marine_ready")
	if player_node and player_node.has_method("set_suit_equipped"):
		player_node.set_suit_equipped(true)
		player_node.show_bubble("Pesa más de lo que parece...", 2.5, "PROTAG_13")

func _update_armor_stand_state() -> void:
	if not armor_stand_sprite or not armor_stand_hint:
		return
	if GameManager.has_suit_equipped:
		# La armadura desaparece del soporte al equiparse (sin opción de guardar)
		armor_stand_sprite.visible = false
		if armor_stand_shadow:
			armor_stand_shadow.visible = false
		armor_stand_hint.visible = false
		armor_stand_hint.text = ""
		if armor_stand_area:
			armor_stand_area.monitoring = false
		var is_medic = (GameManager.selected_hero == "medic")
		if bottom_wireframe:
			var wf_name = "wire_medic" if is_medic else "wire_marine"
			var wf_m = SkinManager.get_sprite(wf_name)
			if wf_m: bottom_wireframe.texture = wf_m
		if bottom_portrait:
			var port_path = "res://assets/skins/sd/portrait/medic_portrait.png" if is_medic else "res://assets/skins/sd/portrait/marine_portrait.png"
			bottom_portrait.set_portrait(load(port_path))
			bottom_portrait.trigger_talk(1.5)
		if bottom_name_label:
			bottom_name_label.text = "MÉDICA TERRAN" if is_medic else "INFANTERÍA TERRAN"
		if bottom_rank_label:
			bottom_rank_label.text = "Soporte Táctico" if is_medic else "Blindaje: CMC-300"
		if bottom_weapon_label:
			bottom_weapon_label.text = "Láser Médico Táctico" if is_medic else "Fusil Gauss C-14"
		if bottom_armor_label:
			bottom_armor_label.text = "Armadura: 0 (+1)"
		if bottom_hp_bar:
			bottom_hp_bar.set_health(40, 40)
		if bottom_hp_label:
			bottom_hp_label.text = "40 / 40"
	else:
		armor_stand_sprite.visible = true
		armor_stand_sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		if armor_stand_shadow:
			armor_stand_shadow.visible = true
			armor_stand_shadow.modulate = Color(1.0, 1.0, 1.0, 1.0)
		armor_stand_hint.text = "[E] EQUIPAR ARMADURA CMC-300"
		if bottom_wireframe:
			var wf_c = SkinManager.get_sprite("wire_civilian")
			if wf_c: bottom_wireframe.texture = wf_c
		if bottom_portrait:
			bottom_portrait.set_portrait(null)
		if bottom_name_label:
			bottom_name_label.text = "??????"
		if bottom_rank_label:
			bottom_rank_label.text = "Identidad Desconocida"
		if bottom_weapon_label:
			bottom_weapon_label.text = "Sin armamento"
		if bottom_armor_label:
			bottom_armor_label.text = "Armadura: 0"
		if bottom_hp_bar:
			bottom_hp_bar.set_health(80, 80)
		if bottom_hp_label:
			bottom_hp_label.text = "80 / 80"

func _connect_signals() -> void:
	cmd_center_close_btn.pressed.connect(_close_all_modals)
	academy_close_btn.pressed.connect(_close_all_modals)
	mission_close_btn.pressed.connect(_close_all_modals)
	deploy_cancel_btn.pressed.connect(_close_all_modals)
	
	# Interacción con Centro de Mando
	if cmd_center_area:
		cmd_center_area.body_entered.connect(func(b):
			if b.is_in_group("player"):
				active_zone = "cmd_center"
				cmd_center_hint.visible = true
		)
		cmd_center_area.body_exited.connect(func(b):
			if b.is_in_group("player"):
				if active_zone == "cmd_center": active_zone = ""
				cmd_center_hint.visible = false
				cmd_center_panel.visible = false
		)
	
	# Menú de Pausa / Configuración
	pause_resume_btn.pressed.connect(_close_pause_menu)
	pause_quit_btn.pressed.connect(func():
		AudioManager.play_sfx("button")
		ScreenFade.fade_out_in(0.3, 0.1, 0.3, func():
			get_tree().change_scene_to_file("res://scenes/title_screen.tscn")
		)
	)
	pause_music_slider.value_changed.connect(func(val):
		AudioManager.set_music_volume(val)
		pause_music_lbl.text = "Volumen Música: %d%%" % int(val * 100)
	)
	pause_sfx_slider.value_changed.connect(func(val):
		AudioManager.set_sfx_volume(val)
		pause_sfx_lbl.text = "Volumen Efectos: %d%%" % int(val * 100)
	)
	if pause_voice_slider and pause_voice_lbl:
		pause_voice_slider.value_changed.connect(func(val):
			AudioManager.set_voice_volume(val)
			pause_voice_lbl.text = "Volumen Voces: %d%%" % int(val * 100)
		)
	pause_fullscreen_check.toggled.connect(func(toggled_on):
		AudioManager.play_sfx("button")
		if toggled_on:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	
	deploy_confirm_btn.pressed.connect(func():
		AudioManager.play_sfx("ship_liftoff")
		_close_all_modals()
		ScreenFade.fade_out_in(0.4, 0.1, 0.4, func():
			if StoryManager.can_access_character_select():
				get_tree().change_scene_to_file("res://scenes/character_select.tscn")
			else:
				GameManager.deploy_to_mission()
		)
	)
	
	mission_action_btn.pressed.connect(func():
		if GameManager.is_mission_completed:
			GameManager.claim_mission_reward()
			AudioManager.play_sfx("upgrade")
			_open_mission()
			_update_top_bar()
		else:
			_close_all_modals()
	)
	
	# Zonas de interacción
	if armor_stand_area:
		armor_stand_area.body_entered.connect(func(b):
			if b.is_in_group("player"):
				active_zone = "armor"
				if armor_stand_hint: armor_stand_hint.visible = true
		)
		armor_stand_area.body_exited.connect(func(b):
			if b.is_in_group("player"):
				if active_zone == "armor": active_zone = ""
				if armor_stand_hint: armor_stand_hint.visible = false
		)
	
	$Barracks/Area2D.body_entered.connect(func(b):
		if b.is_in_group("player"):
			active_zone = "barracks"
			barracks_hint.visible = true
	)
	$Barracks/Area2D.body_exited.connect(func(b):
		if b.is_in_group("player"):
			if active_zone == "barracks": active_zone = ""
			barracks_hint.visible = false
	)
	
	$Academy/Area2D.body_entered.connect(func(b):
		if b.is_in_group("player"):
			active_zone = "academy"
			academy_hint.visible = true
	)
	$Academy/Area2D.body_exited.connect(func(b):
		if b.is_in_group("player"):
			if active_zone == "academy": active_zone = ""
			academy_hint.visible = false
			academy_modal.visible = false
	)
	
	$Starport/Area2D.body_entered.connect(func(b):
		if b.is_in_group("player"):
			active_zone = "starport"
			starport_hint.visible = true
	)
	$Starport/Area2D.body_exited.connect(func(b):
		if b.is_in_group("player"):
			if active_zone == "starport": active_zone = ""
			starport_hint.visible = false
			deploy_modal.visible = false
	)
	
	$NPC/Area2D.body_entered.connect(func(b):
		if b.is_in_group("player"):
			active_zone = "npc"
			npc_hint.visible = true
	)
	$NPC/Area2D.body_exited.connect(func(b):
		if b.is_in_group("player"):
			if active_zone == "npc": active_zone = ""
			npc_hint.visible = false
			mission_modal.visible = false
	)
	
	GameManager.base_resources_changed.connect(func(_m, _g):
		_update_top_bar()
		_refresh_base_buildings()
		_populate_academy_upgrades()
	)

func _update_top_bar() -> void:
	if has_node("CanvasLayer/TopBar/HBox/MineralHBox"):
		$CanvasLayer/TopBar/HBox/MineralHBox.visible = false
	top_bar_gas.text = "%d" % SaveManager.total_gas

func _open_deploy() -> void:
	AudioManager.play_sfx("ship_land")
	var m_id = StoryManager.get_current_mission_id()
	var m = StoryManager.get_mission_data(m_id)
	deploy_mission_lbl.text = "¿Despegar al páramo exterior?\nMisión: %s" % m.get("title", "Misión")
	deploy_modal.visible = true

func _open_mission() -> void:
	AudioManager.play_voss_greeting()
	var stage = SaveManager.get_story_stage()
	var m_id = StoryManager.get_current_mission_id()
	var m = StoryManager.get_mission_data(m_id)
	
	var has_completed_initial = (GameManager.is_mission_completed or GameManager.session_minerals >= 20 or GameManager.mission_kills >= 20)
	var dialog_text: String = ""
	var req_text: String = ""
	
	var voice_id: String = ""
	if not StoryManager.is_engineering_bay_built():
		if has_completed_initial:
			dialog_text = "«Sobreviviste a la incursión y aseguraste la zona. Dirígete a la terminal del Centro de Mando para autorizar el despliegue de la Bahía de Ingeniería.»"
			req_text = "Objetivo: Construir Bahía de Ingeniería en el Centro de Mando"
			voice_id = "VOSS_23"
		else:
			dialog_text = "«Bienvenido. Te dejé la armadura en el soporte. Baja al exterior con la nave, elimina a los Zergs y vuelve entero antes de que te destrozen.»"
			req_text = "Objetivo: Sobrevivir en el exterior y purgar Zerglings"
			voice_id = "VOSS_22"
	elif not StoryManager.is_barracks_built():
		if has_completed_initial:
			dialog_text = "«La Bahía de Ingeniería está operativa. Ve a la terminal del Centro de Mando para autorizar el aterrizaje del Cuartel.»"
			req_text = "Objetivo: Construir Cuartel en el Centro de Mando"
			voice_id = "VOSS_24"
		else:
			dialog_text = "«La Bahía de Ingeniería está en pie. Nuestra siguiente prioridad es el Cuartel.»"
			req_text = "Objetivo: Incursión en el exterior"
			voice_id = "VOSS_28"
	else:
		dialog_text = "«Sobrevive 20 minutos ahí abajo para limpiar los páramos y forzar la emergencia de la amenaza.»"
		req_text = "Misión: %s" % m.get("title", "")
		voice_id = "VOSS_25"
	
	var voss_tex = load("res://assets/skins/sd/portrait/civilian_portrait.png")
	if face_to_face_dialog:
		_close_all_modals()
		if player_node:
			player_node.can_move = false
		face_to_face_dialog.show_dialogue("CAPITÁN HOLLIS VOSS", voss_tex, dialog_text, req_text, func():
			if player_node:
				player_node.can_move = true
			if GameManager.is_mission_completed:
				GameManager.claim_mission_reward()
				AudioManager.play_sfx("upgrade")
				_update_top_bar()
		, voice_id)
	mission_modal.visible = false

func _populate_academy_upgrades() -> void:
	for child in academy_list.get_children():
		child.queue_free()
	
	var cur_min = SaveManager.total_minerals
	var cur_gas = SaveManager.total_gas
	
	for key in GameManager.BARRACKS_UPGRADES_DEF.keys():
		var def = GameManager.BARRACKS_UPGRADES_DEF[key]
		var cur_lvl = GameManager.barracks_upgrades.get(key, 0)
		var max_lvl = def["max_lvl"]
		var prereq = def.get("prereq", "")
		var has_prereq = (prereq == "" or GameManager.barracks_upgrades.get(prereq, 0) > 0)
		var is_max = (cur_lvl >= max_lvl)
		var is_weapon_unlock = def.get("is_weapon", false) and max_lvl == 1
		
		var panel = PanelContainer.new()
		panel.custom_minimum_size = Vector2(165, 88)
		panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.08, 0.13, 0.95)
		if not has_prereq:
			sb.border_color = Color(0.5, 0.2, 0.2, 0.7)
		elif is_max:
			sb.border_color = Color(0.2, 0.6, 0.35, 0.8)
		elif is_weapon_unlock:
			sb.border_color = Color(0.9, 0.7, 0.2, 0.8)
		else:
			sb.border_color = Color(0.2, 0.5, 0.8, 0.8)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		sb.content_margin_left = 6
		sb.content_margin_top = 5
		sb.content_margin_right = 6
		sb.content_margin_bottom = 5
		panel.add_theme_stylebox_override("panel", sb)
		
		var card_vbox = VBoxContainer.new()
		card_vbox.set("theme_override_constants/separation", 3)
		card_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		# Fila superior: Icono + Nombre + Nivel
		var top_row = HBoxContainer.new()
		top_row.set("theme_override_constants/separation", 6)
		
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(30, 30)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		
		var atlas = AtlasTexture.new()
		if def.get("is_weapon", false):
			atlas.atlas = load("res://assets/skins/sd/sprites/weapon_icons.png")
		else:
			atlas.atlas = load("res://assets/skins/sd/sprites/tech_icons_clean.png")
		var icon_idx = def.get("icon_idx", 0)
		atlas.region = Rect2(icon_idx * 48, 0, 48, 48)
		icon_rect.texture = atlas
		if not has_prereq:
			icon_rect.modulate = Color(0.5, 0.5, 0.5, 0.7)
		top_row.add_child(icon_rect)
		
		var name_vbox = VBoxContainer.new()
		name_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		name_vbox.set("theme_override_constants/separation", 0)
		
		var name_lbl = Label.new()
		name_lbl.text = def["name"]
		if not has_prereq:
			name_lbl.add_theme_color_override("font_color", Color(0.7, 0.45, 0.45, 0.9))
		elif is_weapon_unlock:
			name_lbl.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))
		else:
			name_lbl.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0, 1.0))
		name_lbl.add_theme_font_size_override("font_size", 9)
		name_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		name_vbox.add_child(name_lbl)
		
		var lvl_lbl = Label.new()
		if not has_prereq:
			lvl_lbl.text = "BLOQUEADO"
			lvl_lbl.add_theme_color_override("font_color", Color(0.9, 0.3, 0.3, 0.9))
		elif is_weapon_unlock:
			lvl_lbl.text = "DESBLOQUEADA" if is_max else "DISPONIBLE"
			lvl_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9) if is_max else Color(1.0, 0.9, 0.5, 0.9))
		else:
			lvl_lbl.text = "Nv. %d / %d" % [cur_lvl, max_lvl]
			lvl_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 0.9) if is_max else Color(0.75, 0.85, 0.95, 0.9))
		lvl_lbl.add_theme_font_size_override("font_size", 8)
		name_vbox.add_child(lvl_lbl)
		
		top_row.add_child(name_vbox)
		card_vbox.add_child(top_row)
		
		# Descripción
		var desc_lbl = Label.new()
		desc_lbl.text = def["desc"]
		desc_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.85))
		desc_lbl.add_theme_font_size_override("font_size", 8)
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.size_flags_vertical = Control.SIZE_EXPAND_FILL
		card_vbox.add_child(desc_lbl)
		
		# Botón de acción / compra
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(0, 24)
		buy_btn.add_theme_font_size_override("font_size", 8)
		
		if not has_prereq:
			buy_btn.text = "REQUIERE: %s" % def.get("prereq_name", "ARMA BASE").to_upper()
			buy_btn.disabled = true
			buy_btn.add_theme_color_override("font_color", Color(0.9, 0.4, 0.4, 0.9))
		elif is_max:
			buy_btn.text = "OPERATIVO (MAX)"
			buy_btn.disabled = true
			buy_btn.add_theme_color_override("font_color", Color(0.4, 0.9, 0.4, 0.9))
		else:
			var cost_g = def["cost_gas"][cur_lvl]
			var can_afford = (cur_gas >= cost_g)
			
			buy_btn.text = ""
			buy_btn.disabled = not can_afford
			
			var btn_hbox = HBoxContainer.new()
			btn_hbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
			btn_hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
			btn_hbox.add_theme_constant_override("separation", 6)
			
			var action_lbl = Label.new()
			action_lbl.text = "ADQUIRIR" if is_weapon_unlock else "INVESTIGAR"
			action_lbl.add_theme_font_size_override("font_size", 8)
			action_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0) if can_afford else Color(0.85, 0.4, 0.4, 0.9))
			btn_hbox.add_child(action_lbl)
			
			var gas_ico = TextureRect.new()
			gas_ico.texture = load("res://assets/skins/sd/ui/icon_gas.png")
			gas_ico.custom_minimum_size = Vector2(13, 13)
			gas_ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			gas_ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn_hbox.add_child(gas_ico)
			
			var gas_lbl = Label.new()
			gas_lbl.text = "%d" % cost_g
			gas_lbl.add_theme_font_size_override("font_size", 8)
			gas_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0) if can_afford else Color(0.85, 0.4, 0.4, 0.9))
			btn_hbox.add_child(gas_lbl)
			
			buy_btn.add_child(btn_hbox)
			
			if can_afford:
				var up_key = key
				buy_btn.pressed.connect(func():
					if GameManager.buy_barracks_upgrade(up_key):
						_populate_academy_upgrades()
						_update_top_bar()
				)
		
		card_vbox.add_child(buy_btn)
		panel.add_child(card_vbox)
		academy_list.add_child(panel)
