class_name SCTacticalDisplay
extends Control

var anim_phase: float = 0.0

func _process(delta: float) -> void:
	anim_phase += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var w = size.x
	var h = size.y
	# Fondo azul marino oscuro de terminal SC
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.02, 0.04, 0.08, 0.95), true)
	draw_rect(Rect2(Vector2.ZERO, size), Color(0.1, 0.25, 0.45, 0.8), false, 1.0)
	
	# Lineas horizontales de scanline
	for y in range(2, int(h) - 2, 4):
		draw_line(Vector2(2, y), Vector2(w - 2, y), Color(0.05, 0.15, 0.25, 0.35), 1.0)
	
	# Onda senoidal de telemetría táctica (ECG / señal de combate)
	var pts: Array[Vector2] = []
	var player = get_tree().get_first_node_in_group("player")
	var is_stim = player and player.stimpack_active
	var wave_color = Color(1.0, 0.25, 0.25, 0.95) if is_stim else Color(0.2, 0.85, 0.4, 0.85)
	
	for x in range(2, int(w) - 2, 2):
		var nx = float(x) / w
		var freq = 12.0 if is_stim else 6.0
		var amp = (h * 0.25) if is_stim else (h * 0.15)
		var y = h * 0.5 + sin(nx * freq + anim_phase) * amp
		pts.append(Vector2(x, y))
	
	for i in range(pts.size() - 1):
		draw_line(pts[i], pts[i + 1], wave_color, 1.5)
	
	# Retícula de mira central
	var cx = w * 0.5
	var cy = h * 0.5
	draw_arc(Vector2(cx, cy), 12.0, 0, TAU, 16, Color(0.2, 0.5, 0.8, 0.5), 1.0)
