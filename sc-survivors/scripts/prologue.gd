class_name Prologue
extends Node2D

@onready var player: CivilianPlayer = $CivilianPlayer
@onready var ground: Sprite2D = $Ground
@onready var dropship: Sprite2D = $Dropship
@onready var tutorial_banner: Panel = $CanvasLayer/TutorialBanner
@onready var tutorial_label: Label = $CanvasLayer/TutorialBanner/Label
@onready var transmission_comm: TransmissionComm = $CanvasLayer/TransmissionComm
var radio_box: Control = null
var radio_title: Label = null
var radio_text: Label = null
@onready var black_fade: ColorRect = $CanvasLayer/BlackFade

# HUD inferior de salud y estado táctico
@onready var bottom_hud: Panel = $CanvasLayer/BottomHUD
@onready var hp_bar: SCHealthBar = $CanvasLayer/BottomHUD/HBox/InfoVBox/SCHealthBar
@onready var hp_label: Label = $CanvasLayer/BottomHUD/HBox/InfoVBox/HealthLabel

var prologue_step: int = 0
var zerg_spawned: bool = false
var zerg_pack: Array[Node2D] = []
var rescued: bool = false

func _ready() -> void:
	# Cursor
	var cursor_tex = SkinManager.get_ui("cursor")
	if cursor_tex:
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2.ZERO)
	
	# Música ambiente del páramo desértico
	AudioManager.play_music("terran2", true, true)
	
	# Ocultar naves y UI inicial
	dropship.visible = false
	if transmission_comm:
		transmission_comm.visible = false
	tutorial_banner.visible = false
	
	# Configurar límites exactos de la cámara (3200x2400) para evitar cuadros negros
	var cam = player.get_node_or_null("Camera2D")
	if cam:
		cam.limit_left = 0
		cam.limit_top = 0
		cam.limit_right = 3200
		cam.limit_bottom = 2400
	
	# Inicializar HUD de vida inferior
	player.move_speed = 105.0
	_update_hp_display(player.current_health, player.max_health)
	player.health_changed.connect(_on_player_health_changed)
	player.moved_first_time.connect(_on_player_moved_first_time)
	player.critical_hp_reached.connect(_on_critical_hp_reached)
	
	# Fade-in inicial desde negro
	black_fade.visible = true
	black_fade.color = Color(0, 0, 0, 1)
	player.can_move = false
	
	_start_intro_sequence()

func _start_intro_sequence() -> void:
	var tw = create_tween()
	tw.tween_property(black_fade, "color:a", 0.0, 1.8)
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		player.show_bubble("...Ugh. ¿Dónde me encuentro?", 3.5)
	)
	tw.tween_interval(3.8)
	tw.tween_callback(func():
		player.show_bubble("No... no recuerdo nada. Ni cómo llegué aquí.", 4.0)
	)
	tw.tween_interval(4.3)
	tw.tween_callback(func():
		player.show_bubble("Calma. Primero lo primero: ponerse de pie.", 3.5)
		_show_tutorial("Usa [W][A][S][D] o Flechas para moverte")
		player.can_move = true
	)

func _show_tutorial(text: String) -> void:
	tutorial_label.text = text
	tutorial_banner.visible = true
	tutorial_banner.modulate.a = 0.0
	var tw = create_tween()
	tw.tween_property(tutorial_banner, "modulate:a", 1.0, 0.4)

func _on_player_health_changed(cur_hp: float, max_hp: float) -> void:
	_update_hp_display(cur_hp, max_hp)

func _update_hp_display(cur_hp: float, max_hp: float) -> void:
	if hp_bar:
		hp_bar.set_health(cur_hp, max_hp)
	hp_label.text = "VIDA: %d / %d" % [int(max(cur_hp, 0.0)), int(max_hp)]
	
	var pct = clamp(cur_hp / max_hp, 0.0, 1.0)
	if pct > 0.5:
		hp_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
	elif pct > 0.25:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.2, 1.0))
	else:
		hp_label.add_theme_color_override("font_color", Color(1.0, 0.3, 0.3, 1.0))

