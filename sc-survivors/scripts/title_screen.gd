class_name TitleScreen
extends Control

@onready var start_button: Button = $VBoxContainer/StartButton
@onready var options_button: Button = $VBoxContainer/OptionsButton
@onready var quit_button: Button = $VBoxContainer/QuitButton

@onready var options_panel: Panel = $OptionsPanel
@onready var music_slider: HSlider = $OptionsPanel/VBox/MusicSlider
@onready var music_label: Label = $OptionsPanel/VBox/MusicLabel
@onready var sfx_slider: HSlider = $OptionsPanel/VBox/SfxSlider
@onready var sfx_label: Label = $OptionsPanel/VBox/SfxLabel
@onready var fullscreen_check: CheckButton = $OptionsPanel/VBox/FullscreenCheck
@onready var close_options_btn: Button = $OptionsPanel/VBox/CloseBtn

# Armería Terran
@onready var armory_panel: Panel = $ArmoryPanel
@onready var armory_minerals_label: Label = $ArmoryPanel/VBox/StatsHBox/ArmoryMineralsLabel
@onready var armory_kills_label: Label = $ArmoryPanel/VBox/StatsHBox/ArmoryKillsLabel
@onready var armory_rank_label: Label = $ArmoryPanel/VBox/StatsHBox/ArmoryRankLabel
@onready var rank_info_label: Label = $ArmoryPanel/VBox/RankInfoLabel
@onready var perks_container: VBoxContainer = $ArmoryPanel/VBox/ScrollContainer/PerksContainer
@onready var close_armory_btn: Button = $ArmoryPanel/VBox/CloseArmoryBtn

# Ranuras de Guardado
@onready var slots_panel: Panel = $SlotsPanel
@onready var slots_container: VBoxContainer = $SlotsPanel/VBox/SlotsContainer
@onready var close_slots_btn: Button = $SlotsPanel/VBox/CloseSlotsBtn

