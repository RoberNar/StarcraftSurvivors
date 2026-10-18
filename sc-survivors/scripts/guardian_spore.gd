class_name GuardianSpore
extends Area2D

@export var speed: float = 240.0
@export var damage: float = 24.0

var direction: Vector2 = Vector2.ZERO
var target_pos: Vector2 = Vector2.ZERO
var lifetime: float = 2.5
var has_exploded: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var anim_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	body_entered.connect(_on_body_entered)
	
	if sprite:
		var tex = SkinManager.get_sprite("guardian_spore")
		if tex:
			sprite.texture = tex
		sprite.hframes = 8
		sprite.vframes = 15
		sprite.frame = 0

func setup(start_pos: Vector2, target: Vector2, dmg: float) -> void:
	global_position = start_pos
	target_pos = target
	damage = dmg
	direction = (target - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	lifetime -= delta
	if lifetime <= 0.0 or global_position.distance_to(target_pos) < 16.0:
		_explode()
		return
	
	global_position += direction * speed * delta
	
	anim_timer += delta * 15.0
	if sprite:
		sprite.frame = int(anim_timer) % 15

func _on_body_entered(body: Node2D) -> void:
	if has_exploded:
		return
	if body.is_in_group("player"):
		if body.has_method("take_damage"):
			body.take_damage(damage)
		_explode()

func _explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	set_physics_process(false)
	
	# Chequear radio AoE
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		if global_position.distance_to(player.global_position) <= 45.0:
			if player.has_method("take_damage"):
				player.take_damage(damage * 0.75)
	
	var hit_tex = SkinManager.get_sprite("guardian_spore_hit")
	if hit_tex and sprite:
		sprite.texture = hit_tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0
		sprite.scale = Vector2(1.2, 1.2)
		var tw = create_tween()
		for f in range(1, 10):
			tw.tween_interval(0.04)
			tw.tween_callback(func():
				if sprite and is_instance_valid(sprite):
					sprite.frame = f
			)
		tw.tween_interval(0.04)
		tw.tween_callback(queue_free)
	else:
		queue_free()
