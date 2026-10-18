class_name TorrasqueBoss
extends CharacterBody2D

signal health_changed(current_bar_hp: float, max_bar_hp: float, bars_remaining: int)
signal armor_heat_changed(current_heat: float, max_heat: float)
signal state_changed(state_name: String)
signal charge_cast_started(duration: float)
signal charge_launched()
signal stunned(duration: float)
signal recovered()
signal died()

enum State {
	INTRO,
	CHASE,
	TELEGRAPH_CHARGE,
	CHARGING,
	STUNNED,
	RECOVERING,
	DEAD
}

# 6 Barras de vida
const TOTAL_HEALTH_BARS: int = 6
const BAR_MAX_HEALTH: float = 2200.0
var health_bars_remaining: int = 6
var current_bar_health: float = 2200.0

# Armadura y Sobrecalentamiento
var is_armored: bool = true
var armor_heat: float = 0.0
const MAX_ARMOR_HEAT: float = 1000.0

# Velocidades y Daño
@export var base_speed: float = 85.0
var current_speed: float = 85.0
@export var charge_speed: float = 460.0
@export var melee_damage: float = 24.0
@export var charge_damage: float = 999990.0
var attack_cooldown_timer: float = 0.0
const ATTACK_COOLDOWN: float = 0.75
const MELEE_RANGE: float = 85.0

var current_state: State = State.INTRO
var state_timer: float = 0.0

# Casteo de embestida (3 segundos siguiendo al jugador)
const CHARGE_CAST_TIME: float = 3.0
var charge_cast_timer: float = 0.0
var charge_target_pos: Vector2 = Vector2.ZERO
var charge_direction: Vector2 = Vector2.DOWN
var charge_distance_travelled: float = 0.0
var max_charge_distance: float = 900.0

# Aturdimiento
var stun_timer: float = 0.0
const STUN_DURATION: float = 6.0

# Fase 2: Enrage & Destrucción de Rocas
var is_enraged: bool = false
var is_final_phase1_stun: bool = false
var enraged_charge_timer: float = 6.0

# Animación (32 ángulos clásicos de StarCraft)
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0
var attack_anim_timer: float = 0.0
var is_attacking: bool = false

# Nodos
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var telegraph_line: Line2D = $TelegraphLine
@onready var stun_indicator: Node2D = $StunIndicator
@onready var stun_stars_sprite: Sprite2D = get_node_or_null("StunIndicator/StarsSprite")
@onready var charge_particles: CPUParticles2D = get_node_or_null("ChargeParticles")

var player: Player = null

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
	
	health_bars_remaining = TOTAL_HEALTH_BARS
	current_bar_health = BAR_MAX_HEALTH
	armor_heat = 0.0
	is_armored = true
	current_speed = base_speed
	
	_apply_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)
	
	if telegraph_line:
		telegraph_line.visible = false
	if stun_indicator:
		stun_indicator.top_level = true
		stun_indicator.visible = false
	
	_enter_intro()

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if sprite:
		var tex = SkinManager.get_sprite("ultralisk")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 16
		scale = Vector2(1.5, 1.5)
	
	if stun_stars_sprite:
		var stex = SkinManager.get_sprite("stun_stars")
		if stex:
			stun_stars_sprite.texture = stex
		stun_stars_sprite.hframes = 32

func _enter_intro() -> void:
	current_state = State.INTRO
	velocity = Vector2.ZERO
	state_changed.emit("¡EMERGENCIA DEL TORRASQUE!")
	
	modulate = Color(1.4, 1.2, 1.2, 1.0)
	scale = Vector2(1.5, 1.5)
	_update_direction(Vector2.DOWN)
	_set_sprite_frame(facing_column)
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.6).from(Vector2(0.8, 0.8))
	tw.parallel().tween_property(self, "modulate", Color(1, 1, 1, 1), 0.6)

func start_fight() -> void:
	if current_state == State.DEAD:
		return
	_enter_chase()

