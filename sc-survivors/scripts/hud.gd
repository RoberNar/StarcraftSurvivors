class_name GameHUD
extends CanvasLayer

# Referencias Top Bar
@onready var top_bar: Panel = $TopBar
@onready var time_label: Label = get_node_or_null("TopBar/HBox/TimeLabel")
@onready var minerals_label: Label = get_node_or_null("TopBar/HBox/MineralHBox/MineralsLabel") if has_node("TopBar/HBox/MineralHBox/MineralsLabel") else get_node_or_null("TopBar/HBox/MineralsLabel")
@onready var gas_label: Label = get_node_or_null("TopBar/HBox/GasHBox/GasLabel") if has_node("TopBar/HBox/GasHBox/GasLabel") else get_node_or_null("TopBar/HBox/GasLabel")
@onready var kills_label: Label = get_node_or_null("TopBar/HBox/KillsLabel")
@onready var mission_tracker_label: Label = get_node_or_null("TopBar/HBox/MissionTrackerLabel")
@onready var level_label: Label = get_node_or_null("TopBar/HBox/LevelLabel")
@onready var xp_bar: ProgressBar = get_node_or_null("XpBar")

# Referencias Consola Inferior (tconsole)
@onready var console_texture: TextureRect = $ConsoleRect
@onready var radar_control: Control = $ConsoleRect/RadarControl
@onready var wireframe_rect: TextureRect = $ConsoleRect/WireframeRect
@onready var sc_hp_bar: Control = $ConsoleRect/SCHealthBar
@onready var hp_label: Label = $ConsoleRect/HpLabel
@onready var portrait_control: SCPortrait = $ConsoleRect/PortraitControl

# Info Unidad Centro
@onready var unit_name_label: Label = $ConsoleRect/UnitInfo/UnitNameLabel
@onready var rank_label: Label = $ConsoleRect/UnitInfo/RankLabel
@onready var weapon_label: Label = $ConsoleRect/UnitInfo/WeaponLabel
@onready var armor_label: Label = $ConsoleRect/UnitInfo/ArmorLabel
@onready var stim_status_label: Label = $ConsoleRect/UnitInfo/StimStatusLabel
@onready var kills_unit_label: Label = $ConsoleRect/UnitInfo/KillsUnitLabel

# Ranura de Arma Base del Marine (Centralizada a la derecha de las estadísticas)
@onready var base_weapon_slot: Panel = $ConsoleRect/BaseWeaponSlot
@onready var base_weapon_icon: TextureRect = $ConsoleRect/BaseWeaponSlot/IconRect
@onready var base_weapon_badge: Label = $ConsoleRect/BaseWeaponSlot/BadgeLabel

# Command Grid (Inventario 3x3: Armas secundarias + Pasivas)
@onready var command_grid: GridContainer = $ConsoleRect/CommandGrid

# Modales
@onready var level_up_panel: Panel = $LevelUpPanel
@onready var level_up_title: Label = $LevelUpPanel/VBoxContainer/TitleLabel
@onready var cards_container: HBoxContainer = $LevelUpPanel/VBoxContainer/CardsContainer
@onready var game_over_panel: Panel = $GameOverPanel
@onready var game_over_stats: Label = $GameOverPanel/VBoxContainer/StatsLabel
@onready var retry_button: Button = $GameOverPanel/VBoxContainer/RetryButton
@onready var return_base_button: Button = $GameOverPanel/VBoxContainer/ReturnBaseButton

# Menu de Pausa y Logros
@onready var pause_panel: Panel = $PausePanel
@onready var music_label: Label = $PausePanel/MainHBox/VBox/MusicLabel
@onready var music_slider: HSlider = $PausePanel/MainHBox/VBox/MusicSlider
@onready var sfx_label: Label = $PausePanel/MainHBox/VBox/SfxLabel
@onready var sfx_slider: HSlider = $PausePanel/MainHBox/VBox/SfxSlider
@onready var voice_label: Label = $PausePanel/MainHBox/VBox/VoiceLabel
@onready var voice_slider: HSlider = $PausePanel/MainHBox/VBox/VoiceSlider
@onready var fullscreen_check: CheckButton = $PausePanel/MainHBox/VBox/FullscreenCheck
@onready var resume_btn: Button = $PausePanel/MainHBox/VBox/ResumeBtn
@onready var restart_btn: Button = $PausePanel/MainHBox/VBox/RestartBtn
@onready var main_menu_btn: Button = $PausePanel/MainHBox/VBox/MainMenuBtn
@onready var quit_btn: Button = $PausePanel/MainHBox/VBox/QuitBtn
@onready var ach_list: VBoxContainer = $PausePanel/MainHBox/AchVBox/AchScroll/AchList

# Barra de Jefe y Eventos de Estructuras del Enjambre
@onready var boss_bar_panel: Panel = $BossBarPanel
@onready var boss_name_label: Label = $BossBarPanel/Margin/VBox/TopRow/BossNameLabel
@onready var boss_distance_label: Label = $BossBarPanel/Margin/VBox/TopRow/BossDistanceLabel
@onready var boss_hp_bar: ProgressBar = $BossBarPanel/Margin/VBox/BossHpBar
var active_event_boss: Node2D = null

# Notificación Toast de Logros Desbloqueados
@onready var achievement_toast: Panel = $AchievementToast
@onready var toast_header: Label = $AchievementToast/VBox/ToastHeader
@onready var toast_detail: Label = $AchievementToast/VBox/ToastDetail
var toast_tween: Tween = null

# Comunicador de Radio Táctico (StarCraft Style)
@onready var transmission_comm: TransmissionComm = $TransmissionComm
var transmission_panel: Control = null
var transmission_portrait: SCPortrait = null
var transmission_header_lbl: Label = null
var transmission_body_lbl: Label = null
var transmission_tween: Tween = null

var player: Player = null
var tech_icons_tex: Texture2D = null
var weapon_icons_tex: Texture2D = null
var last_hp: float = 40.0
var slot_panels: Array[Panel] = []

# Sistema de Tooltip Táctico
var tooltip_panel: PanelContainer = null
var tooltip_title_label: Label = null
var tooltip_badge_label: Label = null
var tooltip_type_label: Label = null
var tooltip_desc_label: Label = null
var tooltip_stats_label: Label = null
var slot_info_cache: Array = []
var current_hovered_slot: int = -1
var is_hovering_base_weapon: bool = false
var _transmission_queue: Array = []
var _transmission_on_finished: Callable = Callable()

const WEAPON_INFO = {
	"c14_rifle": {
		"name": "Rifle Gauss C-14",
		"type": "Arma Balística Principal",
		"desc": "Dispara ráfagas de proyectiles hipersónicos de acero perforante con auto-apuntado."
	},
	"firebat_flame": {
		"name": "Lanzallamas Perdition",
		"type": "Arma Incendiaria de Área",
		"desc": "Incinera hordas de zerg con napalm continuo. Aplica DoT de quemadura y reduce su armadura."
	},
	"spider_mine": {
		"name": "Minas Araña Vulture",
		"type": "Arma Táctica Desplegable",
		"desc": "Siembra periódicamente minas robóticas inteligentes que se entierran y detonan ante el enjambre."
	},
	"ghost_sniper": {
		"name": "Rifle Francotirador Ghost C-10",
		"type": "Arma Balística de Alta Precisión",
		"desc": "Dispara proyectiles perforantes de 25mm que atraviesan filas de enemigos zerg a largo alcance."
	},
	"mutalisk_glave": {
		"name": "Glave Wurm Mutalisco",
		"type": "Bio-Arma Zerg Parásita",
		"desc": "Lanza un gusano voraz que rebota entre múltiples objetivos Zerg, causando daño masivo en cadena."
	},
	"psionic_storm": {
		"name": "Tormenta Psiónica",
		"type": "Poder Psiónico Ancestral",
		"desc": "Genera descargas devastadoras de energía psiónica errática en tu campo visual."
	},
	"lemon_juice": {
		"name": "Zumo de Limón",
		"type": "Easter Egg // Limo Corrosivo",
		"desc": "Estallido de ácido cítrico concentrado que cubre al enemigo en limo corrosivo, causando DoT severo y ralentización."
	}
}

