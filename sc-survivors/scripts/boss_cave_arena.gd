class_name BossCaveArena
extends Node2D

@onready var player: Player = $Player
@onready var torrasque_boss: TorrasqueBoss = $TorrasqueBoss
@onready var boss_hud: BossHUD = $BossHUD
@onready var transmission_comm: TransmissionComm = $CommLayer/TransmissionComm if has_node("CommLayer/TransmissionComm") else get_node_or_null("TransmissionComm")
@onready var pillars_container: Node2D = $PillarsContainer
@onready var boundary_doodads: Node2D = get_node_or_null("BoundaryDoodads")
@onready var zerg_spawner_timer: Timer = $ZergSpawnerTimer
@onready var arena_camera: Camera2D = get_node_or_null("ArenaCamera")

const ARENA_CENTER: Vector2 = Vector2.ZERO
const ARENA_RADIUS: float = 460.0
const PILLAR_RADIUS: float = 280.0

# 6 Pilares simétricos en círculo (a 0°, 60°, 120°, 180°, 240°, 300° rotados para tener Norte a las 12h)
# Pares opuestos: (0, 3) Norte-Sur, (1, 4) Nororiente-Suroccidente, (2, 5) Suroriente-Noroccidente
const PILLAR_DEFS = [
	{ "id": 0, "name": "PILAR NORTE", "pos": Vector2(0, -280), "opposite_id": 3 },
	{ "id": 1, "name": "PILAR NORORIENTE", "pos": Vector2(242.5, -140), "opposite_id": 4 },
	{ "id": 2, "name": "PILAR SURORIENTE", "pos": Vector2(242.5, 140), "opposite_id": 5 },
	{ "id": 3, "name": "PILAR SUR", "pos": Vector2(0, 280), "opposite_id": 0 },
	{ "id": 4, "name": "PILAR SUROCCIDENTE", "pos": Vector2(-242.5, 140), "opposite_id": 1 },
	{ "id": 5, "name": "PILAR NOROCCIDENTE", "pos": Vector2(-242.5, -140), "opposite_id": 2 }
]

var pillars_map: Dictionary = {}
var broken_pillars_count: int = 0
var pending_opposite_id: int = -1 # -1 = cueva equilibrada
var is_cave_collapsing: bool = false
var evac_circle: EvacuationCircle = null

var is_intro_cinematic_active: bool = true

var lurker_timer: float = 2.0
var lurker_interval: float = 4.0
var lurker_hazard_scene: PackedScene = null

func _ready() -> void:
	get_tree().paused = false
	GameManager.is_game_over = false
	
	_setup_cave_boundary(ARENA_RADIUS, 36)
	_setup_boundary_doodads()
	_setup_pillars()
	
	# Asegurar que NO haya ninguna nave de evacuación activa al entrar a la cueva
	for node in get_tree().get_nodes_in_group("evacuation_zone"):
		if is_instance_valid(node):
			node.queue_free()
	
	if is_instance_valid(player):
		GameManager.restore_player_state(player)
		player.is_in_base = false
		player.global_position = Vector2(0, 190)
		player.set_physics_process(false)
		
		var p_cam = player.get_node_or_null("Camera2D") as Camera2D
		if p_cam:
			p_cam.enabled = false
	
	if arena_camera and is_instance_valid(player):
		arena_camera.enabled = true
		arena_camera.make_current()
		arena_camera.zoom = Vector2(1.0, 1.0)
		arena_camera.position = player.position + Vector2(0, -45)
	
	if is_instance_valid(torrasque_boss):
		torrasque_boss.player = player
		torrasque_boss.global_position = Vector2(0, -90)
		torrasque_boss.died.connect(_on_boss_died)
		if boss_hud:
			boss_hud.setup_boss(torrasque_boss)
	
	AudioManager.play_music("zerg4", true)
	call_deferred("_start_intro_cinematic")

