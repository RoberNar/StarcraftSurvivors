class_name Scourge
extends CharacterBody2D

@export var base_speed: float = 185.0
@export var base_health: float = 32.0
@export var damage_on_impact: float = 30.0

var current_health: float = 32.0
var move_speed: float = 185.0
var is_dead: bool = false
var has_screeched: bool = false
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

# Debuffs
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
var burn_dot_damage: float = 0.0
var burn_armor_shred: float = 0.0

var lemon_timer: float = 0.0
var lemon_tick_timer: float = 0.0
var lemon_dot_damage: float = 0.0
var lemon_slow_ratio: float = 0.0

func set_tier(t: int) -> void:
	tier = t
	var stats = WaveConfig.get_enemy_stats("scourge", t)
	base_health = stats.get("health", 32.0)
	armor = stats.get("armor", 0.0)
	damage_on_impact = stats.get("damage", 30.0)
	base_speed = stats.get("speed", 185.0)
	move_speed = base_speed * randf_range(0.95, 1.10)
	custom_scale = stats.get("scale", 1.0)
	custom_tint = stats.get("tint", Color.WHITE)
	current_health = base_health
	_apply_tier_visuals()

func _apply_tier_visuals() -> void:
	if sprite:
		sprite.modulate = custom_tint
		sprite.scale = Vector2(custom_scale, custom_scale)
	if shadow:
		shadow.scale = Vector2(custom_scale, custom_scale)

func _ready() -> void:
	add_to_group("enemies")
	current_health = base_health
	move_speed = base_speed * randf_range(0.95, 1.10)
	angle_jitter = randf_range(-0.15, 0.15)
	player = get_tree().get_first_node_in_group("player")
	
	_apply_skin()
	_apply_tier_visuals()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("scourge")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 5
	if shadow:
		var tex = SkinManager.get_sprite("scourge_shadow")
		if tex:
			shadow.texture = tex
		shadow.hframes = 17
		shadow.vframes = 5
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.40)
		shadow.position = Vector2(0, 14)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > 1050.0:
		var edge = randi() % 4
		var rel_pos = Vector2.ZERO
		match edge:
			0: rel_pos = Vector2(randf_range(-580.0, 580.0), -360.0 - randf_range(0.0, 80.0))
			1: rel_pos = Vector2(randf_range(-580.0, 580.0), 360.0 + randf_range(0.0, 80.0))
			2: rel_pos = Vector2(-580.0 - randf_range(0.0, 80.0), randf_range(-340.0, 340.0))
			3: rel_pos = Vector2(580.0 + randf_range(0.0, 80.0), randf_range(-340.0, 340.0))
		global_position = player.global_position + rel_pos
		return

	if dist < 320.0 and not has_screech_played():
		has_screeched = true
		AudioManager.play_sfx("scourge_charge", 0.1, -1.0)

	_process_debuffs(delta)

	# Si alcanza al jugador: Detonación Suicida
	const EXPLODE_DIST: float = 24.0
	if dist <= EXPLODE_DIST:
		_explode_on_player()
		return

	var angle_to_player = to_player.angle() + angle_jitter
	var move_dir = Vector2.from_angle(angle_to_player)
	var cur_speed = move_speed * (1.0 - lemon_slow_ratio if lemon_timer > 0.0 else 1.0)

	velocity = move_dir * cur_speed
	move_and_slide()
	_update_direction(move_dir)
	_update_animation(delta)

func has_screech_played() -> bool:
	return has_screeched

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
	# Aleteo rapido constante de 5 cuadros
	anim_timer += delta * 18.0
	var flap_row = int(anim_timer) % 5
	var frame_idx = flap_row * 17 + facing_column
	if sprite:
		sprite.frame = frame_idx
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = frame_idx
		shadow.flip_h = is_facing_left

func _explode_on_player() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	AudioManager.play_sfx("scourge_explode", 0.08, 1.0)
	if player and player.has_method("take_damage"):
		player.take_damage(damage_on_impact)

	if shadow:
		shadow.visible = false

	# Animacion de explosion (scourge_explo.png, 9 frames 48x48)
	var explo_tex = SkinManager.get_sprite("scourge_explo")
	if explo_tex and sprite:
		sprite.texture = explo_tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0
		sprite.scale = Vector2(1.4, 1.4)
		var tw = create_tween()
		for f in range(1, 9):
			tw.tween_interval(0.035)
			tw.tween_callback(func():
				if sprite and is_instance_valid(sprite):
					sprite.frame = f
			)
		tw.tween_interval(0.035)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	var eff_armor = maxf(0.0, armor - burn_armor_shred)
	var dmg = maxf(1.0, amount - eff_armor)
	current_health -= dmg

	if sprite:
		var target_tint = custom_tint
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5, 1), 0.04)
		tw.tween_property(sprite, "modulate", target_tint, 0.08)

	if current_health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	set_physics_process(false)
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)

	AudioManager.play_sfx("scourge_death", 0.08, -1.0)
	GameManager.add_kill()

	_drop_mineral()

	if shadow:
		shadow.visible = false

	var explo_tex = SkinManager.get_sprite("scourge_explo")
	if explo_tex and sprite:
		sprite.texture = explo_tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0
		sprite.scale = Vector2(1.2, 1.2)
		var tw = create_tween()
		for f in range(1, 9):
			tw.tween_interval(0.035)
			tw.tween_callback(func():
				if sprite and is_instance_valid(sprite):
					sprite.frame = f
			)
		tw.tween_interval(0.035)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _drop_mineral() -> void:
	var mineral_scene = load("res://scenes/mineral.tscn")
	if mineral_scene:
		var m = mineral_scene.instantiate()
		m.global_position = global_position
		if randf() < 0.001:
			m.is_rainbow = true
		get_parent().call_deferred("add_child", m)

func apply_burn(dot: float, duration: float, armor_shred_val: float) -> void:
	if is_dead: return
	burn_dot_damage = dot
	burn_armor_shred = armor_shred_val
	burn_timer = max(burn_timer, duration)

func apply_lemon_juice(dot: float, duration: float, slow_ratio: float) -> void:
	if is_dead: return
	lemon_dot_damage = dot
	lemon_slow_ratio = slow_ratio
	lemon_timer = max(lemon_timer, duration)

func _process_debuffs(delta: float) -> void:
	if is_dead: return
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= 0.35:
			burn_tick_timer = 0.0
			take_damage(burn_dot_damage)
	if lemon_timer > 0.0:
		lemon_timer -= delta
		lemon_tick_timer += delta
		if lemon_tick_timer >= 0.35:
			lemon_tick_timer = 0.0
			take_damage(lemon_dot_damage)
