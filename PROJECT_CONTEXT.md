# 🚀 GUÍA DE CONTEXTO DEL PROYECTO: STARCRAFT SURVIVORS (SC-SURVIVORS)

> **Documento maestro de contexto, arquitectura técnica y planificación para agentes de IA y desarrolladores.**
> Contiene toda la información técnica, narrativa, arquitectura de código, distribución de spritesheets, diseño de oleadas del Acto 1 y roadmap para las siguientes sesiones.

---

## 1. 🎯 Propósito del Juego y Visión General
- **Título**: *StarCraft: Survivors*
- **Motor**: Godot Engine 4.5.1 Stable (.NET/C++ Core con GDScript)
- **Género**: Roguelite Survivor (estilo *Vampire Survivors*) ambientado con fidelidad absoluta en el universo clásico de **StarCraft 1 (SD 1998 / Remastered)**.
- **Versión Actual**: **`v0.6`** (Alpha con versionado auto-incremental vía `sc-survivors/version.txt` y tags en GitHub).
- **Repositorio Oficial de GitHub**:
  `https://github.com/RoberNar/StarcraftSurvivors`
- **Ruta Local del Proyecto**: `c:\Users\toffe\Desktop\autocalabazas\sc-survivors\`
- **Ejecutable compilado**: `C:\Users\toffe\Desktop\SC_Survivors.exe`
- **Script de compilación y empaquetado**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\sc-survivors\build_game.ps1
  ```
- **Ruta de Guardado (Saves)**:
  `%APPDATA%\Godot\app_userdata\StarCraft- Survivors\save_slot_1.json`

---

## 2. 📖 Estructura Narrativa y Flujo de Juego (Acto 1)

### Fase 0: Prólogo (`scenes/prologue.tscn` / `scripts/prologue.gd`)
- El jugador viaja en un convoy confederado que sufre una emboscada y aterriza forzosamente en el planeta Sigma-4.
- Despierta como un civil desarmado entre escombros, esquiva el ataque inicial de Zerglings y evacúa en la nave de descenso táctico.
- **Comunicador Táctico de Radio**: El Capitán Hollis Voss transmite las órdenes de extracción en la esquina superior derecha mediante la consola de radio briefing con monitor CRT animado y retrato parlante.

### Fase 1: Puesto Avanzado / Base Terran (`scenes/terran_base.tscn` / `scripts/terran_base.gd`)
- Hub central de descanso, metaprogresión, compra de mejoras y conversación entre incursiones.
- **Diferenciación Espacial y Visual de Diálogos (Presencial vs. Radio)**:
  - **Hablar de Frente (Presencial en Base)**: Implementado mediante `FaceToFaceDialog` (`scenes/face_to_face_dialog.tscn`, `scripts/face_to_face_dialog.gd`). Se sitúa en la parte inferior de la pantalla (justo sobre la consola Terran). Usa el diseño original de pantallas de briefing de StarCraft 1: a la izquierda el monitor CRT con marco metálico (`tframe1`/`tframeh1`) y retrato parlante animado (`SCPortrait`), y a la derecha la pantalla de briefing metálica (`dialog_briefing_frame.png`) con ribete de neón naranja, encabezado en color oro/cian, texto autowrap, objetivo de misión y tecla de avance rápido `[ESPACIO / ENTER / CLIC] Continuar`.
  - **Hablar por Radio (Transmisión Remota)**: Implementado mediante `TransmissionComm` (`scenes/transmission_comm.tscn`). Aparece arriba a la derecha con el comunicador táctico de radio StarCraft, pitidos de transmisión y deslizamiento lateral para transmisiones tácticas en el páramo exterior (`main.tscn`), avisos de dropship (`prologue.tscn`) o alertas lejanas.
- **NPC Principal**: **Capitán Hollis Voss** (oficial veterano que da órdenes, autorizaciones y análisis táctico).
- **Armadura Marine CMC-300**: Se encuentra en un soporte al inicio (`story_stage == "base_initial"`). El jugador interactúa y se la equipa una sola vez. A partir de ese momento, `GameManager.has_suit_equipped = true` y queda guardado permanentemente en `SaveManager`.
- **Estructuras de la Base**:
  1. **Centro de Mando (Command Center)**: Núcleo de operaciones y radar perimetral.
  2. **Bahía de Ingeniería / Academia**: Terminal de mejoras permanentes globales (costos 100% en Gas Vespeno).
  3. **Cuartel (Barracks)**: Hangar de infantería y selección de armas.
  4. **Puerto Estelar**: Nave de descenso y extracción táctica hacia el exterior.

