# 🚀 GUÍA DE CONTEXTO DEL PROYECTO: STARCRAFT SURVIVORS (SC-SURVIVORS)

> **Documento maestro de contexto y arquitectura para agentes de IA y desarrolladores.**
> Este documento contiene toda la información técnica, narrativa, arquitectura de código, distribución de spritesheets y diseño del Acto 1.

---

## 1. 🎯 Propósito del Juego y Visión General
- **Título**: *StarCraft: Survivors*
- **Motor**: Godot Engine 4.5 (.NET/C++ Core con GDScript)
- **Género**: Roguelite Survivor (estilo *Vampire Survivors*) ambientado con fidelidad absoluta en el universo clásico de **StarCraft 1 (SD 1998 / Remastered)**.
- **Ruta del Proyecto**: `c:\Users\toffe\Desktop\autocalabazas\sc-survivors\`
- **Ejecutable compilado**: `C:\Users\toffe\Desktop\SC_Survivors.exe`
- **Script de compilación rápida**:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\build_game.ps1
  ```
- **Ruta de Guardado (Saves)**:
  `%APPDATA%\Godot\app_userdata\StarCraft- Survivors\save_slot_1.json`

---

## 2. 📖 Estructura Narrativa y Flujo de Juego (Hasta el Acto 1)

### Fase 0: Prólogo (`scenes/prologue.tscn` / `scripts/prologue.gd`)
- El jugador viaja en un convoy confederado que sufre una emboscada y aterriza forzosamente en el planeta Sigma-4.
- El jugador despierta como un civil desarmado entre escombros y se arrastra hasta el refugio subterráneo guiado por una baliza de socorro.

### Fase 1: Puesto Avanzado / Base Terran (`scenes/terran_base.tscn` / `scripts/terran_base.gd`)
- Es el hub central de descanso, metaprogresión y conversación entre incursiones.
- **NPC Principal**: **Capitán Hollis Voss** (oficial veterano que da órdenes y autorizaciones).
- **Armadura Marine CMC-300**: Se encuentra en un soporte al inicio (`story_stage == "base_initial"`). El jugador se acerca, interactúa y se la pone **una sola vez**. A partir de ese momento, `GameManager.has_suit_equipped = true` y queda guardado permanentemente en `SaveManager`. **Nunca vuelve a quitarse ni a guardarse**.
- **Nave de Despliegue / Evacuación**: El jugador se sube para bajar a las misiones al exterior.
- **Construcción y Progresión de la Base**:
  1. Base inicial: Posee el **Centro de Mando (Command Center)** y el **Extractor de Vespeno (Geyser)**.
  2. **Misión 1**: Bajar al exterior, recolectar 20 minerales y volver en la nave de evacuación -> Desbloquea la autorización de construir la **Academia Terran** (coste: 20 minerales).
  3. **Misión 2**: Recolectar 20 minerales y sobrevivir al incremento de hostilidad -> Desbloquea la autorización del **Cuartel (Barracks)** (coste: 20 minerales).
  4. La Academia/Cuartel abre la terminal de mejoras permanentes (grilla con costes balanceados y accesibles al 10% para acelerar el ritmo del juego).
- **Retorno de Misión**: Cuando el jugador evacúa con éxito, al volver a la base se dispara el diálogo de felicitación y entrega de recursos con Voss, y se actualiza la historia.

### Fase 2: Incursión Exterior en los Páramos (`scenes/main.tscn` / `scripts/main.gd`)
- El mapa exterior de combate y supervivencia.
- **HUD Superior (`scripts/hud.gd`)**:
  - `minerals_label`: Muestra **`GameManager.session_minerals`** en tiempo real. Comienza en 0 al aterrizar y sube con cada cristal recogido en la partida.
  - Temporizador (`time_label`): Cuenta el tiempo sobrevivido.
  - Barra de XP y Nivel en tiempo real.
- **Condición de Victoria / Evacuación**:
  - Al completar el objetivo de la misión (ej. 20 minerales o metas de bajas), se activa el círculo de evacuación (`scenes/evacuation_circle.tscn`).
  - Entrar en el círculo permite evacuar hacia la base conservando todos los minerales y gas recolectados.