const PASSIVE_INFO = {
	"u238_shells": {
		"name": "Munición U-238",
		"type": "Mejora Balística Terran",
		"desc": "Proyectiles de uranio empobrecido de alta densidad que perforan caparazones Zerg."
	},
	"combat_shield": {
		"name": "Combat Shield",
		"type": "Blindaje Reforzado",
		"desc": "Escudo de aleación de neodimio que incrementa la vitalidad y resistencia del soldado."
	},
	"cadence": {
		"name": "Cadencia Gauss",
		"type": "Acelerador Electromagnético",
		"desc": "Sobrecarga los condensadores de disparo para acelerar el ritmo de ataque de todo el arsenal."
	},
	"multishot": {
		"name": "Disparo Múltiple",
		"type": "Modificación de Cañón",
		"desc": "Añade tubos de dispersión paralelos que disparan proyectiles extras por ráfaga en el Rifle C-14."
	},
	"stimpack_upgrade": {
		"name": "Infusión de Stimpack",
		"type": "Mejora Química Militar",
		"desc": "Potenciador celular que eleva la velocidad del marine y prolonga el efecto del estimulante."
	},
	"extreme_heat_upgrade": {
		"name": "Calor Extremo",
		"type": "Sobrecarga de Blindaje Térmico",
		"desc": "Intensifica el aura ígnea: +2 Armadura durante la habilidad, +0.5% robo de vida y +6 DPS al fuego envolvente."
	},
	"explosive_rounds": {
		"name": "Balas Explosivas",
		"type": "Munición de Fragmentación",
		"desc": "Añade una ojiva de microfragmentación a los proyectiles que estalla al impactar al enjambre."
	},
	"magnetic_field": {
		"name": "Campo Magnético",
		"type": "Atracción Gravitacional",
		"desc": "Generador de flujo magnético que atrae fragmentos de minerales desde grandes distancias."
	},
	"medikit": {
		"name": "Regeneración Médica",
		"type": "Biotecnología Médica",
		"desc": "Nanobots regeneradores que reparan activamente heridas y hemorragias durante la batalla."
	}
}

func _format_weapon_stats(w_id: String, lvl: int, p: Player) -> String:
	match w_id:
		"c14_rifle":
			var bullets = p.multishot if p else 1
			var dmg = (p.damage * p.damage_mult) if p else 14.0
			var fr = (p.fire_rate * p.fire_rate_mult) if p else 2.4
			var pct_dmg = int((p.damage_mult - 1.0) * 100) if p else 0
			var pct_cad = int((p.fire_rate_mult - 1.0) * 100) if p else 0
			
			var lines: Array[String] = []
			lines.append("• Daño: %.1f (+%d%% daño)" % [dmg, pct_dmg])
			lines.append("• Ráfaga: %d %s" % [bullets, "proyectil" if bullets == 1 else "proyectiles"])
			lines.append("• Cadencia: %.1f tiros/s (+%d%% cadencia)" % [fr, pct_cad])
			if p and p.has_explosive:
				lines.append("• Munición: Microfragmentación Explosiva [Área]")
			if p and p.stimpack_active:
				lines.append("• Estado: Estimulante Activo (+50% velocidad)")
			if p and not p.passives.is_empty():
				var mods: Array[String] = []
				for p_key in p.passives.keys():
					var stacks = p.passives[p_key]
					var p_def = PASSIVE_INFO.get(p_key, {})
					var p_name = p_def.get("name", p_key)
					mods.append("%s (x%d)" % [p_name, stacks])
				if not mods.is_empty():
					lines.append("• Mejoras instaladas: " + ", ".join(mods))
			return "\n".join(lines)
		"firebat_flame":
			var pow_lvl = p.firebat_power_lvl if p else lvl
			var streams = p.firebat_streams if p else 1
			var init_dmg = 4.0 * (p.damage_mult if p else 1.0)
			var dot_dmg = (2.0 + (pow_lvl - 1) * 0.5) * (p.damage_mult if p else 1.0)
			var shred = lvl
			return "• Reducción de Armadura: -%d\n• Daño directo: %.1f\n• DoT Quemadura: %.1f / 0.35s\n• Llamaradas: %d en abanico" % [shred, init_dmg, dot_dmg, streams]
		"spider_mine":
			var dmg = (75.0 + (lvl - 1) * 25.0) * (p.damage_mult if p else 1.0)
			return "• Nivel de arma: %d\n• Minas por ciclo: %d\n• Daño de detonación: %.1f\n• Despliegue cada 4.0s" % [lvl, lvl, dmg]
		"ghost_sniper":
			var dmg = (65.0 + (lvl - 1) * 25.0) * (p.damage_mult if p else 1.0)
			var pierce = 4 + lvl
			return "• Nivel de arma: %d\n• Daño penetrante: %.1f\n• Perforación: %d enemigos\n• Largo alcance balístico" % [lvl, dmg, pierce]
		"mutalisk_glave":
			var bounces = 3 + (lvl - 1) * 2
			var dmg = (16.0 + (lvl - 1) * 6.0) * (p.damage_mult if p else 1.0)
			var spd = 340.0 + (lvl - 1) * 35.0
			var mult = p.multishot if p else 1
			return "• Nivel de arma: %d\n• Daño base: %.1f\n• Rebotes en cadena: %d\n• Vel. proyectil: %.0f px/s\n• Proyectiles: %d simultáneos" % [lvl, dmg, bounces, spd, mult]
		"psionic_storm":
			var dmg = (38.0 + (lvl - 1) * 14.0) * (p.damage_mult if p else 1.0)
			var storm_cnt = 2 if lvl >= 4 else 1
			return "• Nivel de habilidad: %d\n• Daño por pulso: %.1f\n• Frecuencia: Pulsos cada 0.28s\n• Tormentas: %d simultáneas" % [lvl, dmg, storm_cnt]
		"lemon_juice":
			var dot_dmg = (8.0 + (lvl - 1) * 3.0) * (p.damage_mult if p else 1.0)
			var slow_pct = 10 + (lvl - 1) * 5
			return "• Nivel secreto: %d\n• DoT Ácido cítrico: %.1f / 0.35s\n• Ralentización Zerg: %d%%\n• Estallido de limo corrosivo" % [lvl, dot_dmg, slow_pct]
	return ""