func _start_intro_cinematic() -> void:
	is_intro_cinematic_active = true
	
	if not arena_camera:
		_finish_intro_cinematic()
		return
	
	# 1. Cámara se aleja suavemente para revelar toda la arena y la escala de la batalla
	var tw = create_tween()
	tw.set_parallel(true)
	tw.tween_property(arena_camera, "zoom", Vector2(0.48, 0.48), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	tw.tween_property(arena_camera, "position", Vector2(0, 196), 1.6).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)
	
	# 2. Al llegar a la vista panorámica: rugido del Torrasque y mensaje corto de Voss
	tw.chain().tween_callback(func():
		AudioManager.play_sfx("ultra_roar", 0.0, 4.0)
		_trigger_camera_shake(8.0)
		_send_voss_radio(
			"«¡Cuidado! Esta caverna se ve inestable... trata de no destruir disparejamente todo adentro.»",
			4.0
		)
	)
	
	# Pausa de 2.2 segundos para apreciar la caverna y los pilares
	tw.tween_interval(2.2)
	
	# 3. La cámara regresa suavemente al tamaño original centrada en el jugador
	tw.chain().tween_callback(func():
		if transmission_comm:
			transmission_comm.hide_transmission()
	)
	
	var target_p = (player.position + Vector2(0, -45)) if is_instance_valid(player) else Vector2(0, 145)
	tw.tween_property(arena_camera, "zoom", Vector2(0.95, 0.95), 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	tw.parallel().tween_property(arena_camera, "position", target_p, 1.3).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN_OUT)
	
	# 4. Al volver al tamaño original: aparece la barra de vida del jefe y comienza la pelea
	tw.chain().tween_callback(_finish_intro_cinematic)

func _finish_intro_cinematic() -> void:
	is_intro_cinematic_active = false
	
	# Control habilitado para el jugador
	if is_instance_valid(player):
		player.set_physics_process(true)
	
	# La barra de vida reducida aparece desde arriba con animación
	if boss_hud:
		boss_hud.show_hud_animated()
	
	# El Torrasque inicia su persecución y suena el tema de combate Brood War Zerg 4
	AudioManager.play_music("zerg4", true)
	if is_instance_valid(torrasque_boss):
		torrasque_boss.start_fight()
	
	# Iniciar temporizador de desove periódico de apoyo
	if zerg_spawner_timer:
		if not zerg_spawner_timer.timeout.is_connected(_on_zerg_spawn_tick):
			zerg_spawner_timer.timeout.connect(_on_zerg_spawn_tick)
		zerg_spawner_timer.start(4.5)
	
	# Desove inicial inmediato al comenzar el combate
	get_tree().create_timer(1.2).timeout.connect(_on_zerg_spawn_tick)

func _process(delta: float) -> void:
	if is_intro_cinematic_active:
		return
	
	if arena_camera and is_instance_valid(player):
		var target_cam = player.position + Vector2(0, -45)
		arena_camera.position = arena_camera.position.lerp(target_cam, delta * 6.0)
	
	# Mecánica periódica de espinas de Lurker en la caverna para esquivar
	if not is_cave_collapsing and is_instance_valid(torrasque_boss) and torrasque_boss.current_state != TorrasqueBoss.State.DEAD:
		lurker_timer -= delta
		if lurker_timer <= 0.0:
			lurker_timer = lurker_interval
			_trigger_arena_lurker_hazard()