func _enter_chase() -> void:
	current_state = State.CHASE
	current_speed = 85.0
	state_changed.emit("PERSIGUIENDO (ARMADURA ACTIVA)")
	_update_armor_visuals()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	_process_debuffs(delta)
	
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player") as Player
	
	match current_state:
		State.INTRO:
			velocity = Vector2.ZERO
			_update_direction(Vector2.DOWN)
			_set_sprite_frame(facing_column)
			# Permanece completamente inmóvil hasta que termine la cinemática de cámara
		State.CHASE:
			_process_chase(delta)
		State.TELEGRAPH_CHARGE:
			_process_telegraph(delta)
		State.CHARGING:
			_process_charging(delta)
		State.STUNNED:
			_process_stunned(delta)
		State.RECOVERING:
			pass

func _process_chase(delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	if is_enraged:
		# Enrage: Cargas periódicas rápidas hacia el jugador para demoler el perímetro
		enraged_charge_timer -= delta
		if enraged_charge_timer <= 0.0:
			_start_enraged_charge_cast()
			return
	else:
		# Fase 1: Acumulación continua de furia / calor de armadura (carga garantizada aun sin disparos)
		armor_heat = min(MAX_ARMOR_HEAT, armor_heat + delta * 18.0)
		armor_heat_changed.emit(armor_heat, MAX_ARMOR_HEAT)
		_update_armor_visuals()
		if armor_heat >= MAX_ARMOR_HEAT:
			_start_charge_cast()
			return
	
	if attack_cooldown_timer > 0.0:
		attack_cooldown_timer -= delta
	
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var move_dir = to_player.normalized()
	
	_update_direction(move_dir)
	
	# Ataque cuerpo a cuerpo
	if dist <= MELEE_RANGE:
		if attack_cooldown_timer <= 0.0:
			_melee_attack()
			attack_cooldown_timer = ATTACK_COOLDOWN
	
	var eff_speed = current_speed * (1.0 - lemon_slow_ratio if lemon_timer > 0.0 else 1.0)
	var target_speed = eff_speed if dist > 62.0 else eff_speed * 0.4
	velocity = move_dir * target_speed
	move_and_slide()
	
	# Desvío tangencial inteligente si choca de frente contra un obstáculo o pilar
	if get_slide_collision_count() > 0 and velocity.length() < target_speed * 0.35:
		var col = get_slide_collision(0)
		var normal = col.get_normal()
		var tangent = Vector2(-normal.y, normal.x)
		if tangent.dot(move_dir) < 0:
			tangent = -tangent
		velocity = (tangent * 0.75 + move_dir * 0.25).normalized() * target_speed
		move_and_slide()
	
	# Verificar impacto directo con el jugador
	for i in range(get_slide_collision_count()):
		var col = get_slide_collision(i)
		var collider = col.get_collider()
		if collider is Player or (collider and collider.is_in_group("player")):
			if attack_cooldown_timer <= 0.0:
				_melee_attack()
				attack_cooldown_timer = ATTACK_COOLDOWN
				break
	
	_update_animation(delta, velocity.length() > 5.0)

func _melee_attack() -> void:
	is_attacking = true
	attack_anim_timer = 0.55
	AudioManager.play_sfx("ultra_attack")
	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(melee_damage)
		var push_dir = (player.global_position - global_position).normalized()
		if push_dir == Vector2.ZERO:
			push_dir = Vector2.DOWN
		player.velocity += push_dir * 130.0

# ==============================================================================
# SISTEMA DE SOBRECALENTAMIENTO DE ARMADURA Y DAÑO
# ==============================================================================
func take_damage(amount: float) -> void:
	if current_state == State.DEAD or current_state == State.INTRO:
		return
	
	if is_enraged:
		# FASE 2 ENRAGE: DAÑO DIRECTO A LA BARRA DE VIDA HEREDADA (DPS CHECK)
		current_bar_health = max(0.0, current_bar_health - amount)
		health_changed.emit(current_bar_health, BAR_MAX_HEALTH, health_bars_remaining)
		
		# Destello de impacto carmesí brillante
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.8, 1.8, 0.4, 1.0), 0.04)
		tw.tween_property(sprite, "modulate", Color(1.3, 0.45, 0.45, 1.0), 0.07)
		
		if current_bar_health <= 0.0:
			health_bars_remaining -= 1
			health_changed.emit(0.0, BAR_MAX_HEALTH, health_bars_remaining)
			if health_bars_remaining <= 0:
				die()
			else:
				current_bar_health = BAR_MAX_HEALTH
				health_changed.emit(current_bar_health, BAR_MAX_HEALTH, health_bars_remaining)
		return
	
	if is_armored:
		# La armadura absorbe el impacto y se sobrecalienta gradualmente
		armor_heat = min(MAX_ARMOR_HEAT, armor_heat + amount * 0.28)
		armor_heat_changed.emit(armor_heat, MAX_ARMOR_HEAT)
		_update_armor_visuals()
		
		# Destello de calor en armadura
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(2.5, 1.4, 0.4, 1.0), 0.05)
		tw.tween_property(sprite, "modulate", _get_heat_color(), 0.08)
		
		# ¿Armadura sobrecalentada al 100%? -> Iniciar casteo de embestida
		if armor_heat >= MAX_ARMOR_HEAT and current_state == State.CHASE:
			_start_charge_cast()
			
	elif current_state == State.STUNNED:
		# JEFE ATURDIDO: RECIBE DAÑO DIRECTO A LA BARRA DE VIDA
		current_bar_health = max(0.0, current_bar_health - amount)
		health_changed.emit(current_bar_health, BAR_MAX_HEALTH, health_bars_remaining)
		
		# Destello crítico amarillo
		var tw = create_tween()
		tw.tween_property(sprite, "modulate", Color(3.0, 3.0, 1.0, 1.0), 0.04)
		tw.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.06)
		
		# Si se vacía la barra actual
		if current_bar_health <= 0.0:
			_on_health_bar_depleted()

