class_name BossHUD
extends CanvasLayer

@onready var container: PanelContainer = $CenterContainer/BossPanel
@onready var boss_name_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/Header/BossName
@onready var status_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/Header/BossStatus
@onready var health_bar: ProgressBar = $CenterContainer/BossPanel/Margin/HBox/VBox/HealthBar
@onready var hp_numeric_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/HealthBar/HPLabel
@onready var portrait_texture: TextureRect = $CenterContainer/BossPanel/Margin/HBox/PortraitFrame/Portrait
@onready var pillars_label: Label = $CenterContainer/BossPanel/Margin/HBox/VBox/PillarsLabel

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
	boss_ref.state_changed.connect(_on_boss_state_changed)
	boss_ref.died.connect(_on_boss_died)
	
	health_bar.max_value = boss_ref.max_health
	health_bar.value = boss_ref.current_health
	_update_hp_text(boss_ref.current_health, boss_ref.max_health)
	
	# Entrada dramática deslizándose desde arriba
	container.position.y = -80.0
	var tw = create_tween()
	tw.tween_property(container, "position:y", 12.0, 0.7).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func update_pillars_count(standing: int, total: int = 6) -> void:
	if pillars_label:
		pillars_label.text = "PILARES DE ROCA: %d / %d" % [standing, total]
		if standing <= 2:
			pillars_label.modulate = Color(1.0, 0.4, 0.4, 1.0)
		elif standing <= 4:
			pillars_label.modulate = Color(1.0, 0.85, 0.3, 1.0)
		else:
			pillars_label.modulate = Color(0.4, 0.9, 1.0, 1.0)

func _on_boss_health_changed(cur: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = cur
	_update_hp_text(cur, max_hp)
	
	# Efecto de pulso en barra de vida
	var pct = cur / max_hp
	if pct <= 0.35:
		health_bar.modulate = Color(1.5, 0.4, 0.4, 1.0)
	elif pct <= 0.65:
		health_bar.modulate = Color(1.3, 0.9, 0.3, 1.0)
	else:
		health_bar.modulate = Color(0.4, 1.2, 0.4, 1.0)

func _update_hp_text(cur: float, max_hp: float) -> void:
	if hp_numeric_label:
		var pct = int((cur / max(1.0, max_hp)) * 100.0)
		hp_numeric_label.text = "%d / %d (%d%%)" % [int(cur), int(max_hp), pct]

func _on_boss_state_changed(state_text: String) -> void:
	if not status_label:
		return
	status_label.text = state_text
	
	# Destellos según el peligro
	if "ATURDIDO" in state_text:
		status_label.modulate = Color(0.2, 1.5, 1.5, 1.0)
	elif "EMBESTIDA" in state_text:
		status_label.modulate = Color(1.8, 0.2, 0.2, 1.0)
	elif "TERREMOTO" in state_text:
		status_label.modulate = Color(1.8, 0.7, 0.1, 1.0)
	else:
		status_label.modulate = Color(0.85, 0.85, 0.85, 1.0)

func _on_boss_died() -> void:
	status_label.text = "¡COLOSO EXTERMINADO!"
	status_label.modulate = Color(0.2, 1.8, 0.4, 1.0)
	var tw = create_tween()
	tw.tween_interval(3.5)
	tw.tween_property(container, "modulate:a", 0.0, 1.0)
	tw.tween_callback(queue_free)
