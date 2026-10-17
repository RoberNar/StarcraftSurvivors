class_name LemonJuiceExplosion
extends Area2D

@export var splash_damage: float = 16.0
@export var dot_damage: float = 8.0
@export var duration: float = 0.6
@export var slow_ratio: float = 0.10

var timer: float = 0.0
var hit_bodies: Dictionary = {}

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player_attacks")
	AudioManager.play_sfx("lemon_splash", 0.08, 1.0)
	AudioManager.play_sfx("lemon_squirt", 0.08, -3.0)
	if sprite:
		sprite.hframes = 15
		var tex = SkinManager.get_sprite("lemon_splash")
		if tex:
			sprite.texture = tex
		sprite.scale = Vector2(1.25, 1.25)
	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	timer += delta
	if sprite:
		sprite.frame = clampi(int((timer / duration) * 15.0), 0, 14)
	if timer >= duration:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies") and not hit_bodies.has(body.get_instance_id()):
		hit_bodies[body.get_instance_id()] = true
		if body.has_method("take_damage"):
			body.take_damage(splash_damage)
		if body.has_method("apply_lemon_juice"):
			body.apply_lemon_juice(dot_damage, 4.0, slow_ratio)
