class_name Player
extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal stimpack_used(duration: float)
signal inventory_changed(weapons: Dictionary, passives: Dictionary)

# Stats base del Marine
@export var move_speed: float = 120.0
@export var max_health: float = 40.0
var current_health: float = 40.0
var health_regen: float = 0.0

# Multiplicadores porcentuales (afectan a TODAS las armas)
var damage_mult: float = 1.0
var fire_rate_mult: float = 1.0
var range_mult: float = 1.0
var aoe_mult: float = 1.0
var bullet_pierce: int = 1

# Stats del rifle Gauss C-14
@export var damage: float = 14.0
@export var fire_rate: float = 2.4 # Disparos por segundo
@export var attack_range: float = 145.0
@export var multishot: int = 1
@export var has_explosive: bool = false
@export var pickup_radius: float = 110.0
var armor: float = 1.0

# Mejoras separadas de Firebat
var firebat_power_lvl: int = 1 # Nivel de potencia (daño térmico gradual)
var firebat_streams: int = 1   # Cantidad de llamaradas simultáneas (abanico)

# Inventario (Max 3 armas, Max 6 pasivas infinitas)
var weapons: Dictionary = { "c14_rifle": 1 }
var passives: Dictionary = {}

# Modificadores de Stimpack
var stimpack_active: bool = false
var stimpack_timer: float = 0.0
var stimpack_duration: float = 5.0
var stimpack_cooldown: float = 8.0
var stimpack_cd_timer: float = 0.0

# Animacion y direccion 32 angulos clasica de StarCraft
var current_dir32: int = 8 # Empieza mirando al Este (Derecha)
var facing_column: int = 8
var is_facing_left: bool = false
var walk_frame_index: int = 0
var walk_anim_timer: float = 0.0
var fire_anim_timer: float = 0.0

# Temporizadores de armas
var fire_timer: float = 0.0
var flame_timer: float = 0.0
var mine_timer: float = 0.0
var sniper_timer: float = 0.0
var mutalisk_timer: float = 0.0
var storm_timer: float = 0.0
var lemon_timer: float = 0.0
var mineral_check_timer: float = 0.0

# Nodos
@onready var sprite: Sprite2D = $Sprite2D
@onready var shadow: Sprite2D = $Shadow
@onready var pickup_area: Area2D = $PickupArea
@onready var pickup_collision: CollisionShape2D = $PickupArea/CollisionShape2D
@onready var bubble: Panel = get_node_or_null("SpeechBubble")
@onready var bubble_label: Label = get_node_or_null("SpeechBubble/VBox/TextLabel")

@export var is_in_base: bool = false
var is_civilian_mode: bool = false
var is_dead: bool = false
var invuln_timer: float = 0.0

func show_bubble(text: String, duration: float = 3.0, voice_id: String = "") -> void:
	if not bubble or not bubble_label:
		return
	bubble_label.text = text
	bubble.visible = true
	var voice_dur = 0.0
	if voice_id != "" and has_node("/root/AudioManager"):
		voice_dur = AudioManager.play_voice(voice_id)
		if voice_dur > 0.0:
			duration = max(duration, voice_dur + 0.4)
	var tw = create_tween()
	tw.tween_interval(duration)
	tw.tween_callback(func():
		if is_instance_valid(bubble):
			bubble.visible = false
	)

