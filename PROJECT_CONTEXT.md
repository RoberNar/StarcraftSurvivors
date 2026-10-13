# 🚀 GUÍA DE CONTEXTO DEL PROYECTO: STARCRAFT SURVIVORS (SC-SURVIVORS)

> **Documento maestro de contexto, arquitectura técnica y planificación para agentes de IA y desarrolladores.**
> Contiene toda la información técnica, narrativa, arquitectura de código, distribución de spritesheets, diseño de oleadas del Acto 1 y roadmap para las siguientes sesiones.

---

## 1. 🎯 Propósito del Juego y Visión General
- **Título**: *StarCraft: Survivors*
- **Motor**: Godot Engine 4.5.1 Stable (.NET/C++ Core con GDScript)
- **Género**: Roguelite Survivor (estilo *Vampire Survivors*) ambientado con fidelidad absoluta en el universo clásico de **StarCraft 1 (SD 1998 / Remastered)**.
- **Repositorio Oficial de GitHub**:
  `https://github.com/RoberNar/StarcraftSurvivors`
- **Ruta Local del Proyecto**: `c:\Users\toffe\Desktop\autocalabazas\sc-survivors\`
- **Ejecutable compilado**: `C:\Users\toffe\Desktop\SC_Survivors.exe`
- **Script de compilación rápida**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\build_game.ps1
  ```
- **Ruta de Guardado (Saves)**:
  `%APPDATA%\Godot\app_userdata\StarCraft- Survivors\save_slot_1.json`

---

## 2. 📖 Estructura Narrativa y Flujo de Juego (Acto 1)

### Fase 0: Prólogo (`scenes/prologue.tscn` / `scripts/prologue.gd`)
- El jugador viaja en un convoy confederado que sufre una emboscada y aterriza forzosamente en el planeta Sigma-4.
- Despierta como un civil desarmado entre escombros y se arrastra hasta el refugio subterráneo guiado por una baliza de socorro.

### Fase 1: Puesto Avanzado / Base Terran (`scenes/terran_base.tscn` / `scripts/terran_base.gd`)
- Hub central de descanso, metaprogresión, compra de mejoras y conversación entre incursiones.
- **NPC Principal**: **Capitán Hollis Voss** (oficial veterano que da órdenes y autorizaciones).
- **Armadura Marine CMC-300**: Se encuentra en un soporte al inicio (`story_stage == "base_initial"`). El jugador interactúa y se la equipa. A partir de ese momento, `GameManager.has_suit_equipped = true` y queda guardado permanentemente en `SaveManager`.
- **Estructuras de la Base**:
  1. **Centro de Mando (Command Center)**: Núcleo de operaciones y radar perimetral.
  2. **Bahía de Ingeniería / Academia**: Terminal de mejoras permanentes globales.
  3. **Cuartel (Barracks)**: Hangar de infantería y selección de armas.
  4. **Puerto Estelar**: Nave de descenso y extracción táctica.
- **Misiones del Acto 1**:
  - **Misión 1**: Reconocimiento y Purga (Eliminar 100 Zerglings).
  - **Misión 2**: Suministro de Gas Vespeno (Recolectar 10 tanques con balizas en radar).
  - **Misión 3**: El Titán del Enjambre (Eliminar 200 enemigos y abatir al Ultralisco gigante).
  - **Misión 4**: Extracción y Supervivencia (Recolectar 20 tanques y resistir la marea Zerg).

### Fase 2: Incursión Exterior en los Páramos (`scenes/main.tscn` / `scripts/main.gd`)
- Mapa exterior de combate y supervivencia.
- **HUD Superior (`scripts/hud.gd`)**:
  - `minerals_label`: Muestra **`GameManager.session_minerals`** en tiempo real.
  - Temporizador (`time_label`): Cuenta el tiempo sobrevivido.
  - Barra de XP y Nivel en tiempo real.
- **Condición de Victoria / Evacuación**:
  - Al completar el objetivo, se activa el círculo de evacuación (`scenes/evacuation_circle.tscn`). Entrar permite regresar a la base conservando todos los recursos.
