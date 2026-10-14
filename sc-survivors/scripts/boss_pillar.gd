class_name BossPillar
extends StaticBody2D

signal pillar_damaged(pillar: BossPillar, hits_left: int)
signal pillar_destroyed(pillar: BossPillar)

@export var max_hits: int = 2
var current_hits: int = 2
var is_crumbled: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var collision_shape: CollisionShape2D = $CollisionShape2D
@onready var shadow: Sprite2D = $Shadow

func _ready() -> void:
	add_to_group("boss_pillars")
	current_hits = max_hits
	_apply_visuals()

func _apply_visuals() -> void:
	if not sprite:
		return
	if is_crumbled:
		var rubble_tex = SkinManager.get_sprite("boss_pillar_rubble")
		if rubble_tex:
			sprite.texture = rubble_tex
			sprite.position = Vector2(0, 8)
			sprite.scale = Vector2(0.85, 0.85)
		z_index = -1
		if shadow:
			shadow.visible = false
	elif current_hits == 1:
		var cracked_tex = SkinManager.get_sprite("boss_pillar_cracked")
		if cracked_tex:
			sprite.texture = cracked_tex
		z_index = 2
		if shadow:
			shadow.visible = true
	else:
		var pillar_tex = SkinManager.get_sprite("boss_pillar")
		if pillar_tex:
			sprite.texture = pillar_tex
		z_index = 2
		if shadow:
			shadow.visible = true

func hit_by_boss_charge() -> bool:
	if is_crumbled:
		return false
	
	current_hits -= 1
	
	# Sacudida del pilar y partículas
	var tw = create_tween()
	var orig_pos = sprite.position
	for i in range(4):
		tw.tween_property(sprite, "position", orig_pos + Vector2(randf_range(-4, 4), randf_range(-4, 4)), 0.04)
	tw.tween_property(sprite, "position", orig_pos, 0.04)
	
	if current_hits > 0:
		# Primer impacto: agrietado severo
		AudioManager.play_sfx("pillar_crack", 0.05, 3.0)
		_apply_visuals()
		pillar_damaged.emit(self, current_hits)
		_spawn_debris(false)
		return true
	else:
		# Segundo impacto: destrucción total en escombros
		is_crumbled = true
		AudioManager.play_sfx("pillar_smash", 0.05, 4.0)
		if collision_shape:
			collision_shape.set_deferred("disabled", true)
		_apply_visuals()
		pillar_destroyed.emit(self)
		_spawn_debris(true)
		return true

func _spawn_debris(is_total_destruction: bool) -> void:
	# Efecto visual de polvo y rocas desprendidas
	var particles_count = 12 if is_total_destruction else 6
	for i in range(particles_count):
		var p = Sprite2D.new()
		var blood_or_debris = SkinManager.get_sprite("mineral_chunk")
		if blood_or_debris:
			p.texture = blood_or_debris
			p.modulate = Color(0.4, 0.35, 0.3, 0.9)
			p.scale = Vector2(0.25, 0.25)
		p.global_position = global_position + Vector2(randf_range(-16, 16), randf_range(-24, 8))
		get_parent().add_child(p)
		
		var fly_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		var fly_dist = randf_range(30, 75)
		var p_tw = p.create_tween()
		p_tw.tween_property(p, "global_position", p.global_position + fly_dir * fly_dist, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
		p_tw.parallel().tween_property(p, "modulate:a", 0.0, 0.35)
		p_tw.tween_callback(p.queue_free)