func _update_armor_visuals() -> void:
	if not sprite:
		return
	if is_enraged:
		sprite.modulate = Color(1.3, 0.45, 0.45, 1.0)
	elif is_armored:
		sprite.modulate = _get_heat_color()
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _get_heat_color() -> Color:
	var heat_ratio = armor_heat / MAX_ARMOR_HEAT
	# De gris metálico a naranja ardiente
	return Color(1.0 + heat_ratio * 1.5, 1.0 + heat_ratio * 0.4, 1.0 - heat_ratio * 0.5, 1.0)

func apply_burn(dot: float, duration: float, armor_shred: float) -> void:
	if current_state == State.DEAD: return
	burn_dot_damage = dot
	burn_armor_shred = armor_shred
	burn_timer = max(burn_timer, duration)
	_update_debuff_visuals()

func apply_lemon_juice(dot: float, duration: float, slow_ratio: float) -> void:
	if current_state == State.DEAD: return
	lemon_dot_damage = dot
	lemon_slow_ratio = slow_ratio
	lemon_timer = max(lemon_timer, duration)
	_update_debuff_visuals()

func _process_debuffs(delta: float) -> void:
	if current_state == State.DEAD: return
	
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

func _update_debuff_visuals() -> void:
	if current_state == State.DEAD:
		if burn_fx: burn_fx.visible = false
		if lemon_fx: lemon_fx.visible = false
		return
		
	if burn_timer > 0.0:
		if not burn_fx:
			burn_fx = Sprite2D.new()
			burn_fx.texture = SkinManager.get_sprite("sc1_fire_loop")
			burn_fx.hframes = 12
			burn_fx.scale = Vector2(1.15, 1.15)
			burn_fx.position = Vector2(0, -18)
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
			lemon_fx.scale = Vector2(1.2, 1.2)
			lemon_fx.position = Vector2(0, -15)
			lemon_fx.z_index = 2
			add_child(lemon_fx)
		lemon_fx.visible = true
	elif lemon_fx:
		lemon_fx.visible = false