### Fase 2: Incursión Exterior en los Páramos (`scenes/main.tscn` / `scripts/main.gd`)
- Mapa exterior de combate, supervivencia y extracción en el planeta Sigma-4.
- **Despegue de la Nave de Evacuación (Misión 2+)**: A partir de la segunda misión, la nave de descenso (`EvacuationCircle`) enciende motores y despega volando hacia el espacio exterior inmediatamente apenas inicia la misión, sin mostrar transmisiones ni diálogos de texto ("no agregues ningún texto").
- **HUD Superior (`scripts/hud.gd`)**:
  - `minerals_label`: Muestra **`GameManager.session_minerals`** (EXP de la run) en tiempo real.
  - Temporizador (`time_label`): Cuenta el tiempo sobrevivido.
  - Barra de XP y Nivel en tiempo real.
- **Duración de Incursión y Clímax a los 20 Minutos (1200s)**:
  - Al alcanzar los 20:00 (1200 segundos), se dispara `_trigger_20min_climax()`.
  - Se limpian instantáneamente todos los enemigos comunes y peligros de espinas del mapa.
  - Emerge un **Canal Nydus Colosal** (`scenes/nydus_canal.tscn`) frente al Marine con sonido sísmico y advertencia del Capitán Voss.
  - **Retiro de la Nave de Evacuación**: Al emerger o entrar al Nydus, la nave de evacuación a la superficie se retira/destruye. No hay vuelta atrás ni escape posible; la única vía es derrotar al Torrasque en la caverna.
  - **Entrada al Nydus**: El jugador interactúa con `[E]` (o entra en la boca del canal) para descender a la Cueva del Jefe.
  - **Atajo de Desarrollo (Debug)**: Tecla `F9` en `main.gd` activa de inmediato el clímax y el Canal Nydus; `F9` en `terran_base.gd` teletransporta directamente a la cueva.

---

### Fase 3: Batalla de Jefe del Acto 1 - La Cueva Zerg y el Torrasque Ancestral

La pelea final del Acto 1 transcurre en una caverna subterránea claustrofóbica a la que se accede descendiendo por el Canal Nydus colosal. Representa el clímax narrativo y de combate, implementando un diseño de puzzle de combate sísmico, armadura reactiva y contención física estricta.

#### A. Arquitectura de la Escena (`scenes/boss_cave_arena.tscn` / `scripts/boss_cave_arena.gd`)
1. **Entorno y Renderizado**:
   - Centro geométrico fijado en `Vector2.ZERO` con radio de combate `ARENA_RADIUS = 460.0` px.
   - Textura de piso: Biomasa viva y Creep Zerg clásica de StarCraft (`assets/skins/sd/tiles/boss_cave_floor.png`, 1280x1280).
   - Anillo visual perimetral en `_draw()`: Múltiples arcos concéntricos con gradiente de oscuridad (de radio 450 a 496 px) que delimitan visualmente la pared de roca cavernosa y la sombra envolvente.

2. **Cámara Táctica Dinámica**:
   - En `_ready()`, se accede al nodo `Camera2D` del Marine y se interpola suavemente su zoom a `Vector2(0.62, 0.62)` con un tween amortiguado (`Tween.TRANS_SINE`).
   - Esto expande el campo de visión horizontal a ~1032 px y vertical a ~774 px, asegurando que el jugador visualice permanentemente los 6 pilares, al Torrasque, el perímetro de la caverna y la interfaz de consola sin puntos ciegos.

3. **Límites Físicos Infranqueables (Prevención de Salida y Túneles)**:
   - **Muros de contención perimetrales (`_setup_cave_boundary`)**: Se generan 36 bloques macizos de roca (`StaticBody2D`) con forma rectangular (`RectangleShape2D`) de **160 px de espesor** y ~90 px de longitud, dispuestos tangencialmente alrededor de la circunferencia de 460 px. Utilizan máscara y capa de colisión 7 (jugador, enemigos y proyectiles).
   - **Restricción matemática estricta (`_physics_process`)**:
     - Si `player.position.length() > ARENA_RADIUS - 16.0`: Se reubica instantáneamente en el borde interior normalizado y se resetea su vector de velocidad a cero.
     - Si `torrasque_boss.position.length() > ARENA_RADIUS - 30.0` (y no está en plena embestida): Se reubica de igual forma para evitar desplazamientos anómalos.
   - **Descarte de Evacuación en Superficie**: Al entrar a la cueva (y en el clímax del min 20), se destruye inmediatamente cualquier nodo en el grupo `evacuation_zone`. La única forma de salir con vida es destruyendo al Torrasque.

