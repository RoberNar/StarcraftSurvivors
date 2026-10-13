class_name UltraliskBoss
extends CharacterBody2D

@export var base_speed: float = 85.0
@export var base_health: float = 550.0
@export var damage_per_hit: float = 24.0
@export var attack_cooldown: float = 0.75

var current_health: float = 550.0
var move_speed: float = 85.0
var attack_timer: float = 0.0
var is_dead: bool = false

# 32 angulos clasicos de StarCraft
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
var player: Node2D = null

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	current_health = base_health
	move_speed = base_speed
	player = get_tree().get_first_node_in_group("player")
	
	# Rugido amenazante de aparicion
	AudioManager.play_sfx("ultra_roar")
	
	_apply_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func set_mini_boss_scale(scale_val: float, hp_val: float, dmg_val: float) -> void:
	scale = Vector2(scale_val, scale_val)
	base_health = hp_val
	current_health = hp_val
	damage_per_hit = dmg_val

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("ultralisk")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 16

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
	var move_dir = to_player.normalized()
	
	if dist > 34.0:
		velocity = move_dir * move_speed
		move_and_slide()
		_update_direction(move_dir)
	else:
		velocity = Vector2.ZERO
		_update_direction(move_dir)
		if attack_timer <= 0.0:
			_attack_player()

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
		# Ataque con cuchillas Kaiser (filas 7..9)
		var attack_sub = int((0.45 - attack_anim_timer) * 9.0) % 3
		_set_sprite_frame((7 + attack_sub) * 17 + facing_column)
	elif is_moving:
		# Carrera pesada de Ultralisco (filas 1..6)
		anim_timer += delta * 10.0
		var run_sub = int(anim_timer) % 6
		_set_sprite_frame((1 + run_sub) * 17 + facing_column)
	else:
		# Idle (fila 0)
		_set_sprite_frame(0 * 17 + facing_column)

func _set_sprite_frame(f: int) -> void:
	if sprite:
		sprite.frame = clampi(f, 0, sprite.hframes * sprite.vframes - 1)
		sprite.flip_h = is_facing_left

func _attack_player() -> void:
	attack_timer = attack_cooldown
	is_attacking = true
	attack_anim_timer = 0.45
	AudioManager.play_sfx("ultra_attack")
	if player and player.has_method("take_damage"):
		player.take_damage(damage_per_hit)

func take_damage(amount: float) -> void:
	if is_dead:
		return
	current_health -= amount
	
	# Flash rojo/blanco de daño
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 1.2, 1.2, 1), 0.05)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.08)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	remove_from_group("enemies")
	remove_from_group("bosses")
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	
	AudioManager.play_sfx("ultra_death")
	GameManager.add_kill()
	GameManager.add_boss_kill()
	
	# DROPEAR COFRE DE RECOMPENSA MILITAR
	_drop_chest()
	
	# Animacion de muerte autentica de SC1 (ultralisk_death.png: 5 frames)
	var death_tex = SkinManager.get_sprite("ultralisk_death")
	if death_tex:
		sprite.texture = death_tex
		sprite.hframes = 5
		sprite.vframes = 1
		sprite.frame = 0
		sprite.flip_h = is_facing_left
	
	var tw = create_tween()
	for f in range(1, 5):
		tw.tween_interval(0.09)
		tw.tween_callback(func():
			if sprite and is_instance_valid(sprite):
				sprite.frame = f
		)
	tw.tween_interval(0.09)
	tw.tween_interval(1.5)
	tw.tween_property(sprite, "modulate:a", 0.0, 1.2)
	tw.tween_callback(queue_free)

func _drop_chest() -> void:
	var chest_scene = load("res://scenes/chest.tscn")
	if chest_scene:
		var c = chest_scene.instantiate()
		c.global_position = global_position
		get_parent().call_deferred("add_child", c)
	
	var vespene_scene = load("res://scenes/vespene_tank.tscn")
	if vespene_scene:
		for i in range(2):
			var v = vespene_scene.instantiate()
			var offset = Vector2(randf_range(-32, 32), randf_range(-32, 32))
			v.global_position = global_position + offset
			get_parent().call_deferred("add_child", v)