# ==============================================================================
# CASTEO DE EMBESTIDA (3 SEGUNDOS SIGUIENDO AL JUGADOR)
# ==============================================================================
func _start_enraged_charge_cast() -> void:
	current_state = State.TELEGRAPH_CHARGE
	velocity = Vector2.ZERO
	charge_cast_timer = 1.8 # Telégrafo rápido en Enrage
	state_changed.emit("¡CARGA SALVAJE DESTRUCTORA DE ROCAS!")
	charge_cast_started.emit(1.8)
	
	AudioManager.play_sfx("ultra_roar", 0.0, 4.5)
	
	if telegraph_line:
		telegraph_line.clear_points()
		telegraph_line.add_point(Vector2.ZERO)
		telegraph_line.add_point(Vector2.DOWN * 850.0)
		telegraph_line.default_color = Color(1.0, 0.05, 0.05, 0.95)
		telegraph_line.width = 28.0
		telegraph_line.visible = true

func _start_charge_cast() -> void:
	current_state = State.TELEGRAPH_CHARGE
	velocity = Vector2.ZERO
	charge_cast_timer = CHARGE_CAST_TIME
	state_changed.emit("¡SOBRECALENTAMIENTO! ¡PREPARANDO EMBESTIDA (3s)!")
	charge_cast_started.emit(CHARGE_CAST_TIME)
	
	AudioManager.play_sfx("ultra_roar", 0.0, 4.5)
	
	if telegraph_line:
		telegraph_line.clear_points()
		telegraph_line.add_point(Vector2.ZERO)
		telegraph_line.add_point(Vector2.DOWN * 800.0)
		telegraph_line.default_color = Color(1.0, 0.15, 0.05, 0.85)
		telegraph_line.width = 24.0
		telegraph_line.visible = true

func _process_telegraph(delta: float) -> void:
	charge_cast_timer -= delta
	
	# La flecha SIGUE al jugador continuamente durante los 3 segundos de casteo
	if is_instance_valid(player):
		charge_target_pos = player.global_position
		charge_direction = (charge_target_pos - global_position).normalized()
		_update_direction(charge_direction)
		
		if telegraph_line:
			var local_target = to_local(global_position + charge_direction * 900.0)
			telegraph_line.set_point_position(0, Vector2.ZERO)
			telegraph_line.set_point_position(1, local_target)
			var pulse = sin(charge_cast_timer * 18.0) * 0.3 + 0.7
			telegraph_line.default_color = Color(1.0, 0.1, 0.05, pulse)
	
	# Al terminar exactamente los 3 segundos: fijar punto y lanzar carga
	if charge_cast_timer <= 0.0:
		_execute_charge()

func _execute_charge() -> void:
	current_state = State.CHARGING
	charge_distance_travelled = 0.0
	state_changed.emit("¡EMBESTIDA SÍSMICA EN CURSO!")
	charge_launched.emit()
	
	if telegraph_line:
		telegraph_line.visible = false
	if charge_particles:
		charge_particles.emitting = true
	
	# Sonido de embestida a fondo
	AudioManager.play_sfx("ultra_attack", 0.0, 4.0)