#### B. Mecánica Sísmica de los 6 Pilares Opuestos (`scenes/boss_pillar.tscn` / `scripts/boss_pillar.gd`)
1. **Modelado y Disposición Simétrica**:
   - Monolitos de roca mineral 2x3 extraídos de los doodads originales de la paleta Dirt de StarCraft SD (`assets/skins/sd/sprites/boss_pillar.png`).
   - Agrandados un 35% (`scale = Vector2(1.35, 1.35)`) con su sombra de suelo, caja de colisión circular (`radius = 24.0`) y sprite de escombros de desintegración (`boss_pillar_rubble.png`).
   - Distribución polar a radio constante `PILLAR_RADIUS = 280.0` px:
     - **Par 1 (Norte / Sur)**: Pilar 0 (`Vector2(0, -280)`) $\longleftrightarrow$ Pilar 3 (`Vector2(0, 280)`)
     - **Par 2 (Nororiente / Suroccidente)**: Pilar 1 (`Vector2(242.5, -140)`) $\longleftrightarrow$ Pilar 4 (`Vector2(-242.5, 140)`)
     - **Par 3 (Suroriente / Noroccidente)**: Pilar 2 (`Vector2(242.5, 140)`) $\longleftrightarrow$ Pilar 5 (`Vector2(-242.5, -140)`)

2. **Lógica de Equilibrio Sísmico (`on_pillar_hit_by_charge`)**:
   - **Destrucción exclusiva por embestida**: Los pilares son inmunes a los disparos del jugador y proyectiles comunes; solo la embestida recta a 460 px/s del Torrasque puede fracturarlos.
   - **Ciclo de Desbalance y Restablecimiento**:
     - **Primer pilar roto de un par**: Al colisionar el Torrasque contra un pilar en estado estable (`pending_opposite_id == -1`), la cueva entra en **DESBALANCE SÍSMICO**. Se registra `pending_opposite_id = pillar.opposite_id`. El pilar opuesto activa su marcador rotatorio en verde (`"▼ OPUESTO ▼"`), el HUD pasa a alerta roja, y el Torrasque entra en estado aturdido (Stun).
     - **Segundo pilar roto (Acierto)**: Si en la siguiente embestida el Torrasque impacta el pilar opuesto exacto (`hit_id == pending_opposite_id`), el equilibrio de la cueva se restablece (`pending_opposite_id = -1`), se apagan los marcadores de peligro, el HUD vuelve a `EQUILIBRIO: ESTABLE` y el Torrasque vuelve a quedar aturdido.
     - **Segundo pilar erróneo (Colapso Fatal de la Cueva)**: Si el Torrasque impacta un pilar distinto al opuesto requerido, se detona `_trigger_cave_collapse_cinematic()`:
       1. Bloqueo inmediato de controles del jugador y acciones del jefe.
       2. Transmisión radial de emergencia con estática de Hollis Voss: *"«¡FALLA ESTRUCTURAL TOTAL! ¡LA CAVERNA ESTÁ COLAPSANDO!»"*.
       3. Sacudida sísmica de pantalla violenta (`shake = 35.0`).
       4. Desprendimiento y caída parabólica masiva de 25 rocas del techo en cascada.
       5. Fundido a negro y detonación del Game Over por aplastamiento total.

#### C. Inteligencia y Máquina de Estados del Torrasque (`scenes/torrasque_boss.tscn` / `scripts/torrasque_boss.gd`)
1. **Máquina de Estados Finita (FSM)**:
   - `INTRO`: Emerge del suelo con sonido sísmico `nydus_emerge` y rugido `ultra_roar`, escalando de 0.3 a 1.5.
   - `CHASE`: Persigue activamente al Marine, ataca cuerpo a cuerpo y absorbe impactos para sobrecalentar armadura.
   - `TELEGRAPH_CHARGE`: Al alcanzar 100% de calor, se detiene durante 3 segundos para casteo; línea roja telégrafo sigue al jugador en tiempo real.
   - `CHARGING`: Embestida en línea recta a 460 px/s con estela de partículas de tierra hasta colisionar con un pilar, el jugador o la pared.
   - `STUNNED`: Aturdido durante 6 segundos tras destruir un pilar; su coraza se abre y recibe daño a su barra de salud.
   - `RECOVERING`: Transición de 0.5s donde restablece su armadura y enfría el calor a 0%.
   - `DEAD`: Cinemática de muerte zerg de 5 cuadros, liberación de recompensas y conclusión del combate.

