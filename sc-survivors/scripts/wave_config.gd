class_name WaveConfig
extends Node

## ==============================================================================
## CONFIGURACIÓN CENTRAL DE OLEADAS, APARICIÓN Y ESTADÍSTICAS ZERG
## ==============================================================================
## Puedes editar libremente los números en este archivo para ajustar el equilibrio:
## - "spawn_interval": Tiempo en segundos entre cada intento de aparición (menor = más rápido).
## - "batch_size": Cuántos enemigos nacen en cada intervalo (mayor = más enemigos por segundo).
## - "max_enemies": Límite máximo de entidades en pantalla en esa fase.
## - "weight": Probabilidad relativa de que aparezca ese tipo de enemigo (a mayor peso, más sale).
## - "ZERG_STATS": Vida (health), armadura (armor), daño (damage), velocidad (speed), escala y color (tint).
## ==============================================================================

# Pausas tácticas entre ciclos de oleadas (cada 2 minutos = 120s)
const CYCLE_DURATION: float = 120.0
const LULL_DURATION: float = 10.0   # Segundos de descanso al final de cada ciclo (seg 110 al 120)

# ==============================================================================
# TABLA DE OLEADAS POR MINUTO
# ==============================================================================
const WAVE_SCHEDULE: Array = [
	{
		"name": "Minuto 0 a 2: Enjambre Inicial Ligero",
		"minute_start": 0.0,
		"minute_end": 2.0,
		"spawn_interval": 0.35,     # Frecuencia rápida para que el inicio esté lleno de enemigos
		"batch_size": 3,            # 3 enemigos por tanda (~8.5 enemigos/seg)
		"max_enemies": 130,         # Límite amplio de pantalla para enemigos débiles
		"spawns": [
			{ "type": "drone", "tier": 1, "weight": 40 },
			{ "type": "zergling", "tier": 1, "weight": 60 }
		]
	},
	{
		"name": "Minuto 2 a 4: Vanguardia Hidralisco y Zerglings Bronce",
		"minute_start": 2.0,
		"minute_end": 4.0,
		"spawn_interval": 0.30,     # Aumento de densidad
		"batch_size": 4,            # 4 enemigos por tanda (~13 enemigos/seg)
		"max_enemies": 140,
		"spawns": [
			{ "type": "drone", "tier": 1, "weight": 15 },
			{ "type": "zergling", "tier": 1, "weight": 35 },
			{ "type": "zergling", "tier": 2, "weight": 35 },
			{ "type": "hydralisk", "tier": 1, "weight": 15 }
		]
	},
	{
		"name": "Minuto 4 a 6: Asalto Aéreo y Cazadores Púrpura",
		"minute_start": 4.0,
		"minute_end": 6.0,
		"spawn_interval": 0.28,     # Presión continua en el clímax del early game
		"batch_size": 4,            # 4 enemigos por tanda (~14 enemigos/seg)
		"max_enemies": 145,
		"spawns": [
			{ "type": "zergling", "tier": 2, "weight": 30 },
			{ "type": "zergling", "tier": 3, "weight": 35 },
			{ "type": "hydralisk", "tier": 1, "weight": 20 },
			{ "type": "mutalisk", "tier": 1, "weight": 15 }
		]
	},
	{
		"name": "Minuto 6 a 8: Marea Carmesí Salvaje",
		"minute_start": 6.0,
		"minute_end": 8.0,
		"spawn_interval": 0.32,
		"batch_size": 3,
		"max_enemies": 125,
		"spawns": [
			{ "type": "zergling", "tier": 3, "weight": 25 },
			{ "type": "zergling", "tier": 4, "weight": 35 },
			{ "type": "hydralisk", "tier": 2, "weight": 20 },
			{ "type": "mutalisk", "tier": 2, "weight": 20 }
		]
	},
	{
		"name": "Minuto 8 a 10: Tormenta Oscura (Zerglings Azules)",
		"minute_start": 8.0,
		"minute_end": 10.0,
		"spawn_interval": 0.38,
		"batch_size": 3,
		"max_enemies": 110,
		"spawns": [
			{ "type": "zergling", "tier": 5, "weight": 40 },
			{ "type": "hydralisk", "tier": 2, "weight": 30 },
			{ "type": "mutalisk", "tier": 2, "weight": 30 }
		]
	},
	{
		"name": "Minuto 10 a 12: Mutación Tóxica Ámbar (Élite Resistente)",
		"minute_start": 10.0,
		"minute_end": 12.0,
		"spawn_interval": 0.45,
		"batch_size": 2,
		"max_enemies": 95,          # Reducción de entidades para asegurar 60 FPS estables
		"spawns": [
			{ "type": "zergling", "tier": 6, "weight": 40 },
			{ "type": "hydralisk", "tier": 3, "weight": 30 },
			{ "type": "mutalisk", "tier": 3, "weight": 30 }
		]
	},
	{
		"name": "Minuto 12 a 14: Fuerza Titánica Esmeralda",
		"minute_start": 12.0,
		"minute_end": 14.0,
		"spawn_interval": 0.48,
		"batch_size": 2,
		"max_enemies": 90,
		"spawns": [
			{ "type": "zergling", "tier": 7, "weight": 40 },
			{ "type": "hydralisk", "tier": 4, "weight": 30 },
			{ "type": "mutalisk", "tier": 4, "weight": 30 }
		]
	},
	{
		"name": "Minuto 14+: Masa Crítica del Enjambre (Endgame Titánico)",
		"minute_start": 14.0,
		"minute_end": 999.0,
		"spawn_interval": 0.50,
		"batch_size": 2,
		"max_enemies": 90,
		"spawns": [
			{ "type": "zergling", "tier": 8, "weight": 35 },
			{ "type": "hydralisk", "tier": 5, "weight": 35 },
			{ "type": "mutalisk", "tier": 5, "weight": 30 }
		]
	}
]

