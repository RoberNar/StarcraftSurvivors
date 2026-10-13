class_name Zergling
extends CharacterBody2D

@export var base_speed: float = 95.0
@export var base_health: float = 24.0
@export var damage_per_hit: float = 7.0
@export var attack_cooldown: float = 0.55

var current_health: float = 24.0
var move_speed: float = 95.0
var attack_timer: float = 0.0
var is_dead: bool = false
var angle_jitter: float = 0.0

# 32 angulos StarCraft
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

var tier: int = 1
var custom_tint: Color = Color(1, 1, 1, 1)
var custom_scale: float = 1.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	current_health = base_health
	move_speed = base_speed * randf_range(0.92, 1.15)
	angle_jitter = randf_range(-0.45, 0.45)
	
	player = get_tree().get_first_node_in_group("player")
	
	_apply_skin()
	_apply_tier_visuals()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)

var armor: float = 0.0

func set_tier(t: int) -> void:
	tier = t
	match t:
		1: # Café / Marrón clásico (0-2 min)
			custom_tint = Color(0.90, 0.70, 0.50, 1.0)
			custom_scale = 0.78
			base_health = 22.0
			armor = 0.0
			damage_per_hit = 5.0
		2: # Bronce cazador (2-4 min)
			custom_tint = Color(1.0, 0.85, 0.65, 1.0)
			custom_scale = 0.92
			base_health = 50.0
			armor = 1.0
			damage_per_hit = 7.0
		3: # Morado / Púrpura Zerg (4-6 min)
			custom_tint = Color(1.20, 0.65, 1.35, 1.0)
			custom_scale = 1.08
			base_health = 110.0
			armor = 2.0
			damage_per_hit = 10.0
		4: # Carmesí Sangre Salvaje (6-8 min)
			custom_tint = Color(1.40, 0.45, 0.45, 1.0)
			custom_scale = 1.22
			base_health = 240.0
			armor = 4.0
			damage_per_hit = 13.0
		5: # Azul Tormenta Enjambre Oscuro (8-10 min)
			custom_tint = Color(0.45, 0.75, 1.45, 1.0)
			custom_scale = 1.35
			base_health = 480.0
			armor = 7.0
			damage_per_hit = 16.0
		6: # Ámbar Dorado Mutante Élite (10-12 min)
			custom_tint = Color(1.45, 1.15, 0.35, 1.0)
			custom_scale = 1.45
			base_health = 950.0
			armor = 11.0
			damage_per_hit = 20.0
		_: # Esmeralda Tóxico Noxious (12+ min)
			custom_tint = Color(0.35, 1.45, 0.55, 1.0)
			custom_scale = 1.55
			base_health = 1800.0 + (t - 7) * 400.0
			armor = 16.0 + (t - 7) * 3.0
			damage_per_hit = 25.0
	current_health = base_health
	_apply_tier_visuals()

func _apply_tier_visuals() -> void:
	if sprite:
		sprite.modulate = custom_tint
		sprite.scale = Vector2(custom_scale, custom_scale)
	if shadow:
		shadow.scale = Vector2(custom_scale, custom_scale)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("zergling")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 18
	if shadow:
		var stex = SkinManager.get_sprite("zergling_shadow")
		if stex:
			shadow.texture = stex
		shadow.hframes = 17
		shadow.vframes = 17
		shadow.position = Vector2(0, 0)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if attack_timer > 0.0:
		attack_timer -= delta
	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
	else:
		is_attacking = false

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	
	# Enjambre natural: angulo de aproximacion personalizado sin bucle O(N^2)
	var angle_to_player = to_player.angle() + angle_jitter
	var move_dir = Vector2.from_angle(angle_to_player)
	
	# Despawnear o reposicionar si esta demasiado lejos (fuera de combate)
	if dist > 850.0:
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 450.0
		return
	
	const ATTACK_RANGE: float = 28.0
	
	if dist <= ATTACK_RANGE:
		if dist < 17.0:
			velocity = -to_player.normalized() * 12.0
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		_update_direction(to_player.normalized())
		if attack_timer <= 0.0:
			_attack_player()
	else:
		velocity = move_dir * move_speed
		move_and_slide()
		_update_direction(move_dir)

	_update_animation(delta, velocity.length() > 5.0)