- **Muerte en Combate**:
  - El jugador reproduce la animación auténtica de muerte de marine (8 frames) y deja los restos esqueléticos en el suelo.
  - Se abre el panel de Game Over permitiendo reintentar la misión o evacuar de emergencia a la base.

---

## 3. ⚔️ Sistema de Combate, Armas y Pasivas

### Jugador (`scripts/player.gd`)
- **Arma Principal**: **Rifle Gauss C-14** (cadencia rápida, busca automáticamente al Zerg más cercano dentro de su alcance).
- **Habilidad Especial**: `[T]` **Stimpack** (Estimulantes). Aumenta dramáticamente la velocidad de disparo y movimiento durante unos segundos a costa de un porcentaje de vida actual.

### Armas Secundarias (Hasta 3 slots en la Run)
1. **Lanzallamas Firebat (`firebat_flame`)**: Daño de fuego continuo en cono frontal.
2. **Minas Araña Vulture (`spider_mine`)**: Siembra minas en el suelo que persiguen a los Zerg y detonan en área.
3. **Francotirador Ghost C-10 (`ghost_sniper`)**: Disparos de alto calibre y gran alcance que perforan múltiples enemigos en línea recta.

### Mejoras Pasivas (Hasta 6 slots en la Run)
1. **Campo Magnético (`magnetic_field`)**: Atrae cristales de mineral desde mayor distancia.
2. **Infusión de Stimpack (`stimpack_upgrade`)**: Incrementa velocidad base y duración de estimulantes.
3. **Blindaje de Combate (`combat_shield`)**: Aumenta la vida máxima y repara salud.
4. **Balas U-238 (`u238_shells`)**: Aumenta el daño balístico y otorga penetración.
5. **Cadencia Gauss (`cadence`)**: Aumenta la velocidad de ataque de todas las armas.
6. **Balas Explosivas (`explosive_rounds`)**: Proyectiles generan explosiones en área al impactar.
7. **Disparo Múltiple (`multishot`)**: Dispara balas/proyectiles simultáneos extra.
8. **Regeneración Médica (`medikit`)**: Regeneración pasiva continua de vida por segundo.

---

## 4. 🎨 Ubicación y Mapeo Exacto de Sprites y Assets