# ==============================================================================
# ESTADÍSTICAS POR TIER Y ESPECIE ZERG
# ==============================================================================
const ZERG_STATS: Dictionary = {
	"zergling": {
		1: { "health": 18.0, "armor": 0.0, "damage": 5.0, "speed": 102.0, "scale": 0.80, "tint": Color(0.90, 0.70, 0.50, 1.0) }, # Marrón Clásico (0-2 min)
		2: { "health": 38.0, "armor": 1.0, "damage": 7.0, "speed": 110.0, "scale": 0.92, "tint": Color(1.00, 0.85, 0.65, 1.0) }, # Bronce Cazador (2-4 min)
		3: { "health": 85.0, "armor": 2.0, "damage": 10.0, "speed": 116.0, "scale": 1.05, "tint": Color(1.20, 0.65, 1.35, 1.0) }, # Púrpura Cazador (4-6 min)
		4: { "health": 190.0, "armor": 4.0, "damage": 13.0, "speed": 122.0, "scale": 1.20, "tint": Color(1.40, 0.45, 0.45, 1.0) }, # Carmesí Devorador (6-8 min)
		5: { "health": 420.0, "armor": 7.0, "damage": 16.0, "speed": 128.0, "scale": 1.32, "tint": Color(0.45, 0.75, 1.45, 1.0) }, # Azul Tormenta (8-10 min)
		6: { "health": 850.0, "armor": 11.0, "damage": 20.0, "speed": 134.0, "scale": 1.45, "tint": Color(1.45, 1.15, 0.35, 1.0) }, # Ámbar Mutante (10-12 min)
		7: { "health": 1600.0, "armor": 16.0, "damage": 25.0, "speed": 138.0, "scale": 1.55, "tint": Color(0.35, 1.45, 0.55, 1.0) }, # Esmeralda Nocivo (12-14 min)
		8: { "health": 2400.0, "armor": 20.0, "damage": 30.0, "speed": 142.0, "scale": 1.65, "tint": Color(1.50, 0.30, 0.80, 1.0) }  # Masa Crítica (14+ min)
	},
	"hydralisk": {
		1: { "health": 110.0, "armor": 2.0, "damage": 12.0, "speed": 80.0, "scale": 1.00, "tint": Color(1.00, 0.95, 0.90, 1.0) }, # Clásico Beige (2-6 min)
		2: { "health": 260.0, "armor": 5.0, "damage": 16.0, "speed": 85.0, "scale": 1.15, "tint": Color(1.20, 0.65, 1.35, 1.0) }, # Púrpura Cazador (6-10 min)
		3: { "health": 620.0, "armor": 10.0, "damage": 22.0, "speed": 90.0, "scale": 1.30, "tint": Color(1.40, 0.45, 0.45, 1.0) }, # Carmesí Devorador (10-12 min)
		4: { "health": 1300.0, "armor": 15.0, "damage": 28.0, "speed": 95.0, "scale": 1.45, "tint": Color(1.45, 1.15, 0.35, 1.0) }, # Ámbar Titán (12-14 min)
		5: { "health": 2400.0, "armor": 20.0, "damage": 35.0, "speed": 100.0, "scale": 1.60, "tint": Color(0.35, 1.45, 0.55, 1.0) }  # Esmeralda Nocivo (14+ min)
	},
	"mutalisk": {
		1: { "health": 85.0, "armor": 1.0, "damage": 9.0, "speed": 115.0, "scale": 1.00, "tint": Color(1.00, 0.95, 0.95, 1.0) }, # Clásico (4-6 min)
		2: { "health": 210.0, "armor": 4.0, "damage": 13.0, "speed": 120.0, "scale": 1.15, "tint": Color(1.40, 0.45, 0.45, 1.0) }, # Carmesí Voraz (6-10 min)
		3: { "health": 520.0, "armor": 8.0, "damage": 18.0, "speed": 126.0, "scale": 1.30, "tint": Color(0.45, 0.75, 1.45, 1.0) }, # Azul Tormenta (10-12 min)
		4: { "health": 1050.0, "armor": 14.0, "damage": 24.0, "speed": 132.0, "scale": 1.45, "tint": Color(1.45, 1.15, 0.35, 1.0) }, # Ámbar Titán (12-14 min)
		5: { "health": 2100.0, "armor": 18.0, "damage": 30.0, "speed": 138.0, "scale": 1.60, "tint": Color(0.35, 1.45, 0.55, 1.0) }  # Esmeralda Nocivo (14+ min)
	},
	"drone": {
		1: { "health": 14.0, "armor": 0.0, "damage": 4.0, "speed": 72.0, "scale": 1.00, "tint": Color.WHITE },
		2: { "health": 30.0, "armor": 1.0, "damage": 6.0, "speed": 78.0, "scale": 1.05, "tint": Color(1.0, 0.85, 0.7, 1.0) },
		3: { "health": 70.0, "armor": 3.0, "damage": 8.0, "speed": 84.0, "scale": 1.12, "tint": Color(0.85, 0.6, 1.0, 1.0) }
	}
}