func _format_passive_stats(p_id: String, stacks: int, _p: Player) -> String:
	match p_id:
		"u238_shells":
			return "• Acumulaciones: x%d\n• +%.0f%% Daño a TODAS las armas\n• +%.0f%% Rango de disparo" % [stacks, stacks * 15.0, stacks * 10.0]
		"combat_shield":
			return "• Acumulaciones: x%d\n• +%.0f%% Vida Máxima total\n• Restaura 25%% de salud total al instalar" % [stacks, stacks * 25.0]
		"cadence":
			return "• Acumulaciones: x%d\n• +%.0f%% Velocidad de ataque general" % [stacks, stacks * 20.0]
		"multishot":
			return "• Acumulaciones: x%d\n• +%d Balas adicionales por disparo" % [stacks, stacks]
		"stimpack_upgrade":
			return "• Acumulaciones: x%d\n• +%.0f%% Velocidad de movimiento\n• +%.1fs Duración del Stimpack [T]" % [stacks, stacks * 12.0, stacks * 1.0]
		"extreme_heat_upgrade":
			return "• Acumulaciones: x%d\n• +%d Armadura en Calor Extremo [T]\n• +%.1f%% Robo de vida con aura\n• +%.0f DPS al calor envolvente" % [stacks, stacks * 2, 1.5 + (stacks - 1) * 0.5, stacks * 6.0]
		"explosive_rounds":
			return "• Acumulaciones: x%d\n• Balas causan daño de área\n• +%.0f%% Daño explosivo" % [stacks, stacks * 10.0]
		"magnetic_field":
			return "• Acumulaciones: x%d\n• +%.0f%% Radio de atracción de minerales" % [stacks, stacks * 30.0]
		"medikit":
			return "• Acumulaciones: x%d\n• +%.0f%% Regeneración de vida/s\n• Restaura 20%% de vida total al instalar" % [stacks, stacks * 3.0]
	return ""

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	add_to_group("hud")
	
	_refresh_hud_skin()
	var sm = get_node_or_null("/root/SkinManager")
	if sm:
		sm.skin_changed.connect(func(_new_skin): _refresh_hud_skin())
	
	tech_icons_tex = load("res://assets/skins/sd/sprites/tech_icons_clean.png")
	weapon_icons_tex = load("res://assets/skins/sd/sprites/weapon_icons.png")
	
	if base_weapon_icon and weapon_icons_tex:
		var atlas = AtlasTexture.new()
		atlas.atlas = weapon_icons_tex
		var slot_idx = 1 if (has_node("/root/GameManager") and GameManager.selected_hero == "firebat") else 0
		atlas.region = Rect2(slot_idx * 48, 0, 48, 48)
		base_weapon_icon.texture = atlas
	
	level_up_panel.visible = false
	game_over_panel.visible = false
	pause_panel.visible = false
	if transmission_comm:
		transmission_comm.visible = false
	
	_setup_tooltip_ui()
	_setup_inventory_slots()
	_restyle_top_bar()
	
	# Conexiones GameManager
	GameManager.xp_changed.connect(_on_xp_changed)
	GameManager.level_up.connect(_on_level_up)
	GameManager.chest_reward.connect(_on_chest_reward)
	GameManager.kills_changed.connect(_on_kills_changed)
	GameManager.time_changed.connect(_on_time_changed)
	GameManager.game_over_triggered.connect(_on_game_over)
	GameManager.mission_updated.connect(func(_m): _update_mission_display())
	GameManager.mission_completed.connect(func(_m): _update_mission_display())
	GameManager.gas_changed.connect(func(_g): _update_resources_display())
	GameManager.base_resources_changed.connect(func(_m, _g): _update_resources_display())
	if has_node("/root/SaveManager"):
		SaveManager.achievement_unlocked.connect(_on_achievement_unlocked)
	
	retry_button.pressed.connect(_on_retry_pressed)
	if return_base_button:
		return_base_button.pressed.connect(func():
			AudioManager.play_sfx("button")
			GameManager.evacuate_to_base()
		)
	
	_update_mission_display()
	_update_resources_display()
	
	if base_weapon_slot:
		base_weapon_slot.mouse_filter = Control.MOUSE_FILTER_STOP
		base_weapon_slot.mouse_entered.connect(_on_base_weapon_mouse_entered)
		base_weapon_slot.mouse_exited.connect(_on_base_weapon_mouse_exited)
		base_weapon_slot.gui_input.connect(_on_base_weapon_gui_input)
	
	_setup_pause_menu()
	get_tree().paused = false
	call_deferred("_setup_player")
	
	if portrait_control:
		portrait_control.trigger_talk(2.0)

# Muestra el panel desplegable de transmisión de radio estilo StarCraft (a la derecha)
func show_transmission(speaker: String, portrait_tex: Texture2D, message: String, duration: float = 4.5, on_finish: Callable = Callable(), voice_id: String = "") -> void:
	if transmission_comm:
		transmission_comm.show_transmission(speaker, portrait_tex, message, duration, on_finish, voice_id)
		return
	if on_finish.is_valid():
		on_finish.call()

func _skip_current_transmission() -> void:
	if transmission_comm:
		transmission_comm.skip_transmission()

# Reproduce una secuencia secuencial de transmisiones de radio
func play_transmission_sequence(lines: Array, on_finished: Callable = Callable()) -> void:
	if transmission_comm:
		transmission_comm.play_sequence(lines, on_finished)
		return
	if on_finished.is_valid():
		on_finished.call()

func _play_next_transmission() -> void:
	pass

func _check_pending_death_cinematic() -> void:
	pass

func _update_mission_display() -> void:
	if not mission_tracker_label:
		return
	var m = GameManager.get_current_mission()
	if GameManager.is_mission_completed:
		mission_tracker_label.text = "🎯 ¡MISIÓN COMPLETADA! [Evacúa en la nave]"
		mission_tracker_label.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
	else:
		mission_tracker_label.text = "🎯 %s [%s]" % [m.get("title", ""), GameManager.get_mission_progress_str()]
		mission_tracker_label.add_theme_color_override("font_color", Color(1.0, 0.85, 0.3, 1.0))

func _update_resources_display() -> void:
	if gas_label:
		gas_label.text = str(SaveManager.total_gas) if has_node("/root/SaveManager") else str(GameManager.mission_gas)
	if minerals_label:
		minerals_label.text = str(GameManager.session_minerals)

func _restyle_top_bar() -> void:
	if xp_bar:
		xp_bar.visible = true
	if level_label:
		level_label.visible = false
		level_label.text = ""
	if minerals_label:
		minerals_label.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 1.0))
	if gas_label:
		gas_label.add_theme_color_override("font_color", Color(0.3, 1.0, 0.4, 1.0))
	if time_label:
		time_label.add_theme_font_size_override("font_size", 12)
		time_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1.0))

func _setup_tooltip_ui() -> void:
	if tooltip_panel:
		return
	
	tooltip_panel = PanelContainer.new()
	tooltip_panel.name = "InventoryTooltip"
	tooltip_panel.process_mode = Node.PROCESS_MODE_ALWAYS
	tooltip_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_panel.z_index = 100
	tooltip_panel.visible = false
	tooltip_panel.custom_minimum_size = Vector2(175, 0)
	
	var sb = StyleBoxFlat.new()
	sb.bg_color = Color(0.03, 0.06, 0.12, 0.95)
	sb.border_color = Color(0.2, 0.55, 0.9, 1.0)
	sb.set_border_width_all(1)
	sb.set_corner_radius_all(3)
	sb.content_margin_left = 8
	sb.content_margin_top = 6
	sb.content_margin_right = 8
	sb.content_margin_bottom = 6
	tooltip_panel.add_theme_stylebox_override("panel", sb)
	
	var vbox = VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.set("theme_override_constants/separation", 2)
	tooltip_panel.add_child(vbox)
	
	var top_row = HBoxContainer.new()
	top_row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vbox.add_child(top_row)
	
	tooltip_title_label = Label.new()
	tooltip_title_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_title_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	tooltip_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
	tooltip_title_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	tooltip_title_label.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_title_label.add_theme_constant_override("shadow_offset_y", 1)
	tooltip_title_label.add_theme_font_size_override("font_size", 10)
	top_row.add_child(tooltip_title_label)
	
	tooltip_badge_label = Label.new()
	tooltip_badge_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_badge_label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0, 1.0))
	tooltip_badge_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	tooltip_badge_label.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_badge_label.add_theme_constant_override("shadow_offset_y", 1)
	tooltip_badge_label.add_theme_font_size_override("font_size", 9)
	top_row.add_child(tooltip_badge_label)
	
	tooltip_type_label = Label.new()
	tooltip_type_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_type_label.add_theme_color_override("font_color", Color(0.5, 0.75, 0.95, 0.85))
	tooltip_type_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(tooltip_type_label)
	
	var sep = HSeparator.new()
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var sep_sb = StyleBoxLine.new()
	sep_sb.color = Color(0.2, 0.45, 0.7, 0.6)
	sep.add_theme_stylebox_override("separator", sep_sb)
	vbox.add_child(sep)
	
	tooltip_desc_label = Label.new()
	tooltip_desc_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_desc_label.add_theme_color_override("font_color", Color(0.85, 0.9, 0.95, 1.0))
	tooltip_desc_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(tooltip_desc_label)
	
	tooltip_stats_label = Label.new()
	tooltip_stats_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip_stats_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	tooltip_stats_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5, 1.0))
	tooltip_stats_label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
	tooltip_stats_label.add_theme_constant_override("shadow_offset_x", 1)
	tooltip_stats_label.add_theme_constant_override("shadow_offset_y", 1)
	tooltip_stats_label.add_theme_font_size_override("font_size", 8)
	vbox.add_child(tooltip_stats_label)
	
	add_child(tooltip_panel)

