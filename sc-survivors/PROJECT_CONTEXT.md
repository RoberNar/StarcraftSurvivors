# 🚀 GUÍA DE CONTEXTO DEL PROYECTO: STARCRAFT SURVIVORS (SC-SURVIVORS)

> **Documento maestro de contexto, arquitectura técnica y planificación para agentes de IA y desarrolladores.**
> Contiene toda la información técnica, narrativa, arquitectura de código, distribución de spritesheets, diseño de oleadas del Acto 1 y roadmap para las siguientes sesiones.

---

## 1. 🎯 Propósito del Juego y Visión General
- **Título**: *StarCraft: Survivors*
- **Motor**: Godot Engine 4.5.1 Stable (.NET/C++ Core con GDScript)
- **Género**: Roguelite Survivor (estilo *Vampire Survivors*) ambientado con fidelidad absoluta en el universo clásico de **StarCraft 1 (SD 1998 / Remastered)**.
- **Versión Actual**: **`v0.333`** (Alpha con versionado auto-incremental vía `sc-survivors/version.txt` y tags en GitHub).
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
### Fase 2: Incursión Exterior en los Páramos (`scenes/main.tscn` / `scripts/main.gd`)
- Mapa exterior de combate, supervivencia y extracción en el planeta Sigma-4.
- **HUD Superior (`scripts/hud.gd`)**:
  - `minerals_label`: Muestra **`GameManager.session_minerals`** (EXP de la run) en tiempo real.
  - Temporizador (`time_label`): Cuenta el tiempo sobrevivido.
  - Barra de XP y Nivel en tiempo real.
- **Duración de Incursión y Clímax a los 20 Minutos (1200s)**:
  - Al alcanzar los 20:00 (1200 segundos), se dispara `_trigger_20min_climax()`.
  - Se limpian instantáneamente todos los enemigos comunes y peligros de espinas del mapa.
  - Emerge un **Canal Nydus Colosal** (`scenes/nydus_canal.tscn`) frente al Marine con sonido sísmico y advertencia del Capitán Voss.
  - **Entrada al Nydus**: El jugador interactúa con `[E]` (o entra en la boca del canal) para descender a la Cueva del Jefe.
  - **Atajo de Desarrollo (Debug)**: Tecla `F9` en `main.gd` activa de inmediato el clímax y el Canal Nydus; `F9` en `terran_base.gd` teletransporta directamente a la cueva.

---

### Fase 3: Batalla de Jefe del Acto 1 - La Cueva Zerg (`scenes/boss_cave_arena.tscn` / `scripts/boss_cave_arena.gd`)
- **Entorno de la Cueva ("Cueva Zerg")**:
  - Zona cavernosa cerrada con suelo orgánico de Creep Zerg y bordes carnosos auténticos (`boss_cave_bg.png`, 1024x574) con barrera física elíptica (centro en `529, 305`, radios 335x235px).
- **Los 6 Pilares en Pares Opuestos (`scenes/boss_pillar.tscn` / `scripts/boss_pillar.gd`)**:
  - Posiciones exactas mapeadas del diseño de la arena:
    - **Par 1 (Verde)**: Pilar 0 (Norte: `531, 167`) <---> Pilar 3 (Sur: `526, 455`)
    - **Par 2 (Rojo)**: Pilar 1 (Nororiente: `660, 214`) <---> Pilar 4 (Suroccidente: `394, 373`)
    - **Par 3 (Blanco)**: Pilar 5 (Noroccidente: `407, 220`) <---> Pilar 2 (Suroriente: `656, 397`)
  - **Mecánica Fundamental de Equilibrio Sísmico**:
    - **Solo con la embestida del Torrasque se pueden destruir pilares**.
    - Al romper el primer pilar de un par, la cueva entra en **DESBALANCE SÍSMICO**.
    - El siguiente pilar destruido **DEBE SER EL OPUESTO EXACTO**:
      - **Si se destruye el opuesto**: Se restablece el equilibrio de la caverna, el jefe queda aturdido y la batalla continúa.
      - **Si se destruye un pilar erróneo (no opuesto)**: Se desata la **Cinemática de Colapso de la Cueva**: sacudida cataclísmica, desprendimiento masivo de rocas del techo y muerte del jugador por aplastamiento total.
