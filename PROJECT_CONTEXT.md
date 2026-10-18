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
- **Soportes de Armaduras en Base (Marine CMC-300 y Médica Terran)**: Ubicados en la zona central de la base (`ArmorStand` en `Vector2(1055, 700)` y `ArmorStandMedic` en `Vector2(1115, 700)`). El jugador puede equipar cualquiera de los dos trajes al inicio o acercarse al soporte del otro traje para cambiar entre Marine y Médica en cualquier momento. El soporte del traje equipado queda vacío mientras que el del traje inactivo muestra la armadura descansando en el perchero.
- **Pantalla de Selección de Personaje (`character_select.tscn`) y Skin Alternativa**:
  - El Monitor 2 permanece como Firebat (bloqueado con overlay táctico).
  - En el Monitor 1 (Marine), al hacer clic sobre el rostro/retrato, se activa una animación mecánica donde el monitor se retrae verticalmente hacia arriba fuera de pantalla, conmuta la skin entre Marine y Médica Terran (`GameManager.selected_hero`), y desciende de vuelta con rebote elástico (`TRANS_BACK`), reproduciendo la confirmación de voz (`marine_ready` / `medic_ready`).
  - La Médica Terran funciona como skin alternativa femenina de combate: dispara con sonido original de fusil Gauss del Marine (`marine_fire`) mientras mantiene la animación visual de emisión nanomédica.
  - **Diferenciación de Acceso (Cuartel vs. Nave)**: Si se abre desde el Cuartel (`GameManager.character_select_source == "barracks"`), el botón muestra `"EQUIPAR PERSONAJE"`, aplica la skin elegida y regresa directamente a la Base sin iniciar la misión. Si se accede desde la Nave de Descenso, el botón muestra `"INICIAR MISIÓN"` y realiza el despliegue al páramo.
  - **Persistencia de Posición en Base**: La posición del jugador se preserva continuamente en `GameManager.base_player_position`, garantizando que al cancelar o regresar de la selección de personaje, el jugador permanezca exactamente frente al Cuartel o la Nave en lugar de reaparecer en el centro del HUB.
- **Estructuras de la Base**:
  1. **Centro de Mando (Command Center)**: Núcleo de operaciones y radar perimetral.
  2. **Bahía de Ingeniería / Academia**: Terminal de mejoras permanentes globales (costos 100% en Gas Vespeno).
  3. **Cuartel (Barracks)**: Hangar de infantería y cambio de trajes/skins sin desplegar.
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

### Fase 3: Batalla de Jefe del Acto 1 - La Cueva Zerg y el Torrasque Ancestral (Encuentro en 2 Fases)

La pelea final del Acto 1 transcurre en una caverna subterránea claustrofóbica a la que se accede descendiendo por el Canal Nydus colosal. Representa el clímax narrativo y de combate, implementando un diseño de puzzle de combate sísmico en 2 fases con escalada de peligros subterráneos, ruptura perimetral y un DPS check final.

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
     - Si `player.position.length() > ARENA_RADIUS - 16.0`: Se reubica instantáneamente en el borde interior normalizado y se resetea su vector de velocidad a cero. Ni aun rompiéndose las rocas perimetrales puede el jugador abandonar la arena.
     - Si `torrasque_boss.position.length() > ARENA_RADIUS - 30.0` (y no está en plena embestida): Se reubica de igual forma para evitar desplazamientos anómalos.
   - **Descarte de Evacuación en Superficie**: Al entrar a la cueva (y en el clímax del min 20), se destruye inmediatamente cualquier nodo en el grupo `evacuation_zone`. La única forma de salir con vida es destruyendo al Torrasque.

#### B. Fase 1: El Puzzle Sísmico de los 6 Pilares y Peligros Escalonados
1. **Regla de Ausencia de Esbirros Iniciales**:
   - Durante la Fase 1 **NO aparecen Zergs comunes** ("que no salgan zergs AUN"). El jugador se concentra exclusivamente en esquivar las embestidas del Torrasque, romper los pilares en pares opuestos y evadir la artillería subterránea.