func _setup_inventory_slots() -> void:
	for child in command_grid.get_children():
		child.queue_free()
	slot_panels.clear()
	slot_info_cache.clear()
	slot_info_cache.resize(9)
	
	for i in range(9):
		var p = Panel.new()
		p.custom_minimum_size = Vector2(37, 34)
		p.mouse_filter = Control.MOUSE_FILTER_PASS
		p.process_mode = Node.PROCESS_MODE_ALWAYS
		
		var sb = StyleBoxFlat.new()
		sb.bg_color = Color(0.04, 0.07, 0.12, 0.8)
		sb.border_color = Color(0.2, 0.38, 0.6, 0.75)
		sb.set_border_width_all(1)
		sb.set_corner_radius_all(1)
		p.add_theme_stylebox_override("panel", sb)
		
		# Icono centrado ocupando todo el interior del botón
		var icon_rect = TextureRect.new()
		icon_rect.name = "IconRect"
		icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon_rect.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
		icon_rect.layout_mode = 1
		icon_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon_rect.offset_left = 2
		icon_rect.offset_top = 2
		icon_rect.offset_right = -2
		icon_rect.offset_bottom = -2
		icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		p.add_child(icon_rect)
		
		# Badge de nivel en la esquina inferior derecha
		var badge = Label.new()
		badge.name = "BadgeLabel"
		badge.mouse_filter = Control.MOUSE_FILTER_IGNORE
		badge.layout_mode = 1
		badge.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
		badge.offset_left = -22
		badge.offset_top = -14
		badge.offset_right = -2
		badge.offset_bottom = -1
		badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		badge.vertical_alignment = VERTICAL_ALIGNMENT_BOTTOM
		badge.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
		badge.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 1))
		badge.add_theme_constant_override("shadow_offset_x", 1)
		badge.add_theme_constant_override("shadow_offset_y", 1)
		badge.add_theme_font_size_override("font_size", 9)
		p.add_child(badge)
		
		var slot_idx = i
		p.mouse_entered.connect(func(): _on_slot_mouse_entered(slot_idx))
		p.mouse_exited.connect(func(): _on_slot_mouse_exited(slot_idx))
		p.gui_input.connect(func(ev): _on_slot_gui_input(slot_idx, ev))
		
		command_grid.add_child(p)
		slot_panels.append(p)

func _on_slot_mouse_entered(slot_idx: int) -> void:
	is_hovering_base_weapon = false
	current_hovered_slot = slot_idx
	var p = slot_panels[slot_idx]
	var sb = p.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = Color(0.4, 0.9, 1.0, 1.0)
		sb.bg_color = Color(0.08, 0.15, 0.25, 0.95)
	AudioManager.play_sfx("button")
	_show_tooltip_for_slot(slot_idx)

func _on_slot_mouse_exited(slot_idx: int) -> void:
	var p = slot_panels[slot_idx]
	var sb = p.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = Color(0.2, 0.38, 0.6, 0.75)
		sb.bg_color = Color(0.04, 0.07, 0.12, 0.8)
	if current_hovered_slot == slot_idx:
		current_hovered_slot = -1
		if tooltip_panel:
			tooltip_panel.visible = false