func _process_charging(delta: float) -> void:
	var move_step = charge_direction * charge_speed * delta
	charge_distance_travelled += move_step.length()
	
	# Animación de carrera rápida
	anim_timer += delta * 20.0
	var run_sub = int(anim_timer) % 6
	_set_sprite_frame((1 + run_sub) * 17 + facing_column)
	
	# Arrollar y aniquilar cualquier zerg en su camino durante la embestida desenfrenada
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy != self and not (enemy is TorrasqueBoss):
			if global_position.distance_to(enemy.global_position) < 95.0:
				if enemy.has_method("take_damage"):
					enemy.take_damage(99999.0)
	
	# Comprobar si arrolló al jugador en proximidad durante la embestida (INSTA-KILL)
	if is_instance_valid(player) and global_position.distance_to(player.global_position) < 70.0:
		if player.has_method("take_damage"):
			player.take_damage(charge_damage)
			player.velocity = charge_direction * 350.0
		if is_enraged:
			_end_enraged_charge_hit_wall(global_position)
		else:
			_end_charge_missed()
		return
	
	var collision = move_and_collide(move_step)
	if collision:
		var collider = collision.get_collider()
		
		# 1. ¿CHOCÓ CONTRA UN PILAR? (SOLO LA CARGA PUEDE ROMPERLO - FASE 1)
		if collider is BossPillar:
			var pillar = collider as BossPillar
			var arena = get_parent()
			if arena and arena.has_method("on_pillar_hit_by_charge"):
				arena.on_pillar_hit_by_charge(pillar)
			return
		
		# 2. Chocó contra el jugador (INSTA-KILL)
		elif collider is Player or (collider and collider.is_in_group("player")):
			var p = collider as Player
			if p and p.has_method("take_damage"):
				p.take_damage(charge_damage)
				p.velocity = charge_direction * 350.0
			if is_enraged:
				_end_enraged_charge_hit_wall(collision.get_position())
			else:
				_end_charge_missed()
			return
		
		# 3. Chocó contra la pared de la cueva / borde perimetral
		else:
			if is_enraged:
				_end_enraged_charge_hit_wall(collision.get_position())
			else:
				_end_charge_missed()
			return
	
	# Detección de proximidad al perímetro en Enrage para romper rocas
	if is_enraged and global_position.length() >= 420.0:
		_end_enraged_charge_hit_wall(global_position)
		return
	
	if charge_distance_travelled >= max_charge_distance:
		if is_enraged:
			_end_enraged_charge_hit_wall(global_position)
		else:
			_end_charge_missed()

func _end_enraged_charge_hit_wall(impact_pos: Vector2) -> void:
	if charge_particles:
		charge_particles.emitting = false
	
	# Romper las rocas perimetrales en el impacto
	var arena = get_parent()
	if arena and arena.has_method("on_torrasque_smashed_wall"):
		arena.on_torrasque_smashed_wall(impact_pos)
	
	AudioManager.play_sfx("pillar_smash", 0.05, 4.5)
	enraged_charge_timer = randf_range(5.5, 7.5)
	current_state = State.RECOVERING
	
	# Breve stagger de 0.5s tras estrellarse contra el muro
	var tw = create_tween()
	tw.tween_interval(0.5)
	tw.tween_callback(func():
		if current_state != State.DEAD:
			_enter_chase()
			state_changed.emit("¡PERSIGUIENDO CON FURIA!")
	)

func _end_charge_missed() -> void:
	if charge_particles:
		charge_particles.emitting = false
	
	# Si falló la carga contra un pilar y chocó contra el muro:
	# Su armadura se reinicia a 0 y hay que calentarla de nuevo
	armor_heat = 0.0
	armor_heat_changed.emit(armor_heat, MAX_ARMOR_HEAT)
	_update_armor_visuals()
	AudioManager.play_sfx("pillar_crack", 0.05, 3.5)
	
	current_state = State.CHASE
	state_changed.emit("PERSIGUIENDO (ARMADURA REINICIADA)")

# ==============================================================================
# ATURDIMIENTO (STUN) TRAS ROMPER PILAR
# ==============================================================================
func enter_final_phase1_stun() -> void:
	is_final_phase1_stun = true
	enter_stunned_state()
	state_changed.emit("¡ÚLTIMO PILAR ROTO! ¡ATURDIMIENTO FINAL FASE 1!")

