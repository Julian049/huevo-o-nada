# Huevo o Nada

**Huevo o Nada** es un simulador de gestión y supervivencia de granjas avícolas en 2D desarrollado en Godot Engine. El objetivo principal es administrar un galpón de gallinas durante 30 días, equilibrando la economía del jugador y mitigando los efectos de enfermedades mediante modelos matemáticos de simulación.

## Cómo Jugar

Al iniciar, el jugador dispone de un lote inicial de gallinas y debe tomar decisiones de compra de suministros médicos y gestión del tiempo.

**Controles Principales:**

* **`ESPACIO`**: Inicia la simulación y activa el movimiento del galpón.
* **`1`**: Compra una Vacuna ($50). Reduce drásticamente la tasa de contagio del día.
* **`2`**: Compra una Medicina ($30). Aumenta la tasa de recuperación y evita la pérdida de vida por enfermedad.
* **`3`**: Avanza al siguiente día (Ejecuta el ciclo de simulación matemática).
* **`4`**: Compra un nuevo lote de gallinas e ingresa al galpón (si hay capacidad).

---

## Arquitectura y Estructura en Godot

El proyecto está diseñado bajo un enfoque de **responsabilidad única** y desacoplamiento para facilitar su escalabilidad. La escena principal (`Main.tscn`) delega tareas específicas a diferentes "Managers" y "Modelos".

### Árbol de Nodos Principal

```text
Main (Node2D) - [main.gd]
 ├── UIManager (Node) - [ui_manager.gd]
 ├── HenManager (Node2D) - [hen_manager.gd]
 ├── Model3Disease (Node) - [model3_disease.gd]
 ├── Model4Queues (Node) - [model4_queues.gd]
 └── Player (Node) - [Lógica de economía e inventario]

```

### ¿Cómo se conecta todo?

El flujo de información es unidireccional y está centralizado por el script principal:

1. **El Director (`main.gd`):** Es el cerebro de la operación. Escucha el teclado del jugador, valida el estado del juego y coordina en qué momento deben actuar los demás componentes. Ningún "Manager" habla directamente con otro sin pasar por el Director.
2. **La Vista (`ui_manager.gd`):** Recibe órdenes exclusivas de mostrar, ocultar o actualizar textos. No realiza cálculos de dinero ni días, solo refleja lo que el Director le envía (`update_hud()`).
3. **El Escenario (`hen_manager.gd`):** Controla las entidades físicas (`hen.tscn`). Se encarga de instanciar las gallinas en pantalla, moverlas y cambiar sus colores/estados visuales cuando el Director le informa que alguien enfermó o se curó.
4. **El Modelo Epidemiológico (`model3_disease.gd`):** Aplica **Dinámica de Sistemas**. Simula matemáticamente cómo se propaga una enfermedad en un grupo cerrado (Susceptibles, Infectados, Recuperados). No sabe de gráficos ni nodos en pantalla, solo procesa números y emite una señal (`day_processed`) con el reporte de contagios y curaciones del día.
5. **El Modelo de Supervivencia (`model4_queues.gd`):** Aplica **Teoría de Colas**. Asigna una esperanza de vida a cada gallina utilizando una distribución normal estándar y aplica un desgaste de salud por cada día que pasa (o penalidades dobles si están enfermas y sin medicina). Avisa cuando una gallina cumple su ciclo biológico o agota su salud.

### Flujo del Ciclo Diario (Presionar `3`)

Cuando el jugador avanza de día, ocurre el siguiente proceso interno:

1. `Main` revisa el inventario del `Player` (Vacunas y Medicinas).
2. `Main` envía esta información al `Model3Disease`.
3. `Model3Disease` calcula matemáticamente los contagios y devuelve un reporte.
4. `Main` lee el reporte y le ordena al `HenManager` cambiar los estados de las gallinas vivas.
5. `Main` le pide al `HenManager` que pase sus gallinas por el filtro del `Model4Queues` para envejecerlas y descontarles vida.
6. `Main` actualiza el día y le dice al `UIManager` que pinte los nuevos números en pantalla.