2. **Ataques Físicos Melee Activos**:
   - **Rango y cadencia**: Rango de ataque `MELEE_RANGE = 85.0` px con tiempo de recuperación de `ATTACK_COOLDOWN = 0.75` s.
   - **Doble detección**: Se evalúa proximidad euclidiana y eventos directos de colisión en `move_and_slide()`.
   - **Daño y respuesta**: Ejecuta sonido `ultra_attack`, animación de ataque con cuchillas en 32 orientaciones clásicas de SC1, inflige **24 de daño** a la armadura/vida del Marine y aplica un impulso de retroceso (knockback de 130 px/s).
   - **Daño por arrollamiento durante carga**: Si cruza o impacta al jugador durante `CHARGING`, inflige **48 de daño** masivo y proyecta al Marine violentamente.

3. **Sistema de Armadura y Sobrecalentamiento**:
   - Durante `CHASE`, el Torrasque tiene `is_armored = true`. Cualquier bala o daño recibido no reduce sus puntos de vida; se transfiere a `armor_heat` (0.0 a 100.0) a razón de `damage * 0.95`.
   - El sprite del jefe modula cromáticamente de blanco/metálico hasta un naranja ígneo intenso conforme sube la temperatura.
   - Al llegar a 100% de calor, ruge y comienza el casteo de 3 segundos de embestida.
   - **Aturdimiento y Efecto Ragnarok Online**: Al colisionar contra un pilar, el Torrasque entra en estado `STUNNED` durante 4.0s: reproduce el efecto de sonido oficial de aturdimiento de Ragnarok Online (`boss_stun.wav`) y activa la corona de estrellitas doradas giratorias sobre su cabeza (`ro_stun_sheet.png`, 32 fotogramas en ciclo suave a 25 FPS). Las estrellitas usan `top_level = true` y modulación neutra independiente para no teñirse de rojo cuando el Ultralisco recibe daño o se calienta.
   - **Controles e Independencia de Stimpack**: La tecla `[ESPACIO]` (usada para inyección de Stimpack en combate) está disociada del salto de diálogos/transmisiones radiales (`TransmissionComm`), el cual solo responde a `[ENTER]` o clic del ratón. Esto evita cortar transmisiones de radio tácticas al combatir.

4. **Las 6 Barras de Vida Consecutivas**:
   - El jefe cuenta con `TOTAL_HEALTH_BARS = 6`, cada una con `BAR_MAX_HEALTH = 250.0` HP (salud total combinada: 1500 HP).
   - Solo es vulnerable mientras se encuentra en estado `STUNNED` (aturdido por estrellarse contra un pilar).
   - Al vaciarse una barra de 250 HP, se descuenta del contador (`health_bars_remaining -= 1`). Si aún quedan barras, el jefe se recupera, reactiva su armadura al 100% y reinicia el ciclo sísmico.

5. **Escalada de Oleadas Zerg**:
   - A través de `_on_zerg_spawn_tick()`, la caverna genera refuerzos cada 8 segundos proporcionales a los pilares destruidos:
     - Zerglings: `broken_pillars_count * 2` unidades.
     - Hidraliscos: `max(0, broken_pillars_count - 2)` unidades.

#### D. Interfaz del Jefe (`scenes/boss_hud.tscn` / `scripts/boss_hud.gd`)
- Anclada en la parte superior central con marco de consola táctica:
  - **Retrato animado**: Ícono del Ultralisco ancestral con scanline CRT.
  - **Contador de barras**: `BARRAS: X / 6` y cuadrícula visual de 6 bloques.
  - **Barra de salud actual**: Barra roja de 250 HP con valor numérico en tiempo real.
  - **Barra de calor de armadura**: Gradiente de gris a naranja con lectura de `CALOR DE ARMADURA: X%`.
  - **Monitor de estabilidad de la caverna**: Muestra `EQUILIBRIO: ESTABLE` en cian, o `¡ALERTA SÍSMICA! DERRIBA: [NOMBRE_PILAR_OPUESTO]` en rojo parpadeante con animación pulsante.
  - **Pilares restantes**: Muestra la cantidad de pilares aún intactos.