2. **Disposición Simétrica de los 6 Pilares**:
   - Monolitos de roca mineral 2x3 (`boss_pillar.png`) a radio polar `PILLAR_RADIUS = 280.0` px:
     - **Par 1 (Norte / Sur)**: Pilar 0 (`Vector2(0, -280)`) $\longleftrightarrow$ Pilar 3 (`Vector2(0, 280)`)
     - **Par 2 (Nororiente / Suroccidente)**: Pilar 1 (`Vector2(242.5, -140)`) $\longleftrightarrow$ Pilar 4 (`Vector2(-242.5, 140)`)
     - **Par 3 (Suroriente / Noroccidente)**: Pilar 2 (`Vector2(242.5, 140)`) $\longleftrightarrow$ Pilar 5 (`Vector2(-242.5, -140)`)
3. **Mecánica de Balance de Pares Opuestos**:
   - Solo la embestida recta a 460 px/s del Torrasque puede fracturar los monolitos.
   - El primer pilar roto desbalancea la cueva e ilumina el opuesto (`pending_opposite_id`), aturdiendo al jefe durante 6 segundos (ventana de DPS).
   - Acertar el pilar opuesto restablece el equilibrio de la caverna (`pending_opposite_id = -1`) y vuelve a aturdir al Torrasque.
   - Romper un pilar erróneo causa el colapso estructural inmediato de la cueva (cinemática de derrumbe masivo y Game Over).
4. **Escalada Progresiva de Peligros Subterráneos (Espinas y Círculos)**:
   - Conforme se destruyen pilares (`broken_pillars_count` de 0 a 6), el intervalo de peligro se acelera de 4.6s hasta 1.8s (`lurker_timer = max(1.8, 4.6 - broken_pillars * 0.5)`).
   - Cada ciclo desata ráfagas combinadas:
     - **Líneas de Lurker**: De 2 a 5 líneas secuenciales en patrones de cruz, abanico, rastrillo o tridente convergente.
     - **Círculos de Sunken Colony**: De 1 a 4 círculos de peligro con retícula roja y brote violento de tentáculos bio-orgánicos (`sunken_hit.wav`).

#### C. Secuencia de Transición a Fase 2 (Al romperse el 6to Pilar)
1. **Aturdimiento Final y Despertar**:
   - Al romperse el 6to pilar sin fallar, el Torrasque entra en su aturdimiento final de Fase 1 (`enter_final_phase1_stun()`).
   - Al liberarse del stun, el Torrasque pisa violentamente el suelo con un rugido sísmico (`ultra_roar` y `pillar_smash`), salta / corre a gran velocidad hacia el centro de la arena (`Vector2.ZERO`).
2. **Onda Expansiva Sísmica y Ruptura de Roca Sur**:
   - Al tocar el centro, emite una onda expansiva colosal que empuja al jugador hacia abajo contra una roca del perímetro sur (`Vector2(0, ARENA_RADIUS - 30)`).
   - La roca del sur se fractura y estalla en escombros (`break_boundary_rock(south_rock)`), convirtiéndose en la primera **brecha activa** del perímetro.
   - Desde los escombros de la roca del sur emergen los primeros 3 Zerglings al combate con sonido `burrow_up`.
3. **Purga Central y Alerta Táctica**:
   - Los restos de los 6 pilares centrales se disuelven en nubes de polvo y se limpian de la caverna (`_clean_center_pillars()`), dejando el centro despejado para el combate definitivo.
   - Transmisión de emergencia de Hollis Voss: *«¡EL TITÁN ENTRÓ EN ENRAGE! ¡REVENTÓ EL PERÍMETRO! ¡MÁTALO ANTES DE QUE DESTRUYA TODA LA CAVERNA!»*.

#### D. Fase 2: Enrage, Brechas Perimetrales y DPS Check
1. **Frenesí del Torrasque (Enrage)**:
   - Modula en color carmesí ígneo (`Color(1.3, 0.45, 0.45, 1.0)`).
   - Velocidad de persecución incrementada a **118 px/s**.
   - Cargas periódicas rápidas cada 6-7 segundos con telégrafo agresivo de 1.8s.
