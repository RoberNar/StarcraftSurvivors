extends Node

# Sistema de Persistencia y Metaprogresión Roguelike para StarCraft: Survivors
# Compatible con múltiples ranuras de guardado (Slots 1, 2, 3) y modo historia.

signal achievement_unlocked(ach_id: String, ach_data: Dictionary)

const LEGACY_SAVE_PATH = "user://profile_save.json"

# Logros del Sistema Táctico y Desbloqueos de Arsenal
const ACHIEVEMENTS_DEF = [
	{
		"id": "firebat_unlock",
		"name": "Fuego Purificador",
		"desc": "Elimina 10 Zerglings en combate",
		"reward": "Desbloquea Lanzallamas Firebat",
		"weapon_id": "firebat_flame",
		"icon_idx": 1,
		"target": 10
	},
	{
		"id": "mutalisk_glave_unlock",
		"name": "Arma Mutalisco",
		"desc": "Elimina 10 enemigos Zerg",
		"reward": "Desbloquea Glave Wurm Mutalisco",
		"weapon_id": "mutalisk_glave",
		"icon_idx": 4,
		"target": 10
	},
	{
		"id": "spider_mine_unlock",
		"name": "Ingeniería de Trampas",
		"desc": "Sobrevive al menos 5 minutos (300s)",
		"reward": "Desbloquea Minas Araña Vulture",
		"weapon_id": "spider_mine",
		"icon_idx": 2,
		"target": 300
	},
	{
		"id": "ghost_sniper_unlock",
		"name": "Ojo de Halcón Táctico",
		"desc": "Sobrevive al menos 10 minutos (600s)",
		"reward": "Desbloquea Francotirador Ghost C-10",
		"weapon_id": "ghost_sniper",
		"icon_idx": 3,
		"target": 600
	},
	{
		"id": "goliath_unlock",
		"name": "Blindaje Pesado Goliat",
		"desc": "Sobrevive al menos 20 minutos (1200s)",
		"reward": "Desbloquea Cañones Goliat",
		"weapon_id": "goliath",
		"icon_idx": 0,
		"target": 1200
	},
	{
		"id": "destroy_spawning_pool",
		"name": "Exterminador de Nidos",
		"desc": "Destruye el Pozo de Desove Zerg (Minuto 10)",
		"reward": "Alijo de Recursos y Gloria Militar",
		"weapon_id": "",
		"icon_idx": 5,
		"target": 1
	},
	{
		"id": "destroy_hydra_den",
		"name": "Erradicador de Espinas",
		"desc": "Destruye la Guarida de Hidraliscos (Minuto 20)",
		"reward": "Alijo de Combustible Vespeno",
		"weapon_id": "",
		"icon_idx": 6,
		"target": 1
	},
	{
		"id": "destroy_mutalisk_spire",
		"name": "Supremacía Aérea",
		"desc": "Destruye la Espira de Mutaliscos (Minuto 25)",
		"reward": "Control Total del Espacio Aéreo",
		"weapon_id": "",
		"icon_idx": 7,
		"target": 1
	},
	{
		"id": "survive_30_min",
		"name": "Leyenda de Koprulu",
		"desc": "Sobrevive 20 minutos hasta la apertura del Nydus",
		"reward": "Acceso al Enfrentamiento Final",
		"weapon_id": "",
		"icon_idx": 4,
		"target": 1200
	}
]

# Rangos Militares por Kills acumuladas (0 hasta 1,000,000)
const RANK_MILESTONES = [
	{ "kills": 0, "name": "Recluta", "title": "Infantería Novata" },
	{ "kills": 100, "name": "Soldado", "title": "Curtido en Escaramuzas" },
	{ "kills": 500, "name": "Cabo", "title": "Superviviente del Enjambre" },
	{ "kills": 1000, "name": "Sargento", "title": "Líder de Escuadrón" },
	{ "kills": 2000, "name": "Sargento Mayor", "title": "Veterano de Guerra" },
	{ "kills": 5000, "name": "Teniente", "title": "Comandante Táctico" },
	{ "kills": 10000, "name": "Capitán", "title": "Héroe del Sector Koprulu" },
	{ "kills": 20000, "name": "Mayor", "title": "Destructor de Criaderos" },
	{ "kills": 50000, "name": "Teniente Coronel", "title": "Castigador de Ultraliscos" },
	{ "kills": 100000, "name": "Coronel", "title": "Leyenda Confederada" },
	{ "kills": 250000, "name": "Brigadier", "title": "Bastión de la Humanidad" },
	{ "kills": 500000, "name": "General", "title": "Azote de los Zerg" },
	{ "kills": 1000000, "name": "Mariscal de Campo", "title": "Dominador del Universo" }
]