func _update_direction(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var angle_sc = fposmod(dir.angle() + PI * 0.5, TAU)
	current_dir32 = int(round(angle_sc / (TAU / 32.0))) % 32
	if current_dir32 <= 16:
		facing_column = current_dir32
		is_facing_left = false
	else:
		facing_column = 32 - current_dir32
		is_facing_left = true

func _update_animation(delta: float, is_moving: bool) -> void:
	if is_attacking:
		# Animacion de ataque de garras y mordisco de SC1 (filas 8 a 12, 5 cuadros)
		var progress = clamp((0.35 - attack_anim_timer) / 0.35, 0.0, 0.99)
		var attack_sub = int(progress * 5.0)
		_set_sprite_frame((8 + attack_sub) * 17 + facing_column)
	elif is_moving:
		# Ciclo de carrera frenetica (filas 1..7, 7 cuadros)
		anim_timer += delta * 14.0
		var run_sub = int(anim_timer) % 7
		_set_sprite_frame((1 + run_sub) * 17 + facing_column)
	else:
		# Idle (fila 0)
		_set_sprite_frame(0 * 17 + facing_column)

func _set_sprite_frame(f: int) -> void:
	if sprite:
		sprite.frame = f
		sprite.flip_h = is_facing_left
	if shadow and shadow.vframes > 0:
		var col = f % 17
		var row = f / 17
		var s_row = mini(row, shadow.vframes - 1)
		shadow.frame = s_row * 17 + col
		shadow.flip_h = is_facing_left

func _attack_player() -> void:
	attack_timer = attack_cooldown
	is_attacking = true
	attack_anim_timer = 0.35
	if player and player.has_method("take_damage"):
		player.take_damage(damage_per_hit)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	var net_dmg = max(1.0, amount - armor)
	current_health -= net_dmg
	
	# Flash blanco de impacto restaurando el tinte de su tier
	if sprite:
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5, 1), 0.04)
		tw.tween_property(sprite, "modulate", custom_tint, 0.08)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	z_index = -2
	z_as_relative = false
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	
	AudioManager.play_sfx("zergling_death", 0.08, -1.0)
	GameManager.add_kill()
	GameManager.add_zergling_kill()
	
	# Soltar cristal de mineral (XP) con probabilidad 1/1000 de cristal arcoiris
	_drop_mineral()
	
	if shadow:
		shadow.visible = false
	
	# Restaurar animación de muerte auténtica de SC1 (frames 289 a 295 en zergling.png)
	if sprite:
		sprite.flip_h = is_facing_left
	
	var tw = create_tween()
	for f in range(289, 296):
		tw.tween_interval(0.04)
		tw.tween_callback(func():
			if sprite and is_instance_valid(sprite):
				sprite.frame = f
		)
	tw.tween_interval(0.05)
	tw.tween_callback(func():
		# Dejar restos / charco de sangre zerg pegados al suelo
		z_index = -2
		z_as_relative = false
		if sprite and is_instance_valid(sprite):
			sprite.z_index = -2
			sprite.z_as_relative = false
			var rem_tex = SkinManager.get_sprite("zergling_remains")
			if rem_tex:
				sprite.texture = rem_tex
				sprite.hframes = 5
				sprite.vframes = 1
				sprite.frame = randi() % 5
		_fade_out_corpse()
	)

func _drop_mineral() -> void:
	var mineral_scene = load("res://scenes/mineral.tscn")
	if mineral_scene:
		var m = mineral_scene.instantiate()
		m.global_position = global_position
		if randf() < 0.001:
			m.is_rainbow = true
		get_parent().call_deferred("add_child", m)

func _fade_out_corpse() -> void:
	var tw = create_tween()
	tw.tween_interval(1.2)
	tw.tween_property(sprite, "modulate:a", 0.0, 0.5)
	tw.tween_callback(queue_free)
