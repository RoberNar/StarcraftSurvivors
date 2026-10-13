extends Node

# Sistema de Modo Historia y Progresión de Campaña (Acto 1 - "Memoria")
# Gestiona el flujo del prólogo, misiones del Capitán Voss, construcciones y diálogos.

signal story_stage_changed(new_stage: String)
signal mission_completed(mission_id: int)
signal dialogue_triggered(dialogue_key: String)

# Etapas principales de la historia
const STAGE_PROLOGUE = "prologue"               # Civil en el páramo, sin armas, rescate guionado
const STAGE_BASE_INITIAL = "base_initial"       # Llegada a la base en ruinas (solo Centro de Mando + Geiser)
const STAGE_MISSION_1 = "mission_1"             # Primera bajada con armadura, 20 minerales (para Cuartel y Bahía de Ingeniería)
const STAGE_BASE_BUILDING = "base_building"     # 20 minerales listos, construir Cuartel y Bahía de Ingeniería (10 y 10)
const STAGE_MISSION_2 = "mission_2"             # Sobrevivir 30 minutos y limpiar los páramos
const STAGE_ACT_1_END = "act_1_end"             # Fin de los 30 minutos, emergencia del Nydus y llegada del Jefe

# Definición de Misiones del Capitán Voss
const MISSIONS = {
	1: {
		"title": "Misión 1: Reconstrucción Perimetral",
		"desc": "Recolecta 20 minerales en el exterior para construir el Cuartel (10) y la Bahía de Ingeniería (10).",
		"type": "minerals",
		"target": 20,
		"reward_text": "Construir Cuartel (10) y Bahía de Ingeniería (10)",
		"next_stage": STAGE_BASE_BUILDING
	},
	2: {
		"title": "Misión 2: Limpieza de los Páramos",
		"desc": "Sobrevive 30 minutos frente al Enjambre para limpiar los páramos y forzar la emergencia de la amenaza.",
		"type": "survival",
		"target": 1800,
		"reward_text": "Emergencia del Canal Nydus",
		"next_stage": STAGE_ACT_1_END
	}
}

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS

# Obtener misión actual según el estado del SaveManager
func get_current_mission_id() -> int:
	var stage = SaveManager.get_story_stage()
	match stage:
		STAGE_PROLOGUE: return 0
		STAGE_BASE_INITIAL, STAGE_MISSION_1, STAGE_BASE_BUILDING, "academy_ready", "barracks_ready": return 1
		STAGE_MISSION_2, "mission_3", "mission_4", "mission_5", "mission_6", "mission_7", "mission_8", "mission_9", "mission_10": return 2
		STAGE_ACT_1_END: return 2
	return 1

func get_mission_data(m_id: int) -> Dictionary:
	return MISSIONS.get(m_id, {})

# Comprobar si el Cuartel está construido
func is_barracks_built() -> bool:
	return SaveManager.has_building("barracks")

# Comprobar si la Bahía de Ingeniería está construida (sustituye a la Academia)
func is_engineering_bay_built() -> bool:
	return SaveManager.has_building("engineering_bay") or SaveManager.has_building("academy")

func is_academy_built() -> bool:
	return is_engineering_bay_built()

# Si el jugador puede recibir mejoras al subir de nivel en una run
# (Solo después de tener la Bahía de Ingeniería)
func can_receive_run_upgrades() -> bool:
	return is_engineering_bay_built()

# Si el jugador puede acceder a la pantalla de selección de personaje
# (Solo después de construir el Cuartel)
func can_access_character_select() -> bool:
	return is_barracks_built()

# Comprobar si se puede recolectar gas vespeno en el exterior
func is_gas_available_outside() -> bool:
	return is_engineering_bay_built() or get_current_mission_id() >= 2

# Construir Cuartel Terran en la Base (10 minerales)
func build_barracks() -> bool:
	if SaveManager.total_minerals >= 10 and not is_barracks_built():
		SaveManager.spend_resources(10, 0)
		SaveManager.add_building("barracks")
		_check_base_buildings_complete()
		return true
	return false

# Construir Bahía de Ingeniería en la Base (10 minerales)
func build_engineering_bay() -> bool:
	if SaveManager.total_minerals >= 10 and not is_engineering_bay_built():
		SaveManager.spend_resources(10, 0)
		SaveManager.add_building("engineering_bay")
		SaveManager.add_building("academy")
		_check_base_buildings_complete()
		return true
	return false

func build_academy() -> bool:
	return build_engineering_bay()

func _check_base_buildings_complete() -> void:
	if is_barracks_built() and is_engineering_bay_built():
		SaveManager.set_story_stage(STAGE_MISSION_2)
		emit_signal("story_stage_changed", STAGE_MISSION_2)

# Manejo de muerte en una run (el jugador conserva todos los minerales obtenidos)
func handle_run_defeat(minerals_collected_in_run: int) -> int:
	return minerals_collected_in_run