# Mejoras permanentes en la Armería Terran (Costos en Gas Vespeno)
const PERKS_DEF = {
	"armor": {
		"name": "Blindaje Compuesto Neosteel",
		"desc": "+1 Armadura base por nivel",
		"max_lvl": 5,
		"costs": [2, 5, 10, 20, 35]
	},
	"damage": {
		"name": "Condensadores de Antimateria",
		"desc": "+6% Daño base permanente para todo el arsenal",
		"max_lvl": 5,
		"costs": [2, 5, 10, 20, 35]
	},
	"max_hp": {
		"name": "Refuerzo Fisiológico CMC",
		"desc": "+15% Vida máxima base permanente",
		"max_lvl": 5,
		"costs": [2, 5, 10, 20, 35]
	},
	"regen": {
		"name": "Dispensador Nanomédico",
		"desc": "+0.8 Regeneración de salud pasiva por segundo",
		"max_lvl": 5,
		"costs": [2, 5, 10, 20, 35]
	},
	"speed": {
		"name": "Servomotores de Articulación",
		"desc": "+8% Velocidad de movimiento permanente",
		"max_lvl": 5,
		"costs": [2, 5, 10, 20, 35]
	},
	"magnet": {
		"name": "Amplificador Gravitón",
		"desc": "+25% Radio de atracción de minerales base",
		"max_lvl": 5,
		"costs": [2, 5, 10, 20, 35]
	}
}

# Ranura actual activa (1, 2 o 3)
var current_slot: int = 1

# Estado persistente de la ranura activa
var total_kills: int = 0
var zergling_kills: int = 0
var total_minerals: int = 0
var total_gas: int = 0
var highest_survive_time: float = 0.0
var runs_played: int = 0
var perks: Dictionary = {
	"armor": 0,
	"damage": 0,
	"max_hp": 0,
	"regen": 0,
	"speed": 0,
	"magnet": 0
}
var selected_skin: String = "sd"
var unlocked_ranks: Array = []
var unlocked_achievements: Dictionary = {}

# Variables del Modo Historia
var story_stage: String = "prologue"
var buildings: Array = ["command_center", "geyser"]
var stimpack_unlocked: bool = false
var academy_upgrades: Dictionary = {}
var has_experienced_first_death: bool = false
var first_death_dialogue_pending: bool = false
var has_seen_first_death_cinematic: bool = false
var has_seen_mission_1_intro: bool = false
var has_suit_equipped: bool = false
var save_timestamp: String = ""
var is_dirty: bool = false
var autosave_timer: float = 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	load_data(current_slot)

func _process(delta: float) -> void:
	if is_dirty:
		autosave_timer += delta
		if autosave_timer >= 12.0:
			autosave_timer = 0.0
			is_dirty = false
			save_data()

func get_slot_path(slot_id: int) -> String:
	return "user://save_slot_%d.json" % slot_id

# Resumen de una ranura para el menú de selección de partidas
func get_slot_summary(slot_id: int) -> Dictionary:
	var path = get_slot_path(slot_id)
	
	# Compatibilidad con save heredado para la ranura 1
	if slot_id == 1 and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		path = LEGACY_SAVE_PATH
	
	if not FileAccess.file_exists(path):
		return { "exists": false, "slot": slot_id }
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		return { "exists": false, "slot": slot_id }
	
	var json_str = file.get_as_text()
	var parsed = JSON.parse_string(json_str)
	if not (parsed is Dictionary):
		return { "exists": false, "slot": slot_id }
	
	var stage = str(parsed.get("story_stage", "base_initial"))
	var stage_name = "Prólogo"
	match stage:
		"prologue": stage_name = "Prólogo: Sin Armas"
		"base_initial", "mission_1": stage_name = "Misión 1: 20 Minerales (Academia)"
		"academy_ready": stage_name = "Base: Construir Academia"
		"mission_2": stage_name = "Misión 2: 20 Minerales (Cuartel)"
		"barracks_ready": stage_name = "Base: Construir Cuartel"
		"academy_built", "mission_3": stage_name = "Misión 3: 50 Zerglings"
		"mission_4": stage_name = "Misión 4: 100 Zerglings"
		"mission_5": stage_name = "Misión 5: 150 Zerglings"
		"mission_6": stage_name = "Misión 6: 200 Zerglings"
		"mission_7": stage_name = "Misión 7: 300 Zerglings"
		"mission_8": stage_name = "Misión 8: 5 Ultraliscos"
		"mission_9": stage_name = "Misión 9: 10 Minutos"
		"mission_10": stage_name = "Misión 10: Ultralisco Titán"
		"act_1_end": stage_name = "Acto 1 Completado"
	
	return {
		"exists": true,
		"slot": slot_id,
		"minerals": int(parsed.get("total_minerals", 0)),
		"gas": int(parsed.get("total_gas", 0)),
		"kills": int(parsed.get("total_kills", 0)),
		"runs": int(parsed.get("runs_played", 0)),
		"stage": stage,
		"stage_name": stage_name,
		"timestamp": str(parsed.get("timestamp", ""))
	}