func enter_stunned_state() -> void:
	current_state = State.STUNNED
	is_armored = false
	stun_timer = STUN_DURATION
	velocity = Vector2.ZERO
	state_changed.emit("¡ATURDIDO! ¡CORAZA EXPUESTA! (FUEGO A DISCRECIÓN)")
	stunned.emit(STUN_DURATION)
	
	if charge_particles:
		charge_particles.emitting = false
	if telegraph_line:
		telegraph_line.visible = false
	if stun_indicator:
		stun_indicator.global_position = global_position + Vector2(0, -60)
		stun_indicator.rotation = 0.0
		stun_indicator.scale = Vector2(1.5, 1.5)
		stun_indicator.modulate = Color(1.0, 1.0, 1.0, 1.0)
		stun_indicator.visible = true
	if stun_stars_sprite:
		stun_stars_sprite.frame = 0
	
	AudioManager.play_sfx("boss_stun", 0.0, 4.0)
	_set_sprite_frame(facing_column)

func _process_stunned(delta: float) -> void:
	stun_timer -= delta
	if stun_indicator:
		stun_indicator.global_position = global_position + Vector2(0, -60)
		stun_indicator.modulate = Color(1.0, 1.0, 1.0, 1.0)
	if stun_stars_sprite:
		# Animación continua de estrellitas girando a 25 FPS (40 ms por frame, 32 frames)
		stun_stars_sprite.frame = int((STUN_DURATION - stun_timer) * 25.0) % 32
	
	# Si se agota el tiempo de stun sin vaciar la barra, se recupera o transiciona
	if stun_timer <= 0.0:
		if is_final_phase1_stun:
			_start_phase_2_transition_flow()
		else:
			_recover_from_stun()

func _on_health_bar_depleted() -> void:
	health_bars_remaining -= 1
	health_changed.emit(0.0, BAR_MAX_HEALTH, health_bars_remaining)
	
	if health_bars_remaining <= 0:
		die()
	else:
		# Barra vaciada con éxito -> reiniciar barra para el siguiente ciclo
		current_bar_health = BAR_MAX_HEALTH
		if is_final_phase1_stun:
			if stun_timer <= 0.0:
				_start_phase_2_transition_flow()
		else:
			_recover_from_stun()

func _start_phase_2_transition_flow() -> void:
	if current_state == State.DEAD:
		return
	is_final_phase1_stun = false
	if stun_indicator:
		stun_indicator.visible = false
	var arena = get_parent()
	if arena and arena.has_method("start_phase_2_transition"):
		arena.start_phase_2_transition()

func enter_transition_stomp_and_leap(target_center: Vector2, on_landed: Callable) -> void:
	current_state = State.INTRO
	velocity = Vector2.ZERO
	if telegraph_line:
		telegraph_line.visible = false
	if charge_particles:
		charge_particles.emitting = false
	if stun_indicator:
		stun_indicator.visible = false
	
	# 1. Pisar el suelo con rugido sísmico
	AudioManager.play_sfx("ultra_roar", 0.0, 5.0)
	AudioManager.play_sfx("pillar_smash", 0.0, 4.5)
	
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.85, 1.15), 0.18).set_trans(Tween.TRANS_QUAD)
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.18).set_trans(Tween.TRANS_QUAD)
	tw.tween_interval(0.2)
	
	# 2. Saltar / correr rápidamente hacia el centro
	tw.tween_callback(func():
		var dir = (target_center - global_position).normalized()
		if dir != Vector2.ZERO:
			_update_direction(dir)
		AudioManager.play_sfx("ultra_attack", 0.0, 4.0)
	)
	tw.tween_property(self, "global_position", target_center, 0.48).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 3. Al aterrizar en el centro
	tw.tween_callback(func():
		AudioManager.play_sfx("pillar_smash", 0.0, 5.0)
		_set_sprite_frame(facing_column)
		if on_landed.is_valid():
			on_landed.call()
	)

