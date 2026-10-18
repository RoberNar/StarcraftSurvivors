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
		"spawn_interval": 0.32,
		"batch_size": 2,
		"max_enemies": 95,
		"spawns": [
			{ "type": "drone", "tier": 1, "weight": 35 },
			{ "type": "zergling", "tier": 1, "weight": 65 }
		]
	},
	{
		"name": "Minuto 2 a 4: Vanguardia Hidralisco y Zerglings Bronce",
		"minute_start": 2.0,
		"minute_end": 4.0,
		"spawn_interval": 0.34,
		"batch_size": 3,
		"max_enemies": 115,
		"spawns": [
			{ "type": "drone", "tier": 1, "weight": 10 },
			{ "type": "zergling", "tier": 1, "weight": 35 },
			{ "type": "zergling", "tier": 2, "weight": 35 },
			{ "type": "hydralisk", "tier": 1, "weight": 20 }
		]
	},
	{
		"name": "Minuto 4 a 6: Asalto Aéreo y Plaga Suicida (Scourge)",
		"minute_start": 4.0,
		"minute_end": 6.0,
		"spawn_interval": 0.30,
		"batch_size": 3,
		"max_enemies": 130,
		"spawns": [
			{ "type": "zergling", "tier": 2, "weight": 30 },
			{ "type": "zergling", "tier": 3, "weight": 25 },
			{ "type": "hydralisk", "tier": 1, "weight": 20 },
			{ "type": "mutalisk", "tier": 1, "weight": 15 },
			{ "type": "scourge", "tier": 1, "weight": 10 }
		]
	},
	{
		"name": "Minuto 6 a 8: Asedio Pesado y Reinas del Enjambre",
		"minute_start": 6.0,
		"minute_end": 8.0,
		"spawn_interval": 0.32,
		"batch_size": 3,
		"max_enemies": 125,
		"spawns": [
			{ "type": "zergling", "tier": 3, "weight": 25 },
			{ "type": "hydralisk", "tier": 2, "weight": 20 },
			{ "type": "mutalisk", "tier": 2, "weight": 15 },
			{ "type": "scourge", "tier": 1, "weight": 15 },
			{ "type": "queen", "tier": 1, "weight": 15 },
			{ "type": "guardian", "tier": 1, "weight": 10 }
		]
	},
	{
		"name": "Minuto 8 a 10: Incursión de Corruptores (Devoradores) y Bombardeo Ácido",
		"minute_start": 8.0,
		"minute_end": 10.0,
		"spawn_interval": 0.38,
		"batch_size": 3,
		"max_enemies": 110,
		"spawns": [
			{ "type": "zergling", "tier": 3, "weight": 20 },
			{ "type": "zergling", "tier": 4, "weight": 15 },
			{ "type": "hydralisk", "tier": 2, "weight": 15 },
			{ "type": "devourer", "tier": 1, "weight": 15 },
			{ "type": "guardian", "tier": 1, "weight": 15 },
			{ "type": "queen", "tier": 1, "weight": 10 },
			{ "type": "scourge", "tier": 2, "weight": 10 }
		]
	},
	{
		"name": "Minuto 10 a 12: Enjambre Aéreo Élite Pesado",
		"minute_start": 10.0,
		"minute_end": 12.0,
		"spawn_interval": 0.42,
		"batch_size": 3,
		"max_enemies": 105,
		"spawns": [
			{ "type": "zergling", "tier": 4, "weight": 20 },
			{ "type": "hydralisk", "tier": 3, "weight": 15 },
			{ "type": "mutalisk", "tier": 3, "weight": 15 },
			{ "type": "devourer", "tier": 2, "weight": 15 },
			{ "type": "guardian", "tier": 2, "weight": 15 },
			{ "type": "queen", "tier": 2, "weight": 10 },
			{ "type": "scourge", "tier": 2, "weight": 10 }
		]
	},
	{
		"name": "Minuto 12 a 14: Fuerza Titánica de Asedio y Corrupción",
		"minute_start": 12.0,
		"minute_end": 14.0,
		"spawn_interval": 0.45,
		"batch_size": 2,
		"max_enemies": 95,
		"spawns": [
			{ "type": "zergling", "tier": 4, "weight": 15 },
			{ "type": "hydralisk", "tier": 3, "weight": 15 },
			{ "type": "devourer", "tier": 2, "weight": 20 },
			{ "type": "guardian", "tier": 2, "weight": 20 },
			{ "type": "queen", "tier": 2, "weight": 15 },
			{ "type": "scourge", "tier": 3, "weight": 15 }
		]
	},
	{
		"name": "Minuto 14+: Masa Crítica del Enjambre (Endgame Antes del Clímax)",
		"minute_start": 14.0,
		"minute_end": 999.0,
		"spawn_interval": 0.46,
		"batch_size": 2,
		"max_enemies": 95,
		"spawns": [
			{ "type": "zergling", "tier": 4, "weight": 15 },
			{ "type": "hydralisk", "tier": 4, "weight": 15 },
			{ "type": "mutalisk", "tier": 3, "weight": 15 },
			{ "type": "devourer", "tier": 3, "weight": 20 },
			{ "type": "guardian", "tier": 3, "weight": 20 },
			{ "type": "queen", "tier": 3, "weight": 15 }
		]
	}
]