func _ready() -> void:
	add_to_group("player")
	z_index = 5
	z_as_relative = false
	
	# Aplicar metaprogresión permanente de la Armería Terran
	if has_node("/root/SaveManager"):
		armor += SaveManager.get_stat_bonus("armor")
		move_speed *= (1.0 + SaveManager.get_stat_bonus("speed"))
		max_health *= (1.0 + SaveManager.get_stat_bonus("max_hp"))
		damage_mult *= (1.0 + SaveManager.get_stat_bonus("damage"))
		health_regen += SaveManager.get_stat_bonus("regen")
		pickup_radius *= (1.0 + SaveManager.get_stat_bonus("magnet"))
	
	# Aplicar mejoras iniciales permanentes de la Academia para la Run
	if has_node("/root/GameManager"):
		armor += GameManager.get_barracks_bonus("armor")
		max_health += GameManager.get_barracks_bonus("max_hp")
		damage_mult += GameManager.get_barracks_bonus("damage")
		move_speed *= (1.0 + GameManager.get_barracks_bonus("speed"))
		multishot += int(GameManager.get_barracks_bonus("multishot"))
		fire_rate_mult += GameManager.get_barracks_bonus("cadence")
		health_regen += GameManager.get_barracks_bonus("regen")
		pickup_radius *= (1.0 + GameManager.get_barracks_bonus("magnet"))
		stimpack_duration += GameManager.get_barracks_bonus("stim_dur")
		stimpack_cooldown = max(2.0, stimpack_cooldown - GameManager.get_barracks_bonus("stim_cd"))
	
	if not GameManager.has_suit_equipped:
		is_civilian_mode = true
		weapons.clear()
		max_health = 80.0
		current_health = 80.0
		armor = 0.0
	
	current_health = max_health
	emit_signal("health_changed", current_health, max_health)
	
	_apply_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)
	
	_update_pickup_shape()
	if is_civilian_mode:
		AudioManager.play_sfx("tcvrdy00")
	elif GameManager.selected_hero == "medic":
		AudioManager.play_sfx("medic_ready")
	else:
		AudioManager.play_sfx("marine_ready")
	call_deferred("_emit_initial_inventory")

func _emit_initial_inventory() -> void:
	emit_signal("inventory_changed", weapons, passives)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if is_civilian_mode:
		if sprite:
			var civ_tex = load("res://assets/skins/sd/sprites/civilian.png")
			if civ_tex: sprite.texture = civ_tex
			sprite.hframes = 17
			sprite.vframes = 8
		if shadow:
			var cshad_tex = load("res://assets/skins/sd/sprites/civilian_shadow.png")
			if cshad_tex: shadow.texture = cshad_tex
			shadow.hframes = 17
			shadow.vframes = 8
			shadow.position = Vector2(0, -6)
		return
	
	var is_medic = (GameManager.selected_hero == "medic")
	if sprite:
		var tex = SkinManager.get_sprite("medic") if is_medic else SkinManager.get_sprite("marine")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 14
	if shadow:
		var stex = SkinManager.get_sprite("medic_shadow") if is_medic else SkinManager.get_sprite("marine_shadow")
		if stex:
			shadow.texture = stex
		shadow.hframes = 17
		shadow.vframes = 14
		shadow.position = Vector2(0, 4)

func _physics_process(delta: float) -> void:
	if is_dead:
		return
	
	if invuln_timer > 0.0:
		invuln_timer -= delta
	
	# Regeneracion de vida
	if health_regen > 0.0 and current_health < max_health:
		current_health = min(max_health, current_health + health_regen * delta)
		emit_signal("health_changed", current_health, max_health)
	
	# Stimpack timer
	if stimpack_active:
		stimpack_timer -= delta
		if stimpack_timer <= 0.0:
			stimpack_active = false
	if stimpack_cd_timer > 0.0:
		stimpack_cd_timer -= delta

	# Movimiento WASD
	var input_vec = Vector2.ZERO
	input_vec.x = Input.get_axis("move_left", "move_right")
	input_vec.y = Input.get_axis("move_up", "move_down")
	input_vec = input_vec.normalized()
	
	var current_speed = move_speed * (1.4 if stimpack_active else 1.0)
	velocity = input_vec * current_speed
	move_and_slide()
	
	# Stimpack manual y disparo de armas solo fuera de base y con armadura
	var target = null
	if not is_in_base and not is_civilian_mode:
		if Input.is_action_just_pressed("stimpack") and not stimpack_active and stimpack_cd_timer <= 0.0:
			var can_stim = SaveManager.is_stimpack_unlocked() if has_node("/root/SaveManager") else (GameManager.barracks_upgrades.get("stim", 0) > 0)
			if can_stim:
				use_stimpack()
			else:
				show_bubble("Estimulante bloqueado: Requiere investigarse en la Academia", 2.2)
		target = _find_nearest_enemy()
		_process_weapons(delta, target)

	# Actualizar animacion y direccion
	if target and (fire_anim_timer > 0.0 or velocity.length() < 5.0):
		_update_direction((target.global_position - global_position).normalized())
	elif velocity.length() > 5.0:
		_update_direction(velocity.normalized())
	
	_update_animation(delta, velocity.length() > 5.0)
	if not is_in_base:
		_collect_minerals(delta)

