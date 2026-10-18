class_name SunkenColonyHazard
extends Node2D

## Peligro subterráneo del Enjambre: Tentáculo Subterráneo de Sunken Colony
## Proyecta un círculo rojo translúcido de peligro y, tras la advertencia previa,
## brota violentamente un tentáculo gigante desde el subsuelo dañando al jugador si está dentro.

@export var radius: float = 42.0
@export var damage: float = 28.0
@export var telegraph_duration: float = 1.25

var is_active: bool = true
var is_telegraphing: bool = true
var telegraph_timer: float = 0.0
var elapsed_time: float = 0.0
var has_dealt_damage: bool = false

var tentacle_sprite: Sprite2D = null
var dirt_particles: CPUParticles2D = null

func _ready() -> void:
	add_to_group("hazards")
	add_to_group("lurker_hazards")
	z_as_relative = false
	z_index = -1
	
	# Audio sísmico sutil de excavación previa
	AudioManager.play_sfx("burrow_up", 0.06, -3.0)

func setup(pos: Vector2, r: float = 42.0, dmg: float = 28.0, duration: float = 1.25) -> void:
	global_position = pos
	radius = r
	damage = dmg
	telegraph_duration = duration

func _process(delta: float) -> void:
	if not is_active:
		return
	
	elapsed_time += delta
	
	if is_telegraphing:
		telegraph_timer += delta
		queue_redraw()
		if telegraph_timer >= telegraph_duration:
			is_telegraphing = false
			queue_redraw()
			_strike_tentacle()

func _draw() -> void:
	if not is_telegraphing:
		return
	
	var pulse = 0.25 + 0.18 * sin(elapsed_time * 16.0)
	var fill_color = Color(1.0, 0.12, 0.12, pulse)
	var border_color = Color(1.0, 0.35, 0.35, 0.90)
	var warning_arc_color = Color(1.0, 0.85, 0.2, 0.75)
	
	# Círculo translúcido de peligro
	draw_circle(Vector2.ZERO, radius, fill_color)
	draw_arc(Vector2.ZERO, radius, 0.0, TAU, 36, border_color, 2.5)
	
	# Anillo interior concéntrico
	draw_arc(Vector2.ZERO, radius * 0.55, 0.0, TAU, 24, Color(1.0, 0.2, 0.2, pulse * 1.5), 1.5)
	
	# Marcas de mira / peligro en cruz
	var m = radius * 0.25
	draw_line(Vector2(-m, 0), Vector2(m, 0), border_color, 1.8)
	draw_line(Vector2(0, -m), Vector2(0, m), border_color, 1.8)
	
	# Arco de progreso del tiempo de advertencia
	var progress = clampf(telegraph_timer / telegraph_duration, 0.0, 1.0)
	if progress > 0.05:
		draw_arc(Vector2.ZERO, radius + 3.0, -PI * 0.5, -PI * 0.5 + TAU * progress, 36, warning_arc_color, 2.8)

func _strike_tentacle() -> void:
	AudioManager.play_sfx("sunken_hit", 0.15, 0.0)
	
	# Partículas de tierra y lodo brotando
	dirt_particles = CPUParticles2D.new()
	dirt_particles.amount = 16
	dirt_particles.lifetime = 0.55
	dirt_particles.one_shot = true
	dirt_particles.explosiveness = 0.9
	dirt_particles.direction = Vector2(0, -1)
	dirt_particles.spread = 70.0
	dirt_particles.gravity = Vector2(0, 180)
	dirt_particles.initial_velocity_min = 40.0
	dirt_particles.initial_velocity_max = 90.0
	dirt_particles.scale_amount_min = 2.5
	dirt_particles.scale_amount_max = 4.5
	dirt_particles.color = Color(0.45, 0.32, 0.22, 0.9)
	dirt_particles.z_index = 0
	add_child(dirt_particles)
	dirt_particles.emitting = true
	
	# Sprite del tentáculo emergiendo
	tentacle_sprite = Sprite2D.new()
	tentacle_sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	var tex = SkinManager.get_sprite("sunken_tentacle")
	if tex:
		tentacle_sprite.texture = tex
	tentacle_sprite.hframes = 6
	tentacle_sprite.vframes = 1
	tentacle_sprite.frame = 0
	tentacle_sprite.position = Vector2(0, -22)
	tentacle_sprite.scale = Vector2(1.35, 1.35)
	tentacle_sprite.z_index = 1
	add_child(tentacle_sprite)
	
	var frames_sequence = [0, 1, 2, 3, 4, 5, 5, 4, 3, 2, 1, 0]
	var tw = create_tween()
	for idx in range(frames_sequence.size()):
		var f = frames_sequence[idx]
		tw.tween_interval(0.038)
		tw.tween_callback(func():
			if tentacle_sprite and is_instance_valid(tentacle_sprite):
				tentacle_sprite.frame = f
			# Al alcanzar la máxima extensión, infligir daño
			if f >= 4 and not has_dealt_damage:
				_check_damage_hit()
		)
	tw.tween_interval(0.05)
	tw.tween_callback(queue_free)

func _check_damage_hit() -> void:
	has_dealt_damage = true
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and not player.is_dead:
		if global_position.distance_to(player.global_position) <= radius:
			if player.has_method("take_damage"):
				player.take_damage(damage)

func clear_immediately() -> void:
	is_active = false
	queue_free()
