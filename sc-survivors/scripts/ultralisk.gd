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

var armor: float = 3.0

# Sistema de debuffs (Quemadura / Zumo de Limón)
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

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	current_health = base_health
	move_speed = base_speed
	player = get_tree().get_first_node_in_group("player")
	
	# Gracia de ataque al aparecer
	attack_timer = 1.0
	
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
	
	_process_debuffs(delta)
	
	var cur_speed = move_speed * (1.0 - lemon_slow_ratio if lemon_timer > 0.0 else 1.0)
	
	if dist > 34.0:
		velocity = move_dir * cur_speed
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
		return Color(1.5, 1.45, 0.25, 1.0)
	elif burn_timer > 0.0:
		return Color(1.6, 0.75, 0.25, 1.0)
	return Color.WHITE

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
			burn_fx.scale = Vector2(0.95, 0.95)
			burn_fx.position = Vector2(0, -12)
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
			lemon_fx.scale = Vector2(0.95, 0.95)
			lemon_fx.position = Vector2(0, -10)
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
		tw.tween_property(sprite, "modulate", Color(2.5, 1.2, 1.2, 1), 0.05)
		tw.tween_property(sprite, "modulate", target_tint, 0.08)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	if is_dead:
		return
	is_dead = true
	if burn_fx: burn_fx.visible = false
	if lemon_fx: lemon_fx.visible = false
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