#### E. Resolución y Extracción
- Al vaciarse la 6ta barra de vida, el Torrasque colapsa definitivamente:
  - Se detiene el temporizador de oleadas zerg.
  - Se añade la baja de jefe a las estadísticas (`GameManager.add_boss_kill()`).
  - Suelta un contenedor de suministros de élite (`chest.tscn`) y 8 tanques de gas vespeno (`vespene_tank.tscn`).
  - **Descenso de la nave de rescate**: 2.5 segundos después de su muerte, aterriza la nave de evacuación (`evacuation_circle.tscn`) en el centro exacto de la cueva con sonido `dropship_ready` y aviso radial de Voss para regresar a la base con la victoria asegurada.

#### F. Atajos de Teclado para Desarrollo y Pruebas
- **`F9`**: Salto directo a la arena del jefe (funciona tanto desde la base de operaciones como durante la incursión de combate).
- **`F10`**: Derrota instantánea del Torrasque en la cueva para verificar la extracción y cinemáticas de fin de misión.

---

## 3. 📻 Sistema de Comunicación de Radio Táctico y Voces (Briefing Style)

Implementado en [`scenes/transmission_comm.tscn`](scenes/transmission_comm.tscn) y [`scripts/transmission_comm.gd`](scripts/transmission_comm.gd):
- **Diseño Visual**:
  - **Monitor de Cámara (Izquierda)**: Chasis metálico cuadrado oficial (`tframe_comm.png` derivado de `tframe1`) con retrato animado en tiempo real (`sc_portrait.gd`, 60x56 px por cuadro, 10 cuadros de reposo y 20 de habla) con sincronización labial y scanlines CRT.
  - **Panel de Órdenes (Derecha)**: Marco de consola oficial de StarCraft (`comm_text_frame.png` derivado de `objterr` invertido horizontalmente) con brazo mecánico articulado que desciende desde el borde superior derecho.
  - **Tamaño Balanceado**: ~270x104 px anclado en la esquina superior derecha, permitiendo lectura cómoda sin tapar la acción ni la consola inferior.
- **Despliegue y Funcionalidad**:
  - Deslizamiento lateral con amortiguación mecánica (`Tween.TRANS_BACK`) desde `x=660` a `x=368`.
  - Efecto de sonido oficial `transmission.wav` y reproducción de secuencias de diálogo en cola.
  - Omitible en cualquier momento mediante clic izquierdo sobre el panel o tecla de acción.
- **Diferenciación de Emisores y Actores**:
  1. **Operadora Terran (Adjutant)** (`advisor_portrait.png` / `assets/voices/ADVISOR/`):
     - Voz y alertas tácticas de combate durante las incursiones exteriores (`main.tscn`):
       - Spawners Zerglings (`ADJ_01`), destrucción de estructuras (`ADJ_02`), Guarida de Hidras (`ADJ_03`), Espira de Mutas (`ADJ_04`).
       - Oleadas sísmicas periódicas (`ADJ_05`, `ADJ_06`, `ADJ_07`, `ADJ_08`).
       - Frenesí tectónico a los 15 minutos (`ADJ_09`).
       - Clímax de los 20 minutos con emergencia del Canal Nydus colosal (`ADJ_10`).
  2. **Capitán Hollis Voss** (`civilian_portrait.png` / `assets/voices/VOSS/`):
     - Rescate inicial del prólogo bajo ataque (`VOSS_01`, `VOSS_02`).
     - Presentación formal en la base (`VOSS_00`: *«Soy el Capitán Hollis Voss, oficial al mando de este puesto de avanzada»*).
     - Diálogo presencial en base (`ARRIVAL_DIALOGUE`, `VOSS_03` a `VOSS_09`).
     - Instrucciones tácticas de armadura y recursos (`VOSS_10`, `VOSS_11`).
     - Reacciones ante derrotas y victorias (`VOSS_17` a `VOSS_21`, `VOSS_27`).
     - Misiones del NPC en base y construcción del Cuartel/Bahía (`VOSS_22` a `VOSS_25`, `VOSS_28`).
     - Extracción victoriosa tras abatir al Torrasque (`VOSS_26`).
  3. **Protagonista (Civil / Marine CMC-300)** (`assets/voices/PROTAG/`):
     - Reacciones de supervivencia en el prólogo (`PROTAG_01` a `PROTAG_05`).
     - Diálogo de llegada e intercambio con Voss (`PROTAG_06` a `PROTAG_12`).
     - Equiparse la armadura CMC (`PROTAG_13`) y asombro balístico al disparar (`PROTAG_14`).
     - Respuestas de misión, construcción y retorno (`PROTAG_15` a `PROTAG_21`).
