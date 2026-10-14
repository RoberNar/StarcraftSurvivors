class_name BossCaveArena
extends Node2D

@onready var player: Player = $Player
@onready var torrasque_boss: TorrasqueBoss = $TorrasqueBoss
@onready var boss_hud: BossHUD = $BossHUD
@onready var transmission_comm: TransmissionComm = $TransmissionComm
@onready var evac_circle: EvacuationCircle = $EvacuationCircle
@onready var pillars_container: Node2D = $PillarsContainer
var total_pillars: int = 6
var standing_pillars: int = 6

func _ready() -> void:
	# Asegurar escala y presencia
	_setup_cave_boundary(460.0, 36)
	_setup_pillars()
	
	# Restaurar el estado y equipamiento completo del jugador desde la run
	if is_instance_valid(player):
		GameManager.restore_player_state(player)
	
	# Ocultar baliza de evacuación hasta abatir al jefe
	if evac_circle:
		evac_circle.visible = false
		evac_circle.monitoring = false
		evac_circle.monitorable = false
		evac_circle.global_position = Vector2(0, 0)
	
	# Configurar el Jefe y su HUD
	if torrasque_boss and boss_hud:
		boss_hud.setup_boss(torrasque_boss)
		torrasque_boss.stunned.connect(_on_boss_stunned)
		torrasque_boss.died.connect(_on_boss_died)
	
	# Transmisión introductoria táctica del Capitán Voss
	call_deferred("_play_intro_transmission")
	
	# Música de combate
	AudioManager.play_music("terran1", true)


func _setup_cave_boundary(radius: float, segments_count: int) -> void:
	var body = StaticBody2D.new()
	body.collision_layer = 3
	body.collision_mask = 3
	body.name = "CaveBoundaryWalls"
	add_child(body)
	
	for i in range(segments_count):
		var a1 = (i / float(segments_count)) * TAU
		var a2 = ((i + 1) / float(segments_count)) * TAU
		var p1 = Vector2.RIGHT.rotated(a1) * radius
		var p2 = Vector2.RIGHT.rotated(a2) * radius
		
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
	
	# Limpiar pilares previos si los hubiese
	for c in pillars_container.get_children():
		c.queue_free()
	
	var radius = 280.0
	standing_pillars = total_pillars
	
	# 6 pilares dispuestos simétricamente en círculo (0, 60, 120, 180, 240, 300 grados)
	for i in range(total_pillars):
		var angle = (i / float(total_pillars)) * TAU
		var pos = Vector2.RIGHT.rotated(angle) * radius
		
		var pillar = pillar_scene.instantiate() as BossPillar
		pillar.name = "Pillar_%d" % i
		pillar.position = pos
		pillar.pillar_damaged.connect(_on_pillar_damaged)
		pillar.pillar_destroyed.connect(_on_pillar_destroyed)
		pillars_container.add_child(pillar)
	
	if boss_hud:
		boss_hud.update_pillars_count(standing_pillars, total_pillars)

func _on_pillar_damaged(_pillar: BossPillar, _hits_left: int) -> void:
	_trigger_camera_shake(5.0)

func _on_pillar_destroyed(_pillar: BossPillar) -> void:
	standing_pillars = max(0, standing_pillars - 1)
	_trigger_camera_shake(10.0)
	
	if boss_hud:
		boss_hud.update_pillars_count(standing_pillars, total_pillars)
	
	if standing_pillars == 0:
		_send_voss_radio(
			"«¡ATENCIÓN! ¡Todos los pilares de piedra han colapsado! ¡La bestia no podrá ser aturdida de nuevo! ¡Usa Stimpack y máxima concentración de fuego!»",
			6.0
		)

func _on_boss_stunned(_duration: float) -> void:
	_trigger_camera_shake(8.0)
	_send_voss_radio(
		"«¡IMPACTO DIRECTO! ¡El titán chocó contra el pilar y está indefenso! ¡SU CORAZA ESTÁ ROTA, ABRAN FUEGO AHORA!»",
		4.5
	)

func _on_boss_died() -> void:
	_trigger_camera_shake(14.0)
	
	# Activar misión completada en GameManager
	GameManager.mission_bosses += 1
	GameManager._check_mission_progress()
	
	# Activar baliza de evacuación en el centro tras breve pausa dramática
	var tw = create_tween()
	tw.tween_interval(2.5)
	tw.tween_callback(func():
		if evac_circle:
			evac_circle.visible = true
			evac_circle.monitoring = true
			evac_circle.monitorable = true
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
		"«¡ALERTA TÁCTICA! Has descendido al Nido Central del Torrasque. Su blindaje natural es casi impenetrable en movimiento. ¡Haz que embista contra los 6 pilares para fracturar su coraza!»",
		7.0
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
	# Atajo debug para victoria inmediata en pruebas (F10)
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_F10:
			if is_instance_valid(torrasque_boss):
				torrasque_boss.take_damage(9999.0)
				get_viewport().set_input_as_handled()
