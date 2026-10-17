class_name Hydralisk
extends CharacterBody2D

@export var base_speed: float = 78.0
@export var base_health: float = 65.0
@export var damage_per_hit: float = 12.0
@export var attack_cooldown: float = 0.65

var current_health: float = 65.0
var move_speed: float = 78.0
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

@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
var player: Node2D = null

var tier: int = 1
var armor: float = 0.0
var custom_tint: Color = Color(1, 1, 1, 1)
var custom_scale: float = 1.0

# Debuffs: Quemadura (Firebat) y Zumo de Limón (Easter Egg)
var burn_timer: float = 0.0
var burn_tick_timer: float = 0.0
var burn_dot_damage: float = 0.0
var burn_armor_shred: float = 0.0
var burn_fx: Sprite2D = null

var lemon_timer: float = 0.0
var lemon_tick_timer: float = 0.0
var lemon_dot_damage: float = 0.0
var lemon_slow_ratio: float = 0.0
var lemon_fx: Sprite2D = null

func set_tier(t: int) -> void:
	tier = t
	var stats = WaveConfig.get_enemy_stats("hydralisk", t)
	base_health = stats.get("health", 110.0)
	armor = stats.get("armor", 2.0)
	damage_per_hit = stats.get("damage", 12.0)
	base_speed = stats.get("speed", 80.0)
	move_speed = base_speed * randf_range(0.92, 1.10)
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
	move_speed = base_speed * randf_range(0.95, 1.1)
	angle_jitter = randf_range(-0.35, 0.35)
	
	player = get_tree().get_first_node_in_group("player")
	
	# Gracia de ataque al nacer para evitar daño instantáneo al jugador
	attack_timer = randf_range(0.6, 0.9)
	
	_apply_skin()
	_apply_tier_visuals()
	
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("hydralisk")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 18
	if shadow:
		var stex = SkinManager.get_sprite("hydralisk_shadow")
		if stex:
			shadow.texture = stex
		shadow.hframes = 17
		shadow.vframes = 18

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
	
	if dist > 900.0:
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
	
	const ATTACK_RANGE: float = 32.0
	
	_process_debuffs(delta)
	
	var cur_speed = move_speed
	if lemon_timer > 0.0:
		cur_speed *= (1.0 - lemon_slow_ratio)
	
	if dist <= ATTACK_RANGE:
		if dist < 18.0:
			velocity = -to_player.normalized() * 10.0
			move_and_slide()
		else:
			velocity = Vector2.ZERO
		_update_direction(to_player.normalized())
		if attack_timer <= 0.0:
			_attack_player()
	else:
		velocity = move_dir * cur_speed
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
		# Animación de ataque en varias direcciones (filas 0..4 en hydralisk.png)
		var progress = clamp((0.40 - attack_anim_timer) / 0.40, 0.0, 0.99)
		var attack_sub = int(progress * 5.0)
		_set_sprite_frame(attack_sub * 17 + facing_column)
	elif is_moving:
		# Ciclo de arrastre/movimiento (filas 5..11, 7 frames)
		anim_timer += delta * 11.0
		var run_sub = int(anim_timer) % 7
		_set_sprite_frame((5 + run_sub) * 17 + facing_column)
	else:
		# Idle
		_set_sprite_frame(5 * 17 + facing_column)

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
	attack_anim_timer = 0.40
	if player and player.has_method("take_damage"):
		player.take_damage(damage_per_hit)

func apply_burn(dot: float, duration: float, armor_shred: float) -> void:
	if is_dead: return
	burn_dot_damage = dot
	burn_armor_shred = armor_shred
	burn_timer = max(burn_timer, duration)
	_update_debuff_visuals()

func apply_lemon_juice(dot: float, duration: float, slow_ratio: float) -> void:
	if is_dead: return
	lemon_dot_damage = dot
	lemon_slow_ratio = slow_ratio
	lemon_timer = max(lemon_timer, duration)
	_update_debuff_visuals()