func _on_slot_gui_input(slot_idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		AudioManager.play_sfx("button")
		current_hovered_slot = slot_idx
		_show_tooltip_for_slot(slot_idx)

func _show_tooltip_for_node(node: Control, info: Dictionary) -> void:
	if not tooltip_panel or node == null or info == null:
		return
	tooltip_title_label.text = info.get("title", "")
	tooltip_badge_label.text = info.get("badge", "")
	tooltip_type_label.text = info.get("type", "")
	tooltip_desc_label.text = info.get("desc", "")
	tooltip_stats_label.text = info.get("stats", "")
	
	if info.get("is_empty", false):
		tooltip_title_label.add_theme_color_override("font_color", Color(0.65, 0.7, 0.75, 1.0))
		tooltip_badge_label.add_theme_color_override("font_color", Color(0.5, 0.55, 0.6, 1.0))
		tooltip_stats_label.add_theme_color_override("font_color", Color(0.6, 0.7, 0.8, 0.85))
	else:
		tooltip_title_label.add_theme_color_override("font_color", Color(1.0, 0.88, 0.25, 1.0))
		tooltip_badge_label.add_theme_color_override("font_color", Color(0.35, 0.9, 1.0, 1.0))
		tooltip_stats_label.add_theme_color_override("font_color", Color(0.35, 1.0, 0.5, 1.0))
	
	tooltip_panel.visible = true
	tooltip_panel.reset_size()
	
	var n_rect = node.get_global_rect()
	var tip_size = tooltip_panel.get_combined_minimum_size()
	tooltip_panel.size = tip_size
	
	var target_x = n_rect.position.x + n_rect.size.x * 0.5 - tip_size.x * 0.5
	if node == base_weapon_slot:
		target_x -= 50.0 # Mover el tooltip del arma principal más a la izquierda
	target_x = clamp(target_x, 8.0, 632.0 - tip_size.x)
	var target_y = n_rect.position.y - tip_size.y - 6.0
	if target_y < 28.0:
		target_y = n_rect.position.y + n_rect.size.y + 6.0
	target_y = clamp(target_y, 30.0, 474.0 - tip_size.y)
	tooltip_panel.global_position = Vector2(target_x, target_y)

func _show_tooltip_for_slot(slot_idx: int) -> void:
	if slot_idx < 0 or slot_idx >= slot_info_cache.size() or tooltip_panel == null:
		return
	var info = slot_info_cache[slot_idx]
	if info != null and (info is Dictionary):
		_show_tooltip_for_node(slot_panels[slot_idx], info)

func _on_base_weapon_mouse_entered() -> void:
	if not base_weapon_slot or not base_weapon_slot.visible:
		return
	is_hovering_base_weapon = true
	current_hovered_slot = -1
	var sb = base_weapon_slot.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = Color(0.4, 0.9, 1.0, 1.0)
		sb.bg_color = Color(0.08, 0.15, 0.25, 0.95)
	AudioManager.play_sfx("button")
	_show_tooltip_for_base_weapon()

func _on_base_weapon_mouse_exited() -> void:
	is_hovering_base_weapon = false
	if not base_weapon_slot:
		return
	var sb = base_weapon_slot.get_theme_stylebox("panel") as StyleBoxFlat
	if sb:
		sb.border_color = Color(0.2, 0.38, 0.6, 0.75)
		sb.bg_color = Color(0.04, 0.07, 0.12, 0.85)
	if tooltip_panel:
		tooltip_panel.visible = false

func _on_base_weapon_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseMotion or (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed):
		is_hovering_base_weapon = true
		current_hovered_slot = -1
		_show_tooltip_for_base_weapon()

func _show_tooltip_for_base_weapon() -> void:
	if not tooltip_panel:
		return
	var is_firebat = (has_node("/root/GameManager") and GameManager.selected_hero == "firebat")
	var base_w_id = "firebat_flame" if is_firebat else "c14_rifle"
	var lvl = 1
	if player and is_instance_valid(player):
		lvl = player.weapons.get(base_w_id, 1)
	var w_def = WEAPON_INFO.get(base_w_id, {})
	var stats_str = _format_weapon_stats(base_w_id, lvl, player)
	var default_title = "Lanzallamas Perdition" if is_firebat else "Rifle de Asalto C-14 Gauß"
	var default_type = "Arma Principal Firebat" if is_firebat else "Arma Principal Reglamentaria CMC"
	var info = {
		"is_empty": false,
		"title": w_def.get("name", default_title),
		"type": default_type,
		"badge": "[Nivel %d]" % lvl,
		"desc": w_def.get("desc", ""),
		"stats": stats_str
	}
	_show_tooltip_for_node(base_weapon_slot, info)

func _update_inventory_display(weapons: Dictionary, passives: Dictionary) -> void:
	if slot_info_cache.size() < 9:
		slot_info_cache.resize(9)
	
	var is_firebat = (has_node("/root/GameManager") and GameManager.selected_hero == "firebat")
	var base_w_id = "firebat_flame" if is_firebat else "c14_rifle"
	
	# 1. Actualizar Ranura de Arma Base (separada de la cuadrícula)
	if base_weapon_slot:
		if not GameManager.has_suit_equipped:
			base_weapon_slot.visible = false
		else:
			base_weapon_slot.visible = true
			var lvl = weapons.get(base_w_id, 1)
			if base_weapon_icon:
				var atlas = AtlasTexture.new()
				atlas.atlas = weapon_icons_tex
				var base_icon_idx = 1 if is_firebat else 0
				atlas.region = Rect2(base_icon_idx * 48, 0, 48, 48)
				base_weapon_icon.texture = atlas
			if base_weapon_badge:
				base_weapon_badge.text = "L%d" % lvl
	
	# 2. Armas Secundarias en slots 0, 1, 2 de CommandGrid (el arma base del personaje no gasta slot aquí)
	var secondary_weapons: Array[String] = []
	for w_id in weapons.keys():
		if w_id != base_w_id:
			secondary_weapons.append(w_id)
	
	var weapon_icon_map = {
		"c14_rifle": 0,
		"firebat_flame": 1,
		"spider_mine": 2,
		"ghost_sniper": 3,
		"mutalisk_glave": 4,
		"psionic_storm": 5,
		"lemon_juice": 6,
		"aux_weapon": 0
	}
	
	for i in range(3):
		var p = slot_panels[i]
		var icon_rect = p.get_node("IconRect") as TextureRect
		var badge = p.get_node("BadgeLabel") as Label
		
		if i < secondary_weapons.size():
			var w_id = secondary_weapons[i]
			var w_def = WEAPON_INFO.get(w_id, {})
			var lvl = weapons[w_id]
			var atlas = AtlasTexture.new()
			atlas.atlas = weapon_icons_tex
			var idx = weapon_icon_map.get(w_id, 0)
			atlas.region = Rect2(idx * 48, 0, 48, 48)
			icon_rect.texture = atlas
			badge.text = "L%d" % lvl
			p.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			var stats_str = _format_weapon_stats(w_id, lvl, player)
			var weapon_type = w_def.get("type", "Arma Secundaria")
			if w_id == "c14_rifle" and is_firebat:
				weapon_type = "Arma Balística Secundaria"
			slot_info_cache[i] = {
				"is_empty": false,
				"title": w_def.get("name", w_id),
				"type": weapon_type,
				"badge": "[Nivel %d]" % lvl,
				"desc": w_def.get("desc", ""),
				"stats": stats_str
			}
			p.tooltip_text = ""
		else:
			icon_rect.texture = null
			badge.text = ""
			p.modulate = Color(0.4, 0.4, 0.4, 0.4)
			
			slot_info_cache[i] = {
				"is_empty": true,
				"title": "Ranura de Arma Secundaria",
				"type": "Arma secundaria disponible",
				"badge": "[DISPONIBLE]",
				"desc": "Ranura para armamento táctico adicional.",
				"stats": "Requiere subir de nivel o alijo militar."
			}
			p.tooltip_text = ""
	
	# Pasivas en slots 3..8 (6 slots restantes)
	var passive_keys = passives.keys()
	var passive_icon_map = {
		"magnetic_field": 0,
		"stimpack_upgrade": 1,
		"extreme_heat_upgrade": 1,
		"combat_shield": 2,
		"u238_shells": 3,
		"cadence": 4,
		"explosive_rounds": 5,
		"multishot": 6,
		"medikit": 7
	}
	
	for i in range(6):
		var slot_idx = 3 + i
		var p = slot_panels[slot_idx]
		var icon_rect = p.get_node("IconRect") as TextureRect
		var badge = p.get_node("BadgeLabel") as Label
		
		if i < passive_keys.size():
			var p_id = passive_keys[i]
			var stacks = passives[p_id]
			var idx = passive_icon_map.get(p_id, 0)
			var atlas = AtlasTexture.new()
			atlas.atlas = tech_icons_tex
			atlas.region = Rect2(idx * 48, 0, 48, 48)
			icon_rect.texture = atlas
			badge.text = "x%d" % stacks
			p.modulate = Color(1.0, 1.0, 1.0, 1.0)
			
			var p_def = PASSIVE_INFO.get(p_id, {})
			var stats_str = _format_passive_stats(p_id, stacks, player)
			slot_info_cache[slot_idx] = {
				"is_empty": false,
				"title": p_def.get("name", p_id),
				"type": p_def.get("type", "Mejora Pasiva"),
				"badge": "[x%d]" % stacks,
				"desc": p_def.get("desc", ""),
				"stats": stats_str
			}
			p.tooltip_text = ""
		else:
			icon_rect.texture = null
			badge.text = ""
			p.modulate = Color(0.4, 0.4, 0.4, 0.4)
			
			slot_info_cache[slot_idx] = {
				"is_empty": true,
				"title": "Ranura de Mejora Vacía",
				"type": "Espacio táctico libre",
				"badge": "[VACÍO]",
				"desc": "Espacio para mejoras tecnológicas de combate Terran. Soporta hasta 6 mejoras activas con niveles infinitos.",
				"stats": "Disponible en el siguiente ascenso militar."
			}
			p.tooltip_text = ""
	
	if current_hovered_slot != -1 and tooltip_panel and tooltip_panel.visible:
		_show_tooltip_for_slot(current_hovered_slot)

func _setup_pause_menu() -> void:
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
	
	if voice_slider and voice_label:
		voice_slider.value = AudioManager.voice_volume
		voice_label.text = "Volumen Voces: %d%%" % int(AudioManager.voice_volume * 100)
		voice_slider.value_changed.connect(func(val):
			AudioManager.set_voice_volume(val)
			voice_label.text = "Volumen Voces: %d%%" % int(val * 100)
		)
	
	var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.button_pressed = is_fs
	fullscreen_check.toggled.connect(func(pressed):
		AudioManager.play_sfx("button")
		if pressed:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
		else:
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	)
	
	resume_btn.pressed.connect(_on_resume_pressed)
	restart_btn.pressed.connect(_on_restart_pressed)
	main_menu_btn.pressed.connect(_on_main_menu_pressed)
	quit_btn.pressed.connect(_on_quit_pressed)
	
	for btn in [resume_btn, restart_btn, main_menu_btn, quit_btn]:
		btn.mouse_entered.connect(func(): AudioManager.play_sfx("button"))

func _unhandled_input(event: InputEvent) -> void:
	if (transmission_comm and transmission_comm.visible) or (transmission_panel and transmission_panel.visible):
		# Excluir Space para que el jugador pueda usar Stimpack libremente en combate sin cortar transmisiones
		var is_enter_key = (event is InputEventKey and event.pressed and not event.echo and (event.keycode == KEY_ENTER or event.keycode == KEY_KP_ENTER))
		var is_mouse_click = (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed)
		if is_enter_key or is_mouse_click:
			_skip_current_transmission()
			get_viewport().set_input_as_handled()
			return
	if event is InputEventKey and event.pressed:
		if event.keycode == KEY_F11 or (event.alt_pressed and event.keycode == KEY_ENTER):
			var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
			DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED if is_fs else DisplayServer.WINDOW_MODE_FULLSCREEN)
			fullscreen_check.set_pressed_no_signal(!is_fs)
	if event.is_action_pressed("ui_cancel"):
		if game_over_panel.visible:
			return
		toggle_pause()