func _process_weapons(delta: float, target: Node2D) -> void:
	var stim_rate = 1.6 if stimpack_active else 1.0
	
	# 1. Rifle Gauss C-14
	if weapons.has("c14_rifle"):
		var total_fire_rate = fire_rate * fire_rate_mult * stim_rate
		var fire_interval = 1.0 / max(0.1, total_fire_rate)
		fire_timer += delta
		if target and fire_timer >= fire_interval:
			fire_timer = 0.0
			_fire_c14(target)
	
	# 2. Lanza-llamas Firebat
	if weapons.has("firebat_flame"):
		var flame_interval = 1.8 / (fire_rate_mult * stim_rate)
		flame_timer += delta
		if flame_timer >= flame_interval:
			flame_timer = 0.0
			_fire_flame(target)
	
	# 3. Minas Araña
	if weapons.has("spider_mine"):
		var mine_interval = 4.0 / (fire_rate_mult * stim_rate)
		mine_timer += delta
		if mine_timer >= mine_interval:
			mine_timer = 0.0
			_deploy_spider_mine()
	
	# 4. Francotirador Ghost C-10
	if weapons.has("ghost_sniper"):
		var sniper_interval = 2.4 / (fire_rate_mult * stim_rate)
		sniper_timer += delta
		if target and sniper_timer >= sniper_interval:
			sniper_timer = 0.0
			_fire_ghost_sniper(target)

	# 5. Glave Wurm Mutalisco (Rebotes y proyectiles simultáneos)
	if weapons.has("mutalisk_glave"):
		var glave_interval = 1.3 / (fire_rate_mult * stim_rate)
		mutalisk_timer += delta
		if target and mutalisk_timer >= glave_interval:
			mutalisk_timer = 0.0
			_fire_glave_wurm(target)

	# 6. Tormenta Psiónica (Invocación errática en campo visual)
	if weapons.has("psionic_storm"):
		var storm_lvl = weapons.get("psionic_storm", 1)
		var storm_interval = max(1.8, 3.8 - (storm_lvl - 1) * 0.4) / (fire_rate_mult * stim_rate)
		storm_timer += delta
		if storm_timer >= storm_interval:
			storm_timer = 0.0
			_cast_psionic_storm()

	# 7. Zumo de Limón (Easter Egg - Limo Corrosivo)
	if weapons.has("lemon_juice"):
		var lemon_lvl = weapons.get("lemon_juice", 1)
		var lemon_interval = max(1.5, 3.2 - (lemon_lvl - 1) * 0.35) / (fire_rate_mult * stim_rate)
		lemon_timer += delta
		if lemon_timer >= lemon_interval:
			lemon_timer = 0.0
			_deploy_lemon_juice()

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
	if is_civilian_mode:
		if is_moving:
			walk_anim_timer += delta * 11.0
			var walk_subframe = int(walk_anim_timer) % 7 # 7 frames de caminata del civil
			_set_sprite_frame((1 + walk_subframe) * 17 + facing_column)
		else:
			walk_anim_timer = 0.0
			_set_sprite_frame(0 * 17 + facing_column)
		return
	
	var is_medic = (GameManager.selected_hero == "medic")
	if is_medic:
		if fire_anim_timer > 0.0:
			fire_anim_timer -= delta
			var heal_subframe = int((0.14 - fire_anim_timer) * 30.0) % 3
			_set_sprite_frame((3 + heal_subframe) * 17 + facing_column)
		elif is_moving:
			walk_anim_timer += delta * (14.0 if stimpack_active else 10.0)
			var walk_subframe = int(walk_anim_timer) % 7 # 7 filas de caminata de la Médica (filas 6 a 12)
			_set_sprite_frame((6 + walk_subframe) * 17 + facing_column)
		else:
			walk_anim_timer = 0.0
			_set_sprite_frame(0 * 17 + facing_column)
		return
	
	# Marine estándar
	if fire_anim_timer > 0.0:
		fire_anim_timer -= delta
		_set_sprite_frame(3 * 17 + facing_column)
	elif is_moving:
		walk_anim_timer += delta * (14.0 if stimpack_active else 10.0)
		var walk_subframe = int(walk_anim_timer) % 9
		_set_sprite_frame((4 + walk_subframe) * 17 + facing_column)
	else:
		walk_anim_timer = 0.0
		_set_sprite_frame(0 * 17 + facing_column)

