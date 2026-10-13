class_name VespeneTank
extends Area2D

@export var gas_value: int = 1
var target: Node2D = null
var speed: float = 0.0
var max_speed: float = 480.0
var acceleration: float = 750.0
var anim_timer: float = 0.0

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	add_to_group("vespene_tanks")
	add_to_group("collectibles")
	var tw = create_tween()
	var offset = Vector2(randf_range(-10, 10), randf_range(-10, 10))
	tw.tween_property(self, "position", position + offset, 0.25).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	anim_timer += delta * 4.0
	if sprite:
		sprite.position.y = sin(anim_timer) * 3.0
	
	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		var dist = global_position.distance_to(target.global_position)
		speed = move_toward(speed, max_speed, acceleration * delta)
		global_position += dir * speed * delta
		
		if dist < 18.0:
			collect()

func attract_to(player: Node2D) -> void:
	if target == null:
		target = player

func collect() -> void:
	AudioManager.play_sfx("vespene_pickup")
	var final_gas = gas_value
	if GameManager.get_barracks_bonus("vespene_doubler") > 0.0:
		final_gas *= 2
	GameManager.add_gas(final_gas)
	_spawn_floating_text(final_gas)
	queue_free()

func _spawn_floating_text(amount: int = 1) -> void:
	var label = Label.new()
	label.text = "+%d GAS VESPENO" % amount
	label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.35, 1.0))
	label.add_theme_color_override("font_shadow_color", Color(0, 0.2, 0.1, 0.9))
	label.add_theme_constant_override("shadow_offset_x", 1)
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.add_theme_font_size_override("font_size", 12)
	label.global_position = global_position + Vector2(-45, -25)
	var parent = get_tree().current_scene
	if parent:
		parent.add_child(label)
		var tw = label.create_tween()
		tw.tween_property(label, "position:y", label.position.y - 25.0, 0.85)
		tw.parallel().tween_property(label, "modulate:a", 0.0, 0.85)
		tw.tween_callback(label.queue_free)
