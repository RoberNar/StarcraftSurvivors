class_name BossPillar
extends StaticBody2D

signal pillar_broken(pillar: BossPillar)

@export var pillar_id: int = 0
@export var opposite_id: int = 3
@export var rock_variant: int = 1 # 1 a 4
var is_destroyed: bool = false
var is_designated_target: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Sprite2D = $Shadow
@onready var dirt_base: Sprite2D = get_node_or_null("DirtBase")
@onready var target_marker: Node2D = get_node_or_null("TargetMarker")

func _ready() -> void:
	add_to_group("boss_pillars")
	opposite_id = (pillar_id + 3) % 6
	_apply_visuals()
	set_designated_target(false)

func _process(delta: float) -> void:
	if is_designated_target and target_marker and not is_destroyed:
		target_marker.visible = true
		target_marker.rotation += delta * 3.5

func set_designated_target(active: bool) -> void:
	is_designated_target = active
	if target_marker:
		target_marker.visible = active and not is_destroyed

func set_rock_variant(v: int) -> void:
	rock_variant = clampi(v, 1, 4)
	_apply_visuals()

func _apply_visuals() -> void:
	if not sprite:
		return
	
	if is_destroyed:
		var rubble_tex = load("res://assets/skins/sd/sprites/boss_pillar_rubble.png")
		if rubble_tex:
			sprite.texture = rubble_tex
			sprite.position = Vector2(0, 10)
		z_index = -3
		if shadow:
			shadow.visible = false
		if target_marker:
			target_marker.visible = false
	else:
		var rock_tex_path = "res://assets/skins/sd/sprites/boss_pillar_rock%d.png" % rock_variant
		if ResourceLoader.exists(rock_tex_path):
			sprite.texture = load(rock_tex_path)
		var shadow_tex_path = "res://assets/skins/sd/sprites/boss_pillar_shadow%d.png" % rock_variant
		if shadow and ResourceLoader.exists(shadow_tex_path):
			shadow.texture = load(shadow_tex_path)
			shadow.visible = true
		z_index = 1

# Solo con la carga del Torrasque se rompe el pilar
func break_by_charge() -> void:
	if is_destroyed:
		return
	is_destroyed = true
	is_designated_target = false
	
	AudioManager.play_sfx("pillar_smash", 0.05, 4.0)
	if collision_shape:
		collision_shape.set_deferred("disabled", true)
	
	# Sacudida y transformación a escombros
	var orig_pos = sprite.position
	var tw = create_tween()
	for i in range(5):
		tw.tween_property(sprite, "position", orig_pos + Vector2(randf_range(-6, 6), randf_range(-6, 6)), 0.03)
	tw.tween_callback(func():
		_apply_visuals()
		_spawn_debris()
		pillar_broken.emit(self)
	)

func _spawn_debris() -> void:
	for i in range(14):
		var p = Sprite2D.new()
		var rock_frag = load("res://assets/skins/sd/sprites/boundary_rock%d.png" % (randi_range(1, 4)))
		if rock_frag:
			p.texture = rock_frag
			p.scale = Vector2(0.4, 0.4)
		p.global_position = global_position + Vector2(randf_range(-20, 20), randf_range(-20, 10))
		get_parent().add_child(p)
		
		var fly_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var fly_dist = randf_range(40, 95)
		var p_tw = p.create_tween()
		p_tw.tween_property(p, "global_position", p.global_position + fly_dir * fly_dist, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.parallel().tween_property(p, "modulate:a", 0.0, 0.45)
		p_tw.tween_callback(p.queue_free)
