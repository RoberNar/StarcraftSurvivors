class_name FlameAttack
extends Area2D

@export var speed: float = 70.0
@export var damage: float = 24.0
@export var lifetime: float = 0.32
@export var aoe_mult: float = 1.0

var direction: Vector2 = Vector2.RIGHT
var timer: float = 0.0
var hit_enemies: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	if collision and collision.shape is CircleShape2D:
		collision.shape = collision.shape.duplicate()
		collision.shape.radius = 22.0 * aoe_mult

func _process(delta: float) -> void:
	timer += delta
	global_position += direction * speed * delta
	
	# Animación de 13 frames auténticos de fuego de Firebat (flamer.grp)
	if sprite:
		var frame_idx = int((timer / lifetime) * 13.0)
		sprite.frame = clampi(frame_idx, 0, 12)
		sprite.scale = Vector2.ONE
	
	if timer >= lifetime:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not hit_enemies.has(body.get_instance_id()):
		hit_enemies[body.get_instance_id()] = true
		if body.has_method("take_damage"):
			body.take_damage(damage)