func _trigger_arena_lurker_hazard() -> void:
	if not lurker_hazard_scene:
		lurker_hazard_scene = load("res://scenes/lurker_spine_hazard.tscn")
	if not lurker_hazard_scene or not is_instance_valid(player) or is_cave_collapsing:
		return
	if not is_instance_valid(torrasque_boss) or torrasque_boss.current_state == TorrasqueBoss.State.DEAD:
		return
	
	var pattern = randi() % 4
	var spine_lines: Array[Dictionary] = []
	var p_pos = player.global_position
	
	match pattern:
		0:
			# Patrón 1: Cuadrícula cruzada (Grid de 4 líneas perpendiculares formando celdas)
			var base_angle = randf() * PI * 0.5
			for i in range(4):
				var ang = base_angle + (float(i) * PI * 0.5)
				var dir = Vector2(cos(ang), sin(ang))
				var perp = Vector2(-dir.y, dir.x)
				var lateral = randf_range(-120.0, 120.0)
				var start_pos = p_pos - (dir * 420.0) + (perp * lateral)
				spine_lines.append({
					"start": start_pos,
					"dir": dir,
					"length": 860.0,
					"delay": float(i) * 0.12,
					"dmg": 26.0,
					"telegraph": 1.25
				})
		1:
			# Patrón 2: Abanico cuádruple fanning across player
			var to_player = (p_pos - ARENA_CENTER).normalized()
			if to_player.length_squared() < 0.01:
				to_player = Vector2.RIGHT
			var base_ang = to_player.angle()
			for i in range(4):
				var spread_ang = base_ang + ((float(i) - 1.5) * 0.38) + randf_range(-0.08, 0.08)
				var dir = Vector2(cos(spread_ang), sin(spread_ang))
				var start_pos = p_pos - (dir * 420.0)
				spine_lines.append({
					"start": start_pos,
					"dir": dir,
					"length": 860.0,
					"delay": float(i) * 0.14,
					"dmg": 26.0,
					"telegraph": 1.25
				})
		2:
			# Patrón 3: Rastrillo paralelo cuádruple (barrido de líneas paralelas)
			var sweep_ang = randf() * TAU
			var dir = Vector2(cos(sweep_ang), sin(sweep_ang))
			var perp = Vector2(-dir.y, dir.x)
			for i in range(4):
				var offset = (float(i) - 1.5) * 110.0 + randf_range(-15.0, 15.0)
				var start_pos = p_pos - (dir * 420.0) + (perp * offset)
				spine_lines.append({
					"start": start_pos,
					"dir": dir,
					"length": 860.0,
					"delay": float(i) * 0.13,
					"dmg": 26.0,
					"telegraph": 1.25
				})
		3:
			# Patrón 4: Tridente convergente desde 3 bordes de la caverna
			var base_rot = randf() * TAU
			for i in range(3):
				var rim_ang = base_rot + (float(i) * (TAU / 3.0))
				var start_pos = ARENA_CENTER + Vector2(cos(rim_ang), sin(rim_ang)) * 430.0
				var dir = (p_pos + Vector2(randf_range(-60.0, 60.0), randf_range(-60.0, 60.0)) - start_pos).normalized()
				spine_lines.append({
					"start": start_pos,
					"dir": dir,
					"length": 880.0,
					"delay": float(i) * 0.15,
					"dmg": 26.0,
					"telegraph": 1.25
				})
	
	for line_data in spine_lines:
		get_tree().create_timer(line_data["delay"]).timeout.connect(func():
			if not is_instance_valid(player) or is_cave_collapsing or not is_instance_valid(torrasque_boss):
				return
			if torrasque_boss.current_state == TorrasqueBoss.State.DEAD:
				return
			var hazard = lurker_hazard_scene.instantiate()
			hazard.setup(line_data["start"], line_data["dir"], line_data["length"], line_data["dmg"], line_data["telegraph"])
			add_child(hazard)
		)

func _physics_process(_delta: float) -> void:
	# Contención estricta: asegurar que nada salga del radio circular de la cueva
	if is_instance_valid(player):
		var p_pos = player.position
		if p_pos.length() > ARENA_RADIUS - 16.0:
			player.position = p_pos.normalized() * (ARENA_RADIUS - 16.0)
			player.velocity = Vector2.ZERO
	
	if is_instance_valid(torrasque_boss):
		if torrasque_boss.current_state != TorrasqueBoss.State.CHARGING:
			var b_pos = torrasque_boss.position
			if b_pos.length() > ARENA_RADIUS - 30.0:
				torrasque_boss.position = b_pos.normalized() * (ARENA_RADIUS - 30.0)
				torrasque_boss.velocity = Vector2.ZERO

