class_name PsionicStorm
extends Area2D

@export var damage_per_tick: float = 34.0
@export var duration: float = 2.2
@export var tick_interval: float = 0.28

var timer: float = 0.0
var tick_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision: CollisionShape2D = $CollisionShape2D

func _ready() -> void:
	add_to_group("player_attacks")
	AudioManager.play_sfx("psistorm", 0.05, 1.5)
	if sprite:
		sprite.hframes = 14
		var tex = SkinManager.get_sprite("psistorm")
		if tex:
			sprite.texture = tex
		sprite.scale = Vector2(0.9, 0.9)
	_damage_enemies_inside()

func _process(delta: float) -> void:
	timer += delta
	tick_timer += delta
	
	if sprite:
		sprite.frame = int((timer / duration) * 14.0) % 14
	
	if tick_timer >= tick_interval:
		tick_timer = 0.0
		_damage_enemies_inside()
	
	if timer >= duration:
		queue_free()

func _damage_enemies_inside() -> void:
	var bodies = get_overlapping_bodies()
	for b in bodies:
		if b.is_in_group("enemies") and b.has_method("take_damage"):
			b.take_damage(damage_per_tick)