- **El Jefe: Torrasque Ancestral (`scenes/torrasque_boss.tscn` / `scripts/torrasque_boss.gd`)**:
  - **Sistema de Armadura y Sobrecalentamiento**:
    - El jefe posee una barra de armadura que absorbe todos los disparos. Los impactos no dañan su vida directamente, sino que **sobrecalientan la armadura** de 0% a 100%.
  - **Casteo de Embestida (3 Segundos)**:
    - Al alcanzar el 100% de calor, el Torrasque canaliza un ataque durante 3 segundos.
    - Durante el casteo, una línea/flecha de advertencia sigue continuamente al jugador.
    - Al cumplirse los 3 segundos, se fija el punto final y el Torrasque embiste a máxima velocidad (460 px/s) en línea recta.
    - El jugador debe colocarse estratégicamente de modo que la carga impacte el pilar adecuado.
  - **Ventana de Aturdimiento y 6 Barras de Vida**:
    - El Torrasque posee **6 barras de vida** consecutivas (una por cada pilar del combate).
    - Al estrellarse contra un pilar válido, queda **ATURDIDO durante 6 segundos** con su coraza expuesta.
    - Solo durante el aturdimiento se puede dañar su barra de vida actual. Al vaciarse la barra, el jefe ruge, reactiva su armadura y se repite el ciclo.
- **Escalada de Oleadas Zerg**:
  - Cada pilar destruido incrementa el desove de refuerzos del Enjambre (Zerglings e Hidraliscos) desde los bordes de la caverna.
- **Boss HUD (`scenes/boss_hud.tscn` / `scripts/boss_hud.gd`)**:
  - Retrato del Ultralisco, contador de 6 barras (`BARRAS: X / 6`), barra de salud activa, barra de calor de armadura (0% a 100%), indicador de estado de balance de la cueva (`ESTABLE` o `DESBALANCE SÍSMICO`) y contador de pilares en pie.



---

## 3. 📻 Sistema de Comunicación de Radio Táctico (Briefing Style)

Implementado en [`scenes/transmission_comm.tscn`](scenes/transmission_comm.tscn) y [`scripts/transmission_comm.gd`](scripts/transmission_comm.gd):
- **Diseño Visual**:
  - **Monitor de Cámara (Izquierda)**: Chasis metálico cuadrado oficial (`tframe_comm.png` derivado de `tframe1`) con retrato animado en tiempo real (`sc_portrait.gd`) con sincronización labial y scanlines CRT del Capitán Hollis Voss (o emisor activo).
  - **Panel de Órdenes (Derecha)**: Marco de consola oficial de StarCraft (`comm_text_frame.png` derivado de `objterr` invertido horizontalmente) con brazo mecánico articulado que desciende desde el borde superior derecho.
  - **Tamaño Balanceado**: ~270x104 px anclado en la esquina superior derecha, permitiendo lectura cómoda sin tapar la acción ni la consola inferior.
- **Despliegue y Funcionalidad**:
  - Deslizamiento lateral con amortiguación mecánica (`Tween.TRANS_BACK`) desde `x=660` a `x=368`.
  - Efecto de sonido oficial `transmission.wav` y reproducción de secuencias de diálogo en cola.
  - Omitible en cualquier momento mediante clic izquierdo sobre el panel o tecla de acción.
- **Escenas Integradas**:
  - **Prólogo**: Instrucciones de la nave de descenso y despegue, con barra de salud oficial de StarCraft (`SCHealthBar`).
  - **Base Terran**: Diálogos narrativos de historia, órdenes del Capitán Hollis Voss y cinemáticas, reemplazando la ventana inferior genérica.
  - **HUD de Incursión Exterior**: Diálogos del Marine, advertencias de estructuras de desove zerg y clímax de los 20 minutos.

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
  - `tframe_comm.png`: Chasis metálico cuadrado para cámara de radio (64x59).
  - `tconsole.png`: Consola inferior completa de comando Terran (640x188).
  - `briefing.png`: Sala de briefing de operaciones (640x480).
- **Iconos de Armas (`sprites/weapon_icons.png`)**:
  - Slot 0: Rifle Gauss C-14
  - Slot 1: Lanza-llamas Firebat
  - Slot 2: Minas Araña Vulture
  - Slot 3: Francotirador Ghost C-10
  - Bio-arma Zerg Mutalisco: `sprites/mutalisk_glave_icon.png`
- **Spritesheets de Unidades**:
  - Marine: `marine.png` (17 cols x 128x128, muerte frames 221-228, restos `marine_remains.png`).
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
