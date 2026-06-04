# DOCUMENTACIÓN COMPLETA: HUEVO O NADA
## Simulador de Gestión y Supervivencia de Granjas Avícolas

---

## 📋 TABLA DE CONTENIDOS

1. [Descripción del Proyecto](#1-descripción-del-proyecto)
2. [Mecánicas del Juego](#2-mecánicas-del-juego)
3. [Arquitectura y Árbol de Nodos](#3-arquitectura-y-árbol-de-nodos)
4. [Flujo del Ciclo Diario](#4-flujo-del-ciclo-diario)
5. [Modelos de Simulación Matemática](#5-modelos-de-simulación-matemática)
6. [Eventos del Modelo Económico](#6-eventos-del-modelo-económico)
7. [Estados de las Gallinas](#7-estados-de-las-gallinas)
8. [Constantes Claves del Juego](#8-constantes-claves-del-juego)
9. [Sistema de Inventario y Recursos](#9-sistema-de-inventario-y-recursos)
10. [Assets y Recursos Visuales](#10-assets-y-recursos-visuales)
11. [Código Fuente Completo](#11-código-fuente-completo)
12. [Diagrama de Flujo Técnico](#12-diagrama-de-flujo-técnico)
13. [Detalles de Implementación](#13-detalles-de-implementación)
14. [Pantalla de Historia](#14-pantalla-de-historia-storyscreen)
15. [Historial de Cambios y Arreglos](#15-historial-de-cambios-y-arreglos)

---

## 1. Descripción del Proyecto

### 1.1 Visión General

**"Huevo o Nada"** es un simulador de gestión y supervivencia de granjas avícolas desarrollado en **Godot Engine 4.6** para demostrar la aplicación de modelos matemáticos complejos en un contexto lúdico. El objetivo principal es administrar un **galpón de gallinas durante 30 días**, equilibrando la economía de la granja con la mitigación de los efectos de enfermedades infecciosas.

### 1.2 Contexto Académico

El proyecto es parte de un curso de **Simulación** en un programa de Ingeniería. Integra:

- **Dinámica de Sistemas (Modelo 3)**: Propagación de enfermedades contagiosas
- **Teoría de Colas (Modelo 4)**: Esperanza de vida y desgaste natural
- **Monte Carlo (Modelo 1)**: Generación estocástica de producción diaria
- **Agentes Basados en Modelos - ABM (Modelo 2)**: Control de plagas (roedores)
- **Cadena de Suministro (Modelo 5)**: Economía, eventos mercantiles e inspecciones

### 1.3 Objetivo del Jugador

Al iniciar la partida, el jugador recibe:
- **3 gallinas iniciales**
- **$1.000.000 COP** en el balance inicial
- **Una deuda de $1.500.000 COP** que debe pagar en 30 días

**Objetivos posibles:**
1. **Victoria**: Pagar la deuda completamente antes del día 30
2. **Supervivencia**: Mantener vivas todas las gallinas durante toda la partida
3. **Gestión**: Equilibrar compras de vacunas/medicinas, expansión de la granja y ventas de huevos

---

## 2. Mecánicas del Juego

### 2.1 Controles Principales

| Tecla | Acción | Costo | Efecto |
|-------|--------|-------|--------|
| **ESPACIO** | Iniciar simulación | Gratis | Activa el movimiento del galpón y permite las acciones del jugador |
| **1** | Comprar Vacuna | $15.000 COP | Reduce la tasa de contagio del día actual en 85% |
| **2** | Comprar Medicina | $8.000 COP | Aumenta tasa de recuperación y evita penalización de salud |
| **3** | Avanzar un día | Gratis | Ejecuta el ciclo de simulación matemática (Modelos 1-5) |
| **4** | Comprar lote de 3 gallinas | $75.000 COP | Ingresa 3 nuevas gallinas al galpón (si hay capacidad) |
| **W/↑** | Mover jugador arriba | Gratis | Movimiento del personaje en el galpón |
| **A/←** | Mover jugador izquierda | Gratis | Movimiento del personaje en el galpón |
| **S/↓** | Mover jugador abajo | Gratis | Movimiento del personaje en el galpón |
| **D/→** | Mover jugador derecha | Gratis | Movimiento del personaje en el galpón |

### 2.2 Mecánicas de Recursos

#### Dinero (Balance de Caja)

- **Balance inicial**: $1.000.000 COP
- **Deuda inicial**: $1.500.000 COP
- **Costos diarios fijos**: 
  - Alimento: `costo_alimento_dia × num_gallinas`
  - Servicios (agua, luz): $5.000 COP/día
- **Ingresos**:
  - Venta de huevos: `num_huevos × precio_huevo` (días específicos: 5, 10, 15, 20, 25, 30)

#### Inventario de Huevos

- **Se genera diariamente** mediante el Modelo 1 (Monte Carlo)
- **Tasa base de postura**: 0.8 por gallina sana
- **Se vende automáticamente** en días específicos (Modelo 5)
- **Máximo actual**: Sin límite explícito, pero limitado por capacidad del galpón

#### Inventario de Medicinas

- **Vacunas**: Compra con tecla **1**. Reduce contagio directo en 85% ese día.
- **Medicinas**: Compra con tecla **2**. Aumenta tasa de recuperación y evita penalización de salud.
- **Uso automático**: Se consume al presionar **3** (avanzar día) si están disponibles.

### 2.3 Mecánicas de Salud y Enfermedad

#### Estados de las Gallinas

Cada gallina tiene un **estado epidemiológico**:

1. **SANA (Healthy)** - Estado 0
   - Color: Amarillo oro
   - Puede contagiarse
   - Produce huevos a tasa base

2. **ENFERMA (Sick)** - Estado 1
   - Color: Verde oscuro
   - Propaga enfermedad
   - Reduce producción de huevos
   - Sufre penalización de salud (-2.0/día sin medicina)

3. **RECUPERADA (Recovered)** - Estado 2
   - Color: Verde claro
   - Inmune a nuevos contagios
   - Recupera producción gradualmente

4. **MUERTA (Dead)** - Estado 3
   - Color: Gris oscuro
   - Se queda en pantalla pero inmóvil
   - No contribuye a población

#### Atributos Individuales de Salud

Cada gallina tiene:
- **Health**: Puntos de salud actuales (disminuyen 1.0 por día)
- **Max_Health**: Salud máxima asignada al nacer (distribución normal)
- **Age**: Edad en días

**Muerte ocurre cuando:**
- `health <= 0.0` O
- `age >= max_health`

### 2.4 Mecánica de Contagio

**Modelo SIR (Susceptibles-Infectados-Recuperados)**:

El contagio ocurre mediante dos canales:

1. **Contagio Directo**: Contacto entre gallinas sanas e infectadas
   - Factor de contacto: Proporcional a la aglomeración (`población / capacidad`)
   - Tasa base: **β = 3**

2. **Contagio Ambiental**: Carga viral en el aire del galpón
   - Aumenta cada día con la aglomeración
   - Puede reducirse drásticamente con vacunas

**Fórmulas utilizadas:**

```
crowding_factor = total_population / max_capacity
environmental_viral_load += crowding_factor × 0.05  [por día]

flow_direct = β × crowding × I × (S / N)
flow_environmental = viral_load × S × 0.10
flow_recovery = γ × I

donde β es reducido a 0.45 (85%) si se usa vacuna
y γ aumenta de 0.05 a 0.75 si se usa medicina
```

### 2.5 Mecánica de Capacidad

- **Capacidad máxima del galpón**: 30 gallinas
- **Gallinas iniciales**: 3
- **Espacio disponible inicial**: 27
- **Al comprar lote (tecla 4)**: Se intenta agregar 3 gallinas, pero solo entran si hay espacio

---

## 3. Arquitectura y Árbol de Nodos

### 3.1 Estructura Jerárquica de la Escena Principal

```
Main (Node2D) [main.gd]
│
├── UIManager (Node) [ui_manager.gd]
│   ├── HUD (CanvasLayer)
│   │   └── HBoxContainer
│   │       ├── LabelDay
│   │       ├── LabelVaccines
│   │       ├── LabelMedications
│   │       ├── BalanceLabel
│   │       ├── InventarioLabel
│   │       └── DeudaLabel
│   ├── LabelInstruction (Label)
│   ├── GameOverPanel (PanelContainer)
│   │   └── VBoxContainer
│   │       ├── LabelGameOver
│   │       └── RestartButton
│   └── EventBanner (PanelContainer)
│       └── LabelEvento
│
├── HenManager (Node2D) [hen_manager.gd]
│   └── [Instancias dinámicas de hen.tscn]
│       └── [Múltiples nodos Hen]
│
├── Player (CharacterBody2D) [player.gd]
│   └── AnimatedSprite2D
│
├── Model3Disease (Node) [model3_disease.gd]
│   └── [Cálculos epidemiológicos SIR]
│
├── Model4Queues (Node) [model4_queues.gd]
│   └── [Cálculos de esperanza de vida]
│
├── Model5Economy (Node) [model5_economy.gd]
│   └── [Eventos económicos y cadena de suministro]
│
└── MapBackground (Node2D) [map_background.gd]
    └── [Dibuja zonas visuales del galpón]
```

### 3.2 Patrón de Arquitectura

El proyecto sigue el patrón **Director + Managers + Models**:

```
┌─────────────────────────────────────────────┐
│           INPUT → KEYBOARD                  │
└──────────────┬──────────────────────────────┘
               │
               ▼
       ┌───────────────┐
       │  main.gd      │ ← DIRECTOR
       │  (Main Node)  │
       └───┬───────┬───┴─────────┬────────────┐
           │       │             │            │
           ▼       ▼             ▼            ▼
      UIManager  HenManager  Modelos    Económico
                             Físicos    (Model5)
      ▲         ▲  ▲        ▲ ▲ ▲         ▲
      │         │  │        │ │ │         │
      └─────────┘  │        │ │ └─────────┘
                   │        │ │
                   └────────┼─┘
                            │
                     ┌──────▼─────┐
                     │  hen.gd    │
                     │  (Entidad) │
                     └────────────┘
```

### 3.3 Flujo de Comunicación

1. **Input Stage**: El jugador presiona una tecla
2. **Decision Stage**: `main._unhandled_input()` procesa la entrada
3. **Action Stage**: Se envía comando al componente correspondiente
4. **Calculation Stage**: El modelo o manager calcula el resultado
5. **Visualization Stage**: Se actualiza la pantalla mediante UIManager
6. **Feedback Stage**: Se emiten señales para eventos importantes

**Ejemplo: Presionar tecla 3 (Avanzar día)**

```
Player presses 3
    ↓
main._unhandled_input() detects KEY_3
    ↓
main._advance_day() called
    ↓
player.try_use_vaccine() / try_use_medicine()
    ↓
disease_model.process_next_day(used_vaccine, used_medicine)
    ↓
disease_model emits "day_processed" signal
    ↓
main._on_day_processed() callback executed
    ↓
hen_manager.apply_state_changes()
    ↓
hen_manager.process_survival()
    ↓
hen_manager.notify_deads()
    ↓
ui_manager.update_hud()
    ↓
model5_economy.process_day()
    ↓
Screen updates with new state
```

---

## 4. Flujo del Ciclo Diario

### 4.1 Secuencia Completa de un Día

Cuando el jugador presiona **3** para avanzar al siguiente día, ocurre esta cascada de eventos:

```
┌─────────────────────────────────────────────────────────────┐
│  INICIO DE CICLO DIARIO                                     │
└─────────────────────────────────────────────────────────────┘

1. EXTRACCIÓN DE RECURSOS DEL JUGADOR
   ├─ player.try_use_vaccine()
   │  └─ Si tiene vacuna → vaccine_inventory--
   │     Si no → retorna false
   │
   └─ player.try_use_medicine()
      └─ Si tiene medicina → medicine_inventory--
         Si no → retorna false

2. SIMULACIÓN EPIDEMIOLÓGICA (MODELO 3)
   ├─ Entrada:
   │  ├─ Población susceptible (S)
   │  ├─ Población infectada (I)
   │  ├─ Población total (N)
   │  ├─ used_vaccine (bool)
   │  └─ used_medicine (bool)
   │
   ├─ Cálculos:
   │  ├─ crowding_factor = N / capacity
   │  ├─ environmental_viral_load += crowding_factor × 0.05
   │  ├─ Si used_vaccine: viral_load -= 0.15
   │  ├─ effective_beta = β × 0.15 [si vacuna] o β [si no]
   │  ├─ effective_gamma = 0.75 [si medicina] o 0.05 [si no]
   │  ├─ flow_direct = effective_beta × crowding × I × (S/N)
   │  ├─ flow_environmental = viral_load × S × 0.10
   │  ├─ new_infections = floor(flow_direct + flow_environmental)
   │  └─ new_recoveries = floor(effective_gamma × I)
   │
   ├─ Salida (reporte):
   │  ├─ day (número de día)
   │  ├─ S (susceptibles)
   │  ├─ I (infectados)
   │  ├─ N (población total)
   │  ├─ nuevos_contagiados (int)
   │  ├─ nuevas_curadas (int)
   │  └─ penalidad_vida (2.0 sin medicina, 0.0 con medicina)
   │
   └─ Emite signal: day_processed(reporte)

3. APLICACIÓN DE CAMBIOS DE ESTADO (HEN MANAGER)
   ├─ apply_state_changes(new_sick, new_recovered)
   │  ├─ Selecciona aleatoriamente new_sick gallinas sanas
   │  │  └─ Cambia estado 0 → 1 (SANA → ENFERMA)
   │  │
   │  └─ Selecciona aleatoriamente new_recovered gallinas enfermas
   │     └─ Cambia estado 1 → 2 (ENFERMA → RECUPERADA)
   │
   └─ Visualmente: Los colores de las gallinas cambian

4. PROCESAMIENTO DE SUPERVIVENCIA (MODELO 4)
   ├─ process_survival(survival_model)
   │  ├─ Para cada gallina activa:
   │  │  ├─ age += 1
   │  │  ├─ health -= DAILY_WEAR (1.0)
   │  │  ├─ Si está enferma: health -= PENALTY_SICK (2.0)
   │  │  ├─ Si health <= 0 o age >= max_health:
   │  │  │  └─ set_state(3) [MUERTA]
   │  │  └─ Retorna lista actualizada
   │  │
   │  └─ active_hens actualizado con gallinas sobrevivientes
   │
   └─ Imprime debug: "Gallina X | Edad Y | Salud Z/Max"

5. NOTIFICACIÓN DE MUERTES
   ├─ notify_deads(disease_model)
   │  ├─ Para cada gallina muerta:
   │  │  ├─ disease_model.report_chicken_death(estado)
   │  │  │  └─ total_population--
   │  │  │  └─ Si era enferma: infected--
   │  │  │
   │  │  └─ hen.dead = true
   │  │
   │  └─ La gallina permanece en pantalla pero inmóvil
   │
   └─ El modelo epidemiológico se ajusta a la nueva población

6. ACTUALIZACIÓN DE DÍA EN MAIN
   └─ day = reporte["day"]

7. INTERFAZ GRÁFICA
   ├─ ui_manager.update_hud(day, player)
   │  ├─ label_day.text = "Día X / 30"
   │  ├─ label_vaccines.text = player.vaccine_inventory
   │  ├─ label_medications.text = player.medicine_inventory
   │  └─ balance/inventory/debt labels actualizado
   │
   └─ Si corresponde: show_event_banner() muestra notificaciones

8. PRODUCCIÓN DE HUEVOS (MODELO 1)
   ├─ produccion = 0
   ├─ Para cada gallina sana (state == 0):
   │  └─ Si randf() < TASA_POSTURA (0.8):
   │     └─ produccion += 1
   │
   └─ produccion es el total de huevos del día

9. EVENTOS ECONÓMICOS (MODELO 5)
   ├─ model5_economy.process_day(
   │      day,
   │      hen_manager.active_hens.size(),
   │      produccion,
   │      0,  # robos (Model 2 no implementado)
   │      disease_model.infected
   │  )
   │
   ├─ Dentro del Modelo 5:
   │  ├─ inventario_huevos += produccion
   │  ├─ Descuenta costos diarios:
   │  │  └─ balance_caja -= (costo_alimento_dia × N_gallinas) + 5000
   │  │
   │  ├─ Verifica bancarrota:
   │  │  └─ Si balance_caja <= 0: game_over("BANCARROTA")
   │  │
   │  └─ Procesa eventos del día (comprador, banquero, etc.)
   │     ├─ Si día 5, 10, 15, 20, 25, 30: COMPRADOR llega
   │     ├─ Si día 7, 14, 21, 28: Nuevo PRECIO_HUEVO aleatorio
   │     ├─ Si día 8, 16, 24: Nuevo COSTO_MAIZ aleatorio
   │     ├─ Si día 10, 20, 30: BANQUERO visita
   │     ├─ Días impares con prob 15%: INSPECCION
   │     ├─ Días 5-25 con prob 20%: OFERTA_VACUNAS
   │     ├─ Días pares con prob 10%: VENTA_VECINO
   │     └─ Emite señales para mostrar en pantalla
   │
   ├─ Emite: balance_actualizado(nuevo_balance, acumulado)
   └─ Emite: game_over(tipo) si se cumplen condiciones

10. VERIFICACIÓN DE FIN DE JUEGO
    ├─ Si todas las gallinas están muertas:
    │  └─ game_over("TODAS_MUERTAS")
    │
    └─ Si Modelo 5 emitió game_over:
       └─ is_running = false

11. DEBUG OUTPUT
    ├─ Imprime:
    │  ├─ "---------- ESTADO DE GALLINAS — Día X ----------"
    │  ├─ Información de cada gallina
    │  └─ Resumen general
    │
    └─ Los logs ayudan a validar que los modelos funcionan

└─────────────────────────────────────────────────────────────┘
  FIN DE CICLO DIARIO — Vuelve a estar esperando input del jugador
```

### 4.2 Diagrama de Datos del Reporte Diario

Cuando `Model3Disease` emite `day_processed`, envía un diccionario con esta estructura:

```gdscript
{
    "day": int,                              # Día actual (1-30)
    "S": int,                                # Susceptibles
    "I": int,                                # Infectados
    "N": int,                                # Población total
    "carga_viral_ambiental": float,          # Nivel de virus en el aire
    "flujo_contagio_directo": float,         # Contagios de contacto
    "flujo_contagio_ambiental": float,       # Contagios del aire
    "flujo_recuperacion": float,             # Tasa de recuperación
    "nuevos_contagiados": int,               # Contagios a aplicar
    "nuevas_curadas": int,                   # Recuperaciones a aplicar
    "penalidad_vida": float                  # Penalización de salud del día
}
```

---

## 5. Modelos de Simulación Matemática

### 5.1 Modelo 1: Producción Diaria de Huevos (Monte Carlo)

**Tipo**: Estocástico con distribución de Bernoulli  
**Ubicación**: `scripts/models/model1_production.gd`  
**Responsabilidad**: Calcular diariamente cuántos huevos produce el galpón

#### Fórmula Base

```
Huevos_día = Σ X_i,  donde X_i ~ Bernoulli(p_i)

p_i = p_base × f_edad × f_alimento × f_estrés

donde:
  p_base = 0.75 (probabilidad base de postura)
  f_edad = health_actual / health_máximo (factor por edad)
  f_alimento = 1.0 (normal) o 1.1 (con fórmula especial)
  f_estrés = 1.0 (sana) o 0.7 (enferma)
```

#### Parámetros Clave

```gdscript
const P_BASE = 0.75                 # Probabilidad base de postura
const F_LUZ_DEFAULT = 1.0           # Factor luz (sin control)
const F_ALIM_NORMAL = 1.0           # Alimentación normal
const F_ALIM_ESPECIAL = 1.1         # Con fórmula del abuelo (Subtrama 1)
const F_ESTRES_SANA = 1.0           # Sin estrés
const F_ESTRES_ENFERMA = 0.7        # Gallina enferma
const P_BASE_ESPECIAL = 0.90        # Para gallinas especiales (Subtrama 3)
```

#### Función Principal

```gdscript
func simulate_production(active_hens: Array, dia_actual: int) -> int:
    var huevos_dia = 0
    
    for gallina in active_hens:
        if gallina.dead: continue
        
        var p_base_gallina = P_BASE_ESPECIAL si es_gallina_especial else P_BASE
        var factor_edad = gallina.health / gallina.max_health
        var factor_alimento = F_ALIM_ESPECIAL si formula_activa else F_ALIM_NORMAL
        var factor_estrés = F_ESTRES_ENFERMA si gallina.state == ENFERMA else F_ESTRES_SANA
        
        var p_individual = p_base_gallina * factor_edad * factor_alimento * factor_estrés
        p_individual = clamp(p_individual, 0.0, 1.0)
        
        if randf() < p_individual:
            huevos_dia += 1
    
    return huevos_dia
```

#### Integración

- Calcula **diariamente** la producción total
- Lo utiliza **Model5Economy** para determinar inventario de huevos
- Las vacunas/medicinas **no afectan directamente** la producción, solo la enfermedad

---

### 5.2 Modelo 2: Control de Plagas - ABM (Agent Based Model)

**Tipo**: Agentes Basados en Modelos (ABM) con dinámica exponencial  
**Ubicación**: `scripts/models/model2_abm.gd`  
**Responsabilidad**: Simular una colonia de roedores que roban huevos

#### Concepto

Cada roedor es un agente autónomo con:
- **Posición**: (x, y) en el mapa
- **Estado**: Vivo o muerto
- **Comportamiento**: Movimiento hacia zona de huevos, robo, captura por trampa

#### Fórmula de Crecimiento

```
N(t+1) = N(t) × λ,  donde λ = 1.10

Crecimiento sin intervención: +10% diario
Capturas diarias reducen población
```

#### Parámetros Clave

```gdscript
const N_INICIAL = 3                 # Roedores iniciales
const TASA_REPRODUCCION = 1.10      # Crecimiento diario
const UMBRAL_COLONIA = 15           # Incontrolable si > 15
const RADIO_MOVIMIENTO = 80.0       # Píxeles por turno
const ALPHA_ROBO = 0.25             # Huevos robados por roedor
const P_CAP_BASE = 0.25             # Probabilidad de captura por trampa
```

#### Mecánica de Robo

```gdscript
var huevos_robados_acumulados = 0

for roedor in colonia:
    if roedor.vivo:
        _mover_roedor(roedor)
        
        # Bernoulli(ALPHA_ROBO): intenta robar
        if huevos_disponibles > 0 and randf() < ALPHA_ROBO:
            robos_del_día += 1
            huevos_disponibles -= 1
        
        # Verificar captura por trampa
        for trampa in trampas:
            distancia = distance_to(trampa)
            if distancia < 60.0 and randf() < P_CAP_BASE:
                roedor.vivo = false
```

#### Estado Actual

⚠️ **MODELO 2 NO ESTÁ COMPLETAMENTE INTEGRADO**

- Las trampas y el robo de huevos están **codificados pero no utilizados**
- El parámetro `robos` en `model5_economy.process_day()` es siempre **0**
- Los huevos robados acumulados no se restan del inventario final
- Preparado para integración futura

---

### 5.3 Modelo 3: Dinámica de Enfermedades (SIR - Epidemiología)

**Tipo**: Dinámica de Sistemas (SIR)  
**Ubicación**: `scripts/models/model3_disease.gd`  
**Responsabilidad**: Simular propagación de enfermedad en población cerrada

#### Modelo SIR Clásico

```
Población dividida en tres categorías:
  S (Susceptibles): Pueden enfermarse
  I (Infectados): Propagan la enfermedad
  R (Recuperados): Inmunes, no se pueden enfermar de nuevo

Transiciones:
  S → I: Contagio (directo o ambiental)
  I → R: Recuperación natural o con medicina
```

#### Fórmulas de Flujo Diario

```
crowding_factor = total_population / max_capacity
viral_load_ambiental += crowding_factor × 0.05  [cada día]

Si se usa vacuna:
  viral_load_ambiental -= 0.15
  β_efectivo = β × 0.15  (85% de reducción)
Si no:
  β_efectivo = β = 3

Si se usa medicina:
  γ_efectivo = 0.75  (tasa de recuperación alta)
Si no:
  γ_efectivo = 0.05  (tasa base baja)

Contagio directo = β_efectivo × crowding × I × (S/N)
Contagio ambiental = viral_load × S × 0.10
Recuperación = γ_efectivo × I

Nuevos infectados = floor(contagio_directo + contagio_ambiental)
Nuevos recuperados = floor(recuperación)

Acum_inflows += nuevos_infectados  [Acumula fracciones]
Acum_outflows += nuevos_recuperados
```

#### Inicialización

```gdscript
func initialize_model(p_total_pop: int, p_capacity: float) -> void:
    total_population = p_total_pop
    infected = 1                   # Paciente cero
    
    base_contagiousness = 3        # β
    crowding_sensitivity = 0.35    # Sensibilidad a aglomeración
    base_recovery_rate = 0.05      # γ base
    max_capacity = p_capacity      # 30 gallinas
    
    current_day = 0
    acum_infections = 0.0
    acum_recoveries = 0.0
```

#### Parámetros Clave

```gdscript
base_contagiousness = 3            # β: tasa base de contagio
crowding_sensitivity = 0.35        # Multiplicador de aglomeración
base_recovery_rate = 0.05          # γ: tasa base de recuperación
max_capacity = 30                  # Capacidad del galpón
penalty_health_base = 2.0          # Penalización de salud/día sin medicina
```

#### Función Principal

```gdscript
func process_next_day(used_vaccine: bool, used_medicine: bool) -> void:
    var susceptible = max(total_population - infected, 0)
    var crowding_factor = float(total_population) / max_capacity
    
    environmental_viral_load += crowding_factor * 0.05
    
    if used_vaccine:
        environmental_viral_load = max(0.0, environmental_viral_load - 0.15)
    
    var effective_beta = 0.45 if used_vaccine else 3.0
    var effective_gamma = 0.75 if used_medicine else 0.05
    
    var flow_direct = effective_beta * crowding_factor * infected * (susceptible / total_population)
    var flow_environmental = environmental_viral_load * susceptible * 0.10
    var flow_recoveries = effective_gamma * infected
    
    var new_infections = floor(flow_direct + flow_environmental)
    var new_recoveries = floor(flow_recoveries)
    
    infected = clamp(infected + new_infections - new_recoveries, 0, total_population)
    
    day_processed.emit({
        "day": current_day,
        "nuevos_contagiados": new_infections,
        "nuevas_curadas": new_recoveries,
        "penalidad_vida": 2.0 if not used_medicine else 0.0
    })
```

#### Mecanismos de Control

| Acción | Efecto | Costo |
|--------|--------|-------|
| **Vacuna** | Reduce β en 85%, reduce viral_load en 0.15 | $15.000 |
| **Medicina** | Aumenta γ de 0.05 a 0.75, evita penalidad de salud | $8.000 |
| Ambas juntas | Máxima contención (contagios casi 0) | $23.000 |

---

### 5.4 Modelo 4: Supervivencia y Esperanza de Vida (Teoría de Colas)

**Tipo**: Teoría de Colas + Análisis de Supervivencia  
**Ubicación**: `scripts/models/model4_queues.gd`  
**Responsabilidad**: Asignar vida a gallinas y procesarlas por desgaste natural

#### Asignación de Vida

Cuando una gallina nace (nueva o comprada):

```
z ~ N(0,1)  [Normal estándar, Box-Muller]
μ = 25.0    [Media de vida base]
σ = 2.0     [Desviación estándar]

max_health = μ + σ × z

Si vacunada: max_health += VACCINE_BONUS (5.0)

Restricción: max_health >= 1.0  [Nunca muere al nacer]
```

#### Parámetros Clave

```gdscript
const MU_BASE = 25.0               # Media de vida (días)
const SIGMA_BASE = 2.0             # Desviación estándar
const VACCINE_BONUS = 5.0          # Bonificación si nace vacunada
const PENALTY_SICK = 2.0           # Pérdida extra si enferma
const DAILY_WEAR = 1.0             # Desgaste diario normal
```

#### Procesamiento Diario de Supervivencia

```gdscript
func process_survival_queue(active_hens: Array) -> Array:
    for hen in active_hens:
        if hen.dead: continue
        
        var was_sick = (hen.current_state == 1)
        
        hen.age += 1                       # Envejece
        hen.health -= DAILY_WEAR (1.0)     # Desgaste normal
        
        if was_sick:
            hen.health -= PENALTY_SICK (2.0)  # Penalidad adicional
        
        # Muerte por edad o salud agotada
        if hen.health <= 0 or hen.age >= int(hen.max_health):
            hen.health = 0
            hen.set_state(3)  # Marca como muerta
            hen.is_moving = false
    
    return active_hens  # Con gallinas muertas marcadas
```

#### Función Box-Muller para Números Aleatorios

```gdscript
func _generate_standard_normal() -> float:
    var u1 = max(randf(), 0.0001)  # Evita log(0)
    var u2 = randf()
    return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
```

#### Capacidad y Llegada de Lotes

```gdscript
func arrive_batch(hens_to_add: Array, active_hens: Array) -> int:
    var space_available = capacity_k - active_hens.size()
    var to_add = min(hens_to_add.size(), space_available)
    
    for i in range(to_add):
        initialize_hen(hens_to_add[i], false)  # No vacunadas
        active_hens.append(hens_to_add[i])
    
    return to_add  # Número realmente agregado
```

#### Utilidades

```gdscript
# Promedio de edad actual
func get_average_age(active_hens: Array) -> float:
    if active_hens.is_empty(): return 0.0
    var total = 0.0
    for hen in active_hens: total += hen.age
    return total / active_hens.size()

# Promedio de vida restante
func get_average_remaining_life(active_hens: Array) -> float:
    if active_hens.is_empty(): return 0.0
    var total = 0.0
    for hen in active_hens: total += hen.health
    return total / active_hens.size()

# Predicción de muertes en N días
func forecast_deaths(active_hens: Array, days_ahead: int) -> int:
    var count = 0
    for hen in active_hens:
        if hen.state != 3 and hen.health <= days_ahead:
            count += 1
    return count
```

---

### 5.5 Modelo 5: Economía y Cadena de Suministro

**Tipo**: Cadena de Suministro + Eventos Estocásticos  
**Ubicación**: `scripts/models/model5_economy.gd`  
**Responsabilidad**: Gestionar dinero, deuda, precios, eventos e inspecciones

#### Estructura de Variables de Estado

```gdscript
var balance_caja = 1_000_000.0         # Dinero disponible ($COP)
var inventario_huevos = 0              # Huevos acumulados (sin vender)
var precio_huevo = 800                 # Precio/unidad actual
var costo_alimento_dia = 140           # Costo/gallina/día
var acumulado_ventas = 0.0             # Total histórico vendido
```

#### Constantes de Rango Económico

```gdscript
const DEUDA_TOTAL = 1_500_000.0        # Debe pagar en 30 días
const BALANCE_INICIAL = 1_000_000.0    # Dinero inicial
const COSTOS_AGUA_LUZ = 5_000.0        # Servicios fijos/día

const PRECIO_HUEVO_MIN = 600
const PRECIO_HUEVO_MAX = 1200
const COSTO_MAIZ_MIN = 80
const COSTO_MAIZ_MAX = 200
const MULTA_MIN = 100_000.0
const MULTA_MAX = 500_000.0
```

#### Fórmula de Costos Diarios

```
costos_día = (costo_alimento_día × número_gallinas) + gastos_servicios
           = (costo_alimento × N) + 5000

balance_caja -= costos_día
```

#### Fórmula de Ingresos (Comprador)

```
ingreso = inventario_huevos × precio_huevo
acumulado_ventas += ingreso
balance_caja += ingreso
inventario_huevos = 0  # Se venden todos
```

#### Calendario de Eventos Deterministas

| Evento | Días | Descripción |
|--------|------|-------------|
| **Comprador** | 5, 10, 15, 20, 25, 30 | Compra todos los huevos acumulados |
| **Precio Huevo** | 7, 14, 21, 28 | Nuevo precio aleatorio U[600,1200] paso 50 |
| **Costo Maíz** | 8, 16, 24 | Nuevo costo de alimento U[80,200] paso 20 |
| **Banquero** | 10, 20, 30 | Visita. En día 30: verifica deuda pagada |

#### Eventos Estocásticos

| Evento | Días | Probabilidad | Efecto |
|--------|------|-------------|--------|
| **Inspección** | Impares | 15% (Bernoulli) | Multa U[100k,500k] si hay infectadas |
| **Oferta Vacunas** | 5-25 | 20% (Bernoulli) | Notificación: 40% descuento |
| **Venta Vecino** | Pares | 10% (Bernoulli) | Precio baja en $50 (compra competencia) |

#### Función Principal del Modelo

```gdscript
func process_day(dia_actual: int, n_gallinas: int, produccion: int, robos: int, n_infectadas: int) -> void:
    # 1. Actualizar inventario
    inventario_huevos += produccion - robos
    
    # 2. Descontar costos
    var costos_dia = costo_alimento_dia * n_gallinas + COSTOS_AGUA_LUZ
    balance_caja -= costos_dia
    
    # 3. Verificar bancarrota
    if balance_caja <= 0:
        emit_signal("game_over", "BANCARROTA")
        return
    
    # 4. Procesar eventos del día
    for evento in _cola_eventos:
        if evento["dia"] == dia_actual:
            _procesar_evento(evento["tipo"], dia_actual)
    
    # 5. Emitir actualización
    emit_signal("balance_actualizado", balance_caja, acumulado_ventas)
```

#### Procesamiento de Evento: Inspección

```gdscript
"INSPECCION":
    if n_infectadas > 0:
        var multa = uniform_continua(MULTA_MIN, MULTA_MAX)
        balance_caja -= multa
        emit_signal("inspeccion_ocurrio", multa)
    else:
        emit_signal("inspeccion_superada")
```

#### Verificación de Victoria/Derrota

```gdscript
"BANQUERO" en día 30:
    deuda_restante = DEUDA_TOTAL - acumulado_ventas
    
    if acumulado_ventas >= DEUDA_TOTAL:
        emit_signal("game_over", "VICTORIA")
    else:
        emit_signal("game_over", "EMBARGO")
```

#### Distribuciones Aleatorias

```gdscript
# Bernoulli(p): Sí/No con probabilidad p
func _bernoulli(p: float) -> bool:
    return randf() < p

# Uniforme Discreta con paso
func _uniforme_discreta(min, max, paso) -> int:
    var n = (max - min) / paso
    return min + randi_range(0, n) * paso

# Uniforme Continua
func _uniforme_continua(min, max) -> float:
    return randf_range(min, max)
```

---

## 6. Eventos del Modelo Económico

### 6.1 Calendario Completo de Eventos (30 días)

```
DÍA 1 (Miércoles)
├─ [Evento] INSPECCION (si 15% Bernoulli)
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

DÍA 2 (Jueves)
├─ [Nada determinista]
└─ Costos de comida y servicios descontados

DÍA 3 (Viernes)
├─ [Evento] INSPECCION (si 15% Bernoulli)
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 5 (Domingo)
├─ [Evento] COMPRADOR llega
│  └─ Compra: inventario_huevos × precio_huevo
│  └─ acumulado_ventas += ingreso
│  └─ balance_caja += ingreso
│  └─ inventario_huevos = 0
│
├─ [Evento] OFERTA_VACUNAS (si 20% Bernoulli, días 5-25)
│  └─ Notificación: "¡Vacunas con 40% descuento!"
│
├─ [Evento] INSPECCION (si 15% Bernoulli, días impares)
│  └─ Si hay infectadas: multa U[100k,500k]
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli, días pares)
   └─ precio_huevo = MAX(600, precio_huevo - 50)

...

DÍA 7 (Martes)
├─ [Evento] PRECIO_HUEVO
│  └─ precio_huevo = U[600, 1200] paso 50
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 8 (Miércoles)
├─ [Evento] COSTO_MAIZ
│  └─ costo_alimento_dia = U[80, 200] paso 20
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 10 (Viernes)
├─ [Evento] COMPRADOR llega
│  └─ (igual que día 5)
│
├─ [Evento] BANQUERO visita
│  └─ deuda_restante = DEUDA_TOTAL - acumulado_ventas
│  └─ Notificación: "🏦 Deuda restante: $X"
│
├─ [Evento] INSPECCION (si 15% Bernoulli, días impares)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli, días pares)

...

DÍA 14 (Martes)
├─ [Evento] PRECIO_HUEVO
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 15 (Miércoles)
├─ [Evento] COMPRADOR llega
│
├─ [Evento] OFERTA_VACUNAS (si 20% Bernoulli)
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 16 (Jueves)
├─ [Evento] COSTO_MAIZ
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 20 (Lunes)
├─ [Evento] COMPRADOR llega
│
├─ [Evento] BANQUERO visita
│  └─ Notificación: "🏦 Deuda restante: $X"
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 21 (Martes)
├─ [Evento] PRECIO_HUEVO
│
├─ [Evento] OFERTA_VACUNAS (si 20% Bernoulli, última oportunidad)
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 24 (Viernes)
├─ [Evento] COSTO_MAIZ
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 25 (Sábado)
├─ [Evento] COMPRADOR llega
│
├─ [Evento] OFERTA_VACUNAS (si 20% Bernoulli, última oportunidad)
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 28 (Martes)
├─ [Evento] PRECIO_HUEVO
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)

...

DÍA 30 (Jueves) - DÍA FINAL
├─ [Evento] COMPRADOR llega
│  └─ Última venta de huevos
│
├─ [Evento] BANQUERO visita
│  └─ VERIFICA DEUDA
│  ├─ Si acumulado_ventas >= DEUDA_TOTAL:
│  │  └─ VICTORIA: "¡Granja salvada! Deuda pagada."
│  └─ Si acumulado_ventas < DEUDA_TOTAL:
│     └─ EMBARGO: "El banquero ejecutó el embargo."
│
├─ [Evento] INSPECCION (si 15% Bernoulli)
│
└─ [Evento] VENTA_VECINO (si 10% Bernoulli)
```

### 6.2 Probabilidades y Distribuciones

| Evento | Tipo | Días | Probabilidad | Rango |
|--------|------|------|-------------|-------|
| **Comprador** | Determinista | 5,10,15,20,25,30 | 100% | - |
| **Precio Huevo** | Determinista | 7,14,21,28 | 100% | $600-$1200 (paso $50) |
| **Costo Maíz** | Determinista | 8,16,24 | 100% | $80-$200 (paso $20) |
| **Banquero** | Determinista | 10,20,30 | 100% | - |
| **Inspección** | Estocástico | Días impares | 15% | Multa $100k-$500k |
| **Oferta Vacunas** | Estocástico | 5-25 | 20% | Notificación |
| **Venta Vecino** | Estocástico | Días pares | 10% | -$50 al precio |

### 6.3 Señales Emitidas por Model5Economy

```gdscript
signal comprador_llego(ingreso: float)           # Comprador llegó
signal precio_actualizado(nuevo_precio: int)     # Nuevo precio
signal costo_maiz_actualizado(nuevo_costo: int)  # Nuevo costo
signal banquero_visito(deuda_restante: float)    # Banquero visitó
signal inspeccion_ocurrio(multa: float)          # Multa aplicada
signal inspeccion_superada()                     # Inspección pasada
signal oferta_vacunas_disponible()               # Oferta disponible
signal vecino_vendio(nuevo_precio: int)          # Vecino bajó precio
signal balance_actualizado(nuevo_balance, acumulado)  # Balance actualizado
signal game_over(tipo: String)                   # Juego terminó
```

---

## 7. Estados de las Gallinas

### 7.1 Máquina de Estados

Cada gallina puede estar en uno de cuatro estados:

```
┌─────────────────────────────────────────────────────────┐
│               MÁQUINA DE ESTADOS (FSM)                  │
└─────────────────────────────────────────────────────────┘

                      ┌─────────────┐
                      │    SANA     │ (Estado 0)
                      │  (HEALTHY)  │
                      └──────┬──────┘
                             │
                             │ Contagio (Model3)
                             │ apply_state_changes()
                             ▼
                      ┌─────────────┐
                      │  ENFERMA    │ (Estado 1)
                      │   (SICK)    │
                      └──────┬──────┘
                             │
                             │ Recuperación (Model3)
                             │ apply_state_changes()
                             ▼
                      ┌─────────────┐
                      │ RECUPERADA  │ (Estado 2)
                      │(RECOVERED)  │
                      └──────┬──────┘
                             │
                             │ Envejecimiento natural (Model4)
                             │ o salud agotada
                             ▼
                      ┌─────────────┐
                      │   MUERTA    │ (Estado 3)
                      │   (DEAD)    │
                      └─────────────┘

Nota: Una RECUPERADA puede enfermar nuevamente si es contagiada,
      pero MUERTA es estado final.
```

### 7.2 Atributos de Estado Individual

Cada gallina (`hen.gd`) tiene estos atributos:

```gdscript
var current_state : int = State.HEALTHY    # 0=SANA, 1=ENFERMA, 2=RECUPERADA, 3=MUERTA

# Salud y Edad (Modelo 4)
var health : float                         # Salud actual
var max_health : float                     # Salud máxima (asignada al nacer)
var age : int = 0                          # Edad en días

# Marcadores
var dead : bool = false                    # ¿Está muerta?

# Movimiento
var direction : Vector2 = Vector2.ZERO     # Dirección de movimiento
var speed : float = 80.0                   # Píxeles/segundo
var is_moving : bool = false               # ¿Se mueve?
```

### 7.3 Colores Visuales por Estado

| Estado | Color RGB | Apariencia |
|--------|-----------|-----------|
| **SANA (0)** | (0.961, 0.773, 0.259) | Amarillo oro |
| **ENFERMA (1)** | (0.478, 0.549, 0.416) | Verde oscuro grisáceo |
| **RECUPERADA (2)** | (0.647, 0.808, 0.537) | Verde claro |
| **MUERTA (3)** | (0.290, 0.290, 0.290) | Gris oscuro |

### 7.4 Transiciones de Estado

#### Transición 0 → 1 (SANA → ENFERMA)

```gdscript
# Ocurre en hen_manager.apply_state_changes()
# Model3 calcula nuevos_contagiados
# HenManager selecciona aleatoriamente esa cantidad de gallinas sanas
for i in range(new_sick):
    var healthy = active_hens.filter(func(h): return h.current_state == 0)
    if healthy.size() > 0:
        healthy.pick_random().set_state(1)  # Cambio visual

# Consecuencias:
# - Gallina cambia color a verde
# - Pierde salud rápidamente (-3.0/día: -1.0 desgaste + -2.0 enfermedad)
# - Reduce producción de huevos (factor 0.7)
# - Propaga enfermedad a otras
```

#### Transición 1 → 2 (ENFERMA → RECUPERADA)

```gdscript
# Ocurre en hen_manager.apply_state_changes()
# Model3 calcula nuevas_curadas
for i in range(new_recovered):
    var sick = active_hens.filter(func(h): return h.current_state == 1)
    if sick.size() > 0:
        sick.pick_random().set_state(2)  # Cambio visual

# Consecuencias:
# - Gallina cambia color a verde claro
# - Ya no propaga enfermedad
# - Tiene inmunidad (NO se puede enfermar de nuevo)
# - Recupera producción de huevos (factor normal 1.0)
# - Continúa envejeciendo normalmente
```

#### Transición 2 → 3 (RECUPERADA/SANA → MUERTA)

```gdscript
# Ocurre en model4_queues.process_survival_queue()
for hen in active_hens:
    hen.age += 1
    hen.health -= DAILY_WEAR
    
    if hen.current_state == SICK:
        hen.health -= PENALTY_SICK
    
    if hen.health <= 0 or hen.age >= hen.max_health:
        hen.set_state(3)  # Muerte

# Ocurre cuando:
# - Salud se agota (health <= 0)
# - O edad alcanza max_health asignado

# Consecuencias:
# - Gallina cambia color a gris
# - Deja de moverse
# - Desaparece de población activa en conteos
# - Model3 es notificado para actualizar datos epidemiológicos
```

### 7.5 Ciclo de Vida Ejemplo

```
Día 1: Gallina nace
├─ max_health = 25 ± 2 (distribución normal)
├─ health = max_health
├─ age = 0
├─ current_state = 0 (SANA)
└─ Color: Amarillo

Día 1-5: Gallina produce huevos, se mueve normalmente
└─ health disminuye 1/día
└─ age aumenta 1/día

Día 3: Contagio
├─ health: 22
├─ age: 3
├─ current_state = 1 (ENFERMA)
├─ Color: Verde oscuro
└─ health disminuirá 3/día (1 desgaste + 2 enfermedad)

Día 5: Recuperación
├─ health: 18
├─ age: 5
├─ current_state = 2 (RECUPERADA)
├─ Color: Verde claro
├─ Inmunidad ganada (no se contagia de nuevo)
└─ health disminuirá 1/día (solo desgaste)

Día 22: Muerte por envejecimiento
├─ health: 0 (22 - 1*22 = 0)
├─ age: 22
├─ current_state = 3 (MUERTA)
├─ Color: Gris
└─ Galería: Inmóvil
```

---

## 8. Constantes Claves del Juego

### 8.1 Configuración Global (main.gd)

```gdscript
const MAX_DAYS : int = 30              # Duración máxima de la partida
const NUMBER_OF_HENS : int = 3         # Gallinas iniciales
const GALPON_CAPACITY : int = 30       # Capacidad máxima del galpón
const BATCH_SIZE : int = 3             # Gallinas por compra (tecla 4)
```

### 8.2 Modelo 3 - Enfermedad (model3_disease.gd)

```gdscript
base_contagiousness = 3.0              # β: tasa base de contagio
crowding_sensitivity = 0.35            # Multiplicador de aglomeración
base_recovery_rate = 0.05              # γ: tasa base de recuperación
max_capacity = 30                      # Capacidad del galpón
penalty_health_base = 2.0              # Penalización de salud/día (sin medicina)
```

**Cálculos derivados:**
- Con vacuna: `β_efectivo = β × 0.15` (85% de reducción)
- Sin vacuna: `β_efectivo = β = 3.0`
- Con medicina: `γ_efectivo = 0.75` (tasa alta)
- Sin medicina: `γ_efectivo = 0.05` (tasa baja)

### 8.3 Modelo 4 - Supervivencia (model4_queues.gd)

```gdscript
const MU_BASE : float = 25.0           # Media de vida (días)
const SIGMA_BASE : float = 2.0         # Desviación estándar
const VACCINE_BONUS : float = 5.0      # Bonificación de vacuna en vida
const PENALTY_SICK : float = 2.0       # Penalización extra si enferma
const DAILY_WEAR : float = 1.0         # Desgaste diario normal
```

**Fórmula de max_health:**
```
z ~ N(0,1)
max_health = MU_BASE + SIGMA_BASE × z
max_health = max(max_health, 1.0)
```

### 8.4 Modelo 5 - Economía (model5_economy.gd)

```gdscript
# Estados iniciales
const DEUDA_TOTAL = 1_500_000.0        # Deuda a pagar
const BALANCE_INICIAL = 1_000_000.0    # Dinero inicial
const PRECIO_HUEVO_INICIAL = 800       # Precio inicial por huevo
const COSTO_ALIMENTO_INICIAL = 140     # Costo/gallina/día
const COSTOS_AGUA_LUZ = 5_000.0        # Servicios fijos/día

# Rangos de variación
const PRECIO_HUEVO_MIN = 600
const PRECIO_HUEVO_MAX = 1200
const PRECIO_HUEVO_PASO = 50
const COSTO_MAIZ_MIN = 80
const COSTO_MAIZ_MAX = 200
const COSTO_MAIZ_PASO = 20
const MULTA_MIN = 100_000.0
const MULTA_MAX = 500_000.0

# Probabilidades estocásticas
const P_INSPECCION = 0.15              # Bernoulli(15%) en días impares
const P_OFERTA_VACUNAS = 0.20          # Bernoulli(20%) en días 5-25
const P_VECINO_VENDE = 0.10            # Bernoulli(10%) en días pares
const PRECIO_BAJADA_VECINO = 50        # Baja de precio

# Tasa de producción
const TASA_POSTURA = 0.8               # Probabilidad de postura por gallina sana

# Calendario
const DIAS_COMPRADOR = [5, 10, 15, 20, 25, 30]
const DIAS_PRECIO_HUEVO = [7, 14, 21, 28]
const DIAS_COSTO_MAIZ = [8, 16, 24]
const DIAS_BANQUERO = [10, 20, 30]
```

### 8.5 Hen (hen.gd) - Colores

```gdscript
const COLOR_SANA = Color(0.961, 0.773, 0.259)        # Amarillo oro
const COLOR_ENFERMA = Color(0.478, 0.549, 0.416)     # Verde oscuro
const COLOR_RECUPERADA = Color(0.647, 0.808, 0.537)  # Verde claro
const COLOR_MUERTA = Color(0.290, 0.290, 0.290)      # Gris
```

### 8.6 Player (player.gd)

```gdscript
const SPEED : float = 200.0            # Píxeles por segundo
```

### 8.7 UI - Límites de Pantalla

```gdscript
const SCREEN_WIDTH = 1152.0
const SCREEN_HEIGHT = 648.0
const Y_SKY_END = 50.0                 # Límite superior del galpón
const Y_PENS_END = 268.0               # Límite inferior del galpón
```

---

## 9. Sistema de Inventario y Recursos

### 9.1 Inventarios Disponibles

#### Dinero (Balance de Caja)

- **Variable**: `model5_economy.balance_caja`
- **Rango**: -∞ a ∞ (aunque negativo = bancarrota)
- **Inicial**: $1.000.000 COP
- **Operaciones**:
  - Gana: Venta de huevos (días 5,10,15,20,25,30)
  - Pierde: Costos diarios, compras, multas

#### Huevos

- **Variable**: `model5_economy.inventario_huevos`
- **Rango**: 0 a ∞
- **Producción diaria**: Según Modelo 1 (Bernoulli)
- **Venta automática**: Días 5,10,15,20,25,30 (se venden todos)
- **Cálculo de ingreso**: `inventario_huevos × precio_huevo`

#### Vacunas

- **Variable**: `player.vaccine_inventory`
- **Compra**: Tecla 1, costo $15.000 COP
- **Uso**: Automático al presionar 3 (avanzar día)
- **Efecto**: Reduce contagio directo en 85%, reduce carga viral ambiental
- **Límite**: Ninguno (puede acumular ilimitadamente)

#### Medicinas

- **Variable**: `player.medicine_inventory`
- **Compra**: Tecla 2, costo $8.000 COP
- **Uso**: Automático al presionar 3 (avanzar día)
- **Efecto**: Aumenta tasa de recuperación de 0.05 a 0.75, evita penalización de salud
- **Límite**: Ninguno

#### Gallinas Vivas

- **Variable**: `hen_manager.active_hens` (Array)
- **Inicial**: 3
- **Máximo**: 30 (capacidad del galpón)
- **Compra**: Tecla 4, costo $75.000 COP (lote de 3)
- **Muerte natural**: Según Modelo 4
- **Muerte por enfermedad**: Indirecta (desgaste extra)

### 9.2 Tabla de Compras

| Acción | Tecla | Costo | Requisitos | Efecto |
|--------|-------|-------|-----------|--------|
| **Vacuna** | 1 | $15.000 | balance >= 15.000 | Usa 1 vacuna al día siguiente |
| **Medicina** | 2 | $8.000 | balance >= 8.000 | Usa 1 medicina al día siguiente |
| **Avanzar Día** | 3 | Gratis | - | Ejecuta ciclo diario |
| **Lote de 3 Gallinas** | 4 | $75.000 | balance >= 75.000, espacio > 3 | Agrega 3 gallinas al galpón |

### 9.3 Fórmulas de Cálculo de Recursos

#### Deuda Restante

```
deuda_restante = DEUDA_TOTAL - acumulado_ventas
                = 1_500_000 - acumulado_ventas
```

#### Costos Diarios

```
costos_día = (costo_alimento_día × número_gallinas_activas) + 5000
balance_caja -= costos_día
```

#### Ingreso por Venta de Huevos (Comprador)

```
ingreso = inventario_huevos × precio_huevo
acumulado_ventas += ingreso
balance_caja += ingreso
inventario_huevos = 0
```

#### Condiciones de Victoria/Derrota

```
Victoria: acumulado_ventas >= DEUDA_TOTAL (en día 30)
Derrota Economía: balance_caja <= 0 (en cualquier día)
Derrota Gallinas: todas mueren (en cualquier día)
Embargo: acumulado < DEUDA_TOTAL (en día 30)
```

---

## 10. Assets y Recursos Visuales

### 10.1 Estructura de Assets

```
assets/
├── sprites/
│   ├── banker.png.import
│   ├── creditos.png.import
│   ├── grandfather.png.import
│   ├── hen.png.import
│   ├── instrucciones1.png.import
│   ├── instrucciones2.png.import
│   ├── menu_bg.png.import
│   ├── player.png.import
│   │
│   ├── hen/
│   │   ├── b1.png.import      # Back walk frame 1
│   │   ├── b2.png.import      # Back walk frame 2
│   │   ├── b3.png.import      # Back walk frame 3
│   │   ├── d.png.import       # Dead/idle
│   │   ├── f1.png.import      # Front walk frame 1
│   │   ├── f2.png.import      # Front walk frame 2
│   │   ├── f3.png.import      # Front walk frame 3
│   │   ├── r1.png.import      # Right walk frame 1
│   │   ├── r2.png.import      # Right walk frame 2
│   │   ├── r3.png.import      # Right walk frame 3
│   │   ├── r4.png.import      # Right walk frame 4
│   │   └── s.png.import       # Standing idle
│   │
│   └── player/
│       ├── b1.png.import      # Back walk frame 1
│       ├── b2.png.import      # Back walk frame 2
│       ├── b3.png.import      # Back walk frame 3
│       ├── b4.png.import      # Back walk frame 4
│       ├── f1.png.import      # Front walk frame 1
│       ├── f2.png.import      # Front walk frame 2
│       ├── f3.png.import      # Front walk frame 3
│       ├── f4.png.import      # Front walk frame 4
│       ├── r1.png.import      # Right walk frame 1
│       ├── r2.png.import      # Right walk frame 2
│       ├── r3.png.import      # Right walk frame 3
│       ├── r4.png.import      # Right walk frame 4
│       └── s.png.import       # Standing idle
```

### 10.2 Animaciones

#### Animaciones de Gallinas (hen.tscn)

```
AnimatedSprite2D [hen/]
├── walk_front      [f1, f2, f3] loop
├── walk_back       [b1, b2, b3] loop
├── walk_side       [r1, r2, r3, r4] loop (flip_h posible)
├── idle_front      [s] (único frame, pausa)
└── dead            [d] (único frame)
```

#### Animaciones del Jugador (player.tscn)

```
AnimatedSprite2D [player/]
├── walk_front      [f1, f2, f3, f4] loop
├── walk_back       [b1, b2, b3, b4] loop
├── walk_side       [r1, r2, r3, r4] loop (flip_h posible)
├── idle_front      [s] (único frame)
```

### 10.3 Zona Visual del Galpón (map_background.gd)

```
┌─────────────────────────────────────────────────────────────┐
│ Y=0-50    CIELO ANDINO (Azul claro) — Exterior             │
├─────────────────────────────────────────────────────────────┤
│ Y=50-68   VEGETACIÓN (Verde oscuro) — Pasto perimetral     │
├─────────────────────────────────────────────────────────────┤
│ Y=68-268  CORRALES (Marrón) — Zona principal del galpón    │
│           └─ Aquí se mueven las gallinas                    │
├─────────────────────────────────────────────────────────────┤
│ Y=268-368 ALIMENTACIÓN (Marrón claro) — Comederos/Bebederos│
│           ├─ Comedero en X=180                             │
│           ├─ Bebedero en X=420                             │
│           ├─ Comedero en X=700                             │
│           └─ Bebedero en X=940                             │
├─────────────────────────────────────────────────────────────┤
│ Y=368-498 PERIMETRAL (Rojo punteado) — Zona de plagas (ABM)│
│           └─ Aquí se mueven los roedores (Model 2)          │
├─────────────────────────────────────────────────────────────┤
│ Y=498-648 HUD (Negro oscuro) — Interfaz gráfica            │
│           ├─ Día: X/30                                      │
│           ├─ Vacunas: X                                     │
│           ├─ Medicinas: X                                   │
│           ├─ Balance: $X                                    │
│           ├─ Inventario: X huevos                           │
│           └─ Deuda: $X                                      │
└─────────────────────────────────────────────────────────────┘

Límites de rebote:
- Izquierda: X = 0 (rebota)
- Derecha: X = 1152 (rebota)
- Arriba: Y = 68 (rebota, borde del corral)
- Abajo: Y = 368 (rebota, límite de alimentación)
```

---

## 11. Código Fuente Completo

### 11.1 main.gd - Director del Juego

```gdscript
extends Node2D
# Actúa como director: escucha el teclado y coordina a los managers y modelos.

@onready var disease_model  : Node = $Model3Disease
@onready var survival_model : Node = $Model4Queues
@onready var player         : Node = $Player
@onready var ui_manager     : Node = $UIManager
@onready var hen_manager    : Node = $HenManager
@onready var model5_economy : Node = $Model5Economy

const MAX_DAYS : int = 30
const NUMBER_OF_HENS  : int = 3
const GALPON_CAPACITY : int = 30
const BATCH_SIZE : int = 3

var is_running  : bool = false
var day : int = 0

# Inicializa modelos, crea las gallinas y prepara la interfaz
func _ready() -> void:
	disease_model.initialize_model(NUMBER_OF_HENS, GALPON_CAPACITY)
	survival_model.initialize_model(GALPON_CAPACITY)
	disease_model.day_processed.connect(_on_day_processed)

	hen_manager.spawn_initial_batch(NUMBER_OF_HENS, survival_model, is_running)

	# Inicializar Modelo 5 — Economía
	model5_economy.initialize()
	model5_economy.comprador_llego.connect(_on_comprador_llego)
	model5_economy.precio_actualizado.connect(_on_precio_actualizado)
	model5_economy.costo_maiz_actualizado.connect(_on_costo_maiz_actualizado)
	model5_economy.banquero_visito.connect(_on_banquero_visito)
	model5_economy.inspeccion_ocurrio.connect(_on_inspeccion_ocurrio)
	model5_economy.inspeccion_superada.connect(_on_inspeccion_superada)
	model5_economy.oferta_vacunas_disponible.connect(_on_oferta_vacunas_disponible)
	model5_economy.vecino_vendio.connect(_on_vecino_vendio)
	model5_economy.balance_actualizado.connect(_on_balance_actualizado)
	model5_economy.game_over.connect(_on_economy_game_over)

	# Bloquea al jugador hasta que inicie el juego
	player.set_physics_process(false)
	player.set_process(false)
	ui_manager.setup_initial_ui()

# Captura los inputs del jugador (iniciar, comprar, avanzar día)
func _unhandled_input(event: InputEvent) -> void:
	# Arranca el juego con ESPACIO
	if not is_running and event is InputEventKey and event.pressed and event.keycode == KEY_SPACE:
		_start_game()
		return

	if not is_running: return

	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: # Compra vacunas ($15.000 COP)
				if model5_economy.comprar_item(15000.0):
					player.vaccine_inventory += 1
					ui_manager.update_hud(day, player)
			KEY_2: # Compra medicinas ($8.000 COP)
				if model5_economy.comprar_item(8000.0):
					player.medicine_inventory += 1
					ui_manager.update_hud(day, player)
			KEY_3: # Avanza un día
				_advance_day()
			KEY_4: # Compra un nuevo lote de 3 gallinas ($75.000 COP - a $25.000 c/u)
				if model5_economy.comprar_item(75000.0):
					hen_manager.spawn_purchased_batch(BATCH_SIZE, survival_model, disease_model, is_running)

# Desbloquea el movimiento general y actualiza la interfaz para jugar
func _start_game() -> void:
	is_running = true
	hen_manager.set_hens_moving(true)
	player.set_physics_process(true)
	player.set_process(true)
	ui_manager.setup_running_ui()
	ui_manager.update_hud(day, player)
	
	# Forzar actualización inicial de la economía en pantalla (Día 0)
	ui_manager.update_economy(
		model5_economy.balance_caja, 
		model5_economy.inventario_huevos, 
		model5_economy.DEUDA_TOTAL - model5_economy.acumulado_ventas
	)

# Dispara el tick diario enviando el estado de vacunas/medicinas al modelo
func _advance_day() -> void:
	var used_vaccine  : bool = player.try_use_vaccine()
	var used_medicine : bool = player.try_use_medicine()
	disease_model.process_next_day(used_vaccine, used_medicine)

# Callback ejecutado cuando el Modelo 3 termina de calcular un día
func _on_day_processed(report: Dictionary) -> void:
	# Coordina las actualizaciones en cascada
	hen_manager.apply_state_changes(report["nuevos_contagiados"], report["nuevas_curadas"])
	hen_manager.process_survival(survival_model)
	hen_manager.notify_deads(disease_model)

	day = int(report["day"])
	ui_manager.update_hud(day, player)

	# Modelo 5 — Economía: procesar después de los modelos 3 y 4
	var produccion := _calcular_produccion()
	model5_economy.process_day(
		day,
		hen_manager.active_hens.size(),
		produccion,
		0,  # robos: 0 hasta que Modelo 2 esté integrado
		disease_model.infected
	)

	_validate_game_over()
	_print_debug_state(day)

# Calcula la producción de huevos del día — sección 3.b.5.6
# Tasa de postura: 0.8 por gallina sana (current_state == 0)
func _calcular_produccion() -> int:
	var total := 0
	for gallina in hen_manager.active_hens:
		if gallina.current_state == 0:
			if randf() < model5_economy.TASA_POSTURA:
				total += 1
	return total

# --- CALLBACKS DEL MODELO 5 (ECONOMÍA) ---

func _on_comprador_llego(ingreso: float) -> void:
	ui_manager.show_event_banner("🛒 Venta: $" + str(int(ingreso)))

func _on_precio_actualizado(nuevo_precio: int) -> void:
	ui_manager.show_event_banner("📈 Precio huevo: $" + str(nuevo_precio))

func _on_costo_maiz_actualizado(nuevo_costo: int) -> void:
	ui_manager.show_event_banner("🌽 Costo alimento: $" + str(nuevo_costo))

func _on_banquero_visito(deuda_restante: float) -> void:
	ui_manager.show_event_banner("🏦 Deuda restante: $" + str(int(deuda_restante)))

func _on_inspeccion_ocurrio(multa: float) -> void:
	ui_manager.show_event_banner("🚨 Multa: $" + str(int(multa)))

func _on_inspeccion_superada() -> void:
	ui_manager.show_event_banner("✅ Inspección superada ✓")

func _on_oferta_vacunas_disponible() -> void:
	ui_manager.show_event_banner("💊 ¡Vacunas con 40% descuento!")

func _on_vecino_vendio(nuevo_precio: int) -> void:
	ui_manager.show_event_banner("😤 Vecino vendió primero. Precio: $" + str(nuevo_precio))

func _on_balance_actualizado(nuevo_balance: float, acumulado: float) -> void:
	ui_manager.update_economy(nuevo_balance, model5_economy.inventario_huevos,
								model5_economy.DEUDA_TOTAL - acumulado)

func _on_economy_game_over(tipo: String) -> void:
	is_running = false
	hen_manager.set_hens_moving(false)
	player.set_physics_process(false)
	player.set_process(false)
	match tipo:
		"BANCARROTA": ui_manager.show_game_over("¡Bancarrota! Te quedaste sin dinero.")
		"VICTORIA":   ui_manager.show_game_over("¡Granja salvada! Deuda pagada.")
		"EMBARGO":    ui_manager.show_game_over("El banquero ejecuto el embargo.")

# Verifica si murieron todas las gallinas (el límite de días lo maneja el Modelo 5)
func _validate_game_over() -> void:
	if hen_manager.are_all_hens_dead() and is_running:
		is_running = false
		ui_manager.show_game_over("¡Todas tus gallinas murieron!")
		hen_manager.set_hens_moving(false)
		player.set_physics_process(false)
		player.set_process(false)

# Imprime un log en consola para monitorear las variables internamente
func _print_debug_state(current_day: int) -> void:
	print("\n---------- ESTADO DE GALLINAS — Día %d ----------" % current_day)
	print("-------------------------------------------------\n")
```

### 11.2 hen_manager.gd

```gdscript
extends Node2D
# Controla la creación, estado, movimiento y muerte de todas las gallinas en escena.

var hen_scene: PackedScene = preload("res://scenes/entities/hen.tscn")
var active_hens: Array = []

# Genera el lote inicial al abrir el juego y define al paciente cero
func spawn_initial_batch(count: int, survival_model: Node, is_running: bool) -> void:
	var new_hens: Array = []
	for i in range(count):
		var hen = hen_scene.instantiate()
		hen.position = Vector2(randf_range(0.0, 1000.0), randf_range(50.0, 300.0))
		add_child(hen)
		new_hens.append(hen)

	var added: int = survival_model.arrive_batch(new_hens, active_hens)

	for i in range(added):
		new_hens[i].is_moving = is_running

	# Elimina de la escena las gallinas que exceden la capacidad del galpón
	for i in range(added, new_hens.size()):
		new_hens[i].queue_free()

	# Infecta a la primera gallina (paciente cero)
	if active_hens.size() > 0:
		active_hens[0].set_state(1)

# Añade nuevas gallinas compradas por el jugador durante la partida
func spawn_purchased_batch(count: int, survival_model: Node, disease_model: Node, is_running: bool) -> int:
	var new_hens: Array = []
	for i in range(count):
		var hen = hen_scene.instantiate()
		hen.position = Vector2(randf_range(0.0, 1000.0), randf_range(50.0, 300.0))
		add_child(hen)
		new_hens.append(hen)

	var added: int = survival_model.arrive_batch(new_hens, active_hens)

	for i in range(added):
		new_hens[i].is_moving = is_running

	for i in range(added, new_hens.size()):
		new_hens[i].queue_free()
		
	disease_model.total_population += count
	return added

# Aplica los contagios y curaciones calculados por el Modelo 3
func apply_state_changes(new_sick: int, new_recovered: int) -> void:
	for _i in range(new_sick):
		var healthy: Array = active_hens.filter(func(h): return h.current_state == 0)
		if healthy.size() > 0: healthy.pick_random().set_state(1)

	for _i in range(new_recovered):
		var sick: Array = active_hens.filter(func(h): return h.current_state == 1)
		if sick.size() > 0: sick.pick_random().set_state(2)

# Actualiza la lista de gallinas vivas usando el cálculo del Modelo 4
func process_survival(survival_model: Node) -> void:
	active_hens = survival_model.process_survival_queue(active_hens)

# Marca como muertas a las gallinas sin vida y reporta la baja al Modelo 3
func notify_deads(disease_model: Node) -> void:
	for hen in active_hens:
		if hen.health <= 0 and not hen.dead:
			disease_model.report_chicken_death(hen.current_state)
			hen.dead = true

# Comprueba si el galpón se quedó completamente sin gallinas vivas
func are_all_hens_dead() -> bool:
	if active_hens.is_empty(): return false
	for hen in active_hens:
		if not hen.dead: return false
	return true

# Pausa o reanuda el movimiento de todas las gallinas vivas
func set_hens_moving(moving: bool) -> void:
	for hen in active_hens:
		if not hen.dead:
			hen.is_moving = moving
```

### 11.3 ui_manager.gd

```gdscript
extends Node

@onready var label_day         : Label          = $HUD/HBoxContainer/LabelDay
@onready var label_vaccines    : Label          = $HUD/HBoxContainer/LabelVaccines
@onready var label_medications : Label          = $HUD/HBoxContainer/LabelMedications
@onready var balance_label     : Label          = $HUD/HBoxContainer/BalanceLabel
@onready var inventory_label   : Label          = $HUD/HBoxContainer/InventarioLabel
@onready var debt_label        : Label          = $HUD/HBoxContainer/DeudaLabel

@onready var label_instruction : Label          = $LabelInstruction

@onready var label_game_over   : Label          = $GameOverPanel/VBoxContainer/LabelGameOver
@onready var restart_button    : Button         = $GameOverPanel/VBoxContainer/RestartButton
@onready var game_over_panel   : PanelContainer = $GameOverPanel

@onready var event_banner      : PanelContainer = $EventBanner
@onready var event_banner_label: Label          = $EventBanner/LabelEvento

func setup_initial_ui() -> void:
	label_instruction.visible = true
	game_over_panel.visible   = false
	_set_hud_visible(false)
	event_banner.visible      = false

func setup_running_ui() -> void:
	label_instruction.visible = false
	_set_hud_visible(true)
	event_banner.visible      = false

func update_hud(day: int, player: Node) -> void:
	label_day.text         = "Día %d / 30" % day
	label_vaccines.text    = "%d" % player.vaccine_inventory
	label_medications.text = "%d" % player.medicine_inventory

func update_economy(balance: float, inventory: int, remaining_debt: float) -> void:
	balance_label.text   = "$%s" % _format_cop(int(balance))
	inventory_label.text = "%d" % inventory
	debt_label.text      = "Deuda: $%s" % _format_cop(int(max(0.0, remaining_debt)))

	# Colorear la deuda según urgencia
	if remaining_debt <= 300_000:
		debt_label.add_theme_color_override("font_color", Color(0.247, 0.780, 0.373))
	elif remaining_debt <= 800_000:
		debt_label.add_theme_color_override("font_color", Color(0.961, 0.773, 0.259))
	else:
		debt_label.add_theme_color_override("font_color", Color(0.753, 0.224, 0.169))

func show_event_banner(message: String) -> void:
	event_banner_label.text = message
	event_banner.visible    = true
	await get_tree().create_timer(3.0).timeout
	event_banner.visible = false

func show_game_over(message: String = "GAME OVER") -> void:
	label_game_over.text    = message
	game_over_panel.visible = true

func _on_restart_pressed() -> void:
	get_tree().reload_current_scene()

func _set_hud_visible(is_visible: bool) -> void:
	$HUD.visible = is_visible

func _format_cop(value: int) -> String:
	# Formatea con puntos de miles: 1500000 → "1.500.000"
	var string_val := str(abs(value))
	var output     := ""
	var count      := 0
	for i in range(string_val.length() - 1, -1, -1):
		if count > 0 and count % 3 == 0:
			output = "." + output
		output = string_val[i] + output
		count += 1
	return ("-" if value < 0 else "") + output
```

### 11.4 model3_disease.gd (Epidemiología)

```gdscript
extends Node

signal day_processed(report: Dictionary)

var base_contagiousness : float
var base_recovery_rate  : float
var max_capacity        : float
var crowding_sensitivity : float
var environmental_viral_load : float

var total_population : int
var infected         : int
var current_day      : int

var acum_infections : float
var acum_recoveries : float
var acum_inflows  : float 
var acum_outflows : float

var penalty_health_base : float = 2.0 

# Configura las estadísticas iniciales para simular el brote
func initialize_model(p_total_pop: int, p_capacity: float) -> void:
	total_population = p_total_pop
	infected = 1
	
	base_contagiousness = 3
	crowding_sensitivity = 0.35
	base_recovery_rate = 0.05
	max_capacity = p_capacity
	
	current_day = 0
	acum_infections = 0.0
	acum_recoveries = 0.0

# Calcula nuevos contagiados y curados del día tomando en cuenta los objetos usados
func process_next_day(used_vaccine: bool, used_medicine: bool) -> void:
	if total_population <= 0: return
	
	var susceptible : int = maxi(total_population - infected, 0)
	var crowding_factor : float = float(total_population) / max_capacity
	
	environmental_viral_load += (crowding_factor * 0.05)
	
	if used_vaccine:
		environmental_viral_load = maxf(0.0, environmental_viral_load - 0.15)
	var effective_beta  : float = base_contagiousness * 0.15 if used_vaccine else base_contagiousness
	var effective_gamma : float = base_recovery_rate + 0.70 if used_medicine else base_recovery_rate
	

	var flow_direct_infections : float = effective_beta * crowding_factor * float(infected) * (float(susceptible) / float(total_population))
	var flow_environmental_infections : float = environmental_viral_load * float(susceptible) * 0.10
	var flow_recoveries : float = effective_gamma * float(infected)
	
	var total_inflow = flow_direct_infections + flow_environmental_infections
	acum_inflows += total_inflow
	acum_outflows += flow_recoveries
	
	var new_infections : int = int(floor(acum_inflows))
	var new_recoveries : int = int(floor(acum_outflows))
	
	acum_inflows -= new_infections
	acum_outflows -= new_recoveries
	
	if new_infections > susceptible: new_infections = susceptible
	if new_recoveries > infected: new_recoveries = infected
	
	infected = clampi(infected + new_infections - new_recoveries, 0, total_population)
	susceptible = maxi(total_population - infected, 0)
	current_day += 1
	
	var current_health_penalty = 0.0 if used_medicine else penalty_health_base
	
	var data = {
		"day": current_day,
		"S": susceptible,
		"I": infected,
		"N": total_population,
		"carga_viral_ambiental": environmental_viral_load,
		"flujo_contagio_directo": flow_direct_infections,
		"flujo_contagio_ambiental": flow_environmental_infections,
		"flujo_recuperacion": flow_recoveries,
		"nuevos_contagiados": new_infections,
		"nuevas_curadas": new_recoveries,
		"penalidad_vida": current_health_penalty
	}
	
	# Log simplificado para depuración
	print("\n--- REPORTE DÍA %d ---" % current_day)
	print("Población: %d | Sanas: %d | Enfermas: %d" % [total_population, susceptible, infected])
	print("Nuevos contagios: %d (Directo: %.1f, Ambiental: %.1f)" % [new_infections, flow_direct_infections, flow_environmental_infections])
	print("Carga Viral Ambiental: %.2f" % environmental_viral_load)
	
	day_processed.emit(data)

# Actualiza las cifras del modelo matemático cuando una gallina muere en escena
func report_chicken_death(state: int) -> void:
	if total_population <= 0: return

---

## 14. Pantalla de Historia (StoryScreen)

### 14.1 Descripción General

La **Pantalla de Historia** (`StoryScreen.tscn` y `story_screen.gd`) es una secuencia narrativa que presenta 6 imágenes consecutivas introduciendo la trama y contexto del juego antes de comenzar la partida.

**Ubicación**: 
- Escena: `scenes/StoryScreen.tscn`
- Script: `scripts/story_screen.gd`
- Assets: `assets/story/story_01.png` a `story_06.png`

### 14.2 Funcionamiento

#### Flujo de la Pantalla

1. **Inicio**: Se carga `StoryScreen.tscn`
2. **Muestra**: Primera imagen de historia (story_01.png)
3. **Interacción**: El jugador presiona el botón "Siguiente" o hace clic
4. **Avance**: Pasa a la siguiente imagen en secuencia
5. **Final**: En la última imagen (story_06.png), el botón vuelve al menú principal

#### Componentes

```
StoryScreen (Node2D) [story_screen.gd]
├── StoryImage (TextureRect)
│   └── Muestra la imagen actual
├── NextButton (Button)
│   └── Botón para avanzar a la siguiente imagen
```

#### Variables Clave

```gdscript
var story_images: Array[Texture2D] = []  # Array con las 6 imágenes
var current_index: int = 0               # Índice de imagen actual (0-5)

@onready var story_image: TextureRect = $StoryImage
@onready var next_button: Button = $NextButton
```

### 14.3 Función Principal: `_on_next_pressed()`

```gdscript
func _on_next_pressed() -> void:
	current_index += 1
	
	if current_index >= story_images.size():
		# Última imagen alcanzada → volver al menú principal
		get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")  
	else:
		# Mostrar siguiente imagen
		story_image.texture = story_images[current_index]
```

**Lógica**:
- Incrementa el índice cada vez que se presiona el botón
- Si se llega al final (`current_index >= 6`), carga la escena del menú principal
- Si aún hay imágenes, actualiza la textura mostrada

### 14.4 Efectos Visuales del Botón

El botón tiene un efecto de cambio de color al interactuar:

```gdscript
func _setup_button_fx(btn: Button) -> void:
	var fx := ColorRect.new()
	fx.color = Color(1, 1, 0, 0)  # Transparente
	fx.size = btn.size
	fx.position = btn.position
	fx.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(fx)
	
	# Al pasar el mouse
	btn.mouse_entered.connect(func():
		var tween = create_tween()
		tween.tween_property(fx, "color", Color(1, 0.85, 0, 0.25), 0.12)
	)
	
	# Al salir el mouse
	btn.mouse_exited.connect(func():
		var tween = create_tween()
		tween.tween_property(fx, "color", Color(1, 1, 0, 0), 0.15)
	)
	
	# Al presionar
	btn.button_down.connect(func():
		var tween = create_tween()
		tween.tween_property(fx, "color", Color(1, 0.75, 0, 0.5), 0.05)
		tween.tween_property(fx, "color", Color(1, 1, 0, 0), 0.2)
	)
```

**Cambios de Color**:
- **Inicio**: Amarillo transparente (1, 1, 0, 0)
- **Mouse hover**: Amarillo más opaco (1, 0.85, 0, 0.25)
- **Click**: Amarillo intenso (1, 0.75, 0, 0.5)
- **Liberación**: Vuelve a transparente

### 14.5 Arreglo Reciente (Junio 2026)

**Problema**: El botón en la última imagen no volvía al menú principal.

**Causa**: En `story_screen.gd` línea 30, se intentaba cargar:
```gdscript
get_tree().change_scene_to_file("res://scenes/world/main_menu.gd")
```

El error estaba en usar la extensión `.gd` (script) en lugar de `.tscn` (escena).

**Solución**: Corregida la línea para cargar la escena correcta:
```gdscript
get_tree().change_scene_to_file("res://scenes/world/main_menu.tscn")
```

Este cambio asegura que al presionar el botón en la última imagen, la aplicación carga correctamente la escena del menú principal en lugar de intentar cargar un archivo de script.

---

## 15. Historial de Cambios y Arreglos

### Cambios Implementados (2026-06-04)

#### Arreglo 1: StoryScreen - Botón de Menú Principal ✅
- **Archivo**: `scripts/story_screen.gd` línea 30
- **Problema**: `main_menu.gd` → **Solución**: `main_menu.tscn`
- **Impacto**: El botón ahora funciona correctamente en la última imagen de la historia
- **Estado**: Completado
	total_population -= 1
	if state == 1:  # Si era enferma
		infected = maxi(infected - 1, 0)
```

### 11.5 model4_queues.gd (Supervivencia)

```gdscript
extends Node

const MU_BASE : float = 25.0
const SIGMA_BASE : float = 2.0
const VACCINE_BONUS : float = 5.0
const PENALTY_SICK : float = 2.0
const DAILY_WEAR : float = 1.0

var capacity_k : int

signal hen_died(hen_node: Node, was_sick: bool)

# Establece el límite máximo de gallinas en el galpón
func initialize_model(max_capacity: int) -> void:
	capacity_k = max_capacity

# Calcula y asigna el tiempo de vida (salud) al instanciar una gallina
func initialize_hen(hen: Node, is_vaccinated: bool) -> void:
	var zi : float = _generate_standard_normal()
	var mu : float = MU_BASE + (VACCINE_BONUS if is_vaccinated else 0.0)
	var xi : float = mu + SIGMA_BASE * zi

	# Evita que la gallina muera instantáneamente al nacer
	xi = max(xi, 1.0)

	hen.max_health = xi
	hen.health = xi
	hen.age = 0

# Ingresa un nuevo grupo de gallinas respetando el cupo disponible
func arrive_batch(hens_to_add: Array, active_hens: Array) -> int:
	var space_available : int = capacity_k - active_hens.size()
	var to_add : int = min(hens_to_add.size(), space_available)

	for i in range(to_add):
		var hen : Node = hens_to_add[i]
		initialize_hen(hen, false)
		active_hens.append(hen)

	return to_add

# Aplica desgaste y penalidades por salud a cada gallina viva
func process_survival_queue(active_hens: Array) -> Array:
	var new_hens : Array = []

	for hen in active_hens:
		if hen.current_state == 3: 
			continue

		var was_sick : bool = (hen.current_state == 1)

		hen.age += 1
		hen.health -= DAILY_WEAR

		if was_sick:
			hen.health -= PENALTY_SICK
			
		print("Gallina: ", hen.name, " | Edad: ", hen.age, " | Salud: ", hen.health, "/", hen.max_health)

		# Marca a la gallina como muerta si se queda sin salud o alcanza su edad límite
		if hen.health <= 0.0 or hen.age >= int(hen.max_health):
			hen.health = 0.0
			hen.set_state(3)
			hen.is_moving = false
			
		new_hens.append(hen)

	return new_hens

# Retorna la edad promedio de las gallinas actualmente vivas
func get_average_age(active_hens: Array) -> float:
	if active_hens.is_empty(): return 0.0
	var total : float = 0.0
	for hen in active_hens: total += hen.age
	return total / active_hens.size()

# Retorna cuánta vida les queda en promedio a las gallinas vivas
func get_average_remaining_life(active_hens: Array) -> float:
	if active_hens.is_empty(): return 0.0
	var total : float = 0.0
	for hen in active_hens: total += hen.health
	return total / active_hens.size()

# Estima cuántas gallinas morirán por desgaste natural en un plazo de días
func forecast_deaths(active_hens: Array, days_ahead: int) -> int:
	var count : int = 0
	for hen in active_hens:
		if hen.current_state == 3: continue
		if hen.health <= float(days_ahead): count += 1
	return count

# Genera un número aleatorio con distribución normal usando el método Box-Muller
func _generate_standard_normal() -> float:
	var u1 : float = max(randf(), 0.0001)
	var u2 : float = randf()
	return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
```

### 11.6 hen.gd (Entidad)

```gdscript
extends Area2D
class_name Hen

enum State { HEALTHY, SICK, RECOVERED, DEAD }

const COLOR_SANA      := Color(0.961, 0.773, 0.259)
const COLOR_ENFERMA   := Color(0.478, 0.549, 0.416)
const COLOR_RECUPERADA:= Color(0.647, 0.808, 0.537) 
const COLOR_MUERTA    := Color(0.290, 0.290, 0.290)  

var current_state : int = State.HEALTHY
@onready var sprite = $AnimatedSprite2D

# Atributos individuales — el Modelo 4 operará directamente sobre estos valores
var health     : int
var max_health : float
var age        : int   = 0
var dead       : bool = false

# Variables de movimiento
var direction : Vector2 = Vector2.ZERO
var speed     : float   = 80.0
var is_moving : bool    = false

func _ready() -> void:
	direction = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)).normalized()
	_update_visuals()

func _process(delta: float) -> void:
	# Si no se está moviendo o está muerta, reproducir animación quieta y salir
	if current_state == State.DEAD:
		sprite.play("dead")
		return
	
	if not is_moving:
		sprite.play("idle_front")
		return
		

		
	# Aplicar movimiento
	position += direction * speed * delta
	_handle_screen_bounce()
	
	if abs(direction.x) > abs(direction.y):
		sprite.play("walk_side")
		sprite.flip_h = direction.x < 0
	elif direction.y > 0:
		sprite.play("walk_front")
	else:
		sprite.play("walk_back")

# main.gd usa esta función para decirle a la gallina que se enfermó
func set_state(new_state: int) -> void:
	if current_state != new_state:
		current_state = new_state
		_update_visuals()

# Actualiza el color de la gallina según su estado
func _update_visuals() -> void:
	match current_state:
		State.HEALTHY:
			modulate = COLOR_SANA
		State.SICK:
			modulate = COLOR_ENFERMA
		State.RECOVERED:
			modulate = COLOR_RECUPERADA
		State.DEAD:
			modulate = COLOR_MUERTA
			speed = 0.0
			is_moving = false

func _handle_screen_bounce() -> void:
	if position.x < -50.0 or position.x > 1050.0: 
		direction.x *= -1.0
		
	# Rebote en los bordes superior (cielo/pasto) e inferior (comederos) del corral
	if position.y < 45.0 or position.y > 310.0: 
		direction.y *= -1.0
```

### 11.7 player.gd

```gdscript
extends CharacterBody2D

# =====================================================================
# PLAYER — STATE & INVENTORY
# =====================================================================

const SPEED : float = 200.0

var vaccine_inventory   : int   = 0
var medicine_inventory  : int   = 0

@onready var sprite = $AnimatedSprite2D

func _physics_process(_delta: float) -> void:
	# Movimiento del jugador (WASD o Flechas)
	var input_dir := Input.get_vector("ui_left", "ui_right", "ui_up", "ui_down")
	velocity = input_dir * SPEED
	
	if input_dir != Vector2.ZERO:
		# Priorizar el movimiento horizontal si se presionan en diagonal
		if abs(input_dir.x) > abs(input_dir.y): 
			sprite.play("walk_side")
			sprite.flip_h = input_dir.x < 0 # Voltea a la izquierda si es necesario
			
		# AQUÍ ESTÁ LA "S" O HACIA ABAJO: Y es mayor a 0
		elif input_dir.y > 0: 
			sprite.play("walk_front")
			
		# Si Y es menor a 0, va hacia arriba ("W")
		else: 
			sprite.play("walk_back")
	else:
		# Si no se presiona nada, se queda quieto
		sprite.play("idle_front")
		
	move_and_slide()
	
	# Limitar movimiento a los bordes de la pantalla
	position.x = clamp(position.x, 20.0, 1132.0)
	position.y = clamp(position.y, 80.0, 630.0)

# Consume una vacuna si hay en el inventario
func try_use_vaccine() -> bool:
	if vaccine_inventory > 0:
		vaccine_inventory -= 1
		return true
	return false

# Consume una medicina si hay en el inventario
func try_use_medicine() -> bool:
	if medicine_inventory > 0:
		medicine_inventory -= 1
		return true
	return false
```

---

## 12. Diagrama de Flujo Técnico

### 12.1 Flujo de Inicialización

```
GAME START
├─ main._ready()
│  ├─ Model3Disease.initialize_model()
│  ├─ Model4Queues.initialize_model()
│  ├─ Model5Economy.initialize()
│  ├─ HenManager.spawn_initial_batch()
│  │  ├─ Crea 3 instances de hen.tscn
│  │  ├─ Model4.arrive_batch() → Asigna max_health
│  │  └─ infected = 1 (paciente cero)
│  ├─ UIManager.setup_initial_ui()
│  │  └─ Muestra instrucciones, oculta HUD
│  └─ Player bloqueado (no puede moverse)
│
└─ Esperando: Usuario presiona ESPACIO

ESPACIO PRESIONADO
├─ main._start_game()
│  ├─ is_running = true
│  ├─ HenManager.set_hens_moving(true)
│  ├─ Player desbloqueado
│  ├─ UIManager.setup_running_ui()
│  │  └─ Oculta instrucciones, muestra HUD
│  └─ update_economy() initial
│
└─ JUEGO EN PROGRESO
```

### 12.2 Flujo de Avance de Día

```
USER PRESSES 3
│
└─ main._advance_day()
   ├─ used_vaccine = player.try_use_vaccine()
   ├─ used_medicine = player.try_use_medicine()
   │
   └─ disease_model.process_next_day(used_vaccine, used_medicine)
      │
      ├─ Calcula contagios y recuperaciones
      ├─ Emite signal: day_processed(report)
      │
      └─ main._on_day_processed(report) ← CALLBACK
         │
         ├─ hen_manager.apply_state_changes(new_sick, new_recovered)
         │  ├─ Selecciona gallinas sanas aleatorias → CONTAGIO
         │  └─ Selecciona gallinas enfermas aleatorias → RECUPERACIÓN
         │
         ├─ hen_manager.process_survival(survival_model)
         │  ├─ Envejece todas las gallinas (age++)
         │  ├─ Reduce salud (health--)
         │  ├─ Si enferma: salud extra (health -= 2)
         │  └─ Marca como muertas (state = 3)
         │
         ├─ hen_manager.notify_deads(disease_model)
         │  └─ disease_model.report_chicken_death()
         │     └─ Ajusta total_population, infected
         │
         ├─ day = report["day"]
         ├─ ui_manager.update_hud(day, player)
         │
         ├─ produccion = main._calcular_produccion()
         │  └─ Bernoulli(0.8) para cada gallina sana
         │
         └─ model5_economy.process_day(day, n_gallinas, produccion, ...)
            │
            ├─ inventario_huevos += produccion
            ├─ balance_caja -= costos_dia
            │
            ├─ Verifica bancarrota
            │  └─ Si balance <= 0: game_over("BANCARROTA")
            │
            ├─ Procesa eventos del día
            │  ├─ COMPRADOR (si aplica)
            │  ├─ PRECIO_HUEVO (si aplica)
            │  ├─ COSTO_MAIZ (si aplica)
            │  ├─ BANQUERO (si aplica)
            │  ├─ INSPECCION (aleatorio)
            │  ├─ OFERTA_VACUNAS (aleatorio)
            │  └─ VENTA_VECINO (aleatorio)
            │
            ├─ Emite: balance_actualizado(...)
            └─ Emite: game_over(...) si victoria/embargo

┌─ Regresa a esperar input del jugador
```

---

## 13. Detalles de Implementación

### 13.1 Cómo Funciona el Modelo SIR

**Implementación en Godot del modelo epidemiológico clásico:**

```
Cada día:
1. Contabiliza susceptibles: S = N - I
2. Calcula factor de aglomeración: crowding = N / capacity
3. Aumenta carga viral ambiental: viral_load += crowding × 0.05
4. Si vacuna: viral_load -= 0.15
5. Define tasa efectiva de contagio: β = 3 si no vacuna, 0.45 si vacuna
6. Define tasa efectiva de recuperación: γ = 0.75 si medicina, 0.05 si no
7. Calcula flujos:
   - Contagio directo = β × crowding × I × (S/N)
   - Contagio ambiental = viral_load × S × 0.10
   - Recuperación = γ × I
8. Acumula fracciones en acum_inflows y acum_outflows
9. Toma floor() para obtener números enteros
10. Actualiza: I = I + nuevos_contagios - nuevas_recuperaciones
```

**Ventaja**: Captura la dinámica realista de propagación de enfermedades contagiosas en espacios cerrados.

### 13.2 Cómo Funciona la Distribución Normal

```gdscript
// Box-Muller Transform: Convierte 2 uniformes en 1 normal
func _generate_standard_normal() -> float:
    u1 = uniform(0.0001, 1.0)  // Evita log(0)
    u2 = uniform(0, 1)
    z = sqrt(-2 × ln(u1)) × cos(2π × u2)
    return z  // z ~ N(0,1)

// Luego se usa:
x = μ + σ × z
// Donde:
// μ = 25 (media de vida)
// σ = 2 (desviación estándar)
// x = max_health (vida asignada a la gallina)
```

**Ventaja**: Cada gallina obtiene una vida única y realista, algunos mueren jóvenes, otros llegan viejos.

### 13.3 Problema de Capacidad Resuelto

```gdscript
// En HenManager:
func spawn_purchased_batch(count, survival_model, disease_model, is_running):
    var new_hens = []
    for i in range(count):
        instantiate hen
        new_hens.append(hen)
    
    // Model4 calcula espacio disponible internamente
    var added = survival_model.arrive_batch(new_hens, active_hens)
    
    // Solo las que cabieron entran
    for i in range(added):
        new_hens[i].is_moving = is_running
    
    // Las que no cabieron se eliminan
    for i in range(added, count):
        new_hens[i].queue_free()
    
    return added
```

**Ventaja**: Nunca excede capacidad máxima (30 gallinas).

### 13.4 Conversión de Fracciones a Enteros

```gdscript
// En Model3Disease:
acum_inflows += flow_direct + flow_environmental
var new_infections = floor(acum_inflows)
acum_inflows -= new_infections  // Mantiene la fracción

acum_outflows += flow_recoveries
var new_recoveries = floor(acum_outflows)
acum_outflows -= new_recoveries
```

**Ventaja**: Preserva precisión matemática sin perder decimales. Evita que 0.3 + 0.3 + 0.3 = 0.9 nunca contagie.

### 13.5 Integración de Eventos Económicos

```gdscript
// Model5 pre-genera todos los eventos en _ready():
_generar_cola_eventos()
// Crea array de eventos: [{dia: 5, tipo: "COMPRADOR"}, ...]

// Cada día en process_day():
for evento in _cola_eventos:
    if evento["dia"] == dia_actual:
        _procesar_evento(evento["tipo"], dia_actual)

// Eventos deterministas: siempre en los mismos días
// Eventos estocásticos: Se decide Bernoulli en la generación
```

**Ventaja**: Eventos predecibles pero con incertidumbre controlada. Permite replay determinista.

---

## Conclusión

**"Huevo o Nada"** es un simulador educativo que integra cinco modelos matemáticos distintos en un contexto lúdico coherente. La arquitectura está diseñada para **desacoplamiento** (cada modelo es independiente), **escalabilidad** (fácil agregar más modelos), y **debuggabilidad** (logs extensos para validar cálculos).

La dificultad está balanceada entre **aún así viable** (si juegas bien) y **desafiante** (la economía es ajustada, las enfermedades son agresivas, los eventos son impredecibles). La curva de aprendizaje es suave: comenzar es fácil, but mastering es complejo.

---

**Documento generado**: 3 de junio de 2026  
**Versión del Proyecto**: Godot 4.6  
**Estado**: Funcionable con Modelo 2 (ABM) pendiente de integración completa

