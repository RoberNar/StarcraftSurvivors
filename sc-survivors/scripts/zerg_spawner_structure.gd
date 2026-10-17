class_name ZergSpawnerStructure
extends StaticBody2D

signal health_changed(current_hp: float, max_hp: float)
signal destroyed(structure_type: String)

@export var structure_type: String = "zergling_pool"
var base_health: float = 1500.0
var current_health: float = 1500.0
var is_destroyed: bool = false
var is_dead: bool = false

var title: String = "POZO DE DESOVE ZERG"
var subtitle: String = "Destruye la estructura para detener la marea"
var spawn_interval: float = 1.5
var spawn_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D

var anim_timer: float = 0.0
var anim_frame: int = 0

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	add_to_group("spawner_structures")
	
	_setup_structure()
	current_health = base_health
	emit_signal("health_changed", current_health, base_health)
	
	# Avisar al HUD para que despliegue la barra de jefe superior
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud and hud.has_method("show_event_boss_bar"):
			hud.show_event_boss_bar(title, current_health, base_health, self)

func _setup_structure() -> void:
	if not sprite:
		return
	
	match structure_type:
		"zergling_pool":
			title = "POZO DE DESOVE ZERG"
			subtitle = "Destruye el nido para frenar la marea de Zerglings"
			base_health = 1500.0
			spawn_interval = 1.5
			sprite.texture = SkinManager.get_sprite("zergling_nest")
			sprite.hframes = 1
			sprite.vframes = 4
			sprite.scale = Vector2(1.2, 1.2)
			AudioManager.play_sfx("zerg_nest_emerge", 0.05, 3.0)
		"hydralisk_den":
			title = "GUARIDA DE HIDRALISCOS"
			subtitle = "Destruye la bio-estructura para contener las espinas"
			base_health = 3200.0
			spawn_interval = 2.0
			sprite.texture = SkinManager.get_sprite("hydralisk_nest")
			sprite.hframes = 1
			sprite.vframes = 4
			sprite.scale = Vector2(1.1, 1.1)
			AudioManager.play_sfx("zerg_nest_emerge", 0.05, 3.0)
		"mutalisk_spire":
			title = "ESPIRA MUTADA ZERG"
			subtitle = "Destruye la espira para erradicar el enjambre aéreo"
			base_health = 4800.0
			spawn_interval = 2.5
			sprite.texture = SkinManager.get_sprite("mutalisk_spire")
			sprite.hframes = 1
			sprite.vframes = 4
			sprite.scale = Vector2(1.3, 1.3)
			AudioManager.play_sfx("zerg_spire_emerge", 0.05, 3.0)

func _process(delta: float) -> void:
	if is_destroyed:
		return
	
	# Animación biológica pulsante de StarCraft
	anim_timer += delta * 4.0
	if sprite and sprite.vframes > 1:
		sprite.frame = int(anim_timer) % sprite.vframes
	
	# Spawn continuo de oleadas agresivas
	spawn_timer += delta
	if spawn_timer >= spawn_interval:
		spawn_timer = 0.0
		_spawn_wave()

func _get_safe_minion_spawn_pos(player: Node2D, radius: float) -> Vector2:
	var to_struct = global_position - player.global_position
	var p_dist = to_struct.length()
	
	# Si el jugador está cerca o encima de la estructura, spawnear al lado OPUESTO
	# de la estructura y garantizar una distancia de exclusión mínima de al menos 180 px.
	const MIN_PLAYER_EXCLUSION: float = 180.0
	if p_dist < MIN_PLAYER_EXCLUSION:
		var away_dir = to_struct.normalized() if p_dist > 5.0 else Vector2.RIGHT.rotated(randf() * TAU)
		var perp = Vector2(-away_dir.y, away_dir.x)
		var spawn_pos = global_position + (away_dir * randf_range(radius + 40.0, radius + 90.0)) + (perp * randf_range(-35.0, 35.0))
		if spawn_pos.distance_to(player.global_position) < MIN_PLAYER_EXCLUSION:
			spawn_pos = player.global_position + (spawn_pos - player.global_position).normalized() * MIN_PLAYER_EXCLUSION
		return spawn_pos
	else:
		var ang = randf() * TAU
		return global_position + Vector2(cos(ang), sin(ang)) * randf_range(radius * 0.7, radius * 1.2)