func _ready() -> void:
	var cursor_tex = SkinManager.get_ui("cursor")
	if cursor_tex:
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2.ZERO)
	
	options_panel.visible = false
	armory_panel.visible = false
	slots_panel.visible = false
	
	# Musica del menu
	AudioManager.play_music("terran1")
	
	# Sliders
	music_slider.value = AudioManager.music_volume
	music_label.text = "Volumen Música: %d%%" % int(AudioManager.music_volume * 100)
	music_slider.value_changed.connect(func(val):
		AudioManager.set_music_volume(val)
		music_label.text = "Volumen Música: %d%%" % int(val * 100)
	)
	
	sfx_slider.value = AudioManager.sfx_volume
	sfx_label.text = "Volumen Efectos: %d%%" % int(AudioManager.sfx_volume * 100)
	sfx_slider.value_changed.connect(func(val):
		AudioManager.set_sfx_volume(val)
		sfx_label.text = "Volumen Efectos: %d%%" % int(val * 100)
	)
	
	# Fullscreen
	var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.button_pressed = is_fs
	fullscreen_check.toggled.connect(func(pressed):
		AudioManager.play_sfx("button")
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	
	# Conectar botones
	start_button.pressed.connect(_on_start_pressed)
	options_button.pressed.connect(_on_options_pressed)
	quit_button.pressed.connect(_on_quit_pressed)
	close_options_btn.pressed.connect(func():
		AudioManager.play_sfx("button")
		options_panel.visible = false
	)
	close_armory_btn.pressed.connect(func():
		AudioManager.play_sfx("button")
		armory_panel.visible = false
	)
	close_slots_btn.pressed.connect(func():
		AudioManager.play_sfx("button")
		slots_panel.visible = false
	)
	
	for btn in [start_button, options_button, quit_button, close_options_btn, close_armory_btn, close_slots_btn]:
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11 or (event.alt_pressed and event.keycode == KEY_ENTER):
			var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
			fullscreen_check.set_pressed_no_signal(!is_fs)
		elif event.keycode == KEY_ESCAPE:
			if slots_panel.visible:
				slots_panel.visible = false
			elif armory_panel.visible:
				armory_panel.visible = false
			elif options_panel.visible:
				options_panel.visible = false

func _on_start_pressed() -> void:
	AudioManager.play_sfx("button")
	armory_panel.visible = false
	options_panel.visible = false
	_refresh_slots()
	slots_panel.visible = true

func _refresh_slots() -> void:
	if not has_node("/root/SaveManager"):
		return
	
	for child in slots_container.get_children():
		slots_container.remove_child(child)
		child.queue_free()
	
	for slot_idx in range(1, 4):
		var info = SaveManager.get_slot_summary(slot_idx)
		
		var panel = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.05, 0.08, 0.13, 0.92)
		sb.border_color = Color(0.2, 0.5, 0.8, 0.8)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(3)
		panel.add_theme_stylebox_override("panel", sb)
		
		var hbox = HBoxContainer.new()
		hbox.set("theme_override_constants/separation", 12)
		hbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.set("theme_override_constants/separation", 2)
		
		if info.exists:
			var title_lbl = Label.new()
			title_lbl.text = "EXPEDIENTE #%d: %s" % [slot_idx, info.stage_name]
			title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.3, 1.0))
			title_lbl.add_theme_font_size_override("font_size", 11)
			info_vbox.add_child(title_lbl)
			
			var stats_lbl = Label.new()
			stats_lbl.text = "Min: %d   Gas: %d   Kills: %d   |   Despliegues: %d" % [info.minerals, info.gas, info.kills, info.runs]
			stats_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.65, 1.0))
			stats_lbl.add_theme_font_size_override("font_size", 9)
			info_vbox.add_child(stats_lbl)
			
			hbox.add_child(info_vbox)
			
			# Botón Continuar
			var cont_btn = Button.new()
			cont_btn.custom_minimum_size = Vector2(90, 26)
			cont_btn.add_theme_font_size_override("font_size", 10)
			cont_btn.text = "CONTINUAR"
			cont_btn.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
			var s_id = slot_idx
			var stage_val = info.stage
			cont_btn.pressed.connect(func():
				AudioManager.play_sfx("button")
				SaveManager.select_slot(s_id)
				if stage_val == "prologue":
					get_tree().change_scene_to_file("res://scenes/prologue.tscn")
				else:
					get_tree().change_scene_to_file("res://scenes/terran_base.tscn")
			)
			cont_btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))
			hbox.add_child(cont_btn)
			
			# Botón Borrar
			var del_btn = Button.new()
			del_btn.custom_minimum_size = Vector2(65, 26)
			del_btn.add_theme_font_size_override("font_size", 9)
			del_btn.text = "BORRAR"
			del_btn.add_theme_color_override("font_color", Color(1.0, 0.4, 0.4, 1.0))
			del_btn.pressed.connect(func():
				AudioManager.play_sfx("button")
				SaveManager.delete_slot(s_id)
				_refresh_slots()
			)
			del_btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))
			hbox.add_child(del_btn)
		else:
			var title_lbl = Label.new()
			title_lbl.text = "EXPEDIENTE #%d: [VACÍO]" % slot_idx
			title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 0.7))
			title_lbl.add_theme_font_size_override("font_size", 11)
			info_vbox.add_child(title_lbl)
			
			var stats_lbl = Label.new()
			stats_lbl.text = "Memoria no inicializada // Sin registros previos"
			stats_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.6))
			stats_lbl.add_theme_font_size_override("font_size", 9)
			info_vbox.add_child(stats_lbl)
			
			hbox.add_child(info_vbox)
			
			var new_btn = Button.new()
			new_btn.custom_minimum_size = Vector2(120, 26)
			new_btn.add_theme_font_size_override("font_size", 10)
			new_btn.text = "NUEVA PARTIDA"
			new_btn.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
			var s_id = slot_idx
			new_btn.pressed.connect(func():
				AudioManager.play_sfx("button")
				SaveManager.reset_slot_to_new_game(s_id)
				get_tree().change_scene_to_file("res://scenes/prologue.tscn")
			)
			new_btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))
			hbox.add_child(new_btn)
		
		panel.add_child(hbox)
		slots_container.add_child(panel)