- **Muerte en Combate**:
  - Animación de muerte auténtica de marine (8 frames) y esqueleto en el suelo. Diálogos contextuales con el Capitán Voss según si completó o no el objetivo antes de caer.

---

## 3. 🌊 Sistema de Oleadas Tácticas, Respiros y Rendimiento

Para evitar que a partir del minuto 10 el juego se llene de cientos de enemigos frágiles que saturan la CPU, se implementó una arquitectura basada en **ritmo táctico, escalado cualitativo y límite estricto de entidades**:

### A. Ciclos de Oleadas de 2 Minutos (Wave Tiers)
Cada 2 minutos (`game_time / 120.0`), la biología Zerg muta a un nuevo escalón con salud incrementada, armadura balística y tintes cromáticos identificativos:

| Minuto | Ciclo | Composición Principal | Tiers y Colores Zerg | Salud / Armadura |
|---|---|---|---|---|
| **0:00 - 2:00** | 0 | 50% Drones, 50% Zerglings | Tier 1 (Clásico Marrón) | HP 15 / Armadura 0 |
| **2:00 - 4:00** | 1 | 20% Hidraliscos, 55% Zerglings T2, Drones | Tier 2 (Bronce Cobrizo) | Zergling HP 32 / Arm 1, Hidra HP 110 / Arm 2 |
| **4:00 - 6:00** | 2 | 22% Mutaliscos, 23% Hidras, 55% Zerglings T3 | Tier 3 (Púrpura Cazador) | Zergling HP 75 / Arm 2, Muta HP 85 / Arm 1 |
| **6:00 - 8:00** | 3 | 25% Mutaliscos, 25% Hidras T2, Zerglings T4 | Tier 4 (Carmesí Devorador) | Zergling HP 160 / Arm 4, Hidra HP 280 / Arm 5 |
| **8:00 - 10:00** | 4 | 30% Mutas, 30% Hidras T2, Zerglings T5 | Tier 5 (Azul Tormenta) | Zergling HP 480 / Arm 7, Muta HP 220 / Arm 4 |
| **10:00 - 12:00** | 5 | 32% Mutas T3, 32% Hidras T3, Zerglings T6 | Tier 6 (Ámbar Mutante Tóxico) | Zergling HP 950 / Arm 11, Hidra HP 680 / Arm 10, Muta HP 550 / Arm 8 |
| **12:00 - 14:00** | 6 | 35% Mutas T4, 35% Hidras T4, Zerglings T7 | Tier 7 (Esmeralda Nocivo / Titán) | Zergling HP 1800 / Arm 16, Hidra HP 1400 / Arm 15, Muta HP 1100 / Arm 14 |
| **14:00+** | 7+ | Enjambre Titánico de Alta Resistencia | Tier 8+ (Masa Crítica) | HP 2500+ / Armadura 20+ |

### B. Archivo de Configuración Central (`scripts/wave_config.gd`)
Todas las variables de spawn y estadísticas Zerg están centralizadas en `WaveConfig` para fácil edición manual:
- **`WAVE_SCHEDULE`**: Array editable con cada franja de minutos, `spawn_interval` (frecuencia), `batch_size` (cantidad por tanda), `max_enemies` (tope en pantalla) y la lista de `spawns` con sus pesos (`weight`) y `tier`.
  - **Minuto 0 a 6 (Fase Inicial Intensa)**: Mayor densidad y velocidad de desove (`spawn_interval` de 0.28s a 0.35s, lotes de 3-4 enemigos y tope de hasta 145 en pantalla) para que la partida arranque con una gran masa de Zerglings y Drones que se eliminan rápidamente.
  - **Minuto 10+ (Fase Estratégica)**: Frecuencia de 0.45s a 0.50s, lotes de 2 y tope de 95 enemigos con armaduras elevadas para proteger el rendimiento a 60 FPS.
- **`ZERG_STATS`**: Diccionario editable con `health`, `armor`, `damage`, `speed`, `scale` y `tint` de cada tier para Zerglings, Hidraliscos, Mutaliscos y Drones.

