class_name TorrasqueBoss
extends CharacterBody2D

signal health_changed(current_hp: float, max_hp: float)
signal state_changed(state_name: String)
signal stunned(duration: float)
signal recovered()
signal died()

enum State {
	INTRO,
	CHASE,
	TELEGRAPH_CHARGE,
	CHARGING,
	STUNNED,
	GROUND_SLAM,
	DEAD
}

@export var max_health: float = 1600.0
var current_health: float = 1600.0

@export var base_speed: float = 88.0
var current_speed: float = 88.0

@export var charge_speed: float = 380.0
@export var melee_damage: float = 28.0
@export var charge_damage: float = 52.0

var current_state: State = State.INTRO
var state_timer: float = 0.0

# Animación y rotación (32 ángulos de StarCraft SD)
var current_dir32: int = 8
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0
var attack_anim_timer: float = 0.0
var is_attacking: bool = false

# Lógica de Embestida (Charge)
var charge_direction: Vector2 = Vector2.DOWN
var charge_target_pos: Vector2 = Vector2.ZERO
var charge_distance_travelled: float = 0.0
var max_charge_distance: float = 850.0
var charge_cooldown_timer: float = 6.0
var slam_cooldown_timer: float = 12.0
var minion_spawn_timer: float = 14.0

# Estado de aturdimiento
var is_vulnerable: bool = false
var stun_timer: float = 0.0
var stun_duration: float = 3.6

# Nodos y referencias
@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var telegraph_line: Line2D = $TelegraphLine
@onready var stun_indicator: Node2D = $StunIndicator
@onready var charge_particles: CPUParticles2D = get_node_or_null("ChargeParticles")

var player: Player = null
var is_enraged: bool = false

func _ready() -> void:
	add_to_group("enemies")
	add_to_group("bosses")
	
	current_health = max_health
	current_speed = base_speed
	
	_apply_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)
	
	if telegraph_line:
		telegraph_line.visible = false
	if stun_indicator:
		stun_indicator.visible = false
	
	# Transición intro emergente
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
		scale = Vector2(1.6, 1.6)

func _enter_intro() -> void:
	current_state = State.INTRO
	state_timer = 2.4
	state_changed.emit("¡EMERGENCIA DEL TITÁN!")
	
	# Pulso telúrico y rugido
	AudioManager.play_sfx("nydus_emerge", 0.0, 5.0)
	AudioManager.play_sfx("ultra_roar", 0.1, 4.0)
	
	modulate = Color(1.8, 1.4, 1.4, 0.0)
	var tw = create_tween()
	tw.tween_property(self, "modulate:a", 1.0, 1.0)
	tw.parallel().tween_property(self, "scale", Vector2(1.6, 1.6), 1.2).from(Vector2(0.4, 0.4))
	tw.tween_callback(func():
		modulate = Color(1, 1, 1, 1)
		_enter_chase()
	)

func _physics_process(delta: float) -> void:
	if current_state == State.DEAD:
		return
	
	player = get_tree().get_first_node_in_group("player") as Player
	
	# Temporizadores de habilidades
	if charge_cooldown_timer > 0.0:
		charge_cooldown_timer -= delta
	if slam_cooldown_timer > 0.0:
		slam_cooldown_timer -= delta
	if minion_spawn_timer > 0.0:
		minion_spawn_timer -= delta
	
	# Furia a menos de 35% de vida
	if not is_enraged and current_health <= max_health * 0.35:
		_trigger_enrage()
	
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
		State.GROUND_SLAM:
			_process_ground_slam(delta)

func _process_chase(delta: float) -> void:
	if not is_instance_valid(player):
		return
	
	# Verificar si es momento de embestir
	if charge_cooldown_timer <= 0.0:
		_start_charge_telegraph()
		return
	
	# Verificar si es momento de azotar el suelo (Fase 2+)
	if current_health <= max_health * 0.65 and slam_cooldown_timer <= 0.0:
		_start_ground_slam()
		return
	
	# Invocar refuerzos de Zerglings en furia
	if is_enraged and minion_spawn_timer <= 0.0:
		minion_spawn_timer = 12.0
		_spawn_zergling_reinforcements(4)
	
	var to_player = player.global_position - global_position
	var dist = to_player.length()
	var move_dir = to_player.normalized()
	
	if dist > 44.0:
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

