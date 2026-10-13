# StarCraft: Survivors

¡Un fangame tributo de supervivencia táctica y roguelite ambientado en el universo clásico de **StarCraft 1 (SD)** desarrollado con Godot Engine 4.5!

![StarCraft: Survivors](Menu.jfif)

---

## 🎮 Características del Juego

- **Estética Clásica StarCraft 1 Remastered/SD**: Spritesheets auténticos con rotación direccional de 16 y 32 ángulos, retratos animados con sincronización labial, fuentes clásicas Terran y efectos de sonido originales remasterizados.
- **Flujo de Campaña & Hub Táctico**:
  - **Prólogo**: Despierta como Civil desarmado en el Sector Exterior tras una emboscada zerg.
  - **Base Terran (HUB Central)**: Habla con el Capitán Hollis Voss, investiga en la **Bahía de Ingeniería / Academia**, equípate en el **Arsenal**, y aborda la nave en el **Puerto Estelar** para desplegarte.
  - **Misiones del Acto 1**:
    - **Misión 1**: Reconocimiento y Purga (Eliminar 100 Zerglings).
    - **Misión 2**: Suministro de Gas Vespeno (Recolectar 10 tanques con radar direccional).
    - **Misión 3**: El Titán del Enjambre (Eliminar 200 enemigos y abatir al Ultralisco).
    - **Misión 4**: Extracción y Supervivencia (Recolectar 20 tanques y resistir).
- **Sistema de Oleadas Tácticas y Respiros**:
  - **Ciclos de 2 Minutos**: Cada 2 minutos la infestación muta a un nuevo nivel de amenaza (Tiers de color, salud y armadura escalados).
  - **Pausas Tácticas de 10s**: Al final de cada ciclo de 2 minutos (entre el segundo 110 y 120), los enjambres cesan su desove para permitirte recolectar minerales, respirar y reposicionarte.
  - **Límite de Entidades Optimizado**: Máximo 95 entidades activas simultáneas para garantizar 60 FPS estables sin caídas ni congelamientos.
- **Arsenal y Armamento**:
  - **Rifle Gauss C-14**: Fuego rápido con saturación balística y mejoras de calibre U-238.
  - **Lanza-llamas Firebat**: Llamaradas de napalm en abanico con daño en área.
  - **Minas Araña Vulture**: Minas robóticas móviles que persiguen a los enemigos y detonan en masa.
  - **Rifle Francotirador Ghost C-10**: Disparos de 25mm de penetración lineal con retícula táctica y onda de choque.
  - **Glave Wurm Mutalisco**: Bio-arma de proyectiles voraces con rebotes orgánicos entre objetivos.
- **Bahía de Ingeniería (Mejoras Permanentes)**:
  - Armamento de Infantería (Daño Global)
  - Saturación Balística (Disparos Adicionales)
  - Servomotores CMC (Velocidad de Movimiento)
  - Blindaje CMC (Vida Máxima y Armadura)
  - Estimulantes Sintéticos (Desbloqueo de Stimpack [T])
  - Botiquín Nanomédico (Regeneración de Salud)
  - Condensador de Flujo (Imán de Recolección)
  - **Excavación de Plasma (Minerales Extra)**: Aumenta los minerales obtenidos por cristal.
  - **Condensador de Vespeno (Gas x2)**: Duplica la extracción de Gas Vespeno obtenido por bidón.
- **Cristal Mineral Arcoíris**: Rara aparición que produce un efecto de vacío atrayendo todos los minerales dispersos en el campo de batalla de forma instantánea y optimizada.

---

## 🛠️ Requisitos e Instalación

- **Motor**: Godot Engine 4.5.1 Stable (Renderer: Forward+ / Mobile / Compatibility)
- **Ejecución desde el Editor**:
  1. Clona el repositorio.
  2. Abre Godot 4.5+ e importa la carpeta `sc-survivors`.
  3. Ejecuta la escena principal (`res://scenes/title_screen.tscn`).
- **Compilación Automática**:
  Ejecuta el script PowerShell incluido en `sc-survivors`:
  ```powershell
  .\build_game.ps1
  ```

---

## 📜 Licencia & Créditos

Proyecto desarrollado como homenaje no comercial a StarCraft (Blizzard Entertainment). Todos los sprites, retratos y sonidos son propiedad intelectual de sus respectivos creadores.