# ==============================================================================
# MÉTODOS DE CONSULTA Y APOYO (ACCESIBLES DIRECTAMENTE)
# ==============================================================================

## Obtiene la configuración de la oleada correspondiente al minuto de juego
static func get_current_wave(game_time: float) -> Dictionary:
	var minutes = game_time / 60.0
	for wave in WAVE_SCHEDULE:
		if minutes >= wave["minute_start"] and minutes < wave["minute_end"]:
			return wave
	return WAVE_SCHEDULE[WAVE_SCHEDULE.size() - 1]

## Comprueba si el juego se encuentra en una pausa táctica (últimos 10s de cada ciclo de 2 min)
static func is_in_lull(game_time: float) -> bool:
	if game_time < 60.0:
		return false
	var cycle_time = fmod(game_time, CYCLE_DURATION)
	return cycle_time >= (CYCLE_DURATION - LULL_DURATION)

## Obtiene las estadísticas de un enemigo según su especie y tier
static func get_enemy_stats(enemy_type: String, tier: int) -> Dictionary:
	if not ZERG_STATS.has(enemy_type):
		return { "health": 25.0, "armor": 0.0, "damage": 5.0, "speed": 90.0, "scale": 1.0, "tint": Color.WHITE }
	
	var species_dict: Dictionary = ZERG_STATS[enemy_type]
	if species_dict.has(tier):
		return species_dict[tier]
	
	# Si se solicita un tier superior al definido, se toma el máximo y se extrapola
	var max_tier = 1
	for k in species_dict.keys():
		if int(k) > max_tier:
			max_tier = int(k)
	
	var base_data = species_dict[max_tier].duplicate()
	var diff = tier - max_tier
	base_data["health"] += diff * 350.0
	base_data["armor"] += diff * 2.0
	base_data["damage"] += diff * 3.0
	base_data["scale"] = clampf(base_data["scale"] + diff * 0.05, 1.0, 1.8)
	return base_data

## Selecciona un enemigo aleatorio basado en los pesos y tiers de la oleada activa
static func pick_random_enemy(game_time: float) -> Dictionary:
	var wave = get_current_wave(game_time)
	var spawns: Array = wave.get("spawns", [])
	if spawns.is_empty():
		return { "type": "zergling", "tier": 1 }
	
	var total_weight: float = 0.0
	for s in spawns:
		total_weight += s.get("weight", 1.0)
	
	var roll = randf() * total_weight
	var accum: float = 0.0
	for s in spawns:
		accum += s.get("weight", 1.0)
		if roll <= accum:
			return { "type": s.get("type", "zergling"), "tier": s.get("tier", 1) }
	
	return { "type": spawns[0].get("type", "zergling"), "tier": spawns[0].get("tier", 1) }
