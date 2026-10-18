class_name GuardianSpore
extends Area2D

@export var speed: float = 160.0
@export var damage: float = 24.0

var direction: Vector2 = Vector2.ZERO
var lifetime: float = 3.5
var has_exploded: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var anim_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	body_entered.connect(_on_body_entered)
	
	if sprite:
		var tex = SkinManager.get_sprite("guardian_spore")
		if tex:
			sprite.texture = tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0
		# Ataque original un poco más ancho (ancho horizontal y en dirección de vuelo)
		sprite.scale = Vector2(2.3, 1.8)

func setup(start_pos: Vector2, target: Vector2, dmg: float) -> void:
	global_position = start_pos
	damage = dmg
	direction = (target - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	# Trayectoria recta y directa para poder esquivar claramente
	global_position += direction * speed * delta
	
	anim_timer += delta * 12.0
	if sprite:
		sprite.frame = int(anim_timer) % 10

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
	
	var hit_tex = SkinManager.get_sprite("guardian_spore_hit")
	if hit_tex and sprite:
		sprite.texture = hit_tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0
		sprite.scale = Vector2(1.8, 1.8)
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