# Seleccionar y cargar una ranura específica
func select_slot(slot_id: int) -> void:
	current_slot = slot_id
	load_data(slot_id)

func _reset_memory_state() -> void:
	total_kills = 0
	zergling_kills = 0
	total_minerals = 0
	total_gas = 0
	highest_survive_time = 0.0
	runs_played = 0
	perks = {
		"armor": 0, "damage": 0, "max_hp": 0, "regen": 0, "speed": 0, "magnet": 0
	}
	selected_skin = "sd"
	unlocked_ranks = []
	unlocked_achievements = {}
	story_stage = "prologue"
	buildings = ["command_center", "geyser"]
	stimpack_unlocked = false
	academy_upgrades = {}
	has_experienced_first_death = false
	first_death_dialogue_pending = false
	has_seen_first_death_cinematic = false
	has_seen_mission_1_intro = false
	save_timestamp = ""
	if has_node("/root/GameManager"):
		get_node("/root/GameManager").has_suit_equipped = false
		get_node("/root/GameManager").sync_barracks_upgrades()

# Reiniciar una ranura a nueva partida y guardarla
func reset_slot_to_new_game(slot_id: int) -> void:
	current_slot = slot_id
	_reset_memory_state()
	save_timestamp = Time.get_datetime_string_from_system()
	save_data()

# Borrar una ranura definitivamente
func delete_slot(slot_id: int) -> void:
	var path = get_slot_path(slot_id)
	var gpath = ProjectSettings.globalize_path(path)
	var dir = DirAccess.open("user://")
	if dir:
		dir.remove(path.get_file())
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(gpath)
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
		
	if slot_id == 1:
		if dir:
			dir.remove(LEGACY_SAVE_PATH.get_file())
		if FileAccess.file_exists(LEGACY_SAVE_PATH):
			DirAccess.remove_absolute(ProjectSettings.globalize_path(LEGACY_SAVE_PATH))
		if FileAccess.file_exists(LEGACY_SAVE_PATH):
			DirAccess.remove_absolute(LEGACY_SAVE_PATH)
			
	if current_slot == slot_id:
		_reset_memory_state()

func load_data(slot_id: int = current_slot) -> void:
	var path = get_slot_path(slot_id)
	if slot_id == 1 and not FileAccess.file_exists(path) and FileAccess.file_exists(LEGACY_SAVE_PATH):
		path = LEGACY_SAVE_PATH
	
	if not FileAccess.file_exists(path):
		_reset_memory_state()
		return
	
	var file = FileAccess.open(path, FileAccess.READ)
	if file:
		var json_str = file.get_as_text()
		var parsed = JSON.parse_string(json_str)
		if parsed is Dictionary:
			total_kills = int(parsed.get("total_kills", 0))
			zergling_kills = int(parsed.get("zergling_kills", 0))
			total_minerals = int(parsed.get("total_minerals", 0))
			total_gas = int(parsed.get("total_gas", 0))
			highest_survive_time = float(parsed.get("highest_survive_time", 0.0))
			runs_played = int(parsed.get("runs_played", 0))
			selected_skin = "sd"
			
			var p = parsed.get("perks", {})
			if p is Dictionary:
				for k in perks.keys():
					if p.has(k):
						perks[k] = int(p[k])
			
			var ur = parsed.get("unlocked_ranks", [])
			if ur is Array:
				unlocked_ranks = ur
			
			var ach = parsed.get("unlocked_achievements", {})
			if ach is Dictionary:
				unlocked_achievements = ach
			
			story_stage = str(parsed.get("story_stage", "base_initial"))
			
			var b = parsed.get("buildings", ["command_center", "geyser"])
			if b is Array:
				buildings = b
			
			stimpack_unlocked = bool(parsed.get("stimpack_unlocked", false))
			
			var au = parsed.get("academy_upgrades", {})
			if au is Dictionary:
				academy_upgrades = au.duplicate()
			
			has_experienced_first_death = bool(parsed.get("has_experienced_first_death", false))
			first_death_dialogue_pending = bool(parsed.get("first_death_dialogue_pending", false))
			has_seen_first_death_cinematic = bool(parsed.get("has_seen_first_death_cinematic", false))
			has_seen_mission_1_intro = bool(parsed.get("has_seen_mission_1_intro", false))
			has_suit_equipped = bool(parsed.get("has_suit_equipped", false))
			if story_stage != "prologue" and story_stage != "base_initial":
				has_suit_equipped = true
			if has_node("/root/GameManager"):
				get_node("/root/GameManager").has_suit_equipped = has_suit_equipped
				get_node("/root/GameManager").selected_hero = str(parsed.get("selected_hero", "marine"))
				get_node("/root/GameManager").sync_barracks_upgrades()
			
			save_timestamp = str(parsed.get("timestamp", ""))

