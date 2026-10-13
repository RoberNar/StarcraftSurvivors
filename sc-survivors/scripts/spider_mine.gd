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
		sprite.modulate = Color(0.7, 0.7, 0.7, 0.8) # Entierra parcialmente

func _physics_process(delta: float) -> void:
	match state:
		State.DEPLOYING:
			arm_timer -= delta
			if arm_timer <= 0.0:
				state = State.ARMED
				if sprite:
					sprite.modulate = Color(1.0, 1.0, 1.0, 1.0)
		
		State.ARMED:
			# Buscar enemigo cercano
			var enemies = get_tree().get_nodes_in_group("enemies")
			for e in enemies:
				if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and not ("is_destroyed" in e and e.is_destroyed):
					var dist = global_position.distance_to(e.global_position)
					if dist <= detection_range:
						target = e
						state = State.CHASING
						chase_timer = 1.2
						AudioManager.play_sfx("mine_trigger")
						break
		
		State.CHASING:
			chase_timer -= delta
			if target and is_instance_valid(target) and not ("is_dead" in target and target.is_dead) and not ("is_destroyed" in target and target.is_destroyed):
				var dir = (target.global_position - global_position).normalized()
				global_position += dir * rush_speed * delta
				if sprite:
					# Animacion de patas corriendo (frames 1..11)
					sprite.frame = (int(Engine.get_physics_frames() / 3) % 11) + 1
				
				if global_position.distance_to(target.global_position) <= 22.0 or chase_timer <= 0.0:
					explode()
			else:
				# Si el objetivo murio, buscar otro o explotar
				explode()

func explode() -> void:
	if state == State.EXPLODING:
		return
	state = State.EXPLODING
	
	# Sonido de explosion de mina
	AudioManager.play_sfx("zergling_death", 0.1, -1.0)
	
	# Efecto visual de explosion
	var explo_scene = load("res://scenes/bullet.tscn")
	# Daño a todos los enemigos en radio de explosion
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and not ("is_destroyed" in e and e.is_destroyed):
			var d = global_position.distance_to(e.global_position)
			if d <= blast_radius:
				var falloff = 1.0 - (d / blast_radius) * 0.4
				if e.has_method("take_damage"):
					e.take_damage(damage * falloff)
	
	# Animacion de explosion
	if sprite:
		sprite.texture = SkinManager.get_sprite("tmnexplo")
		sprite.hframes = 8
		sprite.vframes = 1
		sprite.frame = 0
		sprite.scale = Vector2(1.5, 1.5)
		var tw = create_tween()
		for f in range(8):
			tw.tween_callback(func(): sprite.frame = f)
			tw.tween_interval(0.04)
		tw.tween_callback(queue_free)
	else:
		queue_free()
