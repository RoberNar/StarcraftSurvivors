class_name RadarDisplay
extends Control

var radar_range: float = 520.0
var anim_t: float = 0.0

func _process(delta: float) -> void:
	anim_t += delta * 4.0
	queue_redraw()

func _draw() -> void:
	var size_rect = size
	var center = size_rect * 0.5
	var max_radius = min(size_rect.x, size_rect.y) * 0.45
	var scale_factor = max_radius / radar_range
	
	# 1. Fondo del radar militar terran
	draw_rect(Rect2(Vector2.ZERO, size_rect), Color(0.02, 0.04, 0.03, 0.92), true)
	draw_rect(Rect2(Vector2.ZERO, size_rect), Color(0.12, 0.35, 0.2, 0.7), false, 1.0)
	
	# Círculos concéntricos de rango
	draw_arc(center, max_radius * 0.5, 0, TAU, 24, Color(0.08, 0.22, 0.12, 0.5), 1.0)
	draw_arc(center, max_radius, 0, TAU, 32, Color(0.15, 0.45, 0.25, 0.65), 1.0)
	
	# Cruz táctica
	draw_line(Vector2(center.x, 3), Vector2(center.x, size_rect.y - 3), Color(0.08, 0.25, 0.12, 0.4), 1.0)
	draw_line(Vector2(3, center.y), Vector2(size_rect.x - 3, center.y), Color(0.08, 0.25, 0.12, 0.4), 1.0)
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var p_pos = player.global_position
	
	# 2. Minerales normales (puntos celestes sutiles)
	var minerals = get_tree().get_nodes_in_group("collectibles")
	for m in minerals:
		if is_instance_valid(m) and not m.is_in_group("vespene_tanks"):
			var rel = m.global_position - p_pos
			if rel.length() <= radar_range:
				var r_pos = center + rel * scale_factor
				draw_circle(r_pos, 1.0, Color(0.2, 0.7, 1.0, 0.65))
	
	# 3. Enemigos Zerg (puntos rojos)
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e) and not ("is_dead" in e and e.is_dead) and not ("is_destroyed" in e and e.is_destroyed):
			var rel = e.global_position - p_pos
			if rel.length() <= radar_range:
				var r_pos = center + rel * scale_factor
				draw_circle(r_pos, 1.4, Color(1.0, 0.18, 0.18, 0.85))
	
	# 4. Jefes Ultralisco (círculo rojo-naranja grande y pulsante)
	var bosses = get_tree().get_nodes_in_group("bosses")
	for b in bosses:
		if is_instance_valid(b) and not ("is_dead" in b and b.is_dead) and not ("is_destroyed" in b and b.is_destroyed):
			var rel = b.global_position - p_pos
			if rel.length() <= radar_range:
				var r_pos = center + rel * scale_factor
				draw_circle(r_pos, 3.2, Color(1.0, 0.45, 0.1, 0.95))
			else:
				var dir = rel.normalized()
				var rim_pos = center + dir * max_radius
				_draw_triangle_marker(rim_pos, dir, Color(1.0, 0.35, 0.1, 0.9), 4.5)
	
	# 5. OBJETIVOS DE MISIÓN: Tanques de Gas Vespeno (rombos verdes brillantes)
	var tanks = get_tree().get_nodes_in_group("vespene_tanks")
	for t in tanks:
		if is_instance_valid(t):
			var rel = t.global_position - p_pos
			var dist = rel.length()
			if dist <= radar_range:
				var r_pos = center + rel * scale_factor
				_draw_diamond_marker(r_pos, Color(0.2, 1.0, 0.35, 1.0), 3.0)
			else:
				# Baliza direccional en el borde del minimapa
				var dir = rel.normalized()
				var rim_pos = center + dir * (max_radius - 1.0)
				_draw_triangle_marker(rim_pos, dir, Color(0.25, 1.0, 0.4, 0.95), 4.0)
	
	# 6. OBJETIVO DE EXTRACCIÓN: Baliza de Evacuación / Dropship
	var evac = get_tree().get_first_node_in_group("evacuation_zone")
	if evac and is_instance_valid(evac):
		var rel = evac.global_position - p_pos
		var dist = rel.length()
		var is_ready = GameManager.is_mission_completed
		var evac_col = Color(0.2, 1.0, 0.45, 1.0) if is_ready else Color(0.3, 0.85, 1.0, 0.9)
		if is_ready:
			evac_col.a = 0.7 + sin(anim_t) * 0.3
		
		if dist <= radar_range:
			var r_pos = center + rel * scale_factor
			draw_rect(Rect2(r_pos - Vector2(3, 3), Vector2(6, 6)), evac_col, true)
		else:
			var dir = rel.normalized()
			var rim_pos = center + dir * (max_radius - 2.0)
			_draw_triangle_marker(rim_pos, dir, evac_col, 5.0)
	
	# 7. Marine jugador en el centro (punto verde lima)
	draw_circle(center, 2.5, Color(0.3, 1.0, 0.4, 1.0))
	draw_arc(center, 4.0, 0, TAU, 12, Color(0.4, 1.0, 0.5, 0.5), 1.0)

