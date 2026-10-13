class_name Mutalisk
extends CharacterBody2D

@export var base_speed: float = 115.0
@export var base_health: float = 42.0
@export var damage_per_hit: float = 9.0
@export var attack_cooldown: float = 0.50

var current_health: float = 42.0
var move_speed: float = 115.0
var attack_timer: float = 0.0
var is_dead: bool = false
var angle_jitter: float = 0.0

# 32 angulos StarCraft
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
var player: Node2D = null

var tier: int = 1
var armor: float = 0.0
var custom_tint: Color = Color(1, 1, 1, 1)
var custom_scale: float = 1.0

func set_tier(t: int) -> void:
	tier = t
	match t:
		1: # Clásico púrpura / café
			custom_tint = Color(1.0, 0.95, 0.95, 1.0)
			custom_scale = 1.0
			base_health = 85.0
			armor = 1.0
			damage_per_hit = 9.0
		2: # Carmesí Voraz
			custom_tint = Color(1.40, 0.45, 0.45, 1.0)
			custom_scale = 1.15
			base_health = 220.0
			armor = 4.0
			damage_per_hit = 13.0
		3: # Azul Tormenta
			custom_tint = Color(0.45, 0.75, 1.45, 1.0)
			custom_scale = 1.30
			base_health = 550.0
			armor = 8.0
			damage_per_hit = 18.0
		4: # Ámbar Titán
			custom_tint = Color(1.45, 1.15, 0.35, 1.0)
			custom_scale = 1.45
			base_health = 1100.0
			armor = 14.0
			damage_per_hit = 24.0
		_: # Esmeralda Noxious
			custom_tint = Color(0.35, 1.45, 0.55, 1.0)
			custom_scale = 1.60
			base_health = 2200.0 + (t - 5) * 450.0
			armor = 18.0 + (t - 5) * 4.0
			damage_per_hit = 30.0
	current_health = base_health
	if sprite:
		sprite.modulate = custom_tint
		sprite.scale = Vector2(custom_scale, custom_scale)
	if shadow:
		shadow.scale = Vector2(custom_scale, custom_scale)

func _ready() -> void:
	add_to_group("enemies")
	current_health = base_health
	move_speed = base_speed * randf_range(0.95, 1.15)
	angle_jitter = randf_range(-0.4, 0.4)
	
	player = get_tree().get_first_node_in_group("player")
	_apply_skin()
	
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("mutalisk")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 5
	if shadow:
		var tex = SkinManager.get_sprite("mutalisk")
		if tex:
			shadow.texture = tex
		shadow.hframes = 17
		shadow.vframes = 5
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.40)
		shadow.position = Vector2(0, 18)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if attack_timer > 0.0:
		attack_timer -= delta

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()
	
	var angle_to_player = to_player.angle() + angle_jitter
	var move_dir = Vector2.from_angle(angle_to_player)
	
	if dist > 950.0:
		global_position = player.global_position + Vector2.from_angle(randf() * TAU) * 480.0
		return
	
	const ATTACK_RANGE: float = 28.0
	
	if dist <= ATTACK_RANGE:
		velocity = Vector2.ZERO
		_update_direction(to_player.normalized())
		if attack_timer <= 0.0:
			_attack_player()
	else:
		velocity = move_dir * move_speed
		move_and_slide()
		_update_direction(move_dir)

	_update_animation(delta)

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

func _update_animation(delta: float) -> void:
	# Ciclo continuo de aleteo aéreo de 5 cuadros (filas 0..4)
	anim_timer += delta * 12.0
	var flap_row = int(anim_timer) % 5
	var frame_idx = flap_row * 17 + facing_column
	
	if sprite:
		sprite.frame = frame_idx
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = frame_idx
		shadow.flip_h = is_facing_left

func _attack_player() -> void:
	attack_timer = attack_cooldown
	if player and player.has_method("take_damage"):
		player.take_damage(damage_per_hit)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	var net_dmg = max(1.0, amount - armor)
	current_health -= net_dmg
	
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
	
	AudioManager.play_sfx("muta_death", 0.08, -1.0)
	GameManager.add_kill()
	
	_drop_mineral()
	
	if shadow:
		shadow.visible = false
	
	# Explosion aerea autentica de SC1 (zerg_air_explosion: 9 frames)
	var explo_tex = SkinManager.get_sprite("zerg_air_explosion")
	if explo_tex:
		sprite.texture = explo_tex
		sprite.hframes = 9
		sprite.vframes = 1
		sprite.frame = 0
		sprite.scale = Vector2(1.5, 1.5)
	
	var tw = create_tween()
	for f in range(1, 9):
		tw.tween_interval(0.04)
		tw.tween_callback(func():
			if sprite and is_instance_valid(sprite):
				sprite.frame = f
		)
	tw.tween_interval(0.04)
	tw.tween_callback(queue_free)

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
	tw.tween_interval(3.5)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.5)
	tw.tween_callback(queue_free)