func _set_sprite_frame(f: int) -> void:
	if sprite:
		sprite.frame = f
		sprite.flip_h = is_facing_left
	if shadow:
		shadow.frame = f
		shadow.flip_h = is_facing_left

func _find_nearest_enemy() -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist_sq = (attack_range * range_mult) * (attack_range * range_mult)
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and not ("is_destroyed" in e and e.is_destroyed):
			var d_sq = global_position.distance_squared_to(e.global_position)
			if d_sq < min_dist_sq:
				min_dist_sq = d_sq
				closest = e
	return closest

func _fire_c14(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	_update_direction(dir)
	fire_anim_timer = 0.14 if GameManager.selected_hero == "medic" else 0.09
	AudioManager.play_sfx("marine_fire", 0.08, -1.0)
	
	var bullet_scene = load("res://scenes/bullet.tscn")
	var count = max(1, multishot)
	var spread_step = 0.12
	var start_angle = - (count - 1) * spread_step * 0.5
	
	for i in range(count):
		var b = bullet_scene.instantiate()
		var spread_dir = dir.rotated(start_angle + i * spread_step)
		b.direction = spread_dir
		b.damage = damage * damage_mult
		b.max_range = (attack_range + 20.0) * range_mult
		b.has_explosive = has_explosive
		b.pierce_count = bullet_pierce
		b.scale = Vector2(1.0, 1.0) * aoe_mult
		b.global_position = global_position + dir * 14.0
		get_parent().add_child(b)

func _fire_flame(target: Node2D) -> void:
	var dir = velocity.normalized() if velocity.length() > 5.0 else Vector2.RIGHT
	if target and is_instance_valid(target):
		dir = (target.global_position - global_position).normalized()
	
	_update_direction(dir)
	AudioManager.play_sfx("flame_fire", 0.05, 1.0)
	
	var flame_scene = load("res://scenes/flame.tscn")
	var initial_dmg = 4.0 * damage_mult
	var dot_dmg = (2.0 + (firebat_power_lvl - 1) * 0.5) * damage_mult
	var armor_red = float(weapons.get("firebat_flame", 1))
	var aoe = 1.0 + (firebat_power_lvl - 1) * 0.10
	
	var total_streams = firebat_streams + (multishot - 1)
	var angles: Array[float] = [0.0]
	if total_streams == 2:
		angles = [-0.25, 0.25]
	elif total_streams == 3:
		angles = [-0.35, 0.0, 0.35]
	elif total_streams == 4:
		angles = [-0.4, -0.15, 0.15, 0.4]
	elif total_streams == 5:
		angles = [-0.5, -0.25, 0.0, 0.25, 0.5]
	elif total_streams >= 6:
		angles = [-0.6, -0.36, -0.12, 0.12, 0.36, 0.6]
	
	for ang in angles:
		var f = flame_scene.instantiate()
		var flame_dir = dir.rotated(ang)
		f.direction = flame_dir
		f.damage = initial_dmg
		f.dot_damage = dot_dmg
		f.armor_reduction = armor_red
		f.aoe_mult = aoe * aoe_mult
		f.scale = Vector2.ONE
		f.global_position = global_position + flame_dir * 8.0
		get_parent().add_child(f)

func _deploy_spider_mine() -> void:
	var mine_scene = load("res://scenes/spider_mine.tscn")
	var lvl = weapons.get("spider_mine", 1)
	var count = lvl + (multishot - 1)
	for i in range(count):
		var m = mine_scene.instantiate()
		m.damage = (75.0 + (lvl - 1) * 25.0) * damage_mult
		var offset = Vector2(randf_range(-22, 22), randf_range(-22, 22))
		m.global_position = global_position + offset
		get_parent().add_child(m)

func _fire_ghost_sniper(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	_update_direction(dir)
	fire_anim_timer = 0.12
	AudioManager.play_sfx("ghost_sniper", 0.05, 2.0)
	
	_spawn_sniper_target_fx(target, dir)
	
	var bullet_scene = load("res://scenes/bullet.tscn")
	if bullet_scene:
		var sniper_count = max(1, multishot)
		var spread_step = 0.08
		var start_angle = - (sniper_count - 1) * spread_step * 0.5
		for i in range(sniper_count):
			var b = bullet_scene.instantiate()
			b.is_sniper = true
			b.direction = dir.rotated(start_angle + i * spread_step)
			b.speed = 1200.0
			var lvl = weapons.get("ghost_sniper", 1)
			b.damage = (65.0 + (lvl - 1) * 25.0) * damage_mult
			b.max_range = 580.0
			b.pierce_count = 4 + lvl + (bullet_pierce - 1)
			b.modulate = Color(2.2, 0.4, 0.4, 1.0)
			b.scale = Vector2(1.6, 1.6) * aoe_mult
			b.global_position = global_position + dir * 16.0
			get_parent().add_child(b)

func _spawn_sniper_target_fx(target: Node2D, fire_dir: Vector2) -> void:
	var parent_node = get_parent()
	if not parent_node:
		return
	
	# 1. Haz láser supersónico instantáneo desde el arma que cruza al objetivo
	var laser_beam = Line2D.new()
	laser_beam.width = 3.0
	laser_beam.default_color = Color(1.0, 0.25, 0.25, 0.95)
	var end_pt = global_position + fire_dir * min(580.0, global_position.distance_to(target.global_position) + 160.0)
	laser_beam.points = PackedVector2Array([global_position + fire_dir * 18.0, end_pt])
	laser_beam.z_index = 25
	parent_node.add_child(laser_beam)
	
	var tw_laser = laser_beam.create_tween()
	tw_laser.tween_property(laser_beam, "width", 0.5, 0.22)
	tw_laser.parallel().tween_property(laser_beam, "modulate:a", 0.0, 0.22)
	tw_laser.tween_callback(laser_beam.queue_free)
	
	# 2. Retícula / Mira táctica militar que resalta exactamente al enemigo fijado
	if is_instance_valid(target):
		var reticle_script = load("res://scripts/sniper_target_reticle.gd")
		if reticle_script:
			var marker = Node2D.new()
			marker.global_position = target.global_position
			marker.set_script(reticle_script)
			marker.set("target_ref", target)
			parent_node.add_child(marker)

func _fire_glave_wurm(target: Node2D) -> void:
	var dir = (target.global_position - global_position).normalized()
	_update_direction(dir)
	AudioManager.play_sfx("mutalisk_fire", 0.08, -8.0)
	
	var glave_scene = load("res://scenes/glave_wurm.tscn")
	var lvl = weapons.get("mutalisk_glave", 1)
	var count = max(1, multishot)
	var spread_step = 0.18
	var start_angle = - (count - 1) * spread_step * 0.5
	
	for i in range(count):
		var g = glave_scene.instantiate()
		var spread_dir = dir.rotated(start_angle + i * spread_step)
		g.direction = spread_dir
		g.damage = (16.0 + (lvl - 1) * 6.0) * damage_mult
		g.speed = 340.0 + (lvl - 1) * 35.0
		g.bounces_left = 3 + (lvl - 1) * 2
		g.ricochet_radius = 230.0 * range_mult
		g.target_enemy = target
		g.scale = Vector2(1.0, 1.0) * aoe_mult
		g.global_position = global_position + spread_dir * 10.0
		get_parent().add_child(g)

func _cast_psionic_storm() -> void:
	var storm_scene = load("res://scenes/psionic_storm.tscn")
	if not storm_scene:
		return
	var lvl = weapons.get("psionic_storm", 1)
	var count = 1 + (1 if lvl >= 4 else 0)
	for i in range(count):
		var s = storm_scene.instantiate()
		s.damage_per_tick = (38.0 + (lvl - 1) * 14.0) * damage_mult
		s.duration = 2.2 + (lvl - 1) * 0.2
		var random_angle = randf_range(0.0, TAU)
		var random_dist = randf_range(110.0, 360.0)
		var spawn_pos = global_position + Vector2.from_angle(random_angle) * random_dist
		var target = _find_nearest_enemy()
		if target and is_instance_valid(target) and randf() < 0.65:
			var jitter = Vector2(randf_range(-85.0, 85.0), randf_range(-85.0, 85.0))
			spawn_pos = target.global_position + jitter
		s.global_position = spawn_pos
		s.scale = Vector2.ONE * aoe_mult
		get_parent().add_child(s)

func _deploy_lemon_juice() -> void:
	var lemon_scene = load("res://scenes/lemon_juice_explosion.tscn")
	if not lemon_scene:
		return
	var lvl = weapons.get("lemon_juice", 1)
	var lj = lemon_scene.instantiate()
	lj.splash_damage = (16.0 + (lvl - 1) * 6.0) * damage_mult
	lj.dot_damage = (8.0 + (lvl - 1) * 3.0) * damage_mult
	lj.slow_ratio = min(0.35, 0.10 + (lvl - 1) * 0.05)
	lj.duration = 0.65
	var offset = velocity.normalized() * 16.0 if velocity.length() > 5.0 else Vector2.ZERO
	lj.global_position = global_position + offset
	lj.scale = Vector2.ONE * (1.0 + (lvl - 1) * 0.12) * aoe_mult
	get_parent().add_child(lj)

func use_stimpack() -> void:
	if current_health <= 10.0:
		return
	
	current_health -= 10.0
	stimpack_active = true
	stimpack_timer = stimpack_duration
	stimpack_cd_timer = stimpack_cooldown
	emit_signal("health_changed", current_health, max_health)
	emit_signal("stimpack_used", stimpack_duration)
	
	if randf() > 0.5:
		AudioManager.play_sfx("marine_stim0")
	else:
		AudioManager.play_sfx("marine_stim1")
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(1.4, 0.6, 0.6, 1.0), 0.1)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.3)