# ==============================================================================
# ESTADÍSTICAS POR TIER Y ESPECIE ZERG
# ==============================================================================
const ZERG_STATS: Dictionary = {
	"zergling": {
		1: { "health": 18.0, "armor": 0.0, "damage": 5.0, "speed": 105.0, "scale": 0.80, "tint": Color(0.90, 0.70, 0.50, 1.0) }, # Marrón Clásico (0-2 min)
		2: { "health": 36.0, "armor": 1.0, "damage": 7.0, "speed": 112.0, "scale": 0.92, "tint": Color(1.00, 0.85, 0.65, 1.0) }, # Bronce Cazador (2-4 min)
		3: { "health": 75.0, "armor": 2.0, "damage": 9.0, "speed": 118.0, "scale": 1.05, "tint": Color(1.20, 0.65, 1.35, 1.0) }, # Púrpura Cazador (4-8 min)
		4: { "health": 140.0, "armor": 3.0, "damage": 12.0, "speed": 125.0, "scale": 1.15, "tint": Color(1.40, 0.45, 0.45, 1.0) }  # Carmesí Ágil (8+ min)
	},
	"hydralisk": {
		1: { "health": 110.0, "armor": 2.0, "damage": 12.0, "speed": 80.0, "scale": 1.00, "tint": Color(1.00, 0.95, 0.90, 1.0) }, # Clásico Beige
		2: { "health": 240.0, "armor": 4.0, "damage": 15.0, "speed": 85.0, "scale": 1.15, "tint": Color(1.20, 0.65, 1.35, 1.0) }, # Púrpura Cazador
		3: { "health": 480.0, "armor": 7.0, "damage": 20.0, "speed": 90.0, "scale": 1.30, "tint": Color(1.40, 0.45, 0.45, 1.0) }, # Carmesí Devorador
		4: { "health": 850.0, "armor": 10.0, "damage": 26.0, "speed": 95.0, "scale": 1.45, "tint": Color(1.45, 1.15, 0.35, 1.0) }  # Ámbar Titán
	},
	"mutalisk": {
		1: { "health": 85.0, "armor": 1.0, "damage": 9.0, "speed": 115.0, "scale": 1.00, "tint": Color(1.00, 0.95, 0.95, 1.0) }, # Clásico
		2: { "health": 190.0, "armor": 3.0, "damage": 13.0, "speed": 120.0, "scale": 1.15, "tint": Color(1.40, 0.45, 0.45, 1.0) }, # Carmesí Voraz
		3: { "health": 380.0, "armor": 6.0, "damage": 18.0, "speed": 126.0, "scale": 1.30, "tint": Color(0.45, 0.75, 1.45, 1.0) }, # Azul Tormenta
		4: { "health": 650.0, "armor": 9.0, "damage": 24.0, "speed": 132.0, "scale": 1.45, "tint": Color(1.45, 1.15, 0.35, 1.0) }  # Ámbar Titán
	},
	"drone": {
		1: { "health": 14.0, "armor": 0.0, "damage": 4.0, "speed": 72.0, "scale": 1.00, "tint": Color.WHITE },
		2: { "health": 28.0, "armor": 1.0, "damage": 6.0, "speed": 78.0, "scale": 1.05, "tint": Color(1.0, 0.85, 0.7, 1.0) }
	},
	"scourge": {
		1: { "health": 28.0, "armor": 0.0, "damage": 26.0, "speed": 185.0, "scale": 1.00, "tint": Color.WHITE },
		2: { "health": 45.0, "armor": 0.0, "damage": 34.0, "speed": 195.0, "scale": 1.10, "tint": Color(1.2, 0.7, 0.7, 1.0) },
		3: { "health": 65.0, "armor": 1.0, "damage": 44.0, "speed": 205.0, "scale": 1.20, "tint": Color(1.4, 0.4, 0.4, 1.0) }
	},
	"queen": {
		1: { "health": 280.0, "armor": 1.0, "damage": 12.0, "speed": 95.0, "scale": 1.00, "tint": Color.WHITE },
		2: { "health": 450.0, "armor": 2.0, "damage": 16.0, "speed": 100.0, "scale": 1.15, "tint": Color(0.85, 1.2, 0.85, 1.0) },
		3: { "health": 680.0, "armor": 3.0, "damage": 20.0, "speed": 105.0, "scale": 1.25, "tint": Color(0.4, 1.4, 0.7, 1.0) }
	},
	"guardian": {
		1: { "health": 380.0, "armor": 2.0, "damage": 22.0, "speed": 62.0, "scale": 1.00, "tint": Color.WHITE },
		2: { "health": 620.0, "armor": 4.0, "damage": 28.0, "speed": 66.0, "scale": 1.15, "tint": Color(1.3, 0.8, 0.5, 1.0) },
		3: { "health": 950.0, "armor": 6.0, "damage": 36.0, "speed": 70.0, "scale": 1.25, "tint": Color(1.45, 0.5, 0.3, 1.0) }
	},
	"devourer": {
		1: { "health": 480.0, "armor": 3.0, "damage": 16.0, "speed": 75.0, "scale": 1.00, "tint": Color.WHITE },
		2: { "health": 780.0, "armor": 5.0, "damage": 22.0, "speed": 80.0, "scale": 1.15, "tint": Color(0.8, 0.5, 1.3, 1.0) },
		3: { "health": 1200.0, "armor": 7.0, "damage": 28.0, "speed": 85.0, "scale": 1.25, "tint": Color(0.9, 0.3, 1.4, 1.0) }
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