### C. Pausas Tácticas de 10 Segundos Silenciosas (Wave Lulls)
- Al final de cada ciclo de 2 minutos (entre el segundo 110 y 120 de cada bloque de 120s), el desove de enemigos se **pausa silenciosamente** (sin carteles ni burbujas de texto en pantalla).
- Permite limpiar a los rezagados, recolectar recursos en el suelo y prepararse para la siguiente mutación del enjambre.

### D. Rendimiento y Optimización (60 FPS Fijos)
1. **Límite de Entidades Dinámico**: Controlado por `max_enemies` en `WaveConfig` (130-145 en el early game de baja carga y 90-95 en el endgame de alta carga).
2. **Generación por Lotes Suave**: Grupos controlados por `batch_size` en `WaveConfig` en lugar de oleadas síncronas masivas.
3. **Optimización de Guardado (SaveManager)**: Flag `is_dirty` con guardado automático periódico (cada 12 segundos) en lugar de accesos síncronos a disco por cada cristal.
4. **Cristal Mineral Arcoíris (Efecto Aspiradora)**: Absorción matemática instantánea de cristales fuera de pantalla (>380px) y vuelo directo sin cálculo de colisiones.
5. **Throttling de Sonido (AudioManager / Mineral)**: Limitador de frecuencia a 55ms para evitar saturación de canales de audio.

---

## 4. ⚔️ Arsenal, Pasivas y Mejoras de la Base

### A. Armas en la Run (Hasta 3 simultáneas)
1. **Rifle Gauss C-14 (`c14_rifle`)**: Proyectiles automáticos de alta cadencia.
2. **Lanza-llamas Firebat (`firebat_flame`)**: Conos de fuego continuo en abanico con daño en área.
3. **Minas Araña Vulture (`spider_mine`)**: Minas móviles terrestres que persiguen y explotan en racimo.
4. **Rifle Francotirador Ghost C-10 (`ghost_sniper`)**: Balas balísticas de 25mm con penetración lineal y retícula animada.
5. **Glave Wurm Mutalisco (`mutalisk_glave`)**: Proyectiles parásitos bio-zerg con rebotes orgánicos entre objetivos.

### B. Pasivas en la Run (Hasta 6 simultáneas)
- `u238_shells` (+15% Daño balístico global y +1 penetración)
- `combat_shield` (+25% Vida Máxima y curación)
- `cadence` (+20% Velocidad de ataque)
- `multishot` (+1 Proyectil a todas las armas)
- `stimpack_upgrade` (+12% Velocidad y +1s Stimpack)
- `explosive_rounds` (+25% Radio AoE con explosiones al impactar)
- `magnetic_field` (+30% Radio de recolección de minerales)
- `medikit` (+3% Regeneración de vida/s y cura inmediata)

### C. Bahía de Ingeniería / Academia (Mejoras Permanentes Guardadas)
Definidas en `BARRACKS_UPGRADES_DEF` en `scripts/game_manager.gd`:
1. **Armamento de Infantería (`damage`)**: +5% Daño a todas las armas por nivel (10 niveles).
2. **Saturación Balística (`multishot`)**: +1 Proyectil a todas las armas por nivel (3 niveles: 250, 500, 1000 min).
3. **Servomotores CMC (`speed`)**: +5% Velocidad de movimiento inicial por nivel (10 niveles).
4. **Blindaje CMC (`armor`)**: +15 Vida Máxima y +1 Armadura base por nivel (10 niveles).
5. **Estimulantes Sintéticos (`stim`)**: Desbloquea `[T]` Stimpack y amplía duración (5 niveles).
6. **Botiquín Nanomédico (`regen`)**: +0.8 Regeneración de salud/s por nivel (10 niveles).
7. **Condensador de Flujo (`magnet`)**: +18% Radio de atracción de minerales por nivel (10 niveles).
8. **Excavación de Plasma (`mineral_efficiency`)**: +25% Minerales extra obtenidos por cada cristal recogido por nivel (5 niveles).
9. **Condensador de Vespeno (`vespene_doubler`)**: Duplica la extracción de Gas Vespeno recolectado por cada bidón en el mapa (x2 Gas, 1 nivel).