func enter_enrage() -> void:
	if current_state == State.DEAD:
		return
	is_enraged = true
	is_armored = false # Daño directo para DPS check
	current_speed = 118.0
	enraged_charge_timer = randf_range(5.5, 7.0)
	if sprite:
		sprite.modulate = Color(1.3, 0.45, 0.45, 1.0)
	AudioManager.play_sfx("ultra_roar", 0.0, 5.5)
	state_changed.emit("¡ENRAGE ACTIVADO! ¡DAÑO DIRECTO A LA CORAZA!")
	_enter_chase()

func _recover_from_stun() -> void:
	if current_state == State.DEAD:
		return
	
	current_state = State.RECOVERING
	if stun_indicator:
		stun_indicator.visible = false
	
	AudioManager.play_sfx("ultra_roar", 0.05, 4.0)
	
	# Reactivar armadura y resetear sobrecalentamiento
	is_armored = true
	armor_heat = 0.0
	armor_heat_changed.emit(armor_heat, MAX_ARMOR_HEAT)
	
	# Transición breve de recuperación
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(1.8, 1.8, 1.8, 1.0), 0.25)
	tw.tween_property(sprite, "modulate", _get_heat_color(), 0.25)
	tw.tween_callback(func():
		_enter_chase()
		recovered.emit()
	)

# ==============================================================================
# ANIMACIÓN Y MUERTE
# ==============================================================================
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
	if attack_anim_timer > 0.0:
		attack_anim_timer -= delta
		var attack_sub = int((0.55 - attack_anim_timer) * 8.0) % 3
		_set_sprite_frame((7 + attack_sub) * 17 + facing_column)
	elif is_moving:
		anim_timer += delta * 11.0
		var run_sub = int(anim_timer) % 6
		_set_sprite_frame((1 + run_sub) * 17 + facing_column)
	else:
		_set_sprite_frame(0 * 17 + facing_column)

func _set_sprite_frame(f: int) -> void:
	if sprite:
		sprite.frame = clampi(f, 0, sprite.hframes * sprite.vframes - 1)
		sprite.flip_h = is_facing_left

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	state_changed.emit("¡TORRASQUE ERRADICADO!")
	died.emit()
	
	velocity = Vector2.ZERO
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	if telegraph_line:
		telegraph_line.visible = false
	if stun_indicator:
		stun_indicator.visible = false
	if charge_particles:
		charge_particles.emitting = false
	if burn_fx:
		burn_fx.visible = false
	if lemon_fx:
		lemon_fx.visible = false
	
	AudioManager.play_sfx("ultra_death", 0.0, 5.0)
	GameManager.add_kill()
	GameManager.add_boss_kill()
	
	_drop_rewards()
	
	var death_tex = SkinManager.get_sprite("ultralisk_death")
	if death_tex:
		sprite.texture = death_tex
		sprite.hframes = 5
		sprite.vframes = 1
		sprite.frame = 0
		sprite.flip_h = is_facing_left
	
	var tw = create_tween()
	for f in range(1, 5):
		tw.tween_interval(0.12)
		tw.tween_callback(func():
			if is_instance_valid(sprite):
				sprite.frame = f
		)
	tw.tween_interval(0.2)
	tw.tween_interval(2.0)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 0), 1.5)
	tw.tween_callback(queue_free)

func _drop_rewards() -> void:
	var chest_scene = load("res://scenes/chest.tscn")
	if chest_scene:
		var c = chest_scene.instantiate()
		c.global_position = global_position
		get_parent().call_deferred("add_child", c)
	
	var vespene_scene = load("res://scenes/vespene_tank.tscn")
	if vespene_scene:
		for i in range(8):
			var v = vespene_scene.instantiate()
			var ang = randf_range(0, TAU)
			var dist = randf_range(30, 80)
			v.global_position = global_position + Vector2.RIGHT.rotated(ang) * dist
			get_parent().call_deferred("add_child", v)
