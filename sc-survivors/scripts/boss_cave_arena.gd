class_name BossCaveArena
extends Node2D

@onready var player: Player = $Player
@onready var torrasque_boss: TorrasqueBoss = $TorrasqueBoss
@onready var boss_hud: BossHUD = $BossHUD
@onready var transmission_comm: TransmissionComm = $TransmissionComm
@onready var pillars_container: Node2D = $PillarsContainer
@onready var zerg_spawner_timer: Timer = $ZergSpawnerTimer

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

func _ready() -> void:
	_setup_cave_boundary(ARENA_RADIUS, 36)
	_setup_pillars()
	
	# Asegurar que NO haya ninguna nave de evacuación activa al entrar a la cueva
	for node in get_tree().get_nodes_in_group("evacuation_zone"):
		if is_instance_valid(node):
			node.queue_free()
	
	if is_instance_valid(player):
		GameManager.restore_player_state(player)
		player.global_position = Vector2(0, 330)
	
	if is_instance_valid(torrasque_boss):
		torrasque_boss.global_position = Vector2(0, -60)
		torrasque_boss.died.connect(_on_boss_died)
		if boss_hud:
			boss_hud.setup_boss(torrasque_boss)
	
	if zerg_spawner_timer:
		zerg_spawner_timer.timeout.connect(_on_zerg_spawn_tick)
		zerg_spawner_timer.start(8.0)
	
	call_deferred("_play_intro_transmission")
	AudioManager.play_music("terran1", true)

func _setup_cave_boundary(radius: float, segments: int) -> void:
	var body = StaticBody2D.new()
	body.collision_layer = 3
	body.collision_mask = 3
	body.name = "CaveBoundaryWalls"
	add_child(body)
	
	for i in range(segments):
		var a1 = (i / float(segments)) * TAU
		var a2 = ((i + 1) / float(segments)) * TAU
		var p1 = Vector2(cos(a1) * radius, sin(a1) * radius)
		var p2 = Vector2(cos(a2) * radius, sin(a2) * radius)
		
		var col = CollisionShape2D.new()
		var seg = SegmentShape2D.new()
		seg.a = p1
		seg.b = p2
		col.shape = seg
		body.add_child(col)

func _setup_pillars() -> void:
	var pillar_scene = load("res://scenes/boss_pillar.tscn")
	if not pillar_scene or not pillars_container:
		return
	
	for c in pillars_container.get_children():
		c.queue_free()
	pillars_map.clear()
	broken_pillars_count = 0
	pending_opposite_id = -1
	
	for def in PILLAR_DEFS:
		var p = pillar_scene.instantiate() as BossPillar
		p.name = "Pillar_%d" % def["id"]
		p.pillar_id = def["id"]
		p.opposite_id = def["opposite_id"]
		p.position = def["pos"]
		pillars_container.add_child(p)
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
		
		_send_voss_radio(
			"«¡Pilar destruido! ¡ALERTA SÍSMICA! ¡La caverna está desbalanceada! ¡Haz que el Torrasque embista el %s o el techo colapsará sobre nosotros!»" % opposite_name,
			6.5
		)
		
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
			
			_send_voss_radio(
				"«¡EXCELENTE! ¡Equilibrio estructural restablecido! ¡El Torrasque está aturdido! ¡FUEGO CONCENTRADO A SU VIDA!»",
				5.0
			)
			
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
	
	_send_voss_radio(
		"«¡NO! ¡DESBALANCE CATACLÍSMICO! ¡EL TECHO DE LA CAVERNA SE ESTÁ DERRUMBANDO! ¡¡ES EL FIIIN...!!»",
		7.0
	)
	
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
	title.theme_override_colors/font_color = Color(1.0, 0.2, 0.2, 1.0)
	title.theme_override_colors/font_outline_color = Color(0, 0, 0, 1)
	title.theme_override_constants/outline_size = 4
	title.theme_override_font_sizes/font_size = 20
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(title)
	
	var desc = Label.new()
	desc.text = "La cueva colapsó por desbalance de peso al no destruir el pilar opuesto.\nPara sobrevivir, debes destruir los pilares en pares opuestos exactos."
	desc.theme_override_colors/font_color = Color(0.85, 0.85, 0.85, 1.0)
	desc.theme_override_font_sizes/font_size = 11
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
# SPAWN ESCALONADO DE ZERGS SEGÚN PILARES ROTOS
# ==============================================================================
func _on_zerg_spawn_tick() -> void:
	if is_cave_collapsing or broken_pillars_count == 0 or not is_instance_valid(torrasque_boss):
		return
	
	var z_scene = load("res://scenes/zergling.tscn")
	var h_scene = load("res://scenes/hydralisk.tscn")
	if not z_scene:
		return
	
	var zerglings_count = broken_pillars_count * 2
	var hydras_count = max(0, broken_pillars_count - 2)
	
	for i in range(zerglings_count):
		var z = z_scene.instantiate()
		var ang = randf_range(0, TAU)
		z.global_position = ARENA_CENTER + Vector2(cos(ang) * 380.0, sin(ang) * 380.0)
		add_child(z)
	
	if h_scene and hydras_count > 0:
		for i in range(hydras_count):
			var h = h_scene.instantiate()
			var ang = randf_range(0, TAU)
			h.global_position = ARENA_CENTER + Vector2(cos(ang) * 380.0, sin(ang) * 380.0)
			add_child(h)

# ==============================================================================
# VICTORIA Y EXTRACCIÓN
# ==============================================================================
func _on_boss_died() -> void:
	_trigger_camera_shake(16.0)
	if zerg_spawner_timer:
		zerg_spawner_timer.stop()
	
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
			7.0
		)
	)

func _trigger_camera_shake(intensity: float) -> void:
	if not is_instance_valid(player):
		return
	var cam = player.get_node_or_null("Camera2D") as Camera2D
	if not cam:
		return
	var tw = create_tween()
	for i in range(5):
		var offset = Vector2(randf_range(-intensity, intensity), randf_range(-intensity, intensity))
		tw.tween_property(cam, "offset", offset, 0.04)
	tw.tween_property(cam, "offset", Vector2.ZERO, 0.04)

func _play_intro_transmission() -> void:
	_send_voss_radio(
		"«¡ALERTA TÁCTICA! El Torrasque tiene blindaje pesado. ¡Dispara a su armadura para sobrecalentarla al 100%! Al llenarse, embestirá tras 3 segundos. ¡HAZ QUE SE ESTRELLE CONTRA LOS PILARES EN PARES OPUESTOS PARA ATURDIRLO Y EVITAR EL COLAPSO DE LA CUEVA!»",
		8.5
	)

func _send_voss_radio(msg: String, dur: float) -> void:
	if transmission_comm:
		transmission_comm.show_transmission(
			"CAPITÁN HOLLIS VOSS",
			load("res://assets/skins/sd/portrait/civilian_portrait.png"),
			msg,
			dur
		)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			if is_instance_valid(torrasque_boss):
				torrasque_boss.die()
				get_viewport().set_input_as_handled()
