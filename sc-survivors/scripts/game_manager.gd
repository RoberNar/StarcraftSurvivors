extends Node

signal xp_changed(current_xp: int, max_xp: int, level: int)
signal level_up(new_level: int, choices: Array)
signal chest_reward(choices: Array)
signal kills_changed(kills: int)
signal time_changed(seconds: float)
signal game_over_triggered(time_survived: float, kills: int, level: int)
signal mission_updated(mission: Dictionary)
signal mission_completed(mission: Dictionary)
signal gas_changed(current_gas: int)
signal base_resources_changed(minerals: int, gas: int)
signal suit_equipped_changed(equipped: bool)

# Estado de la Run y Campaña
var selected_hero: String = "marine"
var has_suit_equipped: bool = false
var current_mission_idx: int = 0
var mission_kills: int = 0
var mission_gas: int = 0
var mission_bosses: int = 0
var is_mission_completed: bool = false

# Mejoras permanentes de inicio compradas en la Academia
var barracks_upgrades: Dictionary = {
	"damage": 0,
	"multishot": 0,
	"speed": 0,
	"armor": 0,
	"stim": 0,
	"regen": 0,
	"magnet": 0,
	"mineral_efficiency": 0,
	"vespene_doubler": 0
}

const BARRACKS_UPGRADES_DEF = {
	"damage": {
		"name": "Armamento de Infantería (Daño Global)",
		"desc": "+5% Daño a todas las armas por nivel",
		"max_lvl": 10,
		"cost_min": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cost_gas": [2, 4, 7, 11, 16, 22, 30, 40, 52, 68],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 3
	},
	"multishot": {
		"name": "Saturación Balística (Disparo Adicional)",
		"desc": "+1 Proyectil/disparo adicional a todas las armas por nivel",
		"max_lvl": 3,
		"cost_min": [0, 0, 0],
		"cost_gas": [8, 20, 45],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 6
	},
	"speed": {
		"name": "Servomotores CMC (Velocidad)",
		"desc": "+5% Velocidad de movimiento inicial por nivel",
		"max_lvl": 10,
		"cost_min": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cost_gas": [1, 2, 4, 7, 11, 16, 22, 29, 38, 50],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 4
	},
	"armor": {
		"name": "Blindaje CMC (Vida y Armadura)",
		"desc": "+15 Vida Máxima y +1 Armadura base por nivel",
		"max_lvl": 10,
		"cost_min": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cost_gas": [1, 3, 5, 8, 12, 17, 24, 32, 42, 55],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 2
	},
	"stim": {
		"name": "Estimulantes Sintéticos (Stimpack)",
		"desc": "Desbloquea [T] Stimpack e incrementa su duración y recarga",
		"max_lvl": 5,
		"cost_min": [0, 0, 0, 0, 0],
		"cost_gas": [2, 5, 10, 18, 30],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 1
	},
	"regen": {
		"name": "Botiquín Nanomédico (Regen)",
		"desc": "+0.8 Regeneración de vida/s inicial por nivel",
		"max_lvl": 10,
		"cost_min": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cost_gas": [2, 4, 7, 11, 16, 22, 30, 40, 52, 68],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 7
	},
	"magnet": {
		"name": "Condensador de Flujo (Imán)",
		"desc": "+18% Radio de atracción de minerales de inicio",
		"max_lvl": 10,
		"cost_min": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cost_gas": [1, 2, 4, 7, 11, 16, 22, 29, 38, 50],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 0
	},
	"mineral_efficiency": {
		"name": "Excavación de Plasma (+EXP)",
		"desc": "+exp 5% por nivel",
		"max_lvl": 10,
		"cost_min": [0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
		"cost_gas": [2, 4, 7, 11, 16, 22, 30, 40, 52, 68],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 0
	},
	"vespene_doubler": {
		"name": "Condensador de Vespeno (Gas x2)",
		"desc": "Duplica la extracción de Gas Vespeno por cada tanque recolectado",
		"max_lvl": 1,
		"cost_min": [0],
		"cost_gas": [25],
		"prereq": "",
		"is_weapon": false,
		"icon_idx": 5
	}
}

const MISSIONS_DEF = [
	{
		"id": 1,
		"title": "Misión 1: Reconocimiento y Purga",
		"desc": "Sal al sector exterior y elimina 100 Zerglings.",
		"type": "kills",
		"target_count": 100,
		"reward_minerals": 0,
		"reward_gas": 0,
		"briefing": "¡Soldado! Sensores perimetrales detectan enjambres hostiles fuera de la base. Sube a la nave en el Puerto Estelar, aterriza en el sector exterior y elimina a 100 Zerglings antes de que se acerquen.",
		"complete_dialog": "¡Excelente barrido táctico! El perímetro exterior está asegurado. Reabastécete en la Bahía de Ingeniería con el Gas Vespeno acumulado antes de tu próxima misión."
	},
	{
		"id": 2,
		"title": "Misión 2: Suministro de Gas Vespeno",
		"desc": "Recolecta 10 tanques de Gas Vespeno usando las balizas direccionales.",
		"type": "gas",
		"target_count": 10,
		"reward_minerals": 0,
		"reward_gas": 0,
		"briefing": "Nuestras naves y generadores de energía necesitan combustible de Vespeno de alta pureza. En el exterior hay tanques abandonados. Sigue las flechas verdes en tu radar y tráenos 10 tanques.",
		"complete_dialog": "¡Depósitos de combustible restablecidos! Excelente trabajo rastreando el Vespeno en territorio hostil."
	},
	{
		"id": 3,
		"title": "Misión 3: El Titán del Enjambre",
		"desc": "Elimina a 200 enemigos y abate a la gigantesca bestia Ultralisco.",
		"type": "boss",
		"target_count": 1,
		"kills_req": 200,
		"reward_minerals": 0,
		"reward_gas": 0,
		"briefing": "¡Alerta máxima! Una monstruosidad gigante de clase Ultralisco acecha en el exterior. Erradica la vanguardia y aniquila al Ultralisco con todo tu arsenal.",
		"complete_dialog": "¡El Ultralisco ha sido pulverizado! ¡Eres un auténtico héroe de las Fuerzas Confederadas Terran!"
	},
	{
		"id": 4,
		"title": "Misión 4: Extracción y Supervivencia",
		"desc": "Recolecta 20 tanques de Gas Vespeno y elimina a 300 enemigos.",
		"type": "combined",
		"target_count": 20,
		"kills_req": 300,
		"reward_minerals": 0,
		"reward_gas": 0,
		"briefing": "La infestación zerg ha alcanzado masa crítica. Extrae todo el combustible que puedas y resiste antes de llamar a la nave de evacuación.",
		"complete_dialog": "¡Operación completada con distinción de honor! Dominas el campo de batalla como nadie."
	}
]

var game_time: float = 0.0
var kills_count: int = 0
var current_level: int = 1
var current_xp: int = 0
var xp_needed: int = 40
var is_game_over: bool = false
var is_leveling_up: bool = false
var has_shown_max_upgrades_notice: bool = false
var session_minerals: int = 0
var mineral_accumulator: float = 0.0

# Spawning de enemigos
var spawn_timer: float = 0.0
var base_spawn_interval: float = 1.2
var zergling_scene: PackedScene = null
var hydralisk_scene: PackedScene = null
var mutalisk_scene: PackedScene = null
var ultralisk_scene: PackedScene = null
var drone_scene: PackedScene = null
var nydus_scene: PackedScene = null

# Mini-jefes cada 4 minutos (240 segundos) y Clímax a los 20 minutos (1200s)
var next_ultralisk_time: float = 240.0
var has_triggered_20min_climax: bool = false
var has_triggered_30min_climax: bool = false # compat

# Peligro Subterráneo del Enjambre: Espinas de Lurker
var lurker_hazard_scene: PackedScene = null
var next_lurker_event_time: float = 180.0
var lurker_frenzy_active: bool = false
var lurker_frenzy_timer: float = 0.0
var lurker_frenzy_interval: float = 3.2

# Eventos de Estructuras del Enjambre (Minutos 5, 10 y 13)
var event_zergling_pool_spawned: bool = false
var event_hydralisk_den_spawned: bool = false
var event_mutalisk_spire_spawned: bool = false

# Pool de Armas (Max 3)
const WEAPONS_DEF = [
	{
		"id": "c14_rifle",
		"type": "weapon",
		"name": "Rifle Gauss C-14",
		"desc": "+1 Bala adicional por disparo\nMayor saturación de fuego",
		"weapon_idx": 0
	},
	{
		"id": "firebat_flame",
		"type": "weapon",
		"name": "Lanza-llamas Firebat",
		"desc": "Arma adicional: Dispara conos de fuego\n+1 Llamarada en abanico y +28% AoE",
		"weapon_idx": 1
	},
	{
		"id": "spider_mine",
		"type": "weapon",
		"name": "Minas Araña del Vulture",
		"desc": "Arma adicional: Siembra minas móviles\n+1 Mina robótica por ciclo y daño masivo",
		"weapon_idx": 2
	},
	{
		"id": "ghost_sniper",
		"type": "weapon",
		"name": "Rifle Francotirador Ghost C-10",
		"desc": "Arma adicional: Proyectiles balísticos de 25mm\nque atraviesan enemigos a gran distancia",
		"weapon_idx": 3
	},
	{
		"id": "mutalisk_glave",
		"type": "weapon",
		"name": "Glave Wurm Mutalisco",
		"desc": "Bio-arma Zerg: Proyectiles voraces que rebotan\nentre múltiples objetivos (+2 rebotes por nivel)",
		"weapon_idx": 4
	}
]

# Pool de Mejoras Pasivas (Max 6 distintas, niveles infinitos)
const PASSIVES_DEF = [
	{
		"id": "u238_shells",
		"type": "passive",
		"name": "U-238 Shells",
		"desc": "+15% Daño a TODAS las armas\n+1 Penetración balística (atraviesa enemigos)",
		"icon_idx": 3
	},
	{
		"id": "combat_shield",
		"type": "passive",
		"name": "Combat Shield",
		"desc": "+25% Vida Máxima total\nCura el 25% de la salud inmediatamente",
		"icon_idx": 2
	},
	{
		"id": "cadence",
		"type": "passive",
		"name": "Cadencia Gauss",
		"desc": "+20% Velocidad de ataque a\nTODAS las armas activas",
		"icon_idx": 4
	},
	{
		"id": "multishot",
		"type": "passive",
		"name": "Disparo Múltiple",
		"desc": "+1 Proyectil a TODAS las armas\n(Balas, llamaradas, minas y francotirador)",
		"icon_idx": 6
	},
	{
		"id": "stimpack_upgrade",
		"type": "passive",
		"name": "Infusión de Stimpack",
		"desc": "+12% Velocidad de movimiento base\n+1s Duración del Stimpack [T]",
		"icon_idx": 1
	},
	{
		"id": "explosive_rounds",
		"type": "passive",
		"name": "Balas Explosivas",
		"desc": "+25% Tamaño y radio AoE de armas\nExplosiones en área al impactar",
		"icon_idx": 5
	},
	{
		"id": "magnetic_field",
		"type": "passive",
		"name": "Campo Magnético",
		"desc": "+30% Radio de recolección\nde cristales de mineral",
		"icon_idx": 0
	},
	{
		"id": "medikit",
		"type": "passive",
		"name": "Regeneración Médica",
		"desc": "+3% Regeneración de vida/segundo\nCura 20% de salud inmediata",
		"icon_idx": 7
	}
]

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	zergling_scene = load("res://scenes/zergling.tscn")
	hydralisk_scene = load("res://scenes/hydralisk.tscn")
	mutalisk_scene = load("res://scenes/mutalisk.tscn")
	ultralisk_scene = load("res://scenes/ultralisk.tscn")
	drone_scene = load("res://scenes/drone.tscn")
	nydus_scene = load("res://scenes/nydus_canal.tscn")
	lurker_hazard_scene = load("res://scenes/lurker_spine_hazard.tscn")
	sync_barracks_upgrades()
	reset_game()

func sync_barracks_upgrades() -> void:
	if not has_node("/root/SaveManager"):
		return
	for k in BARRACKS_UPGRADES_DEF.keys():
		barracks_upgrades[k] = SaveManager.get_academy_upgrade_level(k)
	if barracks_upgrades.get("damage", 0) == 0:
		var legacy_dmg = SaveManager.get_academy_upgrade_level("c14_damage")
		if legacy_dmg > 0:
			barracks_upgrades["damage"] = legacy_dmg
	if barracks_upgrades.get("multishot", 0) == 0:
		var legacy_ms = SaveManager.get_academy_upgrade_level("c14_multishot")
		if legacy_ms > 0:
			var m_lvl = 1
			if legacy_ms >= 8: m_lvl = 3
			elif legacy_ms >= 4: m_lvl = 2
			barracks_upgrades["multishot"] = m_lvl

func start_new_run(hero: String = "marine") -> void:
	selected_hero = hero
	current_mission_idx = 0
	mission_kills = 0
	mission_gas = 0
	mission_bosses = 0
	is_mission_completed = false
	sync_barracks_upgrades()
	emit_signal("base_resources_changed", get_total_minerals(), get_total_gas())
	emit_signal("mission_updated", get_current_mission())

func reset_game() -> void:
	sync_barracks_upgrades()
	game_time = 0.0
	kills_count = 0
	current_level = 1
	current_xp = 0
	xp_needed = 40
	session_minerals = 0
	mineral_accumulator = 0.0
	next_ultralisk_time = 240.0
	has_triggered_20min_climax = false
	has_triggered_30min_climax = false
	event_zergling_pool_spawned = false
	event_hydralisk_den_spawned = false
	event_mutalisk_spire_spawned = false
	next_lurker_event_time = 180.0
	lurker_frenzy_active = false
	lurker_frenzy_timer = 0.0
	is_game_over = false
	is_leveling_up = false
	has_shown_max_upgrades_notice = false
	get_tree().paused = false
	AudioManager.play_music("terran2", true, true)

func get_total_minerals() -> int:
	if has_node("/root/SaveManager"):
		return SaveManager.total_minerals
	return 0

func get_total_gas() -> int:
	if has_node("/root/SaveManager"):
		return SaveManager.total_gas
	return 0

func get_current_mission() -> Dictionary:
	if has_node("/root/StoryManager"):
		var m_id = StoryManager.get_current_mission_id()
		var s_m = StoryManager.get_mission_data(m_id)
		if not s_m.is_empty():
			return s_m
	if current_mission_idx >= 0 and current_mission_idx < MISSIONS_DEF.size():
		return MISSIONS_DEF[current_mission_idx]
	return MISSIONS_DEF[MISSIONS_DEF.size() - 1]

func get_mission_progress_str() -> String:
	var m = get_current_mission()
	match m.get("type", ""):
		"minerals":
			var tgt = m.get("target", 20)
			return "%d / %d Minerales" % [mini(session_minerals, tgt), tgt]
		"kills":
			var tgt = m.get("target", m.get("target_count", 100))
			return "%d / %d Zerglings" % [mini(mission_kills, tgt), tgt]
		"gas":
			var tgt = m.get("target", m.get("target_count", 10))
			return "%d / %d Gas Vespeno" % [mini(mission_gas, tgt), tgt]
		"ultralisks", "boss":
			var tgt = m.get("target", m.get("target_count", 1))
			var boss_str = "Jefe Abatido" if mission_bosses >= 1 else "Eliminar Ultralisco"
			return "%d / %d Kills | %s" % [mini(mission_kills, m.get("kills_req", 200)), m.get("kills_req", 200), boss_str]
		"survival":
			var tgt = m.get("target", 1200)
			var cur_s = int(game_time)
			return "%02d:%02d / %02d:%02d" % [cur_s / 60, cur_s % 60, tgt / 60, tgt % 60]
		"combined":
			return "%d / %d Gas | %d / %d Kills" % [mini(mission_gas, m.get("target_count", 20)), m.get("target_count", 20), mini(mission_kills, m.get("kills_req", 300)), m.get("kills_req", 300)]
	return ""

func _check_mission_progress() -> void:
	if is_mission_completed:
		return
	var m = get_current_mission()
	var complete: bool = false
	match m.get("type", ""):
		"minerals":
			var tgt = m.get("target", 20)
			if session_minerals >= tgt or get_total_minerals() >= tgt:
				complete = true
		"kills":
			var tgt = m.get("target", m.get("target_count", 100))
			if mission_kills >= tgt:
				complete = true
		"gas":
			var tgt = m.get("target", m.get("target_count", 10))
			if mission_gas >= tgt:
				complete = true
		"ultralisks", "boss":
			var tgt = m.get("target", m.get("target_count", 1))
			if mission_bosses >= tgt and mission_kills >= m.get("kills_req", 1):
				complete = true
		"survival":
			var tgt = m.get("target", 1200)
			if game_time >= tgt or has_triggered_20min_climax or has_triggered_30min_climax:
				complete = true
		"combined":
			if mission_gas >= m.get("target_count", 20) and mission_kills >= m.get("kills_req", 300):
				complete = true
	
	if complete:
		is_mission_completed = true
		AudioManager.play_sfx("upgrade")
		emit_signal("mission_completed", m)
	else:
		emit_signal("mission_updated", m)

func claim_mission_reward() -> bool:
	if not is_mission_completed:
		return false
	var m = get_current_mission()
	var r_min = m.get("reward_minerals", 0)
	var r_gas = m.get("reward_gas", 0)
	if has_node("/root/SaveManager"):
		SaveManager.add_minerals(r_min)
		SaveManager.add_gas(r_gas)
	
	if current_mission_idx < MISSIONS_DEF.size() - 1:
		current_mission_idx += 1
	mission_kills = 0
	mission_gas = 0
	mission_bosses = 0
	is_mission_completed = false
	emit_signal("mission_updated", get_current_mission())
	emit_signal("base_resources_changed", get_total_minerals(), get_total_gas())
	return true

func buy_barracks_upgrade(upgrade_id: String) -> bool:
	sync_barracks_upgrades()
	if not BARRACKS_UPGRADES_DEF.has(upgrade_id):
		return false
	var def = BARRACKS_UPGRADES_DEF[upgrade_id]
	var prereq = def.get("prereq", "")
	if prereq != "" and barracks_upgrades.get(prereq, 0) == 0:
		return false
	var current_lvl = barracks_upgrades.get(upgrade_id, 0)
	if current_lvl >= def["max_lvl"]:
		return false
	var cost_g = def["cost_gas"][current_lvl]
	
	if has_node("/root/SaveManager"):
		if SaveManager.spend_resources(0, cost_g):
			barracks_upgrades[upgrade_id] = current_lvl + 1
			SaveManager.set_academy_upgrade_level(upgrade_id, current_lvl + 1)
			if upgrade_id == "stim":
				SaveManager.unlock_stimpack()
			SaveManager.save_data()
			AudioManager.play_sfx("upgrade")
			emit_signal("base_resources_changed", get_total_minerals(), get_total_gas())
			return true
	return false

func get_barracks_bonus(stat_name: String) -> float:
	match stat_name:
		"armor": return barracks_upgrades.get("armor", 0) * 1.0
		"max_hp": return barracks_upgrades.get("armor", 0) * 15.0
		"damage":
			var lvl = barracks_upgrades.get("damage", 0)
			if lvl == 0 and barracks_upgrades.has("c14_damage"):
				lvl = barracks_upgrades.get("c14_damage", 0)
			return lvl * 0.05
		"multishot":
			var lvl = barracks_upgrades.get("multishot", 0)
			if lvl == 0 and barracks_upgrades.has("c14_multishot"):
				var legacy = barracks_upgrades.get("c14_multishot", 0)
				if legacy >= 8: lvl = 3
				elif legacy >= 4: lvl = 2
				elif legacy >= 1: lvl = 1
			return float(lvl)
		"speed": return barracks_upgrades.get("speed", 0) * 0.05
		"cadence": return 0.0
		"regen": return barracks_upgrades.get("regen", 0) * 0.8
		"magnet": return barracks_upgrades.get("magnet", 0) * 0.18
		"stim_dur": return barracks_upgrades.get("stim", 0) * 0.5
		"stim_cd": return barracks_upgrades.get("stim", 0) * 0.3
		"mineral_efficiency": return barracks_upgrades.get("mineral_efficiency", 0) * 0.05
		"vespene_doubler": return float(barracks_upgrades.get("vespene_doubler", 0))
	return 0.0

func deploy_to_mission() -> void:
	reset_game()
	get_tree().change_scene_to_file("res://scenes/main.tscn")

func evacuate_to_base() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/terran_base.tscn")

func _process(delta: float) -> void:
	if is_game_over or is_leveling_up or get_tree().paused:
		return
	
	var cur_scene = get_tree().current_scene
	if cur_scene == null or cur_scene.name != "Main":
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player and ("is_in_base" in player) and player.is_in_base:
		return
	
	game_time += delta * 2.0
	emit_signal("time_changed", game_time)
	
	if has_node("/root/SaveManager"):
		SaveManager.check_realtime_achievements(game_time)
	
	_handle_world_events()
	_handle_lurker_hazards(delta)
	
	if game_time >= 1200.0 and not has_triggered_20min_climax:
		_trigger_20min_climax()
	
	_handle_spawning(delta)
	_handle_boss_spawning()

func _handle_world_events() -> void:
	if game_time >= 300.0 and not event_zergling_pool_spawned:
		event_zergling_pool_spawned = true
		_spawn_spawner_structure("zergling_pool")
	if game_time >= 600.0 and not event_hydralisk_den_spawned:
		event_hydralisk_den_spawned = true
		_spawn_spawner_structure("hydralisk_den")
	if game_time >= 780.0 and not event_mutalisk_spire_spawned:
		event_mutalisk_spire_spawned = true
		_spawn_spawner_structure("mutalisk_spire")

func _send_voss_transmission(msg: String, duration: float = 5.5) -> void:
	AudioManager.play_voss_greeting()
	for hud in get_tree().get_nodes_in_group("hud"):
		if hud and hud.has_method("show_transmission"):
			hud.show_transmission(
				"CAPITÁN HOLLIS VOSS",
				load("res://assets/skins/sd/portrait/civilian_portrait.png"),
				msg,
				duration
			)

func _spawn_spawner_structure(type: String) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
	
	var spawner_scene = load("res://scenes/zerg_spawner_structure.tscn")
	if not spawner_scene:
		return
	
	var angle = randf() * TAU
	var dist = randf_range(480.0, 560.0)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	
	var spawner = spawner_scene.instantiate()
	spawner.structure_type = type
	spawner.global_position = spawn_pos
	
	var main_scene = get_tree().current_scene
	if main_scene:
		main_scene.add_child(spawner)
	
	var msg = ""
	match type:
		"zergling_pool":
			msg = "«¡ALERTA TÁCTICA! Detectamos un Pozo de Desove Zerg activo en el sector. ¡Destrúyelo para detener el torrente de Zerglings!»"
		"hydralisk_den":
			msg = "«¡EMERGENCIA BIOLÓGICA! Ha brotado una Guarida de Hidraliscos masiva. ¡Elimina la estructura y frena las ráfagas de espinas!»"
		"mutalisk_spire":
			msg = "«¡CÓDIGO ROJO! Una Espira de Mutaliscos domina el cielo. ¡Derríbala para cortar el asalto aéreo del enjambre!»"
	
	_send_voss_transmission(msg, 5.5)

func _trigger_20min_climax() -> void:
	has_triggered_20min_climax = true
	has_triggered_30min_climax = true
	lurker_frenzy_active = false
	
	# Detener y limpiar de inmediato todos los peligros de espinas subterráneas ("para todo")
	get_tree().call_group("lurker_hazards", "clear_immediately")
	
	# 1. Limpiar todos los enemigos del mapa
	var enemies = get_tree().get_nodes_in_group("enemies")
	for e in enemies:
		if is_instance_valid(e):
			e.queue_free()
	
	# 2. Emerger Canal Nydus colosal en frente del jugador
	var player = get_tree().get_first_node_in_group("player")
	if player and nydus_scene:
		var nydus = nydus_scene.instantiate()
		nydus.global_position = player.global_position + Vector2(0, -90)
		var cur_scene = get_tree().current_scene
		if cur_scene:
			cur_scene.add_child(nydus)
	
	AudioManager.play_sfx("nydus_emerge", 0.0, 5.0)
	
	# 3. Transmisión del Capitán Voss
	_send_voss_transmission(
		"«¡SUPERVIVENCIA DE 20 MINUTOS COMPLETADA! ¡UN CANAL NYDUS COLOSAL HA EMERGIDO! ¡PREPÁRATE PARA LA BATALLA DEFINITIVA!»",
		7.0
	)
	
	_check_mission_progress()

func _trigger_30min_climax() -> void:
	_trigger_20min_climax()

func _handle_lurker_hazards(delta: float) -> void:
	if has_triggered_20min_climax or is_game_over:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player) or player.is_dead:
		return
	
	# 1. Avisos y erupciones tácticas cada 3 minutos (180s, 360s, 540s, 720s)
	if game_time >= next_lurker_event_time and game_time < 900.0:
		var current_mark = next_lurker_event_time
		next_lurker_event_time += 180.0
		_trigger_lurker_event_wave(current_mark)
	
	# 2. Alerta de la fase final a los 15 minutos (900s)
	if game_time >= 900.0 and not lurker_frenzy_active and game_time < 1200.0:
		lurker_frenzy_active = true
		_trigger_lurker_frenzy_warning()
	
	# 3. Frenesí de los últimos 5 minutos (15:00 a 20:00 = 900s a 1200s): espinas incesantes
	if lurker_frenzy_active and game_time < 1200.0:
		lurker_frenzy_timer += delta
		if lurker_frenzy_timer >= lurker_frenzy_interval:
			lurker_frenzy_timer = 0.0
			var count = randi_range(2, 3)
			for i in range(count):
				_spawn_tactical_lurker_line(player.global_position)

