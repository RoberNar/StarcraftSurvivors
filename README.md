# StarCraft: Survivors (Alpha v0.333)

¡Un fangame tributo de supervivencia táctica y roguelite ambientado en el universo clásico de **StarCraft 1 (SD 1998 / Remastered)** desarrollado con Godot Engine 4.5!

![StarCraft: Survivors](Menu.jfif)

---

## 🎮 Características del Juego

- **Estética Clásica StarCraft 1 Remastered / SD**:
  - Spritesheets auténticos con rotación direccional completa de 16 y 32 ángulos.
  - Retratos parlantes con sincronización labial animada, parpadeo y filtros scanline CRT retro.
  - Tipografías oficiales Terran (Eurostile) y efectos de sonido remasterizados de la banda sonora original.

- **Flujo de Campaña & Hub Táctico**:
  - **Prólogo**: Despierta como un Civil desarmado en el Sector Exterior tras una emboscada zerg y evacúa en la nave de descenso táctico.
  - **Base Terran (HUB Central)**: Habla con el **Capitán Hollis Voss**, investiga en la **Bahía de Ingeniería / Academia**, equípate en el **Arsenal**, y aborda la nave en el **Puerto Estelar** para desplegarte al exterior.
  - **Campaña (Acto 1 - En Desarrollo)**: Supervivencia táctica en los páramos del planeta Sigma-4, recolección de minerales, extracción táctica y resistencia ante oleadas masivas del Enjambre. *(Nota: El jefe final del Acto 1 aún no está implementado)*.

- **Comunicador Táctico de Radio Terran**:
  - Consola de transmisión inspirada en la pantalla de *briefing* de StarCraft 1.
  - Monitor cuadrado de cámara a la izquierda con chasis metálico y retrato animado en tiempo real del Capitán Hollis Voss.
  - Panel de órdenes a la derecha con brazo mecánico articulado que desciende desde el marco superior.
  - Despliegue lateral animado con sonido de radiofrecuencia oficial y opción de omisión al hacer clic.

- **Sistema de Oleadas Tácticas, Respiros y Clímax de 20 Minutos**:
  - **Ciclos de 2 Minutos**: Cada 2 minutos la biología Zerg muta a un nuevo escalón con armadura balística, salud incrementada y tintes cromáticos identificativos (marrón, bronce, púrpura, carmesí, azul, ámbar, esmeralda y masa crítica).
  - **Pausas Tácticas de 10s**: Entre el segundo 110 y 120 de cada bloque de 2 minutos, el desove de enemigos se pausa silenciosamente para permitirte recolectar minerales, respirar y reposicionarte.
  - **Clímax de Supervivencia a los 20:00 (1200s)**: Duración límite de la incursión. Al minuto 20 se limpian los enemigos menores y emerge el colosal Canal Nydus ante el jugador.
  - **Rendimiento Fijo a 60 FPS**: Límite dinámico de entidades (máximo 90-130 en pantalla) para evitar saturación de CPU sin perder la sensación de enjambre masivo.

- **Peligros Subterráneos del Enjambre (Lurker Spines)**:
  - **Espinas de Merodeador (Lurker)**: Franjas rojas de telégrafo táctico en el suelo con flechas direccionales chevrons, seguidas de erupciones secuenciales de púas que infligen daño balístico al contacto.
  - **Frenesí de Espinas (Minutos 15 a 20)**: En los últimos 5 minutos de la incursión se desatan oleadas continuas de espinas subterráneas obligando a maniobrar con precisión.
  - **Estructuras de Nido Zerg**: Desove periódico de Pozos de Zerglings, Guaridas de Hidraliscos y Espiras de Mutaliscos que deben ser destruidas para detener el flujo incesante de refuerzos.

- **Arsenal y Armamento (Hasta 3 armas en la Run)**:
  - **Rifle Gauss C-14**: Ráfagas automáticas de alta cadencia con saturación balística.
  - **Lanza-llamas Firebat**: Conos de napalm continuo con daño persistente en área.
  - **Minas Araña Vulture**: Minas móviles terrestres que persiguen a los enemigos y detonan en racimo.
  - **Rifle Francotirador Ghost C-10**: Balas de 25mm de penetración lineal con retícula táctica y onda expansiva.
  - **Glave Wurm Mutalisco**: Proyectiles parásitos bio-zerg con rebotes orgánicos entre objetivos.

- **Bahía de Ingeniería / Academia (Mejoras Permanentes)**:
  - **Armamento de Infantería**: +5% Daño global por nivel (10 niveles).
  - **Saturación Balística**: +1 Proyectil simultáneo a todas las armas por nivel (3 niveles).
  - **Servomotores CMC**: +5% Velocidad de movimiento inicial por nivel (10 niveles).
  - **Blindaje CMC**: +15 Vida Máxima y +1 Armadura base por nivel (10 niveles).
  - **Estimulantes Sintéticos**: Desbloquea la habilidad `[T]` Stimpack y extiende su duración.
  - **Botiquín Nanomédico**: Regeneración de salud continua por segundo (+0.8 PS/s por nivel).
  - **Condensador de Flujo**: +18% Radio de atracción de minerales por nivel (10 niveles).
  - **Excavación de Plasma**: +25% Minerales extra obtenidos por cada cristal recogido.
  - **Condensador de Vespeno**: Duplica la extracción de Gas Vespeno por bidón recolectado (x2 Gas).
  - **Cristal Mineral Arcoíris**: Rara aparición que absorbe matemáticamente todos los cristales del mapa sin cálculo de colisiones.

---

## 📦 Sistema de Versiones

A partir de esta versión, el proyecto se numera de forma auto-incremental iniciando en **`v0.333`** (ej. `v0.333` → `v0.334` → `v0.335`...) para diferenciar con precisión cada compilación y tag en el repositorio:
- **Versión Actual**: `v0.333` (Alpha)
- **Repositorio Oficial**: [https://github.com/RoberNar/StarcraftSurvivors](https://github.com/RoberNar/StarcraftSurvivors)
- **Archivo de seguimiento de versión**: [`sc-survivors/version.txt`](sc-survivors/version.txt)

---

## 🛠️ Requisitos e Instalación

- **Motor**: Godot Engine 4.5.1 Stable (Renderer: Forward+ / Mobile / Compatibility)
- **Ejecución desde el Editor**:
  1. Clona el repositorio:
     ```bash
     git clone https://github.com/RoberNar/StarcraftSurvivors.git
     ```
  2. Abre Godot 4.5+ e importa el proyecto desde la carpeta `sc-survivors`.
  3. Ejecuta la escena principal (`res://scenes/title_screen.tscn`).
- **Compilación Automática y Empaquetado**:
  Ejecuta el script PowerShell incluido en `sc-survivors` para compilar y generar automáticamente el ZIP versionado en el Escritorio:
  ```powershell
  powershell -ExecutionPolicy Bypass -File .\sc-survivors\build_game.ps1
  ```

---

## 📜 Licencia & Créditos

Proyecto desarrollado como homenaje no comercial a StarCraft (Blizzard Entertainment). Todos los sprites, retratos y sonidos son propiedad intelectual de sus respectivos creadores.