func _start_charge_telegraph() -> void:
	current_state = State.TELEGRAPH_CHARGE
	velocity = Vector2.ZERO
	state_timer = 1.25 if not is_enraged else 0.85
	state_changed.emit("¡PREPARANDO EMBESTIDA!")
	
	if is_instance_valid(player):
		charge_direction = (player.global_position - global_position).normalized()
		_update_direction(charge_direction)
	
	# Sonido de aviso y rugido de aviso
	AudioManager.play_sfx("ultra_roar", 0.05, 3.5)
	
	# Mostrar línea de trayectoria roja de peligro
	if telegraph_line:
		telegraph_line.clear_points()
		telegraph_line.add_point(Vector2.ZERO)
		telegraph_line.add_point(charge_direction * 700.0)
		telegraph_line.default_color = Color(1.0, 0.1, 0.1, 0.7)
		telegraph_line.width = 16.0
		telegraph_line.visible = true
	
	# Destello de advertencia
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", Color(2.5, 0.5, 0.5, 1.0), 0.2)
	tw.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.2)
	tw.set_loops(3)

func _process_telegraph(delta: float) -> void:
	state_timer -= delta
	# Ajuste fino continuo antes de fijar trayectoria definitiva
	if state_timer > 0.4 and is_instance_valid(player):
		charge_direction = (player.global_position - global_position).normalized()
		_update_direction(charge_direction)
		if telegraph_line:
			telegraph_line.set_point_position(1, charge_direction * 700.0)
	
	if state_timer <= 0.0:
		_execute_charge()

func _execute_charge() -> void:
	current_state = State.CHARGING
	charge_distance_travelled = 0.0
	state_changed.emit("¡EMBESTIDA SÍSMICA EN CURSO!")
	
	if telegraph_line:
		telegraph_line.visible = false
	
	if charge_particles:
		charge_particles.emitting = true
	
	# Sonido de despegue y temblor
	AudioManager.play_sfx("ultra_attack", 0.0, 4.0)

func _process_charging(delta: float) -> void:
	var move_step = charge_direction * charge_speed * delta
	charge_distance_travelled += move_step.length()
	
	# Animación de carrera rápida
	anim_timer += delta * 18.0
	var run_sub = int(anim_timer) % 6
	_set_sprite_frame((1 + run_sub) * 17 + facing_column)
	
	# Moverse detectando colisiones físicas con move_and_collide
	var collision = move_and_collide(move_step)
	if collision:
		var collider = collision.get_collider()
		
		# 1. ¿CHOCÓ CONTRA UN PILAR DE PIEDRA? (¡MECÁNICA CLAVE!)
		if collider is BossPillar:
			var pillar = collider as BossPillar
			var stunned_boss = pillar.hit_by_boss_charge()
			if stunned_boss:
				_enter_stunned()
				return
		
		# 2. ¿CHOCÓ CONTRA EL JUGADOR?
		elif collider is Player or (collider and collider.is_in_group("player")):
			var p = collider as Player
			if p and p.has_method("take_damage"):
				p.take_damage(charge_damage)
				# Empuje hacia atrás
				p.velocity = charge_direction * 220.0
			_end_charge_recovery()
			return
		
		# 3. Chocó contra la pared de la cueva
		else:
			AudioManager.play_sfx("pillar_crack", 0.05, 2.5)
			_end_charge_recovery()
			return
	
	# Si viajó la distancia máxima sin chocar
	if charge_distance_travelled >= max_charge_distance:
		_end_charge_recovery()

func _end_charge_recovery() -> void:
	if charge_particles:
		charge_particles.emitting = false
	
	# Pequeña desaceleración de 0.6s
	current_state = State.CHASE
	charge_cooldown_timer = 7.0 if not is_enraged else 4.5
	state_changed.emit("PERSIGUIENDO")

func _enter_stunned() -> void:
	current_state = State.STUNNED
	is_vulnerable = true
	stun_timer = stun_duration
	velocity = Vector2.ZERO
	state_changed.emit("¡ATURDIDO! (CORAZA ROTA x2)")
	stunned.emit(stun_duration)
	
	if charge_particles:
		charge_particles.emitting = false
	
	# Sonido de impacto contundente y aturdimiento
	AudioManager.play_sfx("boss_stun", 0.0, 4.0)
	
	# Visuales de aturdimiento (estrellas giratorias)
	if stun_indicator:
		stun_indicator.visible = true
	
	# Animación de sacudida y postura vulnerable (fila 0 inclinada o frame bajo)
	_set_sprite_frame(facing_column)
	var tw = create_tween().set_loops(int(stun_duration * 4.0))
	tw.tween_property(sprite, "modulate", Color(1.6, 1.6, 0.4, 1.0), 0.12)
	tw.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.12)

func _process_stunned(delta: float) -> void:
	stun_timer -= delta
	if stun_indicator:
		stun_indicator.rotation += delta * 6.0
	
	if stun_timer <= 0.0:
		_recover_from_stun()

func _recover_from_stun() -> void:
	is_vulnerable = false
	if stun_indicator:
		stun_indicator.visible = false
	
	# Rugido furioso al recuperarse
	AudioManager.play_sfx("ultra_roar", 0.05, 3.5)
	
	current_state = State.CHASE
	charge_cooldown_timer = 6.0 if not is_enraged else 3.5
	state_changed.emit("PERSIGUIENDO")
	recovered.emit()