func save_data() -> void:
	is_dirty = false
	autosave_timer = 0.0
	var path = get_slot_path(current_slot)
	var file = FileAccess.open(path, FileAccess.WRITE)
	if file:
		save_timestamp = Time.get_datetime_string_from_system()
		var is_suit = has_suit_equipped
		if has_node("/root/GameManager"):
			var gm = get_node("/root/GameManager")
			is_suit = gm.has_suit_equipped or is_suit
			for k in gm.barracks_upgrades.keys():
				var g_lvl = int(gm.barracks_upgrades[k])
				if g_lvl > int(academy_upgrades.get(k, 0)):
					academy_upgrades[k] = g_lvl
		has_suit_equipped = is_suit
		var data = {
			"slot": current_slot,
			"timestamp": save_timestamp,
			"total_kills": total_kills,
			"zergling_kills": zergling_kills,
			"total_minerals": total_minerals,
			"total_gas": total_gas,
			"highest_survive_time": highest_survive_time,
			"runs_played": runs_played,
			"selected_skin": selected_skin,
			"perks": perks,
			"unlocked_ranks": unlocked_ranks,
			"unlocked_achievements": unlocked_achievements,
			"story_stage": story_stage,
			"buildings": buildings,
			"stimpack_unlocked": stimpack_unlocked,
			"academy_upgrades": academy_upgrades,
			"has_experienced_first_death": has_experienced_first_death,
			"first_death_dialogue_pending": first_death_dialogue_pending,
			"has_seen_first_death_cinematic": has_seen_first_death_cinematic,
			"has_seen_mission_1_intro": has_seen_mission_1_intro,
			"has_suit_equipped": has_suit_equipped,
			"selected_hero": (get_node("/root/GameManager").selected_hero if has_node("/root/GameManager") else "marine")
		}
		file.store_string(JSON.stringify(data, "\t"))

func trigger_player_death_event() -> void:
	if not has_experienced_first_death:
		has_experienced_first_death = true
		save_data()

# Story state helpers
func get_story_stage() -> String:
	return story_stage

func set_story_stage(new_stage: String) -> void:
	story_stage = new_stage
	save_data()

func has_building(b_id: String) -> bool:
	return buildings.has(b_id)

func add_building(b_id: String) -> void:
	if not buildings.has(b_id):
		buildings.append(b_id)
		save_data()

func is_stimpack_unlocked() -> bool:
	return stimpack_unlocked

func unlock_stimpack() -> void:
	stimpack_unlocked = true
	save_data()

func get_academy_upgrade_level(upg_id: String) -> int:
	return academy_upgrades.get(upg_id, 0)

func set_academy_upgrade_level(upg_id: String, lvl: int) -> void:
	academy_upgrades[upg_id] = lvl
	save_data()

func set_skin(skin_id: String) -> void:
	selected_skin = skin_id
	save_data()

func add_session_kills(kills: int) -> void:
	total_kills += kills
	save_data()

func add_zergling_kill() -> void:
	zergling_kills += 1
	save_data()
	check_realtime_achievements(0.0)

func is_achievement_unlocked(ach_id: String) -> bool:
	return unlocked_achievements.get(ach_id, false)

func unlock_achievement(ach_id: String) -> bool:
	if not unlocked_achievements.get(ach_id, false):
		unlocked_achievements[ach_id] = true
		save_data()
		var ach_data: Dictionary = {}
		for a in ACHIEVEMENTS_DEF:
			if a["id"] == ach_id:
				ach_data = a
				break
		emit_signal("achievement_unlocked", ach_id, ach_data)
		return true
	return false

