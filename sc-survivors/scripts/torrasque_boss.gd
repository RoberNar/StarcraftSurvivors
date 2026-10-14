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
const BAR_MAX_HEALTH: float = 250.0
var health_bars_remaining: int = 6
var current_bar_health: float = 250.0

# Armadura y Sobrecalentamiento
var is_armored: bool = true
var armor_heat: float = 0.0
const MAX_ARMOR_HEAT: float = 100.0

# Velocidades y Daño
@export var base_speed: float = 95.0
var current_speed: float = 95.0
@export var charge_speed: float = 460.0
@export var melee_damage: float = 24.0
@export var charge_damage: float = 48.0

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
@onready var charge_particles: CPUParticles2D = get_node_or_null("ChargeParticles")

var player: Player = null

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

func _enter_intro() -> void:
	current_state = State.INTRO
	state_timer = 1.8
	state_changed.emit("¡EMERGENCIA DEL TORRASQUE!")
	
	AudioManager.play_sfx("nydus_emerge", 0.0, 5.0)
	AudioManager.play_sfx("ultra_roar", 0.1, 4.0)
	
	modulate = Color(1.8, 1.4, 1.4, 0.0)
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 0.8)
	tw.parallel().tween_property(self, "scale", Vector2(1.5, 1.5), 1.0).from(Vector2(0.3, 0.3))
	tw.tween_callback(func():
		modulate = Color(1, 1, 1, 1)
		_enter_chase()
	)

func _enter_chase() -> void:
	current_state = State.CHASE
	state_changed.emit("PERSIGUIENDO (ARMADURA ACTIVA)")
	_update_armor_visuals()

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	player = get_tree().get_first_node_in_group("player") as Player
	
	match current_state:
		State.INTRO:
			pass
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
	
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var move_dir = to_player.normalized()
	
	if dist > 48.0:
		velocity = move_dir * current_speed
		move_and_slide()
		_update_direction(move_dir)
	else:
		velocity = Vector2.ZERO
		_update_direction(move_dir)
		if attack_anim_timer <= 0.0:
			_melee_attack()
	
	_update_animation(delta, velocity.length() > 5.0)

func _melee_attack() -> void:
	is_attacking = true
	attack_anim_timer = 0.55
	AudioManager.play_sfx("ultra_attack")
	if player and player.has_method("take_damage"):
		player.take_damage(melee_damage)

# ==============================================================================
# SISTEMA DE SOBRECALENTAMIENTO DE ARMADURA Y DAÑO
# ==============================================================================
func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return
	
	if is_armored:
		# La armadura absorbe el impacto y se sobrecalienta
		armor_heat = min(MAX_ARMOR_HEAT, armor_heat + amount * 0.95)
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
	if is_armored:
		sprite.modulate = _get_heat_color()
	else:
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _get_heat_color() -> Color:
	var heat_ratio = armor_heat / MAX_ARMOR_HEAT
	# De gris metálico a naranja ardiente
	return Color(1.0 + heat_ratio * 1.5, 1.0 + heat_ratio * 0.4, 1.0 - heat_ratio * 0.5, 1.0)

# ==============================================================================
# CASTEO DE EMBESTIDA (3 SEGUNDOS SIGUIENDO AL JUGADOR)
# ==============================================================================
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
		telegraph_line.default_color = Color(1.0, 0.4, 0.1, 0.7)
		telegraph_line.width = 18.0
		telegraph_line.visible = true

func _process_telegraph(delta: float) -> void:
	charge_cast_timer -= delta
	
	# La flecha SIGUE al jugador continuamente durante los 3 segundos de casteo
	if is_instance_valid(player):
		charge_target_pos = player.global_position
		charge_direction = (charge_target_pos - global_position).normalized()
		_update_direction(charge_direction)
		
		if telegraph_line:
			var local_target = to_local(charge_target_pos).normalized() * 800.0
			telegraph_line.set_point_position(1, local_target)
			# Parpadeo que se acelera conforme termina el casteo
			var pulse = sin(charge_cast_timer * 15.0) * 0.3 + 0.7
			telegraph_line.default_color = Color(1.0, 0.1, 0.1, pulse)
	
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
	
	var collision = move_and_collide(move_step)
	if collision:
		var collider = collision.get_collider()
		
		# 1. ¿CHOCÓ CONTRA UN PILAR? (SOLO LA CARGA PUEDE ROMPERLO)
		if collider is BossPillar:
			var pillar = collider as BossPillar
			# Notificar al arena que este pilar fue golpeado por la embestida
			var arena = get_parent() as BossCaveArena
			if arena and arena.has_method("on_pillar_hit_by_charge"):
				arena.on_pillar_hit_by_charge(pillar)
			return
		
		# 2. Chocó contra el jugador
		elif collider is Player or (collider and collider.is_in_group("player")):
			var p = collider as Player
			if p and p.has_method("take_damage"):
				p.take_damage(charge_damage)
				p.velocity = charge_direction * 260.0
			_end_charge_missed()
			return
		
		# 3. Chocó contra la pared de la cueva
		else:
			AudioManager.play_sfx("pillar_crack", 0.05, 3.0)
			_end_charge_missed()
			return
	
	if charge_distance_travelled >= max_charge_distance:
		_end_charge_missed()

func _end_charge_missed() -> void:
	if charge_particles:
		charge_particles.emitting = false
	current_state = State.CHASE
	state_changed.emit("PERSIGUIENDO (ARMADURA ACTIVA)")

# ==============================================================================
# ATURDIMIENTO (STUN) TRAS ROMPER PILAR
# ==============================================================================
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
		stun_indicator.visible = true
	
	AudioManager.play_sfx("boss_stun", 0.0, 4.0)
	_set_sprite_frame(facing_column)

func _process_stunned(delta: float) -> void:
	stun_timer -= delta
	if stun_indicator:
		stun_indicator.rotation += delta * 6.0
	
	# Si se agota el tiempo de stun sin vaciar la barra, se recupera
	if stun_timer <= 0.0:
		_recover_from_stun()

func _on_health_bar_depleted() -> void:
	health_bars_remaining -= 1
	health_changed.emit(0.0, BAR_MAX_HEALTH, health_bars_remaining)
	
	if health_bars_remaining <= 0:
		die()
	else:
		# Barra vaciada con éxito -> reiniciar barra para el siguiente ciclo
		current_bar_health = BAR_MAX_HEALTH
		_recover_from_stun()

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
	tw.tween_property(sprite, "modulate:a", 0.0, 1.5)
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