func _spawn_wave() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
	
	var main_scene = get_tree().current_scene
	if not main_scene:
		return
	
	match structure_type:
		"zergling_pool":
			var z_scene = load("res://scenes/zergling.tscn")
			if z_scene:
				for i in range(3):
					var z = z_scene.instantiate()
					z.global_position = _get_safe_minion_spawn_pos(player, 45.0)
					if z.has_method("set_tier"):
						z.set_tier(randi_range(2, 4))
					main_scene.add_child(z)
		"hydralisk_den":
			var h_scene = load("res://scenes/hydralisk.tscn")
			if h_scene:
				for i in range(2):
					var h = h_scene.instantiate()
					h.global_position = _get_safe_minion_spawn_pos(player, 50.0)
					main_scene.add_child(h)
		"mutalisk_spire":
			var m_scene = load("res://scenes/mutalisk.tscn")
			if m_scene:
				for i in range(3):
					var m = m_scene.instantiate()
					m.global_position = _get_safe_minion_spawn_pos(player, 55.0)
					main_scene.add_child(m)

func take_damage(amount: float) -> void:
	if is_destroyed:
		return
	
	current_health -= amount
	emit_signal("health_changed", current_health, base_health)
	
	# Flash de daño orgánico
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 0.8, 0.8, 1), 0.04)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.08)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_destroyed or is_dead:
		return
	is_destroyed = true
	is_dead = true
	current_health = 0.0
	emit_signal("health_changed", 0.0, base_health)
	emit_signal("destroyed", structure_type)
	remove_from_group("enemies")
	remove_from_group("bosses")
	
	AudioManager.play_sfx("zerg_building_death", 0.05, 4.0)
	GameManager.add_kill()
	GameManager.add_boss_kill()
	
	# Recompensas tácticas (cofre militar + minerales)
	_drop_rewards()
	
	# Desbloqueo de logros
	if has_node("/root/SaveManager"):
		match structure_type:
			"zergling_pool":
				SaveManager.unlock_achievement("destroy_spawning_pool")
			"hydralisk_den":
				SaveManager.unlock_achievement("destroy_hydra_den")
			"mutalisk_spire":
				SaveManager.unlock_achievement("destroy_mutalisk_spire")
	
	# Transmisión de confirmación táctica de la Operadora Terran
	var adv_tex = SkinManager.get_portrait("advisor")
	if not adv_tex:
		adv_tex = load("res://assets/skins/sd/portrait/advisor_portrait.png")
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud and hud.has_method("show_transmission"):
			hud.show_transmission(
				"OPERADORA TERRAN",
				adv_tex,
				"«Confirmación de objetivo: Bio-estructura Zerg neutralizada.»",
				4.5,
				Callable(),
				"ADJ_02"
			)
		if hud and hud.has_method("hide_event_boss_bar"):
			hud.hide_event_boss_bar()
	
	# Animación de disolución y explosión orgánica
	var tw = create_tween()
	tw.tween_property(sprite, "scale", sprite.scale * 1.25, 0.15)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.8)
	tw.tween_callback(queue_free)

func _drop_rewards() -> void:
	var chest_scene = load("res://scenes/chest.tscn")
	if chest_scene:
		var c = chest_scene.instantiate()
		c.global_position = global_position
		get_parent().call_deferred("add_child", c)
	
	var mineral_scene = load("res://scenes/mineral.tscn")
	if mineral_scene:
		for i in range(8):
			var m = mineral_scene.instantiate()
			var offset = Vector2(randf_range(-35, 35), randf_range(-35, 35))
			m.global_position = global_position + offset
			get_parent().call_deferred("add_child", m)