func _start_ground_slam() -> void:
	current_state = State.GROUND_SLAM
	state_timer = 1.3
	velocity = Vector2.ZERO
	state_changed.emit("¡TERREMOTO DE ESPINAS!")
	
	# Animación levantando cuchillas Kaiser
	_set_sprite_frame(8 * 17 + facing_column)
	AudioManager.play_sfx("ultra_roar", 0.0, 3.0)
	
	# Sacudir y cargar energía
	var tw = create_tween()
	tw.tween_property(sprite, "position", Vector2(0, -14), 0.5).set_trans(Tween.TRANS_SINE)
	tw.tween_property(sprite, "position", Vector2(0, 0), 0.15).set_trans(Tween.TRANS_BOUNCE)
	tw.tween_callback(func():
		_execute_ground_slam_spines()
	)

func _process_ground_slam(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		current_state = State.CHASE
		slam_cooldown_timer = 14.0
		state_changed.emit("PERSIGUIENDO")

func _execute_ground_slam_spines() -> void:
	# Lanzar espinas subterráneas radiantes en 6 direcciones (hacia los pilares)
	AudioManager.play_sfx("lurker_fire", 0.05, 4.0)
	var hazard_scene = load("res://scenes/lurker_spine_hazard.tscn")
	if not hazard_scene:
		return
	
	var angles = [0.0, PI / 3.0, 2.0 * PI / 3.0, PI, 4.0 * PI / 3.0, 5.0 * PI / 3.0]
	for a in angles:
		var dir = Vector2.RIGHT.rotated(a)
		_spawn_spine_wave(hazard_scene, dir)

func _spawn_spine_wave(hazard_scene: PackedScene, dir: Vector2) -> void:
	var tw = create_tween()
	for step in range(1, 8):
		tw.tween_callback(func():
			if not is_inside_tree():
				return
			var h = hazard_scene.instantiate()
			h.global_position = global_position + dir * (step * 48.0)
			get_parent().add_child(h)
		)
		tw.tween_interval(0.08)

func _trigger_enrage() -> void:
	is_enraged = true
	current_speed = base_speed * 1.25
	charge_speed *= 1.2
	modulate = Color(1.3, 0.7, 0.7, 1.0)
	AudioManager.play_sfx("ultra_roar", 0.0, 4.5)

func _spawn_zergling_reinforcements(count: int) -> void:
	var z_scene = load("res://scenes/zergling.tscn")
	if not z_scene:
		return
	AudioManager.play_sfx("burrow_up", 0.05, 3.0)
	for i in range(count):
		var z = z_scene.instantiate()
		var ang = randf_range(0, TAU)
		z.global_position = global_position + Vector2.RIGHT.rotated(ang) * randf_range(120, 200)
		get_parent().add_child(z)

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

func take_damage(amount: float) -> void:
	if current_state == State.DEAD:
		return
	
	# Mientras esté aturdido por haber chocado con un pilar: ¡DOBLE DAÑO!
	var final_dmg = amount * 2.0 if is_vulnerable else amount * 0.85
	current_health = max(0.0, current_health - final_dmg)
	health_changed.emit(current_health, max_health)
	
	# Destello visual de impacto
	var flash_color = Color(3.0, 3.0, 1.2, 1) if is_vulnerable else Color(2.5, 0.8, 0.8, 1)
	var tw = create_tween()
	tw.tween_property(sprite, "modulate", flash_color, 0.04)
	tw.tween_property(sprite, "modulate", Color(1, 1, 1, 1) if not is_enraged else Color(1.3, 0.7, 0.7, 1), 0.07)
	
	if current_health <= 0.0:
		die()

func die() -> void:
	if current_state == State.DEAD:
		return
	current_state = State.DEAD
	state_changed.emit("¡COLOSO ERRADICADO!")
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
	
	# Recompensas legendarias
	_drop_rewards()
	
	# Animación de muerte canónica SC1 (ultralisk_death.png)
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
	# 1. Gran cofre militar de campaña
	var chest_scene = load("res://scenes/chest.tscn")
	if chest_scene:
		var c = chest_scene.instantiate()
		c.global_position = global_position
		get_parent().call_deferred("add_child", c)
	
	# 2. Gran torrente de Gas Vespeno
	var vespene_scene = load("res://scenes/vespene_tank.tscn")
	if vespene_scene:
		for i in range(8):
			var v = vespene_scene.instantiate()
			var ang = randf_range(0, TAU)
			var dist = randf_range(30, 80)
			v.global_position = global_position + Vector2.RIGHT.rotated(ang) * dist
			get_parent().call_deferred("add_child", v)