func _trigger_lurker_event_wave(mark: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if not player or not is_instance_valid(player):
		return
	
	var msg = ""
	var line_count = 3
	if mark <= 185.0:
		msg = "«¡ALERTA SÍSMICA! ¡Sensores geológicos detectan movimientos en el subsuelo! ¡El Enjambre despliega espinas subterráneas, mantén la movilidad!»"
		line_count = 3
	elif mark <= 365.0:
		msg = "«¡CUIDADO CON EL TERRENO! ¡Erupciones subterráneas detectadas en tu sector! ¡Evita las trayectorias marcadas antes de que broten las púas!»"
		line_count = 4
	elif mark <= 545.0:
		msg = "«¡ACTIVIDAD SÍSMICA EN AUMENTO! ¡Oleadas de espinas subterráneas cruzando el campo de batalla! ¡Vigila tus pasos, soldado!»"
		line_count = 5
	else:
		msg = "«¡RADAR GEOLÓGICO SATURADO! ¡Múltiples líneas de espinas de acechador perforando la superficie en masa!»"
		line_count = 6
	
	_send_voss_transmission(msg, 5.0)
	
	for i in range(line_count):
		get_tree().create_timer(float(i) * 0.40).timeout.connect(func():
			if not is_instance_valid(player) or has_triggered_20min_climax:
				return
			_spawn_tactical_lurker_line(player.global_position)
		)

func _trigger_lurker_frenzy_warning() -> void:
	var msg = "«¡EMERGENCIA CRÍTICA! ¡TEMBLOR ZERG MASIVO! ¡EL SUELO SE ESTÁ DESGARRANDO POR TODAS PARTES, NO DEJES DE MOVERTE HASTA QUE SE CUMPLAN LOS 20 MINUTOS!»"
	_send_voss_transmission(msg, 6.0)

func _spawn_tactical_lurker_line(center_pos: Vector2) -> void:
	if not lurker_hazard_scene:
		lurker_hazard_scene = load("res://scenes/lurker_spine_hazard.tscn")
	if not lurker_hazard_scene:
		return
	
	var hazard = lurker_hazard_scene.instantiate()
	var angle = randf() * TAU
	var dir = Vector2(cos(angle), sin(angle))
	var perp = Vector2(-dir.y, dir.x)
	
	var lateral_offset = randf_range(-140.0, 140.0)
	var start_dist = randf_range(220.0, 320.0)
	var start_pos = center_pos - (dir * start_dist) + (perp * lateral_offset)
	var length = randf_range(560.0, 680.0)
	var telegraph_time = randf_range(1.3, 1.6)
	var dmg = 16.0
	
	hazard.setup(start_pos, dir, length, dmg, telegraph_time)
	
	var cur_scene = get_tree().current_scene
	if cur_scene:
		cur_scene.add_child(hazard)

func _handle_spawning(delta: float) -> void:
	if has_triggered_20min_climax or has_triggered_30min_climax:
		return
	
	# Descanzo táctico de 10 segundos al final de cada ciclo de 2 minutos (sin mensaje)
	if WaveConfig.is_in_lull(game_time):
		return
	
	var wave = WaveConfig.get_current_wave(game_time)
	var interval = wave.get("spawn_interval", 0.35)
	var batch = wave.get("batch_size", 3)
	var max_active = wave.get("max_enemies", 120)
	
	spawn_timer += delta
	if spawn_timer >= interval:
		spawn_timer = 0.0
		var current_enemies = get_tree().get_nodes_in_group("enemies").size()
		if current_enemies >= max_active:
			return
		
		for i in range(batch):
			_spawn_enemy()

func _handle_boss_spawning() -> void:
	if game_time >= next_ultralisk_time and game_time < 1200.0:
		var cycle = int(next_ultralisk_time / 240.0)
		next_ultralisk_time += 240.0
		_spawn_ultralisk(cycle)

func _spawn_ultralisk(cycle: int = 1) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var angle = randf() * TAU
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * 480.0
	
	if ultralisk_scene:
		var boss = ultralisk_scene.instantiate()
		boss.global_position = spawn_pos
		
		var scale_val = clampf(1.0 + (cycle - 1) * 0.12, 1.0, 1.55)
		var hp_val = 600.0 + (cycle - 1) * 450.0
		var dmg_val = 22.0 + (cycle - 1) * 6.0
		if boss.has_method("set_mini_boss_scale"):
			boss.set_mini_boss_scale(scale_val, hp_val, dmg_val)
		else:
			boss.scale = Vector2(scale_val, scale_val)
			boss.base_health = hp_val
			boss.current_health = hp_val
		
		var main_scene = get_tree().current_scene
		if main_scene:
			main_scene.add_child(boss)

func _spawn_enemy() -> void:
	if has_triggered_20min_climax or has_triggered_30min_climax:
		return
	
	var player = get_tree().get_first_node_in_group("player")
	if player == null or not is_instance_valid(player):
		return
	
	var angle = randf() * TAU
	var dist = randf_range(360.0, 450.0)
	var spawn_pos = player.global_position + Vector2(cos(angle), sin(angle)) * dist
	
	var picked = WaveConfig.pick_random_enemy(game_time)
	var enemy_scene: PackedScene = null
	var enemy_type: String = picked.get("type", "zergling")
	var enemy_tier: int = picked.get("tier", 1)
	match enemy_type:
		"zergling": enemy_scene = zergling_scene
		"hydralisk": enemy_scene = hydralisk_scene
		"mutalisk": enemy_scene = mutalisk_scene
		"drone": enemy_scene = drone_scene
		_: enemy_scene = zergling_scene
	
	if enemy_scene:
		var enemy = enemy_scene.instantiate()
		enemy.global_position = spawn_pos
		if enemy.has_method("set_tier"):
			enemy.set_tier(enemy_tier)
		var main_scene = get_tree().current_scene
		if main_scene:
			main_scene.add_child(enemy)

func _spawn_zergling() -> void:
	_spawn_enemy()

func add_zergling_kill() -> void:
	if has_node("/root/SaveManager"):
		SaveManager.add_zergling_kill()

func add_kill() -> void:
	kills_count += 1
	mission_kills += 1
	if has_node("/root/SaveManager"):
		SaveManager.add_session_kills(1)
	emit_signal("kills_changed", kills_count)
	_check_mission_progress()

func add_boss_kill() -> void:
	mission_bosses += 1
	_check_mission_progress()

func add_gas(amount: int = 1) -> void:
	mission_gas += amount
	if has_node("/root/SaveManager"):
		SaveManager.add_gas(amount)
	emit_signal("gas_changed", get_total_gas())
	emit_signal("base_resources_changed", get_total_minerals(), get_total_gas())
	_check_mission_progress()

func add_xp(amount: int, minerals: int = 1) -> void:
	if is_game_over:
		return
	var player = get_tree().get_first_node_in_group("player")
	if player and (player.is_dead or player.current_health <= 0.0):
		return
	
	# Bono de mejora permanente: +5% de experiencia por nivel de Excavación de Plasma
	var bonus_mult = 1.0 + get_barracks_bonus("mineral_efficiency")
	var final_xp = int(round(float(amount) * bonus_mult))
	current_xp += max(1, final_xp) if amount > 0 else 0
	
	# Los minerales representan la experiencia en mapa y recurso de la run activa
	session_minerals += minerals
	if current_xp >= xp_needed:
		_trigger_level_up()
	emit_signal("xp_changed", current_xp, xp_needed, current_level)

func _trigger_level_up() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_game_over or (player and (player.is_dead or player.current_health <= 0.0)):
		return
	current_xp -= xp_needed
	current_level += 1
	xp_needed = int(xp_needed * 1.35) + 15
	
	var choices = _get_available_upgrade_choices()
	if choices.is_empty():
		# Sin mejoras o alcanzado el máximo investigado: no pausar ni congelar el juego
		is_leveling_up = false
		get_tree().paused = false
		# Solo mostrar el mensaje si la academia ya está construida, a partir de nivel 2 y una sola vez
		if StoryManager.is_academy_built() and current_level >= 2 and not has_shown_max_upgrades_notice:
			has_shown_max_upgrades_notice = true
			if player and player.has_method("show_bubble"):
				player.show_bubble("Mejoras al máximo de investigación", 2.2)
		emit_signal("xp_changed", current_xp, xp_needed, current_level)
		return
	
	is_leveling_up = true
	get_tree().paused = true
	AudioManager.play_sfx("upgrade")
	emit_signal("level_up", current_level, choices)

func trigger_chest_reward() -> void:
	var player = get_tree().get_first_node_in_group("player")
	if is_game_over or (player and (player.is_dead or player.current_health <= 0.0)):
		return
	
	var choices = _get_available_upgrade_choices()
	if choices.is_empty():
		# Recompensa directa si no hay mejoras disponibles
		add_xp(0, 50)
		if player and player.has_method("show_bubble"):
			player.show_bubble("Cofre táctico: +50 Minerales", 2.0)
		return
	
	is_leveling_up = true
	get_tree().paused = true
	AudioManager.play_sfx("upgrade")
	emit_signal("chest_reward", choices)

func _get_available_upgrade_choices() -> Array:
	# Antes de construir la Academia, no hay ninguna mejora disponible
	if not StoryManager.is_academy_built():
		return []
	
	var player = get_tree().get_first_node_in_group("player")
	var player_weapons = player.weapons if player else {}
	var player_passives = player.passives if player else {}
	
	var weapon_pool: Array = []
	var passive_pool: Array = []
	
	# 1. Armas
	if player_weapons.has("c14_rifle"):
		var lvl = player_weapons["c14_rifle"] + 1
		weapon_pool.append({
			"id": "c14_rifle",
			"type": "weapon",
			"name": "Rifle Gauss C-14 (Nv. %d)" % lvl,
			"desc": "+1 Bala adicional por disparo\nMayor saturación balística",
			"weapon_idx": 0
		})
	
	var sec_count = 0
	for w in player_weapons.keys():
		if w != "c14_rifle":
			sec_count += 1
	
	# 1. Firebat (Disponible desde el inicio en las runs)
	if player_weapons.has("firebat_flame"):
		var pow_lvl = player.firebat_power_lvl if player else 1
		var str_lvl = player.firebat_streams if player else 1
		if pow_lvl < 6:
			weapon_pool.append({
				"id": "firebat_power",
				"type": "weapon",
				"name": "Potencia de Llamarada (Nv. %d)" % (pow_lvl + 1),
				"desc": "+15% Daño a cada llamarada\nIncremento térmico concentrado (+10% AoE)",
				"weapon_idx": 1
			})
		if str_lvl < 4:
			weapon_pool.append({
				"id": "firebat_streams",
				"type": "weapon",
				"name": "Inyectores Múltiples (Nv. %d)" % (str_lvl + 1),
				"desc": "+1 Llamarada de fuego adicional\nDisparo simultáneo en abanico",
				"weapon_idx": 1
			})
	elif sec_count < 3 and SaveManager.is_weapon_unlocked("firebat_flame"):
		weapon_pool.append({
			"id": "firebat_flame",
			"type": "weapon",
			"name": "NUEVA ARMA: Lanza-llamas Firebat",
			"desc": "Dispara conos de napalm ardiente\nque calcinan a grupos enteros de zerg",
			"weapon_idx": 1
		})
	
	# 2. Minas Araña Vulture (Disponible desde el inicio en las runs)
	if player_weapons.has("spider_mine"):
		var lvl = player_weapons["spider_mine"] + 1
		if lvl <= 6:
			weapon_pool.append({
				"id": "spider_mine",
				"type": "weapon",
				"name": "Minas Araña (Nv. %d)" % lvl,
				"desc": "+1 Mina desplegada por ciclo\n+25 Daño de detonación masivo",
				"weapon_idx": 2
			})
	elif sec_count < 3:
		weapon_pool.append({
			"id": "spider_mine",
			"type": "weapon",
			"name": "NUEVA ARMA: Minas Araña",
			"desc": "Siembra minas móviles robóticas\nque persiguen y destruyen al enjambre",
			"weapon_idx": 2
		})
	
	# 3. Francotirador Ghost C-10 (Sobrevivir 20 minutos)
	var sniper_unlocked = SaveManager.is_weapon_unlocked("ghost_sniper", game_time) if has_node("/root/SaveManager") else false
	if sniper_unlocked:
		if player_weapons.has("ghost_sniper"):
			var lvl = player_weapons["ghost_sniper"] + 1
			if lvl <= 6:
				weapon_pool.append({
					"id": "ghost_sniper",
					"type": "weapon",
					"name": "Francotirador Ghost C-10 (Nv. %d)" % lvl,
					"desc": "+25 Daño balístico perforante\n+1 Enemigo penetrado por bala",
					"weapon_idx": 3
				})
		elif sec_count < 3:
			weapon_pool.append({
				"id": "ghost_sniper",
				"type": "weapon",
				"name": "NUEVA ARMA: Francotirador Ghost C-10",
				"desc": "Desbloqueada: Disparo de alta precisión\nque atraviesa hordas enteras de zerg",
				"weapon_idx": 3
			})
	
	# 4. Glave Wurm Mutalisco (Rebotes en cadena y multishot)
	var mutalisk_unlocked = SaveManager.is_weapon_unlocked("mutalisk_glave", game_time) if has_node("/root/SaveManager") else true
	if mutalisk_unlocked:
		if player_weapons.has("mutalisk_glave"):
			var lvl = player_weapons["mutalisk_glave"] + 1
			if lvl <= 6:
				weapon_pool.append({
					"id": "mutalisk_glave",
					"type": "weapon",
					"name": "Glave Wurm (Nv. %d)" % lvl,
					"desc": "+2 Rebotes de ricochet | +6 Daño\n+35 Velocidad de vuelo del proyectil",
					"weapon_idx": 4
				})
		elif sec_count < 3:
			weapon_pool.append({
				"id": "mutalisk_glave",
				"type": "weapon",
				"name": "NUEVA ARMA: Glave Wurm Mutalisco",
				"desc": "Proyectil biológico zerg con rebote en cadena\n(Daño y velocidad aumentan con mejoras)",
				"weapon_idx": 4
			})
	
	# 2. Pasivas (sin límites de investigación durante la run, progresión libre hasta Nv 5)
	for p in PASSIVES_DEF:
		var p_id = p["id"]
		var allowed_max = 5
		if p_id == "stimpack_upgrade":
			var can_stim = (has_node("/root/SaveManager") and SaveManager.is_stimpack_unlocked()) or barracks_upgrades.get("stim", 0) > 0
			if not can_stim:
				continue
		
		var cur_p_lvl = player_passives.get(p_id, 0)
		if cur_p_lvl < allowed_max:
			if cur_p_lvl > 0:
				var item = p.duplicate()
				item["name"] = p["name"] + " (Nv. %d)" % (cur_p_lvl + 1)
				passive_pool.append(item)
			elif player_passives.size() < 6:
				passive_pool.append(p.duplicate())
	
	weapon_pool.shuffle()
	passive_pool.shuffle()
	
	var choices: Array = []
	if not weapon_pool.is_empty():
		choices.append(weapon_pool.pop_back())
	if not weapon_pool.is_empty() and randf() > 0.35:
		choices.append(weapon_pool.pop_back())
	
	while choices.size() < 3 and not passive_pool.is_empty():
		choices.append(passive_pool.pop_back())
	
	while choices.size() < 3 and not weapon_pool.is_empty():
		choices.append(weapon_pool.pop_back())
	
	choices.shuffle()
	return choices

func select_upgrade(upgrade_id: String) -> void:
	is_leveling_up = false
	var player = get_tree().get_first_node_in_group("player")
	if player and is_instance_valid(player) and not player.is_dead and player.current_health > 0.0:
		player.apply_upgrade(upgrade_id)
	
	get_tree().paused = false
	emit_signal("xp_changed", current_xp, xp_needed, current_level)

func game_over() -> void:
	if is_game_over:
		return
	is_game_over = true
	if has_node("/root/SaveManager"):
		SaveManager.record_run_end(game_time, 0, 0)
	AudioManager.stop_music()
	emit_signal("game_over_triggered", game_time, kills_count, current_level)