- **Sistema de Audio (`scripts/audio_manager.gd`)**:
  - Soporte automático para archivos Vorbis `.ogg`, `.mp3` y `.wav`.
  - Mapeo directo y transparente de carpetas (`ADVISOR/`, `VOSS/`, `PROTAG/`) según el prefijo del ID.

---

## 4. 🌊 Sistema de Oleadas, Peligros Subterráneos y Rendimiento

### A. Ciclos de Oleadas de 2 Minutos (Wave Tiers)
Cada 2 minutos (`game_time / 120.0`), la biología Zerg muta a un nuevo escalón con armadura balística, salud incrementada y tintes cromáticos identificativos:

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

### B. Peligro Subterráneo del Enjambre: Espinas de Lurker (`scenes/lurker_spine_hazard.tscn`)
- **Mecánica**:
  - **Fase de Telégrafo**: Proyecta una franja roja translúcida en el suelo con chevrons direccionales avisando la trayectoria de erupción.
  - **Erupción Secuencial**: Brota una fila de espinas (`lurker_spikes.png`) con partículas de tierra, infligiendo daño balístico al contacto.
  - **Audio Original**: Sonidos `burrow_up.wav`, `lurker_fire.wav` y `lurker_hit.wav`.
- **Frecuencia y Frenesí**:
  - Oleadas tácticas periódicas cada 3 minutos (180s, 360s, 540s...).
  - **Frenesí de Espinas (Minutos 15 a 20 / 900s a 1200s)**: Erupciones continuas cada 3.2s como obstáculo de alta tensión en el endgame.
  - **Limpieza Instantánea**: Se eliminan de inmediato al activarse el clímax de los 20 minutos (`get_tree().call_group("lurker_hazards", "clear_immediately")`).

### C. Estructuras de Desove Zerg (`scenes/zerg_spawner_structure.tscn`)
- **Pozo de Zerglings (Minuto 5)**: Genera flujo acelerado de Zerglings hasta ser destruido.
- **Guarida de Hidraliscos (Minuto 10)**: Desova Hidraliscos de refuerzo.
- **Espira de Mutaliscos (Minuto 13)**: Amenaza aérea continua que debe ser derribada.

### D. Rendimiento y Optimización (60 FPS Fijos)
1. **Límite de Entidades Dinámico**: Controlado por `max_enemies` en `WaveConfig` (130-145 en inicio, 90-95 en endgame).
2. **Pausas Tácticas de 10s (Wave Lulls)**: Entre el segundo 110 y 120 de cada bloque de 2 minutos, el spawn se detiene silenciosamente.
3. **Cristal Mineral Arcoíris**: Absorción matemática instantánea de cristales fuera de pantalla (>380px) sin cálculos de colisión.
4. **Optimización de Guardado**: Flag `is_dirty` en `SaveManager` con guardado automático periódico cada 12 segundos.

---

## 5. ⚔️ Arsenal, Pasivas y Mejoras de la Base

### A. Armas en la Run (Hasta 3 secundarias simultáneas más Rifle principal)
1. **Rifle Gauss C-14 (`c14_rifle`)**: Arma balística principal. Proyectiles automáticos con auto-apuntado y saturación por multishot.
2. **Lanza-llamas Firebat (`firebat_flame`)**: Rediseño táctico de debuff: impacto directo muy bajo (4.0 HP), DoT de combustión prolongada (2.0 HP/0.35s durante 3.5s) y **reducción de armadura acumulativa** (-1 a -3+ según nivel). Utiliza el sprite auténtico de 12 frames de StarCraft 1 (`sc1_fire_loop.png`) limpio de errores de croma.
3. **Minas Araña Vulture (`spider_mine`)**: Minas móviles terrestres que persiguen y explotan en racimo con gran daño táctico.
4. **Rifle Francotirador Ghost C-10 (`ghost_sniper`)**: Balas balísticas de 25mm con penetración lineal y retícula animada.
5. **Glave Wurm Mutalisco (`mutalisk_glave`)**: Proyectiles parásitos bio-zerg con rebotes orgánicos entre objetivos.
6. **Tormenta Psiónica (`psionic_storm`)**: Descargas de energía psiónica errática que se desatan en la línea de visión del jugador. Alto daño masivo de área (38 HP/tick durante 2.2s) para compensar su dispersión imprecisa. Sprites auténticos de 14 frames de High Templar (`psistorm.png`) y SFX original (`psistorm.wav`).
7. **Easter Egg: Zumo de Limón (`lemon_juice`)**: Mini-explosión de ácido cítrico concentrado alrededor del jugador utilizando la animación de ataque parasitario de la Reina Zerg recoloreada a amarillo limón (`lemon_splash.png`). Deja al enemigo impregnado en baba corrosiva de Ensnare amarilla (`lemon_ensnare.png`) con DoT severo (8.0 HP/tick, 4x más fuerte que el fuego) y ralentización del 10% (escalable con mejoras).