func _on_player_moved_first_time() -> void:
	if zerg_spawned:
		return
	
	# Un momento después de moverse, aparecen los Zerglings
	var tw = create_tween()
	tw.tween_interval(2.2)
	tw.tween_callback(_trigger_zerg_ambush)

func _trigger_zerg_ambush() -> void:
	if zerg_spawned:
		return
	zerg_spawned = true
	
	AudioManager.play_sfx("zergling_death")
	player.show_bubble("¡¿Zergs?! ¡¿Aquí?! ¡CORRE!", 3.0)
	_show_tutorial("¡CORRE! ¡NO TIENES ARMAS NI ESCUDOS!")
	
	var tw = create_tween()
	tw.tween_interval(0.4)
	tw.tween_callback(func():
		_spawn_zerglings(7)
	)

func _spawn_zerglings(count: int) -> void:
	var z_scene = load("res://scenes/zergling.tscn")
	if not z_scene:
		return
	
	for i in range(count):
		var angle = (float(i) / float(count)) * TAU + randf_range(-0.2, 0.2)
		var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * randf_range(280.0, 360.0)
		var z = z_scene.instantiate()
		z.global_position = spawn_pos
		z.base_speed = 98.0
		z.damage_per_hit = 8.0
		add_child(z)
		zerg_pack.append(z)

func _on_critical_hp_reached() -> void:
	if rescued:
		return
	rescued = true
	
	player.can_move = false
	player.show_bubble("¡Es el final!... ¡No voy a sobrevivir a esto!", 3.0)
	
	# Efecto de tensión
	Engine.time_scale = 0.7
	
	# Dispersar o frenar a los zerglings
	for z in zerg_pack:
		if is_instance_valid(z):
			var push_dir = (z.global_position - player.global_position).normalized()
			z.velocity = push_dir * 180.0
			z.set_physics_process(false)
	
	var tw = create_tween()
	tw.tween_interval(1.2)
	tw.tween_callback(_start_dropship_rescue)

func _start_dropship_rescue() -> void:
	Engine.time_scale = 1.0
	
	# Efectos mecánicos de nave aterrizando sin voces de tripulación
	AudioManager.play_sfx("ship_land")
	
	# Nave desciende desde el cielo
	dropship.visible = true
	dropship.global_position = player.global_position + Vector2(60, -320)
	dropship.modulate.a = 0.0
	
	var land_pos = player.global_position + Vector2(50, -30)
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(dropship, "global_position", land_pos, 1.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(dropship, "modulate:a", 1.0, 0.5)
	
	# Al aterrizar, sonido de transmisión y radio de Voss con el comunicador táctico
	tw.chain().tween_callback(func():
		_show_radio_message(
			"CAPITÁN HOLLIS VOSS",
			"«¡Oye, tú! ¡Sube a la nave de inmediato, no pienso esperar aquí!»",
			3.6
		)
	)
	
	# El jugador lee el mensaje y sube a la nave (fades into ship)
	tw.chain().tween_interval(3.6)
	tw.chain().tween_property(player, "modulate:a", 0.0, 0.6)
	
	# Mensaje de partida y despegue
	tw.chain().tween_callback(func():
		_show_radio_message(
			"CAPITÁN HOLLIS VOSS",
			"«¡Sujétate bien! ¡Salimos de inmediato!»",
			2.5
		)
	)
	
	# Nave despega con sonido de motores de propulsión
	tw.chain().tween_interval(2.2)
	tw.chain().tween_callback(func():
		AudioManager.play_sfx("ship_liftoff")
	)
	tw.chain().tween_property(dropship, "global_position", land_pos + Vector2(100, -500), 1.1).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.chain().tween_property(black_fade, "color:a", 1.0, 0.8)
	
	# Transición a la Base Terran
	tw.chain().tween_interval(0.5)
	tw.chain().tween_callback(func():
		SaveManager.set_story_stage("base_initial")
		get_tree().change_scene_to_file("res://scenes/terran_base.tscn")
	)

func _show_radio_message(title: String, text: String, duration: float = 4.0) -> void:
	if transmission_comm:
		var voss_tex = load("res://assets/skins/sd/portrait/civilian_portrait.png")
		transmission_comm.show_transmission(title, voss_tex, text, duration)