func toggle_pause() -> void:
	if pause_panel.visible:
		resume_game()
	else:
		pause_game()

func _update_boss_bar() -> void:
	if boss_bar_panel and boss_bar_panel.visible and active_event_boss and is_instance_valid(active_event_boss):
		var player = get_tree().get_first_node_in_group("player")
		if player and is_instance_valid(player):
			var diff = active_event_boss.global_position - player.global_position
			var dist = int(diff.length())
			var arrow = "◄"
			var angle = diff.angle()
			if angle >= -PI * 0.125 and angle < PI * 0.125:
				arrow = "►"
			elif angle >= PI * 0.125 and angle < PI * 0.375:
				arrow = "▼►"
			elif angle >= PI * 0.375 and angle < PI * 0.625:
				arrow = "▼"
			elif angle >= PI * 0.625 and angle < PI * 0.875:
				arrow = "◄▼"
			elif angle >= -PI * 0.375 and angle < -PI * 0.125:
				arrow = "▲►"
			elif angle >= -PI * 0.625 and angle < -PI * 0.375:
				arrow = "▲"
			elif angle >= -PI * 0.875 and angle < -PI * 0.625:
				arrow = "◄▲"
			else:
				arrow = "◄"
			if boss_distance_label:
				boss_distance_label.text = "%s %dm" % [arrow, dist]
	elif boss_bar_panel and boss_bar_panel.visible and (not active_event_boss or not is_instance_valid(active_event_boss)):
		hide_event_boss_bar()

func show_event_boss_bar(title: String, current_hp: float, max_hp: float, structure_node: Node2D) -> void:
	active_event_boss = structure_node
	if boss_bar_panel:
		boss_bar_panel.visible = true
	if boss_name_label:
		boss_name_label.text = title
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = current_hp
	if structure_node and structure_node.has_signal("health_changed"):
		if not structure_node.is_connected("health_changed", Callable(self, "update_event_boss_bar")):
			structure_node.connect("health_changed", Callable(self, "update_event_boss_bar"))

func update_event_boss_bar(current_hp: float, max_hp: float) -> void:
	if boss_hp_bar:
		boss_hp_bar.max_value = max_hp
		boss_hp_bar.value = current_hp

func hide_event_boss_bar() -> void:
	if boss_bar_panel:
		boss_bar_panel.visible = false
	active_event_boss = null

func _on_achievement_unlocked(_ach_id: String, ach_data: Dictionary) -> void:
	if not achievement_toast:
		return
	AudioManager.play_sfx("upgrade")
	var name_str = ach_data.get("name", "Logro Militar")
	var rew_str = ach_data.get("reward", "")
	if toast_detail:
		if rew_str != "":
			toast_detail.text = "%s - %s" % [name_str, rew_str]
		else:
			toast_detail.text = "%s - %s" % [name_str, ach_data.get("desc", "")]
	
	achievement_toast.visible = true
	achievement_toast.modulate.a = 0.0
	
	if toast_tween:
		toast_tween.kill()
	toast_tween = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	toast_tween.tween_property(achievement_toast, "modulate:a", 1.0, 0.3)
	toast_tween.tween_interval(4.0)
	toast_tween.tween_property(achievement_toast, "modulate:a", 0.0, 0.6)
	toast_tween.tween_callback(func(): achievement_toast.visible = false)

func pause_game() -> void:
	AudioManager.play_sfx("button")
	get_tree().paused = true
	music_slider.value = AudioManager.music_volume
	sfx_slider.value = AudioManager.sfx_volume
	if voice_slider:
		voice_slider.value = AudioManager.voice_volume
	if voice_label:
		voice_label.text = "Volumen Voces: %d%%" % int(AudioManager.voice_volume * 100)
	var is_fs = (DisplayServer.window_get_mode() == DisplayServer.WINDOW_MODE_FULLSCREEN)
	fullscreen_check.set_pressed_no_signal(is_fs)
	_populate_pause_achievements()
	pause_panel.visible = true

func _populate_pause_achievements() -> void:
	if not ach_list:
		return
	for child in ach_list.get_children():
		child.queue_free()
	
	if not has_node("/root/SaveManager"):
		return
	
	for a in SaveManager.ACHIEVEMENTS_DEF:
		var a_id = a.get("id", "")
		var is_unlocked = SaveManager.is_achievement_unlocked(a_id)
		
		var card = PanelContainer.new()
		var card_sb = StyleBoxFlat.new()
		card_sb.bg_color = Color(0.02, 0.05, 0.10, 0.85) if not is_unlocked else Color(0.04, 0.12, 0.08, 0.90)
		card_sb.border_color = Color(0.15, 0.35, 0.55, 0.8) if not is_unlocked else Color(0.2, 0.85, 0.4, 0.9)
		card_sb.set_border_width_all(1)
		card_sb.set_corner_radius_all(3)
		card_sb.content_margin_left = 6
		card_sb.content_margin_right = 6
		card_sb.content_margin_top = 4
		card_sb.content_margin_bottom = 4
		card.add_theme_stylebox_override("panel", card_sb)
		
		var vb = VBoxContainer.new()
		vb.set("theme_override_constants/separation", 1)
		card.add_child(vb)
		
		var title_row = HBoxContainer.new()
		vb.add_child(title_row)
		
		var title_lbl = Label.new()
		title_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		title_lbl.add_theme_font_size_override("font_size", 9)
		if is_unlocked:
			title_lbl.text = "★ " + a.get("name", "")
			title_lbl.add_theme_color_override("font_color", Color(0.3, 1.0, 0.5, 1.0))
		else:
			title_lbl.text = "🔒 " + a.get("name", "")
			title_lbl.add_theme_color_override("font_color", Color(0.7, 0.75, 0.8, 1.0))
		title_row.add_child(title_lbl)
		
		var status_badge = Label.new()
		status_badge.add_theme_font_size_override("font_size", 8)
		if is_unlocked:
			status_badge.text = "[DESBLOQUEADO]"
			status_badge.add_theme_color_override("font_color", Color(0.2, 1.0, 0.4, 1.0))
		else:
			status_badge.text = "[PENDIENTE]"
			status_badge.add_theme_color_override("font_color", Color(1.0, 0.6, 0.2, 0.8))
		title_row.add_child(status_badge)
		
		var desc_lbl = Label.new()
		desc_lbl.text = a.get("desc", "")
		desc_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		desc_lbl.add_theme_font_size_override("font_size", 8)
		desc_lbl.add_theme_color_override("font_color", Color(0.75, 0.8, 0.85, 0.9))
		vb.add_child(desc_lbl)
		
		var rew_lbl = Label.new()
		rew_lbl.text = "Recompensa: " + a.get("reward", "")
		rew_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		rew_lbl.add_theme_font_size_override("font_size", 7)
		rew_lbl.add_theme_color_override("font_color", Color(0.3, 0.85, 1.0, 0.95))
		vb.add_child(rew_lbl)
		
		ach_list.add_child(card)

