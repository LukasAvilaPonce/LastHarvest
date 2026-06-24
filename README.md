# LastHarvest 🌱🧟

Juego de **supervivencia por oleadas** en 3D desarrollado en **Godot 4.6** con **GDScript**. El jugador defiende su base de hordas de zombies plantando aliados-planta con distintas habilidades. Si los zombies destruyen la **Planta Madre**, la partida termina.

## 🎮 Concepto

LastHarvest mezcla **tower defense** y **supervivencia por oleadas**: en lugar de torres fijas, plantas semillas que crecen en aliados con comportamientos propios para frenar el avance de los zombies y proteger tu objetivo principal, la Planta Madre.

## ✨ Características

- **Sistema de oleadas** — zombies que aparecen en rondas de dificultad creciente.
- **Sistema de plantas con roles distintos:**
  - **Caminante** — planta móvil de combate cuerpo a cuerpo.
  - **Girasol** — planta de soporte que cura a los aliados.
- **IA de zombies** — ataques basados en distancia, animaciones de Mixamo y priorización de objetivos hacia la Planta Madre.
- **Mecánica de siembra** — sistema de semillas que da origen a las plantas aliadas.
- **Planta Madre** — objetivo central; si cae, es game over.
- **Física en 3D** — entidades basadas en `CharacterBody3D`.

## 🛠 Tecnologías

- **Motor:** Godot 4.6
- **Lenguaje:** GDScript (100%)
- **Animaciones:** Mixamo
- **Física:** Jolt Physics
- **Renderer:** Mobile (D3D12 en Windows)

## 📂 Estructura del proyecto

```
LastHarvest/
├── assets/             # Recursos del juego (modelos, animaciones, texturas)
├── jugador.gd/.tscn    # Jugador
├── zombie.gd/.tscn     # Enemigos (zombie y zombie_run)
├── planta.gd/.tscn     # Plantas aliadas
├── planta_madre.tscn   # Objetivo a defender (game over si cae)
├── semilla.gd/.tscn    # Sistema de siembra
├── mundo.gd/.tscn      # Escena principal / nivel
├── node_3d.gd/.tscn    # Escena raíz (main_scene)
├── LastHarvest_GDD.docx # Game Design Document
└── project.godot       # Archivo de proyecto Godot
```

## 🚀 Cómo ejecutarlo

1. Instala **Godot 4.6** desde [godotengine.org](https://godotengine.org/).
2. Clona el repositorio:
   ```bash
   git clone https://github.com/LukasAvilaPonce/LastHarvest.git
   ```
3. Abre **Godot 4.6** e importa el proyecto seleccionando el archivo `project.godot`.
4. Presiona **F5** (o el botón ▶) para ejecutar.

## 📄 Documentación

El diseño del juego está documentado en `LastHarvest_GDD.docx` (Game Design Document).

## 🎯 Estado del proyecto

En desarrollo activo. Mecánicas implementadas: sistema de oleadas, IA de zombies, plantas Caminante y Girasol, siembra de semillas, y la Planta Madre como condición de derrota.

## 👤 Autor

**Lukas Ávila** — Estudiante de Ingeniería en Informática, Duoc UC
📧 lukas.avila2002@gmail.com
🔗 [GitHub](https://github.com/LukasAvilaPonce)