2. **Coraza Vulnerable y DPS Check**:
   - La armadura reactiva se desactiva permanentemente (`is_armored = false`).
   - **Hereda íntegramente la salud** restante con la que el jugador lo dejó tras la Fase 1.
   - Cada disparo, proyectil, quemadura o tormenta psiónica inflige daño directo a su barra de vida en tiempo real.
3. **Destrucción de Rocas del Borde al Embestir**:
   - Cuando el Torrasque embiste al jugador y choca contra los muros o rocas del perímetro exterior, fractura y destruye las rocas donde impacta (`on_torrasque_smashed_wall()`).
   - El jugador **NO puede cruzar el muro** (la barrera matemática y física de capa 7 sigue infranqueable).
   - **Cada roca destruida se transforma en una nueva brecha activa**:
     - Cada brecha genera oleadas continuas de refuerzos Zerg (Zerglings Tier 7/8, Hidraliscos Tier 4/5 y Scourges kamikaze) cada 3.8 a 5.5 segundos.
     - **Mecánica de DPS Check**: Si el jugador tarda en matar al Torrasque, el jefe romperá más rocas a lo largo del círculo perimetral, acumulando decenas de brechas activas que inundarán la cueva de enemigos hasta abrumar la posición.

#### E. Interfaz del Jefe (`scenes/boss_hud.tscn` / `scripts/boss_hud.gd`)
- **Fase 1**: Monitor de estabilidad `EQUILIBRIO: ESTABLE` o `OBJETIVO: [PILAR]`, contador `PILARES: X / 6` y barra de calor de armadura.
- **Fase 2**: Cambia automáticamente a modo Enrage:
  - Monitor: `¡FASE 2: ENRAGE! ¡DPS CHECK!` en rojo pulsante.
  - Brechas: `BRECHAS: X / 38` indicando cuántos accesos enemigos están abiertos.
  - Barra de Coraza: `¡CORAZA EXPUESTA! (100% VULNERABLE)` con daño directo visible.

#### F. Resolución y Extracción
- Al caer abatido el Torrasque:
  - Se eliminan todas las brechas, espinas activas y esbirros restantes.
  - Se acredita la baja de jefe (`GameManager.add_boss_kill()`).
  - Suelta cofre élite y 8 tanques de gas vespeno.
  - Aterriza la nave de evacuación en el centro exacto de la cueva con confirmación radial de Hollis Voss para completar el Acto 1.
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

## 4. 🌊 Sistema de Oleadas, Nuevas Unidades Zerg y Rendimiento

### A. Nuevas Unidades Zerg Integradas
1. **Scourge (Kamikaze Aéreo - `scenes/scourge.tscn` / `scripts/scourge.gd`)**:
   - Vuela a alta velocidad (185-205 px/s), chilla con audio oficial (`scourge_charge.wav`) al detectar al jugador y se autodestruye en proximidad infligiendo daño explosivo en área (`scourge_explo.png`, 40-75 de daño). Vida baja (28-65 HP), muere de 1 a 2 disparos certeros pero castiga distracciones.
2. **Guardián (Asedio Pesado - `scenes/guardian.tscn` / `scripts/guardian.gd`)**:
   - Unidad de bombardeo aéreo pesado (62-70 px/s). Se posiciona a media distancia (~280 px) y dispara su espora ácida original (`bullet/spores.grp` / `guardian_spore.tscn`), ampliada a 2.3x para tener un impacto visual ancho y contundente. Su trayectoria es directa en línea recta a 160 px/s (velocidad reducida y predecible) permitiendo esquivarla activamente, con impacto `sporehit.grp` al impactar contra el jugador o agotar su alcance.
3. **Devorador / Corruptor (Bio-tanque Corrosivo - `scenes/devourer.tscn` / `scripts/devourer.gd`)**:
   - Unidad pesada voladora (75-85 px/s) con 480-1200 HP y 4-10 de armadura. Dispara saliva de ácido corrosivo (`devourer_acid_projectile.tscn`) a 185 px/s. Al impactar al héroe, le aplica un **efecto de moco morado** (overlay animado de ácido y partículas de goteo morado) que **reduce la mitad de su armadura (50%) durante 3.0 segundos**.
