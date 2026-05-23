extends Node

# =====================================================================
# MODEL 4 — QUEUE SYSTEM & SURVIVAL (TEORÍA DE COLAS PARA MORTALIDAD)
# =====================================================================
# Implementa el modelo de Simulación de Sistemas de Espera descrito en
# la documentación:
#   Xi = mu + sigma * Zi   (vida asignada al arribar)
#   Desgaste diario = -1 (normal) o -3 (enfermedad sin medicina)
#   Condición de salida: tiempo_restante <= 0
# =====================================================================

# --- Parámetros base del modelo (doc: mu ∈ [12,18], sigma ∈ [1,3]) ---
const MU_BASE    : float = 15.0   # Esperanza de vida natural base (días)
const SIGMA_BASE : float = 2.0    # Desviación estándar genética
const VACCINE_BONUS : float = 5.0 # Bono de vida por vacunación al arribar
const PENALTY_SICK  : float = 2.0 # Penalidad diaria si enferma sin medicina
const DAILY_WEAR    : float = 1.0 # Desgaste natural diario

# Capacidad máxima del galpón (K) — sincronizada con Modelo 3
var capacity_k : int

# =====================================================================
# SEÑALES
# =====================================================================
signal hen_died(hen_node: Node, was_sick: bool)


# =====================================================================
# INICIALIZAR MODELO
# Equivale al pseudocódigo: Procedimiento Inicializar_Modelo
# =====================================================================
func initialize_model(max_capacity: int) -> void:
	capacity_k = max_capacity


# =====================================================================
# INICIALIZAR GALLINA INDIVIDUAL
# Asigna su "ticket" de tiempo de servicio al arribar al sistema.
# Xi = (mu + bono_vacuna) + sigma * Zi
# Equivale al pseudocódigo: Procedimiento Inicializar_Gallina
# =====================================================================
func initialize_hen(hen: Node, is_vaccinated: bool) -> void:
	var zi   : float = _generate_standard_normal()
	var mu   : float = MU_BASE + (VACCINE_BONUS if is_vaccinated else 0.0)
	var xi   : float = mu + SIGMA_BASE * zi

	# Tiempo de servicio mínimo = 1 día para evitar muertes instantáneas
	xi = max(xi, 1.0)

	hen.max_health       = xi   # Vida máxima asignada (Xi)
	hen.health           = xi   # Tiempo restante inicial == vida máxima
	hen.age              = 0    # Contador de días en el sistema


# =====================================================================
# LLEGADA DE LOTE
# Ingresa un grupo de gallinas al sistema respetando la capacidad K.
# Equivale al pseudocódigo: Procedimiento Llegada_Lote
# Parámetros:
#   hens_to_add  — arreglo de nodos hen ya instanciados (sin inicializar)
#   active_hens  — arreglo maestro de gallinas vivas (se modifica in-place)
#   is_vaccinated — booleano de estado de vacunación del lote
# Retorna: cantidad de gallinas que realmente ingresaron
# =====================================================================
func arrive_batch(hens_to_add: Array, active_hens: Array) -> int:
	var space_available : int = capacity_k - active_hens.size()
	var to_add          : int = min(hens_to_add.size(), space_available)

	for i in range(to_add):
		var hen : Node = hens_to_add[i]
		initialize_hen(hen, false)
		active_hens.append(hen)

	return to_add


# =====================================================================
# PROCESAR DÍA — COLA DE SUPERVIVENCIA
# Avanza el reloj de cada gallina un tick.
# Retorna arreglo de diccionarios con las gallinas que salen del sistema.
# Equivale al pseudocódigo: Procedimiento Procesar_Dia_Gallina (masivo)
# =====================================================================
func process_survival_queue(active_hens: Array) -> Array:
	var new_hens : Array = []

	for hen in active_hens:
		# Gallinas ya muertas en escena se ignoran
		if hen.current_state == 3:  # State.DEAD
			continue

		var was_sick : bool = (hen.current_state == 1)  # State.SICK

		# --- Avance del reloj (edad) ---
		hen.age += 1

		# --- Desgaste natural diario (-1) ---
		hen.health -= DAILY_WEAR

		# --- Penalidad por enfermedad sin medicina ---
		# La documentación establece Penalidad = 2 si enferma Y sin medicina.
		# sickness_penalty viene de Modelo 3 (0.0 si hay medicina, 2.0 si no).
		if was_sick:
			hen.health -= PENALTY_SICK

		# --- Condición de salida del sistema (tiempo de servicio agotado) ---
		if hen.health <= 0.0 or hen.age >= int(hen.max_health):
			hen.health = 0.0
			hen.set_state(3)
			hen.is_moving = false
			
		new_hens.append(hen)

	return new_hens


# =====================================================================
# QUERY: ESTADO DEL SISTEMA
# Utilidades para el HUD y otros modelos
# =====================================================================

## Retorna la edad promedio del plantel activo
func get_average_age(active_hens: Array) -> float:
	if active_hens.is_empty():
		return 0.0
	var total : float = 0.0
	for hen in active_hens:
		total += hen.age
	return total / active_hens.size()

## Retorna la vida restante promedio del plantel activo
func get_average_remaining_life(active_hens: Array) -> float:
	if active_hens.is_empty():
		return 0.0
	var total : float = 0.0
	for hen in active_hens:
		total += hen.health
	return total / active_hens.size()

## Retorna cuántas gallinas morirán en los próximos N días
## (sin considerar enfermedades ni penalidades futuras)
func forecast_deaths(active_hens: Array, days_ahead: int) -> int:
	var count : int = 0
	for hen in active_hens:
		if hen.current_state == 3:
			continue
		if hen.health <= float(days_ahead):
			count += 1
	return count


# =====================================================================
# GENERADOR DE VARIABLE NORMAL ESTÁNDAR N(0,1)
# Método Box-Muller (no requiere librerías externas en GDScript)
# =====================================================================
func _generate_standard_normal() -> float:
	var u1 : float = randf()
	var u2 : float = randf()
	# Evitar log(0)
	u1 = max(u1, 0.0001)
	return sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