func check_realtime_achievements(run_time: float) -> void:
	if zergling_kills >= 10 and not is_achievement_unlocked("firebat_unlock"):
		unlock_achievement("firebat_unlock")
	if zergling_kills >= 10 and not is_achievement_unlocked("mutalisk_glave_unlock"):
		unlock_achievement("mutalisk_glave_unlock")
	if (run_time >= 300.0 or highest_survive_time >= 300.0) and not is_achievement_unlocked("spider_mine_unlock"):
		unlock_achievement("spider_mine_unlock")
	if (run_time >= 600.0 or highest_survive_time >= 600.0) and not is_achievement_unlocked("ghost_sniper_unlock"):
		unlock_achievement("ghost_sniper_unlock")
	if (run_time >= 1200.0 or highest_survive_time >= 1200.0) and not is_achievement_unlocked("goliath_unlock"):
		unlock_achievement("goliath_unlock")
	if (run_time >= 1200.0 or highest_survive_time >= 1200.0) and not is_achievement_unlocked("survive_30_min"):
		unlock_achievement("survive_30_min")

func is_weapon_unlocked(w_id: String, current_run_time: float = 0.0) -> bool:
	match w_id:
		"c14_rifle":
			return true
		"firebat_flame":
			return is_achievement_unlocked("firebat_unlock")
		"spider_mine":
			return true
		"ghost_sniper":
			return is_achievement_unlocked("ghost_sniper_unlock") or highest_survive_time >= 600.0 or current_run_time >= 600.0
		"goliath":
			return is_achievement_unlocked("goliath_unlock") or highest_survive_time >= 1200.0 or current_run_time >= 1200.0
		"mutalisk_glave":
			return true
	return false

func add_minerals(minerals: int) -> void:
	total_minerals += minerals
	is_dirty = true

func add_gas(gas: int) -> void:
	total_gas += gas
	is_dirty = true

func spend_resources(minerals: int, gas: int) -> bool:
	if total_minerals >= minerals and total_gas >= gas:
		total_minerals -= minerals
		total_gas -= gas
		save_data()
		return true
	return false

func record_run_end(survive_time: float, session_kills: int, _session_minerals: int) -> void:
	runs_played += 1
	total_kills += session_kills
	# Nota: Los minerales ya se acumulan en tiempo real en total_minerals con SaveManager.add_minerals()
	if survive_time > highest_survive_time:
		highest_survive_time = survive_time
	save_data()

func get_current_rank() -> Dictionary:
	var current = RANK_MILESTONES[0]
	var next_m = RANK_MILESTONES[1]
	for i in range(RANK_MILESTONES.size()):
		var m = RANK_MILESTONES[i]
		if total_kills >= m["kills"]:
			current = m
			if i + 1 < RANK_MILESTONES.size():
				next_m = RANK_MILESTONES[i + 1]
			else:
				next_m = m
	return {
		"name": current["name"],
		"title": current["title"],
		"current_kills": total_kills,
		"milestone_kills": current["kills"],
		"next_milestone_kills": next_m["kills"],
		"progress": clampf(float(total_kills - current["kills"]) / max(1.0, float(next_m["kills"] - current["kills"])), 0.0, 1.0)
	}

func get_perk_level(perk_id: String) -> int:
	return perks.get(perk_id, 0)

func get_perk_cost(perk_id: String) -> int:
	if not PERKS_DEF.has(perk_id):
		return -1
	var lvl = get_perk_level(perk_id)
	var p = PERKS_DEF[perk_id]
	if lvl >= p["max_lvl"]:
		return -1
	return p["costs"][lvl]

func can_buy_perk(perk_id: String) -> bool:
	var cost = get_perk_cost(perk_id)
	return cost > 0 and total_gas >= cost

func buy_perk(perk_id: String) -> bool:
	if can_buy_perk(perk_id):
		var cost = get_perk_cost(perk_id)
		total_gas -= cost
		perks[perk_id] = get_perk_level(perk_id) + 1
		save_data()
		return true
	return false

func get_stat_bonus(stat: String) -> float:
	var lvl = get_perk_level(stat)
	match stat:
		"armor":
			return float(lvl)
		"damage":
			return lvl * 0.06
		"max_hp":
			return lvl * 0.15
		"regen":
			return lvl * 0.8
		"speed":
			return lvl * 0.08
		"magnet":
			return lvl * 0.25
	return 0.0