### B. Pasivas en la Run (Hasta 6 simultáneas)
- `u238_shells` (+15% Daño balístico global y +1 penetración)
- `combat_shield` (+25% Vida Máxima y curación)
- `cadence` (+20% Velocidad de ataque)
- `multishot` (+1 Proyectil a todas las armas)
- `stimpack_upgrade` (+12% Velocidad y +1s Stimpack)
- `explosive_rounds` (+25% Radio AoE con explosiones al impactar)
- `magnetic_field` (+30% Radio de recolección de minerales)
- `medikit` (+3% Regeneración de vida/s y cura inmediata)

### C. Bahía de Ingeniería / Academia (Mejoras Permanentes con Gas Vespeno)
Todas las mejoras de metaprogresión permanente se investigan **exclusivamente con Gas Vespeno**, con costos iniciales económicos y escala progresiva.
Los cristales de mineral funcionan como la **representación gráfica de la Experiencia (EXP)** y recurso exclusivo de las runs en combate (sin requerir seguimiento ni acumulación persistente en la base).
Definidas en `BARRACKS_UPGRADES_DEF` en `scripts/game_manager.gd`:
1. **Armamento de Infantería (`damage`)**: +5% Daño a todas las armas por nivel (10 niveles, 2 a 68 Gas).
2. **Saturación Balística (`multishot`)**: +1 Proyectil a todas las armas por nivel (3 niveles, 8, 20, 45 Gas).
3. **Servomotores CMC (`speed`)**: +5% Velocidad de movimiento inicial por nivel (10 niveles, 1 a 50 Gas).
4. **Blindaje CMC (`armor`)**: +15 Vida Máxima y +1 Armadura base por nivel (10 niveles, 1 a 55 Gas).
5. **Estimulantes Sintéticos (`stim`)**: Desbloquea `[T]` Stimpack y amplía duración (5 niveles, 2 a 30 Gas).
6. **Botiquín Nanomédico (`regen`)**: +0.8 Regeneración de salud/s por nivel (10 niveles, 2 a 68 Gas).
7. **Condensador de Flujo (`magnet`)**: +18% Radio de atracción de minerales/EXP por nivel (10 niveles, 1 a 50 Gas).
8. **Excavación de Plasma (`mineral_efficiency`)**: +5% Experiencia (EXP) adicional obtenida por nivel (10 niveles, 2 a 68 Gas).
9. **Condensador de Vespeno (`vespene_doubler`)**: Duplica la extracción de Gas Vespeno por cada tanque en el mapa (x2 Gas, 25 Gas).

---

## 6. 🎨 Mapeo de Assets y Spritesheets