4. **Reina Zerg (Lanzadora Táctica - `scenes/queen.tscn` / `scripts/queen.gd`)**:
   - Unidad de soporte aéreo ágil (95-105 px/s, 280-680 HP). Lanza Ensnare (`queen_ensnare_projectile.tscn`) a 175 px/s. Al golpear al jugador, le aplica un **efecto de moco verde** (overlay animado de Ensnare oficial y gotas ácidas verdes) que **reduce su velocidad de movimiento un 40% durante 3.0 segundos** con su audio oficial `queen_ensnare.wav`.

### B. Rebalanceo de Oleadas y Erradicación de Zerglings "Esponja de Balas"
- **Tope de Zerglings**: Los Zerglings ahora tienen un tope estricto en Tier 4 (140 HP máximo y 3 de armadura en lugar de los antiguos 2400 HP / 20 armadura que los convertían en muros tediosos).
- **Diversificación del Enjambre**: La dificultad escala mediante variedad de amenazas simultáneas (asedio de Guardianes, ralentización de Devoradores y Reinas, ráfagas de Scourges kamikaze, Ultraliscos y mutaciones aéreas).

| Minuto | Ciclo | Composición Principal | Nuevas Amenazas Zerg |
|---|---|---|---|
| **0:00 - 2:00** | 0 | 50% Drones, 50% Zerglings | Tier 1 (Inicio clásico) |
| **2:00 - 4:00** | 1 | 20% Hidraliscos, 55% Zerglings T2, Drones | Tier 2 (Llegada de Hidraliscos) |
| **4:00 - 6:00** | 2 | 15% Scourges, 20% Mutas, 20% Hidras, 45% Zerglings T3 | Tier 3 (Kamikazes Scourge enjambre) |
| **6:00 - 8:00** | 3 | 12% Guardianes, 15% Scourges, 20% Hidras T2, Mutas | Tier 4 (Bombardeo de Guardianes) |
| **8:00 - 10:00** | 4 | 10% Devoradores, 12% Guardianes, 15% Scourges, Mutas, Hidras | Tier 5 (Ácido corrosivo de Devoradores) |
| **10:00 - 12:00** | 5 | 8% Reinas, 10% Devoradores, 12% Guardianes, Scourges, Mutas, Hidras | Tier 6 (Ensnare y ralentización de Reinas) |
| **12:00 - 14:00** | 6 | 6% Ultraliscos, 8% Reinas, 12% Devoradores, 12% Guardianes, Scourges | Tier 7 (Enjambre titánico combinado) |
| **14:00+** | 7+ | Enjambre Total de Élite (Ultraliscos, Devoradores, Guardianes, Reinas) | Masa crítica antes del Canal Nydus (min 20) |

### B. Peligro Subterráneo del Enjambre: Espinas de Lurker y Tentáculos de Sunken Colony
1. **Espinas Subterráneas de Lurker (`scenes/lurker_spine_hazard.tscn`)**:
   - **Fase de Telégrafo**: Proyecta una franja roja translúcida en el suelo con chevrons direccionales avisando la trayectoria de erupción.
   - **Erupción Secuencial**: Brota una fila de espinas (`lurker_spikes.png`) con partículas de tierra, infligiendo daño balístico al contacto.
   - **Duración de los Eventos**: Cada evento sísmico periódico (a los 180s, 360s, 540s, 720s) **dura exactamente 30 segundos continuos**, desovando múltiples líneas de espinas combinadas con círculos de Sunken Colony mientras dura el temblor.
   - **Frenesí Final (Minutos 15 a 20 / 900s a 1200s)**: Erupciones continuas incesantes cada 2.4s.
   - **Audio Original**: Sonidos `burrow_up.wav`, `lurker_fire.wav` y `lurker_hit.wav`.
