class_name OverlordDropship
extends Node2D

## Overlord de Desembarco Táctico Zerg (Evento ambiental de los últimos 5 minutos)
## Vuela sobre el mapa de un lado a otro como evento del mapa (inmune a ataques)
## y va desembarcando Zerglings de élite (Tier 4) con su sonido característico.

@export var flight_speed: float = 120.0
@export var max_drops: int = 5
@export var drop_interval: float = 1.4

var flight_direction: Vector2 = Vector2.RIGHT
var distance_traveled: float = 0.0
var max_distance: float = 1500.0

var drops_performed: int = 0
var drop_timer: float = 1.0

# Animación y dirección StarCraft de 17 columnas
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
var player: Node2D = null

func _ready() -> void:
	add_to_group("overlord_transports")
	z_index = 8 # Vuela a gran altitud sobre las unidades terrestres
	player = get_tree().get_first_node_in_group("player")
	
	if sprite:
		var tex = SkinManager.get_sprite("overlord")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 4
		sprite.scale = Vector2(1.25, 1.25)
	
	if shadow:
		var tex = SkinManager.get_sprite("overlord_shadow")
		if tex:
			shadow.texture = tex
		shadow.hframes = 17
		shadow.vframes = 4
		shadow.position = Vector2(0, 36)
		shadow.scale = Vector2(1.25, 1.25)
		shadow.modulate = Color(0, 0, 0, 0.40)
	
	AudioManager.play_sfx("overlord_groan", 0.08, -2.0)

func setup(start_pos: Vector2, target_dir: Vector2) -> void:
	global_position = start_pos
	flight_direction = target_dir.normalized()
	_update_orientation(flight_direction)

func _update_orientation(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var angle_sc = fposmod(dir.angle() + PI * 0.5, TAU)
	var current_dir32 = int(round(angle_sc / (TAU / 32.0))) % 32
	if current_dir32 <= 16:
		facing_column = current_dir32
		is_facing_left = false
	else:
		facing_column = 32 - current_dir32
		is_facing_left = true

func _physics_process(delta: float) -> void:
	var move_step = flight_direction * flight_speed * delta
	global_position += move_step
	distance_traveled += move_step.length()
	
	# Animación de flotación orgánica (4 filas)
	anim_timer += delta * 6.0
	var flap_row = int(anim_timer) % 4
	var frame_idx = flap_row * 17 + facing_column
	if sprite:
		sprite.frame = frame_idx
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = frame_idx
		shadow.flip_h = is_facing_left
	
	# Desembarco de Zerglings duros cuando está cerca del jugador
	if drops_performed < max_drops:
		drop_timer -= delta
		if drop_timer <= 0.0:
			if not player or not is_instance_valid(player):
				player = get_tree().get_first_node_in_group("player")
			if player and global_position.distance_to(player.global_position) <= 420.0:
				_drop_elite_zergling()
				drop_timer = drop_interval + randf_range(-0.2, 0.3)
	
	if distance_traveled >= max_distance:
		queue_free()

func _drop_elite_zergling() -> void:
	drops_performed += 1
	AudioManager.play_sfx("overlord_drop", 0.12, 0.0)
	
	var zergling_scene = GameManager.zergling_scene
	if not zergling_scene:
		zergling_scene = load("res://scenes/zergling.tscn")
	if not zergling_scene:
		return
	
	var zergling = zergling_scene.instantiate()
	# Caída desde la compuerta del Overlord al suelo
	var drop_start_pos = global_position + Vector2(0, 10)
	var ground_landing_pos = global_position + Vector2(randf_range(-12.0, 12.0), 38.0)
	zergling.global_position = ground_landing_pos
	
	# Asignar Tier 4 (el zergling más duro, 140 HP, armadura y tinte carmesí)
	if zergling.has_method("set_tier"):
		zergling.set_tier(4)
	
	get_parent().add_child(zergling)
	
	# Efecto visual de desembarco (escala y caída rápida)
	if zergling.has_node("Sprite2D"):
		var z_spr = zergling.get_node("Sprite2D")
		var orig_scale = z_spr.scale
		z_spr.position = Vector2(0, -28)
		var tw = zergling.create_tween()
		tw.tween_property(z_spr, "position:y", 0.0, 0.22).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

func clear_immediately() -> void:
	queue_free()