- **Carpeta de origen con todos los assets originales de SC1**:
  `C:\Users\toffe\Desktop\SCsurvivors\`
- **Carpeta de assets activos en Godot**:
  `sc-survivors/assets/skins/sd/`

### A. Spritesheets de Unidades (`assets/skins/sd/sprites/`)
1. **Marine (`marine.png`)**:
   - Hoja con 17 columnas de dirección (128x128).
   - Frames `221` a `228`: Animación de muerte oficial de SC1 (8 frames).
   - `marine_remains.png`: Restos cadavéricos en el suelo (3 frames).
   - `marine_shadow.png`: Sombra volumétrica.
2. **Zergling (`zergling.png`)**:
   - 17 columnas de dirección.
   - `zergling_remains.png`: Restos en el suelo.
3. **Hidralisco (`hydralisk.png`)**:
   - Tamaño: 2176 x 2304 (17 columnas x 18 filas, 128x128 por celda).
   - **Ataque**: **Filas 0 a 4** (5 fases de ataque en las 17 direcciones).
   - **Movimiento**: **Filas 5 a 11** (7 frames de reptación en las 17 direcciones).
   - **Muerte**: **Fila 12, Columnas 0 a 7** (8 frames de estallido de carne/sangre: frames `204` a `211`).
   - `hydralisk_remains.png`: Restos (4 frames).
4. **Drone (`drone.png`)**:
   - Tamaño: 2176 x 2944 (17 columnas x 23 filas, 128x128 por celda).
   - **Ataque**: **Filas 0 a 4** en las 17 direcciones.
   - **Movimiento**: **Filas 5 a 9** en las 17 direcciones.
   - **Muerte**: **Columna 0 vertical, Filas 10 a 17** (8 frames de estallido: frames `170, 187, 204, 221, 238, 255, 272, 289`).
   - `drone_remains.png`: Restos (5 frames).
5. **Ultralisco (`ultralisk.png`)**: Jefe temible de gran tamaño con pisadas sísmicas.

### B. Iconos Oficiales StarCraft (`assets/skins/sd/sprites/`)
Los iconos se generaron con reescalado Lanczos a 48x48 desde los archivos originales de StarCraft Remastered:

#### `weapon_icons.png` (192 x 48 px, 4 ranuras de 48x48):
| Slot | ID en SC | Nombre Arma | Identificador en Código |
|---|---|---|---|
| **0** | **288** | Rifle Gauss C-14 | `c14_rifle` |
| **1** | **301** | Lanzallamas Firebat | `firebat_flame` |
| **2** | **364** | Minas Araña Vulture | `spider_mine` |
| **3** | **324** | Francotirador Ghost | `ghost_sniper` |

#### `tech_icons_clean.png` (384 x 48 px, 8 ranuras de 48x48):
| Slot | ID en SC | Nombre Mejora | Identificador en Código |
|---|---|---|---|
| **0** | **214** | Campo Magnético | `magnetic_field` |
| **1** | **237** | Estimulantes / Stimpack | `stimpack_upgrade` |
| **2** | **287** | Blindaje de Combate | `combat_shield` |
| **3** | **306** | Balas U-238 | `u238_shells` |
| **4** | **282** | Cadencia Gauss | `cadence` |
| **5** | **248** | Balas Explosivas | `explosive_rounds` |
| **6** | **275** | Disparo Múltiple | `multishot` |
| **7** | **365** | Botiquín Nanomédico | `medikit` |

### C. Música Oficial (`assets/skins/sd/music/`)
- `terran1.ogg`: Música del menú principal y de la Base Terran.
- `terran2.ogg`: Música de combate exterior (Misiones) y del Prólogo.
- `trdyroom.ogg`: Música del selector de personaje / hangar.
- `tdefeat.wav`: Marcha fúnebre de derrota al morir.

---

## 5. 🏗️ Arquitectura de Singletons (Autoloads)

1. **`GameManager` (`scripts/game_manager.gd`)**:
   - Administra el bucle de la run: experiencia (`current_xp`, `xp_needed`), nivel (`current_level`), tiempo sobrevivido (`game_time`), oleadas de enemigos Zerg y jefes.
   - Administra el arsenal activo (`weapons`, `passives`) y los cálculos de estadísticas acumulativas.
   - `reset_game()`: Reinicia contadores de run y reproduce `terran2.ogg`.
2. **`SaveManager` (`scripts/save_manager.gd`)**:
   - Gestiona persistencia de 3 ranuras (`save_slot_1.json`, etc.).
   - Guarda y restaura: `total_minerals`, `total_gas`, `story_stage`, `buildings`, `academy_upgrades`, logros y `has_suit_equipped`.
3. **`StoryManager` (`scripts/story_manager.gd`)**:
   - Controla el estado narrativo de la campaña, misiones activas y requisitos de construcción de edificios.
4. **`SkinManager` (`scripts/skin_manager.gd`)**:
   - Carga dinámica de texturas, sonidos y música según la skin seleccionada (arquitectura modular para SD, HD y Carbot).
5. **`AudioManager` (`scripts/audio_manager.gd`)**:
   - Maneja el reproductor de música con loop y un pool de 16 voces de efectos de sonido con modulación aleatoria de tono (pitch jitter).
6. **`ScreenFade` (`scripts/screen_fade.gd`)**:
   - Controla los fundidos a negro entre escenas e interacciones de la base.

---

## 6. ⚠️ Reglas Críticas de Desarrollo
1. **Nunca pausar el árbol al iniciar misiones**: `main.tscn` debe arrancar con `get_tree().paused = false` para que el jugador nunca se quede congelado en `00:00`.
2. **Persistencia del Traje**: `has_suit_equipped` siempre debe mantenerse en `true` una vez equipado. Si `story_stage` no es `"prologue"` ni `"base_initial"`, el personaje SIEMPRE es Marine con armadura y armas.
3. **Tweens de Muerte**: Siempre usar `.set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)` en las animaciones de muerte para garantizar que se reproduzcan y llamen a `GameManager.game_over()` sin importar el estado del motor.
4. **Minerales en Misiones**: En `hud.gd`, la etiqueta de minerales de la barra superior siempre debe mostrar `GameManager.session_minerals` para que el jugador vea su progreso de recolección en tiempo real.
