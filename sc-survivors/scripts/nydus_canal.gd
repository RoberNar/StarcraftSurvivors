class_name NydusCanal
extends Node2D

@onready var sprite: Sprite2D = $Sprite2D
@onready var entrance_area: Area2D = $EntranceArea
@onready var hint_bubble: Panel = $HintBubble
@onready var hint_label: Label = $HintBubble/Label

var is_player_nearby: bool = false
var has_triggered_descent: bool = false
var is_emerged: bool = false

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
	
	if hint_bubble:
		hint_bubble.visible = false
	
	if entrance_area:
		entrance_area.body_entered.connect(_on_body_entered)
		entrance_area.body_exited.connect(_on_body_exited)
	
	AudioManager.play_sfx("nydus_emerge", 0.05, 4.0)
	
	# Animación de emergencia del suelo
	var tw = create_tween()
	for f in range(5):
		tw.tween_callback(func(): if is_instance_valid(sprite): sprite.frame = f)
		tw.tween_interval(0.18)
	
	tw.tween_callback(func():
		is_emerged = true
		if is_player_nearby and hint_bubble:
			hint_bubble.visible = true
		
		# Pulso respiratorio zerg una vez emergido
		var loop_tw = create_tween().set_loops()
		loop_tw.tween_property(sprite, "scale", Vector2(1.9, 1.9), 0.8).set_trans(Tween.TRANS_SINE)
		loop_tw.tween_property(sprite, "scale", Vector2(1.75, 1.75), 0.8).set_trans(Tween.TRANS_SINE)
	)

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = true
		if is_emerged and hint_bubble:
			hint_bubble.visible = true

func _on_body_exited(body: Node2D) -> void:
	if body.is_in_group("player"):
		is_player_nearby = false
		if hint_bubble:
			hint_bubble.visible = false

func _unhandled_input(event: InputEvent) -> void:
	if not is_emerged or has_triggered_descent:
		return
	if is_player_nearby and event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_E or event.keycode == KEY_SPACE or event.is_action_pressed("ui_accept"):
			_trigger_descent_into_cave()
			get_viewport().set_input_as_handled()

func _process(_delta: float) -> void:
	if not is_emerged or has_triggered_descent:
		return
	
	# Si el jugador camina directo hacia la boca central del nydus (distancia < 24)
	var player = get_tree().get_first_node_in_group("player") as Player
	if is_instance_valid(player):
		var dist = (player.global_position - global_position).length()
		if dist <= 28.0:
			_trigger_descent_into_cave()

func _trigger_descent_into_cave() -> void:
	if has_triggered_descent:
		return
	has_triggered_descent = true
	
	if hint_bubble:
		hint_bubble.visible = false
	
	var player = get_tree().get_first_node_in_group("player") as Player
	if is_instance_valid(player):
		# Guardar estado actual del jugador para la arena
		GameManager.save_player_state(player)
		player.set_physics_process(false)
		
		# Sonido de deglución y temblor subterráneo
		AudioManager.play_sfx("burrow_down", 0.0, 4.0)
		
		# Animación del jugador siendo absorbido por el nydus
		var p_tw = player.create_tween()
		p_tw.tween_property(player, "global_position", global_position, 0.45).set_trans(Tween.TRANS_QUAD)
		p_tw.parallel().tween_property(player, "scale", Vector2(0.1, 0.1), 0.45)
		p_tw.tween_interval(0.2)
		p_tw.tween_callback(func():
			get_tree().change_scene_to_file("res://scenes/boss_cave_arena.tscn")
		)
	else:
		get_tree().change_scene_to_file("res://scenes/boss_cave_arena.tscn")