2. **Círculos de Peligro y Tentáculos de Sunken Colony (`scenes/sunken_colony_hazard.tscn`)**:
   - **Mecánica**: Proyecta un círculo rojo translúcido de peligro de radio 42px con retícula en cruz y un arco de progreso de advertencia (1.25s).
   - **Erupción de Tentáculo**: Al completarse la advertencia, el suelo se fractura con partículas de tierra y brota violentamente un tentáculo gigante bio-orgánico (`sunken_tentacle.png` / `unit/bullet/tentacle.grp`), infligiendo 28 de daño al jugador si permanece dentro del círculo.
   - **Audio Original**: Sonido `sunken_hit.wav` (`spooghit.wav`) y retumbo subterráneo `burrow_up.wav`.

### C. Overlords de Desembarco Táctico (Últimos 5 Minutos / 15:00 a 20:00 - `scenes/overlord_dropship.tscn`)
- **Mecánica Ambiental Inmune**: Vuelan a gran altitud sobrevolando el mapa de un extremo a otro cada 14-18 segundos. No pertenecen al grupo de enemigos y carecen de hurtbox, actuando como eventos del mapa inmunes al fuego y armas del jugador.
- **Desembarco de Tropas de Choque**: Al pasar sobre el sector del jugador, abren compuertas y desembarcan de 4 a 5 **Zerglings de élite Tier 4** (los más duros, carmesí, 140 HP y armadura) con animación de descenso vertical.
- **Audio y Sprites Oficiales**: Spritesheet auténtico `overlord.png` (84x84, 17 columnas de rotación y sombra `overlord_shadow.png`), audio de transporte StarCraft 1 `overlord_drop.wav` (`zOvTra00.wav`) y bramido aéreo `overlord_groan.wav` (`zovpss00.wav`).
- **Limpieza Instantánea**: Se eliminan de inmediato junto con todas las espinas y tentáculos al activarse el clímax de los 20 minutos (`get_tree().call_group("overlord_transports", "clear_immediately")`).

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