func _on_armory_pressed() -> void:
	AudioManager.play_sfx("button")
	options_panel.visible = false
	slots_panel.visible = false
	_refresh_armory()
	armory_panel.visible = true

func _refresh_armory() -> void:
	if not has_node("/root/SaveManager"):
		return
	
	armory_minerals_label.text = "MINERALES: %d" % SaveManager.total_minerals
	armory_kills_label.text = "KILLS TOTALES: %d" % SaveManager.total_kills
	
	var r_info = SaveManager.get_current_rank()
	armory_rank_label.text = "RANGO: %s (%s)" % [r_info["name"], r_info["title"]]
	
	if r_info["current_kills"] >= 1000000:
		rank_info_label.text = "★ RANGO MÁXIMO ALCANZADO: MARISCAL SUPREMO DE KOPRULU ★"
	else:
		var pct = int(r_info["progress"] * 100.0)
		rank_info_label.text = "Próximo ascenso a: %d Kills | Progreso actual: %d%%" % [r_info["next_milestone_kills"], pct]
	
	for child in perks_container.get_children():
		child.queue_free()
	
	# Mejoras permanentes activas
	for p_id in SaveManager.PERKS_DEF.keys():
		var p_def = SaveManager.PERKS_DEF[p_id]
		var cur_lvl = SaveManager.get_perk_level(p_id)
		var max_lvl = p_def["max_lvl"]
		var cost = SaveManager.get_perk_cost(p_id)
		var can_buy = SaveManager.can_buy_perk(p_id)
		
		var row = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.06, 0.10, 0.16, 0.9)
		sb.border_color = Color(0.18, 0.42, 0.72, 0.8)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		row.add_theme_stylebox_override("panel", sb)
		
		var hbox = HBoxContainer.new()
		hbox.set("theme_override_constants/separation", 10)
		
		# Icono StarCraft auténtico 38x38
		var perk_icon_map = {
			"armor": 2,
			"damage": 3,
			"max_hp": 2,
			"regen": 7,
			"speed": 1,
			"magnet": 0
		}
		var icon_rect = TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(38, 38)
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon_rect.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var atlas = AtlasTexture.new()
		atlas.atlas = load("res://assets/skins/sd/sprites/tech_icons_clean.png")
		var icon_idx = perk_icon_map.get(p_id, 0)
		atlas.region = Rect2(icon_idx * 48, 0, 48, 48)
		icon_rect.texture = atlas
		hbox.add_child(icon_rect)
		
		# Info VBox
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.set("theme_override_constants/separation", 2)
		
		var title_lbl = Label.new()
		title_lbl.text = "%s [Nivel %d/%d]" % [p_def["name"], cur_lvl, max_lvl]
		title_lbl.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0) if cur_lvl > 0 else Color(0.85, 0.9, 0.95, 1.0))
		title_lbl.add_theme_font_size_override("font_size", 11)
		info_vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = p_def["desc"]
		desc_lbl.add_theme_color_override("font_color", Color(0.35, 0.85, 0.55, 1.0))
		desc_lbl.add_theme_font_size_override("font_size", 9)
		info_vbox.add_child(desc_lbl)
		
		hbox.add_child(info_vbox)
		
		# Botón comprar
		var buy_btn = Button.new()
		buy_btn.custom_minimum_size = Vector2(115, 26)
		buy_btn.add_theme_font_size_override("font_size", 10)
		
		if cur_lvl >= max_lvl:
			buy_btn.text = "MAXIMIZADO"
			buy_btn.disabled = true
		else:
			buy_btn.text = ""
			buy_btn.disabled = not can_buy
			
			var btn_hb = HBoxContainer.new()
			btn_hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
			btn_hb.alignment = BoxContainer.ALIGNMENT_CENTER
			btn_hb.set_anchors_preset(Control.PRESET_FULL_RECT)
			btn_hb.add_theme_constant_override("separation", 6)
			
			var lbl_mej = Label.new()
			lbl_mej.text = "MEJORAR"
			lbl_mej.add_theme_font_size_override("font_size", 9)
			lbl_mej.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0) if can_buy else Color(0.7, 0.7, 0.7, 0.8))
			btn_hb.add_child(lbl_mej)
			
			var ico = TextureRect.new()
			ico.texture = load("res://assets/skins/sd/ui/icon_mineral.png")
			ico.custom_minimum_size = Vector2(13, 13)
			ico.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			ico.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			btn_hb.add_child(ico)
			
			var cost_lbl = Label.new()
			cost_lbl.text = "%d" % cost
			cost_lbl.add_theme_font_size_override("font_size", 9)
			cost_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0) if can_buy else Color(0.7, 0.7, 0.7, 0.8))
			btn_hb.add_child(cost_lbl)
			
			buy_btn.add_child(btn_hb)
			
			var id_copy = p_id
			buy_btn.pressed.connect(func():
				if SaveManager.buy_perk(id_copy):
					AudioManager.play_sfx("upgrade")
					_refresh_armory()
			)
			buy_btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))
		
		hbox.add_child(buy_btn)
		row.add_child(hbox)
		perks_container.add_child(row)
	
	# Placeholders de la hoja de ruta (Roadmap futuras mejoras bloqueadas)
	var roadmap_locked = [
		{"name": "Manto de Camuflaje Ghost [Hoja de Ruta]", "desc": "Invisibilidad táctica temporal ante enjambres."},
		{"name": "Cañón de Asedio Arclite [Hoja de Ruta]", "desc": "Bombardeo orbital de artillería pesada 120mm."},
		{"name": "Propulsores Ígneos Firebat [Hoja de Ruta]", "desc": "Carga incendiaria que empuja y abrasa enemigos."}
	]
	
	for locked_def in roadmap_locked:
		var row = PanelContainer.new()
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.05, 0.08, 0.7)
		sb.border_color = Color(0.3, 0.35, 0.4, 0.5)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(2)
		row.add_theme_stylebox_override("panel", sb)
		
		var hbox = HBoxContainer.new()
		hbox.set("theme_override_constants/separation", 10)
		
		var info_vbox = VBoxContainer.new()
		info_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		info_vbox.set("theme_override_constants/separation", 2)
		
		var title_lbl = Label.new()
		title_lbl.text = "🔒 %s" % locked_def["name"]
		title_lbl.add_theme_color_override("font_color", Color(0.6, 0.65, 0.7, 0.8))
		title_lbl.add_theme_font_size_override("font_size", 10)
		info_vbox.add_child(title_lbl)
		
		var desc_lbl = Label.new()
		desc_lbl.text = locked_def["desc"]
		desc_lbl.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 0.7))
		desc_lbl.add_theme_font_size_override("font_size", 8)
		info_vbox.add_child(desc_lbl)
		
		hbox.add_child(info_vbox)
		
		var lock_lbl = Label.new()
		lock_lbl.custom_minimum_size = Vector2(110, 26)
		lock_lbl.text = "[BLOQUEADO]"
		lock_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		lock_lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		lock_lbl.add_theme_color_override("font_color", Color(0.6, 0.3, 0.3, 0.9))
		lock_lbl.add_theme_font_size_override("font_size", 9)
		hbox.add_child(lock_lbl)
		
		row.add_child(hbox)
		perks_container.add_child(row)

func _on_options_pressed() -> void:
	AudioManager.play_sfx("button")
	armory_panel.visible = false
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.set_pressed_no_signal(is_fs)
	options_panel.visible = true

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().quit()

func _update_background_skin() -> void:
	var bg = get_node_or_null("Background") as TextureRect
	if bg:
		var tex = SkinManager.get_ui("title")
		if tex:
			bg.texture = tex
	var cursor_tex = SkinManager.get_ui("cursor")
	if cursor_tex:
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2.ZERO)