func _draw() -> void:
	# Borde perimetral visual de cueva: delimita el círculo con roca oscura y sombra envolvente
	draw_arc(ARENA_CENTER, ARENA_RADIUS - 8.0, 0, TAU, 64, Color(0.15, 0.08, 0.06, 0.4), 16.0)
	draw_arc(ARENA_CENTER, ARENA_RADIUS + 6.0, 0, TAU, 64, Color(0.04, 0.02, 0.02, 0.88), 28.0)
	draw_arc(ARENA_CENTER, ARENA_RADIUS + 36.0, 0, TAU, 64, Color(0.0, 0.0, 0.0, 1.0), 60.0)

func _setup_cave_boundary(radius: float, segments: int) -> void:
	var body = StaticBody2D.new()
	body.collision_layer = 7
	body.collision_mask = 7
	body.name = "CaveBoundaryWalls"
	add_child(body)
	
	var step_angle = TAU / float(segments)
	var seg_length = 2.0 * radius * sin(step_angle * 0.5) + 24.0
	var wall_thickness = 160.0
	
	for i in range(segments):
		var mid_angle = (i + 0.5) * step_angle
		var center_pos = Vector2(cos(mid_angle), sin(mid_angle)) * (radius + wall_thickness * 0.5)
		
		var col = CollisionShape2D.new()
		var box = RectangleShape2D.new()
		box.size = Vector2(seg_length, wall_thickness)
		col.shape = box
		col.position = center_pos
		col.rotation = mid_angle + PI * 0.5
		body.add_child(col)

func _setup_boundary_doodads() -> void:
	if not boundary_doodads:
		boundary_doodads = Node2D.new()
		boundary_doodads.name = "BoundaryDoodads"
		add_child(boundary_doodads)
		move_child(boundary_doodads, 1)
	
	for c in boundary_doodads.get_children():
		c.queue_free()
	
	var rock_count = 38
	var step_angle = TAU / float(rock_count)
	for i in range(rock_count):
		var angle = i * step_angle + randf_range(-0.03, 0.03)
		var dist = ARENA_RADIUS + randf_range(-4.0, 16.0)
		var pos = Vector2(cos(angle), sin(angle)) * dist
		
		var spr = Sprite2D.new()
		spr.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		var variant = (i % 4) + 1
		var tex_path = "res://assets/skins/sd/sprites/boundary_rock%d.png" % variant
		if ResourceLoader.exists(tex_path):
			spr.texture = load(tex_path)
		var sc = randf_range(1.2, 1.6)
		spr.scale = Vector2(sc, sc)
		spr.rotation = randf_range(-0.25, 0.25)
		spr.position = pos
		spr.z_index = 1
		boundary_doodads.add_child(spr)

func _setup_pillars() -> void:
	var pillar_scene = load("res://scenes/boss_pillar.tscn")
	if not pillar_scene or not pillars_container:
		return
	
	for c in pillars_container.get_children():
		c.queue_free()
	pillars_map.clear()
	broken_pillars_count = 0
	pending_opposite_id = -1
	
	var pillar_variants = [4, 1, 2, 3, 1, 2]
	for i in range(PILLAR_DEFS.size()):
		var def = PILLAR_DEFS[i]
		var p = pillar_scene.instantiate() as BossPillar
		p.name = "Pillar_%d" % def["id"]
		p.pillar_id = def["id"]
		p.opposite_id = def["opposite_id"]
		p.position = def["pos"]
		pillars_container.add_child(p)
		p.set_rock_variant(pillar_variants[i % pillar_variants.size()])
		pillars_map[def["id"]] = p
	
	if boss_hud:
		boss_hud.update_pillars_count(6, 6)
		boss_hud.update_cave_balance(true)

