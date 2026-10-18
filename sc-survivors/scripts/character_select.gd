class_name CharacterSelect
extends Control

@onready var start_button: Button = $StartButton
@onready var cancel_button: Button = $CancelButton

# Monitores de personajes
@onready var marine_monitor: Control = $Monitors/MarineMonitor
@onready var firebat_monitor: Control = $Monitors/FirebatMonitor
@onready var ghost_monitor: Control = $Monitors/GhostMonitor
@onready var goliath_monitor: Control = $Monitors/GoliathMonitor

@onready var marine_button: Button = $Monitors/MarineMonitor/Button
@onready var firebat_button: Button = $Monitors/FirebatMonitor/Button
@onready var ghost_button: Button = $Monitors/GhostMonitor/Button
@onready var goliath_button: Button = $Monitors/GoliathMonitor/Button

@onready var marine_portrait: SCPortrait = $Monitors/MarineMonitor/Portrait
@onready var firebat_portrait: SCPortrait = $Monitors/FirebatMonitor/Portrait
@onready var ghost_portrait: SCPortrait = $Monitors/GhostMonitor/Portrait
@onready var goliath_portrait: SCPortrait = $Monitors/GoliathMonitor/Portrait

@onready var marine_highlight: TextureRect = $Monitors/MarineMonitor/Highlight
@onready var firebat_highlight: TextureRect = $Monitors/FirebatMonitor/Highlight
@onready var ghost_highlight: TextureRect = $Monitors/GhostMonitor/Highlight
@onready var goliath_highlight: TextureRect = $Monitors/GoliathMonitor/Highlight

# Panel Central y Objetivos
@onready var center_panel: Panel = $CenterPanel
@onready var obj_header: Label = $ObjHeaderLabel
@onready var obj_panel: Panel = $ObjectivesPanel

@onready var unit_name_label: Label = $CenterPanel/VBox/UnitNameLabel
@onready var unit_role_label: Label = $CenterPanel/VBox/UnitRoleLabel
@onready var stats_grid: GridContainer = $CenterPanel/VBox/StatsGrid
@onready var stat_hp_label: Label = $CenterPanel/VBox/StatsGrid/HpLabel
@onready var stat_armor_label: Label = $CenterPanel/VBox/StatsGrid/ArmorLabel
@onready var stat_weapon_label: Label = $CenterPanel/VBox/StatsGrid/WeaponLabel
@onready var stat_damage_label: Label = $CenterPanel/VBox/StatsGrid/DamageLabel
@onready var stat_rate_label: Label = $CenterPanel/VBox/StatsGrid/RateLabel
@onready var stat_speed_label: Label = $CenterPanel/VBox/StatsGrid/SpeedLabel
@onready var skill_label: Label = $CenterPanel/VBox/SkillLabel
@onready var lore_label: Label = $CenterPanel/VBox/LoreLabel
@onready var status_badge: Label = $CenterPanel/VBox/StatusBadge

@onready var obj1: Label = $ObjectivesPanel/VBox/Obj1
@onready var obj2: Label = $ObjectivesPanel/VBox/Obj2
@onready var obj3: Label = $ObjectivesPanel/VBox/Obj3
@onready var obj4: Label = $ObjectivesPanel/VBox/Obj4
@onready var obj5: Label = $ObjectivesPanel/VBox/Obj5

var selected_hero: String = "marine"
var current_selected_monitor: String = "marine"
var orig_positions: Dictionary = {}
var is_transitioning: bool = false
var initial_hero: String = "marine"

