class_name BaseMinimap
extends Control

const MAP_W: float = 1920.0
const MAP_H: float = 1152.0

var pulse_t: float = 0.0

func _process(delta: float) -> void:
	pulse_t += delta * 5.0
	queue_redraw()

func _draw() -> void:
	var sz = size
	
	# Fondo de monitor táctico militar
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.03, 0.06, 0.11, 0.94), true)
	draw_rect(Rect2(Vector2.ZERO, sz), Color(0.2, 0.55, 0.85, 0.9), false, 1.5)
	
	# Líneas de cuadrícula táctica
	draw_line(Vector2(sz.x * 0.5, 0), Vector2(sz.x * 0.5, sz.y), Color(0.12, 0.28, 0.45, 0.4), 1.0)
	draw_line(Vector2(0, sz.y * 0.5), Vector2(sz.x, sz.y * 0.5), Color(0.12, 0.28, 0.45, 0.4), 1.0)
	
	# Puntos clave del Campamento Terran
	var font = ThemeDB.fallback_font
	var font_sz = 8
	
	# 1. Centro de Mando Terran
	var cmd_tex = SkinManager.get_building("command_center")
	if cmd_tex:
		var cmd_nx = (950.0 / MAP_W) * sz.x
		var cmd_ny = (320.0 / MAP_H) * sz.y
		draw_texture_rect(cmd_tex, Rect2(Vector2(cmd_nx - 8, cmd_ny - 7), Vector2(16, 14)), false)
	
	# 2. Comandante Hollis Voss
	var voss_tex = SkinManager.get_building("npc_officer")
	var npc = get_tree().get_first_node_in_group("npc")
	var voss_pos = npc.global_position if (npc and is_instance_valid(npc)) else Vector2(880, 700)
	var voss_nx = (voss_pos.x / MAP_W) * sz.x
	var voss_ny = (voss_pos.y / MAP_H) * sz.y
	if voss_tex:
		draw_texture_rect(voss_tex, Rect2(Vector2(voss_nx - 6, voss_ny - 6), Vector2(12, 12)), false)
	else:
		draw_circle(Vector2(voss_nx, voss_ny), 3.0, Color(1.0, 0.85, 0.25, 1.0))
	if font:
		draw_string(font, Vector2(voss_nx - 14, voss_ny - 8), "VOSS", HORIZONTAL_ALIGNMENT_CENTER, 28, font_sz, Color(1.0, 0.85, 0.25, 1.0))
	
	# 3. Cuartel / Barraca (solo si está construido)
	if StoryManager.is_barracks_built():
		var bar_tex = SkinManager.get_building("barracks")
		var bar_pos = Vector2(450, 540)
		var bar_node = get_node_or_null("../../../Barracks")
		if bar_node and is_instance_valid(bar_node):
			bar_pos = bar_node.global_position
		var bar_nx = (bar_pos.x / MAP_W) * sz.x
		var bar_ny = (bar_pos.y / MAP_H) * sz.y
		if bar_tex:
			draw_texture_rect(bar_tex, Rect2(Vector2(bar_nx - 8, bar_ny - 8), Vector2(16, 16)), false)
		else:
			draw_circle(Vector2(bar_nx, bar_ny), 3.0, Color(0.3, 0.8, 1.0, 1.0))
		if font:
			draw_string(font, Vector2(bar_nx - 20, bar_ny - 9), "CUARTEL", HORIZONTAL_ALIGNMENT_CENTER, 40, font_sz, Color(0.3, 0.8, 1.0, 1.0))
	
	# 4. Bahía de Ingeniería Terran (solo si está construida)
	if StoryManager.is_engineering_bay_built():
		var ebay_tex = SkinManager.get_building("engineering_bay_icon")
		var ebay_pos = Vector2(1080, 740)
		var ebay_node = get_node_or_null("../../../Academy")
		if ebay_node and is_instance_valid(ebay_node):
			ebay_pos = ebay_node.global_position
		var ebay_nx = (ebay_pos.x / MAP_W) * sz.x
		var ebay_ny = (ebay_pos.y / MAP_H) * sz.y
		if ebay_tex:
			draw_texture_rect(ebay_tex, Rect2(Vector2(ebay_nx - 8, ebay_ny - 7), Vector2(16, 14)), false)
		else:
			draw_circle(Vector2(ebay_nx, ebay_ny), 3.0, Color(0.2, 0.9, 0.9, 1.0))
		if font:
			draw_string(font, Vector2(ebay_nx - 24, ebay_ny - 8), "BAHÍA ING.", HORIZONTAL_ALIGNMENT_CENTER, 48, font_sz, Color(0.2, 0.9, 0.9, 1.0))
	
	# 5. Nave de Transporte / Starport
	var ship_tex = SkinManager.get_building("dropship")
	var ship_pos = Vector2(1560, 840)
	var ship_node = get_node_or_null("../../../Starport")
	if ship_node and is_instance_valid(ship_node):
		ship_pos = ship_node.global_position
	var ship_nx = (ship_pos.x / MAP_W) * sz.x
	var ship_ny = (ship_pos.y / MAP_H) * sz.y
	if ship_tex:
		draw_texture_rect(ship_tex, Rect2(Vector2(ship_nx - 7, ship_ny - 7), Vector2(14, 14)), false)
	else:
		draw_circle(Vector2(ship_nx, ship_ny), 3.0, Color(0.3, 1.0, 0.45, 1.0))
	if font:
		draw_string(font, Vector2(ship_nx - 14, ship_ny - 8), "NAVE", HORIZONTAL_ALIGNMENT_CENTER, 28, font_sz, Color(0.3, 1.0, 0.45, 1.0))
	
	# 6. Soporte de Armadura Marine CMC-300
	var armor_pos = Vector2(1080, 700)
	var armor_stand = get_node_or_null("../../../ArmorStand")
	if armor_stand and is_instance_valid(armor_stand):
		armor_pos = armor_stand.global_position
	var arm_nx = (armor_pos.x / MAP_W) * sz.x
	var arm_ny = (armor_pos.y / MAP_H) * sz.y
	draw_circle(Vector2(arm_nx, arm_ny), 2.5, Color(0.5, 0.85, 1.0, 0.9))
	
	# 7. Posición del Jugador
	var pl = get_tree().get_first_node_in_group("player")
	if pl and is_instance_valid(pl):
		var px = clamp((pl.global_position.x / MAP_W) * sz.x, 2.0, sz.x - 2.0)
		var py = clamp((pl.global_position.y / MAP_H) * sz.y, 2.0, sz.y - 2.0)
		var pulse_rad = 3.2 + sin(pulse_t) * 0.9
		draw_circle(Vector2(px, py), pulse_rad, Color(0.25, 1.0, 0.4, 0.95))
		draw_circle(Vector2(px, py), 1.5, Color(1.0, 1.0, 1.0, 1.0))
