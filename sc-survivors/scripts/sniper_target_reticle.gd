class_name SniperTargetReticle
extends Node2D

var target_ref: Node2D = null
var current_scale: float = 1.6
var anim_timer: float = 0.0

func _ready() -> void:
	z_index = 45
	var tw = create_tween()
	tw.tween_property(self, "current_scale", 1.0, 0.12).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.tween_interval(0.26)
	tw.tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)

func _process(delta: float) -> void:
	anim_timer += delta
	if target_ref and is_instance_valid(target_ref):
		global_position = target_ref.global_position
	queue_redraw()

func _draw() -> void:
	var r = 16.0 * current_scale
	var col = Color(1.0, 0.2, 0.2, 0.95)
	var col_pulse = Color(1.0, 0.85, 0.3, 0.95)
	
	# Anillo exterior
	draw_arc(Vector2.ZERO, r, 0, TAU, 28, col, 1.5)
	
	# Paréntesis / Brackets tácticos de fijación de objetivo [ + ]
	var b_len = 6.0 * current_scale
	var b_dist = r * 1.15
	# Esquina Sup-Izq
	draw_line(Vector2(-b_dist, -b_dist + b_len), Vector2(-b_dist, -b_dist), col_pulse, 1.8)
	draw_line(Vector2(-b_dist, -b_dist), Vector2(-b_dist + b_len, -b_dist), col_pulse, 1.8)
	# Esquina Sup-Der
	draw_line(Vector2(b_dist, -b_dist + b_len), Vector2(b_dist, -b_dist), col_pulse, 1.8)
	draw_line(Vector2(b_dist, -b_dist), Vector2(b_dist - b_len, -b_dist), col_pulse, 1.8)
	# Esquina Inf-Izq
	draw_line(Vector2(-b_dist, b_dist - b_len), Vector2(-b_dist, b_dist), col_pulse, 1.8)
	draw_line(Vector2(-b_dist, b_dist), Vector2(-b_dist + b_len, b_dist), col_pulse, 1.8)
	# Esquina Inf-Der
	draw_line(Vector2(b_dist, b_dist - b_len), Vector2(b_dist, b_dist), col_pulse, 1.8)
	draw_line(Vector2(b_dist, b_dist), Vector2(b_dist - b_len, b_dist), col_pulse, 1.8)
	
	# Líneas de cruceta
	var inner_gap = 5.0 * current_scale
	var outer_len = r * 1.35
	draw_line(Vector2(0, -inner_gap), Vector2(0, -outer_len), col, 1.5)
	draw_line(Vector2(0, inner_gap), Vector2(0, outer_len), col, 1.5)
	draw_line(Vector2(-inner_gap, 0), Vector2(-outer_len, 0), col, 1.5)
	draw_line(Vector2(inner_gap, 0), Vector2(outer_len, 0), col, 1.5)
	
	# Punto central láser de precisión
	draw_circle(Vector2.ZERO, 2.5, Color(1.0, 0.3, 0.3, 1.0))