- **Carpeta de assets en Godot**: `sc-survivors/assets/skins/sd/`
- **Banco de assets de origen**: `C:\Users\toffe\Desktop\SCsurvivors\`
- **UI y Consola**:
  - `comm_text_frame.png`: Marco de órdenes invertido con brazo mecánico (215x104).
  - `tconsole.png`: Consola inferior oficial StarCraft: Remastered Widescreen (16:9, 960x175 / 1920x350) con radar a la izquierda, estado táctico al centro y panel de mando a la derecha.
  - `title.png`: Pantalla de título oficial StarCraft: Remastered Widescreen (16:9, 960x540).
  - `briefing.png`: Sala de briefing de operaciones.
- **Iconos de Armas (`sprites/weapon_icons.png`)**:
  - Slot 0: Rifle Gauss C-14
  - Slot 1: Lanza-llamas Firebat
  - Slot 2: Minas Araña Vulture
  - Slot 3: Francotirador Ghost C-10
  - Slot 4: Bio-arma Zerg Mutalisco (`mutalisk_glave`)
  - Slot 5: Tormenta Psiónica (icono clásico original de Alto Templario de StarCraft)
  - Slot 6: Zumo de Limón / Limo Corrosivo (Easter Egg)
  - Mejora Multishot: `tech_icons_clean.png` índice 6 con icono original de misiles dobles / proyectiles adicionales (`cmdicons` 290).
- **Spritesheets de Unidades y Héroes**:
  - Marine: `marine.png` (17 cols x 14 filas 64x64, muerte frames 221-228, restos `marine_remains.png`).
  - Médica Terran (Enfermera): `medic.png` (17 cols x 14 filas 64x64, muerte frames 221-228, sombra `medic_shadow.png`, retrato parlante animado 600x168 `medic_portrait.png`, wireframe `wire_medic.png`, SFX `medic_ready`, `medic_heal`, `medic_death`). Su animación de disparo utiliza la emisión y destello curativo de su brazo bio-médico.
  - Zergling: `zergling.png` (17 cols, restos `zergling_remains.png`).
  - Hidralisco: `hydralisk.png` (17 cols x 18 filas, muerte fila 12 cols 0-7, restos `hydralisk_remains.png`).
  - Mutalisco: `mutalisk.png` (17 cols x 6 filas, restos `mutalisk_remains.png`).
  - Drone: `drone.png` (17 cols x 23 filas, restos `drone_remains.png`).
  - Ultralisco: `ultralisk.png` (Jefe de gran tamaño con pisadas sísmicas).
  - Espinas de Lurker: `lurker_spikes.png` (7 cuadros de erupción secuencial).

---

## 7. 📦 Sistema de Versionado Auto-incremental

- **Versión Inicial**: `0.333` (Alpha).
- **Archivo de Configuración**: [`sc-survivors/version.txt`](sc-survivors/version.txt).
- **Mecanismo de Incremento**:
  - Administrado por `sc-survivors/build_game.ps1`.
  - Cada compilación empaqueta la versión actual (`SC_Survivors_v$Version.zip`) y avanza automáticamente el último dígito (`0.333` → `0.334` → `0.335`...) para la próxima sesión.
  - Sincronizado en la pantalla de título (`title_screen.gd`) y con tags en GitHub (`v0.333`).

---

## 8. 🗺️ Roadmap y Planificación de Próximas Sesiones

### Prioridad 1: Cierre del Acto 1
- [x] Corrección de lag con cristal arcoíris (eliminar I/O continuo y absorción instantánea).
- [x] Ritmo de oleadas con pausas tácticas de 10s cada 2 minutos.
- [x] Escalado de enemigos por Tiers con colores, salud y armadura real (Zerglings, Hidras, Mutas hasta T8).
- [x] Mejoras de Excavación de Plasma (+25% min) y Condensador de Vespeno (x2 gas).
- [x] Peligro de Espinas Subterráneas de Lurker y Frenesí de los minutos 15-20.
- [x] Comunicador Táctico de Radio estilo *briefing* con cámara del Capitán Voss.
- [x] Clímax de supervivencia balanceado a los 20 minutos (1200s) con emergencia del Canal Nydus.
- [x] Sistema de versionado auto-incremental desde `v0.333`.
- [ ] **Jefe Final del Acto 1**: Implementar el encuentro épico contra el Jefe del Acto 1 (mecánicas de combate, barra de salud de jefe, cinemática y condición de victoria).
- [ ] Efectos de impacto y sonido visual para el Rifle Francotirador Ghost.

### Prioridad 2: Acto 2 - Expansión de Biomas y Nuevas Amenazas Zerg
- [ ] Nuevo bioma volcánico (Char) con pozas de lava y cenizas.
- [ ] Nuevas unidades Zerg:
  - **Lurker completo (Unidad activa)**: Se entierra físicamente y lanza espinas hacia el jugador.
  - **Defiler (Envilecedor)**: Enjambre oscuro y nube tóxica que obliga a reposicionarse.
  - **Scourge (Plaga Zerg)**: Unidades aéreas suicidas de gran velocidad.
- [ ] Modo Asedio de Tanque Arclite (Torreta secundaria fija o vehículo desbloqueable en el Arsenal).

### Prioridad 3: Héroes y Clases Alternativas
- [ ] Héroe Firebat: Inicio con lanzallamas, armadura pesada y resistencia al fuego.
- [ ] Héroe Ghost: Inicio con rifle C-10, invisibilidad táctica temporal con energía.
- [ ] Héroe Protoss invitado (Zealot / Templario Tétrico): Escudos de plasma regenerables y cuchillas psiónicas.
