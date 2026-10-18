class_name DevourerAcidProjectile
extends Area2D

@export var speed: float = 185.0
@export var damage: float = 18.0

var direction: Vector2 = Vector2.ZERO
var lifetime: float = 2.8
var has_exploded: bool = false

# 17 columnas de dirección oficiales de StarCraft (proyectil directo orientado al lanzarse)
var facing_column: int = 8
var is_facing_left: bool = false
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	body_entered.connect(_on_body_entered)
	
	if sprite:
		var tex = SkinManager.get_sprite("devourer_acid")
		if tex:
			sprite.texture = tex
		sprite.hframes = 17
		sprite.vframes = 4
		sprite.frame = facing_column
		sprite.flip_h = is_facing_left

func setup(start_pos: Vector2, target: Vector2, dmg: float) -> void:
	global_position = start_pos
	damage = dmg
	direction = (target - start_pos).normalized()
	
	# Sin rotación por código del nodo: se orienta con el ángulo fijado al dispararse
	rotation = 0.0
	_set_direction_angle(direction)

func _set_direction_angle(dir: Vector2) -> void:
	if dir == Vector2.ZERO:
		return
	var angle_sc = fposmod(dir.angle() + PI * 0.5, TAU)
	var current_dir32 = int(round(angle_sc / (TAU / 32.0))) % 32
	if current_dir32 <= 16:
		facing_column = current_dir32
		is_facing_left = false
	else:
		facing_column = 32 - current_dir32
		is_facing_left = true
	
	if sprite:
		sprite.flip_h = is_facing_left
		sprite.frame = facing_column

func _physics_process(delta: float) -> void:
	if has_exploded:
		return
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	# Trayectoria recta fija desde el punto de lanzamiento hacia ti
	global_position += direction * speed * delta
	
	# Animación orgánica de 4 filas a lo largo de la dirección fija (sin girar ni rotar en vuelo)
	anim_timer += delta * 10.0
	var anim_row = int(anim_timer) % 4
	if sprite:
		sprite.frame = anim_row * 17 + facing_column
		sprite.flip_h = is_facing_left

func _on_body_entered(body: Node2D) -> void:
	if has_exploded:
		return
	if body.is_in_group("player"):
		AudioManager.play_sfx("devourer_hit", 0.08, 0.0)
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_devourer_acid"):
			body.apply_devourer_acid(3.0) # Moco morado y reduce mitad de armadura por 3 segundos
		_explode()

func _explode() -> void:
	if has_exploded:
		return
	has_exploded = true
	set_physics_process(false)
	
	var hit_tex = SkinManager.get_sprite("devourer_hit_fx")
	if hit_tex and sprite:
		sprite.texture = hit_tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0
		sprite.flip_h = false
		sprite.scale = Vector2(1.3, 1.3)
		var tw = create_tween()
		for f in range(1, 10):
			tw.tween_interval(0.035)
			tw.tween_callback(func():
				if sprite and is_instance_valid(sprite):
					sprite.frame = f
			)
		tw.tween_interval(0.035)
		tw.tween_callback(queue_free)
	else:
		queue_free()
