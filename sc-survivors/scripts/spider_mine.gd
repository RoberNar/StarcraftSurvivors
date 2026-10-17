class_name SpiderMine
extends Node2D

@export var damage: float = 75.0
@export var detection_range: float = 135.0
@export var blast_radius: float = 65.0
@export var rush_speed: float = 230.0

enum State { DEPLOYING, ARMED, CHASING, EXPLODING }
var state: int = State.DEPLOYING

var target: Node2D = null
var arm_timer: float = 0.5
var chase_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	AudioManager.play_sfx("mine_deploy")
	if sprite:
		sprite.frame = 0
		sprite.modulate = Color(0.7, 0.7, 0.7, 0.8) # Entierra parcialmente

func _physics_process(delta: float) -> void:
	match state:
		State.DEPLOYING:
			arm_timer -= delta
			if arm_timer <= 0.0:
				state = State.ARMED
				if sprite:
					sprite.frame = 0
					sprite.modulate = Color(0.7, 0.7, 0.7, 0.8)
		
		State.ARMED:
			# Buscar enemigo cercano dentro del rango de detección
			var new_target = _find_closest_target(detection_range)
			if new_target:
				target = new_target
				state = State.CHASING
				chase_timer = 4.0
				if sprite:
					sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
				AudioManager.play_sfx("mine_trigger")
		
		State.CHASING:
			chase_timer -= delta
			
			# Comprobar si el objetivo actual sigue vivo y activo
			var target_alive = _is_target_alive(target)
			
			if not target_alive:
				# ¡El objetivo murió! Reubicar inmediatamente otro objetivo cercano
				target = _find_closest_target(detection_range * 1.6)
				if target:
					# Encontró nuevo objetivo: reiniciar temporizador de persecución
					chase_timer = 3.5
				else:
					# No hay otros enemigos cerca: volver a enterrarse / armarse en el lugar (no desaparecer)
					state = State.ARMED
					target = null
					if sprite:
						sprite.frame = 0
						sprite.modulate = Color(0.7, 0.7, 0.7, 0.8)
					return
			
			if target and is_instance_valid(target):
				var diff = target.global_position - global_position
				var dist = diff.length()
				
				# Si llegó al objetivo, ¡detonar!
				if dist <= 22.0:
					explode()
					return
				
				# Moverse hacia el objetivo
				var dir = diff.normalized()
				global_position += dir * rush_speed * delta
				if sprite:
					# Animación de patas corriendo (frames 1..11 de spider_mine.png)
					sprite.frame = (int(Engine.get_physics_frames() / 3) % 11) + 1
				
				# Si el temporizador de persecución expiró (p.ej. enemigo inalcanzable)
				if chase_timer <= 0.0:
					# Re-evaluar objetivo más cercano
					var alt = _find_closest_target(detection_range)
					if alt and alt != target:
						target = alt
						chase_timer = 3.0
					else:
						# Re-armarse en el terreno si no alcanza al enemigo
						state = State.ARMED
						target = null
						if sprite:
							sprite.frame = 0
							sprite.modulate = Color(0.7, 0.7, 0.7, 0.8)

func _is_target_alive(t: Node2D) -> bool:
	if not t or not is_instance_valid(t):
		return false
	if "is_dead" in t and t.is_dead:
		return false
	if "is_destroyed" in t and t.is_destroyed:
		return false
	if t.is_queued_for_deletion():
		return false
	return true

func _find_closest_target(max_distance: float) -> Node2D:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var closest: Node2D = null
	var min_dist: float = max_distance
	for e in enemies:
		if _is_target_alive(e):
			var d = global_position.distance_to(e.global_position)
			if d <= min_dist:
				min_dist = d
				closest = e
	return closest

func explode() -> void:
	if state == State.EXPLODING:
		return
	state = State.EXPLODING
	
	# Sonido auténtico de detonación de mina Terran
	AudioManager.play_sfx("mine_explode", 0.08, 2.0)
	
	# Daño de área a todos los enemigos en el radio de explosión
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if _is_target_alive(e):
			var d = global_position.distance_to(e.global_position)
			if d <= blast_radius:
				var falloff = 1.0 - (d / blast_radius) * 0.4
				if e.has_method("take_damage"):
					e.take_damage(damage * falloff)
	
	# Animación auténtica de explosión de mina Terran (tmnexplo, 10 frames de 80x80)
	var explo_tex = SkinManager.get_sprite("tmnexplo")
	if sprite and explo_tex:
		sprite.texture = explo_tex
		sprite.hframes = 10
		sprite.vframes = 1
		sprite.frame = 0
		sprite.scale = Vector2(1.2, 1.2)
		sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		var tw = create_tween()
		for i in range(10):
			var idx = i
			tw.tween_callback(func():
				if is_instance_valid(sprite):
					sprite.frame = idx
			)
			tw.tween_interval(0.04)
		tw.tween_callback(queue_free)
	else:
		queue_free()