func take_damage(amount: float) -> void:
	if is_dead or is_in_base:
		return
	
	var effective_damage = max(1.0, amount - armor)
	current_health = maxf(0.0, current_health - effective_damage)
	invuln_timer = 0.15
	emit_signal("health_changed", current_health, max_health)
	
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2, 2, 2, 1), 0.05)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1), 0.1)
	
	if current_health <= 0.0:
		current_health = 0.0
		if GameManager.is_leveling_up:
			GameManager.is_leveling_up = false
			get_tree().paused = false
		for hud in get_tree().get_nodes_in_group("hud"):
			if hud and hud.has_node("LevelUpPanel"):
				hud.get_node("LevelUpPanel").visible = false
		die()

func die() -> void:
	if is_dead:
		return
	
	# Si es la primera muerte en combate (con armadura CMC):
	# Evacuar de regreso a la base (HUB) donde el jugador despierta y ocurre el diálogo de resurrección
	if has_node("/root/SaveManager") and not SaveManager.has_experienced_first_death and not is_civilian_mode:
		_trigger_first_death_evacuation()
		return
	
	is_dead = true
	current_health = 0.0
	if GameManager.is_leveling_up:
		GameManager.is_leveling_up = false
		get_tree().paused = false
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud and hud.has_node("LevelUpPanel"):
			hud.get_node("LevelUpPanel").visible = false
	velocity = Vector2.ZERO
	
	if is_civilian_mode:
		var death_sfx = SkinManager.get_sfx("tcvdth00")
		if death_sfx:
			AudioManager.play_sfx("tcvdth00")
		else:
			AudioManager.play_sfx("marine_death1")
		
		var tw_civ = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw_civ.tween_property(sprite, "modulate", Color(2.0, 0.3, 0.3, 1.0), 0.1)
		tw_civ.tween_property(sprite, "modulate", Color(0.2, 0.2, 0.2, 0.0), 0.6)
		tw_civ.tween_callback(func():
			if shadow: shadow.visible = false
			GameManager.game_over()
		)
		return
	
	if GameManager.selected_hero == "medic":
		AudioManager.play_sfx("medic_death")
	elif randf() > 0.5:
		AudioManager.play_sfx("marine_death0")
	else:
		AudioManager.play_sfx("marine_death1")
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for f in range(221, 229):
		tw.tween_callback(func(): sprite.frame = f)
		tw.tween_interval(0.06)
	tw.tween_callback(func():
		sprite.texture = SkinManager.get_sprite("marine_remains")
		sprite.hframes = 3
		sprite.vframes = 1
		sprite.frame = randi() % 3
		if shadow: shadow.visible = false
		GameManager.game_over()
	)

