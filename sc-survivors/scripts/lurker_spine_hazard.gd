class_name LurkerSpineHazard
extends Node2D

## Peligro subterráneo del Enjambre: Espinas Subterráneas de Lurker
## Dibuja una franja roja ancha y translúcida de advertencia previa y luego hace brotar
## una fila secuencial de espinas que actúan como obstáculos dañinos en el suelo.

@export var line_length: float = 600.0
@export var line_width: float = 52.0
@export var damage: float = 16.0
@export var telegraph_duration: float = 1.35
@export var spike_spacing: float = 36.0
@export var spike_stay_duration: float = 1.1

var direction: Vector2 = Vector2.RIGHT
var is_active: bool = true
var is_telegraphing: bool = true
var telegraph_timer: float = 0.0
var elapsed_time: float = 0.0

var spikes: Array[Node2D] = []
var spike_tex: Texture2D = null

func _ready() -> void:
	add_to_group("hazards")
	add_to_group("lurker_hazards")
	z_as_relative = false
	z_index = -1
	
	spike_tex = load("res://assets/skins/sd/sprites/lurker_spikes.png")
	if not spike_tex and has_node("/root/SkinManager"):
		var sm = get_node("/root/SkinManager")
		if sm.has_method("get_sprite"):
			spike_tex = sm.get_sprite("lurker_spikes")
	
	# Sonido suave de retumbo/vibración subterránea al inicio de la advertencia
	_play_sfx("burrow_up", 0.08, -3.0)

func setup(start_position: Vector2, dir: Vector2, length_val: float = 600.0, dmg: float = 16.0, duration: float = 1.35) -> void:
	global_position = start_position
	direction = dir.normalized()
	line_length = length_val
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
			_erupt_spines()

func _draw() -> void:
	if not is_telegraphing:
		return
	
	var dir_norm = direction.normalized()
	var perp = Vector2(-dir_norm.y, dir_norm.x) * (line_width * 0.5)
	
	var p0 = Vector2.ZERO - perp
	var p1 = Vector2.ZERO + perp
	var p2 = (dir_norm * line_length) + perp
	var p3 = (dir_norm * line_length) - perp
	
	# Parpadeo de pulso de peligro
	var pulse = 0.28 + 0.16 * sin(elapsed_time * 15.0)
	var fill_color = Color(1.0, 0.12, 0.12, pulse)
	var border_color = Color(1.0, 0.35, 0.35, 0.88)
	
	# Relleno poligonal translúcido
	draw_colored_polygon(PackedVector2Array([p0, p1, p2, p3]), fill_color)
	
	# Líneas de contorno marcadas
	draw_line(p0, p3, border_color, 2.8)
	draw_line(p1, p2, border_color, 2.8)
	draw_line(p0, p1, border_color, 2.0)
	draw_line(p3, p2, border_color, 2.2)
	
	# Flechas direccionales chevrons en el centro de la trayectoria para advertir el avance
	var step = 55.0
	var cur_dist = 35.0
	while cur_dist < line_length - 20.0:
		var center_pt = dir_norm * cur_dist
		var arrow_left = center_pt - dir_norm * 16.0 - perp * 0.48
		var arrow_right = center_pt - dir_norm * 16.0 + perp * 0.48
		draw_line(arrow_left, center_pt, Color(1.0, 0.75, 0.75, 0.85), 2.2)
		draw_line(arrow_right, center_pt, Color(1.0, 0.75, 0.75, 0.85), 2.2)
		cur_dist += step

func _erupt_spines() -> void:
	if not is_active:
		return
	
	# Sonido icónico de erupción de púas de Lurker de StarCraft
	_play_sfx("lurker_fire", 0.05, 2.0)
	
	var num_spikes = int(line_length / spike_spacing)
	var dir_norm = direction.normalized()
	
	for i in range(num_spikes):
		var offset_pos = dir_norm * (float(i) * spike_spacing)
		var delay = float(i) * 0.040
		_spawn_single_spike(offset_pos, delay)
	
	# Temporizador para liberar el nodo contenedor una vez terminen todas las espinas
	var total_lifetime = float(num_spikes) * 0.040 + spike_stay_duration + 0.8
	get_tree().create_timer(total_lifetime).timeout.connect(func():
		if is_instance_valid(self):
			queue_free()
	)

func _spawn_single_spike(rel_pos: Vector2, delay: float) -> void:
	await get_tree().create_timer(delay).timeout
	if not is_instance_valid(self) or not is_active:
		return
	
	var spike_node = Node2D.new()
	spike_node.position = rel_pos
	spike_node.z_as_relative = false
	spike_node.z_index = 2
	add_child(spike_node)
	spikes.append(spike_node)
	
	var spr = Sprite2D.new()
	spr.texture = spike_tex
	spr.hframes = 7
	spr.vframes = 1
	spr.frame = 0
	spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	# Ajustar origen visual para que la base de la púa quede exactamente en la línea de suelo
	spr.offset = Vector2(0, -20)
	spike_node.add_child(spr)
	
	# Efecto de grieta/humo en la base de cada púa
	var dust = Polygon2D.new()
	dust.polygon = PackedVector2Array([
		Vector2(-14, 0), Vector2(-8, -4), Vector2(8, -4), Vector2(14, 0), Vector2(0, 3)
	])
	dust.color = Color(0.22, 0.14, 0.09, 0.7)
	spike_node.add_child(dust)
	
	# Animación de salida (0 a 6)
	var emerge_duration = 0.15
	var step_time = emerge_duration / 6.0
	
	for f in range(1, 7):
		await get_tree().create_timer(step_time).timeout
		if not is_instance_valid(spike_node) or not is_active:
			return
		spr.frame = f
		if f == 4:
			# Chequeo de impacto en punto culminante
			_check_spike_damage(spike_node.global_position)
	
	# Fase de obstáculo persistente en el suelo
	var stay_time = spike_stay_duration
	var check_interval = 0.25
	var checks = int(stay_time / check_interval)
	for c in range(checks):
		await get_tree().create_timer(check_interval).timeout
		if not is_instance_valid(spike_node) or not is_active:
			return
		_check_spike_damage(spike_node.global_position)
	
	# Retracción / regreso bajo tierra (6 a 0)
	var retract_duration = 0.18
	var retract_step = retract_duration / 6.0
	for f in range(5, -1, -1):
		await get_tree().create_timer(retract_step).timeout
		if not is_instance_valid(spike_node) or not is_active:
			return
		spr.frame = f
	
	if is_instance_valid(spike_node):
		spike_node.queue_free()

func _check_spike_damage(world_pos: Vector2) -> void:
	if not is_active:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and not player.is_dead:
		var dist = world_pos.distance_to(player.global_position)
		if dist <= 28.0:
			if player.has_method("take_damage"):
				player.take_damage(damage)
				_play_sfx("lurker_hit", 0.05, 2.0)

func clear_immediately() -> void:
	is_active = false
	is_telegraphing = false
	for s in spikes:
		if is_instance_valid(s):
			s.queue_free()
	spikes.clear()
	queue_free()

func _play_sfx(sfx_name: String, pitch_range: float = 0.05, vol_db: float = 0.0) -> void:
	if has_node("/root/AudioManager"):
		var am = get_node("/root/AudioManager")
		if am.has_method("play_sfx"):
			am.play_sfx(sfx_name, pitch_range, vol_db)
