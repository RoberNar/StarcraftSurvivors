class_name MineralChunk
extends Area2D

@export var xp_value: int = 10
var is_rainbow: bool = false
var target: Node2D = null
var speed: float = 0.0
var max_speed: float = 500.0
var acceleration: float = 800.0
var anim_timer: float = 0.0
var sprite: Sprite2D = null

func _ready() -> void:
	add_to_group("collectibles")
	_apply_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(_on_skin_changed)

func _on_skin_changed(_new_skin: String) -> void:
	_apply_skin()

func _apply_skin() -> void:
	if sprite == null:
		sprite = get_node_or_null("Sprite2D")
	if sprite:
		var tex = SkinManager.get_sprite("mineral_chunk")
		if tex:
			sprite.texture = tex
		sprite.hframes = 8
		sprite.vframes = 3
		if is_rainbow:
			sprite.scale = Vector2(1.5, 1.5)
			xp_value = 100
	
	# Efecto de spawn pequeño salto
	var tw = create_tween()
	var offset = Vector2(randf_range(-12, 12), randf_range(-12, 12))
	tw.tween_property(self, "position", position + offset, 0.2).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

func _physics_process(delta: float) -> void:
	# Brillo suave animado
	anim_timer += delta * 6.0
	if sprite:
		if sprite.vframes > 0:
			sprite.frame = int(anim_timer) % 17
		if is_rainbow:
			# Efecto arcoíris brillante pulsante
			sprite.modulate = Color.from_hsv(fmod(anim_timer * 0.45, 1.0), 0.9, 1.4)
			sprite.scale = Vector2.ONE * (1.5 + sin(anim_timer * 3.5) * 0.15)

	if target and is_instance_valid(target):
		var dir = (target.global_position - global_position).normalized()
		var dist = global_position.distance_to(target.global_position)
		speed = move_toward(speed, max_speed, acceleration * delta)
		global_position += dir * speed * delta
		
		if dist < 22.0:
			collect()

func attract_to(player: Node2D) -> void:
	if target == null:
		target = player

static var last_pickup_sfx_time: float = 0.0

func collect() -> void:
	var now = Time.get_ticks_msec() / 1000.0
	if is_rainbow:
		_trigger_vacuum_effect()
		GameManager.add_xp(xp_value)
		AudioManager.play_sfx("pickup", 0.0, 4.0)
		queue_free()
		return

	GameManager.add_xp(xp_value)
	if now - last_pickup_sfx_time >= 0.055:
		last_pickup_sfx_time = now
		AudioManager.play_sfx("pickup")
	queue_free()

func _trigger_vacuum_effect() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
	
	var all_collectibles = get_tree().get_nodes_in_group("collectibles")
	var count = all_collectibles.size()
	var immediate_xp: int = 0
	var immediate_minerals: int = 0
	
	for c in all_collectibles:
		if is_instance_valid(c) and c != self:
			if c is MineralChunk:
				c.set_deferred("collision_layer", 0)
				if count > 40 and c.global_position.distance_to(player.global_position) > 380.0:
					immediate_xp += c.xp_value
					immediate_minerals += 1
					c.queue_free()
				else:
					c.target = player
					c.speed = max(c.speed, 350.0)
					c.max_speed = 950.0
					c.acceleration = 2400.0
			elif c.has_method("attract_to"):
				c.attract_to(player)
				c.speed = max(c.speed, 350.0)

	if immediate_xp > 0:
		GameManager.add_xp(immediate_xp, immediate_minerals)

	