func _trigger_first_death_evacuation() -> void:
	SaveManager.first_death_dialogue_pending = true
	SaveManager.has_experienced_first_death = true
	SaveManager.has_seen_first_death_cinematic = true
	SaveManager.save_data()
	
	is_dead = true
	current_health = 0.0
	if GameManager.is_leveling_up:
		GameManager.is_leveling_up = false
		get_tree().paused = false
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud and hud.has_node("LevelUpPanel"):
			hud.get_node("LevelUpPanel").visible = false
	velocity = Vector2.ZERO
	
	if randf() > 0.5:
		AudioManager.play_sfx("marine_death0")
	else:
		AudioManager.play_sfx("marine_death1")
	
	var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	for f in range(221, 229):
		tw.tween_callback(func(): sprite.frame = f)
		tw.tween_interval(0.06)
	tw.tween_callback(func():
		sprite.texture = SkinManager.get_sprite("marine_remains")
		sprite.hframes = 3
		sprite.vframes = 1
		sprite.frame = randi() % 3
		if shadow: shadow.visible = false
	)
	
	# Transición suave con fundido a negro y retorno automático al campamento base (HUB)
	tw.tween_interval(0.6)
	tw.tween_callback(func():
		ScreenFade.fade_out_in(0.8, 0.3, 0.8, func():
			get_tree().paused = false
			GameManager.evacuate_to_base()
		)
	)