func _process_debuffs(delta: float) -> void:
	if is_dead: return
	
	if burn_timer > 0.0:
		burn_timer -= delta
		burn_tick_timer += delta
		if burn_tick_timer >= 0.35:
			burn_tick_timer = 0.0
			take_damage(burn_dot_damage)
		if burn_timer <= 0.0:
			_update_debuff_visuals()
			
	if lemon_timer > 0.0:
		lemon_timer -= delta
		lemon_tick_timer += delta
		if lemon_tick_timer >= 0.35:
			lemon_tick_timer = 0.0
			take_damage(lemon_dot_damage)
		if lemon_timer <= 0.0:
			_update_debuff_visuals()
			
	if burn_fx and burn_fx.visible:
		burn_fx.frame = int(Time.get_ticks_msec() / 70.0) % 12
	if lemon_fx and lemon_fx.visible:
		lemon_fx.frame = int(Time.get_ticks_msec() / 75.0) % 15

func _get_current_tint() -> Color:
	if lemon_timer > 0.0:
		return Color(1.5, 1.45, 0.25, 1.0) # Amarillo limón
	elif burn_timer > 0.0:
		return Color(1.6, 0.75, 0.25, 1.0) # Naranja quemado
	return custom_tint

func _update_debuff_visuals() -> void:
	if is_dead:
		if burn_fx: burn_fx.visible = false
		if lemon_fx: lemon_fx.visible = false
		return
		
	if burn_timer > 0.0:
		if not burn_fx:
			burn_fx = Sprite2D.new()
			burn_fx.texture = SkinManager.get_sprite("sc1_fire_loop")
			burn_fx.hframes = 12
			burn_fx.scale = Vector2(0.70, 0.70)
			burn_fx.position = Vector2(0, -10)
			burn_fx.z_index = 1
			add_child(burn_fx)
		burn_fx.visible = true
	elif burn_fx:
		burn_fx.visible = false

	if lemon_timer > 0.0:
		if not lemon_fx:
			lemon_fx = Sprite2D.new()
			lemon_fx.texture = SkinManager.get_sprite("lemon_ensnare")
			lemon_fx.hframes = 15
			lemon_fx.scale = Vector2(0.8, 0.8)
			lemon_fx.position = Vector2(0, -8)
			lemon_fx.z_index = 2
			add_child(lemon_fx)
		lemon_fx.visible = true
	elif lemon_fx:
		lemon_fx.visible = false

	if sprite:
		sprite.modulate = _get_current_tint()

func take_damage(amount: float) -> void:
	if is_dead:
		return
	var eff_armor = armor
	if burn_timer > 0.0:
		eff_armor = max(0.0, eff_armor - burn_armor_shred)
	var net_dmg = max(1.0, amount - eff_armor)
	current_health -= net_dmg
	
	if sprite:
		var target_tint = _get_current_tint()
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 2.5, 2.5, 1), 0.04)
		tw.tween_property(sprite, "modulate", target_tint, 0.08)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if burn_fx: burn_fx.visible = false
	if lemon_fx: lemon_fx.visible = false
	set_physics_process(false)
	z_index = -2
	z_as_relative = false
	remove_from_group("enemies")
	velocity = Vector2.ZERO
	$CollisionShape2D.set_deferred("disabled", true)
	
	AudioManager.play_sfx("hydra_death", 0.08, -1.0)
	GameManager.add_kill()
	
	_drop_mineral()
	
	if shadow:
		shadow.visible = false
	
	# Animación auténtica de muerte de SC1 (Fila 12 de hydralisk.png, columnas 0..7)
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for col in range(8):
		tw.tween_callback(func():
			if sprite and is_instance_valid(sprite):
				sprite.frame = 12 * 17 + col
		)
		tw.tween_interval(0.05)
	tw.tween_callback(func():
		z_index = -2
		z_as_relative = false
		if sprite and is_instance_valid(sprite):
			sprite.z_index = -2
			sprite.z_as_relative = false
			var rem_tex = SkinManager.get_sprite("hydralisk_remains")
			if rem_tex:
				sprite.texture = rem_tex
				sprite.hframes = 4
				sprite.vframes = 1
				sprite.frame = randi() % 4
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