func resume_game() -> void:
	AudioManager.play_sfx("button")
	pause_panel.visible = false
	if not level_up_panel.visible:
		get_tree().paused = false

func _on_resume_pressed() -> void:
	resume_game()

func _on_restart_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()

func _on_main_menu_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().change_scene_to_file("res://scenes/title_screen.tscn")

func _on_quit_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().quit()

func _refresh_hud_skin() -> void:
	if console_texture:
		var ct = SkinManager.get_ui("tconsole")
		if ct: console_texture.texture = ct
	
	if not GameManager.has_suit_equipped:
		if portrait_control:
			portrait_control.set_portrait(null)
		if wireframe_rect:
			var wf_civ = SkinManager.get_sprite("wire_civilian")
			if wf_civ: wireframe_rect.texture = wf_civ
		if unit_name_label:
			unit_name_label.text = "??????"
	else:
		var is_medic = (GameManager.selected_hero == "medic")
		var is_firebat = (GameManager.selected_hero == "firebat")
		if wireframe_rect:
			var wf_name = "wire_firebat" if is_firebat else ("wire_medic" if is_medic else "wire_marine")
			var wf = SkinManager.get_sprite(wf_name)
			if wf: wireframe_rect.texture = wf
		if portrait_control:
			var port_name = "firebat" if is_firebat else ("medic" if is_medic else "marine")
			var p_tex = SkinManager.get_portrait(port_name)
			if p_tex: portrait_control.set_portrait(p_tex)
			if is_firebat:
				portrait_control.voice_list = [
					"firebat_what0", "firebat_what1", "firebat_what2", "firebat_what3",
					"firebat_yes0", "firebat_yes1", "firebat_yes2", "firebat_yes3"
				]
			elif is_medic:
				portrait_control.voice_list = [
					"medic_what0", "medic_what1", "medic_what2", "medic_what3",
					"medic_yes0", "medic_yes1", "medic_yes2", "medic_yes3"
				]
			else:
				portrait_control.voice_list = ["marine_what0", "marine_what1", "marine_yes0", "marine_yes1"]
		if unit_name_label:
			unit_name_label.text = "FIREBAT CMC-660" if is_firebat else ("MÉDICA TERRAN" if is_medic else "INFANTERÍA TERRAN")
	
	var cursor_tex = SkinManager.get_ui("cursor")
	if cursor_tex:
		Input.set_custom_mouse_cursor(cursor_tex, Input.CURSOR_ARROW, Vector2.ZERO)

func _setup_player() -> void:
	player = get_tree().get_first_node_in_group("player") as Player
	if player:
		last_hp = player.current_health
		player.health_changed.connect(_on_player_health_changed)
		player.inventory_changed.connect(_on_inventory_changed)
		_on_player_health_changed(player.current_health, player.max_health)
		_update_inventory_display(player.weapons, player.passives)

func _on_inventory_changed(weapons: Dictionary, passives: Dictionary) -> void:
	_update_inventory_display(weapons, passives)

func _process(_delta: float) -> void:
	_update_boss_bar()
	if radar_control and is_instance_valid(radar_control):
		radar_control.queue_redraw()
	
	if player and is_instance_valid(player):
		if not GameManager.has_suit_equipped:
			unit_name_label.text = "CIVIL TERRAN"
			weapon_label.text = "Sin armas"
			if armor_label:
				armor_label.text = "Armadura: 0"
			if rank_label:
				rank_label.text = "Civil Indefenso"
			stim_status_label.visible = false
		else:
			var pct = int((player.damage_mult - 1.0) * 100)
			var is_firebat = (has_node("/root/GameManager") and GameManager.selected_hero == "firebat")
			if is_firebat:
				weapon_label.text = "Lanza-llamas (+%d%% daño)" % pct
			else:
				weapon_label.text = "Rifle C-14 (+%d%% daño)" % pct
			if armor_label:
				var total_arm = player.armor + (player.extreme_heat_armor_bonus if (is_firebat and player.is_extreme_heat_active) else 0.0)
				armor_label.text = "Armadura: %d" % int(total_arm)
			if rank_label and has_node("/root/SaveManager"):
				var r_info = SaveManager.get_current_rank()
				rank_label.text = "Rango: %s" % r_info["name"]
			
			# Estado de Habilidad [T] (Calor Extremo para Firebat, Stimpack para Marine/Médica)
			if is_firebat:
				stim_status_label.visible = true
				if player.is_extreme_heat_active:
					stim_status_label.text = "CALOR: ACTIVO (%.1fs)" % player.extreme_heat_timer
					stim_status_label.modulate = Color(1.0, 0.45, 0.1, 1.0)
				elif player.extreme_heat_cd_timer > 0.0:
					stim_status_label.text = "CALOR: RECARGA (%.1fs)" % player.extreme_heat_cd_timer
					stim_status_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
				else:
					stim_status_label.text = "CALOR [T]: LISTO"
					stim_status_label.modulate = Color(1.0, 0.6, 0.2, 1.0)
			else:
				var is_stim_unlocked = SaveManager.is_stimpack_unlocked() if has_node("/root/SaveManager") else (GameManager.barracks_upgrades.get("stim", 0) > 0)
				if not is_stim_unlocked:
					stim_status_label.visible = false
				elif player.stimpack_active:
					stim_status_label.visible = true
					stim_status_label.text = "STIM: ACTIVO (%.1fs)" % player.stimpack_timer
					stim_status_label.modulate = Color(1.0, 0.3, 0.3, 1.0)
				elif player.stimpack_cd_timer > 0.0:
					stim_status_label.visible = true
					stim_status_label.text = "STIM: RECARGA (%.1fs)" % player.stimpack_cd_timer
					stim_status_label.modulate = Color(0.7, 0.7, 0.7, 1.0)
				else:
					stim_status_label.visible = true
					stim_status_label.text = "STIM [T]: LISTO"
					stim_status_label.modulate = Color(0.25, 1.0, 0.35, 1.0)
	
	if is_hovering_base_weapon and tooltip_panel and tooltip_panel.visible:
		_show_tooltip_for_base_weapon()
	elif current_hovered_slot != -1 and tooltip_panel and tooltip_panel.visible:
		_show_tooltip_for_slot(current_hovered_slot)

