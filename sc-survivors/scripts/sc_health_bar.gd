class_name SCHealthBar
extends Control

@export var max_health: float = 40.0
@export var current_health: float = 40.0
@export var segment_count: int = 14

func set_health(cur: float, m: float) -> void:
	current_health = clamp(cur, 0.0, m)
	max_health = max(1.0, m)
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	# Fondo negro
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.05, 0.05, 0.05, 0.95), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.25, 0.3, 0.35, 1.0), false, 1.0)
	
	var pct = current_health / max_health
	var active_segments = int(round(pct * segment_count))
	
	var col = Color(0.1, 0.95, 0.2, 1.0) # Verde SC1
	if pct <= 0.33:
		col = Color(0.95, 0.15, 0.15, 1.0) # Rojo SC1
	elif pct <= 0.66:
		col = Color(0.95, 0.85, 0.1, 1.0) # Amarillo SC1
		
	var seg_w = (w - 2.0 - (segment_count - 1)) / segment_count
	for i in range(segment_count):
		var x = 1.0 + i * (seg_w + 1.0)
		var seg_rect = Rect2(Vector2(x, 1.0), Vector2(seg_w, h - 2.0))
		if i < active_segments:
			draw_rect(seg_rect, col, true)
		else:
			draw_rect(seg_rect, Color(0.15, 0.15, 0.18, 0.7), true)
