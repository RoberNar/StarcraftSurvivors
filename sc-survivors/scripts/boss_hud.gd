class_name BossHUD
extends CanvasLayer

@onready var container: PanelContainer = $CenterContainer/BossPanel
@onready var boss_name_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/Header/BossName
@onready var status_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/Header/BossStatus

# Barras de Salud (6 en total)
@onready var bars_count_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/HealthBarsRow/BarsCountLabel
@onready var bars_icons_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/HealthBarsRow/BarsIconsLabel
@onready var health_bar: ProgressBar = $CenterContainer/BossPanel/Margin/HBox/VBox/HealthBar
@onready var hp_numeric_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/HealthBar/HPLabel

# Barra de Sobrecalentamiento de Armadura
@onready var armor_bar: ProgressBar = $CenterContainer/BossPanel/Margin/HBox/VBox/ArmorRow/ArmorBar
@onready var armor_numeric_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/ArmorRow/ArmorBar/ArmorLabel

# Estado de Cueva y Pilares
@onready var cave_balance_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/FooterRow/CaveBalanceLabel
@onready var pillars_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/FooterRow/PillarsLabel

@onready var portrait_texture: TextureRect = $CenterContainer/BossPanel/Margin/HBox/PortraitFrame/Portrait

var boss_ref: TorrasqueBoss = null

func _ready() -> void:
	if portrait_texture:
		var port_tex = load("res://assets/skins/sd/portrait/ultralisk_portrait.png")
		if port_tex:
			portrait_texture.texture = port_tex

func setup_boss(boss: TorrasqueBoss) -> void:
	boss_ref = boss
	if not boss_ref:
		return
	
	boss_ref.health_changed.connect(_on_boss_health_changed)
	boss_ref.armor_heat_changed.connect(_on_armor_heat_changed)
	boss_ref.state_changed.connect(_on_boss_state_changed)
	boss_ref.died.connect(_on_boss_died)
	
	health_bar.max_value = TorrasqueBoss.BAR_MAX_HEALTH
	health_bar.value = boss_ref.current_bar_health
	_update_bars_display(boss_ref.health_bars_remaining, TorrasqueBoss.TOTAL_HEALTH_BARS)
	_update_hp_text(boss_ref.current_bar_health, TorrasqueBoss.BAR_MAX_HEALTH)
	
	armor_bar.max_value = TorrasqueBoss.MAX_ARMOR_HEAT
	armor_bar.value = boss_ref.armor_heat
	_update_armor_text(boss_ref.armor_heat, TorrasqueBoss.MAX_ARMOR_HEAT)
	
	container.position.y = -90.0
	var tw = create_tween()
	tw.tween_property(container, "position:y", 10.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_cave_balance(is_balanced: bool, target_pillar_name: String = "") -> void:
	if not cave_balance_label:
		return
	if is_balanced:
		cave_balance_label.text = "EQUILIBRIO: ESTABLE"
		cave_balance_label.modulate = Color(0.3, 1.0, 0.4, 1.0)
	else:
		cave_balance_label.text = "¡DESBALANCE SÍSMICO! OBJETIVO: %s" % target_pillar_name
		cave_balance_label.modulate = Color(1.0, 0.2, 0.2, 1.0)

func update_pillars_count(standing: int, total: int = 6) -> void:
	if pillars_label:
		pillars_label.text = "PILARES: %d / %d" % [standing, total]

func _on_boss_health_changed(cur_bar_hp: float, max_bar_hp: float, bars_left: int) -> void:
	health_bar.max_value = max_bar_hp
	health_bar.value = cur_bar_hp
	_update_hp_text(cur_bar_hp, max_bar_hp)
	_update_bars_display(bars_left, TorrasqueBoss.TOTAL_HEALTH_BARS)

func _update_bars_display(bars_left: int, total: int) -> void:
	if bars_count_label:
		bars_count_label.text = "BARRAS: %d / %d" % [bars_left, total]
	if bars_icons_label:
		var icons = ""
		for i in range(total):
			if i < bars_left:
				icons += "■ "
			else:
				icons += "□ "
		bars_icons_label.text = icons.strip_edges()

func _update_hp_text(cur: float, max_hp: float) -> void:
	if hp_numeric_label:
		var pct = int((cur / max(1.0, max_hp)) * 100.0)
		hp_numeric_label.text = "%d / %d (%d%%)" % [int(cur), int(max_hp), pct]

func _on_armor_heat_changed(cur_heat: float, max_heat: float) -> void:
	armor_bar.value = cur_heat
	_update_armor_text(cur_heat, max_heat)
	
	if cur_heat >= max_heat:
		armor_bar.modulate = Color(2.5, 0.6, 0.2, 1.0)
	else:
		armor_bar.modulate = Color(1.0, 1.0, 1.0, 1.0)

func _update_armor_text(cur: float, max_h: float) -> void:
	if armor_numeric_label:
		var pct = int((cur / max(1.0, max_h)) * 100.0)
		armor_numeric_label.text = "CALOR DE ARMADURA: %d%%" % pct

func _on_boss_state_changed(state_text: String) -> void:
	if not status_label:
		return
	status_label.text = state_text
	
	if "ATURDIDO" in state_text:
		status_label.modulate = Color(0.2, 1.5, 1.5, 1.0)
	elif "SOBRECALENTAMIENTO" in state_text or "EMBESTIDA" in state_text:
		status_label.modulate = Color(1.8, 0.3, 0.2, 1.0)
	else:
		status_label.modulate = Color(0.85, 0.85, 0.85, 1.0)

func _on_boss_died() -> void:
	status_label.text = "¡TORRASQUE ANIQUILADO!"
	status_label.modulate = Color(0.2, 1.8, 0.4, 1.0)
	var tw = create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(container, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)
