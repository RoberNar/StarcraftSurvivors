class_name QueenEnsnareProjectile
extends Area2D

@export var speed: float = 270.0
@export var damage: float = 14.0

var direction: Vector2 = Vector2.ZERO
var lifetime: float = 2.2
var has_hit: bool = false

@onready var sprite: Sprite2D = $Sprite2D
var anim_timer: float = 0.0

func _ready() -> void:
	collision_layer = 0
	collision_mask = 1 # Player layer
	body_entered.connect(_on_body_entered)
	
	if sprite:
		var tex = SkinManager.get_sprite("queen_ensnare")
		if tex:
			sprite.texture = tex
		sprite.hframes = 8
		sprite.vframes = 2
		sprite.frame = 0

func setup(start_pos: Vector2, target: Vector2, dmg: float) -> void:
	global_position = start_pos
	damage = dmg
	direction = (target - start_pos).normalized()
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	if has_hit:
		return
	
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	
	global_position += direction * speed * delta
	anim_timer += delta * 14.0
	if sprite:
		sprite.frame = int(anim_timer) % 15

func _on_body_entered(body: Node2D) -> void:
	if has_hit:
		return
	if body.is_in_group("player"):
		has_hit = true
		set_physics_process(false)
		if body.has_method("take_damage"):
			body.take_damage(damage)
		if body.has_method("apply_slow"):
			body.apply_slow(0.25, 3.0) # 25% ralentización durante 3.0s
		
		# Animación de disipación de baba
		var tw = create_tween()
		tw.tween_property(sprite, "modulate:a", 0.0, 0.25)
		tw.tween_callback(queue_free)