### A. Armas en la Run (Hasta 3 secundarias simultáneas más Arma Principal del Héroe)
- **Ranura de Arma Base Dedicada**: Se adapta dinámicamente al héroe seleccionado (`c14_rifle` para Marine y Médica; `firebat_flame` para Firebat). No ocupa espacio de armas secundarias. Muestra icono oficial, nivel y estadísticas completas.
- **Rifle Gauss C-14 (`c14_rifle`)**: Arma balística reglamentaria. Proyectiles automáticos con auto-apuntado y saturación por multishot. Para el Firebat (y cualquier clase que no empiece con Gauss), puede aparecer aleatoriamente como arma secundaria (`NUEVA ARMA: Rifle Gauss C-14`) y escalarse hasta nivel 6 en la cuadrícula de armas secundarias.
- **Lanza-llamas Firebat (`firebat_flame`)**: Arma principal de Firebat (o secundaria para Marine/Médica). Rediseño táctico de debuff: impacto directo muy bajo (4.0 HP), DoT de combustión prolongada (2.0 HP/0.35s durante 3.5s) y **reducción de armadura acumulativa** (-1 a -3+ según nivel). Utiliza el sprite auténtico de 12 frames de StarCraft 1 (`sc1_fire_loop.png`) limpio de errores de croma.
- **Minas Araña Vulture (`spider_mine`)**: Minas móviles terrestres que persiguen y explotan en racimo con gran daño táctico.
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
Rebalanceadas al 50% para mantener un combate desafiante y evitar desbalance desmedido:
Definidas en `BARRACKS_UPGRADES_DEF` en `scripts/game_manager.gd`:
1. **Armamento de Infantería (`damage`)**: +2.5% Daño a todas las armas por nivel (10 niveles, 2 a 68 Gas).
2. **Saturación Balística (`multishot`)**: +1 Proyectil adicional a todas las armas por nivel (Máx +2 proyectiles, 2 niveles, 15 y 45 Gas).
3. **Servomotores CMC (`speed`)**: +2.5% Velocidad de movimiento inicial por nivel (10 niveles, 1 a 50 Gas).
4. **Blindaje CMC (`armor`)**: +7.5 Vida Máxima y +0.5 Armadura base por nivel (10 niveles, 1 a 55 Gas).
5. **Estimulantes Sintéticos (`stim`)**: Desbloquea `[T]` Stimpack (+0.25s duración, -0.15s recarga por nivel, 5 niveles, 2 a 30 Gas).
6. **Botiquín Nanomédico (`regen`)**: +0.4 Regeneración de salud/s inicial por nivel (10 niveles, 2 a 68 Gas).
7. **Condensador de Flujo (`magnet`)**: +9% Radio de atracción de minerales/EXP de inicio por nivel (10 niveles, 1 a 50 Gas).
8. **Excavación de Plasma (`mineral_efficiency`)**: +2.5% Experiencia (EXP) adicional obtenida por nivel (10 niveles, 2 a 68 Gas).
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
  - Firebat Terran: `firebat.png` (17 cols x 14 filas 64x64 centrados con offset de 16px, sombra `firebat_shadow.png`, wireframe `wire_firebat.png`, retrato `firebat_portrait.png`, audio completo `firebat_ready`, `firebat_what0..3`, `firebat_yes0..3`, `firebat_death0..2`). Inicia con Lanzallamas Perdition (`firebat_flame`) y su habilidad exclusiva **Calor Extremo** (`[T]`), la cual despliega un aura/nube de Enjambre/Corruptores (`extreme_heat_cloud.png`, `scenes/extreme_heat_aura.tscn`), reduce su velocidad de movimiento un 25%, aumenta su armadura (+4 base, +2 por nivel) e inflige daño ígneo continuo de área, sanando al jugador un porcentaje del daño realizado estrictamente por dicha habilidad (1.5% base, +0.5% por mejora de nivel).
  - Zergling: `zergling.png` (17 cols, restos `zergling_remains.png`).
  - Hidralisco: `hydralisk.png` (17 cols x 18 filas, muerte fila 12 cols 0-7, restos `hydralisk_remains.png`).
  - Mutalisco: `mutalisk.png` (17 cols x 6 filas, restos `mutalisk_remains.png`).
  - Drone: `drone.png` (17 cols x 23 filas, restos `drone_remains.png`).
  - Ultralisco: `ultralisk.png` (Jefe de gran tamaño con pisadas sísmicas).
  - Scourge: `scourge.png` (17 cols x 5 filas 48x48, sombra `scourge_shadow.png`, muerte `scourge_death.png`, explosión kamikaze 9 frames `scourge_explo.png`, SFX `scourge_charge`, `scourge_explode`, `scourge_death`).
  - Guardián: `guardian.png` (17 cols x 7 filas 96x96, sombra `guardian_shadow.png`, muerte `guardian_death.png`, proyectil de esporas 8 frames `guardian_spore.png`, impacto `guardian_spore_hit.png`, SFX `guardian_attack`, `guardian_death`).
  - Devorador / Corruptor: `devourer.png` (17 cols x 10 filas 96x96, sombra `devourer_shadow.png`, muerte `devourer_death.png`, proyectil ácido `devourer_acid.png`, impacto ácido `devourer_hit_fx.png`, SFX `devourer_attack`, `devourer_hit`, `devourer_death`).
  - Reina Zerg: `queen.png` (17 cols x 11 filas 128x128, sombra `queen_shadow.png`, muerte `queen_death.png`, proyectil y efecto Ensnare `queen_ensnare.png`, SFX `queen_ensnare`, `queen_death`).
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
- [x] **Héroe Firebat**: Inicio con Lanzallamas Perdition, armadura pesada (50 HP, 2 armadura), habilidad exclusiva Calor Extremo con aura de nube corrosiva, ralentización, bonificación de armadura y robo de vida balanceado.
- [ ] Héroe Ghost: Inicio con rifle C-10, invisibilidad táctica temporal con energía.
- [ ] Héroe Protoss invitado (Zealot / Templario Tétrico): Escudos de plasma regenerables y cuchillas psiónicas.