func _on_player_health_changed(current_hp: float, max_hp: float) -> void:
	if current_hp < last_hp and portrait_control:
		portrait_control.trigger_talk(1.0)
	last_hp = current_hp
	
	if sc_hp_bar:
		sc_hp_bar.set_health(current_hp, max_hp)
	if hp_label:
		hp_label.text = "%d / %d" % [int(current_hp), int(max_hp)]
		if current_hp <= max_hp * 0.33:
			hp_label.modulate = Color(1.0, 0.25, 0.25, 1.0)
		elif current_hp <= max_hp * 0.66:
			hp_label.modulate = Color(1.0, 0.9, 0.2, 1.0)
		else:
			hp_label.modulate = Color(0.25, 1.0, 0.35, 1.0)

func _on_xp_changed(current_xp: int, max_xp: int, _level: int) -> void:
	if xp_bar:
		xp_bar.visible = true
		xp_bar.max_value = max_xp
		xp_bar.value = current_xp
	if level_label:
		level_label.visible = false
		level_label.text = ""
	_update_resources_display()

func _on_kills_changed(kills: int) -> void:
	if kills_label:
		kills_label.text = "%d" % kills
	if kills_unit_label:
		kills_unit_label.text = "Kills: %d" % kills
	if rank_label and has_node("/root/SaveManager"):
		var r_info = SaveManager.get_current_rank()
		rank_label.text = "Rango: %s" % r_info["name"]

func _on_time_changed(seconds: float) -> void:
	if time_label:
		var mins = int(seconds) / 60
		var secs = int(seconds) % 60
		time_label.text = "%02d:%02d" % [mins, secs]

func _on_level_up(level: int, choices: Array) -> void:
	if portrait_control:
		portrait_control.trigger_talk(3.0)
	level_up_panel.visible = true
	level_up_title.text = "// TRANSMISIÓN MILITAR: MEJORAS TÁCTICAS (NIVEL %d) //" % level
	_render_cards(choices)

func _on_chest_reward(choices: Array) -> void:
	if portrait_control:
		portrait_control.trigger_talk(3.5)
	level_up_panel.visible = true
	level_up_title.text = "★ RECOMPENSA DE JEFE: COFRE MILITAR DEL ENJAMBRE ★"
	_render_cards(choices)

func _render_cards(choices: Array) -> void:
	for child in cards_container.get_children():
		child.queue_free()
	
	for choice in choices:
		var card = _create_upgrade_card(choice)
		cards_container.add_child(card)

func _create_upgrade_card(choice: Dictionary) -> Control:
	var panel = PanelContainer.new()
	panel.custom_minimum_size = Vector2(175, 225)
	panel.size_flags_vertical = Control.SIZE_EXPAND_FILL
	panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = Color(0.06, 0.10, 0.17, 0.95)
	style_box.border_color = Color(0.2, 0.5, 0.85, 1.0)
	style_box.set_border_width_all(2)
	style_box.set_corner_radius_all(3)
	panel.add_theme_stylebox_override("panel", style_box)
	
	var vbox = VBoxContainer.new()
	vbox.set("theme_override_constants/separation", 6)
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	panel.add_child(vbox)
	
	# Icono oficial de StarCraft 48x48
	var icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(48, 48)
	icon_rect.expand_mode = TextureRect.EXPAND_KEEP_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_CENTERED
	
	var atlas = AtlasTexture.new()
	if choice.get("type", "passive") == "weapon":
		atlas.atlas = weapon_icons_tex
		var w_idx = choice.get("weapon_idx", 0)
		atlas.region = Rect2(w_idx * 48, 0, 48, 48)
	else:
		atlas.atlas = tech_icons_tex
		var p_idx = choice.get("icon_idx", 0)
		atlas.region = Rect2(p_idx * 48, 0, 48, 48)
	icon_rect.texture = atlas
	vbox.add_child(icon_rect)
	
	# Titulo mejora (altura uniforme para 1 o 2 líneas)
	var title = Label.new()
	title.text = choice["name"]
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	title.custom_minimum_size = Vector2(0, 32)
	title.add_theme_color_override("font_color", Color(1.0, 0.85, 0.25, 1.0))
	title.add_theme_font_size_override("font_size", 11)
	vbox.add_child(title)
	
	# Descripcion
	var desc = Label.new()
	desc.text = choice["desc"]
	desc.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	desc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	desc.add_theme_color_override("font_color", Color(0.4, 0.95, 0.5, 1.0))
	desc.add_theme_font_size_override("font_size", 10)
	vbox.add_child(desc)
	
	# Boton seleccionar anclado uniformemente al fondo
	var btn = Button.new()
	btn.text = "INSTALAR"
	btn.custom_minimum_size = Vector2(0, 26)
	btn.size_flags_vertical = Control.SIZE_SHRINK_END
	btn.pressed.connect(func():
		AudioManager.play_sfx("upgrade")
		level_up_panel.visible = false
		GameManager.select_upgrade(choice["id"])
	)
	btn.mouse_entered.connect(func():
		AudioManager.play_sfx("button")
		style_box.border_color = Color(0.4, 0.9, 1.0, 1.0)
		style_box.bg_color = Color(0.12, 0.20, 0.32, 0.98)
	)
	btn.mouse_exited.connect(func():
		style_box.border_color = Color(0.2, 0.5, 0.85, 1.0)
		style_box.bg_color = Color(0.06, 0.10, 0.17, 0.95)
	)
	vbox.add_child(btn)
	
	return panel

func _on_game_over(time_survived: float, kills: int, level: int) -> void:
	if not GameManager.has_suit_equipped:
		game_over_panel.visible = true
		var failed_lbl = game_over_panel.get_node_or_null("VBoxContainer/FailedLabel") as Label
		if failed_lbl:
			failed_lbl.text = "// MISIÓN FALLIDA //"
		game_over_stats.text = "VOSS: «¡Estúpido! ¡Tenías que ponerte la armadura!»\n\nRescatando civil del campo de batalla y regresando a la base..."
		retry_button.visible = false
		if return_base_button:
			return_base_button.visible = false
		
		# Auto-retorno a la base militar con fadeout y fadein
		var tw = create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
		tw.tween_interval(2.2)
		tw.tween_callback(func():
			ScreenFade.fade_out_in(0.5, 0.2, 0.5, func():
				get_tree().paused = false
				GameManager.evacuate_to_base()
			)
		)
		return

	_show_game_over_panel(time_survived, kills, level)

func _show_game_over_panel(time_survived: float, kills: int, level: int) -> void:
	var secured_min = GameManager.session_minerals
	
	AudioManager.play_sfx("youlose")
	AudioManager.play_music("tdefeat", false)
	
	game_over_panel.visible = true
	var failed_lbl = game_over_panel.get_node_or_null("VBoxContainer/FailedLabel") as Label
	if failed_lbl:
		failed_lbl.text = "// ALERTA: EVACUACIÓN TÁCTICA //"
	retry_button.visible = true
	if return_base_button:
		return_base_button.visible = true
	var mins = int(time_survived) / 60
	var secs = int(time_survived) % 60
	if secured_min > 0:
		game_over_stats.text = "> TIEMPO DE RESISTENCIA: %02d:%02d\n> ENJAMBRE EXTERMINADO: %d ZERGS\n> RANGO ALCANZADO: NIVEL %d\n> CRISTALES ASEGURADOS PARA LA BASE: +%d" % [mins, secs, kills, level, secured_min]
	else:
		game_over_stats.text = "> TIEMPO DE RESISTENCIA: %02d:%02d\n> ENJAMBRE EXTERMINADO: %d ZERGS\n> RANGO ALCANZADO: NIVEL %d" % [mins, secs, kills, level]

func _on_retry_pressed() -> void:
	AudioManager.play_sfx("button")
	get_tree().paused = false
	GameManager.reset_game()
	get_tree().reload_current_scene()
