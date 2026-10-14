class_name BossPillar
extends StaticBody2D

signal pillar_broken(pillar: BossPillar)

@export var pillar_id: int = 0
@export var opposite_id: int = 3
var is_destroyed: bool = false
var is_designated_target: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Sprite2D = $Shadow
@onready var target_marker: Node2D = get_node_or_null("TargetMarker")

func _ready() -> void:
	add_to_group("boss_pillars")
	opposite_id = (pillar_id + 3) % 6
	if shadow and not shadow.texture:
		var sh_tex = SkinManager.get_sprite("marine_shadow")
		if sh_tex:
			shadow.texture = sh_tex
			shadow.hframes = 17
			shadow.vframes = 14
			shadow.frame = 8
			shadow.scale = Vector2(2.6, 1.3)
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

func _apply_visuals() -> void:
	if not sprite:
		return
	if is_destroyed:
		var rubble_tex = SkinManager.get_sprite("boss_pillar_rubble")
		if rubble_tex:
			sprite.texture = rubble_tex
			sprite.position = Vector2(0, 8)
			sprite.scale = Vector2(0.85, 0.85)
		z_index = -1
		if shadow:
			shadow.visible = false
		if target_marker:
			target_marker.visible = false
	else:
		var pillar_tex = SkinManager.get_sprite("boss_pillar")
		if pillar_tex:
			sprite.texture = pillar_tex
		z_index = 2
		if shadow:
			shadow.visible = true

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
		tw.tween_property(sprite, "position", orig_pos + Vector2(randf_range(-5, 5), randf_range(-5, 5)), 0.03)
	tw.tween_callback(func():
		_apply_visuals()
		_spawn_debris()
		pillar_broken.emit(self)
	)

func _spawn_debris() -> void:
	for i in range(12):
		var p = Sprite2D.new()
		var blood_or_debris = SkinManager.get_sprite("mineral_chunk")
		if blood_or_debris:
			p.texture = blood_or_debris
			p.modulate = Color(0.4, 0.35, 0.3, 0.9)
			p.scale = Vector2(0.3, 0.3)
		p.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-24, 8))
		get_parent().add_child(p)
		
		var fly_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var fly_dist = randf_range(30, 80)
		var p_tw = p.create_tween()
		p_tw.tween_property(p, "global_position", p.global_position + fly_dir * fly_dist, 0.4).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.parallel().tween_property(p, "modulate:a", 0.0, 0.4)
		p_tw.tween_callback(p.queue_free)
