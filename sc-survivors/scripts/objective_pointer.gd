class_name ObjectivePointer
extends CanvasLayer

# Sistema de flechas indicadoras fuera de pantalla al estilo Vampire Survivors
var max_pointers: int = 5
var pointers: Array = []
var evac_pointer: Control = null
var pulse_time: float = 0.0

func _ready() -> void:
	layer = 15
	for i in range(max_pointers):
		var p = _create_pointer_node()
		add_child(p)
		pointers.append(p)
	
	evac_pointer = _create_evac_pointer_node()
	add_child(evac_pointer)

func _create_pointer_node() -> Control:
	var root = Control.new()
	root.visible = false
	
	# Flecha rotada
	var arrow_lbl = Label.new()
	arrow_lbl.name = "Arrow"
	arrow_lbl.text = "➔"
	arrow_lbl.add_theme_font_size_override("font_size", 22)
	arrow_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
	arrow_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	arrow_lbl.add_theme_constant_override("shadow_offset_x", 1)
	arrow_lbl.add_theme_constant_override("shadow_offset_y", 1)
	arrow_lbl.position = Vector2(-12, -14)
	arrow_lbl.pivot_offset = Vector2(12, 14)
	root.add_child(arrow_lbl)
	
	# Icono de Vespeno
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/skins/sd/sprites/vespene_tank.png")
	icon.custom_minimum_size = Vector2(20, 20)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(10, -10)
	root.add_child(icon)
	
	# Distancia en metros
	var dist_lbl = Label.new()
	dist_lbl.name = "Dist"
	dist_lbl.add_theme_font_size_override("font_size", 10)
	dist_lbl.add_theme_color_override("font_color", Color(0.8, 1.0, 0.8, 1.0))
	dist_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	dist_lbl.position = Vector2(10, 10)
	root.add_child(dist_lbl)
	
	return root

func _create_evac_pointer_node() -> Control:
	var root = Control.new()
	root.visible = false
	
	# Flecha azul / cian de evacuación
	var arrow_lbl = Label.new()
	arrow_lbl.name = "Arrow"
	arrow_lbl.text = "➔"
	arrow_lbl.add_theme_font_size_override("font_size", 24)
	arrow_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	arrow_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	arrow_lbl.add_theme_constant_override("shadow_offset_x", 1)
	arrow_lbl.add_theme_constant_override("shadow_offset_y", 1)
	arrow_lbl.position = Vector2(-12, -14)
	arrow_lbl.pivot_offset = Vector2(12, 14)
	root.add_child(arrow_lbl)
	
	# Icono de Dropship
	var icon = TextureRect.new()
	icon.name = "Icon"
	icon.texture = load("res://assets/skins/sd/buildings/dropship.png")
	icon.custom_minimum_size = Vector2(24, 24)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.position = Vector2(12, -12)
	root.add_child(icon)
	
	# Etiqueta de Evacuación y Distancia
	var dist_lbl = Label.new()
	dist_lbl.name = "Dist"
	dist_lbl.add_theme_font_size_override("font_size", 10)
	dist_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 1.0))
	dist_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	dist_lbl.position = Vector2(12, 12)
	root.add_child(dist_lbl)
	
	return root

func _process(delta: float) -> void:
	pulse_time += delta * 4.0
	var viewport = get_viewport()
	if not viewport:
		return
	var cam = viewport.get_camera_2d()
	if not cam:
		return
	
	var cam_pos = cam.global_position
	var v_size = viewport.get_visible_rect().size
	var half_size = v_size * 0.5
	
	# 1. Puntero de Evacuación / Dropship
	_update_evac_pointer(cam_pos, half_size)
	
	# 2. Punteros de Tanques de Vespeno
	_update_vespene_pointers(cam_pos, half_size)

func _update_evac_pointer(cam_pos: Vector2, half_size: Vector2) -> void:
	if not evac_pointer:
		return
	var evac_node = get_tree().get_first_node_in_group("evacuation_zone")
	if not evac_node or not is_instance_valid(evac_node):
		evac_pointer.visible = false
		return
	
	var diff = evac_node.global_position - cam_pos
	# Si está dentro de la pantalla, se oculta la flecha porque el jugador ya ve la nave
	if abs(diff.x) < (half_size.x - 45.0) and abs(diff.y) < (half_size.y - 45.0):
		evac_pointer.visible = false
		return
	
	var dir = diff.normalized()
	var border_x = half_size.x - 42.0
	var border_y = half_size.y - 42.0
	var factor = min(border_x / abs(dir.x) if abs(dir.x) > 0.001 else 9999.0, border_y / abs(dir.y) if abs(dir.y) > 0.001 else 9999.0)
	
	var screen_pos = half_size + dir * factor
	evac_pointer.position = screen_pos
	
	var arrow = evac_pointer.get_node("Arrow") as Label
	var dist_lbl = evac_pointer.get_node("Dist") as Label
	
	if arrow:
		arrow.rotation = dir.angle()
	
	var dist_m = int(diff.length() / 10.0)
	if GameManager.is_mission_completed:
		dist_lbl.text = "★ EVAC: %dm" % dist_m
		dist_lbl.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		evac_pointer.modulate.a = 0.75 + sin(pulse_time) * 0.25
	else:
		dist_lbl.text = "BASE: %dm" % dist_m
		dist_lbl.add_theme_color_override("font_color", Color(0.4, 0.9, 1.0, 1.0))
		evac_pointer.modulate.a = 1.0
	
	evac_pointer.visible = true

func _update_vespene_pointers(cam_pos: Vector2, half_size: Vector2) -> void:
	var tanks = get_tree().get_nodes_in_group("vespene_tanks")
	var offscreen_targets: Array = []
	
	for t in tanks:
		if not is_instance_valid(t):
			continue
		var diff = t.global_position - cam_pos
		if abs(diff.x) < (half_size.x - 30.0) and abs(diff.y) < (half_size.y - 30.0):
			continue
		offscreen_targets.append({
			"pos": t.global_position,
			"diff": diff,
			"dist": diff.length()
		})
	
	offscreen_targets.sort_custom(func(a, b): return a["dist"] < b["dist"])
	
	for i in range(max_pointers):
		var p_node = pointers[i]
		if i < offscreen_targets.size():
			var item = offscreen_targets[i]
			var diff = item["diff"]
			var dir = diff.normalized()
			
			var border_x = half_size.x - 36.0
			var border_y = half_size.y - 36.0
			var factor = min(border_x / abs(dir.x) if abs(dir.x) > 0.001 else 9999.0, border_y / abs(dir.y) if abs(dir.y) > 0.001 else 9999.0)
			
			var screen_pos = half_size + dir * factor
			p_node.position = screen_pos
			
			var arrow = p_node.get_node("Arrow") as Label
			var dist_lbl = p_node.get_node("Dist") as Label
			
			if arrow:
				arrow.rotation = dir.angle()
			if dist_lbl:
				dist_lbl.text = "%dm" % int(item["dist"] / 10.0)
			
			p_node.visible = true
		else:
			p_node.visible = false