# ==============================================================================
# MECÁNICA DE BALANCE DE PILARES Y EMBESTIDA
# ==============================================================================
func on_pillar_hit_by_charge(pillar: BossPillar) -> void:
	if is_cave_collapsing or not is_instance_valid(pillar) or pillar.is_destroyed:
		return
	
	var hit_id = pillar.pillar_id
	pillar.break_by_charge()
	broken_pillars_count += 1
	_trigger_camera_shake(12.0)
	
	if boss_hud:
		boss_hud.update_pillars_count(6 - broken_pillars_count, 6)
	
	# CASO 1: Es el primer pilar de un par
	if pending_opposite_id == -1:
		pending_opposite_id = pillar.opposite_id
		var req_pillar = pillars_map.get(pending_opposite_id) as BossPillar
		if is_instance_valid(req_pillar):
			req_pillar.set_designated_target(true)
		
		var opposite_name = _get_pillar_name(pending_opposite_id)
		if boss_hud:
			boss_hud.update_cave_balance(false, opposite_name)
		
		if is_instance_valid(torrasque_boss):
			torrasque_boss.enter_stunned_state()
			
	# CASO 2: Es el segundo pilar de un par
	else:
		if hit_id == pending_opposite_id:
			# Rompió el opuesto exacto -> Equilibrio mantenido
			var prev_req = pillars_map.get(pending_opposite_id) as BossPillar
			if is_instance_valid(prev_req):
				prev_req.set_designated_target(false)
			pending_opposite_id = -1
			
			if boss_hud:
				boss_hud.update_cave_balance(true)
			
			if is_instance_valid(torrasque_boss):
				torrasque_boss.enter_stunned_state()
		else:
			# Rompió un pilar no opuesto -> Colapso de la cueva
			_trigger_cave_collapse_cinematic(pillar)

func _get_pillar_name(id: int) -> String:
	for def in PILLAR_DEFS:
		if def["id"] == id:
			return def["name"]
	return "PILAR OPUESTO"

# ==============================================================================
# CINEMÁTICA DE COLAPSO DE CUEVA (MUERTE POR DESBALANCE)
# ==============================================================================
func _trigger_cave_collapse_cinematic(_wrong_pillar: BossPillar) -> void:
	if is_cave_collapsing:
		return
	is_cave_collapsing = true
	
	if is_instance_valid(player):
		player.set_physics_process(false)
	if is_instance_valid(torrasque_boss):
		torrasque_boss.set_physics_process(false)
	
	_trigger_camera_shake(35.0)
	AudioManager.play_sfx("pillar_smash", 0.0, 5.0)
	
	for i in range(25):
		var rock_delay = i * 0.08
		get_tree().create_timer(rock_delay).timeout.connect(func():
			_spawn_falling_boulder()
		)
	
	var collapse_tw = create_tween()
	collapse_tw.tween_interval(2.2)
	collapse_tw.tween_callback(func():
		AudioManager.play_sfx("youlose")
		_show_collapse_game_over()
	)

func _spawn_falling_boulder() -> void:
	var rock = Sprite2D.new()
	var rubble_tex = SkinManager.get_sprite("zrubblel")
	if rubble_tex:
		rock.texture = rubble_tex
		rock.hframes = 4
		rock.frame = randi() % 4
	rock.scale = Vector2(1.2, 1.2)
	rock.modulate = Color(0.3, 0.25, 0.25, 0.95)
	
	var drop_pos = ARENA_CENTER + Vector2(randf_range(-340, 340), randf_range(-340, 340))
	rock.global_position = drop_pos + Vector2(0, -380)
	add_child(rock)
	
	var tw = rock.create_tween()
	tw.tween_property(rock, "global_position", drop_pos, 0.35).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tw.tween_callback(func():
		_trigger_camera_shake(15.0)
		AudioManager.play_sfx("pillar_crack", 0.05, 3.0)
	)