func _ready() -> void:
	initial_hero = GameManager.selected_hero
	var cursor_tex = SkinManager.get_ui("cursor")
	if cursor_tex:
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2.ZERO)
	
	# Guardar posiciones originales para la animación mecánica de despliegue
	var anim_nodes = [
		marine_monitor, firebat_monitor, ghost_monitor, goliath_monitor,
		center_panel, obj_header, obj_panel, start_button, cancel_button
	]
	for n in anim_nodes:
		orig_positions[n] = n.position
	
	# Posición fuera de pantalla antes de llegar según su brazo mecánico
	marine_monitor.position = Vector2(-200, orig_positions[marine_monitor].y)
	firebat_monitor.position = Vector2(orig_positions[firebat_monitor].x, -160)
	ghost_monitor.position = Vector2(orig_positions[ghost_monitor].x, -160)
	goliath_monitor.position = Vector2(1000, orig_positions[goliath_monitor].y)
	center_panel.position = Vector2(orig_positions[center_panel].x, -260)
	obj_header.position = Vector2(-300, orig_positions[obj_header].y)
	obj_panel.position = Vector2(-300, orig_positions[obj_panel].y)
	start_button.position = Vector2(orig_positions[start_button].x, 560)
	cancel_button.position = Vector2(orig_positions[cancel_button].x, 560)
	
	# Botones de monitores activos y bloqueados
	marine_button.text = ""
	firebat_button.text = "???"
	ghost_button.text = "???"
	goliath_button.text = "???"
	
	# Música de briefing original de StarCraft
	AudioManager.play_music("trdyroom")
	
	_apply_skin()
	
	# Mantener héroe seleccionado previo (Marine o Médica)
	selected_hero = GameManager.selected_hero if (GameManager.selected_hero == "medic" or GameManager.selected_hero == "marine") else "marine"
	current_selected_monitor = "marine"
	_update_marine_monitor_skin()
	_show_hero(selected_hero)
	
	if selected_hero == "medic" and marine_portrait:
		marine_portrait.trigger_talk(1.8)
	elif marine_portrait:
		marine_portrait.trigger_talk(1.8)
	
	marine_button.pressed.connect(_on_marine_button_pressed)
	firebat_button.pressed.connect(func(): _select_monitor("firebat"))
	ghost_button.pressed.connect(func(): _select_monitor("ghost"))
	goliath_button.pressed.connect(func(): _select_monitor("goliath"))
	
	for btn in [marine_button, firebat_button, ghost_button, goliath_button, start_button, cancel_button]:
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))
	
	start_button.pressed.connect(_on_start_pressed)
	cancel_button.pressed.connect(_on_cancel_pressed)
	
	_play_entrance_animation()

func _apply_skin() -> void:
	_update_marine_monitor_skin()
	
	# Unidades bloqueadas con monitor en negro/señal azul sin rostro
	if firebat_portrait: firebat_portrait.set_portrait(null)
	if ghost_portrait: ghost_portrait.set_portrait(null)
	if goliath_portrait: goliath_portrait.set_portrait(null)
	
	var chassis_texs = [
		SkinManager.get_ui("tframe1"),
		SkinManager.get_ui("tframe2"),
		SkinManager.get_ui("tframe3"),
		SkinManager.get_ui("tframe4")
	]
	var high_texs = [
		SkinManager.get_ui("tframeh1"),
		SkinManager.get_ui("tframeh2"),
		SkinManager.get_ui("tframeh3"),
		SkinManager.get_ui("tframeh4")
	]
	var monitors = [marine_monitor, firebat_monitor, ghost_monitor, goliath_monitor]
	for i in range(4):
		var m = monitors[i]
		if not is_instance_valid(m): continue
		var c = m.get_node_or_null("Chassis") as TextureRect
		if c and chassis_texs[i]: c.texture = chassis_texs[i]
		var h = m.get_node_or_null("Highlight") as TextureRect
		if h and high_texs[i]: h.texture = high_texs[i]
	
	var bg = get_node_or_null("Background") as TextureRect
	if bg:
		var bg_tex = SkinManager.get_ui("briefing")
		if bg_tex: bg.texture = bg_tex

