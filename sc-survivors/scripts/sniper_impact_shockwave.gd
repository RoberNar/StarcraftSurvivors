class_name SniperImpactShockwave
extends Node2D

var current_radius: float = 6.0
var line_width: float = 2.5

func _ready() -> void:
	z_index = 35
	var tw = create_tween()
	tw.tween_property(self, "current_radius", 32.0, 0.18).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(self, "modulate:a", 0.0, 0.18)
	tw.tween_callback(queue_free)

func _process(_delta: float) -> void:
	queue_redraw()

func _draw() -> void:
	draw_arc(Vector2.ZERO, current_radius, 0, TAU, 24, Color(1.0, 0.25, 0.25, modulate.a), line_width)
	draw_circle(Vector2.ZERO, current_radius * 0.45, Color(1.0, 0.88, 0.35, modulate.a * 0.6))
