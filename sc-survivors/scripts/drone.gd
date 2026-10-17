class_name DroneEnemy
extends CharacterBody2D

@export var base_speed: float = 72.0
@export var base_health: float = 16.0
@export var damage_per_hit: float = 5.0
@export var attack_cooldown: float = 0.60

var current_health: float = 16.0
var move_speed: float = 72.0
var attack_timer: float = 0.0
var is_dead: bool = false
var angle_jitter: float = 0.0
var tier: int = 1
var armor: float = 0.0
var custom_tint: Color = Color.WHITE

func set_tier(t: int) -> void:
	tier = t
	var stats = WaveConfig.get_enemy_stats("drone", t)
	base_health = stats.get("health", 14.0)
	armor = stats.get("armor", 0.0)
	damage_per_hit = stats.get("damage", 4.0)
	base_speed = stats.get("speed", 72.0)
	move_speed = base_speed * randf_range(0.92, 1.10)
	custom_tint = stats.get("tint", Color.WHITE)
	current_health = base_health
	_apply_tier_visuals()

func _apply_tier_visuals() -> void:
	if sprite:
		sprite.modulate = custom_tint

var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	current_health = base_health
	move_speed = base_speed * randf_range(0.9, 1.1)
	_apply_tier_visuals()
	angle_jitter = randf_range(-0.4, 0.4)
	
	player = get_tree().get_first_node_in_group("player")
	
	# Gracia de ataque al nacer para evitar daño instantáneo al jugador
	attack_timer = randf_range(0.6, 0.9)
	
	_apply_skin()
	
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("drone")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 23
	if shadow:
		var tex = SkinManager.get_sprite("drone")
		if tex:
			shadow.texture = tex
		shadow.hframes = 17
		shadow.vframes = 23
		shadow.modulate = Color(0, 0, 0, 0.35)
		shadow.position = Vector2(0, 2)

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
	
	var angle_to_player = to_player.angle() + angle_jitter
	var move_dir = Vector2.from_angle(angle_to_player)
	
	if dist > 850.0:
		var edge = randi() % 4
		var rel_pos = Vector2.ZERO
		match edge:
			0: rel_pos = Vector2(randf_range(-580.0, 580.0), -360.0 - randf_range(0.0, 80.0))
			1: rel_pos = Vector2(randf_range(-580.0, 580.0), 360.0 + randf_range(0.0, 80.0))
			2: rel_pos = Vector2(-580.0 - randf_range(0.0, 80.0), randf_range(-340.0, 340.0))
			3: rel_pos = Vector2(580.0 + randf_range(0.0, 80.0), randf_range(-340.0, 340.0))
		global_position = player.global_position + rel_pos
		attack_timer = 0.8
		return
	
	const ATTACK_RANGE: float = 24.0
	
	if dist <= ATTACK_RANGE:
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
		# Animación de ataque en varias direcciones (filas 0..4 en drone.png)
		var progress = clamp((0.35 - attack_anim_timer) / 0.35, 0.0, 0.99)
		var attack_sub = int(progress * 5.0)
		_set_sprite_frame(attack_sub * 17 + facing_column)
	elif is_moving:
		# Ciclo de movimiento (filas 5..9, 5 frames)
		anim_timer += delta * 10.0
		var run_sub = int(anim_timer) % 5
		_set_sprite_frame((5 + run_sub) * 17 + facing_column)
	else:
		# Idle
		_set_sprite_frame(5 * 17 + facing_column)

func _set_sprite_frame(f: int) -> void:
	if sprite:
		sprite.frame = f
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = f
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
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2, 2, 2, 1), 0.04)
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
	
	AudioManager.play_sfx("drone_death", 0.08, -1.0)
	GameManager.add_kill()
	
	_drop_mineral()
	
	if shadow:
		shadow.visible = false
	
	# Animación auténtica de muerte del Drone (Columna 0 vertical, filas 10 a 17)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for r in range(10, 18):
		tw.tween_callback(func():
			if sprite and is_instance_valid(sprite):
				_set_sprite_frame(r * 17 + 0)
		)
		tw.tween_interval(0.05)
	tw.tween_callback(func():
		z_index = -2
		z_as_relative = false
		if sprite and is_instance_valid(sprite):
			sprite.z_index = -2
			sprite.z_as_relative = false
			var rem_tex = SkinManager.get_sprite("drone_remains")
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