func _update_marine_monitor_skin() -> void:
	if not marine_portrait:
		return
	var badge = marine_monitor.get_node_or_null("Badge") as Label
	
	if selected_hero == "medic":
		var p_medic = SkinManager.get_portrait("medic")
		if p_medic:
			marine_portrait.set_portrait(p_medic)
		marine_portrait.voice_list = [
			"medic_what0", "medic_what1", "medic_what2", "medic_what3",
			"medic_yes0", "medic_yes1", "medic_yes2", "medic_yes3"
		]
		if badge: badge.text = "MÉDICA TERRAN"
	else:
		var p_marine = SkinManager.get_portrait("marine")
		if p_marine:
			marine_portrait.set_portrait(p_marine)
		marine_portrait.voice_list = ["marine_what0", "marine_what1", "marine_yes0", "marine_yes1"]
		if badge: badge.text = "MARINE CMC-300"

func _play_entrance_animation() -> void:
	is_transitioning = true
	var tw = create_tween().set_parallel(true)
	var dur = 0.45
	for n in orig_positions.keys():
		tw.tween_property(n, "position", orig_positions[n], dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func():
		is_transitioning = false
	)

func _play_exit_animation(on_complete: Callable) -> void:
	is_transitioning = true
	AudioManager.play_sfx("liftoff")
	var tw = create_tween().set_parallel(true)
	var dur = 0.35
	tw.tween_property(marine_monitor, "position", Vector2(-200, orig_positions[marine_monitor].y), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(firebat_monitor, "position", Vector2(orig_positions[firebat_monitor].x, -160), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(ghost_monitor, "position", Vector2(orig_positions[ghost_monitor].x, -160), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(goliath_monitor, "position", Vector2(1000, orig_positions[goliath_monitor].y), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(center_panel, "position", Vector2(orig_positions[center_panel].x, -260), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(obj_header, "position", Vector2(-300, orig_positions[obj_header].y), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(obj_panel, "position", Vector2(-300, orig_positions[obj_panel].y), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(start_button, "position", Vector2(orig_positions[start_button].x, 560), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.tween_property(cancel_button, "position", Vector2(orig_positions[cancel_button].x, 560), dur).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	tw.chain().tween_callback(on_complete)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo:
		if event.keycode == KEY_ESCAPE:
			_on_cancel_pressed()

func _on_marine_button_pressed() -> void:
	if is_transitioning:
		return
	
	if current_selected_monitor == "marine":
		# Ya está en el monitor del Marine: presionar la cara hace que la pantalla se vaya y vuelva con la otra skin
		_toggle_marine_skin_animation()
	else:
		current_selected_monitor = "marine"
		_show_hero(selected_hero)
		if selected_hero == "medic":
			if marine_portrait: marine_portrait.trigger_talk(1.8)
			AudioManager.play_sfx("medic_ready")
		else:
			if marine_portrait: marine_portrait.trigger_talk(1.8)
			AudioManager.play_sfx("marine_ready")

func _toggle_marine_skin_animation() -> void:
	is_transitioning = true
	AudioManager.play_sfx("liftoff")
	var target_hero = "medic" if selected_hero == "marine" else "marine"
	
	var tw = create_tween()
	# 1. La pantalla se va rápidamente hacia arriba
	tw.tween_property(marine_monitor, "position:y", -180.0, 0.22).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	# 2. En el punto oculto se actualiza la skin a la médica o al marine
	tw.tween_callback(func():
		selected_hero = target_hero
		GameManager.selected_hero = selected_hero
		if has_node("/root/SaveManager"):
			SaveManager.save_data()
		_update_marine_monitor_skin()
		_show_hero(selected_hero)
	)
	# 3. La pantalla vuelve cayendo con rebote mecánico auténtico
	tw.tween_property(marine_monitor, "position:y", orig_positions[marine_monitor].y, 0.28).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	tw.chain().tween_callback(func():
		is_transitioning = false
		if selected_hero == "medic":
			if marine_portrait: marine_portrait.trigger_talk(1.8)
			AudioManager.play_sfx("medic_ready")
		else:
			if marine_portrait: marine_portrait.trigger_talk(1.8)
			AudioManager.play_sfx("marine_ready")
	)

func _select_monitor(mon_id: String) -> void:
	if is_transitioning:
		return
	current_selected_monitor = mon_id
	AudioManager.play_sfx("button")
	_show_hero(mon_id)

func _show_hero(hero_id: String) -> void:
	marine_highlight.visible = (current_selected_monitor == "marine")
	firebat_highlight.visible = (current_selected_monitor == "firebat")
	ghost_highlight.visible = (current_selected_monitor == "ghost")
	goliath_highlight.visible = (current_selected_monitor == "goliath")
	
	match hero_id:
		"marine":
			unit_name_label.text = "MARINE TERRAN"
			unit_role_label.text = "Infantería Ligera de Asalto (Armadura CMC-300)"
			stats_grid.visible = true
			stat_hp_label.text = "Vida: 40 PS"
			stat_armor_label.text = "Armadura: 1"
			stat_weapon_label.text = "Arma: Rifle Gauss C-14"
			stat_damage_label.text = "Daño: 14 dmg"
			stat_rate_label.text = "Cadencia: 2.4/s"
			stat_speed_label.text = "Velocidad: 120 px/s"
			skill_label.visible = true
			skill_label.text = "HABILIDAD: Estimulantes [T] (+50% vel/cad x 5s, -10 PS)"
			lore_label.visible = true
			lore_label.text = "Soldado confederado curtido en combate. Versátil y letal ante enjambres masivos."
			status_badge.text = "[ DESPLEGADO Y LISTO PARA COMBATE ]"
			status_badge.modulate = Color(0.25, 1.0, 0.35, 1.0)
			
			obj_header.text = "EXPEDIENTE TÁCTICO"
			obj1.visible = true
			obj1.text = "• Infantería básica asignada a la expedición."
			obj2.visible = true
			obj2.text = "• Asistencia de tiro automática en armadura CMC-300."
			obj3.visible = true
			obj3.text = "• Extraer mediante nave para conservar minerales."
			obj4.visible = false
			obj5.visible = false
			
			start_button.disabled = false
			if GameManager.character_select_source == "barracks":
				start_button.text = "EQUIPAR PERSONAJE"
			else:
				start_button.text = "INICIAR MISIÓN"
		"medic":
			unit_name_label.text = "MÉDICA TERRAN"
			unit_role_label.text = "Infantería Ligera de Asalto (Armadura CMC-300)"
			stats_grid.visible = true
			stat_hp_label.text = "Vida: 40 PS"
			stat_armor_label.text = "Armadura: 1"
			stat_weapon_label.text = "Arma: Rifle Gauss C-14"
			stat_damage_label.text = "Daño: 14 dmg"
			stat_rate_label.text = "Cadencia: 2.4/s"
			stat_speed_label.text = "Velocidad: 120 px/s"
			skill_label.visible = true
			skill_label.text = "HABILIDAD: Estimulantes [T] (+50% vel/cad x 5s, -10 PS)"
			lore_label.visible = true
			lore_label.text = "Soldado confederado curtido en combate. Versátil y letal ante enjambres masivos."
			status_badge.text = "[ DESPLEGADO Y LISTO PARA COMBATE ]"
			status_badge.modulate = Color(0.25, 1.0, 0.35, 1.0)
			
			obj_header.text = "EXPEDIENTE TÁCTICO"
			obj1.visible = true
			obj1.text = "• Infantería básica asignada a la expedición."
			obj2.visible = true
			obj2.text = "• Asistencia de tiro automática en armadura CMC-300."
			obj3.visible = true
			obj3.text = "• Extraer mediante nave para conservar minerales."
			obj4.visible = false
			obj5.visible = false
			
			start_button.disabled = false
			if GameManager.character_select_source == "barracks":
				start_button.text = "EQUIPAR PERSONAJE"
			else:
				start_button.text = "INICIAR MISIÓN"
		"firebat":
			unit_name_label.text = "??? [UNIDAD TÁCTICA BLOQUEADA]"
			unit_role_label.text = "[ ARCHIVO CLASIFICADO // SEÑAL ENCRIPTADA ]"
			stats_grid.visible = false
			skill_label.visible = false
			lore_label.visible = false
			status_badge.text = "[ PROTOCOLO BLOQUEADO // ACCESO DENEGADO ]"
			status_badge.modulate = Color(1.0, 0.4, 0.4, 1.0)
			
			obj_header.text = "CONDICIÓN DE DESBLOQUEO"
			obj1.visible = true
			obj1.text = "• Sobrevivir 10 minutos en el páramo exterior."
			obj2.visible = true
			obj2.text = "• Costo de adquisición: 500 Minerales."
			obj3.visible = true
			obj3.text = "• Estado: No disponible actualmente."
			obj4.visible = false
			obj5.visible = false
			
			start_button.disabled = true
			start_button.text = "UNIDAD BLOQUEADA"
		"ghost":
			unit_name_label.text = "??? [OPERATIVO ENCUBIERTO BLOQUEADO]"
			unit_role_label.text = "[ ARCHIVO CLASIFICADO // SEÑAL ENCRIPTADA ]"
			stats_grid.visible = false
			skill_label.visible = false
			lore_label.visible = false
			status_badge.text = "[ PROTOCOLO BLOQUEADO // ACCESO DENEGADO ]"
			status_badge.modulate = Color(1.0, 0.4, 0.4, 1.0)
			
			obj_header.text = "CONDICIÓN DE DESBLOQUEO"
			obj1.visible = true
			obj1.text = "• Acumular 1000 Minerales en total en la campaña."
			obj2.visible = true
			obj2.text = "• Estado: No disponible actualmente."
			obj3.visible = false
			obj4.visible = false
			obj5.visible = false
			
			start_button.disabled = true
			start_button.text = "UNIDAD BLOQUEADA"
		"goliath":
			unit_name_label.text = "??? [VEHÍCULO PESADO BLOQUEADO]"
			unit_role_label.text = "[ ARCHIVO CLASIFICADO // SEÑAL ENCRIPTADA ]"
			stats_grid.visible = false
			skill_label.visible = false
			lore_label.visible = false
			status_badge.text = "[ PROTOCOLO BLOQUEADO // ACCESO DENEGADO ]"
			status_badge.modulate = Color(1.0, 0.4, 0.4, 1.0)
			
			obj_header.text = "CONDICIÓN DE DESBLOQUEO"
			obj1.visible = true
			obj1.text = "• Derrotar al Jefe del Acto 1 (Ultralisco Titán en el Nydus)."
			obj2.visible = true
			obj2.text = "• Estado: Requiere completar el Acto 1."
			obj3.visible = false
			obj4.visible = false
			obj5.visible = false
			
			start_button.disabled = true
			start_button.text = "UNIDAD BLOQUEADA"

func _on_start_pressed() -> void:
	if is_transitioning:
		return
	start_button.disabled = true
	cancel_button.disabled = true
	if selected_hero == "medic":
		AudioManager.play_sfx("medic_ready")
	else:
		AudioManager.play_sfx("marine_ready")
	_play_exit_animation(func():
		GameManager.selected_hero = selected_hero
		if has_node("/root/SaveManager"):
			SaveManager.save_data()
		
		if GameManager.character_select_source == "barracks":
			get_tree().change_scene_to_file("res://scenes/terran_base.tscn")
		else:
			GameManager.start_new_run(selected_hero)
			GameManager.deploy_to_mission()
	)

func _on_cancel_pressed() -> void:
	if is_transitioning:
		return
	start_button.disabled = true
	cancel_button.disabled = true
	GameManager.selected_hero = initial_hero
	if has_node("/root/SaveManager"):
		SaveManager.save_data()
	AudioManager.play_sfx("button")
	_play_exit_animation(func():
		get_tree().change_scene_to_file("res://scenes/terran_base.tscn")
	)