func _collect_minerals(delta: float) -> void:
	mineral_check_timer += delta
	if mineral_check_timer < 0.08:
		return
	mineral_check_timer = 0.0
	
	var minerals = get_tree().get_nodes_in_group("collectibles")
	var r_sq = pickup_radius * pickup_radius
	for m in minerals:
		if is_instance_valid(m) and global_position.distance_squared_to(m.global_position) <= r_sq:
			m.attract_to(self)

func _update_pickup_shape() -> void:
	if pickup_collision and pickup_collision.shape is CircleShape2D:
		pickup_collision.shape.radius = pickup_radius

func apply_upgrade(type: String) -> void:
	# Armas adicionales
	if type == "c14_rifle":
		weapons["c14_rifle"] = weapons.get("c14_rifle", 0) + 1
		multishot += 1
	elif type == "firebat_flame":
		weapons["firebat_flame"] = 1
		firebat_power_lvl = 1
		firebat_streams = 1
	elif type == "firebat_power":
		firebat_power_lvl += 1
		weapons["firebat_flame"] = max(weapons.get("firebat_flame", 1), firebat_power_lvl)
	elif type == "firebat_streams":
		firebat_streams += 1
		weapons["firebat_flame"] = max(weapons.get("firebat_flame", 1), firebat_streams)
	elif type == "spider_mine":
		weapons["spider_mine"] = weapons.get("spider_mine", 0) + 1
	elif type == "ghost_sniper":
		weapons["ghost_sniper"] = weapons.get("ghost_sniper", 0) + 1
	elif type == "mutalisk_glave":
		weapons["mutalisk_glave"] = weapons.get("mutalisk_glave", 0) + 1
	elif type == "psionic_storm":
		weapons["psionic_storm"] = weapons.get("psionic_storm", 0) + 1
	elif type == "lemon_juice":
		weapons["lemon_juice"] = weapons.get("lemon_juice", 0) + 1
	
	# Mejoras Pasivas (escalado porcentual acumulativo infinito)
	elif type == "u238_shells":
		passives["u238_shells"] = passives.get("u238_shells", 0) + 1
		damage_mult += 0.15 # +15% de daño a todo
		range_mult += 0.10
		bullet_pierce += 1  # Balas perforantes U-238 atraviesan +1 enemigo
	elif type == "combat_shield":
		passives["combat_shield"] = passives.get("combat_shield", 0) + 1
		var hp_boost = max_health * 0.25 # +25% de vida máxima porcentual
		max_health += hp_boost
		current_health = min(max_health, current_health + hp_boost)
		emit_signal("health_changed", current_health, max_health)
	elif type == "cadence":
		passives["cadence"] = passives.get("cadence", 0) + 1
		fire_rate_mult += 0.20 # +20% velocidad de ataque a todas las armas
	elif type == "multishot":
		passives["multishot"] = passives.get("multishot", 0) + 1
		multishot += 1
	elif type == "stimpack_upgrade":
		passives["stimpack_upgrade"] = passives.get("stimpack_upgrade", 0) + 1
		move_speed += move_speed * 0.12 # +12% velocidad de movimiento porcentual
		stimpack_duration += 1.0
	elif type == "explosive_rounds":
		passives["explosive_rounds"] = passives.get("explosive_rounds", 0) + 1
		has_explosive = true
		damage_mult += 0.10
		aoe_mult += 0.25 # +25% tamaño de balas y área de efecto general
	elif type == "magnetic_field":
		passives["magnetic_field"] = passives.get("magnetic_field", 0) + 1
		pickup_radius += pickup_radius * 0.30 # +30% radio de atracción porcentual
		_update_pickup_shape()
	elif type == "medikit":
		passives["medikit"] = passives.get("medikit", 0) + 1
		health_regen += max(1.0, max_health * 0.03) # +3% de salud máxima/seg
		var heal_amount = max_health * 0.20 # Cura el 20% de salud inmediata
		current_health = min(max_health, current_health + heal_amount)
		emit_signal("health_changed", current_health, max_health)
	
	emit_signal("inventory_changed", weapons, passives)