func _show_collapse_game_over() -> void:
	var canvas = CanvasLayer.new()
	canvas.layer = 50
	add_child(canvas)
	
	var overlay = ColorRect.new()
	overlay.color = Color(0.02, 0.01, 0.01, 0.9)
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(overlay)
	
	var center = CenterContainer.new()
	center.set_anchors_preset(Control.PRESET_FULL_RECT)
	canvas.add_child(center)
	
	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 16)
	center.add_child(vbox)
	
	var title = Label.new()
	title.text = "COLAPSO ESTRUCTURAL TOTAL"
	title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.2, 1.0))
	title.add_theme_color_override("font_outline_color", Color(0, 0, 0, 1))
	title.add_theme_constant_override("outline_size", 4)
	title.add_theme_font_size_override("font_size", 20)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "La cueva colapsó por desbalance de peso al no destruir el pilar opuesto.\nPara sobrevivir, debes destruir los pilares en pares opuestos exactos."
	desc.add_theme_color_override("font_color", Color(0.85, 0.85, 0.85, 1.0))
	desc.add_theme_font_size_override("font_size", 11)
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(desc)
	
	var retry_btn = Button.new()
	retry_btn.text = "REINTENTAR PELEA DE JEFE"
	retry_btn.custom_minimum_size = Vector2(220, 36)
	retry_btn.pressed.connect(func():
		get_tree().change_scene_to_file("res://scenes/boss_cave_arena.tscn")
	)
	vbox.add_child(retry_btn)

# ==============================================================================
# SPAWN ENDGAME MINUTO 20 DE ZERGS (TIER 7/8 Y TIER 4/5)
# ==============================================================================
func _on_zerg_spawn_tick() -> void:
	if is_cave_collapsing or not is_instance_valid(torrasque_boss) or torrasque_boss.current_state == TorrasqueBoss.State.DEAD or is_intro_cinematic_active:
		return
	
	var z_scene = load("res://scenes/zergling.tscn")
	var h_scene = load("res://scenes/hydralisk.tscn")
	var m_scene = load("res://scenes/mutalisk.tscn")
	if not z_scene:
		return
	
	# Limitar esbirros activos en la caverna para garantizar 60 FPS estables
	var existing_enemies = get_tree().get_nodes_in_group("enemies")
	var minion_count = 0
	for e in existing_enemies:
		if is_instance_valid(e) and e != torrasque_boss and not (e is TorrasqueBoss):
			minion_count += 1
	
	if minion_count >= 34:
		return
	
	# Cantidad de apariciones: intensa como minuto 20 (base de 4-6 zerglings + 2 hidras + 1 muta)
	var zerg_count = randi_range(4, 6) + (broken_pillars_count * 2)
	var hydra_count = randi_range(2, 3) + broken_pillars_count
	var muta_count = 1 if randf() < 0.70 else 0
	
	var player = get_tree().get_first_node_in_group("player")
	
	# 1. Zerglings Tier 8 (Masa Crítica, 2400 HP, 20 armadura, 1.65x) y Tier 7 (1600 HP, 16 armadura)
	for i in range(zerg_count):
		if minion_count >= 34:
			break
		var z = z_scene.instantiate()
		z.global_position = _get_safe_cave_spawn_pos(player, 340.0, 420.0)
		add_child(z)
		
		var tier_to_set = 8 if randf() < 0.65 else 7
		if z.has_method("set_tier"):
			z.set_tier(tier_to_set)
		minion_count += 1
	
	# 2. Hidraliscos Tier 5 (Esmeralda, 2400 HP, 20 armadura) y Tier 4 (Ámbar, 1300 HP, 15 armadura)
	if h_scene:
		for i in range(hydra_count):
			if minion_count >= 34:
				break
			var h = h_scene.instantiate()
			h.global_position = _get_safe_cave_spawn_pos(player, 350.0, 420.0)
			add_child(h)
			
			var tier_to_set = 5 if randf() < 0.60 else 4
			if h.has_method("set_tier"):
				h.set_tier(tier_to_set)
			minion_count += 1
	
	# 3. Mutaliscos Tier 5 (Esmeralda, 2100 HP, 18 armadura)
	if m_scene and muta_count > 0 and minion_count < 34:
		for i in range(muta_count):
			var m = m_scene.instantiate()
			m.global_position = _get_safe_cave_spawn_pos(player, 360.0, 420.0)
			add_child(m)
			
			if m.has_method("set_tier"):
				m.set_tier(5)
			minion_count += 1

