class_name TreasureChest
extends Node2D

@export var pickup_radius: float = 65.0
var is_collected: bool = false
var float_offset: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("collectibles")
	# Animacion de brillo sutil neutro sin tinte dorado
	var tw = create_tween().set_loops()
	tw.tween_property(sprite, "modulate", Color(1.25, 1.25, 1.25, 1.0), 0.6)
	tw.tween_property(sprite, "modulate", Color(1.0, 1.0, 1.0, 1.0), 0.6)

func _process(delta: float) -> void:
	if is_collected:
		return
	
	float_offset += delta * 4.0
	sprite.position.y = sin(float_offset) * 3.0
	if sprite.hframes > 1:
		sprite.frame = int(float_offset * 6.0) % sprite.hframes
	
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player):
		var dist = global_position.distance_to(player.global_position)
		if dist <= pickup_radius:
			collect()

func attract_to(player: Node2D) -> void:
	collect()

func collect() -> void:
	if is_collected:
		return
	is_collected = true
	remove_from_group("collectibles")
	
	AudioManager.play_sfx("marine_ready")
	
	# Efecto de succion al jugador
	var tw = create_tween()
	tw.tween_property(self, "scale", Vector2(1.5, 1.5), 0.15)
	tw.tween_property(self, "scale", Vector2.ZERO, 0.2)
	tw.tween_callback(func():
		GameManager.trigger_chest_reward()
		queue_free()
	)