---

## 5. 🎨 Mapeo de Assets y Spritesheets

- **Carpeta de assets en Godot**: `sc-survivors/assets/skins/sd/`
- **Iconos de Armas (`sprites/weapon_icons.png`)**:
  - Slot 0 (x=0): Rifle Gauss C-14
  - Slot 1 (x=48): Lanza-llamas Firebat
  - Slot 2 (x=96): Minas Araña Vulture
  - Slot 3 (x=144): Francotirador Ghost C-10
  - Bio-arma Zerg Mutalisco: `assets/skins/sd/sprites/mutalisk_glave_icon.png`
- **Iconos Tecnológicos (`sprites/tech_icons_clean.png`)**:
  - Slot 0: Campo Magnético / Excavación de Plasma
  - Slot 1: Estimulantes Sintéticos
  - Slot 2: Blindaje de Combate
  - Slot 3: Balas U-238
  - Slot 4: Cadencia Gauss
  - Slot 5: Balas Explosivas / Condensador de Vespeno
  - Slot 6: Disparo Múltiple
  - Slot 7: Botiquín Nanomédico
- **Spritesheets de Unidades**:
  - Marine: `marine.png` (17 cols x 128x128, muerte frames 221-228, restos `marine_remains.png`).
  - Zergling: `zergling.png` (17 cols, restos `zergling_remains.png`).
  - Hidralisco: `hydralisk.png` (17 cols x 18 filas, muerte fila 12 cols 0-7, restos `hydralisk_remains.png`).
  - Mutalisco: `mutalisk.png` (17 cols x 6 filas, restos `mutalisk_remains.png`).
  - Drone: `drone.png` (17 cols x 23 filas, muerte col 0 filas 10-17, restos `drone_remains.png`).
  - Ultralisco: `ultralisk.png` (Jefe con escala dinámica y pisadas sísmicas).

---

## 6. 🗺️ Roadmap y Planificación de Próximas Sesiones

### Prioridad 1: Acto 1 Pulido & Sensación de Impacto
- [x] Corrección de lag con cristal arcoíris (eliminar I/O continuo y absorber fuera de pantalla).
- [x] Ritmo de oleadas con pausas tácticas de 10s cada 2 minutos.
- [x] Escalado de enemigos por Tiers con colores, salud y armadura real (Zerglings, Hidras, Mutas hasta T7+).
- [x] Dos nuevas mejoras en la Bahía de Ingeniería: Minerales extra (+25%/nv) y Gas Vespeno x2.
- [x] Migración del repositorio a `https://github.com/RoberNar/StarcraftSurvivors`.
- [ ] Efectos de impacto y sonido visual para el Rifle Francotirador Ghost (feedback háptico/flash).
- [ ] Balance fino de costes de mejoras y duración de runs.

### Prioridad 2: Acto 2 - Expansión de Biomas y Nuevas Amenazas Zerg
- [ ] Nuevo bioma volcánico (Char) con pozas de lava y cenizas.
- [ ] Nuevas unidades Zerg:
  - **Lurker (Merodeador)**: Se entierra y lanza espinas lineales de daño penetrante en masa.
  - **Defiler (Envilecedor)**: Lanza enjambre oscuro y nube tóxica que obliga a moverse.
  - **Scourge (Plaga Zerg)**: Unidades aéreas suicidas de gran velocidad.
- [ ] Modo Asedio de Tanque Arclite (Torreta secundaria fija o vehículo desbloqueable en el Arsenal).

### Prioridad 3: Héroes y Clases Alternativas
- [ ] Héroe Firebat: Inicio con lanzallamas, armadura pesada, menor velocidad pero alta resistencia al fuego.
- [ ] Héroe Ghost: Inicio con rifle C-10, invisibilidad táctica temporal con energía.
- [ ] Héroe Protoss invitado (Zealot / Templario Tétrico): Escudos de plasma regenerables y cuchillas psiónicas.
