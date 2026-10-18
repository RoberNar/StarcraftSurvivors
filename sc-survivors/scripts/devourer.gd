class_name DevourerEnemy
extends CharacterBody2D

@export var base_speed: float = 75.0
@export var base_health: float = 520.0
@export var damage_per_spit: float = 18.0
@export var attack_cooldown: float = 2.4

var current_health: float = 520.0
var move_speed: float = 75.0
var attack_timer: float = 1.0
var is_dead: bool = false
var is_attacking: bool = false
var attack_anim_timer: float = 0.0

# 32 angulos StarCraft
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
var player: Node2D = null

var tier: int = 1
var armor: float = 3.0
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
	var stats = WaveConfig.get_enemy_stats("devourer", t)
	base_health = stats.get("health", 520.0)
	armor = stats.get("armor", 3.0)
	damage_per_spit = stats.get("damage", 18.0)
	base_speed = stats.get("speed", 75.0)
	move_speed = base_speed * randf_range(0.95, 1.05)
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
	move_speed = base_speed * randf_range(0.95, 1.05)
	player = get_tree().get_first_node_in_group("player")
	attack_timer = randf_range(0.8, 1.6)
	
	_apply_skin()
	_apply_tier_visuals()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("devourer")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 10
	if shadow:
		var tex = SkinManager.get_sprite("devourer_shadow")
		if tex:
			shadow.texture = tex
		shadow.hframes = 17
		shadow.vframes = 10
		shadow.modulate = Color(0.0, 0.0, 0.0, 0.40)
		shadow.position = Vector2(0, 22)

func _physics_process(delta: float) -> void:
	if is_dead:
		return

	if attack_timer > 0.0:
		attack_timer -= delta

	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
		if attack_anim_timer <= 0.0:
			is_attacking = false

	if player == null or not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player = player.global_position - global_position
	var dist = to_player.length()

	if dist > 1100.0:
		var edge = randi() % 4
		var rel_pos = Vector2.ZERO
		match edge:
			0: rel_pos = Vector2(randf_range(-580.0, 580.0), -360.0 - randf_range(0.0, 80.0))
			1: rel_pos = Vector2(randf_range(-580.0, 580.0), 360.0 + randf_range(0.0, 80.0))
			2: rel_pos = Vector2(-580.0 - randf_range(0.0, 80.0), randf_range(-340.0, 340.0))
			3: rel_pos = Vector2(580.0 + randf_range(0.0, 80.0), randf_range(-340.0, 340.0))
		global_position = player.global_position + rel_pos
		return

	_process_debuffs(delta)

	const DESIRED_DISTANCE: float = 200.0
	var move_dir = Vector2.ZERO
	var cur_speed = move_speed * (1.0 - lemon_slow_ratio if lemon_timer > 0.0 else 1.0)

	if dist > DESIRED_DISTANCE + 30.0:
		move_dir = to_player.normalized()
		velocity = move_dir * cur_speed
		move_and_slide()
		_update_direction(move_dir)
	elif dist < DESIRED_DISTANCE - 30.0:
		move_dir = -to_player.normalized()
		velocity = move_dir * cur_speed * 0.6
		move_and_slide()
		_update_direction(-move_dir)
	else:
		velocity = Vector2.ZERO
		_update_direction(to_player.normalized())

	if dist <= 290.0 and attack_timer <= 0.0 and not is_attacking:
		_spit_acid()

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
	anim_timer += delta * 9.0
	var flap_row = int(anim_timer) % 10
	var frame_idx = flap_row * 17 + facing_column
	if sprite:
		sprite.frame = frame_idx
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = frame_idx
		shadow.flip_h = is_facing_left

func _spit_acid() -> void:
	if is_dead: return
	attack_timer = attack_cooldown
	is_attacking = true
	attack_anim_timer = 0.4

	AudioManager.play_sfx("devourer_attack", 0.08, 0.0)

	var proj_scene = load("res://scenes/devourer_acid_projectile.tscn")
	if proj_scene and player:
		var p = proj_scene.instantiate() as DevourerAcidProjectile
		if p:
			var start_pos = global_position + Vector2(0, 8)
			p.setup(start_pos, player.global_position, damage_per_spit)
			get_parent().add_child(p)

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

	AudioManager.play_sfx("devourer_death", 0.08, 0.0)
	GameManager.add_kill()

	_drop_mineral()

	if shadow:
		shadow.visible = false

	var explo_tex = SkinManager.get_sprite("zerg_air_explosion")
	if explo_tex and sprite:
		sprite.texture = explo_tex
		sprite.hframes = 9
		sprite.vframes = 1
		sprite.frame = 0
		sprite.scale = Vector2(2.4, 2.4)
		var tw = create_tween()
		for f in range(1, 9):
			tw.tween_interval(0.045)
			tw.tween_callback(func():
				if sprite and is_instance_valid(sprite):
					sprite.frame = f
			)
		tw.tween_interval(0.045)
		tw.tween_callback(queue_free)
	else:
		queue_free()

func _drop_mineral() -> void:
	var mineral_scene = load("res://scenes/mineral.tscn")
	if mineral_scene:
		for i in range(3):
			var m = mineral_scene.instantiate()
			m.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-16, 16))
			if randf() < 0.005:
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
