class_name Bullet
extends Area2D

var direction: Vector2 = Vector2.RIGHT
var speed: float = 850.0
var damage: float = 12.0
var max_range: float = 400.0
var traveled: float = 0.0
var has_explosive: bool = false
var explosive_radius: float = 45.0
var explosive_damage: float = 8.0

var pierce_count: int = 1
var is_sniper: bool = false

func _ready() -> void:
	rotation = direction.angle()
	body_entered.connect(_on_body_entered)
	if is_sniper:
		var tr = get_node_or_null("Tracer") as Line2D
		if tr:
			tr.width = 3.5
			tr.points = PackedVector2Array([-36, 0, 8, 0])
			tr.default_color = Color(1.0, 0.25, 0.25, 1.0)

func _physics_process(delta: float) -> void:
	var move_dist = speed * delta
	position += direction * move_dist
	traveled += move_dist
	if traveled >= max_range:
		queue_free()

func _on_body_entered(body: Node2D) -> void:
	if body.is_in_group("enemies"):
		hit_enemy(body)

func hit_enemy(enemy: Node2D) -> void:
	if enemy.has_method("take_damage"):
		enemy.take_damage(damage)
	
	if has_explosive:
		_explode()
	
	if is_sniper:
		_spawn_sniper_impact_fx(enemy)
	else:
		_spawn_spark()
	
	pierce_count -= 1
	if pierce_count <= 0:
		queue_free()

func _spawn_sniper_impact_fx(enemy: Node2D) -> void:
	var target_sprite = enemy.get_node_or_null("Sprite2D")
	if target_sprite and target_sprite is CanvasItem:
		var orig_mod = target_sprite.modulate
		target_sprite.modulate = Color(3.0, 0.35, 0.35, 1.0)
		var tw_mod = target_sprite.create_tween()
		tw_mod.tween_property(target_sprite, "modulate", orig_mod, 0.2)
	elif enemy is CanvasItem:
		var orig_mod = enemy.modulate
		enemy.modulate = Color(3.0, 0.35, 0.35, 1.0)
		var tw_mod = enemy.create_tween()
		tw_mod.tween_property(enemy, "modulate", orig_mod, 0.2)
	
	var shockwave_scene = load("res://scripts/sniper_impact_shockwave.gd")
	if shockwave_scene:
		var sw = Node2D.new()
		sw.global_position = global_position
		sw.set_script(shockwave_scene)
		get_parent().add_child(sw)
	
	_spawn_spark()

func _explode() -> void:
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and e.global_position.distance_to(global_position) <= explosive_radius:
			if e.has_method("take_damage"):
				e.take_damage(explosive_damage)

func _spawn_spark() -> void:
	# Spark/blood splash
	var sp = Sprite2D.new()
	sp.texture = SkinManager.get_sprite("blood_hit")
	sp.hframes = 15
	sp.vframes = 1
	sp.frame = randi() % 5
	sp.global_position = global_position
	sp.scale = Vector2(0.6, 0.6)
	get_parent().add_child(sp)
	var tw = sp.create_tween()
	tw.tween_property(sp, "modulate:a", 0.0, 0.25)
	tw.tween_callback(sp.queue_free)
