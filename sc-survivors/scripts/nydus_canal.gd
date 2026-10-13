class_name NydusCanal
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	z_index = -1
	z_as_relative = false
	if sprite:
		var tex = SkinManager.get_sprite("nydus")
		if tex:
			sprite.texture = tex
		sprite.hframes = 1
		sprite.vframes = 5
		sprite.frame = 0
		sprite.scale = Vector2(1.8, 1.8)
	
	AudioManager.play_sfx("nydus_emerge", 0.05, 4.0)
	
	# Animación de emergencia del suelo
	var tw = create_tween()
	for f in range(5):
		tw.tween_callback(func(): if is_instance_valid(sprite): sprite.frame = f)
		tw.tween_interval(0.18)
	
	# Pulso respiratorio zerg una vez emergido
	tw.tween_callback(func():
		var loop_tw = create_tween().set_loops()
		loop_tw.tween_property(sprite, "scale", Vector2(1.9, 1.9), 0.8).set_trans(Tween.TRANS_SINE)
		loop_tw.tween_property(sprite, "scale", Vector2(1.75, 1.75), 0.8).set_trans(Tween.TRANS_SINE)
	)
