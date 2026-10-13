class_name GlaveWurm
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 360.0
var damage: float = 16.0
var bounces_left: int = 3
var ricochet_radius: float = 230.0
var damage_decay: float = 0.85
var max_range: float = 480.0
var traveled: float = 0.0

var hit_targets: Array[Node2D] = []
var target_enemy: Node2D = null

@onready var sprite: Sprite2D = $Sprite2D
@onready var trail: Line2D = $Trail

var trail_points: Array[Vector2] = []
var anim_timer: float = 0.0
var lifetime: float = 3.0
var life_timer: float = 0.0

func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	area_entered.connect(_on_area_entered)

func _physics_process(delta: float) -> void:
	# Vida máxima de 3 segundos para garantizar limpieza y optimización
	life_timer += delta
	if life_timer >= lifetime:
		_dissipate()
		return

	# Animación auténtica del Glave Wurm zerg de 10 frames giratorios (spores.grp)
	anim_timer += delta
	if sprite:
		sprite.frame = int(anim_timer * 22.0) % 10
	
	# Guiado suave hacia el objetivo actual si es válido
	if target_enemy and is_instance_valid(target_enemy) and not ("is_dead" in target_enemy and target_enemy.is_dead) and not ("is_destroyed" in target_enemy and target_enemy.is_destroyed):
		var desired = (target_enemy.global_position - global_position).normalized()
		direction = direction.lerp(desired, delta * 9.0).normalized()
		rotation = direction.angle()
	
	var move_dist = speed * delta
	position += direction * move_dist
	traveled += move_dist
	
	# Actualizar estela visual orgánica
	if trail:
		trail.global_position = Vector2.ZERO
		trail.global_rotation = 0.0
		trail_points.push_front(global_position)
		if trail_points.size() > 6:
			trail_points.pop_back()
		trail.clear_points()
		for p in trail_points:
			trail.add_point(p)
	
	if traveled >= max_range:
		# Si se pasa del rango sin impactar, intentar buscar un rebote o desaparecer
		if bounces_left > 0:
			_find_next_ricochet(null)
		else:
			_dissipate()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not ("is_dead" in body and body.is_dead) and not ("is_destroyed" in body and body.is_destroyed) and not hit_targets.has(body):
		_hit(body)

func _on_area_entered(area: Area2D) -> void:
	var parent_body = area.get_parent()
	if parent_body and parent_body.is_in_group("enemies") and not ("is_dead" in parent_body and parent_body.is_dead) and not ("is_destroyed" in parent_body and parent_body.is_destroyed) and not hit_targets.has(parent_body):
		_hit(parent_body)

func _hit(enemy: Node2D) -> void:
	hit_targets.append(enemy)
	
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	_spawn_hit_spark()
	AudioManager.play_sfx("flame_fire", 0.04, -10.0) # Impacto biológico suave y atenuado
	
	if bounces_left > 0:
		bounces_left -= 1
		damage = max(6.0, damage * damage_decay)
		traveled = 0.0
		_find_next_ricochet(enemy)
	else:
		_dissipate()

func _find_next_ricochet(current_enemy: Node2D) -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	var next_target: Node2D = null
	var min_dist = ricochet_radius
	
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and not ("is_destroyed" in e and e.is_destroyed) and e != current_enemy and not hit_targets.has(e):
			var d = global_position.distance_to(e.global_position)
			if d < min_dist:
				min_dist = d
				next_target = e
	
	# Si todos los enemigos ya fueron impactados, permitir volver a impactar enemigos previos si la horda es pequeña
	if not next_target:
		for e in enemies:
			if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and not ("is_destroyed" in e and e.is_destroyed) and e != current_enemy:
				var d = global_position.distance_to(e.global_position)
				if d < min_dist:
					min_dist = d
					next_target = e
	
	if next_target:
		target_enemy = next_target
		direction = (next_target.global_position - global_position).normalized()
		rotation = direction.angle()
		speed = min(560.0, speed * 1.15) # Aceleración suave en cada rebote
	else:
		_dissipate()

func _spawn_hit_spark() -> void:
	var sp = Sprite2D.new()
	sp.texture = SkinManager.get_sprite("blood_hit")
	if sp.texture:
		sp.hframes = 15
		sp.vframes = 1
		sp.frame = randi() % 5
	sp.modulate = Color(1.2, 0.6, 0.2, 1.0)
	sp.global_position = global_position
	sp.scale = Vector2(0.7, 0.7)
	get_parent().add_child(sp)
	var tw = sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.0, 0.2)
	tw.tween_callback(sp.queue_free)

func _dissipate() -> void:
	queue_free()