func _draw_diamond_marker(pos: Vector2, col: Color, sz: float) -> void:
	var pts = PackedVector2Array([
		pos + Vector2(0, -sz),
		pos + Vector2(sz, 0),
		pos + Vector2(0, sz),
		pos + Vector2(-sz, 0)
	])
	draw_colored_polygon(pts, col)

func _draw_triangle_marker(pos: Vector2, dir: Vector2, col: Color, sz: float) -> void:
	var norm = Vector2(-dir.y, dir.x)
	var p_tip = pos + dir * sz
	var p_left = pos - dir * (sz * 0.5) + norm * (sz * 0.7)
	var p_right = pos - dir * (sz * 0.5) - norm * (sz * 0.7)
	draw_colored_polygon(PackedVector2Array([p_tip, p_left, p_right]), col)

func _draw_mission_label(size_rect: Vector2) -> void:
	var m = GameManager.get_current_mission()
	var font = ThemeDB.fallback_font
	var font_size = 9
	if font == null:
		return
	
	var text = ""
	var col = Color(1.0, 0.85, 0.3, 0.95)
	if GameManager.is_mission_completed:
		text = "★ LISTO: EVACUAR"
		col = Color(0.25, 1.0, 0.4, 0.7 + sin(anim_t) * 0.3)
	else:
		match m.get("type", ""):
			"kills":
				text = "🎯 ZERGS: %d/%d" % [GameManager.mission_kills, m.get("target_count", 100)]
			"gas":
				text = "🧪 GAS: %d/%d" % [GameManager.mission_gas, m.get("target_count", 10)]
			"boss":
				var b_str = "JEFE OK" if GameManager.mission_bosses >= 1 else "MATAR JEFE"
				text = "🎯 %d/200 | %s" % [GameManager.mission_kills, b_str]
			"combined":
				text = "🧪 %d/20 | 🎯 %d/300" % [GameManager.mission_gas, GameManager.mission_kills]
			_:
				text = "🎯 OBJETIVO ACTIVO"
	
	# Dibujar fondo translúcido y texto centrado arriba del radar
	var str_sz = font.get_string_size(text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
	var bg_rect = Rect2(Vector2((size_rect.x - str_sz.x) * 0.5 - 4, 3), Vector2(str_sz.x + 8, font_size + 4))
	draw_rect(bg_rect, Color(0.01, 0.03, 0.02, 0.8), true)
	draw_rect(bg_rect, Color(col.r, col.g, col.b, 0.5), false, 1.0)
	draw_string(font, Vector2((size_rect.x - str_sz.x) * 0.5, font_size + 3), text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, col)