func _get_safe_cave_spawn_pos(player: Node2D, min_d: float, max_d: float) -> Vector2:
	const MIN_PLAYER_EXCLUSION: float = 220.0
	for attempt in range(8):
		var ang = randf() * TAU
		var dist = randf_range(min_d, max_d)
		var pos = ARENA_CENTER + Vector2(cos(ang) * dist, sin(ang) * dist)
		if player and is_instance_valid(player):
			if pos.distance_to(player.global_position) >= MIN_PLAYER_EXCLUSION:
				return pos
		else:
			return pos
	if player and is_instance_valid(player):
		var away_dir = (ARENA_CENTER - player.global_position).normalized()
		if away_dir == Vector2.ZERO:
			away_dir = Vector2.RIGHT.rotated(randf() * TAU)
		return player.global_position + away_dir * MIN_PLAYER_EXCLUSION
	return ARENA_CENTER + Vector2.RIGHT * min_d

# ==============================================================================
# VICTORIA Y EXTRACCIÓN
# ==============================================================================
func _on_boss_died() -> void:
	_trigger_camera_shake(16.0)
	if zerg_spawner_timer:
		zerg_spawner_timer.stop()
	
	# Detener y limpiar peligros de espinas activas
	for hazard in get_tree().get_nodes_in_group("lurker_hazards"):
		if is_instance_valid(hazard) and hazard.has_method("clear_immediately"):
			hazard.clear_immediately()
	
	# Colapso psiónico: eliminar esbirros restantes al morir el Torrasque alfa
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if is_instance_valid(enemy) and enemy != torrasque_boss and not (enemy is TorrasqueBoss):
			if enemy.has_method("die"):
				enemy.die()
	
	GameManager.mission_bosses += 1
	GameManager._check_mission_progress()
	
	var tw = create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		# Aterrizaje de la nave de evacuación únicamente al morir el jefe
		var evac_scene = load("res://scenes/evacuation_circle.tscn")
		if evac_scene:
			evac_circle = evac_scene.instantiate()
			evac_circle.global_position = ARENA_CENTER
			add_child(evac_circle)
			AudioManager.play_sfx("dropship_ready", 0.05, 4.0)
		
		_send_voss_radio(
			"«¡CONFIRMACIÓN DE IMPACTO FATAL! ¡EL TITÁN HA CAÍDO! Nave de extracción balizada en el centro de la cueva. ¡Entra a la baliza para regresar a la base!»",
			7.0,
			"VOSS_26"
		)
	)

func _trigger_camera_shake(intensity: float) -> void:
	var target_cam: Camera2D = arena_camera if arena_camera else (player.get_node_or_null("Camera2D") as Camera2D if is_instance_valid(player) else null)
	if not target_cam:
		return
	var tw = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(target_cam, "offset", offset, 0.04)
	tw.tween_property(target_cam, "offset", Vector2.ZERO, 0.04)

func _send_voss_radio(msg: String, dur: float, voice_id: String = "") -> void:
	if transmission_comm:
		transmission_comm.show_transmission(
			"CAPITÁN HOLLIS VOSS",
			load("res://assets/skins/sd/portrait/civilian_portrait.png"),
			msg,
			dur,
			Callable(),
			voice_id
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10 or event.keycode == KEY_K:
			if is_instance_valid(torrasque_boss):
				torrasque_boss.die()
				get_viewport().set_input_as_handled()
		elif event.keycode == KEY_N or event.keycode == KEY_M:
			get_tree().change_scene_to_file("res://scenes/boss_cave_arena.tscn")
			get_viewport().set_input_as_handled()
