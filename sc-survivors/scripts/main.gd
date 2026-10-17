extends Node2D

var vespene_scene: PackedScene = null
var vespene_spawn_timer: float = 0.0

func _ready() -> void:
	GameManager.reset_game()
	vespene_scene = load("res://scenes/vespene_tank.tscn")
	_apply_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)
	
	call_deferred("_spawn_initial_vespene")
	call_deferred("_setup_mission_intro")

func _setup_mission_intro() -> void:
	var player = get_tree().get_first_node_in_group("player") as Player
	if not player:
		return
	
	# Asegurar SIEMPRE que el jugador pueda moverse de inmediato
	player.set_physics_process(true)
	
	if not GameManager.has_suit_equipped:
		# Despliegue suicida sin armadura (Civil)
		_play_unarmored_intro(player)
	else:
		# Despliegue con armadura Marine CMC-300
		if SaveManager.first_death_dialogue_pending or SaveManager.has_experienced_first_death:
			return
		if SaveManager.get_story_stage() == "mission_1" and not SaveManager.has_seen_mission_1_intro:
			SaveManager.has_seen_mission_1_intro = true
			SaveManager.save_data()
			_play_mission_1_landing_intro(player)

func _play_unarmored_intro(player: Player) -> void:
	var hud_node = get_tree().get_first_node_in_group("hud")
	if hud_node and hud_node.has_method("show_transmission"):
		hud_node.show_transmission("CAPITÁN HOLLIS VOSS", load("res://assets/skins/sd/portrait/civilian_portrait.png"), "«¡Estúpido! ¡Tenías que ponerte la armadura antes de bajar!»", 5.0, Callable(), "VOSS_10")

func _play_mission_1_landing_intro(player: Player) -> void:
	AudioManager.play_sfx("ship_liftoff")
	
	var z_scene = load("res://scenes/zergling.tscn")
	if not z_scene:
		return
	
	var targets: Array[Node2D] = []
	for i in range(3):
		var z = z_scene.instantiate()
		var offset = Vector2(170 + i * 25, -60 + i * 60)
		z.global_position = player.global_position + offset
		z.base_speed = 120.0
		add_child(z)
		targets.append(z)
	
	var tw = create_tween()
	tw.tween_interval(0.8)
	for z in targets:
		tw.tween_callback(func():
			if is_instance_valid(z) and is_instance_valid(player):
				player._fire_c14(z)
				z.take_damage(999.0)
		)
		tw.tween_interval(0.2)
	
	# Diálogo de asombro del Marine
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		var hud_node = get_tree().get_first_node_in_group("hud")
		if hud_node and hud_node.has_method("show_transmission"):
			hud_node.show_transmission("??????", SkinManager.get_portrait("marine"), "«¡¿WOW... yo hice eso?!»", 4.5, Callable(), "PROTAG_14")
	)
	
	# Delay de 5 segundos antes de la respuesta del Capitán Voss
	tw.tween_interval(5.0)
	tw.tween_callback(func():
		var hud_node = get_tree().get_first_node_in_group("hud")
		if hud_node and hud_node.has_method("show_transmission"):
			hud_node.show_transmission("CAPITÁN HOLLIS VOSS", load("res://assets/skins/sd/portrait/civilian_portrait.png"), "«Tranquilo, novato. Es el sistema de tiro automático del traje. Apunta y calcula solo. Junta 20 minerales y regresa a la nave.»", 5.5, Callable(), "VOSS_11")
	)

func _process(delta: float) -> void:
	vespene_spawn_timer += delta
	if vespene_spawn_timer >= 30.0:
		vespene_spawn_timer = 0.0
		_spawn_vespene_batch(2)

func _spawn_initial_vespene() -> void:
	if StoryManager.is_gas_available_outside():
		_spawn_vespene_batch(8)

func _spawn_vespene_batch(count: int) -> void:
	if not StoryManager.is_gas_available_outside():
		return
	
	var player = get_tree().get_first_node_in_group("player")
	var base_pos = player.global_position if player else Vector2(320, 240)
	
	for i in range(count):
		var angle = randf() * TAU
		var dist = randf_range(480.0, 1300.0)
		var pos = base_pos + Vector2(cos(angle), sin(angle)) * dist
		
		if vespene_scene:
			var tank = vespene_scene.instantiate()
			tank.global_position = pos
			add_child(tank)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	var ground = get_node_or_null("ParallaxBackground/ParallaxLayer/GroundSprite") as Sprite2D
	if ground:
		var tile = SkinManager.get_tile("ground")
		if tile:
			ground.texture = tile

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_M:
			# Atajo de desarrollo M: Forzar emergencia del Canal Nydus y clímax
			if not GameManager.has_triggered_20min_climax:
				GameManager._trigger_20min_climax()
			get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N or event.keycode == KEY_F9:
			# Atajo de desarrollo N / F9: Saltar de inmediato a la Cueva del Torrasque
			var player = get_tree().get_first_node_in_group("player") as Player
			if is_instance_valid(player):
				GameManager.save_player_state(player)
			get_tree().change_scene_to_file("res://scenes/boss_cave_arena.tscn")
			get_viewport().set_input_as_handled()

